# 文档导入流水线 — 设计文档

基于 Spring AI + 多策略切分，将 Markdown 书籍导入 Chroma 向量数据库，用于 RAG 问答。

## 架构概览

```
book.md
    │
    ▼
MarkdownDocumentReader  (Spring AI)     ── 读取 MD 文件为 Document
    │
    ▼
CompositeChunker                         ── 多策略编排
    ├── MarkdownSplitter                 ── 按 #/##/### 标题层级切分
    └── SentenceChunker                  ── 大段落 → BreakIterator 句子切分
    │
    ▼
EmbeddingService                         ── 智谱 embedding-2 生成向量
    │
    ▼
ChromaService                            ── 存入 ChromaDB
    │
    ▼
CourseService                            ── 自动创建课程记录
```

## 新增依赖

**pom.xml** — 添加一个依赖：

```xml
<dependency>
    <groupId>org.springframework.ai</groupId>
    <artifactId>spring-ai-markdown-document-reader</artifactId>
</dependency>
```

版本由已存在的 `spring-ai-bom:1.0.0-M6` 管理，无需额外版本号。

## 新增文件清单

```
src/main/java/com/example/course/rag/chunk/
├── DocumentChunk.java           # 数据类
├── ChunkingStrategy.java        # 策略接口
├── MarkdownSplitter.java        # Markdown 标题层级切分
├── SentenceChunker.java         # BreakIterator 句子切分
└── CompositeChunker.java        # 多策略编排器

src/main/java/com/example/course/rag/ingestion/
└── IngestionRunner.java         # 导入入口，@Profile("ingest") 控制

src/main/resources/
├── application-ingest.yaml      # ingest profile 配置
└── data/books/                  # MD 文件存放目录
```

## 各模块详细设计

### 1. DocumentChunk

```java
数据类：
- String text              // 切块文本内容
- Map<String, Object> metadata  // 元数据
```

### 2. ChunkingStrategy

```java
接口：
List<DocumentChunk> chunk(String text, Map<String, Object> baseMetadata)
```

### 3. MarkdownSplitter

**职责**：按 Markdown 标题（`#` `##` `###` `####`）将文档切分为章节块。

**切分规则**：
- 按标题行分割，每个标题及其后内容形成一个块
- 子标题内容合并到父标题块中（除非父标题块已超过 chunk_size）
- 代码块整体保留，不在代码块内部切分

**元数据**：

| key | 示例值 | 说明 |
|-----|--------|------|
| `source` | `Java核心技术.md` | 源文件名 |
| `heading_h1` | `第3章 基本程序结构` | 一级标题 |
| `heading_h2` | `3.1 变量` | 二级标题（可选） |
| `heading_h3` | `3.1.1 变量声明` | 三级标题（可选） |
| `heading_level` | `2` | 本块的最高标题层级 |

**示例**：

```markdown
# 第3章 基本程序结构
Java 程序由类组成...
## 3.1 变量
变量是存储值的位置...
### 3.1.1 变量声明
声明变量需要指定类型...
## 3.2 运算符
运算符用于执行操作...
```

生成 4 个块：

| content | heading_h1 | heading_h2 | heading_h3 |
|---------|-----------|-----------|-----------|
| "Java 程序由类组成..." | 第3章 基本程序结构 | null | null |
| "变量是存储值的位置..." | 第3章 基本程序结构 | 3.1 变量 | null |
| "声明变量需要指定类型..." | 第3章 基本程序结构 | 3.1 变量 | 3.1.1 变量声明 |
| "运算符用于执行操作..." | 第3章 基本程序结构 | 3.2 运算符 | null |

### 4. SentenceChunker

**职责**：将长段落按句子边界切分为更小的块。

**技术选型**：`java.text.BreakIterator.getSentenceInstance(Locale.CHINESE)`

- JDK 内置，无额外依赖
- 支持中文句子边界
- 比 OpenNLP（仅英文模型）更适合中文场景

**参数**：
- `chunkSize`: 1000 字符（默认）
- `overlap`: 100 字符（默认）

**元数据**：

| key | 说明 |
|-----|------|
| `chunk_type` | `"sentence"` |
| `chunk_index` | 在文档中的序号 |
| `source` | 继承自父块 |

### 5. CompositeChunker

**职责**：编排多策略切分。

**流程**：

```
Input: 全文 String + 基础元数据
  1. MarkdownSplitter.chunk(fullText, baseMetadata)
  2. 对每个返回的 chunk:
     a. chunk.text.length <= chunkSize → 保留
     b. chunk.text.length > chunkSize → SentenceChunker.chunk(chunk.text, chunk.metadata)
  3. 合并结果，写入 course_id 元数据
  4. 返回 List<DocumentChunk>
```

### 6. ChromaService 改动

**storeChunks()** 方法接收 `List<DocumentChunk>` 替代原来的 `List<String> texts`：
- metadata 写入 Chroma metadata 字段（当前只写 `chunk_index`）
- 包括：`heading_h1`、`heading_h2`、`heading_h3`、`source`、`chunk_index`

### 7. IngestionRunner

**触发方式**：Spring Profile 激活

```yaml
# application-ingest.yaml
spring:
  main:
    web-application-type: none   # 关闭 Web 服务器，快速启动
app:
  ingestion:
    book-path: data/books/book.md
    chunk-size: 1000
    chunk-overlap: 100
```

**运行命令**：

```bash
java -jar course.jar --spring.profiles.active=ingest
```

或 Maven 开发模式：

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=ingest
```

**执行流程**：

```
1. 从 `${app.ingestion.book-path}` 读取 MD 文件
2. 提取文件名（不含扩展名）作为课程名
3. 在 course 表创建课程记录（如不存在）
4. CompositeChunker.chunk(全文, {source: 文件名})
5. 批量调用 EmbeddingService.embed(chunk.text)
6. ChromaService.storeChunks(courseId, chunks, embeddings)
7. 打印统计摘要
8. System.exit(0)
```

**统计输出示例**：

```
========================================
  文档导入完成
  文件: Java核心技术.md (128,456 字符)
  课程: Java核心技术 (ID: a000...)
  切分策略: MarkdownSplitter → SentenceChunker
  总块数: 42
  平均块大小: 952 字符
========================================
```

## 现有文件改动

| 文件 | 改动内容 |
|------|----------|
| `pom.xml` | 添加 `spring-ai-markdown-document-reader` |
| `application.yaml` | 新增 `app.ingestion.*` 配置段 |
| `ChromaService.java` | `storeChunks()` 接收 `List<DocumentChunk>` 并写入完整 metadata |

## 不改动的文件

- `RagPipeline.java` — 查询/回答逻辑基本不变（仅增加了 history 参数和日志）
- `TextChunker.java` — 保留作为备选
- `EmbeddingService.java` — 不变
- 所有 Entity / Controller / Mapper — 基本不变

## 实现顺序

| 步骤 | 内容 | 涉及文件 |
|------|------|----------|
| 1 | 数据类 + 策略接口 | `DocumentChunk`, `ChunkingStrategy` |
| 2 | Markdown 切分器 | `MarkdownSplitter` |
| 3 | 句子切分器 | `SentenceChunker` |
| 4 | 组合切分器 | `CompositeChunker` |
| 5 | 导入入口 | `IngestionRunner`, `application-ingest.yaml` |
| 6 | 适配 ChromaService | 修改 `ChromaService.java` |
| 7 | 配置 + 依赖 | `application.yaml`, `pom.xml` |
| 8 | 验证 | 放置 MD 文件 → 运行 ingest profile |

# RAG 教育助手 — 后端

基于 Spring Boot 3 + MyBatis-Plus + DashScope（阿里百炼大模型平台）的 RAG 问答系统后端，为 HarmonyOS App 提供 API 服务。

## 技术栈

| 组件 | 选型                                                                                                |
|------|---------------------------------------------------------------------------------------------------|
| 框架 | Spring Boot 3.2.12, Java 17                                                                       |
| ORM | MyBatis-Plus 3.5.9                                                                                |
| 数据库 | MySQL 8.0                                                                                         |
| 缓存 | Redis (token 缓存、验证码)                                                                              |
| AI 聊天 | DashScope 阿里百炼 (`deepseek-v4-flash`), Spring AI 1.0.0-M6                                          |
| Embedding | DashScope (`text-embedding-v3`)，双轨制：Ingestion 用 HTTP 直连，RAG Pipeline 用 Spring AI `EmbeddingModel` |
| 向量库 | ChromaDB (port 8001, HTTP 客户端直连)                                                                  |
| 认证 | JWT (JJWT 0.12.6), BCrypt, Redis token 缓存（单设备登录：新登录使旧 token 失效）                                   |
| 流式推送 | WebSocket (JWT 握手鉴权，`Authorization: Bearer` Header) |
| 文档 | SpringDoc OpenAPI (Swagger UI)                                                                    |

## 快速开始

### 前置要求

- JDK 17+
- MySQL 8.0+
- Redis
- ChromaDB (port 8001)
- DashScope API Key (阿里百炼)

### 配置

复制 `.env.example` 为 `.env`，填写实际配置：

```env
DB_USERNAME=root
DB_PASSWORD=password
SMTP_USERNAME=your-email@163.com
SMTP_PASSWORD=your-auth-code
EMBEDDING_API_KEY=your-dashscope-api-key
```

### 数据库

表结构见 `src/main/resources/schema.sql`。主要表：

| 表 | 说明 |
|----|------|
| `user` | 用户（UUID 主键，含 `today_signed`、`signin_days` 签到字段） |
| `course` | 课程（含 `chroma_collection_id`，服务端预置，前端只读） |
| `session` | 用户会话（软删除 `deleted`，UUID 主键） |
| `chat_message` | 会话消息（`session_id`, `role`, `content`） |
| `qa_source` | 回答引用来源（`message_id` → `chat_message.id`） |

手动执行 SQL：

```bash
mysql -u root -p edu_rag < src/main/resources/schema.sql
```

初始化数据（可选）：

```bash
mysql -u root -p edu_rag < src/main/resources/data.sql
```

```bash
mysql -u root -p edu_rag < migration_v2.sql
```

迁移内容：`qa_history` 数据按角色拆分为 user/assistant 消息写入 `chat_message`，更新 `qa_source` 关联到新消息 ID，清理旧表。

### 启动

```bash
# 使用 Maven Wrapper
mvn spring-boot:run

# 或打包后运行
mvn clean package -DskipTests
java -jar target/course-0.0.1-SNAPSHOT.jar
```

启动后访问：
- 服务: `http://localhost:8080`
- Swagger 文档: `http://localhost:8080/swagger-ui/index.html`
- 健康检查: `http://localhost:8080/actuator/health`

### 文档导入（Ingest）

将教材 Markdown 文件分块、嵌入并存入 ChromaDB：

```bash
# 将 book.md 放入 data/books/ 目录
# 运行导入（关闭 Web 服务器，快速执行）
mvn spring-boot:run -Dspring-boot.run.profiles=ingest
```

导入流程：MD 文件 → MarkdownSplitter（按标题层级切分）→ SentenceChunker（长段落补充分句）→ DashScope Embedding → ChromaDB 存储 → 自动创建课程记录。

## API 概览

### 公共接口（无需认证）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 注册（用户名+密码+邮箱） |
| POST | `/api/auth/login/password` | 密码登录（邮箱+密码） |
| POST | `/api/auth/login/code` | 验证码登录（邮箱+验证码） |
| POST | `/api/auth/code/send` | 发送邮箱验证码（60s 限流） |
| POST | `/api/auth/logout` | 登出（删除 Redis token 缓存） |

### 需认证接口（`Authorization: Bearer <token>`）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/users/me` | 获取当前用户信息 |
| PUT | `/api/users/me` | 更新用户名/邮箱 |
| PUT | `/api/users/me/password` | 修改密码（需原密码） |
| POST | `/api/users/signin` | 签到（今日首次调用成功，重复返回错误） |
| GET | `/api/users/signin/days` | 获取签到信息（`todaySigned` + `signinDays`） |
| GET | `/api/courses` | 课程列表 |
| GET | `/api/courses/{id}` | 课程详情 |
| POST | `/api/qa/ask` | 提问（同步，返回完整回答） |
| WebSocket | `ws://.../ws/qa/ask` | **提问（流式，主要接口）**，前端通过此端点实现逐字输出 |
| POST | `/api/qa/ask/stream` | 提问（已弃用，保留兼容） |
| GET | `/api/sessions` | 已登录用户的所有会话（分页，按更新时间倒序） |
| GET | `/api/sessions/{courseId}` | 按课程过滤会话列表（分页） |
| GET | `/api/sessions/{id}/history` | 会话消息历史（flat 消息列表） |
| DELETE | `/api/sessions/{id}` | 软删除会话 |

### 请求/响应体格式

#### 注册 `POST /api/auth/register`

```json
{"username":"string","password":"string","email":"string","code":"验证码"}
```

返回 `TokenVO`：
```json
{"token":"jwt","userId":"uuid","username":"string"}
```

#### 更新用户 `PUT /api/users/me`

```json
{"username":"string（可选）","email":"string（可选）"}
```

#### 修改密码 `PUT /api/users/me/password`

```json
{"oldPassword":"string","newPassword":"string"}
```

#### 签到 `POST /api/users/signin`

返回 `SigninVO`：
```json
{"todaySigned":true,"signinDays":3}
```

#### 提问 `POST /api/qa/ask`

```json
{"courseId":"uuid","question":"string","sessionId":"uuid（可选，续传历史会话）"}
```

#### 提问（SSE，已弃用） `POST /api/qa/ask/stream`

同 `/api/qa/ask` 请求体，响应为 `text/event-stream`，事件格式同 WebSocket。

> 该端点已弃用，前端已切换为 WebSocket 流式问答。当前保留仅为向后兼容，后续版本将移除。

#### 创建会话 `POST /api/sessions`

```json
{"courseId":"uuid"}
```

### 健康检查

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/` | 应用信息（名称、版本、状态） |
| GET | `/api/health` | 健康检查 |

### WebSocket 流式问答

**端点**: `ws://localhost:8080/ws/qa/ask`

**握手**: 通过 HTTP Header 携带 JWT Token：`Authorization: Bearer <token>`（在 WebSocket 升级请求中设置）

**请求格式**（建立连接后发送）：

```json
{
  "courseId": "uuid",
  "question": "什么是TCP？",
  "sessionId": "uuid（可选，续传历史会话）"
}
```

**响应事件流**（按顺序推送）：

```
{"type":"start","role":"assistant"}
{"type":"sources","data":[{"id":"src-1","content":"..."}]}
{"type":"token","content":"根据"}
{"type":"token","content":"资料"}
...
{"type":"done","data":{"role":"assistant","content":"完整回答","sources":[...],"createdAt":"..."}}
```

### 会话列表分页

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `page` | 1 | 页码（从 1 开始） |
| `size` | 20 | 每页条数 |

返回 `ApiResponse<PageVO<SessionVO>>`。

### 会话历史响应格式

```json
[
  {"role":"user","content":"什么是TCP","createdAt":"..."},
  {"role":"assistant","content":"TCP是...","sources":[{"id":"src-1","content":"..."}],"createdAt":"..."}
]
```

### 统一响应格式

成功：
```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

错误（`data` 不返回）：
```json
{
  "code": 400,
  "message": "错误描述"
}
```

## 测试

```bash
mvn test
```

## 项目结构

```
src/main/java/com/example/course/
├── config/            # 安全、MyBatis、Redis、CORS、Swagger、WebSocket、AI 配置
│   ├── SecurityConfig.java       # 三链安全配置（ERROR/public/API）
│   ├── EmbeddingConfig.java      # Spring AI EmbeddingModel Bean
│   ├── WebSocketConfig.java      # WebSocket 端点注册
│   ├── CorsConfig.java
│   ├── SwaggerConfig.java
│   └── RedisConfig.java / MyBatisPlusConfig.java
├── controller/        # REST 控制器
│   ├── AuthController.java       # 注册/登录/登出/验证码
│   ├── UserController.java       # 用户信息/签到
│   ├── CourseController.java     # 课程列表/详情
│   ├── QaController.java         # 同步/流式提问
│   └── SessionController.java    # 会话 CRUD
├── dto/               # 请求 DTO + 通用响应
│   ├── ApiResponse.java          # 统一响应包装
│   ├── AuthRequest.java          # 登录/注册请求
│   ├── UpdateUserDTO.java        # 更新用户信息
│   ├── ChangePasswordDTO.java    # 修改密码
│   ├── QaRequest.java            # 提问请求
│   └── SessionDTO.java           # 创建会话请求
├── entity/            # 数据库实体（User / Course / Session / ChatMessage / QaSource）
├── exception/         # 全局异常处理
├── mapper/            # MyBatis-Plus Mapper 接口
├── rag/               # RAG 管线
│   ├── RagPipeline.java          # 检索→组装→调用 LLM 主流程
│   ├── EmbeddingService.java     # HTTP 直连 DashScope Embedding API
│   ├── ChromaService.java        # ChromaDB 相似度检索（top-k=5）
│   ├── chunk/                    # 文档切分策略
│   │   ├── CompositeChunker.java # 组合切分器（Markdown + 句子）
│   │   └── TextChunker.java      # 保留备选
│   └── ingestion/                # 文档导入流水线
│       ├── IngestionRunner.java  # 导入入口
│       └── MarkdownDocumentReader.java
├── security/          # JWT 认证
│   ├── JwtTokenProvider.java     # JWT 生成/验证
│   ├── JwtAuthenticationFilter.java # 请求拦截过滤器（Redis 缓存回退）
│   ├── JwtHandshakeInterceptor.java # WebSocket 握手鉴权
│   └── UserDetailsServiceImpl.java
├── service/           # 业务逻辑接口 + 实现
│   ├── AuthService / AuthServiceImpl
│   ├── UserService / UserServiceImpl
│   ├── CourseService / CourseServiceImpl
│   ├── SessionService / SessionServiceImpl
│   ├── QaService / QaServiceImpl
│   ├── ChatMessageService / ChatMessageServiceImpl
│   └── QaSourceService / QaSourceServiceImpl
└── vo/                # 视图对象（响应体）
    ├── TokenVO.java              # 登录/注册返回
    ├── SigninVO.java             # 签到信息
    ├── UserVO.java               # 用户信息
    ├── SessionVO.java            # 会话视图
    ├── ChatMessageVO.java        # 消息 + 来源
    ├── QaSourceVO.java           # 来源引用
    └── PageVO.java               # 分页包装
```

## RAG 管线架构

> **注意**：项目存在两套 Embedding 机制：
> - **RAG Pipeline**（问答时检索）：使用 Spring AI 的 `EmbeddingModel` 接口（通过 `EmbeddingConfig` 配置的 `OpenAiEmbeddingModel` Bean，兼容 DashScope）
> - **Ingestion**（文档导入时）：使用自定义 `EmbeddingService`（HTTP 直连 DashScope 原生 API）
>
> 两套均使用 DashScope `text-embedding-v3` 模型，响应兼容。

```
用户提问
    │
    ▼
EmbeddingModel / EmbeddingService (DashScope text-embedding-v3)
    │
    ▼
ChromaService (相似度检索，top-k=5)
    │
    ▼
RagPipeline (组装 Prompt → 调用阿里百炼 deepseek-v4-flash)
    │
    ▼
返回回答 + 来源引用 → 存入 chat_message + qa_source
```

### 文档导入（Ingestion）

```
book.md
    │
    ▼
MarkdownDocumentReader (Spring AI)
    │
    ▼
CompositeChunker
    ├── MarkdownSplitter (按 #/##/### 标题层级切分)
    └── SentenceChunker (大段落 → BreakIterator 句子补切)
    │
    ▼
EmbeddingService (DashScope text-embedding-v3)
    │
    ▼
ChromaDB (集合名: course_{courseId}_docs)
```

## 环境变量

| 变量 | 默认值                                                                      | 说明 |
|------|--------------------------------------------------------------------------|------|
| DB_USERNAME | root                                                                     | MySQL 用户名 |
| DB_PASSWORD | password                                                                 | MySQL 密码 |
| REDIS_HOST | localhost                                                                | Redis 主机 |
| REDIS_PORT | 6379                                                                     | Redis 端口 |
| SMTP_HOST | smtp.163.com                                                             | SMTP 服务器 |
| SMTP_PORT | 465                                                                      | SMTP 端口 |
| SMTP_USERNAME | dummy@dev.com                                                            | 邮箱账号 |
| SMTP_PASSWORD | dummy-password                                                           | 邮箱密码/授权码 |
| SMTP_FROM | dummy@dev.com                                                            | 发件地址 |
| EMBEDDING_API_KEY | dummy-key                                                                | DashScope API Key（聊天 + Embedding 共用） |
| DASHSCOPE_BASE_URL | https://dashscope.aliyuncs.com/compatible-mode                           | DashScope 兼容 API 地址（聊天用） |
| EMBEDDING_NATIVE_URL | https://dashscope.aliyuncs.com/api/v1/services/embeddings/text-embedding | DashScope 原生 Embedding API 地址（Ingestion 用） |
| EMBEDDING_BASE_URL | https://dashscope.aliyuncs.com/compatible-mode                           | DashScope 兼容模式 Embedding API 地址（RAG Pipeline 用） |
| CHAT_MODEL | deepseek-v4-flash                                                        | 聊天模型 |
| EMBEDDING_MODEL | text-embedding-v3                                                        | Embedding 模型 |
| CHROMA_URL | http://localhost:8001                                                    | ChromaDB 地址 |
| JWT_SECRET | dev-secret-...                                                           | JWT 签名密钥 |
| JWT_EXPIRATION | 86400000                                                                 | JWT 过期时间 (ms) |
| INGESTION_BOOK_PATH | data/books/book.md                                                       | 导入的 MD 文件路径 |
| INGESTION_CHUNK_SIZE | 1000                                                                     | 切分块大小（字符） |
| INGESTION_CHUNK_OVERLAP | 100                                                                      | 切分重叠大小（字符） |

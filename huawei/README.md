# RAG 教育助手 — 鸿蒙客户端

基于 ArkTS + ArkUI 的 HarmonyOS NEXT 应用，为 RAG 教育问答系统提供移动端界面。

## 技术栈

| 组件 | 选型 |
|------|------|
| 语言 | ArkTS (API 12) |
| UI 框架 | ArkUI 声明式 UI |
| 网络 | `@ohos.net.http` + `@ohos.net.webSocket` |
| 状态管理 | `@State` / `@Link` / emitter 事件分发 |
| 持久化 | `@ohos.data.preferences` |
| Markdown | 自定义解析器 + `fluid-markdown` |
| 构建 | Hvigor |

## 页面路由

定义文件：`entry/src/main/resources/base/profile/main_pages.json`

| 页面 | 路径 | 说明 |
|------|------|------|
| Index | `pages/Index.ets` | 应用入口，检查登录状态后跳转 Login 或 MainPage |
| Login | `pages/Login.ets` | 密码登录 / 验证码登录双模式 |
| Register | `pages/Register.ets` | 注册（用户名 + 密码 + 邮箱 + 验证码） |
| MainPage | `pages/MainPage.ets` | 底部 Tab 导航（首页 / 历史 / 我的） |
| QaChat | `pages/QaChat.ets` | AI 问答聊天界面（流式 WebSocket，Markdown 渲染） |
| History | `pages/History.ets` | 历史会话列表（分页加载） |
| Settings | `pages/Settings.ets` | 编辑资料 + 修改密码 |
| SourceDetail | `pages/SourceDetail.ets` | AI 回答引用来源详情 |

## 导航流

```
Index → 未登录 → Login / Register
Index → 已登录 → MainPage
                    ├─ Tab 0: CourseList（课程列表 + 每日签到）
                    │           └─ 点击课程 → QaChat
                    ├─ Tab 1: HistoryTab（历史会话精简版）
                    │           └─ 点击会话 → QaChat
                    └─ Tab 2: Profile（用户信息 + 菜单）
                                ├─ 设置 → Settings
                                └─ 退出登录 → Login
```

## 核心服务

### ApiClient (`service/ApiClient.ets`)

HTTP + WebSocket 通信层：
- HTTP 请求自动附带 `Authorization: Bearer <token>` Header
- WebSocket 流式问答（`ws://10.0.2.2:8080/ws/qa/ask`），握手通过 HTTP Header 鉴权
- 通过 `@ohos.events.emitter` 将 SSE 事件分发到 UI 层
- 支持 Mock 模式切换（`useMock` 标志），离线开发时使用 `MockData`

**SSE 事件类型：**

| 事件 | 说明 |
|------|------|
| `start` | 开始响应 |
| `sources` | 来源引用（`data` 字段） |
| `token` | 逐字回答内容（`content` 字段） |
| `done` | 完整回答结束（含最终 `content` + `sources`） |
| `error` | 错误信息 |

### AuthStorage (`service/AuthStorage.ets`)

基于 `@ohos.data.preferences` 的 Token/用户信息持久化：
- 存储键：`edu_rag_token`（JWT）、`edu_rag_user`（用户 JSON）

### MockData (`service/MockData.ets`)

离线 Mock 数据层，支持无后端开发与测试。

## 设计系统

### 颜色 Token (`common/PixelStyles.ets`)

| Token | 值 | 用途 |
|-------|-----|------|
| `SCREEN_BG` | `#F5F0EB` | 页面背景（暖白） |
| `SURFACE` | `#FFFFFF` | 卡片/表单背景 |
| `ACCENT` | `#C8685A` | 主色调（红棕） |
| `INK` | `#2C2C2C` | 正文 |
| `INK_SECONDARY` | `#6B6B6B` | 辅助文字 |
| `DANGER` | `#C84040` | 危险/退出 |
| `SUCCESS` | `#6B9E6B` | 成功/已签到 |

完整 30 个常量见 `PixelStyles.ets`。

### 图标 (`common/Icons.ets`)

17 个内联 SVG 图标组件（`IconHome`、`IconClock`、`IconUser`、`IconSettings`、`IconLogOut` 等），支持动态颜色和尺寸。

### Markdown 解析 (`common/MarkdownParser.ets`)

自定义 Markdown 解析器（842 行），支持：
- 标题（`#` ~ `######`）
- 有序/无序列表
- 代码块（行内 + 围栏）
- 表格
- 引用块
- 加粗/斜体/行内代码

AI 回答还通过 `fluid-markdown` 库渲染（在 `QaChat.ets` 中使用）。

## 数据模型

| 文件 | 类型 | 说明 |
|------|------|------|
| `model/ApiResponse.ets` | interface | 通用 API 响应 `{code, message, data}` |
| `model/Course.ets` | class | 课程（id, name, description, createdAt） |
| `model/User.ets` | class | 用户（username, email） |
| `model/QaRecord.ets` | class | QA 记录（sessionId, courseId, question, answer） |

## 配置

| 文件 | 说明 |
|------|------|
| `AppScope/app.json5` | bundleName: `com.test.edurag`, versionName: `1.0.0` |
| `entry/src/main/module.json5` | 权限: `ohos.permission.INTERNET` |
| `entry/build-profile.json5` | Stage 模型构建配置 |
| `common/Constants.ets` | API 基地址 `http://10.0.2.2:8080/api` |
| `resources/base/element/color.json` | 亮色/暗色双主题色板 |

## 构建与运行

```bash
# 安装依赖
ohpm install

# 构建 HAP
hvigorw --mode module -p module=entry@default assembleHap

# 安装到设备/模拟器
hdc install entry/build/default/outputs/default/entry-default.hap
```

## 依赖

- `fluid-markdown` — AI 回答 Markdown 渲染（`oh-package.json5` 管理）
- 其余依赖为 HarmonyOS SDK 内置模块

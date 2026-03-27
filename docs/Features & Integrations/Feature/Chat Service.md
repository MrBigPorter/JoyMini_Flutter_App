# Chat Service — 客户端现状审计与 Admin 客服端规划

> **文档版本**: v2.0  
> **更新日期**: 2026-03-18  
> **适用对象**: Flutter 客户端 / Admin 后台 / API 开发者  
> **定位**: 这是一份基于当前仓库代码的**核实版**规划文档，优先级高于旧版推演性描述。  
> **特别说明**: 本文档已校正 `admin/FEATURES_CN.md` 第 19 节中的部分假设，尤其是 **`senderId = null` 客服回复**、**媒体 duration 单位**、**客户端发送链路** 等问题。

---

## 0. 先说结论

### 已经有的

1. **客户端 IM 主链路已经比较完整**：
   - 客服入口：`lib/core/services/customer_service/customer_service_helper.dart`
   - 会话/消息 REST：`lib/core/api/lucky_api.dart`
   - 实时事件：`lib/core/services/socket/socket_service.dart`
   - 发送管线：`lib/ui/chat/services/chat_action_service.dart`
   - 历史同步：`lib/ui/chat/providers/chat_view_model.dart`
   - 本地离线缓存：`lib/ui/chat/services/database/local_database_service.dart`

2. **客服会话已经存在明确入口**：
   - 客户端通过 `Api.chatBusinessApi('official_platform_support_v1')` 进入客服会话。
   - 当前接口真实形态是：
     `GET /api/v1/chat/business?businessId=official_platform_support_v1`

3. **数据库层已经具备聊天基础模型**：
   - `admin/schema.prisma` 中已有 `Conversation` / `ChatMessage` / `ChatMember`
   - `ConversationType.SUPPORT` 已存在
   - `Conversation.status` 已存在，可复用作关闭/归档状态基础

### 还没有的

1. **Chat 服务端主链路代码已在 `admin/` 目录落地**。
   当前已可见：
   - `chat.module.ts`
   - `chat.controller.ts`
   - `chat.service.ts`
   - `chat-group.controller.ts`
   - `chat-group.service.ts`
   - `admin/seed/clear-chat.ts`
   说明：客户端聊天 API 与群管理 API 已有实现基础，文档口径需从“缺模块”切换为“补联调与补 Admin 接待台”。

2. **Admin 客服身份模型没有落地**。
   这是当前最关键缺口。现有客户端/消息模型默认发送者是 `User`，并**不支持**安全地把客服消息定义成 `senderId = null` 的普通客服消息。

3. **媒体消息规范旧文档不够准确**，尤其：
   - 图片 / 视频 / 音频的字段优先级需要统一
   - 视频/音频 `duration` 在当前 Flutter 代码里实际按“秒”使用，不是旧文档里写的毫秒
   - 视频封面字段需要统一优先级：`remote_thumb` > `thumb`

---

## 1. 本次核实范围

本次分析基于以下真实文件，而不是只看文档设想：

### 客户端 Flutter 侧

- `lib/core/services/customer_service/customer_service_helper.dart`
- `lib/core/api/lucky_api.dart`
- `lib/core/services/socket/socket_service.dart`
- `lib/core/services/socket/chat_extension.dart`
- `lib/ui/chat/services/chat_action_service.dart`
- `lib/ui/chat/pipeline/pipeline_steps.dart`
- `lib/ui/chat/services/chat_message_factory.dart`
- `lib/ui/chat/providers/chat_view_model.dart`
- `lib/ui/chat/handlers/chat_event_handler.dart`
- `lib/ui/chat/handlers/global_chat_handler.dart`
- `lib/ui/chat/models/chat_ui_model.dart`
- `lib/ui/chat/models/conversation.dart`
- `lib/ui/chat/models/chat_ui_model_mapper.dart`
- `lib/ui/chat/components/bubbles/image_msg_bubble.dart`
- `lib/ui/chat/components/bubbles/video_msg_bubble.dart`
- `lib/ui/chat/components/bubbles/voice_bubble.dart`
- `lib/utils/upload/global_upload_service.dart`
- `lib/utils/media/url_resolver.dart`
- `lib/utils/media/remote_url_builder.dart`
- `lib/utils/media/media_path.dart`

### Admin / 服务端规划侧

- `admin/schema.prisma`
- `admin/FEATURES_CN.md`
- `admin/ARCHITECTURE.md`
- `admin/group.controller.ts`
- `admin/seed/clear-chat.ts`

---

## 2. 当前真实架构

## 2.1 客户端聊天架构

```text
CustomerServiceHelper
    ↓
Api.chatBusinessApi(businessId)
    ↓
拿到 conversationId
    ↓
进入 ChatPage / ChatRoom
    ↓
ChatViewModel 拉历史消息 + 增量补洞
ChatEventHandler 负责 join_chat / 已读 / 撤回监听
GlobalChatHandler 负责全局 socket 新消息落库
ChatActionService 负责发送管线
```

### 分层职责

| 层 | 当前实现 | 说明 |
|---|---|---|
| 会话入口 | `CustomerServiceHelper.startChat()` | 创建/获取客服会话 |
| HTTP API | `Api.*` | 会话详情、历史消息、发送消息、已读、撤回 |
| Socket | `SocketService` | 实时事件分发、join/leave 房间、读回执、撤回通知 |
| 发送管线 | `ChatActionService` + `pipeline_steps.dart` | 本地乐观写入、媒体处理、上传、最终发送 |
| 本地存储 | `LocalDatabaseService` + `MessageRepository` | 离线缓存、流式观察、未读修复 |
| 页面状态 | `ChatViewModel` + `ChatEventHandler` | 首屏同步、历史分页、已读同步 |

---

## 2.2 一个重要的真实结论：当前“发送”主链路是 REST，不是 Socket

虽然 `SocketChatMixin` 里有：

- `sendMessage()`
- `joinChatRoom()`
- `leaveChatRoom()`

但**当前 Flutter 真正发送消息**走的是：

- `ChatActionService`
- `SyncStep`
- `Api.sendMessage()`
- `POST /api/v1/chat/message`

也就是说：

### 当前客户端链路是

- **发送消息**：HTTP REST
- **接收消息/已读/撤回/会话变更**：Socket `dispatch`
- **进入房间**：Socket `join_chat`
- **拉历史/补洞**：HTTP REST

这对 Admin 很重要：

> **Admin MVP 不必一开始就接 Socket 发消息。**  
> 只要后端提供稳定的 Admin Chat REST 接口，Admin 端完全可以先走 **HTTP 轮询 + HTTP 发送**。

---

## 3. 客服会话当前事实

## 3.1 客服入口

当前 Flutter 客户端是这样进入客服会话的：

```dart
final conversation = await Api.chatBusinessApi('official_platform_support_v1');
```

对应真实 API：

```http
GET /api/v1/chat/business?businessId=official_platform_support_v1
```

### 注意

旧文档里曾写过：

- `POST /api/chat/business`
- body 用 `bizKey`

但**当前仓库代码不是这样**。

### 因此当前的 canonical contract 应该是

| 项目 | 真实值 |
|---|---|
| 客服业务标识 | `official_platform_support_v1` |
| 参数名 | `businessId` |
| 方法 | `GET` |
| 路径 | `/api/v1/chat/business` |

---

## 3.2 会话类型

在 `admin/schema.prisma` 与 Flutter 模型里，已经统一存在：

- `DIRECT`
- `GROUP`
- `SUPPORT`
- `BUSINESS`

其中 Admin 客服端应该只处理：

- `type = SUPPORT`

---

## 4. 当前 Admin 目录分析结果

## 4.1 已有内容

### 1) 数据模型基础已存在

`admin/schema.prisma` 已包含：

- `Conversation`
- `ChatMessage`
- `ChatMember`
- `ConversationType.SUPPORT`
- `Conversation.status`
- `Conversation.lastMsgSeqId`
- `ChatMessage.meta`

这说明：

> 聊天基础表已经够用来做 Admin 客服台第一版。

### 2) 设计意图已存在

`admin/FEATURES_CN.md` 第 19 节已经提出了：

- 会话列表
- 消息历史
- 客服回复
- 强制撤回
- 关闭会话
- 轮询式 Admin Desk

### 3) Admin 模块的 NestJS 风格可参考

从 `admin/group.controller.ts` 可以看出当前 Admin/Nest 风格大致是：

- `@Controller()`
- `@UseGuards(...)`
- `@ApiOkResponse(...)`
- DTO 入参/返回
- Service 注入式组织

客服模块可以沿用同样结构。

---

## 4.2 缺失内容

### 当前 workspace 中主要缺口（更新后）

| 项目 | 状态 | 说明 |
|---|---|---|
| 客户端 Chat/Group API | 已落地 | `chat.controller.ts` + `chat-group.controller.ts` 已覆盖消息、会话、群管理、入群审批等能力 |
| Chat 服务模块编排 | 已落地 | `chat.module.ts` 已接入 `ChatService`、`ChatGroupService`、事件监听与上传能力 |
| Admin 接待台前端 | 缺失 | 仍没有后台客服工作台页面（会话面板/消息窗/分配面板） |
| Admin 专用客服 API | 待补齐 | 当前以客户端 chat 路由为主，后台工单化接口（分配/SLA/筛选）仍需单独设计 |
| 客服身份映射方案 | 待定稿 | `AdminUser` 如何映射为聊天发送者（虚拟 User 或原生 AdminSender）仍需定版 |
| 媒体一致性规范 | 持续约束 | 视频/音频 duration 秒制、`remote_thumb > thumb` 已明确，但需 Admin 端严格执行 |

---

## 5. 当前最核心的架构冲突

## 5.1 `senderId = null` 不能直接作为“客服普通回复”方案

`admin/FEATURES_CN.md` 里有一个旧假设：

- Admin 回复时写 `senderId = null`
- 前端把它当 `isSystem = true`
- 右侧显示客服气泡

这个方案和当前客户端代码**冲突很大**。

### 原因 1：Flutter Socket 模型把 `senderId` 当必填字符串

`lib/ui/chat/models/conversation.dart` 中：

```dart
class SocketMessage {
  final String senderId;
}
```

这意味着如果服务端通过 socket 下发：

```json
{ "senderId": null }
```

客户端解析就存在风险。

### 原因 2：当前客户端把“系统消息”理解为 `type == 99`

`ChatEventHandler._onSocketMessage()` 中明确有：

- `if (msg.type == 99) return;`

也就是说当前“系统消息”的核心判断是：

- **`type == 99`**

而不是“`senderId == null` 的普通文本消息”。

### 原因 3：`ChatMessage.sender` 当前关联的是 `User`

`admin/schema.prisma` 里：

```prisma
senderId String?
sender   User?
```

这里没有 `AdminUser` 关系。

所以如果 Admin 想作为真实会话发送者发言，当前数据库层并没有直接表达：

- 这条消息来自哪个 `AdminUser`
- 前端应该展示哪个客服头像/昵称

---

## 5.2 推荐解决方案

### 方案 A：第一期采用“客服虚拟用户”模型（推荐 MVP）

做法：

- 在 `User` 体系里准备一个或多个“平台客服账号”
- Admin 回复时，服务端将消息写成这个客服用户发出
- 同时在 `meta` 中补充：
  - `agentAdminId`
  - `agentName`
  - `isSupportReply: true`

#### 优点

- 对现有 Flutter 客户端最友好
- 不需要把 `SocketMessage.senderId` 改成 nullable
- 不需要大改现有消息解析
- Socket/REST 契约最稳定

#### 缺点

- Admin 身份和 IM 发送者身份是两层映射
- 审计时要同时看 `senderId` 与 `meta.agentAdminId`

### 方案 B：第二期升级为“Admin 发送者原生建模”

做法：

- 扩展 `ChatMessage`：支持 `adminSenderId`
- 客户端消息模型允许 `senderId` 为空
- 增加 `adminSender` 结构
- 前端明确区分：用户消息 / 客服消息 / 系统消息

#### 优点

- 模型更干净
- 审计更清晰

#### 缺点

- Flutter / Socket / REST / DB / 管理后台全链路都要改
- 第一版成本明显更高

### 本文建议

> **P1 上线请选方案 A。**  
> 等 Admin 客服台跑通后，再决定是否演进到方案 B。

---

## 6. Admin 客服端应该补齐什么

## 6.1 后端模块（现状 + 下一步）

已落地（客户端 chat 侧）：

```text
admin/
  ├── chat.module.ts
  ├── chat.controller.ts
  ├── chat.service.ts
  ├── chat-group.controller.ts
  └── chat-group.service.ts
```

下一步（Admin 接待台侧）建议新增：

```text
apps/api/src/admin/chat-desk/
  ├── admin-chat-desk.module.ts
  ├── admin-chat-desk.controller.ts
  ├── admin-chat-desk.service.ts
  └── dto/
      ├── query-conversations.dto.ts
      ├── query-messages.dto.ts
      ├── admin-reply.dto.ts
      ├── close-conversation.dto.ts
      └── assign-conversation.dto.ts
```

## 6.2 Admin API 建议

### 最小可用接口

| 方法 | 路径 | 说明 |
|---|---|---|
| `GET` | `/v1/admin/chat/conversations` | 客服会话列表，默认 `type=SUPPORT` |
| `GET` | `/v1/admin/chat/conversations/:id/messages` | 消息历史，游标分页 |
| `POST` | `/v1/admin/chat/conversations/:id/reply` | 文本回复 |
| `POST` | `/v1/admin/chat/conversations/:id/send-media` | 图片/视频/音频/文件回复 |
| `POST` | `/v1/admin/chat/messages/:id/force-recall` | 管理员强制撤回 |
| `PATCH` | `/v1/admin/chat/conversations/:id/close` | 关闭会话 |
| `PATCH` | `/v1/admin/chat/conversations/:id/assign` | 分配给某个客服 |
|

### 建议返回结构

#### 会话列表

```ts
interface AdminChatConversation {
  id: string;
  type: 'SUPPORT';
  status: number;              // 1 active, 2 closed
  businessId?: string | null;
  lastMsgContent?: string | null;
  lastMsgType?: number | null;
  lastMsgTime?: number | null;
  lastMsgSeqId: number;
  unreadCount?: number;
  memberCount: number;
  customer?: {
    userId: string;
    nickname: string;
    avatar?: string | null;
  };
  assigneeAdminId?: string | null;
  assigneeAdminName?: string | null;
  lastCustomerMsgAt?: number | null;
  lastAgentReplyAt?: number | null;
}
```

#### 消息结构

```ts
interface AdminChatMessage {
  id: string;
  conversationId: string;
  senderId?: string | null;       // MVP 推荐仍尽量返回真实 User senderId
  type: 0 | 1 | 2 | 3 | 5 | 6 | 99;
  content: string;
  createdAt: number;
  seqId: number;
  isRecalled: boolean;
  isSupportReply?: boolean;
  sender?: {
    id: string;
    nickname: string;
    avatar?: string | null;
  } | null;
  meta?: Record<string, any> | null;
}
```

---

## 6.3 数据库建议补充字段

当前 `Conversation` 只有通用聊天字段，缺少客服工单视角字段。

建议新增：

### Conversation 级

- `supportAssigneeAdminId String?`
- `supportClaimedAt DateTime?`
- `firstResponseAt DateTime?`
- `lastCustomerMsgAt DateTime?`
- `lastAgentReplyAt DateTime?`
- `closedAt DateTime?`
- `closedByAdminId String?`
- `priority Int @default(0)`
- `tags Json?`

### ChatMessage.meta 级

客服消息建议补充：

- `agentAdminId`
- `agentName`
- `isSupportReply`
- `source: 'admin' | 'client' | 'system'`

如果后续要做更强一致的音频波形，也可加：

- `waveform: number[]`

---

## 7. 客户端真实消息链路

## 7.1 文本消息

```text
输入文本
  ↓
ChatActionService.sendText()
  ↓
本地 saveOrUpdate(status=sending)
  ↓
SyncStep
  ↓
POST /api/v1/chat/message
  ↓
本地合并服务端返回，status=success
```

## 7.2 图片/视频/音频/文件消息

```text
选择媒体
  ↓
本地创建 ChatUiModel
  ↓
PersistStep（本地路径/资源持久化）
  ↓
ImageProcessStep / VideoProcessStep（按类型处理）
  ↓
UploadStep（上传到 /api/v1/chat/upload-token 对应 CDN）
  ↓
SyncStep（POST /api/v1/chat/message）
  ↓
服务端入库
```

## 7.3 收消息链路

```text
服务端 socket dispatch(chat_message)
  ↓
SocketService._handleDispatch()
  ↓
GlobalChatHandler 持久化入库
  ↓
ChatEventHandler 做当前会话已读/撤回处理
  ↓
UI 通过 LocalDatabase stream 自动刷新
```

---

## 8. Admin 客服端推荐架构

## 8.1 MVP 架构选型

> 建议先做 **HTTP 轮询版**，不要先做 Admin Socket。

原因：

1. 当前客户端发送本来就主要走 HTTP
2. Admin 当前代码完全未起步，先把业务跑通更重要
3. 客服场景对 5~10 秒级刷新通常可接受
4. 轮询版更容易审计和调试

### 推荐结构

```text
AdminCustomerServiceDesk
  ├── ConversationListPanel
  ├── ChatWindow
  │   ├── MessageList
  │   ├── MessageRendererFactory
  │   └── ReplyComposer
  ├── ConversationMetaPanel
  └── PollingController
```

### 轮询建议

| 区域 | 建议间隔 |
|---|---|
| 会话列表 | 15 秒 |
| 当前会话消息 | 5~10 秒 |
| 手动刷新 | 必须支持 |
| 页面聚焦时 | 立即刷新一次 |

---

## 8.2 Admin 页面核心交互

### 左侧：会话列表

展示：

- 用户头像
- 用户昵称
- 最后消息预览
- 最后消息时间
- 会话状态
- 是否已分配/分配给谁
- 待回复标识

### 中间：聊天窗口

展示：

- 历史消息
- 加载更早消息
- 文本 / 图片 / 视频 / 音频 / 文件 / 系统消息渲染
- 关闭会话按钮
- 强制撤回按钮
- 回复输入区
- 媒体上传按钮

### 右侧：会话元信息

展示：

- 用户信息
- 会话创建时间
- 首响时间
- 最后用户消息时间
- 最后客服回复时间
- 工单标签
- 分配状态

---

## 9. 媒体消息统一规范（Admin 必须遵守）

> 这一节是给 Admin 端做一致性用的。  
> 如果 Admin 客服台自己发图、发视频、发音频，却不遵守客户端当前字段规则，就一定会出现渲染不一致。

## 9.1 总原则

| 类型 | `content` | `meta` 重点字段 | 渲染规则 |
|---|---|---|---|
| image | 图片远程 URL 或 `uploads/...` | `w` `h` `blurHash` `fileName` `fileExt` | 图片走图片 CDN 缩放 |
| video | 视频远程 URL 或 `uploads/...` | `duration` `w` `h` `blurHash` `remote_thumb`/`thumb` | 视频主体直连，封面走图片 CDN |
| audio | 音频远程 URL 或 `uploads/...` | `duration` | 音频直连，不走图片 CDN |
| file | 文件远程 URL 或 `uploads/...` | `fileName` `fileSize` `fileExt` | 文件直链下载/打开 |

---

## 9.2 图片消息规范

### 真实客户端字段来源

- `ChatActionService.sendImage()`
- `ImageProcessStep`
- `UploadStep`
- `ImageMsgBubble`

### Admin 入库/发送时必须保证

```json
{
  "type": 1,
  "content": "uploads/chat/2026/03/xxx.jpg",
  "meta": {
    "w": 1080,
    "h": 1440,
    "blurHash": "...",
    "fileName": "photo.jpg",
    "fileExt": "jpg"
  }
}
```

### 渲染规则

1. `content` 若是 `uploads/...`，先拼完整媒体域名
2. 图片列表缩略图必须走图片 CDN 缩放
3. 宽高比按 `w / h` 计算，建议 clamp 到 `[0.5, 2.0]`
4. 没有真实图前：
   - 优先 `previewBytes`（如果前端本地刚发送）
   - 否则用 `blurHash`
5. 点击后打开原图/大图预览

### 重要说明

当前 Flutter `UrlResolver.resolveImage()` 会把图片交给 `RemoteUrlBuilder.imageCdn()` 处理。  
因此 Admin Web 侧也应该遵守：

- **图片缩略图走图片 CDN**
- **不要把视频/音频也套进图片 CDN**

---

## 9.3 视频消息规范

### 真实客户端字段来源

- `ChatActionService.sendVideo()`
- `VideoProcessStep`
- `VideoMsgBubble`
- `VideoProcessor`

### Admin 入库/发送时必须保证

```json
{
  "type": 3,
  "content": "uploads/chat/2026/03/video_xxx.mp4",
  "meta": {
    "w": 1280,
    "h": 720,
    "duration": 15,
    "blurHash": "...",
    "remote_thumb": "uploads/chat/2026/03/thumb_xxx.jpg",
    "thumb": "uploads/chat/2026/03/thumb_xxx.jpg"
  }
}
```

### 关键统一点

1. **当前代码里视频 `duration` 实际按秒使用**
   - `VideoProcessor` 产出 `durationSec`
   - `VideoMsgBubble._formatDuration(int seconds)` 按秒格式化

2. **封面字段优先级必须统一**

```text
meta.remote_thumb  >  meta.thumb  >  无封面
```

3. **视频主体不走图片 CDN**
   - `content` 直接拼完整媒体 URL
   - 仅封面图走图片 CDN 缩放

4. **封面没加载出来时用 `blurHash` 占位**

### Admin 渲染建议

- 封面宽度：240px 气泡
- 中间播放按钮
- 右下角显示 `MM:SS`
- 同一页面仅允许一个视频播放
- 双击/点击可进全屏播放器

---

## 9.4 音频消息规范

### 真实客户端字段来源

- `VoiceRecorderService.stop()`
- `ChatActionService.sendVoiceMessage()`
- `ChatMessageFactory.voice()`
- `VoiceBubble`

### 当前代码真实情况

`VoiceRecorderService.stop()` 返回的是：

```dart
final duration = DateTime.now().difference(startTime).inSeconds;
```

也就是说：

> **当前语音 `duration` 实际单位是秒，不是毫秒。**

### Admin 入库/发送时必须保证

```json
{
  "type": 2,
  "content": "uploads/chat/2026/03/voice_xxx.m4a",
  "meta": {
    "duration": 8
  }
}
```

### 渲染规则

1. `content` 拼完整媒体 URL 后直接播放
2. 气泡宽度可按 duration 动态扩展
3. 格式可显示为：
   - `8''`
   - 或 `00:08`
4. 同一页面只允许一条语音同时播放

### 波形一致性问题

当前 Flutter `VoiceBubble` 的静态波形是这样生成的：

- 用 `message.id.hashCode` 作为随机种子
- 生成 12 根柱子的高度

这意味着：

- Admin Web 如果想“视觉接近”，可以复用“按 messageId 伪随机生成波形”的策略
- 但 **Dart 的 `hashCode` 与 JS 不一定严格一致**

### 推荐做法

#### MVP

- Admin 先做“固定 12 柱伪随机波形”即可

#### 更强一致

- 服务端在 `meta.waveform` 中保存波形数组
- Flutter 与 Admin 共用同一组波形数据

> 如果后面你们要求“Admin 发出的语音，在客户端和后台波形完全一致”，那就应该升级到 `meta.waveform` 方案。

---

## 9.5 URL 解析统一规则

### 图片

- 输入：`uploads/...` 或完整 URL
- 输出：图片 CDN 缩放 URL

### 视频 / 音频 / 文件

- 输入：`uploads/...` 或完整 URL
- 输出：完整媒体 URL
- **不要**再包一层图片 CDN

### 推荐伪代码

```ts
function resolveMediaUrl(content: string, imgBaseUrl: string) {
  if (!content) return '';
  if (content.startsWith('http://') || content.startsWith('https://')) return content;
  return `${imgBaseUrl}/${content.replace(/^\//, '')}`;
}

function resolveImageUrl(content: string, imgBaseUrl: string, width = 240) {
  const full = resolveMediaUrl(content, imgBaseUrl);
  const uploadsIndex = full.indexOf('uploads/');
  if (uploadsIndex < 0) return full;
  const key = full.slice(uploadsIndex);
  return `${imgBaseUrl}/cdn-cgi/image/width=${width},quality=75,f=auto,fit=scale-down/${key}`;
}
```

---

## 10. Admin 客服端逻辑规划

## 10.1 会话状态

建议先统一为：

| 状态 | 值 | 含义 |
|---|---|---|
| Active | `1` | 正常接待中 |
| Closed | `2` | 已关闭 |

### 状态流转

```text
用户发起 SUPPORT 会话
  ↓
Active
  ↓
客服领取/分配
  ↓
Active
  ↓
客服关闭
  ↓
Closed
  ↓
若用户再次发消息，可自动 reopen
```

---

## 10.2 回复逻辑

### 文本回复

1. 校验会话存在且为 `SUPPORT`
2. 校验 Admin 权限
3. 解析当前客服身份映射
4. 写入 `ChatMessage`
5. 递增 `Conversation.lastMsgSeqId`
6. 更新 `lastMsgContent / lastMsgType / lastMsgTime`
7. 更新 `lastAgentReplyAt`
8. 如果会话已关闭则自动 reopen

### 媒体回复

1. Admin 前端先走上传接口获取远程 key
2. 前端或服务端生成必要 `meta`
3. 调用 Admin send-media 接口
4. 后端按统一字段结构入库
5. 用户端按现有客户端渲染逻辑即可展示

---

## 10.3 已读逻辑

MVP 阶段建议：

- Admin 侧先不做复杂双向已读 UI
- 重点做：
  - 新消息高亮
  - 会话级待回复提醒
  - 进入会话即视为客服已查看

第二阶段再补：

- 客服已读水位
- 用户已读水位
- 最后一条客服消息是否已被用户阅读

---

## 10.4 撤回逻辑

### 用户端当前已有

- 普通撤回：`POST /api/v1/chat/message/recall`
- 客户端本地 2 分钟内可撤回

### Admin 端建议

- 保留普通撤回
- 增加强制撤回 `force-recall`
- 强制撤回用于：
  - 敏感词
  - 发错图
  - 违规内容

---

## 11. 实施计划

## Phase 0：先冻结契约

目标：先把“说法统一”解决掉，避免 Admin 做出来和客户端不一致。

### 要确认的 5 件事

- [ ] 客服身份使用“虚拟 User”还是“原生 AdminSender”
- [ ] `official_platform_support_v1` 是否继续作为唯一客服 businessId
- [ ] 视频/音频 `duration` 单位统一定为秒，还是全链路改毫秒
- [ ] 视频封面字段统一优先级 `remote_thumb > thumb`
- [ ] 是否引入 `meta.waveform`

> 这一步不做，后面前后端一定返工。

---

## Phase 1：后端能力对齐（状态更新）

- [x] `chat.module.ts` 已落地（模块编排 + 事件监听 + 上传能力）
- [x] `chat.controller.ts` 已落地（会话/消息/上传/设置）
- [x] `chat.service.ts` 已落地（发送、撤回、已读、转发等主链路）
- [x] `chat-group.controller.ts` 已落地（踢人/禁言/转让/审批/搜索）
- [x] `chat-group.service.ts` 已落地（权限校验 + 事务 + 系统消息 + 事件）
- [ ] Admin 接待台专用 API 待补（会话分配、SLA、工单筛选）
- [ ] Admin 侧强制撤回/关闭重开的后台管理策略待定稿

---

## Phase 2：Admin Web 接待台 MVP

- [ ] 左侧会话列表
- [ ] 当前会话聊天窗口
- [ ] 文本回复
- [ ] 图片/视频/音频/文件渲染
- [ ] 图片上传/发送
- [ ] 视频上传/发送
- [ ] 音频上传/发送
- [ ] 关闭会话
- [ ] 强制撤回
- [ ] 轮询刷新

---

## Phase 3：运营能力增强

- [ ] 快捷回复
- [ ] 标签体系
- [ ] 优先级
- [ ] SLA 首响/平均响应时长
- [ ] 分配/转接
- [ ] 会话搜索
- [ ] 待回复筛选

---

## Phase 4：更强一致性/性能优化

- [ ] Admin Socket 实时版
- [ ] 原生 `AdminSender` 模型
- [ ] `meta.waveform` 统一波形
- [ ] 已读回执 UI
- [ ] 多客服协同占用提醒
- [ ] 会话监控大屏

---

## 12. 最终建议

### 当前最稳妥的落地顺序

1. **先按现有客户端契约做 Admin MVP**
2. **客服消息第一期不要使用 `senderId = null` 普通文本方案**
3. **媒体字段严格对齐 Flutter 当前实现**
4. **Admin 先上 HTTP 轮询版，不急着做 Socket**
5. **如果追求音频波形完全一致，再引入 `meta.waveform`**

### 用一句话总结

> 现在不是“聊天能力没有”，而是“客户端已经成型，但 Admin 客服端还停留在 schema + 文档层”，真正缺的是 **Admin 身份建模、Admin Chat API、接待台 UI、以及媒体契约统一**。

---

## 13. 交付清单（建议按此拆任务）

### 后端

- [ ] Admin Chat Module
- [ ] Conversation list API
- [ ] Messages API
- [ ] Reply API
- [ ] Send-media API
- [ ] Force recall API
- [ ] Close/reopen API
- [ ] Assign API
- [ ] 审计日志

### 前端 Admin

- [ ] `/im` 客服接待台页面
- [ ] 会话列表组件
- [ ] 消息渲染工厂
- [ ] 文本输入组件
- [ ] 媒体上传组件
- [ ] 图片预览/视频播放/音频播放
- [ ] 轮询控制器

### 数据与契约

- [ ] 客服身份方案定稿
- [ ] media meta 字段定稿
- [ ] duration 单位定稿
- [ ] 封面字段优先级定稿
- [ ] 是否新增 waveform 字段定稿

---

## 14. 前端缺口补充（后端已完成前提）

> 本节用于回答：**如果后端能力已就绪，Flutter 前端还差什么**。  
> 结论：不只是“秒杀 + 抽奖”，还包含**客服分流落地（business/support）**。

### 14.1 目前已对上的能力（代码已存在）

- 客服入口 API 已接：`GET /api/v1/chat/business?businessId=...`（`Api.chatBusinessApi`）
- 会话类型模型已具备：`BUSINESS` / `SUPPORT`（`ConversationType`）
- 下单主链路已具备：`orders/checkout`（`OrdersCheckoutParams` + `purchaseProvider`）
- 拼团列表/详情接口已在后端控制器存在：
  - `GET /client/groups/list`
  - `GET /client/groups/:groupId`
  - 见 `admin/group.controller.ts`（App 侧 list 强制 `GROUP_STATUS.ACTIVE`）

### 14.2 前端 P0 待办（必须先做）

1. **抽奖链路落地（Lucky Draw）**
   - 新增 Flutter API：
     - `GET /api/v1/lucky-draw/my-tickets`
     - `POST /api/v1/lucky-draw/tickets/:ticketId/draw`
     - `GET /api/v1/lucky-draw/my-results`
   - 新增页面/路由：抽奖券列表、抽奖执行页、历史结果页。
   - 下单成功后的抽奖券引导（可从 `OrderCheckoutResponse.lotteryTickets` 衔接）。

2. **秒杀链路落地（Flash Sale）**
   - 商品/详情页补齐秒杀态展示：秒杀价、倒计时、库存、活动结束态。
   - 结算参数补齐秒杀透传字段（如 `flashSaleProductId`，以服务端 contract 为准）。
   - 支付页与订单页价格文案统一（原价/秒杀价/优惠叠加顺序）。

3. **客服分流参数化（Support vs Business）**
   - `CustomerServiceHelper.startChat()` 改为支持场景参数，不再写死 `official_platform_support_v1`。
   - 统一入口策略：
     - 平台客服问题 -> `support`
     - 商家/业务咨询 -> `business`（按 businessId）
   - 会话列表增加标签或过滤，避免 support/business 混淆。

### 14.3 前端 P1 待办（建议紧随其后）

- 订单页客服入口携带上下文（订单号、商品ID、问题类型）到消息 `meta`，降低客服定位成本。
- 抽奖与订单状态联动文案统一（待开奖/已开奖/未中奖）。
- 秒杀活动结束、库存不足、价格变更时的统一错误提示与回退策略。

### 14.4 联调验收标准（DoD）

- 抽奖：用户可完成“看券 -> 抽奖 -> 看历史结果”闭环，且重复点击抽奖有幂等保护。
- 秒杀：下单请求带秒杀标识，服务端按秒杀价结算，前端价格展示与订单结果一致。
- 客服分流：同一用户可按场景进入不同客服会话，列表与路由可正确区分 `support/business`。

### 14.5 一句话结论

> 在“后端已完成”的前提下，前端至少还需完成三件事：**抽奖闭环、秒杀闭环、客服分流参数化**；否则 Admin 侧与客户端会出现流程和数据不一致。

---

*EOF*

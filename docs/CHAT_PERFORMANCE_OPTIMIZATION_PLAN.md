# Chat 模块性能与体验优化计划

> **创建日期**：2026-04-03
> **覆盖范围**：`ChatActionService` · `ChatViewModel` · `ChatPage` · `pipeline_steps` · `OfflineQueueManager`
> **分析方法**：静态代码审查 + 数据流追踪

---

## 总览

| # | 问题 | 优先级 | 风险 | 影响范围 | 状态 |
|---|------|--------|------|---------|------|
| P1 | 进入聊天页面出现 Skeleton 空白 | 🔴 高 | 🟢 低 | `ChatViewModel` `ChatPage` | ✅ 已修复 |
| P2 | 图片上传前被压缩两次 | 🔴 高 | 🟡 中 | `ChatActionService` `GlobalUploadService` | ✅ 已修复 |
| P3 | 图片文件字节被 I/O 读取两次 | 🟡 中 | 🟢 低 | `ChatActionService` `PipelineContext` | ✅ 已修复 |
| P4 | `_sessionPathCache` 静态 Map 永不清理 | 🟡 中 | 🟢 低 | `ChatActionService` | ✅ 已修复 |
| P5 | `UploadStep` 跨步骤调用私有方法 | 🟡 中 | 🟡 中 | `pipeline_steps.dart` | 🗓 待排期 |
| P6 | 离线队列全串行，文本消息恢复慢 | 🟢 低 | 🟡 中 | `OfflineQueueManager` | 🗓 待排期 |
| ➖ | 减少每条媒体消息的 DB patch 次数 | ❌ 暂不做 | 🔴 高 | pipeline 全流程 | — |
| 附A | 视频初始缩略图质量过低 (quality:30) | 🟢 低 | 🟢 低 | `ChatActionService.sendVideo` | ✅ 已修复 |
| 附B | `forwardMessage` 无离线/错误兜底 | 🟢 低 | 🟢 低 | `ChatActionService` | 🗓 待排期 |
| 附C | `_compressMobile` 路径切割方式不安全 | 🟢 低 | 🟢 低 | `ImageCompressionService` | ✅ 已修复 |

---

## P1 — 进入聊天页面出现 Skeleton 空白

### 现象
每次进入任意聊天页面，内容区会先出现空白 + 顶部转圈圈，等待约 300ms~1s 后才渲染出消息列表，体验差。

### 根因分析

**调用链追踪**：
```
ChatViewModel 构造函数
  ├── super(ChatListState())          // messages: [], isInitializing: false
  └── _init()
        ├── _subscribeToStream()      // 注册 Sembast 响应式流（异步，不立即触发）
        └── performIncrementalSync()
              └── state = copyWith(isInitializing: true)   // ← 立刻置 true
              └── await Api.chatMessagesApi(...)           // 等网络...
```

**在 `chat_page.dart` 的渲染逻辑**：
```dart
// Line 108: AppBar 小菊花条件
isSyncing: chatState.isInitializing && messages.isEmpty

// Line 129: 空状态文字（仅 isInitializing = false 时显示）
if (messages.isEmpty && !chatState.isInitializing) {
  return Center(child: Text("No messages yet"));
}
// 否则渲染列表，itemCount = 1，只渲染 _buildLoadingIndicator（转圈）
```

**结论**：`isInitializing: true` 被**同步**设置，而 Sembast 响应式流**需要 `await database` 才能发出第一帧**（异步），导致第一帧必然是 `messages: []` + `isInitializing: true` → 空白转圈。即使本地有历史记录也会如此。

### 修复方案

在 `_init()` 开头插入一次直接的本地 DB 读取，把历史消息在第一帧就装载到 state。网络 Sync 继续在后台静默执行。

```dart
// chat_view_model.dart
void _init() async {
  // 第一步：直接读本地历史，保证第一帧有内容
  try {
    final cached = await _repo.getHistory(
      conversationId: conversationId,
      limit: _currentLimit,
    );
    if (cached.isNotEmpty && mounted) {
      state = state.copyWith(messages: cached);
    }
  } catch (_) {}

  // 第二步：订阅响应式流（处理后续增量更新）
  _subscribeToStream();

  // 第三步：后台静默网络同步（WeChat 风格 AppBar 小菊花）
  performIncrementalSync();
}
```

AppBar spinner 改为：
```dart
// 有内容时也显示小菊花，表示"正在同步新消息"（Telegram/WeChat 风格）
isSyncing: chatState.isInitializing
```

### 效果对比

| 场景 | 修改前 | 修改后 |
|------|--------|--------|
| 有历史消息 | 空白 + 大转圈 → 等网络 | **立即渲染本地消息** + AppBar 小菊花 |
| 新会话（无记录）| 空白 + 大转圈 | 空白 + 大转圈（保持现有行为） |
| 网络断开时 | 空白卡住 | **立即渲染本地缓存消息** |

---

## P2 — 图片上传前被压缩两次

### 现象
发送图片时耗时异常，图片最终质量低于预期（约 64%），压缩耗时翻倍。

### 根因分析

```
sendImage(file)
  ├── [1] ImageCompressionService.compressForUpload(file)
  │         → FlutterImageCompress: maxWidth=1920, quality=80  ← 第一次压缩
  │
  └── uploadChatFile(processedFile)
        └── GlobalUploadService.uploadFile(processedFile)
              └── [2] ImageUtils.compressImage(processedFile.path)
                        → FlutterImageCompress: maxWidth=1920, quality=80  ← 第二次！
```

实际质量 = 80% × 80% ≈ **64%**，且两次产生临时文件。

### 修复方案

`GlobalUploadService.uploadFile` 新增 `skipCompression` 参数；`uploadChatFile` 传入 `true`，因为 Chat 模块已预压缩。

```dart
// GlobalUploadService - 新增参数，默认 false 不影响其他调用方
Future<String> uploadFile({
  ...
  bool skipCompression = false,
}) async {
  if (!skipCompression && !kIsWeb) {
    // 仅在未跳过时执行压缩
  }
}

// ChatActionService - Chat 场景跳过二次压缩
Future<String> uploadChatFile(XFile file) {
  return _uploadService.uploadFile(
    file: file,
    module: UploadModule.chat,
    onProgress: (_) {},
    skipCompression: true,
  );
}
```

---

## P3 — 图片文件字节被 I/O 读取两次

### 现象
发送图片时，同一张图的文件内容被从磁盘读取了两次，增加不必要的 I/O 时间。

### 根因分析

```
sendImage(file)
  ├── [第1次读取] getTinyThumbnail(processedFile)
  │         → processedFile.readAsBytes() ← 读取完整文件字节
  │
  └── _runPipeline([..., ImageProcessStep(), ...])
        └── ImageProcessStep.execute(ctx)
              └── [第2次读取] XFile(path).readAsBytes()  ← 同一文件再次读取！
```

### 修复方案

`PipelineContext` 新增 `cachedFileBytes` 字段，`sendImage` 将读取到的字节缓存，`ImageProcessStep` 优先从缓存取用，避免第二次 I/O。同时在 `ImageCompressionService` 新增 `getTinyThumbnailFromBytes(Uint8List)` 方法，避免 Mobile 端重新写文件。

---

## P4 — `_sessionPathCache` 静态 Map 永不清理（内存泄漏）

### 现象
长时间使用 App 后，内存占用随聊天次数线性增长。

### 根因分析

```dart
static final Map<String, String> _sessionPathCache = {};

// 只有写入，永不删除：
_sessionPathCache[msg.id] = processedFile.path;  // sendImage
_sessionPathCache[msg.id] = fileToUse.path;       // sendVideo
_sessionPathCache[msg.id] = msg.localPath!;       // sendFile
```

静态 Map 生命周期为 App 整个会话。高频用户一天可累积数百条永不释放的记录。

### 修复方案

在 `SyncStep` 完成后（消息已成功同步，本地路径持久化到 DB），主动调用 `cleanupSentMessageCache` 释放对应条目。

```dart
// ChatActionService - 新增实例方法
void cleanupSentMessageCache(String msgId) {
  _sessionPathCache.remove(msgId);
}

// SyncStep - 同步成功后执行清理
await service.repo.patchFields(ctx.initialMsg.id, updates);
service.cleanupSentMessageCache(ctx.initialMsg.id);  // 内存清理
```

---

## P5 — `UploadStep` 跨步骤调用私有方法（封装破坏）

> **状态**：待排期（第三阶段）

### 根因
```dart
// pipeline_steps.dart L271 — UploadStep 直接实例化 RecoverStep 并调用其私有方法
final found = await RecoverStep()._tryFindLocalFile(uploadPath, ctx.initialMsg.type);
```

### 修复方向
将 `_tryFindLocalFile` 提取为 `MediaPathResolver` 工具类的静态方法，`RecoverStep` 和 `UploadStep` 共同调用，消除跨步骤耦合。

---

## P6 — 离线队列全串行，文本消息恢复慢

> **状态**：待排期（第三阶段）

### 根因
```dart
for (var msg in pendingMessages) {
  bool success = await _resendViaPipeline(msg);  // 串行
  await Future.delayed(const Duration(milliseconds: 500));  // 固定节流（文本消息不需要）
}
```

10 条失败文本消息串行 = 至少 **5 秒**追发时间。

### 修复方向
按消息类型分组：文本/位置类使用 `Future.wait` 并发批处理；图片/视频/文件类保持串行 + 节流以避免 OOM。

---

## ❌ 不建议改动：减少 DB patch 次数

### 原因
每条图片消息在 pipeline 中产生约 5 次写入，理论上可以合并减少，但每个步骤独立 patch 是**断点容错的基础**：

- `UploadStep` 崩溃时，`PersistStep` 和 `ImageProcessStep` 的进度（本地路径、BlurHash）已持久化
- `resend()` 恢复时，`RecoverStep` 能从 DB 读取中间状态继续执行

合并写入将破坏"断点续传"能力，风险不可控。**维持现状。**

---

## 附录 A — 视频初始缩略图质量过低

```dart
// 修改前：quality: 30（非常模糊）
quickPreview = await VideoCompress.getByteThumbnail(fileToUse.path, quality: 30);

// 修改后：quality: 55（清晰度与文件大小的平衡点）
quickPreview = await VideoCompress.getByteThumbnail(fileToUse.path, quality: 55);
```

---

## 附录 B — `forwardMessage` 无离线兜底

> **状态**：待排期

转发消息目前仅 `rethrow`，网络断开时静默失败。建议接入 `ErrorHandler.withErrorHandling()` 或在 UI 层加 Toast 提示。转发为一次性操作，不需要进离线队列。

---

## 附录 C — `_compressMobile` 路径切割不安全

```dart
// 修改前：路径含多个 '.' 时切割错误
// 例：/data/1.2/image.png → 被切割到 /data/1
final String outPath = "${filePath.split('.').first}_opt_...jpg";

// 修改后：使用 path 包安全处理
import 'package:path/path.dart' as p;
final String outPath = "${p.withoutExtension(filePath)}_opt_${DateTime.now().millisecondsSinceEpoch}.jpg";
```

`path` 包已在项目中引用，零新增依赖。

---

## 实施记录

### ✅ 2026-04-03 第一、二阶段全部完成

- [x] **P1** — `ChatViewModel._init()` 预热本地数据 + AppBar spinner 条件调整
- [x] **P2** — `GlobalUploadService.skipCompression` 参数 + `uploadChatFile` 跳过二次压缩
- [x] **P3** — `PipelineContext.cachedFileBytes` 字段 + `ImageCompressionService.getTinyThumbnailFromBytes` + `ImageProcessStep` 优先使用缓存
- [x] **P4** — `cleanupSentMessageCache` 方法 + `SyncStep` 完成后主动清理
- [x] **附A** — 视频缩略图质量 30 → 55
- [x] **附C** — `_compressMobile` 改用 `p.withoutExtension` 安全路径处理

### 🗓 第三阶段（待排期）
- [ ] P5 — 提取 `MediaPathResolver` 工具类
- [ ] P6 — 离线队列按消息类型分组并发处理
- [ ] 附B — `forwardMessage` 错误提示

---

*文档维护：每完成一项，在对应条目前更新状态标记和完成日期。*


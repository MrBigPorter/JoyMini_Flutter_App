# HLS 方案评估报告

## 🔑 关键发现：你的代码已经做了一半"HLS的事"

```
VideoProcessor.dart line 117:
'-movflags +faststart'  ← ✅ 已存在！MOOV atom 已移至文件头
```

`-movflags +faststart` 是 MP4 格式能做的"范围请求快速启动"的核心。  
这意味着 **P0 服务端工作实际上已经完成了**。

---

## 🏗️ Cloudflare 的两个产品 ≠ 同一个东西

| 产品 | 作用 | 是否支持 HLS |
|------|------|-------------|
| **Cloudflare R2** | S3 兼容的对象存储（你现在用的） | ❌ 只存文件，不转码 |
| **Cloudflare Stream** | 视频流媒体服务（另一个产品） | ✅ 自动转码为 HLS |

你上传代码里用的是 `S3/R2 PUT`，**R2 不会自动生成 HLS**。  
要用 HLS 必须：
- **方案A**：改成 Cloudflare Stream API 上传（换掉整个上传流程，独立计费 ~$5/千分钟存储）
- **方案B**：服务端 Worker / Lambda 在上传后触发 FFmpeg 转码生成 `.m3u8 + .ts` 分片，再存回 R2

两种方案都需要 **后端改造 + 消息格式变更**，工作量 3-5 天。

---

## ❌ 为什么 HLS 对你的场景性价比低

| 对比维度 | 聊天短视频（你的场景） | HLS 发光的场景 |
|---------|------------------|-------------|
| 视频时长 | 5-30 秒 | >2 分钟的长视频 |
| 文件大小 | <20MB，已压缩 | >100MB 高清大文件 |
| 用户行为 | 单次从头播完 | 随机跳转/拖进度条 |
| 网络适应 | 一个码率就够 | 多码率自适应才有价值 |

**结论：HLS 是为长视频/直播设计的，短消息视频用 HLS 是大炮打蚊子。**

---

## ✅ 真正高 ROI 的优化：3 个 Quick Win

### P0（1小时，已有基础设施，改一行）
**Bug：`VideoMsgBubble` 创建控制器时没用 `VideoPlaybackService`！**

```dart
// 现在（错的）：VideoMsgBubble._togglePlay()
_controller = VideoPlayerController.networkUrl(Uri.parse(url));
//                                                         ↑ 没有 Range header！

// 正确：复用 VideoPlaybackService.createController()
_controller = VideoPlaybackService().createController(url);
//                                                    ↑ 自动加 Range: bytes=0- header
```

效果：`controller.initialize()` 时间减少 **20-40%**（HTTP 206 Partial Content，只下载 MOOV atom）

---

### P1（半天，效果最显著）
**视口预热：用户滚到视频附近时就开始 initialize，点击时直接播放**

```dart
// 用 VisibilityDetector 检测视频进入屏幕
VisibilityDetector(
  onVisibilityChanged: (info) {
    if (info.visibleFraction > 0.3) {
      _prewarm(); // 静默 initialize，不播放
    }
  },
  child: VideoMsgBubble(...)
)
```

效果：点击播放延迟从 1-3s → **<100ms**（用户感受是"秒播"）

---

### P1（半天，解决"回滚重看"慢的问题）
**LRU 控制器池：keep-alive 最近 3 个初始化过的控制器**

```dart
// 不再在 _onGlobalPlayChanged 里 dispose，
// 改成 pause + 放入 LRU pool
// 下次看同一条消息时直接从池子取
```

效果：滚动回看已看过的视频延迟从 1-3s → **<50ms**

---

## 📋 建议执行顺序

```
本次 sprint（今天能做完）：
  Step 1: Fix VideoMsgBubble 使用 VideoPlaybackService  [1小时]
  Step 2: 视口预热 VisibilityDetector               [半天]
  Step 3: LRU 控制器池                               [半天]

下个 sprint（如果还有性能问题）：
  考虑 Cloudflare Stream HLS（需要后端参与）
```

**预期效果**：3 个 Quick Win 完成后，视频首播延迟降低 70-80%，
成本零增加，无需后端改造，可今天上线。

---

## 💡 如果你坚持要做 HLS

最低成本路径：
1. 服务端：视频上传后触发 FFmpeg Worker，生成 HLS 分片存 R2
2. 消息格式：`content` 字段改存 `.m3u8` URL
3. Flutter：检测 `.m3u8` URL，改用 `better_player` 或 `video_player` + HLS 数据源

估时：后端 2-3 天 + Flutter 1 天，适合下一个迭代规划。

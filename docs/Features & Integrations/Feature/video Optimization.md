# 三个 Fix 工作原理详解

## 架构总览

```
用户滚动聊天列表
       │
       ▼
  VisibilityDetector ← Fix 2: 视口监控
  (每个 VideoMsgBubble)
       │ visibleFraction ≥ 0.3
       │
       ▼
  400ms 防抖 Timer
  (快速滚动不触发，只有用户"停留"才触发)
       │ Timer fires
       │
       ▼
  _prewarm() ─────────────────────────────────────────┐
       │                                               │
       ├─ Pool HIT? ─── 是 ──► 直接 setState(_controller = pooled)
       │                       ⚡ 0ms, 无网络请求
       │
       ├─ Pool MISS → _svc.createController(url) ← Fix 1: Range header
       │                    │
       │                    ▼
       │              controller.initialize()
       │              HTTP 206: 只下载 MOOV atom (~几KB)
       │                    │
       │                    ▼
       │              setState(_controller = ctrl)  ← 静默完成，UI无变化
       │
       └─ 用户发现视频不感兴趣，继续滚动
                 │
                 ▼  visibleFraction < 0.1
            Timer.cancel() ← 未触发则取消，不浪费带宽


用户点击播放按钮 (_togglePlay)
       │
       ├─ _controller != null && isInitialized? ── YES ──► play() 立即播放 ⚡ <50ms
       │   (Pre-warm 已完成 or Pool 命中)
       │
       └─ NO (从未进入视口的视频) ──► 正常初始化流程
                 │
                 ▼
           _buildController(url)
                 │
                 ├─ Pool HIT? ──► 返回已初始化控制器 ⚡ 0ms
                 │
                 └─ MISS → _svc.createController(url) ← Fix 1: Range header
                               ▼
                          HTTP 206 initialize()


另一个视频被播放 (_onGlobalPlayChanged)
       │
       ▼   旧逻辑: controller.dispose() → 下次重看要重新下载
       │
       ▼   新逻辑: Fix 3 — pool.put(msgId, controller)
                 │
                 ▼
         _VideoControllerPool (LRU, max 3)
         ┌─────────────────────────────┐
         │ msgId_A → controller (paused) │  ← MRU
         │ msgId_B → controller (paused) │
         │ msgId_C → controller (paused) │  ← LRU (下一个被 evict)
         └─────────────────────────────┘
              │
              ▼ 用户滚回去重看 msgId_A
         pool.get('msgId_A') → 返回已初始化控制器
         play() ⚡ 立即播放，0ms 延迟
```

---

## Fix 1: Range Header — 减少首次 initialize() 时间

| | 之前 | 之后 |
|--|------|------|
| HTTP 请求 | GET (下载整个文件才能解析) | GET + `Range: bytes=0-` |
| 服务器响应 | 200 OK + 全部数据 | 206 Partial Content + MOOV atom 部分 |
| 等待时间 | 等整个 MP4 MOOV atom 被下载 | MOOV 在头部，几 KB 即可开始 |
| 改动 | `VideoPlayerController.networkUrl(Uri.parse(url))` | `VideoPlaybackService().createController(url)` |

**关键前提**: `VideoProcessor` 已经用了 `-movflags +faststart`，MOOV atom 在文件头部 ✅

---

## Fix 2: 视口预热 — 消除首次点击延迟

```
Timeline (用户滚到视频):

T+0ms    VisibilityDetector: fraction=0.45 → 启动 400ms 定时器
T+400ms  定时器触发 → _prewarm() 开始
T+600ms  initialize() 完成 (后台静默)
T+800ms  用户点击 → _controller.isInitialized == true → 立即播放 ⚡

vs. 之前:
T+0ms    用户点击 → 开始 initialize()
T+800ms  initialize() 完成 → 开始播放  (用户等了 800ms)
```

**防抖的意义**: 如果用户在 400ms 内滑过了这个视频，Timer 被 cancel，不会触发 initialize() — 不浪费带宽。

---

## Fix 3: LRU 控制器池 — 消除"回看"延迟

```
容量: max 3 个 (平衡内存与命中率)
数据结构: LinkedHashMap (插入顺序 = LRU 顺序，O(1) get/put)

pool.put(id, ctrl):          pool.get(id):
┌─ 已满? 驱逐 keys.first      ┌─ remove(id) 找到?
│    └─ lru.pause().dispose() │    └─ 重新插入到尾部(MRU)
└─ ctrl.pause()               └─ 返回 ctrl (无需 initialize)
   _pool[id] = ctrl
```

**内存影响**: 3 个 VideoPlayerController 各持有一个 platform 解码器 buffer，
约 5-15 MB 额外内存（可通过 kIsLowEndDevice 检测来动态调整 _maxSize）。

---

## 预期效果

| 场景 | 之前 | 之后 |
|------|------|------|
| 首次点击 (视口内停留 >0.5s) | 1-3s 转圈 | <50ms 秒播 |
| 首次点击 (快速滚到后点击) | 1-3s 转圈 | 300-600ms (Range 优化) |
| 滚回去重看 (pool hit) | 1-3s 转圈 | 0ms 立即播放 |
| 切换视频后上一个 | 重新下载 | 池中暂存，回看免费 |

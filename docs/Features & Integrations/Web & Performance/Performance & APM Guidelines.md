

# 👑 JoyMini 性能与高可用治理手册 (Performance & APM Guidelines) v12.0

## 1. 治理愿景与性能红线 (Overview & Baselines)

JoyMini 的业务形态对终端性能提出了极高的要求。为了保障千万级用户在低端机及弱网环境下的流畅体验，系统设立了三大不可逾越的性能红线：

1. **首屏白屏时间 (FP / FCP)**：严禁超过 100ms（目标 0ms 瞬间直出）。
2. **列表滑动帧率 (FPS)**：复杂商品与通讯列表必须稳定在 60 FPS，杜绝快速滑动时的“白块”与“卡顿”。
3. **静止态 CPU 功耗**：当页面不发生交互时，即使存在上百个倒计时，CPU 占用率必须无限趋近于 0%。

---

## 2. 极速首屏与 SWR 混合缓存基座 (Zero-White-Screen & SWR)

传统的 Loading 菊花图极大地破坏了电商 App 的沉浸感。JoyMini 引入了 **SWR (Stale-While-Revalidate)** 架构，实现了“数据等用户，而非用户等数据”。

### 2.1 多态持久化引擎 (`ApiCacheManager`)

* **底层分流策略**：
  在 `api_cache_manager.dart` 中，针对编译环境实施物理降级策略：
* **Native 端 (iOS/Android)**：采用 `Hive` 二进制序列化引擎，实现磁盘到内存的零延迟吞吐。
* **Web (WASM) 端**：避开 Web 环境下的 Hive 崩溃绝症，自动降级采用 `SharedPreferences`，并通过 `_boxName` 前缀隔离业务空间。


* **业务落地**：系统启动的首帧，直接从本地存储同步读取并反序列化数据，实现页面 0 毫秒构建。

### 2.2 Riverpod 静默防抖 (`skipLoadingOnReload`)

* 在 `HomePage` 与 `ProductPage` 的核心瀑布流中，`AsyncValue` 的渲染强制开启 `skipLoadingOnRefresh: true` 与 `skipLoadingOnReload: true`。
* **效果**：后台静默拉取网络数据的同时，前台界面保持旧数据的完美渲染。当新数据到达时，执行原子化的原地差分比对替换，彻底消灭了刷新导致的屏幕闪烁。

---

## 3. 高频渲染收敛与 CPU 功耗治理 (CPU & Repaint Governance)

在拼团大厅（`GroupLobby`）与商品瀑布流中，动辄同时存在上百个倒计时组件。如果每个组件自带一个 `Timer` 并触发 `setState`，主线程将被瞬间击穿。

### 3.1 全局单例心跳同步 (`_Heartbeat` 引擎)

* **核心实现**：在 `render_countdown.dart` 中剥离出底层的 `_Heartbeat`。全 App 只消耗一个物理 `Timer.periodic`，维持 1Hz 的脉冲。
* **毫秒级物理对齐**：系统在初始化时，通过计算偏移量 `1000 - now.millisecond`，将心跳信号精准对齐到下一秒的起始点。这确保了页面上几百个倒计时文字在同一毫秒内同步跳变，极大地提升了视觉高级感。

### 3.2 `ValueListenable` 局部防波及机制

* 所有的 `RenderCountdown` 组件放弃了粗暴的 `setState`，改为通过 `ValueListenableBuilder` 监听心跳流。
* **效果**：每秒的心跳只重绘 Builder 内部的文字节点，组件外层的卡片容器、图片、阴影等节点完全不参与重绘树（Render Tree）的计算，彻底释放了 CPU。

### 3.3 图层物理隔离 (`RepaintBoundary`)

* 针对详情页（`detail_sections.dart`）中高度消耗 GPU 的富文本 HTML 组件（`HtmlWidget`）以及复杂的 Canvas 自定义绘制阴影（`CardPainter`），强制包裹 `RepaintBoundary`。
* **原理**：将高耗能节点打成独立的渲染图层（Layer），确保周围的高频动效（如金光扫过、红点跳动）不会污染静态重型资产的缓存池。

---

## 4. 瀑布流视口预加载与显存提速 (Predictive Loading)

长图文列表高速滑动时，图片解码速度跟不上滑动速度，会导致满屏“白块”。JoyMini 自研了滚动感知引擎。

### 4.1 滚动感知预加载器 (`ScrollAwarePreloader`)

* **视口偏移探测**：在 `scroll_aware_preloader.dart` 中，抛弃了性能极差的 `VisibilityDetector`。利用轻量级的 `NotificationListener<ScrollNotification>` 监听像素级位移。
* **动态切片解码**：根据当前滑动位置计算出 `_lastStartIndex`，并结合 `preloadWindow` (通常设定为提前 15-30 张)。
* **静默压入显存**：将视窗外的图片 URL 提前通过 `CachedNetworkImageProvider` 交给底层解码。当用户真实滑到该商品时，图片已从 GPU 显存中直接提取并渲染，做到了真正的物理级丝滑。

### 4.2 列表底座的预渲染拓展 (`cacheExtent`)

* 在 `ProductPage` 的 `CustomScrollView` 中，强制开启了 `cacheExtent: 1500`（约等于向下多渲染 2-3 屏的虚拟高度）。配合 `ScrollAwarePreloader`，确立了“资源先行，渲染在后”的立体提速网络。

---

## 5. 高可用与内存防渗漏机制 (Memory Leak Prevention)

内存泄漏在长时间挂机的 IM/金融 App 中是致命的。

1. **`MethodChannel` 弱引用护盾**：
* 跨端调用极易产生僵尸对象。在 iOS 原生桥接层（`AppDelegate.swift`），所有回调闭包强制采用 `[weak self, weak controller]`；在 Android 层（`MainActivity.kt`），`pendingResult` 一旦响应（`success` 或 `error`）必须立刻置为 `null` (用完即焚)。


2. **鉴权自毁生命周期**：
* 如前所述，`OrderListCacheProvider` 深度依赖鉴权状态。不依赖人工手动 GC（垃圾回收），借由状态树的崩塌自然销毁常驻内存的大型 Map。


3. **断网信令堆积拦截**：
* Socket 采用 `onSyncNeeded` 机制，重连时直接执行 HTTP 全量补偿，而不是盲目处理断网期间积压的上万条过期推送，防止重连瞬间引发前端内存爆仓 (OOM)。



---


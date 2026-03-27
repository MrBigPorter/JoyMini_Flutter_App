

# 👑 JoyMini 顶层架构白皮书 (Top-Level Architecture Blueprint) v12.0

## 1. 架构概述 (Architecture Overview)

JoyMini 并非一个普通的展示型 App，而是一个深度融合了**“即时通讯 (IM)”、“高并发拼团 (Social E-commerce)”**与**“金融级钱包 (Wallet)”**的跨端级工业基座。

本架构设计的核心愿景是：

* **多端一致性 (Platform Parity)**：一套代码完美支撑 iOS、Android 以及 Web (WASM) 运行，且物理隔离底层差异。
* **状态确定性 (State Determinism)**：物理级消灭状态不同步、多账号串流、以及金融计算精度丢失的风险。
* **毫秒级感官 (Millisecond UX)**：通过 SWR 架构、视口预加载与局部重绘隔离，在万级列表与高频通讯下死守 60 FPS。

---

## 2. 系统上下文与边界 (System Context)

JoyMini 客户端不作为孤立节点存在，而是整个分布式生态的前端神经末枢。

* **主干通信 (Main API)**：基于 HTTP/HTTPS 的 Restful 服务，承载核心交易、用户鉴权与商品数据。客户端由 `UnifiedInterceptor` 实施全局 Token 调度与排队无感刷新。
* **信令隧道 (WebSocket & FCM)**：
* **Socket.io**：提供低延迟的全双工通道，支撑 `group_update` (拼团状态) 与 `chat_message` (聊天流) 的毫秒级热替换。
* **FCM (Firebase)**：提供系统级离线通道。不仅处理常规推送，更承载 `call_invite` 音视频底层握手信令，直接唤醒原生 CallKit。


* **合规与硬件网关 (Native Integrations)**：
* **AWS Amplify Liveness**：桥接原生层进行 3D 活体防伪拦截。
* **Google ML Kit / VisionKit**：接管终端硬件算力，实现证件 OCR 的离线降噪与预解析。


* **运维与基建层 (DevOps)**：通过 Shorebird 建立 OTA 热更通道，通过 Telegram Bot 闭环 CI/CD 交付状态。

---

## 3. 核心分层模型 (Layered Architecture)

项目严格遵循**领域驱动设计 (DDD)**与**单一职责原则 (SRP)**，将系统划分为五层，严禁跨层级反向调用。

### 3.1 展现层 (Presentation / UI Layer)

* **定位**：纯粹的视觉渲染器。
* **实现**：`Widget` 不包含任何异步网络请求或数据计算。通过监听 Provider 获取状态，通过触发 Logic 层的方法执行动作。
* **防线**：全域采用 `RepaintBoundary` 物理隔离高频动效（如倒计时、骨架屏），并由 Design Token (`design_tokens.g.dart`) 锁定像素级视觉主权。

### 3.2 逻辑控制层 (Controller / Logic Layer)

* **定位**：UI 与状态之间的业务中枢。
* **实现**：采用 `Mixin` 模式（如 `WithdrawPageLogic`, `OrderItemLogic`）。接管表单响应式校验 (Reactive Forms)、路由跳转、弹窗调度以及向 State 层发起 `Action`。
* **收益**：将动辄千行的 UI 页面拆解，使得业务流转逻辑具备可读性与单测可行性。

### 3.3 状态管理层 (State Management Layer - The Brain)

* **定位**：全局数据的唯一事实来源 (Single Source of Truth)。
* **实现**：基于 **Riverpod 2.0** (`AsyncNotifier`, `Provider`) 构建。利用响应式图（Reactive Graph）机制管理 SWR (Stale-While-Revalidate) 缓存流与脏标记自愈链条。

### 3.4 领域数据与防腐层 (Domain / DTO Layer)

* **定位**：防御后端异构脏数据的护盾。
* **实现**：所有实体（如 `OrderItem`, `KycMe`）强制开启 `checked: true`。部署强类型转换器（如 `JsonNumConverter`），确保从后端进入内存的数据 100% 符合预期，物理拦截空指针与类型漂移（如 String 变 int）引发的白屏。

### 3.5 物理与基础设施层 (Infrastructure Layer)

* **定位**：与硬件、磁盘、网络的直接对话者。
* **实现**：
* **存储**：`ApiCacheManager` (Hive / SharedPreferences 智能分流) 与 Sembast (本地 IM 消息库)。
* **网络**：`http_adapter_factory.dart` (条件导出解决跨端冲突)。
* **桥接**：`MethodChannel` 封装类，处理双端原生硬件交互。



---

## 4. 关键架构决策记录 (ADR - Architecture Decision Records)

### ADR-001：抛弃 GetX，拥抱 Riverpod 2.0 响应式基座

* **背景**：应用内存在极其复杂的跨页面状态联动（如：支付成功 -> 刷新余额 -> 刷新流水列表 -> 标记首页更新）。
* **决策**：引入 Riverpod 2.0 构建状态树。
* **收益**：
* **编译期安全**：避免了 GetX 字符串寻址或 Provider 树层级找不到的运行时崩溃。
* **鉴权自毁机制**：通过 `ref.watch(authProvider)`，使所有内存敏感缓存（如订单列表）在用户登出时被 Riverpod 引擎自动垃圾回收，物理消灭了“多账号串流”绝症。



### ADR-002：突破 GoRouter 限制，自研类型安全编解码器 (CommonExtraCodec)

* **背景**：GoRouter 原生不支持跨页面传递复杂自定义对象（会导致刷新后对象丢失或 DeepLink 崩溃）。
* **决策**：在 `extra_codec.dart` 中建立基于 `BaseRouteArgs` 的注册表模型，并在 Router 底层挂载自定义 Codec。
* **收益**：实现了在路由压栈时自动注入 `__type__` 指纹并序列化，使得 `ProductListItem` 等庞大实体在页面间能够 100% 无损穿透，且完美兼容 Web 端的 URL 分享。

### ADR-003：采用 SWR (Stale-While-Revalidate) 终结全屏 Loading

* **背景**：常规网络请求会导致页面短暂白屏或转圈，极大地影响了电商与社交的沉浸感。
* **决策**：通过封装 `ApiCacheManager` 结合 Riverpod 的 `AsyncValue`，确立 SWR 加载范式。
* **收益**：路由进入瞬间（0ms）使用磁盘缓存构建高保真 UI，同时后台静默并发拉取最新数据。新数据到达后通过对象的差异比对，仅在底层数据发生变化时执行局部重绘（`skipLoadingOnReload`）。

### ADR-004：基于 Mixin与适配器的复杂列表治理 (PageListViewPro)

* **背景**：Flutter 原生 `ListView` 在处理下拉刷新、上拉加载、错误兜底、骨架屏时会导致 UI 代码急剧膨胀（动辄上千行）。
* **决策**：剥离 `PageListController` 状态机，结合 `PageListViewPro`，并在业务层引入 `toUiModel()` 适配器模式（如 `TransactionUiModel`）。
* **收益**：彻底解耦了 UI 渲染与分页控制，实现了“不管后端给什么异构流水数据，前端一律洗成同构模型渲染”，代码复用率提升 80%。

---

## 5. 架构级铁律 (Golden Rules)

为了保障代码库在团队扩张和长期演进中的纯洁性，设立以下架构级红线，任何人不可逾越：

1. **金融精度不可篡改**：所有涉及资金、比例、门槛的 DTO 字段，严禁使用原生 `double` 解析，必须强挂载 `@JsonKey(fromJson: JsonNumConverter.toDouble)`。
2. **UI 无头脑原则**：`build()` 方法内严禁出现超过 3 行的复杂业务计算。所有判断（如 `canRequestRefund`）必须内聚在 Model 的 `get` 方法中，所有行为副作用必须托管在 `Logic` 或 `Notifier` 中。
3. **设计主权系统生成**：严禁在 UI 中手写如 `Color(0xFF0000)` 或 `height: 24`。所有设计参数必须通过 `gen_tokens_flutter.dart` 从 Figma 源文件中编译生成，捍卫多端视觉对齐的绝对主权。


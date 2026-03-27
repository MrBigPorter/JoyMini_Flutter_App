
---

# 👑 JoyMini 核心领域设计文档 (Core Domain Design) v12.0

## 1. 概述

在 JoyMini 的复杂业务中，UI 只是表象，真正的护城河在于底层对“状态”和“数据”的绝对控制。本文档基于领域驱动设计（DDD），对系统内最核心的三大业务域（Domain）的边界、聚合根（Aggregate Root）及流转状态机进行深度规约。

---

## 2. 领域一：金融与交易链路 (Financial & Transaction Domain)

本领域涵盖钱包余额、充值提现、订单结算等高危业务。核心诉求是**“精度零丢失、状态无感自愈、支付沙盒绝对闭环”**。

### 2.1 实体防腐与精度护盾 (Anti-Corruption Layer)

* **痛点**：Dart 的 `double` 类型在处理跨平台 JSON 解析时，极易因后端返回数据类型漂移（如 `"10.00"` 变 `10`）导致崩溃，且容易出现浮点数计算精度溢出。
* **架构决议**：
* **类型物理锁**：所有交易实体（如 `Payment`, `OrderItem`, `UserCoupon`）强制开启 `@JsonSerializable(checked: true)`。
* **精度转换算子**：强制挂载自定义工厂 `JsonNumConverter.toDouble`。
* **原则**：后端哪怕吐出脏数据，进入内存前也会被强制清洗为强类型，确立了前端在资产显示上的“绝对主权”。



### 2.2 智能结算与套利状态机 (Smart Checkout Engine)

* **设计落脚点**：`PaymentPageLogic` (`payment_page_logic.dart`)。
* **业务闭环**：
* **静默寻优算法**：进入结算页时，系统自动执行 `_autoMatchBestCoupon`，遍历 `myValidCoupons` 寻找满足 `minPurchase` 门槛且 `discountValue` 最高的优惠券并自动挂载。
* **门槛熔断保护**：利用 Riverpod 建立反应式监听 `listenAndValidateCoupon`。当用户修改购买件数导致 `subtotal < minPurchase` 时，系统触发物理撤回，防止带错误金额请求后端导致 400 异常。



### 2.3 脏标记自愈与沉浸式刷新 (Dirty Flag Healing)

* **痛点**：用户提现或充值后，回到列表页如果直接拉取全量接口，会导致列表跳动和屏幕闪烁。
* **架构决议**：
* **引入靶向失效流**：`TransactionRecordPage` 挂载 `transactionDirtyProvider(UiTransactionType)`。
* **流转过程**：在 `WithdrawPageLogic` 中提现成功后，首行代码将 `withdraw` 的 Dirty 标记置为 `true`。当用户 Pop 回流水页时，UI 层感知到“脏数据”，静默触发 `_ctl.refresh(clearList: false)`。
* **结合 `PageStorageKey**`：实现了状态的“原地热替换”，视觉上列表滚动位置纹丝不动，但最新的处理中（Processing）记录已平滑插入。



### 2.4 支付沙盒劫持引擎 (Payment Sandbox Interception)

针对 GCash/Maya 等第三方支付不可控的网页跳出问题，建立双轨拦截：

* **Native 端**：`PaymentWebViewPage` 中通过 `InAppWebView` 实施 UA 指纹伪装。在 `shouldOverrideUrlLoading` 阶段，物理拦截 `success_url`，强行 `Replacement` 回原生结果页。
* **Web (WASM) 端**：利用 `dart:js_interop`。开启 `Window.closed` 与 `MessageEvent` 双重监听，使得外部 Tab 关闭的瞬间，Flutter 引擎能毫秒级接管状态机并进入轮询核对机制。

---

## 3. 领域二：IM 与拼团大厅实时同步 (Real-time Sync Domain)

本领域解决成千上万人同时在大厅拼团、聊天时，如何保障 UI 的 60FPS 满帧运行而不被海量信令击穿。

### 3.1 静默热替换算法 (Silent Hot-Swap)

* **设计落脚点**：`GroupLobbyLogic` (`group_lobby_logic.dart`)。
* **问题**：传统做法是收到 `group_update` 信令就 `setState` 或 `refresh` 整个列表，在千人并发下会导致严重的 CPU 负载和画面撕裂。
* **架构决议**：
* **原子化定点更新**：监听底层推送后，通过 `indexWhere` 锁定特定 `groupId` 所在的卡片。
* **时间戳幂等防线**：对比 `serverUpdatedAt` 与当前对象的 `updatedAt`。只有在确认是新信令时，才通过 `copyWith` 构建新对象并覆盖原 Index。整个列表不重绘，仅目标卡片内部触发重构，实现物理级丝滑。



### 3.2 物理重连自愈协议 (Reconnection Calibration)

* **问题**：移动端经过电梯、地铁断网后，Socket 漏接了期间的更新信令。
* **架构决议**：深度绑定底层 Socket 的生命周期。一旦 `_socketService.onSyncNeeded` 发射信号（意味着网络从断开到重连），大厅立马执行 `listCtl.refresh()` 发起一次全量 Http 拉取。贯彻了**“重连即校准”**的铁律。

---

## 4. 领域三：鉴权与内存主权治理 (Auth & Memory Governance Domain)

本领域的唯一目标是：**绝对禁止 A 账号看到 B 账号的私人数据**。在电商/金融 App 中这是 P0 级（最高级）的红线。

### 4.1 鉴权驱动的缓存自毁机制 (Auth-Bound Cache Purging)

* **设计落脚点**：`OrderList` (`order_list.dart`) 等含有敏感数据的分页中枢。
* **实现方案**：
```dart
final orderListCacheProvider = Provider<Map<String, PageResult<OrderItem>>>((ref) {
  // 核心护城河：强制监听认证状态
  ref.watch(authProvider.select((s) => s.isAuthenticated));
  return {}; // 一旦未登录或切换账号，旧 Map 直接灰飞烟灭
});

```


* **原理解析**：利用 Riverpod 2.0 的依赖追踪图（Dependency Graph）。当用户点击“退出登录”或 Token 失效导致 `authProvider` 状态变更时，由于 `orderListCacheProvider` 依赖了它，系统会立即丢弃旧的 Provider 实例，从而触发内部缓存 Map 的物理销毁。
* **结果**：消灭了由于“开发人员忘记在 logout() 方法里手动清空各个变量”而导致的跨账号数据串流绝症。

### 4.2 拦截器 UI 零耦合原则 (Decoupled Interceptor)

* **设计落脚点**：`Bootstrap.setupInterceptors` (`bootstrap.dart`)。
* **架构决议**：
  传统的 Dio 拦截器在处理 401 登出时，经常需要依赖当前的 `BuildContext` 去弹窗或跳路由，导致“路由已销毁但回调触发”的红屏崩溃。
  本项目强制要求：拦截器中的 `onTokenInvalid` 严禁传递 Context。必须通过全局单例的 `ProviderContainer` 容器，直接调用底层 `authNotifier.logout()`。由数据层的变动，自然驱动上层 UI 层路由（GoRouter Redirect）的重定向。

---

### 5. 架构边界红线 (Domain Boundaries)

1. **逻辑内聚红线**：UI 的 `build` 树中绝对不允许出现状态判定逻辑（如 `if (status == 3 && payStatus == 1)`），必须封装在 DTO 内部作为 `get` 属性（如 `item.canRequestRefund`）。
2. **跨域隔离红线**：交易域（Wallet/Payment）的状态更新，严禁直接去调用 UI 域的接口。必须通过修改对应的 `DirtyProvider`（脏标记），让 UI 域自行决定在“合适的时机（如页面可见时）”去刷新。

---

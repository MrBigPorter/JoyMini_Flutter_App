# 👑 JoyMini Core Domain Design Document v12.0

## 1. Overview

In JoyMini's complex business, UI is just the surface; the real moat lies in the absolute control of "state" and "data" at the底层. This document, based on Domain-Driven Design (DDD), provides deep specifications for the boundaries, aggregate roots, and state machines of the three core business domains (Domains) in the system.

---

## 2. Domain One: Financial & Transaction Domain

This domain covers wallet balance, deposit/withdrawal, order settlement, and other high-risk businesses. The core诉求 is **"zero precision loss, state self-healing, payment sandbox absolute closure"**.

### 2.1 Entity Anti-Corruption and Precision Shield

* **Pain Point**: Dart's `double` type极易因后端返回数据类型漂移 (e.g., `"10.00"` becomes `10`) when processing cross-platform JSON parsing, leading to crashes, and easily出现浮点数计算精度溢出.
* **Architecture Decision**:
  * **Type Physical Lock**: All transaction entities (e.g., `Payment`, `OrderItem`, `UserCoupon`) enforce `@JsonSerializable(checked: true)`.
  * **Precision Conversion Operator**: Enforce custom factory `JsonNumConverter.toDouble`.
  * **Principle**: Even if backend spits dirty data, it's forced to clean into strong type before entering memory, establishing frontend's "absolute sovereignty" in asset display.

### 2.2 Smart Checkout and Arbitrage State Machine

* **Design Anchor**: `PaymentPageLogic` (`payment_page_logic.dart`).
* **Business Closure**:
  * **Silent Optimization Algorithm**: When entering checkout page, system automatically executes `_autoMatchBestCoupon`,遍历 `myValidCoupons` to find coupons满足 `minPurchase` threshold且 `discountValue` highest并自动挂载.
  * **Threshold熔断 Protection**: Use Riverpod to建立 reactive monitoring `listenAndValidateCoupon`. When user修改 purchase quantity导致 `subtotal < minPurchase`, system触发 physical withdrawal, preventing带错误金额请求后端导致 400 exception.

### 2.3 Dirty Flag Self-Healing and Immersive Refresh

* **Pain Point**: After user withdraws or deposits, returning to list page if直接拉取全量接口,会导致列表跳动和屏幕闪烁.
* **Architecture Decision**:
  * **Introduce Targeted Invalidation Flow**: `TransactionRecordPage`挂载 `transactionDirtyProvider(UiTransactionType)`.
  * **Flow Process**: In `WithdrawPageLogic` after successful withdrawal, first line of code将 `withdraw` Dirty flag置为 `true`. When user Pop回流水页, UI layer感知到"脏数据", silently触发 `_ctl.refresh(clearList: false)`.
  * **Combined with `PageStorageKey`**: Achieves "in-place hot-swap" of state, visually list scroll position纹丝不动, but latest processing record已平滑插入.

### 2.4 Payment Sandbox Hijacking Engine

For third-party payments like GCash/Maya不可控的网页跳出问题, establish dual-track interception:

* **Native端**: In `PaymentWebViewPage`,实施 UA fingerprint spoofing through `InAppWebView`. In `shouldOverrideUrlLoading` phase, physically intercept `success_url`,强行 `Replacement` back to native result page.
* **Web (WASM)端**: Use `dart:js_interop`.开启 `Window.closed` and `MessageEvent` dual monitoring,使得 external Tab关闭的瞬间, Flutter engine能 millisecond-level接管 state machine and进入 polling verification mechanism.

---

## 3. Domain Two: IM and Group Lobby Real-time Sync Domain

This domain solves how to ensure UI's 60FPS full-frame operation when thousands of people simultaneously lobby group buy and chat, without被海量信令击穿.

### 3.1 Silent Hot-Swap Algorithm

* **Design Anchor**: `GroupLobbyLogic` (`group_lobby_logic.dart`).
* **Problem**: Traditional approach is to `setState` or `refresh` entire list upon receiving `group_update` signaling, causing severe CPU load and screen tearing under thousand-person concurrency.
* **Architecture Decision**:
  * **Atomic Targeted Update**: After monitoring底层 push,通过 `indexWhere`锁定 specific `groupId`所在卡片.
  * **Timestamp Idempotent Defense**: Compare `serverUpdatedAt` with current object's `updatedAt`. Only when确认是 new signaling,才通过 `copyWith`构建 new object并覆盖原 Index. Entire list不重绘, only target card内部触发重构, achieving物理级丝滑.

### 3.2 Physical Reconnection Self-Healing Protocol

* **Problem**: After mobile端经过 elevator, subway断网, Socket漏接了期间的 update signaling.
* **Architecture Decision**: Deeply bind底层 Socket's lifecycle.一旦 `_socketService.onSyncNeeded`发射 signal (meaning network从断开到重连), lobby立即执行 `listCtl.refresh()`发起一次全量 Http pull.贯彻了**"重连即校准"**的铁律.

---

## 4. Domain Three: Authentication and Memory Sovereignty Governance Domain

This domain's唯一目标是: **绝对禁止 A 账号看到 B 账号的私人数据**. In e-commerce/financial App, this is P0-level (highest) red line.

### 4.1 Authentication-Driven Cache Self-Destruction Mechanism

* **Design Anchor**: `OrderList` (`order_list.dart`) and other pagination hubs containing sensitive data.
* **Implementation**:
```dart
final orderListCacheProvider = Provider<Map<String, PageResult<OrderItem>>>((ref) {
  // Core moat: enforce monitoring authentication state
  ref.watch(authProvider.select((s) => s.isAuthenticated));
  return {}; //一旦未登录或切换账号, old Map直接灰飞烟灭
});
```
* **Principle**: Use Riverpod 2.0's dependency tracking graph. When user clicks "logout" or Token失效导致 `authProvider` state change,由于 `orderListCacheProvider`依赖了它, system立即丢弃 old Provider instance,从而触发 internal cache Map的物理销毁.
* **Result**: Eliminates cross-account data leakage绝症 caused by "developers forgetting to manually clear various variables in logout() method".

### 4.2 Interceptor UI Zero-Coupling Principle

* **Design Anchor**: `Bootstrap.setupInterceptors` (`bootstrap.dart`).
* **Architecture Decision**:
  Traditional Dio interceptors在处理 401 logout时,经常需要依赖 current `BuildContext`去弹窗或跳路由,导致"路由已销毁但回调触发"的红屏崩溃.
  This project enforces: interceptors中的 `onTokenInvalid`严禁传递 Context. Must通过全局单例的 `ProviderContainer`容器,直接调用底层 `authNotifier.logout()`.由数据层的变动,自然驱动上层 UI层路由 (GoRouter Redirect)的重定向.

---

### 5. Architecture Boundary Red Lines

1. **Logic Cohesion Red Line**: UI的 `build`树中绝对不允许出现状态判定逻辑 (e.g., `if (status == 3 && payStatus == 1)`), must封装在 DTO内部作为 `get`属性 (e.g., `item.canRequestRefund`).
2. **Cross-Domain Isolation Red Line**: Transaction domain (Wallet/Payment) state updates严禁直接去调用 UI domain接口. Must通过修改对应的 `DirtyProvider` (脏标记),让 UI domain自行决定在"合适的时机 (e.g., page visible时)"去刷新.

---
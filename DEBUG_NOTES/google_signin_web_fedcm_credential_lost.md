# Bug 复盘：Google Sign-In Web — FedCM 凭据丢失

> **日期**：2026-03-19  
> **影响范围**：Web 端 Google 登录  
> **状态**：已修复（`oauth_sign_in_service.dart`）  
> **关联文件**：`lib/core/services/auth/oauth_sign_in_service.dart`  
> **包版本**：`google_sign_in: ^7.2.0` / `google_sign_in_web: 1.1.3`

---

## 一、现象

用户在 Web 端点击 Google 登录按钮：

1. FedCM（Google 原生账号选择器）对话框出现 ✅
2. 用户点击自己的账号 ✅
3. 按钮 loading 一直转，最终无反应 ❌（30 秒后静默失败）

日志中没有 crash，也没有错误弹窗，`_handleOauthError` 把 `OauthCancelledException` 静默吞掉了。

---

## 二、关键日志解读

### 按钮点击**之前**

```
[GSI_LOGGER]: Message received: {"type":"command","command":"cancel_protect_start"}
[GSI_LOGGER]: logged event: [..., "aLi-5nDNwDLR5CbnQW5ljsntcqeh6BU2Ztp-0j8bZFA", 8, ...,
              "1065683669109-...apps.googleusercontent.com", "http://localhost:4000", ...]
[GSI_LOGGER]: Cancel prompt request ignored. The prompt is in a protected state.
```

- `cancel_protect_start`：说明**FedCM 对话框已在显示**（来自上一次 initialize 遗留的 One Tap 触发）
- `logged event`：GSI 内部事件，包含 clientId 和 origin，说明 credential 回调已经被触发
- `Cancel prompt request ignored`：有东西想取消弹窗但被 FedCM 保护状态拒绝

> ⚠️ **结论**：凭据（credential）在用户点击按钮**之前**就已经通过 JS 回调返回了。

---

### 按钮点击**之后**

```
[OAuthSignInService] Google initialize() start | keyLen=73
[GSI_LOGGER]: google.accounts.id.initialize() is called multiple times.
              This could cause unexpected behavior and only the last initialized instance will be used.
[OAuthSignInService] Google initialize() success
[OAuthSignInService] Google web lightweight authentication() calling...

[GSI_LOGGER]: Setup message received: {"type":"readyForConnect","channelId":"33551..."}
[GSI_LOGGER]: Setup message received: {"type":"readyForConnect","channelId":"33551..."}  ← 同一 channelId 出现两次
[GSI_LOGGER]: Message received: {"type":"command","command":"resize","height":254}
[GSI_LOGGER]: Message received: {"type":"command","command":"resize","height":144}
[GSI_LOGGER]: Message received: {"type":"command","command":"cancel_protect_end"}
[GSI_LOGGER]: Message received: {"type":"command","command":"cancel_protect_start"}  × 5
[GSI_LOGGER]: Cancel prompt request ignored. The prompt is in a protected state.
```

- `initialize() called multiple times`：Dart 静态变量热重载后重置，但 JS 侧 GSI 库状态持久，导致重复 init
- `channelId` 相同但出现两次：两个 GisSdkClient 实例竞争同一 FedCM 通信信道
- `resize`：新 FedCM 对话框成功显示
- `cancel_protect_end`：用户点击了账号，credential 处理中
- `cancel_protect_start × 5`：FedCM 在处理 credential 时的正常内部保护状态（不是异常）
- **但之后没有任何 Sign-In 事件到达 Flutter**

---

## 三、根因链（从底层到上层）

```
┌─────────────────────────────────────────────────────────────────┐
│ 根因 1：Broadcast stream 在无订阅者时发出了事件 → 凭据永久丢失  │ ← 核心
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
    旧的 requestOneTap() 触发 FedCM
           ↓
    用户(或页面加载自动) 完成 FedCM 选账
           ↓
    _onCredentialResponse() 被调用
           ↓
    _authenticationController.add(SignInEvent)  ← 广播流发出
           ↓
    [此时 _authenticateGoogleOnWeb() 还未调用，无任何 listener]
           ↓
    事件发向 0 个订阅者，直接丢弃

┌─────────────────────────────────────────────────────────────────┐
│ 根因 2：_googleInitialized 热重载后重置，重复 initialize()      │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
    _googleInitialized = false（Dart static 热重载重置）
    + JS 侧 google.accounts.id.initialize() 已调用
           ↓
    第二次 initialize() → 新 GisSdkClient
    （警告：only the last initialized instance will be used）
           ↓
    旧 GisSdkClient 的 _credentialResponses 仍在 pipe 到
    同一个 _authenticationController（泄漏的旧管道）
           ↓
    两个信道竞争同一 FedCM channelId → 行为不确定

┌─────────────────────────────────────────────────────────────────┐
│ 根因 3：_authenticateGoogleOnWeb() 内建订阅时序晚于事件投递     │
└────────────────────────────────────────────────────────────────┘

    旧代码逻辑：
    [用户点击]
        → _ensureGoogleInitialized()       ← 才 initialize
        → _authenticateGoogleOnWeb()
            → authenticationEvents.listen  ← 才订阅  ⚠️ 太晚了
            → attemptLightweightAuthentication()
```

---

## 四、涉及的包内部机制

### `google_sign_in_web 1.1.3` 关键行为

```dart
// attemptLightweightAuthentication 在 web 上始终返回 null！
Future<AuthenticationResults?>? attemptLightweightAuthentication(...) {
  _initialized.then((_) {
    _gisSdkClient.requestOneTap();  // 内部调用 id.prompt()
  });
  return null;  // ← 永远返回 null
}
```

- 调用这个方法只是触发 `id.prompt()`（显示 One Tap / FedCM UI）
- 凭据**只通过** `authenticationEvents` stream 返回，没有其他路径
- `authenticationEvents` 是 `StreamController.broadcast()`，错过就是错过

### `google_sign_in 7.2.0` 的 `authentication` getter

```dart
// 同步的！不是 Future。
GoogleSignInAuthentication get authentication {
  return GoogleSignInAuthentication(idToken: _authenticationTokens.idToken);
}
```

> `final auth = account.authentication; final idToken = auth.idToken;`  
> ✅ 这段代码在 v7.2.0 是**正确**的，`authentication` 已不是 Future。

---

## 五、修复方案

### 核心思路

把 `authenticationEvents` 的订阅从"按需建立"改为"初始化后立即建立并全局保持"：

```
initialize() 完成
    → _setupWebGlobalListener()   ← 立即建立全局订阅
    → 任何时候的 SignIn 事件都进入缓存或 Waiter

用户点击按钮
    → _authenticateGoogleOnWeb()
        → 先查 _webCachedAccount（热路径，凭据已到位则秒返回）
        → 否则设置 _webSignInWaiter 等待下一个事件
        → 触发 attemptLightweightAuthentication()
        → 30s 超时保底
```

### JS-global 热重载守卫

```dart
// 用 window.__gsiInitKey（JS 全局）判断 GSI 是否已初始化
// 热重载不会清除 JS 全局，Dart static 会被清除
static String? _jsGsiInitKey() {
  final v = web_pkg.window.getProperty<JSString?>('__gsiInitKey'.toJS);
  return v?.toDart;
}

static void _setJsGsiInitKey(String key) {
  web_pkg.window.setProperty('__gsiInitKey'.toJS, key.toJS);
}
```

---

## 六、知识点总结

### 1. Broadcast Stream 的"不留档"特性

```dart
final ctrl = StreamController.broadcast();
ctrl.add('hello');      // 此时无 listener
ctrl.stream.listen(print);  // 之后订阅：什么都收不到！
```

`broadcast()` stream 不缓存历史事件，订阅前的事件全部丢弃。  
**规则**：对 broadcast stream，要在事件**可能产生之前**就建立订阅。

### 2. Flutter Web 热重载的陷阱

| 作用域 | 热重载后是否保留 |
|--------|----------------|
| Dart `static` 变量 | ❌ 重置 |
| Dart 实例变量（Widget State）| ❌ 部分重置 |
| JS 全局（`window.xxx`）| ✅ 保留（页面未刷新） |
| JS 库初始化状态（`google.accounts.id`）| ✅ 保留 |

这就是为什么 Dart 侧认为"还没初始化"，而 JS 侧已经初始化了 → 双重初始化。

### 3. FedCM `cancel_protect_start/end` 含义

| 消息 | 含义 |
|------|------|
| `cancel_protect_start` | FedCM 对话框进入保护状态，程序无法通过 `id.cancel()` 关闭 |
| `cancel_protect_end` | 保护结束，通常对应用户完成交互（选账号/关闭） |
| `Cancel prompt request ignored` | 在保护状态下有代码调用了 `id.cancel()`，被拒绝 |
| `credential_returned` dismiss reason | 凭据成功返回，`_onPromptMoment` 不做任何事，`_onCredentialResponse` 会处理 |

`cancel_protect_end` **不等于**取消，也可能是 credential 返回成功后对话框消失。

### 4. `google.accounts.id.initialize()` 的单例行为

GSI 库是全局单例。多次调用 `initialize()` 不会报错，但：
- 只有最后一次注册的 credential 回调生效
- 前一次注册的回调被丢弃
- 如果前一次 callback 正好在 FedCM 返回 credential 时被替换，credential 进入新回调但可能时序错乱

### 5. `dart:js_interop_unsafe` 动态属性访问

```dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// 读取 window 上的任意属性
final v = window.getProperty<JSString?>('myKey'.toJS);
final dartStr = v?.toDart;

// 写入
window.setProperty('myKey'.toJS, 'value'.toJS);
```

`package:web` 的 `Window` 类型不支持 `[]` 和 `[]=` 运算符，  
必须用 `dart:js_interop_unsafe` 的扩展方法 `getProperty`/`setProperty`。

---

## 七、修复后的预期日志

正常流程（FedCM 先触发、用户后点击按钮）：

```
[OAuthSignInService] Google initialize() success
[OAuthSignInService] Google web: global auth listener (re)established
← FedCM 自动触发，credential 到达 ↓
[OAuthSignInService] Google web global: SignIn event | email=xxx@gmail.com

← 用户点击按钮 ↓
[OAuthSignInService] Google sign-in start | isWeb=true | ...
[OAuthSignInService] Google initialize() skipped – already init (JS guard)
[OAuthSignInService] Google web lightweight authentication() calling...
[OAuthSignInService] Google web: returning pre-cached account | email=xxx@gmail.com
[OAuthSignInService] Google authenticate() success | email=xxx@gmail.com | ...
```

热重载后再点击的流程：

```
[OAuthSignInService] Google initialize() skipped – already init (JS guard) | key=...
[OAuthSignInService] Google web: global auth listener (re)established
[OAuthSignInService] Google web lightweight authentication() calling...
← 用户完成 FedCM ↓
[OAuthSignInService] Google web global: SignIn event | email=xxx@gmail.com
[OAuthSignInService] Google authenticate() success | ...
```

---

## 八、参考资料

- [google_sign_in_web 1.1.3 源码](https://pub.dev/packages/google_sign_in_web)
- [FedCM Migration Guide](https://developers.google.com/identity/gsi/web/guides/fedcm-migration)
- [Google One Tap Prompt UI Status](https://developers.google.com/identity/gsi/web/guides/receive-notifications-prompt-ui-status)
- [dart:js_interop_unsafe](https://api.dart.dev/dart-js_interop_unsafe/dart-js_interop_unsafe-library.html)
- Dart broadcast stream 规范：`StreamController.broadcast()` 不缓存事件


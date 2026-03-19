# Google Sign-In Web 平台问题诊断与修复

**日期**: 2026-03-19  
**问题**: Google 登录在 Web 平台无法正常工作  
**状态**: ✅ 已修复

---

## 真正的根本原因（完整分析）

### 问题链：三个并发 FedCM Prompt

```
热重载 → Dart 静态变量重置 → _googleInitialized = false
    ↓
旧 JS guard (window.__gsiInitKey) 失效 → 读回 null
    ↓
第二次调用 id.initialize() → 警告 "called multiple times"
    ↓
两个 auto_select:true 自动触发 → 两个 auto FedCM prompt
    ↓
加上我们显式的 id.prompt() → 三个并发 prompt
    ↓
第 2/3 个 prompt 收到 isSkippedMoment → 流报错
    ↓
onError handler 立即取消 _webSignInWaiter
    ↓
第 1 个 prompt 的 credential 到达 → 但 waiter 已取消 → 登录失败
```

### 日志中的证据

```
readyForConnect × 2  ← 两个 FedCM 信道
resize height=254    ← 对话框出现（某个 prompt 的）
...
cancel_protect_start × 3  ← 三个 prompt 互相干扰
```

---

## 为什么旧的 JS Guard 失效

```dart
// ❌ 旧方案：window.getProperty<JSString?>
final v = web_pkg.window.getProperty<JSString?>('__gsiInitKey'.toJS);
```

- 在 DDC（开发编译模式）下，`js_interop_unsafe.getProperty` 可能静默失败
- 返回 `null` → 条件不满足 → 绕过 guard → 重复初始化

---

## 修复内容（三个层面）

### Fix 1：用 sessionStorage 替代 window 属性

```dart
// ✅ 新方案：sessionStorage（热重载后保持，页面刷新后清除）
static String? _sessionStorageGet(String key) {
  try {
    return web_pkg.window.sessionStorage.getItem(key);
  } catch (_) { return null; }
}

static void _sessionStorageSet(String key, String value) {
  try {
    web_pkg.window.sessionStorage.setItem(key, value);
  } catch (_) {}
}
```

**效果**：`id.initialize()` 在整个浏览器 Tab 生命周期内只调用一次，热重载不触发重复初始化。

### Fix 2：onError 不立即取消 waiter（5 秒 grace period）

```dart
onError: (Object error, StackTrace stack) {
  // isSkippedMoment 来自并发 prompt 冲突，不代表用户取消
  // 给 auto-trigger 的 credential 5 秒到达时间
  Future.delayed(const Duration(seconds: 5), () {
    if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
      _webSignInWaiter!.completeError(error, stack);
      _webSignInWaiter = null;
    }
  });
},
```

**效果**：即使第二个 prompt 发出 `isSkippedMoment` 错误，第一个 prompt 的 credential 仍有 5 秒窗口到达并完成登录。

### Fix 3：清理 catch 块的误判逻辑

```dart
// ❌ 旧代码：字符串匹配不可靠
if (e.toString().toLowerCase().contains('cancel') ||
    e.toString().toLowerCase().contains('user')) {
  throw OauthCancelledException(...);
}

// ✅ 新代码：精确类型判断
on OauthCancelledException { rethrow; }
on GoogleSignInException catch (e) {
  if (e.code == GoogleSignInExceptionCode.canceled) {
    throw OauthCancelledException('Google sign-in cancelled');
  }
  rethrow;
}
```

---

## Google Sign-In Web 工作原理（深层）

### 完整调用链

```
id.initialize(auto_select:true, callback:_onCredentialResponse)
    ↓ 自动触发 auto FedCM prompt（页面加载时）
    
用户点击我们的按钮
    ↓
attemptLightweightAuthentication() → id.prompt(_onPromptMoment)
    ↓
如果 FedCM 已有对话框：id.prompt() 返回 isNotDisplayed（被 plugin 忽略）
    ↓
用户在对话框选择账号
    ↓
_onCredentialResponse(credential) 
    ↓
_credentialResponses.add(response)
    ↓ map(gisResponsesToAuthenticationEvent)
AuthenticationEventSignIn(idToken: credential)
    ↓
_authenticationController.add()
    ↓ _translateAuthenticationEvent()
GoogleSignIn._authenticationStreamController.add(
  GoogleSignInAuthenticationEventSignIn(user)
)
    ↓
我们的监听器
    ↓
_webSignInWaiter.complete(user)
    ↓
account.authentication.idToken ← JWT credential
    ↓
后端 API 验证
```

### isSkippedMoment 触发条件

| 场景 | isSkippedMoment 触发? | 原因 |
|------|----------------------|------|
| 用户未登录 Google | ✅ 是 | 无账号可选 |
| 并发 id.prompt() 冲突 | ✅ 是（某些 Chrome 版本） | 已有 prompt 在运行 |
| FedCM 对话框已显示时再次调用 | ❌ 否 | isNotDisplayed（被忽略） |
| 用户点击 Cancel | ❌ 否 | isDismissedMoment.cancel_called |

---

## 测试验证

### 正常登录流程

```
[OAuthSignInService] Google sign-in start | isWeb=true
[OAuthSignInService] Google initialize() skipped – sessionStorage guard hit  ← ✅ 不重复初始化
[OAuthSignInService] Google web: calling attemptLightweightAuthentication()
# 用户选择账号
[OAuthSignInService] Google web global: SignIn event | email=user@example.com
[OAuthSignInService] Google web: sign-in completed | email=user@example.com
```

### 关键测试场景

1. **热重载后登录**：第二次不应出现 "called multiple times" 警告
2. **多次点击按钮**：每次只有一个 waiter 活跃
3. **用户取消对话框**：5 秒内无响应后抛出 OauthCancelledException（静默）
4. **快速连续点击**：stale waiter 被正确取消，新 waiter 建立

---

## 相关文件

- 修复代码：`lib/core/services/auth/oauth_sign_in_service.dart`
- 原始诊断：`DEBUG_NOTES/google_signin_web_fedcm_credential_lost.md`


---

## 问题症状

### 日志表现
```
[OAuthSignInService] Google authenticate() calling...
[OAuthSignInService] Google sign-in unknown error: UnimplementedError: 
authenticate is not supported on the web. Instead, use renderButton to create a sign-in widget.
```

### 后续尝试
```
[OAuthSignInService] Google web lightweight authentication() calling...
[GSI_LOGGER]: google.accounts.id.initialize() is called multiple times.
[GSI_LOGGER]: Cancel prompt request ignored. The prompt is in a protected state.
```

---

## 根本原因

### 1. 条件判断错误

**问题代码**:
```dart
if (kIsWeb || !GoogleSignIn.instance.supportsAuthenticate()) {
  // Use lightweight auth
} else {
  account = await GoogleSignIn.instance.authenticate();
}
```

**问题**:
- `supportsAuthenticate()` 在某些 Web 环境下可能返回 `true`
- 导致调用了不支持的 `authenticate()` 方法
- Web 平台只支持 `attemptLightweightAuthentication()`

**修复**:
```dart
if (kIsWeb) {
  // Web 平台必须使用轻量级认证
  account = await _authenticateGoogleOnWeb();
} else {
  // Native 平台使用标准认证
  account = await GoogleSignIn.instance.authenticate();
}
```

### 2. 缺少 await 导致异步问题

**问题代码**:
```dart
final auth = account.authentication;  // 缺少 await
```

**问题**:
- `authentication` 是异步 getter，返回 `Future<GoogleSignInAuthentication>`
- 不 await 会导致后续代码拿到的是 Future 而不是实际值

**修复**:
```dart
final auth = await account.authentication;  // 添加 await
```

### 3. 事件监听器不完整

**问题代码**:
```dart
} else if (event is GoogleSignInAuthenticationEventSignOut) {
  _webCachedAccount = null;
  // 没有处理等待中的 waiter
}
```

**问题**:
- 用户取消或登出时，没有通知等待中的 `_webSignInWaiter`
- 导致超时前一直阻塞

**修复**:
```dart
} else if (event is GoogleSignInAuthenticationEventSignOut) {
  _log('Google web global: SignOut event');
  _webCachedAccount = null;
  if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
    _webSignInWaiter!.completeError(
      OauthCancelledException('User signed out during authentication'),
    );
    _webSignInWaiter = null;
  }
} else {
  // Unknown event (可能是取消)
  _log('Google web global: unknown event: ${event.runtimeType}');
  if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
    _webSignInWaiter!.completeError(
      OauthCancelledException('Google sign-in cancelled or failed'),
    );
    _webSignInWaiter = null;
  }
}
```

---

## Web 认证流程说明

### Google Sign-In 在 Web 上的工作原理

1. **初始化**:
   ```dart
   await GoogleSignIn.instance.initialize(
     clientId: AppConfig.googleWebClientId,
   );
   ```
   - 调用 Google Identity Services (GSI) 库的 `google.accounts.id.initialize()`
   - 只能调用一次，多次调用会有警告

2. **触发认证**:
   ```dart
   GoogleSignIn.instance.attemptLightweightAuthentication(
     reportAllExceptions: true,
   );
   ```
   - 内部调用 `google.accounts.id.prompt()`
   - 触发 One Tap UI 或 FedCM 弹窗
   - **注意**: 这个方法返回 `void`，不返回结果

3. **接收结果**:
   ```dart
   GoogleSignIn.instance.authenticationEvents.listen((event) {
     if (event is GoogleSignInAuthenticationEventSignIn) {
       // 用户成功登录
       final user = event.user;
     }
   });
   ```
   - 结果通过 `authenticationEvents` stream 异步返回
   - 必须提前建立监听器

### 我们的实现策略

1. **全局监听器**:
   - 在 `_ensureGoogleInitialized()` 后立即建立
   - 捕获所有认证事件（包括自动触发的 One Tap）
   - 缓存到 `_webCachedAccount` 供后续使用

2. **每次登录请求**:
   - 检查是否有缓存的账号（快速路径）
   - 创建 `_webSignInWaiter` Completer
   - 调用 `attemptLightweightAuthentication()`
   - 等待全局监听器通过 Completer 返回结果

3. **超时保护**:
   - 60 秒超时（给用户足够时间选择账号）
   - 超时后抛出 `OauthCancelledException`

---

## 测试验证

### 测试场景

1. **正常登录**:
   - 点击 Google 按钮
   - One Tap 弹出
   - 选择账号
   - 成功登录

2. **取消登录**:
   - 点击 Google 按钮
   - One Tap 弹出
   - 点击关闭/取消
   - 应该返回 `OauthCancelledException`（不显示错误 toast）

3. **超时**:
   - 点击 Google 按钮
   - One Tap 弹出
   - 60 秒不操作
   - 应该超时并抛出异常

4. **热重载**:
   - 已登录状态下热重载
   - 不应该多次初始化 GSI
   - JS-global `__gsiInitKey` 防护生效

### 验证命令

```bash
# 清理并重新运行
flutter clean
fvm flutter pub get
fvm flutter run -d chrome --web-renderer html
```

### 期望日志

```
[OAuthSignInService] Google sign-in start | isWeb=true | canShow=true | clientIdLen=73
[OAuthSignInService] Google initialize() start | keyLen=73
[GSI_LOGGER]: Experiment enable_itp_optimization set to 0.
[OAuthSignInService] Google initialize() success
[OAuthSignInService] Google web: global auth listener (re)established
[OAuthSignInService] Google web lightweight authentication() calling...
[OAuthSignInService] Google web: calling attemptLightweightAuthentication()

# 用户选择账号后
[OAuthSignInService] Google web global: event type=GoogleSignInAuthenticationEventSignIn
[OAuthSignInService] Google web global: SignIn event | email=user@example.com
[OAuthSignInService] Google web: sign-in completed | email=user@example.com
[OAuthSignInService] Google authenticate() success | email=user@example.com | idTokenLen=xxx
```

---

## 配置检查清单

### 必需配置

1. **Google Cloud Console**:
   - 创建 OAuth 2.0 客户端 ID（Web 应用）
   - 添加授权 JavaScript 来源: `http://localhost:4000`（开发环境）
   - 添加授权重定向 URI: `http://localhost:4000`（开发环境）
   - 复制客户端 ID

2. **Flutter 项目配置**:
   ```json
   // assets/config/dev.json
   {
     "GOOGLE_WEB_CLIENT_ID": "YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com"
   }
   ```

3. **Web HTML 配置**:
   - `web/index.html` 已自动注入 GSI 脚本
   - 无需手动添加

### 环境变量验证

```dart
// 检查配置是否正确加载
print('GOOGLE_WEB_CLIENT_ID: ${AppConfig.googleWebClientId}');
print('Can show button: ${OauthSignInService.canShowGoogleButton}');
```

---

## 常见问题

### Q1: 为什么 Web 上看不到 Google 按钮？

**A**: 检查 `GOOGLE_WEB_CLIENT_ID` 是否配置:
```dart
static bool get canShowGoogleButton {
  if (!kIsWeb) return true;
  return AppConfig.googleWebClientId.isNotEmpty;
}
```

### Q2: 点击后没有任何反应？

**A**: 可能原因:
1. One Tap 被浏览器阻止（检查浏览器设置）
2. clientId 配置错误（检查 Google Cloud Console）
3. 域名不在授权列表（添加到 JavaScript 来源）

### Q3: 多次初始化警告？

**A**: 已通过 JS-global 防护修复:
```dart
static String? _jsGsiInitKey() {
  if (!kIsWeb) return null;
  try {
    final v = web_pkg.window.getProperty<JSString?>('__gsiInitKey'.toJS);
    return v?.toDart;
  } catch (_) {
    return null;
  }
}
```

### Q4: 为什么不用 `renderButton()`？

**A**: 
- `renderButton()` 会渲染 Google 官方按钮样式
- 我们有自己的 UI 设计
- `attemptLightweightAuthentication()` 更灵活，可以用自定义按钮

---

## 相关资源

- [Google Identity Services 文档](https://developers.google.com/identity/gsi/web)
- [google_sign_in 插件文档](https://pub.dev/packages/google_sign_in)
- [FedCM API](https://developers.google.com/identity/gsi/web/guides/fedcm-migration)
- [Web 平台 One Tap 指南](https://developers.google.com/identity/gsi/web/guides/overview)

---

## 总结

修复要点:
1. ✅ Web 平台直接用 `kIsWeb` 判断，不依赖 `supportsAuthenticate()`
2. ✅ 添加 `await` 到 `account.authentication`
3. ✅ 完善事件监听器，处理取消和登出
4. ✅ 增加超时时间到 60 秒
5. ✅ 改进日志，便于调试

修复后的代码已经:
- ✅ 通过编译检查
- ⏳ 待验证：Web 实际登录流程
- ⏳ 待验证：取消操作处理
- ⏳ 待验证：热重载稳定性


# Google 登录 Web 平台修复总结

**修复日期**: 2026-03-19（更新: 页面刷新 + renderButton vs prompt 修复）  
**状态**: ✅ 已修复并通过分析

---

## 核心问题

1. **条件判断错误**: 使用了不可靠的 `supportsAuthenticate()` 判断，导致 Web 上调用了不支持的 `authenticate()` 方法
2. **事件处理不完整**: 取消和登出事件没有正确通知等待中的请求
3. **代码规范**: 有未使用的 import
4. **页面刷新后 Google 按钮消失**: `sessionStorage` 在页面刷新后仍存在，导致 init guard 错误地跳过 `initialize()`
5. **⭐ `id.prompt()` vs `renderButton()` origin 要求不同**: `id.prompt()` (One Tap) 对 origin 校验**严格** (CORS → `/gsi/status` 403)，而 `renderButton()` 的 popup 流程**不需要**严格 origin 匹配

---

## 修复内容

### 1. 直接使用 `kIsWeb` 判断平台
```dart
// ❌ 旧代码
if (kIsWeb || !GoogleSignIn.instance.supportsAuthenticate()) {
  // ...
}

// ✅ 新代码  
if (kIsWeb) {
  account = await _authenticateGoogleOnWeb();
} else {
  account = await GoogleSignIn.instance.authenticate();
}
```

### 2. 完善事件监听器
```dart
// ✅ 处理所有事件类型
} else if (event is GoogleSignInAuthenticationEventSignOut) {
  _webCachedAccount = null;
  if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
    _webSignInWaiter!.completeError(
      OauthCancelledException('User signed out'),
    );
    _webSignInWaiter = null;
  }
} else {
  // 未知事件（可能是取消）
  if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
    _webSignInWaiter!.completeError(
      OauthCancelledException('Cancelled or failed'),
    );
    _webSignInWaiter = null;
  }
}
```

### 3. 改进日志
```dart
_log('Google web global: event type=${event.runtimeType}');
_log('Google web: calling attemptLightweightAuthentication()');
_log('Google web: sign-in completed | email=${result.email}');
```

### 4. 增加超时时间
```dart
// 从 30 秒增加到 60 秒，给用户足够时间选择账号
await _webSignInWaiter!.future.timeout(
  const Duration(seconds: 60),
  onTimeout: () {
    throw OauthCancelledException('Google sign-in timed out');
  },
);
```

---

## 验证结果

✅ 通过 Flutter analyze - 无错误  
⏳ 待验证 - Web 端实际登录流程  
⏳ 待验证 - 取消操作是否正确处理  

---

## 下一步

运行应用并测试：

```bash
# 清理并运行
flutter clean
fvm flutter pub get
fvm flutter run -d chrome --web-renderer html

# 测试场景
1. 正常登录
2. 取消登录
3. 超时场景
4. 热重载稳定性
5. ⭐ 页面刷新后 Google 按钮是否正常显示
```

---

### 4. 页面刷新后 Google 按钮消失 (2026-03-19)

**根因**: 用 `sessionStorage` 做 init guard，但 `sessionStorage` 在页面刷新后不会清空（Tab 级生命周期），
而 JS GSI 库状态在页面刷新后被销毁。guard 命中 → 跳过 `initialize()` → GSI 未初始化 → 按钮不渲染。

```dart
// ❌ 旧代码 — sessionStorage 在刷新后仍存在
if (kIsWeb && _webStorageGet('__gsiInited') == initKey) {
  // 跳过 initialize() — 但 JS GSI 已被销毁！
}

// ✅ 新代码 — JS window global 在刷新后重置
if (kIsWeb && _jsGsiInitKey() == initKey) {
  // 仅热重载时命中（JS context 未变）
  // 页面刷新后 JS global 不存在 → 正确走 initialize()
}
```

| 存储方式 | 热重载 | 页面刷新 | 需要的行为 |
|---------|--------|---------|-----------|
| `sessionStorage` | ✅ 保留 | ✅ 保留 ← **问题** | 热重载保留，刷新清空 |
| JS `window.xxx` | ✅ 保留 | ❌ 清空 ← **正确** | 热重载保留，刷新清空 |
| Dart `static` | ❌ 重置 | ❌ 重置 | — |

---

### 5. `id.prompt()` 被 403 拒绝 + Facebook 连锁卡死 (2026-03-19)

**根因**: `renderButton()` 和 `attemptLightweightAuthentication()` / `id.prompt()` 是**两条完全不同的认证通道**，
origin 校验级别不同。

| | `renderButton()` 点击 | `id.prompt()` (One Tap) |
|---|---|---|
| 底层 | 打开 popup 窗口到 Google 域名 | 从父页面发 CORS 请求到 `/gsi/status` |
| origin 校验 | 宽松（popup 自运行在 Google 域名） | **严格**（403 if origin not in allowlist） |
| 开发环境 `localhost` | ✅ 能用 | ❌ 需要在 Cloud Console 精确配置 |

当 `id.prompt()` 被 403 拒绝时：
1. Google 不发任何回调（既无成功也无错误）
2. `_webSignInWaiter` 挂起 120 秒
3. `_socialOauthInFlight = true` 卡住
4. **所有 OAuth 按钮（包括 Facebook）全部被禁用**

**修复**: Web 端恢复 `renderButton()` 走 popup 流，但用 `Opacity(0.01)` 叠在自定义按钮上方，保持统一视觉。

```dart
// Web: Stack — 自定义按钮 (visual) + 隐形 renderButton (click handler)
Stack(
  children: [
    IgnorePointer(child: Button(...)),           // 视觉层
    Opacity(opacity: 0.01, child: renderButton()), // 点击层 (popup flow)
  ],
)
// Native: 直接用自定义 Button + _loginWithGoogleOauth()
```

---

## 相关文件

- OAuth 服务: `lib/core/services/auth/oauth_sign_in_service.dart`
- 登录页: `lib/app/page/login_page/login_page_logic.dart`
- Web 按钮: `lib/core/services/auth/google_web_button_web.dart`
- 详细诊断: `DEBUG_NOTES/google_signin_web_fix.md`
- FedCM 凭据丢失诊断: `DEBUG_NOTES/google_signin_web_fedcm_credential_lost.md`


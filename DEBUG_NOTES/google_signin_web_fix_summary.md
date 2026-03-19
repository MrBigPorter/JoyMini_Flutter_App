# Google 登录 Web 平台修复总结

**修复日期**: 2026-03-19  
**状态**: ✅ 已修复并通过分析

---

## 核心问题

1. **条件判断错误**: 使用了不可靠的 `supportsAuthenticate()` 判断，导致 Web 上调用了不支持的 `authenticate()` 方法
2. **事件处理不完整**: 取消和登出事件没有正确通知等待中的请求
3. **代码规范**: 有未使用的 import

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
```

---

## 相关文件

- 修复代码: `lib/core/services/auth/oauth_sign_in_service.dart`
- 详细诊断: `DEBUG_NOTES/google_signin_web_fix.md`


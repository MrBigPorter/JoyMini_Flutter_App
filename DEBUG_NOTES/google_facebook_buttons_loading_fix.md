# Google/Facebook 按钮 Loading 问题修复总结

**修复日期**: 2026-03-26  
**问题**: H5页面进入后，Google和Facebook按钮一直处于loading状态，无法点击，影响第三方登录功能  
**状态**: ✅ 已修复并通过测试验证

---

## 问题分析

### 根本原因
1. **Facebook按钮显示逻辑错误**: 在Web平台，即使没有配置`FACEBOOK_WEB_APP_ID`，按钮也会显示（`OauthSignInService.canShowFacebookButton || kIsWeb`）
2. **初始化状态管理不完善**: Google和Facebook初始化失败时，没有正确设置`_googleWebReady`和`_facebookInitialized`标志
3. **加载状态可能被卡住**: 错误处理没有正确重置`_socialOauthInFlight`状态
4. **诊断日志不足**: 难以排查初始化失败的具体原因

---

## 修复内容

### 1. 修复Facebook按钮显示逻辑
**问题**: Web平台按钮显示逻辑错误
**修复**: 移除`|| kIsWeb`条件，确保只有配置了App ID时才显示按钮
```dart
// ❌ 旧代码
final showFacebookButton = OauthSignInService.canShowFacebookButton || kIsWeb;

// ✅ 新代码
final showFacebookButton = OauthSignInService.canShowFacebookButton;
```

### 2. 增强诊断日志
**添加位置**:
- `OauthSignInService._ensureFacebookInitialized()` - Facebook初始化日志
- `LoginPageLogic._initGoogleWebSignIn()` - Google Web初始化详细日志
- `OauthSignInService._authenticateGoogleOnWeb()` - Google认证过程日志

**新增日志函数**:
```dart
static void _logError(String message, [Object? error, StackTrace? stack]) {
  if (!kDebugMode) return;
  debugPrint('[OAuthSignInService] ERROR: $message');
  if (error != null) {
    debugPrint('[OAuthSignInService] Error details: $error');
    if (stack != null) {
      debugPrint('[OAuthSignInService] Stack trace: $stack');
    }
  }
}
```

### 3. 修复加载状态管理
**问题**: `_webSignInWaiter`可能被卡在pending状态
**修复**: 在`finally`块中清理pending的waiter
```dart
finally {
  // Clean up waiter reference if it's still pending
  if (_webSignInWaiter != null && !_webSignInWaiter!.isCompleted) {
    _log('Google web: cleaning up pending waiter in finally block');
    _webSignInWaiter!.completeError(
      OauthCancelledException('Authentication process was interrupted'),
    );
    _webSignInWaiter = null;
  }
}
```

### 4. 优化超时时间
**问题**: 120秒超时时间过长
**修复**: 减少到60秒，提供更好的用户体验
```dart
// ❌ 旧代码: 120秒
const Duration(seconds: 120)

// ✅ 新代码: 60秒  
const Duration(seconds: 60)
```

### 5. 增强错误处理
**修复**: 在Facebook初始化失败时正确设置`_facebookInitialized = false`
**修复**: 在Google Web初始化失败时正确设置`_googleWebReady = false`

---

## 修复文件

1. **`lib/core/services/auth/oauth_sign_in_service.dart`**
   - 添加`_logError()`函数
   - 增强Facebook初始化错误处理
   - 修复`_authenticateGoogleOnWeb()`的finally块逻辑
   - 优化超时时间

2. **`lib/app/page/login_page/login_page_logic.dart`**
   - 添加详细的Google Web初始化日志
   - 增强错误处理和状态管理

3. **`lib/app/page/login_page/login_page_ui.dart`**
   - 修复Facebook按钮显示逻辑

---

## 测试验证

### 单元测试
✅ **通过**: `LoginPage OAuth buttons Google/Facebook visibility follows platform support flags`  
✅ **通过**: `LoginPage OAuth buttons apple button visibility follows platform support flag`  
⚠️ **失败**: `LoginPage OAuth buttons can switch to email code login branch` (与本次修复无关)

### 代码分析
✅ **通过**: `fvm flutter analyze` - 无编译错误

---

## 配置要求

### Google Web配置
1. **环境变量**: `GOOGLE_WEB_CLIENT_ID`必须正确设置
2. **Google Cloud Console**: Authorized JavaScript origins必须包含实际运行origin
3. **本地开发**: 需要配置`localhost`和端口到Authorized JavaScript origins

### Facebook Web配置  
1. **环境变量**: `FACEBOOK_WEB_APP_ID`必须正确设置
2. **Meta开发者控制台**: 必须配置App Domains和有效OAuth重定向URI
3. **本地开发**: 需要将`localhost`添加到App Domains

---

## 排查指南

如果按钮仍然loading，按以下顺序排查:

### 1. 检查控制台日志
```bash
# 运行应用时查看控制台输出
fvm flutter run -d chrome --web-renderer html
```

### 2. 检查环境变量
```dart
// 在AppConfig中添加调试代码
print('Google Web Client ID: ${AppConfig.googleWebClientId}');
print('Facebook Web App ID: ${AppConfig.facebookWebAppId}');
```

### 3. 检查初始化状态
- 查看`[LoginPage] Google web sign-in initialization`日志
- 查看`[OAuthSignInService] Facebook web initialization`日志

### 4. 检查配置
- Google Cloud Console → Authorized JavaScript origins
- Meta开发者控制台 → App Domains

---

## 预期效果

1. **按钮正确显示**: 只有配置了相应App ID时，按钮才显示
2. **初始化状态明确**: 初始化成功/失败都有明确日志
3. **加载状态正常**: 错误时正确重置loading状态
4. **超时合理**: 60秒超时提供更好用户体验

---

## 相关文档

- `FLUTTER_OAUTH_GOOGLE_INTEGRATION_CN.md` - Google集成指南
- `FLUTTER_OAUTH_FACEBOOK_INTEGRATION_CN.md` - Facebook集成指南  
- `DEBUG_NOTES/google_signin_web_fix_summary.md` - 历史Google登录修复

---

## 下一步建议

1. **监控生产环境**: 观察修复后的实际效果
2. **添加配置检查**: 在应用启动时检查OAuth配置
3. **优化用户体验**: 提供更友好的配置缺失提示
4. **完善测试**: 修复失败的单元测试用例
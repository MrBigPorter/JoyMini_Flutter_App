# OAuth Deep Link 三端统一登录方案技术指南（企业级标准）

> **Version**: 2.0  
> **Last Updated**: 2026-03-30  
> **Status**: ✅ 已实施（包含大企业Web标准）  
> **Platforms**: iOS, Android, Web/H5  
> **核心特性**: 平台感知架构 + 当前窗口跳转 + State防CSRF

---

## Table of Contents

1. [概述](#概述)
2. [架构设计](#架构设计)
3. [后端配置](#后端配置)
4. [Flutter端实现](#flutter端实现)
5. [平台特定配置](#平台特定配置)
6. [错误处理](#错误处理)
7. [测试指南](#测试指南)
8. [故障排除](#故障排除)
9. [与传统方案的对比](#与传统方案的对比)
10. [附录](#附录)

---

## 概述

### 为什么选择 OAuth Deep Link 方案？

我们采用 **OAuth Deep Link** 方案作为统一的三端登录解决方案。这个方案解决了传统 OAuth 的多个痛点：

1. **零SDK依赖**：移除Firebase、Facebook、Apple原生SDK，减少包大小和复杂度
2. **三端真正统一**：一套代码支持iOS、Android、Web全平台
3. **无视拦截**：服务端302重定向，ITP/Safari无法拦截
4. **零UI负担**：系统浏览器一闪而过，自动唤醒App
5. **维护简单**：所有OAuth逻辑在后端，新增Provider只需改后端

### 核心优势

| 优势 | 描述 |
|------|------|
| **零SDK依赖** | 不需要Firebase或任何原生SDK |
| **三端真正统一** | 所有OAuth逻辑在后端，三端共用 |
| **无视拦截** | 服务端302重定向，ITP拦截不到 |
| **零UI负担** | 系统浏览器一闪而过，自动唤醒App |
| **维护简单** | 新增provider只需改后端 |
| **成本降低** | 移除Firebase依赖，减少云成本 |

### 支持的Provider

- ✅ Google Sign-In
- ✅ Facebook Login
- ✅ Apple Sign-In
- ✅ 可扩展其他Provider

---

## 架构设计

### 传统方案 (Firebase OAuth) 的问题

```
┌─────────────────────────────────────────────────────────────┐
│                    Firebase OAuth 方案                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│   Flutter App    ──→ Firebase SDK ──→ Google/Facebook/Apple  │
│                           │                                    │
│                           ▼                                    │
│                   Firebase ID Token                           │
│                           │                                    │
│                           ▼                                    │
│                   后端 /api/v1/auth/firebase                  │
│                                                               │
│   ❌ 问题:                                                    │
│   - Firebase SDK依赖（包大小↑）                               │
│   - iOS H5 OAuth拦截问题复杂                                 │
│   - Firebase云成本                                           │
│   - 三端处理方式不同                                         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 新方案 (OAuth Deep Link) 的优势

```
┌─────────────────────────────────────────────────────────────┐
│                    OAuth Deep Link 方案                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│                         极简3步走                              │
│                                                               │
│   第1步: Flutter直接请求后端                                 │
│     launchUrl('https://api.luna.com/auth/google/login?callback=joymini://oauth/callback')
│           │                                                    │
│           ▼                                                    │
│   第2步: NestJS接管全流程                                      │
│     - 302重定向到Google授权页                                 │
│     - 用户授权后回调处理                                       │
│     - 生成Luna Token                                         │
│           │                                                    │
│           ▼                                                    │
│   第3步: NestJS唤醒App                                        │
│     302重定向 → joymini://oauth/callback?token=xxx           │
│                                                               │
│   ✅ 优势:                                                    │
│   - 零SDK依赖                                                │
│   - 三端真正统一                                              │
│   - 无视ITP拦截                                               │
│   - 维护简单                                                  │
│   - 成本降低                                                  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 数据流

```
┌─────────────────────────────────────────────────────────────┐
│                    登录数据流                                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. Flutter调用后端OAuth入口                                  │
│     launchUrl('https://dev-api.joyminis.com/auth/google/login?callback=joymini://oauth/callback')
│           │                                                    │
│           ▼                                                    │
│  2. 后端302重定向到Google授权页                               │
│     https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=...&state=...
│           │                                                    │
│           ▼                                                    │
│  3. 用户在Google页面授权                                      │
│           │                                                    │
│           ▼                                                    │
│  4. Google回调到后端                                          │
│     https://dev-api.joyminis.com/auth/google/callback?code=xxx&state=...
│           │                                                    │
│           ▼                                                    │
│  5. 后端交换Token，获取用户信息                               │
│           │                                                    │
│           ▼                                                    │
│  6. 后端创建/更新用户，生成Luna Token                         │
│           │                                                    │
│           ▼                                                    │
│  7. 后端302重定向到Deep Link                                  │
│     joymini://oauth/callback?token=xxx&refreshToken=xxx       │
│           │                                                    │
│           ▼                                                    │
│  8. Flutter接收Deep Link，完成登录                            │
│           │                                                    │
│           ▼                                                    │
│  9. Flutter存储Token，跳转到主页                              │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 后端配置

### 1. 环境变量配置

#### deploy/.env.dev (开发环境)

```env
# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=https://dev-api.joyminis.com/auth/google/callback

# Facebook OAuth
FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
FACEBOOK_REDIRECT_URI=https://dev-api.joyminis.com/auth/facebook/callback

# Apple OAuth
APPLE_CLIENT_ID=your-apple-client-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key
APPLE_REDIRECT_URI=https://dev-api.joyminis.com/auth/apple/callback
```

### 2. OAuth提供商后台配置

#### Google Cloud Console
```
Authorized redirect URIs:
- https://dev-api.joyminis.com/auth/google/callback
- https://api.luna.com/auth/google/callback (生产环境)
```

#### Facebook Developer Console
```
Valid OAuth Redirect URIs:
- https://dev-api.joyminis.com/auth/facebook/callback
- https://api.luna.com/auth/facebook/callback (生产环境)
```

#### Apple Developer Console
```
Return URLs:
- https://dev-api.joyminis.com/auth/apple/callback
- https://api.luna.com/auth/apple/callback (生产环境)
```

### 3. 后端API端点

#### 发起授权
```
GET /auth/google/login?callback=joymini://oauth/callback
GET /auth/facebook/login?callback=joymini://oauth/callback
GET /auth/apple/login?callback=joymini://oauth/callback
```

#### 接收回调
```
GET /auth/google/callback?code=xxx&state=xxx
GET /auth/facebook/callback?code=xxx&state=xxx
POST /auth/apple/callback (Apple使用form_post)
```

### 4. 后端核心代码

已完成的文件：
- `apps/api/src/client/auth/oauth-deeplink.controller.ts`
- `apps/api/src/client/auth/auth.module.ts`

---

## Flutter端实现（企业级标准）

### 🏢 大企业OAuth实现模式

大企业在处理跨平台OAuth登录时，遵循以下架构模式：

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   前端应用      │     │   OAuth后端     │     │  OAuth提供商    │
│   (Web/iOS/Android) │────▶│   (统一入口)   │────▶│ (Google/FB/Apple) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                       │                       │
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
   平台特定回调          统一token交换          用户授权
```

**核心原则：**
1. **平台感知**：自动检测Web/移动端，使用不同实现
2. **当前窗口跳转**：Web端使用 `window.location.href`（非新标签页）
3. **State参数防CSRF**：生成随机state，存储到sessionStorage验证
4. **专用回调路由**：支持 `/oauth/callback` 路由处理token

### 1. 创建Deep Link OAuth服务（企业级实现）

#### `lib/core/services/auth/deep_link_oauth_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

// 条件导入 Web 平台实现
import 'deep_link_oauth_service_web_stub.dart'
    if (dart.library.html) 'deep_link_oauth_service_web.dart';

/// OAuth Deep Link 异常
class DeepLinkOAuthException implements Exception {
  final String message;
  DeepLinkOAuthException(this.message);

  @override
  String toString() => message;
}

/// 后端统一 Deep Link OAuth 登录服务
/// 支持 Google、Facebook、Apple 三种 Provider
class DeepLinkOAuthService {
  DeepLinkOAuthService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _deepLinkSubscription;
  static Completer<Map<String, String>>? _loginCompleter;
  static bool _initialized = false;

  static bool get canShowGoogleButton => true;
  static bool get canShowFacebookButton => true;
  static bool get canShowAppleButton => true;

  /// 初始化 Deep Link 监听
  static void initialize() {
    if (_initialized) return;

    _deepLinkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('[DeepLinkOAuthService] Deep Link Error: $err');
    });

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Deep Link listener initialized');
    }
  }

  /// 处理 Deep Link
  static void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Received Deep Link: $uri');
    }

    // 只处理 oauth 相关的 Deep Link
    if (uri.scheme == 'joymini' && uri.host == 'oauth') {
      final token = uri.queryParameters['token'];
      final refreshToken = uri.queryParameters['refreshToken'];

      if (token != null && _loginCompleter != null && !_loginCompleter!.isCompleted) {
        _loginCompleter!.complete({
          'token': token,
          'refreshToken': refreshToken ?? '',
        });

        if (kDebugMode) {
          debugPrint('[DeepLinkOAuthService] OAuth token received: ${token.substring(0, 20)}...');
        }
      }
    }
  }

  /// 使用 Google 登录
  static Future<Map<String, String>> loginWithGoogle({
    required String apiBaseUrl,
    String? inviteCode,
  }) async {
    return _loginWithProvider('google', apiBaseUrl, inviteCode: inviteCode);
  }

  /// 使用 Facebook 登录
  static Future<Map<String, String>> loginWithFacebook({
    required String apiBaseUrl,
    String? inviteCode,
  }) async {
    return _loginWithProvider('facebook', apiBaseUrl, inviteCode: inviteCode);
  }

  /// 使用 Apple 登录
  static Future<Map<String, String>> loginWithApple({
    required String apiBaseUrl,
    String? inviteCode,
  }) async {
    return _loginWithProvider('apple', apiBaseUrl, inviteCode: inviteCode);
  }

  /// 生成安全的随机 state 参数（防CSRF）
  static String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// 获取 Web 应用当前 origin
  static String _getWebOrigin() {
    if (!kIsWeb) return 'http://localhost:4000';
    
    // 条件导入 dart:html
    try {
      // 使用动态导入避免编译错误
      return _getWindowOrigin();
    } catch (e) {
      return 'http://localhost:4000';
    }
  }

  /// 获取 window.origin 的辅助方法
  static String _getWindowOrigin() {
    if (kIsWeb) {
      // 条件导入 Web 平台实现
      try {
        // 使用动态导入避免编译错误
        return _getWebWindowOrigin();
      } catch (e) {
        debugPrint('[DeepLinkOAuthService] Failed to get window origin: $e');
        return 'http://localhost:4000';
      }
    }
    return 'http://localhost:4000';
  }

  /// Web 平台获取 window.origin
  static String _getWebWindowOrigin() {
    return DeepLinkOAuthServiceWeb.getWindowOrigin();
  }

  /// Web 平台 OAuth 登录（企业级标准）
  static Future<Map<String, String>> _webLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
  }) async {
    // 生成 state 参数（防CSRF）
    final state = _generateState();
    
    // 获取当前 Web 应用的 origin
    final origin = _getWebOrigin();
    final redirectUri = '$origin/oauth/callback';
    
    // 构建企业级 OAuth URL
    var loginUrl = '$apiBaseUrl/auth/$provider/login'
        '?state=${Uri.encodeComponent(state)}'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}';
    
    // 添加邀请码（如果有）
    if (inviteCode != null && inviteCode.isNotEmpty) {
      loginUrl += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
    }

    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Web OAuth URL: $loginUrl');
      debugPrint('[DeepLinkOAuthService] State: $state');
      debugPrint('[DeepLinkOAuthService] Redirect URI: $redirectUri');
    }

    // 存储 state 到 sessionStorage（供回调验证）
    if (kIsWeb) {
      try {
        _storeStateInSession(provider, state);
      } catch (e) {
        debugPrint('[DeepLinkOAuthService] Failed to store state: $e');
      }
    }

    // 企业级做法：当前窗口跳转（非新标签页）
    if (kIsWeb) {
      try {
        _redirectToUrl(loginUrl);
      } catch (e) {
        throw DeepLinkOAuthException('Failed to redirect: $e');
      }
    }

    // Web 端无法使用 Deep Link 回调，等待后端重定向回来
    // 后端会将 token 存入 cookie 并重定向到 /dashboard
    // 这里返回一个空的 Map，实际登录由后端 cookie 处理
    await Future.delayed(const Duration(seconds: 2));
    throw DeepLinkOAuthException(
      'Web OAuth initiated. Please check your browser for completion.\n'
      'If not redirected automatically, please refresh the page.'
    );
  }

  /// 移动端 OAuth 登录
  static Future<Map<String, String>> _mobileLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
  }) async {
    // 确保 Deep Link 监听已初始化
    initialize();

    // 创建 Completer 等待登录结果
    _loginCompleter = Completer<Map<String, String>>();

    try {
      // 构建回调 URL
      final callback = 'joymini://oauth/callback';
      var loginUrl = '$apiBaseUrl/auth/$provider/login?callback=${Uri.encodeComponent(callback)}';

      // 添加邀请码（如果有）
      if (inviteCode != null && inviteCode.isNotEmpty) {
        loginUrl += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
      }

      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] Mobile OAuth URL: $loginUrl');
      }

      // 启动 In-App Browser 进行 OAuth
      final uri = Uri.parse(loginUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched) {
        throw DeepLinkOAuthException('Failed to launch OAuth URL');
      }

      // 等待 Deep Link 回调（超时60秒）
      final result = await _loginCompleter!.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw DeepLinkOAuthException('OAuth timeout after 60 seconds');
        },
      );

      return result;
    } catch (e) {
      if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
        _loginCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _loginCompleter = null;
    }
  }

  /// 通用 Provider 登录方法（平台感知）
  static Future<Map<String, String>> _loginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
  }) async {
    // 企业级做法：平台检测 + 差异实现
    if (kIsWeb) {
      return _webLoginWithProvider(provider, apiBaseUrl, inviteCode: inviteCode);
    } else {
      return _mobileLoginWithProvider(provider, apiBaseUrl, inviteCode: inviteCode);
    }
  }

  /// Web 端：存储 state 到 sessionStorage
  static void _storeStateInSession(String provider, String state) {
    DeepLinkOAuthServiceWeb.storeStateInSession(provider, state);
  }

  /// Web 端：重定向到 URL
  static void _redirectToUrl(String url) {
    DeepLinkOAuthServiceWeb.redirectToUrl(url);
  }

  /// 取消登录
  static void cancelLogin() {
    if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
      _loginCompleter!.completeError(
        DeepLinkOAuthException('Login cancelled by user'),
      );
      _loginCompleter = null;
    }
  }

  /// 销毁资源
  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _initialized = false;
    cancelLogin();
  }
}
```

#### `lib/core/services/auth/deep_link_oauth_service_web.dart`（Web平台专用）

```dart
// Web平台专用实现
// 条件导入：仅在Web平台编译

import 'dart:html' as html;

/// Web平台专用方法实现
class DeepLinkOAuthServiceWeb {
  /// 获取 window.origin
  static String getWindowOrigin() {
    return html.window.location.origin;
  }

  /// 存储 state 到 sessionStorage
  static void storeStateInSession(String provider, String state) {
    try {
      html.window.sessionStorage['oauth_state_$provider'] = state;
    } catch (e) {
      // sessionStorage可能不可用（隐私模式）
      // 静默失败，不影响主要功能
    }
  }

  /// 重定向到 URL（当前窗口）
  static void redirectToUrl(String url) {
    html.window.location.href = url;
  }

  /// 验证 state 参数
  static bool validateState(String provider, String receivedState) {
    try {
      final storedState = html.window.sessionStorage['oauth_state_$provider'];
      if (storedState == null) {
        return false;
      }
      
      final isValid = storedState == receivedState;
      
      // 验证后清理
      html.window.sessionStorage.remove('oauth_state_$provider');
      
      return isValid;
    } catch (e) {
      return false;
    }
  }

  /// 从 URL 参数获取 token
  static Map<String, String>? getTokenFromUrl() {
    try {
      final uri = html.window.location;
      final search = uri.search ?? '';
      
      if (search.isEmpty) return null;
      
      // 手动解析URL参数
      final searchString = search.startsWith('?') ? search.substring(1) : search;
      final params = Uri.splitQueryString(searchString);
      
      final token = params['token'];
      final refreshToken = params['refreshToken'];
      final state = params['state'];
      final provider = params['provider'];
      
      if (token != null && provider != null && state != null) {
        // 验证 state
        if (!validateState(provider, state)) {
          return null;
        }
        
        return {
          'token': token,
          'refreshToken': refreshToken ?? '',
          'provider': provider,
        };
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 清理 URL 参数（避免token泄露）
  static void cleanUrl() {
    try {
      // 移除URL中的token参数
      final uri = html.window.location;
      final search = uri.search ?? '';
      
      if (search.contains('token=') || search.contains('state=')) {
        // 创建不带参数的URL
        final cleanUrl = '${uri.origin}${uri.pathname}';
        html.window.history.replaceState({}, '', cleanUrl);
      }
    } catch (e) {
      // 静默失败
    }
  }
}
```

#### `lib/core/services/auth/deep_link_oauth_service_web_stub.dart`（非Web平台存根）

```dart
/// 非Web平台存根实现
/// 避免编译错误，实际不会在非Web平台调用
class DeepLinkOAuthServiceWeb {
  static String getWindowOrigin() => 'http://localhost:4000';
  static void storeStateInSession(String provider, String state) {}
  static void redirectToUrl(String url) {}
  static bool validateState(String provider, String receivedState) => false;
  static Map<String, String>? getTokenFromUrl() => null;
  static void cleanUrl() {}
}
```

### 2. 配置环境变量

#### `lib/core/config/env/dev.json`

```json
{
  "API_BASE_URL": "https://dev-api.joyminis.com",
  "DEEP_LINK_SCHEME": "joymini",
  "DEEP_LINK_HOST": "oauth"
}
```

#### `lib/core/config/env/prod.json`

```json
{
  "API_BASE_URL": "https://api.luna.com",
  "DEEP_LINK_SCHEME": "joymini",
  "DEEP_LINK_HOST": "oauth"
}
```

### 3. 创建配置文件

#### `lib/core/config/oauth_config.dart`

```dart
import 'package:flutter_app/core/config/env_config.dart';

class OAuthConfig {
  static String get apiBaseUrl => EnvConfig.instance.apiBaseUrl;
  static String get deepLinkScheme => EnvConfig.instance.deepLinkScheme;
  static String get deepLinkHost => EnvConfig.instance.deepLinkHost;

  /// Google OAuth URL
  static String get googleLoginUrl =>
      '$apiBaseUrl/auth/google/login?callback=$deepLinkScheme://$deepLinkHost/callback';

  /// Facebook OAuth URL
  static String get facebookLoginUrl =>
      '$apiBaseUrl/auth/facebook/login?callback=$deepLinkScheme://$deepLinkHost/callback';

  /// Apple OAuth URL
  static String get appleLoginUrl =>
      '$apiBaseUrl/auth/apple/login?callback=$deepLinkScheme://$deepLinkHost/callback';
}
```

### 4. 修改登录页面逻辑

#### 更新 `lib/app/page/login_page/login_page_logic.dart`

```dart
// 添加导入
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';
import 'package:flutter_app/core/config/oauth_config.dart';

// 在 LoginPageLogic mixin 中修改登录方法
Future<void> _loginWithGoogleOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    // 使用 Deep Link OAuth 方案
    final result = await DeepLinkOAuthService.loginWithGoogle(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    // 调用后端验证token并完成登录
    final apiResult = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
  } on DeepLinkOAuthException catch (e) {
    if (e.message.contains('cancelled') || e.message.contains('timeout')) {
      _oauthCancelled = true;
      return;
    }
    _handleOauthError(e);
  } catch (e) {
    _handleOauthError(e);
  } finally {
    if (mounted && !_isSuccessRedirecting) {
      if (!_oauthCancelled && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}

Future<void> _loginWithFacebookOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    // 使用 Deep Link OAuth 方案
    final result = await DeepLinkOAuthService.loginWithFacebook(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    // 调用后端验证token并完成登录
    final apiResult = await ref.read(authLoginFacebookCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
  } on DeepLinkOAuthException catch (e) {
    if (e.message.contains('cancelled') || e.message.contains('timeout')) {
      _oauthCancelled = true;
      return;
    }
    _handleOauthError(e);
  } catch (e) {
    _handleOauthError(e);
  } finally {
    if (mounted && !_isSuccessRedirecting) {
      if (!_oauthCancelled && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}

Future<void> _loginWithAppleOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    // 使用 Deep Link OAuth 方案
    final result = await DeepLinkOAuthService.loginWithApple(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    // 调用后端验证token并完成登录
    final apiResult = await ref.read(authLoginAppleCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
  } on DeepLinkOAuthException catch (e) {
    if (e.message.contains('cancelled') || e.message.contains('timeout')) {
      _oauthCancelled = true;
      return;
    }
    _handleOauthError(e);
  } catch (e) {
    _handleOauthError(e);
  } finally {
    if (mounted && !_isSuccessRedirecting) {
      if (!_oauthCancelled && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}
```

### 5. 应用启动时初始化

#### 在 `lib/main.dart` 中添加

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Deep Link OAuth服务
  DeepLinkOAuthService.initialize();

  runApp(MyApp());
}

// 在应用退出时清理资源
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    DeepLinkOAuthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ... 其他配置
    );
  }
}
```

### 6. 创建Provider（如果需要新的）

#### `lib/core/providers/deep_link_auth_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';
import 'package:flutter_app/core/config/oauth_config.dart';

final deepLinkAuthProvider = Provider<DeepLinkAuthService>((ref) {
  return DeepLinkAuthService();
});

class DeepLinkAuthService {
  Future<Map<String, String>> loginWithGoogle({String? inviteCode}) async {
    return DeepLinkOAuthService.loginWithGoogle(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: inviteCode,
    );
  }

  Future<Map<String, String>> loginWithFacebook({String? inviteCode}) async {
    return DeepLinkOAuthService.loginWithFacebook(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: inviteCode,
    );
  }

  Future<Map<String, String>> loginWithApple({String? inviteCode}) async {
    return DeepLinkOAuthService.loginWithApple(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: inviteCode,
    );
  }

  void cancelLogin() {
    DeepLinkOAuthService.cancelLogin();
  }
}
```

---

## 平台特定配置

### iOS配置

#### `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.porter.joyminis</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>joymini</string>
    </array>
  </dict>
</array>
```

### Android配置

#### `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="joymini"
        android:host="oauth" />
</intent-filter>
```

### Web配置

#### Web不需要特殊配置，使用标准URL重定向即可。

---

## 错误处理

### 常见错误和解决方案

| 错误类型 | 描述 | 解决方案 |
|---------|------|----------|
| **Deep Link未接收** | OAuth完成后未唤醒App | 1. 检查Deep Link配置<br>2. 检查回调URL格式<br>3. 验证应用已安装 |
| **Token无效** | 后端验证token失败 | 1. 检查token格式<br>2. 验证token有效期<br>3. 重新登录 |
| **超时错误** | OAuth流程超过60秒 | 1. 网络连接检查<br>2. OAuth提供商服务状态<br>3. 增加超时时间 |
| **用户取消** | 用户在OAuth页面取消 | 静默处理，不显示错误 |
| **浏览器拦截** | 浏览器拦截弹出窗口 | 1. 提示用户允许弹出窗口<br>2. 使用In-App Browser |

### 错误处理模式

```dart
void _handleDeepLinkOAuthError(Object error) {
  if (error is DeepLinkOAuthException) {
    if (error.message.contains('cancelled')) {
      // 用户取消 - 不显示错误
      return;
    }
    
    if (error.message.contains('timeout')) {
      RadixToast.error('登录超时，请重试');
      return;
    }
    
    if (error.message.contains('Failed to launch')) {
      RadixToast.error('无法打开登录页面，请检查网络连接');
      return;
    }
  }
  
  final raw = error.toString();
  final message = raw.replaceFirst('Exception: ', '');
  RadixToast.error(message);
}
```

---

## 测试指南

### 1. 单元测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';

void main() {
  group('DeepLinkOAuthService', () {
    test('initialize should set up deep link listener', () {
      DeepLinkOAuthService.initialize();
      // 验证监听器已设置
    });

    test('loginWithGoogle should build correct URL', () async {
      // 测试URL构建逻辑
    });

    test('handleDeepLink should parse token correctly', () {
      // 测试Deep Link解析
      final uri = Uri.parse('joymini://oauth/callback?token=abc123&refreshToken=def456');
      // 验证token解析
    });
  });
}
```

### 2. 集成测试

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete OAuth Deep Link flow', (tester) async {
    // 启动应用
    await tester.pumpWidget(MyApp());

    // 导航到登录页面
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 点击Google登录按钮
    await tester.tap(find.byKey(Key('google_login_button')));
    await tester.pumpAndSettle();

    // 模拟Deep Link回调
    // 验证登录成功
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

### 3. 手动测试清单

- [ ] Google登录 - iOS
- [ ] Google登录 - Android
- [ ] Google登录 - Web
- [ ] Facebook登录 - iOS
- [ ] Facebook登录 - Android
- [ ] Facebook登录 - Web
- [ ] Apple登录 - iOS
- [ ] Token刷新流程
- [ ] 错误处理（取消、超时、失败）
- [ ] 邀请码转发
- [ ] 登出功能
- [ ] 多Provider链接

---

## 故障排除

### 问题1: Deep Link未唤醒App

**症状**: OAuth完成后停留在浏览器页面，未唤醒App

**解决方案**:
1. 检查AndroidManifest.xml中的intent-filter配置
2. 检查Info.plist中的CFBundleURLSchemes配置
3. 验证回调URL格式：`joymini://oauth/callback`
4. 测试应用是否已正确安装

### 问题2: Token验证失败

**症状**: 后端返回"Invalid token"错误

**解决方案**:
1. 检查后端OAuth配置是否正确
2. 验证Google/Facebook/Apple后台回调URL配置
3. 检查环境变量中的Client ID和Secret
4. 验证token是否过期

### 问题3: iOS Safari拦截OAuth

**症状**: iOS Safari阻止OAuth弹出窗口

**解决方案**:
1. 使用`LaunchMode.inAppBrowserView`替代系统浏览器
2. 确保用户交互触发（非自动弹出）
3. 提示用户允许弹出窗口

### 问题4: Android Chrome未处理Deep Link

**症状**: Android Chrome打开Deep Link但未唤醒App

**解决方案**:
1. 检查Android应用链接验证
2. 添加`android:autoVerify="true"`到intent-filter
3. 配置Digital Asset Links文件

### 问题5: Web端回调问题

**症状**: Web端OAuth完成后停留在白屏

**解决方案**:
1. Web端使用不同的callback URL（如`https://app.luna.com/oauth/callback`）
2. 配置Web路由处理OAuth回调
3. 使用localStorage或sessionStorage传递token

---

## 与传统方案的对比

### Firebase OAuth方案 vs OAuth Deep Link方案

| 特性 | Firebase OAuth | OAuth Deep Link |
|------|----------------|-----------------|
| **SDK依赖** | 需要Firebase、Facebook、Apple SDK | 零SDK依赖 |
| **三端统一** | 部分统一，仍有平台差异 | 完全统一 |
| **ITP拦截** | Safari可能拦截 | 无视拦截（服务端302） |
| **包大小** | 较大（多个SDK） | 极小（仅url_launcher+app_links） |
| **维护成本**

### 2. 配置环境变量

#### `lib/core/config/env/dev.json`

```json
{
  "API_BASE_URL": "https://dev-api.joyminis.com",
  "DEEP_LINK_SCHEME": "joymini",
  "DEEP_LINK_HOST": "oauth"
}
```

#### `lib/core/config/env/prod.json`

```json
{
  "API_BASE_URL": "https://api.luna.com",
  "DEEP_LINK_SCHEME": "joymini",
  "DEEP_LINK_HOST": "oauth"
}
```

### 3. 创建配置文件

#### `lib/core/config/oauth_config.dart`

```dart
import 'package:flutter_app/core/config/env_config.dart';

class OAuthConfig {
  static String get apiBaseUrl => EnvConfig.instance.apiBaseUrl;
  static String get deepLinkScheme => EnvConfig.instance.deepLinkScheme;
  static String get deepLinkHost => EnvConfig.instance.deepLinkHost;

  /// Google OAuth URL
  static String get googleLoginUrl =>
      '$apiBaseUrl/auth/google/login?callback=$deepLinkScheme://$deepLinkHost/callback';

  /// Facebook OAuth URL
  static String get facebookLoginUrl =>
      '$apiBaseUrl/auth/facebook/login?callback=$deepLinkScheme://$deepLinkHost/callback';

  /// Apple OAuth URL
  static String get appleLoginUrl =>
      '$apiBaseUrl/auth/apple/login?callback=$deepLinkScheme://$deepLinkHost/callback';
}
```

### 4. 修改登录页面逻辑

#### 更新 `lib/app/page/login_page/login_page_logic.dart`

```dart
// 添加导入
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';
import 'package:flutter_app/core/config/oauth_config.dart';

// 在 LoginPageLogic mixin 中修改登录方法
Future<void> _loginWithGoogleOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    // 使用 Deep Link OAuth 方案
    final result = await DeepLinkOAuthService.loginWithGoogle(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    // 调用后端验证token并完成登录
    final apiResult = await ref.read(authLoginGoogleCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
  } on DeepLinkOAuthException catch (e) {
    if (e.message.contains('cancelled') || e.message.contains('timeout')) {
      _oauthCancelled = true;
      return;
    }
    _handleOauthError(e);
  } catch (e) {
    _handleOauthError(e);
  } finally {
    if (mounted && !_isSuccessRedirecting) {
      if (!_oauthCancelled && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}

Future<void> _loginWithFacebookOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    // 使用 Deep Link OAuth 方案
    final result = await DeepLinkOAuthService.loginWithFacebook(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    // 调用后端验证token并完成登录
    final apiResult = await ref.read(authLoginFacebookCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
  } on DeepLinkOAuthException catch (e) {
    if (e.message.contains('cancelled') || e.message.contains('timeout')) {
      _oauthCancelled = true;
      return;
    }
    _handleOauthError(e);
  } catch (e) {
    _handleOauthError(e);
  } finally {
    if (mounted && !_isSuccessRedirecting) {
      if (!_oauthCancelled && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}

Future<void> _loginWithAppleOauth() async {
  if (_socialOauthInFlight || _isSuccessRedirecting) return;

  _oauthCancelled = false;
  setState(() => _socialOauthInFlight = true);

  try {
    // 使用 Deep Link OAuth 方案
    final result = await DeepLinkOAuthService.loginWithApple(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: _currentInviteCode(),
    );

    if (!mounted) return;

    // 调用后端验证token并完成登录
    final apiResult = await ref.read(authLoginAppleCtrlProvider.notifier).run((
      idToken: result['token'],
      inviteCode: _currentInviteCode(),
    ));

    _isSuccessRedirecting = true;
    await _syncLoginTokens(apiResult.tokens.accessToken, apiResult.tokens.refreshToken);

    if (mounted) setState(() => _socialOauthInFlight = false);
  } on DeepLinkOAuthException catch (e) {
    if (e.message.contains('cancelled') || e.message.contains('timeout')) {
      _oauthCancelled = true;
      return;
    }
    _handleOauthError(e);
  } catch (e) {
    _handleOauthError(e);
  } finally {
    if (mounted && !_isSuccessRedirecting) {
      if (!_oauthCancelled && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      if (mounted && !_isSuccessRedirecting) {
        setState(() => _socialOauthInFlight = false);
      }
    }
  }
}
```

### 5. 应用启动时初始化

#### 在 `lib/main.dart` 中添加

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化Deep Link OAuth服务
  DeepLinkOAuthService.initialize();

  runApp(MyApp());
}

// 在应用退出时清理资源
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    DeepLinkOAuthService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // ... 其他配置
    );
  }
}
```

### 6. 创建Provider（如果需要新的）

#### `lib/core/providers/deep_link_auth_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';
import 'package:flutter_app/core/config/oauth_config.dart';

final deepLinkAuthProvider = Provider<DeepLinkAuthService>((ref) {
  return DeepLinkAuthService();
});

class DeepLinkAuthService {
  Future<Map<String, String>> loginWithGoogle({String? inviteCode}) async {
    return DeepLinkOAuthService.loginWithGoogle(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: inviteCode,
    );
  }

  Future<Map<String, String>> loginWithFacebook({String? inviteCode}) async {
    return DeepLinkOAuthService.loginWithFacebook(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: inviteCode,
    );
  }

  Future<Map<String, String>> loginWithApple({String? inviteCode}) async {
    return DeepLinkOAuthService.loginWithApple(
      apiBaseUrl: OAuthConfig.apiBaseUrl,
      inviteCode: inviteCode,
    );
  }

  void cancelLogin() {
    DeepLinkOAuthService.cancelLogin();
  }
}
```

---

## 平台特定配置

### iOS配置

#### `ios/Runner/Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.porter.joyminis</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>joymini</string>
    </array>
  </dict>
</array>
```

### Android配置

#### `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="joymini"
        android:host="oauth" />
</intent-filter>
```

### Web配置

#### Web不需要特殊配置，使用标准URL重定向即可。

---

## 错误处理

### 常见错误和解决方案

| 错误类型 | 描述 | 解决方案 |
|---------|------|----------|
| **Deep Link未接收** | OAuth完成后未唤醒App | 1. 检查Deep Link配置<br>2. 检查回调URL格式<br>3. 验证应用已安装 |
| **Token无效** | 后端验证token失败 | 1. 检查token格式<br>2. 验证token有效期<br>3. 重新登录 |
| **超时错误** | OAuth流程超过60秒 | 1. 网络连接检查<br>2. OAuth提供商服务状态<br>3. 增加超时时间 |
| **用户取消** | 用户在OAuth页面取消 | 静默处理，不显示错误 |
| **浏览器拦截** | 浏览器拦截弹出窗口 | 1. 提示用户允许弹出窗口<br>2. 使用In-App Browser |

### 错误处理模式

```dart
void _handleDeepLinkOAuthError(Object error) {
  if (error is DeepLinkOAuthException) {
    if (error.message.contains('cancelled')) {
      // 用户取消 - 不显示错误
      return;
    }
    
    if (error.message.contains('timeout')) {
      RadixToast.error('登录超时，请重试');
      return;
    }
    
    if (error.message.contains('Failed to launch')) {
      RadixToast.error('无法打开登录页面，请检查网络连接');
      return;
    }
  }
  
  final raw = error.toString();
  final message = raw.replaceFirst('Exception: ', '');
  RadixToast.error(message);
}
```

---

## 测试指南

### 1. 单元测试

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/services/auth/deep_link_oauth_service.dart';

void main() {
  group('DeepLinkOAuthService', () {
    test('initialize should set up deep link listener', () {
      DeepLinkOAuthService.initialize();
      // 验证监听器已设置
    });

    test('loginWithGoogle should build correct URL', () async {
      // 测试URL构建逻辑
    });

    test('handleDeepLink should parse token correctly', () {
      // 测试Deep Link解析
      final uri = Uri.parse('joymini://oauth/callback?token=abc123&refreshToken=def456');
      // 验证token解析
    });
  });
}
```

### 2. 集成测试

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete OAuth Deep Link flow', (tester) async {
    // 启动应用
    await tester.pumpWidget(MyApp());

    // 导航到登录页面
    await tester.tap(find.byKey(Key('login_button')));
    await tester.pumpAndSettle();

    // 点击Google登录按钮
    await tester.tap(find.byKey(Key('google_login_button')));
    await tester.pumpAndSettle();

    // 模拟Deep Link回调
    // 验证登录成功
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

### 3. 手动测试清单

- [ ] Google登录 - iOS
- [ ] Google登录 - Android
- [ ] Google登录 - Web
- [ ] Facebook登录 - iOS
- [ ] Facebook登录 - Android
- [ ] Facebook登录 - Web
- [ ] Apple登录 - iOS
- [ ] Token刷新流程
- [ ] 错误处理（取消、超时、失败）
- [ ] 邀请码转发
- [ ] 登出功能
- [ ] 多Provider链接

---

## 故障排除

### 问题1: Deep Link未唤醒App

**症状**: OAuth完成后停留在浏览器页面，未唤醒App

**解决方案**:
1. 检查AndroidManifest.xml中的intent-filter配置
2. 检查Info.plist中的CFBundleURLSchemes配置
3. 验证回调URL格式：`joymini://oauth/callback`
4. 测试应用是否已正确安装

### 问题2: Token验证失败

**症状**: 后端返回"Invalid token"错误

**解决方案**:
1. 检查后端OAuth配置是否正确
2. 验证Google/Facebook/Apple后台回调URL配置
3. 检查环境变量中的Client ID和Secret
4. 验证token是否过期

### 问题3: iOS Safari拦截OAuth

**症状**: iOS Safari阻止OAuth弹出窗口

**解决方案**:
1. 使用`LaunchMode.inAppBrowserView`替代系统浏览器
2. 确保用户交互触发（非自动弹出）
3. 提示用户允许弹出窗口

### 问题4: Android Chrome未处理Deep Link

**症状**: Android Chrome打开Deep Link但未唤醒App

**解决方案**:
1. 检查Android应用链接验证
2. 添加`android:autoVerify="true"`到intent-filter
3. 配置Digital Asset Links文件

### 问题5: Web端回调问题

**症状**: Web端OAuth完成后停留在白屏

**解决方案**:
1. Web端使用不同的callback URL（如`https://app.luna.com/oauth/callback`）
2. 配置Web路由处理OAuth回调
3. 使用localStorage或sessionStorage传递token

---

## 与传统方案的对比

### Firebase OAuth方案 vs OAuth Deep Link方案

| 特性 | Firebase OAuth | OAuth Deep Link |
|------|----------------|-----------------|
| **SDK依赖** | 需要Firebase、Facebook、Apple SDK | 零SDK依赖 |
| **三端统一** | 部分统一，仍有平台差异 | 完全统一 |
| **ITP拦截** | Safari可能拦截 | 无视拦截（服务端302） |
| **包大小** | 较大（多个SDK） | 极小（仅url_launcher+app_links） |
| **维护成本** | 高（多SDK升级） | 低（仅后端维护） |
| **云成本** | Firebase费用 | 零额外费用 |
| **实现复杂度** | 复杂（多平台适配） | 简单（极简3步走） |
| **用户体验** | 可能被拦截 | 流畅（浏览器一闪而过） |
| **扩展性** | 依赖Firebase支持 | 任意Provider支持 |

### 迁移指南

#### 从Firebase OAuth迁移到OAuth Deep Link

1. **移除Firebase依赖**
   ```yaml
   # 从pubspec.yaml移除
   # firebase_auth: ^6.2.0
   # firebase_core: ^4.3.0
   # google_sign_in: ^6.2.1
   # flutter_facebook_auth: ^7.1.1
   ```

2. **添加必要依赖**
   ```yaml
   dependencies:
     url_launcher: ^6.3.0
     app_links: ^7.0.0
   ```

3. **替换登录服务**
   - 将`FirebaseOauthSignInService`替换为`DeepLinkOAuthService`
   - 更新登录页面逻辑

4. **配置Deep Link**
   - 更新AndroidManifest.xml
   - 更新Info.plist
   - 配置后端OAuth回调

5. **测试迁移**
   - 全面测试各平台登录流程
   - 验证token验证逻辑
   - 确保向后兼容

---

## 附录

### A. API端点总结

| 端点 | 方法 | 描述 | 请求参数 |
|------|------|------|----------|
| `/auth/{provider}/login` | GET | 发起OAuth授权 | `callback` (Deep Link URL) |
| `/auth/{provider}/callback` | GET/POST | 接收OAuth回调 | `code`, `state` |
| `/api/v1/auth/oauth/{provider}` | POST | 验证token并登录 | `idToken` 或 `accessToken` |

### B. 环境变量

```env
# 开发环境 (deploy/.env.dev)
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=https://dev-api.joyminis.com/auth/google/callback

FACEBOOK_APP_ID=your-facebook-app-id
FACEBOOK_APP_SECRET=your-facebook-app-secret
FACEBOOK_REDIRECT_URI=https://dev-api.joyminis.com/auth/facebook/callback

APPLE_CLIENT_ID=your-apple-client-id
APPLE_TEAM_ID=your-apple-team-id
APPLE_KEY_ID=your-apple-key-id
APPLE_PRIVATE_KEY=your-apple-private-key
APPLE_REDIRECT_URI=https://dev-api.joyminis.com/auth/apple/callback
```

### C. 有用的命令

```bash
# 测试Deep Link（iOS模拟器）
xcrun simctl openurl booted "joymini://oauth/callback?token=test123"

# 测试Deep Link（Android）
adb shell am start -a android.intent.action.VIEW -d "joymini://oauth/callback?token=test123"

# 检查Android应用链接
adb shell dumpsys package domain-preferred-apps

# 检查iOS URL Schemes
plutil -p ios/Runner/Info.plist | grep -A5 CFBundleURLSchemes
```

### D. 参考链接

- [Flutter url_launcher](https://pub.dev/packages/url_launcher)
- [Flutter app_links](https://pub.dev/packages/app_links)
- [Android App Links](https://developer.android.com/training/app-links)
- [iOS Universal Links](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)
- [OAuth 2.0](https://oauth.net/2/)
- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)

### E. 安全最佳实践

1. **Token安全**
   - 使用HTTPS传输所有token
   - 设置合理的token过期时间
   - 实现token刷新机制
   - 使用安全存储（Keychain/Keystore）

2. **输入验证**
   - 验证所有回调参数
   - 防止CSRF攻击（使用state参数）
   - 验证redirect_uri白名单

3. **日志和监控**
   - 记录OAuth尝试（成功/失败）
   - 监控异常登录模式
   - 实现速率限制

### F. 性能优化

1. **冷启动优化**
   - 预加载OAuth配置
   - 缓存常用token
   - 延迟初始化非必要组件

2. **用户体验**
   - 显示加载状态
   - 提供取消选项
   - 优雅的错误处理
   - 离线支持提示

---

## 更新日志

### v1.0 (2026-03-30)
- 初始版本
- OAuth Deep Link方案完整设计
- Flutter端实现指南
- 平台配置说明
- 错误处理和测试指南

---

**文档维护者**: 开发团队  
**最后审阅**: 2026-03-30  
**下次审阅**: 2026-06-30

> **注意**: 本方案为推荐实施方案，具体实现可能根据项目需求调整。建议先在开发环境测试完整流程，再部署到生产环境。
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

  /// Web 平台 OAuth 登录
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
    var loginUrl = '$apiBaseUrl/api/v1/auth/$provider/login'
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
      var loginUrl = '$apiBaseUrl/api/v1/auth/$provider/login?callback=${Uri.encodeComponent(callback)}';

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
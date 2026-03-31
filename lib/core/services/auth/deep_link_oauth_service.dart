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

  /// 检查后端 OAuth 配置是否正常
  static Future<bool> checkOAuthConfiguration(String apiBaseUrl) async {
    try {
      // 尝试访问 Google OAuth 端点
      final testUrl = '$apiBaseUrl/auth/google/login?callback=joymini://oauth/callback';
      final uri = Uri.parse(testUrl);
      
      // 检查 URL 是否可以打开
      final canLaunch = await canLaunchUrl(uri);
      
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] OAuth configuration check: $canLaunch');
        debugPrint('[DeepLinkOAuthService] Test URL: $testUrl');
      }
      
      return canLaunch;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] OAuth configuration check failed: $e');
      }
      return false;
    }
  }

  /// 初始化 Deep Link 监听
  static void initialize() {
    if (_initialized) return;

    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('[DeepLinkOAuthService] Deep Link Error: $err');
      },
    );

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Deep Link listener initialized');
    }
  }

  /// 处理 Deep Link
  static void _handleDeepLink(Uri uri) {
    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Received URI: $uri');
    }

    // 只处理 oauth 相关的 Deep Link (joymini://oauth/callback)
    if (uri.scheme == 'joymini' && uri.host == 'oauth') {
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] Processing OAuth Deep Link: $uri');
      }

      final token = uri.queryParameters['token'];
      final refreshToken = uri.queryParameters['refreshToken'];

      if (token != null &&
          _loginCompleter != null &&
          !_loginCompleter!.isCompleted) {
        _loginCompleter!.complete({
          'token': token,
          'refreshToken': refreshToken ?? '',
        });

        if (kDebugMode) {
          debugPrint(
            '[DeepLinkOAuthService] OAuth token received: ${token.substring(0, 20)}...',
          );
        }
      } else if (kDebugMode) {
        if (token == null) {
          debugPrint('[DeepLinkOAuthService] No token found in Deep Link');
        }
        if (_loginCompleter == null) {
          debugPrint('[DeepLinkOAuthService] No login completer found');
        } else if (_loginCompleter!.isCompleted) {
          debugPrint(
            '[DeepLinkOAuthService] Login completer already completed',
          );
        }
      }
    } else if (uri.scheme == 'https' || uri.scheme == 'http') {
      // 忽略 HTTP/HTTPS URL，这些不是 OAuth Deep Link 回调
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] Ignoring HTTP/HTTPS URL: $uri');
      }
    } else if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Ignoring non-OAuth Deep Link: $uri');
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
    final state = _generateState();
    final origin = _getWebOrigin();
    final redirectUri = '$origin/oauth/callback';

    // 🚀 安全处理 BaseUrl：去掉末尾多余的斜杠，防止拼出双斜杠 (//)
    final cleanBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    // 🚀 核心修改：去掉 /api/v1，匹配 Nginx 的 ^~ /auth/ 规则
    var loginPath =
        '/auth/$provider/login'
        '?state=${Uri.encodeComponent(state)}'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}';

    if (inviteCode != null && inviteCode.isNotEmpty) {
      loginPath += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
    }

    final loginUrl = cleanBaseUrl + loginPath;

    if (kDebugMode) {
      debugPrint('[DeepLinkOAuthService] Web OAuth URL: $loginUrl');
    }

    if (kIsWeb) {
      try {
        _storeStateInSession(provider, state);
      } catch (e) {
        debugPrint('[DeepLinkOAuthService] Failed to store state: $e');
      }
      try {
        _redirectToUrl(loginUrl);
      } catch (e) {
        throw DeepLinkOAuthException('Failed to redirect: $e');
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    throw DeepLinkOAuthException(
      'Web OAuth initiated. Please check your browser for completion.\n'
      'If not redirected automatically, please refresh the page.',
    );
  }

  /// 移动端 OAuth 登录
  static Future<Map<String, String>> _mobileLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
  }) async {
    initialize();
    _loginCompleter = Completer<Map<String, String>>();

    try {
      final callback = 'joymini://oauth/callback';

      // 🚀 安全处理 BaseUrl
      final cleanBaseUrl = apiBaseUrl.endsWith('/')
          ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
          : apiBaseUrl;

      // 🚀 核心修改：去掉 /api/v1
      var loginPath =
          '/auth/$provider/login?callback=${Uri.encodeComponent(callback)}';

      if (inviteCode != null && inviteCode.isNotEmpty) {
        loginPath += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
      }

      final loginUrl = cleanBaseUrl + loginPath;

      // 🚨 照妖镜：打印准备发射的完整 URL
      if (kDebugMode) {
        debugPrint('\n====================================');
        debugPrint('🚀 [DeepLinkOAuth] 准备发射的完整 URL:');
        debugPrint(loginUrl);
        debugPrint('====================================\n');
      }

      final uri = Uri.parse(loginUrl);

      // 🛡️ 关键修复：在打开 OAuth URL 前，暂时取消 app_links 监听
      // 防止 Android 系统将 URL 发送回应用
      if (_deepLinkSubscription != null) {
        debugPrint('🛡️ [DeepLinkOAuth] 暂时取消 app_links 监听，防止 URL 被错误捕获');
        _deepLinkSubscription!.pause();
      }

      try {
        // 首先检查 URL 是否可以打开
        final canLaunch = await canLaunchUrl(uri);
        if (!canLaunch) {
          debugPrint('❌ [DeepLinkOAuth] canLaunchUrl 返回 false！URL: $loginUrl');
          throw DeepLinkOAuthException(
            'Cannot launch OAuth URL. Check URL format.',
          );
        }

        debugPrint('✅ [DeepLinkOAuth] canLaunchUrl 返回 true，准备打开 URL');

        // 使用 inAppBrowserView 模式（更好的用户体验，减少上下文切换）
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.inAppBrowserView,
        );

        // 🚨 如果发射失败，尝试备用方案
        if (!launched) {
          debugPrint('❌ [DeepLinkOAuth] inAppBrowserView 模式失败！URL: $loginUrl');
          debugPrint('❌ [DeepLinkOAuth] 尝试使用 externalApplication 模式...');

          // 尝试使用 externalApplication 模式作为备用方案
          final launchedExternal = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launchedExternal) {
            debugPrint('❌ [DeepLinkOAuth] externalApplication 也失败了！');
            debugPrint('❌ [DeepLinkOAuth] 尝试使用 platformDefault 模式...');

            // 最后尝试 platformDefault 模式
            final launchedDefault = await launchUrl(
              uri,
              mode: LaunchMode.platformDefault,
            );

            if (!launchedDefault) {
              debugPrint('❌ [DeepLinkOAuth] 所有模式都失败了！');
              throw DeepLinkOAuthException(
                'Failed to launch OAuth URL. Check URL format or device browser availability.',
              );
            }
          }
        }

        debugPrint('✅ [DeepLinkOAuth] URL 已成功打开，等待 Deep Link 回调...');
      } finally {
        // 恢复 app_links 监听，等待真正的 Deep Link 回调
        if (_deepLinkSubscription != null) {
          debugPrint('🛡️ [DeepLinkOAuth] 恢复 app_links 监听，等待 Deep Link 回调');
          _deepLinkSubscription!.resume();
        }
      }

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
    if (kIsWeb) {
      return _webLoginWithProvider(
        provider,
        apiBaseUrl,
        inviteCode: inviteCode,
      );
    } else {
      return _mobileLoginWithProvider(
        provider,
        apiBaseUrl,
        inviteCode: inviteCode,
      );
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

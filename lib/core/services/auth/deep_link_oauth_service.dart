import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'deep_link_oauth_service_web_stub.dart'
    if (dart.library.html) 'deep_link_oauth_service_web.dart';
import 'oauth_web_view_page.dart';

/// OAuth Deep Link 异常
class DeepLinkOAuthException implements Exception {
  final String message;

  DeepLinkOAuthException(this.message);

  @override
  String toString() => message;
}

/// 内嵌 OAuth 浏览器
/// 在我们自己的 WebView 里跑 OAuth 流程，拦截 joymini:// 回调后主动关闭，
/// 彻底解决「授权完成后浏览器页面残留」的问题。
class _OAuthInAppBrowser extends InAppBrowser {
  final Completer<Map<String, String>> completer;
  bool _handled = false;

  _OAuthInAppBrowser({required this.completer});

  /// 检测到 joymini://oauth/callback 时提取 token 并关闭浏览器
  bool _interceptOAuthUrl(dynamic rawUrl) {
    Uri? uri;
    if (rawUrl is Uri) {
      uri = rawUrl;
    } else if (rawUrl is WebUri) {
      uri = Uri.tryParse(rawUrl.toString());
    } else if (rawUrl is String) {
      uri = Uri.tryParse(rawUrl);
    }

    if (uri == null) return false;
    if (uri.scheme != 'joymini' || uri.host != 'oauth') return false;
    if (_handled || completer.isCompleted) return false;

    _handled = true;
    final token = uri.queryParameters['token'];
    final refreshToken = uri.queryParameters['refreshToken'];

    // 关闭浏览器（我们自己的 WebView，直接 close() 可靠）
    close().catchError((_) {});

    if (token != null && token.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[OAuthBrowser] ✅ Token received, closing browser');
      }
      completer.complete({'token': token, 'refreshToken': refreshToken ?? ''});
    } else {
      completer.completeError(
        DeepLinkOAuthException('No token found in OAuth callback URL'),
      );
    }
    return true;
  }

  /// shouldOverrideUrlLoading 是最可靠的拦截点：
  /// WebView 试图跳转到 joymini:// 时，在加载前就被我们捕获
  @override
  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(
    NavigationAction navigationAction,
  ) async {
    final url = navigationAction.request.url;
    if (kDebugMode) {
      debugPrint('[OAuthBrowser] shouldOverrideUrlLoading: $url');
    }
    if (url != null && url.scheme == 'joymini') {
      _interceptOAuthUrl(url);
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  /// onLoadStart 作为双重保险（部分 Android 版本顺序不同）
  @override
  void onLoadStart(Uri? url) {
    if (kDebugMode) debugPrint('[OAuthBrowser] onLoadStart: $url');
    _interceptOAuthUrl(url);
  }

  /// onLoadError 兜底：WKWebView（iOS）在遇到自定义 scheme 时
  /// 可能先触发错误事件，在这里同样尝试提取 token
  @override
  void onLoadError(Uri? url, int code, String message) {
    if (kDebugMode) {
      debugPrint('[OAuthBrowser] onLoadError: $url  code=$code  msg=$message');
    }
    _interceptOAuthUrl(url);
  }

  /// 用户手动关闭浏览器（按返回键 / 点 X）
  @override
  void onExit() {
    if (kDebugMode) debugPrint('[OAuthBrowser] onExit - user closed browser');
    if (!completer.isCompleted) {
      completer.completeError(
        DeepLinkOAuthException('Login cancelled by user'),
      );
    }
  }
}

/// 后端统一 Deep Link OAuth 登录服务
/// 支持 Google、Facebook、Apple 三种 Provider
class DeepLinkOAuthService {
  DeepLinkOAuthService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _deepLinkSubscription;
  static Completer<Map<String, String>>? _loginCompleter;
  static bool _initialized = false;
  // 当前活跃的 InAppBrowser（用于 cancelLogin 时关闭）
  static _OAuthInAppBrowser? _activeBrowser;

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
        // 注：InAppBrowser 流程里这里不会触发（InAppBrowser 内部已拦截）
        // 这里作为 app_links 回退兜底（比如用外部浏览器打开的情况）
        _loginCompleter!.complete({
          'token': token,
          'refreshToken': refreshToken ?? '',
        });

        if (kDebugMode) {
          debugPrint(
            '[DeepLinkOAuthService] OAuth token received via app_links: ${token.substring(0, 20)}...',
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
  /// [context] 不为空时使用 Flutter 原生页面（推荐，有返回键 + 刘海适配）
  static Future<Map<String, String>> loginWithGoogle({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async {
    return _loginWithProvider('google', apiBaseUrl, inviteCode: inviteCode, context: context);
  }

  /// 使用 Facebook 登录
  static Future<Map<String, String>> loginWithFacebook({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async {
    return _loginWithProvider('facebook', apiBaseUrl, inviteCode: inviteCode, context: context);
  }

  /// 使用 Apple 登录
  static Future<Map<String, String>> loginWithApple({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async {
    return _loginWithProvider('apple', apiBaseUrl, inviteCode: inviteCode, context: context);
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

    //安全处理 BaseUrl：去掉末尾多余的斜杠，防止拼出双斜杠 (//)
    final cleanBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    //核心修改：去掉 /api/v1，匹配 Nginx 的 ^~ /auth/ 规则
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
  /// - 有 context：推 OAuthWebViewPage（有返回键 / 刘海适配，推荐）
  /// - 无 context：降级到 InAppBrowser（兼容旧调用）
  static Future<Map<String, String>> _mobileLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
    BuildContext? context,
  }) async {
    final cleanBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    var loginPath =
        '/auth/$provider/login?callback=${Uri.encodeComponent('joymini://oauth/callback')}';

    if (inviteCode != null && inviteCode.isNotEmpty) {
      loginPath += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
    }

    final loginUrl = cleanBaseUrl + loginPath;

    if (kDebugMode) {
      debugPrint('\n====================================');
      debugPrint(' [DeepLinkOAuth] OAuth URL: $loginUrl');
      debugPrint('   方式: ${(context != null) ? "Flutter 页面" : "InAppBrowser"}');
      debugPrint('====================================\n');
    }

    // ── 优先：Flutter 原生页面（有 AppBar 关闭按钮 + SafeArea 刘海适配）──
    if (context != null && context.mounted) {
      final result = await Navigator.of(context).push<Map<String, String>?>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => OAuthWebViewPage(loginUrl: loginUrl, provider: provider),
        ),
      );

      if (result != null) return result;
      throw DeepLinkOAuthException('Login cancelled by user');
    }

    // ── 降级：InAppBrowser（context 不可用时的兜底）────────────────────────
    _loginCompleter = Completer<Map<String, String>>();
    try {
      final browser = _OAuthInAppBrowser(completer: _loginCompleter!);
      _activeBrowser = browser;

      await browser.openUrlRequest(
        urlRequest: URLRequest(url: WebUri(loginUrl)),
        settings: InAppBrowserClassSettings(
          browserSettings: InAppBrowserSettings(
            hideUrlBar: true,
            hideToolbarTop: defaultTargetPlatform != TargetPlatform.iOS,
            hideProgressBar: false,
          ),
          webViewSettings: InAppWebViewSettings(
            useShouldOverrideUrlLoading: true,
            javaScriptEnabled: true,
            userAgent:
                'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
          ),
        ),
      );

      return await _loginCompleter!.future.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          browser.close().catchError((_) {});
          throw DeepLinkOAuthException('OAuth timeout after 120 seconds');
        },
      );
    } catch (e) {
      if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
        _loginCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _activeBrowser = null;
      _loginCompleter = null;
    }
  }

  /// 通用 Provider 登录方法（平台感知）
  static Future<Map<String, String>> _loginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      return _webLoginWithProvider(provider, apiBaseUrl, inviteCode: inviteCode);
    } else {
      return _mobileLoginWithProvider(provider, apiBaseUrl, inviteCode: inviteCode, context: context);
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

  /// 取消登录（用户主动取消或页面销毁）
  static void cancelLogin() {
    // 关闭 InAppBrowser（如果还开着）
    _activeBrowser?.close().catchError((_) {});
    _activeBrowser = null;

    if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
      if (kDebugMode) {
        debugPrint('[DeepLinkOAuthService] Cancelling pending OAuth login');
      }
      _loginCompleter!.completeError(
        DeepLinkOAuthException('Login cancelled by user'),
      );
      _loginCompleter = null;
    }
  }

  /// 获取当前是否正在进行 OAuth 登录
  static bool get isOAuthInProgress => _loginCompleter != null && !_loginCompleter!.isCompleted;

  /// 是否正在使用 InAppBrowser 降级模式（决定生命周期 Observer 是否需要自动取消）
  static bool get isInAppBrowserMode => _activeBrowser != null;

  /// 销毁资源
  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _initialized = false;
    cancelLogin();
  }
}

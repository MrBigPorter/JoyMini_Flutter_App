import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

/// 后端统一 Deep Link OAuth 登录服务
/// 支持 Google、Facebook、Apple 三种 Provider
/// 移动端统一使用 OAuthWebViewPage（官方 webview_flutter，兼容 iOS 26+）
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
      final testUrl = '$apiBaseUrl/auth/google/login?callback=joymini://oauth/callback';
      final uri = Uri.parse(testUrl);
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
      (uri) => _handleDeepLink(uri),
      onError: (err) => debugPrint('[DeepLinkOAuthService] Deep Link Error: $err'),
    );
    _initialized = true;
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] Deep Link listener initialized');
  }

  /// 处理 Deep Link
  static void _handleDeepLink(Uri uri) {
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] Received URI: $uri');

    if (uri.scheme == 'joymini' && uri.host == 'oauth') {
      if (kDebugMode) debugPrint('[DeepLinkOAuthService] Processing OAuth Deep Link: $uri');
      final token = uri.queryParameters['token'];
      final refreshToken = uri.queryParameters['refreshToken'];
      if (token != null && _loginCompleter != null && !_loginCompleter!.isCompleted) {
        _loginCompleter!.complete({'token': token, 'refreshToken': refreshToken ?? ''});
        if (kDebugMode) {
          debugPrint('[DeepLinkOAuthService] OAuth token received via app_links: ${token.substring(0, 20)}...');
        }
      } else if (kDebugMode) {
        if (token == null) debugPrint('[DeepLinkOAuthService] No token found in Deep Link');
        if (_loginCompleter == null) debugPrint('[DeepLinkOAuthService] No login completer found');
        else if (_loginCompleter!.isCompleted) debugPrint('[DeepLinkOAuthService] Login completer already completed');
      }
    } else if (uri.scheme != 'https' && uri.scheme != 'http') {
      if (kDebugMode) debugPrint('[DeepLinkOAuthService] Ignoring non-OAuth Deep Link: $uri');
    }
  }

  /// 使用 Google 登录
  static Future<Map<String, String>> loginWithGoogle({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async =>
      _loginWithProvider('google', apiBaseUrl, inviteCode: inviteCode, context: context);

  /// 使用 Facebook 登录
  static Future<Map<String, String>> loginWithFacebook({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async =>
      _loginWithProvider('facebook', apiBaseUrl, inviteCode: inviteCode, context: context);

  /// 使用 Apple 登录
  static Future<Map<String, String>> loginWithApple({
    required String apiBaseUrl,
    String? inviteCode,
    BuildContext? context,
  }) async =>
      _loginWithProvider('apple', apiBaseUrl, inviteCode: inviteCode, context: context);

  static String _generateState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  static String _getWebOrigin() {
    if (!kIsWeb) return 'http://localhost:4000';
    try { return _getWindowOrigin(); } catch (_) { return 'http://localhost:4000'; }
  }

  static String _getWindowOrigin() {
    if (kIsWeb) {
      try { return _getWebWindowOrigin(); }
      catch (e) {
        debugPrint('[DeepLinkOAuthService] Failed to get window origin: $e');
        return 'http://localhost:4000';
      }
    }
    return 'http://localhost:4000';
  }

  static String _getWebWindowOrigin() => DeepLinkOAuthServiceWeb.getWindowOrigin();

  /// Web 平台 OAuth 登录
  static Future<Map<String, String>> _webLoginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
  }) async {
    final state = _generateState();
    final origin = _getWebOrigin();
    final redirectUri = '$origin/oauth/callback';
    final cleanBaseUrl = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;

    var loginPath =
        '/auth/$provider/login'
        '?state=${Uri.encodeComponent(state)}'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}';
    if (inviteCode != null && inviteCode.isNotEmpty) {
      loginPath += '&inviteCode=${Uri.encodeComponent(inviteCode)}';
    }
    final loginUrl = cleanBaseUrl + loginPath;
    if (kDebugMode) debugPrint('[DeepLinkOAuthService] Web OAuth URL: $loginUrl');

    if (kIsWeb) {
      try { _storeStateInSession(provider, state); } catch (e) {
        debugPrint('[DeepLinkOAuthService] Failed to store state: $e');
      }
      try { _redirectToUrl(loginUrl); } catch (e) {
        throw DeepLinkOAuthException('Failed to redirect: $e');
      }
    }
    await Future.delayed(const Duration(seconds: 2));
    throw DeepLinkOAuthException(
      'Web OAuth initiated. Please check your browser for completion.\n'
      'If not redirected automatically, please refresh the page.',
    );
  }

  /// 移动端 OAuth 登录（使用 OAuthWebViewPage，基于官方 webview_flutter，兼容 iOS 26+）
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
      debugPrint('====================================\n');
    }

    if (context == null || !context.mounted) {
      throw DeepLinkOAuthException(
          'OAuth requires a valid BuildContext (context is null or unmounted)');
    }

    final result = await Navigator.of(context).push<Map<String, String>?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OAuthWebViewPage(loginUrl: loginUrl, provider: provider),
      ),
    );

    if (result != null) return result;
    throw DeepLinkOAuthException('Login cancelled by user');
  }

  static Future<Map<String, String>> _loginWithProvider(
    String provider,
    String apiBaseUrl, {
    String? inviteCode,
    BuildContext? context,
  }) async {
    if (kIsWeb) {
      return _webLoginWithProvider(provider, apiBaseUrl, inviteCode: inviteCode);
    } else {
      return _mobileLoginWithProvider(provider, apiBaseUrl,
          inviteCode: inviteCode, context: context);
    }
  }

  static void _storeStateInSession(String provider, String state) =>
      DeepLinkOAuthServiceWeb.storeStateInSession(provider, state);

  static void _redirectToUrl(String url) =>
      DeepLinkOAuthServiceWeb.redirectToUrl(url);

  /// 取消登录（用户主动取消或页面销毁）
  static void cancelLogin() {
    if (_loginCompleter != null && !_loginCompleter!.isCompleted) {
      if (kDebugMode) debugPrint('[DeepLinkOAuthService] Cancelling pending OAuth login');
      _loginCompleter!.completeError(DeepLinkOAuthException('Login cancelled by user'));
      _loginCompleter = null;
    }
  }

  static bool get isOAuthInProgress =>
      _loginCompleter != null && !_loginCompleter!.isCompleted;

  /// 已废弃：InAppBrowser 已移除，始终返回 false
  static bool get isInAppBrowserMode => false;

  static void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkSubscription = null;
    _initialized = false;
    cancelLogin();
  }
}

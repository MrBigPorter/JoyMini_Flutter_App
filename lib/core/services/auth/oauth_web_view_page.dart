import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// OAuth 登录 WebView 页面（Flutter 原生 Scaffold）
///
/// - AppBar 有 X 关闭按钮（Android 同时支持物理返回键）
/// - SafeArea 自动处理刘海屏 / Dynamic Island
/// - NavigationDelegate 拦截 joymini:// 回调，pop 返回 token
/// - 平台感知 User Agent（iOS → Safari，Android → Chrome）
/// - 5 分钟超时保护，防止用户永久卡在 WebView
class OAuthWebViewPage extends StatefulWidget {
  final String loginUrl;
  final String provider;

  /// 从 loginUrl 提取后端域名，用于检测 OAuth 回调后是否被重定向回后端自身页面
  /// 例：https://dev-api.joyminis.com/auth/facebook/login → https://dev-api.joyminis.com
  static String _extractOrigin(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
    } catch (_) {
      return '';
    }
  }

  const OAuthWebViewPage({
    super.key,
    required this.loginUrl,
    required this.provider,
  });

  @override
  State<OAuthWebViewPage> createState() => _OAuthWebViewPageState();
}

class _OAuthWebViewPageState extends State<OAuthWebViewPage> {
  late final WebViewController _controller;
  late final String _backendOrigin; // 后端 API 域名，用于检测异常回跳
  int _progress = 0;
  bool _handled = false;
  Timer? _timeoutTimer;

  /// 检测后端是否将 OAuth 重定向到自身的 login 页
  /// （说明后端未正确实现 joymini:// callback 跳转）
  bool _isBackendLoginPage(String url) {
    if (_backendOrigin.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
    if (origin != _backendOrigin) return false;
    // /login 和 /login/ 是明显的失败信号；/auth/ 是正常的 OAuth 流程路径，放行
    final path = uri.path;
    return !path.startsWith('/auth/') &&
        (path == '/login' || path.startsWith('/login/') || path.startsWith('/login?'));
  }

  /// 处理系统返回键：WebView 有历史则向后导航，否则关闭页面
  Future<void> _handleBackPress() async {
    final canGoBack = await _controller.canGoBack();
    if (!mounted) return;
    if (canGoBack) {
      await _controller.goBack();
    } else {
      Navigator.of(context).pop(null);
    }
  }

  /// 根据平台返回合适的 User Agent，避免 iOS 上显示 Android 版 OAuth 页面
  static String _buildUserAgent() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
          'AppleWebKit/605.1.15 (KHTML, like Gecko) '
          'Version/17.0 Mobile/15E148 Safari/604.1';
    }
    // Android / other
    return 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  }

  @override
  void initState() {
    super.initState();
    _backendOrigin = OAuthWebViewPage._extractOrigin(widget.loginUrl);

    // 5 分钟超时保护
    _timeoutTimer = Timer(const Duration(minutes: 5), () {
      if (!mounted || _handled) return;
      debugPrint('[OAuthWebViewPage] ⏰ Timeout, closing WebView');
      Navigator.of(context).pop(null);
    });

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_buildUserAgent())
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            debugPrint('[OAuthWebViewPage] onPageStarted: $url');
            _interceptUrl(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('[OAuthWebViewPage] onNavigationRequest: ${request.url}');
            final uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme == 'joymini') {
              _interceptUrl(request.url);
              return NavigationDecision.prevent;
            }
            // 防御：后端 OAuth 未正确跳 joymini:// 而是重定向回自身 /login 页
            // （常见于后端未保存 callback 参数或 Facebook 授权被取消）
            if (_isBackendLoginPage(request.url) && !_handled) {
              _handled = true;
              _timeoutTimer?.cancel();
              debugPrint('[OAuthWebViewPage] 🔙 Backend redirected to login page '
                  '(OAuth failed / backend missing joymini:// redirect): ${request.url}');
              // 使用 addPostFrameCallback 确保在 NavigationDelegate 回调外执行 pop
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(null);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            // 只拦截 joymini:// 回调 URL 引起的资源错误（自定义协议被 WebView 当作 404）
            final url = error.url;
            if (url != null && url.startsWith('joymini://')) {
              debugPrint('[OAuthWebViewPage] joymini:// resource error (expected): $url');
              _interceptUrl(url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _interceptUrl(String rawUrl) {
    if (_handled) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    if (uri.scheme != 'joymini' || uri.host != 'oauth') return;

    final token = uri.queryParameters['token'];
    final refreshToken = uri.queryParameters['refreshToken'];
    final error = uri.queryParameters['error'];

    if (token != null && token.isNotEmpty && mounted) {
      // 授权成功：带 token 返回
      _handled = true;
      _timeoutTimer?.cancel();
      debugPrint('[OAuthWebViewPage] ✅ Token received, popping page');
      Navigator.of(context).pop(<String, String>{
        'token': token,
        'refreshToken': refreshToken ?? '',
      });
    } else if (mounted) {
      // 授权取消或后端返回错误（无 token）：静默关闭 WebView
      _handled = true;
      _timeoutTimer?.cancel();
      debugPrint('[OAuthWebViewPage] ⚠️ OAuth callback without token '
          '(error: $error), closing WebView');
      Navigator.of(context).pop(null);
    }
  }

  String _providerTitle() {
    switch (widget.provider) {
      case 'google':
        return 'login.oauth.google'.tr();
      case 'facebook':
        return 'login.oauth.facebook'.tr();
      case 'apple':
        return 'login.oauth.apple'.tr();
      default:
        return 'login.oauth.signing_in'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // 禁止系统自动 pop，改由 _handleBackPress 决定行为：
      // - WebView 有历史 → 在 WebView 内后退
      // - WebView 无历史 → 关闭页面
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'login.oauth.cancel'.tr(),
            onPressed: () => Navigator.of(context).pop(null),
          ),
          title: Text(
            _providerTitle(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_progress < 100)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress / 100.0 : null,
                    minHeight: 3,
                    color: theme.colorScheme.primary,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


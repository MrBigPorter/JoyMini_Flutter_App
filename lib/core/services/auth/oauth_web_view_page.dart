import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// OAuth 登录 WebView 页面（Flutter 原生 Scaffold）
///
/// - AppBar 有 X 关闭按钮（Android 同时支持物理返回键）
/// - SafeArea 自动处理刘海屏 / Dynamic Island
/// - NavigationDelegate 拦截 joymini:// 回调，pop 返回 token
/// - 使用官方 webview_flutter（无 storyboard，兼容 iOS 26+）
class OAuthWebViewPage extends StatefulWidget {
  final String loginUrl;
  final String provider;

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
  int _progress = 0;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      )
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
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint(
              '[OAuthWebViewPage] onWebResourceError: ${error.url}  ${error.description}',
            );
            if (error.url != null) _interceptUrl(error.url!);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.loginUrl));
  }

  void _interceptUrl(String rawUrl) {
    if (_handled) return;
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    if (uri.scheme != 'joymini' || uri.host != 'oauth') return;

    final token = uri.queryParameters['token'];
    final refreshToken = uri.queryParameters['refreshToken'];

    if (token != null && token.isNotEmpty && mounted) {
      _handled = true;
      debugPrint('[OAuthWebViewPage] ✅ Token received, popping page');
      Navigator.of(context).pop(<String, String>{
        'token': token,
        'refreshToken': refreshToken ?? '',
      });
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

    return Scaffold(
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
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


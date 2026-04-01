import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// OAuth 登录 WebView 页面（Flutter 原生 Scaffold）
///
/// - AppBar 有 X 关闭按钮（Android 同时支持物理返回键）
/// - SafeArea 自动处理刘海屏 / Dynamic Island
/// - shouldOverrideUrlLoading 拦截 joymini:// 回调，pop 返回 token
/// - 不依赖 app_links / InAppBrowser，完全受控
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
  double _progress = 0;
  bool _handled = false;

  // ——— 拦截 joymini://oauth/callback ———
  void _interceptUrl(dynamic rawUrl) {
    if (_handled) return;
    Uri? uri;
    if (rawUrl is Uri) {
      uri = rawUrl;
    } else if (rawUrl is WebUri) {
      uri = Uri.tryParse(rawUrl.toString());
    } else if (rawUrl is String) {
      uri = Uri.tryParse(rawUrl);
    }

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
      // ── AppBar ─────────────────────────────────────────
      appBar: AppBar(
        // 关闭按钮（X）：pop null → 上层 catch 识别为 cancelled
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
      // ── Body：SafeArea 处理刘海 / 底部 Home 指示条 ──────
      body: SafeArea(
        bottom: false, // WebView 延伸到底部（底部边距由系统手势条决定）
        child: Stack(
          children: [
            // WebView
            InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri(widget.loginUrl)),
              initialSettings: InAppWebViewSettings(
                // ⚠️ 必须 true，否则 shouldOverrideUrlLoading 不触发
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
                // 模拟 Chrome UA，避免 Google/Facebook 拒绝 WebView
                userAgent:
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
                    '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
                // 自适应内容大小
                supportZoom: false,
                useWideViewPort: true,
                loadWithOverviewMode: true,
              ),

              // 拦截 joymini:// ← 主路径（最可靠）
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url;
                debugPrint('[OAuthWebViewPage] shouldOverride: $url');
                if (url != null && url.scheme == 'joymini') {
                  _interceptUrl(url);
                  return NavigationActionPolicy.CANCEL;
                }
                return NavigationActionPolicy.ALLOW;
              },

              // 进度条
              onProgressChanged: (controller, progress) {
                setState(() => _progress = progress / 100.0);
              },

              // onLoadStart 双重保险
              onLoadStart: (controller, url) {
                debugPrint('[OAuthWebViewPage] onLoadStart: $url');
                _interceptUrl(url);
              },

              // onReceivedError 兜底（iOS WKWebView 遇到自定义 scheme 有时先报错）
              onReceivedError: (controller, request, error) {
                debugPrint(
                  '[OAuthWebViewPage] onReceivedError: ${request.url}  ${error.description}',
                );
                _interceptUrl(request.url);
              },
            ),

            // 顶部进度条（加载中显示）
            if (_progress < 1.0)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
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


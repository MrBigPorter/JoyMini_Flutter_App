import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'deposit_result_page.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String url;
  final String orderNo;
  const PaymentWebViewPage({super.key, required this.url, required this.orderNo});
  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewMobileState();
}

class _PaymentWebViewMobileState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('wallet/recharge/success')) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => DepositResultPage(orderNo: widget.orderNo),
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment")),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_progress < 100) LinearProgressIndicator(value: _progress / 100.0),
        ],
      ),
    );
  }
}
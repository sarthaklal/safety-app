import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafeWebView extends StatefulWidget {
  final String? url;

  SafeWebView({this.url});

  @override
  _SafeWebViewState createState() => _SafeWebViewState();
}

class _SafeWebViewState extends State<SafeWebView> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    // Initialize the WebViewController
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url ?? 'https://flutter.dev')); // Load the URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebView')),
      body: WebViewWidget(controller: _webViewController),
    );
  }
}

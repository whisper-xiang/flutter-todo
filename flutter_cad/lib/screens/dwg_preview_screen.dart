import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/cad_file.dart';

class DwgPreviewScreen extends StatefulWidget {
  final CadFile cadFile;

  const DwgPreviewScreen({super.key, required this.cadFile});

  @override
  State<DwgPreviewScreen> createState() => _DwgPreviewScreenState();
}

class _DwgPreviewScreenState extends State<DwgPreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 更新加载进度
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('加载失败: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://web.gstarcad.com/openDwg?type=dd071be4cf01cb45c1b8b72d92363f41ec2ab2f7e7700cca150d67c63487a1cb'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cadFile.name),
        actions: [
          IconButton(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

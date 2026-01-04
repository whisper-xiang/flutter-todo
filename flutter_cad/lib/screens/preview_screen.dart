import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'dart:convert';
import '../models/cad_file.dart';

class PreviewScreen extends StatefulWidget {
  final String id;
  final CadFile file;

  const PreviewScreen({super.key, required this.id, required this.file});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              // 如果是本地文件，加载文件内容
              if (widget.file.path != null) {
                _loadLocalFile();
              }
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'ConsoleChannel',
        onMessageReceived: (message) {
          debugPrint('JS 👉 ${message.message}');
        },
      );

    // 根据文件类型加载不同的内容
    await _loadContent();
  }

  Future<void> _loadContent() async {
    String url;

    if (widget.file.path != null && widget.file.path!.startsWith('/')) {
      // 本地文件 - 使用本地HTML文件
      url = 'http://localhost:5500/assets/web/demo/site.html';
    } else if (widget.file.url != null) {
      // 远程文件
      url = widget.file.url!;
    } else {
      // 默认演示页面
      url = 'http://localhost:5500/assets/web/demo/site.html';
    }

    await _controller.loadRequest(Uri.parse(url));
  }

  Future<void> _loadLocalFile() async {
    try {
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Data = base64Encode(bytes);

          // 发送文件数据到WebView
          await _controller.runJavaScript('''
            if (window.loadLocalFile) {
              window.loadLocalFile('${widget.file.name}', 'data:application/octet-stream;base64,$base64Data');
            }
          ''');
        }
      }
    } catch (e) {
      debugPrint('加载本地文件失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // Send message to WebView
              _controller.runJavaScript(
                'receiveFromFlutter("Hello from Flutter!");',
              );
            },
            tooltip: 'Send Message to WebView',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/cad_file.dart';
import '../utils/local_asset_server.dart';

class OcfPreviewScreen extends StatefulWidget {
  final String id;
  final CadFile file;

  const OcfPreviewScreen({super.key, required this.id, required this.file});

  @override
  State<OcfPreviewScreen> createState() => _OcfPreviewScreenState();
}

class _OcfPreviewScreenState extends State<OcfPreviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
             debugPrint('开始加载: $url');
          },
          onPageFinished: (String url) {
            debugPrint('加载完成: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web资源错误: code=${error.errorCode}, description=${error.description}, type=${error.errorType}, url=${error.url}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('加载失败: ${error.description} (代码: ${error.errorCode})'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      );

    try {
      // 尝试设置背景色，macOS 上不支持 setBackgroundColor 会抛出异常，因此直接跳过
      if (!Platform.isMacOS) {
        await controller.setBackgroundColor(const Color(0x00000000));
      }
    } catch (e) {
      debugPrint('设置背景色失败: $e');
    }

    _controller = controller;
    setState(() {
      _isControllerInitialized = true;
    });

    await _loadLocalHtml();
  }

  Future<void> _loadLocalHtml() async {
    final server = LocalAssetServer();
    const host = 'localhost';
    final serverUrl = server.getAssetsUrl(host: host);

    if (serverUrl != null) {
      // 1. 将 OCF 文件托管到本地服务器
      String? ocfUrl;
      try {
        // 假设 widget.file.path 是本地文件路径
        // 如果是 FileProvider 中的虚拟文件，可能需要先下载或获取真实路径
        // 这里假设它有本地路径
        if (widget.file.path != null) {
          ocfUrl = await server.serveFile(widget.file.path!,
              fileName: widget.file.name, host: host);
          debugPrint('OCF文件已托管: $ocfUrl');
        } else {
          debugPrint('错误: OCF文件没有本地路径');
        }
      } catch (e) {
        debugPrint('托管OCF文件失败: $e');
      }

      // 2. 构建带参数的 URL
      String url = '$serverUrl/index.html';
      if (ocfUrl != null) {
        url += '?file=${Uri.encodeComponent(ocfUrl)}';
      }
      
      debugPrint('【OcfPreviewScreen】加载 URL: $url');

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('DEBUG: OCF URL'),
            content: SingleChildScrollView(
              child: SelectableText('URL: $url\n\nFile Path: ${widget.file.path}\nName: ${widget.file.name}'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }

      await _controller.loadRequest(Uri.parse(url));
    } else {
      // Handle server not started error
      debugPrint('Error: Local asset server is not running.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.file.name)),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isControllerInitialized) WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

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
    _initializePreview();
  }
  Future<void> _initializePreview() async {
    // 所有格式走WebView渲染
    await _initializeWebView();
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
    final fileExtension = widget.file.name.split('.').last.toLowerCase();
    debugPrint('文件扩展名: $fileExtension');

    if (widget.file.path != null && widget.file.path!.startsWith('/')) {
      // 本地文件 - 根据文件类型选择不同的webview内容
      if (fileExtension == 'dwg') {
        url =
            'https://web.gstarcad.com/openDwg?type=dd071be4cf01cb45c1b8b72d92363f41ec2ab2f7e7700cca150d67c63487a1cb';
      } else if (fileExtension == 'pdf') {
        url = 'https://mozilla.github.io/pdf.js/web/viewer.html';
      } else if ([
        'jpg',
        'jpeg',
        'png',
        'gif',
        'bmp',
        'webp',
      ].contains(fileExtension)) {
        // 图片文件使用简单的图片查看器
        final bytes = await File(widget.file.path!).readAsBytes();
        final base64Data = base64Encode(bytes);
        url = 'data:image/${_getMimeType(fileExtension)};base64,$base64Data';
      } else if (fileExtension == 'txt') {
        // 文本文件
        final content = await File(widget.file.path!).readAsString();
        final htmlContent =
            '''
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: monospace; padding: 20px; white-space: pre-wrap; }
            </style>
          </head>
          <body>$content</body>
          </html>
        ''';
        await _controller.loadHtmlString(htmlContent);
        return;
      } else if (['doc', 'docx'].contains(fileExtension)) {
        // Word文档 - 创建简单的HTML预览
        try {
          if (fileExtension == 'docx') {
            // 对于.docx文件，显示文件信息
            await _loadDocxContent();
          } else if (fileExtension == 'doc') {
            // 对于.doc文件，使用阿里云盘WebView页面
            url =
                'https://whisper-xiang.github.io/paper-directory/%E5%AD%A6%E6%9C%AF%E8%AE%BA%E6%96%87%E5%9E%8B%E6%AF%95%E4%B8%9A%E8%AE%BA%E6%96%87%E6%92%B0%E5%86%99%E6%8C%87%E5%8D%97(%E6%B3%95%E5%AD%A6%E7%B1%BB%E9%80%82%E7%94%A8).pdf';
            debugPrint('DOC文件URL:~~~~~ $url');
            await _controller.loadRequest(Uri.parse(url));
            return;
          }
          return;
        } catch (e) {
          debugPrint('Word文档预览失败: $e');
          await _showDocErrorPage();
          return;
        }
      } else if (['xls', 'xlsx'].contains(fileExtension)) {
        // Excel文档 - 显示文件信息而不是内容
        try {
          await _showExcelInfoPage();
          return;
        } catch (e) {
          debugPrint('Excel文档预览失败: $e');
          await _showExcelErrorPage();
          return;
        }
      } else {
        // 其他类型默认使用DWG查看器
        url =
            'https://web.gstarcad.com/openDwg?type=dd071be4cf01cb45c1b8b72d92363f41ec2ab2f7e7700cca150d67c63487a1cb';
      }
    } else if (widget.file.url != null) {
      // 远程文件
      url = widget.file.url!;
    } else {
      // 默认演示页面
      url =
          'https://web.gstarcad.com/openDwg?type=dd071be4cf01cb45c1b8b72d92363f41ec2ab2f7e7700cca150d67c63487a1cb';
    }
    debugPrint('加载URL:~~~~~ $url');
    await _controller.loadRequest(Uri.parse(url));
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'gif':
        return 'gif';
      case 'bmp':
        return 'bmp';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
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

  Future<void> _loadDocxContent() async {
    // 对于.docx文件，显示文件信息
    await _showDocInfoPage();
  }

  Future<void> _showDocInfoPage() async {
    final file = File(widget.file.path!);
    final fileSize = await file.length();
    final lastModified = await file.lastModified();

    final infoHtml =
        '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { 
            font-family: Arial, sans-serif; 
            padding: 20px; 
            line-height: 1.6;
            background: #f5f5f5;
          }
          .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 800px;
            margin: 0 auto;
          }
          .header {
            border-bottom: 2px solid #2196F3;
            padding-bottom: 15px;
            margin-bottom: 20px;
          }
          .title {
            color: #2196F3;
            font-size: 24px;
            font-weight: bold;
          }
          .info-grid {
            display: grid;
            grid-template-columns: 120px 1fr;
            gap: 15px;
            margin: 20px 0;
          }
          .info-label {
            font-weight: bold;
            color: #666;
          }
          .info-value {
            color: #333;
          }
          .notice {
            background: #e3f2fd;
            border: 1px solid #bbdefb;
            border-radius: 4px;
            padding: 15px;
            margin-bottom: 20px;
            color: #1565c0;
          }
          .tips {
            background: #f5f5f5;
            border-left: 4px solid #2196F3;
            padding: 15px;
            margin-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="title">📄 ${widget.file.name}</div>
          </div>
          <div class="notice">
            ℹ️ Word文档信息：由于Word文档是二进制格式，无法直接显示内容
          </div>
          <div class="info-grid">
            <div class="info-label">文件名：</div>
            <div class="info-value">${widget.file.name}</div>
            <div class="info-label">文件大小：</div>
            <div class="info-value">${_formatFileSize(fileSize)}</div>
            <div class="info-label">修改时间：</div>
            <div class="info-value">${lastModified.toString().substring(0, 19)}</div>
            <div class="info-label">文件类型：</div>
            <div class="info-value">${widget.file.path!.split('.').last.toUpperCase()} 文档</div>
            <div class="info-label">文件路径：</div>
            <div class="info-value">${widget.file.path}</div>
          </div>
          <div class="tips">
            <strong>💡 提示：</strong><br>
            • 要查看Word文档内容，请使用Microsoft Word、WPS Office或其他文档编辑器<br>
            • 也可以将文档转换为PDF或TXT格式后再导入<br>
            • 系统目前支持PDF和TXT文件的完整预览
          </div>
        </div>
      </body>
      </html>
    ''';
    await _controller.loadHtmlString(infoHtml);
  }

  Future<void> _showDocErrorPage() async {
    final errorHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { 
            font-family: Arial, sans-serif; 
            padding: 20px; 
            text-align: center;
            background: #f5f5f5;
          }
          .error-container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 50px auto;
          }
          .icon { font-size: 48px; color: #f44336; }
          .title { color: #333; font-size: 24px; margin: 20px 0; }
          .message { color: #666; line-height: 1.6; }
        </style>
      </head>
      <body>
        <div class="error-container">
          <div class="icon">📄</div>
          <div class="title">Word文档预览失败</div>
          <div class="message">
            无法预览此Word文档。这可能是因为：<br>
            • 文件格式不受支持<br>
            • 文件已损坏<br>
            • 文件过大<br><br>
            请尝试使用其他应用程序打开此文件。
          </div>
        </div>
      </body>
      </html>
    ''';
    await _controller.loadHtmlString(errorHtml);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _showExcelInfoPage() async {
    final file = File(widget.file.path!);
    final fileSize = await file.length();
    final lastModified = await file.lastModified();

    final infoHtml =
        '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { 
            font-family: Arial, sans-serif; 
            padding: 20px; 
            line-height: 1.6;
            background: #f5f5f5;
          }
          .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 800px;
            margin: 0 auto;
          }
          .header {
            border-bottom: 2px solid #4CAF50;
            padding-bottom: 15px;
            margin-bottom: 20px;
          }
          .title {
            color: #4CAF50;
            font-size: 24px;
            font-weight: bold;
          }
          .info-grid {
            display: grid;
            grid-template-columns: 120px 1fr;
            gap: 15px;
            margin: 20px 0;
          }
          .info-label {
            font-weight: bold;
            color: #666;
          }
          .info-value {
            color: #333;
          }
          .notice {
            background: #e8f5e8;
            border: 1px solid #c8e6c9;
            border-radius: 4px;
            padding: 15px;
            margin-bottom: 20px;
            color: #2e7d32;
          }
          .tips {
            background: #f5f5f5;
            border-left: 4px solid #4CAF50;
            padding: 15px;
            margin-top: 20px;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <div class="title">📊 ${widget.file.name}</div>
          </div>
          <div class="notice">
            ℹ️ Excel文档信息：由于Excel文档是二进制格式，无法直接显示内容
          </div>
          <div class="info-grid">
            <div class="info-label">文件名：</div>
            <div class="info-value">${widget.file.name}</div>
            <div class="info-label">文件大小：</div>
            <div class="info-value">${_formatFileSize(fileSize)}</div>
            <div class="info-label">修改时间：</div>
            <div class="info-value">${lastModified.toString().substring(0, 19)}</div>
            <div class="info-label">文件类型：</div>
            <div class="info-value">${widget.file.path!.split('.').last.toUpperCase()} 表格</div>
            <div class="info-label">文件路径：</div>
            <div class="info-value">${widget.file.path}</div>
          </div>
          <div class="tips">
            <strong>💡 提示：</strong><br>
            • 要查看Excel表格内容，请使用Microsoft Excel、WPS Office或其他表格软件<br>
            • 也可以将表格转换为CSV或TXT格式后再导入<br>
            • 系统目前支持CSV和TXT文件的完整预览
          </div>
        </div>
      </body>
      </html>
    ''';
    await _controller.loadHtmlString(infoHtml);
  }

  Future<void> _showExcelErrorPage() async {
    final errorHtml = '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { 
            font-family: Arial, sans-serif; 
            padding: 20px; 
            text-align: center;
            background: #f5f5f5;
          }
          .error-container {
            background: white;
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            max-width: 600px;
            margin: 50px auto;
          }
          .icon { font-size: 48px; color: #f44336; }
          .title { color: #333; font-size: 24px; margin: 20px 0; }
          .message { color: #666; line-height: 1.6; }
        </style>
      </head>
      <body>
        <div class="error-container">
          <div class="icon">📊</div>
          <div class="title">Excel文档预览失败</div>
          <div class="message">
            无法预览此Excel文档。这可能是因为：<br>
            • 文件格式不受支持<br>
            • 文件已损坏<br>
            • 文件过大<br><br>
            请尝试使用其他应用程序打开此文件。
          </div>
        </div>
      </body>
      </html>
    ''';
    await _controller.loadHtmlString(errorHtml);
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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import '../models/cad_file.dart';
import '../services/pdf_converter_service.dart';
import '../services/online_preview_service.dart';
import 'pdf_preview_screen.dart';

class PptPreviewScreen extends StatefulWidget {
  final CadFile file;

  const PptPreviewScreen({super.key, required this.file});

  @override
  State<PptPreviewScreen> createState() => _PptPreviewScreenState();
}

class _PptPreviewScreenState extends State<PptPreviewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _useWebView = true;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  Future<void> _initializePreview() async {
    try {
      print('尝试加载PowerPoint文件: ${widget.file.path}');
      
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        
        if (!await file.exists()) {
          throw Exception('文件不存在');
        }
        
        print('文件大小: ${await file.length()} bytes');
        
        // 检测文件格式
        final extension = widget.file.name.split('.').last.toLowerCase();
        print('PowerPoint格式: $extension');
        
        if (!['ppt', 'pptx'].contains(extension)) {
          throw Exception('不支持的PowerPoint格式: $extension');
        }
        
        // 默认使用WebView预览
        await _loadWebView();
      }
    } catch (e) {
      print('PowerPoint文件加载失败: $e');
      if (mounted) {
        setState(() {
          _error = 'PowerPoint文件加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadWebView() async {
    try {
      // 使用Microsoft PowerPoint Online查看器
      final officeOnlineUrl = _getOfficeViewerUrl();
      
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (NavigationRequest request) {
              print('导航到: ${request.url}');
              return NavigationDecision.navigate;
            },
            onPageFinished: (String url) {
              print('页面加载完成: $url');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _useWebView = true;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView错误: ${error.description}');
              if (mounted) {
                setState(() {
                  _error = 'WebView加载失败: ${error.description}';
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(officeOnlineUrl));
      
      print('WebView初始化成功!');
    } catch (e) {
      print('WebView初始化失败: $e');
      if (mounted) {
        setState(() {
          _error = 'WebView初始化失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getOfficeViewerUrl() {
    final fileName = widget.file.name;
    
    // 使用Microsoft Office Online查看器
    // 注意：这需要文件可以通过URL访问，对于本地文件我们提供指导
    return 'data:text/html;charset=utf-8,${Uri.encodeComponent('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PowerPoint演示文稿预览</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .file-info {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .file-info h3 {
            margin: 0 0 10px 0;
            color: #333;
        }
        .file-info p {
            margin: 5px 0;
            color: #666;
        }
        .options {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        .option {
            color: white;
            padding: 15px;
            border-radius: 8px;
            text-decoration: none;
            text-align: center;
            transition: background 0.3s;
            cursor: pointer;
        }
        .option:hover {
            opacity: 0.8;
        }
        .option.primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .option.success {
            background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
        }
        .option.warning {
            background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);
            color: #212529;
        }
        .option.info {
            background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
        }
        .success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .instructions {
            background: #e7f3ff;
            border: 1px solid #b3d9ff;
            color: #004085;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .instructions h4 {
            margin: 0 0 10px 0;
        }
        .instructions ol {
            margin: 0;
            padding-left: 20px;
        }
        .instructions li {
            margin: 5px 0;
        }
        .ppt-icon {
            font-size: 48px;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="ppt-icon">📊</div>
            <h1>PowerPoint演示文稿预览</h1>
            <p>本地PPT文件查看器</p>
        </div>
        
        <div class="success">
            <strong>✅ 多种预览方案可用！</strong><br>
            选择最适合您的预览方式来查看演示文稿。
        </div>
        
        <div class="file-info">
            <h3>📁 文件信息</h3>
            <p><strong>文件名：</strong> $fileName</p>
            <p><strong>格式：</strong> ${fileName.split('.').last.toUpperCase()}</p>
            <p><strong>类型：</strong> PowerPoint演示文稿</p>
        </div>
        
        <div class="instructions">
            <h4>🎯 预览方案说明：</h4>
            <ol>
                <li><strong>在线预览：</strong> 使用Microsoft Office Online，完美显示动画和效果</li>
                <li><strong>PDF转换：</strong> 转换为PDF格式，保留内容和基本格式</li>
                <li><strong>其他应用：</strong> 分享到支持PPT预览的其他应用</li>
            </ol>
        </div>
        
        <div class="options">
            <div class="option primary" onclick="window.flutter_inappwebview.callHandler('onlinePreview')">
                🌐 <strong>在线预览</strong><br>
                <small>使用Microsoft Office Online完美预览（推荐）</small>
            </div>
            
            <div class="option success" onclick="window.flutter_inappwebview.callHandler('convertToPdf')">
                📄 <strong>转换为PDF预览</strong><br>
                <small>将PPT转换为PDF格式进行预览</small>
            </div>
            
            <div class="option warning">
                📱 <strong>使用其他应用打开</strong><br>
                <small>分享到PowerPoint、Keynote等应用</small>
            </div>
            
            <div class="option info">
                ℹ️ <strong>查看文件信息</strong><br>
                <small>显示详细的文件属性和元数据</small>
            </div>
        </div>
        
        <div style="margin-top: 30px; text-align: center; color: #666;">
            <p><strong>💡 提示：</strong></p>
            <p>• 在线预览需要网络连接，但效果最佳</p>
            <p>• PDF转换可以离线使用，但动画效果会丢失</p>
            <p>• 建议使用Microsoft PowerPoint或Keynote获得最佳体验</p>
        </div>
    </div>
</body>
</html>
    ''')}';
  }

  Future<void> _convertToPdfAndPreview() async {
    if (widget.file.path == null) return;
    
    setState(() {
      _isConverting = true;
    });

    try {
      print('开始转换PowerPoint为PDF: ${widget.file.path}');
      
      final pdfFile = await PdfConverterService.convertWordToPdf(widget.file.path!);
      
      if (pdfFile != null) {
        print('PDF转换成功: ${pdfFile.path}');
        
        // 导航到PDF预览页面
        if (mounted) {
          final pdfCadFile = CadFile(
            id: widget.file.id,
            name: '${widget.file.name.split('.').first}.pdf',
            path: pdfFile.path,
            type: FileType.pdf,
            size: await pdfFile.length(),
            modifiedAt: DateTime.now(),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PdfPreviewScreen(file: pdfCadFile),
            ),
          );
        }
      } else {
        throw Exception('PDF转换失败');
      }
    } catch (e) {
      print('PDF转换失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF转换失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConverting = false;
        });
      }
    }
  }

  Future<void> _openOnlinePreview() async {
    try {
      print('开始在线预览PowerPoint: ${widget.file.name}');
      
      // 使用在线预览服务创建WebView控制器
      final controller = OnlinePreviewService.createPreviewController(
        widget.file.name,
        filePath: widget.file.path,
        onPageFinished: (url) {
          print('在线预览页面加载完成: $url');
        },
        onError: (error) {
          print('在线预览错误: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('在线预览失败: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
      
      // 导航到在线预览页面
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.deepOrange,
                title: Text(
                  '在线预览 - ${widget.file.name}',
                  style: const TextStyle(color: Colors.white),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('正在使用Jina AI代理服务'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    tooltip: '预览信息',
                  ),
                ],
              ),
              body: WebViewWidget(controller: controller),
            ),
          ),
        );
      }
    } catch (e) {
      print('在线预览失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('在线预览失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text(
          widget.file.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _shareFile,
            icon: const Icon(Icons.share, color: Colors.white),
            tooltip: '分享文件',
          ),
        ],
      ),
      body: _buildContent(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isConverting ? null : _convertToPdfAndPreview,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        icon: _isConverting 
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.picture_as_pdf),
        label: Text(_isConverting ? '转换中...' : '转PDF'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepOrange),
            SizedBox(height: 20),
            Text(
              '正在加载PowerPoint文件...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                'PowerPoint文件预览失败',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _initializePreview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 如果使用WebView，显示WebView
    if (_useWebView) {
      return Column(
        children: [
          // 文件信息栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.grey[50],
            child: Row(
              children: [
                Text('文件: ${widget.file.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('格式: PPT/PPTX'),
                const SizedBox(width: 16),
                const Icon(Icons.slideshow, color: Colors.deepOrange),
              ],
            ),
          ),
          // WebView内容
          Expanded(
            child: WebViewWidget(controller: _controller!),
          ),
        ],
      );
    }

    return const Center(
      child: Text('PowerPoint预览'),
    );
  }

  Future<void> _shareFile() async {
    // TODO: 实现文件分享功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('分享功能开发中...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

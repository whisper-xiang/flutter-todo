import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import '../models/cad_file.dart';
import '../services/pdf_converter_service.dart';
import '../services/online_preview_service.dart';
import 'pdf_preview_screen.dart';

class WordPreviewScreen extends StatefulWidget {
  final CadFile file;

  const WordPreviewScreen({super.key, required this.file});

  @override
  State<WordPreviewScreen> createState() => _WordPreviewScreenState();
}

class _WordPreviewScreenState extends State<WordPreviewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _convertToPdfAndPreview() async {
    if (widget.file.path == null) return;
    
    setState(() {
      _isConverting = true;
    });

    try {
      print('开始转换Word文档为PDF: ${widget.file.path}');
      
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

  Future<void> _initializeWebView() async {
    try {
      print('尝试加载Word文档: ${widget.file.path}');
      
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        
        if (!await file.exists()) {
          throw Exception('文件不存在');
        }
        
        print('文件大小: ${await file.length()} bytes');
        
        // 检测文件格式
        final extension = widget.file.name.split('.').last.toLowerCase();
        print('文档格式: $extension');
        
        if (!['doc', 'docx'].contains(extension)) {
          throw Exception('不支持的文档格式: $extension');
        }
        
        // 使用微软Office Online查看器
        final officeViewerUrl = _getOfficeViewerUrl(widget.file.path!);
        
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
          ..loadRequest(Uri.parse(officeViewerUrl));
        
        print('WebView初始化成功!');
      }
    } catch (e) {
      print('Word文档加载失败: $e');
      if (mounted) {
        setState(() {
          _error = 'Word文档加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getOfficeViewerUrl(String filePath) {
    final fileName = widget.file.name;
    
    // 使用Google Docs查看器（支持在线转换）
    // 注意：这需要文件可以通过URL访问，对于本地文件我们提供指导
    return 'data:text/html;charset=utf-8,${Uri.encodeComponent('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Word文档预览</title>
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
            background: #007bff;
            color: white;
            padding: 15px;
            border-radius: 8px;
            text-decoration: none;
            text-align: center;
            transition: background 0.3s;
            cursor: pointer;
        }
        .option:hover {
            background: #0056b3;
        }
        .option.success {
            background: #28a745;
        }
        .option.success:hover {
            background: #1e7e34;
        }
        .option.warning {
            background: #ffc107;
            color: #212529;
        }
        .option.warning:hover {
            background: #e0a800;
        }
        .option.disabled {
            background: #6c757d;
            cursor: not-allowed;
        }
        .warning {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
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
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📄 Word文档预览</h1>
            <p>本地Word文档查看器</p>
        </div>
        
        <div class="success">
            <strong>✅ PDF转换功能已启用！</strong><br>
            点击下方按钮即可将Word文档转换为PDF格式进行预览。
        </div>
        
        <div class="file-info">
            <h3>📁 文件信息</h3>
            <p><strong>文件名：</strong> $fileName</p>
            <p><strong>格式：</strong> ${fileName.split('.').last.toUpperCase()}</p>
            <p><strong>路径：</strong> $filePath</p>
        </div>
        
        <div class="instructions">
            <h4>🚀 使用说明：</h4>
            <ol>
                <li>点击下方"转换为PDF"按钮</li>
                <li>等待转换完成（几秒钟）</li>
                <li>自动跳转到PDF预览页面</li>
                <li>在PDF页面中查看文档内容</li>
            </ol>
        </div>
        
        <div class="options">
            <div class="option success" onclick="window.flutter_inappwebview.callHandler('convertToPdf')">
                🔄 <strong>转换为PDF并预览</strong><br>
                <small>使用智能转换技术，支持DOC和DOCX格式</small>
            </div>
            
            <div class="option warning">
                🌐 <strong>在线查看器方案</strong><br>
                <small>可以将文件上传到Google Docs查看（需要网络）</small>
            </div>
            
            <div class="option">
                📱 <strong>使用其他应用打开</strong><br>
                <small>分享到支持Word预览的其他应用</small>
            </div>
        </div>
        
        <div style="margin-top: 30px; text-align: center; color: #666;">
            <p><strong>💡 提示：</strong></p>
            <p>• PDF转换会保留文档的文本内容和基本格式</p>
            <p>• 复杂的图片和表格可能需要手动调整</p>
            <p>• 转换后的PDF文件保存在临时目录中</p>
        </div>
    </div>
</body>
</html>
    ''')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
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
        backgroundColor: Colors.green,
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
        label: Text(_isConverting ? '转换中...' : '转换为PDF'),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 20),
            Text(
              '正在加载Word文档...',
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
                'Word文档预览失败',
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
                  _initializeWebView();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _controller!);
  }

  Future<void> _openOnlinePreview() async {
    try {
      print('开始在线预览Word文档: ${widget.file.name}');
      
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
                backgroundColor: Colors.blue,
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

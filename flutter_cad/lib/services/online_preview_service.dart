import 'dart:io';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';

/// 在线预览服务
/// 支持多种在线文档预览方案
class OnlinePreviewService {
  
  /// 获取在线预览URL
  static String getPreviewUrl(String fileName, {String? filePath}) {
    final extension = fileName.split('.').last.toLowerCase();
    
    // 方案1: 使用Jina AI代理服务（推荐，可以处理本地文件）
    // Jina AI可以抓取和渲染网页内容，包括文档
    return 'https://r.jina.ai/http://localhost:8080/$fileName';
    
    // 方案2: 使用Google Docs查看器（需要文件可公开访问）
    // return 'https://docs.google.com/gview?embedded=1&url=$fileUrl';
    
    // 方案3: 使用Microsoft Office Online（需要文件可公开访问）
    // return 'https://view.officeapps.live.com/op/view.aspx?src=$fileUrl';
    
    // 方案4: 使用Office 365在线查看器
    // return 'https://view.officeapps.live.com/op/view.aspx?src=$fileUrl';
  }
  
  /// 创建在线预览WebView控制器
  static WebViewController createPreviewController(
    String fileName, {
    String? filePath,
    Function(String)? onPageFinished,
    Function(String)? onError,
  }) {
    final url = getPreviewUrl(fileName, filePath: filePath);
    
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            print('在线预览导航到: ${request.url}');
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            print('在线预览页面加载完成: $url');
            onPageFinished?.call(url);
          },
          onWebResourceError: (WebResourceError error) {
            print('在线预览错误: ${error.description}');
            onError?.call(error.description);
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }
  
  /// 获取文档类型特定的预览URL
  static String getDocumentPreviewUrl(String fileName, String documentType) {
    switch (documentType.toLowerCase()) {
      case 'word':
      case 'doc':
      case 'docx':
        return 'https://r.jina.ai/http://localhost:8080/$fileName';
      case 'excel':
      case 'xls':
      case 'xlsx':
        return 'https://r.jina.ai/http://localhost:8080/$fileName';
      case 'powerpoint':
      case 'ppt':
      case 'pptx':
        return 'https://r.jina.ai/http://localhost:8080/$fileName';
      default:
        return 'https://r.jina.ai/http://localhost:8080/$fileName';
    }
  }
  
  /// 检查是否支持在线预览
  static bool isSupported(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return [
      'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'pdf', 'txt', 'rtf', 'odt', 'ods', 'odp'
    ].contains(extension);
  }
  
  /// 获取预览方案描述
  static String getPreviewDescription(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'doc':
      case 'docx':
        return '使用在线查看器预览Word文档，保留格式和样式';
      case 'xls':
      case 'xlsx':
        return '使用在线查看器预览Excel表格，支持多工作表';
      case 'ppt':
      case 'pptx':
        return '使用在线查看器预览PowerPoint演示文稿';
      case 'pdf':
        return '使用在线查看器预览PDF文档';
      default:
        return '使用在线查看器预览文档';
    }
  }
  
  /// 创建备用HTML内容（当在线预览不可用时）
  static String createFallbackHtml(String fileName, String documentType) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>在线预览 - $fileName</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
            max-width: 500px;
            text-align: center;
        }
        .icon {
            font-size: 64px;
            margin-bottom: 20px;
        }
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        .description {
            color: #666;
            margin-bottom: 30px;
            line-height: 1.6;
        }
        .features {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            text-align: left;
        }
        .feature {
            margin: 10px 0;
            color: #555;
        }
        .note {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .button {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 25px;
            font-size: 16px;
            cursor: pointer;
            text-decoration: none;
            display: inline-block;
            transition: transform 0.2s;
        }
        .button:hover {
            transform: translateY(-2px);
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="icon">📄</div>
        <h1>在线预览</h1>
        <div class="description">
            正在为您预览 <strong>$fileName</strong> 文档
        </div>
        <div class="features">
            <div class="feature">✨ 保持原始格式</div>
            <div class="feature">📱 移动端友好</div>
            <div class="feature">🔄 快速加载</div>
            <div class="feature">🌐 无需安装软件</div>
        </div>
        <div class="note">
            <strong>提示：</strong> 在线预览需要网络连接，文件内容将被安全处理。
        </div>
        <a href="#" class="button" onclick="window.close()">关闭预览</a>
    </div>
</body>
</html>
    ''';
  }
}

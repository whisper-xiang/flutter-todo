import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    
    // In a real app, you would load different viewers based on file type.
    // For 3D CAD, usually a WebGL viewer url.
    // Here we use a placeholder that demonstrates 2-way communication.
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Received from JS: ${message.message}')),
          );
        },
      )
      ..loadHtmlString(_getHtmlContent(widget.file.name));
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
              _controller.runJavaScript('receiveFromFlutter("Hello from Flutter!");');
            },
            tooltip: 'Send Message to WebView',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  String _getHtmlContent(String filename) {
    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: sans-serif; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; background: #f0f0f0; }
          .viewer { width: 90%; height: 60%; background: #333; color: white; display: flex; align-items: center; justify-content: center; border-radius: 8px; }
          button { padding: 10px 20px; font-size: 16px; margin-top: 20px; cursor: pointer; }
          #log { margin-top: 20px; color: #666; }
        </style>
      </head>
      <body>
        <h2>CAD Viewer Demo</h2>
        <p>File: $filename</p>
        <div class="viewer">
           [ 3D Model Placeholder ]
        </div>
        
        <div id="log">Waiting for Flutter...</div>
        
        <button onclick="sendMessage()">Send Info to Flutter</button>

        <script>
          function sendMessage() {
            if (window.FlutterChannel) {
              FlutterChannel.postMessage('Viewer initialized for ' + '$filename');
            }
          }
          
          function receiveFromFlutter(message) {
            document.getElementById('log').innerText = 'Flutter says: ' + message;
          }
        </script>
      </body>
      </html>
    ''';
  }
}

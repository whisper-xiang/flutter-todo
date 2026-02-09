import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

class LocalAssetServer {
  static final LocalAssetServer _instance = LocalAssetServer._internal();
  factory LocalAssetServer() => _instance;

  HttpServer? _server;
  int? _port;
  Directory? _tempDir;

  LocalAssetServer._internal();

  Future<void> start() async {
    if (_server != null) return;

    _tempDir = await getTemporaryDirectory();
    final webRoot = Directory(p.join(_tempDir!.path, 'assets'));
    if (await webRoot.exists()) {
      await webRoot.delete(recursive: true);
    }
    await webRoot.create(recursive: true);

    // 解压所有 assets/web/ 下的资源到临时目录
    // 注意：AssetManifest.json 在某些构建模式下可能不可用，或者路径有变化
    // 这里增加 try-catch 来处理可能的异常，避免应用启动崩溃
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final webAssetKeys = manifestMap.keys.where((key) => key.startsWith('assets/web/'));

      for (final key in webAssetKeys) {
        final byteData = await rootBundle.load(key);
        // 创建一个与资源路径匹配的文件路径
        final filePath = p.join(_tempDir!.path, key);
        final file = File(filePath);
        if (!await file.parent.exists()) {
            await file.parent.create(recursive: true);
        }
        await file.writeAsBytes(byteData.buffer.asUint8List());
      }
    } catch (e) {
       print('Error loading AssetManifest.json or extracting assets: $e');
       // 如果 AssetManifest.json 加载失败，我们可以尝试直接加载 index.html
       // 这在调试模式下通常是可行的，至少保证核心功能可用
       try {
          final indexContent = await rootBundle.loadString('assets/web/index.html');
          final indexPath = p.join(_tempDir!.path, 'assets/web/index.html');
          final indexFile = File(indexPath);
          if (!await indexFile.parent.exists()) {
             await indexFile.parent.create(recursive: true);
          }
          await indexFile.writeAsString(indexContent);
       } catch (e2) {
          print('Fallback loading of index.html failed: $e2');
       }
    }

    var handler = createStaticHandler(_tempDir!.path, defaultDocument: 'index.html');
    _server = await io.serve(handler, 'localhost', 0);
    _port = _server!.port;
    print('Local asset server started on http://localhost:$_port');
  }

  void stop() {
    _server?.close();
    _server = null;
    _port = null;
    _tempDir?.delete(recursive: true);
    print('Local asset server stopped');
  }

  String? get a_s_s_e_t_s_url => _port != null ? 'http://localhost:$_port/assets/web' : null;
}

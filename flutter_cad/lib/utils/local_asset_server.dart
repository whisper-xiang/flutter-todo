import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
        await _extractFile(key);
      }
    } catch (e) {
      debugPrint('Error loading AssetManifest.json or extracting assets: $e');
    }
    
    // 无论 Manifest 是否加载成功，都显式尝试加载关键文件
    // 这可以解决开发过程中 Manifest 未及时更新导致新文件 404 的问题
    await _extractFile('assets/web/index.html');
    await _extractFile('assets/web/GStarSDK.js');
    await _extractFile('assets/web/3d/index.html');
    await _extractFile('assets/web/3d/1303-5504001-01.ocf4');
    await _extractFile('assets/web/3d/web-viewer-monolith.umd.js');
    await _extractFile('assets/web/3d/view3d-h5.umd.js');

    var handler = createStaticHandler(_tempDir!.path, defaultDocument: 'index.html');
    
    // 使用 loopbackIPv4 (127.0.0.1) 而不是 'localhost'，在某些 Android 设备上更稳定
    _server = await io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
    debugPrint('Local asset server started on http://127.0.0.1:$_port');
  }
  
  Future<void> _extractFile(String key) async {
    try {
      // 尝试加载资源
      final byteData = await rootBundle.load(key);
      final filePath = p.join(_tempDir!.path, key);
      final file = File(filePath);
      if (!await file.parent.exists()) {
          await file.parent.create(recursive: true);
      }
      await file.writeAsBytes(byteData.buffer.asUint8List());
    } catch (e) {
      // 忽略文件不存在的错误，避免日志刷屏，但在调试时可能有用
      debugPrint('Failed to extract $key: $e');
    }
  }

  void stop() {
    _server?.close();
    _server = null;
    _port = null;
    _tempDir?.delete(recursive: true);
    debugPrint('Local asset server stopped');
  }

  String? getAssetsUrl({String host = '127.0.0.1'}) =>
      _port != null ? 'http://$host:$_port/assets/web' : null;

  /// 将本地文件复制到服务器目录并返回可访问的 URL
  Future<String?> serveFile(String filePath,
      {String? fileName, String host = '127.0.0.1'}) async {
    if (_port == null || _tempDir == null) return null;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('Error: Source file does not exist at $filePath');
        return null;
      }

      // 如果未提供文件名，则使用源文件名
      final effectiveFileName = fileName ?? p.basename(filePath);
      // 使用 hash 避免缓存问题，保留原始文件名（含扩展名）
      final uniqueName =
          '${DateTime.now().millisecondsSinceEpoch}_$effectiveFileName';

      // 复制到 assets/web/files 目录
      final targetPath =
          p.join(_tempDir!.path, 'assets', 'web', 'files', uniqueName);
      final targetFile = File(targetPath);

      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }

      await file.copy(targetPath);

      // 再次验证目标文件是否存在
      if (await targetFile.exists()) {
        return 'http://$host:$_port/assets/web/files/$uniqueName';
      } else {
        debugPrint('Error: Target file failed to be created at $targetPath');
        return null;
      }
    } catch (e) {
      debugPrint('Error serving file: $e');
      return null;
    }
  }
}

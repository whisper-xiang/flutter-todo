import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FileStorageService {
  static FileStorageService? _instance;
  static FileStorageService get instance =>
      _instance ??= FileStorageService._();

  FileStorageService._();

  /// 获取应用文档目录 - 用于存储用户数据
  Future<Directory> getDocumentsDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// 获取应用临时目录 - 用于缓存临时文件
  Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// 获取应用支持目录 - 用于存储应用配置等
  Future<Directory> getSupportDirectory() async {
    if (Platform.isIOS) {
      return await getApplicationSupportDirectory();
    } else if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  /// 创建图纸存储目录
  Future<Directory> createDrawingsDirectory() async {
    final docDir = await getDocumentsDirectory();
    final drawingsDir = Directory(path.join(docDir.path, 'drawings'));

    if (!await drawingsDir.exists()) {
      await drawingsDir.create(recursive: true);
    }

    return drawingsDir;
  }

  /// 创建缓存目录
  Future<Directory> createCacheDirectory() async {
    final tempDir = await getTempDirectory();
    final cacheDir = Directory(path.join(tempDir.path, 'cad_cache'));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// 保存图纸文件到本地
  Future<String> saveDrawingToLocal({
    required String fileName,
    required File sourceFile,
    String? subfolder,
  }) async {
    try {
      final drawingsDir = await createDrawingsDirectory();

      // 如果指定了子文件夹，创建子文件夹
      Directory targetDir = drawingsDir;
      if (subfolder != null && subfolder.isNotEmpty) {
        targetDir = Directory(path.join(drawingsDir.path, subfolder));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }
      }

      final targetPath = path.join(targetDir.path, fileName);
      final targetFile = File(targetPath);

      // 如果文件已存在，先删除
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      // 复制文件
      await sourceFile.copy(targetPath);

      debugPrint('图纸已保存到: $targetPath');
      return targetPath;
    } catch (e) {
      debugPrint('保存图纸失败: $e');
      rethrow;
    }
  }

  /// 获取本地保存的图纸列表
  Future<List<File>> getLocalDrawings({String? subfolder}) async {
    try {
      // 扫描多个目录：应用专用目录 + 文档目录 + 下载目录 + 我的iPhone
      final List<Directory> scanDirectories = [];

      // 1. 应用专用目录
      final drawingsDir = await createDrawingsDirectory();
      scanDirectories.add(drawingsDir);

      // 2. 文档目录
      final documentsDir = await getApplicationDocumentsDirectory();
      scanDirectories.add(documentsDir);

      // 3. 下载目录（如果存在）
      try {
        final downloadsDir = Directory(
          path.join(documentsDir.path, 'Downloads'),
        );
        if (await downloadsDir.exists()) {
          scanDirectories.add(downloadsDir);
        }
      } catch (e) {
        debugPrint('无法访问下载目录: $e');
      }

      // 4. 我的iPhone目录 (iOS模拟器共享文件)
      try {
        // 尝试几个可能的"我的iPhone"路径
        final possiblePaths = [
          '/Users/yun/Library/Developer/CoreSimulator/Devices/77134BEA-442A-4F99-B9FF-DA0D993398A7/data/Containers/Shared/AppGroup/My iPhone',
          '/Users/yun/Library/Developer/CoreSimulator/Devices/77134BEA-442A-4F99-B9FF-DA0D993398A7/data/Media/DCIM',
          '/Users/yun/Library/Developer/CoreSimulator/Devices/77134BEA-442A-4F99-B9FF-DA0D993398A7/data/Documents/My iPhone',
        ];

        for (final possiblePath in possiblePaths) {
          final myiPhoneDir = Directory(possiblePath);
          if (await myiPhoneDir.exists()) {
            scanDirectories.add(myiPhoneDir);
            debugPrint('找到我的iPhone目录: $possiblePath');
            break;
          }
        }
      } catch (e) {
        debugPrint('无法访问我的iPhone目录: $e');
      }

      final List<File> allDrawingFiles = [];

      for (Directory scanDir in scanDirectories) {
        Directory searchDir = scanDir;
        if (subfolder != null && subfolder.isNotEmpty) {
          searchDir = Directory(path.join(scanDir.path, subfolder));
        }

        if (await searchDir.exists()) {
          try {
            final files = await searchDir.list().toList();
            final drawingFiles = files.whereType<File>().where((file) {
              final extension = path.extension(file.path).toLowerCase();
              // 支持所有常见的文件类型
              return [
                // CAD文件
                '.dwg', '.dxf', '.ocf',
                // 图片文件
                '.jpg',
                '.jpeg',
                '.png',
                '.gif',
                '.bmp',
                '.webp',
                '.svg',
                '.ico',
                // 文档文件
                '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
                // 文本文件
                '.txt', '.md', '.rtf', '.csv', '.json', '.xml', '.html', '.htm',
                // 音频文件
                '.mp3', '.wav', '.flac', '.aac', '.m4a', '.ogg',
                // 视频文件
                '.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv', '.webm',
                // 压缩文件
                '.zip', '.rar', '.7z', '.tar', '.gz',
                // 其他常见格式
                '.psd', '.ai', '.sketch', '.fig', '.epub', '.mobi',
              ].contains(extension);
            }).toList();

            allDrawingFiles.addAll(drawingFiles);
            debugPrint('在 ${searchDir.path} 中找到 ${drawingFiles.length} 个图纸文件');
          } catch (e) {
            debugPrint('扫描目录失败 ${searchDir.path}: $e');
          }
        }
      }

      // 去重（基于文件路径）
      final uniqueFiles = <File>{};
      for (final file in allDrawingFiles) {
        uniqueFiles.add(file);
      }

      // 按修改时间排序，最新的在前
      final sortedFiles = uniqueFiles.toList();
      sortedFiles.sort((a, b) {
        final aModified = a.lastModifiedSync();
        final bModified = b.lastModifiedSync();
        return bModified.compareTo(aModified);
      });

      debugPrint('总共找到 ${sortedFiles.length} 个唯一的图纸文件');
      return sortedFiles;
    } catch (e) {
      debugPrint('获取本地图纸列表失败: $e');
      return [];
    }
  }

  /// 删除本地图纸
  Future<bool> deleteLocalDrawing(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('图纸已删除: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除图纸失败: $e');
      return false;
    }
  }

  /// 获取文件大小
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      debugPrint('获取文件大小失败: $e');
      return 0;
    }
  }

  /// 清理缓存文件
  Future<void> clearCache() async {
    try {
      final cacheDir = await createCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        debugPrint('缓存已清理');
      }
    } catch (e) {
      debugPrint('清理缓存失败: $e');
    }
  }

  /// 获取存储空间信息
  Future<Map<String, int>> getStorageInfo() async {
    try {
      final drawingsDir = await createDrawingsDirectory();
      final cacheDir = await createCacheDirectory();

      int drawingsSize = 0;
      int cacheSize = 0;

      // 计算图纸文件夹大小
      if (await drawingsDir.exists()) {
        await for (final entity in drawingsDir.list(recursive: true)) {
          if (entity is File) {
            drawingsSize += await entity.length();
          }
        }
      }

      // 计算缓存大小
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            cacheSize += await entity.length();
          }
        }
      }

      return {
        'drawings': drawingsSize,
        'cache': cacheSize,
        'total': drawingsSize + cacheSize,
      };
    } catch (e) {
      debugPrint('获取存储信息失败: $e');
      return {'drawings': 0, 'cache': 0, 'total': 0};
    }
  }
}

import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AssetsFileService {
  static final AssetsFileService _instance = AssetsFileService._internal();
  factory AssetsFileService() => _instance;
  AssetsFileService._internal();

  /// 获取assets中的测试文件列表（从配置文件读取）
  static Future<List<String>> getTestFiles() async {
    try {
      // 方案1：从配置文件读取
      final configString = await rootBundle.loadString(
        'assets/config/test_files.json',
      );
      final configData = jsonDecode(configString) as Map<String, dynamic>;
      final testFilesData = configData['test_files'] as List;

      final List<String> filePaths = [];
      for (final item in testFilesData) {
        if (item is Map<String, dynamic>) {
          filePaths.add(item['path'] as String);
        }
      }

      print('从配置文件加载了 ${filePaths.length} 个测试文件');
      return filePaths;
    } catch (e) {
      print('从配置文件读取失败，使用预定义列表: $e');

      // 方案2：预定义的测试文件列表（备用方案）
      const List<String> predefinedFiles = [
        'assets/test_files/sample2.pdf',
        'assets/test_files/sample1.txt',
        'assets/test_files/sample1.csv',
        'assets/test_files/sample2.doc',
        'assets/test_files/sample3.docx',
        'assets/test_files/sample2.xls',
        'assets/test_files/sample3.xlsx',
        'assets/test_files/sample3.ppt',
        'assets/test_files/file_example_JPG_100kB.jpg',
        'assets/test_files/file_example_PNG_500kB.png',
        'assets/test_files/file_example_GIF_500kB.gif',
        'assets/test_files/file_example_WEBP_50kB.webp',
        'assets/test_files/file_example_OGG_480_1_7mg.ogg',
        'assets/test_files/file_example_AVI_480_750kB.avi',
        'assets/test_files/file_example_WEBM_480_900KB.webm',
        'assets/test_files/file_example_WMV_480_1_2MB.wmv',
        'assets/test_files/电磁铁.dwg',
      ];

      return predefinedFiles;
    }
  }

  /// 将assets文件复制到应用文档目录
  Future<File> copyAssetToFile(String assetPath) async {
    try {
      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(assetPath);
      final localPath = path.join(directory.path, fileName);

      // 检查文件是否已存在
      final file = File(localPath);
      if (await file.exists()) {
        return file;
      }

      // 从assets读取数据
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();

      // 写入本地文件
      await file.writeAsBytes(bytes);

      print('Assets文件复制成功: $localPath');
      return file;
    } catch (e) {
      print('复制assets文件失败: $e');
      rethrow;
    }
  }

  /// 初始化所有测试文件
  Future<List<File>> initializeTestFiles() async {
    final List<File> files = [];

    // 动态获取测试文件列表
    final testFileList = await getTestFiles();

    for (final assetPath in testFileList) {
      try {
        final file = await copyAssetToFile(assetPath);
        files.add(file);
      } catch (e) {
        print('初始化测试文件失败: $assetPath, 错误: $e');
      }
    }

    return files;
  }

  /// 获取测试文件信息
  Future<List<Map<String, dynamic>>> getTestFilesInfo() async {
    final List<Map<String, dynamic>> filesInfo = [];

    // 动态获取测试文件列表
    final testFileList = await getTestFiles();

    for (final assetPath in testFileList) {
      try {
        final file = await copyAssetToFile(assetPath);
        final stat = await file.stat();

        filesInfo.add({
          'name': path.basename(assetPath),
          'path': file.path,
          'size': stat.size,
          'modified': stat.modified,
          'type': path.extension(assetPath).toLowerCase(),
        });
      } catch (e) {
        print('获取文件信息失败: $assetPath, 错误: $e');
      }
    }

    return filesInfo;
  }
}

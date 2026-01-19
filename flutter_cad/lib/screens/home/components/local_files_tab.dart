/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-19 15:22:21
 */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/cad_file.dart';
import '../../../services/file_storage_service.dart';
import '../../../services/assets_file_service.dart';

class LocalFilesTab extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const LocalFilesTab({super.key, required this.scaffoldKey});

  @override
  State<LocalFilesTab> createState() => _LocalFilesTabState();
}

class _LocalFilesTabState extends State<LocalFilesTab>
    with SingleTickerProviderStateMixin {
  final FileStorageService _storageService = FileStorageService.instance;
  List<File> _recentFiles = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadRecentFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentFiles() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // 加载本地文件
      final files = await _storageService.getLocalDrawings();
      print('本地文件数量: ${files.length}');

      // 加载assets测试文件
      final assetsService = AssetsFileService();
      final assetsFiles = await assetsService.initializeTestFiles();
      print('Assets文件数量: ${assetsFiles.length}');

      // 合并文件列表
      final allFiles = [...files, ...assetsFiles];
      print('总文件数量: ${allFiles.length}');

      // 打印所有文件名用于调试
      for (final file in allFiles) {
        print('文件: ${file.path.split('/').last}');
      }

      if (mounted) {
        setState(() {
          _recentFiles = allFiles.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openFileWithNative(File file) async {
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final fileId = 'local-native-${file.path.hashCode}';
    final extension = fileName.split('.').last.toLowerCase();

    // 根据文件扩展名确定文件类型
    FileType fileType;
    if (['dwg', 'dxf'].contains(extension)) {
      fileType = FileType.cad2d;
    } else if ([
      'ocf',
      'sldprt',
      'step',
      'stp',
      'iges',
      'igs',
      'hsf',
    ].contains(extension)) {
      fileType = FileType.cad3d;
    } else if (['pdf'].contains(extension)) {
      fileType = FileType.pdf;
    } else if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
    ].contains(extension)) {
      fileType = FileType.image;
    } else {
      fileType = FileType.unknown;
    }

    final cadFile = CadFile(
      id: fileId,
      name: fileName,
      path: file.path,
      url: null,
      type: fileType,
      modifiedAt: DateTime.now(),
      size: fileSize,
    );

    if (mounted) {
      // CAD文件使用HOOPS预览，其他文件使用普通预览
      if (fileType == FileType.cad2d || fileType == FileType.cad3d) {
        context.push('/hoops-preview/$fileId', extra: cadFile);
      } else {
        context.push('/preview/$fileId', extra: cadFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地文件'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            tooltip: '本地文件',
            onPressed: () => context.push('/local'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: () => _loadRecentFiles(),
          ),
        ],
      ),
      body: _buildFileList(),
    );
  }

  Widget _buildFileList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentFiles.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _recentFiles.length,
      itemBuilder: (context, index) {
        final file = _recentFiles[index];
        return ListTile(
          leading: Icon(
            _getFileIcon(file.path.split('/').last),
            color: _getFileIconColor(file.path.split('/').last),
          ),
          title: Text(file.path.split('/').last),
          subtitle: Text(_formatFileSize(file.lengthSync())),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _openFileWithNative(file),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('暂无本地文件', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('点击右上角导入按钮添加文件', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/local'),
              child: const Text('管理本地文件'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case '.dwg':
      case '.dxf':
        return Icons.design_services;
      case '.ocf':
        return Icons.view_in_ar;
      case '.pdf':
        return Icons.picture_as_pdf;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return Icons.image;
      case '.doc':
      case '.docx':
        return Icons.description;
      case '.txt':
        return Icons.text_snippet;
      case '.xls':
      case '.xlsx':
        return Icons.table_chart;
      case '.ppt':
      case '.pptx':
        return Icons.slideshow;
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
      case '.m4a':
      case '.ogg':
        return Icons.audiotrack;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.mkv':
      case '.webm':
        return Icons.videocam;
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return Icons.archive;
      case '.psd':
      case '.ai':
      case '.sketch':
      case '.fig':
        return Icons.brush;
      case '.epub':
      case '.mobi':
        return Icons.menu_book;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case '.dwg':
      case '.dxf':
        return Colors.orange;
      case '.ocf':
        return Colors.purple;
      case '.pdf':
        return Colors.red;
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return Colors.blue;
      case '.doc':
      case '.docx':
        return Colors.blue;
      case '.txt':
        return Colors.grey;
      case '.xls':
      case '.xlsx':
        return Colors.green;
      case '.ppt':
      case '.pptx':
        return Colors.orange;
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
      case '.m4a':
      case '.ogg':
        return Colors.purple;
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.mkv':
      case '.webm':
        return Colors.red;
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return Colors.brown;
      case '.psd':
      case '.ai':
      case '.sketch':
      case '.fig':
        return Colors.purple;
      case '.epub':
      case '.mobi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语 243267674@qq.com
 * @LastEditTime: 2026-01-21 17:11:33
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

      // 按文件扩展名去重，每种格式只保留一个文件
      final Map<String, File> uniqueFiles = {};
      for (final file in allFiles) {
        final fileName = file.path.split('/').last;
        final extension = fileName.split('.').last.toLowerCase();
        
        // 优先级：assets文件 > 本地文件
        // 如果该扩展名还没有文件，或者当前文件是assets文件而现有文件不是assets文件
        if (!uniqueFiles.containsKey(extension)) {
          uniqueFiles[extension] = file;
        } else {
          final existingFile = uniqueFiles[extension]!;
          // 如果当前文件是assets文件而现有文件不是，则替换
          if (file.path.contains('assets') && !existingFile.path.contains('assets')) {
            uniqueFiles[extension] = file;
          }
        }
      }

      // 按文件类型重要性排序
      final List<String> typeOrder = [
        'dwg', 'dxf', 'ocf', 'obj', 'hsf', // CAD文件
        'pdf', // PDF文件
        'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', // 图片文件
        'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm', // 视频文件
        'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', // 音频文件
        'txt', 'md', 'json', 'xml', 'html', 'htm', 'csv', // 文本文件
        'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', // Office文档
        'zip', 'rar', '7z', 'tar', 'gz', // 压缩文件
        'psd', 'ai', 'sketch', 'fig', 'epub', 'mobi', // 其他文件
      ];

      final deduplicatedFiles = <File>[];
      for (final type in typeOrder) {
        if (uniqueFiles.containsKey(type)) {
          deduplicatedFiles.add(uniqueFiles[type]!);
        }
      }
      
      // 添加不在预定义顺序中的文件
      for (final entry in uniqueFiles.entries) {
        if (!typeOrder.contains(entry.key)) {
          deduplicatedFiles.add(entry.value);
        }
      }
      print('去重后文件数量: ${deduplicatedFiles.length}');

      // 打印去重后的文件名用于调试
      for (final file in deduplicatedFiles) {
        print('文件: ${file.path.split('/').last}');
      }

      if (mounted) {
        setState(() {
          _recentFiles = deduplicatedFiles;
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
      'obj',
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
    } else if ([
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'mkv',
      'webm',
    ].contains(extension)) {
      fileType = FileType.video;
    } else if ([
      'mp3',
      'wav',
      'flac',
      'aac',
      'm4a',
      'ogg',
    ].contains(extension)) {
      fileType = FileType.audio;
    } else if ([
      'txt',
      'md',
      'json',
      'xml',
      'html',
      'htm',
      'csv',
    ].contains(extension)) {
      fileType = FileType.text;
    } else if ([
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
    ].contains(extension)) {
      fileType = FileType.document;
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
      // 根据文件类型进行不同的处理
      if (fileType == FileType.cad2d && extension == 'dwg') {
        // DWG文件使用WebView预览
        context.push('/dwg-preview/$fileId', extra: cadFile);
      } else if (fileType == FileType.cad2d || fileType == FileType.cad3d) {
        // 其他CAD文件使用HOOPS预览
        context.push('/hoops-preview/$fileId', extra: cadFile);
      } else if (fileType == FileType.pdf) {
        // PDF文件使用专门的PDF预览页面
        context.push('/pdf-preview/$fileId', extra: cadFile);
      } else if (fileType == FileType.image || fileType == FileType.text || fileType == FileType.video || fileType == FileType.audio) {
        // Flutter原生支持的文件类型使用增强预览
        context.push('/enhanced-preview/$fileId', extra: cadFile);
      } else if (fileType == FileType.document) {
        // 文档文件暂不支持
        _showUnsupportedFormatDialog('Office文档', '暂不支持Office文档预览，将逐步添加相关插件');
      } else {
        // 未知格式
        _showUnsupportedFormatDialog('未知格式', '暂不支持此文件格式预览');
      }
    }
  }

  void _showUnsupportedFormatDialog(String format, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$format预览'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件预览'),
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
            const Text('暂无文件', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('已按文件类型去重显示', style: TextStyle(color: Colors.grey)),
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

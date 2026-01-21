import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import '../services/file_storage_service.dart';
import '../services/assets_file_service.dart';
import '../models/cad_file.dart';

class LocalFilesScreen extends StatefulWidget {
  const LocalFilesScreen({super.key});

  @override
  State<LocalFilesScreen> createState() => _LocalFilesScreenState();
}

class _LocalFilesScreenState extends State<LocalFilesScreen> {
  final FileStorageService _storageService = FileStorageService.instance;
  List<File> _localDrawings = [];
  bool _isLoading = false;
  Map<String, int>? _storageInfo;

  @override
  void initState() {
    super.initState();
    _loadLocalDrawings();
    _loadStorageInfo();
  }

  Future<void> _loadLocalDrawings() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // 只加载assets中的文件
      final assetsFiles = await AssetsFileService().initializeTestFiles();
      
      if (mounted) {
        setState(() {
          _localDrawings = assetsFiles;
          _isLoading = false;
        });
        debugPrint('Assets文件数量: ${assetsFiles.length}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载Assets文件失败: $e')));
      }
    }
  }

  Future<void> _loadStorageInfo() async {
    final info = await _storageService.getStorageInfo();
    if (mounted) {
      setState(() => _storageInfo = info);
    }
  }

  Future<void> _openFileForPreview(File file) async {
    try {
      final fileName = path.basename(file.path);
      final extension = path.extension(fileName).toLowerCase();

      // 根据文件扩展名确定文件类型
      FileType fileType;
      if (['.dwg', '.dxf'].contains(extension)) {
        fileType = FileType.cad2d;
      } else if (['.ocf'].contains(extension)) {
        fileType = FileType.cad3d;
      } else if (['.pdf'].contains(extension)) {
        fileType = FileType.pdf;
      } else if (['.doc', '.docx'].contains(extension)) {
        fileType = FileType.unknown; // 可以添加新的文档类型
      } else if (['.xls', 'xlsx'].contains(extension)) {
        fileType = FileType.unknown; // 可以添加新的表格类型
      } else if ([
        '.jpg',
        '.png',
        '.gif',
        '.bmp',
        '.webp',
      ].contains(extension)) {
        fileType = FileType.image;
      } else {
        fileType = FileType.unknown;
      }

      // 创建CadFile对象
      final cadFile = CadFile(
        id: 'local-${file.path.hashCode}',
        name: fileName,
        path: file.path,
        url: null,
        type: fileType,
        modifiedAt: await file.lastModified(),
        size: await file.length(),
      );

      // 跳转到预览页面
      if (mounted) {
        // CAD文件使用HOOPS预览，其他文件使用普通预览
        if (fileType == FileType.cad2d || fileType == FileType.cad3d) {
          context.push('/hoops-preview/${cadFile.id}', extra: cadFile);
        } else {
          context.push('/preview/${cadFile.id}', extra: cadFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('打开文件失败: $e')));
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets文件'),
        actions: [
          IconButton(
            onPressed: _loadLocalDrawings,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
          IconButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              await _storageService.clearCache();
              await _loadStorageInfo();
              if (mounted) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('缓存已清理')),
                );
              }
            },
            icon: const Icon(Icons.cleaning_services),
            tooltip: '清理缓存',
          ),
        ],
      ),
      body: Column(
        children: [
          // 存储信息卡片
          if (_storageInfo != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '存储信息',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '图纸文件: ${_formatFileSize(_storageInfo!['drawings']!)}',
                    ),
                    Text('缓存文件: ${_formatFileSize(_storageInfo!['cache']!)}'),
                    Text('总计: ${_formatFileSize(_storageInfo!['total']!)}'),
                  ],
                ),
              ),
            ),

          // 文件列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _localDrawings.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('暂无Assets文件', style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text(
                          '点击刷新按钮重新加载文件',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _localDrawings.length,
                    itemBuilder: (context, index) {
                      final file = _localDrawings[index];

                      return FutureBuilder<int>(
                        future: _storageService.getFileSize(file.path),
                        builder: (context, snapshot) {
                          final fileSize = snapshot.data ?? 0;
                          final fileName = path.basename(file.path);
                          final filePath = file.path;

                          // 判断文件来源
                          String source = 'Assets';
                          if (filePath.contains('/My iPhone/') ||
                              filePath.contains('My iPhone')) {
                            source = '我的iPhone';
                          } else if (filePath.contains(
                            '/Documents/Downloads/',
                          )) {
                            source = '下载';
                          } else if (filePath.contains('/Documents/')) {
                            source = '文档';
                          } else if (filePath.contains(
                            '/Application Support/',
                          )) {
                            source = '应用';
                          }

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: _buildFileIcon(fileName),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$source • ${_formatFileSize(fileSize)}'),
                                const SizedBox(height: 2),
                                Text(
                                  filePath,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'preview':
                                    _openFileForPreview(file);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'preview',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('预览'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => _openFileForPreview(file),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    switch (extension) {
      // CAD文件
      case '.dwg':
      case '.dxf':
        return Icon(Icons.design_services, size: 20, color: Colors.orange);
      case '.ocf':
        return Icon(Icons.view_in_ar, size: 20, color: Colors.purple);

      // 图片文件
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.bmp':
      case '.webp':
        return Icon(Icons.image, size: 20, color: Colors.blue);
      case '.svg':
        return Icon(Icons.crop_original, size: 20, color: Colors.purple);
      case '.ico':
        return Icon(Icons.apps, size: 20, color: Colors.grey);

      // 文档文件
      case '.pdf':
        return Icon(Icons.picture_as_pdf, size: 20, color: Colors.red);
      case '.doc':
      case '.docx':
        return Icon(Icons.description, size: 20, color: Colors.blue);
      case '.xls':
      case '.xlsx':
        return Icon(Icons.table_chart, size: 20, color: Colors.green);
      case '.ppt':
      case '.pptx':
        return Icon(Icons.slideshow, size: 20, color: Colors.orange);

      // 文本文件
      case '.txt':
        return Icon(Icons.text_snippet, size: 20, color: Colors.grey);
      case '.md':
        return Icon(Icons.code, size: 20, color: Colors.black);
      case '.rtf':
        return Icon(Icons.text_fields, size: 20, color: Colors.brown);
      case '.csv':
        return Icon(Icons.table_rows, size: 20, color: Colors.teal);
      case '.json':
        return Icon(Icons.data_object, size: 20, color: Colors.blue);
      case '.xml':
        return Icon(Icons.code, size: 20, color: Colors.orange);
      case '.html':
      case '.htm':
        return Icon(Icons.language, size: 20, color: Colors.blue);

      // 音频文件
      case '.mp3':
      case '.wav':
      case '.flac':
      case '.aac':
      case '.m4a':
      case '.ogg':
        return Icon(Icons.audiotrack, size: 20, color: Colors.purple);

      // 视频文件
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
      case '.flv':
      case '.mkv':
      case '.webm':
        return Icon(Icons.videocam, size: 20, color: Colors.red);

      // 压缩文件
      case '.zip':
      case '.rar':
      case '.7z':
      case '.tar':
      case '.gz':
        return Icon(Icons.archive, size: 20, color: Colors.brown);

      // 设计文件
      case '.psd':
        return Icon(Icons.brush, size: 20, color: Colors.purple);
      case '.ai':
        return Icon(Icons.palette, size: 20, color: Colors.orange);
      case '.sketch':
        return Icon(Icons.draw, size: 20, color: Colors.yellow);
      case '.fig':
        return Icon(Icons.design_services, size: 20, color: Colors.red);

      // 电子书
      case '.epub':
      case '.mobi':
        return Icon(Icons.menu_book, size: 20, color: Colors.green);

      // 其他文件
      default:
        return Icon(Icons.insert_drive_file, size: 20, color: Colors.grey);
    }
  }
}

/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 13:30:48
 */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/cad_file.dart';
import '../../../services/file_storage_service.dart';

class LocalFilesTab extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const LocalFilesTab({super.key, required this.scaffoldKey});

  @override
  State<LocalFilesTab> createState() => _LocalFilesTabState();
}

class _LocalFilesTabState extends State<LocalFilesTab> {
  final FileStorageService _storageService = FileStorageService.instance;
  List<File> _recentFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final files = await _storageService.getLocalDrawings();
      if (mounted) {
        setState(() {
          _recentFiles = files.take(5).toList();
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

  Future<void> _openFileForPreview(File file) async {
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final fileId = 'local-${file.path.hashCode}';

    final cadFile = CadFile(
      id: fileId,
      name: fileName,
      path: file.path,
      url: null,
      type: FileType.cad2d,
      modifiedAt: DateTime.now(),
      size: fileSize,
    );
    if (mounted) {
      context.push('/preview/$fileId', extra: cadFile);
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
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentFiles.isNotEmpty) ...[
            _buildRecentFilesHeader(),
            ..._recentFiles.map(
              (file) => ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(file.path.split('/').last),
                subtitle: Text('本地文件'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _openFileForPreview(file),
              ),
            ),
            const Divider(),
          ],
          if (_recentFiles.isEmpty)
            _buildEmptyState()
          else
            _buildContentState(),
        ],
      ),
    );
  }

  Widget _buildRecentFilesHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '最近文件',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () => context.push('/local'),
            child: const Text('查看全部'),
          ),
        ],
      ),
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

  Widget _buildContentState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder, size: 64, color: Colors.teal),
            const SizedBox(height: 16),
            Text(
              '已找到 ${_recentFiles.length} 个本地文件',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/local'),
              child: const Text('查看全部文件'),
            ),
          ],
        ),
      ),
    );
  }
}

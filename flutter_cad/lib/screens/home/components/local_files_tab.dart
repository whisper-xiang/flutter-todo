/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 16:29:28
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

class _LocalFilesTabState extends State<LocalFilesTab>
    with SingleTickerProviderStateMixin {
  final FileStorageService _storageService = FileStorageService.instance;
  List<File> _recentFiles = [];
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

  Future<void> _openFileWithWebView(File file) async {
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final fileId = 'local-webview-${file.path.hashCode}';

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
      context.push('/webview-preview/$fileId', extra: cadFile);
    }
  }

  Future<void> _openFileWithNative(File file) async {
    final fileSize = await file.length();
    final fileName = file.path.split('/').last;
    final fileId = 'local-native-${file.path.hashCode}';

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
      context.push('/native-preview/$fileId', extra: cadFile);
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.web), text: 'WebView渲染'),
            Tab(icon: Icon(Icons.phone_android), text: 'Flutter原生'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileList(isWebView: true),
          _buildFileList(isWebView: false),
        ],
      ),
    );
  }

  Widget _buildFileList({required bool isWebView}) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recentFiles.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        ..._recentFiles.map(
          (file) => ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(file.path.split('/').last),
            subtitle: Text(isWebView ? 'WebView渲染' : 'Flutter原生'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => isWebView
                ? _openFileWithWebView(file)
                : _openFileWithNative(file),
          ),
        ),
        const Divider(),
      ],
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
}

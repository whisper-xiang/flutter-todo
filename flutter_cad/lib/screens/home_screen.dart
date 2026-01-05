/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 10:09:24
 */
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/cad_file.dart';
import '../services/file_storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _LocalFilesTab(scaffoldKey: _scaffoldKey),
          _CloudFilesTab(scaffoldKey: _scaffoldKey),
          _ProfileTab(scaffoldKey: _scaffoldKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '本地文件'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: '云图'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text('轻语'),
            accountEmail: const Text('243267674@qq.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 40, color: Colors.blue),
            ),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('个人信息'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('设置'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _LocalFilesTab extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _LocalFilesTab({required this.scaffoldKey});

  @override
  State<_LocalFilesTab> createState() => _LocalFilesTabState();
}

class _LocalFilesTabState extends State<_LocalFilesTab> {
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
          _recentFiles = files.take(5).toList(); // 只显示最近5个文件
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
    // 生成安全的ID，使用文件路径的hash而不是直接使用路径
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
            backgroundColor: Colors.blue,
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
          // 最近文件部分
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentFiles.isNotEmpty) ...[
            Padding(
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
            ),
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
          // 如果没有最近文件，显示提示
          if (_recentFiles.isEmpty)
            Expanded(
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
            )
          else
            // 如果有最近文件，显示查看全部按钮
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.folder, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      '已找到 ${_recentFiles.length} 个本地文件',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.push('/local'),
                      child: const Text('查看全部文件'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CloudFilesTab extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _CloudFilesTab({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('云图'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.cloud),
            title: Text('云图 ${index + 1}'),
            subtitle: const Text('更新时间: 2024-01-01'),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show more options
              },
            ),
            onTap: () {
              // Open cloud diagram
            },
          );
        },
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _ProfileTab({required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100),
            SizedBox(height: 16),
            Text('用户信息'),
          ],
        ),
      ),
    );
  }
}

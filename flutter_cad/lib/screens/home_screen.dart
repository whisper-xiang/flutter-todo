/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2025-12-29 13:13:20
 */
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/cad_file.dart';

class _DwgAsset {
  final String name;
  final String assetPath;

  const _DwgAsset({required this.name, required this.assetPath});
}

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
          _FilesTab(scaffoldKey: _scaffoldKey),
          _CloudDiagramsTab(scaffoldKey: _scaffoldKey),
          _ProfileTab(scaffoldKey: _scaffoldKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '文件'),
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

class _FilesTab extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _FilesTab({required this.scaffoldKey});

  static const List<_DwgAsset> _dwgAssets = [
    _DwgAsset(name: '电磁铁.dwg', assetPath: 'assets/dwg/电磁铁.dwg'),
    _DwgAsset(name: '电磁铁座.dwg', assetPath: 'assets/dwg/电磁铁座.dwg'),
    _DwgAsset(name: '销轴.dwg', assetPath: 'assets/dwg/销轴.dwg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文件'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.blue,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: ListView.builder(
        itemCount: _dwgAssets.length,
        itemBuilder: (context, index) {
          final item = _dwgAssets[index];
          return ListTile(
            leading: const Icon(Icons.insert_drive_file),
            title: Text(item.name),
            subtitle: Text(item.assetPath),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                // Show more options
              },
            ),
            onTap: () {
              final file = CadFile(
                id: 'asset-$index',
                name: item.name,
                path: item.assetPath,
                url: null,
                type: FileType.cad2d,
                modifiedAt: DateTime.now(),
                size: 0,
              );

              context.push('/preview/${file.id}', extra: file);
            },
          );
        },
      ),
    );
  }
}

class _CloudDiagramsTab extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const _CloudDiagramsTab({required this.scaffoldKey});

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

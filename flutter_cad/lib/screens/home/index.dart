/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-26 10:47:00
 */
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:go_router/go_router.dart';
import '../../models/cad_file.dart';
import 'components/app_drawer.dart';
import 'components/local_files_tab.dart';
import 'components/cloud_files_tab.dart';
import 'components/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _pickAndOpenFile() async {
    try {
      picker.FilePickerResult? result = await picker.FilePicker.platform.pickFiles(
        type: picker.FileType.custom,
        allowedExtensions: ['ocf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final cadFile = CadFile(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: file.name,
          path: file.path,
          type: FileType.unknown, // OCF type might not be in enum yet, using unknown or mapped type
          modifiedAt: DateTime.now(),
          size: file.size,
        );

        if (mounted) {
          context.push(
            '/ocf-preview/${cadFile.id}',
            extra: cadFile,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _pickAndOpenFile,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          LocalFilesTab(scaffoldKey: _scaffoldKey),
          CloudFilesTab(scaffoldKey: _scaffoldKey),
          ProfileTab(scaffoldKey: _scaffoldKey),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '本地文件'),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: '系统能力'),
          // BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
      drawer: AppDrawer(scaffoldKey: _scaffoldKey),
    );
  }
}

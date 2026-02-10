/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: whisper_xiang
 * @LastEditTime: 2026-02-10 10:41:02
 */
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:go_router/go_router.dart';
import '../../models/cad_file.dart';
import 'components/local_files_tab.dart';
import 'components/cloud_files_tab.dart';
import 'components/profile_tab.dart';
import 'components/app_drawer.dart';

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
      debugPrint('🔍 [DEBUG] _pickAndOpenFile 开始执行');

      picker.FilePickerResult? result = await picker.FilePicker.platform
          .pickFiles(
            type: picker.FileType.custom,
            // 允许所有支持的文件格式
            allowedExtensions: [
              // CAD文件
              'dwg', 'dxf', 'ocf', 'ocf4', 'sldprt', 'step', 'stp',
              'iges', 'igs', 'hsf', 'obj',
              // PDF文件
              'pdf',
              // 图片文件
              'jpg',
              'jpeg',
              'png',
              'gif',
              'bmp',
              'webp',
              'svg',
              'ico',
              'tiff',
              'tif',
              // 视频文件
              'mp4', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'webm',
              // 音频文件
              'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg',
              // 文本文件
              'txt', 'md', 'json', 'xml', 'html', 'htm', 'csv',
              // Office文档
              'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
              // 压缩文件
              'zip', 'rar', '7z', 'tar', 'gz',
            ],
          );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final fileName = file.name;
        final extension = fileName.split('.').last.toLowerCase().trim();

        debugPrint('🔍 [DEBUG] 选中文件: $fileName, 扩展名: $extension');

        // 根据文件扩展名确定文件类型
        FileType fileType;
        if (['dwg', 'dxf'].contains(extension)) {
          fileType = FileType.cad2d;
        } else if (['ocf', 'ocf4'].contains(extension)) {
          fileType = FileType.ocf;
        } else if ([
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
          'svg',
          'ico',
          'tiff',
          'tif',
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

        debugPrint('🔍 [DEBUG] 文件类型识别为: $fileType');

        final cadFile = CadFile(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: fileName,
          path: file.path,
          type: fileType,
          modifiedAt: DateTime.now(),
          size: file.size,
        );

        if (mounted) {
          debugPrint('🔍 [DEBUG] 开始路由跳转');

          // 根据文件类型和扩展名进行路由跳转
          if (extension == 'dwg') {
            debugPrint('🔍 [DEBUG] 跳转 DWG 预览');
            context.push('/dwg-preview/${cadFile.id}', extra: cadFile);
          } else if (extension == 'ocf4') {
            debugPrint('🔍 [DEBUG] 跳转 OCF4 预览');
            context.push('/ocf4-preview/${cadFile.id}', extra: cadFile);
          } else if (extension == 'ocf') {
            debugPrint('🔍 [DEBUG] 跳转 OCF 预览');
            context.push('/ocf-preview/${cadFile.id}', extra: cadFile);
          } else if (fileType == FileType.cad2d || fileType == FileType.cad3d) {
            debugPrint('🔍 [DEBUG] 跳转 HOOPS 预览');
            context.push('/hoops-preview/${cadFile.id}', extra: cadFile);
          } else if (fileType == FileType.pdf) {
            debugPrint('🔍 [DEBUG] 跳转 PDF 预览');
            context.push('/pdf-preview/${cadFile.id}', extra: cadFile);
          } else if (fileType == FileType.video) {
            debugPrint('🔍 [DEBUG] 跳转视频预览');
            context.push('/video-preview/${cadFile.id}', extra: cadFile);
          } else if (fileType == FileType.audio) {
            debugPrint('🔍 [DEBUG] 跳转音频预览');
            context.push('/audio-preview/${cadFile.id}', extra: cadFile);
          } else if (fileType == FileType.document) {
            // Office文档需要进一步区分
            if (['xls', 'xlsx'].contains(extension)) {
              debugPrint('🔍 [DEBUG] 跳转 Excel 预览');
              context.push('/excel-preview/${cadFile.id}', extra: cadFile);
            } else if (['ppt', 'pptx'].contains(extension)) {
              debugPrint('🔍 [DEBUG] 跳转 PPT 预览');
              context.push('/ppt-preview/${cadFile.id}', extra: cadFile);
            } else {
              debugPrint('🔍 [DEBUG] 跳转 Word 预览');
              context.push('/word-preview/${cadFile.id}', extra: cadFile);
            }
          } else {
            // 其他文件类型使用通用预览
            debugPrint('🔍 [DEBUG] 跳转通用预览');
            context.push('/preview/${cadFile.id}', extra: cadFile);
          }

          debugPrint('🔍 [DEBUG] 路由跳转完成');
        }
      } else {
        debugPrint('🔍 [DEBUG] 用户取消选择或文件路径为空');
      }
    } catch (e) {
      debugPrint('🔍 [DEBUG] 选择文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('选择文件失败: $e')));
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

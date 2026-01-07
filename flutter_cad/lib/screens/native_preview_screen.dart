/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:33:42
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-07 13:50:31
 */

import 'package:flutter/material.dart';
import 'dart:io';
import '../models/cad_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

/*
 * Flutter原生文件预览处理方式说明
 * 
 * 本页面实现了Flutter原生组件的文件预览功能，不同文件类型的处理方式如下：
 * 
 * 📸 图片文件 (jpg, jpeg, png, gif, bmp, webp, svg, ico)
 *    - 渲染方式：Flutter Image组件 + BoxFit.contain
 *    - 特点：原生渲染，支持缩放，性能优秀
 *    - 限制：不支持专业图片编辑功能
 * 
 * 📝 文本文件 (txt, md, rtf, csv, json, xml, html, htm)
 *    - 渲染方式：Flutter SelectableText组件
 *    - 特点：可选择复制，等宽字体，保持格式
 *    - 限制：大文件可能有性能问题
 * 
 * 📄 PDF文件 (pdf)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：Flutter没有内置PDF渲染器
 *    - 解决方案：使用外部应用打开或WebView渲染
 * 
 * 📚 Office文档 (doc, docx, xls, xlsx, ppt, pptx)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：Office文档是二进制格式，Flutter无法直接解析
 *    - 解决方案：使用外部应用打开（Word/Excel/PowerPoint等）
 * 
 * 🎵 音频文件 (mp3, wav, flac, aac, m4a, ogg)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：Flutter没有内置音频播放组件
 *    - 解决方案：使用外部音乐播放器打开
 * 
 * 🎬 视频文件 (mp4, avi, mov, wmv, flv, mkv, webm)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：需要video_player插件，增加复杂度
 *    - 解决方案：使用外部视频播放器打开
 * 
 * 📦 压缩文件 (zip, rar, 7z, tar, gz)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：Flutter不是文件管理器，不处理压缩包
 *    - 解决方案：使用外部解压软件打开
 * 
 * 🎨 设计文件 (psd, ai, sketch, fig)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：专业设计文件格式复杂，需要专用软件
 *    - 解决方案：使用Photoshop/Illustrator/Sketch/Figma等
 * 
 * 📖 电子书 (epub, mobi)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：需要专门的电子书阅读器
 *    - 解决方案：使用Apple Books/Kindle等阅读器
 * 
 * 🏗️ CAD文件 (dwg, dxf, ocf)
 *    - 处理方式：显示文件信息卡片
 *    - 原因：CAD文件格式复杂，需要专业CAD软件
 *    - 解决方案：使用AutoCAD/DraftSight等CAD软件
 * 
 * 🔄 二进制文件 (其他所有格式)
 *    - 处理方式：尝试读取为文本，失败则显示信息卡片
 *    - 特点：智能判断，提供备用方案
 *    - 解决方案：外部应用打开或手动处理
 * 
 * 💡 设计理念：
 * 1. 能原生渲染的优先使用Flutter组件（图片、文本）
 * 2. 不能原生渲染的提供文件信息和使用建议
 * 3. 统一使用外部应用打开作为备选方案
 * 4. 保持UI一致性和用户体验
 */

class NativePreviewScreen extends StatefulWidget {
  final String id;
  final CadFile file;

  const NativePreviewScreen({super.key, required this.id, required this.file});

  @override
  State<NativePreviewScreen> createState() => _NativePreviewScreenState();
}

class _NativePreviewScreenState extends State<NativePreviewScreen> {
  bool _isLoading = true;
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final fileExtension = widget.file.name.split('.').last.toLowerCase();

      if (widget.file.path != null) {
        final file = File(widget.file.path!);

        if (fileExtension == 'txt') {
          // 文本文件直接读取
          _content = await file.readAsString();
        } else if ([
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
        ].contains(fileExtension)) {
          // 图片文件
          _content = 'IMAGE'; // 标记为图片类型
        } else if (fileExtension == 'pdf') {
          // PDF文件显示信息
          _content = 'PDF_INFO'; // 标记为PDF类型
        } else if (['doc', 'docx'].contains(fileExtension)) {
          // Word文档显示信息
          _content = 'DOC_INFO'; // 标记为DOC类型
        } else if (['xls', 'xlsx'].contains(fileExtension)) {
          // Excel文档显示信息
          _content = 'EXCEL_INFO'; // 标记为Excel类型
        } else if (['ppt', 'pptx'].contains(fileExtension)) {
          // PowerPoint文档显示信息
          _content = 'PPT_INFO'; // 标记为PPT类型
        } else if (['dwg', 'dxf'].contains(fileExtension)) {
          // CAD文件显示信息
          _content = 'CAD_INFO'; // 标记为CAD类型
        } else if ([
          'mp3',
          'wav',
          'flac',
          'aac',
          'm4a',
          'ogg',
        ].contains(fileExtension)) {
          // 音频文件显示信息
          _content = 'AUDIO_INFO'; // 标记为音频类型
        } else if ([
          'mp4',
          'avi',
          'mov',
          'wmv',
          'flv',
          'mkv',
          'webm',
        ].contains(fileExtension)) {
          // 视频文件显示信息
          _content = 'VIDEO_INFO'; // 标记为视频类型
        } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(fileExtension)) {
          // 压缩文件显示信息
          _content = 'ARCHIVE_INFO'; // 标记为压缩类型
        } else if (['psd', 'ai', 'sketch', 'fig'].contains(fileExtension)) {
          // 设计文件显示信息
          _content = 'DESIGN_INFO'; // 标记为设计类型
        } else if (['epub', 'mobi'].contains(fileExtension)) {
          // 电子书显示信息
          _content = 'EBOOK_INFO'; // 标记为电子书类型
        } else if ([
          'md',
          'rtf',
          'csv',
          'json',
          'xml',
          'html',
          'htm',
        ].contains(fileExtension)) {
          // 其他文本类文件尝试读取为文本
          try {
            final bytes = await file.readAsBytes();
            _content = String.fromCharCodes(bytes);
          } catch (e) {
            _content = 'BINARY_FILE'; // 二进制文件标记
          }
        } else {
          // 其他文件类型尝试读取为文本
          try {
            final bytes = await file.readAsBytes();
            _content = String.fromCharCodes(bytes);
          } catch (e) {
            _content = 'BINARY_FILE'; // 二进制文件标记
          }
        }
      }
    } catch (e) {
      _error = '加载文件失败: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildContent() {
    final fileExtension = widget.file.name.split('.').last.toLowerCase();

    if (_error != null) {
      return _buildErrorWidget();
    }

    // 根据文件类型显示不同的原生内容
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileExtension)) {
      return _buildImagePreview();
    } else if (fileExtension == 'txt') {
      return _buildTextPreview();
    } else if (fileExtension == 'pdf') {
      return _buildPdfInfo();
    } else if (['doc', 'docx'].contains(fileExtension)) {
      return _buildDocInfo();
    } else if (['xls', 'xlsx'].contains(fileExtension)) {
      return _buildExcelInfo();
    } else if (['ppt', 'pptx'].contains(fileExtension)) {
      return _buildPptInfo();
    } else if (['dwg', 'dxf'].contains(fileExtension)) {
      return _buildCadInfo();
    } else if ([
      'mp3',
      'wav',
      'flac',
      'aac',
      'm4a',
      'ogg',
    ].contains(fileExtension)) {
      return _buildAudioInfo();
    } else if ([
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      'mkv',
      'webm',
    ].contains(fileExtension)) {
      return _buildVideoInfo();
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(fileExtension)) {
      return _buildArchiveInfo();
    } else if (['psd', 'ai', 'sketch', 'fig'].contains(fileExtension)) {
      return _buildDesignInfo();
    } else if (['epub', 'mobi'].contains(fileExtension)) {
      return _buildEbookInfo();
    } else if ([
      'md',
      'rtf',
      'csv',
      'json',
      'xml',
      'html',
      'htm',
    ].contains(fileExtension)) {
      return _buildTextPreview();
    } else {
      return _buildGenericInfo();
    }
  }

  Widget _buildImagePreview() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(widget.file.path!), fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.file.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTextPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SelectableText(
          _content ?? '内容为空',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPdfInfo() {
    return _buildFileInfoCard(
      icon: Icons.picture_as_pdf,
      title: 'PDF文档',
      color: Colors.red,
      message:
          'PDF文件需要使用专门的PDF阅读器打开。\n\n建议使用：\n• Adobe Acrobat Reader\n• 系统内置PDF查看器\n• 或转换为其他格式',
    );
  }

  Widget _buildDocInfo() {
    return _buildFileInfoCard(
      icon: Icons.description,
      title: 'Word文档',
      color: Colors.blue,
      message:
          'Word文档需要使用Microsoft Word或兼容软件打开。\n\n建议使用：\n• Microsoft Word\n• WPS Office\n• Google Docs\n• 或转换为PDF格式',
    );
  }

  Widget _buildExcelInfo() {
    return _buildFileInfoCard(
      icon: Icons.table_chart,
      title: 'Excel表格',
      color: Colors.green,
      message:
          'Excel文件需要使用电子表格软件打开。\n\n建议使用：\n• Microsoft Excel\n• WPS Office\n• Google Sheets\n• 或转换为CSV格式',
    );
  }

  Widget _buildCadInfo() {
    return _buildFileInfoCard(
      icon: Icons.design_services,
      title: 'CAD图纸',
      color: Colors.orange,
      message:
          'CAD文件需要使用专业的CAD软件打开。\n\n建议使用：\n• AutoCAD\n• DraftSight\n• LibreCAD\n• 或转换为PDF/DWG格式',
    );
  }

  Widget _buildGenericInfo() {
    return _buildFileInfoCard(
      icon: Icons.insert_drive_file,
      title: '未知文件',
      color: Colors.grey,
      message:
          '此文件类型暂不支持原生预览。\n\n请尝试：\n• 使用对应的专业软件打开\n• 转换为支持的格式\n• 使用WebView渲染方式查看',
    );
  }

  Widget _buildFileInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required String message,
  }) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.file.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('文件大小', _formatFileSize(widget.file.size)),
                    _buildInfoRow(
                      '修改时间',
                      widget.file.modifiedAt.toString().substring(0, 19),
                    ),
                    // _buildInfoRow('文件路径', widget.file.path ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _openWithExternalApp,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('使用外部应用打开'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _openWithWebView,
                    icon: const Icon(Icons.web),
                    label: const Text('WebView渲染'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label：',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '未知错误',
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWithExternalApp() async {
    if (widget.file.path == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('文件路径无效')));
      return;
    }

    try {
      final file = File(widget.file.path!);
      if (!await file.exists()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('文件不存在')));
        return;
      }

      // 首先尝试使用url_launcher
      try {
        final uri = Uri.file(widget.file.path!);

        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (launched) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('文件已在外部应用中打开')));
            return;
          }
        }
      } catch (e) {
        debugPrint('url_launcher失败: $e');
      }

      // 如果url_launcher失败，尝试使用系统文件管理器
      await _openWithFileManager();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('打开文件时出错: $e')));
    }
  }

  Future<void> _openWithFileManager() async {
    if (Platform.isIOS) {
      // iOS: 在文件管理器中显示文件
      final uri = Uri.parse('shareddocuments://${widget.file.path}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已在文件管理器中打开文件位置')));
        return;
      }
    } else if (Platform.isAndroid) {
      // Android: 使用Intent打开文件
      final uri = Uri.file(widget.file.path!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('已尝试打开文件')));
        return;
      }
    }

    // 如果所有方法都失败，显示文件路径供用户手动操作
    _showFilePathDialog();
  }

  void _showFilePathDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文件信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('文件名: ${widget.file.name}'),
            const SizedBox(height: 8),
            Text('大小: ${_formatFileSize(widget.file.size)}'),
            const SizedBox(height: 8),
            const Text('文件路径:'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.file.path ?? '',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('请手动使用文件管理器打开此文件'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
          TextButton(
            onPressed: () {
              // 复制文件路径到剪贴板
              // 这里可以添加剪贴板功能
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('请手动打开文件')));
            },
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildPptInfo() {
    return _buildFileInfoCard(
      icon: Icons.slideshow,
      title: 'PowerPoint演示文稿',
      color: Colors.orange,
      message:
          'PowerPoint文件需要使用演示软件打开。\n\n建议使用：\n• Microsoft PowerPoint\n• Keynote\n• Google Slides\n• 或转换为PDF格式',
    );
  }

  Widget _buildAudioInfo() {
    return _buildFileInfoCard(
      icon: Icons.audiotrack,
      title: '音频文件',
      color: Colors.purple,
      message:
          '音频文件需要使用播放器打开。\n\n建议使用：\n• 系统音乐播放器\n• VLC Media Player\n• iTunes/Apple Music\n• 支持多种音频格式',
    );
  }

  Widget _buildVideoInfo() {
    return _buildFileInfoCard(
      icon: Icons.videocam,
      title: '视频文件',
      color: Colors.red,
      message:
          '视频文件需要使用播放器打开。\n\n建议使用：\n• 系统视频播放器\n• VLC Media Player\n• QuickTime Player\n• 支持多种视频格式',
    );
  }

  Widget _buildArchiveInfo() {
    return _buildFileInfoCard(
      icon: Icons.archive,
      title: '压缩文件',
      color: Colors.brown,
      message:
          '压缩文件需要使用解压软件打开。\n\n建议使用：\n• 系统解压工具\n• WinRAR/7-Zip\n• The Unarchiver\n• 支持多种压缩格式',
    );
  }

  Widget _buildDesignInfo() {
    return _buildFileInfoCard(
      icon: Icons.brush,
      title: '设计文件',
      color: Colors.purple,
      message:
          '设计文件需要使用专业软件打开。\n\n建议使用：\n• Adobe Photoshop/Illustrator\n• Sketch/Figma\n• Affinity Designer\n• 专业设计软件',
    );
  }

  Widget _buildEbookInfo() {
    return _buildFileInfoCard(
      icon: Icons.menu_book,
      title: '电子书',
      color: Colors.green,
      message:
          '电子书需要使用阅读器打开。\n\n建议使用：\n• Apple Books\n• Kindle\n• Adobe Digital Editions\n• 专用电子书阅读器',
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openWithWebView() async {
    // 导航到WebView预览页面
    final webviewFileId = 'webview-${widget.file.id}';
    if (mounted) {
      GoRouter.of(
        context,
      ).push('/webview-preview/$webviewFileId', extra: widget.file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            tooltip: '使用外部应用打开',
            onPressed: _openWithExternalApp,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('文件信息'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('文件名: ${widget.file.name}'),
                      Text('大小: ${_formatFileSize(widget.file.size)}'),
                      Text('修改时间: ${widget.file.modifiedAt}'),
                      if (widget.file.path != null)
                        Text('路径: ${widget.file.path}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
}

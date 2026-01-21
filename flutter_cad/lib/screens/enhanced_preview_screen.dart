import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../models/cad_file.dart';

class EnhancedPreviewScreen extends StatefulWidget {
  final CadFile file;

  const EnhancedPreviewScreen({super.key, required this.file});

  @override
  State<EnhancedPreviewScreen> createState() => _EnhancedPreviewScreenState();
}

class _EnhancedPreviewScreenState extends State<EnhancedPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  dynamic _content;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      if (widget.file.type == FileType.image) {
        await _loadImage();
      } else if (widget.file.type == FileType.text) {
        await _loadText();
      } else if (widget.file.type == FileType.pdf) {
        await _loadPdf();
      } else if (widget.file.type == FileType.video) {
        await _loadVideo();
      } else if (widget.file.type == FileType.audio) {
        await _loadAudio();
      } else {
        setState(() {
          _error = '暂不支持此文件格式的Flutter原生预览';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadImage() async {
    if (widget.file.path != null) {
      final file = File(widget.file.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _content = Image.memory(bytes);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadText() async {
    if (widget.file.path != null) {
      final file = File(widget.file.path!);
      final content = await file.readAsString();
      setState(() {
        _content = content;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPdf() async {
    // PDF预览需要额外的插件，这里显示占位符
    setState(() {
      _error = 'PDF预览需要插件支持，将逐步添加';
      _isLoading = false;
    });
  }

  Future<void> _loadVideo() async {
    if (widget.file.path != null) {
      setState(() {
        _content = widget.file.path;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAudio() async {
    if (widget.file.path != null) {
      setState(() {
        _content = widget.file.path;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_content == null) {
      return const Center(child: Text('无内容'));
    }

    // 根据文件类型显示不同的内容
    if (widget.file.type == FileType.image) {
      return _buildImageViewer();
    } else if (widget.file.type == FileType.text) {
      return _buildTextViewer();
    } else if (widget.file.type == FileType.video) {
      return _buildVideoViewer();
    } else if (widget.file.type == FileType.audio) {
      return _buildAudioViewer();
    }

    return const Center(child: Text('不支持的格式'));
  }

  Widget _buildImageViewer() {
    return Center(
      child: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 0.5,
        maxScale: 4.0,
        child: _content as Widget,
      ),
    );
  }

  Widget _buildTextViewer() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: SelectableText(
        _content as String,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildVideoViewer() {
    final videoPath = _content as String;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('视频文件: ${widget.file.name}'),
          const SizedBox(height: 8),
          Text('路径: $videoPath', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('视频播放器插件开发中...'),
        ],
      ),
    );
  }

  Widget _buildAudioViewer() {
    final audioPath = _content as String;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audiotrack, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('音频文件: ${widget.file.name}'),
          const SizedBox(height: 8),
          Text('路径: $audioPath', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('音频播放器插件开发中...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error!),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadContent,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

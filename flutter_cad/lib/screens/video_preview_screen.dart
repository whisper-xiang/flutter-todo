import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'dart:async';
import '../models/cad_file.dart';

class VideoPreviewScreen extends StatefulWidget {
  final CadFile file;

  const VideoPreviewScreen({super.key, required this.file});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        print('视频文件路径: ${widget.file.path}');
        print('文件是否存在: ${await file.exists()}');
        print('文件大小: ${await file.length()} bytes');
        
        _controller = VideoPlayerController.file(file);
        
        // 添加监听器
        _controller!.addListener(() {
          if (mounted) {
            setState(() {});
          }
        });
        
        // 设置错误处理
        _controller!.setVolume(1.0);
        
        try {
          await _controller!.initialize();
          print('视频初始化成功');
          print('视频时长: ${_controller!.value.duration}');
          print('视频比例: ${_controller!.value.aspectRatio}');
          
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        } catch (initError) {
          print('视频初始化错误: $initError');
          if (mounted) {
            setState(() {
              _error = '视频格式不支持或文件损坏: $initError';
              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('视频加载异常: $e');
      if (mounted) {
        setState(() {
          _error = '视频加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _resetHideControlsTimer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.file.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isLoading = true;
                });
                _initializeVideo();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              '正在加载视频...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          '视频初始化失败',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _showControlsTemporarily,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 视频播放器
          Container(
            color: Colors.black,
            child: Center(
              child: _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio > 0 
                          ? _controller!.value.aspectRatio 
                          : 16 / 9, // 默认比例
                      child: VideoPlayer(_controller!),
                    )
                  : Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.black,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '视频初始化失败',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // 控制层
          if (_showControls && _controller!.value.isInitialized)
            _buildControls(),
            
          // 视频信息
          if (_controller!.value.isInitialized)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '文件: ${widget.file.name}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '时长: ${_controller!.value.duration.toString().split('.')[0]}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '状态: ${_controller!.value.isPlaying ? '播放中' : '已暂停'}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 进度条
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Colors.red,
              backgroundColor: Colors.grey,
              bufferedColor: Colors.white24,
            ),
          ),
          
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if (_controller!.value.isPlaying) {
                      _controller!.pause();
                    } else {
                      _controller!.play();
                    }
                  });
                  _resetHideControlsTimer();
                },
                icon: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

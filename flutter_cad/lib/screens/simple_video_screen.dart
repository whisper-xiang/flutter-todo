import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/cad_file.dart';

class SimpleVideoScreen extends StatefulWidget {
  final CadFile file;

  const SimpleVideoScreen({super.key, required this.file});

  @override
  State<SimpleVideoScreen> createState() => _SimpleVideoScreenState();
}

class _SimpleVideoScreenState extends State<SimpleVideoScreen> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      print('尝试加载视频: ${widget.file.path}');
      
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        
        if (!await file.exists()) {
          throw Exception('文件不存在');
        }
        
        print('文件大小: ${await file.length()} bytes');
        
        // 检测文件格式
        final extension = widget.file.name.split('.').last.toLowerCase();
        print('文件格式: $extension');
        
        // AVI格式警告
        if (extension == 'avi') {
          print('警告: AVI格式在iOS模拟器上可能存在兼容性问题');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('AVI格式在iOS模拟器上可能不支持，建议使用MP4格式'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
        
        // 尝试不同的初始化方式
        _controller = VideoPlayerController.file(file);
        
        // 添加错误监听
        _controller!.addListener(() {
          if (_controller!.value.hasError) {
            print('视频播放错误: ${_controller!.value.errorDescription}');
            setState(() {
              _error = '播放错误: ${_controller!.value.errorDescription}';
              _isLoading = false;
            });
          } else {
            // 强制更新UI以反映播放状态变化
            if (mounted) {
              setState(() {});
            }
          }
        });
        
        await _controller!.initialize();
        
        print('视频初始化成功!');
        print('时长: ${_controller!.value.duration}');
        print('比例: ${_controller!.value.aspectRatio}');
        print('视频尺寸: ${_controller!.value.size}');
        print('是否初始化: ${_controller!.value.isInitialized}');
        print('是否有错误: ${_controller!.value.hasError}');
        if (_controller!.value.hasError) {
          print('错误描述: ${_controller!.value.errorDescription}');
        }
        
        // 检查视频尺寸是否有效
        if (_controller!.value.size.width == 0.0 || _controller!.value.size.height == 0.0) {
          print('警告: 视频尺寸无效，可能是格式不兼容');
          if (mounted) {
            setState(() {
              _error = '视频格式不兼容：AVI文件无法在iOS模拟器上正常显示\n建议：\n1. 使用MP4格式\n2. 在真机上测试\n3. 转换视频格式';
              _isLoading = false;
            });
            return;
          }
        }
        
        // 自动开始播放
        _controller!.play();
        
        // 添加循环播放以便测试
        _controller!.setLooping(true);
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('视频初始化失败: $e');
      if (mounted) {
        setState(() {
          _error = '视频加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
      body: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text(
            '正在加载视频...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 20),
          Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _initializeVideo();
            },
            child: const Text('重试'),
          ),
        ],
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Text(
        '视频初始化失败',
        style: TextStyle(color: Colors.white),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 视频播放器容器
        GestureDetector(
          onTap: () {
            if (_controller!.value.isInitialized) {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            }
          },
          child: Container(
            width: double.infinity,
            height: 300,
            color: Colors.black,
            child: _controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio > 0 
                        ? _controller!.value.aspectRatio 
                        : 16 / 9,
                    child: Stack(
                      children: [
                        // 视频播放器
                        VideoPlayer(_controller!),
                        
                        // 测试覆盖层 - 确认VideoPlayer在渲染
                        Container(
                          color: Colors.red.withOpacity(0.1), // 半透明红色覆盖层
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '视频播放中',
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 播放指示器
                        if (!_controller!.value.isPlaying && _controller!.value.isInitialized)
                          const Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                      ],
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // 进度条
        if (_controller!.value.isInitialized)
          Column(
            children: [
              VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Colors.red,
                  backgroundColor: Colors.grey,
                  bufferedColor: Colors.white24,
                ),
              ),
              const SizedBox(height: 10),
              // 时间显示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_controller!.value.position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_controller!.value.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        
        const SizedBox(height: 20),
        
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
              },
              icon: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
            IconButton(
              onPressed: () {
                _controller!.seekTo(Duration.zero);
                _controller!.play();
              },
              icon: const Icon(
                Icons.replay,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // 视频信息
        Text(
          '文件: ${widget.file.name}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        Text(
          '状态: ${_controller!.value.isPlaying ? '播放中' : '已暂停'}',
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          '缓冲: ${_controller!.value.buffered.isNotEmpty ? _controller!.value.buffered.last.end.inSeconds.toInt() : 0}s',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../models/cad_file.dart';

class AudioPreviewScreen extends StatefulWidget {
  final CadFile file;

  const AudioPreviewScreen({super.key, required this.file});

  @override
  State<AudioPreviewScreen> createState() => _AudioPreviewScreenState();
}

class _AudioPreviewScreenState extends State<AudioPreviewScreen> {
  AudioPlayer? _audioPlayer;
  bool _isLoading = true;
  String? _error;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      print('尝试加载音频: ${widget.file.path}');
      
      if (widget.file.path != null) {
        final file = File(widget.file.path!);
        
        if (!await file.exists()) {
          throw Exception('文件不存在');
        }
        
        print('文件大小: ${await file.length()} bytes');
        
        // 检测文件格式
        final extension = widget.file.name.split('.').last.toLowerCase();
        print('音频格式: $extension');
        
        // 检查格式支持
        if (extension == 'ogg') {
          print('警告: OGG格式可能不被audioplayers支持');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OGG格式可能不支持，建议使用MP3、AAC或WAV格式'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
        
        _audioPlayer = AudioPlayer();
        
        // 设置监听器
        _audioPlayer!.onPlayerStateChanged.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state == PlayerState.playing;
            });
          }
        });
        
        _audioPlayer!.onDurationChanged.listen((duration) {
          if (mounted) {
            setState(() {
              _duration = duration;
            });
          }
        });
        
        _audioPlayer!.onPositionChanged.listen((position) {
          if (mounted) {
            setState(() {
              _position = position;
            });
          }
        });
        
        _audioPlayer!.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        });
        
        // 加载音频文件
        await _audioPlayer!.setSourceDeviceFile(widget.file.path!);
        
        // 获取音频时长
        final duration = await _audioPlayer!.getDuration();
        if (duration != null) {
          print('音频加载成功!');
          print('时长: $duration');
        } else {
          print('无法获取音频时长');
        }
        
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('音频加载失败: $e');
      if (mounted) {
        setState(() {
          _error = '音频加载失败: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer != null) {
      try {
        if (_isPlaying) {
          await _audioPlayer!.pause();
        } else {
          await _audioPlayer!.resume();
        }
      } catch (e) {
        print('播放控制失败: $e');
      }
    }
  }

  Future<void> _seekTo(double value) async {
    if (_audioPlayer != null && _duration.inMilliseconds > 0) {
      final position = Duration(milliseconds: (value * _duration.inMilliseconds).toInt());
      await _audioPlayer!.seek(position);
    }
  }

  Future<void> _setVolume(double value) async {
    if (_audioPlayer != null) {
      _volume = value;
      await _audioPlayer!.setVolume(_volume);
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
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
            '正在加载音频...',
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
              _initializeAudio();
            },
            child: const Text('重试'),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 音频图标
          const Icon(
            Icons.audiotrack,
            size: 120,
            color: Colors.white,
          ),
          
          const SizedBox(height: 40),
          
          // 文件信息
          Text(
            widget.file.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 10),
          
          Text(
            '格式: ${widget.file.name.split('.').last.toUpperCase()}',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 进度条
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.red,
                  inactiveTrackColor: Colors.grey,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                ),
                child: Slider(
                  value: _duration.inMilliseconds > 0 
                      ? _position.inMilliseconds / _duration.inMilliseconds 
                      : 0.0,
                  onChanged: _seekTo,
                  min: 0.0,
                  max: 1.0,
                ),
              ),
              
              // 时间显示
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // 播放控制
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  if (_audioPlayer != null) {
                    _audioPlayer!.seek(Duration.zero);
                  }
                },
                icon: const Icon(
                  Icons.replay,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              
              const SizedBox(width: 20),
              
              IconButton(
                onPressed: _togglePlayPause,
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
              ),
              
              const SizedBox(width: 20),
              
              IconButton(
                onPressed: () {
                  if (_audioPlayer != null) {
                    _audioPlayer!.seek(_duration);
                  }
                },
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // 音量控制
          Column(
            children: [
              const Text(
                '音量',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.blue,
                  inactiveTrackColor: Colors.grey,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white.withOpacity(0.2),
                ),
                child: Slider(
                  value: _volume,
                  onChanged: _setVolume,
                  min: 0.0,
                  max: 1.0,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // 状态信息
          Text(
            _isPlaying ? '播放中' : '已暂停',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

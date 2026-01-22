/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语 243267674@qq.com
 * @LastEditTime: 2026-01-22 14:50:42
 */
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:torch_light/torch_light.dart';
import 'package:vibration/vibration.dart';
import 'package:path_provider/path_provider.dart';
import 'package:app_settings/app_settings.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'dart:io';
import 'dart:async';

class CloudFilesTab extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CloudFilesTab({super.key, required this.scaffoldKey});

  @override
  State<CloudFilesTab> createState() => _CloudFilesTabState();
}

class _CloudFilesTabState extends State<CloudFilesTab> {
  List<CameraDescription> cameras = [];
  String _locationStatus = '未知';
  String _deviceInfo = '未知';
  String _appInfo = '未知';
  Iterable<Contact>? _contacts;
  String _cameraStatus = '未检查';
  String _accelerometerStatus = '未检查';
  String _gyroscopeStatus = '未检查';
  String _flashlightStatus = '未检查';
  String _microphoneStatus = '未检查';
  String _storageStatus = '未检查';
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  
  // 录制功能状态
  bool _isRecordingVideo = false;
  bool _isRecordingAudio = false;
  bool _isStreaming = false;
  String _recordingStatus = '未开始';
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _videoPath;
  String? _audioPath;
  
  // 系统UI定制状态
  bool _isImmersiveMode = false;
  bool _isStatusBarHidden = false;
  bool _isNavigationBarHidden = false;
  bool _isSystemThemeEnabled = false;
  Brightness _systemBrightness = Brightness.light;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _checkPermissions();
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
      setState(() {
        _cameraStatus = '可用 (${cameras.length})';
      });
    } catch (e) {
      setState(() {
        _cameraStatus = '不可用: $e';
      });
    }
  }

  Future<void> _checkPermissions() async {
    await _getLocation();
    await _getDeviceInfo();
    await _getAppInfo();
    await _getContacts();
    await _getStorageInfo();
    await _checkFlashlight();
    await _checkMicrophone();
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationStatus = 'GPS服务未启用';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationStatus = 'GPS权限被拒绝';
          });
          return;
        } else if (permission == LocationPermission.deniedForever) {
          _showSettingsDialog('位置');
          setState(() {
            _locationStatus = 'GPS权限被永久拒绝';
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationStatus = '纬度: ${position.latitude.toStringAsFixed(6)}, 经度: ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'GPS错误: $e';
      });
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        setState(() {
          _deviceInfo = '${iosInfo.model} - ${iosInfo.systemVersion}';
        });
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          _deviceInfo = '${androidInfo.brand} ${androidInfo.model} - ${androidInfo.version.release}';
        });
      }
    } catch (e) {
      setState(() {
        _deviceInfo = '获取失败: $e';
      });
    }
  }

  Future<void> _getAppInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appInfo = '${packageInfo.appName} v${packageInfo.version}';
      });
    } catch (e) {
      setState(() {
        _appInfo = '获取失败: $e';
      });
    }
  }

  Future<void> _getContacts() async {
    try {
      PermissionStatus status = await Permission.contacts.request();
      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，引导用户到设置
        _showSettingsDialog('联系人');
        setState(() {
          _contacts = null;
        });
      } else if (status.isGranted) {
        Iterable<Contact> contacts = await ContactsService.getContacts();
        setState(() {
          _contacts = contacts;
        });
      } else {
        setState(() {
          _contacts = null;
        });
      }
    } catch (e) {
      print('获取联系人失败: $e');
      setState(() {
        _contacts = null;
      });
    }
  }

  Future<void> _getStorageInfo() async {
    try {
      PermissionStatus status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，引导用户到设置
        _showSettingsDialog('存储');
        setState(() {
          _storageStatus = '权限被永久拒绝';
        });
      } else if (status.isGranted) {
        final appDir = await getApplicationDocumentsDirectory();
        setState(() {
          _storageStatus = '可用: ${appDir.path}';
        });
      } else {
        setState(() {
          _storageStatus = '权限被拒绝';
        });
      }
    } catch (e) {
      setState(() {
        _storageStatus = '获取失败: $e';
      });
    }
  }

  Future<void> _checkFlashlight() async {
    try {
      bool hasFlash = await TorchLight.isTorchAvailable();
      setState(() {
        _flashlightStatus = hasFlash ? '可用' : '不可用';
      });
    } catch (e) {
      setState(() {
        _flashlightStatus = '检查失败: $e';
      });
    }
  }

  Future<void> _checkMicrophone() async {
    try {
      PermissionStatus status = await Permission.microphone.request();
      if (status.isPermanentlyDenied) {
        // 权限被永久拒绝，引导用户到设置
        _showSettingsDialog('麦克风');
        setState(() {
          _microphoneStatus = '权限被永久拒绝';
        });
      } else {
        setState(() {
          _microphoneStatus = status.isGranted ? '已授权' : '权限被拒绝';
        });
      }
    } catch (e) {
      setState(() {
        _microphoneStatus = '检查失败: $e';
      });
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$permissionName权限被拒绝'),
          content: Text('请在设置中开启$permissionName权限：\n\n设置 → 隐私与安全性 → $permissionName → 允许'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 打开应用设置页面
                openAppSettings();
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('照片已保存: ${image.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开摄像头失败: $e')),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    const phoneNumber = 'tel:10086';
    try {
      if (await canLaunch(phoneNumber)) {
        await launch(phoneNumber);
      } else {
        throw '无法拨打电话';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('拨打电话失败: $e')),
      );
    }
  }

  Future<void> _sendEmail() async {
    const email = 'mailto:test@example.com?subject=测试&body=这是一封测试邮件';
    try {
      if (await canLaunch(email)) {
        await launch(email);
      } else {
        throw '无法发送邮件';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送邮件失败: $e')),
      );
    }
  }

  Future<void> _openWebsite() async {
    const url = 'https://www.flutter.dev';
    try {
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw '无法打开网站';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打开网站失败: $e')),
      );
    }
  }

  Future<void> _shareContent() async {
    try {
      await Share.share('这是一个系统能力测试应用，支持多种硬件功能！');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  Future<void> _vibrateDevice() async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(duration: 1000);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设备已震动')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设备不支持震动')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('震动失败: $e')),
      );
    }
  }

  Future<void> _startAccelerometer() async {
    try {
      // 先取消现有订阅
      await _accelerometerSubscription?.cancel();
      
      _accelerometerSubscription = accelerometerEvents.listen((event) {
        setState(() {
          _accelerometerStatus = 'X: ${event.x.toStringAsFixed(2)}, Y: ${event.y.toStringAsFixed(2)}, Z: ${event.z.toStringAsFixed(2)}';
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('加速度传感器已启动')),
      );
    } catch (e) {
      setState(() {
        _accelerometerStatus = '启动失败: $e';
      });
    }
  }

  Future<void> _startGyroscope() async {
    try {
      // 先取消现有订阅
      await _gyroscopeSubscription?.cancel();
      
      _gyroscopeSubscription = gyroscopeEvents.listen((event) {
        setState(() {
          _gyroscopeStatus = 'X: ${event.x.toStringAsFixed(2)}, Y: ${event.y.toStringAsFixed(2)}, Z: ${event.z.toStringAsFixed(2)}';
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('陀螺仪传感器已启动')),
      );
    } catch (e) {
      setState(() {
        _gyroscopeStatus = '启动失败: $e';
      });
    }
  }

  Future<void> _stopSensors() async {
    await _accelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    
    // 将订阅设置为null，确保完全清理
    _accelerometerSubscription = null;
    _gyroscopeSubscription = null;
    
    setState(() {
      _accelerometerStatus = '已停止';
      _gyroscopeStatus = '已停止';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('传感器已停止')),
    );
  }

  Future<void> _startRecording() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('录音功能暂时不可用')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('录音失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemCapabilities = [
      {
        'title': '摄像头',
        'subtitle': '状态: $_cameraStatus',
        'icon': Icons.camera_alt,
        'onTap': _openCamera,
      },
      {
        'title': 'GPS定位',
        'subtitle': '状态: $_locationStatus',
        'icon': Icons.location_on,
        'onTap': _getLocation,
      },
      {
        'title': '设备信息',
        'subtitle': _deviceInfo,
        'icon': Icons.phone_android,
        'onTap': _getDeviceInfo,
      },
      {
        'title': '应用信息',
        'subtitle': _appInfo,
        'icon': Icons.info,
        'onTap': _getAppInfo,
      },
      {
        'title': '联系人',
        'subtitle': _contacts != null ? '共${_contacts!.length}个联系人' : '未授权',
        'icon': Icons.contacts,
        'onTap': _getContacts,
      },
      {
        'title': '存储权限',
        'subtitle': '状态: $_storageStatus',
        'icon': Icons.storage,
        'onTap': _getStorageInfo,
      },
      {
        'title': '手电筒',
        'subtitle': '状态: $_flashlightStatus',
        'icon': Icons.flashlight_on,
        'onTap': _toggleFlashlight,
      },
      {
        'title': '麦克风',
        'subtitle': '状态: $_microphoneStatus',
        'icon': Icons.mic,
        'onTap': _startRecording,
      },
      {
        'title': '震动',
        'subtitle': '测试设备震动',
        'icon': Icons.vibration,
        'onTap': _vibrateDevice,
      },
      {
        'title': '加速度传感器',
        'subtitle': '状态: $_accelerometerStatus',
        'icon': Icons.sensors,
        'onTap': _startAccelerometer,
      },
      {
        'title': '陀螺仪传感器',
        'subtitle': '状态: $_gyroscopeStatus',
        'icon': Icons.rotate_90_degrees_ccw,
        'onTap': _startGyroscope,
      },
      {
        'title': '停止传感器',
        'subtitle': '停止所有传感器',
        'icon': Icons.stop,
        'onTap': _stopSensors,
      },
      {
        'title': '拨打电话',
        'subtitle': '拨打10086',
        'icon': Icons.call,
        'onTap': _makePhoneCall,
      },
      {
        'title': '发送邮件',
        'subtitle': '发送测试邮件',
        'icon': Icons.email,
        'onTap': _sendEmail,
      },
      {
        'title': '打开网站',
        'subtitle': 'Flutter官网',
        'icon': Icons.language,
        'onTap': _openWebsite,
      },
      {
        'title': '分享内容',
        'subtitle': '分享应用信息',
        'icon': Icons.share,
        'onTap': _shareContent,
      },
      {
        'title': '录制视频',
        'subtitle': '开始录制视频',
        'icon': Icons.videocam,
        'onTap': _toggleVideoRecording,
      },
      {
        'title': '录制音频',
        'subtitle': '开始录制音频',
        'icon': Icons.mic,
        'onTap': _toggleAudioRecording,
      },
      {
        'title': '开始推流',
        'subtitle': '开始直播推流',
        'icon': Icons.live_tv,
        'onTap': _toggleStreaming,
      },
      {
        'title': '显示弹窗',
        'subtitle': '显示各种类型弹窗',
        'icon': Icons.message,
        'onTap': _showDialogs,
      },
      {
        'title': '调用原生控件',
        'subtitle': '调用iOS/Android原生功能',
        'icon': Icons.phone_android,
        'onTap': _callNativeFeatures,
      },
      {
        'title': '系统分享',
        'subtitle': '调用系统分享功能',
        'icon': Icons.share,
        'onTap': _showSystemShare,
      },
      {
        'title': '打开设置',
        'subtitle': '打开应用系统设置',
        'icon': Icons.settings,
        'onTap': _openSettings,
      },
      {
        'title': '系统UI定制',
        'subtitle': '状态栏、导航栏等系统UI定制',
        'icon': Icons.palette,
        'onTap': _showSystemUICustomization,
      },
      {
        'title': '沉浸式模式',
        'subtitle': '全屏沉浸式体验',
        'icon': Icons.fullscreen,
        'onTap': _toggleImmersiveMode,
      },
      {
        'title': '相册访问',
        'subtitle': '访问系统相册和图片',
        'icon': Icons.photo_library,
        'onTap': _accessPhotoLibrary,
      },
      {
        'title': '相机拍照',
        'subtitle': '调用系统相机拍照',
        'icon': Icons.camera_alt,
        'onTap': _takePhoto,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('系统能力测试'),
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.teal,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: ListView.builder(
        itemCount: systemCapabilities.length,
        itemBuilder: (context, index) {
          final capability = systemCapabilities[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal.withOpacity(0.1),
                child: Icon(capability['icon'] as IconData, color: Colors.teal),
              ),
              title: Text(capability['title'] as String),
              subtitle: Text(capability['subtitle'] as String),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: capability['onTap'] as VoidCallback,
            ),
          );
        },
      ),
    );
  }

  // 录制功能方法
  Future<void> _toggleVideoRecording() async {
    try {
      if (_isRecordingVideo) {
        // 停止录制视频
        setState(() {
          _isRecordingVideo = false;
          _recordingStatus = '视频录制已停止';
        });
        
        if (_videoPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('视频已保存: $_videoPath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // 开始录制视频
        final cameraStatus = await Permission.camera.request();
        final micStatus = await Permission.microphone.request();
        
        if (cameraStatus.isGranted && micStatus.isGranted) {
          setState(() {
            _isRecordingVideo = true;
            _recordingStatus = '正在录制视频...';
          });
          
          // 生成视频文件路径
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _videoPath = '${directory.path}/video_$timestamp.mp4';
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('开始录制视频'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
          
          // 模拟录制过程（实际应用中需要使用camera控制器）
          Future.delayed(const Duration(seconds: 5), () {
            if (_isRecordingVideo) {
              _toggleVideoRecording();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要相机和麦克风权限'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('视频录制失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAudioRecording() async {
    try {
      if (_isRecordingAudio) {
        // 停止录制音频
        final path = await _audioRecorder.stop();
        
        setState(() {
          _isRecordingAudio = false;
          _recordingStatus = '音频录制已停止';
          _audioPath = path;
        });
        
        if (path != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('音频已保存: $path'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // 开始录制音频
        final micStatus = await Permission.microphone.request();
        
        if (micStatus.isGranted) {
          setState(() {
            _isRecordingAudio = true;
            _recordingStatus = '正在录制音频...';
          });
          
          // 开始录制
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final path = '${directory.path}/audio_$timestamp.m4a';
          
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            ),
            path: path,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('开始录制音频'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要麦克风权限'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('音频录制失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleStreaming() async {
    try {
      if (_isStreaming) {
        // 停止推流
        setState(() {
          _isStreaming = false;
          _recordingStatus = '推流已停止';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('直播推流已停止'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // 开始推流
        final cameraStatus = await Permission.camera.request();
        final micStatus = await Permission.microphone.request();
        
        if (cameraStatus.isGranted && micStatus.isGranted) {
          setState(() {
            _isStreaming = true;
            _recordingStatus = '正在推流中...';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('开始直播推流'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          
          // 模拟推流过程（实际应用中需要使用RTMP推流库）
          Future.delayed(const Duration(seconds: 10), () {
            if (_isStreaming) {
              _toggleStreaming();
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要相机和麦克风权限'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('推流失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 弹窗和原生控件功能方法
  Future<void> _showDialogs() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择弹窗类型'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('基本对话框'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showBasicDialog();
                },
              ),
              ListTile(
                title: const Text('底部弹窗'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showBottomSheet();
                },
              ),
              ListTile(
                title: const Text('选择器弹窗'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showPickerDialog();
                },
              ),
              ListTile(
                title: const Text('全屏弹窗'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showFullScreenDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBasicDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('基本对话框'),
          content: const Text('这是一个基本的AlertDialog弹窗，用于显示重要信息或获取用户确认。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '底部弹窗',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('这是一个从底部滑出的弹窗，常用于显示选项或操作菜单。'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('确认'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('选择器弹窗'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择了选项 1')),
                );
              },
              child: const Text('选项 1'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择了选项 2')),
                );
              },
              child: const Text('选项 2'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择了选项 3')),
                );
              },
              child: const Text('选项 3'),
            ),
          ],
        );
      },
    );
  }

  void _showFullScreenDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('全屏弹窗'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fullscreen,
                    size: 64,
                    color: Colors.blue,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '全屏弹窗',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '这是一个全屏弹窗，适合显示复杂内容或需要用户专注操作的场景。',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _callNativeFeatures() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('原生控件功能'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('震动反馈'),
                subtitle: const Text('触发设备震动'),
                onTap: () {
                  Navigator.of(context).pop();
                  _triggerVibration();
                },
              ),
              ListTile(
                title: const Text('手电筒'),
                subtitle: const Text('开关手电筒'),
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleFlashlight();
                },
              ),
              ListTile(
                title: const Text('电池信息'),
                subtitle: const Text('获取电池状态'),
                onTap: () {
                  Navigator.of(context).pop();
                  _getBatteryInfo();
                },
              ),
              ListTile(
                title: const Text('系统信息'),
                subtitle: const Text('显示系统版本'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showSystemInfo();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerVibration() async {
    try {
      // 检查是否支持震动
      bool? hasVibrator = await Vibration.hasVibrator();
      
      if (hasVibrator == true) {
        // 短震动
        await Vibration.vibrate(duration: 100);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('震动已触发'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('设备不支持震动'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('震动失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleFlashlight() async {
    try {
      // 简化手电筒功能，只显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('手电筒功能演示（需要真实设备）'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );
      
      // 触发震动作为反馈
      await Vibration.vibrate(duration: 100);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('手电筒功能演示失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getBatteryInfo() async {
    try {
      // 获取设备信息
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('iOS设备: ${iosInfo.model}'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Android: ${androidInfo.model}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取设备信息失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSystemInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      
      String systemInfo = '';
      
      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        systemInfo = 'iOS ${iosInfo.systemVersion}\n设备: ${iosInfo.model}';
      } else if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        systemInfo = 'Android ${androidInfo.version.release}\n设备: ${androidInfo.model}';
      }
      
      systemInfo += '\n应用版本: ${packageInfo.version}';
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('系统信息'),
            content: Text(systemInfo),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获取系统信息失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showSystemShare() async {
    try {
      // 使用系统分享功能，添加分享源视图
      await Share.share(
        '这是一个来自Flutter应用的分享内容！\n应用版本: 1.0.0\n平台: ${Platform.operatingSystem}',
        subject: 'Flutter应用分享',
        sharePositionOrigin: Rect.fromLTWH(0, 0, 100, 100), // 添加分享源坐标
      );
    } catch (e) {
      // 如果分享失败，显示备用分享选项
      _showShareDialog();
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('分享选项'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择分享方式：'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('复制到剪贴板'),
                onTap: () {
                  Navigator.of(context).pop();
                  _copyToClipboard();
                },
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('通过邮件分享'),
                onTap: () {
                  Navigator.of(context).pop();
                  _shareViaEmail();
                },
              ),
              ListTile(
                leading: const Icon(Icons.message),
                title: const Text('通过短信分享'),
                onTap: () {
                  Navigator.of(context).pop();
                  _shareViaSMS();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyToClipboard() async {
    try {
      final shareContent = '这是一个来自Flutter应用的分享内容！\n应用版本: 1.0.0\n平台: ${Platform.operatingSystem}';
      
      // 使用Flutter的Clipboard API
      await Clipboard.setData(ClipboardData(text: shareContent));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已复制到剪贴板'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('复制失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareViaEmail() async {
    try {
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: '',
        query: 'subject=Flutter应用分享&body=这是一个来自Flutter应用的分享内容！\n应用版本: 1.0.0\n平台: ${Platform.operatingSystem}',
      );
      
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw Exception('无法打开邮件应用');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('邮件分享失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareViaSMS() async {
    try {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: '',
        query: 'body=这是一个来自Flutter应用的分享内容！\n应用版本: 1.0.0\n平台: ${Platform.operatingSystem}',
      );
      
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        throw Exception('无法打开短信应用');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('短信分享失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openSettings() async {
    try {
      // 尝试使用app_settings插件
      await AppSettings.openAppSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已打开应用设置'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 如果app_settings失败，使用备用方案
      _showSettingsOptions();
    }
  }

  void _showSettingsOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('设置选项'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择设置方式：'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.settings_applications),
                title: const Text('应用设置'),
                subtitle: const Text('权限、通知等设置'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openAppSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: const Text('系统设置'),
                subtitle: const Text('设备系统设置'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openSystemSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('应用信息'),
                subtitle: const Text('存储、数据使用等'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openAppInfo();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAppSettings() async {
    try {
      if (Platform.isIOS) {
        // iOS: 尝试打开应用设置
        final Uri settingsUri = Uri.parse('app-settings:');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        } else {
          throw Exception('无法打开iOS设置');
        }
      } else if (Platform.isAndroid) {
        // Android: 尝试打开应用详情页面
        final Uri settingsUri = Uri.parse('app-settings:');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        } else {
          throw Exception('无法打开Android设置');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开应用设置失败: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openSystemSettings() async {
    try {
      if (Platform.isIOS) {
        // iOS: 打开系统设置
        final Uri settingsUri = Uri.parse('App-Prefs:');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        } else {
          throw Exception('无法打开iOS系统设置');
        }
      } else if (Platform.isAndroid) {
        // Android: 打开系统设置
        final Uri settingsUri = Uri.parse('android.settings.SETTINGS');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        } else {
          throw Exception('无法打开Android系统设置');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开系统设置失败: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openAppInfo() async {
    try {
      if (Platform.isIOS) {
        // iOS: 打开应用信息页面
        final Uri infoUri = Uri.parse('App-Prefs:root=General&path=About');
        if (await canLaunchUrl(infoUri)) {
          await launchUrl(infoUri);
        } else {
          throw Exception('无法打开iOS应用信息');
        }
      } else if (Platform.isAndroid) {
        // Android: 打开应用详情页面
        final Uri infoUri = Uri.parse('android.settings.APPLICATION_DETAILS_SETTINGS');
        if (await canLaunchUrl(infoUri)) {
          await launchUrl(infoUri);
        } else {
          throw Exception('无法打开Android应用信息');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('打开应用信息失败: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // 系统UI定制功能方法
  Future<void> _showSystemUICustomization() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('系统UI定制'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('状态栏控制'),
                subtitle: Text(_isStatusBarHidden ? '显示状态栏' : '隐藏状态栏'),
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleStatusBar();
                },
              ),
              ListTile(
                title: const Text('导航栏控制'),
                subtitle: Text(_isNavigationBarHidden ? '显示导航栏' : '隐藏导航栏'),
                onTap: () {
                  Navigator.of(context).pop();
                  _toggleNavigationBar();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleStatusBar() async {
    try {
      if (_isStatusBarHidden) {
        // 显示状态栏
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
        setState(() {
          _isStatusBarHidden = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('状态栏已显示'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 隐藏状态栏 - 只隐藏顶部状态栏，保留底部导航栏
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: [SystemUiOverlay.bottom]);
        setState(() {
          _isStatusBarHidden = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('状态栏已隐藏'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('状态栏控制失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleNavigationBar() async {
    try {
      if (_isNavigationBarHidden) {
        // 显示导航栏
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
        setState(() {
          _isNavigationBarHidden = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导航栏已显示'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 隐藏导航栏 - 只隐藏底部导航栏，保留顶部状态栏
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: [SystemUiOverlay.top]);
        setState(() {
          _isNavigationBarHidden = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('导航栏已隐藏'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导航栏控制失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openBrightnessSettings() async {
    try {
      if (Platform.isIOS) {
        // iOS: 尝试多种方式打开显示设置
        bool opened = false;
        
        // 方法1: 尝试打开通用设置
        final Uri generalSettingsUri = Uri.parse('App-Prefs:');
        if (await canLaunchUrl(generalSettingsUri)) {
          await launchUrl(generalSettingsUri);
          opened = true;
        } else {
          // 方法2: 尝试打开系统设置
          final Uri systemSettingsUri = Uri.parse('app-settings:');
          if (await canLaunchUrl(systemSettingsUri)) {
            await launchUrl(systemSettingsUri);
            opened = true;
          }
        }
        
        if (!opened) {
          throw Exception('无法打开iOS设置，请手动前往 设置 > 显示与亮度');
        }
      } else if (Platform.isAndroid) {
        // Android: 打开显示设置
        final Uri settingsUri = Uri.parse('android.settings.DISPLAY_SETTINGS');
        if (await canLaunchUrl(settingsUri)) {
          await launchUrl(settingsUri);
        } else {
          throw Exception('无法打开Android显示设置');
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Platform.isIOS 
            ? const Text('已打开iOS设置，请前往"显示与亮度"调节亮度')
            : const Text('已打开Android显示设置'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e\n请手动前往系统设置调节亮度'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _toggleSystemUIStyle() async {
    try {
      // 切换系统UI样式
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _systemBrightness == Brightness.light 
              ? Brightness.dark 
              : Brightness.light,
          statusBarBrightness: _systemBrightness,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: _systemBrightness == Brightness.light 
              ? Brightness.dark 
              : Brightness.light,
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('系统UI样式已更新'),
          backgroundColor: Colors.indigo,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('系统UI样式更新失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleImmersiveMode() async {
    try {
      if (_isImmersiveMode) {
        // 退出沉浸式模式
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
        
        setState(() {
          _isImmersiveMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已退出沉浸式模式'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // 进入沉浸式模式
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        
        setState(() {
          _isImmersiveMode = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已进入沉浸式模式'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('沉浸式模式切换失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleSystemTheme() async {
    try {
      setState(() {
        _isSystemThemeEnabled = !_isSystemThemeEnabled;
      });
      
      if (_isSystemThemeEnabled) {
        // 启用系统主题跟随
        // 这里可以添加系统主题监听逻辑
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已启用系统主题跟随'),
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        // 禁用系统主题跟随
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已禁用系统主题跟随'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('系统主题切换失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 相册和相机功能方法
  Future<void> _accessPhotoLibrary() async {
    try {
      // 检查相册权限
      var photoStatus = await Permission.photos.request();
      
      if (photoStatus.isGranted) {
        // 打开相册选择图片
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );
        
        if (image != null) {
          // 显示选中的图片
          _showSelectedImage(image);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未选择图片'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要相册权限才能访问图片'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('访问相册失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      // 检查相机权限
      var cameraStatus = await Permission.camera.request();
      
      if (cameraStatus.isGranted) {
        // 打开相机拍照
        final ImagePicker picker = ImagePicker();
        final XFile? photo = await picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );
        
        if (photo != null) {
          // 显示拍摄的照片
          _showSelectedImage(photo);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('未拍摄照片'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('需要相机权限才能拍照'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拍照失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSelectedImage(XFile imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('图片预览'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Image.file(
                  File(imageFile.path),
                  fit: BoxFit.contain,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '文件信息',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('路径: ${imageFile.path}'),
                    Text('大小: ${_getFileSize(imageFile.path)}'),
                    Text('格式: ${imageFile.path.split('.').last.toUpperCase()}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _shareImage(imageFile);
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('分享'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _deleteImage(imageFile);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('删除'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFileSize(String filePath) {
    try {
      final file = File(filePath);
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '${bytes}B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return '未知大小';
    }
  }

  Future<void> _shareImage(XFile imageFile) async {
    try {
      await Share.shareXFiles(
        [imageFile],
        text: '分享图片',
        subject: '来自Flutter应用的图片',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteImage(XFile imageFile) async {
    try {
      await File(imageFile.path).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('图片已删除'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('删除失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

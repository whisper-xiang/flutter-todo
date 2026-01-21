/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:37:54
 * @LastEditors: 轻语 243267674@qq.com
 * @LastEditTime: 2026-01-21 16:36:07
 */
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  Future<void> _toggleFlashlight() async {
    try {
      await TorchLight.enableTorch();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('手电筒已开启')),
      );
      // 3秒后自动关闭
      Timer(const Duration(seconds: 3), () async {
        await TorchLight.disableTorch();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('手电筒操作失败: $e')),
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
}

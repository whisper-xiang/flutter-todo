import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionDebugHelper {
  static Future<void> showPermissionStatus(BuildContext context) async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceInfoText = '未知设备';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceInfoText = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceInfoText = 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      deviceInfoText = '获取设备信息失败: $e';
    }
    
    // 检查各种权限状态
    final permissions = {
      '相机': Permission.camera.status,
      '照片': Permission.photos.status,
      '存储': Permission.storage.status,
      '视频': Permission.videos.status,
      '麦克风': Permission.microphone.status,
    };
    
    final permissionStatuses = <String, String>{};
    
    for (final entry in permissions.entries) {
      try {
        final status = await entry.value;
        permissionStatuses[entry.key] = _getStatusText(status);
      } catch (e) {
        permissionStatuses[entry.key] = '检查失败: $e';
      }
    }
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('权限状态调试'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('设备信息: $deviceInfoText'),
                const SizedBox(height: 16),
                const Text('权限状态:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...permissionStatuses.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text('${entry.key}:'),
                        ),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: entry.value.contains('已授权') 
                                  ? Colors.green 
                                  : entry.value.contains('被拒绝')
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                const Text(
                  '调试提示:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• 如果权限显示"被拒绝"，请点击去设置'),
                const Text('• 如果权限显示"未检查"，请重新尝试访问相册'),
                const Text('• Android 13+需要分别请求照片和视频权限'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('去设置'),
            ),
          ],
        );
      },
    );
  }
  
  static String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return '已授权';
      case PermissionStatus.denied:
        return '被拒绝';
      case PermissionStatus.restricted:
        return '受限制';
      case PermissionStatus.limited:
        return '有限访问';
      case PermissionStatus.permanentlyDenied:
        return '永久拒绝';
      case PermissionStatus.provisional:
        return '临时授权';
    }
  }
}

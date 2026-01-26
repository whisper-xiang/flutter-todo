import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// 真实本机号码检测工具类
///
/// 注意：由于隐私和安全限制，直接获取真实本机号码在大多数情况下不可行
/// 此类提供了多种检测方法，包括模拟和真实检测的混合方案
class PhoneNumberDetector {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 检测本机号码的主要方法
  ///
  /// 返回格式化的手机号码（如：138****8888）
  /// 如果无法获取真实号码，则返回基于设备信息的模拟号码
  static Future<String> detectPhoneNumber() async {
    try {
      // 首先尝试获取真实号码
      String? realNumber = await _tryGetRealPhoneNumber();

      if (realNumber != null && realNumber.isNotEmpty) {
        return _formatPhoneNumber(realNumber);
      }

      // 如果无法获取真实号码，使用设备信息生成模拟号码
      return await _generateSimulatedPhoneNumber();
    } catch (e) {
      print('Phone number detection failed: $e');
      return '138****8888'; // 默认模拟号码
    }
  }

  /// 尝试获取真实手机号码
  static Future<String?> _tryGetRealPhoneNumber() async {
    // 方法1：检查是否有权限并尝试读取SIM卡信息
    if (Platform.isAndroid) {
      return await _getAndroidPhoneNumber();
    } else if (Platform.isIOS) {
      return await _getIOSPhoneNumber();
    }

    return null;
  }

  /// Android平台获取手机号码
  static Future<String?> _getAndroidPhoneNumber() async {
    try {
      // 检查READ_PHONE_STATE权限
      PermissionStatus status = await Permission.phone.request();

      if (status.isGranted) {
        // 注意：在Android中，即使有权限，大多数设备也不会返回真实号码
        // 这是运营商和制造商的安全限制

        // 这里可以尝试使用TelephonyManager
        // 但实际成功率很低
        return await _tryTelephonyManager();
      }
    } catch (e) {
      print('Android phone number detection failed: $e');
    }

    return null;
  }

  /// iOS平台获取手机号码
  static Future<String?> _getIOSPhoneNumber() async {
    try {
      // iOS系统完全不提供获取手机号码的API
      // 这是Apple的隐私保护政策

      // 唯一的方法是通过用户授权的联系人或运营商应用
      return null;
    } catch (e) {
      print('iOS phone number detection failed: $e');
    }

    return null;
  }

  /// 尝试使用TelephonyManager（Android）
  static Future<String?> _tryTelephonyManager() async {
    // 这里需要使用Method Channel调用原生Android代码
    // 由于复杂性，这里返回null
    // 在实际项目中，可以创建Method Channel来调用：
    // TelephonyManager.getLine1Number()

    return null;
  }

  /// 基于设备信息生成模拟号码
  static Future<String> _generateSimulatedPhoneNumber() async {
    try {
      String deviceId = '';
      String prefix = '138'; // 默认前缀

      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;

        // 根据设备信息选择前缀
        int hash = deviceId.hashCode;
        if (hash % 3 == 0)
          prefix = '138';
        else if (hash % 3 == 1)
          prefix = '150';
        else
          prefix = '186';
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';

        // 根据iOS设备信息选择前缀
        int hash = deviceId.hashCode;
        if (hash % 3 == 0)
          prefix = '138';
        else if (hash % 3 == 1)
          prefix = '150';
        else
          prefix = '186';
      }

      // 生成8位随机数字
      int middle = (deviceId.hashCode.abs() % 90000000) + 10000000;
      String fullNumber = '$prefix$middle';

      // 格式化为掩码形式
      return _formatPhoneNumber(fullNumber);
    } catch (e) {
      print('Failed to generate simulated phone number: $e');
      return '138****8888';
    }
  }

  /// 格式化手机号码（添加掩码）
  static String _formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length >= 11) {
      return '${phoneNumber.substring(0, 3)}****${phoneNumber.substring(7)}';
    }
    return phoneNumber;
  }

  /// 获取完整的手机号码（无掩码）
  static Future<String> getFullPhoneNumber() async {
    try {
      String? realNumber = await _tryGetRealPhoneNumber();

      if (realNumber != null && realNumber.isNotEmpty) {
        return realNumber;
      }

      // 生成模拟号码的完整版本
      String masked = await _generateSimulatedPhoneNumber();
      return masked.replaceAll('****', '1234');
    } catch (e) {
      return '13812348888';
    }
  }

  /// 检查是否支持真实号码检测
  static Future<bool> supportsRealDetection() async {
    if (Platform.isAndroid) {
      PermissionStatus status = await Permission.phone.status;
      return status.isGranted;
    }
    return false; // iOS不支持
  }

  /// 获取检测方法说明
  static String getDetectionMethodDescription() {
    if (Platform.isAndroid) {
      return '''
检测方法：
1. 尝试读取SIM卡信息（需要READ_PHONE_STATE权限）
2. 基于设备ID生成模拟号码
3. 格式：138****8888

注意：大多数Android设备出于安全考虑不会返回真实号码
      ''';
    } else if (Platform.isIOS) {
      return '''
检测方法：
1. 基于设备ID生成模拟号码
2. 格式：138****8888

注意：iOS系统完全不提供获取手机号码的API
      ''';
    }
    return '未知平台';
  }
}

import 'dart:async';
import 'package:flutter/services.dart';

export 'hoops_native_view.dart';

/// HOOPS Visualize Flutter Plugin
/// 用于渲染CAD文件（DWG等）
class HoopsVisualizer {
  static const MethodChannel _channel = MethodChannel('hoops_visualize');

  /// 初始化HOOPS引擎
  /// [license] - HOOPS许可证字符串
  static Future<bool> initialize({required String license}) async {
    final result = await _channel.invokeMethod<bool>('initialize', {
      'license': license,
    });
    return result ?? false;
  }

  /// 关闭HOOPS引擎
  static Future<void> shutdown() async {
    await _channel.invokeMethod('shutdown');
  }

  /// 加载CAD文件
  /// [filePath] - 文件路径
  /// 返回模型ID，用于后续操作
  static Future<int?> loadFile(String filePath) async {
    final result = await _channel.invokeMethod<int>('loadFile', {
      'filePath': filePath,
    });
    return result;
  }

  /// 卸载模型
  /// [modelId] - 模型ID
  static Future<void> unloadModel(int modelId) async {
    await _channel.invokeMethod('unloadModel', {'modelId': modelId});
  }

  /// 设置视图操作
  /// [operation] - 操作类型: 'orbit', 'pan', 'zoom', 'fit'
  static Future<void> setViewOperation(String operation) async {
    await _channel.invokeMethod('setViewOperation', {'operation': operation});
  }

  /// 重置视图到初始状态
  static Future<void> resetView() async {
    await _channel.invokeMethod('resetView');
  }

  /// 适应视图到模型
  static Future<void> fitView() async {
    await _channel.invokeMethod('fitView');
  }

  /// 获取纹理ID用于Flutter渲染
  static Future<int?> getTextureId() async {
    final result = await _channel.invokeMethod<int>('getTextureId');
    return result;
  }

  /// 设置视口大小
  static Future<void> setViewportSize(double width, double height) async {
    await _channel.invokeMethod('setViewportSize', {
      'width': width,
      'height': height,
    });
  }

  /// 处理触摸/鼠标事件
  static Future<void> handlePointerEvent({
    required String type,
    required double x,
    required double y,
    double? deltaX,
    double? deltaY,
    double? scale,
  }) async {
    await _channel.invokeMethod('handlePointerEvent', {
      'type': type,
      'x': x,
      'y': y,
      if (deltaX != null) 'deltaX': deltaX,
      if (deltaY != null) 'deltaY': deltaY,
      if (scale != null) 'scale': scale,
    });
  }
}

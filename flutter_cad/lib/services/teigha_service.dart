import 'package:flutter/services.dart';
import 'dart:typed_data';

class TeighaService {
  static const MethodChannel _channel = MethodChannel('teigha_sdk');

  static Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initialize');
    } catch (e) {
      throw Exception('Failed to initialize Teigha SDK: $e');
    }
  }

  static Future<Uint8List?> renderDwgToImage(
    String filePath, {
    int width = 1024,
    int height = 768,
    String format = 'png',
  }) async {
    try {
      final result = await _channel.invokeMethod('renderDwgToImage', {
        'filePath': filePath,
        'width': width,
        'height': height,
        'format': format,
      });

      if (result is Uint8List) {
        return result;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to render DWG: $e');
    }
  }

  static Future<Map<String, dynamic>?> getDwgInfo(String filePath) async {
    try {
      final result = await _channel.invokeMethod('getDwgInfo', {
        'filePath': filePath,
      });

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get DWG info: $e');
    }
  }

  static Future<List<String>?> getLayers(String filePath) async {
    try {
      final result = await _channel.invokeMethod('getLayers', {
        'filePath': filePath,
      });

      if (result is List) {
        return result.cast<String>();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get layers: $e');
    }
  }

  static Future<void> cleanup() async {
    try {
      await _channel.invokeMethod('cleanup');
    } catch (e) {
      throw Exception('Failed to cleanup Teigha SDK: $e');
    }
  }
}

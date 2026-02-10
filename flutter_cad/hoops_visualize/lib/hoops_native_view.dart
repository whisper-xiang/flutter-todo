import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class HoopsNativeView extends StatefulWidget {
  final String license;
  final String? filePath;
  final VoidCallback? onViewCreated;
  final ValueChanged<bool>? onFileLoaded;

  const HoopsNativeView({
    super.key,
    required this.license,
    this.filePath,
    this.onViewCreated,
    this.onFileLoaded,
  });

  @override
  State<HoopsNativeView> createState() => HoopsNativeViewState();
}

class HoopsNativeViewState extends State<HoopsNativeView> {
  MethodChannel? _channel;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void didUpdateWidget(HoopsNativeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath && widget.filePath != null) {
      loadFile(widget.filePath!);
    }
  }

  Future<bool> loadFile(String filePath) async {
    if (_channel == null || _isDisposed) return false;
    try {
      final result = await _channel!.invokeMethod<bool>('loadFile', {
        'filePath': filePath,
      });
      if (!_isDisposed) {
        widget.onFileLoaded?.call(result ?? false);
      }
      return result ?? false;
    } catch (e) {
      debugPrint('HoopsNativeView loadFile error: $e');
      if (!_isDisposed) {
        widget.onFileLoaded?.call(false);
      }
      return false;
    }
  }

  Future<void> fitView() async {
    if (_channel != null && !_isDisposed) {
      await _channel?.invokeMethod('fitView');
    }
  }

  Future<void> resetView() async {
    if (_channel != null && !_isDisposed) {
      await _channel?.invokeMethod('resetView');
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('hoops_visualize/view_$viewId');

    // 初始化
    _initializeView();
  }

  Future<void> _initializeView() async {
    if (_channel == null || _isDisposed) return;

    try {
      // 尝试初始化引擎，如果已经初始化会失败但这是正常的
      try {
        final success = await _channel!.invokeMethod<bool>('initialize', {
          'license': widget.license,
        });

        if (success == true && !_isDisposed) {
          _isInitialized = true;
          widget.onViewCreated?.call();

          // 如果有初始文件路径，加载它
          if (widget.filePath != null) {
            await loadFile(widget.filePath!);
          }
        }
      } catch (e) {
        // 如果初始化失败是因为引擎已经初始化，直接标记为已初始化
        if (e.toString().contains('already') ||
            e.toString().contains('World object')) {
          debugPrint('HOOPS engine already initialized, continuing...');
          _isInitialized = true;
          widget.onViewCreated?.call();

          if (widget.filePath != null && !_isDisposed) {
            await loadFile(widget.filePath!);
          }
        } else {
          // 其他错误，重新抛出
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('HoopsNativeView initialize error: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // 安全地关闭通道，不调用 shutdown 以避免二次打开时的问题
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String viewType = 'hoops_native_view';
    final Map<String, dynamic> creationParams = {'license': widget.license};

    if (defaultTargetPlatform == TargetPlatform.macOS) {
      return AppKitView(
        viewType: viewType,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }

    return const Center(
      child: Text('HOOPS Native View is only supported on macOS'),
    );
  }
}

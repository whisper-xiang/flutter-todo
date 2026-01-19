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

  @override
  void didUpdateWidget(HoopsNativeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath && widget.filePath != null) {
      loadFile(widget.filePath!);
    }
  }

  Future<bool> loadFile(String filePath) async {
    if (_channel == null) return false;
    try {
      final result = await _channel!.invokeMethod<bool>('loadFile', {
        'filePath': filePath,
      });
      widget.onFileLoaded?.call(result ?? false);
      return result ?? false;
    } catch (e) {
      debugPrint('HoopsNativeView loadFile error: $e');
      widget.onFileLoaded?.call(false);
      return false;
    }
  }

  Future<void> fitView() async {
    await _channel?.invokeMethod('fitView');
  }

  Future<void> resetView() async {
    await _channel?.invokeMethod('resetView');
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('hoops_visualize/view_$viewId');

    // 初始化
    _initializeView();
  }

  Future<void> _initializeView() async {
    if (_channel == null) return;

    try {
      final success = await _channel!.invokeMethod<bool>('initialize', {
        'license': widget.license,
      });

      if (success == true) {
        _isInitialized = true;
        widget.onViewCreated?.call();

        // 如果有初始文件路径，加载它
        if (widget.filePath != null) {
          await loadFile(widget.filePath!);
        }
      }
    } catch (e) {
      debugPrint('HoopsNativeView initialize error: $e');
    }
  }

  @override
  void dispose() {
    _channel?.invokeMethod('shutdown');
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

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'hoops_visualize.dart';

/// HOOPS Visualize渲染视图Widget
class HoopsVisualizeView extends StatefulWidget {
  /// CAD文件路径
  final String? filePath;

  /// 加载完成回调
  final VoidCallback? onLoaded;

  /// 加载错误回调
  final void Function(String error)? onError;

  /// 背景颜色
  final Color backgroundColor;

  const HoopsVisualizeView({
    super.key,
    this.filePath,
    this.onLoaded,
    this.onError,
    this.backgroundColor = Colors.black,
  });

  @override
  State<HoopsVisualizeView> createState() => _HoopsVisualizeViewState();
}

class _HoopsVisualizeViewState extends State<HoopsVisualizeView> {
  int? _textureId;
  bool _isLoading = true;
  String? _errorMessage;
  int? _modelId;

  @override
  void initState() {
    super.initState();
    _initializeView();
  }

  @override
  void didUpdateWidget(HoopsVisualizeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath && widget.filePath != null) {
      _loadFile(widget.filePath!);
    }
  }

  Future<void> _initializeView() async {
    try {
      // 获取纹理ID
      _textureId = await HoopsVisualizer.getTextureId();

      if (_textureId != null && widget.filePath != null) {
        await _loadFile(widget.filePath!);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      widget.onError?.call(e.toString());
    }
  }

  Future<void> _loadFile(String filePath) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 卸载之前的模型
      if (_modelId != null) {
        await HoopsVisualizer.unloadModel(_modelId!);
      }

      // 加载新文件
      _modelId = await HoopsVisualizer.loadFile(filePath);

      if (_modelId != null) {
        await HoopsVisualizer.fitView();
        widget.onLoaded?.call();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      widget.onError?.call(e.toString());
    }
  }

  @override
  void dispose() {
    if (_modelId != null) {
      HoopsVisualizer.unloadModel(_modelId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 更新视口大小
        if (_textureId != null) {
          HoopsVisualizer.setViewportSize(
            constraints.maxWidth,
            constraints.maxHeight,
          );
        }

        return Container(color: widget.backgroundColor, child: _buildContent());
      },
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('加载失败', style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_textureId == null) {
      return const Center(
        child: Text('HOOPS引擎未初始化', style: TextStyle(color: Colors.white)),
      );
    }

    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerSignal: _handlePointerSignal,
      child: Texture(textureId: _textureId!),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    HoopsVisualizer.handlePointerEvent(
      type: 'down',
      x: event.localPosition.dx,
      y: event.localPosition.dy,
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    HoopsVisualizer.handlePointerEvent(
      type: 'move',
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      deltaX: event.delta.dx,
      deltaY: event.delta.dy,
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    HoopsVisualizer.handlePointerEvent(
      type: 'up',
      x: event.localPosition.dx,
      y: event.localPosition.dy,
    );
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // 滚轮缩放
      final scale = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
      HoopsVisualizer.handlePointerEvent(
        type: 'scroll',
        x: event.localPosition.dx,
        y: event.localPosition.dy,
        scale: scale,
      );
    }
  }
}

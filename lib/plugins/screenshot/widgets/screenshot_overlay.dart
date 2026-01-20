library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/screenshot_models.dart';

/// 截图覆盖层
///
/// 全屏覆盖层，允许用户拖拽选择截图区域
class ScreenshotOverlay extends StatefulWidget {
  final Uint8List screenshotBytes;
  final Function(Rect) onRegionSelected;
  final VoidCallback onCancel;

  const ScreenshotOverlay({
    super.key,
    required this.screenshotBytes,
    required this.onRegionSelected,
    required this.onCancel,
  });

  @override
  State<ScreenshotOverlay> createState() => _ScreenshotOverlayState();
}

class _ScreenshotOverlayState extends State<ScreenshotOverlay> {
  Offset? _startPosition;
  Offset? _currentPosition;
  final double _borderWidth = 2.0;
  final double _handleSize = 10.0;
  final double _minimumSize = 10.0;

  @override
  void initState() {
    super.initState();
    // 进入全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    // 退出全屏模式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // 背景截图（完全清晰）
          Positioned.fill(
            child: Image.memory(
              widget.screenshotBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          // 半透明蒙版层（在选择区域外显示）
          Positioned.fill(child: _buildDimOverlay()),

          // 手势检测层
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior.translucent,
              child: _buildSelectionContent(),
            ),
          ),

          // 工具栏
          _buildToolbar(),
        ],
      ),
    );
  }

  /// 构建半透明蒙版（在选择区域外显示）
  Widget _buildDimOverlay() {
    if (_startPosition == null || _currentPosition == null) {
      // 没有选择时，整个屏幕半透明
      return Container(color: Colors.black.withOpacity(0.3));
    }

    final rect = _calculateRect(_startPosition!, _currentPosition!);
    if (rect.width < _minimumSize || rect.height < _minimumSize) {
      return Container(color: Colors.black.withOpacity(0.3));
    }

    // 有选择时，使用 Stack 在选择区域外显示蒙版
    // 我们使用四个半透明容器来覆盖非选择区域
    return Stack(
      children: [
        // 上方区域
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          height: rect.top,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // 下方区域
        Positioned(
          left: 0,
          top: rect.bottom,
          right: 0,
          bottom: 0,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // 左侧区域
        Positioned(
          left: 0,
          top: rect.top,
          width: rect.left,
          height: rect.height,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
        // 右侧区域
        Positioned(
          left: rect.right,
          top: rect.top,
          right: 0,
          height: rect.height,
          child: Container(color: Colors.black.withOpacity(0.5)),
        ),
      ],
    );
  }

  /// 构建选择区域内容
  Widget _buildSelectionContent() {
    if (_startPosition == null || _currentPosition == null) {
      return const SizedBox.shrink();
    }

    final rect = _calculateRect(_startPosition!, _currentPosition!);
    if (rect.width < _minimumSize || rect.height < _minimumSize) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // 选择框边框
        Positioned(
          left: rect.left,
          top: rect.top,
          child: Container(
            width: rect.width,
            height: rect.height,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: _borderWidth),
            ),
          ),
        ),

        // 四个角的调整手柄
        _buildHandle(rect.left, rect.top), // 左上
        _buildHandle(rect.right, rect.top), // 右上
        _buildHandle(rect.left, rect.bottom), // 左下
        _buildHandle(rect.right, rect.bottom), // 右下
        // 尺寸标签
        _buildSizeLabel(rect),
      ],
    );
  }

  /// 构建调整手柄
  Widget _buildHandle(double x, double y) {
    return Positioned(
      left: x - _handleSize,
      top: y - _handleSize,
      child: Container(
        width: _handleSize * 2,
        height: _handleSize * 2,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  /// 构建尺寸标签
  Widget _buildSizeLabel(Rect rect) {
    return Positioned(
      left: rect.left,
      top: rect.top - 30,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${rect.width.toInt()} x ${rect.height.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onCancel,
                tooltip: '取消',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _canConfirmSelection() ? _confirmSelection : null,
                tooltip: '确认',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 处理拖拽开始
  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _startPosition = details.localPosition;
      _currentPosition = details.localPosition;
    });
  }

  /// 处理拖拽更新
  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPosition = details.localPosition;
    });
  }

  /// 处理拖拽结束
  void _handlePanEnd(DragEndDetails details) {
    // 不在这里确认选择，让用户手动点击确认按钮
  }

  /// 计算矩形区域
  Rect _calculateRect(Offset start, Offset end) {
    final left = start.dx < end.dx ? start.dx : end.dx;
    final top = start.dy < end.dy ? start.dy : end.dy;
    final width = (end.dx - start.dx).abs();
    final height = (end.dy - start.dy).abs();

    return Rect.fromLTWH(left, top, width, height);
  }

  /// 检查是否可以确认选择
  bool _canConfirmSelection() {
    if (_startPosition == null || _currentPosition == null) {
      return false;
    }

    final rect = _calculateRect(_startPosition!, _currentPosition!);
    return rect.width >= _minimumSize && rect.height >= _minimumSize;
  }

  /// 确认选择
  void _confirmSelection() {
    if (!_canConfirmSelection()) return;

    final rect = _calculateRect(_startPosition!, _currentPosition!);
    widget.onRegionSelected(rect);
  }
}

/// 截图触发器
///
/// 用于触发截图的 Widget
class ScreenshotTrigger extends StatefulWidget {
  final Widget child;
  final Future<Uint8List?> Function() onCaptureRequested;

  const ScreenshotTrigger({
    super.key,
    required this.child,
    required this.onCaptureRequested,
  });

  @override
  State<ScreenshotTrigger> createState() => _ScreenshotTriggerState();
}

class _ScreenshotTriggerState extends State<ScreenshotTrigger> {
  bool _isCapturing = false;

  Future<void> _startCapture() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final screenshotBytes = await widget.onCaptureRequested();
      if (screenshotBytes != null && mounted) {
        await _showScreenshotOverlay(screenshotBytes);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<void> _showScreenshotOverlay(Uint8List screenshotBytes) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return ScreenshotOverlay(
            screenshotBytes: screenshotBytes,
            onRegionSelected: (rect) {
              Navigator.of(context).pop(rect);
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          );
        },
        opaque: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onLongPress: _startCapture, child: widget.child);
  }
}

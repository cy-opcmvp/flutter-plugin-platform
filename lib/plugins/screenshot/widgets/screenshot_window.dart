library;

import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/screenshot_models.dart';

/// 截图覆盖层
///
/// 使用 Route 在当前窗口显示全屏截图界面
class ScreenshotWindow {
  /// 显示全屏区域截图界面
  ///
  /// [context] BuildContext
  /// [screenshotBytes] 当前屏幕的截图字节数据
  /// [onRegionSelected] 用户选择区域后的回调
  /// [onCancel] 用户取消的回调
  static Future<void> showRegionCapture({
    required BuildContext context,
    required Uint8List screenshotBytes,
    required Function(Rect) onRegionSelected,
    required VoidCallback onCancel,
  }) async {
    // 进入全屏模式
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 设置为全屏
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 使用全屏 Dialog 显示截图界面
    final result = await showDialog<Rect>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => _ScreenshotRegionDialog(
        screenshotBytes: screenshotBytes,
        onRegionSelected: (rect) {
          Navigator.of(context).pop(rect);
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );

    // 恢复系统UI
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([]);

    if (result != null) {
      onRegionSelected(result);
    } else {
      onCancel();
    }
  }
}

/// 全屏区域截图对话框
class _ScreenshotRegionDialog extends StatefulWidget {
  final Uint8List screenshotBytes;
  final Function(Rect) onRegionSelected;
  final VoidCallback onCancel;

  const _ScreenshotRegionDialog({
    required this.screenshotBytes,
    required this.onRegionSelected,
    required this.onCancel,
  });

  @override
  State<_ScreenshotRegionDialog> createState() => _ScreenshotRegionDialogState();
}

class _ScreenshotRegionDialogState extends State<_ScreenshotRegionDialog> {
  Offset? _startPosition;
  Offset? _currentPosition;
  final double _borderWidth = 3.0;
  final double _handleSize = 12.0;
  final double _minimumSize = 20.0;

  @override
  Widget build(BuildContext context) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(context).size;

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
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
            Positioned.fill(
              child: _buildDimOverlay(),
            ),

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
      ),
    );
  }

  /// 构建半透明蒙版
  Widget _buildDimOverlay() {
    if (_startPosition == null || _currentPosition == null) {
      return Container(color: Colors.black.withOpacity(0.3));
    }

    final rect = _calculateRect(_startPosition!, _currentPosition!);
    if (rect.width < _minimumSize || rect.height < _minimumSize) {
      return Container(color: Colors.black.withOpacity(0.3));
    }

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
              border: Border.all(
                color: Colors.red,
                width: _borderWidth,
              ),
            ),
          ),
        ),

        // 四个角的调整手柄
        _buildHandle(rect.left, rect.top),
        _buildHandle(rect.right, rect.top),
        _buildHandle(rect.left, rect.bottom),
        _buildHandle(rect.right, rect.bottom),

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
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  /// 构建尺寸标签
  Widget _buildSizeLabel(Rect rect) {
    return Positioned(
      left: rect.left,
      top: rect.top - 35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          '${rect.width.toInt()} x ${rect.height.toInt()}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                label: const Text('取消', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _canConfirmSelection() ? _confirmSelection : null,
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
                label: const Text('确认截图', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
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
    // 不在这里确认，让用户手动点击确认按钮
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

/// 区域选择 overlay（宿主呈现面）。
///
/// 全屏路由内容：底图铺满 + 半透明遮罩 + 红框与四角控制点 + 尺寸标签 +
/// 工具条（保存/复制/放弃）。交互：空白拖拽新建选区、框内拖动移动、
/// 角点缩放（命中容差见 [kRegionHandleHitSlop]）；Enter 确认保存、
/// Esc 取消；选区小于 [kMinRegionLogicalSize] 时确认被忽略。
///
/// 纯 widget：不触碰窗口形态与全局热键（由 coordinator 负责）；退出
/// 经 `Navigator.pop` 返回 [ScreenRegion]（null 表示取消）。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screenshot/screenshot.dart';

/// 区域选择 overlay。
final class RegionSelectionOverlay extends StatefulWidget {
  /// 创建 overlay。
  ///
  /// [imageBytes] 为全屏底图 PNG；[imageLogicalSize] 携带底图像素尺寸
  ///（left/top 恒 0），物理选区按 视口:像素 比例折算。
  const RegionSelectionOverlay({
    required this.imageBytes,
    required this.imageLogicalSize,
    required this.saveLabel,
    required this.copyLabel,
    required this.discardLabel,
    required this.hint,
    super.key,
  });

  /// 全屏底图字节（PNG）。
  final Uint8List imageBytes;

  /// 底图像素尺寸（Rect(0,0,像素宽,像素高)）。
  final Rect imageLogicalSize;

  /// 工具条：保存按钮文案。
  final String saveLabel;

  /// 工具条：复制按钮文案。
  final String copyLabel;

  /// 工具条：放弃按钮文案。
  final String discardLabel;

  /// 操作提示（框选/ESC/Enter）。
  final String hint;

  @override
  State<RegionSelectionOverlay> createState() => _RegionSelectionOverlayState();
}

class _RegionSelectionOverlayState extends State<RegionSelectionOverlay> {
  final FocusNode _focusNode = FocusNode();

  /// 当前选区（视口逻辑坐标）。
  Rect? _selection;

  /// 当前拖拽模式（new/move/resize）。
  String? _dragMode;

  /// 拖拽起点。
  Offset? _dragStart;

  /// 拖拽前选区（move/resize 基准）。
  Rect? _dragOrigin;

  /// 最近一次布局视口尺寸（拖拽回调在 builder 作用域之外使用）。
  Size _viewportSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// 确认选区并以 [action] 退出（选区过小则忽略）。
  void _confirm(ScreenRegionAction action) {
    final Rect? selection = _selection;
    if (selection == null ||
        _viewportSize == Size.zero ||
        selection.width < kMinRegionLogicalSize ||
        selection.height < kMinRegionLogicalSize) {
      return;
    }
    final Rect physical = screenshotPhysicalRegionFromLogical(
      selection,
      _viewportSize,
      widget.imageLogicalSize.width.round(),
      widget.imageLogicalSize.height.round(),
    );
    Navigator.of(context).pop(
      ScreenRegion(
        logicalRect: selection,
        physicalRect: physical,
        action: action,
      ),
    );
  }

  /// 取消（Esc / 放弃按钮）。
  void _cancel() {
    Navigator.of(context).pop(null);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _confirm(ScreenRegionAction.save);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPanStart(DragStartDetails details) {
    _dragMode = screenshotRegionDragModeFor(details.localPosition, _selection);
    _dragStart = details.localPosition;
    _dragOrigin = _selection;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final Offset? start = _dragStart;
    if (start == null || _viewportSize == Size.zero) {
      return;
    }
    setState(() {
      _selection = screenshotRegionRectForDrag(
        dragMode: _dragMode ?? 'new',
        start: start,
        current: details.localPosition,
        viewportSize: _viewportSize,
        previous: _dragOrigin,
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _dragMode = null;
      _dragStart = null;
      _dragOrigin = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          _viewportSize = constraints.biggest;
          final Rect? selection = _selection;
          return Focus(
            focusNode: _focusNode,
            onKeyEvent: _onKeyEvent,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
                // 拖拽手势层：位于底图之上、遮罩/工具条之下；translucent
                // 保证遮罩区域仍可发起框选。
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                  ),
                ),
                if (selection != null) ...<Widget>[
                  IgnorePointer(child: _buildMask(_viewportSize, selection)),
                  IgnorePointer(child: _buildFrame(selection)),
                  _buildSizeLabel(selection),
                  _buildToolbar(selection),
                ] else
                  _buildHint(),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 半透明遮罩：围绕选区的四段黑色蒙层。
  Widget _buildMask(Size viewport, Rect selection) {
    const Color maskColor = Color(0x66000000);
    final Rect top = Rect.fromLTWH(
      0,
      0,
      viewport.width,
      selection.top.clamp(0.0, viewport.height),
    );
    final Rect bottom = Rect.fromLTWH(
      0,
      selection.bottom,
      viewport.width,
      (viewport.height - selection.bottom).clamp(0.0, viewport.height),
    );
    final Rect left = Rect.fromLTWH(
      0,
      selection.top,
      selection.left.clamp(0.0, viewport.width),
      selection.height,
    );
    final Rect right = Rect.fromLTWH(
      selection.right,
      selection.top,
      (viewport.width - selection.right).clamp(0.0, viewport.width),
      selection.height,
    );
    return Stack(
      children: <Widget>[
        if (top.height > 0) _maskRect(top, maskColor),
        if (bottom.height > 0) _maskRect(bottom, maskColor),
        if (left.width > 0) _maskRect(left, maskColor),
        if (right.width > 0) _maskRect(right, maskColor),
      ],
    );
  }

  Widget _maskRect(Rect rect, Color color) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: ColoredBox(color: color),
    );
  }

  /// 红色边框 + 四角白色控制点。
  Widget _buildFrame(Rect selection) {
    const double handleSize = 8;
    return Stack(
      children: <Widget>[
        Positioned.fromRect(
          rect: selection,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
        ...<Offset>[
          Offset(selection.left, selection.top),
          Offset(selection.right, selection.top),
          Offset(selection.left, selection.bottom),
          Offset(selection.right, selection.bottom),
        ].map(
          (Offset corner) => Positioned(
            left: corner.dx - handleSize / 2,
            top: corner.dy - handleSize / 2,
            width: handleSize,
            height: handleSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.redAccent, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 尺寸标签（选区左上角上方，越界时贴顶）。
  Widget _buildSizeLabel(Rect selection) {
    final double top = (selection.top - 28).clamp(0.0, double.infinity);
    // Positioned 必须是 Stack 直接子级，IgnorePointer 包在 child 内。
    return Positioned(
      left: selection.left.clamp(0.0, double.infinity),
      top: top,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          color: Colors.black87,
          child: Text(
            '${selection.width.round()}×${selection.height.round()}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  /// 未选中时的操作提示（顶部居中）。
  Widget _buildHint() {
    return Positioned(
      left: 0,
      right: 0,
      top: 16,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black87,
          child: Text(
            widget.hint,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ),
    );
  }

  /// 工具条（选区下方；越界时回退选区上方，仍越界贴视口底部）。
  Widget _buildToolbar(Rect selection) {
    const double toolbarHeight = 44;
    final Size viewport = _viewportSize;
    double top = selection.bottom + 8;
    if (top + toolbarHeight > viewport.height) {
      top = selection.top - 8 - toolbarHeight;
    }
    if (top < 0) {
      top = (viewport.height - toolbarHeight - 8).clamp(0.0, double.infinity);
    }
    final double left = (selection.left).clamp(
      0.0,
      (viewport.width - 200).clamp(0.0, double.infinity),
    );
    return Positioned(
      left: left,
      top: top,
      height: toolbarHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextButton(
              onPressed: () => _confirm(ScreenRegionAction.save),
              child: Text(widget.saveLabel),
            ),
            TextButton(
              onPressed: () => _confirm(ScreenRegionAction.copy),
              child: Text(widget.copyLabel),
            ),
            TextButton(onPressed: _cancel, child: Text(widget.discardLabel)),
          ],
        ),
      ),
    );
  }
}

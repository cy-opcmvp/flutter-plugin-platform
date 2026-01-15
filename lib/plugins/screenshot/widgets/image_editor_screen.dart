library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/annotation_models.dart';
import '../models/screenshot_settings.dart';

/// 图片编辑界面
///
/// 提供截图后的标注和编辑功能
class ImageEditorScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List) onSave;

  const ImageEditorScreen({
    super.key,
    required this.imageBytes,
    required this.onSave,
  });

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final List<Annotation> _annotations = [];
  AnnotationType _selectedTool = AnnotationType.pen;
  bool _isDrawing = false;
  final List<Offset> _currentPath = [];

  // 工具设置
  Color _selectedColor = Colors.red;
  double _strokeWidth = 3.0;
  double _mosaicBlockSize = 10.0;

  // 撤销/重做栈
  final List<List<Annotation>> _undoStack = [];
  final List<List<Annotation>> _redoStack = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑截图'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _canUndo() ? _undo : null,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _canRedo() ? _redo : null,
            tooltip: '重做',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _saveAndClose(),
            tooltip: '保存',
          ),
        ],
      ),
      body: Column(
        children: [
          // 工具栏
          _buildToolbar(),

          // 颜色和线条设置
          _buildSettingsBar(),

          // 编辑画布
          Expanded(
            child: _buildCanvas(),
          ),
        ],
      ),
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ToolButton(
            icon: Icons.edit,
            label: '画笔',
            selected: _selectedTool == AnnotationType.pen,
            onTap: () => setState(() => _selectedTool = AnnotationType.pen),
          ),
          _ToolButton(
            icon: Icons.crop_square,
            label: '矩形',
            selected: _selectedTool == AnnotationType.rectangle,
            onTap: () => setState(() => _selectedTool = AnnotationType.rectangle),
          ),
          _ToolButton(
            icon: Icons.arrow_forward,
            label: '箭头',
            selected: _selectedTool == AnnotationType.arrow,
            onTap: () => setState(() => _selectedTool == AnnotationType.arrow
                ? null
                : _selectedTool = AnnotationType.arrow),
          ),
          _ToolButton(
            icon: Icons.text_fields,
            label: '文字',
            selected: _selectedTool == AnnotationType.text,
            onTap: () => setState(() => _selectedTool = AnnotationType.text),
          ),
          _ToolButton(
            icon: Icons.blur_on,
            label: '马赛克',
            selected: _selectedTool == AnnotationType.mosaic,
            onTap: () => setState(() => _selectedTool == AnnotationType.mosaic
                ? null
                : _selectedTool = AnnotationType.mosaic),
          ),
        ],
      ),
    );
  }

  /// 构建设置栏
  Widget _buildSettingsBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          // 颜色选择器
          Icon(Icons.palette, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          ...[
            Colors.red,
            Colors.blue,
            Colors.green,
            Colors.yellow,
            Colors.black,
            Colors.white,
          ].map((color) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // 线条宽度
          if (_selectedTool == AnnotationType.pen ||
              _selectedTool == AnnotationType.rectangle ||
              _selectedTool == AnnotationType.arrow)
            Row(
              children: [
                Icon(Icons.line_weight, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  onChanged: (value) => setState(() => _strokeWidth = value),
                ),
                Text('${_strokeWidth.toInt()}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建画布
  Widget _buildCanvas() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: GestureDetector(
            onPanStart: _handleCanvasPanStart,
            onPanUpdate: _handleCanvasPanUpdate,
            onPanEnd: _handleCanvasPanEnd,
            child: Stack(
              children: [
                Image.memory(widget.imageBytes),
                // 标注层
                ..._annotations.map((annotation) => _buildAnnotationWidget(annotation)),
                // 当前绘制路径
                if (_isDrawing && _currentPath.isNotEmpty)
                  _buildCurrentPath(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建标注 Widget
  Widget _buildAnnotationWidget(Annotation annotation) {
    // 简化实现，只显示矩形标注
    if (annotation is RectangleAnnotation) {
      final rect = annotation.rect;
      return Positioned(
        left: rect.left,
        top: rect.top,
        child: Container(
          width: rect.width,
          height: rect.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: Color(annotation.color.toARGB32()),
              width: annotation.strokeWidth,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// 构建当前绘制路径
  Widget _buildCurrentPath() {
    if (_currentPath.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: Size.infinite,
      painter: _PathPainter(
        path: _currentPath,
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      ),
    );
  }

  /// 处理画布拖拽开始
  void _handleCanvasPanStart(DragStartDetails details) {
    if (_selectedTool != AnnotationType.pen) return;

    setState(() {
      _isDrawing = true;
      _currentPath.clear();
      _currentPath.add(details.localPosition);
    });
  }

  /// 处理画布拖拽更新
  void _handleCanvasPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _selectedTool != AnnotationType.pen) return;

    setState(() {
      _currentPath.add(details.localPosition);
    });
  }

  /// 处理画布拖拽结束
  void _handleCanvasPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    if (_currentPath.length > 1) {
      _saveStateToUndoStack();

      final annotation = PenAnnotation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        points: List.from(_currentPath),
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      );

      _annotations.add(annotation);
    }

    setState(() {
      _isDrawing = false;
      _currentPath.clear();
    });
  }

  /// 保存状态到撤销栈
  void _saveStateToUndoStack() {
    _undoStack.add(List.from(_annotations));
    _redoStack.clear();
  }

  /// 撤销
  void _undo() {
    if (_undoStack.isEmpty) return;

    _redoStack.add(List.from(_annotations));
    _annotations.clear();
    _annotations.addAll(_undoStack.last);
    _undoStack.removeLast();

    setState(() {});
  }

  /// 重做
  void _redo() {
    if (_redoStack.isEmpty) return;

    _undoStack.add(List.from(_annotations));
    _annotations.clear();
    _annotations.addAll(_redoStack.last);
    _redoStack.removeLast();

    setState(() {});
  }

  /// 检查是否可以撤销
  bool _canUndo() => _undoStack.isNotEmpty;

  /// 检查是否可以重做
  bool _canRedo() => _redoStack.isNotEmpty;

  /// 保存并关闭
  Future<void> _saveAndClose() async {
    // 这里应该应用所有标注到图片上
    // 简化实现：直接返回原图
    widget.onSave(widget.imageBytes);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// 工具按钮
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 路径绘制器
class _PathPainter extends CustomPainter {
  final List<Offset> path;
  final Color color;
  final double strokeWidth;

  _PathPainter({
    required this.path,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final pathObj = Path();
    pathObj.moveTo(path.first.dx, path.first.dy);

    for (var i = 1; i < path.length; i++) {
      pathObj.lineTo(path[i].dx, path[i].dy);
    }

    canvas.drawPath(pathObj, paint);
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

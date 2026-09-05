/// 区域选择与全局热键接缝：类型、坐标换算与 combo 校验纯逻辑
/// （设计 §2.1/§2.2，S1 批C）。
///
/// 插件包保持零平台依赖：overlay 与热键注册均由宿主经函数缝注入，
/// 本文件只声明缝的形状与可独立测试的纯逻辑。
library;

import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

/// 选区确认方式（工具条决定后仍返回选区，落盘动作归插件）。
enum ScreenRegionAction {
  /// 保存：走批次 B 落盘 + 自动复制闭环。
  save,

  /// 仅复制：选区图像写剪贴板，不落盘。
  copy,

  /// 放弃：丢弃本次选择。
  discard,
}

/// 一次区域选择的产物。
///
/// - [logicalRect]：overlay 逻辑显示坐标系的选区（全屏 overlay 与屏幕
///   逻辑坐标 1:1 对应，即 `captureRegion` 的输入坐标系）；
/// - [physicalRect]：底图物理像素坐标系的选区（逻辑 × 物理缩放比），
///   供展示、裁剪与换算断言。
final class ScreenRegion {
  /// 创建选区产物。
  const ScreenRegion({
    required this.logicalRect,
    required this.physicalRect,
    required this.action,
  });

  /// 逻辑显示坐标系选区。
  final Rect logicalRect;

  /// 底图物理像素坐标系选区。
  final Rect physicalRect;

  /// 确认方式。
  final ScreenRegionAction action;
}

/// 区域选择缝：宿主注入 overlay 实现，插件传入已捕获的全屏底图
/// （物理像素）与底图像素尺寸（[imageLogicalSize] 命名沿用规格；
/// 控制器无 DPR 语境，实际传入底图像素尺寸 Rect(0,0,w,h)，overlay
/// 以自身视口重新换算缩放比）。
///
/// 返回 [ScreenRegion]；返回 null 表示取消（ESC/关闭 overlay）。
typedef RegionSelector =
    Future<ScreenRegion?> Function(
      Uint8List fullscreenImage,
      Rect imageLogicalSize,
    );

/// 全局热键绑定缝：宿主把 GlobalHotkeys 能力包装为按 combo 注册；
/// [fired] 为触发回调。注册失败（组合键冲突/非法/平台不支持）返回
/// false，调用方折算 `hotkey.register_failed` 语义。
typedef HotkeyBinder =
    Future<bool> Function(String combo, void Function() fired);

/// 全局热键解绑缝：按 combo 反注册（未绑定为无操作）。
typedef HotkeyUnbinder = Future<void> Function(String combo);

/// overlay 内最小选区边长（逻辑像素）。
const double kMinRegionLogicalSize = 8;

/// 逻辑选区 → 底图物理像素选区。
///
/// 缩放比 = 底图像素尺寸 / overlay 视口逻辑尺寸；结果四舍五入取整并
/// 钳制到底图边界。宿主 overlay 以 `BoxFit.fill` 把底图铺满视口时
/// 使用本换算产出 [ScreenRegion.physicalRect]。
Rect screenshotPhysicalRegionFromLogical(
  Rect logical,
  Size viewportSize,
  int imageWidth,
  int imageHeight,
) {
  final double scaleX = imageWidth / viewportSize.width;
  final double scaleY = imageHeight / viewportSize.height;
  // 先钳制四边到像素边界，再由钳制后的边长推导宽高（保证选区不越
  // 底图；负/超界逻辑选区由 overlay 拖拽钳制兜底，这里只防御）。
  final double left = (logical.left * scaleX).roundToDouble().clamp(
    0,
    imageWidth.toDouble(),
  );
  final double top = (logical.top * scaleY).roundToDouble().clamp(
    0,
    imageHeight.toDouble(),
  );
  final double right = (logical.right * scaleX).roundToDouble().clamp(
    0,
    imageWidth.toDouble(),
  );
  final double bottom = (logical.bottom * scaleY).roundToDouble().clamp(
    0,
    imageHeight.toDouble(),
  );
  return Rect.fromLTWH(left, top, right - left, bottom - top);
}

/// 校验热键 combo（与 windows FFI 解析同规则，用于设置表单预校验）。
///
/// 形如 `Ctrl+Shift+A`：修饰键 Ctrl/Control/Alt/Shift/Win/Meta 至少一个
/// 且不重复（大小写与空白容错），主键为字母 A-Z、数字 0-9 或 F1-F12。
bool screenshotIsValidHotkeyCombo(String combo) {
  final List<String> tokens = combo
      .split('+')
      .map((String token) => token.trim().toLowerCase())
      .where((String token) => token.isNotEmpty)
      .toList();
  if (tokens.length < 2) {
    return false;
  }
  var seenMods = 0;
  for (final String token in tokens.sublist(0, tokens.length - 1)) {
    final int bit = switch (token) {
      'ctrl' || 'control' => 1,
      'alt' => 2,
      'shift' => 3,
      'win' || 'meta' => 4,
      _ => 0,
    };
    if (bit == 0 || (seenMods & (1 << bit)) != 0) {
      return false;
    }
    seenMods |= 1 << bit;
  }
  final String key = tokens.last;
  if (key.length == 1) {
    final int code = key.codeUnitAt(0);
    return (code >= 0x61 && code <= 0x7A) || (code >= 0x30 && code <= 0x39);
  }
  return RegExp(r'^f([1-9]|1[0-2])$').hasMatch(key);
}

/// overlay 手势命中半径（逻辑像素）：拖拽起点落在选区手柄/内部时分别
/// 进入调整/移动模式。
const double kRegionHandleHitSlop = 12;

/// 计算拖拽后的选区矩形（纯逻辑，供 overlay 与测试共用）。
///
/// [dragMode] 为 new/move/resize 之一；新建与调整把结果钳制到视口内并
/// 保证最小边长 [kMinRegionLogicalSize]（不足时向下/向上扩展）。
Rect screenshotRegionRectForDrag({
  required String dragMode,
  required Offset start,
  required Offset current,
  required Size viewportSize,
  Rect? previous,
}) {
  final double maxX = viewportSize.width;
  final double maxY = viewportSize.height;
  switch (dragMode) {
    case 'new':
      final Rect raw = Rect.fromPoints(
        Offset(start.dx.clamp(0, maxX), start.dy.clamp(0, maxY)),
        Offset(current.dx.clamp(0, maxX), current.dy.clamp(0, maxY)),
      );
      return _growToMin(raw, maxX, maxY);
    case 'move':
      if (previous == null) {
        return Rect.zero;
      }
      final double dx = (current.dx - start.dx).clamp(
        -previous.left,
        maxX - previous.right,
      );
      final double dy = (current.dy - start.dy).clamp(
        -previous.top,
        maxY - previous.bottom,
      );
      return previous.shift(Offset(dx, dy));
    case 'resize':
      if (previous == null) {
        return Rect.zero;
      }
      var left = previous.left;
      var top = previous.top;
      var right = previous.right;
      var bottom = previous.bottom;
      if ((start.dx - previous.left).abs() <= kRegionHandleHitSlop) {
        left = current.dx.clamp(0, right - kMinRegionLogicalSize);
      } else if ((start.dx - previous.right).abs() <= kRegionHandleHitSlop) {
        right = current.dx.clamp(left + kMinRegionLogicalSize, maxX);
      }
      if ((start.dy - previous.top).abs() <= kRegionHandleHitSlop) {
        top = current.dy.clamp(0, bottom - kMinRegionLogicalSize);
      } else if ((start.dy - previous.bottom).abs() <= kRegionHandleHitSlop) {
        bottom = current.dy.clamp(top + kMinRegionLogicalSize, maxY);
      }
      return Rect.fromLTRB(left, top, right, bottom);
    default:
      return Rect.zero;
  }
}

/// 把宽高不足最小选区的矩形扩展到最小边长（不越出视口）。
Rect _growToMin(Rect raw, double maxX, double maxY) {
  var left = raw.left;
  var top = raw.top;
  var right = raw.right;
  var bottom = raw.bottom;
  if (right - left < kMinRegionLogicalSize) {
    final double center = (left + right) / 2;
    left = (center - kMinRegionLogicalSize / 2).clamp(0, maxX);
    right = (left + kMinRegionLogicalSize).clamp(0, maxX);
    left = right - kMinRegionLogicalSize <= 0
        ? 0
        : right - kMinRegionLogicalSize;
  }
  if (bottom - top < kMinRegionLogicalSize) {
    final double center = (top + bottom) / 2;
    top = (center - kMinRegionLogicalSize / 2).clamp(0, maxY);
    bottom = (top + kMinRegionLogicalSize).clamp(0, maxY);
    top = bottom - kMinRegionLogicalSize <= 0
        ? 0
        : bottom - kMinRegionLogicalSize;
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

/// 判定拖拽模式：选区手柄（边缘命中带）→ resize；选区内部 → move；
/// 其余 → new。
String screenshotRegionDragModeFor(Offset position, Rect? selection) {
  if (selection == null || !selection.contains(position)) {
    return 'new';
  }
  final bool nearHorizontal =
      (position.dx - selection.left).abs() <= kRegionHandleHitSlop ||
      (position.dx - selection.right).abs() <= kRegionHandleHitSlop;
  final bool nearVertical =
      (position.dy - selection.top).abs() <= kRegionHandleHitSlop ||
      (position.dy - selection.bottom).abs() <= kRegionHandleHitSlop;
  if (nearHorizontal || nearVertical) {
    return 'resize';
  }
  return 'move';
}

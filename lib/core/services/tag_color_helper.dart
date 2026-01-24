library;

import 'package:flutter/material.dart';
import '../models/tag_model.dart';

/// 标签颜色辅助类
///
/// 提供统一的标签颜色转换功能
class TagColorHelper {
  TagColorHelper._();

  /// 将 TagColor 转换为 MaterialColor
  static Color getTagColor(TagColor color) {
    switch (color) {
      case TagColor.blue:
        return Colors.blue;
      case TagColor.green:
        return Colors.green;
      case TagColor.orange:
        return Colors.orange;
      case TagColor.purple:
        return Colors.purple;
      case TagColor.red:
        return Colors.red;
      case TagColor.teal:
        return Colors.teal;
      case TagColor.indigo:
        return Colors.indigo;
      case TagColor.pink:
        return Colors.pink;
    }
  }

  /// 获取标签颜色的浅色版本（用于背景）
  static Color getTagColorLight(TagColor color, {double alpha = 0.1}) {
    return getTagColor(color).withValues(alpha: alpha);
  }

  /// 获取标签颜色的半透明版本（用于选中状态）
  static Color getTagColorMedium(TagColor color, {double alpha = 0.2}) {
    return getTagColor(color).withValues(alpha: alpha);
  }

  /// 获取所有可用的标签颜色
  static List<TagColor> get allColors => TagColor.values;

  /// 获取颜色的显示名称
  static String getColorDisplayName(TagColor color) {
    switch (color) {
      case TagColor.blue:
        return '蓝色';
      case TagColor.green:
        return '绿色';
      case TagColor.orange:
        return '橙色';
      case TagColor.purple:
        return '紫色';
      case TagColor.red:
        return '红色';
      case TagColor.teal:
        return '青色';
      case TagColor.indigo:
        return '靛蓝';
      case TagColor.pink:
        return '粉色';
    }
  }
}

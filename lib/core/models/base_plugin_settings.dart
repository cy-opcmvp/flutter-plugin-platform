library;

import 'dart:convert';

/// 插件配置基类
///
/// 所有插件配置类都应该继承这个基类
abstract class BasePluginSettings {
  /// 配置版本号（用于迁移）
  String get version;

  /// 验证配置是否有效
  bool isValid();

  /// 转换为 JSON
  Map<String, dynamic> toJson();

  /// 转换为 JSON 字符串（带缩进）
  String toJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  /// 复制并修改部分配置
  BasePluginSettings copyWith();

  /// 获取配置验证错误信息
  /// 如果配置有效，返回 null
  String? getValidationError() {
    if (isValid()) return null;
    return 'Invalid configuration values';
  }
}

/// 插件配置默认值基类
///
/// 提供配置默认值管理的公共工具方法
/// 所有插件的 ConfigDefaults 类都应该使用这些工具方法
class BasePluginConfigDefaults {
  /// 递归移除帮助字段（静态工具方法）
  static Map<String, dynamic> removeHelpFields(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    for (final entry in json.entries) {
      // 跳过注释和帮助字段
      if (entry.key.startsWith('_') ||
          entry.key == '_comment' ||
          entry.key == '_description' ||
          entry.key.endsWith('_help') ||
          entry.key.endsWith('_default') ||
          entry.key.endsWith('_range') ||
          entry.key.endsWith('_note') ||
          entry.key.endsWith('_examples')) {
        continue;
      }
      // 递归处理嵌套对象
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = removeHelpFields(
          entry.value as Map<String, dynamic>,
        );
      } else if (entry.value is List) {
        // 跳过示例列表
        continue;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}

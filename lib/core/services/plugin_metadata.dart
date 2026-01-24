library;

import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import '../models/plugin_models.dart';

/// 插件元数据服务
///
/// 提供插件相关的元数据和国际化支持
class PluginMetadata {
  PluginMetadata._();

  /// 单例实例
  static final PluginMetadata instance = PluginMetadata._();

  /// 获取插件名称（国际化）
  String getPluginName(String pluginId, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (pluginId) {
      case 'com.example.calculator':
        return l10n.plugin_calculator_name;
      case 'com.example.worldclock':
        return l10n.plugin_worldclock_name;
      case 'com.example.screenshot':
        return l10n.plugin_screenshot_name;
      default:
        // 如果没有对应的翻译，返回插件ID或描述符中的名称
        return _getDescriptorName(pluginId);
    }
  }

  /// 获取插件描述（国际化）
  String getPluginDescription(String pluginId, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (pluginId) {
      case 'com.example.calculator':
        return l10n.plugin_calculator_description;
      case 'com.example.worldclock':
        return l10n.plugin_worldclock_description;
      case 'com.example.screenshot':
        return l10n.plugin_screenshot_description;
      default:
        // 如果没有对应的翻译，返回描述符中的描述
        return _getDescriptorDescription(pluginId);
    }
  }

  /// 获取插件图标
  IconData getPluginIcon(String pluginId) {
    switch (pluginId) {
      case 'com.example.calculator':
        return Icons.calculate;
      case 'com.example.worldclock':
        return Icons.schedule;
      case 'com.example.screenshot':
        return Icons.screenshot;
      default:
        return Icons.extension;
    }
  }

  /// 从描述符获取名称（备用方案）
  String _getDescriptorName(String pluginId) {
    // 这里应该从注册表获取，避免循环依赖
    // 暂时返回插件ID作为后备
    return pluginId;
  }

  /// 从描述符获取描述（备用方案）
  String _getDescriptorDescription(String pluginId) {
    // 暂时返回空字符串
    return '';
  }

  /// 获取所有支持的插件ID列表
  static const List<String> supportedPluginIds = [
    'com.example.calculator',
    'com.example.worldclock',
    'com.example.screenshot',
  ];

  /// 检查插件ID是否有效
  static bool isValidPluginId(String pluginId) {
    return supportedPluginIds.contains(pluginId);
  }
}

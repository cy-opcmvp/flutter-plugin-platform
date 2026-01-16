library;

import 'package:flutter/foundation.dart';
import '../models/global_config.dart';
import 'config_service.dart';

/// 配置管理器
///
/// 统一管理全局配置和插件配置的加载、保存和访问
/// 提供类型安全的配置访问接口
class ConfigManager {
  static ConfigManager? _instance;

  /// 获取单例实例
  static ConfigManager get instance {
    _instance ??= ConfigManager._internal();
    return _instance!;
  }

  ConfigManager._internal();

  final ConfigService _service = ConfigService.instance;
  GlobalConfig? _globalConfig;
  final Map<String, Map<String, dynamic>> _pluginConfigs = {};

  bool _isInitialized = false;

  /// 初始化配置管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _service.initialize();
      await loadGlobalConfig();

      _isInitialized = true;
      debugPrint('ConfigManager initialized');
    } catch (e) {
      debugPrint('Failed to initialize ConfigManager: $e');
      rethrow;
    }
  }

  /// 加载全局配置
  Future<void> loadGlobalConfig() async {
    final configData = await _service.loadGlobalConfig();
    _globalConfig = GlobalConfig.fromJson(configData);
    debugPrint('Global config loaded');
  }

  /// 保存全局配置
  Future<void> saveGlobalConfig() async {
    if (_globalConfig == null) {
      throw StateError('Global config not loaded');
    }

    await _service.saveGlobalConfig(_globalConfig!.toJson());
    debugPrint('Global config saved');
  }

  /// 更新全局配置
  Future<void> updateGlobalConfig(GlobalConfig newConfig) async {
    _globalConfig = newConfig;
    await saveGlobalConfig();
  }

  /// 加载插件配置
  Future<Map<String, dynamic>> loadPluginConfig(String pluginId) async {
    if (!_pluginConfigs.containsKey(pluginId)) {
      final config = await _service.loadPluginConfig(pluginId);
      _pluginConfigs[pluginId] = config;
    }
    return Map<String, dynamic>.from(_pluginConfigs[pluginId]!);
  }

  /// 保存插件配置
  Future<void> savePluginConfig(String pluginId, Map<String, dynamic> config) async {
    _pluginConfigs[pluginId] = config;
    await _service.savePluginConfig(pluginId, config);
    debugPrint('Plugin config saved for $pluginId');
  }

  /// 更新插件配置中的某个键值
  Future<void> updatePluginConfigKey(
    String pluginId,
    String key,
    dynamic value,
  ) async {
    final config = await loadPluginConfig(pluginId);
    config[key] = value;
    await savePluginConfig(pluginId, config);
  }

  /// 删除插件配置
  Future<void> deletePluginConfig(String pluginId) async {
    _pluginConfigs.remove(pluginId);
    await _service.deletePluginConfig(pluginId);
    debugPrint('Plugin config deleted for $pluginId');
  }

  /// 获取全局配置
  GlobalConfig get globalConfig {
    if (_globalConfig == null) {
      throw StateError('Global config not loaded. Call initialize() first.');
    }
    return _globalConfig!;
  }

  /// 导出所有配置到字符串
  Future<String> exportAllConfig() async {
    return await _service.exportConfigToString();
  }

  /// 从字符串导入所有配置
  Future<void> importAllConfig(String configString) async {
    await _service.importConfigFromString(configString);
    await loadGlobalConfig();
    _pluginConfigs.clear();
  }

  /// 重置为默认配置
  Future<void> resetToDefaults() async {
    _globalConfig = GlobalConfig.defaultConfig;
    await saveGlobalConfig();

    // 清空所有插件配置
    for (final pluginId in _pluginConfigs.keys.toList()) {
      await deletePluginConfig(pluginId);
    }

    debugPrint('Config reset to defaults');
  }

  /// 检查是否已初始化
  bool get isInitialized => _isInitialized;
}

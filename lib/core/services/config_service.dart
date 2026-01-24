library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// 配置文件服务
///
/// 负责管理应用和插件的 JSON 配置文件
/// 支持全局配置和插件配置的读写
class ConfigService {
  static ConfigService? _instance;

  /// 获取单例实例
  static ConfigService get instance {
    _instance ??= ConfigService._internal();
    return _instance!;
  }

  ConfigService._internal();

  late Directory _configDir;
  bool _isInitialized = false;

  /// 初始化配置服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 获取应用配置目录
      if (kIsWeb) {
        // Web 平台使用内存存储
        _configDir = Directory('/');
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        _configDir = Directory('${appDocDir.path}/config');

        // 确保配置目录存在
        if (!await _configDir.exists()) {
          await _configDir.create(recursive: true);
        }

        // 检查并复制 example 配置文件
        await _ensureExampleConfigExists();
      }

      _isInitialized = true;
      debugPrint('ConfigService initialized: ${_configDir.path}');
    } catch (e) {
      debugPrint('Failed to initialize ConfigService: $e');
      rethrow;
    }
  }

  /// 确保 example 配置文件存在于配置目录
  Future<void> _ensureExampleConfigExists() async {
    final exampleFile = File('${_configDir.path}/global_config.example.json');

    // 如果 example 文件已存在，跳过
    if (await exampleFile.exists()) {
      debugPrint('Example config file already exists');
      return;
    }

    try {
      // 从 assets 加载 example 配置
      final exampleConfigString = await rootBundle.loadString('assets/config/global_config.example.json');
      await exampleFile.writeAsString(exampleConfigString);
      debugPrint('Example config file created from assets');
    } catch (e) {
      debugPrint('Failed to create example config file: $e');
      // 不抛出异常，允许应用继续运行
    }
  }

  /// 读取全局配置文件
  Future<Map<String, dynamic>> loadGlobalConfig() async {
    final file = File('${_configDir.path}/global_config.json');

    if (!await file.exists()) {
      // 配置文件不存在，尝试从 example 文件复制
      final exampleFile = File('${_configDir.path}/global_config.example.json');

      if (await exampleFile.exists()) {
        // 从 example 文件复制
        await file.writeAsString(await exampleFile.readAsString());
        debugPrint('Global config created from example file');

        // 读取并返回
        final jsonString = await file.readAsString();
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return json;
      } else {
        // example 文件也不存在，返回默认配置
        debugPrint('No config file found, using default config');
        return _getDefaultGlobalConfig();
      }
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('Failed to load global config: $e');
      return _getDefaultGlobalConfig();
    }
  }

  /// 保存全局配置文件
  Future<void> saveGlobalConfig(Map<String, dynamic> config) async {
    final file = File('${_configDir.path}/global_config.json');

    try {
      final jsonString = JsonEncoder.withIndent('  ').convert(config);
      await file.writeAsString(jsonString);
      debugPrint('Global config saved');
    } catch (e) {
      debugPrint('Failed to save global config: $e');
      rethrow;
    }
  }

  /// 读取插件配置文件
  Future<Map<String, dynamic>> loadPluginConfig(String pluginId) async {
    final file = File('${_configDir.path}/plugin_$pluginId.json');

    if (!await file.exists()) {
      // 返回空配置
      return {};
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('Failed to load plugin config for $pluginId: $e');
      return {};
    }
  }

  /// 保存插件配置文件
  Future<void> savePluginConfig(
    String pluginId,
    Map<String, dynamic> config,
  ) async {
    final file = File('${_configDir.path}/plugin_$pluginId.json');

    try {
      final jsonString = JsonEncoder.withIndent('  ').convert(config);
      await file.writeAsString(jsonString);
      debugPrint('Plugin config saved for $pluginId');
    } catch (e) {
      debugPrint('Failed to save plugin config for $pluginId: $e');
      rethrow;
    }
  }

  /// 获取所有插件配置
  Future<Map<String, Map<String, dynamic>>> loadAllPluginConfigs() async {
    final result = <String, Map<String, dynamic>>{};

    try {
      final entities = await _configDir.list().toList();
      for (final entity in entities) {
        if (entity is File &&
            entity.path.contains('plugin_') &&
            entity.path.endsWith('.json')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final pluginId = fileName
              .replaceAll('plugin_', '')
              .replaceAll('.json', '');

          final config = await loadPluginConfig(pluginId);
          result[pluginId] = config;
        }
      }
    } catch (e) {
      debugPrint('Failed to load all plugin configs: $e');
    }

    return result;
  }

  /// 删除插件配置文件
  Future<void> deletePluginConfig(String pluginId) async {
    final file = File('${_configDir.path}/plugin_$pluginId.json');

    if (await file.exists()) {
      await file.delete();
      debugPrint('Plugin config deleted for $pluginId');
    }
  }

  /// 导出配置到字符串
  Future<String> exportConfigToString() async {
    final globalConfig = await loadGlobalConfig();
    final pluginConfigs = await loadAllPluginConfigs();

    final exportData = {
      'global': globalConfig,
      'plugins': pluginConfigs,
      'exportTime': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };

    return JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// 从字符串导入配置
  Future<void> importConfigFromString(String configString) async {
    try {
      final data = jsonDecode(configString) as Map<String, dynamic>;

      // 导入全局配置
      if (data.containsKey('global')) {
        final globalConfig = data['global'] as Map<String, dynamic>;
        await saveGlobalConfig(globalConfig);
      }

      // 导入插件配置
      if (data.containsKey('plugins')) {
        final pluginConfigs = data['plugins'] as Map<String, dynamic>;
        for (final entry in pluginConfigs.entries) {
          await savePluginConfig(
            entry.key,
            entry.value as Map<String, dynamic>,
          );
        }
      }

      debugPrint('Config imported successfully');
    } catch (e) {
      debugPrint('Failed to import config: $e');
      rethrow;
    }
  }

  /// 获取默认全局配置
  Map<String, dynamic> _getDefaultGlobalConfig() {
    return {
      'app': {
        'name': 'Flutter Plugin Platform',
        'version': '0.3.4',
        'language': 'zh_CN',
        'theme': 'system',
      },
      'features': {
        'autoStart': false,
        'minimizeToTray': true,
        'showDesktopPet': true,
        'enableNotifications': true,
      },
      'services': {
        'audio': {'enabled': true},
        'notification': {'enabled': true},
        'taskScheduler': {'enabled': true},
      },
      'advanced': {
        'debugMode': false,
        'logLevel': 'info',
        'maxLogFileSize': 10, // MB
      },
    };
  }

  /// 读取自定义配置文件
  Future<Map<String, dynamic>?> loadCustomConfig(String configName) async {
    final file = File('${_configDir.path}/${configName}_config.json');

    if (!await file.exists()) {
      return null;
    }

    try {
      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return json;
    } catch (e) {
      debugPrint('Failed to load custom config $configName: $e');
      return null;
    }
  }

  /// 保存自定义配置文件
  Future<void> saveCustomConfig(
    String configName,
    Map<String, dynamic> config,
  ) async {
    final file = File('${_configDir.path}/${configName}_config.json');

    try {
      final jsonString = JsonEncoder.withIndent('  ').convert(config);
      await file.writeAsString(jsonString);
      debugPrint('Custom config saved: $configName');
    } catch (e) {
      debugPrint('Failed to save custom config $configName: $e');
      rethrow;
    }
  }

  /// 删除自定义配置文件
  Future<void> deleteCustomConfig(String configName) async {
    final file = File('${_configDir.path}/${configName}_config.json');

    if (await file.exists()) {
      await file.delete();
      debugPrint('Custom config deleted: $configName');
    }
  }

  /// 检查服务是否已初始化
  bool get isInitialized => _isInitialized;
}

library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/i_plugin.dart';

/// 插件数据存储实现
///
/// 基于 SharedPreferences 实现持久化存储
/// 所有数据会在应用重启后保持
class PluginDataStorage implements IDataStorage {
  final String pluginId;
  SharedPreferences? _prefs;

  PluginDataStorage(this.pluginId);

  /// 初始化存储
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 生成完整的存储键（包含插件 ID 前缀）
  String _getFullKey(String key) {
    return 'plugin_${pluginId}_$key';
  }

  @override
  Future<void> store(String key, dynamic value) async {
    await initialize();

    try {
      final fullKey = _getFullKey(key);

      if (value == null) {
        await _prefs!.remove(fullKey);
      } else if (value is String) {
        await _prefs!.setString(fullKey, value);
      } else if (value is int) {
        await _prefs!.setInt(fullKey, value);
      } else if (value is double) {
        await _prefs!.setDouble(fullKey, value);
      } else if (value is bool) {
        await _prefs!.setBool(fullKey, value);
      } else if (value is List<String>) {
        await _prefs!.setStringList(fullKey, value);
      } else if (value is List) {
        // 其他 List 类型（如 List<Map>）转为 JSON 字符串存储
        final jsonString = jsonEncode(value);
        await _prefs!.setString(fullKey, jsonString);
      } else if (value is Map) {
        // Map 类型转为 JSON 字符串存储
        final jsonString = jsonEncode(value);
        await _prefs!.setString(fullKey, jsonString);
      } else {
        // 其他类型尝试转为字符串存储
        final jsonString = value.toString();
        await _prefs!.setString(fullKey, jsonString);
      }

      debugPrint('PluginDataStorage: Stored $key for plugin $pluginId');
    } catch (e) {
      debugPrint(
        'PluginDataStorage: Failed to store $key for plugin $pluginId: $e',
      );
      rethrow;
    }
  }

  @override
  Future<T?> retrieve<T>(String key) async {
    await initialize();

    try {
      final fullKey = _getFullKey(key);

      if (!_prefs!.containsKey(fullKey)) {
        return null;
      }

      final value = _prefs!.get(fullKey);

      // 如果值是字符串，尝试解析为复杂类型
      if (value is String) {
        // 检查是否需要解析为 Map<String, dynamic>
        if (T.toString() == 'Map<String, dynamic>') {
          try {
            final decoded = jsonDecode(value) as Map<String, dynamic>;
            return decoded as T;
          } catch (e) {
            debugPrint('PluginDataStorage: Failed to parse JSON for $key: $e');
            return null;
          }
        }

        // 检查是否需要解析为 List<dynamic> 或 List<Map>
        if (T.toString() == 'List<dynamic>' ||
            T.toString() == 'List<Map<String, dynamic>>') {
          try {
            final decoded = jsonDecode(value) as List<dynamic>;
            return decoded as T;
          } catch (e) {
            debugPrint(
              'PluginDataStorage: Failed to parse JSON list for $key: $e',
            );
            return null;
          }
        }
      }

      // 直接返回，让 Dart 进行类型转换
      // 如果类型不匹配，调用方会得到类型错误
      return value as T?;
    } catch (e) {
      debugPrint(
        'PluginDataStorage: Failed to retrieve $key for plugin $pluginId: $e',
      );
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    await initialize();
    final fullKey = _getFullKey(key);
    await _prefs!.remove(fullKey);
    debugPrint('PluginDataStorage: Removed $key for plugin $pluginId');
  }

  @override
  Future<void> clear() async {
    await initialize();
    final keys = _prefs!.getKeys().where(
      (key) => key.startsWith('plugin_${pluginId}_'),
    );
    for (final key in keys) {
      await _prefs!.remove(key);
    }
    debugPrint('PluginDataStorage: Cleared all data for plugin $pluginId');
  }

  /// 获取插件的所有存储键
  Future<Set<String>> getKeys() async {
    await initialize();
    final prefix = 'plugin_${pluginId}_';
    return _prefs!
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .toSet();
  }
}

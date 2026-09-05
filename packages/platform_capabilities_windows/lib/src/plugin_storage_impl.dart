/// 插件数据存储的 Windows（`dart:io`）真实现：每插件单 JSON 文件 KV。
///
/// 布局：`<rootDir>/<pluginId>/kv.json`，文件内容为扁平 JSON 对象（键 →
/// 值字符串）。写入采用「临时文件 + rename」原子替换，避免半写文件；
/// [PluginId] 已验证为反向域格式（无路径分隔符），目录拼接无穿越空间。
/// I/O 失败一律抛 `storage.io_error` 结构化失败（reason: read|write|delete）。
library;

import 'dart:convert';
import 'dart:io';

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

/// 基于每插件 JSON 文件的 [PluginStorage] 实现（构造注入存储根目录）。
final class JsonPluginStorage implements PluginStorage {
  /// 创建存储实现；[rootDir] 为存储根目录（懒创建，构造不触发 I/O）。
  JsonPluginStorage({required String rootDir}) : _rootDir = rootDir;

  final String _rootDir;

  /// 单插件 KV 文件名。
  static const String _kvFileName = 'kv.json';

  Directory _pluginDir(PluginId plugin) {
    return Directory('$_rootDir/${plugin.value}');
  }

  File _kvFileOf(PluginId plugin) {
    return File('${_pluginDir(plugin).path}/$_kvFileName');
  }

  /// 整表读取：文件缺失返回空表；损坏或读取失败抛 read 失败。
  Future<Map<String, String>> _readTable(PluginId plugin) async {
    final File file = _kvFileOf(plugin);
    if (!await file.exists()) {
      return <String, String>{};
    }
    final String raw;
    try {
      raw = await file.readAsString();
    } on FileSystemException catch (error) {
      throw storageIoFailure(
        'read',
        '读取 KV 文件失败: ${error.message}',
        <String, Object?>{'path': file.path},
      );
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<Object?, Object?>) {
        throw const FormatException('KV 文件顶层必须是 JSON 对象');
      }
      return <String, String>{
        for (final MapEntry<Object?, Object?> entry in decoded.entries)
          if (entry.value is String) '${entry.key}': entry.value! as String,
      };
    } on FormatException catch (error) {
      throw storageIoFailure(
        'read',
        'KV 文件损坏: ${error.message}',
        <String, Object?>{'path': file.path},
      );
    }
  }

  /// 整表原子写：临时文件 + rename 替换；失败抛 write 失败。
  Future<void> _writeTable(PluginId plugin, Map<String, String> table) async {
    final Directory dir = _pluginDir(plugin);
    final File file = _kvFileOf(plugin);
    final File tempFile = File('${file.path}.tmp');
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      await tempFile.writeAsString(encoder.convert(table), flush: true);
      await tempFile.rename(file.path);
    } on FileSystemException catch (error) {
      throw storageIoFailure(
        'write',
        '写入 KV 文件失败: ${error.message}',
        <String, Object?>{'path': file.path},
      );
    }
  }

  @override
  Future<String?> read(PluginId plugin, String key) async {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', '不能为空');
    }
    final Map<String, String> table = await _readTable(plugin);
    return table[key];
  }

  @override
  Future<void> write(PluginId plugin, String key, String value) async {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', '不能为空');
    }
    final Map<String, String> table = await _readTable(plugin);
    table[key] = value;
    await _writeTable(plugin, table);
  }

  @override
  Future<void> delete(PluginId plugin, String key) async {
    if (key.isEmpty) {
      throw ArgumentError.value(key, 'key', '不能为空');
    }
    final Map<String, String> table = await _readTable(plugin);
    if (!table.containsKey(key)) {
      return;
    }
    table.remove(key);
    await _writeTable(plugin, table);
  }
}

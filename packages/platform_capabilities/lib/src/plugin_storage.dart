/// 插件数据存储契约：插件作用域 KV 最小版（设计 §2.6，S2 前置）。
///
/// 每插件命名空间隔离（[PluginStorage.read] 等方法按 [PluginId] 分域），
/// 值为 UTF-8 字符串（结构化数据由调用方自行 JSON 编解码）。文件区
/// （`list/read/write/delete` 二进制文件）留给 S2 扩展，本契约只覆盖 KV。
///
/// 实现方约定：
/// - I/O 失败抛 `storage.io_error` 结构化失败，`details['reason']` 为
///   `read` / `write` / `delete`；
/// - 键不存在时 [PluginStorage.read] 返回 null，不视为失败；
/// - 接口与实现值类型保持零平台依赖（本文件不 import `dart:io`）。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

/// 构造 `storage.io_error` 结构化失败值。
///
/// [reason] 为失败阶段（`read` / `write` / `delete`）；[message] 为实现方
/// 的可读描述；[details] 允许补充实现方上下文（如路径）。
PluginFailure storageIoFailure(
  String reason,
  String message, [
  Map<String, Object?> details = const <String, Object?>{},
]) {
  return PluginFailure('storage.io_error', message, <String, Object?>{
    'reason': reason,
    ...details,
  });
}

/// 插件作用域 KV 存储契约。
abstract interface class PluginStorage {
  /// 读取 [plugin] 命名空间下 [key] 的值；无值返回 null。
  Future<String?> read(PluginId plugin, String key);

  /// 写入（覆盖）[plugin] 命名空间下 [key] 的值。
  Future<void> write(PluginId plugin, String key, String value);

  /// 删除 [plugin] 命名空间下 [key]；键不存在时为无操作。
  Future<void> delete(PluginId plugin, String key);
}

/// 内存默认实现：测试与降级用，进程结束即丢失。
final class InMemoryPluginStorage implements PluginStorage {
  final Map<String, Map<String, String>> _buckets =
      <String, Map<String, String>>{};

  Map<String, String> _bucketOf(PluginId plugin) {
    return _buckets.putIfAbsent(plugin.value, () => <String, String>{});
  }

  @override
  Future<String?> read(PluginId plugin, String key) async {
    return _bucketOf(plugin)[key];
  }

  @override
  Future<void> write(PluginId plugin, String key, String value) async {
    _bucketOf(plugin)[key] = value;
  }

  @override
  Future<void> delete(PluginId plugin, String key) async {
    _bucketOf(plugin).remove(key);
  }
}

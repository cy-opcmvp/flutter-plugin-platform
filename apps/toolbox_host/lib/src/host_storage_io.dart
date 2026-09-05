/// 宿主插件存储工厂（`dart:io` 实现版）。
///
/// io 目标接入 JsonPluginStorage（platform_capabilities_windows）：每插件
/// 单 JSON 文件 KV，布局 `<dataRoot>/plugin-data/<pluginId>/kv.json`，
/// 临时文件 + rename 原子写；I/O 失败抛 `storage.io_error` 结构化失败。
library;

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';

/// 按宿主数据根构建 JSON 文件版插件存储。
PluginStorage createHostPluginStorage(String dataRoot) {
  return JsonPluginStorage(rootDir: '$dataRoot/plugin-data');
}

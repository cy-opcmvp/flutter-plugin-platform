/// 宿主插件存储工厂的条件导出入口。
///
/// 镜像 `host_bytes_loader` 的条件导出模式：io 目标接入 JsonPluginStorage
/// （每插件单 JSON 文件，落宿主数据根下的 `plugin-data` 目录）；web 等
/// 无 io 目标接入内存实现（不持久化，仅会话内 KV），保证宿主源码不直接
/// 引用 dart:io 即可完成双端编译。
///
/// 两分支均提供同签名工厂 `createHostPluginStorage(dataRoot)`，KV 文件
/// 布局为 `<dataRoot>/plugin-data/<pluginId>/kv.json`（每插件单目录）。
library;

export 'host_storage_none.dart' if (dart.library.io) 'host_storage_io.dart';

/// 宿主数据根解析的 `dart:io` 实现版。
///
/// F4-07：将 path_provider 从组装根抽出并隔离到本文件——宿主中唯一的
/// 平台专属插件引用点，经 [resolveApplicationSupportRoot] 提供应用支持
/// 目录作为 sidecar 安装根与插件数据根。
library;

import 'package:path_provider/path_provider.dart';

/// 默认数据根解析：应用支持目录（path_provider）。
Future<String> resolveApplicationSupportRoot() async {
  return (await getApplicationSupportDirectory()).path;
}

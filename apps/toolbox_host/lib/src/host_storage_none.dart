/// 宿主插件存储工厂（无 `dart:io` 平台的实现版）。
///
/// web 等无文件系统目标接入 [InMemoryPluginStorage]：**不持久化**，仅
/// 提供会话内 KV（进程结束即丢失）。正常流程下 `HostCompositionRoot`
/// 在 kIsWeb 分支同样使用占位数据根，插件设置只在当前会话生效。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// 构建内存版插件存储（[dataRoot] 不参与布局，仅为签名一致保留）。
PluginStorage createHostPluginStorage(String dataRoot) {
  return InMemoryPluginStorage();
}

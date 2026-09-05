/// 宿主剪贴板/已知目录工厂（无 `dart:io` 平台的实现版）。
///
/// web 等目标接入接口包默认实现：剪贴板写入抛 `capability.unsupported`，
/// 已知目录恒返回 null（调用方回退插件数据目录）。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// 构建不支持平台的剪贴板能力。
Clipboard createHostClipboard() => const UnsupportedClipboard('web');

/// 构建不支持平台的已知目录能力。
KnownFolders createHostKnownFolders() => const UnsupportedKnownFolders('web');

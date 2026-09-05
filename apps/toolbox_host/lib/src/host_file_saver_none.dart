/// 宿主截图写文件缝（无 dart:io 平台的空实现，恒返回空串）。
///
/// 经条件导出在 web 等无 io 库的编译目标下替代 io 版本；截图插件清单
/// 仅声明 windows 目标，该分支实际不会被调用。
library;

import 'dart:typed_data';

/// 恒返回空串（无文件系统能力）。
Future<String> saveHostScreenshotFile({
  required String rootDir,
  required Uint8List bytes,
  required String filename,
}) async => '';

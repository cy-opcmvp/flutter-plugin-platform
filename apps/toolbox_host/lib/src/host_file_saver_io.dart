/// 宿主截图写文件缝（dart:io 实现版）。
///
/// F4-05：宿主是唯一允许触碰文件系统的 app 层；截图插件的写文件缝经
/// 此实现落盘到宿主数据根下的插件数据目录（`tools.screenshot/`）。
library;

import 'dart:io';
import 'dart:typed_data';

/// 把截图字节写入 [rootDir]/[filename] 并返回完整路径。
///
/// 目录不存在时递归创建；返回宿主平台原生路径分隔符的完整路径。
Future<String> saveHostScreenshotFile({
  required String rootDir,
  required Uint8List bytes,
  required String filename,
}) async {
  final Directory dir = Directory(rootDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final File file = File('$rootDir/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

/// 宿主截图写文件缝（dart:io 实现版）。
///
/// 宿主是唯一允许触碰文件系统的 app 层；截图插件的写文件缝经此实现
/// 落盘——目标目录由控制器按设置解析（系统图片/文档目录或插件数据
/// 目录），本函数只负责建目录与写文件。
library;

import 'dart:io';
import 'dart:typed_data';

/// 把截图字节写入 [dir]/[filename] 并返回完整路径。
///
/// 目录不存在时递归创建；[dir] 为空串时按相对路径落盘（调用方已尽力
/// 解析目录，此为兜底分支）。
Future<String> saveHostScreenshotFile({
  required String dir,
  required Uint8List bytes,
  required String filename,
}) async {
  if (dir.isNotEmpty) {
    final Directory target = Directory(dir);
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
  }
  final File file = File(dir.isEmpty ? filename : '$dir/$filename');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

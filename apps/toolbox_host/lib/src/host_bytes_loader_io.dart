/// 宿主图片字节加载器（dart:io 实现版）。
///
/// F4-02：宿主是唯一允许触碰文件系统的 app 层；真实数据根来自
/// path_provider，[loadHostImageBytes] 按结果渲染器的 bytesLoader 契约
/// （`Future<Uint8List?> Function(String path)`）读取本地图片。
library;

import 'dart:io';
import 'dart:typed_data';

/// 按路径读取图片字节；文件缺失或读取失败时返回 null（UI 回退占位框）。
Future<Uint8List?> loadHostImageBytes(String path) async {
  final File file = File(path);
  if (!await file.exists()) {
    return null;
  }
  try {
    return await file.readAsBytes();
  } on FileSystemException {
    return null;
  }
}

/// 宿主图片字节加载器（无 dart:io 平台的空实现，恒返回 null）。
///
/// 经条件导出在 web 等无 io 库的编译目标下替代 io 版本；结果渲染器据此
/// 统一回退占位框，不产生真实解码。
library;

import 'dart:typed_data';

/// 恒返回 null（无文件系统能力，UI 回退占位框）。
Future<Uint8List?> loadHostImageBytes(String path) async => null;

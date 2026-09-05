/// 宿主剪贴板/已知目录工厂的条件导出入口。
///
/// 镜像 `host_storage` 的条件导出模式：io 目标接入 Windows FFI 实现
/// （CF_UNICODETEXT / CF_DIBV5 / CF_HDROP 写入 + SHGetKnownFolderPath）；
/// web 等无 io 目标接入默认不支持实现（写入抛 `capability.unsupported`、
/// 目录解析返回 null），保证宿主源码不直接引用 dart:ffi/dart:io 即可
/// 完成双端编译。
///
/// 两分支均提供同签名工厂：`createHostClipboard()` 与
/// `createHostKnownFolders()`。
library;

export 'host_clipboard_none.dart' if (dart.library.io) 'host_clipboard_io.dart';

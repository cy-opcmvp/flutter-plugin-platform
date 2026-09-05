/// 宿主全局热键工厂的条件导出入口。
///
/// 镜像 `host_clipboard` 的条件导出模式：io 目标接入 Windows
/// `RegisterHotKey` + `PeekMessage` 轮询实现（S1 批C）；web 等无 io
/// 目标接入默认不支持实现（注册恒 false、事件流为空流），保证宿主
/// 源码不直接引用 dart:ffi/dart:io 即可完成双端编译。
///
/// 两分支均提供同签名工厂：`createHostGlobalHotkeys()`。
library;

export 'host_hotkeys_none.dart' if (dart.library.io) 'host_hotkeys_io.dart';

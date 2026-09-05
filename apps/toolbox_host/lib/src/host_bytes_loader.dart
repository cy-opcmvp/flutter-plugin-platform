/// 宿主图片字节加载器的条件导出入口。
///
/// 有 `dart:io` 的编译目标使用 io 实现；web 等目标使用恒返回 null 的空
/// 实现，保证宿主源码不直接引用 dart:io 即可完成双端编译（F4-02）。
library;

export 'host_bytes_loader_none.dart'
    if (dart.library.io) 'host_bytes_loader_io.dart';

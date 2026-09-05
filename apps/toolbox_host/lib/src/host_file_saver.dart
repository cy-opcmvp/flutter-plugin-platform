/// 宿主截图写文件缝的条件导出入口。
///
/// 有 `dart:io` 的编译目标使用 io 实现落盘；web 等目标使用恒返回空串的
/// 空实现，保证宿主源码不直接引用 dart:io 即可完成双端编译（镜像
/// `host_bytes_loader` 的 F4-02 模式）。
library;

export 'host_file_saver_none.dart'
    if (dart.library.io) 'host_file_saver_io.dart';

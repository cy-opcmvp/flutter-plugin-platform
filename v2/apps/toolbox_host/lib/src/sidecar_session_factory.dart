/// Sidecar 会话工厂的条件导出入口。
///
/// 有 `dart:io` 的编译目标使用真实工厂（Python 解释器探测 + 进程启动）；
/// web 等目标使用恒不支持的空实现（F4-02 条件导出模式）。
library;

export 'sidecar_session_factory_none.dart'
    if (dart.library.io) 'sidecar_session_factory_io.dart';

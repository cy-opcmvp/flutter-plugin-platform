/// 宿主屏幕捕获能力接线条件导出入口。
///
/// 镜像 `host_bytes_loader` / `host_data_root` 的条件导出模式
/// （F4-07 集中验证修复）：`platform_capabilities_windows` 的 GDI 实现
/// 含 `dart:ffi`，宿主源码不得直接 import 该包，否则 web 编译图混入
/// ffi 导致 `flutter build web` 失败。经本入口，web 目标取 stub，其余
/// 目标取 io 分支的 Windows 真实现。
library;

export 'host_screen_capture_io.dart'
    if (dart.library.js_interop) 'host_screen_capture_stub.dart';

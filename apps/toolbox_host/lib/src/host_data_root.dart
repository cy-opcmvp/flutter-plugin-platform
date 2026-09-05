/// 宿主数据根解析的条件导出入口。
///
/// 镜像 `host_bytes_loader` 的 F4-02 模式：`path_provider` 只允许出现在
/// io 分支实现文件中，宿主其余源码不直接引用平台专属插件，保证六端
/// 编译图静态检查（build-matrix compile-graph）与 web 双端编译通过
/// （F4-07 集中验证修复）。
library;

export 'host_data_root_none.dart' if (dart.library.io) 'host_data_root_io.dart';

/// web 目标（无文件系统）下使用的宿主数据根占位常量（F4-02 决策 6）。
const String kWebHostDataRoot = 'app-support://toolbox-host-web';

/// 宿主窗口选择态切换工厂的条件导出入口。
///
/// 镜像 `host_hotkeys` 的条件导出模式：io 目标（桌面）接入
/// window_manager 实现（保存状态 → 全屏 + 置顶 + 跳过任务栏 → 恢复，
/// S1 批C）；web 等无 io 目标接入零操作实现，保证宿主源码不直接
/// 引用 window_manager 即可完成双端编译。
///
/// 两分支均提供同签名工厂：`createHostWindowOps()`。
library;

export 'host_window_none.dart' if (dart.library.io) 'host_window_io.dart';

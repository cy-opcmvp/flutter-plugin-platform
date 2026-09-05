/// 宿主窗口选择态切换（无 `dart:io` 平台的实现版）。
///
/// web 等目标接入零操作实现：不触碰窗口状态，overlay 流程仍可走通
/// （路由内铺满视口，仅无真实全屏形态切换）。
library;

/// 宿主窗口状态切换缝（区域选择 overlay 进出）。
abstract interface class HostWindowOps {
  /// 进入选择态（无操作）。
  Future<void> enterSelection();

  /// 退出选择态（无操作）。
  Future<void> exitSelection();
}

/// 零操作实现：所有切换直接完成。
final class NoopHostWindowOps implements HostWindowOps {
  /// 创建零操作实现。
  const NoopHostWindowOps();

  @override
  Future<void> enterSelection() async {}

  @override
  Future<void> exitSelection() async {}
}

/// 构建无 io 平台的窗口操作。
HostWindowOps createHostWindowOps() => const NoopHostWindowOps();

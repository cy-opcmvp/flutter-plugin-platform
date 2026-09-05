/// 宿主窗口选择态切换（`dart:io` 实现版）。
///
/// 经 window_manager 实现区域选择 overlay 的窗口形态切换：进入时保存
/// 当前状态并切换为全屏 + 置顶 + 跳过任务栏；退出时恢复进入前状态。
/// 仅由桌面宿主组装根使用；web 分支经条件导出切换为零操作实现，
/// 保证宿主源码不直接引用 window_manager 即可完成双端编译。
library;

import 'dart:ui' show Rect;

import 'package:window_manager/window_manager.dart';

/// 宿主窗口状态切换缝（区域选择 overlay 进出）。
abstract interface class HostWindowOps {
  /// 进入选择态：保存当前状态并切换为全屏 + 置顶 + 跳过任务栏。
  Future<void> enterSelection();

  /// 退出选择态：恢复进入前保存的状态（幂等安全）。
  Future<void> exitSelection();
}

/// window_manager 实现（进入/退出严格配对，退出恢复进入前快照）。
final class WindowsHostWindowOps implements HostWindowOps {
  bool _wasFullScreen = false;

  bool _wasAlwaysOnTop = false;

  Rect? _savedBounds;

  @override
  Future<void> enterSelection() async {
    _wasFullScreen = await windowManager.isFullScreen();
    _wasAlwaysOnTop = await windowManager.isAlwaysOnTop();
    if (!_wasFullScreen) {
      _savedBounds = await windowManager.getBounds();
    }
    await windowManager.setSkipTaskbar(true);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setFullScreen(true);
  }

  @override
  Future<void> exitSelection() async {
    await windowManager.setFullScreen(_wasFullScreen);
    await windowManager.setSkipTaskbar(false);
    await windowManager.setAlwaysOnTop(_wasAlwaysOnTop);
    final Rect? bounds = _savedBounds;
    if (!_wasFullScreen && bounds != null) {
      await windowManager.setBounds(bounds);
    }
    _savedBounds = null;
  }
}

/// 构建桌面宿主窗口操作（宿主级单例，实例持有快照状态）。
HostWindowOps createHostWindowOps() => WindowsHostWindowOps();

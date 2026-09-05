/// 宿主全局热键工厂（`dart:io` 实现版）。
///
/// io 目标接入 Windows FFI 实现（platform_capabilities_windows）：
/// `RegisterHotKey`（NULL hwnd）+ 16ms `PeekMessageW` 轮询 `WM_HOTKEY`。
library;

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';

/// 构建 Windows 全局热键能力（实例持有槽位与轮询泵状态，宿主级单例）。
GlobalHotkeys createHostGlobalHotkeys() => WindowsGlobalHotkeys();

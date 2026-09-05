/// 宿主屏幕捕获能力接线的 io 实现版（Windows GDI 真实现，F4-04）。
///
/// `platform_capabilities_windows` 包内部已按目标处理：非 Windows 的
/// io 目标编译不受影响（`dart:ffi` 在 android/桌面 io 目标可用）；
/// 仅 web（无 `dart:ffi`）由条件导出挡在本文件之外。
library;

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';

/// 宿主屏幕捕获实现：Windows GDI 真实现。
const ScreenCapture hostScreenCapture = windowsScreenCapture;

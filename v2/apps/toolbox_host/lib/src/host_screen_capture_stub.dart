/// 宿主屏幕捕获能力接线的 web（无 `dart:ffi`）实现。
///
/// web 目标不支持 GDI 截图：返回接口包的 unsupported 结构化失败实现
/// （`capability.unsupported` + platform=web），与 M1 词汇表对齐。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// 宿主屏幕捕获实现：web 目标恒返回结构化失败。
const ScreenCapture hostScreenCapture = UnsupportedScreenCapture('web');

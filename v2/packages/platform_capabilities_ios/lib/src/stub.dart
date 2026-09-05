/// ios 端能力 stub：接口已就位，实现交由后续任务落地（规格 §10）。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// ios 端区域截图 stub：一律返回 capability.unsupported。
const ScreenCapture iosScreenCapture = UnsupportedScreenCapture('ios');

/// ios 端系统路径 stub：一律抛 capability.unsupported。
const SystemPaths iosSystemPaths = UnsupportedSystemPaths('ios');

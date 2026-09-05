/// windows 端能力 stub：接口已就位，实现交由后续任务落地（规格 §10）。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// windows 端区域截图 stub：一律返回 capability.unsupported。
const ScreenCapture windowsScreenCapture = UnsupportedScreenCapture('windows');

/// windows 端系统路径 stub：一律抛 capability.unsupported。
const SystemPaths windowsSystemPaths = UnsupportedSystemPaths('windows');

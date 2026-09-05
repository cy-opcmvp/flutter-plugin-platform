/// windows 端能力绑定：截图已升级为 GDI 真实现（F4-04），系统路径维持
/// unsupported stub（宿主接线 [ResolvedSystemPaths] 替代）。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// windows 端系统路径 stub：一律抛 capability.unsupported。
const SystemPaths windowsSystemPaths = UnsupportedSystemPaths('windows');

/// 宿主剪贴板/已知目录工厂（`dart:io` 实现版）。
///
/// io 目标接入 Windows FFI 实现（platform_capabilities_windows）：
/// - 剪贴板写入走 CF_UNICODETEXT / CF_DIBV5 / CF_HDROP；
/// - 已知目录走 SHGetKnownFolderPath。
library;

import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:platform_capabilities_windows/platform_capabilities_windows.dart';

/// 构建 Windows FFI 版剪贴板能力。
Clipboard createHostClipboard() => const WindowsClipboard();

/// 构建 Windows FFI 版已知目录能力。
KnownFolders createHostKnownFolders() => const WindowsKnownFolders();

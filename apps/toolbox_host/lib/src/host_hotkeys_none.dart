/// 宿主全局热键工厂（无 `dart:io` 平台的实现版）。
///
/// web 等目标接入接口包默认实现：注册恒返回 false（调用方折算
/// `hotkey.register_failed`，reason=unsupported），事件流为空流。
library;

import 'package:platform_capabilities/platform_capabilities.dart';

/// 构建不支持平台的全局热键能力。
GlobalHotkeys createHostGlobalHotkeys() => const UnsupportedGlobalHotkeys(
      'web',
    );

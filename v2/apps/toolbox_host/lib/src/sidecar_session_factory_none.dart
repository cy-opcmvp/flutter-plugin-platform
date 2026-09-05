/// Sidecar 会话工厂的 web（无 dart:io）实现：恒抛不支持失败。
library;

import 'package:plugin_contracts/plugin_contracts.dart';

import 'sidecar_command_bridge.dart';

/// 创建会话工厂（web 目标）：任何调用都抛不支持的结构化失败。
SidecarSessionFactory createHashToolSessionFactory() {
  return (String scriptPath) async {
    throw SidecarSessionFactoryException(
      PluginFailure(
        'session.start_failed',
        'sidecar sessions are not supported on this target',
        {'reason': 'unsupportedTarget'},
      ),
    );
  };
}

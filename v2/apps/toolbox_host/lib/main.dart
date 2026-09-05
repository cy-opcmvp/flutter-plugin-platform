/// 工具箱宿主应用入口（F3-06，F4-02 接入真实数据根）。
///
/// 按计划约定，本文件只做引导：经异步工厂 [HostCompositionRoot.create]
/// 组装组装根（数据根由 path_provider 解析、web 分支使用占位常量），随后
/// 运行 [ToolboxApp]。全部依赖组装都在 [HostCompositionRoot] 内完成。
library;

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import 'src/app.dart';
import 'src/host_composition_root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final HostCompositionRoot root = await HostCompositionRoot.create(
    // 解析目标平台由 main 显式传入（计划 F3-06 要求）。
    target: PluginTarget.windows,
  );
  runApp(ToolboxApp(root: root));
}

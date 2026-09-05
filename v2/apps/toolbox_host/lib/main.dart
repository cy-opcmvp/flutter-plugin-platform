/// 工具箱宿主应用入口（F3-06）。
///
/// 按计划约定，本文件只做引导：声明宿主数据根字符串并以显式目标平台组装
/// [HostCompositionRoot]，随后运行 [ToolboxApp]。全部依赖组装都在
/// [HostCompositionRoot] 内完成。
library;

import 'package:flutter/material.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import 'src/app.dart';
import 'src/host_composition_root.dart';

/// 宿主数据根目录占位字符串。
///
/// M3 阶段只做路径拼接、不真实创建目录；真实路径解析与落盘在后续阶段接入
/// （届时由平台能力包提供 `%APPDATA%` 等环境变量展开）。
const String _kHostDataRoot = '%APPDATA%/toolbox-host';

void main() {
  runApp(
    ToolboxApp(
      root: HostCompositionRoot(
        // 解析目标平台由 main 显式传入（计划 F3-06 要求）。
        target: PluginTarget.windows,
        hostDataRoot: _kHostDataRoot,
      ),
    ),
  );
}

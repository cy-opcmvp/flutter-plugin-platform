import 'dart:io';

import 'package:plugin_cli/plugin_cli.dart';

/// `dart run plugin_cli <command>` 的进程入口。
///
/// 退出码语义：0 成功；1 结构化失败（错误码见计划词汇表）；2 用法错误。
void main(List<String> arguments) {
  exitCode = CliRunner.run(arguments, out: stdout, err: stderr);
}

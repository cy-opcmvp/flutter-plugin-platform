import 'dart:convert';

import 'commands/create.dart';
import 'commands/pack.dart';
import 'commands/validate.dart';

/// CLI 错误码：清单无效（含清单文件缺失或 JSON/字段非法）。
const String cliInvalidManifest = 'cli.invalid_manifest';

/// CLI 错误码：sidecar 清单声明的入口文件不存在。
const String cliMissingEntrypoint = 'cli.missing_entrypoint';

/// CLI 错误码：打包或打包自校验失败。
const String cliPackFailed = 'cli.pack_failed';

/// 命令成功退出码。
const int exitSuccess = 0;

/// 结构化失败退出码。
const int exitFailure = 1;

/// 用法错误退出码（参数缺失、未知命令等）。
const int exitUsage = 2;

/// CLI 命令统一入口：分发子命令并把结果映射为进程退出码。
abstract final class CliRunner {
  /// 执行 [arguments]（不含可执行名）。
  ///
  /// [out] 接收正常输出，[err] 接收结构化失败与用法说明；测试注入
  /// `StringBuffer` 即可捕获全部输出。返回值直接作为进程退出码：
  /// 0 成功、1 结构化失败、2 用法错误。
  static int run(
    List<String> arguments, {
    required StringSink out,
    required StringSink err,
  }) {
    if (arguments.isEmpty) {
      writeUsage(err);
      return exitUsage;
    }

    final String command = arguments.first;
    final List<String> rest = arguments.sublist(1);
    switch (command) {
      case 'create':
        return runCreate(arguments: rest, out: out, err: err);
      case 'validate':
        return runValidate(arguments: rest, out: out, err: err);
      case 'pack':
        return runPack(arguments: rest, out: out, err: err);
      case 'help' || '--help' || '-h':
        writeUsage(out);
        return exitSuccess;
      default:
        err.writeln('Unknown command: $command');
        writeUsage(err);
        return exitUsage;
    }
  }

  /// 输出全部命令的用法说明。
  static void writeUsage(StringSink sink) {
    sink.writeln('Usage: dart run plugin_cli <command>');
    sink.writeln('');
    sink.writeln('Commands:');
    sink.writeln(
      '  create --id <pluginId> --name <name> --kind <builtin|sidecar> <dir>',
    );
    sink.writeln(
      '      Scaffold a minimal manifest (plugin.json) and an entrypoint',
    );
    sink.writeln('      skeleton at <dir>.');
    sink.writeln('  validate <dir>');
    sink.writeln(
      '      Strictly decode <dir>/plugin.json; for sidecar manifests the',
    );
    sink.writeln('      entrypoint file must exist.');
    sink.writeln('  pack <dir> -o <out.scp>');
    sink.writeln(
      '      Pack every file under <dir> into an SCP1 container, then',
    );
    sink.writeln('      verify the result by reading it back.');
  }
}

/// 把结构化失败写入 [err]；单行 JSON，便于脚本消费。
///
/// [code] 必须取自计划错误码词汇表（如 `cli.invalid_manifest`）。
void writeFailure(
  StringSink err,
  String code,
  String message,
  Map<String, Object?> details,
) {
  err.writeln(
    jsonEncode(<String, Object?>{
      'code': code,
      'message': message,
      'details': details,
    }),
  );
}

import 'dart:io';
import 'dart:typed_data';

import 'package:plugin_sidecar/plugin_sidecar.dart';

import '../cli_runner.dart';
import '../parsed_args.dart';
import '../path_util.dart';

/// `pack` 子命令：打包目录为 SCP1 容器并自校验。
///
/// 退出码：0 成功；1 结构化失败（`cli.pack_failed`，details.reason 取
/// ioError / entrypointMissing / manifestMissing 等底层原因）；
/// 2 用法错误。
int runPack({
  required List<String> arguments,
  required StringSink out,
  required StringSink err,
}) {
  final ParsedArgs parsed = ParsedArgs.parse(arguments);
  final String? outputArg = parsed.option('-o');
  if ((outputArg == null || outputArg.isEmpty) ||
      parsed.positionals.length != 1) {
    err.writeln('Usage: dart run plugin_cli pack <dir> -o <out.scp>');
    return exitUsage;
  }

  final String directory = parsed.positionals.single;
  final Directory root = Directory(directory);
  if (!root.existsSync()) {
    writeFailure(
      err,
      cliPackFailed,
      'plugin directory not found: $directory',
      <String, Object?>{'reason': 'ioError'},
    );
    return exitFailure;
  }

  final File outputFile = File(outputArg);
  final List<({File file, String path})> entries = _collectEntries(
    root: root,
    outputFile: outputFile,
  );
  if (!entries.any(((entry) => entry.path == 'plugin.json'))) {
    writeFailure(
      err,
      cliPackFailed,
      '"plugin.json" not found under $directory',
      <String, Object?>{'reason': 'ioError'},
    );
    return exitFailure;
  }

  final Uint8List bytes;
  try {
    final PackageBuilder builder = PackageBuilder();
    for (final ({File file, String path}) entry in entries) {
      builder.add(entry.path, entry.file.readAsBytesSync());
    }
    bytes = builder.build();

    // 自校验：打包结果必须能被读取器完整还原（含清单与入口条目）。
    PackageReader.fromBytes(bytes).read();

    outputFile.parent.createSync(recursive: true);
    outputFile.writeAsBytesSync(bytes, flush: true);
  } on PackageException catch (exception) {
    final Object? reason = exception.failure.details['reason'];
    writeFailure(
      err,
      cliPackFailed,
      'pack failed: ${exception.failure.message}',
      <String, Object?>{'reason': reason ?? 'ioError'},
    );
    return exitFailure;
  } on FileSystemException {
    writeFailure(
      err,
      cliPackFailed,
      'failed to read plugin files',
      <String, Object?>{'reason': 'ioError'},
    );
    return exitFailure;
  }

  out.writeln(
    'Packed ${entries.length} file(s) '
    '(${bytes.length} bytes) -> ${outputFile.path}',
  );
  return exitSuccess;
}

/// 递归收集目录下全部文件；相对路径统一正斜杠并排序，跳过输出文件自身。
List<({File file, String path})> _collectEntries({
  required Directory root,
  required File outputFile,
}) {
  final List<({File file, String path})> entries =
      <({File file, String path})>[];
  for (final FileSystemEntity entity in root.listSync(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) {
      continue;
    }
    if (samePath(entity.absolute.path, outputFile.absolute.path)) {
      continue;
    }
    entries.add((file: entity, path: relativePathOf(entity, root.path)));
  }
  entries.sort(
    (({File file, String path}) a, ({File file, String path}) b) =>
        a.path.compareTo(b.path),
  );
  return entries;
}

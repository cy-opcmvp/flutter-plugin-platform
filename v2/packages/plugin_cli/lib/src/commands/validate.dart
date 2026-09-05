import 'dart:convert';
import 'dart:io';

import 'package:plugin_contracts/plugin_contracts.dart';

import '../cli_runner.dart';
import '../path_util.dart';

/// `validate` 子命令：严格解码清单并检查 sidecar 入口存在性。
///
/// 退出码：0 通过；1 结构化失败（`cli.invalid_manifest` /
/// `cli.missing_entrypoint`）；2 用法错误。
int runValidate({
  required List<String> arguments,
  required StringSink out,
  required StringSink err,
}) {
  if (arguments.length != 1) {
    err.writeln('Usage: dart run plugin_cli validate <dir>');
    return exitUsage;
  }

  final String directory = arguments.single;
  final File manifestFile = File(joinPath(directory, 'plugin.json'));
  final String manifestText;
  try {
    manifestText = manifestFile.readAsStringSync();
  } on FileSystemException {
    writeFailure(
      err,
      cliInvalidManifest,
      'plugin.json not found under $directory',
      <String, Object?>{'path': 'plugin.json'},
    );
    return exitFailure;
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(manifestText);
  } on FormatException catch (exception) {
    writeFailure(
      err,
      cliInvalidManifest,
      'plugin.json is not valid JSON: ${exception.message}',
      <String, Object?>{'message': exception.message},
    );
    return exitFailure;
  }
  if (decoded is! Map<String, Object?>) {
    writeFailure(
      err,
      cliInvalidManifest,
      'plugin.json must be a JSON object',
      <String, Object?>{},
    );
    return exitFailure;
  }

  final PluginManifest manifest;
  try {
    manifest = PluginManifestCodec.decode(decoded);
  } on FormatException catch (exception) {
    final Map<String, Object?> details = <String, Object?>{
      'message': exception.message,
    };
    const String fieldPrefix = 'Invalid manifest field: ';
    if (exception.message.startsWith(fieldPrefix)) {
      details['field'] = exception.message.substring(fieldPrefix.length);
    }
    writeFailure(err, cliInvalidManifest, exception.message, details);
    return exitFailure;
  }

  if (manifest.kind == PluginKind.sidecar) {
    final File entryFile = File(joinPath(directory, manifest.entrypoint));
    if (!entryFile.existsSync()) {
      writeFailure(
        err,
        cliMissingEntrypoint,
        'sidecar entrypoint not found: ${manifest.entrypoint}',
        <String, Object?>{'entrypoint': manifest.entrypoint},
      );
      return exitFailure;
    }
  }

  out.writeln('OK ${manifest.id} (${manifest.kind.name} v${manifest.version})');
  return exitSuccess;
}

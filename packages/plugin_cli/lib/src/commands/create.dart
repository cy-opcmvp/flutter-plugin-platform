import 'dart:convert';
import 'dart:io';

import 'package:plugin_contracts/plugin_contracts.dart';

import '../cli_runner.dart';
import '../parsed_args.dart';
import '../path_util.dart';
import '../templates/builtin_template.dart';
import '../templates/sidecar_template.dart';

/// `create` 子命令：生成最小清单与入口骨架。
///
/// 退出码：0 成功；2 用法错误（缺参、id/kind 非法、目标文件已存在）；
/// 1 生成自校验失败（防御路径，正常不应触达）。
int runCreate({
  required List<String> arguments,
  required StringSink out,
  required StringSink err,
}) {
  final ParsedArgs parsed = ParsedArgs.parse(arguments);
  final String? id = parsed.option('--id');
  final String? name = parsed.option('--name');
  final String? kind = parsed.option('--kind');
  final List<String> positionals = parsed.positionals;

  if ((id == null || id.isEmpty) ||
      (name == null || name.isEmpty) ||
      (kind == null || kind.isEmpty) ||
      positionals.length != 1) {
    _writeUsage(err);
    return exitUsage;
  }
  if (kind != 'builtin' && kind != 'sidecar') {
    err.writeln("Invalid --kind: $kind (expected builtin or sidecar)");
    return exitUsage;
  }
  if (PluginId.tryParse(id) == null) {
    err.writeln(
      'Invalid --id: $id '
      '(expected reverse-domain form like tools.demo)',
    );
    return exitUsage;
  }

  final String directory = positionals.single;
  final String entrypoint = kind == 'sidecar'
      ? sidecarFileName
      : builtinFileName(id);
  final File manifestFile = File(joinPath(directory, 'plugin.json'));
  final File entryFile = File(joinPath(directory, entrypoint));
  if (manifestFile.existsSync() || entryFile.existsSync()) {
    err.writeln(
      'Refusing to overwrite: plugin.json or $entrypoint already exists '
      'in $directory',
    );
    return exitUsage;
  }

  final Map<String, Object?> manifest = _buildManifest(
    id: id,
    name: name,
    kind: kind,
    entrypoint: entrypoint,
  );

  // 防御模板与 codec 漂移：落盘前先严格解码一次。
  try {
    PluginManifestCodec.decode(manifest);
  } on FormatException catch (exception) {
    writeFailure(
      err,
      cliInvalidManifest,
      'generated manifest is invalid: ${exception.message}',
      <String, Object?>{},
    );
    return exitFailure;
  }

  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  Directory(directory).createSync(recursive: true);
  manifestFile.writeAsStringSync('${encoder.convert(manifest)}\n');
  entryFile.writeAsStringSync(
    kind == 'sidecar'
        ? renderSidecarTemplate(pluginId: id, pluginName: name)
        : renderBuiltinTemplate(
            pluginId: id,
            pluginName: name,
            className: builtinClassName(id),
          ),
    flush: true,
  );

  out.writeln('Created $kind plugin "$id" in $directory');
  out.writeln('  plugin.json');
  out.writeln('  $entrypoint');
  return exitSuccess;
}

/// 组装 12 个必需字段的清单 JSON。
Map<String, Object?> _buildManifest({
  required String id,
  required String name,
  required String kind,
  required String entrypoint,
}) {
  final bool isSidecar = kind == 'sidecar';
  return <String, Object?>{
    'id': id,
    'name': name,
    'version': '1.0.0',
    'apiVersion': 1,
    'kind': kind,
    'targets': isSidecar
        ? <String>['windows']
        : <String>['windows', 'macos', 'linux', 'android', 'ios', 'web'],
    'entrypoint': isSidecar ? entrypoint : 'builtin://$id',
    'provides': <Object?>[],
    'requires': <Object?>[],
    'surfaces': isSidecar ? <String>[sidecarSurface] : <String>[builtinSurface],
    'configSchemaVersion': 1,
    'dataSchemaVersion': 1,
  };
}

void _writeUsage(StringSink sink) {
  sink.writeln(
    'Usage: dart run plugin_cli create --id <pluginId> --name <name> '
    '--kind <builtin|sidecar> <dir>',
  );
}

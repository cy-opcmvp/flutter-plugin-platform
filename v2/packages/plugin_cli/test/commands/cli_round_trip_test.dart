/// plugin_cli 核心闭环焦点测试。
///
/// 场景清单：
/// 1. create(builtin) → validate 通过；
/// 2. create(sidecar) → validate 通过；
/// 3. sidecar 骨架静态检查：4B 大端长度前缀（struct ">I"）、首帧 "ready"、
///    JSON-RPC 2.0 与 -32601；
/// 4. 删除 sidecar 入口后 validate → cli.missing_entrypoint；
/// 5. 篡改清单后 validate → cli.invalid_manifest（含 field 详情）；
/// 6. pack → PackageReader 往返一致（清单与条目字节）；
/// 7. pack 缺入口 → cli.pack_failed(entrypointMissing)；
/// 8. pack 缺 plugin.json → cli.pack_failed(ioError)。
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:plugin_cli/plugin_cli.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('plugin_cli_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  int runCli(
    List<String> arguments, {
    required StringBuffer out,
    required StringBuffer err,
  }) {
    return CliRunner.run(arguments, out: out, err: err);
  }

  /// 在临时目录内 create 一个 kind 类型的插件并返回插件目录路径。
  String scaffold(String kind) {
    final String pluginDir = '${tempDir.path}/plugin';
    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    final int code = runCli(
      <String>[
        'create',
        '--id',
        'tools.demo',
        '--name',
        'Demo',
        '--kind',
        kind,
        pluginDir,
      ],
      out: out,
      err: err,
    );
    expect(code, exitSuccess, reason: 'create($kind) failed: $err');
    return pluginDir;
  }

  /// 解析结构化失败输出（单行 JSON）。
  Map<String, Object?> decodeFailure(StringBuffer err) {
    final Object? decoded = jsonDecode(err.toString().trim());
    expect(decoded, isA<Map<String, Object?>>());
    return decoded! as Map<String, Object?>;
  }

  test('create builtin then validate passes', () {
    final String pluginDir = scaffold('builtin');

    expect(File('$pluginDir/plugin.json').existsSync(), isTrue);
    expect(File('$pluginDir/tools_demo_plugin.dart').existsSync(), isTrue);

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(<String>['validate', pluginDir], out: out, err: err),
      exitSuccess,
    );
    expect(err.toString(), isEmpty);
    expect(out.toString(), contains('tools.demo'));
  });

  test('create sidecar then validate passes', () {
    final String pluginDir = scaffold('sidecar');

    expect(File('$pluginDir/plugin.json').existsSync(), isTrue);
    expect(File('$pluginDir/main.py').existsSync(), isTrue);

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(<String>['validate', pluginDir], out: out, err: err),
      exitSuccess,
    );
    expect(err.toString(), isEmpty);
    expect(out.toString(), contains('sidecar'));
  });

  test('sidecar skeleton matches the M2 frame protocol', () {
    final String pluginDir = scaffold('sidecar');
    final String source = File('$pluginDir/main.py').readAsStringSync();

    // 4 字节大端长度前缀。
    expect(source, contains('struct.pack(">I"'));
    expect(source, contains('struct.unpack(">I"'));
    // 启动先发送就绪字符串帧（宿主吞掉首帧）。
    expect(source, contains('write_frame("ready")'));
    // JSON-RPC 2.0 与未知方法错误码。
    expect(source, contains('"jsonrpc": "2.0"'));
    expect(source, contains('-32601'));
  });

  test('missing sidecar entrypoint reports cli.missing_entrypoint', () {
    final String pluginDir = scaffold('sidecar');
    File('$pluginDir/main.py').deleteSync();

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(<String>['validate', pluginDir], out: out, err: err),
      exitFailure,
    );

    final Map<String, Object?> failure = decodeFailure(err);
    expect(failure['code'], cliMissingEntrypoint);
    final Map<String, Object?> details =
        failure['details']! as Map<String, Object?>;
    expect(details['entrypoint'], 'main.py');
  });

  test('tampered manifest reports cli.invalid_manifest with field detail', () {
    final String pluginDir = scaffold('sidecar');
    final File manifest = File('$pluginDir/plugin.json');
    final Map<String, Object?> decoded =
        jsonDecode(manifest.readAsStringSync())! as Map<String, Object?>;
    decoded['id'] = 'Tools.Demo'; // 违反反向域小写格式。
    manifest.writeAsStringSync(jsonEncode(decoded));

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(<String>['validate', pluginDir], out: out, err: err),
      exitFailure,
    );

    final Map<String, Object?> failure = decodeFailure(err);
    expect(failure['code'], cliInvalidManifest);
    final Map<String, Object?> details =
        failure['details']! as Map<String, Object?>;
    expect(details['field'], 'id');
  });

  test('pack output round-trips through PackageReader', () {
    final String pluginDir = scaffold('sidecar');
    final String packagePath = '${tempDir.path}/out.scp';

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(
        <String>['pack', pluginDir, '-o', packagePath],
        out: out,
        err: err,
      ),
      exitSuccess,
    );
    expect(err.toString(), isEmpty);

    final Uint8List bytes = File(packagePath).readAsBytesSync();
    final SidecarPackage package = PackageReader.fromBytes(bytes).read();
    expect(package.manifest.id.value, 'tools.demo');
    expect(package.manifest.kind, PluginKind.sidecar);
    expect(package.entries.length, 2);

    final PackageEntry? entry = package.entryByPath('main.py');
    expect(entry, isNotNull);
    expect(
      utf8.decode(entry!.bytes),
      File('$pluginDir/main.py').readAsStringSync(),
    );
  });

  test('pack without entrypoint reports cli.pack_failed', () {
    final String pluginDir = scaffold('sidecar');
    File('$pluginDir/main.py').deleteSync();
    final String packagePath = '${tempDir.path}/out.scp';

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(
        <String>['pack', pluginDir, '-o', packagePath],
        out: out,
        err: err,
      ),
      exitFailure,
    );
    expect(File(packagePath).existsSync(), isFalse);

    final Map<String, Object?> failure = decodeFailure(err);
    expect(failure['code'], cliPackFailed);
    final Map<String, Object?> details =
        failure['details']! as Map<String, Object?>;
    expect(details['reason'], 'entrypointMissing');
  });

  test('pack without manifest reports cli.pack_failed', () {
    final String pluginDir = scaffold('sidecar');
    File('$pluginDir/plugin.json').deleteSync();
    final String packagePath = '${tempDir.path}/out.scp';

    final StringBuffer out = StringBuffer();
    final StringBuffer err = StringBuffer();
    expect(
      runCli(
        <String>['pack', pluginDir, '-o', packagePath],
        out: out,
        err: err,
      ),
      exitFailure,
    );

    final Map<String, Object?> failure = decodeFailure(err);
    expect(failure['code'], cliPackFailed);
    final Map<String, Object?> details =
        failure['details']! as Map<String, Object?>;
    expect(details['reason'], 'ioError');
  });
}

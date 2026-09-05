// 覆盖场景清单（计划 F2-09 场景矩阵 1-10，语义相近断言合并为 6 个用例）：
// 1. install 构建的包 → installed，安装目录含 plugin.json 与 echo_sidecar.py。
// 2. SidecarSession 启动 python 脚本 → 就绪（stdout 首字节 + 首帧被吞）。
// 3. call('ping') → 'pong'。
// 4. call('echo', params) → params 原样回显。
// 5. call('stderrNoise') → 'ok'（stderr 噪声不影响 RPC）。
// 6. call('hang') → rpc.timeout(methodName=hang)，通道随之关闭。
// 7. call('crash') → onUnexpectedExit 收到 process.unexpected_exit(exitCode=1)。
// 8. session.stop → 通道关闭 + 进程优雅退出回收；uninstall + 重装成功。
// 9. 篡改包 → package.bad_format(digestMismatch)，原安装不受影响。
// 10. uninstall → 目录消失、isInstalled == false。
//
// 每个用例使用独立临时根目录，串行执行；无 python 3 环境时整体跳过。
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

const String _pluginIdValue = 'dev.example.pyecho';

/// 定位包内夹具：workspace 根启动测试时 cwd 不是包根，
/// 必须经 package: URI 解析到插件包目录。
Future<String> fixtureFilePath() async {
  final libUri = await Isolate.resolvePackageUri(
    Uri.parse('package:plugin_sidecar/'),
  );
  final rootUri = libUri!.resolve('..');
  return rootUri.resolve('test/fixtures/python/echo_sidecar.py').toFilePath();
}

/// 探测到的 Python 解释器命令：可执行文件 + 前置参数（如 `py -3`）。
(String, List<String>)? _pythonCommand;

/// 统一的进程级超时保护：任何一步挂起都不至于拖垮整个测试进程。
Future<T> _guard<T>(Future<T> future) {
  return future.timeout(const Duration(seconds: 20));
}

/// 探测可用的 Python 3 解释器；全部失败时跳过当前测试。
///
/// setUp 与每个用例体首行都会调用：无解释器环境下 body 立即中止。
void _requirePython() {
  _pythonCommand ??= _probePython();
  if (_pythonCommand == null) {
    markTestSkipped('python 3 not available');
  }
}

/// 依次尝试常见入口：`python`、`python3`、`py -3`（Windows 启动器）。
(String, List<String>)? _probePython() {
  const candidates = <(String, List<String>)>[
    ('python', <String>[]),
    ('python3', <String>[]),
    ('py', <String>['-3']),
  ];
  for (final (executable, prefix) in candidates) {
    final probe = Process.runSync(executable, <String>[...prefix, '--version']);
    if (probe.exitCode == 0) {
      return (executable, prefix);
    }
  }
  return null;
}

/// 用例环境：独立临时安装根 + 安装器（进程编排全部交给 SidecarSession）。
final class _Env {
  _Env._(this.root, this.installer);

  final Directory root;
  final SidecarInstaller installer;

  static Future<_Env> create() async {
    final root = await Directory.systemTemp.createTemp('py_sidecar_e2e_');
    final installer = SidecarInstaller(
      fs: const IoPackageFileSystem(),
      rootDir: root.path,
    );
    return _Env._(root, installer);
  }

  String get installDir => '${root.path}/$_pluginIdValue';

  String get scriptPath => '$installDir/echo_sidecar.py';
}

void main() {
  final pluginId = PluginId.parse(_pluginIdValue);

  setUp(_requirePython);

  Future<_Env> newEnv() async {
    final env = await _Env.create();
    addTearDown(() async {
      try {
        await env.root.delete(recursive: true);
      } on Object {
        // Windows 上句柄偶发未释放时容忍临时目录残留。
      }
    });
    return env;
  }

  Future<Uint8List> buildPackage() async {
    final manifest = utf8.encode(
      jsonEncode(<String, Object?>{
        'id': _pluginIdValue,
        'name': 'Py Echo',
        'version': '1.0.0',
        'apiVersion': 1,
        'kind': 'sidecar',
        'targets': <String>['windows'],
        'entrypoint': 'echo_sidecar.py',
        'provides': <Object?>[],
        'requires': <Object?>[],
        'surfaces': <String>['command'],
        'configSchemaVersion': 1,
        'dataSchemaVersion': 1,
      }),
    );
    final script = await _guard(File(await fixtureFilePath()).readAsBytes());
    return PackageBuilder()
        .add('plugin.json', manifest)
        .add('echo_sidecar.py', script)
        .build();
  }

  Future<InstallOutcome> installGood(_Env env) async {
    final bytes = await buildPackage();
    final package = PackageReader.fromBytes(bytes).read();
    final outcome = await _guard(env.installer.install(package));
    return outcome;
  }

  Future<SidecarSession> startAndConnect(
    _Env env, {
    Duration requestTimeout = const Duration(seconds: 3),
    void Function(PluginFailure failure)? onUnexpectedExit,
  }) async {
    final command = _pythonCommand;
    if (command == null) {
      fail('python 3 not available');
    }
    final result = await _guard(
      SidecarSession.start(
        launcher: const IoProcessLauncher(),
        spawn: SidecarSpawn(
          executable: command.$1,
          arguments: <String>[...command.$2, env.scriptPath],
        ),
        delayer: Future<void>.delayed,
        startupTimeout: const Duration(seconds: 15),
        requestTimeout: requestTimeout,
        onUnexpectedExit: onUnexpectedExit,
      ),
    );
    expect(result.succeeded, isTrue, reason: result.failure?.toString());
    return result.session!;
  }

  test('场景 1-5: 安装落盘、启动就绪、ping/echo/stderrNoise 往返', () async {
    _requirePython();
    final env = await newEnv();

    // 场景 1：安装成功且目录内容齐全。
    final outcome = await installGood(env);
    expect(outcome.succeeded, isTrue, reason: outcome.failure?.toString());
    expect(outcome.state, SidecarInstallState.installed);
    expect(File('${env.installDir}/plugin.json').existsSync(), isTrue);
    expect(File(env.scriptPath).existsSync(), isTrue);

    // 场景 2：SidecarSession 就绪（stdout 首字节；就绪帧由会话吞掉）。
    final session = await startAndConnect(env);
    addTearDown(session.stop);

    // 场景 3：ping → pong。
    final ping = await session.channel!.call('ping');
    expect(ping.failure, isNull);
    expect(ping.value, 'pong');

    // 场景 4：echo 原样回显参数（含嵌套结构与中文）。
    final params = <String, Object?>{
      'text': '你好 sidecar',
      'nested': <String, Object?>{'n': 1},
    };
    final echo = await session.channel!.call('echo', params);
    expect(echo.failure, isNull);
    expect(echo.value, params);

    // 场景 5：stderr 噪声不影响请求响应。
    final noisy = await session.channel!.call('stderrNoise');
    expect(noisy.failure, isNull);
    expect(noisy.value, 'ok');
  });

  test('场景 6: hang 请求以 rpc.timeout 完成且通道关闭', () async {
    _requirePython();
    final env = await newEnv();
    final outcome = await installGood(env);
    expect(outcome.succeeded, isTrue, reason: outcome.failure?.toString());

    final session = await startAndConnect(env);
    addTearDown(session.stop);

    final result = await session.channel!.call('hang');
    expect(result.failure?.code, 'rpc.timeout');
    expect(result.failure?.details['methodName'], 'hang');
    expect(result.failure?.details['elapsedMs'], 3000);
    expect(session.channel!.isClosed, isTrue);
  });

  test('场景 7: crash 后 onUnexpectedExit 收到 unexpected_exit', () async {
    _requirePython();
    final env = await newEnv();
    final outcome = await installGood(env);
    expect(outcome.succeeded, isTrue, reason: outcome.failure?.toString());

    final unexpected = Completer<PluginFailure>();
    final session = await startAndConnect(
      env,
      onUnexpectedExit: unexpected.complete,
    );
    addTearDown(session.stop);

    // 先确认通道可用，再触发崩溃。
    final ping = await session.channel!.call('ping');
    expect(ping.value, 'pong');

    final crash = await session.channel!.call('crash');
    expect(crash.failure?.code, 'rpc.timeout');

    final failure = await unexpected.future.timeout(
      const Duration(seconds: 20),
    );
    expect(failure.code, 'process.unexpected_exit');
    expect(failure.details['exitCode'], 1);
  });

  test('场景 8: stop 优雅退出；uninstall 后重装成功', () async {
    _requirePython();
    final env = await newEnv();
    final outcome = await installGood(env);
    expect(outcome.succeeded, isTrue, reason: outcome.failure?.toString());

    final session = await startAndConnect(env);

    final stop = await _guard(session.stop());
    expect(stop.succeeded, isTrue, reason: stop.failure?.toString());
    expect(session.channel!.isClosed, isTrue);

    final uninstall = await _guard(env.installer.uninstall(pluginId));
    expect(uninstall.succeeded, isTrue, reason: uninstall.failure?.toString());

    final reinstalled = await installGood(env);
    expect(
      reinstalled.succeeded,
      isTrue,
      reason: reinstalled.failure?.toString(),
    );
    expect(reinstalled.state, SidecarInstallState.installed);
  });

  test('场景 9: 篡改包报 digestMismatch，原安装不受影响', () async {
    _requirePython();
    final env = await newEnv();
    final bytes = await buildPackage();
    final outcome = await _guard(
      env.installer.install(PackageReader.fromBytes(bytes).read()),
    );
    expect(outcome.succeeded, isTrue, reason: outcome.failure?.toString());

    // 篡改索引之后第一个 payload 字节（plugin.json 的 '{'），
    // 使该条目 sha256 与索引不符。
    final tampered = Uint8List.fromList(bytes);
    final indexLength = ByteData.sublistView(
      tampered,
      4,
      8,
    ).getUint32(0, Endian.big);
    tampered[8 + indexLength] ^= 0x01;

    Object? caught;
    try {
      await _guard(env.installer.installBytes(tampered));
    } on PackageException catch (error) {
      caught = error;
    }
    expect(caught, isNotNull);
    final failure = (caught! as PackageException).failure;
    expect(failure.code, 'package.bad_format');
    expect(failure.details['reason'], 'digestMismatch');

    // 原安装完好：状态与文件内容均未被触碰。
    expect(await _guard(env.installer.isInstalled(pluginId)), isTrue);
    final installed = File(env.scriptPath).readAsStringSync();
    expect(installed, startsWith('"""Echo sidecar fixture'));
  });

  test('场景 10: uninstall 后目录消失且 isInstalled 为 false', () async {
    _requirePython();
    final env = await newEnv();
    final outcome = await installGood(env);
    expect(outcome.succeeded, isTrue, reason: outcome.failure?.toString());
    expect(Directory(env.installDir).existsSync(), isTrue);

    final uninstall = await _guard(env.installer.uninstall(pluginId));
    expect(uninstall.succeeded, isTrue, reason: uninstall.failure?.toString());

    expect(Directory(env.installDir).existsSync(), isFalse);
    expect(await _guard(env.installer.isInstalled(pluginId)), isFalse);
  });
}

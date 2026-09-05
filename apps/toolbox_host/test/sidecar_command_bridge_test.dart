/// SidecarCommandBridge 单元测试：安装/启动/命令失败的编排语义。
///
/// 全部经内存文件系统与脚本化 fake 会话注入，不依赖 Python 进程。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:toolbox_host/src/sidecar_command_bridge.dart';

/// 按请求 id 回放预设响应（result 或 error）的 fake 传输。
final class _ScriptedTransport implements RpcTransport {
  _ScriptedTransport({this.error});

  /// 非空时回 JSON-RPC error；为空时回三摘要 result。
  final Map<String, Object?>? error;

  final StreamController<String> _incoming = StreamController<String>();

  @override
  void send(String payload) {
    final Map<String, Object?> request =
        jsonDecode(payload) as Map<String, Object?>;
    final Object? id = request['id'];
    final Map<String, Object?>? error = this.error;
    if (error != null) {
      _incoming.add(
        jsonEncode(<String, Object?>{
          'jsonrpc': '2.0',
          'id': id,
          'error': error,
        }),
      );
      return;
    }
    _incoming.add(
      jsonEncode(<String, Object?>{
        'jsonrpc': '2.0',
        'id': id,
        'result': <String, Object?>{
          'md5': 'md5hex',
          'sha1': 'sha1hex',
          'sha256': 'sha256hex',
        },
      }),
    );
  }

  @override
  Stream<String> get incoming => _incoming.stream;
}

/// 记录 stop 次数的 fake 会话句柄。
final class _FakeSessionHandle implements SidecarSessionHandle {
  _FakeSessionHandle(this.error);

  /// 透传给 fake 传输的预设 error（null 表示成功响应）。
  final Map<String, Object?>? error;

  int stopCount = 0;

  @override
  RpcChannel get channel => RpcChannel(
    transport: _ScriptedTransport(error: error),
    delayer: (Duration duration) => Future<void>.delayed(duration),
    requestTimeout: const Duration(seconds: 2),
  );

  @override
  Future<PluginFailure?> stop() async {
    stopCount += 1;
    return null;
  }
}

/// 内存包文件系统（前缀语义的删除/重命名）。
final class _MemoryFs implements PackageFileSystem {
  final Map<String, List<int>> files = <String, List<int>>{};
  final Set<String> dirs = <String>{};

  @override
  Future<void> createDir(String path, {bool recursive = true}) async {
    dirs.add(path);
  }

  @override
  Future<bool> exists(String path) async {
    return files.containsKey(path) || dirs.contains(path);
  }

  @override
  Future<void> writeFile(String path, List<int> bytes) async {
    files[path] = List<int>.of(bytes);
  }

  @override
  Future<void> deleteTree(String path) async {
    dirs.removeWhere((String dir) => dir == path || dir.startsWith('$path/'));
    files.removeWhere(
      (String file, _) => file == path || file.startsWith('$path/'),
    );
  }

  @override
  Future<void> renameDir(String from, String to) async {
    for (final String dir
        in dirs
            .where((String dir) => dir == from || dir.startsWith('$from/'))
            .toList()) {
      dirs.remove(dir);
      dirs.add(to + dir.substring(from.length));
    }
    for (final String file
        in files.keys
            .where((String file) => file.startsWith('$from/'))
            .toList()) {
      files[to + file.substring(from.length)] = files.remove(file)!;
    }
    // 目标目录本身随 rename 而存在（对齐真实文件系统语义）。
    dirs.add(to);
  }
}

/// 构造合法的 tools.hashtool SCP1 包字节。
Uint8List _validPackageBytes() {
  final PackageBuilder builder = PackageBuilder()
    ..add(
      'plugin.json',
      utf8.encode(
        jsonEncode(<String, Object?>{
          'id': 'tools.hashtool',
          'name': 'Hash 工具',
          'version': '1.0.0',
          'apiVersion': 1,
          'kind': 'sidecar',
          'targets': <String>['windows'],
          'entrypoint': 'hash_tool.py',
          'provides': <Map<String, Object?>>[
            <String, Object?>{'id': 'hash.compute', 'version': 1},
          ],
          'requires': const <Object>[],
          'surfaces': <String>['command'],
          'configSchemaVersion': 1,
          'dataSchemaVersion': 1,
        }),
      ),
    )
    ..add('hash_tool.py', utf8.encode('print("ready")'));
  return builder.build();
}

SidecarCommandBridge _bridgeWith(_FakeSessionHandle handle) {
  return SidecarCommandBridge(
    installer: SidecarInstaller(fs: _MemoryFs(), rootDir: '/test-root'),
    pluginId: PluginId.parse('tools.hashtool'),
    entrypointFileName: 'hash_tool.py',
    sessionFactory: (String scriptPath) async => handle,
  );
}

const HashToolStrings _strings = HashToolStrings(
  formTitle: 'Hash 计算',
  textLabel: '文本',
  textPlaceholder: '输入文本',
  md5Label: 'MD5',
  sha1Label: 'SHA-1',
  sha256Label: 'SHA-256',
);

void main() {
  test('run 在未安装时返回 bridge.not_installed 且不触发会话工厂', () async {
    var factoryCalls = 0;
    final SidecarCommandBridge bridge = SidecarCommandBridge(
      installer: SidecarInstaller(fs: _MemoryFs(), rootDir: '/test-root'),
      pluginId: PluginId.parse('tools.hashtool'),
      entrypointFileName: 'hash_tool.py',
      sessionFactory: (String scriptPath) async {
        factoryCalls += 1;
        throw StateError('should not be called');
      },
    );

    final BridgeRunResult result = await bridge.run(<String, Object?>{
      'text': 'abc',
    }, strings: _strings);

    expect(result.succeeded, isFalse);
    expect(result.failure?.code, 'bridge.not_installed');
    expect(result.failure?.details['pluginId'], 'tools.hashtool');
    expect(factoryCalls, 0);
  });

  test('installFromBytes 非法字节返回 package.bad_format', () async {
    final SidecarCommandBridge bridge = _bridgeWith(_FakeSessionHandle(null));

    final BridgeInstallResult result = await bridge.installFromBytes(
      Uint8List.fromList(<int>[0, 1, 2, 3]),
    );

    expect(result.succeeded, isFalse);
    expect(result.failure?.code, 'package.bad_format');
  });

  test('安装后 start/run 成功并映射 FieldsResultDescriptor', () async {
    final _FakeSessionHandle handle = _FakeSessionHandle(null);
    final SidecarCommandBridge bridge = _bridgeWith(handle);

    final BridgeInstallResult install = await bridge.installFromBytes(
      _validPackageBytes(),
    );
    expect(install.succeeded, isTrue);

    final BridgeRunResult run = await bridge.run(<String, Object?>{
      'text': 'abc',
    }, strings: _strings);

    expect(run.succeeded, isTrue);
    final FieldsResultDescriptor descriptor =
        run.result! as FieldsResultDescriptor;
    expect(descriptor.fields.map((ResultField field) => field.label), <String>[
      'MD5',
      'SHA-1',
      'SHA-256',
    ]);
    expect(descriptor.fields.map((ResultField field) => field.value), <String>[
      'md5hex',
      'sha1hex',
      'sha256hex',
    ]);
    expect(bridge.formDescriptor(_strings).fields.single.key, 'text');

    expect(await bridge.stop(), isNull);
    expect(handle.stopCount, 1);
  });

  test('run 远端错误透传为 bridge.command_failed(cause=rpc.remote_error)', () async {
    final SidecarCommandBridge bridge = _bridgeWith(
      _FakeSessionHandle(<String, Object?>{
        'code': -32601,
        'message': 'Method not found',
      }),
    );
    await bridge.installFromBytes(_validPackageBytes());

    final BridgeRunResult run = await bridge.run(<String, Object?>{
      'text': 'abc',
    }, strings: _strings);

    expect(run.succeeded, isFalse);
    expect(run.failure?.code, 'bridge.command_failed');
    expect(run.failure?.details['cause'], 'rpc.remote_error');
    expect(run.failure?.details['pluginId'], 'tools.hashtool');
  });

  test('start 工厂失败透传 cause=session.start_failed', () async {
    final SidecarCommandBridge bridge = SidecarCommandBridge(
      installer: SidecarInstaller(fs: _MemoryFs(), rootDir: '/test-root'),
      pluginId: PluginId.parse('tools.hashtool'),
      entrypointFileName: 'hash_tool.py',
      sessionFactory: (String scriptPath) async {
        throw SidecarSessionFactoryException(
          PluginFailure(
            'session.start_failed',
            'python not found',
            <String, Object?>{'reason': 'pythonNotFound'},
          ),
        );
      },
    );
    await bridge.installFromBytes(_validPackageBytes());

    final BridgeStartOutcome outcome = await bridge.start();

    expect(outcome.succeeded, isFalse);
    expect(outcome.failure?.code, 'bridge.command_failed');
    expect(outcome.failure?.details['cause'], 'session.start_failed');
    expect(outcome.failure?.details['causeDetails'], <String, Object?>{
      'reason': 'pythonNotFound',
    });
  });

  test('重复 start 先停止旧会话', () async {
    final _FakeSessionHandle first = _FakeSessionHandle(null);
    final _FakeSessionHandle second = _FakeSessionHandle(null);
    var factoryCalls = 0;
    final SidecarCommandBridge bridge = SidecarCommandBridge(
      installer: SidecarInstaller(fs: _MemoryFs(), rootDir: '/test-root'),
      pluginId: PluginId.parse('tools.hashtool'),
      entrypointFileName: 'hash_tool.py',
      sessionFactory: (String scriptPath) async {
        factoryCalls += 1;
        return factoryCalls == 1 ? first : second;
      },
    );
    await bridge.installFromBytes(_validPackageBytes());

    expect((await bridge.start()).succeeded, isTrue);
    expect((await bridge.start()).succeeded, isTrue);

    expect(first.stopCount, 1);
    expect(second.stopCount, 0);
    expect(factoryCalls, 2);
  });

  test('无会话时 stop 幂等返回 null；未安装卸载返回结构化失败', () async {
    final SidecarCommandBridge bridge = _bridgeWith(_FakeSessionHandle(null));

    expect(await bridge.stop(), isNull);
    final PluginFailure? uninstallFailure = await bridge.uninstall();
    expect(uninstallFailure?.code, 'sidecar.uninstall_failed');
  });
}

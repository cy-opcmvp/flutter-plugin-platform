// 覆盖场景清单：
// 1. start 成功：stdout 首字节即视为就绪，process 返回且 hasAlive == true。
// 2. start 超时：delayer 到期 → kill 被调用 + process.start_timeout。
// 3. 启动即退出：process.start_failed（reason=exited，details 含 exitCode），
//    不触发 onUnexpectedExit。
// 4. launcher.start 抛异常：process.start_failed（reason=spawnError），
//    process 为 null。
// 5. stop 正常：kill 被调用、进程退出 → success；不触发意外退出回调。
// 6. stop 超时：kill 后进程未退出且 delayer 到期 → process.stop_timeout。
// 7. 就绪后意外退出：onUnexpectedExit 收 process.unexpected_exit
//    （details 含 exitCode）。
// 8. disposeAll：两个存活进程都被 stop，hasAlive == false。
// 9. disposeAll 幂等：无存活进程时二次调用为 no-op。
import 'dart:async';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// fake 子进程：手动注入 stdout/exitCode，记录 kill 与 stdin 调用。
final class _FakeProcess implements SidecarProcess {
  _FakeProcess();

  /// kill 时模拟的退出码；负数表示 kill 后仍不退出（顽固进程）。
  int exitCodeOnKill = -1;

  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final StreamController<List<int>> _stderr = StreamController<List<int>>();
  final Completer<int> _exitCode = Completer<int>();
  int killCount = 0;
  final List<List<int>> writtenStdin = <List<int>>[];
  bool stdinClosed = false;

  /// 模拟 stdout 送出首字节（就绪信号）。
  void emitReady() {
    _stdout.add(<int>[1]);
  }

  /// 模拟进程以给定退出码结束。
  void exit(int code) {
    if (!_exitCode.isCompleted) {
      _exitCode.complete(code);
    }
  }

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  Future<void> kill() async {
    killCount += 1;
    if (exitCodeOnKill >= 0) {
      exit(exitCodeOnKill);
    }
  }

  @override
  Future<void> writeStdin(List<int> bytes) async {
    writtenStdin.add(bytes);
  }

  @override
  Future<void> closeStdin() async {
    stdinClosed = true;
  }
}

/// fake 启动器：可注入启动异常，记录创建的 fake 进程。
final class _FakeLauncher implements SidecarProcessLauncher {
  Object? startError;
  final List<_FakeProcess> created = <_FakeProcess>[];

  @override
  Future<SidecarProcess> start(SidecarSpawn spawn) async {
    final error = startError;
    if (error != null) {
      throw error;
    }
    final process = _FakeProcess();
    created.add(process);
    return process;
  }
}

/// 受控延时器：测试手动触发到期，不真实等待。
final class _ControlledDelayer {
  final List<Completer<void>> _completers = <Completer<void>>[];

  Future<void> call(Duration duration) {
    final completer = Completer<void>();
    _completers.add(completer);
    return completer.future;
  }

  void fireAll() {
    for (final completer in _completers) {
      completer.complete();
    }
    _completers.clear();
  }
}

/// 启动并推进到就绪，返回 fake 进程。
Future<_FakeProcess> _startReady(
  SidecarSupervisor supervisor,
  _FakeLauncher launcher, {
  void Function(PluginFailure failure)? onUnexpectedExit,
}) async {
  final future = supervisor.start(
    const SidecarSpawn(executable: 'echo'),
    onUnexpectedExit: onUnexpectedExit,
  );
  await pumpEventQueue();
  launcher.created.last.emitReady();
  final result = await future;
  return result.process! as _FakeProcess;
}

void main() {
  late _FakeLauncher launcher;
  late _ControlledDelayer delayer;
  late SidecarSupervisor supervisor;

  setUp(() {
    launcher = _FakeLauncher();
    delayer = _ControlledDelayer();
    supervisor = SidecarSupervisor(
      launcher: launcher,
      delayer: delayer.call,
      startupTimeout: const Duration(milliseconds: 100),
    );
  });

  test('start succeeds on the first stdout bytes', () async {
    final future = supervisor.start(const SidecarSpawn(executable: 'echo'));

    await pumpEventQueue();
    launcher.created.single.emitReady();

    final result = await future;
    expect(result.succeeded, isTrue);
    expect(result.failure, isNull);
    expect(result.process, same(launcher.created.single));
    expect(supervisor.hasAlive, isTrue);
  });

  test('start timeout kills the process and reports start_timeout', () async {
    final future = supervisor.start(const SidecarSpawn(executable: 'echo'));

    await pumpEventQueue();
    delayer.fireAll();

    final result = await future;
    expect(result.failure?.code, 'process.start_timeout');
    expect(launcher.created.single.killCount, 1);
    expect(supervisor.hasAlive, isFalse);
  });

  test('exiting during startup reports start_failed with exitCode', () async {
    PluginFailure? unexpected;
    final future = supervisor.start(
      const SidecarSpawn(executable: 'echo'),
      onUnexpectedExit: (failure) => unexpected = failure,
    );

    await pumpEventQueue();
    launcher.created.single.exit(3);

    final result = await future;
    expect(result.failure?.code, 'process.start_failed');
    expect(result.failure?.details['reason'], 'exited');
    expect(result.failure?.details['exitCode'], 3);
    // 启动阶段的失败不算意外退出。
    expect(unexpected, isNull);
  });

  test('launcher failure reports start_failed with spawnError', () async {
    launcher.startError = StateError('binary missing');

    final result = await supervisor.start(
      const SidecarSpawn(executable: 'echo'),
    );

    expect(result.failure?.code, 'process.start_failed');
    expect(result.failure?.details['reason'], 'spawnError');
    expect(result.process, isNull);
    expect(supervisor.hasAlive, isFalse);
  });

  test('stop succeeds when the process exits promptly', () async {
    PluginFailure? unexpected;
    final process = await _startReady(
      supervisor,
      launcher,
      onUnexpectedExit: (failure) => unexpected = failure,
    );

    final stopFuture = supervisor.stop(process);
    process.exit(0);

    final result = await stopFuture;
    expect(result.succeeded, isTrue);
    expect(result.failure, isNull);
    expect(process.killCount, 1);
    expect(supervisor.hasAlive, isFalse);
    await pumpEventQueue();
    // 主动 stop 引发的退出不算意外退出。
    expect(unexpected, isNull);
  });

  test('stop reports stop_timeout when the process ignores kill', () async {
    final process = await _startReady(supervisor, launcher);

    final stopFuture = supervisor.stop(process);
    await pumpEventQueue();
    delayer.fireAll();

    final result = await stopFuture;
    expect(result.failure?.code, 'process.stop_timeout');
    expect(process.killCount, 1);
    // 顽固进程未退出，仍视为存活。
    expect(supervisor.hasAlive, isTrue);
  });

  test('unexpected exit after readiness invokes the callback', () async {
    PluginFailure? unexpected;
    final process = await _startReady(
      supervisor,
      launcher,
      onUnexpectedExit: (failure) => unexpected = failure,
    );

    process.exit(9);
    await pumpEventQueue();

    expect(unexpected?.code, 'process.unexpected_exit');
    expect(unexpected?.details['exitCode'], 9);
    expect(supervisor.hasAlive, isFalse);
  });

  test('disposeAll stops every alive process', () async {
    final first = await _startReady(supervisor, launcher);
    final second = await _startReady(supervisor, launcher);
    first.exitCodeOnKill = 0;
    second.exitCodeOnKill = 0;

    await supervisor.disposeAll();

    expect(first.killCount, 1);
    expect(second.killCount, 1);
    expect(supervisor.hasAlive, isFalse);
  });

  test('disposeAll is idempotent when nothing is alive', () async {
    await supervisor.disposeAll();

    await supervisor.disposeAll();

    expect(supervisor.hasAlive, isFalse);
    expect(launcher.created, isEmpty);
  });
}

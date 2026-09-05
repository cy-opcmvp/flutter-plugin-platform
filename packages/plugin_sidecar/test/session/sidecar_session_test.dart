// 覆盖场景清单（计划 F3-02 Step 2，相似断言合并为 8 个用例）：
// 1. start 成功（粘包）：就绪帧与响应帧前段粘在同一 chunk → channel 非空，
//    首帧（"ready"）被吞掉不进通道（否则响应被误判为 unexpectedResponse），
//    粘包后半段补齐后响应按 id 匹配，请求帧写入 stdin。
// 2. start 成功（半包）：就绪帧分片到达 → 未解出首帧前会话未就绪；
//    补齐后即可建通道完成往返。
// 3. 启动超时 → session.start_failed(reason=process.start_timeout)，
//    进程已回收（kill 被调用），无通道泄漏（session 为 null）。
// 4. 启动即退出 → session.start_failed 带 exitCode，不触发 onUnexpectedExit。
// 5. launcher.start 抛异常 → session.start_failed(reason=spawnError)。
// 6. 就绪前 stdout 帧协议违规 → 透传 rpc.frame_invalid，进程已回收。
// 7. call/stop 全链路 → 响应按 id 匹配、stop 后通道关闭、kill 被调用、
//    stop 引发的退出不算意外、stop 幂等。
// 8. 宽限期内未退出的进程 → stop 报 process.stop_timeout；
//    就绪后进程意外退出 → onUnexpectedExit(process.unexpected_exit)。
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// 内存 fake 进程：stdout 可手动注入字节，kill 行为受控。
final class _FakeProcess implements SidecarProcess {
  final StreamController<List<int>> _stdout = StreamController<List<int>>();
  final Completer<int> _exitCode = Completer<int>();

  /// kill 时若尚未显式退出，则以此退出码结束；null 表示 kill 后不退出。
  int? exitCodeOnKill = 0;

  int killCount = 0;
  final List<List<int>> writtenStdin = <List<int>>[];

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  Future<void> kill() async {
    killCount += 1;
    final code = exitCodeOnKill;
    if (code != null) {
      _exit(code);
    }
  }

  @override
  Future<void> writeStdin(List<int> bytes) async {
    writtenStdin.add(List<int>.of(bytes));
  }

  @override
  Future<void> closeStdin() async {}

  /// 向 stdout 注入字节（无监听时由控制器缓冲）。
  void emit(List<int> bytes) {
    _stdout.add(bytes);
  }

  /// 模拟进程以给定退出码结束。
  void exit(int code) {
    _exit(code);
  }

  void _exit(int code) {
    if (!_exitCode.isCompleted) {
      _exitCode.complete(code);
    }
  }
}

/// fake 启动器：返回预置进程，可注入启动异常。
final class _FakeLauncher implements SidecarProcessLauncher {
  _FakeLauncher(this.process);

  /// 非 null 时 start 抛出该异常。
  Object? startError;

  final _FakeProcess process;

  @override
  Future<SidecarProcess> start(SidecarSpawn spawn) async {
    final error = startError;
    if (error != null) {
      throw error;
    }
    return process;
  }
}

/// 受控延时器：记录调用次数，测试手动触发到期，不真实等待。
final class _ControlledDelayer {
  final List<Completer<void>> _completers = <Completer<void>>[];
  int callCount = 0;

  Future<void> call(Duration duration) {
    callCount += 1;
    final completer = Completer<void>();
    _completers.add(completer);
    return completer.future;
  }

  /// 触发所有已挂起的延时到期。
  void fireAll() {
    for (final completer in _completers) {
      completer.complete();
    }
    _completers.clear();
  }
}

Uint8List frameFor(String payload) => encodeFrame(payload);

/// 夹具约定的就绪帧 payload：JSON 编码的纯字符串 "ready"。
String readyPayload() => jsonEncode('ready');

Map<String, Object?> successPayload(Object id, Object? value) {
  return <String, Object?>{'jsonrpc': '2.0', 'id': id, 'result': value};
}

Future<SessionStartResult> _beginSession({
  required SidecarProcessLauncher launcher,
  required _ControlledDelayer delayer,
  void Function(PluginFailure failure)? onUnexpectedExit,
}) {
  return SidecarSession.start(
    launcher: launcher,
    spawn: const SidecarSpawn(executable: 'fake', arguments: <String>[]),
    delayer: delayer.call,
    startupTimeout: const Duration(milliseconds: 100),
    requestTimeout: const Duration(milliseconds: 100),
    onUnexpectedExit: onUnexpectedExit,
  );
}

void main() {
  test('start 成功：粘包的就绪帧被吞掉且响应照常进入通道', () async {
    final process = _FakeProcess();
    final delayer = _ControlledDelayer();

    // 就绪帧与响应帧前 5 字节粘在同一 chunk 到达（无监听时控制器缓冲）。
    final response = frameFor(jsonEncode(successPayload(0, 'pong')));
    process.emit(<int>[...frameFor(readyPayload()), ...response.sublist(0, 5)]);

    final result = await _beginSession(
      launcher: _FakeLauncher(process),
      delayer: delayer,
    );
    expect(result.succeeded, isTrue, reason: result.failure?.toString());
    final session = result.session!;
    expect(session.channel, isNotNull);

    // 若就绪帧泄漏进通道，首个响应会被误判为 unexpectedResponse 而关闭通道。
    final call = session.channel!.call('ping');
    process.emit(response.sublist(5));
    final callResult = await call;
    expect(callResult.failure, isNull);
    expect(callResult.value, 'pong');
    expect(process.writtenStdin, isNotEmpty);

    final stop = await session.stop();
    expect(stop.succeeded, isTrue);
  });

  test('start 成功：就绪帧半包到达，补齐前不就绪', () async {
    final process = _FakeProcess();
    final delayer = _ControlledDelayer();

    final frame = frameFor(readyPayload());
    process.emit(frame.sublist(0, 3));

    final startFuture = _beginSession(
      launcher: _FakeLauncher(process),
      delayer: delayer,
    );
    var settled = false;
    unawaited(startFuture.then((_) => settled = true));
    await pumpEventQueue();
    // 半包未解出首帧：会话尚未就绪（超时分支由受控 delayer 排除）。
    expect(settled, isFalse);

    process.emit(<int>[
      ...frame.sublist(3),
      ...frameFor(jsonEncode(successPayload(0, 'pong'))),
    ]);
    final result = await startFuture;
    expect(result.succeeded, isTrue, reason: result.failure?.toString());
    final call = await result.session!.channel!.call('ping');
    expect(call.value, 'pong');
  });

  test('启动超时：进程已回收且无通道泄漏', () async {
    final process = _FakeProcess();
    final delayer = _ControlledDelayer();

    final startFuture = _beginSession(
      launcher: _FakeLauncher(process),
      delayer: delayer,
    );
    await pumpEventQueue();
    delayer.fireAll();

    final result = await startFuture;
    expect(result.session, isNull);
    expect(result.failure?.code, 'session.start_failed');
    expect(result.failure?.details['reason'], 'process.start_timeout');
    expect(process.killCount, 1);
  });

  test('启动即退出：失败带 exitCode 且不触发 onUnexpectedExit', () async {
    final process = _FakeProcess();
    final unexpected = Completer<PluginFailure>();
    final delayer = _ControlledDelayer();

    final startFuture = _beginSession(
      launcher: _FakeLauncher(process),
      delayer: delayer,
      onUnexpectedExit: unexpected.complete,
    );
    await pumpEventQueue();
    process.exit(3);

    final result = await startFuture;
    expect(result.session, isNull);
    expect(result.failure?.code, 'session.start_failed');
    expect(result.failure?.details['reason'], 'process.start_failed');
    expect(result.failure?.details['exitCode'], 3);
    expect(unexpected.isCompleted, isFalse);
  });

  test('launcher.start 抛异常：session.start_failed(spawnError)', () async {
    final process = _FakeProcess();
    final launcher = _FakeLauncher(process)..startError = StateError('denied');

    final result = await _beginSession(
      launcher: launcher,
      delayer: _ControlledDelayer(),
    );
    expect(result.session, isNull);
    expect(result.failure?.code, 'session.start_failed');
    expect(result.failure?.details['reason'], 'process.start_failed');
    expect(result.failure?.details['detail'], 'spawnError');
  });

  test('就绪前 stdout 帧协议违规：透传 frame_invalid 且进程已回收', () async {
    final process = _FakeProcess();
    // 'garbage' 的前 4 字节被解读为超大长度前缀 → tooLarge。
    process.emit(utf8.encode('garbage'));

    final result = await _beginSession(
      launcher: _FakeLauncher(process),
      delayer: _ControlledDelayer(),
    );
    expect(result.session, isNull);
    expect(result.failure?.code, 'session.start_failed');
    expect(result.failure?.details['reason'], 'rpc.frame_invalid');
    expect(process.killCount, 1);
  });

  test('call/stop 全链路：stop 关闭通道且幂等，退出不算意外', () async {
    final process = _FakeProcess();
    final unexpected = Completer<PluginFailure>();
    final delayer = _ControlledDelayer();
    process.emit(frameFor(readyPayload()));

    final result = await _beginSession(
      launcher: _FakeLauncher(process),
      delayer: delayer,
      onUnexpectedExit: unexpected.complete,
    );
    final session = result.session!;

    final call = session.channel!.call('ping');
    process.emit(frameFor(jsonEncode(successPayload(0, 'pong'))));
    expect((await call).value, 'pong');
    expect(process.writtenStdin, isNotEmpty);

    final stop = await session.stop();
    expect(stop.succeeded, isTrue);
    expect(process.killCount, 1);
    expect(session.channel!.isClosed, isTrue);
    expect(unexpected.isCompleted, isFalse);

    // stop 幂等：重复调用不抛异常，且结果不劣化。
    final again = await session.stop();
    expect(again.succeeded, isTrue);
  });

  test('stop 超时与意外退出：宽限期内未退出报 stop_timeout，退出触发回调', () async {
    final process = _FakeProcess()..exitCodeOnKill = null; // kill 后拒不退出
    final unexpected = Completer<PluginFailure>();
    final delayer = _ControlledDelayer();
    process.emit(frameFor(readyPayload()));

    final result = await _beginSession(
      launcher: _FakeLauncher(process),
      delayer: delayer,
      onUnexpectedExit: unexpected.complete,
    );
    final session = result.session!;

    // 宽限期内未退出：受控推进触发 stop_timeout。
    final stopFuture = session.stop();
    await pumpEventQueue();
    delayer.fireAll();
    final stop = await stopFuture;
    expect(stop.succeeded, isFalse);
    expect(stop.failure?.code, 'process.stop_timeout');
    expect(process.killCount, 1);

    // 仍未退出的进程随后自行退出：非 stop 完成的退出视为意外。
    process.exit(1);
    final failure = await unexpected.future.timeout(const Duration(seconds: 5));
    expect(failure.code, 'process.unexpected_exit');
    expect(failure.details['exitCode'], 1);
  });
}

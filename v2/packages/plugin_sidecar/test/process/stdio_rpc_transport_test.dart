// 覆盖场景清单：
// 1. send 将 payload 经 encodeFrame 写入 stdin（写入转发）。
// 2. stdout 半包与粘包均被增量解码为 payload 流；stdout 关闭后 incoming 完成。
// 3. send 的 payload 超过帧上限时同步抛 RpcFrameException(tooLarge)。
// 4. stdout 帧协议违规时 incoming 投递 RpcFrameException error 事件。
// 5. stdin 写入失败时错误投递到 incoming。
// 6. dispose 幂等并关闭 incoming。
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// 测试用假进程：记录 stdin 写入、手动喂 stdout。
final class _FakeProcess implements SidecarProcess {
  final StreamController<List<int>> stdoutController =
      StreamController<List<int>>();
  final List<List<int>> written = <List<int>>[];
  bool stdinClosed = false;
  Object? writeError;

  @override
  Stream<List<int>> get stdout => stdoutController.stream;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  Future<int> get exitCode => Completer<int>().future;

  @override
  Future<void> kill() async {}

  @override
  Future<void> writeStdin(List<int> bytes) async {
    final error = writeError;
    if (error != null) {
      throw error;
    }
    written.add(bytes);
  }

  @override
  Future<void> closeStdin() async {
    stdinClosed = true;
  }
}

/// 构造一帧完整字节：4 字节大端长度前缀 + UTF-8 payload。
List<int> frameFor(String payload) {
  final data = utf8.encode(payload);
  final header = ByteData(4)..setUint32(0, data.length, Endian.big);
  return <int>[...header.buffer.asUint8List(), ...data];
}

void main() {
  test('send 将 payload 编码为帧写入 stdin', () async {
    final process = _FakeProcess();
    final transport = StdioRpcTransport(process);

    transport.send('{"a":1}');
    await pumpEventQueue();

    expect(process.written, hasLength(1));
    expect(process.written.single, frameFor('{"a":1}'));
    expect(process.stdinClosed, isFalse);
    await transport.dispose();
  });

  test('stdout 半包与粘包均被增量解码，关闭后 incoming 完成', () async {
    final process = _FakeProcess();
    final transport = StdioRpcTransport(process);

    final done = expectLater(
      transport.incoming,
      emitsInOrder(<Object>['{"a":1}', '{"b":2}', '{"c":3}', emitsDone]),
    );

    final frame1 = frameFor('{"a":1}');
    final frame2 = frameFor('{"b":2}');
    final frame3 = frameFor('{"c":3}');
    // 半包：帧 1 拆两次投递。
    process.stdoutController.add(frame1.sublist(0, 2));
    process.stdoutController.add(frame1.sublist(2));
    // 粘包：帧 2 完整 + 帧 3 前半一次投递。
    process.stdoutController.add(<int>[...frame2, ...frame3.sublist(0, 5)]);
    process.stdoutController.add(frame3.sublist(5));
    await process.stdoutController.close();
    await done;
    await transport.dispose();
  });

  test('send 的 payload 超过帧上限时同步抛 RpcFrameException', () {
    final process = _FakeProcess();
    final transport = StdioRpcTransport(process, maxFrameBytes: 8);

    expect(
      () => transport.send('123456789'),
      throwsA(
        isA<RpcFrameException>().having(
          (error) => error.failure.details['reason'],
          'reason',
          'tooLarge',
        ),
      ),
    );
    expect(process.written, isEmpty);
    return transport.dispose();
  });

  test('stdout 帧协议违规时 incoming 投递 RpcFrameException', () async {
    final process = _FakeProcess();
    final transport = StdioRpcTransport(process, maxFrameBytes: 8);

    final errors = <Object>[];
    transport.incoming.listen((_) {}, onError: errors.add);

    // 声明长度 100 超过上限 8，不等 payload 到达即失败。
    final header = ByteData(4)..setUint32(0, 100, Endian.big);
    process.stdoutController.add(header.buffer.asUint8List());
    await pumpEventQueue();

    expect(errors, hasLength(1));
    final failure = (errors.single as RpcFrameException).failure;
    expect(failure.code, 'rpc.frame_invalid');
    expect(failure.details['reason'], 'tooLarge');
    await transport.dispose();
  });

  test('stdin 写入失败时错误投递到 incoming', () async {
    final process = _FakeProcess()..writeError = StateError('broken pipe');
    final transport = StdioRpcTransport(process);

    final errors = <Object>[];
    transport.incoming.listen((_) {}, onError: errors.add);

    transport.send('{}');
    await pumpEventQueue();

    expect(errors, hasLength(1));
    expect(errors.single, isA<StateError>());
    await transport.dispose();
  });

  test('dispose 幂等并关闭 incoming', () async {
    final process = _FakeProcess();
    final transport = StdioRpcTransport(process);

    await transport.dispose();
    await transport.dispose();

    expect(transport.incoming, emitsDone);
  });
}

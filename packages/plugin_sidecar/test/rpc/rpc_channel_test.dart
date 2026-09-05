// 覆盖场景清单：
// 1. call 收到匹配 id 的成功响应：value 透传、无 failure、通道保持打开。
// 2. 并发 3 个 call、响应乱序到达：各自按 id 精确匹配，互不错配。
// 3. error 响应：rpc.remote_error，details 携带远端 code/message/data。
// 4. delayer 到期无响应：rpc.timeout（details 含 methodName/elapsedMs），
//    通道关闭；其余 pending call 按各自超时结果收敛为 failure。
// 5. 超时后迟到的响应：通道保持 closed，结果不被改写，不崩溃。
// 6. 响应 id 无对应 pending：通道关闭，pending 以
//    rpc.channel_closed(unexpectedResponse) 完成。
// 7. transport.send 抛异常：pending 以 rpc.channel_closed(transportError)
//    完成，通道关闭。
// 8. incoming 喂非法 JSON payload：当前 call 以 rpc.message_invalid 完成
//    并关闭通道；关闭后的 call 立即以
//    rpc.channel_closed(closedByCaller) 完成。
// 9. close()：pending 以 rpc.channel_closed(closedByCaller) 完成；
//    close 后再 call 立即失败；close 幂等。
// 10. notify：只发送 notification、不注册超时 pending。
// 11. 请求 id 从 0 开始递增分配。
import 'dart:async';
import 'dart:convert';

import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

/// 内存 fake 传输：记录发送的 payload，手动注入 incoming 事件。
final class _FakeTransport implements RpcTransport {
  final List<String> sent = <String>[];

  /// 非 null 时 send 抛出该异常（模拟传输错误）。
  Object? sendError;

  final StreamController<String> _incoming =
      StreamController<String>.broadcast();

  @override
  void send(String payload) {
    final error = sendError;
    if (error != null) {
      throw error;
    }
    sent.add(payload);
  }

  @override
  Stream<String> get incoming => _incoming.stream;

  /// 模拟对端送来一帧 payload。
  void emit(String payload) {
    _incoming.add(payload);
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

Map<String, Object?> successPayload(Object id, Object? value) {
  return <String, Object?>{'jsonrpc': '2.0', 'id': id, 'result': value};
}

Map<String, Object?> errorPayload(
  Object id,
  int code,
  String message,
  Object? data,
) {
  return <String, Object?>{
    'jsonrpc': '2.0',
    'id': id,
    'error': <String, Object?>{'code': code, 'message': message, 'data': data},
  };
}

int sentId(String payload) {
  final decoded = jsonDecode(payload) as Map<String, Object?>;
  return decoded['id']! as int;
}

void main() {
  late _FakeTransport transport;
  late _ControlledDelayer delayer;
  late RpcChannel channel;

  setUp(() {
    transport = _FakeTransport();
    delayer = _ControlledDelayer();
    channel = RpcChannel(
      transport: transport,
      delayer: delayer.call,
      requestTimeout: const Duration(milliseconds: 100),
    );
  });

  test('call matches the success response by id', () async {
    final future = channel.call('ping');

    transport.emit(jsonEncode(successPayload(0, 'pong')));

    final result = await future;
    expect(result.value, 'pong');
    expect(result.failure, isNull);
    expect(channel.isClosed, isFalse);
  });

  test('concurrent calls match out-of-order responses by id', () async {
    final first = channel.call('a');
    final second = channel.call('b');
    final third = channel.call('c');

    transport.emit(jsonEncode(successPayload(2, 'c-value')));
    transport.emit(jsonEncode(successPayload(0, 'a-value')));
    transport.emit(jsonEncode(successPayload(1, 'b-value')));

    expect((await first).value, 'a-value');
    expect((await second).value, 'b-value');
    expect((await third).value, 'c-value');
    expect(channel.isClosed, isFalse);
  });

  test('error response surfaces remote error details', () async {
    final future = channel.call('boom');

    transport.emit(jsonEncode(errorPayload(0, 42, 'boom', {'hint': 'x'})));

    final result = await future;
    expect(result.value, isNull);
    expect(result.failure?.code, 'rpc.remote_error');
    expect(result.failure?.message, 'boom');
    expect(result.failure?.details['code'], 42);
    expect(result.failure?.details['message'], 'boom');
    expect(result.failure?.details['data'], <String, Object?>{'hint': 'x'});
  });

  test('timeout fails the call and closes the channel', () async {
    final first = channel.call('ping');
    final second = channel.call('slow');

    delayer.fireAll();

    final firstResult = await first;
    expect(firstResult.failure?.code, 'rpc.timeout');
    expect(firstResult.failure?.details['methodName'], 'ping');
    expect(firstResult.failure?.details['elapsedMs'], 100);
    expect(channel.isClosed, isTrue);
    // 其余 pending call 按各自超时结果收敛。
    final secondResult = await second;
    expect(secondResult.failure?.code, 'rpc.timeout');
  });

  test('late response after timeout meets a closed channel', () async {
    final future = channel.call('ping');

    delayer.fireAll();
    final result = await future;
    transport.emit(jsonEncode(successPayload(0, 'late')));

    expect(result.failure?.code, 'rpc.timeout');
    expect(channel.isClosed, isTrue);
  });

  test('unexpected response id closes the channel', () async {
    final future = channel.call('ping');

    transport.emit(jsonEncode(successPayload(99, 'stray')));

    final result = await future;
    expect(result.failure?.code, 'rpc.channel_closed');
    expect(result.failure?.details['reason'], 'unexpectedResponse');
    expect(channel.isClosed, isTrue);
  });

  test('send failure closes the channel with transportError', () async {
    transport.sendError = StateError('pipe broken');

    final result = await channel.call('ping');

    expect(result.failure?.code, 'rpc.channel_closed');
    expect(result.failure?.details['reason'], 'transportError');
    expect(channel.isClosed, isTrue);
  });

  test('invalid payload fails the call with message_invalid', () async {
    final future = channel.call('ping');

    transport.emit('not-json');

    final result = await future;
    expect(result.failure?.code, 'rpc.message_invalid');
    expect(channel.isClosed, isTrue);
    // 关闭后的 call 立即以 closedByCaller 完成。
    final later = await channel.call('ping');
    expect(later.failure?.code, 'rpc.channel_closed');
    expect(later.failure?.details['reason'], 'closedByCaller');
  });

  test('close fails pending calls and rejects later calls', () async {
    final future = channel.call('ping');

    channel.close();
    final result = await future;

    expect(result.failure?.code, 'rpc.channel_closed');
    expect(result.failure?.details['reason'], 'closedByCaller');
    expect(channel.isClosed, isTrue);
    final later = await channel.call('ping');
    expect(later.failure?.details['reason'], 'closedByCaller');
    // 幂等：重复 close 不抛异常。
    channel.close();
  });

  test('notify sends a notification without pending state', () {
    channel.notify('tick', {'n': 1});

    expect(transport.sent, hasLength(1));
    final decoded = jsonDecode(transport.sent.single) as Map<String, Object?>;
    expect(decoded['method'], 'tick');
    expect(decoded['params'], <String, Object?>{'n': 1});
    expect(decoded.containsKey('id'), isFalse);
    expect(delayer.callCount, 0);
  });

  test('request ids are assigned incrementally from zero', () async {
    final first = channel.call('a');
    expect(sentId(transport.sent[0]), 0);

    transport.emit(jsonEncode(successPayload(0, 'x')));
    await first;

    final second = channel.call('b');
    expect(sentId(transport.sent[1]), 1);

    transport.emit(jsonEncode(successPayload(1, 'y')));
    await second;
  });
}

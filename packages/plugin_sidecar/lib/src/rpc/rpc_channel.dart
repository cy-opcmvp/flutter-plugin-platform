import 'dart:async';

import 'package:plugin_contracts/plugin_contracts.dart';

import 'rpc_message_codec.dart';

/// 受控延时注入点：所有超时经此触发；测试中受控推进，不真实等待。
typedef Delayer = Future<void> Function(Duration duration);

/// 通道与对端之间的传输抽象；帧编码/解码由实现负责。
abstract interface class RpcTransport {
  /// 发送一条 JSON payload；抛异常视为传输错误。
  void send(String payload);

  /// 已解码的帧 payload 流。
  Stream<String> get incoming;
}

/// 单次 RPC 调用的结果：远端成功时 [value] 为 result，失败时 [failure] 非空。
final class RpcCallResult {
  const RpcCallResult({this.value, this.failure});

  /// 远端 result。
  final Object? value;

  /// 失败原因：`rpc.timeout` / `rpc.remote_error` / `rpc.channel_closed`。
  final PluginFailure? failure;
}

/// 帧化 JSON-RPC 客户端通道。
///
/// - 每个请求注册 pending 表，以自增 int id 匹配响应，支持并发乱序。
/// - 请求超时后通道关闭（防止响应错配），该请求以 `rpc.timeout` 完成；
///   其余 pending 各自按结果收敛，超时引发的关闭不额外补发 failure 码。
/// - 取消请求 = [close]：所有 pending 以
///   `rpc.channel_closed(closedByCaller)` 完成。
final class RpcChannel {
  RpcChannel({
    required RpcTransport transport,
    required Delayer delayer,
    required this.requestTimeout,
  }) : _transport = transport,
       _delayer = delayer {
    _subscription = _transport.incoming.listen(
      _onIncoming,
      onError: (Object _) {
        _failAllPending(_closedFailure('transportError'));
        _close();
      },
    );
  }

  /// 单个请求的超时上限。
  final Duration requestTimeout;

  final RpcTransport _transport;
  final Delayer _delayer;

  final Map<int, Completer<RpcCallResult>> _pending =
      <int, Completer<RpcCallResult>>{};
  StreamSubscription<String>? _subscription;
  int _nextId = 0;
  bool _closed = false;

  /// 通道是否已关闭；关闭后不再发送，也不再消费 incoming。
  bool get isClosed => _closed;

  /// 发起一次 RPC 调用。
  ///
  /// 通道已关闭时立即以 `rpc.channel_closed(closedByCaller)` 完成。
  Future<RpcCallResult> call(String method, [Map<String, Object?>? params]) {
    if (_closed) {
      return Future<RpcCallResult>.value(
        RpcCallResult(failure: _closedFailure('closedByCaller')),
      );
    }
    final id = _nextId;
    _nextId += 1;
    final completer = Completer<RpcCallResult>();
    _pending[id] = completer;
    try {
      _transport.send(
        encodeRpcMessage(RpcRequest(id: id, method: method, params: params)),
      );
    } catch (_) {
      _failAllPending(_closedFailure('transportError'));
      _close();
    }
    // 超时竞速：delayer 先到期则本请求以 rpc.timeout 完成并关闭通道；
    // 响应先到时本回调在完成后直接返回。
    unawaited(
      _delayer(requestTimeout).then((_) {
        if (completer.isCompleted) {
          return;
        }
        completer.complete(RpcCallResult(failure: _timeoutFailure(method)));
        _pending.remove(id);
        _close();
      }),
    );
    return completer.future;
  }

  /// 发送通知；不注册 pending，不期待响应。
  void notify(String method, [Map<String, Object?>? params]) {
    if (_closed) {
      return;
    }
    try {
      _transport.send(
        encodeRpcMessage(RpcNotification(method: method, params: params)),
      );
    } catch (_) {
      _failAllPending(_closedFailure('transportError'));
      _close();
    }
  }

  /// 关闭通道：所有 pending 以 `rpc.channel_closed(closedByCaller)` 完成；
  /// 幂等。
  void close() {
    _failAllPending(_closedFailure('closedByCaller'));
    _close();
  }

  void _onIncoming(String payload) {
    if (_closed) {
      return;
    }
    final RpcMessage message;
    try {
      message = decodeRpcMessage(payload);
    } on FormatException catch (exception) {
      _failAllPending(
        PluginFailure(
          'rpc.message_invalid',
          exception.message,
          const <String, Object?>{},
        ),
      );
      _close();
      return;
    }
    switch (message) {
      case RpcSuccess():
        _resolvePending(message.id, RpcCallResult(value: message.result));
      case RpcError():
        _resolvePending(
          message.id,
          RpcCallResult(
            failure: PluginFailure(
              'rpc.remote_error',
              message.message,
              <String, Object?>{
                'code': message.code,
                'message': message.message,
                'data': message.data,
              },
            ),
          ),
        );
      case RpcRequest():
      case RpcNotification():
        // 协议违规：响应流上出现非响应消息。
        _failAllPending(
          PluginFailure(
            'rpc.message_invalid',
            'received a non-response message',
            const <String, Object?>{},
          ),
        );
        _close();
    }
  }

  /// 按 id 匹配 pending；无对应 pending 时视为协议错配，关闭通道。
  void _resolvePending(Object? id, RpcCallResult result) {
    final completer = _pending[id];
    if (completer == null) {
      _failAllPending(_closedFailure('unexpectedResponse'));
      _close();
      return;
    }
    _pending.remove(id);
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  /// 以给定 failure 完成所有 pending（已完成的跳过）并清空 pending 表。
  void _failAllPending(PluginFailure failure) {
    final pending = Map<int, Completer<RpcCallResult>>.of(_pending);
    _pending.clear();
    for (final completer in pending.values) {
      if (!completer.isCompleted) {
        completer.complete(RpcCallResult(failure: failure));
      }
    }
  }

  /// 统一关闭：置位、取消订阅；此后 [RpcTransport.send] 不再被调用。
  void _close() {
    if (_closed) {
      return;
    }
    _closed = true;
    _subscription?.cancel();
    _subscription = null;
  }

  PluginFailure _timeoutFailure(String method) {
    return PluginFailure('rpc.timeout', 'request timed out', {
      'methodName': method,
      'elapsedMs': requestTimeout.inMilliseconds,
    });
  }

  PluginFailure _closedFailure(String reason) {
    return PluginFailure('rpc.channel_closed', 'channel is closed', {
      'reason': reason,
    });
  }
}

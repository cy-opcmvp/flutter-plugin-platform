/// stdio 帧传输层：将 [SidecarProcess] 绑定为 [RpcTransport]。
///
/// 发送方向：[StdioRpcTransport.send] 先用 [encodeFrame] 把 payload 编码为
/// 4 字节大端长度前缀帧，再异步写入子进程 stdin；payload 超过帧上限时
/// 同步抛出 [RpcFrameException]。
/// 接收方向：子进程 stdout 的字节流经 [RpcFrameDecoder] 增量解码
/// （天然兼容半包与粘包），解出的 payload 依序投递到 [incoming]。
library;

import 'dart:async';

import '../rpc/rpc_channel.dart' show RpcTransport;
import '../rpc/rpc_frame_codec.dart';
import 'sidecar_process.dart';

/// 基于 [SidecarProcess] stdio 的帧传输层实现。
///
/// 错误约定：
/// - stdout 错误、帧协议违规（[RpcFrameException]）与 stdin 写入失败的
///   异步错误，均以 error 事件投递到 [incoming]，由 [RpcChannel] 统一
///   映射为 `rpc.channel_closed(transportError)`；
/// - stdout 关闭（子进程退出）后 [incoming] 随之完成。
///
/// 本类只依赖 [SidecarProcess] 抽象，不触碰平台进程 API，便于测试注入
/// 假进程，也便于宿主复用既有进程管理设施。
final class StdioRpcTransport implements RpcTransport {
  /// 创建绑定 [process] 的传输层。
  ///
  /// [maxFrameBytes] 同时约束发送编码与接收解码两侧。
  StdioRpcTransport(this._process, {int maxFrameBytes = defaultMaxFrameBytes})
    : _decoder = RpcFrameDecoder(maxFrameBytes: maxFrameBytes),
      _controller = StreamController<String>() {
    _subscription = _process.stdout.listen(
      _onStdoutBytes,
      onError: _propagateError,
      onDone: _onStdoutDone,
    );
  }

  final SidecarProcess _process;
  final RpcFrameDecoder _decoder;
  final StreamController<String> _controller;
  late final StreamSubscription<List<int>> _subscription;
  bool _closed = false;

  @override
  Stream<String> get incoming => _controller.stream;

  @override
  void send(String payload) {
    // 编码超限同步抛出，调用方（RpcChannel）可立即感知；
    // 写入异步进行，失败时转为 incoming 上的 error 事件。
    final frame = encodeFrame(payload, maxFrameBytes: _decoder.maxFrameBytes);
    unawaited(_process.writeStdin(frame).catchError(_propagateError));
  }

  /// 取消 stdout 订阅并关闭 [incoming]；幂等。
  ///
  /// 通道关闭后由宿主调用以回收传输层资源。close 的 done future
  /// 依赖监听者消费完成事件，这里不等待它，避免无人监听时挂起。
  Future<void> dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _subscription.cancel();
    _decoder.reset();
    unawaited(_controller.close());
  }

  void _onStdoutBytes(List<int> chunk) {
    try {
      _decoder.addBytes(chunk);
    } on RpcFrameException catch (error) {
      _propagateError(error);
      return;
    }
    // 无人监听时丢弃已解出的帧，避免关闭后无界堆积。
    if (!_controller.hasListener) {
      _decoder.drainFrames();
      return;
    }
    for (final payload in _decoder.drainFrames()) {
      _controller.add(payload);
    }
  }

  void _onStdoutDone() {
    if (_closed) {
      return;
    }
    _closed = true;
    _controller.close();
  }

  void _propagateError(Object error) {
    if (_closed || _controller.isClosed) {
      return;
    }
    _controller.addError(error);
  }
}

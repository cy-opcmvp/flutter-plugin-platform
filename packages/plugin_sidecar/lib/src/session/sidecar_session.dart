/// Sidecar 会话层：统一编排「进程 + 就绪 + 通道」。
///
/// 相较直接组合 [SidecarSupervisor] 与 [StdioRpcTransport]，会话在内部
/// 单订阅子进程 stdout，以增量帧解码消除广播摩擦：
/// - 就绪信号 = stdout 首字节；
/// - 首帧（就绪帧，夹具约定为 framed 纯字符串如 `"ready"`）由会话
///   吞掉，不进入 [RpcChannel]；
/// - 启动失败（超时/立即退出/帧协议违规/stdout 异常）时进程已回收，
///   统一报 `session.start_failed`，details.reason 透传底层原码。
library;

import 'dart:async';

import 'package:plugin_contracts/plugin_contracts.dart';

import '../process/sidecar_process.dart';
import '../process/sidecar_supervisor.dart';
import '../rpc/rpc_channel.dart' show Delayer, RpcChannel, RpcTransport;
import '../rpc/rpc_frame_codec.dart';

/// [SidecarSession.start] 的结果：成功时 [session] 非空且 [failure] 为空；
/// 失败时子进程已被回收（kill 已尽力执行）。
final class SessionStartResult {
  const SessionStartResult._({this.session, this.failure});

  /// 就绪的会话；启动失败时为 null。
  final SidecarSession? session;

  /// 失败原因：`session.start_failed`（details.reason 透传底层原码）。
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

/// 统一编排进程、就绪与通道的 sidecar 会话对象。
///
/// - [start] 内部单订阅 stdout：首字节即就绪，首帧（就绪帧）被吞掉不进
///   通道，其后数据直接投递给 [channel]；
/// - 就绪后 stdout 出错转为通道 error 事件；stdout 关闭（子进程退出）
///   会完成数据流，pending 请求由 `rpc.timeout` 兜底；
/// - 非主动 [stop] 成功引发的进程退出触发 `onUnexpectedExit`
///   （`process.unexpected_exit`，details 含 exitCode）；
/// - [stop] 关闭通道并停止进程（复用 [SidecarSupervisor.stop] 的
///   kill + 宽限竞速语义），幂等：重复调用返回首次结果。
final class SidecarSession {
  SidecarSession._({
    required SidecarProcess process,
    required StreamController<String> controller,
    required StreamSubscription<List<int>> subscription,
    required List<String> pendingPayloads,
    required SidecarProcessLauncher launcher,
    required Delayer delayer,
    required this.startupTimeout,
    required this.requestTimeout,
    required void Function(PluginFailure failure)? onUnexpectedExit,
    required void Function() onReady,
  }) : _process = process,
       _controller = controller,
       _subscription = subscription,
       _launcher = launcher,
       _delayer = delayer,
       _onUnexpectedExit = onUnexpectedExit {
    _transport = _SessionTransport(process, controller);
    _channel = RpcChannel(
      transport: _transport,
      delayer: delayer,
      requestTimeout: requestTimeout,
    );
    onReady();
    // 就绪前缓冲的 payload（就绪帧与响应同 chunk 抵达等场景）补投给通道。
    for (final payload in pendingPayloads) {
      _controller.add(payload);
    }
  }

  static final Object _readyToken = Object();
  static final Object _timeoutToken = Object();
  static final Object _brokenToken = Object();

  final SidecarProcess _process;
  final StreamController<String> _controller;
  final StreamSubscription<List<int>> _subscription;
  final SidecarProcessLauncher _launcher;
  final Delayer _delayer;
  final void Function(PluginFailure failure)? _onUnexpectedExit;

  /// 就绪判定超时上限（供 [stop] 复用监督器语义）。
  final Duration startupTimeout;

  /// 通道请求超时上限，透传给 [RpcChannel]。
  final Duration requestTimeout;

  late final _SessionTransport _transport;
  late final RpcChannel _channel;

  Future<StopResult>? _stopFuture;
  bool _stopInFlight = false;
  bool _stopCompleted = false;

  /// 退出落在 stop 窗口内时的暂存退出码，由 stop 结果裁决是否上报。
  int? _exitWhileStopping;

  /// 就绪后的 RPC 通道；仅当会话成功就绪后非空（stop 后仍可读其状态）。
  RpcChannel? get channel => _channel;

  /// 启动子进程并等待就绪，就绪后建立 [RpcChannel]。
  ///
  /// 就绪信号 = stdout 首字节；首帧（就绪帧，约定为纯字符串如
  /// `"ready"`）被会话吞掉，不进入通道。启动阶段的两阶段竞速共用同一
  /// deadline：先等首字节，再等首个完整帧（即就绪帧解出）。
  static Future<SessionStartResult> start({
    required SidecarProcessLauncher launcher,
    required SidecarSpawn spawn,
    required Delayer delayer,
    required Duration startupTimeout,
    required Duration requestTimeout,
    void Function(PluginFailure failure)? onUnexpectedExit,
  }) async {
    final SidecarProcess process;
    try {
      process = await launcher.start(spawn);
    } on Object {
      return SessionStartResult._(
        failure: PluginFailure(
          'session.start_failed',
          'failed to start sidecar session',
          {'reason': 'process.start_failed', 'detail': 'spawnError'},
        ),
      );
    }

    final decoder = RpcFrameDecoder();
    final controller = StreamController<String>();
    final broken = Completer<PluginFailure>();
    final firstByte = Completer<void>();
    final firstFrame = Completer<void>();
    final pendingPayloads = <String>[];
    var readyFrameSwallowed = false;
    var channelReady = false;
    var startupSettled = false;
    var recycled = false;
    late final StreamSubscription<List<int>> stdoutSubscription;

    // 回收进程与启动期资源；幂等。
    Future<void> recycle() async {
      if (recycled) {
        return;
      }
      recycled = true;
      await stdoutSubscription.cancel();
      try {
        await process.kill();
      } on Object {
        // 回收失败不掩盖启动失败原因。
      }
      unawaited(controller.close());
    }

    // 启动失败：立即记账并回收进程，竞速方经 broken.future 读取原因。
    void breakStartup(PluginFailure failure) {
      if (startupSettled) {
        return;
      }
      startupSettled = true;
      if (!broken.isCompleted) {
        broken.complete(failure);
      }
      unawaited(recycle());
    }

    Future<SessionStartResult> settleFailure(PluginFailure failure) async {
      startupSettled = true;
      await recycle();
      return SessionStartResult._(failure: failure);
    }

    // 单阶段竞速：阶段完成 / 进程退出 / deadline / 帧协议违规。
    // 分支判定顺序：超时 → 帧违规 → 退出 → 就绪（首帧与违规可能在同一
    // 回调内完成，broken 已完成时优先报告违规）。
    Future<PluginFailure?> awaitPhase(Future<void> phase) async {
      final deadline = delayer(startupTimeout);
      final winner = await Future.any<Object?>(<Future<Object?>>[
        phase.then<Object?>((_) => _readyToken),
        process.exitCode.then<Object?>((int code) => code),
        deadline.then<Object?>((_) => _timeoutToken),
        broken.future.then<Object?>((_) => _brokenToken),
      ]);
      if (identical(winner, _timeoutToken)) {
        return PluginFailure(
          'session.start_failed',
          'sidecar did not signal readiness in time',
          {'reason': 'process.start_timeout'},
        );
      }
      if (broken.isCompleted) {
        return broken.future;
      }
      if (winner is int) {
        return PluginFailure(
          'session.start_failed',
          'sidecar exited during startup',
          {'reason': 'process.start_failed', 'exitCode': winner},
        );
      }
      return null;
    }

    void onBytes(List<int> chunk) {
      // 首字节即就绪信号（协议无关弱信号，与监督器语义一致）。
      if (!firstByte.isCompleted) {
        firstByte.complete();
      }
      try {
        decoder.addBytes(chunk);
      } on RpcFrameException {
        breakStartup(
          PluginFailure(
            'session.start_failed',
            'sidecar violated the frame protocol during startup',
            {'reason': 'rpc.frame_invalid'},
          ),
        );
        return;
      }
      for (final payload in decoder.drainFrames()) {
        if (!readyFrameSwallowed) {
          // 首帧为就绪帧（约定纯字符串），由会话吞掉，不进入通道。
          readyFrameSwallowed = true;
          if (!firstFrame.isCompleted) {
            firstFrame.complete();
          }
          continue;
        }
        if (channelReady) {
          _controllerAdd(controller, payload);
        } else {
          pendingPayloads.add(payload);
        }
      }
    }

    void onStdoutError(Object error) {
      if (channelReady) {
        _controllerAddError(controller, error);
        return;
      }
      breakStartup(
        PluginFailure(
          'session.start_failed',
          'sidecar stdout failed during startup',
          {'reason': 'process.start_failed', 'detail': 'stdoutError'},
        ),
      );
    }

    void onStdoutDone() {
      if (channelReady) {
        // 数据流完成；通道 pending 由 rpc.timeout 兜底，通道不自动关闭。
        if (!controller.isClosed) {
          unawaited(controller.close());
        }
        return;
      }
      if (startupSettled) {
        return;
      }
      breakStartup(
        PluginFailure(
          'session.start_failed',
          'sidecar stdout closed during startup',
          {'reason': 'process.start_failed', 'detail': 'stdoutClosed'},
        ),
      );
    }

    stdoutSubscription = process.stdout.listen(
      onBytes,
      onError: onStdoutError,
      onDone: onStdoutDone,
    );

    var phaseFailure = await awaitPhase(firstByte.future);
    phaseFailure ??= await awaitPhase(firstFrame.future);
    if (phaseFailure != null) {
      return settleFailure(phaseFailure);
    }

    final session = SidecarSession._(
      process: process,
      controller: controller,
      subscription: stdoutSubscription,
      pendingPayloads: pendingPayloads,
      launcher: launcher,
      delayer: delayer,
      startupTimeout: startupTimeout,
      requestTimeout: requestTimeout,
      onUnexpectedExit: onUnexpectedExit,
      onReady: () {
        startupSettled = true;
        channelReady = true;
      },
    );

    // 就绪后挂接退出监听：stop 成功引发的退出不算意外（见 _onProcessExit）。
    unawaited(process.exitCode.then(session._onProcessExit));
    return SessionStartResult._(session: session);
  }

  /// 停止会话：关闭通道并停止子进程（宽限 5s）。
  ///
  /// 幂等：重复调用返回首次调用的结果。
  Future<StopResult> stop() {
    return _stopFuture ??= _performStop();
  }

  Future<StopResult> _performStop() async {
    _stopInFlight = true;
    try {
      _channel.close();
      await _subscription.cancel();
      unawaited(_controller.close());
      // 复用监督器 stop 的 kill + 宽限竞速语义（StopResult 为私有构造）。
      final supervisor = SidecarSupervisor(
        launcher: _launcher,
        delayer: _delayer,
        startupTimeout: startupTimeout,
      );
      final result = await supervisor.stop(_process);
      if (result.succeeded) {
        _stopCompleted = true;
      } else {
        // 退出落在失败窗口内：kill 未能结束进程，退出仍视为意外。
        final pendingExit = _exitWhileStopping;
        if (pendingExit != null) {
          _emitUnexpectedExit(pendingExit);
        }
      }
      return result;
    } finally {
      _stopInFlight = false;
    }
  }

  /// 进程退出监听入口（start 成功后注册一次）。
  ///
  /// stop 成功引发的退出不算意外；退出落在 stop 窗口内时暂存退出码，
  /// 由 [stop] 的最终结果裁决（成功 → 丢弃，失败 → 补报意外）。
  void _onProcessExit(int exitCode) {
    if (_stopCompleted) {
      return;
    }
    if (_stopInFlight) {
      _exitWhileStopping = exitCode;
      return;
    }
    _emitUnexpectedExit(exitCode);
  }

  void _emitUnexpectedExit(int exitCode) {
    _onUnexpectedExit?.call(
      PluginFailure('process.unexpected_exit', 'sidecar exited unexpectedly', {
        'exitCode': exitCode,
      }),
    );
  }
}

/// 会话内部传输层：把 [SidecarProcess] 的 stdin 绑定为发送方向，
/// 接收方向复用会话持有的 stdout 数据控制器。
final class _SessionTransport implements RpcTransport {
  _SessionTransport(this._process, this._controller);

  final SidecarProcess _process;
  final StreamController<String> _controller;

  @override
  Stream<String> get incoming => _controller.stream;

  @override
  void send(String payload) {
    final frame = encodeFrame(payload);
    unawaited(_process.writeStdin(frame).catchError(_onWriteError));
  }

  // stdin 写入失败转为 incoming 上的 error，由通道映射为 transportError。
  void _onWriteError(Object error) {
    if (_controller.isClosed) {
      return;
    }
    _controller.addError(error);
  }
}

/// 控制器已关闭时静默丢弃（stdout 关闭与错误事件竞态的兜底）。
void _controllerAdd(StreamController<String> controller, String payload) {
  if (controller.isClosed) {
    return;
  }
  controller.add(payload);
}

/// 控制器已关闭时静默丢弃错误事件。
void _controllerAddError(StreamController<String> controller, Object error) {
  if (controller.isClosed) {
    return;
  }
  controller.addError(error);
}

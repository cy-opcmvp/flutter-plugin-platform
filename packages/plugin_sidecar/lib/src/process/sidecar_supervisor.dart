import 'dart:async';

import 'package:plugin_contracts/plugin_contracts.dart';

import '../rpc/rpc_channel.dart' show Delayer;
import 'sidecar_process.dart';

/// [SidecarSupervisor.start] 的结果：成功时 [process] 非空且 [failure] 为空。
final class SupervisedStartResult {
  const SupervisedStartResult._({this.process, this.failure});

  /// 就绪的子进程；启动失败（spawnError）时为 null，其余失败场景仍返回
  /// 进程句柄以便观察。
  final SidecarProcess? process;

  /// 失败原因：`process.start_failed` / `process.start_timeout`。
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

/// [SidecarSupervisor.stop] 的结果：优雅退出时 [failure] 为空。
final class StopResult {
  const StopResult._({this.failure});

  /// 失败原因：`process.stop_timeout`。
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

/// 子进程监督器：以 stdout 首字节为就绪信号管理启动、停止与意外退出。
///
/// - [start] 以 `Future.any` 竞速 stdout 首字节 / exitCode /
///   startupTimeout；超时分支会 kill 进程。
/// - [stop] 为 kill 后竞速 exitCode 与 stopGracePeriod（默认 5s）。
/// - 就绪后进程退出（非 [stop] 引发）触发 `onUnexpectedExit`
///   （`process.unexpected_exit`，details 含 exitCode）。
/// - 所有超时经注入 [Delayer] 触发，测试可受控推进。
final class SidecarSupervisor {
  SidecarSupervisor({
    required SidecarProcessLauncher launcher,
    required Delayer delayer,
    required this.startupTimeout,
    this.stopGracePeriod = const Duration(seconds: 5),
  }) : _launcher = launcher,
       _delayer = delayer;

  /// 就绪判定超时上限。
  final Duration startupTimeout;

  /// 优雅停止的宽限期上限。
  final Duration stopGracePeriod;

  final SidecarProcessLauncher _launcher;
  final Delayer _delayer;

  final Set<SidecarProcess> _alive = <SidecarProcess>{};
  final Set<SidecarProcess> _stopping = <SidecarProcess>{};

  static final Object _readyToken = Object();
  static final Object _startupTimeoutToken = Object();
  static final Object _stopTimeoutToken = Object();

  /// 是否仍有存活（已就绪且未退出）的受监督进程。
  bool get hasAlive => _alive.isNotEmpty;

  /// 启动并等待就绪。
  ///
  /// 就绪信号 = stdout 首字节（协议无关弱信号）。
  Future<SupervisedStartResult> start(
    SidecarSpawn spawn, {
    void Function(PluginFailure failure)? onUnexpectedExit,
  }) async {
    final SidecarProcess process;
    try {
      process = await _launcher.start(spawn);
    } catch (_) {
      return SupervisedStartResult._(
        failure: PluginFailure(
          'process.start_failed',
          'failed to spawn sidecar process',
          {'reason': 'spawnError'},
        ),
      );
    }

    // stdout 关闭/出错（无字节）时按收到事件处理：exitCode 竞速与
    // 意外退出回调仍会如实报告进程状态。
    final ready = process.stdout.first.catchError((Object _) => const <int>[]);
    final winner = await Future.any<Object?>(<Future<Object?>>[
      ready.then<Object>((_) => _readyToken),
      process.exitCode,
      _delayer(startupTimeout).then<Object>((_) => _startupTimeoutToken),
    ]);

    if (identical(winner, _startupTimeoutToken)) {
      try {
        await process.kill();
      } catch (_) {
        // kill 失败无法恢复；仍以 start_timeout 报告。
      }
      return SupervisedStartResult._(
        process: process,
        failure: PluginFailure(
          'process.start_timeout',
          'sidecar did not signal readiness in time',
          const <String, Object?>{},
        ),
      );
    }
    if (winner is int) {
      // 启动即退出：属启动失败，不触发 onUnexpectedExit。
      return SupervisedStartResult._(
        process: process,
        failure: PluginFailure(
          'process.start_failed',
          'sidecar exited during startup',
          {'reason': 'exited', 'exitCode': winner},
        ),
      );
    }

    _alive.add(process);
    _attachExitWatcher(process, onUnexpectedExit);
    return SupervisedStartResult._(process: process);
  }

  /// 停止进程：kill 后等待退出，宽限期内未退出则报 `process.stop_timeout`。
  Future<StopResult> stop(SidecarProcess process) async {
    _stopping.add(process);
    try {
      await process.kill();
    } catch (_) {
      // kill 失败 ≈ 无法保证退出，按超时语义报告。
      return StopResult._(
        failure: PluginFailure(
          'process.stop_timeout',
          'failed to stop the sidecar process',
          const <String, Object?>{},
        ),
      );
    }
    final winner = await Future.any<Object?>(<Future<Object?>>[
      process.exitCode,
      _delayer(stopGracePeriod).then<Object>((_) => _stopTimeoutToken),
    ]);
    if (identical(winner, _stopTimeoutToken)) {
      return StopResult._(
        failure: PluginFailure(
          'process.stop_timeout',
          'sidecar did not exit within the grace period',
          const <String, Object?>{},
        ),
      );
    }
    _alive.remove(process);
    _stopping.remove(process);
    return const StopResult._();
  }

  /// 停止所有存活进程（逆序），幂等。
  Future<void> disposeAll() async {
    for (final process in List<SidecarProcess>.of(_alive).reversed) {
      await stop(process);
    }
  }

  /// 就绪后挂接退出监听：退出时移出存活表；非 stop 引发的退出视为意外。
  void _attachExitWatcher(
    SidecarProcess process,
    void Function(PluginFailure failure)? onUnexpectedExit,
  ) {
    unawaited(
      process.exitCode.then((exitCode) {
        _alive.remove(process);
        if (_stopping.remove(process)) {
          return; // 主动 stop 的退出不算意外。
        }
        onUnexpectedExit?.call(
          PluginFailure(
            'process.unexpected_exit',
            'sidecar exited unexpectedly',
            {'exitCode': exitCode},
          ),
        );
      }),
    );
  }
}

/// Sidecar 会话工厂的 io 实现：Python 解释器探测 + 真实进程会话。
///
/// 探测候选与 M2 e2e 同法：依次尝试 `python`、`python3`、`py -3`，
/// 以 `--version` 退出码判定可用性；样本协议零 pip 依赖，任意 Python 3
/// 解释器即可运行。
library;

import 'dart:io';

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';

import 'sidecar_command_bridge.dart';

/// Python 解释器探测候选（可执行名, 参数前缀）。
const List<(String, List<String>)> kPythonProbeCandidates =
    <(String, List<String>)>[
      ('python', <String>[]),
      ('python3', <String>[]),
      ('py', <String>['-3']),
    ];

/// 依次探测候选解释器；全部不可用时返回 null。
(String, List<String>)? probePythonCommand() {
  for (final (String, List<String>) candidate in kPythonProbeCandidates) {
    try {
      final ProcessResult result = Process.runSync(candidate.$1, <String>[
        ...candidate.$2,
        '--version',
      ]);
      if (result.exitCode == 0) {
        return candidate;
      }
    } on Object {
      // 候选不可执行（不存在/权限不足），继续探测下一个。
    }
  }
  return null;
}

/// 包内 `SidecarSession` 的句柄适配器。
final class LiveSidecarSessionHandle implements SidecarSessionHandle {
  /// 包装一个已就绪的真实会话。
  const LiveSidecarSessionHandle(this._session);

  final SidecarSession _session;

  @override
  RpcChannel? get channel => _session.channel;

  @override
  Future<PluginFailure?> stop() async {
    final StopResult result = await _session.stop();
    return result.failure;
  }
}

/// 创建真实会话工厂：探测解释器后启动 hash_tool 脚本并等待就绪。
SidecarSessionFactory createHashToolSessionFactory() {
  return (String scriptPath) async {
    final (String, List<String>)? command = probePythonCommand();
    if (command == null) {
      throw SidecarSessionFactoryException(
        PluginFailure('session.start_failed', 'python interpreter not found', {
          'reason': 'pythonNotFound',
        }),
      );
    }
    final SessionStartResult result = await SidecarSession.start(
      launcher: IoProcessLauncher(),
      delayer: (Duration duration) => Future<void>.delayed(duration),
      spawn: SidecarSpawn(
        executable: command.$1,
        arguments: <String>[...command.$2, scriptPath],
      ),
      startupTimeout: const Duration(seconds: 15),
      requestTimeout: const Duration(seconds: 5),
    );
    if (!result.succeeded || result.session == null) {
      throw SidecarSessionFactoryException(
        result.failure ??
            PluginFailure(
              'session.start_failed',
              'sidecar session failed to start',
              {'reason': 'unknown'},
            ),
      );
    }
    return LiveSidecarSessionHandle(result.session!);
  };
}

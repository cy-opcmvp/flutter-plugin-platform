import 'dart:io';

import 'sidecar_process.dart';

/// [SidecarProcessLauncher] 的 `dart:io` 适配实现。
///
/// 本文件是包内仅有的两处 `dart:io` 使用点之一（另一处为包文件系统适配）。
final class IoProcessLauncher implements SidecarProcessLauncher {
  const IoProcessLauncher();

  @override
  Future<SidecarProcess> start(SidecarSpawn spawn) async {
    final process = await Process.start(
      spawn.executable,
      spawn.arguments,
      workingDirectory: spawn.workingDirectory,
    );
    return _IoSidecarProcess(process);
  }
}

/// [Process] 到 [SidecarProcess] 的最小映射。
final class _IoSidecarProcess implements SidecarProcess {
  _IoSidecarProcess(this._process);

  final Process _process;

  @override
  Stream<List<int>> get stdout => _process.stdout;

  @override
  Stream<List<int>> get stderr => _process.stderr;

  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> kill() async {
    // 默认信号；Windows 上等价 TerminateProcess。
    _process.kill();
  }

  @override
  Future<void> writeStdin(List<int> bytes) async {
    _process.stdin.add(bytes);
    await _process.stdin.flush();
  }

  @override
  Future<void> closeStdin() async {
    await _process.stdin.close();
  }
}

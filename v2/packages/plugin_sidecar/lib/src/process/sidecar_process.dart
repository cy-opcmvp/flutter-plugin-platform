/// 子进程抽象：spawn 描述、进程句柄接口与启动器接口。
///
/// 主机可替换为自定义实现（如复用既有进程管理设施）；默认适配实现见
/// [IoProcessLauncher]。
library;

/// 一次子进程启动的描述。
final class SidecarSpawn {
  const SidecarSpawn({
    required this.executable,
    this.arguments = const [],
    this.workingDirectory,
  });

  /// 可执行文件路径。
  final String executable;

  /// 传给可执行文件的参数列表。
  final List<String> arguments;

  /// 工作目录；null 表示继承宿主进程的当前目录。
  final String? workingDirectory;
}

/// 已启动子进程的最小句柄抽象。
abstract interface class SidecarProcess {
  /// 标准输出字节流（就绪信号、RPC 帧均从此读取）。
  Stream<List<int>> get stdout;

  /// 标准错误字节流。
  Stream<List<int>> get stderr;

  /// 进程退出码；进程退出后完成。
  Future<int> get exitCode;

  /// 请求终止进程（默认信号；Windows 上等价强制终止）。
  Future<void> kill();

  /// 向 stdin 写入字节（RPC 通道写帧用）。
  Future<void> writeStdin(List<int> bytes);

  /// 关闭 stdin（通道关闭时回收写端）。
  Future<void> closeStdin();
}

/// 子进程启动器抽象。
abstract interface class SidecarProcessLauncher {
  Future<SidecarProcess> start(SidecarSpawn spawn);
}

import 'dart:typed_data';

import 'package:plugin_contracts/plugin_contracts.dart';

import 'install_state_machine.dart';
import 'package_reader.dart';

/// 安装器所需的文件系统操作抽象；测试以 fake 注入。
abstract interface class PackageFileSystem {
  /// 创建目录；`recursive` 时逐级创建已存在父目录不报错。
  Future<void> createDir(String path, {bool recursive = true});

  /// 路径（文件或目录）是否存在。
  Future<bool> exists(String path);

  /// 写入文件字节（含必要的父目录创建）。
  Future<void> writeFile(String path, List<int> bytes);

  /// 递归删除；不存在时为 no-op。
  Future<void> deleteTree(String path);

  /// 原子重命名目录。
  Future<void> renameDir(String from, String to);
}

/// 安装/卸载单次操作的结果。
final class InstallOutcome {
  const InstallOutcome._({required this.state, this.failure});

  /// 操作完成后的状态机状态。
  final SidecarInstallState state;

  /// 失败原因；成功时为 null。
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

/// 原子安装/卸载编排器。
///
/// 目录名只来自已验证的 [PluginId.value]，无其他字符串拼接进入路径。
/// 安装以「`<id>.staging` → `<id>` 单次 rename」为提交点；卸载先 rename 到
/// `<id>.trash-N`（N 递增防撞）再做 best-effort 删除。
final class SidecarInstaller {
  SidecarInstaller({required this.fs, required this.rootDir});

  final PackageFileSystem fs;

  /// 安装根目录；最终目录为 `<rootDir>/<pluginId>`。
  final String rootDir;

  final Map<String, InstallStateMachine> _machines =
      <String, InstallStateMachine>{};

  InstallStateMachine _machineFor(PluginId pluginId) {
    return _machines.putIfAbsent(
      pluginId.value,
      () => InstallStateMachine(pluginId),
    );
  }

  String _finalDir(PluginId pluginId) => '$rootDir/${pluginId.value}';

  String _stagingDir(PluginId pluginId) => '$rootDir/${pluginId.value}.staging';

  /// 安装已解析的包。
  Future<InstallOutcome> install(SidecarPackage package) async {
    final pluginId = package.manifest.id;
    final finalDir = _finalDir(pluginId);
    final stagingDir = _stagingDir(pluginId);
    final machine = _machineFor(pluginId);

    if (await fs.exists(finalDir)) {
      // 已安装：拒绝重复安装，且不得触碰既有安装（先清 staging）。
      await _deleteQuietly(stagingDir);
      return InstallOutcome._(
        state: machine.state,
        failure: _installFailure('alreadyInstalled', pluginId),
      );
    }
    _syncMachineDown(machine);
    final transition = machine.transitionTo(SidecarInstallState.installing);
    if (!transition.succeeded) {
      return InstallOutcome._(
        state: transition.state,
        failure: transition.failure,
      );
    }

    // 暂存解包：任何写入异常 → 清 staging → stagingFailed → 回退。
    try {
      await fs.createDir(rootDir);
      await fs.deleteTree(stagingDir);
      for (final entry in package.entries) {
        await fs.writeFile('$stagingDir/${entry.path}', entry.bytes);
      }
    } catch (_) {
      await _deleteQuietly(stagingDir);
      machine.transitionTo(SidecarInstallState.notInstalled);
      return InstallOutcome._(
        state: machine.state,
        failure: _installFailure('stagingFailed', pluginId),
      );
    }

    // 原子提交点：staging → final 单次 rename。
    try {
      await fs.renameDir(stagingDir, finalDir);
    } catch (_) {
      await _deleteQuietly(stagingDir);
      machine.transitionTo(SidecarInstallState.notInstalled);
      return InstallOutcome._(
        state: machine.state,
        failure: _installFailure('commitFailed', pluginId),
      );
    }

    machine.transitionTo(SidecarInstallState.installed);
    return InstallOutcome._(state: machine.state);
  }

  /// 便捷入口：内部 `PackageReader.fromBytes` 解析后安装。
  ///
  /// 容器解析失败以 [PackageException] 抛出（不折叠为 [InstallOutcome]）。
  Future<InstallOutcome> installBytes(Uint8List packageBytes) async {
    final package = PackageReader.fromBytes(packageBytes).read();
    return install(package);
  }

  /// 卸载已安装的插件。
  Future<InstallOutcome> uninstall(PluginId pluginId) async {
    final finalDir = _finalDir(pluginId);
    final machine = _machineFor(pluginId);

    if (!await fs.exists(finalDir)) {
      _syncMachineDown(machine);
      return InstallOutcome._(
        state: SidecarInstallState.notInstalled,
        failure: _uninstallFailure('notInstalled', pluginId),
      );
    }
    // 宿主重启后状态机可能落后于磁盘真值：补齐认知再走合法链。
    if (machine.state == SidecarInstallState.notInstalled) {
      machine.transitionTo(SidecarInstallState.installing);
      machine.transitionTo(SidecarInstallState.installed);
    }
    final transition = machine.transitionTo(SidecarInstallState.uninstalling);
    if (!transition.succeeded) {
      return InstallOutcome._(
        state: transition.state,
        failure: transition.failure,
      );
    }

    // rename 落点 trash-N 递增探测，避开历史残留。
    var sequence = 0;
    var trashDir = '';
    do {
      sequence += 1;
      trashDir = '$finalDir.trash-$sequence';
    } while (await fs.exists(trashDir));

    try {
      await fs.renameDir(finalDir, trashDir);
    } catch (_) {
      machine.transitionTo(SidecarInstallState.installed);
      return InstallOutcome._(
        state: machine.state,
        failure: _uninstallFailure('renameFailed', pluginId),
      );
    }

    // 删除为 best-effort：失败时残留 trash 目录，由下次卸载的递增落点绕开。
    try {
      await fs.deleteTree(trashDir);
    } catch (_) {}

    machine.transitionTo(SidecarInstallState.notInstalled);
    return InstallOutcome._(state: machine.state);
  }

  /// 最终安装目录是否存在于磁盘。
  Future<bool> isInstalled(PluginId pluginId) {
    return fs.exists(_finalDir(pluginId));
  }

  /// 磁盘上目录已消失但状态机仍认为 installed 时，补齐为 notInstalled。
  void _syncMachineDown(InstallStateMachine machine) {
    if (machine.state == SidecarInstallState.installed) {
      machine.transitionTo(SidecarInstallState.uninstalling);
      machine.transitionTo(SidecarInstallState.notInstalled);
    }
  }

  PluginFailure _installFailure(String reason, PluginId pluginId) {
    return PluginFailure('sidecar.install_failed', 'Install failed.', {
      'reason': reason,
      'pluginId': pluginId.value,
    });
  }

  PluginFailure _uninstallFailure(String reason, PluginId pluginId) {
    return PluginFailure('sidecar.uninstall_failed', 'Uninstall failed.', {
      'reason': reason,
      'pluginId': pluginId.value,
    });
  }

  /// best-effort 清理：失败时静默忽略。
  Future<void> _deleteQuietly(String path) async {
    try {
      await fs.deleteTree(path);
    } catch (_) {}
  }
}

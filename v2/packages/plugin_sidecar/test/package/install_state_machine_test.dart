// 覆盖场景清单：
// 1. 合法链 notInstalled→installing→installed→uninstalling→notInstalled 全链
//    成功，最终状态一致。
// 2. 失败回退 installing→notInstalled 与 uninstalling→installed 合法。
// 3. 非法转换 notInstalled→installed、installed→installing、
//    notInstalled→uninstalling：返回结构化 failure
//    （sidecar.install_state.invalid_transition，details 含 pluginId/from/to），
//    且状态保持不变。
// 4. 安装状态机无终态：回到 notInstalled 后可再次 installing。
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_sidecar/plugin_sidecar.dart';
import 'package:test/test.dart';

void main() {
  final pluginId = PluginId.parse('dev.example.echo');

  /// 驱动一个新状态机到目标状态。
  InstallStateMachine machineAt(SidecarInstallState target) {
    final machine = InstallStateMachine(pluginId);
    if (target != SidecarInstallState.notInstalled) {
      machine.transitionTo(SidecarInstallState.installing);
    }
    if (target == SidecarInstallState.installed ||
        target == SidecarInstallState.uninstalling) {
      machine.transitionTo(SidecarInstallState.installed);
    }
    if (target == SidecarInstallState.uninstalling) {
      machine.transitionTo(SidecarInstallState.uninstalling);
    }
    return machine;
  }

  group('InstallStateMachine', () {
    test('legal chain walks the full install lifecycle', () {
      final machine = InstallStateMachine(pluginId);
      expect(machine.state, SidecarInstallState.notInstalled);

      expect(
        machine.transitionTo(SidecarInstallState.installing).succeeded,
        isTrue,
      );
      expect(machine.state, SidecarInstallState.installing);
      expect(
        machine.transitionTo(SidecarInstallState.installed).succeeded,
        isTrue,
      );
      expect(machine.state, SidecarInstallState.installed);
      expect(
        machine.transitionTo(SidecarInstallState.uninstalling).succeeded,
        isTrue,
      );
      expect(machine.state, SidecarInstallState.uninstalling);

      final back = machine.transitionTo(SidecarInstallState.notInstalled);
      expect(back.succeeded, isTrue);
      expect(machine.state, SidecarInstallState.notInstalled);
    });

    test('failure rollback transitions are legal', () {
      final installing = machineAt(SidecarInstallState.installing);
      final rolledBack = installing.transitionTo(
        SidecarInstallState.notInstalled,
      );
      expect(rolledBack.succeeded, isTrue);
      expect(installing.state, SidecarInstallState.notInstalled);

      final uninstalling = machineAt(SidecarInstallState.uninstalling);
      final restored = uninstalling.transitionTo(SidecarInstallState.installed);
      expect(restored.succeeded, isTrue);
      expect(uninstalling.state, SidecarInstallState.installed);
    });

    test('illegal transitions return structured failure and keep state', () {
      final cases = <(SidecarInstallState, SidecarInstallState)>[
        (SidecarInstallState.notInstalled, SidecarInstallState.installed),
        (SidecarInstallState.installed, SidecarInstallState.installing),
        (SidecarInstallState.notInstalled, SidecarInstallState.uninstalling),
      ];
      for (final (from, to) in cases) {
        final machine = machineAt(from);
        final result = machine.transitionTo(to);

        expect(result.succeeded, isFalse, reason: '$from -> $to');
        expect(
          result.failure?.code,
          'sidecar.install_state.invalid_transition',
          reason: '$from -> $to',
        );
        expect(result.failure?.details['pluginId'], 'dev.example.echo');
        expect(
          result.failure?.details['from'],
          from.name,
          reason: '$from -> $to',
        );
        expect(result.failure?.details['to'], to.name, reason: '$from -> $to');
        expect(result.previousState, from, reason: '$from -> $to');
        expect(result.requestedState, to, reason: '$from -> $to');
        expect(machine.state, from, reason: '$from -> $to must keep state');
        expect(result.state, from, reason: '$from -> $to');
      }
    });

    test('no terminal state: reinstall is possible after uninstall', () {
      final machine = InstallStateMachine(pluginId);
      machine.transitionTo(SidecarInstallState.installing);
      machine.transitionTo(SidecarInstallState.installed);
      machine.transitionTo(SidecarInstallState.uninstalling);
      machine.transitionTo(SidecarInstallState.notInstalled);

      expect(
        machine.transitionTo(SidecarInstallState.installing).succeeded,
        isTrue,
      );
    });
  });
}

import 'package:plugin_contracts/plugin_contracts.dart';

/// 安装生命周期状态。
enum SidecarInstallState { notInstalled, installing, installed, uninstalling }

/// 安装状态机：维护单个插件的安装/卸载状态转换。
///
/// 合法转换：
/// - `notInstalled → installing → installed → uninstalling → notInstalled`
/// - 失败回退：`installing → notInstalled`、`uninstalling → installed`
///
/// 其余转换均非法，返回 code 为 `sidecar.install_state.invalid_transition`
/// 的结构化 [PluginFailure]，且状态保持不变。安装状态机没有终态：
/// 回到 notInstalled 后可以再次安装。
final class InstallStateMachine {
  InstallStateMachine(this.pluginId);

  final PluginId pluginId;

  SidecarInstallState _state = SidecarInstallState.notInstalled;

  SidecarInstallState get state => _state;

  /// 请求状态转换；非法时返回结构化 failure 且状态不变。
  InstallTransitionResult transitionTo(SidecarInstallState requestedState) {
    final previousState = _state;
    if (!_isAllowed(previousState, requestedState)) {
      return InstallTransitionResult._(
        previousState: previousState,
        requestedState: requestedState,
        state: previousState,
        failure: PluginFailure(
          'sidecar.install_state.invalid_transition',
          'Requested install transition is not allowed.',
          <String, Object?>{
            'pluginId': pluginId.value,
            'from': previousState.name,
            'to': requestedState.name,
          },
        ),
      );
    }
    _state = requestedState;
    return InstallTransitionResult._(
      previousState: previousState,
      requestedState: requestedState,
      state: requestedState,
    );
  }

  static bool _isAllowed(
    SidecarInstallState previousState,
    SidecarInstallState requestedState,
  ) => switch ((previousState, requestedState)) {
    (SidecarInstallState.notInstalled, SidecarInstallState.installing) => true,
    (SidecarInstallState.installing, SidecarInstallState.installed) => true,
    (SidecarInstallState.installing, SidecarInstallState.notInstalled) => true,
    (SidecarInstallState.installed, SidecarInstallState.uninstalling) => true,
    (SidecarInstallState.uninstalling, SidecarInstallState.notInstalled) =>
      true,
    (SidecarInstallState.uninstalling, SidecarInstallState.installed) => true,
    _ => false,
  };
}

/// 单次状态转换的结果。
final class InstallTransitionResult {
  InstallTransitionResult._({
    required this.previousState,
    required this.requestedState,
    required this.state,
    this.failure,
  });

  /// 转换前的状态。
  final SidecarInstallState previousState;

  /// 请求的目标状态。
  final SidecarInstallState requestedState;

  /// 转换后的实际状态（非法转换时等于 [previousState]）。
  final SidecarInstallState state;

  /// 非法转换时的结构化失败；合法转换时为 null。
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

import 'package:plugin_contracts/plugin_contracts.dart';

final class LifecycleMachine {
  LifecycleMachine(this.pluginId);

  final PluginId pluginId;

  PluginLifecycleState _state = PluginLifecycleState.discovered;

  PluginLifecycleState get state => _state;

  LifecycleTransitionResult transitionTo(PluginLifecycleState requestedState) {
    final previousState = _state;
    if (!_isAllowed(previousState, requestedState)) {
      return LifecycleTransitionResult._(
        previousState: previousState,
        requestedState: requestedState,
        state: previousState,
        failure: PluginFailure(
          'lifecycle.invalid_transition',
          'Requested lifecycle transition is not allowed.',
          <String, Object?>{
            'pluginId': pluginId.value,
            'from': previousState.name,
            'to': requestedState.name,
          },
        ),
      );
    }

    _state = requestedState;
    return LifecycleTransitionResult._(
      previousState: previousState,
      requestedState: requestedState,
      state: requestedState,
    );
  }

  static bool _isAllowed(
    PluginLifecycleState previousState,
    PluginLifecycleState requestedState,
  ) => switch ((previousState, requestedState)) {
    (PluginLifecycleState.discovered, PluginLifecycleState.resolved) => true,
    (PluginLifecycleState.resolved, PluginLifecycleState.inactive) => true,
    (PluginLifecycleState.inactive, PluginLifecycleState.activating) => true,
    (PluginLifecycleState.activating, PluginLifecycleState.active) => true,
    (PluginLifecycleState.active, PluginLifecycleState.deactivating) => true,
    (PluginLifecycleState.deactivating, PluginLifecycleState.inactive) => true,
    (PluginLifecycleState.inactive, PluginLifecycleState.disposed) => true,
    (PluginLifecycleState.failed, PluginLifecycleState.disposed) => true,
    (PluginLifecycleState.resolved, PluginLifecycleState.failed) => true,
    (PluginLifecycleState.inactive, PluginLifecycleState.failed) => true,
    (PluginLifecycleState.activating, PluginLifecycleState.failed) => true,
    (PluginLifecycleState.active, PluginLifecycleState.failed) => true,
    (PluginLifecycleState.deactivating, PluginLifecycleState.failed) => true,
    _ => false,
  };
}

final class LifecycleTransitionResult {
  LifecycleTransitionResult._({
    required this.previousState,
    required this.requestedState,
    required this.state,
    this.failure,
  });

  final PluginLifecycleState previousState;
  final PluginLifecycleState requestedState;
  final PluginLifecycleState state;
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

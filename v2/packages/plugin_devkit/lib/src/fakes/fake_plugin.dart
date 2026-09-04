import 'package:plugin_contracts/plugin_contracts.dart';

enum FakePluginOperation { activate, deactivate, dispose }

final class FakePlugin implements PluginLifecycle {
  FakePlugin({Map<FakePluginOperation, PluginFailure> failures = const {}})
    : _failures = Map<FakePluginOperation, PluginFailure>.unmodifiable(
        failures,
      );

  final Map<FakePluginOperation, PluginFailure> _failures;
  int _activateCalls = 0;
  int _deactivateCalls = 0;
  int _disposeCalls = 0;

  @override
  Future<void> activate() async {
    _activateCalls++;
    _throwIfConfigured(FakePluginOperation.activate);
  }

  @override
  Future<void> deactivate() async {
    _deactivateCalls++;
    _throwIfConfigured(FakePluginOperation.deactivate);
  }

  @override
  Future<void> dispose() async {
    _disposeCalls++;
    _throwIfConfigured(FakePluginOperation.dispose);
  }

  int get activateCalls => _activateCalls;
  int get deactivateCalls => _deactivateCalls;
  int get disposeCalls => _disposeCalls;

  void _throwIfConfigured(FakePluginOperation operation) {
    final failure = _failures[operation];
    if (failure != null) {
      throw failure;
    }
  }
}

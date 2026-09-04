enum PluginLifecycleState {
  discovered,
  resolved,
  inactive,
  activating,
  active,
  deactivating,
  failed,
  disposed,
}

abstract interface class PluginLifecycle {
  Future<void> activate();

  Future<void> deactivate();

  Future<void> dispose();
}

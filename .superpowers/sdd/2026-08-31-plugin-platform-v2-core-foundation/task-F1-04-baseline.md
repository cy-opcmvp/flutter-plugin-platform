# F1-04 filesystem baseline

Captured: 2026-08-31T21:40:00+08:00

- `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart`: absent
- `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart`: absent
- `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`: absent
- `v2/packages/plugin_contracts/lib/plugin_contracts.dart`: present with accepted F1-02/F1-03 exports
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`: present and empty

F1-02 and F1-03 are accepted. The controller will produce a complete filesystem baseline-to-head package after implementation. Generated lock/cache state is excluded from authored changes.

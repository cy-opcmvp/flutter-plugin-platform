# F1-04 fix round 1 review package — complete filesystem delta

Captured: 2026-08-31T22:40:00+08:00

This project forbids AI Git operations. This package is the complete fix-only delta from the initial F1-04 review to fix round 1.

## Findings under verification

1. Important: a detached `_CountingLifecycle` fixture was never reachable from `LifecycleMachine`, so asserting its counters stayed zero was tautological and could not detect future optional plugin/callback coupling.
2. Minor: after `_CountingLifecycle implements PluginLifecycle` compiled, `isA<PluginLifecycle>()` was guaranteed and added no independent interface-drift evidence.

## Controller ruling

The binding machine design forbids receiving or storing `PluginLifecycle`. A causal runtime unit test for machine-to-plugin calls would require introducing the coupling the design forbids. Therefore the two tautological tests and detached fixture must be removed without replacement. The negative state-only/no-plugin boundary is enforced by independent structural review of `LifecycleMachine` public constructor/API/fields and by the final review, not by a fake runtime assertion.

Cost if wrong: a future optional plugin/callback parameter has no dedicated unit-test failure and must be caught by required structural review.

## Complete fix delta

Only `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart` changed; F1-04 production files and exports retain their initial-review hashes.

Deleted the entire test:

```dart
test(
  'catches lifecycle interface drifting from its three async methods',
  () {
    final lifecycle = _CountingLifecycle();

    expect(lifecycle, isA<PluginLifecycle>());
  },
);
```

Deleted the entire test:

```dart
test('catches the machine invoking plugin lifecycle callbacks', () {
  final lifecycle = _CountingLifecycle();
  final machine = LifecycleMachine(PluginId.parse('tools.calculator'));

  _advanceToActive(machine);
  _expectSuccessfulTransition(
    machine,
    PluginLifecycleState.active,
    PluginLifecycleState.deactivating,
  );
  _expectSuccessfulTransition(
    machine,
    PluginLifecycleState.deactivating,
    PluginLifecycleState.inactive,
  );
  _expectSuccessfulTransition(
    machine,
    PluginLifecycleState.inactive,
    PluginLifecycleState.disposed,
  );

  expect(lifecycle.activateCalls, 0);
  expect(lifecycle.deactivateCalls, 0);
  expect(lifecycle.disposeCalls, 0);
});
```

Deleted the entire private `_CountingLifecycle implements PluginLifecycle` fixture and its three counters/methods. No source grep, I/O, compile subprocess, mock, alternate fixture, or equivalent tautology was added.

The remaining runtime test file contains 13 tests covering lifecycle vocabulary, fixed initial state/identity, all allowed edges, specified illegal edges, same-state rejection, disposed terminal behavior, success/rejection result fields, failure diagnostics, state preservation, immutable details, and independent rejection instances.

## Fresh controller verification

1. Runtime focused lifecycle test — exit 0; 13/13 passed.
2. Runtime full — exit 0; 13/13 passed.
3. Contracts full — exit 0; accepted 48/48 passed.
4. Workspace format — exit 0; 15 files checked, 0 changed.
5. Workspace analyze — exit 0; no issues found.
6. Search for `CountingLifecycle`, callback-test text, and `isA<PluginLifecycle>` in the runtime test returned zero matches.

The report's fix-round append explicitly withdraws earlier claims that the removed fixture automatically guards no-plugin coupling and records the structural-review boundary and no concerns.

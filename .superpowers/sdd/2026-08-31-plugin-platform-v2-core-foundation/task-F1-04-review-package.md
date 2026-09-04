# F1-04 review package — complete filesystem baseline-to-head snapshot

Captured: 2026-08-31T22:15:00+08:00

This project forbids AI Git operations. This package replaces a Git diff. The three lifecycle source/test files were absent at baseline; plugin_contracts export contained accepted F1-02/F1-03 exports; plugin_runtime export was empty.

## Baseline-to-head summary

| File | Baseline | Head SHA-256 |
|---|---|---|
| `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart` | absent | `00E289E626CD742BEA0ED4887EF4E014CDEB3F057C6A4F9EE510D90C676C566F` |
| `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart` | absent | `C2F4667FF873D21CCD06542CA39C9F5CCEEE5F091217E2DD4FC174813E2BF296` |
| `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart` | absent | `98C696D09C9708DD723ADD0DAB79D2D9530A35A3282E9354A541F37CDEACC3D2` |
| `v2/packages/plugin_contracts/lib/plugin_contracts.dart` | accepted F1-02/F1-03 exports; SHA-256 1493BC991A1CDD50824058C441922A60E7BFB80D44E1944C3E3B9F74E6B0E278 | `B82BF49232E662C210699EE8CDB8A3B9693C94D6DC1B26E12B15F35B3F3112E4` |
| `v2/packages/plugin_runtime/lib/plugin_runtime.dart` | empty; SHA-256 E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855 | `D3917EAB03ED28AB14460918BA623F0ECB205208AFFCFC676610820487446CE2` |

## Controller-authorized baseline maintenance

`v2/packages/plugin_devkit/lib/plugin_devkit.dart` was an accepted zero-byte F1-01 stub owned by future F1-07, but Dart's workspace formatter required a blank LF. After an explicit ledger ruling, the original implementer used apply_patch to change it from zero bytes to exactly one byte `0x0A`. It contains no token, declaration, comment, export, or behavior and is excluded from F1-04 production authored scope.

## Complete F1-04 task snapshot

### `v2/packages/plugin_contracts/lib/src/lifecycle/plugin_lifecycle.dart`

```dart
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

```

### `v2/packages/plugin_runtime/lib/src/lifecycle/lifecycle_machine.dart`

```dart
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

```

### `v2/packages/plugin_runtime/test/lifecycle/lifecycle_machine_test.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_runtime/plugin_runtime.dart';
import 'package:test/test.dart';

void main() {
  group('PluginLifecycle contract', () {
    test('catches lifecycle vocabulary being added, removed, or reordered', () {
      expect(PluginLifecycleState.values, <PluginLifecycleState>[
        PluginLifecycleState.discovered,
        PluginLifecycleState.resolved,
        PluginLifecycleState.inactive,
        PluginLifecycleState.activating,
        PluginLifecycleState.active,
        PluginLifecycleState.deactivating,
        PluginLifecycleState.failed,
        PluginLifecycleState.disposed,
      ]);
    });

    test(
      'catches lifecycle interface drifting from its three async methods',
      () {
        final lifecycle = _CountingLifecycle();

        expect(lifecycle, isA<PluginLifecycle>());
      },
    );
  });

  group('LifecycleMachine successful transitions', () {
    test('catches construction losing the provided ID or discovered state', () {
      final pluginId = PluginId.parse('tools.calculator');
      final machine = LifecycleMachine(pluginId);

      expect(machine.pluginId, same(pluginId));
      expect(machine.state, PluginLifecycleState.discovered);
    });

    test('catches any activation-chain edge or result field being wrong', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));
      const edges =
          <({PluginLifecycleState previous, PluginLifecycleState requested})>[
            (
              previous: PluginLifecycleState.discovered,
              requested: PluginLifecycleState.resolved,
            ),
            (
              previous: PluginLifecycleState.resolved,
              requested: PluginLifecycleState.inactive,
            ),
            (
              previous: PluginLifecycleState.inactive,
              requested: PluginLifecycleState.activating,
            ),
            (
              previous: PluginLifecycleState.activating,
              requested: PluginLifecycleState.active,
            ),
          ];

      for (final edge in edges) {
        final result = machine.transitionTo(edge.requested);

        expect(result.previousState, edge.previous);
        expect(result.requestedState, edge.requested);
        expect(result.state, edge.requested);
        expect(result.failure, isNull);
        expect(result.succeeded, isTrue);
        expect(machine.state, edge.requested);
      }

      expect(machine.state, PluginLifecycleState.active);
    });

    test('catches deactivation or reactivation edges being removed', () {
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
        PluginLifecycleState.activating,
      );
      _expectSuccessfulTransition(
        machine,
        PluginLifecycleState.activating,
        PluginLifecycleState.active,
      );
    });

    test('catches activating-to-failed-to-disposed path being removed', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));
      _advanceThrough(machine, const <PluginLifecycleState>[
        PluginLifecycleState.resolved,
        PluginLifecycleState.inactive,
        PluginLifecycleState.activating,
      ]);

      _expectSuccessfulTransition(
        machine,
        PluginLifecycleState.activating,
        PluginLifecycleState.failed,
      );
      _expectSuccessfulTransition(
        machine,
        PluginLifecycleState.failed,
        PluginLifecycleState.disposed,
      );
    });

    test('catches any allowed non-terminal failure edge being removed', () {
      const cases =
          <({PluginLifecycleState previous, List<PluginLifecycleState> setup})>[
            (
              previous: PluginLifecycleState.resolved,
              setup: <PluginLifecycleState>[PluginLifecycleState.resolved],
            ),
            (
              previous: PluginLifecycleState.inactive,
              setup: <PluginLifecycleState>[
                PluginLifecycleState.resolved,
                PluginLifecycleState.inactive,
              ],
            ),
            (
              previous: PluginLifecycleState.active,
              setup: <PluginLifecycleState>[
                PluginLifecycleState.resolved,
                PluginLifecycleState.inactive,
                PluginLifecycleState.activating,
                PluginLifecycleState.active,
              ],
            ),
            (
              previous: PluginLifecycleState.deactivating,
              setup: <PluginLifecycleState>[
                PluginLifecycleState.resolved,
                PluginLifecycleState.inactive,
                PluginLifecycleState.activating,
                PluginLifecycleState.active,
                PluginLifecycleState.deactivating,
              ],
            ),
          ];

      for (final testCase in cases) {
        final machine = LifecycleMachine(PluginId.parse('tools.calculator'));
        _advanceThrough(machine, testCase.setup);

        _expectSuccessfulTransition(
          machine,
          testCase.previous,
          PluginLifecycleState.failed,
        );
      }
    });

    test('catches direct inactive disposal being rejected', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));
      _advanceThrough(machine, const <PluginLifecycleState>[
        PluginLifecycleState.resolved,
        PluginLifecycleState.inactive,
      ]);

      _expectSuccessfulTransition(
        machine,
        PluginLifecycleState.inactive,
        PluginLifecycleState.disposed,
      );
    });

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
  });

  group('LifecycleMachine rejected transitions', () {
    test('catches discovered-to-active mutation or unstable diagnostics', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));

      final result = machine.transitionTo(PluginLifecycleState.active);

      expect(result.previousState, PluginLifecycleState.discovered);
      expect(result.requestedState, PluginLifecycleState.active);
      expect(result.state, PluginLifecycleState.discovered);
      expect(result.succeeded, isFalse);
      expect(result.failure, isNotNull);
      expect(result.failure!.code, 'lifecycle.invalid_transition');
      expect(result.failure!.message.trim(), isNotEmpty);
      expect(result.failure!.details, <String, Object?>{
        'pluginId': 'tools.calculator',
        'from': 'discovered',
        'to': 'active',
      });
      expect(
        () => result.failure!.details['extra'] = true,
        throwsUnsupportedError,
      );
      expect(machine.state, PluginLifecycleState.discovered);
    });

    test('catches discovered entering failed or mutating before rejection', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));

      _expectRejectedTransition(
        machine,
        PluginLifecycleState.discovered,
        PluginLifecycleState.failed,
      );

      expect(machine.state, PluginLifecycleState.discovered);
    });

    test('catches active skipping deactivation to become inactive', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));
      _advanceToActive(machine);

      _expectRejectedTransition(
        machine,
        PluginLifecycleState.active,
        PluginLifecycleState.inactive,
      );

      expect(machine.state, PluginLifecycleState.active);
    });

    test('catches same-state transitions being accepted', () {
      final discoveredMachine = LifecycleMachine(
        PluginId.parse('tools.calculator'),
      );
      final activeMachine = LifecycleMachine(PluginId.parse('tools.clock'));
      _advanceToActive(activeMachine);

      _expectRejectedTransition(
        discoveredMachine,
        PluginLifecycleState.discovered,
        PluginLifecycleState.discovered,
      );
      _expectRejectedTransition(
        activeMachine,
        PluginLifecycleState.active,
        PluginLifecycleState.active,
      );
    });

    test(
      'catches disposed losing terminal behavior for any requested state',
      () {
        final machine = LifecycleMachine(PluginId.parse('tools.calculator'));
        _advanceThrough(machine, const <PluginLifecycleState>[
          PluginLifecycleState.resolved,
          PluginLifecycleState.inactive,
          PluginLifecycleState.disposed,
        ]);

        for (final requested in PluginLifecycleState.values) {
          final result = machine.transitionTo(requested);

          expect(result.previousState, PluginLifecycleState.disposed);
          expect(result.requestedState, requested);
          expect(result.state, PluginLifecycleState.disposed);
          expect(result.succeeded, isFalse);
          expect(result.failure, isNotNull);
          expect(result.failure!.code, 'lifecycle.invalid_transition');
          expect(result.failure!.details, <String, Object?>{
            'pluginId': 'tools.calculator',
            'from': 'disposed',
            'to': requested.name,
          });
          expect(machine.state, PluginLifecycleState.disposed);
        }
      },
    );

    test('catches illegal attempts reusing result or failure instances', () {
      final machine = LifecycleMachine(PluginId.parse('tools.calculator'));

      final first = machine.transitionTo(PluginLifecycleState.active);
      final second = machine.transitionTo(PluginLifecycleState.active);

      expect(identical(first, second), isFalse);
      expect(first.failure, isNotNull);
      expect(second.failure, isNotNull);
      expect(identical(first.failure, second.failure), isFalse);
      expect(first.state, PluginLifecycleState.discovered);
      expect(second.state, PluginLifecycleState.discovered);
      expect(machine.state, PluginLifecycleState.discovered);
    });
  });
}

void _advanceToActive(LifecycleMachine machine) {
  _advanceThrough(machine, const <PluginLifecycleState>[
    PluginLifecycleState.resolved,
    PluginLifecycleState.inactive,
    PluginLifecycleState.activating,
    PluginLifecycleState.active,
  ]);
}

void _advanceThrough(
  LifecycleMachine machine,
  List<PluginLifecycleState> requestedStates,
) {
  for (final requestedState in requestedStates) {
    final result = machine.transitionTo(requestedState);
    expect(result.succeeded, isTrue);
    expect(result.failure, isNull);
    expect(machine.state, requestedState);
  }
}

void _expectSuccessfulTransition(
  LifecycleMachine machine,
  PluginLifecycleState previousState,
  PluginLifecycleState requestedState,
) {
  final result = machine.transitionTo(requestedState);

  expect(result.previousState, previousState);
  expect(result.requestedState, requestedState);
  expect(result.state, requestedState);
  expect(result.failure, isNull);
  expect(result.succeeded, isTrue);
  expect(machine.state, requestedState);
}

void _expectRejectedTransition(
  LifecycleMachine machine,
  PluginLifecycleState previousState,
  PluginLifecycleState requestedState,
) {
  final result = machine.transitionTo(requestedState);

  expect(result.previousState, previousState);
  expect(result.requestedState, requestedState);
  expect(result.state, previousState);
  expect(result.succeeded, isFalse);
  expect(result.failure, isNotNull);
  expect(result.failure!.code, 'lifecycle.invalid_transition');
  expect(result.failure!.details, <String, Object?>{
    'pluginId': machine.pluginId.value,
    'from': previousState.name,
    'to': requestedState.name,
  });
  expect(machine.state, previousState);
}

final class _CountingLifecycle implements PluginLifecycle {
  int activateCalls = 0;
  int deactivateCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> activate() async {
    activateCalls += 1;
  }

  @override
  Future<void> deactivate() async {
    deactivateCalls += 1;
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

```

### `v2/packages/plugin_contracts/lib/plugin_contracts.dart`

```dart
export 'src/capability/capability_descriptor.dart';
export 'src/errors/plugin_failure.dart';
export 'src/identity/plugin_id.dart';
export 'src/lifecycle/plugin_lifecycle.dart';
export 'src/manifest/plugin_manifest.dart';
export 'src/manifest/plugin_manifest_codec.dart';
export 'src/manifest/plugin_target.dart';

```

### `v2/packages/plugin_runtime/lib/plugin_runtime.dart`

```dart
export 'src/lifecycle/lifecycle_machine.dart';

```

## Fresh controller verification

1. From `v2/packages/plugin_runtime`: `dart test test/lifecycle/lifecycle_machine_test.dart` — exit 0; 15/15 passed.
2. From the same package: `dart test` — exit 0; 15/15 passed.
3. From `v2/packages/plugin_contracts`: `dart test` — exit 0; accepted 48/48 passed.
4. From `v2`: `dart format --output=none --set-exit-if-changed .` — exit 0; 15 files checked, 0 changed.
5. From `v2`: `dart analyze` — exit 0; no issues found.
6. Baseline-maintenance byte check: `plugin_devkit.dart` is exactly one byte, decimal 10 (LF).

## TDD/scope evidence

- The implementation report records a focused RED before F1-04 production/exports: exit 1 caused only by missing lifecycle types/exports, then focused GREEN.
- The implementer live-mutated the allowed `activating -> active` edge, observed a named test fail, restored it with apply_patch, and reran final focused/full GREEN.
- Authored F1-04 production/test changes are exactly the five complete files above plus `task-F1-04-report.md`; the one-byte empty-stub normalization is separately ledgered baseline maintenance.
- No Git, subagents, I/O, Flutter, platform APIs, service locator, install state, registry, resolver, Sidecar, or business plugin implementation was used.
- Full implementation/TDD/mutation/context report: `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-04-report.md`.


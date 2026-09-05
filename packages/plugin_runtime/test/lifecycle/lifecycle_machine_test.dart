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

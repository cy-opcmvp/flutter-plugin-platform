# F1-07 review package — complete filesystem snapshot

Captured: 2026-09-01T21:00:00+08:00

No Git operations. Fake/matcher/test were absent; devkit export was one LF; pubspec had no direct matcher dependency.

| File | Baseline | SHA-256 |
|---|---|---|
| `v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart` | absent | `BFF597C49A86E1CDE3CB7CAC70DBE898F5E1D720ED15A929EE43A17FD3C34872` |
| `v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart` | absent | `E9DB9F2D598F45031302CDD3F5397E4BC3AF11BC8C9715499282AD1B06D2B551` |
| `v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart` | absent | `C6202EB86CC2674D13C175BAF851438CEFCAC73E979243EC05559F15442F0DFC` |
| `v2/packages/plugin_devkit/lib/plugin_devkit.dart` | empty formatter-clean stub | `01B7A07BC8A8D897FB3023D56912ED77142E12285051B400269CE633384241F8` |
| `v2/packages/plugin_devkit/pubspec.yaml` | accepted contracts/runtime dependencies; no matcher | `BC8CEA6185FF72C4E1B91E403B3A2CD945FD465545A7BF5B349EFC52E553E72E` |

## `v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart`

```dart
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

```

## `v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart`

```dart
import 'package:matcher/matcher.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

Matcher hasPluginFailureCode(String code) {
  if (code.trim().isEmpty) {
    throw ArgumentError.value(code, 'code', 'must not be blank');
  }

  return _PluginFailureCodeMatcher(code);
}

final class _PluginFailureCodeMatcher extends Matcher {
  _PluginFailureCodeMatcher(this._expectedCode);

  final String _expectedCode;

  @override
  bool matches(dynamic item, Map<Object?, Object?> matchState) {
    return item is PluginFailure && item.code == _expectedCode;
  }

  @override
  Description describe(Description description) {
    return description
        .add('a PluginFailure with code ')
        .addDescriptionOf(_expectedCode);
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    if (item is! PluginFailure) {
      return mismatchDescription.add(
        'was not a PluginFailure (actual type: ${item.runtimeType})',
      );
    }

    return mismatchDescription.add(
      'had failure code ${item.code}, expected $_expectedCode',
    );
  }
}

```

## `v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_devkit/plugin_devkit.dart';
import 'package:test/test.dart';

void main() {
  group('success operations', () {
    final operations =
        <
          ({
            FakePluginOperation operation,
            Future<void> Function(FakePlugin) invoke,
          })
        >[
          (
            operation: FakePluginOperation.activate,
            invoke: (plugin) => plugin.activate(),
          ),
          (
            operation: FakePluginOperation.deactivate,
            invoke: (plugin) => plugin.deactivate(),
          ),
          (
            operation: FakePluginOperation.dispose,
            invoke: (plugin) => plugin.dispose(),
          ),
        ];

    for (final entry in operations) {
      test(entry.operation.name, () async {
        final plugin = FakePlugin();
        await entry.invoke(plugin);

        expect(
          [plugin.activateCalls, plugin.deactivateCalls, plugin.disposeCalls],
          [
            entry.operation == FakePluginOperation.activate ? 1 : 0,
            entry.operation == FakePluginOperation.deactivate ? 1 : 0,
            entry.operation == FakePluginOperation.dispose ? 1 : 0,
          ],
        );
      });
    }
  });

  group('injected failures', () {
    final operations =
        <
          ({
            FakePluginOperation operation,
            Future<void> Function(FakePlugin) invoke,
            int Function(FakePlugin) calls,
          })
        >[
          (
            operation: FakePluginOperation.activate,
            invoke: (plugin) => plugin.activate(),
            calls: (plugin) => plugin.activateCalls,
          ),
          (
            operation: FakePluginOperation.deactivate,
            invoke: (plugin) => plugin.deactivate(),
            calls: (plugin) => plugin.deactivateCalls,
          ),
          (
            operation: FakePluginOperation.dispose,
            invoke: (plugin) => plugin.dispose(),
            calls: (plugin) => plugin.disposeCalls,
          ),
        ];

    for (final entry in operations) {
      test(entry.operation.name, () async {
        final failure = PluginFailure(
          'plugin.${entry.operation.name}',
          'failed',
        );
        final plugin = FakePlugin(failures: {entry.operation: failure});

        await expectLater(entry.invoke(plugin), throwsA(same(failure)));
        expect(entry.calls(plugin), 1);
      });
    }
  });

  group('failure code matcher', () {
    final matcher = hasPluginFailureCode('plugin.failed');
    final wrongCode = PluginFailure('plugin.other', 'same message');

    test('matches code and rejects wrong code or type', () {
      expect(
        matcher.matches(PluginFailure('plugin.failed', 'message'), {}),
        isTrue,
      );
      expect(matcher.matches(wrongCode, {}), isFalse);
      expect(matcher.matches('plugin.failed', {}), isFalse);
    });
  });

  group('matcher validation and mismatch', () {
    test('rejects blank code and describes actual wrong code', () {
      expect(
        () => hasPluginFailureCode(' \t'),
        throwsA(predicate<ArgumentError>((error) => error.name == 'code')),
      );

      final matcher = hasPluginFailureCode('plugin.expected');
      final description = matcher
          .describeMismatch(
            PluginFailure('plugin.actual', 'message'),
            StringDescription(),
            {},
            false,
          )
          .toString();
      expect(description, contains('plugin.actual'));
    });
  });
}

```

## `v2/packages/plugin_devkit/lib/plugin_devkit.dart`

```dart
export 'src/fakes/fake_plugin.dart';
export 'src/matchers/plugin_failure_matcher.dart';

```

## `v2/packages/plugin_devkit/pubspec.yaml`

```yaml
name: plugin_devkit
publish_to: none
resolution: workspace
environment:
  sdk: ^3.10.0

dependencies:
  matcher: ^0.12.20
  plugin_contracts:
    path: ../plugin_contracts
  plugin_runtime:
    path: ../plugin_runtime

dev_dependencies:
  lints: ^6.0.0
  test: ^1.26.0

```

## Controller verification

- Devkit focused/full: 8/8; runtime: 26/26; contracts: 48/48; all exit 0.
- Workspace format: 25 files, 0 changed; analyze: no issues.
- Forbidden I/O/FFI/Flutter/process/timer/delay scan: zero matches.
- Public lib imports `package:matcher`; devkit pubspec declares `matcher ^0.12.20` as a direct package dependency.
- Two restored mutations detected: skipped failure-attempt increment; message-vs-code matcher comparison.
- Implementer report says contracts 49/49. Fresh controller evidence is 48/48, matching the accepted pre-task suite; reviewer must classify this report-only count discrepancy.
- Tests use four scenario groups and parameterized operation cases under the global minimal-test policy.


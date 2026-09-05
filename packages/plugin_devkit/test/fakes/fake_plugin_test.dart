import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_devkit/plugin_devkit.dart';
import 'package:flutter_test/flutter_test.dart';

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

import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('PluginId', () {
    test('catches valid dotted lowercase IDs being rejected', () {
      expect(PluginId.parse('tools.calculator').value, 'tools.calculator');
    });

    test('catches path traversal being accepted as an ID', () {
      expect(() => PluginId.parse('../escape'), throwsFormatException);
    });

    test('catches uppercase characters bypassing validation', () {
      expect(
        () => PluginId.parse('Tools.Calculator'),
        throwsFormatException,
      );
    });

    test('catches a single segment being accepted as an ID', () {
      expect(() => PluginId.parse('single'), throwsFormatException);
    });

    test('catches an empty string being accepted as an ID', () {
      expect(() => PluginId.parse(''), throwsFormatException);
    });

    test('catches malformed dotted segments bypassing validation', () {
      expect(() => PluginId.parse('tools.'), throwsFormatException);
      expect(() => PluginId.parse('tools..clock'), throwsFormatException);
    });

    test('catches tryParse rejecting a valid ID', () {
      expect(PluginId.tryParse('tools.clock')?.value, 'tools.clock');
    });

    test('catches tryParse throwing instead of returning null', () {
      expect(PluginId.tryParse('bad/path'), isNull);
    });

    test('catches equality or hash code drifting from the ID value', () {
      final first = PluginId.parse('tools.calculator');
      final same = PluginId.parse('tools.calculator');
      final different = PluginId.parse('tools.clock');

      expect(first, equals(same));
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(equals(different)));
    });

    test('catches toString exposing data beyond the validated ID', () {
      expect(PluginId.parse('tools.calculator').toString(), 'tools.calculator');
    });
  });

  group('PluginFailure', () {
    test('catches constructor fields not preserving valid failure data', () {
      final failure = PluginFailure(
        'plugin.invalid',
        'Plugin is invalid',
        <String, Object?>{'pluginId': 'tools.calculator'},
      );

      expect(failure.code, 'plugin.invalid');
      expect(failure.message, 'Plugin is invalid');
      expect(failure.details, <String, Object?>{
        'pluginId': 'tools.calculator',
      });
    });

    test('catches blank failure codes bypassing validation', () {
      expect(
        () => PluginFailure('  ', 'Plugin is invalid'),
        throwsA(
          isA<ArgumentError>().having((error) => error.name, 'name', 'code'),
        ),
      );
    });

    test('catches blank failure messages bypassing validation', () {
      expect(
        () => PluginFailure('plugin.invalid', '\t'),
        throwsA(
          isA<ArgumentError>().having(
            (error) => error.name,
            'name',
            'message',
          ),
        ),
      );
    });

    test('catches later input-map mutation changing failure details', () {
      final input = <String, Object?>{'attempt': 1};
      final failure = PluginFailure('plugin.invalid', 'Plugin is invalid', input);

      input['attempt'] = 2;
      input['new'] = true;

      expect(failure.details, <String, Object?>{'attempt': 1});
    });

    test('catches callers mutating exposed failure details', () {
      final failure = PluginFailure(
        'plugin.invalid',
        'Plugin is invalid',
        <String, Object?>{'attempt': 1},
      );

      expect(() => failure.details['attempt'] = 2, throwsUnsupportedError);
      expect(failure.details, <String, Object?>{'attempt': 1});
    });
  });
}

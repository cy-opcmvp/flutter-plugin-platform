import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('CapabilityDescriptor', () {
    test('catches valid descriptor data being rejected or normalized', () {
      final descriptor = CapabilityDescriptor('math.calculate', 2);

      expect(descriptor.id, 'math.calculate');
      expect(descriptor.version, 2);
    });

    test('catches invalid descriptor IDs bypassing strict validation', () {
      for (final id in <String>[
        'Math.calculate',
        '../math.calculate',
        'calculate',
        '',
        'math.',
        'math..calculate',
        'math.-calculate',
      ]) {
        expect(
          () => CapabilityDescriptor(id, 1),
          throwsA(
            isA<ArgumentError>().having((error) => error.name, 'name', 'id'),
          ),
          reason: 'invalid descriptor ID: $id',
        );
      }
    });

    test('catches zero or negative descriptor versions being accepted', () {
      for (final version in <int>[0, -1]) {
        expect(
          () => CapabilityDescriptor('math.calculate', version),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'version',
            ),
          ),
          reason: 'invalid descriptor version: $version',
        );
      }
    });
  });

  group('CapabilityRequirement', () {
    test('catches valid requirement data being rejected or normalized', () {
      final requirement = CapabilityRequirement('storage.read', 3);

      expect(requirement.id, 'storage.read');
      expect(requirement.version, 3);
    });

    test('catches invalid requirement IDs bypassing strict validation', () {
      for (final id in <String>[
        'Storage.read',
        'storage/read',
        'read',
        '',
        '.storage',
        'storage..read',
        'storage.read-',
      ]) {
        expect(
          () => CapabilityRequirement(id, 1),
          throwsA(
            isA<ArgumentError>().having((error) => error.name, 'name', 'id'),
          ),
          reason: 'invalid requirement ID: $id',
        );
      }
    });

    test('catches zero or negative requirement versions being accepted', () {
      for (final version in <int>[0, -1]) {
        expect(
          () => CapabilityRequirement('storage.read', version),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.name,
              'name',
              'version',
            ),
          ),
          reason: 'invalid requirement version: $version',
        );
      }
    });
  });
}

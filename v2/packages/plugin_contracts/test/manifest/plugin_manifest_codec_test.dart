import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:test/test.dart';

void main() {
  group('PluginManifestCodec', () {
    test('catches valid manifest fields being rejected or decoded wrongly', () {
      final manifest = PluginManifestCodec.decode(_validJson());

      expect(manifest.id.value, 'tools.calculator');
      expect(manifest.name, 'Calculator');
      expect(manifest.version, '1.0.0');
      expect(manifest.apiVersion, 1);
      expect(manifest.kind, PluginKind.builtin);
      expect(manifest.targets, <PluginTarget>[
        PluginTarget.windows,
        PluginTarget.macos,
        PluginTarget.linux,
        PluginTarget.android,
        PluginTarget.ios,
        PluginTarget.web,
      ]);
      expect(manifest.entrypoint, 'CalculatorPlugin');
      expect(manifest.provides, hasLength(1));
      expect(manifest.provides.single.id, 'math.calculate');
      expect(manifest.provides.single.version, 1);
      expect(manifest.requires, isEmpty);
      expect(manifest.surfaces, <String>['page']);
      expect(manifest.configSchemaVersion, 1);
      expect(manifest.dataSchemaVersion, 1);
    });

    test('catches encode drifting from the exact twelve-key JSON schema', () {
      final manifest = PluginManifestCodec.decode(_validJson());

      expect(PluginManifestCodec.encode(manifest), equals(_validJson()));
    });

    test('catches unknown top-level fields being silently accepted', () {
      final json = _validJson()..['command'] = 'calculator.exe';

      _expectFormatFailure(json, 'command');
    });

    test('catches sensitive unknown field keys leaking into diagnostics', () {
      const sensitiveKey =
          r'C:\Users\alice\AppData\plugin.exe --token=top-secret';
      final json = _validJson()..[sensitiveKey] = true;

      expect(
        () => PluginManifestCodec.decode(json),
        throwsA(
          isA<FormatException>()
              .having(
                (error) => error.message.toString(),
                'message',
                contains('unknown field'),
              )
              .having(
                (error) => error.message.toString(),
                'message',
                isNot(contains(sensitiveKey)),
              )
              .having(
                (error) => error.message.toString(),
                'message',
                isNot(contains(r'C:\Users\alice')),
              )
              .having(
                (error) => error.message.toString(),
                'message',
                isNot(contains('top-secret')),
              ),
        ),
      );
    });

    test(
      'catches alphanumeric secret-shaped unknown keys leaking into diagnostics',
      () {
        const sensitiveKey = 'topSecret123';
        final json = _validJson()..[sensitiveKey] = true;

        expect(
          () => PluginManifestCodec.decode(json),
          throwsA(
            isA<FormatException>()
                .having(
                  (error) => error.message.toString(),
                  'message',
                  contains('unknown field'),
                )
                .having(
                  (error) => error.message.toString(),
                  'message',
                  isNot(contains(sensitiveKey)),
                )
                .having(
                  (error) => error.message.toString(),
                  'message',
                  isNot(contains('Secret123')),
                ),
          ),
        );
      },
    );

    test('catches a missing required top-level field being defaulted', () {
      final json = _validJson()..remove('dataSchemaVersion');

      _expectFormatFailure(json, 'dataSchemaVersion');
    });

    test('catches an invalid plugin ID reaching the manifest model', () {
      final json = _validJson()..['id'] = '../calculator';

      _expectFormatFailure(json, 'id');
    });

    test('catches a wrong scalar runtime type being coerced', () {
      final json = _validJson()..['apiVersion'] = '1';

      _expectFormatFailure(json, 'apiVersion');
    });

    test('catches a wrong target list-member type being coerced', () {
      final json = _validJson()..['targets'] = <Object?>['windows', 1];

      _expectFormatFailure(json, 'targets');
    });

    test('catches an unknown plugin kind being accepted', () {
      final json = _validJson()..['kind'] = 'process';

      _expectFormatFailure(json, 'kind');
    });

    test('catches an unknown plugin target being accepted', () {
      final json = _validJson()..['targets'] = <Object?>['windows', 'fuchsia'];

      _expectFormatFailure(json, 'targets');
    });

    test('catches empty or duplicate target sets being accepted', () {
      final empty = _validJson()..['targets'] = <Object?>[];
      final duplicate = _validJson()
        ..['targets'] = <Object?>['windows', 'windows'];

      _expectFormatFailure(empty, 'targets');
      _expectFormatFailure(duplicate, 'targets');
    });

    test('catches non-positive manifest schema versions being accepted', () {
      for (final field in <String>[
        'apiVersion',
        'configSchemaVersion',
        'dataSchemaVersion',
      ]) {
        for (final value in <int>[0, -1]) {
          final json = _validJson()..[field] = value;

          _expectFormatFailure(json, field);
        }
      }
    });

    test('catches missing or unknown nested capability keys', () {
      final missing = _validJson()
        ..['provides'] = <Object?>[
          <String, Object?>{'id': 'math.calculate'},
        ];
      final unknown = _validJson()
        ..['requires'] = <Object?>[
          <String, Object?>{
            'id': 'storage.read',
            'version': 1,
            'optional': true,
          },
        ];

      _expectFormatFailure(missing, 'provides');
      _expectFormatFailure(unknown, 'requires');
    });

    test('catches malformed nested capability runtime shapes', () {
      final wrongEntry = _validJson()
        ..['provides'] = <Object?>['math.calculate'];
      final wrongKey = _validJson()
        ..['requires'] = <Object?>[
          <Object?, Object?>{1: 'storage.read', 'version': 1},
        ];

      _expectFormatFailure(wrongEntry, 'provides');
      _expectFormatFailure(wrongKey, 'requires');
    });

    test('catches invalid nested capability IDs bypassing validation', () {
      final json = _validJson()
        ..['provides'] = <Object?>[
          <String, Object?>{'id': 'Math.calculate', 'version': 1},
        ];

      _expectFormatFailure(json, 'provides');
    });

    test('catches non-positive nested capability versions being accepted', () {
      for (final value in <int>[0, -1]) {
        final json = _validJson()
          ..['requires'] = <Object?>[
            <String, Object?>{'id': 'storage.read', 'version': value},
          ];

        _expectFormatFailure(json, 'requires');
      }
    });

    test('catches duplicate provided capability IDs being accepted', () {
      final json = _validJson()
        ..['provides'] = <Object?>[
          <String, Object?>{'id': 'math.calculate', 'version': 1},
          <String, Object?>{'id': 'math.calculate', 'version': 2},
        ];

      _expectFormatFailure(json, 'provides');
    });

    test('catches duplicate required capability IDs being accepted', () {
      final json = _validJson()
        ..['requires'] = <Object?>[
          <String, Object?>{'id': 'storage.read', 'version': 1},
          <String, Object?>{'id': 'storage.read', 'version': 2},
        ];

      _expectFormatFailure(json, 'requires');
    });

    test('catches a sidecar manifest omitting its required entrypoint', () {
      final json = _validJson()
        ..['kind'] = 'sidecar'
        ..remove('entrypoint');

      _expectFormatFailure(json, 'entrypoint');
    });

    test('catches a sidecar manifest using a blank entrypoint', () {
      final json = _validJson()
        ..['kind'] = 'sidecar'
        ..['entrypoint'] = '  ';

      _expectFormatFailure(json, 'entrypoint');
    });

    test('catches a sidecar manifest without a desktop target', () {
      final json = _validJson()
        ..['kind'] = 'sidecar'
        ..['targets'] = <Object?>['android', 'ios', 'web'];

      _expectFormatFailure(json, 'targets');
    });

    test('catches blank names or versions being accepted', () {
      final blankName = _validJson()..['name'] = '\t';
      final blankVersion = _validJson()..['version'] = '  ';

      _expectFormatFailure(blankName, 'name');
      _expectFormatFailure(blankVersion, 'version');
    });

    test('catches blank or duplicate surfaces being accepted', () {
      final blank = _validJson()..['surfaces'] = <Object?>['page', '  '];
      final duplicate = _validJson()..['surfaces'] = <Object?>['page', 'page'];

      _expectFormatFailure(blank, 'surfaces');
      _expectFormatFailure(duplicate, 'surfaces');
    });

    test('catches constructor input-list mutation changing a manifest', () {
      final targets = <PluginTarget>[PluginTarget.windows];
      final provides = <CapabilityDescriptor>[
        CapabilityDescriptor('math.calculate', 1),
      ];
      final requires = <CapabilityRequirement>[
        CapabilityRequirement('storage.read', 1),
      ];
      final surfaces = <String>['page'];
      final manifest = PluginManifest(
        id: PluginId.parse('tools.calculator'),
        name: 'Calculator',
        version: '1.0.0',
        apiVersion: 1,
        kind: PluginKind.builtin,
        targets: targets,
        entrypoint: 'CalculatorPlugin',
        provides: provides,
        requires: requires,
        surfaces: surfaces,
        configSchemaVersion: 1,
        dataSchemaVersion: 1,
      );

      targets
        ..clear()
        ..add(PluginTarget.web);
      provides.clear();
      requires.clear();
      surfaces.clear();

      expect(manifest.targets, <PluginTarget>[PluginTarget.windows]);
      expect(manifest.provides.single.id, 'math.calculate');
      expect(manifest.requires.single.id, 'storage.read');
      expect(manifest.surfaces, <String>['page']);
    });

    test('catches callers mutating exposed manifest collections', () {
      final manifest = PluginManifestCodec.decode(_validJson());

      expect(
        () => manifest.targets.add(PluginTarget.windows),
        throwsUnsupportedError,
      );
      expect(
        () => manifest.provides.add(CapabilityDescriptor('time.read', 1)),
        throwsUnsupportedError,
      );
      expect(
        () => manifest.requires.add(CapabilityRequirement('time.read', 1)),
        throwsUnsupportedError,
      );
      expect(() => manifest.surfaces.add('tray'), throwsUnsupportedError);
    });

    test('catches encoded map and list mutation changing a manifest', () {
      final manifest = PluginManifestCodec.decode(_validJson());
      final encoded = PluginManifestCodec.encode(manifest);

      encoded['name'] = 'Changed';
      (encoded['targets']! as List<Object?>).clear();
      final encodedProvides = encoded['provides']! as List<Object?>;
      (encodedProvides.single as Map<String, Object?>)['id'] = 'time.read';
      (encoded['requires']! as List<Object?>).add(<String, Object?>{
        'id': 'storage.read',
        'version': 1,
      });
      (encoded['surfaces']! as List<Object?>).clear();

      expect(manifest.name, 'Calculator');
      expect(manifest.targets, hasLength(6));
      expect(manifest.provides.single.id, 'math.calculate');
      expect(manifest.requires, isEmpty);
      expect(manifest.surfaces, <String>['page']);
    });
  });
}

Map<String, Object?> _validJson() => <String, Object?>{
  'id': 'tools.calculator',
  'name': 'Calculator',
  'version': '1.0.0',
  'apiVersion': 1,
  'kind': 'builtin',
  'targets': <Object?>['windows', 'macos', 'linux', 'android', 'ios', 'web'],
  'entrypoint': 'CalculatorPlugin',
  'provides': <Object?>[
    <String, Object?>{'id': 'math.calculate', 'version': 1},
  ],
  'requires': <Object?>[],
  'surfaces': <Object?>['page'],
  'configSchemaVersion': 1,
  'dataSchemaVersion': 1,
};

void _expectFormatFailure(Map<String, Object?> json, String field) {
  expect(
    () => PluginManifestCodec.decode(json),
    throwsA(
      isA<FormatException>().having(
        (error) => error.message.toString(),
        'message',
        contains(field),
      ),
    ),
  );
}

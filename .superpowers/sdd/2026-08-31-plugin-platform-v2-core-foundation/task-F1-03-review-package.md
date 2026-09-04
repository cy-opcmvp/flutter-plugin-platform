# F1-03 review package — complete filesystem baseline-to-head snapshot

Captured: 2026-08-31T20:35:00+08:00

This project forbids AI Git operations. This package replaces a Git diff. All six new task files were absent at baseline; the package export existed with only the two accepted F1-02 exports. Generated lock/cache state and controller-owned progress artifacts are excluded.

## Baseline-to-head summary

| File | Baseline | Head SHA-256 |
|---|---|---|
| `v2/packages/plugin_contracts/lib/src/manifest/plugin_target.dart` | absent | `582F957D228D912B49D315D483157801A9726DF3C277C79A3375755A207A0C74` |
| `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest.dart` | absent | `19C9C5107A8E85F1A7B2F05B3CCF099526EE08601CB6D7E3D6AF84A0ACD3F6AA` |
| `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart` | absent | `103A9C7027EFEBF249BB077D23A54800CF6BE13ED5EDF735BD2FBAD769ED5538` |
| `v2/packages/plugin_contracts/lib/src/capability/capability_descriptor.dart` | absent | `F4F266F5E36367014D9B5E8C0EBEF3D44DF777B99B513EE140905F6BA8CC46FE` |
| `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart` | absent | `7E77C69F3942C4BAF2F4B1EE5D0135A9DDBE2C9D2F01D8235C397E3E507EE628` |
| `v2/packages/plugin_contracts/test/capability/capability_descriptor_test.dart` | absent | `733CC051AB493F4C10B5CBBB050C3F96AC2D6CA902EE17164E23FE02054A6D1B` |
| `v2/packages/plugin_contracts/lib/plugin_contracts.dart` | F1-02 exports only; SHA-256 4314FFEC086F31DD47AFAA565F523A8FBEB4F638C684393DCB3F22AF37A27E5F | `1493BC991A1CDD50824058C441922A60E7BFB80D44E1944C3E3B9F74E6B0E278` |

## Complete task snapshot

### `v2/packages/plugin_contracts/lib/src/manifest/plugin_target.dart`

```dart
enum PluginTarget { windows, macos, linux, android, ios, web }

enum PluginKind { builtin, sidecar }

```

### `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest.dart`

```dart
import '../capability/capability_descriptor.dart';
import '../identity/plugin_id.dart';
import 'plugin_target.dart';

/// 插件的不可变声明；所有集合均为保持输入顺序的只读快照。
final class PluginManifest {
  PluginManifest({
    required this.id,
    required String name,
    required String version,
    required int apiVersion,
    required this.kind,
    required List<PluginTarget> targets,
    required String entrypoint,
    required List<CapabilityDescriptor> provides,
    required List<CapabilityRequirement> requires,
    required List<String> surfaces,
    required int configSchemaVersion,
    required int dataSchemaVersion,
  }) : name = _requireNonBlank(name, 'name'),
       version = _requireNonBlank(version, 'version'),
       apiVersion = _requirePositive(apiVersion, 'apiVersion'),
       targets = _snapshotTargets(targets),
       entrypoint = _requireNonBlank(entrypoint, 'entrypoint'),
       provides = _snapshotProvides(provides),
       requires = _snapshotRequires(requires),
       surfaces = _snapshotSurfaces(surfaces),
       configSchemaVersion = _requirePositive(
         configSchemaVersion,
         'configSchemaVersion',
       ),
       dataSchemaVersion = _requirePositive(
         dataSchemaVersion,
         'dataSchemaVersion',
       ) {
    if (kind == PluginKind.sidecar &&
        !this.targets.any(_desktopTargets.contains)) {
      throw ArgumentError.value(
        this.targets,
        'targets',
        'sidecar requires a desktop target',
      );
    }
  }

  static const Set<PluginTarget> _desktopTargets = <PluginTarget>{
    PluginTarget.windows,
    PluginTarget.macos,
    PluginTarget.linux,
  };

  final PluginId id;
  final String name;
  final String version;
  final int apiVersion;
  final PluginKind kind;
  final List<PluginTarget> targets;
  final String entrypoint;
  final List<CapabilityDescriptor> provides;
  final List<CapabilityRequirement> requires;
  final List<String> surfaces;
  final int configSchemaVersion;
  final int dataSchemaVersion;
}

String _requireNonBlank(String value, String field) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }

  return value;
}

int _requirePositive(int value, String field) {
  if (value <= 0) {
    throw ArgumentError.value(value, field, 'must be positive');
  }

  return value;
}

List<PluginTarget> _snapshotTargets(List<PluginTarget> values) {
  if (values.isEmpty || values.toSet().length != values.length) {
    throw ArgumentError.value(
      values,
      'targets',
      'must be non-empty and contain no duplicates',
    );
  }

  return List<PluginTarget>.unmodifiable(values);
}

List<CapabilityDescriptor> _snapshotProvides(
  List<CapabilityDescriptor> values,
) {
  if (_hasDuplicateCapabilityIds(values.map((value) => value.id))) {
    throw ArgumentError.value(
      values,
      'provides',
      'must contain unique capability IDs',
    );
  }

  return List<CapabilityDescriptor>.unmodifiable(values);
}

List<CapabilityRequirement> _snapshotRequires(
  List<CapabilityRequirement> values,
) {
  if (_hasDuplicateCapabilityIds(values.map((value) => value.id))) {
    throw ArgumentError.value(
      values,
      'requires',
      'must contain unique capability IDs',
    );
  }

  return List<CapabilityRequirement>.unmodifiable(values);
}

bool _hasDuplicateCapabilityIds(Iterable<String> ids) {
  final seen = <String>{};
  return ids.any((id) => !seen.add(id));
}

List<String> _snapshotSurfaces(List<String> values) {
  if (values.any((value) => value.trim().isEmpty) ||
      values.toSet().length != values.length) {
    throw ArgumentError.value(
      values,
      'surfaces',
      'must be non-blank and contain no duplicates',
    );
  }

  return List<String>.unmodifiable(values);
}

```

### `v2/packages/plugin_contracts/lib/src/manifest/plugin_manifest_codec.dart`

```dart
import '../capability/capability_descriptor.dart';
import '../identity/plugin_id.dart';
import 'plugin_manifest.dart';
import 'plugin_target.dart';

/// 在严格 JSON 映射与不可变插件清单之间转换。
abstract final class PluginManifestCodec {
  static const Set<String> _fields = <String>{
    'id',
    'name',
    'version',
    'apiVersion',
    'kind',
    'targets',
    'entrypoint',
    'provides',
    'requires',
    'surfaces',
    'configSchemaVersion',
    'dataSchemaVersion',
  };

  static PluginManifest decode(Map<String, Object?> json) {
    for (final field in json.keys) {
      if (!_fields.contains(field)) {
        _fail(field);
      }
    }
    for (final field in _fields) {
      if (!json.containsKey(field)) {
        _fail(field);
      }
    }

    final id = _decodePluginId(json['id']);
    final name = _readString(json, 'name');
    final version = _readString(json, 'version');
    final apiVersion = _readInt(json, 'apiVersion');
    final kind = _decodeKind(json['kind']);
    final targets = _decodeTargets(json['targets']);
    final entrypoint = _readString(json, 'entrypoint');
    final provides = _decodeProvides(json['provides']);
    final requires = _decodeRequires(json['requires']);
    final surfaces = _decodeStringList(json['surfaces'], 'surfaces');
    final configSchemaVersion = _readInt(json, 'configSchemaVersion');
    final dataSchemaVersion = _readInt(json, 'dataSchemaVersion');

    try {
      return PluginManifest(
        id: id,
        name: name,
        version: version,
        apiVersion: apiVersion,
        kind: kind,
        targets: targets,
        entrypoint: entrypoint,
        provides: provides,
        requires: requires,
        surfaces: surfaces,
        configSchemaVersion: configSchemaVersion,
        dataSchemaVersion: dataSchemaVersion,
      );
    } on ArgumentError catch (error) {
      _fail(error.name ?? 'manifest');
    }
  }

  static Map<String, Object?> encode(PluginManifest manifest) {
    return <String, Object?>{
      'id': manifest.id.value,
      'name': manifest.name,
      'version': manifest.version,
      'apiVersion': manifest.apiVersion,
      'kind': manifest.kind.name,
      'targets': <Object?>[for (final target in manifest.targets) target.name],
      'entrypoint': manifest.entrypoint,
      'provides': <Object?>[
        for (final descriptor in manifest.provides)
          <String, Object?>{'id': descriptor.id, 'version': descriptor.version},
      ],
      'requires': <Object?>[
        for (final requirement in manifest.requires)
          <String, Object?>{
            'id': requirement.id,
            'version': requirement.version,
          },
      ],
      'surfaces': <Object?>[...manifest.surfaces],
      'configSchemaVersion': manifest.configSchemaVersion,
      'dataSchemaVersion': manifest.dataSchemaVersion,
    };
  }

  static PluginId _decodePluginId(Object? value) {
    if (value is! String) {
      _fail('id');
    }

    try {
      return PluginId.parse(value);
    } on FormatException {
      _fail('id');
    }
  }

  static PluginKind _decodeKind(Object? value) {
    if (value is! String) {
      _fail('kind');
    }

    return switch (value) {
      'builtin' => PluginKind.builtin,
      'sidecar' => PluginKind.sidecar,
      _ => _fail('kind'),
    };
  }

  static List<PluginTarget> _decodeTargets(Object? value) {
    if (value is! List<Object?>) {
      _fail('targets');
    }

    return <PluginTarget>[for (final item in value) _decodeTarget(item)];
  }

  static PluginTarget _decodeTarget(Object? value) {
    if (value is! String) {
      _fail('targets');
    }

    return switch (value) {
      'windows' => PluginTarget.windows,
      'macos' => PluginTarget.macos,
      'linux' => PluginTarget.linux,
      'android' => PluginTarget.android,
      'ios' => PluginTarget.ios,
      'web' => PluginTarget.web,
      _ => _fail('targets'),
    };
  }

  static List<CapabilityDescriptor> _decodeProvides(Object? value) {
    if (value is! List<Object?>) {
      _fail('provides');
    }

    return <CapabilityDescriptor>[
      for (final item in value)
        _decodeCapability(item, 'provides', CapabilityDescriptor.new),
    ];
  }

  static List<CapabilityRequirement> _decodeRequires(Object? value) {
    if (value is! List<Object?>) {
      _fail('requires');
    }

    return <CapabilityRequirement>[
      for (final item in value)
        _decodeCapability(item, 'requires', CapabilityRequirement.new),
    ];
  }

  static T _decodeCapability<T>(
    Object? value,
    String field,
    T Function(String id, int version) create,
  ) {
    if (value is! Map<Object?, Object?> ||
        value.keys.any((key) => key is! String)) {
      _fail(field);
    }

    final capability = <String, Object?>{
      for (final entry in value.entries) entry.key as String: entry.value,
    };
    if (capability.length != 2 ||
        !capability.containsKey('id') ||
        !capability.containsKey('version')) {
      _fail(field);
    }

    final id = capability['id'];
    final version = capability['version'];
    if (id is! String || version is! int) {
      _fail(field);
    }

    try {
      return create(id, version);
    } on ArgumentError {
      _fail(field);
    }
  }

  static List<String> _decodeStringList(Object? value, String field) {
    if (value is! List<Object?> || value.any((item) => item is! String)) {
      _fail(field);
    }

    return <String>[for (final item in value) item as String];
  }

  static String _readString(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! String) {
      _fail(field);
    }

    return value;
  }

  static int _readInt(Map<String, Object?> json, String field) {
    final value = json[field];
    if (value is! int) {
      _fail(field);
    }

    return value;
  }

  static Never _fail(String field) {
    throw FormatException('Invalid manifest field: $field');
  }
}

```

### `v2/packages/plugin_contracts/lib/src/capability/capability_descriptor.dart`

```dart
final RegExp _capabilityIdPattern = RegExp(r'^[a-z][a-z0-9]*(\.[a-z0-9]+)+$');

/// 插件提供的、带正版本号的能力契约。
final class CapabilityDescriptor {
  CapabilityDescriptor(String id, int version)
    : id = _requireCapabilityId(id),
      version = _requirePositiveVersion(version);

  final String id;
  final int version;
}

/// 插件依赖的、带正版本号的能力契约。
final class CapabilityRequirement {
  CapabilityRequirement(String id, int version)
    : id = _requireCapabilityId(id),
      version = _requirePositiveVersion(version);

  final String id;
  final int version;
}

String _requireCapabilityId(String id) {
  if (!_capabilityIdPattern.hasMatch(id)) {
    throw ArgumentError.value(id, 'id', 'must be a dotted lowercase ID');
  }

  return id;
}

int _requirePositiveVersion(int version) {
  if (version <= 0) {
    throw ArgumentError.value(version, 'version', 'must be positive');
  }

  return version;
}

```

### `v2/packages/plugin_contracts/test/manifest/plugin_manifest_codec_test.dart`

```dart
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

```

### `v2/packages/plugin_contracts/test/capability/capability_descriptor_test.dart`

```dart
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

```

### `v2/packages/plugin_contracts/lib/plugin_contracts.dart`

```dart
export 'src/capability/capability_descriptor.dart';
export 'src/errors/plugin_failure.dart';
export 'src/identity/plugin_id.dart';
export 'src/manifest/plugin_manifest.dart';
export 'src/manifest/plugin_manifest_codec.dart';
export 'src/manifest/plugin_target.dart';

```

## Fresh controller verification

Working directory: `v2/packages/plugin_contracts`.

1. `dart test test/manifest test/capability` — exit 0; `+31: All tests passed!`.
2. `dart test` — exit 0; `+46: All tests passed!`, including accepted F1-02 tests.
3. `dart format --output=none --set-exit-if-changed .` — exit 0; `Formatted 10 files (0 changed)`.
4. `dart analyze` — exit 0; `No issues found!`.
5. Forbidden dependency scan across package lib/tests for Flutter, `dart:io`, `dart:ffi`, win32, or plugin_runtime — zero matches.

## TDD and scope evidence

- The implementer report records the focused RED before any F1-03 production/export file: exit 1 with undefined F1-03 public symbols and `Some tests failed`. The login PowerShell host required Ctrl+C only after the full failure summary; GREEN and every fresh no-profile verification exited normally.
- Authored changes are exactly the seven files above plus `task-F1-03-report.md`.
- No Git commands, subagents, later-phase runtime code, platform code, Flutter code, Sidecar process code, or business plugins were used by the implementer.
- The detailed implementation/TDD/mutation report is `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-03-report.md`.


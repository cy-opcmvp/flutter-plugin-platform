import '../capability/capability_descriptor.dart';
import '../identity/plugin_id.dart';
import 'plugin_manifest.dart';
import 'plugin_target.dart';

/// 在严格 JSON 映射与不可变插件清单之间转换。
abstract final class PluginManifestCodec {
  static const Set<String> _diagnosticUnknownFieldAllowlist = <String>{
    'command',
  };

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
        _failUnknownField(field);
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

  static Never _failUnknownField(String field) {
    if (_diagnosticUnknownFieldAllowlist.contains(field)) {
      throw FormatException('Invalid manifest unknown field: $field');
    }

    throw const FormatException('Invalid manifest: unknown field');
  }
}

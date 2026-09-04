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

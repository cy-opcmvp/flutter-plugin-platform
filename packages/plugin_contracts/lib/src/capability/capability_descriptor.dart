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

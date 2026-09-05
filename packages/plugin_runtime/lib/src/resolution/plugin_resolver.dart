import 'package:plugin_contracts/plugin_contracts.dart';

abstract final class PluginResolver {
  static PluginResolutionResult resolve(
    Iterable<PluginManifest> manifests,
    PluginTarget target,
  ) {
    final manifestSnapshot = List<PluginManifest>.unmodifiable(manifests);
    final inputIndexes = <PluginId, int>{
      for (var index = 0; index < manifestSnapshot.length; index++)
        manifestSnapshot[index].id: index,
    };
    final providers = <String, _Provider>{};
    for (final manifest in manifestSnapshot) {
      for (final descriptor in manifest.provides) {
        providers[descriptor.id] = _Provider(manifest, descriptor);
      }
    }

    final dependencies = <PluginId, List<_Dependency>>{};
    final initiallyUnavailable = <PluginId>{};
    for (final manifest in manifestSnapshot) {
      final pluginDependencies = <_Dependency>[];
      dependencies[manifest.id] = pluginDependencies;
      if (!manifest.targets.contains(target)) {
        initiallyUnavailable.add(manifest.id);
        continue;
      }

      for (final requirement in manifest.requires) {
        final provider = providers[requirement.id];
        if (provider == null ||
            provider.descriptor.version < requirement.version) {
          initiallyUnavailable.add(manifest.id);
          continue;
        }
        pluginDependencies.add(_Dependency(provider.manifest.id));
      }
    }

    final unavailable = <PluginId>{...initiallyUnavailable};
    _propagateUnavailable(manifestSnapshot, dependencies, unavailable);

    final candidates = <PluginId>{
      for (final manifest in manifestSnapshot)
        if (!unavailable.contains(manifest.id)) manifest.id,
    };
    final cycleComponents = _findCycleComponents(
      manifestSnapshot,
      inputIndexes,
      dependencies,
      candidates,
    );
    final cycleByPlugin = <PluginId, List<PluginId>>{};
    for (final component in cycleComponents) {
      for (final id in component) {
        cycleByPlugin[id] = component;
        unavailable.add(id);
      }
    }
    _propagateUnavailable(manifestSnapshot, dependencies, unavailable);

    final resolutions = <PluginId, PluginResolution>{};
    final failureView = <PluginId, List<PluginFailure>>{};
    for (final manifest in manifestSnapshot) {
      final failures = _failuresFor(
        manifest,
        target,
        providers,
        unavailable,
        cycleByPlugin,
      );
      final resolution = PluginResolution._(manifest, failures);
      resolutions[manifest.id] = resolution;
      if (!resolution.available) {
        failureView[manifest.id] = resolution.failures;
      }
    }

    final available = <PluginId>[
      for (final manifest in manifestSnapshot)
        if (!unavailable.contains(manifest.id)) manifest.id,
    ];
    return PluginResolutionResult._(
      plugins: resolutions,
      available: available,
      activationOrder: _activationOrder(
        manifestSnapshot,
        dependencies,
        available,
      ),
      failures: failureView,
    );
  }
}

final class PluginResolution {
  PluginResolution._(this.manifest, List<PluginFailure> failures)
    : failures = List<PluginFailure>.unmodifiable(failures);

  final PluginManifest manifest;
  final List<PluginFailure> failures;

  bool get available => failures.isEmpty;
}

final class PluginResolutionResult {
  PluginResolutionResult._({
    required Map<PluginId, PluginResolution> plugins,
    required List<PluginId> available,
    required List<PluginId> activationOrder,
    required Map<PluginId, List<PluginFailure>> failures,
  }) : plugins = Map<PluginId, PluginResolution>.unmodifiable(plugins),
       available = List<PluginId>.unmodifiable(available),
       activationOrder = List<PluginId>.unmodifiable(activationOrder),
       failures = Map<PluginId, List<PluginFailure>>.unmodifiable(
         <PluginId, List<PluginFailure>>{
           for (final entry in failures.entries)
             entry.key: List<PluginFailure>.unmodifiable(entry.value),
         },
       );

  final Map<PluginId, PluginResolution> plugins;
  final List<PluginId> available;
  final List<PluginId> activationOrder;
  final Map<PluginId, List<PluginFailure>> failures;
}

void _propagateUnavailable(
  List<PluginManifest> manifests,
  Map<PluginId, List<_Dependency>> dependencies,
  Set<PluginId> unavailable,
) {
  var changed = true;
  while (changed) {
    changed = false;
    for (final manifest in manifests) {
      if (unavailable.contains(manifest.id)) {
        continue;
      }
      if (dependencies[manifest.id]!.any(
        (dependency) => unavailable.contains(dependency.providerId),
      )) {
        unavailable.add(manifest.id);
        changed = true;
      }
    }
  }
}

List<List<PluginId>> _findCycleComponents(
  List<PluginManifest> manifests,
  Map<PluginId, int> inputIndexes,
  Map<PluginId, List<_Dependency>> dependencies,
  Set<PluginId> candidates,
) {
  var nextIndex = 0;
  final indexes = <PluginId, int>{};
  final lowLinks = <PluginId, int>{};
  final stack = <PluginId>[];
  final onStack = <PluginId>{};
  final cycles = <List<PluginId>>[];

  void visit(PluginId id) {
    indexes[id] = nextIndex;
    lowLinks[id] = nextIndex;
    nextIndex++;
    stack.add(id);
    onStack.add(id);

    for (final dependency in dependencies[id]!) {
      final providerId = dependency.providerId;
      if (!candidates.contains(providerId)) {
        continue;
      }
      if (!indexes.containsKey(providerId)) {
        visit(providerId);
        lowLinks[id] = _minimum(lowLinks[id]!, lowLinks[providerId]!);
      } else if (onStack.contains(providerId)) {
        lowLinks[id] = _minimum(lowLinks[id]!, indexes[providerId]!);
      }
    }

    if (lowLinks[id] != indexes[id]) {
      return;
    }
    final component = <PluginId>[];
    PluginId member;
    do {
      member = stack.removeLast();
      onStack.remove(member);
      component.add(member);
    } while (member != id);

    final hasSelfEdge =
        component.length == 1 &&
        dependencies[id]!.any((dependency) => dependency.providerId == id);
    if (component.length > 1 || hasSelfEdge) {
      component.sort(
        (left, right) => inputIndexes[left]!.compareTo(inputIndexes[right]!),
      );
      cycles.add(List<PluginId>.unmodifiable(component));
    }
  }

  for (final manifest in manifests) {
    if (candidates.contains(manifest.id) && !indexes.containsKey(manifest.id)) {
      visit(manifest.id);
    }
  }
  return cycles;
}

List<PluginFailure> _failuresFor(
  PluginManifest manifest,
  PluginTarget target,
  Map<String, _Provider> providers,
  Set<PluginId> unavailable,
  Map<PluginId, List<PluginId>> cycleByPlugin,
) {
  if (!manifest.targets.contains(target)) {
    return <PluginFailure>[
      PluginFailure(
        'resolution.unsupported_target',
        'The plugin does not support the requested target.',
        <String, Object?>{'pluginId': manifest.id.value, 'target': target.name},
      ),
    ];
  }

  final failures = <PluginFailure>[];
  final cycle = cycleByPlugin[manifest.id];
  for (final requirement in manifest.requires) {
    final provider = providers[requirement.id];
    if (provider == null) {
      failures.add(
        PluginFailure(
          'resolution.missing_capability',
          'No plugin provides the required capability.',
          <String, Object?>{
            'pluginId': manifest.id.value,
            'capabilityId': requirement.id,
            'requiredVersion': requirement.version,
          },
        ),
      );
    } else if (provider.descriptor.version < requirement.version) {
      failures.add(
        PluginFailure(
          'resolution.capability_version_too_low',
          'The provided capability version is below the required version.',
          <String, Object?>{
            'pluginId': manifest.id.value,
            'capabilityId': requirement.id,
            'requiredVersion': requirement.version,
            'providedVersion': provider.descriptor.version,
            'providerId': provider.manifest.id.value,
          },
        ),
      );
    } else if (unavailable.contains(provider.manifest.id) &&
        !(cycle?.contains(provider.manifest.id) ?? false)) {
      failures.add(
        PluginFailure(
          'resolution.provider_unavailable',
          'The capability provider is unavailable.',
          <String, Object?>{
            'pluginId': manifest.id.value,
            'capabilityId': requirement.id,
            'providerId': provider.manifest.id.value,
          },
        ),
      );
    }
  }

  if (cycle != null) {
    failures.add(
      PluginFailure(
        'resolution.dependency_cycle',
        'The plugin is part of a dependency cycle.',
        <String, Object?>{
          'pluginId': manifest.id.value,
          'cyclePluginIds': List<String>.unmodifiable(
            cycle.map((id) => id.value),
          ),
        },
      ),
    );
  }
  return failures;
}

List<PluginId> _activationOrder(
  List<PluginManifest> manifests,
  Map<PluginId, List<_Dependency>> dependencies,
  List<PluginId> available,
) {
  final availableSet = available.toSet();
  final indegrees = <PluginId, int>{for (final id in available) id: 0};
  final consumers = <PluginId, List<PluginId>>{
    for (final id in available) id: <PluginId>[],
  };
  for (final manifest in manifests) {
    if (!availableSet.contains(manifest.id)) {
      continue;
    }
    for (final dependency in dependencies[manifest.id]!) {
      if (availableSet.contains(dependency.providerId)) {
        indegrees[manifest.id] = indegrees[manifest.id]! + 1;
        consumers[dependency.providerId]!.add(manifest.id);
      }
    }
  }

  final order = <PluginId>[];
  final emitted = <PluginId>{};
  while (order.length < available.length) {
    PluginId? next;
    for (final manifest in manifests) {
      if (availableSet.contains(manifest.id) &&
          !emitted.contains(manifest.id) &&
          indegrees[manifest.id] == 0) {
        next = manifest.id;
        break;
      }
    }
    if (next == null) {
      break;
    }
    emitted.add(next);
    order.add(next);
    for (final consumerId in consumers[next]!) {
      indegrees[consumerId] = indegrees[consumerId]! - 1;
    }
  }
  return order;
}

int _minimum(int left, int right) => left < right ? left : right;

final class _Provider {
  const _Provider(this.manifest, this.descriptor);

  final PluginManifest manifest;
  final CapabilityDescriptor descriptor;
}

final class _Dependency {
  const _Dependency(this.providerId);

  final PluginId providerId;
}

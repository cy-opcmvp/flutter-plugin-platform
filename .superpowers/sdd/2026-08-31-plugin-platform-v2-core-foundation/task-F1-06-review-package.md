# F1-06 review package — complete filesystem snapshot

Captured: 2026-09-01T20:10:00+08:00

No Git operations. Resolver source/test were absent; runtime export had accepted F1-04/F1-05 exports.

| File | Baseline | SHA-256 |
|---|---|---|
| `v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart` | absent | `BE1772BDFB38FE0AB590102F8A2122E23AB0A97B678E1CE3BCB1D0D6E87ADE21` |
| `v2/packages/plugin_runtime/test/resolution/plugin_resolver_test.dart` | absent | `034C11E7A72E6311043CF3095359FBDCB93BA0BA2833F38F779131B92A66D375` |
| `v2/packages/plugin_runtime/lib/plugin_runtime.dart` | accepted prior exports | `F41C10976FF90C54A7D8550F36737623F285D81CB381A93C5C28C9BC1BB5AFCF` |

## `v2/packages/plugin_runtime/lib/src/resolution/plugin_resolver.dart`

```dart
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

```

## `v2/packages/plugin_runtime/test/resolution/plugin_resolver_test.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_runtime/plugin_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('explicit target filtering preserves supported input order', () {
    final first = _manifest('tools.first');
    final unsupported = _manifest(
      'tools.unsupported',
      targets: const <PluginTarget>[PluginTarget.macos],
    );
    final last = _manifest('tools.last');

    final result = PluginResolver.resolve(<PluginManifest>[
      first,
      unsupported,
      last,
    ], PluginTarget.windows);

    expect(result.plugins.keys, <PluginId>[first.id, unsupported.id, last.id]);
    expect(result.available, <PluginId>[first.id, last.id]);
    expect(result.activationOrder, <PluginId>[first.id, last.id]);
    expect(result.plugins[first.id]!.available, isTrue);
    final resolution = result.plugins[unsupported.id]!;
    expect(resolution.available, isFalse);
    expect(resolution.manifest, same(unsupported));
    expect(resolution.failures, hasLength(1));
    expect(resolution.failures.single.code, 'resolution.unsupported_target');
    expect(resolution.failures.single.message.trim(), isNotEmpty);
    expect(resolution.failures.single.details, <String, Object?>{
      'pluginId': 'tools.unsupported',
      'target': 'windows',
    });
    expect(result.failures.keys, <PluginId>[unsupported.id]);
    expect(result.failures[unsupported.id], resolution.failures);
    expect(() => result.plugins.remove(first.id), throwsUnsupportedError);
    expect(() => result.available.clear(), throwsUnsupportedError);
    expect(() => result.activationOrder.clear(), throwsUnsupportedError);
    expect(() => result.failures.clear(), throwsUnsupportedError);
    expect(
      () => result.failures[unsupported.id]!.clear(),
      throwsUnsupportedError,
    );
    expect(() => resolution.failures.clear(), throwsUnsupportedError);
    expect(
      () => resolution.failures.single.details['extra'] = true,
      throwsUnsupportedError,
    );
  });

  test('dependency chain keeps provider order and stable ties', () {
    final independent = _manifest('tools.independent');
    final downstream = _manifest(
      'tools.downstream',
      requires: <CapabilityRequirement>[
        CapabilityRequirement('tools.output', 1),
      ],
    );
    final consumer = _manifest(
      'tools.consumer',
      provides: <CapabilityDescriptor>[CapabilityDescriptor('tools.output', 1)],
      requires: <CapabilityRequirement>[
        CapabilityRequirement('tools.source', 1),
      ],
    );
    final provider = _manifest(
      'tools.provider',
      provides: <CapabilityDescriptor>[CapabilityDescriptor('tools.source', 2)],
    );
    final manifests = <PluginManifest>[
      independent,
      downstream,
      consumer,
      provider,
    ];

    final result = PluginResolver.resolve(manifests, PluginTarget.windows);

    expect(result.available, <PluginId>[
      independent.id,
      downstream.id,
      consumer.id,
      provider.id,
    ]);
    expect(result.activationOrder, <PluginId>[
      independent.id,
      provider.id,
      consumer.id,
      downstream.id,
    ]);
    expect(result.failures, isEmpty);
    expect(manifests, <PluginManifest>[
      independent,
      downstream,
      consumer,
      provider,
    ]);
  });

  test('failure views match missing and insufficient capabilities', () {
    final cases = <_FailureCase>[
      (
        manifests: <PluginManifest>[
          _manifest(
            'tools.missing.consumer',
            requires: <CapabilityRequirement>[
              CapabilityRequirement('tools.absent', 3),
            ],
          ),
        ],
        consumerId: PluginId.parse('tools.missing.consumer'),
        code: 'resolution.missing_capability',
        details: <String, Object?>{
          'pluginId': 'tools.missing.consumer',
          'capabilityId': 'tools.absent',
          'requiredVersion': 3,
        },
      ),
      (
        manifests: <PluginManifest>[
          _manifest(
            'tools.low.provider',
            provides: <CapabilityDescriptor>[
              CapabilityDescriptor('tools.versioned', 2),
            ],
          ),
          _manifest(
            'tools.low.consumer',
            requires: <CapabilityRequirement>[
              CapabilityRequirement('tools.versioned', 3),
            ],
          ),
        ],
        consumerId: PluginId.parse('tools.low.consumer'),
        code: 'resolution.capability_version_too_low',
        details: <String, Object?>{
          'pluginId': 'tools.low.consumer',
          'capabilityId': 'tools.versioned',
          'requiredVersion': 3,
          'providedVersion': 2,
          'providerId': 'tools.low.provider',
        },
      ),
    ];

    for (final testCase in cases) {
      final result = PluginResolver.resolve(
        testCase.manifests,
        PluginTarget.windows,
      );
      final resolution = result.plugins[testCase.consumerId]!;

      expect(resolution.available, isFalse);
      expect(resolution.failures, hasLength(1));
      expect(resolution.failures.single.code, testCase.code);
      expect(resolution.failures.single.message.trim(), isNotEmpty);
      expect(resolution.failures.single.details, testCase.details);
      expect(result.failures.keys, contains(testCase.consumerId));
      expect(result.failures[testCase.consumerId], resolution.failures);
    }
  });

  test('an unavailable target provider propagates to its consumer', () {
    final provider = _manifest(
      'tools.remote.provider',
      targets: const <PluginTarget>[PluginTarget.macos],
      provides: <CapabilityDescriptor>[CapabilityDescriptor('tools.remote', 1)],
    );
    final consumer = _manifest(
      'tools.remote.consumer',
      requires: <CapabilityRequirement>[
        CapabilityRequirement('tools.remote', 1),
      ],
    );

    final result = PluginResolver.resolve(<PluginManifest>[
      provider,
      consumer,
    ], PluginTarget.windows);

    expect(result.available, isEmpty);
    expect(result.activationOrder, isEmpty);
    expect(
      result.plugins[provider.id]!.failures.single.code,
      'resolution.unsupported_target',
    );
    final failure = result.plugins[consumer.id]!.failures.single;
    expect(failure.code, 'resolution.provider_unavailable');
    expect(failure.message.trim(), isNotEmpty);
    expect(failure.details, <String, Object?>{
      'pluginId': 'tools.remote.consumer',
      'capabilityId': 'tools.remote',
      'providerId': 'tools.remote.provider',
    });
  });

  test('a two-plugin cycle marks both members with stable cycle ids', () {
    final second = _manifest(
      'tools.cycle.second',
      provides: <CapabilityDescriptor>[
        CapabilityDescriptor('tools.cycle.b', 1),
      ],
      requires: <CapabilityRequirement>[
        CapabilityRequirement('tools.cycle.a', 1),
      ],
    );
    final first = _manifest(
      'tools.cycle.first',
      provides: <CapabilityDescriptor>[
        CapabilityDescriptor('tools.cycle.a', 1),
      ],
      requires: <CapabilityRequirement>[
        CapabilityRequirement('tools.cycle.b', 1),
      ],
    );

    final result = PluginResolver.resolve(<PluginManifest>[
      second,
      first,
    ], PluginTarget.windows);

    expect(result.available, isEmpty);
    expect(result.activationOrder, isEmpty);
    for (final id in <PluginId>[second.id, first.id]) {
      final failure = result.plugins[id]!.failures.single;
      expect(failure.code, 'resolution.dependency_cycle');
      expect(failure.message.trim(), isNotEmpty);
      expect(failure.details['pluginId'], id.value);
      expect(failure.details['cyclePluginIds'], <String>[
        'tools.cycle.second',
        'tools.cycle.first',
      ]);
      expect(
        () => (failure.details['cyclePluginIds']! as List<String>).clear(),
        throwsUnsupportedError,
      );
    }
    expect(result.failures.keys, <PluginId>[second.id, first.id]);
  });
}

typedef _FailureCase = ({
  List<PluginManifest> manifests,
  PluginId consumerId,
  String code,
  Map<String, Object?> details,
});

PluginManifest _manifest(
  String id, {
  List<PluginTarget> targets = const <PluginTarget>[PluginTarget.windows],
  List<CapabilityDescriptor> provides = const <CapabilityDescriptor>[],
  List<CapabilityRequirement> requires = const <CapabilityRequirement>[],
}) => PluginManifest(
  id: PluginId.parse(id),
  name: id,
  version: '1.0.0',
  apiVersion: 1,
  kind: PluginKind.builtin,
  targets: targets,
  entrypoint: 'main',
  provides: provides,
  requires: requires,
  surfaces: const <String>[],
  configSchemaVersion: 1,
  dataSchemaVersion: 1,
);

```

## `v2/packages/plugin_runtime/lib/plugin_runtime.dart`

```dart
export 'src/capability/capability_catalog.dart';
export 'src/lifecycle/lifecycle_machine.dart';
export 'src/registry/plugin_registration.dart';
export 'src/registry/plugin_registry.dart';
export 'src/resolution/plugin_resolver.dart';

```

## Controller verification

- Resolver 5/5; runtime 26/26; contracts 48/48; all exit 0.
- Workspace format: 22 files, 0 changed; analyze: no issues.
- Forbidden Platform/env/filesystem/I/O/Flutter/FFI/registry/catalog lookup scan: zero matches.
- Three restored mutations detected: dependency direction/order, provider-unavailable propagation, cycle marking.
- Tests are exactly five scenario groups and follow the global minimal/parameterized policy.


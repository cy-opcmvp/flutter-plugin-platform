# F1-05 review package — complete filesystem baseline-to-head snapshot

Captured: 2026-08-31T23:40:00+08:00

This project forbids AI Git operations. The five planned source/test files were absent at baseline; the runtime export contained only the accepted lifecycle export.

## Summary

| File | Baseline | Head SHA-256 |
|---|---|---|
| `v2/packages/plugin_runtime/lib/src/registry/plugin_registration.dart` | absent | `33993299AC43E38FE405190A5503BC5DA9CD44B0744C7E8163CFE6D8FD23A74D` |
| `v2/packages/plugin_runtime/lib/src/registry/plugin_registry.dart` | absent | `FA83BD2CC22DCC80C8D58234A05B95408848F5A938926DE015F09A6E41B43674` |
| `v2/packages/plugin_runtime/lib/src/capability/capability_catalog.dart` | absent | `B752E65EE39C1ED58C6509216C78CF4FC46584A20AD4E352FFA6E6CB38E73EEC` |
| `v2/packages/plugin_runtime/test/registry/plugin_registry_test.dart` | absent | `92B56E89B3EEC1BF2C120F98A6F4CA1788D983063D547DA39AFE90382773272B` |
| `v2/packages/plugin_runtime/test/capability/capability_catalog_test.dart` | absent | `FD47153CE1E114721172FEB0FFAF78E49B6842D48E93F3605F7FBC83C6493225` |
| `v2/packages/plugin_runtime/lib/plugin_runtime.dart` | accepted lifecycle export | `58EB1621875CEFE28F636EBFE8A1AA3D6D9A70F1BCE717056BD01B0DDF311791` |

## Complete snapshot

### `v2/packages/plugin_runtime/lib/src/registry/plugin_registration.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';

final class PluginRegistration {
  PluginRegistration(this.manifest);

  final PluginManifest manifest;

  PluginId get id => manifest.id;
}

```

### `v2/packages/plugin_runtime/lib/src/registry/plugin_registry.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';

import '../capability/capability_catalog.dart';
import 'plugin_registration.dart';

final class PluginRegistry {
  PluginRegistry()
    : _registrations = Map<PluginId, PluginRegistration>.unmodifiable(
        const <PluginId, PluginRegistration>{},
      ),
      _capabilityCatalog = CapabilityCatalog.build(
        const <PluginRegistration>[],
      ).catalog!;

  Map<PluginId, PluginRegistration> _registrations;
  CapabilityCatalog _capabilityCatalog;

  Map<PluginId, PluginRegistration> get registrations =>
      Map<PluginId, PluginRegistration>.unmodifiable(_registrations);

  PluginRegistration? lookup(PluginId id) => _registrations[id];

  CapabilityCatalog get capabilityCatalog => _capabilityCatalog;

  RegistryMutationResult register(PluginRegistration registration) {
    if (_registrations.containsKey(registration.id)) {
      return RegistryMutationResult._(
        failure: PluginFailure(
          'registry.duplicate_plugin',
          'A plugin with this ID is already registered.',
          <String, Object?>{'pluginId': registration.id.value},
        ),
      );
    }

    final candidate = Map<PluginId, PluginRegistration>.of(_registrations)
      ..[registration.id] = registration;
    return _commitCandidate(candidate);
  }

  RegistryMutationResult unregister(PluginId id) {
    if (!_registrations.containsKey(id)) {
      return RegistryMutationResult._(
        failure: PluginFailure(
          'registry.plugin_not_found',
          'No plugin with this ID is registered.',
          <String, Object?>{'pluginId': id.value},
        ),
      );
    }

    final candidate = Map<PluginId, PluginRegistration>.of(_registrations)
      ..remove(id);
    return _commitCandidate(candidate);
  }

  RegistryMutationResult _commitCandidate(
    Map<PluginId, PluginRegistration> candidate,
  ) {
    final catalogResult = CapabilityCatalog.build(candidate.values);
    if (!catalogResult.succeeded) {
      return RegistryMutationResult._(failure: catalogResult.failure);
    }

    _registrations = Map<PluginId, PluginRegistration>.unmodifiable(candidate);
    _capabilityCatalog = catalogResult.catalog!;
    return RegistryMutationResult._();
  }
}

final class RegistryMutationResult {
  RegistryMutationResult._({this.failure});

  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

```

### `v2/packages/plugin_runtime/lib/src/capability/capability_catalog.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';

import '../registry/plugin_registration.dart';

final class CapabilityCatalog {
  CapabilityCatalog._(Map<String, _CapabilityProvider> providers)
    : _providers = Map<String, _CapabilityProvider>.unmodifiable(providers);

  final Map<String, _CapabilityProvider> _providers;

  static CapabilityCatalogBuildResult build(
    Iterable<PluginRegistration> registrations,
  ) {
    final providers = <String, _CapabilityProvider>{};
    for (final registration in registrations) {
      for (final descriptor in registration.manifest.provides) {
        final existing = providers[descriptor.id];
        if (existing != null) {
          return CapabilityCatalogBuildResult._(
            failure: PluginFailure(
              'capability.duplicate_provider',
              'Multiple plugins provide the same capability.',
              <String, Object?>{
                'capabilityId': descriptor.id,
                'existingProvider': existing.pluginId.value,
                'conflictingProvider': registration.id.value,
              },
            ),
          );
        }

        providers[descriptor.id] = _CapabilityProvider(
          registration.id,
          descriptor,
        );
      }
    }

    return CapabilityCatalogBuildResult._(
      catalog: CapabilityCatalog._(providers),
    );
  }

  CapabilityResolution resolve(CapabilityRequirement requirement) {
    final provider = _providers[requirement.id];
    if (provider == null) {
      return CapabilityResolution._(
        requirement: requirement,
        failure: PluginFailure(
          'capability.missing',
          'No plugin provides the required capability.',
          <String, Object?>{
            'capabilityId': requirement.id,
            'requiredVersion': requirement.version,
          },
        ),
      );
    }

    if (provider.descriptor.version < requirement.version) {
      return CapabilityResolution._(
        requirement: requirement,
        failure: PluginFailure(
          'capability.version_too_low',
          'The provided capability version is below the required version.',
          <String, Object?>{
            'capabilityId': requirement.id,
            'requiredVersion': requirement.version,
            'providedVersion': provider.descriptor.version,
            'providerId': provider.pluginId.value,
          },
        ),
      );
    }

    return CapabilityResolution._(
      requirement: requirement,
      providerId: provider.pluginId,
      descriptor: provider.descriptor,
    );
  }
}

final class CapabilityCatalogBuildResult {
  CapabilityCatalogBuildResult._({this.catalog, this.failure});

  final CapabilityCatalog? catalog;
  final PluginFailure? failure;

  bool get succeeded => failure == null;
}

final class CapabilityResolution {
  CapabilityResolution._({
    required this.requirement,
    this.providerId,
    this.descriptor,
    this.failure,
  });

  final CapabilityRequirement requirement;
  final PluginId? providerId;
  final CapabilityDescriptor? descriptor;
  final PluginFailure? failure;

  bool get available => failure == null;
}

final class _CapabilityProvider {
  const _CapabilityProvider(this.pluginId, this.descriptor);

  final PluginId pluginId;
  final CapabilityDescriptor descriptor;
}

```

### `v2/packages/plugin_runtime/test/registry/plugin_registry_test.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_runtime/plugin_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('registers manifests and exposes snapshot state and capabilities', () {
    final registry = PluginRegistry();
    final calculator = PluginRegistration(
      _manifest('tools.calculator', 'tools.calculate', 2),
    );
    final clock = PluginRegistration(_manifest('tools.clock', 'tools.time', 4));

    expect(registry.register(calculator).succeeded, isTrue);
    final firstSnapshot = registry.registrations;
    expect(registry.register(clock).succeeded, isTrue);

    expect(firstSnapshot, <PluginId, PluginRegistration>{
      calculator.id: calculator,
    });
    expect(registry.registrations, <PluginId, PluginRegistration>{
      calculator.id: calculator,
      clock.id: clock,
    });
    expect(registry.lookup(calculator.id), same(calculator));
    expect(() => firstSnapshot[clock.id] = clock, throwsUnsupportedError);

    final cases = <({String capabilityId, PluginRegistration provider})>[
      (capabilityId: 'tools.calculate', provider: calculator),
      (capabilityId: 'tools.time', provider: clock),
    ];
    for (final testCase in cases) {
      final resolution = registry.capabilityCatalog.resolve(
        CapabilityRequirement(testCase.capabilityId, 1),
      );

      expect(resolution.available, isTrue);
      expect(resolution.requirement.id, testCase.capabilityId);
      expect(resolution.providerId, testCase.provider.id);
      expect(
        resolution.descriptor,
        same(testCase.provider.manifest.provides.single),
      );
      expect(resolution.failure, isNull);
    }
  });

  final rejectionCases =
      <
        ({
          String name,
          RegistryMutationResult Function(PluginRegistry, PluginRegistration)
          mutate,
          String code,
          String rejectedId,
        })
      >[
        (
          name: 'duplicate plugin ID',
          mutate: (registry, existing) => registry.register(
            PluginRegistration(
              _manifest(existing.id.value, 'tools.alternate', 1),
            ),
          ),
          code: 'registry.duplicate_plugin',
          rejectedId: 'tools.calculator',
        ),
        (
          name: 'unknown unregister',
          mutate: (registry, _) =>
              registry.unregister(PluginId.parse('tools.unknown')),
          code: 'registry.plugin_not_found',
          rejectedId: 'tools.unknown',
        ),
      ];

  for (final testCase in rejectionCases) {
    test('${testCase.name} rejects without changing state', () {
      final registry = PluginRegistry();
      final existing = PluginRegistration(
        _manifest('tools.calculator', 'tools.calculate', 2),
      );
      expect(registry.register(existing).succeeded, isTrue);
      final before = registry.registrations;

      final result = testCase.mutate(registry, existing);

      expect(result.succeeded, isFalse);
      expect(result.failure, isNotNull);
      expect(result.failure!.code, testCase.code);
      expect(result.failure!.message.trim(), isNotEmpty);
      expect(result.failure!.details, <String, Object?>{
        'pluginId': testCase.rejectedId,
      });
      expect(registry.registrations, before);
      final resolution = registry.capabilityCatalog.resolve(
        CapabilityRequirement('tools.calculate', 1),
      );
      expect(resolution.available, isTrue);
      expect(resolution.providerId, existing.id);
    });
  }

  test('provider conflict rejects the whole registration atomically', () {
    final registry = PluginRegistry();
    final existing = PluginRegistration(
      _manifest('tools.calculator', 'tools.calculate', 2),
    );
    final conflicting = PluginRegistration(
      _manifest('tools.alternate', 'tools.calculate', 3),
    );
    expect(registry.register(existing).succeeded, isTrue);

    final result = registry.register(conflicting);

    expect(result.succeeded, isFalse);
    expect(result.failure!.code, 'capability.duplicate_provider');
    expect(registry.registrations, <PluginId, PluginRegistration>{
      existing.id: existing,
    });
    expect(registry.lookup(conflicting.id), isNull);
    final resolution = registry.capabilityCatalog.resolve(
      CapabilityRequirement('tools.calculate', 2),
    );
    expect(resolution.available, isTrue);
    expect(resolution.providerId, existing.id);
    expect(resolution.descriptor, same(existing.manifest.provides.single));
  });

  test('unregister removes the registration and its capabilities together', () {
    final registry = PluginRegistry();
    final registration = PluginRegistration(
      _manifest('tools.calculator', 'tools.calculate', 2),
    );
    expect(registry.register(registration).succeeded, isTrue);

    final result = registry.unregister(registration.id);

    expect(result.succeeded, isTrue);
    expect(result.failure, isNull);
    expect(registry.registrations, isEmpty);
    expect(registry.lookup(registration.id), isNull);
    final resolution = registry.capabilityCatalog.resolve(
      CapabilityRequirement('tools.calculate', 1),
    );
    expect(resolution.available, isFalse);
    expect(resolution.providerId, isNull);
    expect(resolution.descriptor, isNull);
    expect(resolution.failure!.code, 'capability.missing');
  });
}

PluginManifest _manifest(
  String pluginId,
  String capabilityId,
  int capabilityVersion,
) => PluginManifest(
  id: PluginId.parse(pluginId),
  name: pluginId,
  version: '1.0.0',
  apiVersion: 1,
  kind: PluginKind.builtin,
  targets: const <PluginTarget>[PluginTarget.windows],
  entrypoint: 'main',
  provides: <CapabilityDescriptor>[
    CapabilityDescriptor(capabilityId, capabilityVersion),
  ],
  requires: const <CapabilityRequirement>[],
  surfaces: const <String>[],
  configSchemaVersion: 1,
  dataSchemaVersion: 1,
);

```

### `v2/packages/plugin_runtime/test/capability/capability_catalog_test.dart`

```dart
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_runtime/plugin_runtime.dart';
import 'package:test/test.dart';

void main() {
  test('build resolves exact and higher provider versions', () {
    final exact = PluginRegistration(
      _manifest('tools.calculator', 'tools.calculate', 3),
    );
    final higher = PluginRegistration(
      _manifest('tools.clock', 'tools.time', 5),
    );

    final build = CapabilityCatalog.build(<PluginRegistration>[exact, higher]);

    expect(build.succeeded, isTrue);
    expect(build.catalog, isNotNull);
    expect(build.failure, isNull);
    final cases =
        <({CapabilityRequirement requirement, PluginRegistration provider})>[
          (
            requirement: CapabilityRequirement('tools.calculate', 3),
            provider: exact,
          ),
          (
            requirement: CapabilityRequirement('tools.time', 3),
            provider: higher,
          ),
        ];
    for (final testCase in cases) {
      final resolution = build.catalog!.resolve(testCase.requirement);

      expect(resolution.available, isTrue);
      expect(resolution.requirement, same(testCase.requirement));
      expect(resolution.providerId, testCase.provider.id);
      expect(
        resolution.descriptor,
        same(testCase.provider.manifest.provides.single),
      );
      expect(resolution.failure, isNull);
    }
  });

  test('resolve reports missing and insufficient capabilities', () {
    final provider = PluginRegistration(
      _manifest('tools.calculator', 'tools.calculate', 2),
    );
    final catalog = CapabilityCatalog.build(<PluginRegistration>[
      provider,
    ]).catalog!;
    final cases =
        <
          ({
            CapabilityRequirement requirement,
            String code,
            Map<String, Object?> details,
          })
        >[
          (
            requirement: CapabilityRequirement('tools.missing', 1),
            code: 'capability.missing',
            details: <String, Object?>{
              'capabilityId': 'tools.missing',
              'requiredVersion': 1,
            },
          ),
          (
            requirement: CapabilityRequirement('tools.calculate', 3),
            code: 'capability.version_too_low',
            details: <String, Object?>{
              'capabilityId': 'tools.calculate',
              'requiredVersion': 3,
              'providedVersion': 2,
              'providerId': 'tools.calculator',
            },
          ),
        ];

    for (final testCase in cases) {
      final resolution = catalog.resolve(testCase.requirement);

      expect(resolution.available, isFalse);
      expect(resolution.requirement, same(testCase.requirement));
      expect(resolution.providerId, isNull);
      expect(resolution.descriptor, isNull);
      expect(resolution.failure, isNotNull);
      expect(resolution.failure!.code, testCase.code);
      expect(resolution.failure!.message.trim(), isNotEmpty);
      expect(resolution.failure!.details, testCase.details);
      expect(
        () => resolution.failure!.details['extra'] = true,
        throwsUnsupportedError,
      );
    }
  });

  test('duplicate provider build fails without a partial catalog', () {
    final existing = PluginRegistration(
      _manifest('tools.calculator', 'tools.calculate', 2),
    );
    final conflicting = PluginRegistration(
      _manifest('tools.alternate', 'tools.calculate', 3),
    );

    final result = CapabilityCatalog.build(<PluginRegistration>[
      existing,
      conflicting,
    ]);

    expect(result.succeeded, isFalse);
    expect(result.catalog, isNull);
    expect(result.failure, isNotNull);
    expect(result.failure!.code, 'capability.duplicate_provider');
    expect(result.failure!.message.trim(), isNotEmpty);
    expect(result.failure!.details, <String, Object?>{
      'capabilityId': 'tools.calculate',
      'existingProvider': 'tools.calculator',
      'conflictingProvider': 'tools.alternate',
    });
  });
}

PluginManifest _manifest(
  String pluginId,
  String capabilityId,
  int capabilityVersion,
) => PluginManifest(
  id: PluginId.parse(pluginId),
  name: pluginId,
  version: '1.0.0',
  apiVersion: 1,
  kind: PluginKind.builtin,
  targets: const <PluginTarget>[PluginTarget.windows],
  entrypoint: 'main',
  provides: <CapabilityDescriptor>[
    CapabilityDescriptor(capabilityId, capabilityVersion),
  ],
  requires: const <CapabilityRequirement>[],
  surfaces: const <String>[],
  configSchemaVersion: 1,
  dataSchemaVersion: 1,
);

```

### `v2/packages/plugin_runtime/lib/plugin_runtime.dart`

```dart
export 'src/capability/capability_catalog.dart';
export 'src/lifecycle/lifecycle_machine.dart';
export 'src/registry/plugin_registration.dart';
export 'src/registry/plugin_registry.dart';

```

## Fresh controller verification

- Runtime focused registry/catalog: exit 0, 8/8.
- Runtime full: exit 0, 21/21.
- Contracts full: exit 0, 48/48.
- Workspace format: exit 0, 20 files, 0 changed.
- Workspace analyze: exit 0, no issues.
- Forbidden dependency/pattern scan: zero matches.

## Scope and policy

- Authored task changes are exactly the six files above plus `task-F1-05-report.md`.
- The report records three restored live mutations: conflict partial state, stale catalog after unregister, and reversed version comparison.
- Global TDD/output policy is binding: keep main and critical exception scenarios only, parameterize repeated case shapes, avoid redundant independent tests/comments, and do not narrate TDD stages or reproduce full old files during iteration.
- No Git, subagents, plugin execution, singleton/service locator, platform/Flutter/I/O/FFI, or F1-06 resolver.


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

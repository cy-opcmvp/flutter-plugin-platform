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

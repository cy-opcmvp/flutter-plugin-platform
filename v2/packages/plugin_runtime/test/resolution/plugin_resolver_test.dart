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

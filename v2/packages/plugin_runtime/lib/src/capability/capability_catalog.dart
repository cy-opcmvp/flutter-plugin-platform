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

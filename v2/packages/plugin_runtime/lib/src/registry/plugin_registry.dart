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

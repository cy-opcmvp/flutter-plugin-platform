import '../models/feature_metadata.dart';

/// Feature Manager
///
/// Centralized service for managing platform features including their
/// metadata, availability, and relationships. This service provides
/// a single source of truth for feature states across the application.
class FeatureManager {
  FeatureManager._();

  /// Singleton instance
  static final FeatureManager instance = FeatureManager._();

  /// All registered features with their metadata
  static const Map<String, FeatureMetadata> _features = {
    'plugin_management': FeatureMetadata(
      id: 'plugin_management',
      status: FeatureStatus.implemented,
      sinceVersion: '1.0.0',
    ),
    'local_storage': FeatureMetadata(
      id: 'local_storage',
      status: FeatureStatus.implemented,
      sinceVersion: '1.0.0',
    ),
    'offline_plugins': FeatureMetadata(
      id: 'offline_plugins',
      status: FeatureStatus.implemented,
      sinceVersion: '1.0.0',
    ),
    'local_preferences': FeatureMetadata(
      id: 'local_preferences',
      status: FeatureStatus.implemented,
      sinceVersion: '1.0.0',
    ),
    'cloud_sync': FeatureMetadata(
      id: 'cloud_sync',
      status: FeatureStatus.partial,
      sinceVersion: '1.0.0',
    ),
    'multiplayer': FeatureMetadata(
      id: 'multiplayer',
      status: FeatureStatus.planned,
      plannedVersion: '2.0.0',
      dependencies: {'cloud_sync'},
    ),
    'online_plugins': FeatureMetadata(
      id: 'online_plugins',
      status: FeatureStatus.planned,
      plannedVersion: '2.0.0',
      dependencies: {'cloud_storage', 'remote_config'},
    ),
    'cloud_storage': FeatureMetadata(
      id: 'cloud_storage',
      status: FeatureStatus.planned,
      plannedVersion: '1.5.0',
      dependencies: {'cloud_sync'},
    ),
    'remote_config': FeatureMetadata(
      id: 'remote_config',
      status: FeatureStatus.planned,
      plannedVersion: '1.5.0',
    ),
  };

  /// Get metadata for a specific feature
  ///
  /// Returns null if feature is not registered
  FeatureMetadata? getFeature(String id) {
    return _features[id];
  }

  /// Get all registered features
  ///
  /// Returns a list of all feature metadata sorted by feature ID
  List<FeatureMetadata> getAllFeatures() {
    return _features.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Get features filtered by status
  ///
  /// Returns a list of features that match the given status
  List<FeatureMetadata> getFeaturesByStatus(FeatureStatus status) {
    return _features.values
        .where((f) => f.status == status)
        .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Get all available features (implemented or partial)
  ///
  /// This returns features that can actually be used by users
  List<FeatureMetadata> getAvailableFeatures() {
    return _features.values
        .where((f) => f.isAvailable)
        .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Get all planned features
  ///
  /// Returns features that are planned for future implementation
  List<FeatureMetadata> getPlannedFeatures() {
    return getFeaturesByStatus(FeatureStatus.planned);
  }

  /// Check if a feature is available for use
  ///
  /// Returns false if feature is not registered or not available
  bool isFeatureAvailable(String id) {
    final feature = _features[id];
    if (feature == null) return false;
    return feature.isAvailable;
  }

  /// Check if a feature is implemented (including partial/beta)
  ///
  /// Returns false if feature is not registered or not implemented
  bool isFeatureImplemented(String id) {
    final feature = _features[id];
    if (feature == null) return false;
    return feature.isImplemented;
  }

  /// Check if a feature's dependencies are satisfied
  ///
  /// Returns true if all dependencies are implemented/available
  /// Returns false if feature not found or any dependency is not met
  bool areDependenciesSatisfied(String id) {
    final feature = _features[id];
    if (feature == null) return false;

    for (final depId in feature.dependencies) {
      if (!isFeatureImplemented(depId)) {
        return false;
      }
    }
    return true;
  }

  /// Get features that depend on the given feature
  ///
  /// Returns a list of features that have this feature as a dependency
  List<FeatureMetadata> getDependentFeatures(String id) {
    return _features.values
        .where((f) => f.dependencies.contains(id))
        .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// Get features for a specific operation mode
  ///
  /// [modeFeatures] should be the set of feature IDs available in that mode
  /// Returns metadata for features that are both in the mode and implemented
  List<FeatureMetadata> getFeaturesForMode(Set<String> modeFeatures) {
    return modeFeatures
        .map((id) => _features[id])
        .whereType<FeatureMetadata>()
        .where((f) => f.isAvailable)
        .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  }
}

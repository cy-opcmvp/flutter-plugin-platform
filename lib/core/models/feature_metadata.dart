import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// Feature status enumeration
enum FeatureStatus {
  /// Feature is fully implemented and available
  implemented,

  /// Feature is partially implemented (beta/testing)
  partial,

  /// Feature is planned for future implementation
  planned,

  /// Feature is deprecated and should not be used
  deprecated,
}

/// Metadata for a platform feature
///
/// This class contains all metadata about a feature including its status,
/// version information, and dependencies. It provides methods to get
/// localized display names and descriptions.
class FeatureMetadata {
  const FeatureMetadata({
    required this.id,
    required this.status,
    this.sinceVersion,
    this.plannedVersion,
    this.dependencies = const {},
  });

  /// Unique feature identifier (e.g., 'cloud_sync', 'multiplayer')
  final String id;

  /// Current status of the feature
  final FeatureStatus status;

  /// Version when feature was implemented (if implemented)
  final String? sinceVersion;

  /// Version when feature is planned to be implemented (if planned)
  final String? plannedVersion;

  /// Other features this feature depends on
  final Set<String> dependencies;

  /// Get localized display name for this feature
  String getDisplayName(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (id) {
      case 'plugin_management':
        return l10n.feature_plugin_management;
      case 'local_storage':
        return l10n.feature_local_storage;
      case 'offline_plugins':
        return l10n.feature_offline_plugins;
      case 'local_preferences':
        return l10n.feature_local_preferences;
      case 'cloud_sync':
        return l10n.feature_cloud_sync;
      case 'multiplayer':
        return l10n.feature_multiplayer;
      case 'online_plugins':
        return l10n.feature_online_plugins;
      case 'cloud_storage':
        return l10n.feature_cloud_storage;
      case 'remote_config':
        return l10n.feature_remote_config;
      default:
        return id.toUpperCase();
    }
  }

  /// Get localized description for this feature
  String getDescription(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (id) {
      case 'plugin_management':
        return l10n.feature_plugin_management_desc;
      case 'local_storage':
        return l10n.feature_local_storage_desc;
      case 'offline_plugins':
        return l10n.feature_offline_plugins_desc;
      case 'local_preferences':
        return l10n.feature_local_preferences_desc;
      case 'cloud_sync':
        return l10n.feature_cloud_sync_desc;
      case 'multiplayer':
        return l10n.feature_multiplayer_desc;
      case 'online_plugins':
        return l10n.feature_online_plugins_desc;
      case 'cloud_storage':
        return l10n.feature_cloud_storage_desc;
      case 'remote_config':
        return l10n.feature_remote_config_desc;
      default:
        return '';
    }
  }

  /// Get localized status text for this feature
  String getStatusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case FeatureStatus.implemented:
        return l10n.feature_status_implemented;
      case FeatureStatus.partial:
        return l10n.feature_status_partial;
      case FeatureStatus.planned:
        return l10n.feature_status_planned;
      case FeatureStatus.deprecated:
        return l10n.feature_status_deprecated;
    }
  }

  /// Check if feature is available for use
  bool get isAvailable {
    return status == FeatureStatus.implemented ||
        status == FeatureStatus.partial;
  }

  /// Check if feature is implemented (including partial)
  bool get isImplemented {
    return status == FeatureStatus.implemented ||
        status == FeatureStatus.partial;
  }

  @override
  String toString() {
    return 'FeatureMetadata(id: $id, status: $status, '
        'sinceVersion: $sinceVersion, plannedVersion: $plannedVersion, '
        'dependencies: $dependencies)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FeatureMetadata &&
        other.id == id &&
        other.status == status &&
        other.sinceVersion == sinceVersion &&
        other.plannedVersion == plannedVersion &&
        _setEquals(other.dependencies, dependencies);
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  @override
  int get hashCode {
    return id.hashCode ^
        status.hashCode ^
        sinceVersion.hashCode ^
        plannedVersion.hashCode ^
        dependencies.hashCode;
  }
}

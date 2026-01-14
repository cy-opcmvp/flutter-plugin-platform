// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plugin Platform';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_save => 'Save';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_close => 'Close';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_search => 'Search';

  @override
  String get common_ok => 'OK';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_all => 'All';

  @override
  String get common_refresh => 'Refresh';

  @override
  String get common_back => 'Back';

  @override
  String get common_error => 'Error';

  @override
  String get common_success => 'Success';

  @override
  String get common_warning => 'Warning';

  @override
  String get common_info => 'Info';

  @override
  String get error_unknown => 'An unknown error occurred';

  @override
  String get error_network => 'Network connection failed';

  @override
  String error_loadFailed(String message) {
    return 'Failed to load: $message';
  }

  @override
  String error_operationFailed(String message) {
    return 'Operation failed: $message';
  }

  @override
  String error_initFailed(String message) {
    return 'Initialization failed: $message';
  }

  @override
  String error_platformInit(String message) {
    return 'Platform initialization failed: $message';
  }

  @override
  String get hint_searchPlugins => 'Search plugins...';

  @override
  String get hint_searchExternalPlugins => 'Search external plugins...';

  @override
  String get hint_inputRequired => 'This field is required';

  @override
  String get hint_noResults => 'No matching results found';

  @override
  String get hint_tryAdjustSearch =>
      'Try adjusting your search or filter criteria';

  @override
  String get button_launch => 'Launch';

  @override
  String get button_install => 'Install';

  @override
  String get button_uninstall => 'Uninstall';

  @override
  String get button_enable => 'Enable';

  @override
  String get button_disable => 'Disable';

  @override
  String get button_update => 'Update';

  @override
  String get button_rollback => 'Rollback';

  @override
  String get button_remove => 'Remove';

  @override
  String get button_updateAll => 'Update All';

  @override
  String get button_removeAll => 'Remove All';

  @override
  String get button_selectAll => 'Select All';

  @override
  String get button_deselectAll => 'Deselect All';

  @override
  String get button_multiSelect => 'Multi-select';

  @override
  String get button_enablePetMode => 'Enable Pet Mode';

  @override
  String get button_exitPetMode => 'Exit Pet Mode';

  @override
  String get dialog_confirmTitle => 'Confirm Action';

  @override
  String get dialog_uninstallPlugin =>
      'Are you sure you want to uninstall this plugin? This action cannot be undone.';

  @override
  String get dialog_removePlugin =>
      'Are you sure you want to remove this plugin? This action cannot be undone.';

  @override
  String get dialog_updatePlugin =>
      'Are you sure you want to update this plugin? A backup will be created for rollback if needed.';

  @override
  String get dialog_rollbackPlugin =>
      'Are you sure you want to rollback this plugin? This will undo the last update.';

  @override
  String dialog_batchUpdate(int count) {
    return 'Are you sure you want to update $count selected plugin(s)?';
  }

  @override
  String dialog_batchRemove(int count) {
    return 'Are you sure you want to remove $count selected plugin(s)? This action cannot be undone.';
  }

  @override
  String get plugin_title => 'Plugin Management';

  @override
  String get plugin_externalTitle => 'External Plugins';

  @override
  String get plugin_statusEnabled => 'Enabled';

  @override
  String get plugin_statusDisabled => 'Disabled';

  @override
  String get plugin_statusActive => 'Active';

  @override
  String get plugin_statusInactive => 'Inactive';

  @override
  String get plugin_statusPaused => 'Paused';

  @override
  String get plugin_statusError => 'Error';

  @override
  String get plugin_typeTool => 'Tool';

  @override
  String get plugin_typeGame => 'Game';

  @override
  String get plugin_typeAll => 'All Types';

  @override
  String get plugin_stateAll => 'All States';

  @override
  String get plugin_noPlugins => 'No Plugins Available';

  @override
  String get plugin_noExternalPlugins => 'No External Plugins Installed';

  @override
  String get plugin_installFirst => 'Install your first plugin to get started';

  @override
  String get plugin_installExternalFirst =>
      'Install your first external plugin to get started';

  @override
  String get plugin_noMatch => 'No plugins match your search';

  @override
  String get plugin_filterByType => 'Filter by type: ';

  @override
  String get plugin_filterByState => 'Filter by state';

  @override
  String plugin_launchSuccess(String name) {
    return 'Plugin $name launched';
  }

  @override
  String plugin_launchFailed(String message) {
    return 'Failed to launch plugin: $message';
  }

  @override
  String plugin_switchSuccess(String name) {
    return 'Switched to plugin $name';
  }

  @override
  String plugin_switchFailed(String message) {
    return 'Failed to switch plugin: $message';
  }

  @override
  String plugin_closeSuccess(String name) {
    return 'Plugin $name closed';
  }

  @override
  String plugin_pauseSuccess(String name) {
    return 'Plugin $name moved to background';
  }

  @override
  String get plugin_enableSuccess => 'Plugin enabled';

  @override
  String get plugin_disableSuccess => 'Plugin disabled';

  @override
  String get plugin_installSuccess => 'Sample plugin installed successfully';

  @override
  String get plugin_uninstallSuccess => 'Plugin uninstalled successfully';

  @override
  String get plugin_updateSuccess =>
      'Plugin updated successfully. Rollback available if needed.';

  @override
  String plugin_updateFailed(String message) {
    return 'Update failed and was rolled back: $message';
  }

  @override
  String get plugin_rollbackSuccess => 'Plugin rolled back successfully';

  @override
  String get plugin_removeSuccess => 'Plugin removed successfully';

  @override
  String plugin_operationFailed(String message) {
    return 'Plugin operation failed: $message';
  }

  @override
  String plugin_batchUpdateResult(int success, int failed) {
    return '$success updated, $failed failed';
  }

  @override
  String plugin_batchRemoveResult(int success, int failed) {
    return '$success removed, $failed failed';
  }

  @override
  String plugin_allUpdateSuccess(int count) {
    return 'All $count plugin(s) updated successfully';
  }

  @override
  String plugin_allRemoveSuccess(int count) {
    return 'All $count plugin(s) removed successfully';
  }

  @override
  String plugin_allUpdateFailed(int count) {
    return 'Failed to update all $count plugin(s)';
  }

  @override
  String plugin_allRemoveFailed(int count) {
    return 'Failed to remove all $count plugin(s)';
  }

  @override
  String plugin_selected(int count) {
    return '$count selected';
  }

  @override
  String get plugin_updating => 'Updating plugin...';

  @override
  String plugin_updatingBatch(int count) {
    return 'Updating $count plugin(s)...';
  }

  @override
  String get plugin_removing => 'Removing plugin...';

  @override
  String plugin_removingBatch(int count) {
    return 'Removing $count plugin(s)...';
  }

  @override
  String get plugin_rollingBack => 'Rolling back plugin...';

  @override
  String plugin_errorDetails(String error) {
    return 'Plugin error: $error';
  }

  @override
  String get pet_title => 'Desktop Pet';

  @override
  String get pet_notSupported => 'Desktop Pet Not Available';

  @override
  String pet_notSupportedDesc(String platform) {
    return 'Desktop Pet functionality is not supported on $platform platform. This feature requires a desktop environment with window management capabilities.';
  }

  @override
  String get pet_webLimitation => 'Web Platform Limitations';

  @override
  String get pet_webLimitationDesc =>
      'Web browsers do not support:\n• Desktop window management\n• Always-on-top windows\n• System tray integration\n• Native desktop interactions';

  @override
  String get pet_enableMode => 'Enable Pet Mode';

  @override
  String get pet_exitMode => 'Exit Pet Mode';

  @override
  String get pet_exitSuccess => 'Exited Desktop Pet mode';

  @override
  String get pet_returnToApp => 'Return to Main App';

  @override
  String get pet_settings => 'Pet Settings';

  @override
  String get pet_quickActions => 'Quick Actions';

  @override
  String get pet_openFullApp => 'Open Full App';

  @override
  String get pet_modeTitle => 'Desktop Pet Mode';

  @override
  String get pet_modeDesc =>
      'Enable Desktop Pet mode to have a cute companion on your desktop!';

  @override
  String get pet_features => 'Features:';

  @override
  String get pet_featureAlwaysOnTop => '• Always on top window';

  @override
  String get pet_featureAnimations => '• Cute animations and interactions';

  @override
  String get pet_featureQuickAccess => '• Quick access to plugins';

  @override
  String get pet_featureCustomize => '• Customizable appearance';

  @override
  String get pet_tip =>
      'Right-click the pet for quick actions, double-click to return to full app.';

  @override
  String get pet_platformInfo => 'Platform Information';

  @override
  String get pet_platformInfoDesc =>
      'Desktop Pet requires the following capabilities:';

  @override
  String get pet_capabilityDesktop => 'Desktop Environment';

  @override
  String get pet_capabilityWindow => 'Window Management';

  @override
  String get pet_capabilityTray => 'System Tray';

  @override
  String get pet_capabilityFileSystem => 'File System Access';

  @override
  String get pet_platformNote =>
      'Your current platform may not support all these features. Desktop Pet works best on Windows, macOS, and Linux desktop environments.';

  @override
  String pet_launchFailed(String message) {
    return 'Failed to launch desktop pet: $message';
  }

  @override
  String pet_toggleFailed(String message) {
    return 'Failed to toggle Desktop Pet mode: $message';
  }

  @override
  String pet_navFailed(String message) {
    return 'Failed to navigate to Desktop Pet screen: $message';
  }

  @override
  String get mode_local => 'LOCAL';

  @override
  String get mode_online => 'ONLINE';

  @override
  String mode_switchSuccess(String mode) {
    return 'Switched to $mode mode';
  }

  @override
  String mode_switchFailed(String message) {
    return 'Failed to switch mode: $message';
  }

  @override
  String get platform_initializing => 'Initializing Platform...';

  @override
  String get platform_error => 'Platform Error';

  @override
  String get platform_availableFeatures => 'Available Features';

  @override
  String get platform_noPluginsAvailable => 'No Plugins Available';

  @override
  String get platform_installFromManagement =>
      'Install plugins from the management screen';

  @override
  String get platform_activePlugins => 'Active Plugins';

  @override
  String get platform_platformInfo => 'Platform Info';

  @override
  String get nav_plugins => 'Plugins';

  @override
  String get nav_active => 'Active';

  @override
  String get nav_info => 'Info';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_languageChinese => '中文';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get plugin_detailsTitle => 'Plugin Details';

  @override
  String get plugin_detailsStatus => 'Status';

  @override
  String get plugin_detailsState => 'State';

  @override
  String get plugin_detailsEnabled => 'Enabled';

  @override
  String get plugin_detailsType => 'Type';

  @override
  String get plugin_detailsPluginId => 'Plugin ID';

  @override
  String get plugin_detailsDescription => 'Description';

  @override
  String get plugin_detailsInstallation => 'Installation';

  @override
  String get plugin_detailsInstalled => 'Installed';

  @override
  String get plugin_detailsLastUsed => 'Last Used';

  @override
  String get plugin_detailsEntryPoint => 'Entry Point';

  @override
  String get plugin_detailsPermissions => 'Permissions';

  @override
  String get plugin_detailsAdditionalInfo => 'Additional Information';

  @override
  String plugin_detailsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get plugin_stateActive => 'Active';

  @override
  String get plugin_stateInactive => 'Inactive';

  @override
  String get plugin_stateLoading => 'Loading';

  @override
  String get plugin_statePaused => 'Paused';

  @override
  String get plugin_stateError => 'Error';

  @override
  String get plugin_permissionFileAccess => 'File Access';

  @override
  String get plugin_permissionFileSystemRead => 'File System Read';

  @override
  String get plugin_permissionFileSystemWrite => 'File System Write';

  @override
  String get plugin_permissionFileSystemExecute => 'File System Execute';

  @override
  String get plugin_permissionNetworkAccess => 'Network Access';

  @override
  String get plugin_permissionNetworkServer => 'Network Server';

  @override
  String get plugin_permissionNetworkClient => 'Network Client';

  @override
  String get plugin_permissionNotifications => 'Notifications';

  @override
  String get plugin_permissionSystemNotifications => 'System Notifications';

  @override
  String get plugin_permissionCamera => 'Camera';

  @override
  String get plugin_permissionSystemCamera => 'System Camera';

  @override
  String get plugin_permissionMicrophone => 'Microphone';

  @override
  String get plugin_permissionSystemMicrophone => 'System Microphone';

  @override
  String get plugin_permissionLocation => 'Location';

  @override
  String get plugin_permissionStorage => 'Storage';

  @override
  String get plugin_permissionPlatformStorage => 'Platform Storage';

  @override
  String get plugin_permissionSystemClipboard => 'System Clipboard';

  @override
  String get plugin_permissionPlatformServices => 'Platform Services';

  @override
  String get plugin_permissionPlatformUI => 'Platform UI';

  @override
  String get plugin_permissionPluginCommunication => 'Plugin Communication';

  @override
  String get plugin_permissionPluginDataSharing => 'Plugin Data Sharing';

  @override
  String plugin_lastUsed(String time) {
    return 'Last used: $time';
  }

  @override
  String plugin_permissionCount(int count) {
    return '$count permissions';
  }

  @override
  String get plugin_permissionCountSingle => '1 permission';

  @override
  String time_daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String time_minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String get time_justNow => 'Just now';

  @override
  String get worldClock_title => 'World Clock';

  @override
  String get worldClock_addClock => 'Add Clock';

  @override
  String get worldClock_addCountdown => 'Add Countdown';

  @override
  String get worldClock_settings => 'Settings';

  @override
  String get worldClock_noClocks =>
      'No clocks available, tap the top right to add';

  @override
  String get worldClock_noCountdowns =>
      'No countdowns available, tap the top right to add';

  @override
  String get worldClock_defaultClock => 'Default';

  @override
  String get worldClock_deleteClock => 'Delete Clock';

  @override
  String get worldClock_deleteCountdown => 'Delete Countdown';

  @override
  String get worldClock_confirmDelete => 'Confirm Delete';

  @override
  String worldClock_confirmDeleteClock(String cityName) {
    return 'Are you sure you want to delete the clock for $cityName?';
  }

  @override
  String worldClock_confirmDeleteCountdown(String title) {
    return 'Are you sure you want to delete countdown \"$title\"?';
  }

  @override
  String get worldClock_addClockTitle => 'Add Clock';

  @override
  String get worldClock_cityName => 'City Name';

  @override
  String get worldClock_cityNameHint => 'Enter city name';

  @override
  String get worldClock_timeZone => 'Time Zone';

  @override
  String get worldClock_addCountdownTitle => 'Add Countdown';

  @override
  String get worldClock_countdownTitle => 'Countdown Title';

  @override
  String get worldClock_countdownTitleHint => 'Enter reminder content';

  @override
  String get worldClock_hours => 'Hours';

  @override
  String get worldClock_minutes => 'Minutes';

  @override
  String get worldClock_seconds => 'Seconds';

  @override
  String worldClock_countdownComplete(String title) {
    return 'Countdown reminder: $title time\'s up!';
  }

  @override
  String get worldClock_completed => 'Completed';

  @override
  String get worldClock_almostComplete => 'Almost complete!';

  @override
  String worldClock_remaining(String time) {
    return 'Remaining $time';
  }

  @override
  String worldClock_remainingMinutes(int minutes) {
    return 'Remaining $minutes minutes';
  }

  @override
  String worldClock_remainingHours(int hours, int minutes) {
    return 'Remaining $hours hours $minutes minutes';
  }

  @override
  String worldClock_remainingDays(int days, int hours) {
    return 'Remaining $days days $hours hours';
  }

  @override
  String get worldClock_settingsTitle => 'World Clock Settings';

  @override
  String get worldClock_settingsDesc =>
      'Settings options will be added in future versions';

  @override
  String get worldClock_currentFeatures => 'Current features:';

  @override
  String get worldClock_featureMultipleTimezones =>
      '• Display multiple timezone times';

  @override
  String get worldClock_featureCountdown => '• Countdown reminders';

  @override
  String get worldClock_featureBeijingDefault => '• Default Beijing time';

  @override
  String get pet_openMainApp => 'Open Main App';

  @override
  String get pet_notAvailable => 'Not Available';

  @override
  String get pet_settingsTitle => 'Desktop Pet Settings';

  @override
  String get pet_opacity => 'Opacity:';

  @override
  String get pet_enableAnimations => 'Enable Animations';

  @override
  String get pet_animationsSubtitle => 'Breathing and blinking effects';

  @override
  String get pet_enableInteractions => 'Enable Interactions';

  @override
  String get pet_interactionsSubtitle => 'Click and drag interactions';

  @override
  String get pet_autoHide => 'Auto Hide';

  @override
  String get pet_autoHideSubtitle => 'Hide when not in use';

  @override
  String get pet_reset => 'Reset';

  @override
  String get pet_done => 'Done';

  @override
  String get pet_moving => 'Moving...';

  @override
  String get tooltip_switchPlugin => 'Switch Plugin';

  @override
  String get tooltip_pausePlugin => 'Move to Background';

  @override
  String get tooltip_stopPlugin => 'Stop Plugin';

  @override
  String get tooltip_switchMode => 'Switch Plugin';

  @override
  String get tooltip_pauseMode => 'Move to Background';

  @override
  String get info_platformType => 'Platform Type';

  @override
  String get info_version => 'Version';

  @override
  String get info_currentMode => 'Current Mode';

  @override
  String get info_unknown => 'Unknown';

  @override
  String get info_capabilities => 'Capabilities';

  @override
  String get info_statistics => 'Statistics';

  @override
  String get info_availablePlugins => 'Available Plugins';

  @override
  String get info_activePlugins => 'Active Plugins';

  @override
  String get info_availableFeatures => 'Available Features';

  @override
  String get capability_desktopPetSupport => 'Desktop Pet Support';

  @override
  String get capability_alwaysOnTop => 'Always On Top';

  @override
  String get capability_systemTray => 'System Tray';

  @override
  String get feature_plugin_management => 'Plugin Management';

  @override
  String get feature_plugin_management_desc =>
      'Install, update, and manage plugins';

  @override
  String get feature_local_storage => 'Local Storage';

  @override
  String get feature_local_storage_desc =>
      'Persistent data storage on your device';

  @override
  String get feature_offline_plugins => 'Offline Plugins';

  @override
  String get feature_offline_plugins_desc => 'Access plugins even when offline';

  @override
  String get feature_local_preferences => 'Local Preferences';

  @override
  String get feature_local_preferences_desc =>
      'Personalize your local experience';

  @override
  String get feature_cloud_sync => 'Cloud Sync';

  @override
  String get feature_cloud_sync_desc =>
      'Keep your data synchronized across devices';

  @override
  String get feature_multiplayer => 'Multiplayer';

  @override
  String get feature_multiplayer_desc => 'Collaborate with others in real-time';

  @override
  String get feature_online_plugins => 'Online Plugins';

  @override
  String get feature_online_plugins_desc => 'Access plugins from the cloud';

  @override
  String get feature_cloud_storage => 'Cloud Storage';

  @override
  String get feature_cloud_storage_desc =>
      'Unlimited cloud storage for your data';

  @override
  String get feature_remote_config => 'Remote Config';

  @override
  String get feature_remote_config_desc => 'Configure features remotely';

  @override
  String get feature_status_implemented => 'Available';

  @override
  String get feature_status_partial => 'Beta';

  @override
  String get feature_status_planned => 'Coming Soon';

  @override
  String get feature_status_deprecated => 'Deprecated';

  @override
  String get feature_learn_more => 'Learn more';

  @override
  String feature_planned_for_version(String version) {
    return 'Planned for version $version';
  }
}

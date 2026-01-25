// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Multi-Function Plugin Platform';

  @override
  String get appName => 'Multi-Function Plugin Platform';

  @override
  String get autoStart => 'Default Start';

  @override
  String get autoStartPlugin => 'Plugin Default Start';

  @override
  String get autoStartDescription => 'Default Start';

  @override
  String autoStartedPlugins(Object count) {
    return 'Auto-started $count plugins';
  }

  @override
  String get autoStartAdded => 'Added to auto-start list';

  @override
  String get autoStartRemoved => 'Removed from auto-start list';

  @override
  String get autoStartPlugins_empty => 'No auto-start plugins';

  @override
  String get tag_title => 'Tags';

  @override
  String get tag_add => 'Add Tag';

  @override
  String get tag_edit => 'Edit Tag';

  @override
  String get tag_delete => 'Delete Tag';

  @override
  String get tag_name => 'Tag Name';

  @override
  String get tag_description => 'Tag Description';

  @override
  String get tag_color => 'Tag Color';

  @override
  String get tag_icon => 'Tag Icon';

  @override
  String get tag_create_success => 'Tag created successfully';

  @override
  String get tag_update_success => 'Tag updated successfully';

  @override
  String get tag_delete_success => 'Tag deleted successfully';

  @override
  String tag_delete_confirm(Object name) {
    return 'Are you sure you want to delete tag \"$name\"?';
  }

  @override
  String get tag_in_use => 'This tag is in use and cannot be deleted';

  @override
  String get tag_system_protected =>
      'System tags cannot be deleted or modified';

  @override
  String get tag_assign_success => 'Tag assigned successfully';

  @override
  String get tag_plugin_assignment_title => 'Plugin Tag Assignment';

  @override
  String get tag_search_plugins => 'Search plugins...';

  @override
  String get tag_select_tags_for_plugin => 'Select tags for plugin';

  @override
  String get tag_selected_tags => 'Selected Tags';

  @override
  String get tag_all_available_tags => 'All Available Tags';

  @override
  String get tag_no_plugins_found => 'No matching plugins found';

  @override
  String get tag_assign_removed => 'Tag removed';

  @override
  String get tag_filter_all => 'All';

  @override
  String tag_filter_active(Object count) {
    return '$count tags selected';
  }

  @override
  String get tag_no_tags => 'No tags yet';

  @override
  String get tag_total => 'tags';

  @override
  String get tag_and_more => 'and';

  @override
  String get tag_items => 'more';

  @override
  String get tag_manage => 'Manage Tags';

  @override
  String get tag_create_hint => 'Create custom tag';

  @override
  String get tag_select_hint => 'Select tags to filter';

  @override
  String get tag_empty => 'No tags';

  @override
  String get tag_popular => 'Popular Tags';

  @override
  String get tag_productivity => 'Productivity';

  @override
  String get tag_system => 'System';

  @override
  String get tag_entertainment => 'Entertainment';

  @override
  String get tag_game => 'Game';

  @override
  String get tag_development => 'Development';

  @override
  String get tag_favorite => 'Favorite';

  @override
  String get common_add => 'Add';

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
  String get button_open => 'Open';

  @override
  String get button_install => 'Install';

  @override
  String get button_uninstall => 'Uninstall';

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
  String get autoStartEnabled => 'Remove from default start';

  @override
  String get autoStartDisabled => 'Set as default start';

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
  String plugin_disableSuccess(String name) {
    return 'Plugin $name disabled';
  }

  @override
  String plugin_enableSuccess(String name) {
    return 'Plugin $name enabled';
  }

  @override
  String get button_disable => 'Disable';

  @override
  String get button_enable => 'Enable';

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
  String get mode_local => 'Local Mode';

  @override
  String get mode_online => 'Online Mode';

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
  String get settings_title => 'Settings';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_app => 'App';

  @override
  String get settings_general => 'General Settings';

  @override
  String get settings_appName => 'App Name';

  @override
  String get settings_appVersion => 'App Version';

  @override
  String get appInfo_title => 'Application Information';

  @override
  String get appInfo_viewDetails =>
      'View application information and configuration';

  @override
  String get appInfo_section_app => 'Application';

  @override
  String get appInfo_section_features => 'Feature Status';

  @override
  String get appInfo_section_developerTools => 'Developer Tools';

  @override
  String get appInfo_serviceTest_desc => 'Test and debug platform services';

  @override
  String get settings_changeTheme => 'Change Theme';

  @override
  String settings_themeChanged(String theme) {
    return 'Theme changed to $theme';
  }

  @override
  String get settings_languageChinese => '中文';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get settings_currentLanguage => 'Current Language';

  @override
  String get settings_changeLanguage => 'Change Language';

  @override
  String settings_languageChanged(String language) {
    return 'Language changed to $language';
  }

  @override
  String get settings_global => 'Global Config';

  @override
  String get settings_features => 'Features';

  @override
  String get settings_services => 'Services';

  @override
  String get tray_title => 'System Tray';

  @override
  String get tray_enabled => 'Enable System Tray';

  @override
  String get tray_enabled_desc => 'Show application icon in system tray';

  @override
  String get tray_tooltip => 'Tray Tooltip';

  @override
  String get tray_menu => 'Tray Menu';

  @override
  String get tray_menu_edit => 'Edit Menu';

  @override
  String get tray_menu_add => 'Add Menu Item';

  @override
  String get tray_menu_item_type => 'Menu Item Type';

  @override
  String get tray_menu_item_text => 'Menu Item Text';

  @override
  String get tray_menu_item_action => 'Action Type';

  @override
  String get tray_menu_item_enabled => 'Enabled';

  @override
  String get tray_menu_item_visible => 'Visible';

  @override
  String get tray_menu_item_checked => 'Checked';

  @override
  String get tray_menu_separator => 'Separator';

  @override
  String get tray_menu_normal => 'Normal Item';

  @override
  String get tray_menu_submenu => 'Submenu';

  @override
  String get tray_menu_action_show_hide => 'Show/Hide';

  @override
  String get tray_menu_action_quit => 'Quit';

  @override
  String get tray_menu_action_settings => 'Settings';

  @override
  String get tray_menu_action_custom => 'Custom';

  @override
  String get tray_minimize_to_tray => 'Minimize to Tray';

  @override
  String get tray_minimize_to_tray_desc =>
      'Hide to tray when closing window instead of quitting';

  @override
  String get tray_start_minimized => 'Start Minimized to Tray';

  @override
  String get tray_menu_saved => 'Menu saved';

  @override
  String get tray_menu_reset_confirm => 'Reset menu to default?';

  @override
  String get settings_advanced => 'Advanced';

  @override
  String get settings_plugins => 'Plugin Config';

  @override
  String get settings_addPlugin => 'Add Plugin';

  @override
  String get settings_addPlugin_desc => 'Add a new plugin to the platform';

  @override
  String get settings_selectPluginType => 'Select Plugin Type';

  @override
  String get settings_autoStart => 'Auto Start';

  @override
  String get settings_autoStart_description => 'Launch app on system startup';

  @override
  String get settings_minimizeToTray => 'Minimize to Tray';

  @override
  String get settings_showDesktopPet => 'Show Desktop Pet';

  @override
  String get settings_enableNotifications => 'Enable Notifications';

  @override
  String get settings_notificationMode => 'Notification Mode';

  @override
  String get settings_notificationMode_app => 'App Internal';

  @override
  String get settings_notificationMode_system => 'System Notification';

  @override
  String get settings_notificationMode_desc =>
      'Choose how notifications are displayed';

  @override
  String get settings_debugMode => 'Debug Mode';

  @override
  String get settings_logLevel => 'Log Level';

  @override
  String get settings_savePath => 'Save Path';

  @override
  String get settings_filenameFormat => 'Filename Format';

  @override
  String get settings_imageFormat => 'Image Format';

  @override
  String get settings_imageQuality => 'Image Quality';

  @override
  String get settings_autoCopyToClipboard => 'Auto Copy to Clipboard';

  @override
  String get settings_showPreview => 'Show Preview';

  @override
  String get settings_saveHistory => 'Save History';

  @override
  String get settings_maxHistoryCount => 'Max History Count';

  @override
  String get settings_shortcuts => 'Shortcuts';

  @override
  String get settings_regionCapture => 'Region Capture';

  @override
  String get settings_fullScreenCapture => 'Full Screen Capture';

  @override
  String get settings_windowCapture => 'Window Capture';

  @override
  String get settings_configSaved => 'Configuration saved';

  @override
  String get settings_configSaveFailed => 'Failed to save configuration';

  @override
  String get settings_resetToDefaults => 'Reset to Defaults';

  @override
  String get settings_resetConfirm =>
      'Are you sure you want to reset to defaults? This cannot be undone.';

  @override
  String get plugin_detailsTitle => 'Plugin Details';

  @override
  String get plugin_detailsStatus => 'Status';

  @override
  String get plugin_detailsState => 'State';

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
  String get desktopPet_settings_title => 'Desktop Pet Settings';

  @override
  String get desktopPet_section_appearance => 'Appearance';

  @override
  String get desktopPet_section_behavior => 'Behavior';

  @override
  String get desktopPet_opacity => 'Opacity';

  @override
  String get desktopPet_colorTheme => 'Color Theme';

  @override
  String get desktopPet_enableAnimations => 'Enable Animations';

  @override
  String get desktopPet_animationsSubtitle => 'Breathing and blinking effects';

  @override
  String get desktopPet_enableInteractions => 'Enable Interactions';

  @override
  String get desktopPet_interactionsSubtitle => 'Click and drag interactions';

  @override
  String get desktopPet_autoHide => 'Auto Hide';

  @override
  String get desktopPet_autoHideSubtitle => 'Hide when not in use';

  @override
  String get desktopPet_enabledSubtitle => 'Show pet character on desktop';

  @override
  String get desktopPet_openSettings => 'Tap to view detailed settings';

  @override
  String get desktopPet_settingsSaved => 'Desktop pet settings saved';

  @override
  String get desktopPet_reset => 'Reset to Defaults';

  @override
  String get desktopPet_resetConfirm =>
      'Are you sure you want to reset desktop pet settings?';

  @override
  String get desktopPet_config_name => 'Desktop Pet Configuration';

  @override
  String get desktopPet_config_description =>
      'Appearance and behavior settings for the desktop pet, including opacity, animations, and interactions';

  @override
  String get common_enabled => 'Enabled';

  @override
  String get common_disabled => 'Disabled';

  @override
  String get settings_pluginManagement => 'Plugin Tag Association';

  @override
  String get settings_pluginManagement_desc =>
      'Configure plugin and tag associations';

  @override
  String get executable_clearOutput => 'Clear Output';

  @override
  String get executable_disableAutoScroll => 'Disable Auto-scroll';

  @override
  String get executable_enableAutoScroll => 'Enable Auto-scroll';

  @override
  String get executable_scrollToBottom => 'Scroll to Bottom';

  @override
  String get executable_enterCommand => 'Enter command...';

  @override
  String get executable_send => 'Send';

  @override
  String get pluginManagement_installSample => 'Install Sample Plugin';

  @override
  String get externalPlugin_details => 'Plugin Details';

  @override
  String get externalPlugin_remove => 'Remove';

  @override
  String get desktopPet_themeDefault => 'Default Blue';

  @override
  String get desktopPet_themeBlue => 'Sky Blue';

  @override
  String get desktopPet_themeGreen => 'Natural Green';

  @override
  String get desktopPet_themeOrange => 'Vibrant Orange';

  @override
  String get desktopPet_themePurple => 'Mysterious Purple';

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
  String get mode_local_desc =>
      'Runs completely offline with all features executing on your local device';

  @override
  String get mode_online_desc =>
      'Connected mode with access to cloud features and online services';

  @override
  String get capability_desktopPetSupport => 'Desktop Pet';

  @override
  String get capability_desktopPetSupport_desc =>
      'Display interactive pet characters on desktop';

  @override
  String get capability_alwaysOnTop => 'Always On Top';

  @override
  String get capability_alwaysOnTop_desc => 'Window stays above other windows';

  @override
  String get capability_systemTray => 'System Tray';

  @override
  String get capability_systemTray_desc =>
      'Minimize to system tray and run in background';

  @override
  String get capability_supportsEnvironmentVariables => 'Environment Variables';

  @override
  String get capability_supportsEnvironmentVariables_desc =>
      'Access and modify system environment variables';

  @override
  String get capability_supportsFileSystem => 'File System';

  @override
  String get capability_supportsFileSystem_desc =>
      'Read and write local file system for data persistence';

  @override
  String get capability_touchInput => 'Touch Input';

  @override
  String get capability_touchInput_desc =>
      'Support touch screen interactions and multi-touch (mobile/touchscreen only)';

  @override
  String get capability_desktop => 'Desktop Platform';

  @override
  String get capability_desktop_desc =>
      'Running on desktop operating system (Windows, macOS, Linux)';

  @override
  String get feature_autoStart => 'Default Start';

  @override
  String get feature_minimizeToTray => 'Minimize to Tray';

  @override
  String get feature_enableNotifications => 'Notifications';

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

  @override
  String get plugin_calculator_name => 'Calculator';

  @override
  String get plugin_calculator_description =>
      'A simple calculator tool for basic arithmetic operations';

  @override
  String get plugin_calculator_initialized => 'Calculator plugin initialized';

  @override
  String get plugin_calculator_disposed => 'Calculator plugin disposed';

  @override
  String get plugin_calculator_error => 'Error';

  @override
  String get plugin_worldclock_name => 'World Clock';

  @override
  String get plugin_worldclock_description =>
      'Display times from multiple time zones with countdown timer support, showing Beijing time by default';

  @override
  String get serviceTest_title => 'Platform Services Test';

  @override
  String get serviceTest_notifications => 'Notifications';

  @override
  String get serviceTest_audio => 'Audio';

  @override
  String get serviceTest_tasks => 'tasks';

  @override
  String get serviceTest_activityLog => 'Activity Log';

  @override
  String get serviceTest_clear => 'Clear';

  @override
  String get serviceTest_copyAll => 'Copy All';

  @override
  String get serviceTest_copied => 'Copied';

  @override
  String get serviceTest_logCopied => 'Log entry copied to clipboard';

  @override
  String get serviceTest_allLogsCopied => 'All logs copied to clipboard';

  @override
  String get serviceTest_permissionGranted => 'Notification Permission Granted';

  @override
  String get serviceTest_permissionNotGranted =>
      'Notification Permission Not Granted';

  @override
  String get serviceTest_requestPermission => 'Request Permission';

  @override
  String get serviceTest_windowsPlatform => 'Windows Platform';

  @override
  String get serviceTest_windowsNotice =>
      'Scheduled notifications will appear immediately on Windows. Use the Countdown Timer in the Task tab for timed notifications.';

  @override
  String get serviceTest_notificationTitle => 'Notification Title';

  @override
  String get serviceTest_notificationBody => 'Notification Body';

  @override
  String get serviceTest_defaultNotificationTitle => 'Test Notification';

  @override
  String get serviceTest_defaultNotificationBody =>
      'This is a test notification from the platform services!';

  @override
  String get serviceTest_showNow => 'Show Now';

  @override
  String get serviceTest_schedule => 'Schedule (5s)';

  @override
  String get serviceTest_cancelAll => 'Cancel All';

  @override
  String get serviceTest_testAudioFeatures =>
      'Test various audio playback features';

  @override
  String get serviceTest_audioNotAvailable =>
      'Audio service is not available on this platform. Some features may be disabled.';

  @override
  String get serviceTest_notificationSound => 'Notification Sound';

  @override
  String get serviceTest_successSound => 'Success Sound';

  @override
  String get serviceTest_errorSound => 'Error Sound';

  @override
  String get serviceTest_warningSound => 'Warning Sound';

  @override
  String get serviceTest_clickSound => 'Click Sound';

  @override
  String get serviceTest_globalVolume => 'Global Volume';

  @override
  String get serviceTest_stopAllAudio => 'Stop All Audio';

  @override
  String get serviceTest_countdownTimer => 'Countdown Timer';

  @override
  String get serviceTest_seconds => 'Seconds';

  @override
  String get serviceTest_start => 'Start';

  @override
  String get serviceTest_cancel => 'Cancel';

  @override
  String get serviceTest_periodicTask => 'Periodic Task';

  @override
  String get serviceTest_interval => 'Interval';

  @override
  String get serviceTest_activeTasks => 'Active Tasks';

  @override
  String get serviceTest_noActiveTasks => 'No active tasks';

  @override
  String get serviceTest_at => 'At';

  @override
  String get serviceTest_every => 'Every';

  @override
  String get serviceTest_countdownComplete => 'Countdown Complete!';

  @override
  String get serviceTest_countdownFinished => 'Your countdown has finished.';

  @override
  String get serviceTest_error => 'Error';

  @override
  String get serviceTest_errorPlayingSound => 'Error playing sound';

  @override
  String get serviceTest_audioServiceNotAvailable =>
      'Audio service is not available on this platform';

  @override
  String get serviceTest_enterValidSeconds =>
      'Please enter a valid number of seconds';

  @override
  String get serviceTest_enterValidInterval => 'Please enter a valid interval';

  @override
  String get serviceTest_notificationShown => 'Notification shown';

  @override
  String get serviceTest_errorShowingNotification =>
      'Error showing notification';

  @override
  String get serviceTest_notificationScheduled =>
      'Notification scheduled for 5 seconds from now';

  @override
  String get serviceTest_errorSchedulingNotification =>
      'Error scheduling notification';

  @override
  String get serviceTest_allNotificationsCancelled =>
      'All notifications cancelled';

  @override
  String get serviceTest_errorCancellingNotifications =>
      'Error cancelling notifications';

  @override
  String serviceTest_countdownStarted(Object seconds) {
    return 'Countdown started: $seconds seconds';
  }

  @override
  String get serviceTest_errorStartingCountdown => 'Error starting countdown';

  @override
  String get serviceTest_countdownCancelled => 'Countdown cancelled';

  @override
  String get serviceTest_errorCancellingCountdown =>
      'Error cancelling countdown';

  @override
  String serviceTest_periodicTaskStarted(Object interval) {
    return 'Periodic task started: every $interval seconds';
  }

  @override
  String get serviceTest_errorStartingPeriodicTask =>
      'Error starting periodic task';

  @override
  String get serviceTest_periodicTaskCancelled => 'Periodic task cancelled';

  @override
  String get serviceTest_errorCancellingPeriodicTask =>
      'Error cancelling periodic task';

  @override
  String get serviceTest_periodicTaskExecuted => 'Periodic task executed';

  @override
  String get serviceTest_taskCompleted => 'Task completed';

  @override
  String get serviceTest_taskFailed => 'Task failed';

  @override
  String get serviceTest_taskCancelled => 'Task cancelled';

  @override
  String get serviceTest_couldNotPlaySound => 'Could not play sound';

  @override
  String serviceTest_volumeSet(Object percent) {
    return 'Volume set to $percent%';
  }

  @override
  String get serviceTest_stoppedAllAudio => 'Stopped all audio playback';

  @override
  String serviceTest_notificationPermission(Object status) {
    return 'Notification permission $status';
  }

  @override
  String get serviceTest_granted => 'granted';

  @override
  String get serviceTest_denied => 'denied';

  @override
  String get serviceTest_audioServiceUnavailable =>
      'Audio service is not available';

  @override
  String get serviceTest_serviceTestInitialized =>
      'Service Test Screen initialized';

  @override
  String get serviceTest_errorMessage => 'Error message';

  @override
  String get serviceTest_copy => 'Copy';

  @override
  String get plugin_screenshot_name => 'Smart Screenshot';

  @override
  String get plugin_screenshot_description =>
      'Professional screenshot tool like Snipaste, supporting region, fullscreen, window capture and image annotation';

  @override
  String get screenshot_region => 'Region Capture';

  @override
  String get screenshot_fullScreen => 'Full Screen';

  @override
  String get screenshot_window => 'Window Capture';

  @override
  String get screenshot_history => 'History';

  @override
  String get screenshot_settings => 'Settings';

  @override
  String get screenshot_savePath => 'Save Path';

  @override
  String get screenshot_filenameFormat => 'Filename Format';

  @override
  String get screenshot_autoCopy => 'Auto Copy to Clipboard';

  @override
  String get screenshot_showPreview => 'Show Preview';

  @override
  String get screenshot_saveHistory => 'Save History';

  @override
  String get screenshot_maxHistoryCount => 'Max History Count';

  @override
  String get screenshot_imageFormat => 'Image Format';

  @override
  String get screenshot_imageQuality => 'Image Quality';

  @override
  String get screenshot_shortcuts => 'Shortcuts';

  @override
  String get screenshot_pinSettings => 'Pin Settings';

  @override
  String get screenshot_alwaysOnTop => 'Always on Top';

  @override
  String get screenshot_defaultOpacity => 'Default Opacity';

  @override
  String get screenshot_enableDrag => 'Enable Drag';

  @override
  String get screenshot_enableResize => 'Enable Resize';

  @override
  String get screenshot_quickActions => 'Quick Actions';

  @override
  String get screenshot_recentScreenshots => 'Recent Screenshots';

  @override
  String get screenshot_statistics => 'Statistics';

  @override
  String get screenshot_noScreenshots => 'No screenshots yet';

  @override
  String get screenshot_clickToStart =>
      'Click buttons above to start capturing';

  @override
  String get screenshot_totalScreenshots => 'Total Screenshots';

  @override
  String get screenshot_todayScreenshots => 'Today';

  @override
  String get screenshot_storageUsed => 'Storage Used';

  @override
  String get screenshot_preview => 'Screenshot Preview';

  @override
  String get screenshot_confirmDelete => 'Confirm Delete';

  @override
  String get screenshot_confirmDeleteMessage =>
      'Are you sure you want to delete this screenshot?';

  @override
  String get screenshot_deleted => 'Screenshot deleted';

  @override
  String get screenshot_deleteFailed => 'Failed to delete screenshot';

  @override
  String get screenshot_saved => 'Screenshot saved';

  @override
  String get screenshot_copied => 'Copied to clipboard';

  @override
  String get screenshot_error => 'Screenshot failed';

  @override
  String get screenshot_unsupportedPlatform => 'Platform Functionality Limited';

  @override
  String get screenshot_unsupportedPlatformDesc =>
      'Screenshot functionality is not fully supported on this platform. Supported platforms: Windows, macOS, Linux';

  @override
  String get screenshot_featureNotImplemented =>
      'This feature is not yet implemented';

  @override
  String get screenshot_tool_pen => 'Pen';

  @override
  String get screenshot_tool_rectangle => 'Rectangle';

  @override
  String get screenshot_tool_arrow => 'Arrow';

  @override
  String get screenshot_tool_text => 'Text';

  @override
  String get screenshot_tool_mosaic => 'Mosaic';

  @override
  String get screenshot_undo => 'Undo';

  @override
  String get screenshot_redo => 'Redo';

  @override
  String get screenshot_save => 'Save';

  @override
  String get screenshot_cancel => 'Cancel';

  @override
  String get screenshot_type_fullScreen => 'Full Screen';

  @override
  String get screenshot_type_region => 'Region';

  @override
  String get screenshot_type_window => 'Window';

  @override
  String get screenshot_justNow => 'Just now';

  @override
  String screenshot_minutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String screenshot_hoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String screenshot_daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get settings_behavior => 'Behavior';

  @override
  String get screenshot_config_title => 'Screenshot Plugin Config';

  @override
  String get plugin_version => 'Version';

  @override
  String get plugin_type_label => 'Type';

  @override
  String get plugin_id_label => 'ID';

  @override
  String get plugin_background_plugins => 'Background Plugins';

  @override
  String plugin_pauseFailed(String message) {
    return 'Failed to pause plugin: $message';
  }

  @override
  String get plugin_update_label => 'Update';

  @override
  String get plugin_rollback_label => 'Rollback';

  @override
  String get plugin_remove_label => 'Remove';

  @override
  String get screenshot_select_window => 'Select Window';

  @override
  String get screenshot_close_preview => 'Close Preview';

  @override
  String get screenshot_share_not_implemented =>
      'Share feature not implemented';

  @override
  String get screenshot_saved_to_temp => 'Saved to temporary file';

  @override
  String get screenshot_copy_failed => 'Failed to copy to clipboard';

  @override
  String get screenshot_image_load_failed => 'Image load failed';

  @override
  String get screenshot_file_not_exists => 'File does not exist';

  @override
  String get screenshot_window_not_available =>
      'Window selection not available';

  @override
  String screenshot_region_failed(String error) {
    return 'Region capture failed: $error';
  }

  @override
  String screenshot_fullscreen_failed(String error) {
    return 'Full screen capture failed: $error';
  }

  @override
  String get screenshot_native_window_failed =>
      'Failed to open native capture window';

  @override
  String screenshot_window_failed(String error) {
    return 'Window capture failed: $error';
  }

  @override
  String get worldClock_section_clocks => 'World Clocks';

  @override
  String get worldClock_section_countdown => 'Countdown Reminders';

  @override
  String get worldClock_empty_clocks => 'No clocks';

  @override
  String get worldClock_empty_clocks_hint =>
      'Click + in the top right to add a clock';

  @override
  String get worldClock_empty_countdown => 'No countdowns';

  @override
  String get worldClock_empty_countdown_hint =>
      'Click the alarm icon to add a countdown';

  @override
  String get worldClock_tooltip_addCountdown => 'Add Countdown';

  @override
  String get worldClock_tooltip_addClock => 'Add Clock';

  @override
  String get worldClock_tooltip_settings => 'Settings';

  @override
  String get worldClock_setTime => 'Set Time';

  @override
  String get worldClock_display_options => 'Display Options';

  @override
  String get worldClock_24hour_format => '24-Hour Format';

  @override
  String get worldClock_24hour_format_desc => 'Use 24-hour time format';

  @override
  String get worldClock_show_seconds => 'Show Seconds';

  @override
  String get worldClock_show_seconds_desc => 'Display seconds in clocks';

  @override
  String get worldClock_feature_options => 'Feature Options';

  @override
  String get worldClock_enable_notifications => 'Enable Notifications';

  @override
  String get worldClock_enable_notifications_desc =>
      'Show notification when countdown completes';

  @override
  String get worldClock_enable_animations => 'Enable Animations';

  @override
  String get worldClock_enable_animations_desc => 'Show animation effects';

  @override
  String get screenshot_settings_title => 'Screenshot Settings';

  @override
  String get screenshot_settings_save => 'Save Settings';

  @override
  String get screenshot_settings_section_save => 'Save Settings';

  @override
  String get screenshot_settings_section_function => 'Function Settings';

  @override
  String get screenshot_settings_section_shortcuts => 'Shortcuts';

  @override
  String get screenshot_settings_section_pin => 'Pin Settings';

  @override
  String get screenshot_settings_auto_copy_desc =>
      'Auto copy to clipboard after capture';

  @override
  String get screenshot_clipboard_content_type => 'Clipboard Content Type';

  @override
  String get screenshot_clipboard_type_image => 'Image';

  @override
  String get screenshot_clipboard_type_filename => 'Filename';

  @override
  String get screenshot_clipboard_type_full_path => 'Full Path';

  @override
  String get screenshot_clipboard_type_directory_path => 'Directory Path';

  @override
  String get screenshot_clipboard_type_image_desc =>
      'Copy the image itself to clipboard';

  @override
  String get screenshot_clipboard_type_filename_desc =>
      'Copy filename only (without path)';

  @override
  String get screenshot_clipboard_type_full_path_desc =>
      'Copy the full file path';

  @override
  String get screenshot_clipboard_type_directory_path_desc =>
      'Copy the directory path containing the file';

  @override
  String get screenshot_settings_clipboard_type_title =>
      'Select Clipboard Content Type';

  @override
  String get screenshot_settings_show_preview_desc =>
      'Show preview and edit window after capture';

  @override
  String get screenshot_settings_save_history_desc =>
      'Save screenshot history for viewing';

  @override
  String get screenshot_settings_always_on_top_desc =>
      'Pin window always stays on top';

  @override
  String get screenshot_settings_saved => 'Settings saved';

  @override
  String get screenshot_settings_save_path_title => 'Set Save Path';

  @override
  String get screenshot_settings_save_path_hint => '[documents]/Screenshots';

  @override
  String get screenshot_settings_save_path_helper =>
      'Available placeholders: [documents], [home], [temp]';

  @override
  String get screenshot_settings_filename_title => 'Set Filename Format';

  @override
  String get screenshot_settings_filename_helper =>
      'Available placeholders: [timestamp], [date], [time], [datetime], [index]';

  @override
  String get screenshot_settings_format_title => 'Select Image Format';

  @override
  String get screenshot_settings_quality_title => 'Set Image Quality';

  @override
  String get screenshot_settings_history_title => 'Set Max History Count';

  @override
  String get screenshot_settings_opacity_title => 'Set Default Opacity';

  @override
  String get screenshot_settings_items => 'items';

  @override
  String get screenshot_shortcut_region => 'Region Capture';

  @override
  String get screenshot_shortcut_fullscreen => 'Full Screen Capture';

  @override
  String get screenshot_shortcut_window => 'Window Capture';

  @override
  String get screenshot_shortcut_history => 'Show History';

  @override
  String get screenshot_shortcut_settings => 'Open Settings';

  @override
  String get screenshot_settings_json_editor => 'JSON Configuration Editor';

  @override
  String get screenshot_settings_json_editor_desc =>
      'Edit JSON configuration file directly for advanced customization';

  @override
  String get screenshot_settings_config_name => 'Screenshot Configuration';

  @override
  String get screenshot_settings_config_description =>
      'Configure all screenshot plugin options';

  @override
  String get screenshot_settings_json_saved => 'Configuration saved';

  @override
  String get screenshot_tooltip_history => 'History';

  @override
  String get screenshot_tooltip_settings => 'Settings';

  @override
  String get screenshot_tooltip_cancel => 'Cancel';

  @override
  String get screenshot_tooltip_confirm => 'Confirm';

  @override
  String get screenshot_confirm_capture => 'Confirm Capture';

  @override
  String get ui_retry => 'Retry';

  @override
  String get ui_close => 'Close';

  @override
  String get ui_follow_system => 'Follow System';

  @override
  String json_editor_title(String configName) {
    return 'Edit $configName';
  }

  @override
  String get json_editor_format => 'Format';

  @override
  String get json_editor_minify => 'Minify';

  @override
  String get json_editor_reset => 'Reset';

  @override
  String get json_editor_example => 'Example';

  @override
  String get json_editor_validate => 'Validate';

  @override
  String get json_editor_unsaved_changes => 'Unsaved changes';

  @override
  String get json_editor_save_failed => 'Save failed';

  @override
  String get json_editor_reset_confirm_title => 'Reset to Default';

  @override
  String get json_editor_reset_confirm_message =>
      'Are you sure you want to reset to default configuration? All current changes will be lost.';

  @override
  String get json_editor_reset_confirm => 'Reset';

  @override
  String get json_editor_example_title => 'Load Example Configuration';

  @override
  String get json_editor_example_message =>
      'Loading example will replace current content. The example contains detailed configuration explanations.';

  @override
  String get json_editor_example_warning =>
      'Warning: Current content will be overwritten';

  @override
  String get json_editor_example_load => 'Load';

  @override
  String get json_editor_discard_title => 'Discard Changes';

  @override
  String get json_editor_discard_message =>
      'You have unsaved changes. Are you sure you want to discard them?';

  @override
  String get json_editor_discard_confirm => 'Discard';

  @override
  String get json_editor_edit_json => 'Edit JSON Configuration';

  @override
  String get json_editor_reset_to_default => 'Reset to Default';

  @override
  String get json_editor_view_example => 'View Configuration Example';

  @override
  String get json_editor_config_description => 'Configuration File Description';

  @override
  String get settings_config_saved => 'Settings saved';

  @override
  String get close_dialog_title => 'Close Confirmation';

  @override
  String get close_dialog_message => 'What would you like to do?';

  @override
  String get close_dialog_directly => 'Close Directly';

  @override
  String get close_dialog_minimize_to_tray => 'Minimize to Tray';

  @override
  String get close_dialog_cancel => 'Cancel';

  @override
  String get close_dialog_remember => 'Remember my choice, don\'t ask again';

  @override
  String get close_behavior_ask => 'Ask Every Time';

  @override
  String get close_behavior_close => 'Close Directly';

  @override
  String get close_behavior_minimize_to_tray => 'Minimize to Tray';

  @override
  String get settings_close_behavior => 'Close Behavior';

  @override
  String get settings_close_behavior_desc =>
      'Default behavior when closing the window';

  @override
  String get settings_remember_close_choice => 'Remember Close Choice';

  @override
  String get settings_remember_close_choice_desc =>
      'Remember the user\'s choice for closing';

  @override
  String get plugin_view_mode => 'View Mode';

  @override
  String get plugin_view_large_icon => 'Large Icons';

  @override
  String get plugin_view_medium_icon => 'Medium Icons';

  @override
  String get plugin_view_small_icon => 'Small Icons';

  @override
  String get plugin_view_list => 'List';

  @override
  String get calculator_settings_title => 'Calculator Settings';

  @override
  String get calculator_settings_basic => 'Basic Settings';

  @override
  String get calculator_settings_display => 'Display Settings';

  @override
  String get calculator_settings_interaction => 'Interaction Settings';

  @override
  String get calculator_setting_precision => 'Precision';

  @override
  String get calculator_decimal_places => 'decimal places';

  @override
  String get calculator_setting_angleMode => 'Angle Mode';

  @override
  String get calculator_angle_mode_degrees => 'Degrees';

  @override
  String get calculator_angle_mode_radians => 'Radians';

  @override
  String get calculator_angle_mode_degrees_short => 'Deg';

  @override
  String get calculator_angle_mode_radians_short => 'Rad';

  @override
  String get calculator_setting_historySize => 'History Size';

  @override
  String calculator_history_size_description(Object count) {
    return 'Save last $count calculations';
  }

  @override
  String get calculator_setting_showGroupingSeparator =>
      'Show Grouping Separator';

  @override
  String get calculator_grouping_separator_description =>
      'Show commas in large numbers, like 1,234.56';

  @override
  String get calculator_setting_enableVibration => 'Enable Vibration';

  @override
  String get calculator_vibration_description => 'Haptic feedback on key press';

  @override
  String get calculator_setting_buttonSoundVolume => 'Button Sound Volume';

  @override
  String get calculator_config_name => 'Calculator Configuration';

  @override
  String get calculator_config_description =>
      'Customize calculator precision, angle mode, and history';

  @override
  String get calculator_settings_saved => 'Settings saved';

  @override
  String get world_clock_settings_title => 'World Clock Settings';

  @override
  String get world_clock_settings_basic => 'Basic Settings';

  @override
  String get world_clock_settings_display => 'Display Settings';

  @override
  String get world_clock_settings_notification => 'Notification Settings';

  @override
  String get world_clock_setting_defaultTimeZone => 'Default Time Zone';

  @override
  String get world_clock_setting_timeFormat => 'Time Format';

  @override
  String get world_clock_time_format_12h => '12-hour';

  @override
  String get world_clock_time_format_24h => '24-hour';

  @override
  String get world_clock_time_format_desc =>
      'Choose 12-hour or 24-hour time format';

  @override
  String get world_clock_setting_showSeconds => 'Show Seconds';

  @override
  String get world_clock_showSeconds_desc => 'Include seconds in time display';

  @override
  String get world_clock_setting_enableNotifications =>
      'Enable Countdown Notifications';

  @override
  String get world_clock_enable_notifications_desc =>
      'Show notification when countdown completes';

  @override
  String get world_clock_setting_updateInterval => 'Update Interval';

  @override
  String get world_clock_update_interval_desc =>
      'Clock refresh rate in milliseconds (lower = faster updates)';

  @override
  String get world_clock_config_name => 'World Clock Configuration';

  @override
  String get world_clock_config_description =>
      'Customize world clock time zone, display format, and notifications';

  @override
  String get world_clock_settings_saved => 'Settings saved';

  @override
  String get world_clock_add_clock => 'Add Clock';

  @override
  String get world_clock_no_clocks => 'No Clocks';

  @override
  String get world_clock_add_clock_hint => 'Click + in top right to add clock';

  @override
  String get world_clock_city_name => 'City Name';

  @override
  String get world_clock_city_name_hint => 'Enter city name';

  @override
  String get world_clock_time_zone => 'Time Zone';

  @override
  String get world_clock_set_time => 'Set Time';

  @override
  String get world_clock_hours => 'Hours';

  @override
  String get world_clock_minutes => 'Minutes';

  @override
  String get world_clock_seconds => 'Seconds';

  @override
  String get world_clock_loading => 'Loading...';

  @override
  String get world_clock_no_image => 'Unable to load image';

  @override
  String get world_clock_countdown_completed => 'Completed';

  @override
  String get world_clock_countdown_almost_complete => 'Almost complete!';

  @override
  String world_clock_countdown_complete(Object title) {
    return 'Countdown \"$title\" completed!';
  }

  @override
  String world_clock_remaining_minutes(Object minutes) {
    return '$minutes minutes remaining';
  }

  @override
  String world_clock_remaining_hours_minutes(Object hours, Object minutes) {
    return '$hours hours $minutes minutes remaining';
  }

  @override
  String world_clock_remaining_days_hours(Object days, Object hours) {
    return '$days days $hours hours remaining';
  }

  @override
  String get world_clock_confirm_delete => 'Confirm Delete';

  @override
  String world_clock_confirm_delete_countdown_message(Object title) {
    return 'Are you sure you want to delete countdown \"$title\"?';
  }

  @override
  String world_clock_plugin_initialized(Object name) {
    return '$name plugin initialized successfully';
  }

  @override
  String world_clock_plugin_init_failed(Object error, Object name) {
    return '$name plugin initialization failed: $error';
  }

  @override
  String get screenshot_tool_pen_label => 'Pen';

  @override
  String get screenshot_tool_rectangle_label => 'Rectangle';

  @override
  String get screenshot_tool_arrow_label => 'Arrow';

  @override
  String get screenshot_tool_text_label => 'Text';

  @override
  String get screenshot_tool_mosaic_label => 'Mosaic';

  @override
  String get screenshot_undo_tooltip => 'Undo';

  @override
  String get screenshot_redo_tooltip => 'Redo';

  @override
  String get screenshot_save_tooltip => 'Save';

  @override
  String get screenshot_copy_to_clipboard => 'Copy to Clipboard';

  @override
  String get screenshot_share => 'Share';

  @override
  String get screenshot_loading => 'Loading...';

  @override
  String get screenshot_unable_load_image => 'Unable to load image';

  @override
  String get screenshot_history_title => 'Screenshot History';

  @override
  String get screenshot_clear_history => 'Clear History';

  @override
  String get screenshot_confirm_clear_history => 'Confirm Clear';

  @override
  String get screenshot_confirm_clear_history_message =>
      'Are you sure you want to clear all screenshot history? This cannot be undone.';

  @override
  String get screenshot_clear => 'Clear';

  @override
  String get screenshot_no_records => 'No screenshots yet';

  @override
  String get screenshot_history_hint =>
      'Screenshot history will appear here after taking screenshots';

  @override
  String get screenshot_recent => 'Just now';

  @override
  String screenshot_minutes_ago(Object minutes) {
    return '$minutes minutes ago';
  }

  @override
  String screenshot_hours_ago(Object hours) {
    return '$hours hours ago';
  }

  @override
  String screenshot_days_ago(Object days) {
    return '$days days ago';
  }

  @override
  String screenshot_date_format(Object day, Object month) {
    return '$month/$day';
  }

  @override
  String screenshot_datetime_format(
    Object day,
    Object hour,
    Object minute,
    Object month,
    Object second,
    Object year,
  ) {
    return '$year/$month/$day $hour:$minute:$second';
  }

  @override
  String get screenshot_type_fullscreen => 'Full Screen';

  @override
  String get screenshot_detail_info => 'Detail Info';

  @override
  String get screenshot_info_file_path => 'File Path';

  @override
  String get screenshot_info_file_size => 'File Size';

  @override
  String get screenshot_info_type => 'Screenshot Type';

  @override
  String get screenshot_info_created => 'Created';

  @override
  String get screenshot_info_dimensions => 'Dimensions';

  @override
  String screenshot_shortcut_edit_pending(Object action) {
    return 'Shortcut edit feature pending: $action';
  }

  @override
  String get screenshot_editor_title => 'Edit Screenshot';

  @override
  String get image_editor_pen => 'Pen';

  @override
  String get image_editor_rectangle => 'Rectangle';

  @override
  String get image_editor_arrow => 'Arrow';

  @override
  String get image_editor_text => 'Text';

  @override
  String get image_editor_mosaic => 'Mosaic';

  @override
  String get screenshot_main_history => 'History';

  @override
  String get screenshot_main_settings => 'Settings';

  @override
  String get screenshot_main_platform_limited => 'Platform Features Limited';

  @override
  String get screenshot_main_platform_limited_desc =>
      'Screenshot features are not fully supported on this platform. Supported platforms: Windows, macOS, Linux';

  @override
  String get screenshot_main_quick_actions => 'Quick Actions';

  @override
  String get screenshot_main_region_capture => 'Region Capture';

  @override
  String get screenshot_main_fullscreen_capture => 'Fullscreen Capture';

  @override
  String get screenshot_main_window_capture => 'Window Capture';

  @override
  String get screenshot_main_recent_screenshots => 'Recent Screenshots';

  @override
  String get screenshot_main_no_records => 'No screenshots yet';

  @override
  String get screenshot_main_no_records_hint =>
      'Click buttons above to start capturing';

  @override
  String get screenshot_main_statistics => 'Statistics';

  @override
  String get screenshot_main_total_count => 'Total Screenshots';

  @override
  String get screenshot_main_today_count => 'Today';

  @override
  String get screenshot_main_total_size => 'Total Size';

  @override
  String get screenshot_main_delete => 'Delete';

  @override
  String get screenshot_main_copy_to_clipboard => 'Copy to Clipboard';

  @override
  String get screenshot_main_share => 'Share';

  @override
  String get screenshot_main_loading => 'Loading...';

  @override
  String get screenshot_main_load_failed => 'Cannot Load Image';

  @override
  String get screenshot_main_just_now => 'Just now';

  @override
  String get worldclock_main_add_countdown => 'Add Countdown';

  @override
  String get worldclock_main_add_clock => 'Add Clock';

  @override
  String get worldclock_main_settings => 'Settings';

  @override
  String get worldclock_main_world_clocks => 'World Clocks';

  @override
  String get worldclock_main_no_clocks => 'No Clocks';

  @override
  String get worldclock_main_add_clock_hint =>
      'Click + in top right to add clock';

  @override
  String get worldclock_main_countdown_timers => 'Countdown Timers';

  @override
  String get worldclock_main_no_countdowns => 'No Countdowns';

  @override
  String get worldclock_main_add_countdown_hint =>
      'Click alarm icon to add countdown';
}

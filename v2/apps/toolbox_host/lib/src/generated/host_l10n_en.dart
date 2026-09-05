// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'host_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class HostL10nEn extends HostL10n {
  HostL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Toolbox';

  @override
  String get navDirectory => 'Plugins';

  @override
  String get navSettings => 'Settings';

  @override
  String get directoryTitle => 'Plugin Directory';

  @override
  String get reasonUnsupportedTarget =>
      'This plugin does not support the current platform';

  @override
  String reasonGeneric(String code) {
    return 'Cannot be enabled on this platform ($code)';
  }

  @override
  String get kindBuiltin => 'Builtin';

  @override
  String get kindSidecar => 'Sidecar';

  @override
  String get detailBasicInfo => 'Basic Info';

  @override
  String get detailFieldId => 'Plugin ID';

  @override
  String get detailFieldVersion => 'Version';

  @override
  String get detailFieldKind => 'Kind';

  @override
  String get detailFieldTargets => 'Targets';

  @override
  String get detailFieldSurfaces => 'Surfaces';

  @override
  String get detailEnableToggle => 'Enable plugin';

  @override
  String get detailOpenPage => 'Open plugin page';

  @override
  String get detailNoPage => 'This plugin provides no page';

  @override
  String get detailFormDemo => 'Form Demo';

  @override
  String get formDemoResultTitle => 'Submitted form values';

  @override
  String get detailSidecarPanel => 'Sidecar Install Panel';

  @override
  String get sidecarPlaceholder =>
      'Sidecar package installation and resolution arrive in a later phase; this panel is a placeholder.';

  @override
  String get sidecarRootDir => 'Package dir';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTheme => 'Theme preset';

  @override
  String get themePrecisionTools => 'Precision';

  @override
  String get themeWarmLife => 'Warm Life';

  @override
  String get themeDarkPro => 'Dark Pro';

  @override
  String get settingsBrightness => 'Brightness mode';

  @override
  String get brightnessSystem => 'System';

  @override
  String get brightnessLight => 'Light';

  @override
  String get brightnessDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get welcomePageTitle => 'Welcome to Toolbox';

  @override
  String get welcomeBody =>
      'This page is served by the builtin welcome plugin, composed by the host and exposed via PluginPageProvider.';

  @override
  String get welcomeFormTitle => 'Feedback Demo Form';

  @override
  String get welcomeFormName => 'Name';

  @override
  String get welcomeFormNamePlaceholder => 'How should we call you';

  @override
  String get welcomeFormScore => 'Experience score (1-5)';

  @override
  String get welcomeFormChannel => 'Preferred channel';

  @override
  String get welcomeFormChannelEmail => 'Email';

  @override
  String get welcomeFormChannelPush => 'System notification';

  @override
  String get welcomeFormSubscribe => 'Willing to receive product updates';

  @override
  String get welcomeFormTopics => 'Topics of interest';

  @override
  String get welcomeFormTopicDesign => 'UI design';

  @override
  String get welcomeFormTopicPlugins => 'Plugin development';

  @override
  String get formFieldRequired => 'required';
}

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
  String get reasonUnsupportedSurface =>
      'A surface declared by this plugin is not implemented by this host';

  @override
  String reasonGeneric(String code) {
    return 'Cannot be enabled on this platform ($code)';
  }

  @override
  String get kindBuiltin => 'Builtin';

  @override
  String get kindSidecar => 'Sidecar';

  @override
  String get kindSidecarInstallable => 'Sidecar plugin (install to run)';

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
  String get detailPluginSection => 'Plugin page';

  @override
  String get detailOpenPage => 'Open plugin page';

  @override
  String get detailSidecarPanel => 'Sidecar Install Panel';

  @override
  String get sidecarRootDir => 'Package dir';

  @override
  String get hashPanelTitle => 'Hash tool (Sidecar)';

  @override
  String get hashInstallPathLabel => 'Package file path (.scp)';

  @override
  String get hashInstallPathPlaceholder => 'e.g. D:/dist/hash-tool.scp';

  @override
  String get hashInstallButton => 'Install';

  @override
  String get hashInstallSuccess => 'Installed';

  @override
  String hashInstallFailed(String code) {
    return 'Install failed ($code)';
  }

  @override
  String get hashStartButton => 'Start';

  @override
  String get hashStopButton => 'Stop';

  @override
  String get hashNotInstalled =>
      'Not installed: install the .scp package first';

  @override
  String get hashInstalled => 'Installed';

  @override
  String get hashFormTitle => 'Hash computation';

  @override
  String get hashTextLabel => 'Text';

  @override
  String get hashTextPlaceholder => 'Text to hash';

  @override
  String get hashResultTitle => 'Result';

  @override
  String get hashMd5Label => 'MD5';

  @override
  String get hashSha1Label => 'SHA-1';

  @override
  String get hashSha256Label => 'SHA-256';

  @override
  String get hashPanelUnsupported =>
      'No command panel is available for this sidecar yet';

  @override
  String hashCommandFailed(String cause) {
    return 'Command failed ($cause)';
  }

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
  String get formDemoResultTitle => 'Form Result';

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

  @override
  String get detailSettings => 'Plugin Settings';

  @override
  String get detailNoSettings => 'This plugin provides no settings';

  @override
  String get calcDisplayHint => 'Enter an expression';

  @override
  String get calcHistoryTitle => 'History';

  @override
  String get calcClearHistory => 'Clear';

  @override
  String get calcHistoryEmpty => 'No history yet';

  @override
  String get calcErrorEmpty => 'Expression is empty (position: 0)';

  @override
  String calcErrorUnexpectedToken(int position) {
    return 'Unrecognized symbol (position: $position)';
  }

  @override
  String calcErrorUnbalancedParens(int position) {
    return 'Unbalanced parentheses (position: $position)';
  }

  @override
  String get calcErrorDivideByZero => 'Division by zero';

  @override
  String get calcErrorUnknown => 'Invalid expression';

  @override
  String get calcSettingsDecimals => 'Decimal places';

  @override
  String calcSettingsDecimalsValue(int value) {
    return '$value decimal places';
  }

  @override
  String get calcSettingsHistoryToggle => 'Show history';

  @override
  String get shotCaptureButton => 'Screenshot';

  @override
  String get shotCapturing => 'Capturing…';

  @override
  String get shotResultTitle => 'Latest capture';

  @override
  String shotSavedHint(String path) {
    return 'Saved: $path';
  }

  @override
  String get shotFailureTitle => 'Screenshot failed';

  @override
  String get shotSettingsFormTitle => 'Screenshot settings';

  @override
  String get shotSettingsFilenamePrefix => 'Filename prefix';

  @override
  String get shotSettingsFilenamePrefixPlaceholder => 'shot';

  @override
  String get shotSettingsQuality => 'Save quality';

  @override
  String get shotQualityLossless => 'Lossless (PNG)';

  @override
  String get shotQualityHigh => 'High';

  @override
  String get shotQualityStandard => 'Standard';

  @override
  String get shotQualityNote =>
      'PNG is lossless; quality options currently save the original image.';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'plugin_flutter_l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class PluginFlutterL10nEn extends PluginFlutterL10n {
  PluginFlutterL10nEn([String locale = 'en']) : super(locale);

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusDisabled => 'Disabled';

  @override
  String get statusUnavailable => 'Unavailable';

  @override
  String get statusReasonLabel => 'Reason';

  @override
  String get statusViewReason => 'View reason';

  @override
  String get statusReasonUnsupportedTarget =>
      'This plugin does not support the current platform';

  @override
  String get statusReasonMissingCapability =>
      'A required platform capability is missing';

  @override
  String get statusReasonCapabilityVersionTooLow =>
      'Platform capability version is too low for this plugin';

  @override
  String get statusReasonProviderUnavailable =>
      'The required capability provider is unavailable';

  @override
  String get statusReasonDependencyCycle =>
      'Plugin dependencies form a cycle and cannot be resolved';

  @override
  String get statusReasonUnknown => 'Unknown reason';

  @override
  String get formRequiredMark => 'Required';

  @override
  String get formRequiredError => 'This field is required';

  @override
  String get formInvalidNumber => 'Enter a valid number';

  @override
  String formNumberRange(String min, String max) {
    return 'Enter a value between $min and $max';
  }

  @override
  String formNumberMin(String min) {
    return 'Must be at least $min';
  }

  @override
  String formNumberMax(String max) {
    return 'Must be at most $max';
  }

  @override
  String get formSubmit => 'Submit';

  @override
  String get resultTableEmpty => 'No data';

  @override
  String resultImageUnavailable(String path) {
    return 'Image path: $path (host does not expose file access yet)';
  }
}

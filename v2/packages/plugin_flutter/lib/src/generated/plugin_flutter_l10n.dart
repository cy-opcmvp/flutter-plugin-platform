import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'plugin_flutter_l10n_en.dart';
import 'plugin_flutter_l10n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of PluginFlutterL10n
/// returned by `PluginFlutterL10n.of(context)`.
///
/// Applications need to include `PluginFlutterL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/plugin_flutter_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: PluginFlutterL10n.localizationsDelegates,
///   supportedLocales: PluginFlutterL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the PluginFlutterL10n.supportedLocales
/// property.
abstract class PluginFlutterL10n {
  PluginFlutterL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static PluginFlutterL10n of(BuildContext context) {
    return Localizations.of<PluginFlutterL10n>(context, PluginFlutterL10n)!;
  }

  static const LocalizationsDelegate<PluginFlutterL10n> delegate =
      _PluginFlutterL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @statusAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get statusAvailable;

  /// No description provided for @statusDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已停用'**
  String get statusDisabled;

  /// No description provided for @statusUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'不可用'**
  String get statusUnavailable;

  /// No description provided for @statusReasonLabel.
  ///
  /// In zh, this message translates to:
  /// **'原因'**
  String get statusReasonLabel;

  /// No description provided for @statusViewReason.
  ///
  /// In zh, this message translates to:
  /// **'查看原因'**
  String get statusViewReason;

  /// No description provided for @statusReasonUnsupportedTarget.
  ///
  /// In zh, this message translates to:
  /// **'该插件不支持当前平台'**
  String get statusReasonUnsupportedTarget;

  /// No description provided for @statusReasonMissingCapability.
  ///
  /// In zh, this message translates to:
  /// **'缺少插件所需的平台能力'**
  String get statusReasonMissingCapability;

  /// No description provided for @statusReasonCapabilityVersionTooLow.
  ///
  /// In zh, this message translates to:
  /// **'平台能力版本过低，无法满足插件要求'**
  String get statusReasonCapabilityVersionTooLow;

  /// No description provided for @statusReasonProviderUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'所需能力提供方不可用'**
  String get statusReasonProviderUnavailable;

  /// No description provided for @statusReasonDependencyCycle.
  ///
  /// In zh, this message translates to:
  /// **'插件依赖存在循环，无法解析'**
  String get statusReasonDependencyCycle;

  /// No description provided for @statusReasonUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知原因'**
  String get statusReasonUnknown;

  /// No description provided for @formRequiredMark.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get formRequiredMark;

  /// No description provided for @formRequiredError.
  ///
  /// In zh, this message translates to:
  /// **'请填写必填项'**
  String get formRequiredError;

  /// No description provided for @formInvalidNumber.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效数字'**
  String get formInvalidNumber;

  /// No description provided for @formNumberRange.
  ///
  /// In zh, this message translates to:
  /// **'请输入 {min} 到 {max} 之间的数值'**
  String formNumberRange(String min, String max);

  /// No description provided for @formNumberMin.
  ///
  /// In zh, this message translates to:
  /// **'不能小于 {min}'**
  String formNumberMin(String min);

  /// No description provided for @formNumberMax.
  ///
  /// In zh, this message translates to:
  /// **'不能大于 {max}'**
  String formNumberMax(String max);

  /// No description provided for @formSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get formSubmit;

  /// No description provided for @resultTableEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get resultTableEmpty;

  /// No description provided for @resultImageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'图片路径：{path}（宿主暂未提供文件读取能力）'**
  String resultImageUnavailable(String path);
}

class _PluginFlutterL10nDelegate
    extends LocalizationsDelegate<PluginFlutterL10n> {
  const _PluginFlutterL10nDelegate();

  @override
  Future<PluginFlutterL10n> load(Locale locale) {
    return SynchronousFuture<PluginFlutterL10n>(
      lookupPluginFlutterL10n(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_PluginFlutterL10nDelegate old) => false;
}

PluginFlutterL10n lookupPluginFlutterL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return PluginFlutterL10nEn();
    case 'zh':
      return PluginFlutterL10nZh();
  }

  throw FlutterError(
    'PluginFlutterL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

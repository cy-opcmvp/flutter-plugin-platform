import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'host_l10n_en.dart';
import 'host_l10n_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of HostL10n
/// returned by `HostL10n.of(context)`.
///
/// Applications need to include `HostL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/host_l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: HostL10n.localizationsDelegates,
///   supportedLocales: HostL10n.supportedLocales,
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
/// be consistent with the languages listed in the HostL10n.supportedLocales
/// property.
abstract class HostL10n {
  HostL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static HostL10n of(BuildContext context) {
    return Localizations.of<HostL10n>(context, HostL10n)!;
  }

  static const LocalizationsDelegate<HostL10n> delegate = _HostL10nDelegate();

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

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'工具箱'**
  String get appTitle;

  /// No description provided for @navDirectory.
  ///
  /// In zh, this message translates to:
  /// **'插件目录'**
  String get navDirectory;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @directoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'插件目录'**
  String get directoryTitle;

  /// No description provided for @reasonUnsupportedTarget.
  ///
  /// In zh, this message translates to:
  /// **'该插件不支持当前平台'**
  String get reasonUnsupportedTarget;

  /// No description provided for @reasonGeneric.
  ///
  /// In zh, this message translates to:
  /// **'无法在当前平台启用（{code}）'**
  String reasonGeneric(String code);

  /// No description provided for @kindBuiltin.
  ///
  /// In zh, this message translates to:
  /// **'内置插件'**
  String get kindBuiltin;

  /// No description provided for @kindSidecar.
  ///
  /// In zh, this message translates to:
  /// **'Sidecar 插件'**
  String get kindSidecar;

  /// No description provided for @detailBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get detailBasicInfo;

  /// No description provided for @detailFieldId.
  ///
  /// In zh, this message translates to:
  /// **'插件 ID'**
  String get detailFieldId;

  /// No description provided for @detailFieldVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get detailFieldVersion;

  /// No description provided for @detailFieldKind.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get detailFieldKind;

  /// No description provided for @detailFieldTargets.
  ///
  /// In zh, this message translates to:
  /// **'支持平台'**
  String get detailFieldTargets;

  /// No description provided for @detailFieldSurfaces.
  ///
  /// In zh, this message translates to:
  /// **'呈现面'**
  String get detailFieldSurfaces;

  /// No description provided for @detailEnableToggle.
  ///
  /// In zh, this message translates to:
  /// **'启用插件'**
  String get detailEnableToggle;

  /// No description provided for @detailOpenPage.
  ///
  /// In zh, this message translates to:
  /// **'打开插件页面'**
  String get detailOpenPage;

  /// No description provided for @detailNoPage.
  ///
  /// In zh, this message translates to:
  /// **'该插件未提供页面'**
  String get detailNoPage;

  /// No description provided for @detailFormDemo.
  ///
  /// In zh, this message translates to:
  /// **'表单演示'**
  String get detailFormDemo;

  /// No description provided for @formDemoResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'表单回填结果'**
  String get formDemoResultTitle;

  /// No description provided for @detailSidecarPanel.
  ///
  /// In zh, this message translates to:
  /// **'Sidecar 安装面板'**
  String get detailSidecarPanel;

  /// No description provided for @sidecarPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'Sidecar 包安装与解析将在后续阶段接入，当前为面板占位。'**
  String get sidecarPlaceholder;

  /// No description provided for @sidecarRootDir.
  ///
  /// In zh, this message translates to:
  /// **'包目录'**
  String get sidecarRootDir;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题方向'**
  String get settingsTheme;

  /// No description provided for @themePrecisionTools.
  ///
  /// In zh, this message translates to:
  /// **'精密工具'**
  String get themePrecisionTools;

  /// No description provided for @themeWarmLife.
  ///
  /// In zh, this message translates to:
  /// **'温暖生活'**
  String get themeWarmLife;

  /// No description provided for @themeDarkPro.
  ///
  /// In zh, this message translates to:
  /// **'极简暗色'**
  String get themeDarkPro;

  /// No description provided for @settingsBrightness.
  ///
  /// In zh, this message translates to:
  /// **'明暗模式'**
  String get settingsBrightness;

  /// No description provided for @brightnessSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get brightnessSystem;

  /// No description provided for @brightnessLight.
  ///
  /// In zh, this message translates to:
  /// **'亮色'**
  String get brightnessLight;

  /// No description provided for @brightnessDark.
  ///
  /// In zh, this message translates to:
  /// **'暗色'**
  String get brightnessDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @welcomePageTitle.
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用工具箱'**
  String get welcomePageTitle;

  /// No description provided for @welcomeBody.
  ///
  /// In zh, this message translates to:
  /// **'这是宿主内置的欢迎插件页面，由宿主组装并经 PluginPageProvider 呈现。'**
  String get welcomeBody;

  /// No description provided for @welcomeFormTitle.
  ///
  /// In zh, this message translates to:
  /// **'反馈演示表单'**
  String get welcomeFormTitle;

  /// No description provided for @welcomeFormName.
  ///
  /// In zh, this message translates to:
  /// **'称呼'**
  String get welcomeFormName;

  /// No description provided for @welcomeFormNamePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'怎么称呼你'**
  String get welcomeFormNamePlaceholder;

  /// No description provided for @welcomeFormScore.
  ///
  /// In zh, this message translates to:
  /// **'体验评分（1-5）'**
  String get welcomeFormScore;

  /// No description provided for @welcomeFormChannel.
  ///
  /// In zh, this message translates to:
  /// **'偏好渠道'**
  String get welcomeFormChannel;

  /// No description provided for @welcomeFormChannelEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮件'**
  String get welcomeFormChannelEmail;

  /// No description provided for @welcomeFormChannelPush.
  ///
  /// In zh, this message translates to:
  /// **'系统通知'**
  String get welcomeFormChannelPush;

  /// No description provided for @welcomeFormSubscribe.
  ///
  /// In zh, this message translates to:
  /// **'愿意接收产品动态'**
  String get welcomeFormSubscribe;

  /// No description provided for @welcomeFormTopics.
  ///
  /// In zh, this message translates to:
  /// **'感兴趣的主题'**
  String get welcomeFormTopics;

  /// No description provided for @welcomeFormTopicDesign.
  ///
  /// In zh, this message translates to:
  /// **'界面设计'**
  String get welcomeFormTopicDesign;

  /// No description provided for @welcomeFormTopicPlugins.
  ///
  /// In zh, this message translates to:
  /// **'插件开发'**
  String get welcomeFormTopicPlugins;

  /// No description provided for @formFieldRequired.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get formFieldRequired;
}

class _HostL10nDelegate extends LocalizationsDelegate<HostL10n> {
  const _HostL10nDelegate();

  @override
  Future<HostL10n> load(Locale locale) {
    return SynchronousFuture<HostL10n>(lookupHostL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_HostL10nDelegate old) => false;
}

HostL10n lookupHostL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return HostL10nEn();
    case 'zh':
      return HostL10nZh();
  }

  throw FlutterError(
    'HostL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

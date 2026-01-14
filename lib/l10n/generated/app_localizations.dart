import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

  /// 应用标题
  ///
  /// In zh, this message translates to:
  /// **'插件平台'**
  String get appTitle;

  /// No description provided for @common_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get common_confirm;

  /// No description provided for @common_cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get common_cancel;

  /// No description provided for @common_save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get common_save;

  /// No description provided for @common_delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get common_delete;

  /// No description provided for @common_close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get common_close;

  /// No description provided for @common_retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get common_retry;

  /// No description provided for @common_loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get common_loading;

  /// No description provided for @common_search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get common_search;

  /// No description provided for @common_ok.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get common_ok;

  /// No description provided for @common_yes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get common_no;

  /// No description provided for @common_all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get common_all;

  /// No description provided for @common_refresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get common_refresh;

  /// No description provided for @common_back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get common_back;

  /// No description provided for @common_error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get common_error;

  /// No description provided for @common_success.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get common_success;

  /// No description provided for @common_warning.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get common_warning;

  /// No description provided for @common_info.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get common_info;

  /// No description provided for @error_unknown.
  ///
  /// In zh, this message translates to:
  /// **'发生未知错误'**
  String get error_unknown;

  /// No description provided for @error_network.
  ///
  /// In zh, this message translates to:
  /// **'网络连接失败'**
  String get error_network;

  /// No description provided for @error_loadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败: {message}'**
  String error_loadFailed(String message);

  /// No description provided for @error_operationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败: {message}'**
  String error_operationFailed(String message);

  /// No description provided for @error_initFailed.
  ///
  /// In zh, this message translates to:
  /// **'初始化失败: {message}'**
  String error_initFailed(String message);

  /// No description provided for @error_platformInit.
  ///
  /// In zh, this message translates to:
  /// **'平台初始化失败: {message}'**
  String error_platformInit(String message);

  /// No description provided for @hint_searchPlugins.
  ///
  /// In zh, this message translates to:
  /// **'搜索插件...'**
  String get hint_searchPlugins;

  /// No description provided for @hint_searchExternalPlugins.
  ///
  /// In zh, this message translates to:
  /// **'搜索外部插件...'**
  String get hint_searchExternalPlugins;

  /// No description provided for @hint_inputRequired.
  ///
  /// In zh, this message translates to:
  /// **'此字段为必填项'**
  String get hint_inputRequired;

  /// No description provided for @hint_noResults.
  ///
  /// In zh, this message translates to:
  /// **'没有找到匹配的结果'**
  String get hint_noResults;

  /// No description provided for @hint_tryAdjustSearch.
  ///
  /// In zh, this message translates to:
  /// **'尝试调整搜索或筛选条件'**
  String get hint_tryAdjustSearch;

  /// No description provided for @button_launch.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get button_launch;

  /// No description provided for @button_install.
  ///
  /// In zh, this message translates to:
  /// **'安装'**
  String get button_install;

  /// No description provided for @button_uninstall.
  ///
  /// In zh, this message translates to:
  /// **'卸载'**
  String get button_uninstall;

  /// No description provided for @button_enable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get button_enable;

  /// No description provided for @button_disable.
  ///
  /// In zh, this message translates to:
  /// **'禁用'**
  String get button_disable;

  /// No description provided for @button_update.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get button_update;

  /// No description provided for @button_rollback.
  ///
  /// In zh, this message translates to:
  /// **'回滚'**
  String get button_rollback;

  /// No description provided for @button_remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get button_remove;

  /// No description provided for @button_updateAll.
  ///
  /// In zh, this message translates to:
  /// **'全部更新'**
  String get button_updateAll;

  /// No description provided for @button_removeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部移除'**
  String get button_removeAll;

  /// No description provided for @button_selectAll.
  ///
  /// In zh, this message translates to:
  /// **'全选'**
  String get button_selectAll;

  /// No description provided for @button_deselectAll.
  ///
  /// In zh, this message translates to:
  /// **'取消全选'**
  String get button_deselectAll;

  /// No description provided for @button_multiSelect.
  ///
  /// In zh, this message translates to:
  /// **'多选'**
  String get button_multiSelect;

  /// No description provided for @button_enablePetMode.
  ///
  /// In zh, this message translates to:
  /// **'启用宠物模式'**
  String get button_enablePetMode;

  /// No description provided for @button_exitPetMode.
  ///
  /// In zh, this message translates to:
  /// **'退出宠物模式'**
  String get button_exitPetMode;

  /// No description provided for @dialog_confirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认操作'**
  String get dialog_confirmTitle;

  /// No description provided for @dialog_uninstallPlugin.
  ///
  /// In zh, this message translates to:
  /// **'确定要卸载此插件吗？此操作无法撤销。'**
  String get dialog_uninstallPlugin;

  /// No description provided for @dialog_removePlugin.
  ///
  /// In zh, this message translates to:
  /// **'确定要移除此插件吗？此操作无法撤销。'**
  String get dialog_removePlugin;

  /// No description provided for @dialog_updatePlugin.
  ///
  /// In zh, this message translates to:
  /// **'确定要更新此插件吗？更新前会创建备份以便回滚。'**
  String get dialog_updatePlugin;

  /// No description provided for @dialog_rollbackPlugin.
  ///
  /// In zh, this message translates to:
  /// **'确定要回滚此插件吗？这将撤销上次更新。'**
  String get dialog_rollbackPlugin;

  /// No description provided for @dialog_batchUpdate.
  ///
  /// In zh, this message translates to:
  /// **'确定要更新 {count} 个选中的插件吗？'**
  String dialog_batchUpdate(int count);

  /// No description provided for @dialog_batchRemove.
  ///
  /// In zh, this message translates to:
  /// **'确定要移除 {count} 个选中的插件吗？此操作无法撤销。'**
  String dialog_batchRemove(int count);

  /// No description provided for @plugin_title.
  ///
  /// In zh, this message translates to:
  /// **'插件管理'**
  String get plugin_title;

  /// No description provided for @plugin_externalTitle.
  ///
  /// In zh, this message translates to:
  /// **'外部插件'**
  String get plugin_externalTitle;

  /// No description provided for @plugin_statusEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get plugin_statusEnabled;

  /// No description provided for @plugin_statusDisabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get plugin_statusDisabled;

  /// No description provided for @plugin_statusActive.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get plugin_statusActive;

  /// No description provided for @plugin_statusInactive.
  ///
  /// In zh, this message translates to:
  /// **'未激活'**
  String get plugin_statusInactive;

  /// No description provided for @plugin_statusPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get plugin_statusPaused;

  /// No description provided for @plugin_statusError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get plugin_statusError;

  /// No description provided for @plugin_typeTool.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get plugin_typeTool;

  /// No description provided for @plugin_typeGame.
  ///
  /// In zh, this message translates to:
  /// **'游戏'**
  String get plugin_typeGame;

  /// No description provided for @plugin_typeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部类型'**
  String get plugin_typeAll;

  /// No description provided for @plugin_stateAll.
  ///
  /// In zh, this message translates to:
  /// **'全部状态'**
  String get plugin_stateAll;

  /// No description provided for @plugin_noPlugins.
  ///
  /// In zh, this message translates to:
  /// **'暂无插件'**
  String get plugin_noPlugins;

  /// No description provided for @plugin_noExternalPlugins.
  ///
  /// In zh, this message translates to:
  /// **'暂无外部插件'**
  String get plugin_noExternalPlugins;

  /// No description provided for @plugin_installFirst.
  ///
  /// In zh, this message translates to:
  /// **'安装您的第一个插件开始使用'**
  String get plugin_installFirst;

  /// No description provided for @plugin_installExternalFirst.
  ///
  /// In zh, this message translates to:
  /// **'安装您的第一个外部插件开始使用'**
  String get plugin_installExternalFirst;

  /// No description provided for @plugin_noMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的插件'**
  String get plugin_noMatch;

  /// No description provided for @plugin_filterByType.
  ///
  /// In zh, this message translates to:
  /// **'按类型筛选: '**
  String get plugin_filterByType;

  /// No description provided for @plugin_filterByState.
  ///
  /// In zh, this message translates to:
  /// **'按状态筛选'**
  String get plugin_filterByState;

  /// No description provided for @plugin_launchSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件 {name} 已启动'**
  String plugin_launchSuccess(String name);

  /// No description provided for @plugin_launchFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动插件失败: {message}'**
  String plugin_launchFailed(String message);

  /// No description provided for @plugin_switchSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已切换到插件 {name}'**
  String plugin_switchSuccess(String name);

  /// No description provided for @plugin_switchFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换插件失败: {message}'**
  String plugin_switchFailed(String message);

  /// No description provided for @plugin_closeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件 {name} 已关闭'**
  String plugin_closeSuccess(String name);

  /// No description provided for @plugin_pauseSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件 {name} 已移至后台'**
  String plugin_pauseSuccess(String name);

  /// No description provided for @plugin_enableSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件已启用'**
  String get plugin_enableSuccess;

  /// No description provided for @plugin_disableSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件已禁用'**
  String get plugin_disableSuccess;

  /// No description provided for @plugin_installSuccess.
  ///
  /// In zh, this message translates to:
  /// **'示例插件安装成功'**
  String get plugin_installSuccess;

  /// No description provided for @plugin_uninstallSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件卸载成功'**
  String get plugin_uninstallSuccess;

  /// No description provided for @plugin_updateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件更新成功，可回滚'**
  String get plugin_updateSuccess;

  /// No description provided for @plugin_updateFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败并已回滚: {message}'**
  String plugin_updateFailed(String message);

  /// No description provided for @plugin_rollbackSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件回滚成功'**
  String get plugin_rollbackSuccess;

  /// No description provided for @plugin_removeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件移除成功'**
  String get plugin_removeSuccess;

  /// No description provided for @plugin_operationFailed.
  ///
  /// In zh, this message translates to:
  /// **'插件操作失败: {message}'**
  String plugin_operationFailed(String message);

  /// No description provided for @plugin_batchUpdateResult.
  ///
  /// In zh, this message translates to:
  /// **'{success} 个更新成功，{failed} 个失败'**
  String plugin_batchUpdateResult(int success, int failed);

  /// No description provided for @plugin_batchRemoveResult.
  ///
  /// In zh, this message translates to:
  /// **'{success} 个移除成功，{failed} 个失败'**
  String plugin_batchRemoveResult(int success, int failed);

  /// No description provided for @plugin_allUpdateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 个插件更新成功'**
  String plugin_allUpdateSuccess(int count);

  /// No description provided for @plugin_allRemoveSuccess.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 个插件移除成功'**
  String plugin_allRemoveSuccess(int count);

  /// No description provided for @plugin_allUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 个插件更新失败'**
  String plugin_allUpdateFailed(int count);

  /// No description provided for @plugin_allRemoveFailed.
  ///
  /// In zh, this message translates to:
  /// **'全部 {count} 个插件移除失败'**
  String plugin_allRemoveFailed(int count);

  /// No description provided for @plugin_selected.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 个'**
  String plugin_selected(int count);

  /// No description provided for @plugin_updating.
  ///
  /// In zh, this message translates to:
  /// **'正在更新插件...'**
  String get plugin_updating;

  /// No description provided for @plugin_updatingBatch.
  ///
  /// In zh, this message translates to:
  /// **'正在更新 {count} 个插件...'**
  String plugin_updatingBatch(int count);

  /// No description provided for @plugin_removing.
  ///
  /// In zh, this message translates to:
  /// **'正在移除插件...'**
  String get plugin_removing;

  /// No description provided for @plugin_removingBatch.
  ///
  /// In zh, this message translates to:
  /// **'正在移除 {count} 个插件...'**
  String plugin_removingBatch(int count);

  /// No description provided for @plugin_rollingBack.
  ///
  /// In zh, this message translates to:
  /// **'正在回滚插件...'**
  String get plugin_rollingBack;

  /// No description provided for @plugin_errorDetails.
  ///
  /// In zh, this message translates to:
  /// **'插件错误: {error}'**
  String plugin_errorDetails(String error);

  /// No description provided for @pet_title.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物'**
  String get pet_title;

  /// No description provided for @pet_notSupported.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物不可用'**
  String get pet_notSupported;

  /// No description provided for @pet_notSupportedDesc.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物功能在 {platform} 平台上不可用。此功能需要桌面环境和窗口管理能力。'**
  String pet_notSupportedDesc(String platform);

  /// No description provided for @pet_webLimitation.
  ///
  /// In zh, this message translates to:
  /// **'Web 平台限制'**
  String get pet_webLimitation;

  /// No description provided for @pet_webLimitationDesc.
  ///
  /// In zh, this message translates to:
  /// **'Web 浏览器不支持:\n• 桌面窗口管理\n• 置顶窗口\n• 系统托盘集成\n• 原生桌面交互'**
  String get pet_webLimitationDesc;

  /// No description provided for @pet_enableMode.
  ///
  /// In zh, this message translates to:
  /// **'启用宠物模式'**
  String get pet_enableMode;

  /// No description provided for @pet_exitMode.
  ///
  /// In zh, this message translates to:
  /// **'退出宠物模式'**
  String get pet_exitMode;

  /// No description provided for @pet_exitSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已退出桌面宠物模式'**
  String get pet_exitSuccess;

  /// No description provided for @pet_returnToApp.
  ///
  /// In zh, this message translates to:
  /// **'返回主应用'**
  String get pet_returnToApp;

  /// No description provided for @pet_settings.
  ///
  /// In zh, this message translates to:
  /// **'宠物设置'**
  String get pet_settings;

  /// No description provided for @pet_quickActions.
  ///
  /// In zh, this message translates to:
  /// **'快捷操作'**
  String get pet_quickActions;

  /// No description provided for @pet_openFullApp.
  ///
  /// In zh, this message translates to:
  /// **'打开完整应用'**
  String get pet_openFullApp;

  /// No description provided for @pet_modeTitle.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物模式'**
  String get pet_modeTitle;

  /// No description provided for @pet_modeDesc.
  ///
  /// In zh, this message translates to:
  /// **'启用桌面宠物模式，让可爱的伙伴陪伴您！'**
  String get pet_modeDesc;

  /// No description provided for @pet_features.
  ///
  /// In zh, this message translates to:
  /// **'功能特点:'**
  String get pet_features;

  /// No description provided for @pet_featureAlwaysOnTop.
  ///
  /// In zh, this message translates to:
  /// **'• 窗口置顶'**
  String get pet_featureAlwaysOnTop;

  /// No description provided for @pet_featureAnimations.
  ///
  /// In zh, this message translates to:
  /// **'• 可爱的动画和交互'**
  String get pet_featureAnimations;

  /// No description provided for @pet_featureQuickAccess.
  ///
  /// In zh, this message translates to:
  /// **'• 快速访问插件'**
  String get pet_featureQuickAccess;

  /// No description provided for @pet_featureCustomize.
  ///
  /// In zh, this message translates to:
  /// **'• 可自定义外观'**
  String get pet_featureCustomize;

  /// No description provided for @pet_tip.
  ///
  /// In zh, this message translates to:
  /// **'右键点击宠物查看快捷操作，双击返回完整应用。'**
  String get pet_tip;

  /// No description provided for @pet_platformInfo.
  ///
  /// In zh, this message translates to:
  /// **'平台信息'**
  String get pet_platformInfo;

  /// No description provided for @pet_platformInfoDesc.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物需要以下能力:'**
  String get pet_platformInfoDesc;

  /// No description provided for @pet_capabilityDesktop.
  ///
  /// In zh, this message translates to:
  /// **'桌面环境'**
  String get pet_capabilityDesktop;

  /// No description provided for @pet_capabilityWindow.
  ///
  /// In zh, this message translates to:
  /// **'窗口管理'**
  String get pet_capabilityWindow;

  /// No description provided for @pet_capabilityTray.
  ///
  /// In zh, this message translates to:
  /// **'系统托盘'**
  String get pet_capabilityTray;

  /// No description provided for @pet_capabilityFileSystem.
  ///
  /// In zh, this message translates to:
  /// **'文件系统访问'**
  String get pet_capabilityFileSystem;

  /// No description provided for @pet_platformNote.
  ///
  /// In zh, this message translates to:
  /// **'您当前的平台可能不支持所有这些功能。桌面宠物在 Windows、macOS 和 Linux 桌面环境下效果最佳。'**
  String get pet_platformNote;

  /// No description provided for @pet_launchFailed.
  ///
  /// In zh, this message translates to:
  /// **'启动桌面宠物失败: {message}'**
  String pet_launchFailed(String message);

  /// No description provided for @pet_toggleFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换桌面宠物模式失败: {message}'**
  String pet_toggleFailed(String message);

  /// No description provided for @pet_navFailed.
  ///
  /// In zh, this message translates to:
  /// **'导航到桌面宠物屏幕失败: {message}'**
  String pet_navFailed(String message);

  /// No description provided for @mode_local.
  ///
  /// In zh, this message translates to:
  /// **'本地'**
  String get mode_local;

  /// No description provided for @mode_online.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get mode_online;

  /// No description provided for @mode_switchSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已切换到 {mode} 模式'**
  String mode_switchSuccess(String mode);

  /// No description provided for @mode_switchFailed.
  ///
  /// In zh, this message translates to:
  /// **'切换模式失败: {message}'**
  String mode_switchFailed(String message);

  /// No description provided for @platform_initializing.
  ///
  /// In zh, this message translates to:
  /// **'正在初始化平台...'**
  String get platform_initializing;

  /// No description provided for @platform_error.
  ///
  /// In zh, this message translates to:
  /// **'平台错误'**
  String get platform_error;

  /// No description provided for @platform_availableFeatures.
  ///
  /// In zh, this message translates to:
  /// **'可用功能'**
  String get platform_availableFeatures;

  /// No description provided for @platform_noPluginsAvailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用插件'**
  String get platform_noPluginsAvailable;

  /// No description provided for @platform_installFromManagement.
  ///
  /// In zh, this message translates to:
  /// **'从管理界面安装插件'**
  String get platform_installFromManagement;

  /// No description provided for @platform_activePlugins.
  ///
  /// In zh, this message translates to:
  /// **'活动插件'**
  String get platform_activePlugins;

  /// No description provided for @platform_platformInfo.
  ///
  /// In zh, this message translates to:
  /// **'平台信息'**
  String get platform_platformInfo;

  /// No description provided for @nav_plugins.
  ///
  /// In zh, this message translates to:
  /// **'插件'**
  String get nav_plugins;

  /// No description provided for @nav_active.
  ///
  /// In zh, this message translates to:
  /// **'活动'**
  String get nav_active;

  /// No description provided for @nav_info.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get nav_info;

  /// No description provided for @settings_language.
  ///
  /// In zh, this message translates to:
  /// **'语言设置'**
  String get settings_language;

  /// No description provided for @settings_theme.
  ///
  /// In zh, this message translates to:
  /// **'主题设置'**
  String get settings_theme;

  /// No description provided for @settings_languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get settings_languageChinese;

  /// No description provided for @settings_languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get settings_languageEnglish;

  /// No description provided for @plugin_detailsTitle.
  ///
  /// In zh, this message translates to:
  /// **'插件详情'**
  String get plugin_detailsTitle;

  /// No description provided for @plugin_detailsStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get plugin_detailsStatus;

  /// No description provided for @plugin_detailsState.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get plugin_detailsState;

  /// No description provided for @plugin_detailsEnabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get plugin_detailsEnabled;

  /// No description provided for @plugin_detailsType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get plugin_detailsType;

  /// No description provided for @plugin_detailsPluginId.
  ///
  /// In zh, this message translates to:
  /// **'插件ID'**
  String get plugin_detailsPluginId;

  /// No description provided for @plugin_detailsDescription.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get plugin_detailsDescription;

  /// No description provided for @plugin_detailsInstallation.
  ///
  /// In zh, this message translates to:
  /// **'安装信息'**
  String get plugin_detailsInstallation;

  /// No description provided for @plugin_detailsInstalled.
  ///
  /// In zh, this message translates to:
  /// **'安装时间'**
  String get plugin_detailsInstalled;

  /// No description provided for @plugin_detailsLastUsed.
  ///
  /// In zh, this message translates to:
  /// **'最后使用'**
  String get plugin_detailsLastUsed;

  /// No description provided for @plugin_detailsEntryPoint.
  ///
  /// In zh, this message translates to:
  /// **'入口点'**
  String get plugin_detailsEntryPoint;

  /// No description provided for @plugin_detailsPermissions.
  ///
  /// In zh, this message translates to:
  /// **'权限'**
  String get plugin_detailsPermissions;

  /// No description provided for @plugin_detailsAdditionalInfo.
  ///
  /// In zh, this message translates to:
  /// **'附加信息'**
  String get plugin_detailsAdditionalInfo;

  /// No description provided for @plugin_detailsVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String plugin_detailsVersion(String version);

  /// No description provided for @plugin_stateActive.
  ///
  /// In zh, this message translates to:
  /// **'运行中'**
  String get plugin_stateActive;

  /// No description provided for @plugin_stateInactive.
  ///
  /// In zh, this message translates to:
  /// **'未激活'**
  String get plugin_stateInactive;

  /// No description provided for @plugin_stateLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中'**
  String get plugin_stateLoading;

  /// No description provided for @plugin_statePaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get plugin_statePaused;

  /// No description provided for @plugin_stateError.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get plugin_stateError;

  /// No description provided for @plugin_permissionFileAccess.
  ///
  /// In zh, this message translates to:
  /// **'文件访问'**
  String get plugin_permissionFileAccess;

  /// No description provided for @plugin_permissionFileSystemRead.
  ///
  /// In zh, this message translates to:
  /// **'文件系统读取'**
  String get plugin_permissionFileSystemRead;

  /// No description provided for @plugin_permissionFileSystemWrite.
  ///
  /// In zh, this message translates to:
  /// **'文件系统写入'**
  String get plugin_permissionFileSystemWrite;

  /// No description provided for @plugin_permissionFileSystemExecute.
  ///
  /// In zh, this message translates to:
  /// **'文件系统执行'**
  String get plugin_permissionFileSystemExecute;

  /// No description provided for @plugin_permissionNetworkAccess.
  ///
  /// In zh, this message translates to:
  /// **'网络访问'**
  String get plugin_permissionNetworkAccess;

  /// No description provided for @plugin_permissionNetworkServer.
  ///
  /// In zh, this message translates to:
  /// **'网络服务器'**
  String get plugin_permissionNetworkServer;

  /// No description provided for @plugin_permissionNetworkClient.
  ///
  /// In zh, this message translates to:
  /// **'网络客户端'**
  String get plugin_permissionNetworkClient;

  /// No description provided for @plugin_permissionNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get plugin_permissionNotifications;

  /// No description provided for @plugin_permissionSystemNotifications.
  ///
  /// In zh, this message translates to:
  /// **'系统通知'**
  String get plugin_permissionSystemNotifications;

  /// No description provided for @plugin_permissionCamera.
  ///
  /// In zh, this message translates to:
  /// **'相机'**
  String get plugin_permissionCamera;

  /// No description provided for @plugin_permissionSystemCamera.
  ///
  /// In zh, this message translates to:
  /// **'系统相机'**
  String get plugin_permissionSystemCamera;

  /// No description provided for @plugin_permissionMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'麦克风'**
  String get plugin_permissionMicrophone;

  /// No description provided for @plugin_permissionSystemMicrophone.
  ///
  /// In zh, this message translates to:
  /// **'系统麦克风'**
  String get plugin_permissionSystemMicrophone;

  /// No description provided for @plugin_permissionLocation.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get plugin_permissionLocation;

  /// No description provided for @plugin_permissionStorage.
  ///
  /// In zh, this message translates to:
  /// **'存储'**
  String get plugin_permissionStorage;

  /// No description provided for @plugin_permissionPlatformStorage.
  ///
  /// In zh, this message translates to:
  /// **'平台存储'**
  String get plugin_permissionPlatformStorage;

  /// No description provided for @plugin_permissionSystemClipboard.
  ///
  /// In zh, this message translates to:
  /// **'系统剪贴板'**
  String get plugin_permissionSystemClipboard;

  /// No description provided for @plugin_permissionPlatformServices.
  ///
  /// In zh, this message translates to:
  /// **'平台服务'**
  String get plugin_permissionPlatformServices;

  /// No description provided for @plugin_permissionPlatformUI.
  ///
  /// In zh, this message translates to:
  /// **'平台UI'**
  String get plugin_permissionPlatformUI;

  /// No description provided for @plugin_permissionPluginCommunication.
  ///
  /// In zh, this message translates to:
  /// **'插件通信'**
  String get plugin_permissionPluginCommunication;

  /// No description provided for @plugin_permissionPluginDataSharing.
  ///
  /// In zh, this message translates to:
  /// **'插件数据共享'**
  String get plugin_permissionPluginDataSharing;

  /// No description provided for @plugin_lastUsed.
  ///
  /// In zh, this message translates to:
  /// **'最后使用: {time}'**
  String plugin_lastUsed(String time);

  /// No description provided for @plugin_permissionCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个权限'**
  String plugin_permissionCount(int count);

  /// No description provided for @plugin_permissionCountSingle.
  ///
  /// In zh, this message translates to:
  /// **'1 个权限'**
  String get plugin_permissionCountSingle;

  /// No description provided for @time_daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{days}天前'**
  String time_daysAgo(int days);

  /// No description provided for @time_hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{hours}小时前'**
  String time_hoursAgo(int hours);

  /// No description provided for @time_minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{minutes}分钟前'**
  String time_minutesAgo(int minutes);

  /// No description provided for @time_justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get time_justNow;

  /// No description provided for @worldClock_title.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟'**
  String get worldClock_title;

  /// No description provided for @worldClock_addClock.
  ///
  /// In zh, this message translates to:
  /// **'添加时钟'**
  String get worldClock_addClock;

  /// No description provided for @worldClock_addCountdown.
  ///
  /// In zh, this message translates to:
  /// **'添加倒计时'**
  String get worldClock_addCountdown;

  /// No description provided for @worldClock_settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get worldClock_settings;

  /// No description provided for @worldClock_noClocks.
  ///
  /// In zh, this message translates to:
  /// **'暂无时钟，点击右上角添加'**
  String get worldClock_noClocks;

  /// No description provided for @worldClock_noCountdowns.
  ///
  /// In zh, this message translates to:
  /// **'暂无倒计时，点击右上角添加'**
  String get worldClock_noCountdowns;

  /// No description provided for @worldClock_defaultClock.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get worldClock_defaultClock;

  /// No description provided for @worldClock_deleteClock.
  ///
  /// In zh, this message translates to:
  /// **'删除时钟'**
  String get worldClock_deleteClock;

  /// No description provided for @worldClock_deleteCountdown.
  ///
  /// In zh, this message translates to:
  /// **'删除倒计时'**
  String get worldClock_deleteCountdown;

  /// No description provided for @worldClock_confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get worldClock_confirmDelete;

  /// No description provided for @worldClock_confirmDeleteClock.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除 {cityName} 的时钟吗？'**
  String worldClock_confirmDeleteClock(String cityName);

  /// No description provided for @worldClock_confirmDeleteCountdown.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除倒计时 \"{title}\" 吗？'**
  String worldClock_confirmDeleteCountdown(String title);

  /// No description provided for @worldClock_addClockTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加时钟'**
  String get worldClock_addClockTitle;

  /// No description provided for @worldClock_cityName.
  ///
  /// In zh, this message translates to:
  /// **'城市名称'**
  String get worldClock_cityName;

  /// No description provided for @worldClock_cityNameHint.
  ///
  /// In zh, this message translates to:
  /// **'输入城市名称'**
  String get worldClock_cityNameHint;

  /// No description provided for @worldClock_timeZone.
  ///
  /// In zh, this message translates to:
  /// **'时区'**
  String get worldClock_timeZone;

  /// No description provided for @worldClock_addCountdownTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加倒计时'**
  String get worldClock_addCountdownTitle;

  /// No description provided for @worldClock_countdownTitle.
  ///
  /// In zh, this message translates to:
  /// **'倒计时标题'**
  String get worldClock_countdownTitle;

  /// No description provided for @worldClock_countdownTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'输入提醒内容'**
  String get worldClock_countdownTitleHint;

  /// No description provided for @worldClock_hours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get worldClock_hours;

  /// No description provided for @worldClock_minutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get worldClock_minutes;

  /// No description provided for @worldClock_seconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get worldClock_seconds;

  /// No description provided for @worldClock_countdownComplete.
  ///
  /// In zh, this message translates to:
  /// **'倒计时提醒: {title} 时间到了！'**
  String worldClock_countdownComplete(String title);

  /// No description provided for @worldClock_completed.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get worldClock_completed;

  /// No description provided for @worldClock_almostComplete.
  ///
  /// In zh, this message translates to:
  /// **'即将完成！'**
  String get worldClock_almostComplete;

  /// No description provided for @worldClock_remaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {time}'**
  String worldClock_remaining(String time);

  /// No description provided for @worldClock_remainingMinutes.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {minutes} 分钟'**
  String worldClock_remainingMinutes(int minutes);

  /// No description provided for @worldClock_remainingHours.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {hours} 小时 {minutes} 分钟'**
  String worldClock_remainingHours(int hours, int minutes);

  /// No description provided for @worldClock_remainingDays.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {days} 天 {hours} 小时'**
  String worldClock_remainingDays(int days, int hours);

  /// No description provided for @worldClock_settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟设置'**
  String get worldClock_settingsTitle;

  /// No description provided for @worldClock_settingsDesc.
  ///
  /// In zh, this message translates to:
  /// **'设置选项将在后续版本中添加'**
  String get worldClock_settingsDesc;

  /// No description provided for @worldClock_currentFeatures.
  ///
  /// In zh, this message translates to:
  /// **'当前功能：'**
  String get worldClock_currentFeatures;

  /// No description provided for @worldClock_featureMultipleTimezones.
  ///
  /// In zh, this message translates to:
  /// **'• 显示多个时区时间'**
  String get worldClock_featureMultipleTimezones;

  /// No description provided for @worldClock_featureCountdown.
  ///
  /// In zh, this message translates to:
  /// **'• 倒计时提醒'**
  String get worldClock_featureCountdown;

  /// No description provided for @worldClock_featureBeijingDefault.
  ///
  /// In zh, this message translates to:
  /// **'• 默认北京时间'**
  String get worldClock_featureBeijingDefault;

  /// No description provided for @pet_openMainApp.
  ///
  /// In zh, this message translates to:
  /// **'打开主应用'**
  String get pet_openMainApp;

  /// No description provided for @pet_notAvailable.
  ///
  /// In zh, this message translates to:
  /// **'不可用'**
  String get pet_notAvailable;

  /// No description provided for @pet_settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物设置'**
  String get pet_settingsTitle;

  /// No description provided for @pet_opacity.
  ///
  /// In zh, this message translates to:
  /// **'透明度:'**
  String get pet_opacity;

  /// No description provided for @pet_enableAnimations.
  ///
  /// In zh, this message translates to:
  /// **'启用动画'**
  String get pet_enableAnimations;

  /// No description provided for @pet_animationsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'呼吸和眨眼效果'**
  String get pet_animationsSubtitle;

  /// No description provided for @pet_enableInteractions.
  ///
  /// In zh, this message translates to:
  /// **'启用交互'**
  String get pet_enableInteractions;

  /// No description provided for @pet_interactionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点击和拖拽交互'**
  String get pet_interactionsSubtitle;

  /// No description provided for @pet_autoHide.
  ///
  /// In zh, this message translates to:
  /// **'自动隐藏'**
  String get pet_autoHide;

  /// No description provided for @pet_autoHideSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'不使用时隐藏'**
  String get pet_autoHideSubtitle;

  /// No description provided for @pet_reset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get pet_reset;

  /// No description provided for @pet_done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get pet_done;

  /// No description provided for @pet_moving.
  ///
  /// In zh, this message translates to:
  /// **'移动中...'**
  String get pet_moving;

  /// No description provided for @tooltip_switchPlugin.
  ///
  /// In zh, this message translates to:
  /// **'切换插件'**
  String get tooltip_switchPlugin;

  /// No description provided for @tooltip_pausePlugin.
  ///
  /// In zh, this message translates to:
  /// **'移至后台'**
  String get tooltip_pausePlugin;

  /// No description provided for @tooltip_stopPlugin.
  ///
  /// In zh, this message translates to:
  /// **'停止插件'**
  String get tooltip_stopPlugin;

  /// No description provided for @tooltip_switchMode.
  ///
  /// In zh, this message translates to:
  /// **'切换插件'**
  String get tooltip_switchMode;

  /// No description provided for @tooltip_pauseMode.
  ///
  /// In zh, this message translates to:
  /// **'移至后台'**
  String get tooltip_pauseMode;

  /// No description provided for @info_platformType.
  ///
  /// In zh, this message translates to:
  /// **'平台类型'**
  String get info_platformType;

  /// No description provided for @info_version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get info_version;

  /// No description provided for @info_currentMode.
  ///
  /// In zh, this message translates to:
  /// **'当前模式'**
  String get info_currentMode;

  /// No description provided for @info_unknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get info_unknown;

  /// No description provided for @info_capabilities.
  ///
  /// In zh, this message translates to:
  /// **'功能特性'**
  String get info_capabilities;

  /// No description provided for @info_statistics.
  ///
  /// In zh, this message translates to:
  /// **'统计信息'**
  String get info_statistics;

  /// No description provided for @info_availablePlugins.
  ///
  /// In zh, this message translates to:
  /// **'可用插件'**
  String get info_availablePlugins;

  /// No description provided for @info_activePlugins.
  ///
  /// In zh, this message translates to:
  /// **'活动插件'**
  String get info_activePlugins;

  /// No description provided for @info_availableFeatures.
  ///
  /// In zh, this message translates to:
  /// **'可用功能'**
  String get info_availableFeatures;

  /// No description provided for @capability_desktopPetSupport.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物支持'**
  String get capability_desktopPetSupport;

  /// No description provided for @capability_alwaysOnTop.
  ///
  /// In zh, this message translates to:
  /// **'窗口置顶'**
  String get capability_alwaysOnTop;

  /// No description provided for @capability_systemTray.
  ///
  /// In zh, this message translates to:
  /// **'系统托盘'**
  String get capability_systemTray;

  /// No description provided for @feature_plugin_management.
  ///
  /// In zh, this message translates to:
  /// **'插件管理'**
  String get feature_plugin_management;

  /// No description provided for @feature_plugin_management_desc.
  ///
  /// In zh, this message translates to:
  /// **'安装、更新和管理插件'**
  String get feature_plugin_management_desc;

  /// No description provided for @feature_local_storage.
  ///
  /// In zh, this message translates to:
  /// **'本地存储'**
  String get feature_local_storage;

  /// No description provided for @feature_local_storage_desc.
  ///
  /// In zh, this message translates to:
  /// **'在设备上持久化存储数据'**
  String get feature_local_storage_desc;

  /// No description provided for @feature_offline_plugins.
  ///
  /// In zh, this message translates to:
  /// **'离线插件'**
  String get feature_offline_plugins;

  /// No description provided for @feature_offline_plugins_desc.
  ///
  /// In zh, this message translates to:
  /// **'无网络时也可使用插件'**
  String get feature_offline_plugins_desc;

  /// No description provided for @feature_local_preferences.
  ///
  /// In zh, this message translates to:
  /// **'本地设置'**
  String get feature_local_preferences;

  /// No description provided for @feature_local_preferences_desc.
  ///
  /// In zh, this message translates to:
  /// **'自定义本地体验'**
  String get feature_local_preferences_desc;

  /// No description provided for @feature_cloud_sync.
  ///
  /// In zh, this message translates to:
  /// **'云同步'**
  String get feature_cloud_sync;

  /// No description provided for @feature_cloud_sync_desc.
  ///
  /// In zh, this message translates to:
  /// **'跨设备同步数据'**
  String get feature_cloud_sync_desc;

  /// No description provided for @feature_multiplayer.
  ///
  /// In zh, this message translates to:
  /// **'多人协作'**
  String get feature_multiplayer;

  /// No description provided for @feature_multiplayer_desc.
  ///
  /// In zh, this message translates to:
  /// **'与他人实时协作'**
  String get feature_multiplayer_desc;

  /// No description provided for @feature_online_plugins.
  ///
  /// In zh, this message translates to:
  /// **'在线插件'**
  String get feature_online_plugins;

  /// No description provided for @feature_online_plugins_desc.
  ///
  /// In zh, this message translates to:
  /// **'访问云端插件库'**
  String get feature_online_plugins_desc;

  /// No description provided for @feature_cloud_storage.
  ///
  /// In zh, this message translates to:
  /// **'云存储'**
  String get feature_cloud_storage;

  /// No description provided for @feature_cloud_storage_desc.
  ///
  /// In zh, this message translates to:
  /// **'云端数据无限存储'**
  String get feature_cloud_storage_desc;

  /// No description provided for @feature_remote_config.
  ///
  /// In zh, this message translates to:
  /// **'远程配置'**
  String get feature_remote_config;

  /// No description provided for @feature_remote_config_desc.
  ///
  /// In zh, this message translates to:
  /// **'远程管理功能配置'**
  String get feature_remote_config_desc;

  /// No description provided for @feature_status_implemented.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get feature_status_implemented;

  /// No description provided for @feature_status_partial.
  ///
  /// In zh, this message translates to:
  /// **'测试版'**
  String get feature_status_partial;

  /// No description provided for @feature_status_planned.
  ///
  /// In zh, this message translates to:
  /// **'即将推出'**
  String get feature_status_planned;

  /// No description provided for @feature_status_deprecated.
  ///
  /// In zh, this message translates to:
  /// **'已弃用'**
  String get feature_status_deprecated;

  /// No description provided for @feature_learn_more.
  ///
  /// In zh, this message translates to:
  /// **'了解更多'**
  String get feature_learn_more;

  /// No description provided for @feature_planned_for_version.
  ///
  /// In zh, this message translates to:
  /// **'计划于版本 {version} 推出'**
  String feature_planned_for_version(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

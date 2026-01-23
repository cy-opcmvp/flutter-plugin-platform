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
  /// **'多功能插件平台'**
  String get appTitle;

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'多功能插件平台'**
  String get appName;

  /// No description provided for @autoStart.
  ///
  /// In zh, this message translates to:
  /// **'开机自启动'**
  String get autoStart;

  /// No description provided for @autoStartPlugin.
  ///
  /// In zh, this message translates to:
  /// **'插件自启动'**
  String get autoStartPlugin;

  /// No description provided for @autoStartDescription.
  ///
  /// In zh, this message translates to:
  /// **'开机自启动'**
  String get autoStartDescription;

  /// No description provided for @autoStartedPlugins.
  ///
  /// In zh, this message translates to:
  /// **'已自动启动 {count} 个插件'**
  String autoStartedPlugins(Object count);

  /// No description provided for @autoStartAdded.
  ///
  /// In zh, this message translates to:
  /// **'已添加到自启动列表'**
  String get autoStartAdded;

  /// No description provided for @autoStartRemoved.
  ///
  /// In zh, this message translates to:
  /// **'已从自启动列表移除'**
  String get autoStartRemoved;

  /// No description provided for @autoStartPlugins_empty.
  ///
  /// In zh, this message translates to:
  /// **'暂无自启动插件'**
  String get autoStartPlugins_empty;

  /// No description provided for @tag_title.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get tag_title;

  /// No description provided for @tag_add.
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get tag_add;

  /// No description provided for @tag_edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑标签'**
  String get tag_edit;

  /// No description provided for @tag_delete.
  ///
  /// In zh, this message translates to:
  /// **'删除标签'**
  String get tag_delete;

  /// No description provided for @tag_name.
  ///
  /// In zh, this message translates to:
  /// **'标签名称'**
  String get tag_name;

  /// No description provided for @tag_description.
  ///
  /// In zh, this message translates to:
  /// **'标签描述'**
  String get tag_description;

  /// No description provided for @tag_color.
  ///
  /// In zh, this message translates to:
  /// **'标签颜色'**
  String get tag_color;

  /// No description provided for @tag_icon.
  ///
  /// In zh, this message translates to:
  /// **'标签图标'**
  String get tag_icon;

  /// No description provided for @tag_create_success.
  ///
  /// In zh, this message translates to:
  /// **'标签创建成功'**
  String get tag_create_success;

  /// No description provided for @tag_update_success.
  ///
  /// In zh, this message translates to:
  /// **'标签更新成功'**
  String get tag_update_success;

  /// No description provided for @tag_delete_success.
  ///
  /// In zh, this message translates to:
  /// **'标签删除成功'**
  String get tag_delete_success;

  /// No description provided for @tag_delete_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除标签 \"{name}\" 吗？'**
  String tag_delete_confirm(Object name);

  /// No description provided for @tag_in_use.
  ///
  /// In zh, this message translates to:
  /// **'该标签正在被使用中，无法删除'**
  String get tag_in_use;

  /// No description provided for @tag_system_protected.
  ///
  /// In zh, this message translates to:
  /// **'系统标签无法删除或修改'**
  String get tag_system_protected;

  /// No description provided for @tag_assign_success.
  ///
  /// In zh, this message translates to:
  /// **'标签分配成功'**
  String get tag_assign_success;

  /// No description provided for @tag_assign_removed.
  ///
  /// In zh, this message translates to:
  /// **'标签已移除'**
  String get tag_assign_removed;

  /// No description provided for @tag_filter_all.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get tag_filter_all;

  /// No description provided for @tag_filter_active.
  ///
  /// In zh, this message translates to:
  /// **'已选择 {count} 个标签'**
  String tag_filter_active(Object count);

  /// No description provided for @tag_no_tags.
  ///
  /// In zh, this message translates to:
  /// **'暂无标签'**
  String get tag_no_tags;

  /// No description provided for @tag_total.
  ///
  /// In zh, this message translates to:
  /// **'个标签'**
  String get tag_total;

  /// No description provided for @tag_and_more.
  ///
  /// In zh, this message translates to:
  /// **'还有'**
  String get tag_and_more;

  /// No description provided for @tag_items.
  ///
  /// In zh, this message translates to:
  /// **'个'**
  String get tag_items;

  /// No description provided for @tag_manage.
  ///
  /// In zh, this message translates to:
  /// **'管理标签'**
  String get tag_manage;

  /// No description provided for @tag_create_hint.
  ///
  /// In zh, this message translates to:
  /// **'创建自定义标签'**
  String get tag_create_hint;

  /// No description provided for @tag_select_hint.
  ///
  /// In zh, this message translates to:
  /// **'选择标签进行筛选'**
  String get tag_select_hint;

  /// No description provided for @tag_empty.
  ///
  /// In zh, this message translates to:
  /// **'没有标签'**
  String get tag_empty;

  /// No description provided for @tag_popular.
  ///
  /// In zh, this message translates to:
  /// **'热门标签'**
  String get tag_popular;

  /// No description provided for @tag_productivity.
  ///
  /// In zh, this message translates to:
  /// **'生产力工具'**
  String get tag_productivity;

  /// No description provided for @tag_system.
  ///
  /// In zh, this message translates to:
  /// **'系统工具'**
  String get tag_system;

  /// No description provided for @tag_entertainment.
  ///
  /// In zh, this message translates to:
  /// **'娱乐休闲'**
  String get tag_entertainment;

  /// No description provided for @tag_game.
  ///
  /// In zh, this message translates to:
  /// **'游戏'**
  String get tag_game;

  /// No description provided for @tag_development.
  ///
  /// In zh, this message translates to:
  /// **'开发工具'**
  String get tag_development;

  /// No description provided for @tag_favorite.
  ///
  /// In zh, this message translates to:
  /// **'常用'**
  String get tag_favorite;

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

  /// No description provided for @button_open.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get button_open;

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

  /// No description provided for @autoStartEnabled.
  ///
  /// In zh, this message translates to:
  /// **'开机自启：已开启'**
  String get autoStartEnabled;

  /// No description provided for @autoStartDisabled.
  ///
  /// In zh, this message translates to:
  /// **'开机自启：已关闭'**
  String get autoStartDisabled;

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

  /// No description provided for @plugin_disableSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件 {name} 已禁用'**
  String plugin_disableSuccess(String name);

  /// No description provided for @plugin_enableSuccess.
  ///
  /// In zh, this message translates to:
  /// **'插件 {name} 已启用'**
  String plugin_enableSuccess(String name);

  /// No description provided for @button_disable.
  ///
  /// In zh, this message translates to:
  /// **'禁用'**
  String get button_disable;

  /// No description provided for @button_enable.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get button_enable;

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
  /// **'本地模式'**
  String get mode_local;

  /// No description provided for @mode_online.
  ///
  /// In zh, this message translates to:
  /// **'在线模式'**
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

  /// No description provided for @settings_title.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings_title;

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

  /// No description provided for @settings_app.
  ///
  /// In zh, this message translates to:
  /// **'应用设置'**
  String get settings_app;

  /// No description provided for @settings_general.
  ///
  /// In zh, this message translates to:
  /// **'常规设置'**
  String get settings_general;

  /// No description provided for @settings_appName.
  ///
  /// In zh, this message translates to:
  /// **'应用名称'**
  String get settings_appName;

  /// No description provided for @settings_appVersion.
  ///
  /// In zh, this message translates to:
  /// **'应用版本'**
  String get settings_appVersion;

  /// No description provided for @appInfo_title.
  ///
  /// In zh, this message translates to:
  /// **'应用信息'**
  String get appInfo_title;

  /// No description provided for @appInfo_viewDetails.
  ///
  /// In zh, this message translates to:
  /// **'查看应用信息、配置功能和管理标签'**
  String get appInfo_viewDetails;

  /// No description provided for @appInfo_section_app.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get appInfo_section_app;

  /// No description provided for @appInfo_section_features.
  ///
  /// In zh, this message translates to:
  /// **'功能状态'**
  String get appInfo_section_features;

  /// No description provided for @appInfo_section_developerTools.
  ///
  /// In zh, this message translates to:
  /// **'开发者工具'**
  String get appInfo_section_developerTools;

  /// No description provided for @appInfo_serviceTest_desc.
  ///
  /// In zh, this message translates to:
  /// **'测试和调试平台服务'**
  String get appInfo_serviceTest_desc;

  /// No description provided for @settings_changeTheme.
  ///
  /// In zh, this message translates to:
  /// **'更改主题'**
  String get settings_changeTheme;

  /// No description provided for @settings_themeChanged.
  ///
  /// In zh, this message translates to:
  /// **'主题已更改为 {theme}'**
  String settings_themeChanged(String theme);

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

  /// No description provided for @settings_currentLanguage.
  ///
  /// In zh, this message translates to:
  /// **'当前语言'**
  String get settings_currentLanguage;

  /// No description provided for @settings_changeLanguage.
  ///
  /// In zh, this message translates to:
  /// **'更改语言'**
  String get settings_changeLanguage;

  /// No description provided for @settings_languageChanged.
  ///
  /// In zh, this message translates to:
  /// **'语言已更改为 {language}'**
  String settings_languageChanged(String language);

  /// No description provided for @settings_global.
  ///
  /// In zh, this message translates to:
  /// **'全局配置'**
  String get settings_global;

  /// No description provided for @settings_features.
  ///
  /// In zh, this message translates to:
  /// **'功能设置'**
  String get settings_features;

  /// No description provided for @settings_services.
  ///
  /// In zh, this message translates to:
  /// **'服务设置'**
  String get settings_services;

  /// No description provided for @tray_title.
  ///
  /// In zh, this message translates to:
  /// **'系统托盘'**
  String get tray_title;

  /// No description provided for @tray_enabled.
  ///
  /// In zh, this message translates to:
  /// **'启用系统托盘'**
  String get tray_enabled;

  /// No description provided for @tray_enabled_desc.
  ///
  /// In zh, this message translates to:
  /// **'在系统托盘显示应用图标'**
  String get tray_enabled_desc;

  /// No description provided for @tray_tooltip.
  ///
  /// In zh, this message translates to:
  /// **'托盘提示'**
  String get tray_tooltip;

  /// No description provided for @tray_menu.
  ///
  /// In zh, this message translates to:
  /// **'托盘菜单'**
  String get tray_menu;

  /// No description provided for @tray_menu_edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑菜单'**
  String get tray_menu_edit;

  /// No description provided for @tray_menu_add.
  ///
  /// In zh, this message translates to:
  /// **'添加菜单项'**
  String get tray_menu_add;

  /// No description provided for @tray_menu_item_type.
  ///
  /// In zh, this message translates to:
  /// **'菜单项类型'**
  String get tray_menu_item_type;

  /// No description provided for @tray_menu_item_text.
  ///
  /// In zh, this message translates to:
  /// **'菜单项文本'**
  String get tray_menu_item_text;

  /// No description provided for @tray_menu_item_action.
  ///
  /// In zh, this message translates to:
  /// **'动作类型'**
  String get tray_menu_item_action;

  /// No description provided for @tray_menu_item_enabled.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get tray_menu_item_enabled;

  /// No description provided for @tray_menu_item_visible.
  ///
  /// In zh, this message translates to:
  /// **'可见'**
  String get tray_menu_item_visible;

  /// No description provided for @tray_menu_item_checked.
  ///
  /// In zh, this message translates to:
  /// **'已勾选'**
  String get tray_menu_item_checked;

  /// No description provided for @tray_menu_separator.
  ///
  /// In zh, this message translates to:
  /// **'分隔符'**
  String get tray_menu_separator;

  /// No description provided for @tray_menu_normal.
  ///
  /// In zh, this message translates to:
  /// **'普通菜单项'**
  String get tray_menu_normal;

  /// No description provided for @tray_menu_submenu.
  ///
  /// In zh, this message translates to:
  /// **'子菜单'**
  String get tray_menu_submenu;

  /// No description provided for @tray_menu_action_show_hide.
  ///
  /// In zh, this message translates to:
  /// **'显示/隐藏'**
  String get tray_menu_action_show_hide;

  /// No description provided for @tray_menu_action_quit.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get tray_menu_action_quit;

  /// No description provided for @tray_menu_action_settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get tray_menu_action_settings;

  /// No description provided for @tray_menu_action_custom.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get tray_menu_action_custom;

  /// No description provided for @tray_minimize_to_tray.
  ///
  /// In zh, this message translates to:
  /// **'最小化到托盘'**
  String get tray_minimize_to_tray;

  /// No description provided for @tray_minimize_to_tray_desc.
  ///
  /// In zh, this message translates to:
  /// **'关闭窗口时隐藏到托盘而非退出'**
  String get tray_minimize_to_tray_desc;

  /// No description provided for @tray_start_minimized.
  ///
  /// In zh, this message translates to:
  /// **'启动时最小化到托盘'**
  String get tray_start_minimized;

  /// No description provided for @tray_menu_saved.
  ///
  /// In zh, this message translates to:
  /// **'菜单已保存'**
  String get tray_menu_saved;

  /// No description provided for @tray_menu_reset_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要重置为默认菜单吗？'**
  String get tray_menu_reset_confirm;

  /// No description provided for @settings_advanced.
  ///
  /// In zh, this message translates to:
  /// **'高级设置'**
  String get settings_advanced;

  /// No description provided for @settings_plugins.
  ///
  /// In zh, this message translates to:
  /// **'插件配置'**
  String get settings_plugins;

  /// No description provided for @settings_autoStart.
  ///
  /// In zh, this message translates to:
  /// **'开机自启'**
  String get settings_autoStart;

  /// No description provided for @settings_minimizeToTray.
  ///
  /// In zh, this message translates to:
  /// **'最小化到托盘'**
  String get settings_minimizeToTray;

  /// No description provided for @settings_showDesktopPet.
  ///
  /// In zh, this message translates to:
  /// **'显示桌面宠物'**
  String get settings_showDesktopPet;

  /// No description provided for @settings_enableNotifications.
  ///
  /// In zh, this message translates to:
  /// **'启用通知'**
  String get settings_enableNotifications;

  /// No description provided for @settings_debugMode.
  ///
  /// In zh, this message translates to:
  /// **'调试模式'**
  String get settings_debugMode;

  /// No description provided for @settings_logLevel.
  ///
  /// In zh, this message translates to:
  /// **'日志级别'**
  String get settings_logLevel;

  /// No description provided for @settings_savePath.
  ///
  /// In zh, this message translates to:
  /// **'保存路径'**
  String get settings_savePath;

  /// No description provided for @settings_filenameFormat.
  ///
  /// In zh, this message translates to:
  /// **'文件名格式'**
  String get settings_filenameFormat;

  /// No description provided for @settings_imageFormat.
  ///
  /// In zh, this message translates to:
  /// **'图片格式'**
  String get settings_imageFormat;

  /// No description provided for @settings_imageQuality.
  ///
  /// In zh, this message translates to:
  /// **'图片质量'**
  String get settings_imageQuality;

  /// No description provided for @settings_autoCopyToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'自动复制到剪贴板'**
  String get settings_autoCopyToClipboard;

  /// No description provided for @settings_showPreview.
  ///
  /// In zh, this message translates to:
  /// **'显示预览窗口'**
  String get settings_showPreview;

  /// No description provided for @settings_saveHistory.
  ///
  /// In zh, this message translates to:
  /// **'保存历史记录'**
  String get settings_saveHistory;

  /// No description provided for @settings_maxHistoryCount.
  ///
  /// In zh, this message translates to:
  /// **'最大历史记录数'**
  String get settings_maxHistoryCount;

  /// No description provided for @settings_shortcuts.
  ///
  /// In zh, this message translates to:
  /// **'快捷键设置'**
  String get settings_shortcuts;

  /// No description provided for @settings_regionCapture.
  ///
  /// In zh, this message translates to:
  /// **'区域截图'**
  String get settings_regionCapture;

  /// No description provided for @settings_fullScreenCapture.
  ///
  /// In zh, this message translates to:
  /// **'全屏截图'**
  String get settings_fullScreenCapture;

  /// No description provided for @settings_windowCapture.
  ///
  /// In zh, this message translates to:
  /// **'窗口截图'**
  String get settings_windowCapture;

  /// No description provided for @settings_configSaved.
  ///
  /// In zh, this message translates to:
  /// **'配置已保存'**
  String get settings_configSaved;

  /// No description provided for @settings_configSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'配置保存失败'**
  String get settings_configSaveFailed;

  /// No description provided for @settings_resetToDefaults.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认设置'**
  String get settings_resetToDefaults;

  /// No description provided for @settings_resetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要恢复默认设置吗？此操作不可撤销。'**
  String get settings_resetConfirm;

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

  /// No description provided for @desktopPet_settings_title.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物设置'**
  String get desktopPet_settings_title;

  /// No description provided for @desktopPet_section_appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get desktopPet_section_appearance;

  /// No description provided for @desktopPet_section_behavior.
  ///
  /// In zh, this message translates to:
  /// **'行为'**
  String get desktopPet_section_behavior;

  /// No description provided for @desktopPet_opacity.
  ///
  /// In zh, this message translates to:
  /// **'透明度'**
  String get desktopPet_opacity;

  /// No description provided for @desktopPet_colorTheme.
  ///
  /// In zh, this message translates to:
  /// **'颜色主题'**
  String get desktopPet_colorTheme;

  /// No description provided for @desktopPet_enableAnimations.
  ///
  /// In zh, this message translates to:
  /// **'启用动画'**
  String get desktopPet_enableAnimations;

  /// No description provided for @desktopPet_animationsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'呼吸和眨眼效果'**
  String get desktopPet_animationsSubtitle;

  /// No description provided for @desktopPet_enableInteractions.
  ///
  /// In zh, this message translates to:
  /// **'启用交互'**
  String get desktopPet_enableInteractions;

  /// No description provided for @desktopPet_interactionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点击和拖拽交互'**
  String get desktopPet_interactionsSubtitle;

  /// No description provided for @desktopPet_autoHide.
  ///
  /// In zh, this message translates to:
  /// **'自动隐藏'**
  String get desktopPet_autoHide;

  /// No description provided for @desktopPet_autoHideSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'不使用时隐藏'**
  String get desktopPet_autoHideSubtitle;

  /// No description provided for @desktopPet_enabledSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'在桌面显示宠物角色'**
  String get desktopPet_enabledSubtitle;

  /// No description provided for @desktopPet_openSettings.
  ///
  /// In zh, this message translates to:
  /// **'点击查看详细设置'**
  String get desktopPet_openSettings;

  /// No description provided for @desktopPet_settingsSaved.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物设置已保存'**
  String get desktopPet_settingsSaved;

  /// No description provided for @desktopPet_reset.
  ///
  /// In zh, this message translates to:
  /// **'重置为默认设置'**
  String get desktopPet_reset;

  /// No description provided for @desktopPet_resetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要重置桌面宠物设置吗？'**
  String get desktopPet_resetConfirm;

  /// No description provided for @common_enabled.
  ///
  /// In zh, this message translates to:
  /// **'已启用'**
  String get common_enabled;

  /// No description provided for @common_disabled.
  ///
  /// In zh, this message translates to:
  /// **'已禁用'**
  String get common_disabled;

  /// No description provided for @settings_pluginManagement.
  ///
  /// In zh, this message translates to:
  /// **'插件标签关联'**
  String get settings_pluginManagement;

  /// No description provided for @settings_pluginManagement_desc.
  ///
  /// In zh, this message translates to:
  /// **'配置插件与标签的关联关系'**
  String get settings_pluginManagement_desc;

  /// No description provided for @executable_clearOutput.
  ///
  /// In zh, this message translates to:
  /// **'清空输出'**
  String get executable_clearOutput;

  /// No description provided for @executable_disableAutoScroll.
  ///
  /// In zh, this message translates to:
  /// **'禁用自动滚动'**
  String get executable_disableAutoScroll;

  /// No description provided for @executable_enableAutoScroll.
  ///
  /// In zh, this message translates to:
  /// **'启用自动滚动'**
  String get executable_enableAutoScroll;

  /// No description provided for @executable_scrollToBottom.
  ///
  /// In zh, this message translates to:
  /// **'滚动到底部'**
  String get executable_scrollToBottom;

  /// No description provided for @executable_enterCommand.
  ///
  /// In zh, this message translates to:
  /// **'输入命令...'**
  String get executable_enterCommand;

  /// No description provided for @executable_send.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get executable_send;

  /// No description provided for @pluginManagement_installSample.
  ///
  /// In zh, this message translates to:
  /// **'安装示例插件'**
  String get pluginManagement_installSample;

  /// No description provided for @externalPlugin_details.
  ///
  /// In zh, this message translates to:
  /// **'插件详情'**
  String get externalPlugin_details;

  /// No description provided for @externalPlugin_remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get externalPlugin_remove;

  /// No description provided for @desktopPet_themeDefault.
  ///
  /// In zh, this message translates to:
  /// **'默认蓝色'**
  String get desktopPet_themeDefault;

  /// No description provided for @desktopPet_themeBlue.
  ///
  /// In zh, this message translates to:
  /// **'天空蓝'**
  String get desktopPet_themeBlue;

  /// No description provided for @desktopPet_themeGreen.
  ///
  /// In zh, this message translates to:
  /// **'自然绿'**
  String get desktopPet_themeGreen;

  /// No description provided for @desktopPet_themeOrange.
  ///
  /// In zh, this message translates to:
  /// **'活力橙'**
  String get desktopPet_themeOrange;

  /// No description provided for @desktopPet_themePurple.
  ///
  /// In zh, this message translates to:
  /// **'神秘紫'**
  String get desktopPet_themePurple;

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

  /// No description provided for @mode_local_desc.
  ///
  /// In zh, this message translates to:
  /// **'完全离线运行，所有功能在本地设备上执行，无需网络连接'**
  String get mode_local_desc;

  /// No description provided for @mode_online_desc.
  ///
  /// In zh, this message translates to:
  /// **'联网模式，可访问云端功能和在线服务，需要稳定的网络连接'**
  String get mode_online_desc;

  /// No description provided for @capability_desktopPetSupport.
  ///
  /// In zh, this message translates to:
  /// **'桌面宠物'**
  String get capability_desktopPetSupport;

  /// No description provided for @capability_desktopPetSupport_desc.
  ///
  /// In zh, this message translates to:
  /// **'在桌面上显示可交互的宠物角色'**
  String get capability_desktopPetSupport_desc;

  /// No description provided for @capability_alwaysOnTop.
  ///
  /// In zh, this message translates to:
  /// **'窗口置顶'**
  String get capability_alwaysOnTop;

  /// No description provided for @capability_alwaysOnTop_desc.
  ///
  /// In zh, this message translates to:
  /// **'窗口始终保持最前，不被其他窗口遮挡'**
  String get capability_alwaysOnTop_desc;

  /// No description provided for @capability_systemTray.
  ///
  /// In zh, this message translates to:
  /// **'系统托盘'**
  String get capability_systemTray;

  /// No description provided for @capability_systemTray_desc.
  ///
  /// In zh, this message translates to:
  /// **'最小化到系统托盘，在后台运行'**
  String get capability_systemTray_desc;

  /// No description provided for @capability_supportsEnvironmentVariables.
  ///
  /// In zh, this message translates to:
  /// **'环境变量'**
  String get capability_supportsEnvironmentVariables;

  /// No description provided for @capability_supportsEnvironmentVariables_desc.
  ///
  /// In zh, this message translates to:
  /// **'可访问和修改系统环境变量配置'**
  String get capability_supportsEnvironmentVariables_desc;

  /// No description provided for @capability_supportsFileSystem.
  ///
  /// In zh, this message translates to:
  /// **'文件系统'**
  String get capability_supportsFileSystem;

  /// No description provided for @capability_supportsFileSystem_desc.
  ///
  /// In zh, this message translates to:
  /// **'可读写本地文件系统，保存和加载数据'**
  String get capability_supportsFileSystem_desc;

  /// No description provided for @capability_touchInput.
  ///
  /// In zh, this message translates to:
  /// **'触摸输入'**
  String get capability_touchInput;

  /// No description provided for @capability_touchInput_desc.
  ///
  /// In zh, this message translates to:
  /// **'支持触摸屏交互和多点触控操作（仅移动设备和触摸屏）'**
  String get capability_touchInput_desc;

  /// No description provided for @capability_desktop.
  ///
  /// In zh, this message translates to:
  /// **'桌面平台'**
  String get capability_desktop;

  /// No description provided for @capability_desktop_desc.
  ///
  /// In zh, this message translates to:
  /// **'运行在桌面操作系统上（Windows、macOS、Linux）'**
  String get capability_desktop_desc;

  /// No description provided for @feature_autoStart.
  ///
  /// In zh, this message translates to:
  /// **'开机启动'**
  String get feature_autoStart;

  /// No description provided for @feature_minimizeToTray.
  ///
  /// In zh, this message translates to:
  /// **'最小化到托盘'**
  String get feature_minimizeToTray;

  /// No description provided for @feature_enableNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知功能'**
  String get feature_enableNotifications;

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

  /// No description provided for @plugin_calculator_name.
  ///
  /// In zh, this message translates to:
  /// **'计算器'**
  String get plugin_calculator_name;

  /// No description provided for @plugin_calculator_description.
  ///
  /// In zh, this message translates to:
  /// **'用于基本算术运算的简单计算器工具'**
  String get plugin_calculator_description;

  /// No description provided for @plugin_calculator_initialized.
  ///
  /// In zh, this message translates to:
  /// **'计算器插件已初始化'**
  String get plugin_calculator_initialized;

  /// No description provided for @plugin_calculator_disposed.
  ///
  /// In zh, this message translates to:
  /// **'计算器插件已销毁'**
  String get plugin_calculator_disposed;

  /// No description provided for @plugin_calculator_error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get plugin_calculator_error;

  /// No description provided for @plugin_worldclock_name.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟'**
  String get plugin_worldclock_name;

  /// No description provided for @plugin_worldclock_description.
  ///
  /// In zh, this message translates to:
  /// **'显示多个时区的时间，支持倒计时提醒功能，默认显示北京时间'**
  String get plugin_worldclock_description;

  /// No description provided for @serviceTest_title.
  ///
  /// In zh, this message translates to:
  /// **'平台服务测试'**
  String get serviceTest_title;

  /// No description provided for @serviceTest_notifications.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get serviceTest_notifications;

  /// No description provided for @serviceTest_audio.
  ///
  /// In zh, this message translates to:
  /// **'音频'**
  String get serviceTest_audio;

  /// No description provided for @serviceTest_tasks.
  ///
  /// In zh, this message translates to:
  /// **'任务'**
  String get serviceTest_tasks;

  /// No description provided for @serviceTest_activityLog.
  ///
  /// In zh, this message translates to:
  /// **'活动日志'**
  String get serviceTest_activityLog;

  /// No description provided for @serviceTest_clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get serviceTest_clear;

  /// No description provided for @serviceTest_copyAll.
  ///
  /// In zh, this message translates to:
  /// **'复制全部'**
  String get serviceTest_copyAll;

  /// No description provided for @serviceTest_copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get serviceTest_copied;

  /// No description provided for @serviceTest_logCopied.
  ///
  /// In zh, this message translates to:
  /// **'日志已复制到剪贴板'**
  String get serviceTest_logCopied;

  /// No description provided for @serviceTest_allLogsCopied.
  ///
  /// In zh, this message translates to:
  /// **'所有日志已复制到剪贴板'**
  String get serviceTest_allLogsCopied;

  /// No description provided for @serviceTest_permissionGranted.
  ///
  /// In zh, this message translates to:
  /// **'通知权限已授予'**
  String get serviceTest_permissionGranted;

  /// No description provided for @serviceTest_permissionNotGranted.
  ///
  /// In zh, this message translates to:
  /// **'通知权限未授予'**
  String get serviceTest_permissionNotGranted;

  /// No description provided for @serviceTest_requestPermission.
  ///
  /// In zh, this message translates to:
  /// **'请求权限'**
  String get serviceTest_requestPermission;

  /// No description provided for @serviceTest_windowsPlatform.
  ///
  /// In zh, this message translates to:
  /// **'Windows 平台'**
  String get serviceTest_windowsPlatform;

  /// No description provided for @serviceTest_windowsNotice.
  ///
  /// In zh, this message translates to:
  /// **'计划通知将在 Windows 上立即显示。请使用任务标签页中的倒计时定时器来实现定时通知。'**
  String get serviceTest_windowsNotice;

  /// No description provided for @serviceTest_notificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'通知标题'**
  String get serviceTest_notificationTitle;

  /// No description provided for @serviceTest_notificationBody.
  ///
  /// In zh, this message translates to:
  /// **'通知内容'**
  String get serviceTest_notificationBody;

  /// No description provided for @serviceTest_defaultNotificationTitle.
  ///
  /// In zh, this message translates to:
  /// **'测试通知'**
  String get serviceTest_defaultNotificationTitle;

  /// No description provided for @serviceTest_defaultNotificationBody.
  ///
  /// In zh, this message translates to:
  /// **'这是来自平台服务的测试通知！'**
  String get serviceTest_defaultNotificationBody;

  /// No description provided for @serviceTest_showNow.
  ///
  /// In zh, this message translates to:
  /// **'立即显示'**
  String get serviceTest_showNow;

  /// No description provided for @serviceTest_schedule.
  ///
  /// In zh, this message translates to:
  /// **'计划 (5秒)'**
  String get serviceTest_schedule;

  /// No description provided for @serviceTest_cancelAll.
  ///
  /// In zh, this message translates to:
  /// **'全部取消'**
  String get serviceTest_cancelAll;

  /// No description provided for @serviceTest_testAudioFeatures.
  ///
  /// In zh, this message translates to:
  /// **'测试各种音频播放功能'**
  String get serviceTest_testAudioFeatures;

  /// No description provided for @serviceTest_audioNotAvailable.
  ///
  /// In zh, this message translates to:
  /// **'此平台上音频服务不可用。某些功能可能被禁用。'**
  String get serviceTest_audioNotAvailable;

  /// No description provided for @serviceTest_notificationSound.
  ///
  /// In zh, this message translates to:
  /// **'通知音效'**
  String get serviceTest_notificationSound;

  /// No description provided for @serviceTest_successSound.
  ///
  /// In zh, this message translates to:
  /// **'成功音效'**
  String get serviceTest_successSound;

  /// No description provided for @serviceTest_errorSound.
  ///
  /// In zh, this message translates to:
  /// **'错误音效'**
  String get serviceTest_errorSound;

  /// No description provided for @serviceTest_warningSound.
  ///
  /// In zh, this message translates to:
  /// **'警告音效'**
  String get serviceTest_warningSound;

  /// No description provided for @serviceTest_clickSound.
  ///
  /// In zh, this message translates to:
  /// **'点击音效'**
  String get serviceTest_clickSound;

  /// No description provided for @serviceTest_globalVolume.
  ///
  /// In zh, this message translates to:
  /// **'全局音量'**
  String get serviceTest_globalVolume;

  /// No description provided for @serviceTest_stopAllAudio.
  ///
  /// In zh, this message translates to:
  /// **'停止所有音频'**
  String get serviceTest_stopAllAudio;

  /// No description provided for @serviceTest_countdownTimer.
  ///
  /// In zh, this message translates to:
  /// **'倒计时定时器'**
  String get serviceTest_countdownTimer;

  /// No description provided for @serviceTest_seconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get serviceTest_seconds;

  /// No description provided for @serviceTest_start.
  ///
  /// In zh, this message translates to:
  /// **'开始'**
  String get serviceTest_start;

  /// No description provided for @serviceTest_cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get serviceTest_cancel;

  /// No description provided for @serviceTest_periodicTask.
  ///
  /// In zh, this message translates to:
  /// **'周期性任务'**
  String get serviceTest_periodicTask;

  /// No description provided for @serviceTest_interval.
  ///
  /// In zh, this message translates to:
  /// **'间隔'**
  String get serviceTest_interval;

  /// No description provided for @serviceTest_activeTasks.
  ///
  /// In zh, this message translates to:
  /// **'活动任务'**
  String get serviceTest_activeTasks;

  /// No description provided for @serviceTest_noActiveTasks.
  ///
  /// In zh, this message translates to:
  /// **'没有活动任务'**
  String get serviceTest_noActiveTasks;

  /// No description provided for @serviceTest_at.
  ///
  /// In zh, this message translates to:
  /// **'在'**
  String get serviceTest_at;

  /// No description provided for @serviceTest_every.
  ///
  /// In zh, this message translates to:
  /// **'每'**
  String get serviceTest_every;

  /// No description provided for @serviceTest_countdownComplete.
  ///
  /// In zh, this message translates to:
  /// **'倒计时完成！'**
  String get serviceTest_countdownComplete;

  /// No description provided for @serviceTest_countdownFinished.
  ///
  /// In zh, this message translates to:
  /// **'您的倒计时已结束。'**
  String get serviceTest_countdownFinished;

  /// No description provided for @serviceTest_error.
  ///
  /// In zh, this message translates to:
  /// **'错误'**
  String get serviceTest_error;

  /// No description provided for @serviceTest_errorPlayingSound.
  ///
  /// In zh, this message translates to:
  /// **'播放音效时出错'**
  String get serviceTest_errorPlayingSound;

  /// No description provided for @serviceTest_audioServiceNotAvailable.
  ///
  /// In zh, this message translates to:
  /// **'音频服务在此平台上不可用'**
  String get serviceTest_audioServiceNotAvailable;

  /// No description provided for @serviceTest_enterValidSeconds.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的秒数'**
  String get serviceTest_enterValidSeconds;

  /// No description provided for @serviceTest_enterValidInterval.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的间隔'**
  String get serviceTest_enterValidInterval;

  /// No description provided for @serviceTest_notificationShown.
  ///
  /// In zh, this message translates to:
  /// **'通知已显示'**
  String get serviceTest_notificationShown;

  /// No description provided for @serviceTest_errorShowingNotification.
  ///
  /// In zh, this message translates to:
  /// **'显示通知时出错'**
  String get serviceTest_errorShowingNotification;

  /// No description provided for @serviceTest_notificationScheduled.
  ///
  /// In zh, this message translates to:
  /// **'通知已计划在 5 秒后显示'**
  String get serviceTest_notificationScheduled;

  /// No description provided for @serviceTest_errorSchedulingNotification.
  ///
  /// In zh, this message translates to:
  /// **'计划通知时出错'**
  String get serviceTest_errorSchedulingNotification;

  /// No description provided for @serviceTest_allNotificationsCancelled.
  ///
  /// In zh, this message translates to:
  /// **'所有通知已取消'**
  String get serviceTest_allNotificationsCancelled;

  /// No description provided for @serviceTest_errorCancellingNotifications.
  ///
  /// In zh, this message translates to:
  /// **'取消通知时出错'**
  String get serviceTest_errorCancellingNotifications;

  /// No description provided for @serviceTest_countdownStarted.
  ///
  /// In zh, this message translates to:
  /// **'倒计时已开始：{seconds} 秒'**
  String serviceTest_countdownStarted(Object seconds);

  /// No description provided for @serviceTest_errorStartingCountdown.
  ///
  /// In zh, this message translates to:
  /// **'启动倒计时出错'**
  String get serviceTest_errorStartingCountdown;

  /// No description provided for @serviceTest_countdownCancelled.
  ///
  /// In zh, this message translates to:
  /// **'倒计时已取消'**
  String get serviceTest_countdownCancelled;

  /// No description provided for @serviceTest_errorCancellingCountdown.
  ///
  /// In zh, this message translates to:
  /// **'取消倒计时出错'**
  String get serviceTest_errorCancellingCountdown;

  /// No description provided for @serviceTest_periodicTaskStarted.
  ///
  /// In zh, this message translates to:
  /// **'周期性任务已启动：每 {interval} 秒'**
  String serviceTest_periodicTaskStarted(Object interval);

  /// No description provided for @serviceTest_errorStartingPeriodicTask.
  ///
  /// In zh, this message translates to:
  /// **'启动周期性任务出错'**
  String get serviceTest_errorStartingPeriodicTask;

  /// No description provided for @serviceTest_periodicTaskCancelled.
  ///
  /// In zh, this message translates to:
  /// **'周期性任务已取消'**
  String get serviceTest_periodicTaskCancelled;

  /// No description provided for @serviceTest_errorCancellingPeriodicTask.
  ///
  /// In zh, this message translates to:
  /// **'取消周期性任务出错'**
  String get serviceTest_errorCancellingPeriodicTask;

  /// No description provided for @serviceTest_periodicTaskExecuted.
  ///
  /// In zh, this message translates to:
  /// **'周期性任务已执行'**
  String get serviceTest_periodicTaskExecuted;

  /// No description provided for @serviceTest_taskCompleted.
  ///
  /// In zh, this message translates to:
  /// **'任务已完成'**
  String get serviceTest_taskCompleted;

  /// No description provided for @serviceTest_taskFailed.
  ///
  /// In zh, this message translates to:
  /// **'任务失败'**
  String get serviceTest_taskFailed;

  /// No description provided for @serviceTest_taskCancelled.
  ///
  /// In zh, this message translates to:
  /// **'任务已取消'**
  String get serviceTest_taskCancelled;

  /// No description provided for @serviceTest_couldNotPlaySound.
  ///
  /// In zh, this message translates to:
  /// **'无法播放音效'**
  String get serviceTest_couldNotPlaySound;

  /// No description provided for @serviceTest_volumeSet.
  ///
  /// In zh, this message translates to:
  /// **'音量设置为 {percent}%'**
  String serviceTest_volumeSet(Object percent);

  /// No description provided for @serviceTest_stoppedAllAudio.
  ///
  /// In zh, this message translates to:
  /// **'已停止所有音频播放'**
  String get serviceTest_stoppedAllAudio;

  /// No description provided for @serviceTest_notificationPermission.
  ///
  /// In zh, this message translates to:
  /// **'通知权限 {status}'**
  String serviceTest_notificationPermission(Object status);

  /// No description provided for @serviceTest_granted.
  ///
  /// In zh, this message translates to:
  /// **'已授予'**
  String get serviceTest_granted;

  /// No description provided for @serviceTest_denied.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get serviceTest_denied;

  /// No description provided for @serviceTest_audioServiceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'音频服务不可用'**
  String get serviceTest_audioServiceUnavailable;

  /// No description provided for @serviceTest_serviceTestInitialized.
  ///
  /// In zh, this message translates to:
  /// **'服务测试屏幕已初始化'**
  String get serviceTest_serviceTestInitialized;

  /// No description provided for @serviceTest_errorMessage.
  ///
  /// In zh, this message translates to:
  /// **'错误信息'**
  String get serviceTest_errorMessage;

  /// No description provided for @serviceTest_copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get serviceTest_copy;

  /// 智能截图插件名称
  ///
  /// In zh, this message translates to:
  /// **'智能截图'**
  String get plugin_screenshot_name;

  /// 智能截图插件描述
  ///
  /// In zh, this message translates to:
  /// **'类似 Snipaste 的专业截图工具，支持区域截图、全屏截图、窗口截图、图片标注和编辑'**
  String get plugin_screenshot_description;

  /// No description provided for @screenshot_region.
  ///
  /// In zh, this message translates to:
  /// **'区域截图'**
  String get screenshot_region;

  /// No description provided for @screenshot_fullScreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏截图'**
  String get screenshot_fullScreen;

  /// No description provided for @screenshot_window.
  ///
  /// In zh, this message translates to:
  /// **'窗口截图'**
  String get screenshot_window;

  /// No description provided for @screenshot_history.
  ///
  /// In zh, this message translates to:
  /// **'截图历史'**
  String get screenshot_history;

  /// No description provided for @screenshot_settings.
  ///
  /// In zh, this message translates to:
  /// **'截图设置'**
  String get screenshot_settings;

  /// No description provided for @screenshot_savePath.
  ///
  /// In zh, this message translates to:
  /// **'保存路径'**
  String get screenshot_savePath;

  /// No description provided for @screenshot_filenameFormat.
  ///
  /// In zh, this message translates to:
  /// **'文件名格式'**
  String get screenshot_filenameFormat;

  /// No description provided for @screenshot_autoCopy.
  ///
  /// In zh, this message translates to:
  /// **'自动复制到剪贴板'**
  String get screenshot_autoCopy;

  /// No description provided for @screenshot_showPreview.
  ///
  /// In zh, this message translates to:
  /// **'显示预览窗口'**
  String get screenshot_showPreview;

  /// No description provided for @screenshot_saveHistory.
  ///
  /// In zh, this message translates to:
  /// **'保存历史记录'**
  String get screenshot_saveHistory;

  /// No description provided for @screenshot_maxHistoryCount.
  ///
  /// In zh, this message translates to:
  /// **'最大历史记录数'**
  String get screenshot_maxHistoryCount;

  /// No description provided for @screenshot_imageFormat.
  ///
  /// In zh, this message translates to:
  /// **'图片格式'**
  String get screenshot_imageFormat;

  /// No description provided for @screenshot_imageQuality.
  ///
  /// In zh, this message translates to:
  /// **'图片质量'**
  String get screenshot_imageQuality;

  /// No description provided for @screenshot_shortcuts.
  ///
  /// In zh, this message translates to:
  /// **'快捷键'**
  String get screenshot_shortcuts;

  /// No description provided for @screenshot_pinSettings.
  ///
  /// In zh, this message translates to:
  /// **'钉图设置'**
  String get screenshot_pinSettings;

  /// No description provided for @screenshot_alwaysOnTop.
  ///
  /// In zh, this message translates to:
  /// **'始终置顶'**
  String get screenshot_alwaysOnTop;

  /// No description provided for @screenshot_defaultOpacity.
  ///
  /// In zh, this message translates to:
  /// **'默认透明度'**
  String get screenshot_defaultOpacity;

  /// No description provided for @screenshot_enableDrag.
  ///
  /// In zh, this message translates to:
  /// **'启用拖拽'**
  String get screenshot_enableDrag;

  /// No description provided for @screenshot_enableResize.
  ///
  /// In zh, this message translates to:
  /// **'启用调整大小'**
  String get screenshot_enableResize;

  /// No description provided for @screenshot_quickActions.
  ///
  /// In zh, this message translates to:
  /// **'快速操作'**
  String get screenshot_quickActions;

  /// No description provided for @screenshot_recentScreenshots.
  ///
  /// In zh, this message translates to:
  /// **'最近截图'**
  String get screenshot_recentScreenshots;

  /// No description provided for @screenshot_statistics.
  ///
  /// In zh, this message translates to:
  /// **'统计信息'**
  String get screenshot_statistics;

  /// No description provided for @screenshot_noScreenshots.
  ///
  /// In zh, this message translates to:
  /// **'暂无截图记录'**
  String get screenshot_noScreenshots;

  /// No description provided for @screenshot_clickToStart.
  ///
  /// In zh, this message translates to:
  /// **'点击上方按钮开始截图'**
  String get screenshot_clickToStart;

  /// No description provided for @screenshot_totalScreenshots.
  ///
  /// In zh, this message translates to:
  /// **'总截图数'**
  String get screenshot_totalScreenshots;

  /// No description provided for @screenshot_todayScreenshots.
  ///
  /// In zh, this message translates to:
  /// **'今日截图'**
  String get screenshot_todayScreenshots;

  /// No description provided for @screenshot_storageUsed.
  ///
  /// In zh, this message translates to:
  /// **'占用空间'**
  String get screenshot_storageUsed;

  /// No description provided for @screenshot_preview.
  ///
  /// In zh, this message translates to:
  /// **'截图预览'**
  String get screenshot_preview;

  /// No description provided for @screenshot_confirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get screenshot_confirmDelete;

  /// No description provided for @screenshot_confirmDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除这张截图吗？'**
  String get screenshot_confirmDeleteMessage;

  /// No description provided for @screenshot_deleted.
  ///
  /// In zh, this message translates to:
  /// **'截图已删除'**
  String get screenshot_deleted;

  /// No description provided for @screenshot_deleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除截图失败'**
  String get screenshot_deleteFailed;

  /// No description provided for @screenshot_saved.
  ///
  /// In zh, this message translates to:
  /// **'截图已保存'**
  String get screenshot_saved;

  /// No description provided for @screenshot_copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get screenshot_copied;

  /// No description provided for @screenshot_error.
  ///
  /// In zh, this message translates to:
  /// **'截图失败'**
  String get screenshot_error;

  /// No description provided for @screenshot_unsupportedPlatform.
  ///
  /// In zh, this message translates to:
  /// **'平台功能受限'**
  String get screenshot_unsupportedPlatform;

  /// No description provided for @screenshot_unsupportedPlatformDesc.
  ///
  /// In zh, this message translates to:
  /// **'此平台暂不完全支持截图功能。支持的平台：Windows、macOS、Linux'**
  String get screenshot_unsupportedPlatformDesc;

  /// No description provided for @screenshot_featureNotImplemented.
  ///
  /// In zh, this message translates to:
  /// **'此功能待实现'**
  String get screenshot_featureNotImplemented;

  /// No description provided for @screenshot_tool_pen.
  ///
  /// In zh, this message translates to:
  /// **'画笔'**
  String get screenshot_tool_pen;

  /// No description provided for @screenshot_tool_rectangle.
  ///
  /// In zh, this message translates to:
  /// **'矩形'**
  String get screenshot_tool_rectangle;

  /// No description provided for @screenshot_tool_arrow.
  ///
  /// In zh, this message translates to:
  /// **'箭头'**
  String get screenshot_tool_arrow;

  /// No description provided for @screenshot_tool_text.
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get screenshot_tool_text;

  /// No description provided for @screenshot_tool_mosaic.
  ///
  /// In zh, this message translates to:
  /// **'马赛克'**
  String get screenshot_tool_mosaic;

  /// No description provided for @screenshot_undo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get screenshot_undo;

  /// No description provided for @screenshot_redo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get screenshot_redo;

  /// No description provided for @screenshot_save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get screenshot_save;

  /// No description provided for @screenshot_cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get screenshot_cancel;

  /// No description provided for @screenshot_type_fullScreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏'**
  String get screenshot_type_fullScreen;

  /// No description provided for @screenshot_type_region.
  ///
  /// In zh, this message translates to:
  /// **'区域'**
  String get screenshot_type_region;

  /// No description provided for @screenshot_type_window.
  ///
  /// In zh, this message translates to:
  /// **'窗口'**
  String get screenshot_type_window;

  /// No description provided for @screenshot_justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get screenshot_justNow;

  /// No description provided for @screenshot_minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟前'**
  String screenshot_minutesAgo(int minutes);

  /// No description provided for @screenshot_hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时前'**
  String screenshot_hoursAgo(int hours);

  /// No description provided for @screenshot_daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天前'**
  String screenshot_daysAgo(int days);

  /// No description provided for @settings_behavior.
  ///
  /// In zh, this message translates to:
  /// **'行为'**
  String get settings_behavior;

  /// No description provided for @screenshot_config_title.
  ///
  /// In zh, this message translates to:
  /// **'截图插件配置'**
  String get screenshot_config_title;

  /// No description provided for @plugin_version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get plugin_version;

  /// No description provided for @plugin_type_label.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get plugin_type_label;

  /// No description provided for @plugin_id_label.
  ///
  /// In zh, this message translates to:
  /// **'ID'**
  String get plugin_id_label;

  /// No description provided for @plugin_background_plugins.
  ///
  /// In zh, this message translates to:
  /// **'后台插件'**
  String get plugin_background_plugins;

  /// No description provided for @plugin_pauseFailed.
  ///
  /// In zh, this message translates to:
  /// **'暂停插件失败: {message}'**
  String plugin_pauseFailed(String message);

  /// No description provided for @plugin_update_label.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get plugin_update_label;

  /// No description provided for @plugin_rollback_label.
  ///
  /// In zh, this message translates to:
  /// **'回滚'**
  String get plugin_rollback_label;

  /// No description provided for @plugin_remove_label.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get plugin_remove_label;

  /// No description provided for @screenshot_select_window.
  ///
  /// In zh, this message translates to:
  /// **'选择窗口'**
  String get screenshot_select_window;

  /// No description provided for @screenshot_close_preview.
  ///
  /// In zh, this message translates to:
  /// **'关闭预览'**
  String get screenshot_close_preview;

  /// No description provided for @screenshot_share_not_implemented.
  ///
  /// In zh, this message translates to:
  /// **'分享功能待实现'**
  String get screenshot_share_not_implemented;

  /// No description provided for @screenshot_saved_to_temp.
  ///
  /// In zh, this message translates to:
  /// **'已保存到临时文件'**
  String get screenshot_saved_to_temp;

  /// No description provided for @screenshot_copy_failed.
  ///
  /// In zh, this message translates to:
  /// **'复制到剪贴板失败'**
  String get screenshot_copy_failed;

  /// No description provided for @screenshot_image_load_failed.
  ///
  /// In zh, this message translates to:
  /// **'图片加载失败'**
  String get screenshot_image_load_failed;

  /// No description provided for @screenshot_file_not_exists.
  ///
  /// In zh, this message translates to:
  /// **'文件不存在'**
  String get screenshot_file_not_exists;

  /// No description provided for @screenshot_window_not_available.
  ///
  /// In zh, this message translates to:
  /// **'窗口选择不可用'**
  String get screenshot_window_not_available;

  /// No description provided for @screenshot_region_failed.
  ///
  /// In zh, this message translates to:
  /// **'区域截图失败: {error}'**
  String screenshot_region_failed(String error);

  /// No description provided for @screenshot_fullscreen_failed.
  ///
  /// In zh, this message translates to:
  /// **'全屏截图失败: {error}'**
  String screenshot_fullscreen_failed(String error);

  /// No description provided for @screenshot_native_window_failed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开原生截图窗口'**
  String get screenshot_native_window_failed;

  /// No description provided for @screenshot_window_failed.
  ///
  /// In zh, this message translates to:
  /// **'窗口截图失败: {error}'**
  String screenshot_window_failed(String error);

  /// No description provided for @worldClock_section_clocks.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟'**
  String get worldClock_section_clocks;

  /// No description provided for @worldClock_section_countdown.
  ///
  /// In zh, this message translates to:
  /// **'倒计时提醒'**
  String get worldClock_section_countdown;

  /// No description provided for @worldClock_empty_clocks.
  ///
  /// In zh, this message translates to:
  /// **'暂无时钟'**
  String get worldClock_empty_clocks;

  /// No description provided for @worldClock_empty_clocks_hint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角 + 添加时钟'**
  String get worldClock_empty_clocks_hint;

  /// No description provided for @worldClock_empty_countdown.
  ///
  /// In zh, this message translates to:
  /// **'暂无倒计时'**
  String get worldClock_empty_countdown;

  /// No description provided for @worldClock_empty_countdown_hint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角闹钟图标添加倒计时'**
  String get worldClock_empty_countdown_hint;

  /// No description provided for @worldClock_tooltip_addCountdown.
  ///
  /// In zh, this message translates to:
  /// **'添加倒计时'**
  String get worldClock_tooltip_addCountdown;

  /// No description provided for @worldClock_tooltip_addClock.
  ///
  /// In zh, this message translates to:
  /// **'添加时钟'**
  String get worldClock_tooltip_addClock;

  /// No description provided for @worldClock_tooltip_settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get worldClock_tooltip_settings;

  /// No description provided for @worldClock_setTime.
  ///
  /// In zh, this message translates to:
  /// **'设置时间'**
  String get worldClock_setTime;

  /// No description provided for @worldClock_display_options.
  ///
  /// In zh, this message translates to:
  /// **'显示选项'**
  String get worldClock_display_options;

  /// No description provided for @worldClock_24hour_format.
  ///
  /// In zh, this message translates to:
  /// **'24小时制'**
  String get worldClock_24hour_format;

  /// No description provided for @worldClock_24hour_format_desc.
  ///
  /// In zh, this message translates to:
  /// **'使用24小时时间格式'**
  String get worldClock_24hour_format_desc;

  /// No description provided for @worldClock_show_seconds.
  ///
  /// In zh, this message translates to:
  /// **'显示秒数'**
  String get worldClock_show_seconds;

  /// No description provided for @worldClock_show_seconds_desc.
  ///
  /// In zh, this message translates to:
  /// **'在时钟中显示秒数'**
  String get worldClock_show_seconds_desc;

  /// No description provided for @worldClock_feature_options.
  ///
  /// In zh, this message translates to:
  /// **'功能选项'**
  String get worldClock_feature_options;

  /// No description provided for @worldClock_enable_notifications.
  ///
  /// In zh, this message translates to:
  /// **'启用通知'**
  String get worldClock_enable_notifications;

  /// No description provided for @worldClock_enable_notifications_desc.
  ///
  /// In zh, this message translates to:
  /// **'倒计时完成时显示通知'**
  String get worldClock_enable_notifications_desc;

  /// No description provided for @worldClock_enable_animations.
  ///
  /// In zh, this message translates to:
  /// **'启用动画'**
  String get worldClock_enable_animations;

  /// No description provided for @worldClock_enable_animations_desc.
  ///
  /// In zh, this message translates to:
  /// **'显示动画效果'**
  String get worldClock_enable_animations_desc;

  /// No description provided for @screenshot_settings_title.
  ///
  /// In zh, this message translates to:
  /// **'截图设置'**
  String get screenshot_settings_title;

  /// No description provided for @screenshot_settings_save.
  ///
  /// In zh, this message translates to:
  /// **'保存设置'**
  String get screenshot_settings_save;

  /// No description provided for @screenshot_settings_section_save.
  ///
  /// In zh, this message translates to:
  /// **'保存设置'**
  String get screenshot_settings_section_save;

  /// No description provided for @screenshot_settings_section_function.
  ///
  /// In zh, this message translates to:
  /// **'功能设置'**
  String get screenshot_settings_section_function;

  /// No description provided for @screenshot_settings_section_shortcuts.
  ///
  /// In zh, this message translates to:
  /// **'快捷键'**
  String get screenshot_settings_section_shortcuts;

  /// No description provided for @screenshot_settings_section_pin.
  ///
  /// In zh, this message translates to:
  /// **'钉图设置'**
  String get screenshot_settings_section_pin;

  /// No description provided for @screenshot_settings_auto_copy_desc.
  ///
  /// In zh, this message translates to:
  /// **'截图后自动复制到剪贴板'**
  String get screenshot_settings_auto_copy_desc;

  /// No description provided for @screenshot_clipboard_content_type.
  ///
  /// In zh, this message translates to:
  /// **'剪贴板内容类型'**
  String get screenshot_clipboard_content_type;

  /// No description provided for @screenshot_clipboard_type_image.
  ///
  /// In zh, this message translates to:
  /// **'图片本身'**
  String get screenshot_clipboard_type_image;

  /// No description provided for @screenshot_clipboard_type_filename.
  ///
  /// In zh, this message translates to:
  /// **'文件名'**
  String get screenshot_clipboard_type_filename;

  /// No description provided for @screenshot_clipboard_type_full_path.
  ///
  /// In zh, this message translates to:
  /// **'完整路径'**
  String get screenshot_clipboard_type_full_path;

  /// No description provided for @screenshot_clipboard_type_directory_path.
  ///
  /// In zh, this message translates to:
  /// **'目录路径'**
  String get screenshot_clipboard_type_directory_path;

  /// No description provided for @screenshot_clipboard_type_image_desc.
  ///
  /// In zh, this message translates to:
  /// **'复制图片本身到剪贴板'**
  String get screenshot_clipboard_type_image_desc;

  /// No description provided for @screenshot_clipboard_type_filename_desc.
  ///
  /// In zh, this message translates to:
  /// **'仅复制文件名（不含路径）'**
  String get screenshot_clipboard_type_filename_desc;

  /// No description provided for @screenshot_clipboard_type_full_path_desc.
  ///
  /// In zh, this message translates to:
  /// **'复制文件的完整路径'**
  String get screenshot_clipboard_type_full_path_desc;

  /// No description provided for @screenshot_clipboard_type_directory_path_desc.
  ///
  /// In zh, this message translates to:
  /// **'复制文件所在的目录路径'**
  String get screenshot_clipboard_type_directory_path_desc;

  /// No description provided for @screenshot_settings_clipboard_type_title.
  ///
  /// In zh, this message translates to:
  /// **'选择剪贴板内容类型'**
  String get screenshot_settings_clipboard_type_title;

  /// No description provided for @screenshot_settings_show_preview_desc.
  ///
  /// In zh, this message translates to:
  /// **'截图后显示预览和编辑窗口'**
  String get screenshot_settings_show_preview_desc;

  /// No description provided for @screenshot_settings_save_history_desc.
  ///
  /// In zh, this message translates to:
  /// **'保存截图历史以供查看'**
  String get screenshot_settings_save_history_desc;

  /// No description provided for @screenshot_settings_always_on_top_desc.
  ///
  /// In zh, this message translates to:
  /// **'钉图窗口始终在最前面'**
  String get screenshot_settings_always_on_top_desc;

  /// No description provided for @screenshot_settings_saved.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存'**
  String get screenshot_settings_saved;

  /// No description provided for @screenshot_settings_save_path_title.
  ///
  /// In zh, this message translates to:
  /// **'设置保存路径'**
  String get screenshot_settings_save_path_title;

  /// No description provided for @screenshot_settings_save_path_hint.
  ///
  /// In zh, this message translates to:
  /// **'[documents]/Screenshots'**
  String get screenshot_settings_save_path_hint;

  /// No description provided for @screenshot_settings_save_path_helper.
  ///
  /// In zh, this message translates to:
  /// **'可用占位符: [documents], [home], [temp]'**
  String get screenshot_settings_save_path_helper;

  /// No description provided for @screenshot_settings_filename_title.
  ///
  /// In zh, this message translates to:
  /// **'设置文件名格式'**
  String get screenshot_settings_filename_title;

  /// No description provided for @screenshot_settings_filename_helper.
  ///
  /// In zh, this message translates to:
  /// **'可用占位符: [timestamp], [date], [time], [datetime], [index]'**
  String get screenshot_settings_filename_helper;

  /// No description provided for @screenshot_settings_format_title.
  ///
  /// In zh, this message translates to:
  /// **'选择图片格式'**
  String get screenshot_settings_format_title;

  /// No description provided for @screenshot_settings_quality_title.
  ///
  /// In zh, this message translates to:
  /// **'设置图片质量'**
  String get screenshot_settings_quality_title;

  /// No description provided for @screenshot_settings_history_title.
  ///
  /// In zh, this message translates to:
  /// **'设置最大历史记录数'**
  String get screenshot_settings_history_title;

  /// No description provided for @screenshot_settings_opacity_title.
  ///
  /// In zh, this message translates to:
  /// **'设置默认透明度'**
  String get screenshot_settings_opacity_title;

  /// No description provided for @screenshot_settings_items.
  ///
  /// In zh, this message translates to:
  /// **'条'**
  String get screenshot_settings_items;

  /// No description provided for @screenshot_shortcut_region.
  ///
  /// In zh, this message translates to:
  /// **'区域截图'**
  String get screenshot_shortcut_region;

  /// No description provided for @screenshot_shortcut_fullscreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏截图'**
  String get screenshot_shortcut_fullscreen;

  /// No description provided for @screenshot_shortcut_window.
  ///
  /// In zh, this message translates to:
  /// **'窗口截图'**
  String get screenshot_shortcut_window;

  /// No description provided for @screenshot_shortcut_history.
  ///
  /// In zh, this message translates to:
  /// **'显示历史'**
  String get screenshot_shortcut_history;

  /// No description provided for @screenshot_shortcut_settings.
  ///
  /// In zh, this message translates to:
  /// **'打开设置'**
  String get screenshot_shortcut_settings;

  /// No description provided for @screenshot_settings_json_editor.
  ///
  /// In zh, this message translates to:
  /// **'JSON 配置编辑器'**
  String get screenshot_settings_json_editor;

  /// No description provided for @screenshot_settings_json_editor_desc.
  ///
  /// In zh, this message translates to:
  /// **'直接编辑 JSON 配置文件，支持高级自定义'**
  String get screenshot_settings_json_editor_desc;

  /// No description provided for @screenshot_settings_config_name.
  ///
  /// In zh, this message translates to:
  /// **'截图配置'**
  String get screenshot_settings_config_name;

  /// No description provided for @screenshot_settings_config_description.
  ///
  /// In zh, this message translates to:
  /// **'配置截图插件的所有选项'**
  String get screenshot_settings_config_description;

  /// No description provided for @screenshot_settings_json_saved.
  ///
  /// In zh, this message translates to:
  /// **'配置已保存'**
  String get screenshot_settings_json_saved;

  /// No description provided for @screenshot_tooltip_history.
  ///
  /// In zh, this message translates to:
  /// **'历史记录'**
  String get screenshot_tooltip_history;

  /// No description provided for @screenshot_tooltip_settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get screenshot_tooltip_settings;

  /// No description provided for @screenshot_tooltip_cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get screenshot_tooltip_cancel;

  /// No description provided for @screenshot_tooltip_confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get screenshot_tooltip_confirm;

  /// No description provided for @screenshot_confirm_capture.
  ///
  /// In zh, this message translates to:
  /// **'确认截图'**
  String get screenshot_confirm_capture;

  /// No description provided for @ui_retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get ui_retry;

  /// No description provided for @ui_close.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get ui_close;

  /// No description provided for @ui_follow_system.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get ui_follow_system;

  /// No description provided for @json_editor_title.
  ///
  /// In zh, this message translates to:
  /// **'编辑 {configName}'**
  String json_editor_title(String configName);

  /// No description provided for @json_editor_format.
  ///
  /// In zh, this message translates to:
  /// **'格式化'**
  String get json_editor_format;

  /// No description provided for @json_editor_minify.
  ///
  /// In zh, this message translates to:
  /// **'压缩'**
  String get json_editor_minify;

  /// No description provided for @json_editor_reset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get json_editor_reset;

  /// No description provided for @json_editor_example.
  ///
  /// In zh, this message translates to:
  /// **'示例'**
  String get json_editor_example;

  /// No description provided for @json_editor_validate.
  ///
  /// In zh, this message translates to:
  /// **'验证'**
  String get json_editor_validate;

  /// No description provided for @json_editor_unsaved_changes.
  ///
  /// In zh, this message translates to:
  /// **'有未保存的更改'**
  String get json_editor_unsaved_changes;

  /// No description provided for @json_editor_save_failed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get json_editor_save_failed;

  /// No description provided for @json_editor_reset_confirm_title.
  ///
  /// In zh, this message translates to:
  /// **'重置为默认值'**
  String get json_editor_reset_confirm_title;

  /// No description provided for @json_editor_reset_confirm_message.
  ///
  /// In zh, this message translates to:
  /// **'确定要重置为默认配置吗？当前所有更改将丢失。'**
  String get json_editor_reset_confirm_message;

  /// No description provided for @json_editor_reset_confirm.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get json_editor_reset_confirm;

  /// No description provided for @json_editor_example_title.
  ///
  /// In zh, this message translates to:
  /// **'加载示例配置'**
  String get json_editor_example_title;

  /// No description provided for @json_editor_example_message.
  ///
  /// In zh, this message translates to:
  /// **'加载示例将替换当前内容，示例包含详细的配置说明。'**
  String get json_editor_example_message;

  /// No description provided for @json_editor_example_warning.
  ///
  /// In zh, this message translates to:
  /// **'警告：当前内容将被覆盖'**
  String get json_editor_example_warning;

  /// No description provided for @json_editor_example_load.
  ///
  /// In zh, this message translates to:
  /// **'加载'**
  String get json_editor_example_load;

  /// No description provided for @json_editor_discard_title.
  ///
  /// In zh, this message translates to:
  /// **'放弃更改'**
  String get json_editor_discard_title;

  /// No description provided for @json_editor_discard_message.
  ///
  /// In zh, this message translates to:
  /// **'您有未保存的更改，确定要放弃吗？'**
  String get json_editor_discard_message;

  /// No description provided for @json_editor_discard_confirm.
  ///
  /// In zh, this message translates to:
  /// **'放弃'**
  String get json_editor_discard_confirm;

  /// No description provided for @json_editor_edit_json.
  ///
  /// In zh, this message translates to:
  /// **'编辑 JSON 配置'**
  String get json_editor_edit_json;

  /// No description provided for @json_editor_reset_to_default.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认配置'**
  String get json_editor_reset_to_default;

  /// No description provided for @json_editor_view_example.
  ///
  /// In zh, this message translates to:
  /// **'查看配置示例'**
  String get json_editor_view_example;

  /// No description provided for @json_editor_config_description.
  ///
  /// In zh, this message translates to:
  /// **'配置文件说明'**
  String get json_editor_config_description;

  /// No description provided for @settings_config_saved.
  ///
  /// In zh, this message translates to:
  /// **'设置已保存'**
  String get settings_config_saved;

  /// No description provided for @close_dialog_title.
  ///
  /// In zh, this message translates to:
  /// **'关闭确认'**
  String get close_dialog_title;

  /// No description provided for @close_dialog_message.
  ///
  /// In zh, this message translates to:
  /// **'您希望如何操作？'**
  String get close_dialog_message;

  /// No description provided for @close_dialog_directly.
  ///
  /// In zh, this message translates to:
  /// **'直接关闭'**
  String get close_dialog_directly;

  /// No description provided for @close_dialog_minimize_to_tray.
  ///
  /// In zh, this message translates to:
  /// **'最小化到托盘'**
  String get close_dialog_minimize_to_tray;

  /// No description provided for @close_dialog_cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get close_dialog_cancel;

  /// No description provided for @close_dialog_remember.
  ///
  /// In zh, this message translates to:
  /// **'记住选择，不再询问'**
  String get close_dialog_remember;

  /// No description provided for @close_behavior_ask.
  ///
  /// In zh, this message translates to:
  /// **'每次询问'**
  String get close_behavior_ask;

  /// No description provided for @close_behavior_close.
  ///
  /// In zh, this message translates to:
  /// **'直接关闭'**
  String get close_behavior_close;

  /// No description provided for @close_behavior_minimize_to_tray.
  ///
  /// In zh, this message translates to:
  /// **'最小化到托盘'**
  String get close_behavior_minimize_to_tray;

  /// No description provided for @settings_close_behavior.
  ///
  /// In zh, this message translates to:
  /// **'关闭行为'**
  String get settings_close_behavior;

  /// No description provided for @settings_close_behavior_desc.
  ///
  /// In zh, this message translates to:
  /// **'关闭窗口时的默认行为'**
  String get settings_close_behavior_desc;

  /// No description provided for @settings_remember_close_choice.
  ///
  /// In zh, this message translates to:
  /// **'记住关闭选择'**
  String get settings_remember_close_choice;

  /// No description provided for @settings_remember_close_choice_desc.
  ///
  /// In zh, this message translates to:
  /// **'记住用户选择的关闭方式'**
  String get settings_remember_close_choice_desc;

  /// No description provided for @plugin_view_mode.
  ///
  /// In zh, this message translates to:
  /// **'视图模式'**
  String get plugin_view_mode;

  /// No description provided for @plugin_view_large_icon.
  ///
  /// In zh, this message translates to:
  /// **'大图标'**
  String get plugin_view_large_icon;

  /// No description provided for @plugin_view_medium_icon.
  ///
  /// In zh, this message translates to:
  /// **'中图标'**
  String get plugin_view_medium_icon;

  /// No description provided for @plugin_view_small_icon.
  ///
  /// In zh, this message translates to:
  /// **'小图标'**
  String get plugin_view_small_icon;

  /// No description provided for @plugin_view_list.
  ///
  /// In zh, this message translates to:
  /// **'列表'**
  String get plugin_view_list;

  /// No description provided for @calculator_settings_title.
  ///
  /// In zh, this message translates to:
  /// **'计算器设置'**
  String get calculator_settings_title;

  /// No description provided for @calculator_settings_basic.
  ///
  /// In zh, this message translates to:
  /// **'基础设置'**
  String get calculator_settings_basic;

  /// No description provided for @calculator_settings_display.
  ///
  /// In zh, this message translates to:
  /// **'显示设置'**
  String get calculator_settings_display;

  /// No description provided for @calculator_settings_interaction.
  ///
  /// In zh, this message translates to:
  /// **'交互设置'**
  String get calculator_settings_interaction;

  /// No description provided for @calculator_setting_precision.
  ///
  /// In zh, this message translates to:
  /// **'计算精度'**
  String get calculator_setting_precision;

  /// No description provided for @calculator_decimal_places.
  ///
  /// In zh, this message translates to:
  /// **'位小数'**
  String get calculator_decimal_places;

  /// No description provided for @calculator_setting_angleMode.
  ///
  /// In zh, this message translates to:
  /// **'角度模式'**
  String get calculator_setting_angleMode;

  /// No description provided for @calculator_angle_mode_degrees.
  ///
  /// In zh, this message translates to:
  /// **'角度制'**
  String get calculator_angle_mode_degrees;

  /// No description provided for @calculator_angle_mode_radians.
  ///
  /// In zh, this message translates to:
  /// **'弧度制'**
  String get calculator_angle_mode_radians;

  /// No description provided for @calculator_angle_mode_degrees_short.
  ///
  /// In zh, this message translates to:
  /// **'角度'**
  String get calculator_angle_mode_degrees_short;

  /// No description provided for @calculator_angle_mode_radians_short.
  ///
  /// In zh, this message translates to:
  /// **'弧度'**
  String get calculator_angle_mode_radians_short;

  /// No description provided for @calculator_setting_historySize.
  ///
  /// In zh, this message translates to:
  /// **'历史记录大小'**
  String get calculator_setting_historySize;

  /// No description provided for @calculator_history_size_description.
  ///
  /// In zh, this message translates to:
  /// **'保存最近 {count} 条计算记录'**
  String calculator_history_size_description(Object count);

  /// No description provided for @calculator_setting_showGroupingSeparator.
  ///
  /// In zh, this message translates to:
  /// **'显示千分位分隔符'**
  String get calculator_setting_showGroupingSeparator;

  /// No description provided for @calculator_grouping_separator_description.
  ///
  /// In zh, this message translates to:
  /// **'在大数字中显示逗号分隔，如 1,234.56'**
  String get calculator_grouping_separator_description;

  /// No description provided for @calculator_setting_enableVibration.
  ///
  /// In zh, this message translates to:
  /// **'启用振动反馈'**
  String get calculator_setting_enableVibration;

  /// No description provided for @calculator_vibration_description.
  ///
  /// In zh, this message translates to:
  /// **'按键时触觉反馈'**
  String get calculator_vibration_description;

  /// No description provided for @calculator_setting_buttonSoundVolume.
  ///
  /// In zh, this message translates to:
  /// **'按键音效音量'**
  String get calculator_setting_buttonSoundVolume;

  /// No description provided for @calculator_config_name.
  ///
  /// In zh, this message translates to:
  /// **'计算器配置'**
  String get calculator_config_name;

  /// No description provided for @calculator_config_description.
  ///
  /// In zh, this message translates to:
  /// **'自定义计算器的计算精度、角度模式和历史记录'**
  String get calculator_config_description;

  /// No description provided for @calculator_settings_saved.
  ///
  /// In zh, this message translates to:
  /// **'配置已保存'**
  String get calculator_settings_saved;

  /// No description provided for @world_clock_settings_title.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟设置'**
  String get world_clock_settings_title;

  /// No description provided for @world_clock_settings_basic.
  ///
  /// In zh, this message translates to:
  /// **'基础设置'**
  String get world_clock_settings_basic;

  /// No description provided for @world_clock_settings_display.
  ///
  /// In zh, this message translates to:
  /// **'显示设置'**
  String get world_clock_settings_display;

  /// No description provided for @world_clock_settings_notification.
  ///
  /// In zh, this message translates to:
  /// **'通知设置'**
  String get world_clock_settings_notification;

  /// No description provided for @world_clock_setting_defaultTimeZone.
  ///
  /// In zh, this message translates to:
  /// **'默认时区'**
  String get world_clock_setting_defaultTimeZone;

  /// No description provided for @world_clock_setting_timeFormat.
  ///
  /// In zh, this message translates to:
  /// **'时间格式'**
  String get world_clock_setting_timeFormat;

  /// No description provided for @world_clock_time_format_12h.
  ///
  /// In zh, this message translates to:
  /// **'12小时制'**
  String get world_clock_time_format_12h;

  /// No description provided for @world_clock_time_format_24h.
  ///
  /// In zh, this message translates to:
  /// **'24小时制'**
  String get world_clock_time_format_24h;

  /// No description provided for @world_clock_setting_showSeconds.
  ///
  /// In zh, this message translates to:
  /// **'显示秒数'**
  String get world_clock_setting_showSeconds;

  /// No description provided for @world_clock_setting_enableNotifications.
  ///
  /// In zh, this message translates to:
  /// **'启用倒计时通知'**
  String get world_clock_setting_enableNotifications;

  /// No description provided for @world_clock_enable_notifications_desc.
  ///
  /// In zh, this message translates to:
  /// **'倒计时完成时显示通知'**
  String get world_clock_enable_notifications_desc;

  /// No description provided for @world_clock_setting_updateInterval.
  ///
  /// In zh, this message translates to:
  /// **'更新间隔'**
  String get world_clock_setting_updateInterval;

  /// No description provided for @world_clock_update_interval_description.
  ///
  /// In zh, this message translates to:
  /// **'每 {ms} 毫秒更新一次'**
  String world_clock_update_interval_description(Object ms);

  /// No description provided for @world_clock_config_name.
  ///
  /// In zh, this message translates to:
  /// **'世界时钟配置'**
  String get world_clock_config_name;

  /// No description provided for @world_clock_config_description.
  ///
  /// In zh, this message translates to:
  /// **'自定义世界时钟的时区、显示格式和通知'**
  String get world_clock_config_description;

  /// No description provided for @world_clock_settings_saved.
  ///
  /// In zh, this message translates to:
  /// **'配置已保存'**
  String get world_clock_settings_saved;

  /// No description provided for @world_clock_add_clock.
  ///
  /// In zh, this message translates to:
  /// **'添加时钟'**
  String get world_clock_add_clock;

  /// No description provided for @world_clock_no_clocks.
  ///
  /// In zh, this message translates to:
  /// **'暂无时钟'**
  String get world_clock_no_clocks;

  /// No description provided for @world_clock_add_clock_hint.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角 + 添加时钟'**
  String get world_clock_add_clock_hint;

  /// No description provided for @world_clock_city_name.
  ///
  /// In zh, this message translates to:
  /// **'城市名称'**
  String get world_clock_city_name;

  /// No description provided for @world_clock_city_name_hint.
  ///
  /// In zh, this message translates to:
  /// **'输入城市名称'**
  String get world_clock_city_name_hint;

  /// No description provided for @world_clock_time_zone.
  ///
  /// In zh, this message translates to:
  /// **'时区'**
  String get world_clock_time_zone;

  /// No description provided for @world_clock_set_time.
  ///
  /// In zh, this message translates to:
  /// **'设置时间'**
  String get world_clock_set_time;

  /// No description provided for @world_clock_hours.
  ///
  /// In zh, this message translates to:
  /// **'小时'**
  String get world_clock_hours;

  /// No description provided for @world_clock_minutes.
  ///
  /// In zh, this message translates to:
  /// **'分钟'**
  String get world_clock_minutes;

  /// No description provided for @world_clock_seconds.
  ///
  /// In zh, this message translates to:
  /// **'秒'**
  String get world_clock_seconds;

  /// No description provided for @world_clock_loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get world_clock_loading;

  /// No description provided for @world_clock_no_image.
  ///
  /// In zh, this message translates to:
  /// **'无法加载图片'**
  String get world_clock_no_image;

  /// No description provided for @world_clock_countdown_completed.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get world_clock_countdown_completed;

  /// No description provided for @world_clock_countdown_almost_complete.
  ///
  /// In zh, this message translates to:
  /// **'即将完成！'**
  String get world_clock_countdown_almost_complete;

  /// No description provided for @world_clock_countdown_complete.
  ///
  /// In zh, this message translates to:
  /// **'倒计时 \"{title}\" 已完成！'**
  String world_clock_countdown_complete(Object title);

  /// No description provided for @world_clock_remaining_minutes.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {minutes} 分钟'**
  String world_clock_remaining_minutes(Object minutes);

  /// No description provided for @world_clock_remaining_hours_minutes.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {hours} 小时 {minutes} 分钟'**
  String world_clock_remaining_hours_minutes(Object hours, Object minutes);

  /// No description provided for @world_clock_remaining_days_hours.
  ///
  /// In zh, this message translates to:
  /// **'剩余 {days} 天 {hours} 小时'**
  String world_clock_remaining_days_hours(Object days, Object hours);

  /// No description provided for @world_clock_confirm_delete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get world_clock_confirm_delete;

  /// No description provided for @world_clock_confirm_delete_countdown_message.
  ///
  /// In zh, this message translates to:
  /// **'确定要删除倒计时 \"{title}\" 吗？'**
  String world_clock_confirm_delete_countdown_message(Object title);

  /// No description provided for @world_clock_plugin_initialized.
  ///
  /// In zh, this message translates to:
  /// **'{name} 插件已成功初始化'**
  String world_clock_plugin_initialized(Object name);

  /// No description provided for @world_clock_plugin_init_failed.
  ///
  /// In zh, this message translates to:
  /// **'{name} 插件初始化失败: {error}'**
  String world_clock_plugin_init_failed(Object error, Object name);

  /// No description provided for @screenshot_tool_pen_label.
  ///
  /// In zh, this message translates to:
  /// **'画笔'**
  String get screenshot_tool_pen_label;

  /// No description provided for @screenshot_tool_rectangle_label.
  ///
  /// In zh, this message translates to:
  /// **'矩形'**
  String get screenshot_tool_rectangle_label;

  /// No description provided for @screenshot_tool_arrow_label.
  ///
  /// In zh, this message translates to:
  /// **'箭头'**
  String get screenshot_tool_arrow_label;

  /// No description provided for @screenshot_tool_text_label.
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get screenshot_tool_text_label;

  /// No description provided for @screenshot_tool_mosaic_label.
  ///
  /// In zh, this message translates to:
  /// **'马赛克'**
  String get screenshot_tool_mosaic_label;

  /// No description provided for @screenshot_undo_tooltip.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get screenshot_undo_tooltip;

  /// No description provided for @screenshot_redo_tooltip.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get screenshot_redo_tooltip;

  /// No description provided for @screenshot_save_tooltip.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get screenshot_save_tooltip;

  /// No description provided for @screenshot_copy_to_clipboard.
  ///
  /// In zh, this message translates to:
  /// **'复制到剪贴板'**
  String get screenshot_copy_to_clipboard;

  /// No description provided for @screenshot_share.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get screenshot_share;

  /// No description provided for @screenshot_loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get screenshot_loading;

  /// No description provided for @screenshot_unable_load_image.
  ///
  /// In zh, this message translates to:
  /// **'无法加载图片'**
  String get screenshot_unable_load_image;

  /// No description provided for @screenshot_history_title.
  ///
  /// In zh, this message translates to:
  /// **'截图历史'**
  String get screenshot_history_title;

  /// No description provided for @screenshot_clear_history.
  ///
  /// In zh, this message translates to:
  /// **'清空历史'**
  String get screenshot_clear_history;

  /// No description provided for @screenshot_confirm_clear_history.
  ///
  /// In zh, this message translates to:
  /// **'确认清空'**
  String get screenshot_confirm_clear_history;

  /// No description provided for @screenshot_confirm_clear_history_message.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空所有截图历史吗？此操作无法撤销。'**
  String get screenshot_confirm_clear_history_message;

  /// No description provided for @screenshot_clear.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get screenshot_clear;

  /// No description provided for @screenshot_no_records.
  ///
  /// In zh, this message translates to:
  /// **'暂无截图记录'**
  String get screenshot_no_records;

  /// No description provided for @screenshot_history_hint.
  ///
  /// In zh, this message translates to:
  /// **'开始截图后，历史记录将显示在这里'**
  String get screenshot_history_hint;

  /// No description provided for @screenshot_recent.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get screenshot_recent;

  /// No description provided for @screenshot_minutes_ago.
  ///
  /// In zh, this message translates to:
  /// **'{minutes} 分钟前'**
  String screenshot_minutes_ago(Object minutes);

  /// No description provided for @screenshot_hours_ago.
  ///
  /// In zh, this message translates to:
  /// **'{hours} 小时前'**
  String screenshot_hours_ago(Object hours);

  /// No description provided for @screenshot_days_ago.
  ///
  /// In zh, this message translates to:
  /// **'{days} 天前'**
  String screenshot_days_ago(Object days);

  /// No description provided for @screenshot_date_format.
  ///
  /// In zh, this message translates to:
  /// **'{month}月{day}日'**
  String screenshot_date_format(Object day, Object month);

  /// No description provided for @screenshot_datetime_format.
  ///
  /// In zh, this message translates to:
  /// **'{year}年{month}月{day}日 {hour}:{minute}:{second}'**
  String screenshot_datetime_format(
    Object day,
    Object hour,
    Object minute,
    Object month,
    Object second,
    Object year,
  );

  /// No description provided for @screenshot_type_fullscreen.
  ///
  /// In zh, this message translates to:
  /// **'全屏'**
  String get screenshot_type_fullscreen;

  /// No description provided for @screenshot_detail_info.
  ///
  /// In zh, this message translates to:
  /// **'详细信息'**
  String get screenshot_detail_info;

  /// No description provided for @screenshot_info_file_path.
  ///
  /// In zh, this message translates to:
  /// **'文件路径'**
  String get screenshot_info_file_path;

  /// No description provided for @screenshot_info_file_size.
  ///
  /// In zh, this message translates to:
  /// **'文件大小'**
  String get screenshot_info_file_size;

  /// No description provided for @screenshot_info_type.
  ///
  /// In zh, this message translates to:
  /// **'截图类型'**
  String get screenshot_info_type;

  /// No description provided for @screenshot_info_created.
  ///
  /// In zh, this message translates to:
  /// **'创建时间'**
  String get screenshot_info_created;

  /// No description provided for @screenshot_info_dimensions.
  ///
  /// In zh, this message translates to:
  /// **'图片尺寸'**
  String get screenshot_info_dimensions;

  /// No description provided for @screenshot_shortcut_edit_pending.
  ///
  /// In zh, this message translates to:
  /// **'快捷键编辑功能待实现：{action}'**
  String screenshot_shortcut_edit_pending(Object action);

  /// No description provided for @screenshot_editor_title.
  ///
  /// In zh, this message translates to:
  /// **'编辑截图'**
  String get screenshot_editor_title;

  /// No description provided for @image_editor_pen.
  ///
  /// In zh, this message translates to:
  /// **'画笔'**
  String get image_editor_pen;

  /// No description provided for @image_editor_rectangle.
  ///
  /// In zh, this message translates to:
  /// **'矩形'**
  String get image_editor_rectangle;

  /// No description provided for @image_editor_arrow.
  ///
  /// In zh, this message translates to:
  /// **'箭头'**
  String get image_editor_arrow;

  /// No description provided for @image_editor_text.
  ///
  /// In zh, this message translates to:
  /// **'文字'**
  String get image_editor_text;

  /// No description provided for @image_editor_mosaic.
  ///
  /// In zh, this message translates to:
  /// **'马赛克'**
  String get image_editor_mosaic;
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

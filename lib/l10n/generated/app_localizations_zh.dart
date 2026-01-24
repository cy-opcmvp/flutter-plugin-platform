// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '多功能插件平台';

  @override
  String get appName => '多功能插件平台';

  @override
  String get autoStart => '开机自启动';

  @override
  String get autoStartPlugin => '插件自启动';

  @override
  String get autoStartDescription => '开机自启动';

  @override
  String autoStartedPlugins(Object count) {
    return '已自动启动 $count 个插件';
  }

  @override
  String get autoStartAdded => '已添加到自启动列表';

  @override
  String get autoStartRemoved => '已从自启动列表移除';

  @override
  String get autoStartPlugins_empty => '暂无自启动插件';

  @override
  String get tag_title => '标签';

  @override
  String get tag_add => '添加标签';

  @override
  String get tag_edit => '编辑标签';

  @override
  String get tag_delete => '删除标签';

  @override
  String get tag_name => '标签名称';

  @override
  String get tag_description => '标签描述';

  @override
  String get tag_color => '标签颜色';

  @override
  String get tag_icon => '标签图标';

  @override
  String get tag_create_success => '标签创建成功';

  @override
  String get tag_update_success => '标签更新成功';

  @override
  String get tag_delete_success => '标签删除成功';

  @override
  String tag_delete_confirm(Object name) {
    return '确定要删除标签 \"$name\" 吗？';
  }

  @override
  String get tag_in_use => '该标签正在被使用中，无法删除';

  @override
  String get tag_system_protected => '系统标签无法删除或修改';

  @override
  String get tag_assign_success => '标签分配成功';

  @override
  String get tag_plugin_assignment_title => '插件标签关联';

  @override
  String get tag_search_plugins => '搜索插件...';

  @override
  String get tag_select_tags_for_plugin => '为插件选择标签';

  @override
  String get tag_selected_tags => '已选标签';

  @override
  String get tag_all_available_tags => '所有可用标签';

  @override
  String get tag_no_plugins_found => '未找到匹配的插件';

  @override
  String get tag_assign_removed => '标签已移除';

  @override
  String get tag_filter_all => '全部';

  @override
  String tag_filter_active(Object count) {
    return '已选择 $count 个标签';
  }

  @override
  String get tag_no_tags => '暂无标签';

  @override
  String get tag_total => '个标签';

  @override
  String get tag_and_more => '还有';

  @override
  String get tag_items => '个';

  @override
  String get tag_manage => '管理标签';

  @override
  String get tag_create_hint => '创建自定义标签';

  @override
  String get tag_select_hint => '选择标签进行筛选';

  @override
  String get tag_empty => '没有标签';

  @override
  String get tag_popular => '热门标签';

  @override
  String get tag_productivity => '生产力工具';

  @override
  String get tag_system => '系统工具';

  @override
  String get tag_entertainment => '娱乐休闲';

  @override
  String get tag_game => '游戏';

  @override
  String get tag_development => '开发工具';

  @override
  String get tag_favorite => '常用';

  @override
  String get common_confirm => '确认';

  @override
  String get common_cancel => '取消';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_close => '关闭';

  @override
  String get common_retry => '重试';

  @override
  String get common_loading => '加载中...';

  @override
  String get common_search => '搜索';

  @override
  String get common_ok => '确定';

  @override
  String get common_yes => '是';

  @override
  String get common_no => '否';

  @override
  String get common_all => '全部';

  @override
  String get common_refresh => '刷新';

  @override
  String get common_back => '返回';

  @override
  String get common_error => '错误';

  @override
  String get common_success => '成功';

  @override
  String get common_warning => '警告';

  @override
  String get common_info => '信息';

  @override
  String get error_unknown => '发生未知错误';

  @override
  String get error_network => '网络连接失败';

  @override
  String error_loadFailed(String message) {
    return '加载失败: $message';
  }

  @override
  String error_operationFailed(String message) {
    return '操作失败: $message';
  }

  @override
  String error_initFailed(String message) {
    return '初始化失败: $message';
  }

  @override
  String error_platformInit(String message) {
    return '平台初始化失败: $message';
  }

  @override
  String get hint_searchPlugins => '搜索插件...';

  @override
  String get hint_searchExternalPlugins => '搜索外部插件...';

  @override
  String get hint_inputRequired => '此字段为必填项';

  @override
  String get hint_noResults => '没有找到匹配的结果';

  @override
  String get hint_tryAdjustSearch => '尝试调整搜索或筛选条件';

  @override
  String get button_launch => '启动';

  @override
  String get button_open => '打开';

  @override
  String get button_install => '安装';

  @override
  String get button_uninstall => '卸载';

  @override
  String get button_update => '更新';

  @override
  String get button_rollback => '回滚';

  @override
  String get button_remove => '移除';

  @override
  String get button_updateAll => '全部更新';

  @override
  String get button_removeAll => '全部移除';

  @override
  String get button_selectAll => '全选';

  @override
  String get button_deselectAll => '取消全选';

  @override
  String get button_multiSelect => '多选';

  @override
  String get button_enablePetMode => '启用宠物模式';

  @override
  String get button_exitPetMode => '退出宠物模式';

  @override
  String get autoStartEnabled => '开机自启：已开启';

  @override
  String get autoStartDisabled => '开机自启：已关闭';

  @override
  String get dialog_confirmTitle => '确认操作';

  @override
  String get dialog_uninstallPlugin => '确定要卸载此插件吗？此操作无法撤销。';

  @override
  String get dialog_removePlugin => '确定要移除此插件吗？此操作无法撤销。';

  @override
  String get dialog_updatePlugin => '确定要更新此插件吗？更新前会创建备份以便回滚。';

  @override
  String get dialog_rollbackPlugin => '确定要回滚此插件吗？这将撤销上次更新。';

  @override
  String dialog_batchUpdate(int count) {
    return '确定要更新 $count 个选中的插件吗？';
  }

  @override
  String dialog_batchRemove(int count) {
    return '确定要移除 $count 个选中的插件吗？此操作无法撤销。';
  }

  @override
  String get plugin_title => '插件管理';

  @override
  String get plugin_externalTitle => '外部插件';

  @override
  String get plugin_statusActive => '运行中';

  @override
  String get plugin_statusInactive => '未激活';

  @override
  String get plugin_statusPaused => '已暂停';

  @override
  String get plugin_statusError => '错误';

  @override
  String get plugin_typeTool => '工具';

  @override
  String get plugin_typeGame => '游戏';

  @override
  String get plugin_typeAll => '全部类型';

  @override
  String get plugin_stateAll => '全部状态';

  @override
  String get plugin_noPlugins => '暂无插件';

  @override
  String get plugin_noExternalPlugins => '暂无外部插件';

  @override
  String get plugin_installFirst => '安装您的第一个插件开始使用';

  @override
  String get plugin_installExternalFirst => '安装您的第一个外部插件开始使用';

  @override
  String get plugin_noMatch => '没有匹配的插件';

  @override
  String get plugin_filterByType => '按类型筛选: ';

  @override
  String get plugin_filterByState => '按状态筛选';

  @override
  String plugin_launchSuccess(String name) {
    return '插件 $name 已启动';
  }

  @override
  String plugin_launchFailed(String message) {
    return '启动插件失败: $message';
  }

  @override
  String plugin_switchSuccess(String name) {
    return '已切换到插件 $name';
  }

  @override
  String plugin_switchFailed(String message) {
    return '切换插件失败: $message';
  }

  @override
  String plugin_closeSuccess(String name) {
    return '插件 $name 已关闭';
  }

  @override
  String plugin_pauseSuccess(String name) {
    return '插件 $name 已移至后台';
  }

  @override
  String plugin_disableSuccess(String name) {
    return '插件 $name 已禁用';
  }

  @override
  String plugin_enableSuccess(String name) {
    return '插件 $name 已启用';
  }

  @override
  String get button_disable => '禁用';

  @override
  String get button_enable => '启用';

  @override
  String get plugin_installSuccess => '示例插件安装成功';

  @override
  String get plugin_uninstallSuccess => '插件卸载成功';

  @override
  String get plugin_updateSuccess => '插件更新成功，可回滚';

  @override
  String plugin_updateFailed(String message) {
    return '更新失败并已回滚: $message';
  }

  @override
  String get plugin_rollbackSuccess => '插件回滚成功';

  @override
  String get plugin_removeSuccess => '插件移除成功';

  @override
  String plugin_operationFailed(String message) {
    return '插件操作失败: $message';
  }

  @override
  String plugin_batchUpdateResult(int success, int failed) {
    return '$success 个更新成功，$failed 个失败';
  }

  @override
  String plugin_batchRemoveResult(int success, int failed) {
    return '$success 个移除成功，$failed 个失败';
  }

  @override
  String plugin_allUpdateSuccess(int count) {
    return '全部 $count 个插件更新成功';
  }

  @override
  String plugin_allRemoveSuccess(int count) {
    return '全部 $count 个插件移除成功';
  }

  @override
  String plugin_allUpdateFailed(int count) {
    return '全部 $count 个插件更新失败';
  }

  @override
  String plugin_allRemoveFailed(int count) {
    return '全部 $count 个插件移除失败';
  }

  @override
  String plugin_selected(int count) {
    return '已选择 $count 个';
  }

  @override
  String get plugin_updating => '正在更新插件...';

  @override
  String plugin_updatingBatch(int count) {
    return '正在更新 $count 个插件...';
  }

  @override
  String get plugin_removing => '正在移除插件...';

  @override
  String plugin_removingBatch(int count) {
    return '正在移除 $count 个插件...';
  }

  @override
  String get plugin_rollingBack => '正在回滚插件...';

  @override
  String plugin_errorDetails(String error) {
    return '插件错误: $error';
  }

  @override
  String get pet_title => '桌面宠物';

  @override
  String get pet_notSupported => '桌面宠物不可用';

  @override
  String pet_notSupportedDesc(String platform) {
    return '桌面宠物功能在 $platform 平台上不可用。此功能需要桌面环境和窗口管理能力。';
  }

  @override
  String get pet_webLimitation => 'Web 平台限制';

  @override
  String get pet_webLimitationDesc =>
      'Web 浏览器不支持:\n• 桌面窗口管理\n• 置顶窗口\n• 系统托盘集成\n• 原生桌面交互';

  @override
  String get pet_enableMode => '启用宠物模式';

  @override
  String get pet_exitMode => '退出宠物模式';

  @override
  String get pet_exitSuccess => '已退出桌面宠物模式';

  @override
  String get pet_returnToApp => '返回主应用';

  @override
  String get pet_settings => '宠物设置';

  @override
  String get pet_quickActions => '快捷操作';

  @override
  String get pet_openFullApp => '打开完整应用';

  @override
  String get pet_modeTitle => '桌面宠物模式';

  @override
  String get pet_modeDesc => '启用桌面宠物模式，让可爱的伙伴陪伴您！';

  @override
  String get pet_features => '功能特点:';

  @override
  String get pet_featureAlwaysOnTop => '• 窗口置顶';

  @override
  String get pet_featureAnimations => '• 可爱的动画和交互';

  @override
  String get pet_featureQuickAccess => '• 快速访问插件';

  @override
  String get pet_featureCustomize => '• 可自定义外观';

  @override
  String get pet_tip => '右键点击宠物查看快捷操作，双击返回完整应用。';

  @override
  String get pet_platformInfo => '平台信息';

  @override
  String get pet_platformInfoDesc => '桌面宠物需要以下能力:';

  @override
  String get pet_capabilityDesktop => '桌面环境';

  @override
  String get pet_capabilityWindow => '窗口管理';

  @override
  String get pet_capabilityTray => '系统托盘';

  @override
  String get pet_capabilityFileSystem => '文件系统访问';

  @override
  String get pet_platformNote =>
      '您当前的平台可能不支持所有这些功能。桌面宠物在 Windows、macOS 和 Linux 桌面环境下效果最佳。';

  @override
  String pet_launchFailed(String message) {
    return '启动桌面宠物失败: $message';
  }

  @override
  String pet_toggleFailed(String message) {
    return '切换桌面宠物模式失败: $message';
  }

  @override
  String pet_navFailed(String message) {
    return '导航到桌面宠物屏幕失败: $message';
  }

  @override
  String get mode_local => '本地模式';

  @override
  String get mode_online => '在线模式';

  @override
  String mode_switchSuccess(String mode) {
    return '已切换到 $mode 模式';
  }

  @override
  String mode_switchFailed(String message) {
    return '切换模式失败: $message';
  }

  @override
  String get platform_initializing => '正在初始化平台...';

  @override
  String get platform_error => '平台错误';

  @override
  String get platform_availableFeatures => '可用功能';

  @override
  String get platform_noPluginsAvailable => '暂无可用插件';

  @override
  String get platform_installFromManagement => '从管理界面安装插件';

  @override
  String get platform_activePlugins => '活动插件';

  @override
  String get platform_platformInfo => '平台信息';

  @override
  String get nav_plugins => '插件';

  @override
  String get nav_active => '活动';

  @override
  String get nav_info => '信息';

  @override
  String get settings_title => '设置';

  @override
  String get settings_language => '语言设置';

  @override
  String get settings_theme => '主题设置';

  @override
  String get settings_app => '应用设置';

  @override
  String get settings_general => '常规设置';

  @override
  String get settings_appName => '应用名称';

  @override
  String get settings_appVersion => '应用版本';

  @override
  String get appInfo_title => '应用信息';

  @override
  String get appInfo_viewDetails => '查看应用信息、配置功能和管理标签';

  @override
  String get appInfo_section_app => '应用';

  @override
  String get appInfo_section_features => '功能状态';

  @override
  String get appInfo_section_developerTools => '开发者工具';

  @override
  String get appInfo_serviceTest_desc => '测试和调试平台服务';

  @override
  String get settings_changeTheme => '更改主题';

  @override
  String settings_themeChanged(String theme) {
    return '主题已更改为 $theme';
  }

  @override
  String get settings_languageChinese => '中文';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get settings_currentLanguage => '当前语言';

  @override
  String get settings_changeLanguage => '更改语言';

  @override
  String settings_languageChanged(String language) {
    return '语言已更改为 $language';
  }

  @override
  String get settings_global => '全局配置';

  @override
  String get settings_features => '功能设置';

  @override
  String get settings_services => '服务设置';

  @override
  String get tray_title => '系统托盘';

  @override
  String get tray_enabled => '启用系统托盘';

  @override
  String get tray_enabled_desc => '在系统托盘显示应用图标';

  @override
  String get tray_tooltip => '托盘提示';

  @override
  String get tray_menu => '托盘菜单';

  @override
  String get tray_menu_edit => '编辑菜单';

  @override
  String get tray_menu_add => '添加菜单项';

  @override
  String get tray_menu_item_type => '菜单项类型';

  @override
  String get tray_menu_item_text => '菜单项文本';

  @override
  String get tray_menu_item_action => '动作类型';

  @override
  String get tray_menu_item_enabled => '启用';

  @override
  String get tray_menu_item_visible => '可见';

  @override
  String get tray_menu_item_checked => '已勾选';

  @override
  String get tray_menu_separator => '分隔符';

  @override
  String get tray_menu_normal => '普通菜单项';

  @override
  String get tray_menu_submenu => '子菜单';

  @override
  String get tray_menu_action_show_hide => '显示/隐藏';

  @override
  String get tray_menu_action_quit => '退出';

  @override
  String get tray_menu_action_settings => '设置';

  @override
  String get tray_menu_action_custom => '自定义';

  @override
  String get tray_minimize_to_tray => '最小化到托盘';

  @override
  String get tray_minimize_to_tray_desc => '关闭窗口时隐藏到托盘而非退出';

  @override
  String get tray_start_minimized => '启动时最小化到托盘';

  @override
  String get tray_menu_saved => '菜单已保存';

  @override
  String get tray_menu_reset_confirm => '确定要重置为默认菜单吗？';

  @override
  String get settings_advanced => '高级设置';

  @override
  String get settings_plugins => '插件配置';

  @override
  String get settings_addPlugin => '新增插件';

  @override
  String get settings_addPlugin_desc => '添加新的插件到平台';

  @override
  String get settings_selectPluginType => '选择插件类型';

  @override
  String get settings_autoStart => '开机自启';

  @override
  String get settings_minimizeToTray => '最小化到托盘';

  @override
  String get settings_showDesktopPet => '显示桌面宠物';

  @override
  String get settings_enableNotifications => '启用通知';

  @override
  String get settings_notificationMode => '通知模式';

  @override
  String get settings_notificationMode_app => 'App 内部';

  @override
  String get settings_notificationMode_system => '系统通知';

  @override
  String get settings_notificationMode_desc => '选择通知显示方式';

  @override
  String get settings_debugMode => '调试模式';

  @override
  String get settings_logLevel => '日志级别';

  @override
  String get settings_savePath => '保存路径';

  @override
  String get settings_filenameFormat => '文件名格式';

  @override
  String get settings_imageFormat => '图片格式';

  @override
  String get settings_imageQuality => '图片质量';

  @override
  String get settings_autoCopyToClipboard => '自动复制到剪贴板';

  @override
  String get settings_showPreview => '显示预览窗口';

  @override
  String get settings_saveHistory => '保存历史记录';

  @override
  String get settings_maxHistoryCount => '最大历史记录数';

  @override
  String get settings_shortcuts => '快捷键设置';

  @override
  String get settings_regionCapture => '区域截图';

  @override
  String get settings_fullScreenCapture => '全屏截图';

  @override
  String get settings_windowCapture => '窗口截图';

  @override
  String get settings_configSaved => '配置已保存';

  @override
  String get settings_configSaveFailed => '配置保存失败';

  @override
  String get settings_resetToDefaults => '恢复默认设置';

  @override
  String get settings_resetConfirm => '确定要恢复默认设置吗？此操作不可撤销。';

  @override
  String get plugin_detailsTitle => '插件详情';

  @override
  String get plugin_detailsStatus => '状态';

  @override
  String get plugin_detailsState => '状态';

  @override
  String get plugin_detailsType => '类型';

  @override
  String get plugin_detailsPluginId => '插件ID';

  @override
  String get plugin_detailsDescription => '描述';

  @override
  String get plugin_detailsInstallation => '安装信息';

  @override
  String get plugin_detailsInstalled => '安装时间';

  @override
  String get plugin_detailsLastUsed => '最后使用';

  @override
  String get plugin_detailsEntryPoint => '入口点';

  @override
  String get plugin_detailsPermissions => '权限';

  @override
  String get plugin_detailsAdditionalInfo => '附加信息';

  @override
  String plugin_detailsVersion(String version) {
    return '版本 $version';
  }

  @override
  String get plugin_stateActive => '运行中';

  @override
  String get plugin_stateInactive => '未激活';

  @override
  String get plugin_stateLoading => '加载中';

  @override
  String get plugin_statePaused => '已暂停';

  @override
  String get plugin_stateError => '错误';

  @override
  String get plugin_permissionFileAccess => '文件访问';

  @override
  String get plugin_permissionFileSystemRead => '文件系统读取';

  @override
  String get plugin_permissionFileSystemWrite => '文件系统写入';

  @override
  String get plugin_permissionFileSystemExecute => '文件系统执行';

  @override
  String get plugin_permissionNetworkAccess => '网络访问';

  @override
  String get plugin_permissionNetworkServer => '网络服务器';

  @override
  String get plugin_permissionNetworkClient => '网络客户端';

  @override
  String get plugin_permissionNotifications => '通知';

  @override
  String get plugin_permissionSystemNotifications => '系统通知';

  @override
  String get plugin_permissionCamera => '相机';

  @override
  String get plugin_permissionSystemCamera => '系统相机';

  @override
  String get plugin_permissionMicrophone => '麦克风';

  @override
  String get plugin_permissionSystemMicrophone => '系统麦克风';

  @override
  String get plugin_permissionLocation => '位置';

  @override
  String get plugin_permissionStorage => '存储';

  @override
  String get plugin_permissionPlatformStorage => '平台存储';

  @override
  String get plugin_permissionSystemClipboard => '系统剪贴板';

  @override
  String get plugin_permissionPlatformServices => '平台服务';

  @override
  String get plugin_permissionPlatformUI => '平台UI';

  @override
  String get plugin_permissionPluginCommunication => '插件通信';

  @override
  String get plugin_permissionPluginDataSharing => '插件数据共享';

  @override
  String plugin_lastUsed(String time) {
    return '最后使用: $time';
  }

  @override
  String plugin_permissionCount(int count) {
    return '$count 个权限';
  }

  @override
  String get plugin_permissionCountSingle => '1 个权限';

  @override
  String time_daysAgo(int days) {
    return '$days天前';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String get time_justNow => '刚刚';

  @override
  String get worldClock_title => '世界时钟';

  @override
  String get worldClock_addClock => '添加时钟';

  @override
  String get worldClock_addCountdown => '添加倒计时';

  @override
  String get worldClock_settings => '设置';

  @override
  String get worldClock_noClocks => '暂无时钟，点击右上角添加';

  @override
  String get worldClock_noCountdowns => '暂无倒计时，点击右上角添加';

  @override
  String get worldClock_defaultClock => '默认';

  @override
  String get worldClock_deleteClock => '删除时钟';

  @override
  String get worldClock_deleteCountdown => '删除倒计时';

  @override
  String get worldClock_confirmDelete => '确认删除';

  @override
  String worldClock_confirmDeleteClock(String cityName) {
    return '确定要删除 $cityName 的时钟吗？';
  }

  @override
  String worldClock_confirmDeleteCountdown(String title) {
    return '确定要删除倒计时 \"$title\" 吗？';
  }

  @override
  String get worldClock_addClockTitle => '添加时钟';

  @override
  String get worldClock_cityName => '城市名称';

  @override
  String get worldClock_cityNameHint => '输入城市名称';

  @override
  String get worldClock_timeZone => '时区';

  @override
  String get worldClock_addCountdownTitle => '添加倒计时';

  @override
  String get worldClock_countdownTitle => '倒计时标题';

  @override
  String get worldClock_countdownTitleHint => '输入提醒内容';

  @override
  String get worldClock_hours => '小时';

  @override
  String get worldClock_minutes => '分钟';

  @override
  String get worldClock_seconds => '秒';

  @override
  String worldClock_countdownComplete(String title) {
    return '倒计时提醒: $title 时间到了！';
  }

  @override
  String get worldClock_completed => '已完成';

  @override
  String get worldClock_almostComplete => '即将完成！';

  @override
  String worldClock_remaining(String time) {
    return '剩余 $time';
  }

  @override
  String worldClock_remainingMinutes(int minutes) {
    return '剩余 $minutes 分钟';
  }

  @override
  String worldClock_remainingHours(int hours, int minutes) {
    return '剩余 $hours 小时 $minutes 分钟';
  }

  @override
  String worldClock_remainingDays(int days, int hours) {
    return '剩余 $days 天 $hours 小时';
  }

  @override
  String get worldClock_settingsTitle => '世界时钟设置';

  @override
  String get worldClock_settingsDesc => '设置选项将在后续版本中添加';

  @override
  String get worldClock_currentFeatures => '当前功能：';

  @override
  String get worldClock_featureMultipleTimezones => '• 显示多个时区时间';

  @override
  String get worldClock_featureCountdown => '• 倒计时提醒';

  @override
  String get worldClock_featureBeijingDefault => '• 默认北京时间';

  @override
  String get pet_openMainApp => '打开主应用';

  @override
  String get pet_notAvailable => '不可用';

  @override
  String get pet_settingsTitle => '桌面宠物设置';

  @override
  String get pet_opacity => '透明度:';

  @override
  String get pet_enableAnimations => '启用动画';

  @override
  String get pet_animationsSubtitle => '呼吸和眨眼效果';

  @override
  String get pet_enableInteractions => '启用交互';

  @override
  String get pet_interactionsSubtitle => '点击和拖拽交互';

  @override
  String get pet_autoHide => '自动隐藏';

  @override
  String get pet_autoHideSubtitle => '不使用时隐藏';

  @override
  String get pet_reset => '重置';

  @override
  String get pet_done => '完成';

  @override
  String get pet_moving => '移动中...';

  @override
  String get desktopPet_settings_title => '桌面宠物设置';

  @override
  String get desktopPet_section_appearance => '外观';

  @override
  String get desktopPet_section_behavior => '行为';

  @override
  String get desktopPet_opacity => '透明度';

  @override
  String get desktopPet_colorTheme => '颜色主题';

  @override
  String get desktopPet_enableAnimations => '启用动画';

  @override
  String get desktopPet_animationsSubtitle => '呼吸和眨眼效果';

  @override
  String get desktopPet_enableInteractions => '启用交互';

  @override
  String get desktopPet_interactionsSubtitle => '点击和拖拽交互';

  @override
  String get desktopPet_autoHide => '自动隐藏';

  @override
  String get desktopPet_autoHideSubtitle => '不使用时隐藏';

  @override
  String get desktopPet_enabledSubtitle => '在桌面显示宠物角色';

  @override
  String get desktopPet_openSettings => '点击查看详细设置';

  @override
  String get desktopPet_settingsSaved => '桌面宠物设置已保存';

  @override
  String get desktopPet_reset => '重置为默认设置';

  @override
  String get desktopPet_resetConfirm => '确定要重置桌面宠物设置吗？';

  @override
  String get common_enabled => '已启用';

  @override
  String get common_disabled => '已禁用';

  @override
  String get settings_pluginManagement => '插件标签关联';

  @override
  String get settings_pluginManagement_desc => '配置插件与标签的关联关系';

  @override
  String get executable_clearOutput => '清空输出';

  @override
  String get executable_disableAutoScroll => '禁用自动滚动';

  @override
  String get executable_enableAutoScroll => '启用自动滚动';

  @override
  String get executable_scrollToBottom => '滚动到底部';

  @override
  String get executable_enterCommand => '输入命令...';

  @override
  String get executable_send => '发送';

  @override
  String get pluginManagement_installSample => '安装示例插件';

  @override
  String get externalPlugin_details => '插件详情';

  @override
  String get externalPlugin_remove => '移除';

  @override
  String get desktopPet_themeDefault => '默认蓝色';

  @override
  String get desktopPet_themeBlue => '天空蓝';

  @override
  String get desktopPet_themeGreen => '自然绿';

  @override
  String get desktopPet_themeOrange => '活力橙';

  @override
  String get desktopPet_themePurple => '神秘紫';

  @override
  String get tooltip_switchPlugin => '切换插件';

  @override
  String get tooltip_pausePlugin => '移至后台';

  @override
  String get tooltip_stopPlugin => '停止插件';

  @override
  String get tooltip_switchMode => '切换插件';

  @override
  String get tooltip_pauseMode => '移至后台';

  @override
  String get info_platformType => '平台类型';

  @override
  String get info_version => '版本';

  @override
  String get info_currentMode => '当前模式';

  @override
  String get info_unknown => '未知';

  @override
  String get info_capabilities => '功能特性';

  @override
  String get info_statistics => '统计信息';

  @override
  String get info_availablePlugins => '可用插件';

  @override
  String get info_activePlugins => '活动插件';

  @override
  String get info_availableFeatures => '可用功能';

  @override
  String get mode_local_desc => '完全离线运行，所有功能在本地设备上执行，无需网络连接';

  @override
  String get mode_online_desc => '联网模式，可访问云端功能和在线服务，需要稳定的网络连接';

  @override
  String get capability_desktopPetSupport => '桌面宠物';

  @override
  String get capability_desktopPetSupport_desc => '在桌面上显示可交互的宠物角色';

  @override
  String get capability_alwaysOnTop => '窗口置顶';

  @override
  String get capability_alwaysOnTop_desc => '窗口始终保持最前，不被其他窗口遮挡';

  @override
  String get capability_systemTray => '系统托盘';

  @override
  String get capability_systemTray_desc => '最小化到系统托盘，在后台运行';

  @override
  String get capability_supportsEnvironmentVariables => '环境变量';

  @override
  String get capability_supportsEnvironmentVariables_desc => '可访问和修改系统环境变量配置';

  @override
  String get capability_supportsFileSystem => '文件系统';

  @override
  String get capability_supportsFileSystem_desc => '可读写本地文件系统，保存和加载数据';

  @override
  String get capability_touchInput => '触摸输入';

  @override
  String get capability_touchInput_desc => '支持触摸屏交互和多点触控操作（仅移动设备和触摸屏）';

  @override
  String get capability_desktop => '桌面平台';

  @override
  String get capability_desktop_desc => '运行在桌面操作系统上（Windows、macOS、Linux）';

  @override
  String get feature_autoStart => '开机启动';

  @override
  String get feature_minimizeToTray => '最小化到托盘';

  @override
  String get feature_enableNotifications => '通知功能';

  @override
  String get feature_plugin_management => '插件管理';

  @override
  String get feature_plugin_management_desc => '安装、更新和管理插件';

  @override
  String get feature_local_storage => '本地存储';

  @override
  String get feature_local_storage_desc => '在设备上持久化存储数据';

  @override
  String get feature_offline_plugins => '离线插件';

  @override
  String get feature_offline_plugins_desc => '无网络时也可使用插件';

  @override
  String get feature_local_preferences => '本地设置';

  @override
  String get feature_local_preferences_desc => '自定义本地体验';

  @override
  String get feature_cloud_sync => '云同步';

  @override
  String get feature_cloud_sync_desc => '跨设备同步数据';

  @override
  String get feature_multiplayer => '多人协作';

  @override
  String get feature_multiplayer_desc => '与他人实时协作';

  @override
  String get feature_online_plugins => '在线插件';

  @override
  String get feature_online_plugins_desc => '访问云端插件库';

  @override
  String get feature_cloud_storage => '云存储';

  @override
  String get feature_cloud_storage_desc => '云端数据无限存储';

  @override
  String get feature_remote_config => '远程配置';

  @override
  String get feature_remote_config_desc => '远程管理功能配置';

  @override
  String get feature_status_implemented => '可用';

  @override
  String get feature_status_partial => '测试版';

  @override
  String get feature_status_planned => '即将推出';

  @override
  String get feature_status_deprecated => '已弃用';

  @override
  String get feature_learn_more => '了解更多';

  @override
  String feature_planned_for_version(String version) {
    return '计划于版本 $version 推出';
  }

  @override
  String get plugin_calculator_name => '计算器';

  @override
  String get plugin_calculator_description => '用于基本算术运算的简单计算器工具';

  @override
  String get plugin_calculator_initialized => '计算器插件已初始化';

  @override
  String get plugin_calculator_disposed => '计算器插件已销毁';

  @override
  String get plugin_calculator_error => '错误';

  @override
  String get plugin_worldclock_name => '世界时钟';

  @override
  String get plugin_worldclock_description => '显示多个时区的时间，支持倒计时提醒功能，默认显示北京时间';

  @override
  String get serviceTest_title => '平台服务测试';

  @override
  String get serviceTest_notifications => '通知';

  @override
  String get serviceTest_audio => '音频';

  @override
  String get serviceTest_tasks => '任务';

  @override
  String get serviceTest_activityLog => '活动日志';

  @override
  String get serviceTest_clear => '清空';

  @override
  String get serviceTest_copyAll => '复制全部';

  @override
  String get serviceTest_copied => '已复制';

  @override
  String get serviceTest_logCopied => '日志已复制到剪贴板';

  @override
  String get serviceTest_allLogsCopied => '所有日志已复制到剪贴板';

  @override
  String get serviceTest_permissionGranted => '通知权限已授予';

  @override
  String get serviceTest_permissionNotGranted => '通知权限未授予';

  @override
  String get serviceTest_requestPermission => '请求权限';

  @override
  String get serviceTest_windowsPlatform => 'Windows 平台';

  @override
  String get serviceTest_windowsNotice =>
      '计划通知将在 Windows 上立即显示。请使用任务标签页中的倒计时定时器来实现定时通知。';

  @override
  String get serviceTest_notificationTitle => '通知标题';

  @override
  String get serviceTest_notificationBody => '通知内容';

  @override
  String get serviceTest_defaultNotificationTitle => '测试通知';

  @override
  String get serviceTest_defaultNotificationBody => '这是来自平台服务的测试通知！';

  @override
  String get serviceTest_showNow => '立即显示';

  @override
  String get serviceTest_schedule => '计划 (5秒)';

  @override
  String get serviceTest_cancelAll => '全部取消';

  @override
  String get serviceTest_testAudioFeatures => '测试各种音频播放功能';

  @override
  String get serviceTest_audioNotAvailable => '此平台上音频服务不可用。某些功能可能被禁用。';

  @override
  String get serviceTest_notificationSound => '通知音效';

  @override
  String get serviceTest_successSound => '成功音效';

  @override
  String get serviceTest_errorSound => '错误音效';

  @override
  String get serviceTest_warningSound => '警告音效';

  @override
  String get serviceTest_clickSound => '点击音效';

  @override
  String get serviceTest_globalVolume => '全局音量';

  @override
  String get serviceTest_stopAllAudio => '停止所有音频';

  @override
  String get serviceTest_countdownTimer => '倒计时定时器';

  @override
  String get serviceTest_seconds => '秒';

  @override
  String get serviceTest_start => '开始';

  @override
  String get serviceTest_cancel => '取消';

  @override
  String get serviceTest_periodicTask => '周期性任务';

  @override
  String get serviceTest_interval => '间隔';

  @override
  String get serviceTest_activeTasks => '活动任务';

  @override
  String get serviceTest_noActiveTasks => '没有活动任务';

  @override
  String get serviceTest_at => '在';

  @override
  String get serviceTest_every => '每';

  @override
  String get serviceTest_countdownComplete => '倒计时完成！';

  @override
  String get serviceTest_countdownFinished => '您的倒计时已结束。';

  @override
  String get serviceTest_error => '错误';

  @override
  String get serviceTest_errorPlayingSound => '播放音效时出错';

  @override
  String get serviceTest_audioServiceNotAvailable => '音频服务在此平台上不可用';

  @override
  String get serviceTest_enterValidSeconds => '请输入有效的秒数';

  @override
  String get serviceTest_enterValidInterval => '请输入有效的间隔';

  @override
  String get serviceTest_notificationShown => '通知已显示';

  @override
  String get serviceTest_errorShowingNotification => '显示通知时出错';

  @override
  String get serviceTest_notificationScheduled => '通知已计划在 5 秒后显示';

  @override
  String get serviceTest_errorSchedulingNotification => '计划通知时出错';

  @override
  String get serviceTest_allNotificationsCancelled => '所有通知已取消';

  @override
  String get serviceTest_errorCancellingNotifications => '取消通知时出错';

  @override
  String serviceTest_countdownStarted(Object seconds) {
    return '倒计时已开始：$seconds 秒';
  }

  @override
  String get serviceTest_errorStartingCountdown => '启动倒计时出错';

  @override
  String get serviceTest_countdownCancelled => '倒计时已取消';

  @override
  String get serviceTest_errorCancellingCountdown => '取消倒计时出错';

  @override
  String serviceTest_periodicTaskStarted(Object interval) {
    return '周期性任务已启动：每 $interval 秒';
  }

  @override
  String get serviceTest_errorStartingPeriodicTask => '启动周期性任务出错';

  @override
  String get serviceTest_periodicTaskCancelled => '周期性任务已取消';

  @override
  String get serviceTest_errorCancellingPeriodicTask => '取消周期性任务出错';

  @override
  String get serviceTest_periodicTaskExecuted => '周期性任务已执行';

  @override
  String get serviceTest_taskCompleted => '任务已完成';

  @override
  String get serviceTest_taskFailed => '任务失败';

  @override
  String get serviceTest_taskCancelled => '任务已取消';

  @override
  String get serviceTest_couldNotPlaySound => '无法播放音效';

  @override
  String serviceTest_volumeSet(Object percent) {
    return '音量设置为 $percent%';
  }

  @override
  String get serviceTest_stoppedAllAudio => '已停止所有音频播放';

  @override
  String serviceTest_notificationPermission(Object status) {
    return '通知权限 $status';
  }

  @override
  String get serviceTest_granted => '已授予';

  @override
  String get serviceTest_denied => '已拒绝';

  @override
  String get serviceTest_audioServiceUnavailable => '音频服务不可用';

  @override
  String get serviceTest_serviceTestInitialized => '服务测试屏幕已初始化';

  @override
  String get serviceTest_errorMessage => '错误信息';

  @override
  String get serviceTest_copy => '复制';

  @override
  String get plugin_screenshot_name => '智能截图';

  @override
  String get plugin_screenshot_description =>
      '类似 Snipaste 的专业截图工具，支持区域截图、全屏截图、窗口截图、图片标注和编辑';

  @override
  String get screenshot_region => '区域截图';

  @override
  String get screenshot_fullScreen => '全屏截图';

  @override
  String get screenshot_window => '窗口截图';

  @override
  String get screenshot_history => '截图历史';

  @override
  String get screenshot_settings => '截图设置';

  @override
  String get screenshot_savePath => '保存路径';

  @override
  String get screenshot_filenameFormat => '文件名格式';

  @override
  String get screenshot_autoCopy => '自动复制到剪贴板';

  @override
  String get screenshot_showPreview => '显示预览窗口';

  @override
  String get screenshot_saveHistory => '保存历史记录';

  @override
  String get screenshot_maxHistoryCount => '最大历史记录数';

  @override
  String get screenshot_imageFormat => '图片格式';

  @override
  String get screenshot_imageQuality => '图片质量';

  @override
  String get screenshot_shortcuts => '快捷键';

  @override
  String get screenshot_pinSettings => '钉图设置';

  @override
  String get screenshot_alwaysOnTop => '始终置顶';

  @override
  String get screenshot_defaultOpacity => '默认透明度';

  @override
  String get screenshot_enableDrag => '启用拖拽';

  @override
  String get screenshot_enableResize => '启用调整大小';

  @override
  String get screenshot_quickActions => '快速操作';

  @override
  String get screenshot_recentScreenshots => '最近截图';

  @override
  String get screenshot_statistics => '统计信息';

  @override
  String get screenshot_noScreenshots => '暂无截图记录';

  @override
  String get screenshot_clickToStart => '点击上方按钮开始截图';

  @override
  String get screenshot_totalScreenshots => '总截图数';

  @override
  String get screenshot_todayScreenshots => '今日截图';

  @override
  String get screenshot_storageUsed => '占用空间';

  @override
  String get screenshot_preview => '截图预览';

  @override
  String get screenshot_confirmDelete => '确认删除';

  @override
  String get screenshot_confirmDeleteMessage => '确定要删除这张截图吗？';

  @override
  String get screenshot_deleted => '截图已删除';

  @override
  String get screenshot_deleteFailed => '删除截图失败';

  @override
  String get screenshot_saved => '截图已保存';

  @override
  String get screenshot_copied => '已复制到剪贴板';

  @override
  String get screenshot_error => '截图失败';

  @override
  String get screenshot_unsupportedPlatform => '平台功能受限';

  @override
  String get screenshot_unsupportedPlatformDesc =>
      '此平台暂不完全支持截图功能。支持的平台：Windows、macOS、Linux';

  @override
  String get screenshot_featureNotImplemented => '此功能待实现';

  @override
  String get screenshot_tool_pen => '画笔';

  @override
  String get screenshot_tool_rectangle => '矩形';

  @override
  String get screenshot_tool_arrow => '箭头';

  @override
  String get screenshot_tool_text => '文字';

  @override
  String get screenshot_tool_mosaic => '马赛克';

  @override
  String get screenshot_undo => '撤销';

  @override
  String get screenshot_redo => '重做';

  @override
  String get screenshot_save => '保存';

  @override
  String get screenshot_cancel => '取消';

  @override
  String get screenshot_type_fullScreen => '全屏';

  @override
  String get screenshot_type_region => '区域';

  @override
  String get screenshot_type_window => '窗口';

  @override
  String get screenshot_justNow => '刚刚';

  @override
  String screenshot_minutesAgo(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String screenshot_hoursAgo(int hours) {
    return '$hours 小时前';
  }

  @override
  String screenshot_daysAgo(int days) {
    return '$days 天前';
  }

  @override
  String get settings_behavior => '行为';

  @override
  String get screenshot_config_title => '截图插件配置';

  @override
  String get plugin_version => '版本';

  @override
  String get plugin_type_label => '类型';

  @override
  String get plugin_id_label => 'ID';

  @override
  String get plugin_background_plugins => '后台插件';

  @override
  String plugin_pauseFailed(String message) {
    return '暂停插件失败: $message';
  }

  @override
  String get plugin_update_label => '更新';

  @override
  String get plugin_rollback_label => '回滚';

  @override
  String get plugin_remove_label => '移除';

  @override
  String get screenshot_select_window => '选择窗口';

  @override
  String get screenshot_close_preview => '关闭预览';

  @override
  String get screenshot_share_not_implemented => '分享功能待实现';

  @override
  String get screenshot_saved_to_temp => '已保存到临时文件';

  @override
  String get screenshot_copy_failed => '复制到剪贴板失败';

  @override
  String get screenshot_image_load_failed => '图片加载失败';

  @override
  String get screenshot_file_not_exists => '文件不存在';

  @override
  String get screenshot_window_not_available => '窗口选择不可用';

  @override
  String screenshot_region_failed(String error) {
    return '区域截图失败: $error';
  }

  @override
  String screenshot_fullscreen_failed(String error) {
    return '全屏截图失败: $error';
  }

  @override
  String get screenshot_native_window_failed => '无法打开原生截图窗口';

  @override
  String screenshot_window_failed(String error) {
    return '窗口截图失败: $error';
  }

  @override
  String get worldClock_section_clocks => '世界时钟';

  @override
  String get worldClock_section_countdown => '倒计时提醒';

  @override
  String get worldClock_empty_clocks => '暂无时钟';

  @override
  String get worldClock_empty_clocks_hint => '点击右上角 + 添加时钟';

  @override
  String get worldClock_empty_countdown => '暂无倒计时';

  @override
  String get worldClock_empty_countdown_hint => '点击右上角闹钟图标添加倒计时';

  @override
  String get worldClock_tooltip_addCountdown => '添加倒计时';

  @override
  String get worldClock_tooltip_addClock => '添加时钟';

  @override
  String get worldClock_tooltip_settings => '设置';

  @override
  String get worldClock_setTime => '设置时间';

  @override
  String get worldClock_display_options => '显示选项';

  @override
  String get worldClock_24hour_format => '24小时制';

  @override
  String get worldClock_24hour_format_desc => '使用24小时时间格式';

  @override
  String get worldClock_show_seconds => '显示秒数';

  @override
  String get worldClock_show_seconds_desc => '在时钟中显示秒数';

  @override
  String get worldClock_feature_options => '功能选项';

  @override
  String get worldClock_enable_notifications => '启用通知';

  @override
  String get worldClock_enable_notifications_desc => '倒计时完成时显示通知';

  @override
  String get worldClock_enable_animations => '启用动画';

  @override
  String get worldClock_enable_animations_desc => '显示动画效果';

  @override
  String get screenshot_settings_title => '截图设置';

  @override
  String get screenshot_settings_save => '保存设置';

  @override
  String get screenshot_settings_section_save => '保存设置';

  @override
  String get screenshot_settings_section_function => '功能设置';

  @override
  String get screenshot_settings_section_shortcuts => '快捷键';

  @override
  String get screenshot_settings_section_pin => '钉图设置';

  @override
  String get screenshot_settings_auto_copy_desc => '截图后自动复制到剪贴板';

  @override
  String get screenshot_clipboard_content_type => '剪贴板内容类型';

  @override
  String get screenshot_clipboard_type_image => '图片本身';

  @override
  String get screenshot_clipboard_type_filename => '文件名';

  @override
  String get screenshot_clipboard_type_full_path => '完整路径';

  @override
  String get screenshot_clipboard_type_directory_path => '目录路径';

  @override
  String get screenshot_clipboard_type_image_desc => '复制图片本身到剪贴板';

  @override
  String get screenshot_clipboard_type_filename_desc => '仅复制文件名（不含路径）';

  @override
  String get screenshot_clipboard_type_full_path_desc => '复制文件的完整路径';

  @override
  String get screenshot_clipboard_type_directory_path_desc => '复制文件所在的目录路径';

  @override
  String get screenshot_settings_clipboard_type_title => '选择剪贴板内容类型';

  @override
  String get screenshot_settings_show_preview_desc => '截图后显示预览和编辑窗口';

  @override
  String get screenshot_settings_save_history_desc => '保存截图历史以供查看';

  @override
  String get screenshot_settings_always_on_top_desc => '钉图窗口始终在最前面';

  @override
  String get screenshot_settings_saved => '设置已保存';

  @override
  String get screenshot_settings_save_path_title => '设置保存路径';

  @override
  String get screenshot_settings_save_path_hint => '[documents]/Screenshots';

  @override
  String get screenshot_settings_save_path_helper =>
      '可用占位符: [documents], [home], [temp]';

  @override
  String get screenshot_settings_filename_title => '设置文件名格式';

  @override
  String get screenshot_settings_filename_helper =>
      '可用占位符: [timestamp], [date], [time], [datetime], [index]';

  @override
  String get screenshot_settings_format_title => '选择图片格式';

  @override
  String get screenshot_settings_quality_title => '设置图片质量';

  @override
  String get screenshot_settings_history_title => '设置最大历史记录数';

  @override
  String get screenshot_settings_opacity_title => '设置默认透明度';

  @override
  String get screenshot_settings_items => '条';

  @override
  String get screenshot_shortcut_region => '区域截图';

  @override
  String get screenshot_shortcut_fullscreen => '全屏截图';

  @override
  String get screenshot_shortcut_window => '窗口截图';

  @override
  String get screenshot_shortcut_history => '显示历史';

  @override
  String get screenshot_shortcut_settings => '打开设置';

  @override
  String get screenshot_settings_json_editor => 'JSON 配置编辑器';

  @override
  String get screenshot_settings_json_editor_desc => '直接编辑 JSON 配置文件，支持高级自定义';

  @override
  String get screenshot_settings_config_name => '截图配置';

  @override
  String get screenshot_settings_config_description => '配置截图插件的所有选项';

  @override
  String get screenshot_settings_json_saved => '配置已保存';

  @override
  String get screenshot_tooltip_history => '历史记录';

  @override
  String get screenshot_tooltip_settings => '设置';

  @override
  String get screenshot_tooltip_cancel => '取消';

  @override
  String get screenshot_tooltip_confirm => '确认';

  @override
  String get screenshot_confirm_capture => '确认截图';

  @override
  String get ui_retry => '重试';

  @override
  String get ui_close => '关闭';

  @override
  String get ui_follow_system => '跟随系统';

  @override
  String json_editor_title(String configName) {
    return '编辑 $configName';
  }

  @override
  String get json_editor_format => '格式化';

  @override
  String get json_editor_minify => '压缩';

  @override
  String get json_editor_reset => '重置';

  @override
  String get json_editor_example => '示例';

  @override
  String get json_editor_validate => '验证';

  @override
  String get json_editor_unsaved_changes => '有未保存的更改';

  @override
  String get json_editor_save_failed => '保存失败';

  @override
  String get json_editor_reset_confirm_title => '重置为默认值';

  @override
  String get json_editor_reset_confirm_message => '确定要重置为默认配置吗？当前所有更改将丢失。';

  @override
  String get json_editor_reset_confirm => '重置';

  @override
  String get json_editor_example_title => '加载示例配置';

  @override
  String get json_editor_example_message => '加载示例将替换当前内容，示例包含详细的配置说明。';

  @override
  String get json_editor_example_warning => '警告：当前内容将被覆盖';

  @override
  String get json_editor_example_load => '加载';

  @override
  String get json_editor_discard_title => '放弃更改';

  @override
  String get json_editor_discard_message => '您有未保存的更改，确定要放弃吗？';

  @override
  String get json_editor_discard_confirm => '放弃';

  @override
  String get json_editor_edit_json => '编辑 JSON 配置';

  @override
  String get json_editor_reset_to_default => '恢复默认配置';

  @override
  String get json_editor_view_example => '查看配置示例';

  @override
  String get json_editor_config_description => '配置文件说明';

  @override
  String get settings_config_saved => '设置已保存';

  @override
  String get close_dialog_title => '关闭确认';

  @override
  String get close_dialog_message => '您希望如何操作？';

  @override
  String get close_dialog_directly => '直接关闭';

  @override
  String get close_dialog_minimize_to_tray => '最小化到托盘';

  @override
  String get close_dialog_cancel => '取消';

  @override
  String get close_dialog_remember => '记住选择，不再询问';

  @override
  String get close_behavior_ask => '每次询问';

  @override
  String get close_behavior_close => '直接关闭';

  @override
  String get close_behavior_minimize_to_tray => '最小化到托盘';

  @override
  String get settings_close_behavior => '关闭行为';

  @override
  String get settings_close_behavior_desc => '关闭窗口时的默认行为';

  @override
  String get settings_remember_close_choice => '记住关闭选择';

  @override
  String get settings_remember_close_choice_desc => '记住用户选择的关闭方式';

  @override
  String get plugin_view_mode => '视图模式';

  @override
  String get plugin_view_large_icon => '大图标';

  @override
  String get plugin_view_medium_icon => '中图标';

  @override
  String get plugin_view_small_icon => '小图标';

  @override
  String get plugin_view_list => '列表';

  @override
  String get calculator_settings_title => '计算器设置';

  @override
  String get calculator_settings_basic => '基础设置';

  @override
  String get calculator_settings_display => '显示设置';

  @override
  String get calculator_settings_interaction => '交互设置';

  @override
  String get calculator_setting_precision => '计算精度';

  @override
  String get calculator_decimal_places => '位小数';

  @override
  String get calculator_setting_angleMode => '角度模式';

  @override
  String get calculator_angle_mode_degrees => '角度制';

  @override
  String get calculator_angle_mode_radians => '弧度制';

  @override
  String get calculator_angle_mode_degrees_short => '角度';

  @override
  String get calculator_angle_mode_radians_short => '弧度';

  @override
  String get calculator_setting_historySize => '历史记录大小';

  @override
  String calculator_history_size_description(Object count) {
    return '保存最近 $count 条计算记录';
  }

  @override
  String get calculator_setting_showGroupingSeparator => '显示千分位分隔符';

  @override
  String get calculator_grouping_separator_description =>
      '在大数字中显示逗号分隔，如 1,234.56';

  @override
  String get calculator_setting_enableVibration => '启用振动反馈';

  @override
  String get calculator_vibration_description => '按键时触觉反馈';

  @override
  String get calculator_setting_buttonSoundVolume => '按键音效音量';

  @override
  String get calculator_config_name => '计算器配置';

  @override
  String get calculator_config_description => '自定义计算器的计算精度、角度模式和历史记录';

  @override
  String get calculator_settings_saved => '配置已保存';

  @override
  String get world_clock_settings_title => '世界时钟设置';

  @override
  String get world_clock_settings_basic => '基础设置';

  @override
  String get world_clock_settings_display => '显示设置';

  @override
  String get world_clock_settings_notification => '通知设置';

  @override
  String get world_clock_setting_defaultTimeZone => '默认时区';

  @override
  String get world_clock_setting_timeFormat => '时间格式';

  @override
  String get world_clock_time_format_12h => '12小时制';

  @override
  String get world_clock_time_format_24h => '24小时制';

  @override
  String get world_clock_setting_showSeconds => '显示秒数';

  @override
  String get world_clock_setting_enableNotifications => '启用倒计时通知';

  @override
  String get world_clock_enable_notifications_desc => '倒计时完成时显示通知';

  @override
  String get world_clock_setting_updateInterval => '更新间隔';

  @override
  String world_clock_update_interval_description(Object ms) {
    return '每 $ms 毫秒更新一次';
  }

  @override
  String get world_clock_config_name => '世界时钟配置';

  @override
  String get world_clock_config_description => '自定义世界时钟的时区、显示格式和通知';

  @override
  String get world_clock_settings_saved => '配置已保存';

  @override
  String get world_clock_add_clock => '添加时钟';

  @override
  String get world_clock_no_clocks => '暂无时钟';

  @override
  String get world_clock_add_clock_hint => '点击右上角 + 添加时钟';

  @override
  String get world_clock_city_name => '城市名称';

  @override
  String get world_clock_city_name_hint => '输入城市名称';

  @override
  String get world_clock_time_zone => '时区';

  @override
  String get world_clock_set_time => '设置时间';

  @override
  String get world_clock_hours => '小时';

  @override
  String get world_clock_minutes => '分钟';

  @override
  String get world_clock_seconds => '秒';

  @override
  String get world_clock_loading => '加载中...';

  @override
  String get world_clock_no_image => '无法加载图片';

  @override
  String get world_clock_countdown_completed => '已完成';

  @override
  String get world_clock_countdown_almost_complete => '即将完成！';

  @override
  String world_clock_countdown_complete(Object title) {
    return '倒计时 \"$title\" 已完成！';
  }

  @override
  String world_clock_remaining_minutes(Object minutes) {
    return '剩余 $minutes 分钟';
  }

  @override
  String world_clock_remaining_hours_minutes(Object hours, Object minutes) {
    return '剩余 $hours 小时 $minutes 分钟';
  }

  @override
  String world_clock_remaining_days_hours(Object days, Object hours) {
    return '剩余 $days 天 $hours 小时';
  }

  @override
  String get world_clock_confirm_delete => '确认删除';

  @override
  String world_clock_confirm_delete_countdown_message(Object title) {
    return '确定要删除倒计时 \"$title\" 吗？';
  }

  @override
  String world_clock_plugin_initialized(Object name) {
    return '$name 插件已成功初始化';
  }

  @override
  String world_clock_plugin_init_failed(Object error, Object name) {
    return '$name 插件初始化失败: $error';
  }

  @override
  String get screenshot_tool_pen_label => '画笔';

  @override
  String get screenshot_tool_rectangle_label => '矩形';

  @override
  String get screenshot_tool_arrow_label => '箭头';

  @override
  String get screenshot_tool_text_label => '文字';

  @override
  String get screenshot_tool_mosaic_label => '马赛克';

  @override
  String get screenshot_undo_tooltip => '撤销';

  @override
  String get screenshot_redo_tooltip => '重做';

  @override
  String get screenshot_save_tooltip => '保存';

  @override
  String get screenshot_copy_to_clipboard => '复制到剪贴板';

  @override
  String get screenshot_share => '分享';

  @override
  String get screenshot_loading => '加载中...';

  @override
  String get screenshot_unable_load_image => '无法加载图片';

  @override
  String get screenshot_history_title => '截图历史';

  @override
  String get screenshot_clear_history => '清空历史';

  @override
  String get screenshot_confirm_clear_history => '确认清空';

  @override
  String get screenshot_confirm_clear_history_message =>
      '确定要清空所有截图历史吗？此操作无法撤销。';

  @override
  String get screenshot_clear => '清空';

  @override
  String get screenshot_no_records => '暂无截图记录';

  @override
  String get screenshot_history_hint => '开始截图后，历史记录将显示在这里';

  @override
  String get screenshot_recent => '刚刚';

  @override
  String screenshot_minutes_ago(Object minutes) {
    return '$minutes 分钟前';
  }

  @override
  String screenshot_hours_ago(Object hours) {
    return '$hours 小时前';
  }

  @override
  String screenshot_days_ago(Object days) {
    return '$days 天前';
  }

  @override
  String screenshot_date_format(Object day, Object month) {
    return '$month月$day日';
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
    return '$year年$month月$day日 $hour:$minute:$second';
  }

  @override
  String get screenshot_type_fullscreen => '全屏';

  @override
  String get screenshot_detail_info => '详细信息';

  @override
  String get screenshot_info_file_path => '文件路径';

  @override
  String get screenshot_info_file_size => '文件大小';

  @override
  String get screenshot_info_type => '截图类型';

  @override
  String get screenshot_info_created => '创建时间';

  @override
  String get screenshot_info_dimensions => '图片尺寸';

  @override
  String screenshot_shortcut_edit_pending(Object action) {
    return '快捷键编辑功能待实现：$action';
  }

  @override
  String get screenshot_editor_title => '编辑截图';

  @override
  String get image_editor_pen => '画笔';

  @override
  String get image_editor_rectangle => '矩形';

  @override
  String get image_editor_arrow => '箭头';

  @override
  String get image_editor_text => '文字';

  @override
  String get image_editor_mosaic => '马赛克';
}

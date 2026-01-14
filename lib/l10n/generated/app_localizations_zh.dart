// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '插件平台';

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
  String get button_install => '安装';

  @override
  String get button_uninstall => '卸载';

  @override
  String get button_enable => '启用';

  @override
  String get button_disable => '禁用';

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
  String get plugin_statusEnabled => '已启用';

  @override
  String get plugin_statusDisabled => '已禁用';

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
  String get plugin_enableSuccess => '插件已启用';

  @override
  String get plugin_disableSuccess => '插件已禁用';

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
  String get settings_language => '语言设置';

  @override
  String get settings_theme => '主题设置';

  @override
  String get settings_languageChinese => '中文';

  @override
  String get settings_languageEnglish => 'English';

  @override
  String get plugin_detailsTitle => '插件详情';

  @override
  String get plugin_detailsStatus => '状态';

  @override
  String get plugin_detailsState => '状态';

  @override
  String get plugin_detailsEnabled => '已启用';

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
}

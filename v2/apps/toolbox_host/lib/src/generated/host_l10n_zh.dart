// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'host_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class HostL10nZh extends HostL10n {
  HostL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '工具箱';

  @override
  String get navDirectory => '插件目录';

  @override
  String get navSettings => '设置';

  @override
  String get directoryTitle => '插件目录';

  @override
  String get reasonUnsupportedTarget => '该插件不支持当前平台';

  @override
  String reasonGeneric(String code) {
    return '无法在当前平台启用（$code）';
  }

  @override
  String get kindBuiltin => '内置插件';

  @override
  String get kindSidecar => 'Sidecar 插件';

  @override
  String get detailBasicInfo => '基本信息';

  @override
  String get detailFieldId => '插件 ID';

  @override
  String get detailFieldVersion => '版本';

  @override
  String get detailFieldKind => '类型';

  @override
  String get detailFieldTargets => '支持平台';

  @override
  String get detailFieldSurfaces => '呈现面';

  @override
  String get detailEnableToggle => '启用插件';

  @override
  String get detailOpenPage => '打开插件页面';

  @override
  String get detailNoPage => '该插件未提供页面';

  @override
  String get detailFormDemo => '表单演示';

  @override
  String get formDemoResultTitle => '表单回填结果';

  @override
  String get detailSidecarPanel => 'Sidecar 安装面板';

  @override
  String get sidecarPlaceholder => 'Sidecar 包安装与解析将在后续阶段接入，当前为面板占位。';

  @override
  String get sidecarRootDir => '包目录';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsTheme => '主题方向';

  @override
  String get themePrecisionTools => '精密工具';

  @override
  String get themeWarmLife => '温暖生活';

  @override
  String get themeDarkPro => '极简暗色';

  @override
  String get settingsBrightness => '明暗模式';

  @override
  String get brightnessSystem => '跟随系统';

  @override
  String get brightnessLight => '亮色';

  @override
  String get brightnessDark => '暗色';

  @override
  String get settingsLanguage => '语言';

  @override
  String get welcomePageTitle => '欢迎使用工具箱';

  @override
  String get welcomeBody => '这是宿主内置的欢迎插件页面，由宿主组装并经 PluginPageProvider 呈现。';

  @override
  String get welcomeFormTitle => '反馈演示表单';

  @override
  String get welcomeFormName => '称呼';

  @override
  String get welcomeFormNamePlaceholder => '怎么称呼你';

  @override
  String get welcomeFormScore => '体验评分（1-5）';

  @override
  String get welcomeFormChannel => '偏好渠道';

  @override
  String get welcomeFormChannelEmail => '邮件';

  @override
  String get welcomeFormChannelPush => '系统通知';

  @override
  String get welcomeFormSubscribe => '愿意接收产品动态';

  @override
  String get welcomeFormTopics => '感兴趣的主题';

  @override
  String get welcomeFormTopicDesign => '界面设计';

  @override
  String get welcomeFormTopicPlugins => '插件开发';

  @override
  String get formFieldRequired => '必填';
}

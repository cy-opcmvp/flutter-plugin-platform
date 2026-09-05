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
  String get reasonUnsupportedSurface => '该插件声明的呈现面在此宿主未实现';

  @override
  String reasonGeneric(String code) {
    return '无法在当前平台启用（$code）';
  }

  @override
  String get kindBuiltin => '内置插件';

  @override
  String get kindSidecar => 'Sidecar 插件';

  @override
  String get kindSidecarInstallable => 'Sidecar 插件（需安装后运行）';

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
  String get detailPluginSection => '插件页面';

  @override
  String get detailOpenPage => '打开插件页面';

  @override
  String get detailSidecarPanel => 'Sidecar 安装面板';

  @override
  String get sidecarRootDir => '包目录';

  @override
  String get hashPanelTitle => 'Hash 工具（Sidecar）';

  @override
  String get hashInstallPathLabel => '包文件路径（.scp）';

  @override
  String get hashInstallPathPlaceholder => '例如 D:/dist/hash-tool.scp';

  @override
  String get hashInstallButton => '安装';

  @override
  String get hashInstallSuccess => '安装成功';

  @override
  String hashInstallFailed(String code) {
    return '安装失败（$code）';
  }

  @override
  String get hashStartButton => '启动';

  @override
  String get hashStopButton => '停止';

  @override
  String get hashNotInstalled => '未安装：请先安装 .scp 包';

  @override
  String get hashInstalled => '已安装';

  @override
  String get hashFormTitle => 'Hash 计算';

  @override
  String get hashTextLabel => '文本';

  @override
  String get hashTextPlaceholder => '输入要计算摘要的文本';

  @override
  String get hashResultTitle => '计算结果';

  @override
  String get hashMd5Label => 'MD5';

  @override
  String get hashSha1Label => 'SHA-1';

  @override
  String get hashSha256Label => 'SHA-256';

  @override
  String get hashPanelUnsupported => '此宿主暂未提供该 Sidecar 的命令面板';

  @override
  String hashCommandFailed(String cause) {
    return '命令失败（$cause）';
  }

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
  String get formDemoResultTitle => '表单回填结果';

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

  @override
  String get detailSettings => '插件设置';

  @override
  String get detailNoSettings => '该插件未提供设置项';

  @override
  String get calcDisplayHint => '输入表达式';

  @override
  String get calcHistoryTitle => '历史记录';

  @override
  String get calcClearHistory => '清空';

  @override
  String get calcHistoryEmpty => '暂无历史记录';

  @override
  String get calcErrorEmpty => '表达式为空（位置：0）';

  @override
  String calcErrorUnexpectedToken(int position) {
    return '存在无法识别的符号（位置：$position）';
  }

  @override
  String calcErrorUnbalancedParens(int position) {
    return '括号未闭合（位置：$position）';
  }

  @override
  String get calcErrorDivideByZero => '除数不能为零';

  @override
  String get calcErrorUnknown => '表达式无效';

  @override
  String get calcSettingsDecimals => '小数位数';

  @override
  String calcSettingsDecimalsValue(int value) {
    return '保留 $value 位小数';
  }

  @override
  String get calcSettingsHistoryToggle => '显示历史记录';

  @override
  String get shotCaptureButton => '截图';

  @override
  String get shotCapturing => '正在捕获…';

  @override
  String get shotResultTitle => '最近截图';

  @override
  String shotSavedHint(String path) {
    return '已保存：$path';
  }

  @override
  String get shotFailureTitle => '截图失败';

  @override
  String get shotSettingsFormTitle => '截图设置';

  @override
  String get shotSettingsFilenamePrefix => '文件名前缀';

  @override
  String get shotSettingsFilenamePrefixPlaceholder => 'shot';

  @override
  String get shotSettingsQuality => '保存质量';

  @override
  String get shotQualityLossless => '无损（PNG）';

  @override
  String get shotQualityHigh => '高';

  @override
  String get shotQualityStandard => '标准';

  @override
  String get shotQualityNote => 'PNG 为无损格式，质量选项暂以原图保存。';
}

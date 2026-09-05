// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'plugin_flutter_l10n.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class PluginFlutterL10nZh extends PluginFlutterL10n {
  PluginFlutterL10nZh([String locale = 'zh']) : super(locale);

  @override
  String get statusAvailable => '可用';

  @override
  String get statusDisabled => '已停用';

  @override
  String get statusUnavailable => '不可用';

  @override
  String get statusReasonLabel => '原因';

  @override
  String get statusViewReason => '查看原因';

  @override
  String get statusReasonUnsupportedTarget => '该插件不支持当前平台';

  @override
  String get statusReasonMissingCapability => '缺少插件所需的平台能力';

  @override
  String get statusReasonCapabilityVersionTooLow => '平台能力版本过低，无法满足插件要求';

  @override
  String get statusReasonProviderUnavailable => '所需能力提供方不可用';

  @override
  String get statusReasonDependencyCycle => '插件依赖存在循环，无法解析';

  @override
  String get statusReasonUnknown => '未知原因';

  @override
  String get formRequiredMark => '必填';

  @override
  String get formRequiredError => '请填写必填项';

  @override
  String get formInvalidNumber => '请输入有效数字';

  @override
  String formNumberRange(String min, String max) {
    return '请输入 $min 到 $max 之间的数值';
  }

  @override
  String formNumberMin(String min) {
    return '不能小于 $min';
  }

  @override
  String formNumberMax(String max) {
    return '不能大于 $max';
  }

  @override
  String get formSubmit => '提交';

  @override
  String get resultTableEmpty => '暂无数据';

  @override
  String resultImageUnavailable(String path) {
    return '图片路径：$path（宿主暂未提供文件读取能力）';
  }
}

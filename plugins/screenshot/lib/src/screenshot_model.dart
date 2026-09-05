/// 截图运行设置与状态模型。
///
/// 模型只存稳定键与原始输入；展示文案由宿主注入的文案载体渲染，
/// 插件包自身零 l10n 配置。
///
/// 可选注入 [PluginStorage]（宿主组装根提供，KV 契约见能力接口包）：
/// [loadFromStorage] 恢复持久化设置（保存目录/文件名模板/格式/JPEG
/// 质量/自动复制/全局热键），设置每次变更即异步写回；存储失败一律
/// 静默降级为内存态（debugPrint），不阻断交互。
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:platform_capabilities/platform_capabilities.dart';
import 'package:plugin_contracts/plugin_contracts.dart';

import 'filename_template.dart';
import 'region_selection.dart';
import 'screenshot_manifest.dart';

/// 保存目录稳定键集合（下拉展示文案经文案载体映射）。
///
/// `{pictures}`/`{documents}` 由宿主 KnownFolders 能力解析系统目录；
/// `{pluginData}` 为插件数据目录（落盘能力兜底）。
const List<String> kScreenshotSaveDirKeys = <String>[
  '{pictures}',
  '{documents}',
  '{pluginData}',
];

/// 默认保存目录稳定键。
const String kScreenshotDefaultSaveDir = '{pictures}';

/// 保存格式稳定键集合：`png` 原样保存，`jpeg` 按质量重编码。
const List<String> kScreenshotFormatKeys = <String>['png', 'jpeg'];

/// 默认保存格式稳定键。
const String kScreenshotDefaultFormat = 'png';

/// 默认 JPEG 质量（1-100）。
const int kScreenshotDefaultJpegQuality = 90;

/// 自动复制稳定键集合：不复制 / 复制图像 / 复制文件路径。
const List<String> kScreenshotAutoCopyKeys = <String>['none', 'image', 'path'];

/// 默认自动复制稳定键。
const String kScreenshotDefaultAutoCopy = 'image';

/// 默认全局热键 combo（S1 批C；设置页可改，注册失败时页面提示）。
const String kScreenshotDefaultHotkeyCombo = 'Ctrl+Shift+A';

/// 截图运行设置。
final class ScreenshotSettings {
  /// 创建设置；各稳定键字段必须属于对应键集合，[jpegQuality] 取
  /// 1-100，[filenameTemplate] 非空白，[hotkeyCombo] 须通过
  /// [screenshotIsValidHotkeyCombo] 校验。
  ///
  /// 断言依赖 `contains()` 等方法调用，无法声明为 const 构造。
  ScreenshotSettings({
    this.saveDir = kScreenshotDefaultSaveDir,
    this.filenameTemplate = kScreenshotDefaultFilenameTemplate,
    this.format = kScreenshotDefaultFormat,
    this.jpegQuality = kScreenshotDefaultJpegQuality,
    this.autoCopy = kScreenshotDefaultAutoCopy,
    this.hotkeyCombo = kScreenshotDefaultHotkeyCombo,
  }) : assert(kScreenshotSaveDirKeys.contains(saveDir), 'saveDir 必须为稳定键'),
       assert(filenameTemplate.trim().isNotEmpty, 'filenameTemplate 不能为空白'),
       assert(kScreenshotFormatKeys.contains(format), 'format 必须为稳定键'),
       assert(jpegQuality >= 1 && jpegQuality <= 100, 'jpegQuality 取 1-100'),
       assert(kScreenshotAutoCopyKeys.contains(autoCopy), 'autoCopy 必须为稳定键'),
       assert(
         screenshotIsValidHotkeyCombo(hotkeyCombo),
         'hotkeyCombo 必须为合法组合键（如 Ctrl+Shift+A）',
       );

  /// 保存目录稳定键（见 [kScreenshotSaveDirKeys]）。
  final String saveDir;

  /// 文件名模板（tokens：{date}/{time}/{seq}，见 [expandFilenameTemplate]）。
  final String filenameTemplate;

  /// 保存格式稳定键（见 [kScreenshotFormatKeys]）。
  final String format;

  /// JPEG 编码质量（1-100，仅 format=jpeg 时生效）。
  final int jpegQuality;

  /// 自动复制稳定键（见 [kScreenshotAutoCopyKeys]）。
  final String autoCopy;

  /// 全局热键 combo（如 `Ctrl+Shift+A`，S1 批C；页面据此注册/重注册）。
  final String hotkeyCombo;

  /// 复制并按需覆盖部分字段（传 null 表示保留原值）。
  ScreenshotSettings copyWith({
    String? saveDir,
    String? filenameTemplate,
    String? format,
    int? jpegQuality,
    String? autoCopy,
    String? hotkeyCombo,
  }) {
    return ScreenshotSettings(
      saveDir: saveDir ?? this.saveDir,
      filenameTemplate: filenameTemplate ?? this.filenameTemplate,
      format: format ?? this.format,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      autoCopy: autoCopy ?? this.autoCopy,
      hotkeyCombo: hotkeyCombo ?? this.hotkeyCombo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenshotSettings &&
          saveDir == other.saveDir &&
          filenameTemplate == other.filenameTemplate &&
          format == other.format &&
          jpegQuality == other.jpegQuality &&
          autoCopy == other.autoCopy &&
          hotkeyCombo == other.hotkeyCombo;

  @override
  int get hashCode => Object.hash(
    saveDir,
    filenameTemplate,
    format,
    jpegQuality,
    autoCopy,
    hotkeyCombo,
  );
}

/// 截图状态模型：当前设置（可变），UI 经 ListenableBuilder 订阅。
class ScreenshotModel extends ChangeNotifier {
  /// 创建模型；[settings] 缺省取默认设置，[storage] 缺省不持久化。
  ScreenshotModel({ScreenshotSettings? settings, PluginStorage? storage})
    : _settings = settings ?? ScreenshotSettings(),
      _storage = storage;

  /// 设置项在本插件 KV 命名空间下的存储键。
  static const String _kSettingsKey = 'settings';

  ScreenshotSettings _settings;

  final PluginStorage? _storage;

  /// 当前设置。
  ScreenshotSettings get settings => _settings;

  /// 更新设置并通知监听者，同时异步写回存储（失败静默保留内存态）。
  void updateSettings(ScreenshotSettings settings) {
    _settings = settings;
    notifyListeners();
    _persistSettings();
  }

  /// 从存储异步恢复设置（未注入存储时为无操作）。
  ///
  /// 无持久化值或值损坏时保持当前设置；单字段值非法时该字段回退当前
  /// 值；存储失败静默降级。
  Future<void> loadFromStorage() async {
    final PluginStorage? storage = _storage;
    if (storage == null) {
      return;
    }
    final String? raw;
    try {
      raw = await storage.read(
        PluginId.parse(kScreenshotPluginId),
        _kSettingsKey,
      );
    } on PluginFailure catch (error) {
      _debugStorageFailure('read', error);
      return;
    }
    if (raw == null) {
      return;
    }
    try {
      final Map<String, Object?> data = jsonDecode(raw) as Map<String, Object?>;
      _settings = _settings.copyWith(
        saveDir: _stableKey(data['saveDir'], kScreenshotSaveDirKeys),
        filenameTemplate: switch (data['filenameTemplate']) {
          final String value when value.trim().isNotEmpty => value,
          _ => null,
        },
        format: _stableKey(data['format'], kScreenshotFormatKeys),
        jpegQuality: switch (data['jpegQuality']) {
          final int value when value >= 1 && value <= 100 => value,
          _ => null,
        },
        autoCopy: _stableKey(data['autoCopy'], kScreenshotAutoCopyKeys),
        hotkeyCombo: switch (data['hotkeyCombo']) {
          final String value when screenshotIsValidHotkeyCombo(value) =>
            value,
          _ => null,
        },
      );
      notifyListeners();
    } on FormatException catch (error) {
      debugPrint('screenshot settings 损坏，保持当前设置: ${error.message}');
    }
  }

  /// 解析稳定键字段：字符串且属于键集合才生效，否则返回 null（保留
  /// 当前值）。
  String? _stableKey(Object? raw, List<String> keys) {
    return switch (raw) {
      final String value when keys.contains(value) => value,
      _ => null,
    };
  }

  /// 把当前设置写回 KV（每次变更即写；失败静默保留内存态）。
  void _persistSettings() {
    final PluginStorage? storage = _storage;
    if (storage == null) {
      return;
    }
    final String raw = jsonEncode(<String, Object?>{
      'saveDir': _settings.saveDir,
      'filenameTemplate': _settings.filenameTemplate,
      'format': _settings.format,
      'jpegQuality': _settings.jpegQuality,
      'autoCopy': _settings.autoCopy,
      'hotkeyCombo': _settings.hotkeyCombo,
    });
    unawaited(_writeSettings(storage, raw));
  }

  Future<void> _writeSettings(PluginStorage storage, String raw) async {
    try {
      await storage.write(
        PluginId.parse(kScreenshotPluginId),
        _kSettingsKey,
        raw,
      );
    } on PluginFailure catch (error) {
      _debugStorageFailure('write', error);
    }
  }

  /// 输出存储失败的调试信息（宿主偏好静默降级约定）。
  void _debugStorageFailure(String reason, PluginFailure error) {
    debugPrint(
      'screenshot settings $reason 失败: ${error.code} '
      '${error.details}',
    );
  }
}

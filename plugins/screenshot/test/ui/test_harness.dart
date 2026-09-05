/// 截图 UI 测试共享骨架：主题令牌注入 + 固定文案载体。
///
/// 插件包自身零 l10n 配置：文案经固定 [ScreenshotStrings] 载体模拟
/// 宿主注入；FormRenderer/ResultRenderer 的包内固定文案依赖
/// plugin_flutter 本地化委托，harness 中一并注册。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_flutter/plugin_flutter.dart';
import 'package:screenshot/screenshot.dart';

/// 固定文案函数：保存成功提示（const 闭包不可用，以顶层函数满足）。
String _savedHint(String path) => '已保存：$path';

/// 测试固定文案载体。
final ScreenshotStrings kTestStrings = ScreenshotStrings(
  captureButton: '截图',
  capturing: '正在捕获…',
  resultTitle: '最近截图',
  savedHint: _savedHint,
  failureTitle: '截图失败',
  settingsFormTitle: '截图设置',
  settingsSaveDir: '保存目录',
  saveDirPictures: '图片目录',
  saveDirDocuments: '文档目录',
  saveDirPluginData: '插件数据目录',
  settingsFilenameTemplate: '文件名模板',
  settingsFilenameTemplatePlaceholder: 'screenshot-20260101-120000',
  settingsFormat: '保存格式',
  formatPng: 'PNG（无损）',
  formatJpeg: 'JPEG（压缩）',
  settingsJpegQuality: 'JPEG 质量（1-100）',
  settingsAutoCopy: '自动复制',
  autoCopyNone: '不复制',
  autoCopyImage: '复制图像',
  autoCopyPath: '复制文件路径',
  formatNote: '文件名模板支持日期、时间与同秒序号变量；系统目录不可用时自动回退插件数据目录。',
  fieldPath: '保存路径',
  fieldSize: '图像尺寸',
  fieldCopied: '自动复制',
  copiedNone: '未复制',
  copiedImage: '已复制图像',
  copiedPath: '已复制文件路径',
  copiedFailed: '复制失败',
  regionButton: '区域截图',
  settingsHotkey: '全局热键',
  hotkeyNote: '热键在应用运行期间全局生效；修改后自动重新注册。',
  hotkeyFailedHint: '热键注册失败：',
  regionCopiedHint: '选区已复制到剪贴板',
  regionSelectorSave: '保存',
  regionSelectorCopy: '复制',
  regionSelectorDiscard: '放弃',
  regionSelectorHint: '拖拽框选区域，Enter 确认保存，Esc 取消',
);

/// 文案解析器：恒定返回测试载体（语言无关）。
ScreenshotStringsResolver kTestResolver = _resolve;

/// 解析实现。
ScreenshotStrings _resolve(BuildContext context) => kTestStrings;

/// 以主题令牌装配的 MaterialApp 包裹 [child] 供组件测试渲染。
Widget buildScreenshotHarness(Widget child) {
  return MaterialApp(
    theme: AppTheme.build(AppThemePreset.warmLife, Brightness.light),
    localizationsDelegates: PluginFlutterL10n.localizationsDelegates,
    supportedLocales: PluginFlutterL10n.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// 放大测试视口，保证表单与结果区全部落在视口内可交互。
void enlargeTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

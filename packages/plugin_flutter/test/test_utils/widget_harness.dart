/// 组件测试共享骨架：本地化 + 主题令牌注入。
library;

import 'package:flutter/material.dart';

import 'package:plugin_flutter/plugin_flutter.dart';

/// 以指定方向与语言包裹 [child]，供组件测试渲染。
Widget buildHarness(
  Widget child, {
  Locale locale = const Locale('zh'),
  AppThemePreset preset = AppThemePreset.warmLife,
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: PluginFlutterL10n.supportedLocales,
    localizationsDelegates: PluginFlutterL10n.localizationsDelegates,
    theme: AppTheme.build(preset, Brightness.light),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

/// 宿主应用壳：语言与明暗模式状态、MaterialApp 组装与导航外壳。
///
/// 组装依赖全部来自 [HostCompositionRoot]；本文件只持 UI 侧状态（语言、
/// 明暗模式、插件停用集合），并合并宿主与 plugin_flutter 两套 l10n 委托
/// （FormRenderer/ResultRenderer 内部依赖 PluginFlutterL10n）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:plugin_contracts/plugin_contracts.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

import 'brightness_mode.dart';
import 'generated/host_l10n.dart';
import 'host_composition_root.dart';
import 'pages/plugin_directory_page.dart';
import 'pages/plugin_detail_page.dart';
import 'pages/settings_page.dart';

/// 宿主应用组件：持有 [HostCompositionRoot] 并提供 MaterialApp。
final class ToolboxApp extends StatefulWidget {
  /// 创建宿主应用；[root] 为组装根（通常由 main 构造）。
  const ToolboxApp({super.key, required this.root});

  /// 宿主组装根。
  final HostCompositionRoot root;

  @override
  State<ToolboxApp> createState() => _ToolboxAppState();
}

class _ToolboxAppState extends State<ToolboxApp> {
  Locale _locale = const Locale('zh');
  BrightnessMode _brightnessMode = BrightnessMode.system;
  Set<String> _disabledPluginIds = <String>{};

  @override
  void initState() {
    super.initState();
    widget.root.themeController.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.root.themeController.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlugin(String pluginId, bool enabled) {
    setState(() {
      final Set<String> next = Set<String>.of(_disabledPluginIds);
      if (enabled) {
        next.remove(pluginId);
      } else {
        next.add(pluginId);
      }
      _disabledPluginIds = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController theme = widget.root.themeController;
    return MaterialApp(
      onGenerateTitle: (BuildContext context) => HostL10n.of(context).appTitle,
      theme: AppTheme.build(theme.value, Brightness.light),
      darkTheme: AppTheme.build(theme.value, Brightness.dark),
      themeMode: switch (_brightnessMode) {
        BrightnessMode.system => ThemeMode.system,
        BrightnessMode.light => ThemeMode.light,
        BrightnessMode.dark => ThemeMode.dark,
      },
      locale: _locale,
      // 合并两套委托：宿主文案 + 组件库内部文案（全局委托去重）。
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        HostL10n.delegate,
        PluginFlutterL10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: HostL10n.supportedLocales,
      home: _HomeShell(
        root: widget.root,
        disabledPluginIds: _disabledPluginIds,
        onTogglePlugin: _togglePlugin,
        brightnessMode: _brightnessMode,
        onBrightnessModeChanged: (BrightnessMode mode) =>
            setState(() => _brightnessMode = mode),
        locale: _locale,
        onLocaleChanged: (Locale locale) => setState(() => _locale = locale),
      ),
    );
  }
}

/// 导航外壳：左侧 NavigationRail 切换目录页/设置页，详情页经 Navigator 压栈。
final class _HomeShell extends StatefulWidget {
  const _HomeShell({
    required this.root,
    required this.disabledPluginIds,
    required this.onTogglePlugin,
    required this.brightnessMode,
    required this.onBrightnessModeChanged,
    required this.locale,
    required this.onLocaleChanged,
  });

  final HostCompositionRoot root;
  final Set<String> disabledPluginIds;
  final void Function(String pluginId, bool enabled) onTogglePlugin;
  final BrightnessMode brightnessMode;
  final ValueChanged<BrightnessMode> onBrightnessModeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  void _openPlugin(PluginManifest manifest) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PluginDetailPage(
          root: widget.root,
          manifest: manifest,
          enabled: !widget.disabledPluginIds.contains(manifest.id.value),
          onToggleEnabled: widget.onTogglePlugin,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final HostL10n l10n = HostL10n.of(context);
    return Scaffold(
      body: Row(
        children: <Widget>[
          SafeArea(
            child: NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (int index) =>
                  setState(() => _index = index),
              labelType: NavigationRailLabelType.all,
              destinations: <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: const Icon(Icons.grid_view_outlined),
                  label: Text(l10n.navDirectory),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.settings_outlined),
                  label: Text(l10n.navSettings),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: _index == 0
                ? PluginDirectoryPage(
                    root: widget.root,
                    disabledPluginIds: widget.disabledPluginIds,
                    onOpenPlugin: _openPlugin,
                  )
                : SettingsPage(
                    themeController: widget.root.themeController,
                    brightnessMode: widget.brightnessMode,
                    onBrightnessModeChanged: widget.onBrightnessModeChanged,
                    locale: widget.locale,
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
          ),
        ],
      ),
    );
  }
}

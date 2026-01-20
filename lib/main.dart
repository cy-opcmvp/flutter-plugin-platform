import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import './l10n/generated/app_localizations.dart';
import './core/services/locale_provider.dart';
import './core/services/platform_service_manager.dart';
import './core/services/config_manager.dart';
import './ui/screens/main_platform_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化window_manager（仅在桌面平台）
  if (!kIsWeb) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600), // 设置窗口最小尺寸，防止布局溢出
      center: true,
      backgroundColor: Color(0xFF1E1E1E), // 使用深色背景替代透明，避免边框问题
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 初始化配置管理器
  await ConfigManager.instance.initialize();
  if (kDebugMode) {
    debugPrint('Config manager initialized');
  }

  // 初始化平台服务
  final servicesInitialized = await PlatformServiceManager.initialize();
  if (kDebugMode) {
    debugPrint('Platform services initialized: $servicesInitialized');
  }

  // 初始化语言设置
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();

  runApp(PluginPlatformApp(localeProvider: localeProvider));
}

class PluginPlatformApp extends StatefulWidget {
  final LocaleProvider localeProvider;

  const PluginPlatformApp({super.key, required this.localeProvider});

  @override
  State<PluginPlatformApp> createState() => _PluginPlatformAppState();

  /// 获取 LocaleProvider 实例
  static LocaleProvider of(BuildContext context) {
    final state = context.findAncestorStateOfType<_PluginPlatformAppState>();
    return state!.widget.localeProvider;
  }
}

class _PluginPlatformAppState extends State<PluginPlatformApp>
    with WindowListener {
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.localeProvider.addListener(_onLocaleChanged);
    if (!kIsWeb) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    widget.localeProvider.removeListener(_onLocaleChanged);
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  void onWindowFocus() async {
    // 当窗口获得焦点时，确保窗口可见
    // 这处理了用户点击任务栏图标的情况
    final isVisible = await windowManager.isVisible();
    if (!isVisible) {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  @override
  void onWindowClose() async {
    // 直接关闭应用
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Plugin Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 国际化配置
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales,
      locale: widget.localeProvider.locale,
      home: const MainPlatformScreen(),
    );
  }
}

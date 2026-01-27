import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import './l10n/generated/app_localizations.dart';
import './core/services/locale_provider.dart';
import './core/services/theme_provider.dart';
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

  // 初始化主题设置
  final themeProvider = ThemeProvider();
  await themeProvider.loadSavedThemeMode();

  runApp(
    PluginPlatformApp(
      localeProvider: localeProvider,
      themeProvider: themeProvider,
    ),
  );
}

class PluginPlatformApp extends StatefulWidget {
  final LocaleProvider localeProvider;
  final ThemeProvider themeProvider;

  const PluginPlatformApp({
    super.key,
    required this.localeProvider,
    required this.themeProvider,
  });

  @override
  State<PluginPlatformApp> createState() => _PluginPlatformAppState();

  /// 获取 LocaleProvider 实例
  static LocaleProvider of(BuildContext context) {
    final state = context.findAncestorStateOfType<_PluginPlatformAppState>();
    return state!.widget.localeProvider;
  }

  /// 获取 ThemeProvider 实例
  static ThemeProvider themeOf(BuildContext context) {
    final state = context.findAncestorStateOfType<_PluginPlatformAppState>();
    return state!.widget.themeProvider;
  }
}

class _PluginPlatformAppState extends State<PluginPlatformApp>
    with WindowListener {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.localeProvider.addListener(_onSettingsChanged);
    widget.themeProvider.addListener(_onSettingsChanged);
    if (!kIsWeb) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    widget.localeProvider.removeListener(_onSettingsChanged);
    widget.themeProvider.removeListener(_onSettingsChanged);
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  void _onSettingsChanged() {
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ).copyWith(
              // 调整黑暗模式的背景色，使用更深的颜色
              surface: const Color(0xFF121212),
              onSurface: const Color(0xFFE1E1E1),
              surfaceContainer: const Color(0xFF1E1E1E),
              surfaceContainerHigh: const Color(0xFF2A2A2A),
              surfaceContainerHighest: const Color(0xFF333333),
            ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
        // 自定义深色模式下的填充按钮样式，使用更柔和的紫色
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(
              const Color(0xFFBB86FC).withValues(alpha: 0.7), // 更柔和、更暗的紫色
            ),
            foregroundColor: WidgetStateProperty.all<Color>(
              const Color(0xFFFFFFFF),
            ),
          ),
        ),
      ),
      themeMode: widget.themeProvider.themeMode,
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

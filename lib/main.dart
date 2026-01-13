import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:window_manager/window_manager.dart';
import './l10n/generated/app_localizations.dart';
import './core/services/locale_provider.dart';
import './ui/screens/main_platform_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化window_manager（仅在桌面平台）
  if (!kIsWeb) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  // 初始化语言设置
  final localeProvider = LocaleProvider();
  await localeProvider.loadSavedLocale();
  
  runApp(PluginPlatformApp(localeProvider: localeProvider));
}

class PluginPlatformApp extends StatefulWidget {
  final LocaleProvider localeProvider;
  
  const PluginPlatformApp({
    super.key,
    required this.localeProvider,
  });

  @override
  State<PluginPlatformApp> createState() => _PluginPlatformAppState();
  
  /// 获取 LocaleProvider 实例
  static LocaleProvider of(BuildContext context) {
    final state = context.findAncestorStateOfType<_PluginPlatformAppState>();
    return state!.widget.localeProvider;
  }
}

class _PluginPlatformAppState extends State<PluginPlatformApp> {
  @override
  void initState() {
    super.initState();
    widget.localeProvider.addListener(_onLocaleChanged);
  }
  
  @override
  void dispose() {
    widget.localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }
  
  void _onLocaleChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

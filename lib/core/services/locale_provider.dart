import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 语言设置提供者
/// 管理应用的语言设置和持久化
class LocaleProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  
  Locale _locale = const Locale('zh', 'CN');
  
  /// 当前语言设置
  Locale get locale => _locale;
  
  /// 支持的语言列表
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];
  
  /// 切换语言
  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.contains(locale)) return;
    if (_locale == locale) return;
    
    _locale = locale;
    await _saveLocalePreference(locale);
    notifyListeners();
  }
  
  /// 从持久化存储加载语言设置
  Future<void> loadSavedLocale() async {
    final savedLocale = await _loadLocalePreference();
    if (savedLocale != null && savedLocale != _locale) {
      _locale = savedLocale;
      notifyListeners();
    }
  }
  
  /// 保存语言设置到持久化存储
  Future<void> _saveLocalePreference(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
    } catch (e) {
      // 忽略保存错误，不影响应用运行
      debugPrint('Failed to save locale preference: $e');
    }
  }
  
  /// 从持久化存储加载语言设置
  Future<Locale?> _loadLocalePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeString = prefs.getString(_localeKey);
      
      if (localeString != null) {
        final parts = localeString.split('_');
        if (parts.length == 2) {
          final locale = Locale(parts[0], parts[1]);
          if (supportedLocales.contains(locale)) {
            return locale;
          }
        }
      }
    } catch (e) {
      // 忽略加载错误，使用默认语言
      debugPrint('Failed to load locale preference: $e');
    }
    return null;
  }
  
  /// 获取语言显示名称
  String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return '中文';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }
  
  /// 检查是否为中文
  bool get isChinese => _locale.languageCode == 'zh';
  
  /// 检查是否为英文
  bool get isEnglish => _locale.languageCode == 'en';
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 主题设置提供者
/// 管理应用的主题模式和持久化
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  /// 当前主题模式
  ThemeMode get themeMode => _themeMode;

  /// 是否为浅色主题
  bool get isLight => _themeMode == ThemeMode.light;

  /// 是否为深色主题
  bool get isDark => _themeMode == ThemeMode.dark;

  /// 是否跟随系统
  bool get isSystem => _themeMode == ThemeMode.system;

  /// 设置主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _saveThemeModePreference(mode);
    notifyListeners();
  }

  /// 从持久化存储加载主题设置
  Future<void> loadSavedThemeMode() async {
    final savedThemeMode = await _loadThemeModePreference();
    if (savedThemeMode != null && savedThemeMode != _themeMode) {
      _themeMode = savedThemeMode;
      notifyListeners();
    }
  }

  /// 保存主题设置到持久化存储
  Future<void> _saveThemeModePreference(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = mode.toString();
      await prefs.setString(_themeModeKey, themeModeString);
    } catch (e) {
      debugPrint('Failed to save theme mode preference: $e');
    }
  }

  /// 从持久化存储加载主题设置
  Future<ThemeMode?> _loadThemeModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        if (themeModeString.contains('light')) {
          return ThemeMode.light;
        } else if (themeModeString.contains('dark')) {
          return ThemeMode.dark;
        } else if (themeModeString.contains('system')) {
          return ThemeMode.system;
        }
      }
    } catch (e) {
      debugPrint('Failed to load theme mode preference: $e');
    }
    return null;
  }

  /// 获取主题模式显示名称
  String getThemeModeDisplayName(ThemeMode mode, {required bool isChinese}) {
    switch (mode) {
      case ThemeMode.light:
        return isChinese ? '浅色' : 'Light';
      case ThemeMode.dark:
        return isChinese ? '深色' : 'Dark';
      case ThemeMode.system:
        return isChinese ? '跟随系统' : 'Follow System';
    }
  }
}

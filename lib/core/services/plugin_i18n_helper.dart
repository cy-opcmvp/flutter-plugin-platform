library;

import 'package:plugin_platform/core/services/locale_provider.dart';
import '../interfaces/i_plugin_i18n.dart';

/// 插件国际化辅助实现
///
/// 为外部插件提供完整的国际化支持，包括：
/// - 插件翻译注册和管理
/// - 多语言文本获取
/// - 占位符替换
/// - 语言切换支持
class PluginI18nHelper implements IPluginI18n {
  /// 所有注册的翻译
  /// 格式：{语言代码: {翻译键: 翻译文本}}
  final Map<String, Map<String, String>> _translations = {};

  /// 语言提供者
  final LocaleProvider _localeProvider;

  /// 构造函数
  PluginI18nHelper(this._localeProvider);

  @override
  String get currentLocale {
    return _localeProvider.locale.languageCode;
  }

  @override
  String translate(String key, {Map<String, dynamic>? args}) {
    return translateLocale(currentLocale, key, args: args);
  }

  @override
  bool hasTranslation(String key) {
    final locale = currentLocale;
    final translations = _translations[locale];
    return translations?.containsKey(key) ?? false;
  }

  @override
  List<String> get supportedLocales {
    return _translations.keys.toList();
  }

  @override
  void registerTranslations(
    String pluginId,
    Map<String, Map<String, String>> translations,
  ) {
    translations.forEach((locale, localeTranslations) {
      // 合并翻译到对应语言的翻译映射中
      _translations[locale] = {
        ...(_translations[locale] ?? {}),
        ...localeTranslations,
      };
    });
  }

  @override
  String translateLocale(
    String locale,
    String key, {
    Map<String, dynamic>? args,
  }) {
    // 获取指定语言的翻译
    final localeTranslations = _translations[locale];

    // 如果找不到翻译，返回键本身
    if (localeTranslations == null || !localeTranslations.containsKey(key)) {
      // 尝试使用主语言（如 zh_CN -> zh）
      final mainLocale = locale.split('_').first;
      final mainTranslations = _translations[mainLocale];
      if (mainTranslations != null && mainTranslations.containsKey(key)) {
        return _replacePlaceholders(mainTranslations[key]!, args);
      }
      // 最终回退：返回键本身
      return key;
    }

    // 获取翻译文本
    String text = localeTranslations[key]!;

    // 替换占位符
    return _replacePlaceholders(text, args);
  }

  /// 替换文本中的占位符
  ///
  /// [text] 包含占位符的文本
  /// [args] 占位符参数映射
  ///
  /// 支持 {key} 和 $key 两种占位符格式
  String _replacePlaceholders(String text, Map<String, dynamic>? args) {
    if (args == null || args.isEmpty) {
      return text;
    }

    String result = text;
    args.forEach((key, value) {
      // 替换 {key} 格式
      result = result.replaceAll('{$key}', value.toString());
      // 替换 $key 格式
      result = result.replaceAll('\$$key', value.toString());
    });

    return result;
  }

  /// 清除所有翻译（用于测试或重置）
  void clear() {
    _translations.clear();
  }

  /// 获取翻译统计信息
  ///
  /// 返回格式：{语言代码: 翻译数量}
  Map<String, int> getTranslationStats() {
    final stats = <String, int>{};
    _translations.forEach((locale, translations) {
      stats[locale] = translations.length;
    });
    return stats;
  }
}

library;

/// 插件国际化辅助接口
///
/// 为外部插件提供国际化支持，允许插件：
/// - 注册自定义翻译
/// - 访问当前语言设置
/// - 获取本地化文本
abstract class IPluginI18n {
  /// 获取当前语言代码（如 "zh", "en"）
  String get currentLocale;

  /// 翻译文本（使用插件自带的翻译）
  ///
  /// [key] 翻译键
  /// [args] 可选的占位符参数，用于替换文本中的 {key} 占位符
  ///
  /// 示例：
  /// ```dart
  /// i18n.translate('welcome_message', args: {'name': 'John'});
  /// // 如果翻译是 "欢迎 {name}"，则返回 "欢迎 John"
  /// ```
  String translate(String key, {Map<String, dynamic>? args});

  /// 检查是否支持某个翻译键
  ///
  /// [key] 要检查的翻译键
  /// 返回 true 如果当前语言下存在该翻译，否则返回 false
  bool hasTranslation(String key);

  /// 获取所有支持的语言代码列表
  ///
  /// 返回格式：["zh", "en", "ja"]
  List<String> get supportedLocales;

  /// 注册插件的翻译资源
  ///
  /// [pluginId] 插件ID（如 "com.example.myplugin"）
  /// [translations] 翻译映射，格式为：
  /// ```dart
  /// {
  ///   'zh': {
  ///     'key1': '翻译1',
  ///     'key2': '翻译2',
  ///   },
  ///   'en': {
  ///     'key1': 'Translation 1',
  ///     'key2': 'Translation 2',
  ///   }
  /// }
  /// ```
  ///
  /// 注意：
  /// - 同一个翻译键可以被多次注册，后注册的会覆盖先注册的
  /// - 建议在插件的 initialize() 方法中调用此方法
  /// - 翻译资源会与主应用的翻译合并
  void registerTranslations(
    String pluginId,
    Map<String, Map<String, String>> translations,
  );

  /// 获取指定语言的翻译文本
  ///
  /// [locale] 语言代码（如 "zh", "en"）
  /// [key] 翻译键
  /// [args] 可选的占位符参数
  ///
  /// 如果当前语言下不存在该翻译，会返回翻译键本身
  String translateLocale(
    String locale,
    String key, {
    Map<String, dynamic>? args,
  });
}

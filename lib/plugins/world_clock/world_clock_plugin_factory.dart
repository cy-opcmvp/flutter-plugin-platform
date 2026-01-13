import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import 'world_clock_plugin.dart';

/// 世界时钟插件工厂类，负责创建插件实例和提供插件描述符
class WorldClockPluginFactory {
  /// 创建插件实例
  static IPlugin createPlugin() {
    return WorldClockPlugin();
  }

  /// 获取插件描述符
  static PluginDescriptor getDescriptor() {
    return const PluginDescriptor(
      id: 'com.example.worldclock',
      name: '世界时钟',
      version: '1.0.0',
      type: PluginType.tool,
      requiredPermissions: [
        Permission.platformStorage,
        Permission.systemNotifications,
        Permission.platformServices,
      ],
      metadata: {
        'description': '显示多个时区的时间，支持倒计时提醒功能，默认显示北京时间',
        'author': 'Plugin Platform Team',
        'email': 'support@pluginplatform.com',
        'website': 'https://pluginplatform.com',
        'category': 'productivity',
        'tags': ['clock', 'time', 'timezone', 'countdown', 'timer', 'productivity'],
        'icon': 'access_time',
        'minPlatformVersion': '1.0.0',
        'supportedPlatforms': ['mobile', 'desktop', 'web'],
        'supportsHotReload': true,
        'configurable': true,
        'documentation': 'https://docs.pluginplatform.com/plugins/world-clock',
        'sourceCode': 'https://github.com/pluginplatform/world-clock-plugin',
        'license': 'MIT',
        'changelog': {
          '1.0.0': '初始版本发布 - 支持世界时钟显示和倒计时提醒功能',
        },
        'features': [
          '多时区时间显示',
          '默认北京时间',
          '倒计时提醒功能',
          '自定义时钟添加',
          '实时时间更新',
          '完成通知提醒',
          '简洁美观的界面',
          '支持删除非默认时钟',
        ],
        'screenshots': [
          'assets/screenshots/world_clock_main.png',
          'assets/screenshots/world_clock_countdown.png',
          'assets/screenshots/world_clock_add_dialog.png',
        ],
        'keywords': [
          '世界时钟',
          '时区',
          '倒计时',
          '提醒',
          '北京时间',
          '定时器',
          '时间管理',
          '生产力工具',
        ],
        'requirements': {
          'minFlutterVersion': '3.0.0',
          'minDartVersion': '2.17.0',
          'permissions': [
            'storage - 用于保存时钟和倒计时设置',
            'notifications - 用于倒计时完成提醒',
            'platformServices - 用于访问平台服务',
          ],
        },
        'configuration': {
          'defaultTimeZone': 'Asia/Shanghai',
          'updateInterval': 1000,
          'maxClocks': 10,
          'maxCountdowns': 20,
          'enableNotifications': true,
          'enableAnimations': true,
        },
        'localization': {
          'supportedLocales': ['zh_CN', 'en_US'],
          'defaultLocale': 'zh_CN',
        },
      },
      entryPoint: 'lib/plugins/world_clock/world_clock_plugin.dart',
    );
  }
}
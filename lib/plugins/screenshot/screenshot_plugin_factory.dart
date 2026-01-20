library;

import 'package:flutter/widgets.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'screenshot_plugin.dart';

/// 智能截图插件工厂类
///
/// 负责创建插件实例和提供插件描述符
class ScreenshotPluginFactory {
  /// 创建插件实例
  static IPlugin createPlugin() {
    return ScreenshotPlugin();
  }

  /// 获取插件描述符
  static PluginDescriptor getDescriptor({BuildContext? context}) {
    final l10n = context != null ? AppLocalizations.of(context) : null;

    return PluginDescriptor(
      id: 'com.example.screenshot',
      name: l10n?.plugin_screenshot_name ?? '智能截图',
      version: '1.0.0',
      type: PluginType.tool,
      requiredPermissions: const [
        Permission.platformStorage,
        Permission.systemClipboard,
        Permission.platformServices,
        Permission.fileSystemWrite,
        Permission.fileSystemRead,
      ],
      metadata: {
        'description':
            l10n?.plugin_screenshot_description ??
            '类似 Snipaste 的专业截图工具，支持区域截图、全屏截图、窗口截图、图片标注和编辑',
        'author': 'Plugin Platform Team',
        'email': 'support@pluginplatform.com',
        'website': 'https://pluginplatform.com',
        'category': 'productivity',
        'tags': const [
          'screenshot',
          'capture',
          'annotation',
          'productivity',
          'snipaste',
        ],
        'icon': 'screenshot',
        'minPlatformVersion': '1.0.0',
        'supportedPlatforms': const ['windows', 'macos', 'linux'],
        'supportsHotReload': true,
        'configurable': true,
        'documentation': 'https://docs.pluginplatform.com/plugins/screenshot',
        'sourceCode': 'https://github.com/pluginplatform/screenshot-plugin',
        'license': 'MIT',
        'changelog': const {'1.0.0': '初始版本发布 - 支持基础截图功能'},
        'features': const [
          '区域截图（手动框选）',
          '全屏截图',
          '窗口截图（Windows/macOS/Linux）',
          '图片标注和编辑',
          '复制到剪贴板',
          '保存到文件',
          '截图历史记录',
          '可自定义设置',
        ],
        'screenshots': const [
          'assets/screenshots/screenshot_main.png',
          'assets/screenshots/screenshot_editor.png',
          'assets/screenshots/screenshot_settings.png',
        ],
        'keywords': const [
          '截图',
          '屏幕捕获',
          '图片标注',
          '生产力工具',
          'Snipaste',
          '区域截图',
          '全屏截图',
          '窗口截图',
        ],
        'requirements': const {
          'minFlutterVersion': '3.0.0',
          'minDartVersion': '2.17.0',
          'permissions': [
            'storage - 用于保存截图文件',
            'clipboard - 用于复制截图到剪贴板',
            'platformServices - 用于访问平台服务',
          ],
        },
        'configuration': const {
          'defaultSavePath': '{documents}/Screenshots',
          'filenameFormat': 'screenshot_{datetime}',
          'imageFormat': 'png',
          'imageQuality': 95,
          'autoCopyToClipboard': true,
          'showPreview': true,
          'saveHistory': true,
          'maxHistoryCount': 100,
        },
        'localization': const {
          'supportedLocales': ['zh_CN', 'en_US'],
          'defaultLocale': 'zh_CN',
        },
      },
      entryPoint: 'lib/plugins/screenshot/screenshot_plugin.dart',
    );
  }
}

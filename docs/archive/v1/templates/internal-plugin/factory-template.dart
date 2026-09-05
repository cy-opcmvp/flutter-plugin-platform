import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import '{{PLUGIN_FILE_NAME}}_plugin.dart';

/// Factory class for creating {{PLUGIN_NAME}} plugin instances
class {{PLUGIN_CLASS}}PluginFactory {
  /// Creates a new instance of the plugin
  IPlugin createPlugin() {
    return {{PLUGIN_CLASS}}Plugin();
  }

  /// Gets the plugin descriptor
  PluginDescriptor getDescriptor() {
    return const PluginDescriptor(
      id: '{{PLUGIN_ID}}',
      name: '{{PLUGIN_NAME}}',
      version: '1.0.0',
      type: PluginType.tool,
      requiredPermissions: [Permission.storage, Permission.notifications],
      metadata: {
        'description': '{{PLUGIN_DESCRIPTION}}',
        'author': '{{AUTHOR_NAME}}',
        'email': '{{AUTHOR_EMAIL}}',
        'category': '{{PLUGIN_CATEGORY}}',
        'tags': [{{PLUGIN_TAGS}}],
        'icon': '{{PLUGIN_ICON}}',
        'minPlatformVersion': '1.0.0',
        'supportedPlatforms': ['mobile', 'desktop', 'web'],
        'license': '{{LICENSE}}',
        'createdAt': '{{CREATION_DATE}}',
      },
      entryPoint: 'lib/plugins/{{PLUGIN_FILE_NAME}}/{{PLUGIN_FILE_NAME}}_plugin.dart',
    );
  }
}

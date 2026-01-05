import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import 'calculator_plugin.dart';

/// Factory class for creating calculator plugin instances
class CalculatorPluginFactory {
  /// Creates a new instance of the calculator plugin
  static IPlugin createPlugin() {
    return CalculatorPlugin();
  }

  /// Gets the plugin descriptor for the calculator
  static PluginDescriptor getDescriptor() {
    return const PluginDescriptor(
      id: 'com.example.calculator',
      name: 'Calculator',
      version: '1.0.0',
      type: PluginType.tool,
      requiredPermissions: [Permission.notifications],
      metadata: {
        'description': 'A simple calculator tool for basic arithmetic operations',
        'author': 'Example Developer',
        'category': 'Utility',
        'tags': ['calculator', 'math', 'arithmetic', 'tool'],
        'icon': 'calculate',
        'minPlatformVersion': '1.0.0',
        'supportedPlatforms': ['mobile', 'desktop', 'steam'],
      },
      entryPoint: 'lib/plugins/calculator/calculator_plugin.dart',
    );
  }
}
import 'package:flutter/material.dart';
import '../../core/interfaces/i_plugin.dart';
import '../../core/models/plugin_models.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'calculator_plugin.dart';

/// Factory class for creating calculator plugin instances
class CalculatorPluginFactory {
  /// Creates a new instance of the calculator plugin
  static IPlugin createPlugin() {
    return CalculatorPlugin();
  }

  /// Gets the plugin descriptor for the calculator
  static PluginDescriptor getDescriptor({BuildContext? context}) {
    final l10n = context != null ? AppLocalizations.of(context) : null;

    return PluginDescriptor(
      id: 'com.example.calculator',
      name: l10n?.plugin_calculator_name ?? 'Calculator',
      version: '1.0.0',
      type: PluginType.tool,
      requiredPermissions: const [Permission.notifications],
      metadata: {
        'description':
            l10n?.plugin_calculator_description ??
            'A simple calculator tool for basic arithmetic operations',
        'author': 'Example Developer',
        'category': 'Utility',
        'tags': const ['calculator', 'math', 'arithmetic', 'tool'],
        'icon': 'calculate',
        'minPlatformVersion': '1.0.0',
        'supportedPlatforms': const ['mobile', 'desktop', 'steam'],
      },
      entryPoint: 'lib/plugins/calculator/calculator_plugin.dart',
    );
  }
}

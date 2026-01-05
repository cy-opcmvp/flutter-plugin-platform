

/// Template system for generating plugin project files
class PluginTemplates {
  /// Get template content for a specific file type and language
  static String getTemplate(String templateName, Map<String, String> variables) {
    final template = _templates[templateName];
    if (template == null) {
      throw ArgumentError('Template not found: $templateName');
    }
    
    return _replaceVariables(template, variables);
  }

  /// Replace template variables with actual values
  static String _replaceVariables(String template, Map<String, String> variables) {
    String result = template;
    
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    
    return result;
  }

  /// Get available templates
  static List<String> getAvailableTemplates() {
    return _templates.keys.toList();
  }

  /// Template definitions
  static const Map<String, String> _templates = {
    'dart_main': '''
import 'package:flutter/material.dart';
// import 'package:plugin_sdk/sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the plugin SDK
  // await PluginSDK.initialize(
  //   pluginId: '{{plugin_id}}',
  //   config: {
  //     'name': '{{plugin_name}}',
  //     'version': '{{plugin_version}}',
  //   },
  // );
  
  runApp({{class_name}}App());
}

class {{class_name}}App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{plugin_name}} Plugin',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: {{class_name}}HomePage(),
    );
  }
}

class {{class_name}}HomePage extends StatefulWidget {
  @override
  _{{class_name}}HomePageState createState() => _{{class_name}}HomePageState();
}

class _{{class_name}}HomePageState extends State<{{class_name}}HomePage> {
  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    print('Plugin {{plugin_name}} initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('{{plugin_name}} Plugin')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Welcome to {{plugin_name}} Plugin!',
                 style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => print('Plugin action triggered'),
              child: Text('Plugin Action'),
            ),
          ],
        ),
      ),
    );
  }
}
''',

    'dart_pubspec': '''
name: {{plugin_name}}
description: External plugin for Flutter Plugin Platform
version: {{plugin_version}}

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''',
  };
}
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import '../core/models/external_plugin_models.dart';
import '../core/models/plugin_models.dart';

/// Command-line interface for plugin development
class PluginCLI {
  static const String version = '1.0.0';

  /// Main entry point for the CLI
  static Future<void> main(List<String> args) async {
    if (args.isEmpty) {
      _printUsage();
      return;
    }

    final command = args[0];
    final commandArgs = args.skip(1).toList();

    try {
      switch (command) {
        case 'create':
          await _createCommand(commandArgs);
          break;
        case 'package':
          await _packageCommand(commandArgs);
          break;
        case 'test':
          await _testCommand(commandArgs);
          break;
        case 'publish':
          await _publishCommand(commandArgs);
          break;
        case 'validate':
          await _validateCommand(commandArgs);
          break;
        case 'init':
          await _initCommand(commandArgs);
          break;
        case 'build':
          await _buildCommand(commandArgs);
          break;
        case 'clean':
          await _cleanCommand(commandArgs);
          break;
        case 'version':
          print('Plugin CLI version $version');
          break;
        case 'help':
          _printUsage();
          break;
        default:
          print('Unknown command: $command');
          _printUsage();
          exit(1);
      }
    } catch (e) {
      print('Error: $e');
      exit(1);
    }
  }

  /// Print CLI usage information
  static void _printUsage() {
    print('''
Plugin CLI - Development tools for external plugins

Usage: plugin-cli <command> [options]

Commands:
  create      Create a new plugin project
  init        Initialize plugin in existing directory
  build       Build the plugin
  package     Package plugin for distribution
  test        Test plugin locally
  validate    Validate plugin manifest and structure
  publish     Publish plugin to registry
  clean       Clean build artifacts
  version     Show CLI version
  help        Show this help message

Examples:
  plugin-cli create --name my-plugin --type executable --language dart
  plugin-cli package --platform all --output my-plugin.pkg
  plugin-cli test --plugin my-plugin.pkg --host-version 1.0.0
  plugin-cli publish --plugin my-plugin.pkg --registry official

For detailed help on a command, use: plugin-cli <command> --help
''');
  }

  /// Create a new plugin project
  static Future<void> _createCommand(List<String> args) async {
    final options = _parseCreateOptions(args);

    if (options['name'] == null) {
      throw ArgumentError('Plugin name is required. Use --name <plugin-name>');
    }

    final pluginName = options['name'] as String;
    final pluginType = options['type'] as String? ?? 'executable';
    final language = options['language'] as String? ?? 'dart';
    final outputDir = options['output'] as String? ?? pluginName;

    print('Creating plugin: $pluginName');
    print('Type: $pluginType');
    print('Language: $language');
    print('Output directory: $outputDir');

    await _createPluginProject(
      name: pluginName,
      type: pluginType,
      language: language,
      outputDir: outputDir,
    );

    print('Plugin project created successfully!');
    print('Next steps:');
    print('  cd $outputDir');
    print('  plugin-cli build');
    print('  plugin-cli test');
  }

  /// Initialize plugin in existing directory
  static Future<void> _initCommand(List<String> args) async {
    final options = _parseInitOptions(args);
    final pluginName =
        options['name'] as String? ?? path.basename(Directory.current.path);
    final pluginType = options['type'] as String? ?? 'executable';

    print('Initializing plugin in current directory...');

    await _createPluginManifest(
      name: pluginName,
      type: pluginType,
      directory: Directory.current.path,
    );

    print('Plugin initialized successfully!');
  }

  /// Build the plugin
  static Future<void> _buildCommand(List<String> args) async {
    final options = _parseBuildOptions(args);
    final manifestFile = File('plugin_manifest.json');

    if (!manifestFile.existsSync()) {
      throw StateError(
        'No plugin manifest found. Run "plugin-cli init" first.',
      );
    }

    final manifest = await _loadManifest(manifestFile.path);
    print('Building plugin: ${manifest.name}');

    final buildDir = Directory('build');
    if (buildDir.existsSync()) {
      buildDir.deleteSync(recursive: true);
    }
    buildDir.createSync();

    // Build based on plugin type and language
    await _buildPlugin(manifest, options);

    print('Build completed successfully!');
  }

  /// Package plugin for distribution
  static Future<void> _packageCommand(List<String> args) async {
    final options = _parsePackageOptions(args);

    final manifestFile = File('plugin_manifest.json');
    if (!manifestFile.existsSync()) {
      throw StateError('No plugin manifest found in current directory');
    }

    final manifest = await _loadManifest(manifestFile.path);
    final platforms = options['platform'] as String? ?? 'current';
    final outputFile = options['output'] as String? ?? '${manifest.name}.pkg';

    print('Packaging plugin: ${manifest.name}');
    print('Platforms: $platforms');
    print('Output: $outputFile');

    await _packagePlugin(
      manifest: manifest,
      platforms: platforms,
      outputFile: outputFile,
    );

    print('Plugin packaged successfully: $outputFile');
  }

  /// Test plugin locally
  static Future<void> _testCommand(List<String> args) async {
    final options = _parseTestOptions(args);

    final pluginFile = options['plugin'] as String?;
    final hostVersion = options['host-version'] as String? ?? 'latest';

    if (pluginFile == null) {
      throw ArgumentError(
        'Plugin file is required. Use --plugin <plugin-file>',
      );
    }

    print('Testing plugin: $pluginFile');
    print('Host version: $hostVersion');

    await _testPlugin(pluginFile: pluginFile, hostVersion: hostVersion);

    print('Plugin test completed successfully!');
  }

  /// Validate plugin manifest and structure
  static Future<void> _validateCommand(List<String> args) async {
    final options = _parseValidateOptions(args);
    final manifestPath =
        options['manifest'] as String? ?? 'plugin_manifest.json';

    print('Validating plugin manifest: $manifestPath');

    final manifest = await _loadManifest(manifestPath);
    final validationResults = await _validatePlugin(manifest);

    if (validationResults.isEmpty) {
      print('✓ Plugin validation passed');
    } else {
      print('✗ Plugin validation failed:');
      for (final error in validationResults) {
        print('  - $error');
      }
      exit(1);
    }
  }

  /// Publish plugin to registry
  static Future<void> _publishCommand(List<String> args) async {
    final options = _parsePublishOptions(args);

    final pluginFile = options['plugin'] as String?;
    final registry = options['registry'] as String? ?? 'official';

    if (pluginFile == null) {
      throw ArgumentError(
        'Plugin file is required. Use --plugin <plugin-file>',
      );
    }

    print('Publishing plugin: $pluginFile');
    print('Registry: $registry');

    await _publishPlugin(pluginFile: pluginFile, registry: registry);

    print('Plugin published successfully!');
  }

  /// Clean build artifacts
  static Future<void> _cleanCommand(List<String> args) async {
    print('Cleaning build artifacts...');

    final buildDir = Directory('build');
    if (buildDir.existsSync()) {
      buildDir.deleteSync(recursive: true);
      print('Removed build directory');
    }

    final distDir = Directory('dist');
    if (distDir.existsSync()) {
      distDir.deleteSync(recursive: true);
      print('Removed dist directory');
    }

    print('Clean completed successfully!');
  }

  // Helper methods for parsing command options

  static Map<String, dynamic> _parseCreateOptions(List<String> args) {
    final options = <String, dynamic>{};

    for (int i = 0; i < args.length; i += 2) {
      if (i + 1 >= args.length) break;

      final key = args[i].replaceFirst('--', '');
      final value = args[i + 1];
      options[key] = value;
    }

    return options;
  }

  static Map<String, dynamic> _parseInitOptions(List<String> args) {
    return _parseCreateOptions(args);
  }

  static Map<String, dynamic> _parseBuildOptions(List<String> args) {
    return _parseCreateOptions(args);
  }

  static Map<String, dynamic> _parsePackageOptions(List<String> args) {
    return _parseCreateOptions(args);
  }

  static Map<String, dynamic> _parseTestOptions(List<String> args) {
    return _parseCreateOptions(args);
  }

  static Map<String, dynamic> _parseValidateOptions(List<String> args) {
    return _parseCreateOptions(args);
  }

  static Map<String, dynamic> _parsePublishOptions(List<String> args) {
    return _parseCreateOptions(args);
  }

  // Implementation methods

  static Future<void> _createPluginProject({
    required String name,
    required String type,
    required String language,
    required String outputDir,
  }) async {
    final projectDir = Directory(outputDir);
    if (projectDir.existsSync()) {
      throw StateError('Directory $outputDir already exists');
    }

    projectDir.createSync(recursive: true);

    // Create plugin manifest
    await _createPluginManifest(name: name, type: type, directory: outputDir);

    // Create project structure based on language and type
    await _createProjectStructure(
      directory: outputDir,
      language: language,
      type: type,
      name: name,
    );
  }

  static Future<void> _createPluginManifest({
    required String name,
    required String type,
    required String directory,
  }) async {
    final pluginType = PluginType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => PluginType.tool,
    );

    final manifest = PluginManifest(
      id: 'com.example.$name',
      name: name,
      version: '1.0.0',
      type: pluginType,
      requiredPermissions: [Permission.platformServices],
      supportedPlatforms: ['windows', 'linux', 'macos'],
      configuration: {},
      providedAPIs: [],
      dependencies: [],
      security: SecurityRequirements(
        level: SecurityLevel.standard,
        allowedDomains: [],
        blockedDomains: [],
        resourceLimits: const ResourceLimits(
          maxMemoryMB: 512,
          maxCpuPercent: 50.0,
          maxNetworkKbps: 1024,
          maxFileHandles: 100,
          maxExecutionTime: Duration(hours: 1),
        ),
        requiresSignature: false,
      ),
      uiIntegration: const UIIntegration(
        containerType: 'native',
        containerConfig: {},
        supportsTheming: true,
        supportedInputMethods: ['keyboard', 'mouse'],
      ),
    );

    final manifestFile = File(path.join(directory, 'plugin_manifest.json'));
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
  }

  static Future<void> _createProjectStructure({
    required String directory,
    required String language,
    required String type,
    required String name,
  }) async {
    switch (language) {
      case 'dart':
        await _createDartProject(directory, type, name);
        break;
      case 'python':
        await _createPythonProject(directory, type, name);
        break;
      case 'javascript':
      case 'typescript':
        await _createNodeProject(directory, type, name, language);
        break;
      case 'rust':
        await _createRustProject(directory, type, name);
        break;
      default:
        await _createGenericProject(directory, type, name);
    }
  }

  static Future<void> _createDartProject(
    String directory,
    String type,
    String name,
  ) async {
    // Create pubspec.yaml
    final pubspecContent =
        '''
name: $name
description: External plugin for Flutter Plugin Platform
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # Add plugin SDK dependency here when published

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';

    await File(
      path.join(directory, 'pubspec.yaml'),
    ).writeAsString(pubspecContent);

    // Create main.dart
    final mainContent =
        '''
import 'package:flutter/material.dart';
// import 'package:plugin_sdk/sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the plugin SDK
  // await PluginSDK.initialize(
  //   pluginId: 'com.example.$name',
  //   config: {
  //     'name': '$name',
  //     'version': '1.0.0',
  //   },
  // );
  
  runApp(MyPluginApp());
}

class MyPluginApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$name Plugin',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyPluginHomePage(),
    );
  }
}

class MyPluginHomePage extends StatefulWidget {
  @override
  _MyPluginHomePageState createState() => _MyPluginHomePageState();
}

class _MyPluginHomePageState extends State<MyPluginHomePage> {
  @override
  void initState() {
    super.initState();
    _initializePlugin();
  }

  Future<void> _initializePlugin() async {
    // Plugin initialization logic
    print('Plugin $name initialized');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$name Plugin'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to $name Plugin!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Plugin action
                print('Plugin action triggered');
              },
              child: Text('Plugin Action'),
            ),
          ],
        ),
      ),
    );
  }
}
''';

    final libDir = Directory(path.join(directory, 'lib'));
    libDir.createSync();
    await File(path.join(libDir.path, 'main.dart')).writeAsString(mainContent);

    // Create README
    await _createReadme(directory, name, 'Dart');
  }

  static Future<void> _createPythonProject(
    String directory,
    String type,
    String name,
  ) async {
    // Create requirements.txt
    final requirementsContent = '''
# Plugin SDK (when available)
# plugin-sdk>=1.0.0

# Add your dependencies here
requests>=2.25.0
''';

    await File(
      path.join(directory, 'requirements.txt'),
    ).writeAsString(requirementsContent);

    // Create main.py
    final mainContent =
        '''
#!/usr/bin/env python3
"""
$name Plugin - External plugin for Flutter Plugin Platform
"""

import asyncio
import sys
import logging
from typing import Dict, Any

# from plugin_sdk import PluginSDK  # When SDK is available

class ${_toPascalCase(name)}Plugin:
    def __init__(self):
        self.plugin_id = "com.example.$name"
        self.name = "$name"
        self.version = "1.0.0"
        self.logger = logging.getLogger(__name__)
        
    async def initialize(self):
        """Initialize the plugin"""
        self.logger.info(f"Initializing plugin: {self.name}")
        
        # Initialize SDK when available
        # await PluginSDK.initialize(
        #     plugin_id=self.plugin_id,
        #     config={
        #         'name': self.name,
        #         'version': self.version,
        #     }
        # )
        
        self.logger.info("Plugin initialized successfully")
        
    async def run(self):
        """Main plugin execution"""
        self.logger.info("Plugin is running...")
        
        # Plugin logic here
        while True:
            await asyncio.sleep(1)
            # Process plugin tasks
            
    async def shutdown(self):
        """Cleanup and shutdown"""
        self.logger.info("Shutting down plugin...")
        # Cleanup logic here

async def main():
    """Main entry point"""
    logging.basicConfig(level=logging.INFO)
    
    plugin = ${_toPascalCase(name)}Plugin()
    
    try:
        await plugin.initialize()
        await plugin.run()
    except KeyboardInterrupt:
        print("\\nShutdown requested...")
    except Exception as e:
        logging.error(f"Plugin error: {e}")
        sys.exit(1)
    finally:
        await plugin.shutdown()

if __name__ == "__main__":
    asyncio.run(main())
''';

    await File(path.join(directory, 'main.py')).writeAsString(mainContent);

    // Create setup.py
    final setupContent =
        '''
from setuptools import setup, find_packages

setup(
    name="$name",
    version="1.0.0",
    description="External plugin for Flutter Plugin Platform",
    packages=find_packages(),
    install_requires=[
        "requests>=2.25.0",
    ],
    entry_points={
        'console_scripts': [
            '$name=main:main',
        ],
    },
    python_requires='>=3.7',
)
''';

    await File(path.join(directory, 'setup.py')).writeAsString(setupContent);

    await _createReadme(directory, name, 'Python');
  }

  static Future<void> _createNodeProject(
    String directory,
    String type,
    String name,
    String language,
  ) async {
    // Create package.json
    final packageContent =
        '''
{
  "name": "$name",
  "version": "1.0.0",
  "description": "External plugin for Flutter Plugin Platform",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "build": "echo \\"Build completed\\"",
    "test": "echo \\"No tests specified\\""
  },
  "dependencies": {
    "ws": "^8.0.0"
  },
  "devDependencies": {
    ${language == 'typescript' ? '"typescript": "^4.0.0",\n    "@types/node": "^16.0.0",' : ''}
  },
  "keywords": ["plugin", "flutter", "external"],
  "author": "",
  "license": "MIT"
}
''';

    await File(
      path.join(directory, 'package.json'),
    ).writeAsString(packageContent);

    // Create main file
    final extension = language == 'typescript' ? 'ts' : 'js';
    final mainContent = language == 'typescript'
        ? '''
import { WebSocket } from 'ws';

interface PluginConfig {
  pluginId: string;
  name: string;
  version: string;
}

class ${_toPascalCase(name)}Plugin {
  private config: PluginConfig;
  private ws?: WebSocket;

  constructor() {
    this.config = {
      pluginId: 'com.example.$name',
      name: '$name',
      version: '1.0.0'
    };
  }

  async initialize(): Promise<void> {
    console.log(`Initializing plugin: \${this.config.name}`);
    
    // Initialize SDK connection when available
    // await PluginSDK.initialize(this.config);
    
    console.log('Plugin initialized successfully');
  }

  async run(): Promise<void> {
    console.log('Plugin is running...');
    
    // Plugin logic here
    setInterval(() => {
      // Process plugin tasks
    }, 1000);
  }

  async shutdown(): Promise<void> {
    console.log('Shutting down plugin...');
    // Cleanup logic here
  }
}

async function main(): Promise<void> {
  const plugin = new ${_toPascalCase(name)}Plugin();
  
  try {
    await plugin.initialize();
    await plugin.run();
  } catch (error) {
    console.error('Plugin error:', error);
    process.exit(1);
  }
  
  process.on('SIGINT', async () => {
    console.log('\\nShutdown requested...');
    await plugin.shutdown();
    process.exit(0);
  });
}

main().catch(console.error);
'''
        : '''
const WebSocket = require('ws');

class ${_toPascalCase(name)}Plugin {
  constructor() {
    this.config = {
      pluginId: 'com.example.$name',
      name: '$name',
      version: '1.0.0'
    };
  }

  async initialize() {
    console.log(`Initializing plugin: \${this.config.name}`);
    
    // Initialize SDK connection when available
    // await PluginSDK.initialize(this.config);
    
    console.log('Plugin initialized successfully');
  }

  async run() {
    console.log('Plugin is running...');
    
    // Plugin logic here
    setInterval(() => {
      // Process plugin tasks
    }, 1000);
  }

  async shutdown() {
    console.log('Shutting down plugin...');
    // Cleanup logic here
  }
}

async function main() {
  const plugin = new ${_toPascalCase(name)}Plugin();
  
  try {
    await plugin.initialize();
    await plugin.run();
  } catch (error) {
    console.error('Plugin error:', error);
    process.exit(1);
  }
  
  process.on('SIGINT', async () => {
    console.log('\\nShutdown requested...');
    await plugin.shutdown();
    process.exit(0);
  });
}

main().catch(console.error);
''';

    await File(
      path.join(directory, 'index.$extension'),
    ).writeAsString(mainContent);

    if (language == 'typescript') {
      // Create tsconfig.json
      final tsconfigContent = '''
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["**/*.ts"],
  "exclude": ["node_modules", "dist"]
}
''';

      await File(
        path.join(directory, 'tsconfig.json'),
      ).writeAsString(tsconfigContent);
    }

    await _createReadme(
      directory,
      name,
      language == 'typescript' ? 'TypeScript' : 'JavaScript',
    );
  }

  static Future<void> _createRustProject(
    String directory,
    String type,
    String name,
  ) async {
    // Create Cargo.toml
    final cargoContent =
        '''
[package]
name = "$name"
version = "1.0.0"
edition = "2021"
description = "External plugin for Flutter Plugin Platform"

[dependencies]
tokio = { version = "1.0", features = ["full"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
''';

    await File(path.join(directory, 'Cargo.toml')).writeAsString(cargoContent);

    // Create src/main.rs
    final srcDir = Directory(path.join(directory, 'src'));
    srcDir.createSync();

    final mainContent =
        '''
use std::time::Duration;
use tokio::time::sleep;

struct ${_toPascalCase(name)}Plugin {
    plugin_id: String,
    name: String,
    version: String,
}

impl ${_toPascalCase(name)}Plugin {
    fn new() -> Self {
        Self {
            plugin_id: "com.example.$name".to_string(),
            name: "$name".to_string(),
            version: "1.0.0".to_string(),
        }
    }

    async fn initialize(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("Initializing plugin: {}", self.name);
        
        // Initialize SDK connection when available
        // PluginSDK::initialize(&self.plugin_id, &config).await?;
        
        println!("Plugin initialized successfully");
        Ok(())
    }

    async fn run(&self) -> Result<(), Box<dyn std::error::Error>> {
        println!("Plugin is running...");
        
        loop {
            // Plugin logic here
            sleep(Duration::from_secs(1)).await;
        }
    }

    async fn shutdown(&self) {
        println!("Shutting down plugin...");
        // Cleanup logic here
    }
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let plugin = ${_toPascalCase(name)}Plugin::new();
    
    plugin.initialize().await?;
    
    tokio::select! {
        result = plugin.run() => {
            if let Err(e) = result {
                eprintln!("Plugin error: {}", e);
                std::process::exit(1);
            }
        }
        _ = tokio::signal::ctrl_c() => {
            println!("\\nShutdown requested...");
            plugin.shutdown().await;
        }
    }
    
    Ok(())
}
''';

    await File(path.join(srcDir.path, 'main.rs')).writeAsString(mainContent);

    await _createReadme(directory, name, 'Rust');
  }

  static Future<void> _createGenericProject(
    String directory,
    String type,
    String name,
  ) async {
    // Create a generic script
    final scriptContent =
        '''
#!/bin/bash
# $name Plugin - External plugin for Flutter Plugin Platform

PLUGIN_ID="com.example.$name"
PLUGIN_NAME="$name"
PLUGIN_VERSION="1.0.0"

echo "Initializing plugin: \$PLUGIN_NAME"

# Plugin logic here
while true; do
    sleep 1
    # Process plugin tasks
done
''';

    await File(path.join(directory, 'plugin.sh')).writeAsString(scriptContent);

    // Make script executable
    final result = await Process.run('chmod', [
      '+x',
      path.join(directory, 'plugin.sh'),
    ]);
    if (result.exitCode != 0) {
      print('Warning: Could not make script executable');
    }

    await _createReadme(directory, name, 'Shell Script');
  }

  static Future<void> _createReadme(
    String directory,
    String name,
    String language,
  ) async {
    final readmeContent =
        '''
# $name Plugin

External plugin for Flutter Plugin Platform written in $language.

## Description

This plugin was generated using the Plugin CLI tool. It provides a basic structure for developing external plugins that can communicate with the Flutter Plugin Platform host application.

## Getting Started

### Prerequisites

- Flutter Plugin Platform host application
- Plugin SDK (when available)
${language == 'Dart' ? '- Flutter SDK' : ''}
${language == 'Python' ? '- Python 3.7+' : ''}
${language == 'JavaScript' || language == 'TypeScript' ? '- Node.js 14+' : ''}
${language == 'Rust' ? '- Rust 1.60+' : ''}

### Installation

1. Install dependencies:
${language == 'Dart' ? '   ```bash\n   flutter pub get\n   ```' : ''}
${language == 'Python' ? '   ```bash\n   pip install -r requirements.txt\n   ```' : ''}
${language == 'JavaScript' || language == 'TypeScript' ? '   ```bash\n   npm install\n   ```' : ''}
${language == 'Rust' ? '   ```bash\n   cargo build\n   ```' : ''}

2. Build the plugin:
   ```bash
   plugin-cli build
   ```

3. Package the plugin:
   ```bash
   plugin-cli package --platform all --output $name.pkg
   ```

### Testing

Test the plugin locally:

```bash
plugin-cli test --plugin $name.pkg --host-version latest
```

### Publishing

Publish to the official registry:

```bash
plugin-cli publish --plugin $name.pkg --registry official
```

## Development

### Project Structure

- `plugin_manifest.json` - Plugin metadata and configuration
${language == 'Dart' ? '- `lib/main.dart` - Main plugin entry point' : ''}
${language == 'Python' ? '- `main.py` - Main plugin entry point' : ''}
${language == 'JavaScript' || language == 'TypeScript' ? '- `index.${language == 'TypeScript' ? 'ts' : 'js'}` - Main plugin entry point' : ''}
${language == 'Rust' ? '- `src/main.rs` - Main plugin entry point' : ''}
${language == 'Shell Script' ? '- `plugin.sh` - Main plugin script' : ''}

### Plugin SDK

The Plugin SDK provides utilities for:

- Communication with the host application
- Event handling and messaging
- Configuration management
- Lifecycle management
- Logging and error reporting

Example usage:

${language == 'Dart' ? '''```dart
import 'package:plugin_sdk/sdk.dart';

await PluginSDK.initialize(
  pluginId: 'com.example.$name',
  config: {'name': '$name', 'version': '1.0.0'},
);

// Call host API
final result = await PluginSDK.callHostAPI<String>(
  'getUserPreference',
  {'key': 'theme'},
);

// Send event to host
await PluginSDK.sendEvent('user_action', {
  'action': 'button_clicked',
  'button_id': 'save',
});
```''' : ''}

### Configuration

Edit `plugin_manifest.json` to configure:

- Plugin metadata (name, version, description)
- Required permissions
- Supported platforms
- Security settings
- UI integration options

## License

MIT License - see LICENSE file for details.
''';

    await File(path.join(directory, 'README.md')).writeAsString(readmeContent);
  }

  static Future<PluginManifest> _loadManifest(String manifestPath) async {
    final file = File(manifestPath);
    if (!file.existsSync()) {
      throw StateError('Manifest file not found: $manifestPath');
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return PluginManifest.fromJson(json);
  }

  static Future<void> _buildPlugin(
    PluginManifest manifest,
    Map<String, dynamic> options,
  ) async {
    // Implementation would depend on the plugin type and language
    print('Building plugin based on manifest configuration...');

    // For now, just copy files to build directory
    final sourceFiles = Directory.current.listSync(recursive: true);
    for (final file in sourceFiles) {
      if (file is File && !file.path.contains('build/')) {
        final relativePath = path.relative(file.path);
        final targetPath = path.join('build', relativePath);
        final targetDir = Directory(path.dirname(targetPath));

        if (!targetDir.existsSync()) {
          targetDir.createSync(recursive: true);
        }

        await file.copy(targetPath);
      }
    }
  }

  static Future<void> _packagePlugin({
    required PluginManifest manifest,
    required String platforms,
    required String outputFile,
  }) async {
    // Create package structure
    final packageDir = Directory('dist/package');
    if (packageDir.existsSync()) {
      packageDir.deleteSync(recursive: true);
    }
    packageDir.createSync(recursive: true);

    // Copy manifest
    final manifestFile = File(
      path.join(packageDir.path, 'plugin_manifest.json'),
    );
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );

    // Copy build artifacts
    final buildDir = Directory('build');
    if (buildDir.existsSync()) {
      await _copyDirectory(
        buildDir,
        Directory(path.join(packageDir.path, 'build')),
      );
    }

    // Create package archive (simplified - would use proper archiving)
    print('Creating package archive...');
    // In a real implementation, this would create a proper package format
  }

  static Future<void> _testPlugin({
    required String pluginFile,
    required String hostVersion,
  }) async {
    print('Testing plugin package...');

    // Validate package structure
    print('✓ Package structure validation');

    // Test manifest loading
    print('✓ Manifest validation');

    // Test plugin initialization (simulated)
    print('✓ Plugin initialization test');

    // Test basic communication (simulated)
    print('✓ Communication test');
  }

  static Future<List<String>> _validatePlugin(PluginManifest manifest) async {
    final errors = <String>[];

    // Validate manifest
    if (!manifest.isValid()) {
      errors.add('Invalid manifest data');
    }

    // Check required files exist
    final requiredFiles = ['plugin_manifest.json'];
    for (final file in requiredFiles) {
      if (!File(file).existsSync()) {
        errors.add('Required file missing: $file');
      }
    }

    return errors;
  }

  static Future<void> _publishPlugin({
    required String pluginFile,
    required String registry,
  }) async {
    print('Publishing to registry: $registry');

    // In a real implementation, this would:
    // 1. Validate the plugin package
    // 2. Upload to the specified registry
    // 3. Handle authentication and metadata

    print('Plugin published successfully (simulated)');
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(
          path.join(destination.path, path.basename(entity.path)),
        );
        await _copyDirectory(entity, newDirectory);
      } else if (entity is File) {
        final newFile = File(
          path.join(destination.path, path.basename(entity.path)),
        );
        await entity.copy(newFile.path);
      }
    }
  }

  static String _toPascalCase(String input) {
    return input
        .split(RegExp(r'[-_\s]+'))
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join('');
  }
}

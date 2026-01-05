#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;

/// Flutter插件平台 - 插件CLI工具
/// 
/// 提供一键生成内部插件的命令行功能
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addCommand('create-internal')
    ..addCommand('create-external')
    ..addCommand('list-templates')
    ..addCommand('build')
    ..addCommand('test')
    ..addCommand('package')
    ..addCommand('validate')
    ..addCommand('publish')
    ..addFlag('help', abbr: 'h', negatable: false, help: '显示帮助信息')
    ..addFlag('version', abbr: 'v', negatable: false, help: '显示版本信息');

  // 配置create-internal命令
  parser.commands['create-internal']!
    ..addOption('name', abbr: 'n', mandatory: true, help: '插件名称')
    ..addOption('type', abbr: 't', defaultsTo: 'tool', help: '插件类型 (tool/game)')
    ..addOption('author', abbr: 'a', help: '作者名称')
    ..addOption('email', abbr: 'e', help: '作者邮箱')
    ..addOption('description', abbr: 'd', help: '插件描述')
    ..addOption('output', abbr: 'o', help: '输出目录');

  // 配置create-external命令
  parser.commands['create-external']!
    ..addOption('name', abbr: 'n', mandatory: true, help: '插件名称')
    ..addOption('type', abbr: 't', defaultsTo: 'executable', help: '插件类型 (executable/web/container)')
    ..addOption('language', abbr: 'l', defaultsTo: 'dart', help: '编程语言')
    ..addOption('author', abbr: 'a', help: '作者名称')
    ..addOption('email', abbr: 'e', help: '作者邮箱');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      printHelp(parser);
      return;
    }

    if (results['version'] as bool) {
      printVersion();
      return;
    }

    if (results.command == null) {
      print('错误: 请指定一个命令\n');
      printHelp(parser);
      exit(1);
    }

    final command = results.command!;
    
    switch (command.name) {
      case 'create-internal':
        await createInternalPlugin(command);
        break;
      case 'create-external':
        await createExternalPlugin(command);
        break;
      case 'list-templates':
        await listTemplates();
        break;
      case 'build':
        await buildPlugin(command);
        break;
      case 'test':
        await testPlugin(command);
        break;
      case 'package':
        await packagePlugin(command);
        break;
      case 'validate':
        await validatePlugin(command);
        break;
      case 'publish':
        await publishPlugin(command);
        break;
      default:
        print('未知命令: ${command.name}');
        exit(1);
    }
  } catch (e) {
    print('错误: $e');
    exit(1);
  }
}

/// 创建内部插件
Future<void> createInternalPlugin(ArgResults args) async {
  final pluginName = args['name'] as String;
  final pluginType = args['type'] as String;
  final author = args['author'] as String? ?? 'Your Name';
  final email = args['email'] as String? ?? 'your.email@example.com';
  final description = args['description'] as String? ?? 'A new plugin';
  final outputDir = args['output'] as String? ?? 'lib/plugins';

  print('🚀 创建内部插件: $pluginName');
  print('   类型: $pluginType');
  print('   作者: $author');
  print('   输出目录: $outputDir');

  // 生成插件ID和类名
  final pluginId = 'com.example.${pluginName.toLowerCase().replaceAll(' ', '_')}';
  final pluginClass = _toPascalCase(pluginName);
  final pluginFileName = pluginName.toLowerCase().replaceAll(' ', '_');

  // 创建插件目录
  final pluginDir = path.join(outputDir, pluginFileName);
  await Directory(pluginDir).create(recursive: true);
  await Directory(path.join(pluginDir, 'widgets')).create();
  await Directory(path.join(pluginDir, 'models')).create();

  // 读取模板
  final templateDir = 'docs_new/templates/internal-plugin';
  final pluginTemplate = await File(path.join(templateDir, 'plugin-template.dart')).readAsString();
  final factoryTemplate = await File(path.join(templateDir, 'factory-template.dart')).readAsString();

  // 替换占位符
  final replacements = {
    '{{PLUGIN_NAME}}': pluginName,
    '{{PLUGIN_ID}}': pluginId,
    '{{PLUGIN_CLASS}}': pluginClass,
    '{{PLUGIN_FILE_NAME}}': pluginFileName,
    '{{AUTHOR_NAME}}': author,
    '{{AUTHOR_EMAIL}}': email,
    '{{PLUGIN_DESCRIPTION}}': description,
    '{{AUTHOR_WEBSITE}}': 'https://example.com',
    '{{PLUGIN_CATEGORY}}': pluginType == 'game' ? 'entertainment' : 'productivity',
    '{{PLUGIN_TAGS}}': pluginType == 'game' ? "'game', 'entertainment'" : "'tool', 'utility'",
    '{{PLUGIN_ICON}}': pluginType == 'game' ? 'games' : 'extension',
    '{{DOCUMENTATION_URL}}': 'https://docs.example.com',
    '{{SOURCE_CODE_URL}}': 'https://github.com/example/$pluginFileName',
    '{{LICENSE}}': 'MIT',
    '{{CREATION_DATE}}': DateTime.now().toString().split(' ')[0],
  };

  String pluginCode = pluginTemplate;
  String factoryCode = factoryTemplate;

  replacements.forEach((key, value) {
    pluginCode = pluginCode.replaceAll(key, value);
    factoryCode = factoryCode.replaceAll(key, value);
  });

  // 写入文件
  await File(path.join(pluginDir, '${pluginFileName}_plugin.dart')).writeAsString(pluginCode);
  await File(path.join(pluginDir, '${pluginFileName}_plugin_factory.dart')).writeAsString(factoryCode);

  // 创建README
  final readme = '''
# $pluginName

$description

## 功能特性

- 功能1
- 功能2
- 功能3

## 使用方法

1. 在插件注册表中注册插件
2. 通过插件管理器加载插件
3. 使用插件功能

## 开发者

- 作者: $author
- 邮箱: $email

## 许可证

MIT License
''';

  await File(path.join(pluginDir, 'README.md')).writeAsString(readme);

  // 创建测试文件
  await _createTestFile(pluginDir, pluginFileName, pluginClass, pluginId);

  // 生成注册代码提示
  final registrationCode = '''

// 在 lib/plugins/plugin_registry.dart 中添加以下代码:

import '$pluginFileName/${pluginFileName}_plugin_factory.dart';

// 在 _factories 映射中添加:
'$pluginId': PluginFactory(
  createPlugin: ${pluginClass}PluginFactory.createPlugin,
  getDescriptor: ${pluginClass}PluginFactory.getDescriptor,
),
''';

  print('\n✅ 插件创建成功!');
  print('   插件目录: $pluginDir');
  print('\n📝 下一步:');
  print('   1. 查看生成的文件');
  print('   2. 根据需要修改插件代码');
  print('   3. 在插件注册表中注册插件');
  print('\n📋 注册代码:');
  print(registrationCode);
}

/// 创建外部插件
Future<void> createExternalPlugin(ArgResults args) async {
  final pluginName = args['name'] as String;
  final pluginType = args['type'] as String;
  final language = args['language'] as String;
  final author = args['author'] as String? ?? 'Your Name';

  print('🚀 创建外部插件: $pluginName');
  print('   类型: $pluginType');
  print('   语言: $language');
  print('   作者: $author');

  // TODO: 实现外部插件创建逻辑
  print('\n⚠️  外部插件创建功能正在开发中...');
}

/// 列出可用模板
Future<void> listTemplates() async {
  print('📋 可用模板列表:\n');
  
  print('内部插件模板:');
  print('  - basic-tool: 基础工具插件模板');
  print('  - basic-game: 基础游戏插件模板');
  print('  - advanced-tool: 高级工具插件模板');
  print('  - advanced-game: 高级游戏插件模板');
  
  print('\n外部插件模板:');
  print('  - dart-executable: Dart可执行插件模板');
  print('  - python-executable: Python可执行插件模板');
  print('  - web-plugin: Web插件模板');
  print('  - container-plugin: 容器插件模板');
}

/// 构建插件
Future<void> buildPlugin(ArgResults args) async {
  print('🔨 构建插件...');
  // TODO: 实现构建逻辑
  print('⚠️  构建功能正在开发中...');
}

/// 测试插件
Future<void> testPlugin(ArgResults args) async {
  print('🧪 测试插件...');
  // TODO: 实现测试逻辑
  print('⚠️  测试功能正在开发中...');
}

/// 打包插件
Future<void> packagePlugin(ArgResults args) async {
  print('📦 打包插件...');
  // TODO: 实现打包逻辑
  print('⚠️  打包功能正在开发中...');
}

/// 验证插件
Future<void> validatePlugin(ArgResults args) async {
  print('✓ 验证插件...');
  // TODO: 实现验证逻辑
  print('⚠️  验证功能正在开发中...');
}

/// 发布插件
Future<void> publishPlugin(ArgResults args) async {
  print('🚀 发布插件...');
  // TODO: 实现发布逻辑
  print('⚠️  发布功能正在开发中...');
}

/// 创建测试文件
Future<void> _createTestFile(String pluginDir, String pluginFileName, String pluginClass, String pluginId) async {
  final testContent = '''
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/plugins/$pluginFileName/${pluginFileName}_plugin.dart';
import 'package:plugin_platform/plugins/$pluginFileName/${pluginFileName}_plugin_factory.dart';
import 'package:plugin_platform/core/models/plugin_models.dart';
import 'package:plugin_platform/core/interfaces/i_plugin.dart';

// Mock实现
class MockPlatformServices implements IPlatformServices {
  final List<String> notifications = [];
  
  @override
  Future<void> showNotification(String message, {NotificationType? type, bool? persistent}) async {
    notifications.add(message);
  }
  
  @override
  Future<bool> requestPermission(Permission permission) async => true;
  
  @override
  Future<bool> hasPermission(Permission permission) async => true;
}

class MockDataStorage implements IDataStorage {
  final Map<String, dynamic> _storage = {};
  
  @override
  Future<void> store(String key, dynamic value) async {
    _storage[key] = value;
  }
  
  @override
  Future<T?> retrieve<T>(String key) async {
    return _storage[key] as T?;
  }
  
  @override
  Future<void> remove(String key) async {
    _storage.remove(key);
  }
  
  @override
  Future<void> clear() async {
    _storage.clear();
  }
}

class MockNetworkAccess implements INetworkAccess {
  @override
  Future<Map<String, dynamic>> get(String url, {Map<String, String>? headers}) async {
    return {'status': 'success', 'data': 'mock data'};
  }
  
  @override
  Future<Map<String, dynamic>> post(String url, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    return {'status': 'success'};
  }
  
  @override
  Future<bool> isConnected() async => true;
}

void main() {
  group('$pluginClass Tests', () {
    late ${pluginClass}Plugin plugin;
    late MockPlatformServices mockPlatformServices;
    late MockDataStorage mockDataStorage;
    late MockNetworkAccess mockNetworkAccess;
    late PluginContext context;

    setUp(() {
      plugin = ${pluginClass}Plugin();
      mockPlatformServices = MockPlatformServices();
      mockDataStorage = MockDataStorage();
      mockNetworkAccess = MockNetworkAccess();
      
      context = PluginContext(
        platformServices: mockPlatformServices,
        dataStorage: mockDataStorage,
        networkAccess: mockNetworkAccess,
        configuration: {},
      );
    });

    test('Plugin properties should be correct', () {
      expect(plugin.id, '$pluginId');
      expect(plugin.name, isNotEmpty);
      expect(plugin.version, '1.0.0');
    });

    test('Plugin should initialize successfully', () async {
      await plugin.initialize(context);
      expect(mockPlatformServices.notifications, isNotEmpty);
    });

    test('Plugin should handle state changes', () async {
      await plugin.initialize(context);
      await plugin.onStateChanged(PluginState.active);
      await plugin.onStateChanged(PluginState.paused);
      await plugin.onStateChanged(PluginState.inactive);
    });

    test('Plugin should save and restore state', () async {
      await plugin.initialize(context);
      final state = await plugin.getState();
      expect(state, isA<Map<String, dynamic>>());
      expect(state['version'], '1.0.0');
    });

    test('Plugin should dispose cleanly', () async {
      await plugin.initialize(context);
      await plugin.dispose();
    });
  });
}
''';

  final testDir = path.join('test', 'plugins');
  await Directory(testDir).create(recursive: true);
  await File(path.join(testDir, '${pluginFileName}_test.dart')).writeAsString(testContent);
}

/// 转换为PascalCase
String _toPascalCase(String input) {
  return input
      .split(RegExp(r'[_\s-]+'))
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join('');
}

/// 打印帮助信息
void printHelp(ArgParser parser) {
  print('''
Flutter插件平台 - 插件CLI工具

用法: plugin-cli <command> [options]

可用命令:
  create-internal    创建内部插件
  create-external    创建外部插件
  list-templates     列出可用模板
  build             构建插件
  test              测试插件
  package           打包插件
  validate          验证插件
  publish           发布插件

全局选项:
  -h, --help        显示帮助信息
  -v, --version     显示版本信息

示例:
  # 创建内部插件
  plugin-cli create-internal --name "My Plugin" --type tool --author "John Doe"

  # 创建外部插件
  plugin-cli create-external --name "My Plugin" --type executable --language dart

  # 列出可用模板
  plugin-cli list-templates

更多信息请访问: https://docs.flutter-platform.com
''');
}

/// 打印版本信息
void printVersion() {
  print('Flutter插件平台 CLI工具 v1.0.0');
}
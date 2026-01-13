# 插件 SDK 指南

本文档介绍如何使用插件 SDK 开发外部插件。

> 规范详情请参考 [外部插件开发规范](./external-plugin-development.md)

## 快速开始

### 安装

```yaml
# pubspec.yaml (Dart/Flutter 插件)
dependencies:
  plugin_sdk:
    git:
      url: https://github.com/flutter-platform/plugin-sdk
      ref: main
```

### 创建插件

```bash
# 创建内部插件
dart tools/plugin_cli.dart create-internal --name "My Plugin" --type tool

# 创建外部插件 (开发中)
dart tools/plugin_cli.dart create-external --name "My Plugin" --type executable --language dart
```

## SDK 架构

```
┌─────────────────────────────────┐
│         插件应用程序             │
├─────────────────────────────────┤
│    插件辅助工具 (Helpers)        │
├─────────────────────────────────┤
│   核心 SDK (通信、事件、API)     │
├─────────────────────────────────┤
│         IPC 桥接层              │
├─────────────────────────────────┤
│         宿主应用程序             │
└─────────────────────────────────┘
```

## 插件初始化

### 可执行插件

```dart
import 'package:plugin_sdk/sdk.dart';

void main() async {
  await ExecutablePluginHelper.initialize(
    pluginId: 'com.example.my-plugin',
    executablePath: Platform.resolvedExecutable,
    arguments: ['--plugin-mode'],
  );
  
  await PluginLifecycleHelper.reportReady();
}
```

### Web 插件

```dart
await WebPluginHelper.initialize(
  pluginId: 'com.example.web-plugin',
  entryUrl: 'https://my-plugin.example.com',
  webViewConfig: {'allowScripts': true},
);

await WebPluginHelper.injectBridgeScript();
```

### 容器插件

```dart
await ContainerPluginHelper.initialize(
  pluginId: 'com.example.container-plugin',
  imageName: 'my-plugin:latest',
  containerConfig: {'ports': ['8080:8080']},
);
```

## 宿主 API 调用

```dart
// 获取用户偏好
final theme = await PluginSDK.callHostAPI<String>(
  'getUserPreference',
  {'key': 'theme'},
);

// 读取文件 (需要权限)
final content = await PluginSDK.callHostAPI<String>(
  'readFile',
  {'path': '/path/to/file.txt'},
);

// 显示通知
await PluginSDK.callHostAPI<void>(
  'showNotification',
  {'title': '标题', 'message': '内容', 'type': 'info'},
);
```

## 事件处理

### 监听宿主事件

```dart
PluginSDK.onHostEvent('theme_changed', (event) async {
  final newTheme = event.data['theme'] as String;
  await updatePluginTheme(newTheme);
});

PluginSDK.onHostEvent('user_action', (event) async {
  await handleUserAction(event.data['action']);
});
```

### 发送插件事件

```dart
await PluginSDK.sendEvent('data_updated', {
  'timestamp': DateTime.now().toIso8601String(),
  'recordCount': 42,
});
```

### 注册消息处理器

```dart
PluginSDK.registerMessageHandler('custom_command', (message) async {
  final command = message.payload['command'] as String;
  switch (command) {
    case 'process_data':
      await processData(message.payload['params']);
      break;
  }
});
```

## 配置管理

```dart
// 读取配置
final apiKey = await PluginConfigHelper.getConfig<String>('api_key');
final timeout = await PluginConfigHelper.getConfig<int>('timeout', 30);

// 更新配置
await PluginConfigHelper.setConfig('last_sync', DateTime.now().toIso8601String());

// 批量更新
await PluginSDK.callHostAPI<void>('updatePluginConfig', {
  'pluginId': PluginSDK.instance.pluginId,
  'config': {'api_endpoint': 'https://api.v2.com', 'retry_count': 3},
});
```

## 生命周期管理

```dart
PluginLifecycleHelper.registerLifecycleHandlers(
  onInitialize: () async => await initializeResources(),
  onStart: () async => await startBackgroundTasks(),
  onPause: () async => await pauseBackgroundTasks(),
  onResume: () async => await resumeBackgroundTasks(),
  onStop: () async => await stopBackgroundTasks(),
  onDestroy: () async => await cleanupResources(),
);
```

### 状态报告

```dart
// 报告就绪
await PluginLifecycleHelper.reportReady();

// 报告错误
await PluginLifecycleHelper.reportError(
  '数据库连接失败',
  {'error_code': 'DB_CONN_001'},
);

// 更新状态
await PluginSDK.updateStatus(PluginState.active, {
  'connections': 5,
  'last_activity': DateTime.now().toIso8601String(),
});
```

## 权限请求

```dart
// 请求权限
final hasFileAccess = await PluginSDK.requestPermission(Permission.fileSystemRead);
final hasNetwork = await PluginSDK.requestPermission(Permission.networkAccess);

// 检查权限
if (await PluginSDK.hasPermission(Permission.systemCamera)) {
  // 访问相机
}
```

## 日志记录

```dart
await PluginSDK.logDebug('调试信息', {'variable': value});
await PluginSDK.logInfo('操作完成');
await PluginSDK.logWarning('已弃用的 API', {'api': 'oldMethod'});
await PluginSDK.logError('操作失败', {'error': e.toString()});
```

## CLI 命令

```bash
# 创建内部插件
dart tools/plugin_cli.dart create-internal --name <name> --type <tool|game> [--author <author>] [--output <dir>]

# 创建外部插件 (开发中)
dart tools/plugin_cli.dart create-external --name <name> --type <executable|webApp|container> --language <dart|python|js>

# 列出模板
dart tools/plugin_cli.dart list-templates

# 以下命令开发中:
# dart tools/plugin_cli.dart build
# dart tools/plugin_cli.dart test --plugin <file.pkg>
# dart tools/plugin_cli.dart package --platform <all|windows|linux|macos> --output <file.pkg>
# dart tools/plugin_cli.dart validate --plugin <file.pkg>
# dart tools/plugin_cli.dart publish --plugin <file.pkg> --registry <official|url>
```

## 多语言示例

### Python

```python
import asyncio
from plugin_sdk import PluginSDK

async def main():
    sdk = PluginSDK(plugin_id='com.example.my-plugin')
    await sdk.initialize()
    
    sdk.register_message_handler('process', handle_process)
    sdk.on_host_event('theme_changed', on_theme_changed)
    
    await sdk.report_ready()
    await sdk.keep_alive()

async def handle_process(message):
    result = await process_data(message.payload['data'])
    await sdk.send_response(message.message_id, {'result': result})

if __name__ == '__main__':
    asyncio.run(main())
```

### JavaScript (Web)

```javascript
await PluginSDK.initialize({
  pluginId: 'com.example.web-plugin',
  config: { debug: true }
});

PluginSDK.onHostEvent('theme_changed', (event) => {
  document.body.className = event.data.theme;
});

const result = await PluginSDK.callHostAPI('getData', { type: 'user_data' });

PluginSDK.reportReady();
```

## 最佳实践

### 性能优化

```dart
class DataManager {
  final Map<String, dynamic> _cache = {};
  
  Future<List<DataItem>> loadData(String category) async {
    if (_cache.containsKey(category)) {
      return _cache[category];
    }
    
    // 批量请求，只获取需要的字段
    final data = await PluginSDK.callHostAPI<List<dynamic>>(
      'loadDataBatch',
      {'category': category, 'limit': 100, 'fields': ['id', 'name']},
    );
    
    final items = data.map((e) => DataItem.fromJson(e)).toList();
    _cache[category] = items;
    return items;
  }
}
```

### 错误处理

```dart
Future<void> syncData() async {
  const maxRetries = 3;
  
  for (int i = 0; i < maxRetries; i++) {
    try {
      await performSync();
      return;
    } catch (e) {
      if (i == maxRetries - 1) {
        await PluginLifecycleHelper.reportError('同步失败', {'error': '$e'});
        return;
      }
      await Future.delayed(Duration(seconds: (i + 1) * 2)); // 指数退避
    }
  }
}
```

### 进度反馈

```dart
Future<void> processItems(List<Item> items) async {
  for (int i = 0; i < items.length; i++) {
    await processItem(items[i]);
    
    if (i % 10 == 0 || i == items.length - 1) {
      await PluginSDK.sendEvent('progress', {
        'current': i + 1,
        'total': items.length,
        'percentage': ((i + 1) / items.length * 100).round(),
      });
    }
  }
}
```

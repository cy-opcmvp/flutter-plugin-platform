# 插件 SDK 开发者指南

插件 SDK 提供了一个全面的框架，用于开发与 Flutter 插件平台无缝集成的外部插件。本指南涵盖了创建、测试和分发外部插件所需的所有知识。

## 目录

1. [入门指南](#入门指南)
2. [SDK 架构](#sdk-架构)
3. [插件类型](#插件类型)
4. [通信系统](#通信系统)
5. [配置管理](#配置管理)
6. [生命周期管理](#生命周期管理)
7. [安全与权限](#安全与权限)
8. [测试与调试](#测试与调试)
9. [分发与发布](#分发与发布)
10. [最佳实践](#最佳实践)

## 入门指南

### 前置要求

- Flutter 插件平台宿主应用程序 (v1.0.0+)
- 您所选语言的开发环境
- 插件 CLI 工具（包含在 SDK 中）

### 安装

将插件 SDK 添加到您的项目中：

```yaml
# pubspec.yaml (用于 Dart/Flutter 插件)
dependencies:
  plugin_sdk:
    git:
      url: https://github.com/flutter-platform/plugin-sdk
      ref: main
```

### 快速开始

通过 3 个步骤创建您的第一个插件：

```bash
# 1. 创建新的插件项目
plugin-cli create --name hello-world --type executable --language dart

# 2. 构建插件
cd hello-world
plugin-cli build

# 3. 本地测试
plugin-cli test --plugin hello-world.pkg
```

## SDK 架构

插件 SDK 遵循分层架构：

```
┌─────────────────────────────────────┐
│           插件应用程序               │
├─────────────────────────────────────┤
│         插件辅助工具                 │
│  (可执行文件、Web、容器)             │
├─────────────────────────────────────┤
│           核心 SDK                  │
│    (通信、事件、API)                 │
├─────────────────────────────────────┤
│          IPC 桥接                   │
│   (命名管道、WebSocket、HTTP)        │
├─────────────────────────────────────┤
│        宿主应用程序                  │
└─────────────────────────────────────┘
```

### 核心组件

- **PluginSDK**：用于初始化和通信的主 SDK 接口
- **插件辅助工具**：针对不同插件类型的特定工具
- **IPC 桥接**：进程间通信层
- **配置管理器**：插件设置和首选项
- **生命周期管理器**：插件状态和生命周期事件

## 插件类型

SDK 支持多种插件类型，每种都有特定的功能：

### 可执行插件

作为独立进程运行的原生可执行文件：

```dart
import 'package:plugin_sdk/sdk.dart';

void main() async {
  await ExecutablePluginHelper.initialize(
    pluginId: 'com.example.my-plugin',
    executablePath: Platform.resolvedExecutable,
    arguments: ['--plugin-mode'],
  );
  
  // 插件逻辑在这里
  await PluginLifecycleHelper.reportReady();
}
```

### Web 插件

在沙盒化 WebView 容器中运行的 Web 应用程序：

```dart
import 'package:plugin_sdk/sdk.dart';

void main() async {
  await WebPluginHelper.initialize(
    pluginId: 'com.example.web-plugin',
    entryUrl: 'https://my-plugin.example.com',
    webViewConfig: {
      'allowScripts': true,
      'allowForms': true,
    },
  );
  
  // 注入通信桥接脚本
  await WebPluginHelper.injectBridgeScript();
}
```

### 容器插件

容器化应用程序（Docker 等）：

```dart
import 'package:plugin_sdk/sdk.dart';

void main() async {
  await ContainerPluginHelper.initialize(
    pluginId: 'com.example.container-plugin',
    imageName: 'my-plugin:latest',
    containerConfig: {
      'ports': ['8080:8080'],
      'volumes': ['/data:/app/data'],
    },
  );
  
  // 健康检查实现
  PluginSDK.onHostEvent('health_check', (event) async {
    final status = await ContainerPluginHelper.performHealthCheck();
    await PluginSDK.sendEvent('health_check_response', status);
  });
}
```

## 通信系统

### 宿主 API 调用

从您的插件调用宿主应用程序 API：

```dart
// 获取用户偏好设置
final theme = await PluginSDK.callHostAPI<String>(
  'getUserPreference',
  {'key': 'theme'},
);

// 访问文件系统（需要权限）
final fileContent = await PluginSDK.callHostAPI<String>(
  'readFile',
  {'path': '/path/to/file.txt'},
);

// 显示通知
await PluginSDK.callHostAPI<void>(
  'showNotification',
  {
    'title': '插件通知',
    'message': '来自插件的问候！',
    'type': 'info',
  },
);
```

### 事件处理

监听宿主事件并发送插件事件：

```dart
// 监听主题变化
PluginSDK.onHostEvent('theme_changed', (event) async {
  final newTheme = event.data['theme'] as String;
  await updatePluginTheme(newTheme);
});

// 监听用户操作
PluginSDK.onHostEvent('user_action', (event) async {
  final action = event.data['action'] as String;
  await handleUserAction(action);
});

// 发送插件事件
await PluginSDK.sendEvent('data_updated', {
  'timestamp': DateTime.now().toIso8601String(),
  'recordCount': 42,
});

await PluginSDK.sendEvent('user_interaction', {
  'type': 'button_click',
  'elementId': 'save-button',
});
```

### 消息处理

注册自定义消息处理器：

```dart
// 为自定义消息注册处理器
PluginSDK.registerMessageHandler('custom_command', (message) async {
  final command = message.payload['command'] as String;
  final params = message.payload['params'] as Map<String, dynamic>;
  
  switch (command) {
    case 'process_data':
      await processData(params);
      break;
    case 'export_results':
      await exportResults(params);
      break;
  }
});
```

## 配置管理

### 读取配置

```dart
// 获取类型化的配置值
final apiKey = await PluginConfigHelper.getConfig<String>('api_key');
final timeout = await PluginConfigHelper.getConfig<int>('timeout', 30);
final enableLogging = await PluginConfigHelper.getConfig<bool>('enable_logging', false);

// 获取所有配置
final allConfig = await PluginSDK.getPluginConfig();
```

### 更新配置

```dart
// 设置单个值
await PluginConfigHelper.setConfig('last_sync', DateTime.now().toIso8601String());
await PluginConfigHelper.setConfig('user_count', 150);

// 批量更新
await PluginSDK.callHostAPI<void>('updatePluginConfig', {
  'pluginId': PluginSDK.instance.pluginId,
  'config': {
    'api_endpoint': 'https://api.example.com/v2',
    'retry_count': 3,
    'cache_enabled': true,
  },
});
```

## 生命周期管理

### 生命周期事件

处理插件生命周期事件：

```dart
PluginLifecycleHelper.registerLifecycleHandlers(
  onInitialize: () async {
    print('插件正在初始化...');
    await initializeResources();
  },
  
  onStart: () async {
    print('插件正在启动...');
    await startBackgroundTasks();
  },
  
  onPause: () async {
    print('插件正在暂停...');
    await pauseBackgroundTasks();
  },
  
  onResume: () async {
    print('插件正在恢复...');
    await resumeBackgroundTasks();
  },
  
  onStop: () async {
    print('插件正在停止...');
    await stopBackgroundTasks();
  },
  
  onDestroy: () async {
    print('插件正在销毁...');
    await cleanupResources();
  },
);
```

### 状态报告

向宿主报告插件状态：

```dart
// 报告就绪状态
await PluginLifecycleHelper.reportReady();

// 报告错误
await PluginLifecycleHelper.reportError(
  '数据库连接失败',
  {'error_code': 'DB_CONN_001', 'retry_count': 3},
);

// 使用自定义数据更新状态
await PluginSDK.updateStatus(PluginState.active, {
  'connections': 5,
  'last_activity': DateTime.now().toIso8601String(),
});
```

## 安全与权限

### 请求权限

```dart
// 请求特定权限
final hasFileAccess = await PluginSDK.requestPermission(
  Permission.fileSystemRead,
);

final hasNetworkAccess = await PluginSDK.requestPermission(
  Permission.networkAccess,
);

// 检查现有权限
final canAccessCamera = await PluginSDK.hasPermission(
  Permission.systemCamera,
);

if (canAccessCamera) {
  // 访问相机功能
}
```

### 安全最佳实践

1. **最小权限**：仅请求您实际需要的权限
2. **输入验证**：始终验证来自宿主的数据
3. **安全通信**：对敏感数据使用加密通道
4. **错误处理**：不要向宿主暴露内部错误
5. **资源限制**：遵守内存和 CPU 限制

```dart
// 示例：安全数据处理
Future<void> processUserData(Map<String, dynamic> data) async {
  // 验证输入
  if (!isValidUserData(data)) {
    await PluginSDK.logError('收到无效的用户数据');
    return;
  }
  
  try {
    // 安全地处理数据
    final result = await secureDataProcessor.process(data);
    
    // 发送结果而不暴露内部信息
    await PluginSDK.sendEvent('data_processed', {
      'success': true,
      'recordCount': result.length,
    });
  } catch (e) {
    // 内部记录错误，向宿主发送通用错误
    await PluginSDK.logError('数据处理失败: $e');
    await PluginSDK.sendEvent('data_processed', {
      'success': false,
      'error': '处理失败',
    });
  }
}
```

## 测试与调试

### 日志记录

使用 SDK 的日志系统：

```dart
// 不同的日志级别
await PluginSDK.logDebug('调试信息', {'variable': value});
await PluginSDK.logInfo('操作成功完成');
await PluginSDK.logWarning('使用了已弃用的 API', {'api': 'oldMethod'});
await PluginSDK.logError('操作失败', {'error': e.toString()});
```

### 本地测试

在本地测试您的插件：

```bash
# 使用特定宿主版本测试
plugin-cli test --plugin my-plugin.pkg --host-version 1.2.0

# 使用详细输出测试
plugin-cli test --plugin my-plugin.pkg --verbose

# 测试特定场景
plugin-cli test --plugin my-plugin.pkg --scenario integration
```

### 调试

在您的插件中启用调试模式：

```dart
void main() async {
  // 启用调试模式
  await PluginSDK.initialize(
    pluginId: 'com.example.my-plugin',
    config: {
      'debug': true,
      'logLevel': 'debug',
    },
  );
  
  // 调试事件处理器
  PluginSDK.onHostEvent('debug_command', (event) async {
    final command = event.data['command'] as String;
    
    switch (command) {
      case 'dump_state':
        await dumpInternalState();
        break;
      case 'reload_config':
        await reloadConfiguration();
        break;
    }
  });
}
```

## 分发与发布

### 插件清单

在 `plugin_manifest.json` 中配置您的插件：

```json
{
  "id": "com.example.my-plugin",
  "name": "我的超棒插件",
  "version": "1.0.0",
  "type": "tool",
  "requiredPermissions": [
    "fileSystemRead",
    "networkAccess"
  ],
  "supportedPlatforms": [
    "windows",
    "linux",
    "macos"
  ],
  "configuration": {
    "configurable": true,
    "settings": {
      "api_endpoint": {
        "type": "string",
        "default": "https://api.example.com",
        "description": "API 端点 URL"
      },
      "timeout": {
        "type": "integer",
        "default": 30,
        "description": "请求超时时间（秒）"
      }
    }
  },
  "security": {
    "level": "standard",
    "resourceLimits": {
      "maxMemoryMB": 512,
      "maxCpuPercent": 25.0,
      "maxNetworkKbps": 1024,
      "maxFileHandles": 50,
      "maxExecutionTimeSeconds": 3600
    }
  }
}
```

### 打包

打包您的插件以供分发：

```bash
# 为所有平台打包
plugin-cli package --platform all --output my-plugin.pkg

# 为特定平台打包
plugin-cli package --platform windows --output my-plugin-windows.pkg

# 包含额外资源
plugin-cli package --include-resources --output my-plugin-full.pkg
```

### 发布

发布到插件注册表：

```bash
# 发布到官方注册表
plugin-cli publish --plugin my-plugin.pkg --registry official

# 发布到自定义注册表
plugin-cli publish --plugin my-plugin.pkg --registry https://my-registry.com

# 使用元数据发布
plugin-cli publish --plugin my-plugin.pkg --category productivity --tags "utility,automation"
```

## 最佳实践

### 性能

1. **延迟加载**：仅在需要时加载资源
2. **高效通信**：尽可能批量处理 API 调用
3. **内存管理**：及时清理资源
4. **后台处理**：使用适当的线程

```dart
// 示例：高效的数据加载
class DataManager {
  final Map<String, dynamic> _cache = {};
  
  Future<List<DataItem>> loadData(String category) async {
    // 首先检查缓存
    if (_cache.containsKey(category)) {
      return _cache[category] as List<DataItem>;
    }
    
    // 高效地加载数据
    final data = await PluginSDK.callHostAPI<List<dynamic>>(
      'loadDataBatch',
      {
        'category': category,
        'limit': 100,
        'fields': ['id', 'name', 'timestamp'], // 仅需要的字段
      },
    );
    
    final items = data.map((item) => DataItem.fromJson(item)).toList();
    _cache[category] = items;
    
    return items;
  }
}
```

### 错误处理

1. **优雅降级**：尽可能继续运行
2. **用户友好的消息**：提供清晰的错误消息
3. **恢复机制**：实现重试逻辑
4. **日志记录**：记录错误以便调试

```dart
// 示例：健壮的错误处理
Future<void> syncData() async {
  int retryCount = 0;
  const maxRetries = 3;
  
  while (retryCount < maxRetries) {
    try {
      await performSync();
      await PluginSDK.logInfo('数据同步成功完成');
      return;
    } catch (e) {
      retryCount++;
      
      if (retryCount >= maxRetries) {
        await PluginSDK.logError('数据同步在 $maxRetries 次尝试后失败: $e');
        await PluginLifecycleHelper.reportError(
          '同步失败',
          {'attempts': retryCount, 'error': e.toString()},
        );
        return;
      }
      
      await PluginSDK.logWarning('同步尝试 $retryCount 失败，正在重试...');
      await Future.delayed(Duration(seconds: retryCount * 2)); // 指数退避
    }
  }
}
```

### 用户体验

1. **响应式 UI**：在操作期间保持 UI 响应
2. **进度反馈**：为长时间操作显示进度
3. **一致的主题**：适应宿主应用程序主题
4. **无障碍性**：支持无障碍功能

```dart
// 示例：进度报告
Future<void> processLargeDataset(List<DataItem> items) async {
  final total = items.length;
  
  for (int i = 0; i < items.length; i++) {
    await processItem(items[i]);
    
    // 每 10 个项目报告一次进度
    if (i % 10 == 0 || i == total - 1) {
      await PluginSDK.sendEvent('progress_update', {
        'current': i + 1,
        'total': total,
        'percentage': ((i + 1) / total * 100).round(),
      });
    }
  }
}
```

本指南提供了插件 SDK 的全面概述。有关更详细的示例和高级主题，请参阅 `examples/` 目录中的示例插件。
# 外部插件开发标准规范

## 概述

本文档定义了为Flutter插件平台开发外部插件的标准规范。外部插件是独立于主应用程序进程运行的插件，支持多种编程语言和技术栈，通过标准化的通信协议与主应用程序交互。

## 目录

1. [插件类型与支持的技术栈](#插件类型与支持的技术栈)
2. [插件包结构规范](#插件包结构规范)
3. [插件清单文件规范](#插件清单文件规范)
4. [通信协议规范](#通信协议规范)
5. [安全与权限规范](#安全与权限规范)
6. [开发环境要求](#开发环境要求)
7. [开发流程](#开发流程)
8. [测试规范](#测试规范)
9. [分发与发布](#分发与发布)
10. [限制与约束](#限制与约束)
11. [接入指南](#接入指南)

## 插件类型与支持的技术栈

### 支持的插件类型

#### 1. 可执行插件 (Executable Plugin)
- **描述**: 编译为本地可执行文件的插件
- **支持语言**: 
  - Dart (编译为原生可执行文件)
  - Python (使用PyInstaller打包)
  - JavaScript/TypeScript (使用Node.js + pkg)
  - Java (编译为JAR，使用GraalVM Native Image)
  - C/C++ (原生编译)
  - Rust (原生编译)
  - Go (原生编译)
  - C# (.NET Native AOT)

#### 2. Web插件 (Web Plugin)
- **描述**: 基于Web技术的插件，运行在沙盒化的WebView容器中
- **支持技术**:
  - HTML5 + CSS3 + JavaScript
  - React/Vue.js/Angular等前端框架
  - WebAssembly (WASM)
  - Progressive Web Apps (PWA)

#### 3. 容器插件 (Container Plugin)
- **描述**: 运行在容器环境中的插件
- **支持技术**:
  - Docker容器
  - 任何可容器化的应用程序
  - 微服务架构

### 平台兼容性

| 插件类型 | Windows | Linux | macOS | Android | iOS | Web |
|---------|---------|-------|-------|---------|-----|-----|
| 可执行插件 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Web插件 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 容器插件 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

## 插件包结构规范

### 标准包结构

```
plugin-package/
├── manifest.json                 # 插件清单文件 (必需)
├── platforms/                    # 平台特定资源 (必需)
│   ├── windows/
│   │   ├── plugin.exe           # Windows可执行文件
│   │   └── dependencies/        # Windows依赖
│   ├── linux/
│   │   ├── plugin              # Linux可执行文件
│   │   └── dependencies/       # Linux依赖
│   ├── macos/
│   │   ├── plugin.app          # macOS应用包
│   │   └── dependencies/       # macOS依赖
│   └── web/
│       ├── index.html          # Web应用入口
│       ├── assets/             # Web资源
│       └── dependencies/       # Web依赖
├── resources/                   # 共享资源 (可选)
│   ├── icons/                  # 插件图标
│   │   ├── icon-16.png
│   │   ├── icon-32.png
│   │   ├── icon-64.png
│   │   └── icon-128.png
│   ├── localization/           # 本地化文件
│   │   ├── en.json
│   │   ├── zh-CN.json
│   │   └── zh-TW.json
│   └── documentation/          # 插件文档
│       ├── README.md
│       └── CHANGELOG.md
├── security/                    # 安全相关文件 (必需)
│   ├── signature.sig           # 数字签名
│   ├── certificate.pem         # 安全证书
│   └── permissions.json        # 权限声明
└── metadata/                    # 元数据 (可选)
    ├── license.txt             # 许可证信息
    └── dependencies.json       # 依赖声明
```

### 文件大小限制

- **单个插件包**: 最大 500MB
- **可执行文件**: 最大 200MB
- **Web资源**: 最大 100MB
- **图标文件**: 每个最大 1MB
- **文档文件**: 最大 10MB

## 插件清单文件规范

### manifest.json 结构

```json
{
  "id": "com.company.plugin-name",
  "name": "Plugin Display Name",
  "version": "1.0.0",
  "type": "tool",
  "runtimeType": "executable",
  "requiredPermissions": [
    "fileSystemRead",
    "networkAccess"
  ],
  "supportedPlatforms": [
    "windows",
    "linux",
    "macos"
  ],
  "entryPoints": {
    "windows": "platforms/windows/plugin.exe",
    "linux": "platforms/linux/plugin",
    "macos": "platforms/macos/plugin.app",
    "web": "platforms/web/index.html"
  },
  "configuration": {
    "configurable": true,
    "settings": {
      "api_endpoint": {
        "type": "string",
        "default": "https://api.example.com",
        "description": "API端点URL",
        "required": false
      },
      "timeout": {
        "type": "integer",
        "default": 30,
        "min": 5,
        "max": 300,
        "description": "请求超时时间(秒)",
        "required": false
      }
    }
  },
  "security": {
    "level": "standard",
    "requiresSignature": true,
    "allowedDomains": [
      "api.example.com",
      "cdn.example.com"
    ],
    "blockedDomains": [],
    "resourceLimits": {
      "maxMemoryMB": 512,
      "maxCpuPercent": 25.0,
      "maxNetworkKbps": 1024,
      "maxFileHandles": 50,
      "maxExecutionTimeSeconds": 3600
    }
  },
  "uiIntegration": {
    "containerType": "embedded",
    "containerConfig": {
      "width": 800,
      "height": 600,
      "resizable": true
    },
    "supportsTheming": true,
    "supportedInputMethods": [
      "mouse",
      "keyboard",
      "touch"
    ]
  },
  "dependencies": [
    {
      "name": "example-lib",
      "version": ">=1.0.0",
      "type": "system",
      "optional": false
    }
  ],
  "providedAPIs": [
    {
      "name": "data-processor",
      "version": "1.0.0",
      "description": "数据处理API"
    }
  ],
  "metadata": {
    "description": "插件详细描述",
    "author": "开发者名称",
    "email": "developer@example.com",
    "website": "https://example.com",
    "category": "productivity",
    "tags": ["utility", "automation"],
    "license": "MIT",
    "minHostVersion": "1.0.0",
    "maxHostVersion": "2.0.0"
  }
}
```

### 字段说明

#### 必需字段

- **id**: 插件唯一标识符，使用反向域名格式
- **name**: 插件显示名称
- **version**: 插件版本，遵循语义化版本规范
- **type**: 插件类型 (`tool` | `game` | `utility`)
- **runtimeType**: 运行时类型 (`executable` | `webApp` | `container`)
- **supportedPlatforms**: 支持的平台列表
- **entryPoints**: 各平台的入口点

#### 可选字段

- **requiredPermissions**: 所需权限列表
- **configuration**: 配置选项定义
- **security**: 安全设置
- **uiIntegration**: UI集成配置
- **dependencies**: 依赖声明
- **providedAPIs**: 提供的API
- **metadata**: 元数据信息

## 通信协议规范

### IPC消息格式

```json
{
  "messageId": "uuid-v4-string",
  "messageType": "api_call|event|response|error",
  "sourceId": "host|plugin_id",
  "targetId": "host|plugin_id|broadcast",
  "timestamp": "2023-12-17T10:30:00.000Z",
  "priority": "low|normal|high|critical",
  "payload": {
    "method": "method_name",
    "parameters": {},
    "data": {},
    "error": {
      "code": "ERROR_CODE",
      "message": "错误描述",
      "details": {}
    }
  }
}
```

### 通信通道

#### 1. 可执行插件通信
- **Windows**: 命名管道 (Named Pipes)
- **Linux/macOS**: Unix域套接字 (Unix Domain Sockets)

#### 2. Web插件通信
- **协议**: WebSocket
- **端口**: 动态分配
- **安全**: WSS (WebSocket Secure)

#### 3. 容器插件通信
- **协议**: HTTP REST API
- **端口**: 容器内部端口映射
- **格式**: JSON

### 标准API调用

#### 主机API调用示例

```javascript
// 获取用户偏好设置
const theme = await callHostAPI('getUserPreference', {
  key: 'theme'
});

// 显示通知
await callHostAPI('showNotification', {
  title: '插件通知',
  message: '操作完成',
  type: 'success'
});

// 文件系统访问
const content = await callHostAPI('readFile', {
  path: '/path/to/file.txt'
});
```

#### 事件处理示例

```javascript
// 监听主题变化事件
onHostEvent('theme_changed', (event) => {
  const newTheme = event.data.theme;
  updatePluginTheme(newTheme);
});

// 发送插件事件
sendEvent('data_updated', {
  timestamp: new Date().toISOString(),
  recordCount: 42
});
```

## 安全与权限规范

### 权限类型

#### 文件系统权限
- `fileSystemRead`: 读取文件
- `fileSystemWrite`: 写入文件
- `fileSystemExecute`: 执行文件

#### 网络权限
- `networkAccess`: 网络访问
- `networkServer`: 创建网络服务器
- `networkClient`: 创建网络客户端

#### 系统权限
- `systemNotifications`: 系统通知
- `systemClipboard`: 剪贴板访问
- `systemCamera`: 摄像头访问
- `systemMicrophone`: 麦克风访问

#### 平台权限
- `platformServices`: 平台服务访问
- `platformUI`: 平台UI集成
- `platformStorage`: 平台存储访问

#### 插件间权限
- `pluginCommunication`: 插件间通信
- `pluginDataSharing`: 插件数据共享

### 安全级别

#### minimal (最小安全)
- 基础沙盒隔离
- 有限的资源访问
- 适用于简单工具插件

#### standard (标准安全)
- 标准安全控制
- 权限验证
- 资源监控
- 适用于大多数插件

#### strict (严格安全)
- 增强安全控制
- 严格的权限检查
- 网络流量过滤
- 适用于处理敏感数据的插件

#### isolated (完全隔离)
- 最大程度隔离
- 最小权限原则
- 严格的资源限制
- 适用于不受信任的插件

### 资源限制

```json
{
  "resourceLimits": {
    "maxMemoryMB": 512,           // 最大内存使用(MB)
    "maxCpuPercent": 25.0,        // 最大CPU使用率(%)
    "maxNetworkKbps": 1024,       // 最大网络带宽(Kbps)
    "maxFileHandles": 50,         // 最大文件句柄数
    "maxExecutionTimeSeconds": 3600, // 最大执行时间(秒)
    "maxDiskUsageMB": 100,        // 最大磁盘使用(MB)
    "maxNetworkConnections": 10   // 最大网络连接数
  }
}
```

## 开发环境要求

### 基础要求

1. **Flutter插件平台主机应用** (v1.0.0+)
2. **插件CLI工具** (随SDK提供)
3. **选择的编程语言开发环境**
4. **代码签名证书** (用于插件签名)

### 推荐工具

- **IDE**: Visual Studio Code, IntelliJ IDEA, 或语言特定IDE
- **版本控制**: Git
- **包管理**: 语言特定的包管理器
- **容器工具**: Docker (用于容器插件)
- **测试工具**: 语言特定的测试框架

## 开发流程

### 1. 项目初始化

```bash
# 创建新插件项目
plugin-cli create --name my-plugin --type executable --language dart

# 进入项目目录
cd my-plugin

# 初始化开发环境
plugin-cli init
```

### 2. 插件开发

#### Dart可执行插件示例

```dart
import 'dart:io';
import 'package:plugin_sdk/sdk.dart';

void main(List<String> args) async {
  // 初始化插件SDK
  await PluginSDK.initialize(
    pluginId: 'com.example.my-plugin',
    config: {
      'debug': true,
      'logLevel': 'info',
    },
  );

  // 注册消息处理器
  PluginSDK.registerMessageHandler('process_data', handleDataProcessing);
  
  // 监听主机事件
  PluginSDK.onHostEvent('theme_changed', onThemeChanged);
  
  // 报告插件就绪
  await PluginSDK.reportReady();
  
  // 保持插件运行
  await PluginSDK.keepAlive();
}

Future<void> handleDataProcessing(IPCMessage message) async {
  final data = message.payload['data'];
  
  // 处理数据
  final result = await processData(data);
  
  // 发送结果
  await PluginSDK.sendResponse(message.messageId, {
    'success': true,
    'result': result,
  });
}

Future<void> onThemeChanged(HostEvent event) async {
  final theme = event.data['theme'];
  // 更新插件主题
  await updatePluginTheme(theme);
}
```

#### Python可执行插件示例

```python
import asyncio
import json
from plugin_sdk import PluginSDK, IPCMessage, HostEvent

async def main():
    # 初始化插件SDK
    sdk = PluginSDK(
        plugin_id='com.example.my-plugin',
        config={
            'debug': True,
            'log_level': 'info'
        }
    )
    
    await sdk.initialize()
    
    # 注册消息处理器
    sdk.register_message_handler('process_data', handle_data_processing)
    
    # 监听主机事件
    sdk.on_host_event('theme_changed', on_theme_changed)
    
    # 报告插件就绪
    await sdk.report_ready()
    
    # 保持插件运行
    await sdk.keep_alive()

async def handle_data_processing(message: IPCMessage):
    data = message.payload.get('data')
    
    # 处理数据
    result = await process_data(data)
    
    # 发送结果
    await sdk.send_response(message.message_id, {
        'success': True,
        'result': result
    })

async def on_theme_changed(event: HostEvent):
    theme = event.data.get('theme')
    # 更新插件主题
    await update_plugin_theme(theme)

if __name__ == '__main__':
    asyncio.run(main())
```

#### Web插件示例

```html
<!DOCTYPE html>
<html>
<head>
    <title>My Web Plugin</title>
    <script src="plugin-sdk.js"></script>
</head>
<body>
    <div id="app">
        <h1>My Web Plugin</h1>
        <button onclick="processData()">处理数据</button>
    </div>

    <script>
        // 初始化插件SDK
        PluginSDK.initialize({
            pluginId: 'com.example.my-web-plugin',
            config: {
                debug: true
            }
        }).then(() => {
            console.log('Plugin initialized');
            
            // 监听主机事件
            PluginSDK.onHostEvent('theme_changed', (event) => {
                updateTheme(event.data.theme);
            });
            
            // 报告插件就绪
            PluginSDK.reportReady();
        });

        async function processData() {
            try {
                const result = await PluginSDK.callHostAPI('getData', {
                    type: 'user_data'
                });
                
                // 处理数据并显示结果
                displayResult(result);
                
            } catch (error) {
                console.error('Data processing failed:', error);
            }
        }

        function updateTheme(theme) {
            document.body.className = theme;
        }

        function displayResult(result) {
            document.getElementById('app').innerHTML += 
                `<p>处理结果: ${JSON.stringify(result)}</p>`;
        }
    </script>
</body>
</html>
```

### 3. 构建与打包

```bash
# 构建插件
plugin-cli build

# 打包为分发包
plugin-cli package --platform all --output my-plugin.pkg

# 签名插件包
plugin-cli sign --plugin my-plugin.pkg --certificate cert.pem --key private.key
```

### 4. 本地测试

```bash
# 本地测试
plugin-cli test --plugin my-plugin.pkg

# 详细测试输出
plugin-cli test --plugin my-plugin.pkg --verbose

# 特定场景测试
plugin-cli test --plugin my-plugin.pkg --scenario integration
```

## 测试规范

### 单元测试

每个插件应包含单元测试，覆盖：
- 核心功能逻辑
- 错误处理
- 边界条件
- API调用

### 集成测试

测试插件与主机应用的集成：
- IPC通信
- 权限验证
- 资源使用
- 生命周期管理

### 性能测试

验证插件性能指标：
- 启动时间 < 5秒
- 内存使用 < 配置限制
- CPU使用 < 配置限制
- 响应时间 < 1秒

### 安全测试

验证安全措施：
- 权限边界
- 沙盒隔离
- 数据验证
- 恶意输入处理

## 分发与发布

### 分发渠道

1. **官方插件商店**: 经过审核的插件
2. **社区注册表**: 开源社区插件
3. **直接下载**: 通过URL直接下载
4. **包管理器**: 系统包管理器集成
5. **Git仓库**: 基于Git的分发
6. **容器注册表**: 容器化插件

### 发布流程

```bash
# 1. 验证插件包
plugin-cli validate --plugin my-plugin.pkg

# 2. 发布到官方商店
plugin-cli publish --plugin my-plugin.pkg --registry official

# 3. 发布到自定义注册表
plugin-cli publish --plugin my-plugin.pkg --registry https://my-registry.com

# 4. 添加元数据
plugin-cli publish --plugin my-plugin.pkg --category productivity --tags "utility,automation"
```

### 版本管理

- 遵循语义化版本规范 (SemVer)
- 主版本号: 不兼容的API更改
- 次版本号: 向后兼容的功能添加
- 修订版本号: 向后兼容的错误修复

## 限制与约束

### 技术限制

1. **资源限制**: 严格的内存、CPU、网络使用限制
2. **权限限制**: 基于权限的访问控制
3. **平台限制**: 某些插件类型不支持所有平台
4. **网络限制**: 受限的网络访问和域名白名单

### 功能限制

1. **文件系统访问**: 仅限沙盒目录
2. **系统调用**: 受限的系统API访问
3. **进程管理**: 不能创建子进程
4. **硬件访问**: 需要明确权限

### 安全约束

1. **代码签名**: 必须使用有效证书签名
2. **权限声明**: 必须明确声明所需权限
3. **沙盒隔离**: 强制沙盒环境运行
4. **审核要求**: 官方商店需要安全审核

### 性能约束

1. **启动时间**: 最大5秒启动时间
2. **响应时间**: API调用响应时间 < 1秒
3. **资源使用**: 严格的资源使用监控
4. **并发限制**: 限制并发连接和操作

## 接入指南

### 快速开始

#### 1. 环境准备

```bash
# 安装Flutter插件平台
# 下载并安装主机应用

# 安装插件CLI工具
npm install -g @flutter-platform/plugin-cli

# 验证安装
plugin-cli --version
```

#### 2. 创建第一个插件

```bash
# 创建插件项目
plugin-cli create --name hello-world --type executable --language dart

# 进入项目目录
cd hello-world

# 查看项目结构
ls -la
```

#### 3. 开发插件

编辑 `lib/main.dart`:

```dart
import 'package:plugin_sdk/sdk.dart';

void main() async {
  await PluginSDK.initialize(
    pluginId: 'com.example.hello-world',
  );

  // 注册API处理器
  PluginSDK.registerMessageHandler('greet', (message) async {
    final name = message.payload['name'] ?? 'World';
    await PluginSDK.sendResponse(message.messageId, {
      'greeting': 'Hello, $name!'
    });
  });

  await PluginSDK.reportReady();
  await PluginSDK.keepAlive();
}
```

#### 4. 构建和测试

```bash
# 构建插件
plugin-cli build

# 打包插件
plugin-cli package --output hello-world.pkg

# 本地测试
plugin-cli test --plugin hello-world.pkg
```

#### 5. 发布插件

```bash
# 验证插件包
plugin-cli validate --plugin hello-world.pkg

# 发布到测试环境
plugin-cli publish --plugin hello-world.pkg --registry test

# 发布到生产环境
plugin-cli publish --plugin hello-world.pkg --registry official
```

### 常见问题

#### Q: 如何调试插件？
A: 使用 `--debug` 标志启动插件，并查看日志输出：
```bash
plugin-cli test --plugin my-plugin.pkg --debug
```

#### Q: 如何处理权限被拒绝？
A: 检查 `manifest.json` 中的权限声明，确保请求了必要的权限。

#### Q: 如何优化插件性能？
A: 
- 使用异步操作避免阻塞
- 实现资源缓存
- 优化内存使用
- 减少不必要的API调用

#### Q: 如何实现跨平台兼容？
A: 
- 为每个平台提供相应的可执行文件
- 使用Web技术实现跨平台UI
- 抽象平台特定的功能

### 技术支持

- **文档**: https://docs.flutter-platform.com/plugins
- **示例**: https://github.com/flutter-platform/plugin-examples
- **社区**: https://community.flutter-platform.com
- **问题报告**: https://github.com/flutter-platform/issues

---

本规范文档将随着平台的发展持续更新。请定期查看最新版本以获取最新的开发指南和最佳实践。
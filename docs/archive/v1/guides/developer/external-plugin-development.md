# 外部插件开发规范

本文档定义了外部插件的标准规范，包括包结构、清单格式、通信协议和安全要求。

> SDK API 使用请参考 [插件 SDK 指南](./plugin-sdk-guide.md)

## 目录

1. [插件类型](#插件类型)
2. [包结构规范](#包结构规范)
3. [清单文件规范](#清单文件规范)
4. [通信协议](#通信协议)
5. [安全与权限](#安全与权限)
6. [限制与约束](#限制与约束)

## 插件类型

### 运行时类型

| 类型 | 描述 | 支持语言 |
|-----|------|---------|
| **可执行插件** | 独立进程运行的原生可执行文件 | Dart, Python, JS, Java, C++, Rust, Go, C# |
| **Web 插件** | 沙盒化 WebView 容器中运行 | HTML5, React, Vue, Angular, WASM |
| **容器插件** | Docker 容器环境运行 | 任何可容器化的应用 |

### 平台兼容性

| 插件类型 | Windows | Linux | macOS | Android | iOS | Web |
|---------|:-------:|:-----:|:-----:|:-------:|:---:|:---:|
| 可执行插件 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Web 插件 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 容器插件 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |

## 包结构规范

### 标准目录结构

```
plugin-package/
├── manifest.json              # 插件清单 (必需)
├── platforms/                 # 平台特定资源 (必需)
│   ├── windows/
│   │   ├── plugin.exe
│   │   └── dependencies/
│   ├── linux/
│   │   ├── plugin
│   │   └── dependencies/
│   ├── macos/
│   │   ├── plugin.app
│   │   └── dependencies/
│   └── web/
│       ├── index.html
│       └── assets/
├── resources/                 # 共享资源 (可选)
│   ├── icons/                # 图标 (16/32/64/128px)
│   ├── localization/         # 本地化 (en.json, zh-CN.json)
│   └── documentation/        # 文档
├── security/                  # 安全文件 (必需)
│   ├── signature.sig         # 数字签名
│   ├── certificate.pem       # 安全证书
│   └── permissions.json      # 权限声明
└── metadata/                  # 元数据 (可选)
    ├── license.txt
    └── dependencies.json
```

### 文件大小限制

| 类型 | 限制 |
|-----|-----|
| 单个插件包 | 500MB |
| 可执行文件 | 200MB |
| Web 资源 | 100MB |
| 图标文件 | 1MB/个 |
| 文档文件 | 10MB |

## 清单文件规范

### manifest.json 完整结构

```json
{
  "id": "com.company.plugin-name",
  "name": "Plugin Display Name",
  "version": "1.0.0",
  "type": "tool",
  "runtimeType": "executable",
  "supportedPlatforms": ["windows", "linux", "macos"],
  "entryPoints": {
    "windows": "platforms/windows/plugin.exe",
    "linux": "platforms/linux/plugin",
    "macos": "platforms/macos/plugin.app",
    "web": "platforms/web/index.html"
  },
  "requiredPermissions": ["fileSystemRead", "networkAccess"],
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
        "min": 5,
        "max": 300,
        "description": "超时时间(秒)"
      }
    }
  },
  "security": {
    "level": "standard",
    "requiresSignature": true,
    "allowedDomains": ["api.example.com"],
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
    "containerConfig": { "width": 800, "height": 600, "resizable": true },
    "supportsTheming": true
  },
  "metadata": {
    "description": "插件描述",
    "author": "开发者",
    "email": "dev@example.com",
    "category": "productivity",
    "tags": ["utility"],
    "license": "MIT",
    "minHostVersion": "1.0.0"
  }
}
```

### 必需字段

| 字段 | 说明 |
|-----|------|
| `id` | 唯一标识符，反向域名格式 |
| `name` | 显示名称 |
| `version` | 语义化版本 |
| `type` | `tool` / `game` / `utility` |
| `runtimeType` | `executable` / `webApp` / `container` |
| `supportedPlatforms` | 支持的平台列表 |
| `entryPoints` | 各平台入口点 |

## 通信协议

### IPC 消息格式

```json
{
  "messageId": "uuid-v4",
  "messageType": "api_call | event | response | error",
  "sourceId": "host | plugin_id",
  "targetId": "host | plugin_id | broadcast",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "priority": "low | normal | high | critical",
  "payload": {
    "method": "method_name",
    "parameters": {},
    "data": {},
    "error": { "code": "ERROR_CODE", "message": "描述" }
  }
}
```

### 通信通道

| 插件类型 | 通道 |
|---------|-----|
| 可执行插件 (Windows) | 命名管道 |
| 可执行插件 (Unix) | Unix 域套接字 |
| Web 插件 | WebSocket (WSS) |
| 容器插件 | HTTP REST API |

## 国际化 (i18n)

### 概述

外部插件必须提供自带的翻译资源，通过 `IPluginI18n` 接口实现国际化支持。与内部插件不同，外部插件不能直接使用系统的 `AppLocalizations`，而是需要注册自己的翻译资源。

### 内部插件 vs 外部插件国际化

| 特性 | 内部插件 | 外部插件 |
|------|---------|---------|
| **翻译来源** | 系统 ARB 文件（`lib/l10n/app_*.arb`） | 插件自带翻译 |
| **访问方式** | `AppLocalizations.of(context)!` | `context.i18n.translate()` |
| **翻译注册** | 自动（系统管理） | 手动注册（`initialize()` 中） |
| **语言切换** | 自动响应系统语言切换 | 自动响应系统语言切换 |
| **翻译键冲突** | 系统统一管理 | 插件内部隔离 |

### 实现步骤

#### 1. 准备翻译资源

在插件包中创建翻译文件：

**文件结构**：
```
com.example.myplugin/
├── lib/
│   └── myplugin.dart
├── assets/
│   └── translations/
│       ├── zh.json
│       └── en.json
└── pubspec.yaml
```

**翻译文件格式** (`assets/translations/zh.json`):
```json
{
  "myplugin_title": "我的插件",
  "myplugin_welcome": "欢迎使用",
  "myplugin_settings": "设置",
  "myplugin_save": "保存",
  "myplugin_cancel": "取消"
}
```

**翻译文件格式** (`assets/translations/en.json`):
```json
{
  "myplugin_title": "My Plugin",
  "myplugin_welcome": "Welcome",
  "myplugin_settings": "Settings",
  "myplugin_save": "Save",
  "myplugin_cancel": "Cancel"
}
```

#### 2. 加载并注册翻译

在插件的 `initialize()` 方法中加载并注册翻译：

```dart
import 'dart:convert';
import 'package:flutter/services.dart';

class MyExternalPlugin implements IPlugin {
  late PluginContext _context;

  /// 加载翻译文件
  Future<Map<String, Map<String, String>>> _loadTranslations() async {
    final zhJson = await rootBundle.loadString('assets/translations/zh.json');
    final enJson = await rootBundle.loadString('assets/translations/en.json');

    return {
      'zh': json.decode(zhJson),
      'en': json.decode(enJson),
    };
  }

  @override
  Future<void> initialize(PluginContext context) async {
    _context = context;

    // 加载并注册翻译
    final translations = await _loadTranslations();
    context.i18n.registerTranslations('com.example.myplugin', translations);
  }

  @override
  Widget buildUI(BuildContext context) {
    final i18n = _context.i18n;

    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('myplugin_title')),
      ),
      body: Center(
        child: Text(i18n.translate('myplugin_welcome')),
      ),
    );
  }
}
```

#### 3. 使用翻译

在 UI 中使用翻译：

```dart
@override
Widget buildUI(BuildContext context) {
  final i18n = _context.i18n;

  return Scaffold(
    appBar: AppBar(
      title: Text(i18n.translate('myplugin_title')),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: i18n.translate('myplugin_settings'),
          onPressed: () => _openSettings(),
        ),
      ],
    ),
    body: Column(
      children: [
        Text(i18n.translate('myplugin_welcome')),
        ElevatedButton(
          onPressed: () => _save(),
          child: Text(i18n.translate('myplugin_save')),
        ),
      ],
    ),
  );
}
```

### 高级功能

#### 1. 占位符翻译

翻译支持占位符替换：

**定义翻译**：
```json
{
  "myplugin_greeting": "欢迎，{name}！"
}
```

**使用翻译**：
```dart
Text(
  i18n.translate('myplugin_greeting', args: {'name': 'John'}),
  // 输出：欢迎，John！
)
```

#### 2. 检查翻译可用性

```dart
void _showWelcomeMessage() {
  final i18n = _context.i18n;

  if (i18n.hasTranslation('myplugin_welcome')) {
    // 使用插件自己的翻译
    final message = i18n.translate('myplugin_welcome');
    _showSnackBar(message);
  } else {
    // 回退到系统翻译或默认文本
    _showSnackBar('Welcome');
  }
}
```

#### 3. 获取当前语言

```dart
void _logCurrentLanguage() {
  final i18n = _context.i18n;
  final currentLocale = i18n.currentLocale;  // "zh" 或 "en"

  debugPrint('当前语言: $currentLocale');
}
```

#### 4. 获取指定语言的翻译

```dart
void _showAllLanguages() {
  final i18n = _context.i18n;

  final zhText = i18n.translateLocale('zh', 'myplugin_title');
  final enText = i18n.translateLocale('en', 'myplugin_title');

  debugPrint('中文: $zhText');
  debugPrint('英文: $enText');
}
```

#### 5. 支持的语言列表

```dart
void _printSupportedLanguages() {
  final i18n = _context.i18n;
  final locales = i18n.supportedLocales;  // ["zh", "en", "ja"]

  debugPrint('支持的语言: $locales');
}
```

### 翻译优先级规则

外部插件应按以下优先级查找翻译：

1. **系统翻译**（优先）- 如果主应用提供了该翻译键
   ```dart
   final text = l10n.plugin_myplugin_name ?? i18n.translate('myplugin_title');
   ```

2. **插件翻译**（回退）- 使用插件自带的翻译
   ```dart
   final text = i18n.translate('myplugin_title');
   ```

3. **键名本身**（最终回退）- 便于调试
   ```dart
   // 如果找不到翻译，返回键名 'myplugin_title'
   ```

### 语言回退机制

`IPluginI18n` 接口支持自动语言回退：

```dart
// 当前语言是 zh_CN
i18n.translate('myplugin_title');

// 查找顺序：
// 1. 查找 zh_CN 翻译
// 2. 如果找不到，查找 zh 翻译（主语言）
// 3. 如果找不到，返回键名 'myplugin_title'
```

### 翻译键命名规范

**格式**：`{plugin}_{component}_{text}`

**示例**：
```
myplugin_title              - 插件标题
myplugin_welcome            - 欢迎消息
myplugin_settings_title     - 设置标题
myplugin_settings_save      - 设置保存按钮
myplugin_dialog_delete_title - 删除对话框标题
```

**组件分类**：
- `main` - 主界面组件
- `settings` / `config` - 设置界面
- `dialog` - 对话框
- `error` - 错误消息
- `tooltip` - 工具提示

### 最佳实践

1. **提供完整翻译**：至少支持中文和英文
2. **使用命名空间**：所有翻译键使用插件前缀，避免冲突
3. **占位符统一**：使用 `{key}` 格式的占位符
4. **语言回退**：如果某个语言缺少翻译，自动回退到英文或键名
5. **测试验证**：在切换系统语言时测试插件显示是否正确

### 检查清单

开发外部插件时，确保：

- [ ] 在 `initialize()` 中注册了所有翻译
- [ ] 提供了中文和英文两种翻译
- [ ] 所有用户可见文本使用 `i18n.translate()`
- [ ] 翻译键使用插件前缀（避免冲突）
- [ ] 占位符使用正确（`{key}` 格式）
- [ ] 在系统语言切换时测试过插件
- [ ] 处理了翻译缺失的情况（有回退方案）

### 常见错误

**错误 1：忘记注册翻译**
```dart
// ❌ 错误：没有注册翻译
@override
Future<void> initialize(PluginContext context) async {
  _context = context;
  // 忘记注册翻译
}

// ✅ 正确：注册翻译
@override
Future<void> initialize(PluginContext context) async {
  _context = context;
  final translations = await _loadTranslations();
  context.i18n.registerTranslations('com.example.myplugin', translations);
}
```

**错误 2：硬编码文本**
```dart
// ❌ 错误：硬编码文本
Text('欢迎')

// ✅ 正确：使用翻译
Text(i18n.translate('myplugin_welcome'))
```

**错误 3：翻译键冲突**
```dart
// ❌ 错误：使用通用键名（可能冲突）
"title": "我的插件"

// ✅ 正确：使用插件前缀
"myplugin_title": "我的插件"
```

**错误 4：占位符格式错误**
```dart
// ❌ 错误：占位符格式不匹配
翻译: "欢迎，$name!"
代码: i18n.translate('greeting', args: {'name': 'John'})

// ✅ 正确：使用 {key} 格式
翻译: "欢迎，{name}!"
代码: i18n.translate('greeting', args: {'name': 'John'})
```

### 完整示例

**Python 插件示例**：

```python
import json
import os

class MyPlugin:
    def __init__(self):
        self.context = None
        self.translations = {}

    def initialize(self, context):
        self.context = context

        # 加载翻译文件
        translations_path = os.path.join(
            os.path.dirname(__file__),
            'assets',
            'translations'
        )

        with open(os.path.join(translations_path, 'zh.json'), 'r', encoding='utf-8') as f:
            zh_data = json.load(f)

        with open(os.path.join(translations_path, 'en.json'), 'r', encoding='utf-8') as f:
            en_data = json.load(f)

        # 注册翻译
        self.context['i18n'].registerTranslations('com.example.myplugin', {
            'zh': zh_data,
            'en': en_data
        })

    def build_ui(self, context):
        # 使用翻译
        title = self.context['i18n'].translate('myplugin_title')
        welcome = self.context['i18n'].translate('myplugin_welcome')

        return {
            'type': 'scaffold',
            'appBar': {
                'title': {'text': title}
            },
            'body': {
                'type': 'center',
                'child': {'text': welcome}
            }
        }
```

## 安全与权限

### 权限类型

**文件系统**
- `fileSystemRead` - 读取文件
- `fileSystemWrite` - 写入文件
- `fileSystemExecute` - 执行文件

**网络**
- `networkAccess` - 网络访问
- `networkServer` - 创建服务器
- `networkClient` - 创建客户端

**系统**
- `systemNotifications` - 系统通知
- `systemClipboard` - 剪贴板
- `systemCamera` - 摄像头
- `systemMicrophone` - 麦克风

**平台**
- `platformServices` - 平台服务
- `platformUI` - 平台 UI
- `platformStorage` - 平台存储

**插件间**
- `pluginCommunication` - 插件间通信
- `pluginDataSharing` - 数据共享

### 安全级别

| 级别 | 描述 | 适用场景 |
|-----|------|---------|
| `minimal` | 基础沙盒隔离 | 简单工具 |
| `standard` | 标准安全控制 + 权限验证 | 大多数插件 |
| `strict` | 增强控制 + 网络过滤 | 敏感数据处理 |
| `isolated` | 最大隔离 + 最小权限 | 不受信任插件 |

### 资源限制

```json
{
  "maxMemoryMB": 512,
  "maxCpuPercent": 25.0,
  "maxNetworkKbps": 1024,
  "maxFileHandles": 50,
  "maxExecutionTimeSeconds": 3600,
  "maxDiskUsageMB": 100,
  "maxNetworkConnections": 10
}
```

## 限制与约束

### 技术限制

- 资源使用受配置限制
- 基于权限的访问控制
- 部分插件类型不支持所有平台
- 网络访问受域名白名单限制

### 功能限制

- 文件系统仅限沙盒目录
- 受限的系统 API 访问
- 不能创建子进程
- 硬件访问需明确权限

### 性能约束

| 指标 | 要求 |
|-----|-----|
| 启动时间 | < 5 秒 |
| API 响应 | < 1 秒 |
| 资源使用 | 严格监控 |

### 发布要求

- 必须使用有效证书签名
- 必须明确声明所需权限
- 强制沙盒环境运行
- 官方商店需安全审核

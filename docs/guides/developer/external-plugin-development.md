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

# Windows 平台产品化指南

## 🎯 开发 vs 分发

### 开发环境要求

**开发者需要启用开发人员模式**:
```
设置 → 更新和安全 → 开发者 → 开发人员模式 (开)
```

**原因**:
- Flutter 需要创建符号链接来访问插件代码
- Windows 默认只允许管理员和开发模式创建符号链接
- 这是开发时的技术限制，不影响最终用户

### 最终用户环境要求

**✅ 最终用户不需要任何特殊设置！**

分发后的应用特点:
- ✅ 不需要开发人员模式
- ✅ 不需要管理员权限
- ✅ 可以在标准 Windows 用户账户下运行
- ✅ 即插即用，双击 `.exe` 即可启动

## 📦 构建和分发流程

### 步骤 1: 开发者构建应用

```bash
# 开发者的机器需要启用开发人员模式
flutter build windows --release
```

**输出位置**:
```
build/windows/x64/runner/Release/
└── plugin_platform.exe  # 这是分发给用户的文件
```

### 步骤 2: 准备分发文件

```bash
# 创建分发目录
mkdir dist
mkdir dist\PluginPlatform

# 复制可执行文件
copy build\windows\x64\runner\Release\plugin_platform.exe dist\PluginPlatform\

# 复制依赖文件（自动生成）
xcopy /E /I build\windows\x64\runner\Release\* dist\PluginPlatform\

# 最终目录结构
dist/PluginPlatform/
├── plugin_platform.exe        # 主程序
├── flutter_windows.dll         # Flutter 运行时
├── data/                       # 应用数据
│   ├── flutter_assets/
│   └── ...
└── ... (其他运行时文件)
```

### 步骤 3: 打包（可选）

**使用 Inno Setup 创建安装程序**:
```iss
[Setup]
AppName=Flutter Plugin Platform
AppVersion=1.0.0
DefaultDirName={pf}\PluginPlatform
DefaultGroupName=Plugin Platform
OutputDir=installer
OutputBaseFilename=PluginPlatform-Setup

[Files]
Source: "dist\PluginPlatform\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Plugin Platform"; Filename: "{app}\plugin_platform.exe"
```

**或使用 7-Zip 创建压缩包**:
```bash
"C:\Program Files\7-Zip\7z.exe" a -tzip PluginPlatform-Windows-v1.0.0.zip .\dist\PluginPlatform\*
```

## 🔍 验证最终用户不需要开发人员模式

### 测试方法

**在干净的 Windows 机器上测试**:
1. 创建新的标准用户账户（非管理员）
2. **不启用开发人员模式**
3. 运行 `plugin_platform.exe`
4. ✅ 应用应该正常启动

### 关键点

| 环境 | 需要开发人员模式 | 需要管理员权限 |
|------|----------------|--------------|
| **开发** (`flutter run`) | ✅ 是 | ❌ 否 |
| **构建** (`flutter build`) | ✅ 是 | ❌ 否 |
| **运行** (`.exe`) | ❌ **否** | ❌ **否** |

## 🌍 跨平台对比

### macOS

**开发环境**:
- ✅ 不需要特殊模式
- macOS 默认允许创建符号链接

**最终用户**:
- ✅ 不需要任何特殊设置
- 双击 `.app` 即可运行

### Linux

**开发环境**:
- ✅ 不需要特殊模式
- Linux 默认允许创建符号链接

**最终用户**:
- ✅ 不需要任何特殊设置
- 运行可执行文件即可

### 移动平台 (Android/iOS)

**开发环境**:
- Android: 需要 USB 调试模式
- iOS: 需要开发者证书和信任设置

**最终用户**:
- ✅ 不需要任何开发设置
- 从应用商店安装后直接使用

## 📋 开发者检查清单

在分发应用前，确保:

- [ ] 已测试在**没有开发人员模式**的 Windows 上运行
- [ ] 已测试在**标准用户账户**（非管理员）下运行
- [ ] 已包含所有必要的运行时文件
- [ ] 已创建安装程序或压缩包
- [ ] 已准备用户文档（安装说明、系统要求）

## 🎓 最佳实践

### 对于开发团队

1. **CI/CD 环境**:
   - 在构建服务器上启用开发人员模式
   - 使用服务账户运行构建

2. **新开发者入职**:
   - 在开发环境设置文档中说明需要启用开发人员模式
   - 提供一键启用脚本

### 对于最终用户

1. **分发说明**:
   - **不要**告诉用户需要开发人员模式
   - 只说明最低系统要求（Windows 10/11）

2. **安装方式**:
   - 提供安装程序（推荐）
   - 或提供便携式压缩包

## 📝 用户文档示例

### 系统要求

```
系统要求:
- Windows 10 或更高版本
- 2 GB RAM (推荐 4 GB)
- 100 MB 可用磁盘空间

安装步骤:
1. 下载 PluginPlatform-Setup.exe
2. 双击运行安装程序
3. 安装完成后，从开始菜单启动应用
```

**注意**: 不需要提及开发人员模式！

## 🔧 故障排除

### 问题：用户报告无法启动

**可能原因**:
1. 缺少运行时文件
2. Windows Defender 误报
3. 权限问题

**解决方案**:
```powershell
# 以管理员身份运行，检查权限
icacls "C:\Program Files\PluginPlatform\plugin_platform.exe"

# 检查文件完整性
Get-FileHash "C:\Program Files\PluginPlatform\plugin_platform.exe"
```

---

**总结**:
- ✅ 开发者需要开发人员模式
- ✅ 最终用户不需要任何特殊设置
- ✅ 这是 Windows 开发的标准实践
- ✅ 所有主流桌面应用（VS Code, Sublime Text 等）都是这样分发的

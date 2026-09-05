# 图标生成指南

## 应用图标设计

### 设计规范
- **形状**: 3:4 比例的长方形框
- **背景色**: 蓝色 (#2962FF)
- **文字**: 白色大写字母 "P"
- **用途**: 系统托盘图标、应用图标

### 设计预览

```
┌─────────────────┐
│                 │
│   ┌─────────┐   │
│   │         │   │
│   │    P    │   │  ← 蓝色长方形框 (3:4)
│   │         │   │
│   └─────────┘   │
│                 │
└─────────────────┘
```

## 快速生成

### Windows 用户

双击运行 `scripts/generate_icon.bat`，或在命令行中执行：

```bash
cd scripts
python generate_app_icon.py
```

### macOS/Linux 用户

```bash
cd scripts
python3 generate_app_icon.py
```

## 前置要求

### Python 环境
- Python 3.6 或更高版本
- Pillow 图像处理库

### 安装依赖

```bash
pip install Pillow
```

## 生成文件位置

脚本会自动生成以下文件：

### Windows
- `windows/runner/resources/app_icon.ico` - Windows 应用图标（多尺寸）

### macOS
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/` - macOS 应用图标
  - `app_icon_16.png`
  - `app_icon_32.png`
  - `app_icon_64.png`
  - `app_icon_128.png`
  - `app_icon_256.png`
  - `app_icon_512.png`
  - `app_icon_1024.png`

### 通用 PNG 图标
- `assets/icons/` - 通用 PNG 格式图标
  - `app_icon_48x48.png`
  - `app_icon_64x64.png`
  - `app_icon_128x128.png`
  - `app_icon_256x256.png`
  - `app_icon_512x512.png`
  - `app_icon_1024x1024.png`

### 预览图
- `assets/icon_preview.png` - 所有尺寸的预览图

## 自定义设计

如需修改图标设计，编辑 `scripts/generate_app_icon.py` 中的以下配置：

```python
# 图标配置
ICON_RATIO = 3 / 4  # 宽高比
BG_COLOR = (41, 98, 255)  # 背景色 (RGB)
TEXT_COLOR = (255, 255, 255)  # 文字颜色 (RGB)
TEXT = "P"  # 显示文字
```

## 应用图标

### 重新编译

生成新图标后，需要重新编译项目：

```bash
# 清理
flutter clean

# 重新获取依赖
flutter pub get

# 重新编译
flutter build windows   # Windows
flutter build macos     # macOS
```

### 验证

编译完成后，检查应用图标是否正确显示：
- **Windows**: 查看任务栏、桌面快捷方式
- **macOS**: 查看 Finder、应用程序文件夹
- **系统托盘**: 右下角托盘区域

## 故障排除

### Pillow 安装失败

```bash
# 尝试使用国内镜像
pip install Pillow -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### 图标未更新

1. 清理项目：`flutter clean`
2. 删除 build 目录
3. 重新编译
4. Windows 可能需要清除图标缓存

### Windows 图标缓存清理

```bash
# 删除图标缓存
ie4uinit.exe -show
```

或使用第三方工具如 IconClear。

## 技术说明

### 尺寸规格

- **16x16**: 最小尺寸，用于密集显示
- **32x32**: 标准小图标
- **48x48**: Windows 传统尺寸
- **64x64**: 高DPI小图标
- **128x128**: macOS 标准尺寸
- **256x256**: 高分辨率
- **512x512**: Retina 显示
- **1024x1024**: 最大尺寸

### 设计原则

1. **简洁性**: 简单的设计在小尺寸下更清晰
2. **对比度**: 高对比度确保可读性
3. **适应性**: 在各种背景下都清晰可见
4. **一致性**: 所有尺寸保持视觉一致性

## 相关文档

- [项目文件组织规范](../.claude/rules/FILE_ORGANIZATION_RULES.md)
- [国际化开发规范](../.claude/CLAUDE.md#国际化开发规范)
- [项目主文档](../README.md)

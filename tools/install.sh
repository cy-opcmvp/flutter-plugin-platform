#!/bin/bash
# Flutter插件平台 - CLI工具安装脚本 (Unix/Linux/macOS)

set -e

echo "Flutter插件平台 - CLI工具安装程序"
echo "====================================="

# 检查Dart是否安装
if ! command -v dart &> /dev/null; then
    echo "错误: 未找到Dart命令。请先安装Flutter SDK。"
    echo "下载地址: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✓ 检测到Dart环境"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$SCRIPT_DIR"

# 检查是否已经在PATH中
if echo "$PATH" | grep -q "$TOOLS_DIR"; then
    echo "✓ CLI工具已在PATH中"
else
    # 添加到PATH
    echo "正在添加CLI工具到PATH..."
    
    # 检测shell类型
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    # 添加到shell配置文件
    if ! grep -q "$TOOLS_DIR" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# Flutter Plugin Platform CLI" >> "$SHELL_RC"
        echo "export PATH=\"\$PATH:$TOOLS_DIR\"" >> "$SHELL_RC"
        echo "✓ 已添加到 $SHELL_RC"
        echo "注意: 请运行 'source $SHELL_RC' 或重新打开终端以使PATH生效"
    else
        echo "✓ PATH配置已存在"
    fi
fi

# 给脚本执行权限
chmod +x "$TOOLS_DIR/plugin-cli.sh"
echo "✓ 设置执行权限"

# 测试CLI工具
echo "正在测试CLI工具..."
if "$TOOLS_DIR/plugin-cli.sh" --version; then
    echo "✓ CLI工具安装成功！"
else
    echo "✗ CLI工具测试失败"
    exit 1
fi

# 创建配置目录
CONFIG_DIR="$HOME/.plugin-cli"
if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR/logs"
    mkdir -p "$CONFIG_DIR/templates"
    echo "✓ 创建配置目录: $CONFIG_DIR"
fi

# 创建默认配置文件
CONFIG_FILE="$CONFIG_DIR/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "创建默认配置文件..."
    cat > "$CONFIG_FILE" << EOF
{
  "defaultAuthor": "$USER",
  "defaultEmail": "your.email@example.com",
  "defaultLicense": "MIT",
  "defaultRegistry": "https://registry.flutter-platform.com",
  "templates": {
    "customTemplatesPath": "$CONFIG_DIR/templates"
  },
  "build": {
    "defaultPlatform": "$(uname -s | tr '[:upper:]' '[:lower:]')",
    "outputDirectory": "./dist"
  }
}
EOF
    echo "✓ 创建配置文件: $CONFIG_FILE"
fi

# 创建符号链接（可选）
if [ -w "/usr/local/bin" ]; then
    if [ ! -L "/usr/local/bin/plugin-cli" ]; then
        ln -s "$TOOLS_DIR/plugin-cli.sh" "/usr/local/bin/plugin-cli"
        echo "✓ 创建全局符号链接: /usr/local/bin/plugin-cli"
    fi
fi

echo ""
echo "安装完成！"
echo ""
echo "使用方法:"
echo "  plugin-cli create-internal --name \"My Plugin\" --type tool"
echo "  plugin-cli create-external --name \"My Plugin\" --type executable --language dart"
echo "  plugin-cli --help"
echo ""
echo "配置文件位置: $CONFIG_FILE"
echo "日志目录: $CONFIG_DIR/logs"
echo ""

# 如果PATH未生效，提示用户
if ! command -v plugin-cli &> /dev/null; then
    echo "注意: 如果 'plugin-cli' 命令不可用，请运行以下命令："
    echo "  source $SHELL_RC"
    echo "或重新打开终端"
fi
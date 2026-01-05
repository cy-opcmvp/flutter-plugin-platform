#!/bin/bash
# Flutter插件平台 - 插件CLI工具 (Unix Shell脚本)

# 检查Dart是否安装
if ! command -v dart &> /dev/null; then
    echo "错误: 未找到Dart命令。请确保已安装Flutter SDK并将其添加到PATH中。"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 运行Dart脚本
dart "$SCRIPT_DIR/plugin_cli.dart" "$@"
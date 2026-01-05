@echo off
chcp 65001 >nul
REM Flutter插件平台 - 插件CLI工具 (Windows批处理脚本)

REM 检查Dart是否安装
where dart >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到Dart命令。请确保已安装Flutter SDK并将其添加到PATH中。
    exit /b 1
)

REM 获取脚本所在目录
set SCRIPT_DIR=%~dp0

REM 运行Dart脚本
dart "%SCRIPT_DIR%plugin_cli.dart" %*
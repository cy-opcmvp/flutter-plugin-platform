@echo off
chcp 65001 >nul
REM 简化的CLI工具设置脚本

echo Flutter插件平台 - CLI工具快速设置
echo ===================================

REM 检查Dart是否安装
where dart >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到Dart命令。请先安装Flutter SDK。
    echo 下载地址: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✓ 检测到Dart环境

REM 安装依赖
echo 正在安装CLI工具依赖...
cd tools
dart pub get
if %errorlevel% neq 0 (
    echo ✗ 依赖安装失败
    pause
    exit /b 1
)

echo ✓ 依赖安装成功

REM 测试CLI工具
echo 正在测试CLI工具...
dart plugin_cli.dart --version
if %errorlevel% neq 0 (
    echo ✗ CLI工具测试失败
    pause
    exit /b 1
)

cd ..
echo.
echo ✅ CLI工具设置完成！
echo.
echo 使用方法:
echo   dart tools/plugin_cli.dart create-internal --name "My Plugin" --type tool --author "Your Name"
echo   dart tools/plugin_cli.dart list-templates
echo   dart tools/plugin_cli.dart --help
echo.

pause
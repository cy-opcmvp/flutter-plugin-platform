@echo off
chcp 65001 >nul
REM Flutter插件平台 - CLI工具安装脚本 (Windows)

echo Flutter插件平台 - CLI工具安装程序
echo =====================================

REM 检查Dart是否安装
where dart >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: 未找到Dart命令。请先安装Flutter SDK。
    echo 下载地址: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✓ 检测到Dart环境

REM 获取当前目录
set CURRENT_DIR=%~dp0
set TOOLS_DIR=%CURRENT_DIR%

REM 检查是否已经在PATH中
echo %PATH% | findstr /C:"%TOOLS_DIR%" >nul
if %errorlevel% equ 0 (
    echo ✓ CLI工具已在PATH中
    goto :test_cli
)

REM 添加到用户PATH
echo 正在添加CLI工具到PATH...
for /f "usebackq tokens=2,*" %%A in (`reg query HKCU\Environment /v PATH 2^>nul`) do set USER_PATH=%%B
if defined USER_PATH (
    reg add HKCU\Environment /v PATH /t REG_EXPAND_SZ /d "%USER_PATH%;%TOOLS_DIR%" /f >nul
) else (
    reg add HKCU\Environment /v PATH /t REG_EXPAND_SZ /d "%TOOLS_DIR%" /f >nul
)

if %errorlevel% equ 0 (
    echo ✓ 已添加到用户PATH
    echo 注意: 请重新打开命令提示符以使PATH生效
) else (
    echo ⚠ 无法自动添加到PATH，请手动添加: %TOOLS_DIR%
)

:test_cli
REM 测试CLI工具
echo 正在测试CLI工具...
call "%TOOLS_DIR%plugin-cli.bat" --version
if %errorlevel% equ 0 (
    echo ✓ CLI工具安装成功！
) else (
    echo ✗ CLI工具测试失败
    exit /b 1
)

REM 创建配置目录
set CONFIG_DIR=%USERPROFILE%\.plugin-cli
if not exist "%CONFIG_DIR%" (
    mkdir "%CONFIG_DIR%"
    mkdir "%CONFIG_DIR%\logs"
    mkdir "%CONFIG_DIR%\templates"
    echo ✓ 创建配置目录: %CONFIG_DIR%
)

REM 创建默认配置文件
set CONFIG_FILE=%CONFIG_DIR%\config.json
if not exist "%CONFIG_FILE%" (
    echo 创建默认配置文件...
    (
        echo {
        echo   "defaultAuthor": "%USERNAME%",
        echo   "defaultEmail": "your.email@example.com",
        echo   "defaultLicense": "MIT",
        echo   "defaultRegistry": "https://registry.flutter-platform.com",
        echo   "templates": {
        echo     "customTemplatesPath": "%CONFIG_DIR%\\templates"
        echo   },
        echo   "build": {
        echo     "defaultPlatform": "windows",
        echo     "outputDirectory": "./dist"
        echo   }
        echo }
    ) > "%CONFIG_FILE%"
    echo ✓ 创建配置文件: %CONFIG_FILE%
)

echo.
echo 安装完成！
echo.
echo 使用方法:
echo   plugin-cli create-internal --name "My Plugin" --type tool
echo   plugin-cli create-external --name "My Plugin" --type executable --language dart
echo   plugin-cli --help
echo.
echo 配置文件位置: %CONFIG_FILE%
echo 日志目录: %CONFIG_DIR%\logs
echo.

pause
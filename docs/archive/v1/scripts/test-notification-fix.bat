@echo off
REM 通知服务修复测试脚本
REM 用于验证 Windows 平台上的通知功能

echo ========================================
echo 通知服务修复测试脚本
echo ========================================
echo.

echo [1/4] 检查 Flutter 环境...
flutter --version
if %errorlevel% neq 0 (
    echo 错误: Flutter 未安装或不在 PATH 中
    pause
    exit /b 1
)
echo ✓ Flutter 环境正常
echo.

echo [2/4] 检查依赖...
flutter pub get
if %errorlevel% neq 0 (
    echo 错误: 依赖安装失败
    pause
    exit /b 1
)
echo ✓ 依赖检查完成
echo.

echo [3/4] 检查 Windows 开发者模式...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense | find "0x1"
if %errorlevel% neq 0 (
    echo 警告: Windows 开发者模式未启用
    echo.
    echo 请启用开发者模式：
    echo 1. 打开 Windows 设置
    echo 2. 更新和安全 → 开发者
    echo 3. 启用"开发者模式"
    echo.
    echo 按任意键继续尝试运行...
    pause > nul
) else (
    echo ✓ Windows 开发者模式已启用
)
echo.

echo [4/4] 启动应用...
echo.
echo ========================================
echo 测试说明：
echo ========================================
echo 1. 导航到 Notifications 标签页
echo 2. 点击 "Show Now" 按钮
echo    预期: 显示蓝色 SnackBar
echo 3. 点击 "Schedule (5s)" 按钮
echo    预期: 5秒后显示 SnackBar
echo 4. 点击 "Cancel All" 按钮
echo    预期: 显示取消日志
echo.
echo 按任意键启动应用...
pause > nul

flutter run -d windows

echo.
echo ========================================
echo 测试完成
echo ========================================
pause

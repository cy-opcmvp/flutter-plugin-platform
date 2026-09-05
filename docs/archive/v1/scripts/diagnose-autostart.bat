@echo off
chcp 65001 >nul
echo ========================================
echo 开机自启功能诊断工具
echo ========================================
echo.

echo [1] 检查注册表中的开机自启项...
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v PluginPlatform 2>nul
if %errorlevel% equ 0 (
    echo [✓] 找到注册表项
) else (
    echo [×] 未找到注册表项
)
echo.

echo [2] 当前的可执行文件路径：
echo %~dp0build\windows\x64\runner\Debug\plugin_platform.exe
echo.

echo [3] 检查文件是否存在：
if exist "%~dp0build\windows\x64\runner\Debug\plugin_platform.exe" (
    echo [✓] Debug 版本存在
) else (
    echo [×] Debug 版本不存在
)
echo.

echo [4] 开发模式下的常见问题：
echo - 注册表中保存的路径指向临时构建目录
echo - 每次 flutter clean 后路径会变化
echo - Debug 版本的 exe 路径不稳定
echo.

echo ========================================
echo 建议：
echo ========================================
echo.
echo 如果要在开发阶段测试开机自启：
echo 1. 启用开机自启功能
echo 2. 手动检查注册表中的路径是否正确
echo 3. 确保路径指向的 exe 文件存在
echo 4. 如果不正确，删除注册表项后重新启用
echo.
echo 生产环境部署：
echo 1. 构建发布版本：flutter build windows --release
echo 2. 安装后重新启用开机自启
echo 3. 发布版本的路径是稳定的
echo.
pause

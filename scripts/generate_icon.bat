@echo off
REM 图标生成脚本 (Windows)
REM 需要 Python 和 Pillow 库

echo ============================================
echo 多功能插件平台 - 图标生成器
echo ============================================
echo.

REM 检查 Python 是否安装
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: 未找到 Python
    echo 请先安装 Python 3.6 或更高版本
    pause
    exit /b 1
)

REM 检查 Pillow 是否安装
python -c "import PIL" >nul 2>&1
if %errorlevel% neq 0 (
    echo Pillow 库未安装，正在安装...
    pip install Pillow
)

REM 运行图标生成脚本
python scripts\generate_app_icon.py

echo.
pause

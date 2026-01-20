@echo off
REM 重构完整性检查脚本 (Windows 版本)
REM 用法: check_refactoring.bat <搜索模式> [描述]

setlocal enabledelayedexpansion

if "%~1"=="" (
    echo 用法: check_refactoring.bat ^<搜索模式^> [描述]
    echo.
    echo 示例:
    echo   check_refactoring.bat "enablePlugin" "检查启用/禁用功能"
    exit /b 1
)

set "SEARCH_PATTERN=%~1"
set "DESCRIPTION=%~2"
if "%DESCRIPTION%"=="" set "DESCRIPTION=重构检查"

echo 🔍 开始: %DESCRIPTION%
echo 🎯 搜索模式: %SEARCH_PATTERN%
echo.

REM 临时文件
set "TEMP_FILE=%TEMP%\grep_results.txt"

REM 搜索 Dart 文件
echo 📂 搜索 Dart 文件...
findstr /S /N /I /C:"%SEARCH_PATTERN%" "*.dart" lib\ >nul 2>&1
if errorlevel 1 (
    echo ✅ Dart 文件中未发现引用
) else (
    echo ❌ 发现引用在 Dart 文件中:
    findstr /S /N /I /C:"%SEARCH_PATTERN%" "*.dart" lib\
    echo.
)

REM 搜索 ARB 文件
echo 📂 搜索国际化文件...
findstr /S /N /I /C:"%SEARCH_PATTERN%" "*.arb" lib\l10n\ >nul 2>&1
if errorlevel 1 (
    echo ✅ ARB 文件中未发现引用
) else (
    echo ⚠️  发现引用在 ARB 文件中:
    findstr /S /N /I /C:"%SEARCH_PATTERN%" "*.arb" lib\l10n\
    echo.
)

REM 搜索生成的国际化文件
echo 📂 搜索生成的国际化文件...
findstr /S /N /I /C:"%SEARCH_PATTERN%" "*.dart" lib\l10n\generated\ >nul 2>&1
if errorlevel 1 (
    echo ✅ 生成的文件中未发现引用
) else (
    echo ⚠️  发现引用在生成的文件中（需要重新生成）:
    findstr /S /N /I /C:"%SEARCH_PATTERN%" "*.dart" lib\l10n\generated\
    echo.
)

echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
echo 💡 提示：
echo   - 如果发现引用，请手动检查上述文件
echo   - 修改 ARB 文件后运行: flutter gen-l10n
echo   - 修改完成后运行: flutter analyze
echo.

endlocal

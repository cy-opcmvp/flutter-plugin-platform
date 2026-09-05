@echo off
REM 更新国际化文件的快捷脚本
REM 用法: scripts\update-i18n.bat

echo ========================================
echo Updating Internationalization Files
echo ========================================

echo.
echo [1/3] Generating localization files...
call flutter gen-l10n
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate localization files
    exit /b %errorlevel%
)

echo.
echo [2/3] Cleaning build cache...
call flutter clean
if %errorlevel% neq 0 (
    echo WARNING: Flutter clean had issues, but continuing...
)

echo.
echo [3/3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies
    exit /b %errorlevel%
)

echo.
echo ========================================
echo Internationalization update complete!
echo ========================================
echo.
echo You can now run the app with:
echo   flutter run -d windows
echo.

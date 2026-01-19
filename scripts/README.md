# Scripts Directory

This directory contains various scripts for development, building, and troubleshooting.

## 📁 Directory Structure

```
scripts/
├── README.md                  # This file
├── generate_app_icon.py       # App icon generation script
├── generate_icon.bat          # Windows icon generation batch script
├── fix-nuget.ps1              # NuGet package installation fix
└── install-cppwinrt.ps1       # Windows CppWinRT package installation
```

## 🔧 Available Scripts

### Icon Generation Scripts

#### `generate_app_icon.py`
**Purpose**: Generate application icons with a blue rectangular frame and white "P" letter.

**Design**:
- 3:4 aspect ratio blue rectangle
- White uppercase letter "P" in center
- Supports multiple sizes (16x16 to 1024x1024)
- Generates Windows ICO, macOS PNG, and general icons

**Usage**:
```bash
# Windows
python generate_app_icon.py

# macOS/Linux
python3 generate_app_icon.py
```

**Requirements**:
- Python 3.6+
- Pillow library: `pip install Pillow`

**When to use**:
- When updating app icon design
- When first setting up the project
- When adding new icon sizes

#### `generate_icon.bat`
**Purpose**: Windows batch script for quick icon generation.

**Usage**:
```bash
# Double-click or run in command prompt
generate_icon.bat
```

**When to use**:
- Quick icon generation on Windows
- Automatically installs dependencies if needed

### Windows Build Scripts

#### `fix-nuget.ps1`
**Purpose**: Downloads and installs the missing NuGet package `Microsoft.Windows.ImplementationLibrary` required by audioplayers_windows.

**Usage**:
```powershell
# Run with Administrator privileges
powershell -ExecutionPolicy Bypass -File fix-nuget.ps1
```

**When to use**:
- When building Windows app fails with NuGet package errors
- When `audioplayers_windows` CMakeLists.txt reports missing packages

#### `install-cppwinrt.ps1`
**Purpose**: Downloads and installs the missing NuGet package `Microsoft.Windows.CppWinRT` required by permission_handler_windows.

**Usage**:
```powershell
# Run with Administrator privileges
powershell -ExecutionPolicy Bypass -File install-cppwinrt.ps1
```

**When to use**:
- When building Windows app fails with CppWinRT package errors
- When `permission_handler_windows` CMakeLists.txt reports missing packages

## ⚠️ Important Notes

1. **Administrator Privileges**: All PowerShell scripts in this directory require Administrator privileges to run.
2. **Network Connection**: These scripts download packages from nuget.org, requiring internet connection.
3. **Temporary Solutions**: These scripts provide workarounds for Windows build issues. Long-term solutions should use alternative packages without NuGet dependencies.

## 🚀 Quick Start

If you're experiencing Windows build errors:

```powershell
# 1. Open PowerShell as Administrator
# 2. Navigate to project root
cd d:\Code\flutter-plugin-platform

# 3. Run the required fix script
.\scripts\fix-nuget.ps1
# or
.\scripts\install-cppwinrt.ps1

# 4. Try building again
flutter run -d windows
```

## 📚 Related Documentation

- [Icon Generation Guide](../docs/guides/ICON_GENERATION_GUIDE.md) - Detailed icon generation guide
- [Icon Update Guide](../ICON_UPDATE_GUIDE.md) - Quick icon update instructions
- [Windows Build Fix Guide](../docs/troubleshooting/WINDOWS_BUILD_FIX.md)
- [Windows Distribution Guide](../docs/WINDOWS_DISTRIBUTION_GUIDE.md)
- [Platform Services User Guide](../docs/guides/PLATFORM_SERVICES_USER_GUIDE.md)

## 🐛 Troubleshooting

### Script execution fails

**Error**: "Execution policy restriction"
**Solution**: Run with `-ExecutionPolicy Bypass` flag

### Package installation fails

**Error**: "Access denied"
**Solution**: Ensure PowerShell is running as Administrator

### Build still fails after running scripts

**Possible causes**:
1. NuGet package cache needs to be cleared
2. Flutter build cache needs to be cleared
3. Package version mismatch

**Solution**:
```powershell
flutter clean
flutter pub get
flutter run -d windows
```

## 💡 Alternative Solutions

If these scripts don't resolve your Windows build issues, consider:

1. **Remove problematic dependencies**: Temporarily disable `audioplayers` or `permission_handler`
2. **Use alternative packages**: Switch to packages without NuGet dependencies
3. **Build in Release mode**: `flutter build windows --release` (may have different requirements)

See [WINDOWS_BUILD_FIX.md](../docs/troubleshooting/WINDOWS_BUILD_FIX.md) for detailed solutions.

---

**Last Updated**: 2026-01-19
**Maintained By**: Flutter Plugin Platform Team

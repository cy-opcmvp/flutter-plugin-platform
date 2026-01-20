#ifndef RUNNER_SCREENSHOT_PLUGIN_H_
#define RUNNER_SCREENSHOT_PLUGIN_H_

// 定义 NOMINMAX 以避免 Windows 宏与 std::min/max 冲突
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>
#include <algorithm>  // 必须在 gdiplus.h 之前包含
#include <vector>
#include <string>
#include <tuple>

// 在全局作用域引入 std::min 和 std::max 供 GDI+ 使用
using std::min;
using std::max;

#include <gdiplus.h>

// Structure to hold window information with icon
struct WindowInfo {
    std::string title;
    std::string id;
    std::string appName;
    std::vector<uint8_t> icon;
};

// Initialize GDI+ (call once at startup)
void InitializeGDIPlus();

// Shutdown GDI+ (call once at shutdown)
void ShutdownGDIPlus();

// Capture full screen screenshot
// Returns PNG image data as byte vector
std::vector<uint8_t> CaptureFullScreen();

// Capture specific window screenshot
// hwnd: Window handle
// Returns PNG image data as byte vector
std::vector<uint8_t> CaptureWindow(HWND hwnd);

// Capture screen region screenshot
// x, y: Top-left corner of region
// width, height: Size of region
// Returns PNG image data as byte vector
std::vector<uint8_t> CaptureRegion(int x, int y, int width, int height);

// Enumerate all visible windows
// Returns vector of WindowInfo structures
std::vector<WindowInfo> EnumerateWindows();

// Convert HWND from string representation
HWND HwndFromString(const std::string& str);

// Helper function to get encoder CLSID for image format
int GetEncoderClsid(const WCHAR* format, CLSID* pClsid);

#endif  // RUNNER_SCREENSHOT_PLUGIN_H_

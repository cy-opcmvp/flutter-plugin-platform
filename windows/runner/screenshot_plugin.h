#ifndef RUNNER_SCREENSHOT_PLUGIN_H_
#define RUNNER_SCREENSHOT_PLUGIN_H_

// 不定义 NOMINMAX，让 GDI+ 可以使用 min/max 宏
#include <windows.h>
#include <algorithm>
#include <vector>
#include <string>
#include <tuple>

// GDI+ 需要 min/max 宏，确保它们可用
#ifndef min
#define min(a, b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef max
#define max(a, b) (((a) > (b)) ? (a) : (b))
#endif

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

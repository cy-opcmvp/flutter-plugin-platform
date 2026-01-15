#ifndef RUNNER_SCREENSHOT_PLUGIN_H_
#define RUNNER_SCREENSHOT_PLUGIN_H_

#include <windows.h>
#include <vector>
#include <string>
#include <tuple>

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
// Returns vector of tuples (title, windowId)
std::vector<std::tuple<std::string, std::string>> EnumerateWindows();

// Convert HWND from string representation
HWND HwndFromString(const std::string& str);

#endif  // RUNNER_SCREENSHOT_PLUGIN_H_

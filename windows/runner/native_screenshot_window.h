#ifndef RUNNER_NATIVE_SCREENSHOT_WINDOW_H_
#define RUNNER_NATIVE_SCREENSHOT_WINDOW_H_

// 定义 NOMINMAX 以避免 Windows 宏与 std::min/max 冲突
#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>

class NativeScreenshotWindow {
public:
    typedef void (*RegionSelectedCallback)(int x, int y, int width, int height);
    typedef void (*CancelledCallback)();

    NativeScreenshotWindow();
    ~NativeScreenshotWindow();

    bool Show(RegionSelectedCallback onSelected, CancelledCallback onCancelled);
    void Close();

private:
    HWND hwnd_;
    RegionSelectedCallback onSelected_;
    CancelledCallback onCancelled_;

    POINT startPoint_;
    POINT endPoint_;
    bool isSelecting_;

    HBITMAP hBackgroundBitmap_;  // 捕获的桌面背景
    int screenWidth_;
    int screenHeight_;

    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

    // Helper methods
    void CaptureDesktopBackground();
    void DrawSelectionBox(HDC hdc, int x, int y, int width, int height);
    void DrawMask(HDC hdc, int x, int y, int width, int height);
};

#endif  // RUNNER_NATIVE_SCREENSHOT_WINDOW_H_

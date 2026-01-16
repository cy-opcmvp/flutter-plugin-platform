#ifndef RUNNER_NATIVE_SCREENSHOT_WINDOW_H_
#define RUNNER_NATIVE_SCREENSHOT_WINDOW_H_

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
    LRESULT HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam);
    void DrawSelection(HDC hdc);
    bool CaptureDesktopBackground();
};

#endif
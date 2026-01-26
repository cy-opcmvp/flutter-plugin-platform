#ifndef RUNNER_NATIVE_SCREENSHOT_WINDOW_H_
#define RUNNER_NATIVE_SCREENSHOT_WINDOW_H_

#ifndef NOMINMAX
#define NOMINMAX
#endif

#include <windows.h>

// 窗口状态枚举
enum class ScreenshotState {
    Idle,           // 初始状态，全屏蒙版
    Hovering,       // 鼠标悬停，检测窗体
    Selected        // 已选择，显示控制点
};

// 控制点类型
enum class HandleType {
    None,
    TopLeft,        // 1
    TopCenter,      // 2
    TopRight,       // 3
    RightCenter,    // 4
    BottomRight,    // 5
    BottomCenter,   // 6
    BottomLeft,     // 7
    LeftCenter,     // 8
    Move            // 移动整个框
};

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

    // 选择区域
    RECT selectionRect_;
    ScreenshotState state_;

    // 拖拽状态
    bool isDragging_;
    HandleType activeHandle_;
    POINT dragStartPoint_;
    RECT dragStartRect_;

    // 放大镜
    static const int MAGNIFIER_SIZE = 150;
    static const int MAGNIFIER_ZOOM = 4;

    // 背景
    HBITMAP hBackgroundBitmap_;
    int screenWidth_;
    int screenHeight_;

    // 按钮
    RECT confirmButtonRect_;
    RECT cancelButtonRect_;
    bool isHoveringConfirm_;
    bool isHoveringCancel_;

    // 悬停检测
    HWND hHoveredWindow_;

    // 静态回调
    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);
    LRESULT HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam);

    // 绘制方法
    void DrawSelection(HDC hdc);
    void DrawMagnifier(HDC hdc, int mouseX, int mouseY);
    void DrawButtons(HDC hdc);
    void DrawDimmedMask(HDC hdc, const RECT& excludeRect);

    // 辅助方法
    bool CaptureDesktopBackground();
    HandleType HitTest(int x, int y);
    RECT GetHandleRect(HandleType handle, const RECT& rect);
    HCURSOR GetHandleCursor(HandleType handle);
    void UpdateSelectionFromDrag(int x, int y);
    void DetectWindowAtPoint(POINT pt, RECT& windowRect);
    void NormalizeRect(RECT& rect);
    bool PointInRect(POINT pt, const RECT& rect);
};

#endif

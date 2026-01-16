#include "native_screenshot_window.h"
#include <dwmapi.h>
#include <cwchar>
#include <string>
#include <windows.h>
#include <fstream>
#pragma comment(lib, "dwmapi.lib")

static const wchar_t kClassName[] = L"NativeScreenshotWindow";

// 文件日志函数
static void LogToFile(const char* message) {
  static std::ofstream logFile;
  static bool initialized = false;
  if (!initialized) {
    logFile.open("C:\\temp\\screenshot_native.log", std::ios::app);
    initialized = true;
  }
  if (logFile.is_open()) {
    logFile << message << std::endl;
    logFile.flush();
  }
}

// 简单的日志输出宏
#define LOG_DEBUG(msg) \
  do { \
    char buffer[512]; \
    sprintf_s(buffer, "[NativeScreenshotWindow] " msg "\n"); \
    OutputDebugStringA(buffer); \
    LogToFile(buffer); \
  } while (0)

#define LOG_DEBUG_FMT(msg, ...) \
  do { \
    char buffer[512]; \
    sprintf_s(buffer, sizeof(buffer), "[NativeScreenshotWindow] " msg "\n", __VA_ARGS__); \
    OutputDebugStringA(buffer); \
    LogToFile(buffer); \
  } while (0)

NativeScreenshotWindow::NativeScreenshotWindow()
    : hwnd_(NULL), onSelected_(NULL), onCancelled_(NULL), isSelecting_(false),
      hBackgroundBitmap_(NULL), screenWidth_(0), screenHeight_(0) {
    startPoint_.x = 0;
    startPoint_.y = 0;
    endPoint_.x = 0;
    endPoint_.y = 0;
}

NativeScreenshotWindow::~NativeScreenshotWindow() {
    Close();
    if (hBackgroundBitmap_) {
        DeleteObject(hBackgroundBitmap_);
        hBackgroundBitmap_ = NULL;
    }
}

bool NativeScreenshotWindow::Show(RegionSelectedCallback onSelected, CancelledCallback onCancelled) {
    LOG_DEBUG("Show() called");

    onSelected_ = onSelected;
    onCancelled_ = onCancelled;

    HINSTANCE hInstance = GetModuleHandle(NULL);
    LOG_DEBUG_FMT("Got module instance: 0x%p", hInstance);

    WNDCLASSEXW wc = {0};
    wc.cbSize = sizeof(WNDCLASSEXW);
    wc.style = CS_HREDRAW | CS_VREDRAW;
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(NULL, IDC_CROSS);
    wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
    wc.lpszClassName = kClassName;

    LOG_DEBUG("Registering window class...");
    if (!RegisterClassExW(&wc)) {
        DWORD error = GetLastError();
        if (error != ERROR_CLASS_ALREADY_EXISTS) {
            LOG_DEBUG_FMT("Failed to register window class, error: %lu", error);
            return false;
        }
        LOG_DEBUG("Window class already registered");
    }
    LOG_DEBUG("Window class registered successfully");

    screenWidth_ = GetSystemMetrics(SM_CXSCREEN);
    screenHeight_ = GetSystemMetrics(SM_CYSCREEN);
    LOG_DEBUG_FMT("Screen dimensions: %dx%d", screenWidth_, screenHeight_);

    // 捕获桌面背景
    if (!CaptureDesktopBackground()) {
        LOG_DEBUG("Failed to capture desktop background");
        return false;
    }

    LOG_DEBUG("Creating window...");
    // 不使用 WS_EX_LAYERED，使用普通窗口
    hwnd_ = CreateWindowExW(
        WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
        kClassName,
        L"Screenshot",
        WS_POPUP,
        0, 0, screenWidth_, screenHeight_,
        NULL, NULL, hInstance, this
    );

    if (!hwnd_) {
        LOG_DEBUG_FMT("Failed to create window, error: %lu", GetLastError());
        return false;
    }
    LOG_DEBUG_FMT("Window created successfully: 0x%p", hwnd_);

    LOG_DEBUG("Showing window...");
    ShowWindow(hwnd_, SW_SHOW);
    SetForegroundWindow(hwnd_);

    // 强制置顶窗口
    LOG_DEBUG("Setting window to topmost...");
    SetWindowPos(hwnd_, HWND_TOPMOST, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW);

    // 再次确保窗口在最上层
    BringWindowToTop(hwnd_);
    LOG_DEBUG("Window shown and set to topmost");

    // 进入消息循环，等待用户操作
    LOG_DEBUG("Entering message loop...");
    MSG msg;
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);

        // 确保窗口始终在最上层（处理某些应用可能抢占焦点的情况）
        if (IsWindow(hwnd_)) {
          SetWindowPos(hwnd_, HWND_TOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        } else {
          LOG_DEBUG("Window destroyed, exiting message loop");
          break;
        }
    }
    LOG_DEBUG("Message loop exited");

    return true;
}

void NativeScreenshotWindow::Close() {
    LOG_DEBUG("Close() called");
    if (hwnd_) {
        LOG_DEBUG("Posting quit message to exit message loop");
        PostQuitMessage(0);
        DestroyWindow(hwnd_);
        hwnd_ = NULL;
    }
}

LRESULT CALLBACK NativeScreenshotWindow::WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    NativeScreenshotWindow* window = NULL;

    if (msg == WM_CREATE) {
        CREATESTRUCT* cs = (CREATESTRUCT*)lParam;
        window = (NativeScreenshotWindow*)cs->lpCreateParams;
        SetWindowLongPtr(hwnd, GWLP_USERDATA, (LONG_PTR)window);
    } else {
        window = (NativeScreenshotWindow*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
    }

    if (window) {
        return window->HandleMessage(msg, wParam, lParam);
    }

    return DefWindowProc(hwnd, msg, wParam, lParam);
}

LRESULT NativeScreenshotWindow::HandleMessage(UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
        case WM_PAINT: {
            LOG_DEBUG("WM_PAINT");
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd_, &ps);

            // 始终绘制，即使没有选择时也显示背景
            DrawSelection(hdc);

            EndPaint(hwnd_, &ps);
            break;
        }

        case WM_LBUTTONDOWN: {
            LOG_DEBUG("WM_LBUTTONDOWN");
            isSelecting_ = true;
            startPoint_.x = LOWORD(lParam);
            startPoint_.y = HIWORD(lParam);
            endPoint_ = startPoint_;
            LOG_DEBUG_FMT("Start point: (%d, %d)", startPoint_.x, startPoint_.y);
            SetCapture(hwnd_);
            InvalidateRect(hwnd_, NULL, TRUE);
            break;
        }

        case WM_MOUSEMOVE: {
            if (isSelecting_) {
                endPoint_.x = LOWORD(lParam);
                endPoint_.y = HIWORD(lParam);
                // LOG_DEBUG_FMT("Mouse move: (%d, %d)", endPoint_.x, endPoint_.y);
                InvalidateRect(hwnd_, NULL, FALSE);
            }
            break;
        }

        case WM_LBUTTONUP: {
            LOG_DEBUG("WM_LBUTTONUP");
            if (isSelecting_) {
                isSelecting_ = false;
                ReleaseCapture();

                int left = (startPoint_.x < endPoint_.x) ? startPoint_.x : endPoint_.x;
                int top = (startPoint_.y < endPoint_.y) ? startPoint_.y : endPoint_.y;
                int width = abs(endPoint_.x - startPoint_.x);
                int height = abs(endPoint_.y - startPoint_.y);

                LOG_DEBUG_FMT("Selection: (%d, %d) size: %dx%d", left, top, width, height);

                if (width >= 10 && height >= 10) {
                    LOG_DEBUG("Calling onSelected callback");
                    if (onSelected_) {
                        onSelected_(left, top, width, height);
                    }
                } else {
                    LOG_DEBUG("Selection too small, calling onCancelled");
                    if (onCancelled_) {
                        onCancelled_();
                    }
                }

                Close();
            }
            break;
        }

        case WM_KEYDOWN: {
            LOG_DEBUG_FMT("WM_KEYDOWN, key code: 0x%X", static_cast<unsigned int>(wParam));
            if (wParam == VK_ESCAPE) {
                LOG_DEBUG("ESC pressed, cancelling");
                if (onCancelled_) {
                    onCancelled_();
                }
                Close();
            }
            break;
        }

        case WM_DESTROY: {
            LOG_DEBUG("WM_DESTROY");
            break;
        }

        default:
            return DefWindowProc(hwnd_, msg, wParam, lParam);
    }

    return 0;
}

void NativeScreenshotWindow::DrawSelection(HDC hdc) {
    // 使用双缓冲技术避免闪烁
    // 1. 创建内存 DC 和位图
    HDC hdcMem = CreateCompatibleDC(hdc);
    HBITMAP hbmMem = CreateCompatibleBitmap(hdc, screenWidth_, screenHeight_);
    HBITMAP hbmOld = (HBITMAP)SelectObject(hdcMem, hbmMem);

    // 2. 在内存 DC 中绘制背景
    if (hBackgroundBitmap_) {
        HDC hdcBg = CreateCompatibleDC(hdc);
        HBITMAP hbmBgOld = (HBITMAP)SelectObject(hdcBg, hBackgroundBitmap_);
        BitBlt(hdcMem, 0, 0, screenWidth_, screenHeight_, hdcBg, 0, 0, SRCCOPY);
        SelectObject(hdcBg, hbmBgOld);
        DeleteDC(hdcBg);
    } else {
        // 如果没有捕获到背景，填充黑色
        RECT rect = {0, 0, screenWidth_, screenHeight_};
        HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
        FillRect(hdcMem, &rect, hBrush);
        DeleteObject(hBrush);
    }

    // 如果没有选择，只显示背景
    if (!isSelecting_) {
        // 一次性将内存 DC 拷贝到屏幕
        BitBlt(hdc, 0, 0, screenWidth_, screenHeight_, hdcMem, 0, 0, SRCCOPY);
        SelectObject(hdcMem, hbmOld);
        DeleteObject(hbmMem);
        DeleteDC(hdcMem);
        return;
    }

    int left = (startPoint_.x < endPoint_.x) ? startPoint_.x : endPoint_.x;
    int top = (startPoint_.y < endPoint_.y) ? startPoint_.y : endPoint_.y;
    int right = (startPoint_.x > endPoint_.x) ? startPoint_.x : endPoint_.x;
    int bottom = (startPoint_.y > endPoint_.y) ? startPoint_.y : endPoint_.y;

    // 3. 在内存 DC 中绘制非选中区域的半透明黑色遮罩
    BLENDFUNCTION blend = { AC_SRC_OVER, 0, 160, 0 };  // 160/255 ≈ 63% 不透明度

    // 辅助函数：绘制单个区域的半透明遮罩
    auto drawDimmedRegion = [&](const RECT& rect) {
        if (rect.left >= rect.right || rect.top >= rect.bottom) {
            return;  // 跳过空区域
        }

        int width = rect.right - rect.left;
        int height = rect.bottom - rect.top;

        HDC hdcDim = CreateCompatibleDC(hdc);
        HBITMAP hbmDim = CreateCompatibleBitmap(hdc, width, height);
        HBITMAP hbmDimOld = (HBITMAP)SelectObject(hdcDim, hbmDim);

        // 填充黑色背景
        HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
        RECT fillRect = {0, 0, width, height};
        FillRect(hdcDim, &fillRect, hBrush);
        DeleteObject(hBrush);

        // 半透明混合到内存 DC
        AlphaBlend(hdcMem, rect.left, rect.top, width, height,
                   hdcDim, 0, 0, width, height, blend);

        SelectObject(hdcDim, hbmDimOld);
        DeleteObject(hbmDim);
        DeleteDC(hdcDim);
    };

    // 定义四个遮罩区域并绘制
    RECT topRect = {0, 0, screenWidth_, top};
    RECT bottomRect = {0, bottom, screenWidth_, screenHeight_};
    RECT leftRect = {0, top, left, bottom};
    RECT rightRect = {right, top, screenWidth_, bottom};

    drawDimmedRegion(topRect);
    drawDimmedRegion(bottomRect);
    drawDimmedRegion(leftRect);
    drawDimmedRegion(rightRect);

    // 4. 在内存 DC 中绘制红色边框
    HPEN hPen = CreatePen(PS_SOLID, 4, RGB(255, 0, 0));
    HPEN hOldPen = (HPEN)SelectObject(hdcMem, hPen);
    SelectObject(hdcMem, (HBRUSH)GetStockObject(NULL_BRUSH));
    Rectangle(hdcMem, left, top, right, bottom);
    SelectObject(hdcMem, hOldPen);
    DeleteObject(hPen);

    // 5. 在内存 DC 中绘制控制点
    HBRUSH hHandleBrush = CreateSolidBrush(RGB(255, 0, 0));
    int handleSize = 8;
    SelectObject(hdcMem, hHandleBrush);
    Ellipse(hdcMem, left - handleSize, top - handleSize, left + handleSize, top + handleSize);
    Ellipse(hdcMem, right - handleSize, top - handleSize, right + handleSize, top + handleSize);
    Ellipse(hdcMem, left - handleSize, bottom - handleSize, left + handleSize, bottom + handleSize);
    Ellipse(hdcMem, right - handleSize, bottom - handleSize, right + handleSize, bottom + handleSize);
    DeleteObject(hHandleBrush);

    // 6. 在内存 DC 中绘制尺寸文字
    wchar_t text[64];
    swprintf_s(text, 64, L"%d x %d", right - left, bottom - top);

    HFONT hFont = CreateFont(20, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Arial");
    HFONT hOldFont = (HFONT)SelectObject(hdcMem, hFont);

    RECT textRect = {left, top - 40, right, top};
    HBRUSH hTextBrush = CreateSolidBrush(RGB(255, 0, 0));
    FillRect(hdcMem, &textRect, hTextBrush);
    DeleteObject(hTextBrush);

    SetBkMode(hdcMem, TRANSPARENT);
    SetTextColor(hdcMem, RGB(255, 255, 255));
    DrawText(hdcMem, text, -1, &textRect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    SelectObject(hdcMem, hOldFont);
    DeleteObject(hFont);

    // 7. 一次性将内存 DC 的内容拷贝到屏幕（避免闪烁）
    BitBlt(hdc, 0, 0, screenWidth_, screenHeight_, hdcMem, 0, 0, SRCCOPY);

    // 8. 清理资源
    SelectObject(hdcMem, hbmOld);
    DeleteObject(hbmMem);
    DeleteDC(hdcMem);
}

bool NativeScreenshotWindow::CaptureDesktopBackground() {
    LOG_DEBUG("Capturing desktop background...");

    // 获取整个桌面的 DC
    HDC hdcDesktop = GetDC(NULL);
    if (!hdcDesktop) {
        LOG_DEBUG("Failed to get desktop DC");
        return false;
    }

    // 创建内存 DC 和位图
    HDC hdcMem = CreateCompatibleDC(hdcDesktop);
    if (!hdcMem) {
        LOG_DEBUG("Failed to create memory DC");
        ReleaseDC(NULL, hdcDesktop);
        return false;
    }

    hBackgroundBitmap_ = CreateCompatibleBitmap(hdcDesktop, screenWidth_, screenHeight_);
    if (!hBackgroundBitmap_) {
        LOG_DEBUG("Failed to create background bitmap");
        DeleteDC(hdcMem);
        ReleaseDC(NULL, hdcDesktop);
        return false;
    }

    HBITMAP hbmOld = (HBITMAP)SelectObject(hdcMem, hBackgroundBitmap_);

    // 捕获整个屏幕
    if (!BitBlt(hdcMem, 0, 0, screenWidth_, screenHeight_, hdcDesktop, 0, 0, SRCCOPY)) {
        LOG_DEBUG("Failed to capture screen");
        SelectObject(hdcMem, hbmOld);
        DeleteObject(hBackgroundBitmap_);
        hBackgroundBitmap_ = NULL;
        DeleteDC(hdcMem);
        ReleaseDC(NULL, hdcDesktop);
        return false;
    }

    SelectObject(hdcMem, hbmOld);
    DeleteDC(hdcMem);
    ReleaseDC(NULL, hdcDesktop);

    LOG_DEBUG("Desktop background captured successfully");
    return true;
}
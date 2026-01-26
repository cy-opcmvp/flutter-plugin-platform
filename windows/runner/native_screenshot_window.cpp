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
        logFile.open("C:\\\\temp\\\\screenshot_native.log", std::ios::app);
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

// 按钮尺寸
const int BUTTON_WIDTH = 80;
const int BUTTON_HEIGHT = 30;
const int BUTTON_MARGIN = 10;

NativeScreenshotWindow::NativeScreenshotWindow()
    : hwnd_(NULL), onSelected_(NULL), onCancelled_(NULL),
      state_(ScreenshotState::Idle),
      isDragging_(false), activeHandle_(HandleType::None),
      hBackgroundBitmap_(NULL), screenWidth_(0), screenHeight_(0),
      isHoveringConfirm_(false), isHoveringCancel_(false),
      hHoveredWindow_(NULL) {
    ZeroMemory(&selectionRect_, sizeof(RECT));
    ZeroMemory(&dragStartPoint_, sizeof(POINT));
    ZeroMemory(&dragStartRect_, sizeof(RECT));
    ZeroMemory(&confirmButtonRect_, sizeof(RECT));
    ZeroMemory(&cancelButtonRect_, sizeof(RECT));
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

        // 确保窗口始终在最上层
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
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hwnd_, &ps);

            // 始终绘制
            DrawSelection(hdc);

            EndPaint(hwnd_, &ps);
            break;
        }

        case WM_MOUSEMOVE: {
            int mouseX = LOWORD(lParam);
            int mouseY = HIWORD(lParam);

            // 如果正在拖拽，更新选择区域
            if (isDragging_) {
                if (state_ == ScreenshotState::Idle) {
                    // 自由框选中
                    selectionRect_.left = dragStartPoint_.x;
                    selectionRect_.top = dragStartPoint_.y;
                    selectionRect_.right = mouseX;
                    selectionRect_.bottom = mouseY;
                } else {
                    // 从预览框开始拖拽
                    UpdateSelectionFromDrag(mouseX, mouseY);
                }
                InvalidateRect(hwnd_, NULL, FALSE);
            } else if (state_ == ScreenshotState::Selected) {
                // 检查是否悬停在按钮上
                POINT pt = {mouseX, mouseY};
                bool wasHoveringConfirm = isHoveringConfirm_;
                bool wasHoveringCancel = isHoveringCancel_;

                isHoveringConfirm_ = PointInRect(pt, confirmButtonRect_);
                isHoveringCancel_ = PointInRect(pt, cancelButtonRect_);

                if (wasHoveringConfirm != isHoveringConfirm_ || wasHoveringCancel != isHoveringCancel_) {
                    InvalidateRect(hwnd_, NULL, FALSE);
                }

                // 更新光标
                HandleType handle = HitTest(mouseX, mouseY);
                HCURSOR hCursor = GetHandleCursor(handle);
                if (hCursor) {
                    SetCursor(hCursor);
                }
            } else if (state_ == ScreenshotState::Idle) {
                // 在空闲状态下检测窗体
                RECT windowRect;
                DetectWindowAtPoint({mouseX, mouseY}, windowRect);

                if (!IsRectEmpty(&windowRect)) {
                    // 有窗体，更新预览
                    selectionRect_ = windowRect;
                    state_ = ScreenshotState::Hovering;
                } else {
                    // 无窗体，保持空闲
                    state_ = ScreenshotState::Idle;
                }
                InvalidateRect(hwnd_, NULL, FALSE);
            }

            break;
        }

        case WM_LBUTTONDOWN: {
            int mouseX = LOWORD(lParam);
            int mouseY = HIWORD(lParam);

            // 检查按钮点击（仅在选中状态）
            if (state_ == ScreenshotState::Selected) {
                if (PointInRect({mouseX, mouseY}, confirmButtonRect_)) {
                    LOG_DEBUG("Confirm button clicked");
                    int width = selectionRect_.right - selectionRect_.left;
                    int height = selectionRect_.bottom - selectionRect_.top;
                    if (width >= 10 && height >= 10 && onSelected_) {
                        onSelected_(selectionRect_.left, selectionRect_.top, width, height);
                    }
                    Close();
                    return 0;
                }

                if (PointInRect({mouseX, mouseY}, cancelButtonRect_)) {
                    LOG_DEBUG("Cancel button clicked");
                    if (onCancelled_) {
                        onCancelled_();
                    }
                    Close();
                    return 0;
                }

                // 检查是否点击了8个控制点
                HandleType handle = HitTest(mouseX, mouseY);
                if (handle != HandleType::None && handle != HandleType::Move) {
                    // 开始调整大小
                    isDragging_ = true;
                    activeHandle_ = handle;
                    dragStartPoint_ = {mouseX, mouseY};
                    dragStartRect_ = selectionRect_;
                    SetCapture(hwnd_);
                    InvalidateRect(hwnd_, NULL, FALSE);
                    return 0;
                }
            }

            // 开始拖拽或自由框选
            isDragging_ = true;
            dragStartPoint_ = {mouseX, mouseY};

            if (state_ == ScreenshotState::Hovering) {
                // 从预览框开始拖拽
                dragStartRect_ = selectionRect_;
                activeHandle_ = HandleType::Move;
            } else if (state_ == ScreenshotState::Selected) {
                // 从选中状态开始拖拽整个框
                dragStartRect_ = selectionRect_;
                activeHandle_ = HandleType::Move;
            } else {
                // Idle 状态：自由框选
                dragStartRect_ = {mouseX, mouseY, mouseX, mouseY};
                activeHandle_ = HandleType::None; // 自由框选
            }

            SetCapture(hwnd_);
            break;
        }

        case WM_LBUTTONUP: {
            if (isDragging_) {
                isDragging_ = false;
                ReleaseCapture();

                NormalizeRect(selectionRect_);
                int width = selectionRect_.right - selectionRect_.left;
                int height = selectionRect_.bottom - selectionRect_.top;

                if (width >= 10 && height >= 10) {
                    state_ = ScreenshotState::Selected;

                    // 计算按钮位置（紧贴的工具栏样式）
                    confirmButtonRect_.left = selectionRect_.right + BUTTON_MARGIN;
                    confirmButtonRect_.top = selectionRect_.bottom + BUTTON_MARGIN;
                    confirmButtonRect_.right = confirmButtonRect_.left + BUTTON_WIDTH;
                    confirmButtonRect_.bottom = confirmButtonRect_.top + BUTTON_HEIGHT;

                    cancelButtonRect_.left = confirmButtonRect_.right; // 紧贴确定按钮
                    cancelButtonRect_.top = confirmButtonRect_.top;
                    cancelButtonRect_.right = cancelButtonRect_.left + BUTTON_WIDTH;
                    cancelButtonRect_.bottom = cancelButtonRect_.top + BUTTON_HEIGHT;

                    LOG_DEBUG_FMT("Selection complete: (%d, %d) size: %dx%d",
                                selectionRect_.left, selectionRect_.top, width, height);
                } else {
                    state_ = ScreenshotState::Idle;
                }

                InvalidateRect(hwnd_, NULL, FALSE);
            }
            break;
        }

        case WM_KEYDOWN: {
            if (wParam == VK_ESCAPE) {
                LOG_DEBUG("ESC pressed, cancelling");
                if (onCancelled_) {
                    onCancelled_();
                }
                Close();
                return 0;
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
    // 使用双缓冲技术
    HDC hdcMem = CreateCompatibleDC(hdc);
    HBITMAP hbmMem = CreateCompatibleBitmap(hdc, screenWidth_, screenHeight_);
    HBITMAP hbmOld = (HBITMAP)SelectObject(hdcMem, hbmMem);

    // 绘制背景
    if (hBackgroundBitmap_) {
        HDC hdcBg = CreateCompatibleDC(hdc);
        HBITMAP hbmBgOld = (HBITMAP)SelectObject(hdcBg, hBackgroundBitmap_);
        BitBlt(hdcMem, 0, 0, screenWidth_, screenHeight_, hdcBg, 0, 0, SRCCOPY);
        SelectObject(hdcBg, hbmBgOld);
        DeleteDC(hdcBg);
    } else {
        RECT rect = {0, 0, screenWidth_, screenHeight_};
        HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
        FillRect(hdcMem, &rect, hBrush);
        DeleteObject(hBrush);
    }

    // 根据状态绘制不同的内容
    if (state_ == ScreenshotState::Idle && !isDragging_) {
        // 空闲状态：绘制全屏蒙版（不排除任何区域）
        RECT emptyRect = {0, 0, 0, 0};
        DrawDimmedMask(hdcMem, emptyRect);
        // 不绘制选择框和控制点
    } else {
        // 有选择内容：绘制遮罩和选择框
        RECT excludeRect = selectionRect_;
        DrawDimmedMask(hdcMem, excludeRect);

        // 绘制选择框
        int left = selectionRect_.left;
        int top = selectionRect_.top;
        int right = selectionRect_.right;
        int bottom = selectionRect_.bottom;

        // 绘制边框
        HPEN hPen = CreatePen(PS_SOLID, 3, RGB(255, 0, 0));
        HPEN hOldPen = (HPEN)SelectObject(hdcMem, hPen);
        SelectObject(hdcMem, (HBRUSH)GetStockObject(NULL_BRUSH));

        if (state_ == ScreenshotState::Hovering && !isDragging_) {
            // 虚线边框（预览状态）
            HPEN hDashPen = CreatePen(PS_DOT, 2, RGB(255, 0, 0));
            SelectObject(hdcMem, hDashPen);
            Rectangle(hdcMem, left, top, right, bottom);
            SelectObject(hdcMem, hPen);
            DeleteObject(hDashPen);
        } else {
            // 实线边框（拖拽中或已选择）
            Rectangle(hdcMem, left, top, right, bottom);
        }

        SelectObject(hdcMem, hOldPen);
        DeleteObject(hPen);

        // 绘制8个控制点（仅在选中状态）
        if (state_ == ScreenshotState::Selected) {
            HBRUSH hHandleBrush = CreateSolidBrush(RGB(255, 0, 0));
            SelectObject(hdcMem, hHandleBrush);

            for (int i = (int)HandleType::TopLeft; i <= (int)HandleType::LeftCenter; i++) {
                RECT handleRect = GetHandleRect((HandleType)i, selectionRect_);
                Ellipse(hdcMem, handleRect.left, handleRect.top, handleRect.right, handleRect.bottom);
            }

            DeleteObject(hHandleBrush);

            // 绘制尺寸文字（左下角）
            wchar_t text[64];
            swprintf_s(text, 64, L"%d x %d", right - left, bottom - top);

            HFONT hFont = CreateFont(18, 0, 0, 0, FW_BOLD, FALSE, FALSE, FALSE,
                                    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                                    DEFAULT_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Arial");
            HFONT hOldFont = (HFONT)SelectObject(hdcMem, hFont);

            RECT textRect = {left, bottom + 5, left + 150, bottom + 30};
            SetBkMode(hdcMem, TRANSPARENT);
            SetTextColor(hdcMem, RGB(255, 255, 255));
            DrawText(hdcMem, text, -1, &textRect, DT_LEFT | DT_VCENTER | DT_SINGLELINE);

            SelectObject(hdcMem, hOldFont);
            DeleteObject(hFont);

            // 绘制按钮
            DrawButtons(hdcMem);
        }
    }

    // 始终绘制放大镜（在所有状态下）
    POINT cursorPos;
    GetCursorPos(&cursorPos);
    ScreenToClient(hwnd_, &cursorPos);
    DrawMagnifier(hdcMem, cursorPos.x, cursorPos.y);

    // 一次性拷贝到屏幕
    BitBlt(hdc, 0, 0, screenWidth_, screenHeight_, hdcMem, 0, 0, SRCCOPY);

    SelectObject(hdcMem, hbmOld);
    DeleteObject(hbmMem);
    DeleteDC(hdcMem);
}

void NativeScreenshotWindow::DrawMagnifier(HDC hdc, int mouseX, int mouseY) {
    // 如果鼠标不在窗口内，不绘制
    if (mouseX < 0 || mouseX >= screenWidth_ || mouseY < 0 || mouseY >= screenHeight_) {
        return;
    }

    // 放大镜位置（右上角，偏移20px）
    int magX = mouseX + 20;
    int magY = mouseY + 20;

    // 确保放大镜不会超出屏幕
    if (magX + MAGNIFIER_SIZE > screenWidth_) {
        magX = mouseX - MAGNIFIER_SIZE - 20;
    }
    if (magY + MAGNIFIER_SIZE + 30 > screenHeight_) {
        magY = mouseY - MAGNIFIER_SIZE - 30;
    }

    // 放大镜圆角半径（小圆角）
    const int CORNER_RADIUS = 8;

    // 绘制阴影（灰色半透明）
    RECT shadowRect = {magX + 3, magY + 3, magX + MAGNIFIER_SIZE + 3, magY + MAGNIFIER_SIZE + 3};

    // 使用分层窗口绘制阴影
    HDC hdcShadow = CreateCompatibleDC(hdc);
    HBITMAP hbmShadow = CreateCompatibleBitmap(hdc, MAGNIFIER_SIZE, MAGNIFIER_SIZE);
    HBITMAP hbmShadowOld = (HBITMAP)SelectObject(hdcShadow, hbmShadow);

    // 填充半透明灰色
    BLENDFUNCTION blendShadow = { AC_SRC_OVER, 0, 80, 0 }; // 透明度 80/255
    HBRUSH hShadowBrush = CreateSolidBrush(RGB(128, 128, 128));
    RECT fillShadowRect = {0, 0, MAGNIFIER_SIZE, MAGNIFIER_SIZE};
    FillRect(hdcShadow, &fillShadowRect, hShadowBrush);
    DeleteObject(hShadowBrush);

    // 绘制圆角阴影
    HRGN hRgnShadow = CreateRoundRectRgn(0, 0, MAGNIFIER_SIZE, MAGNIFIER_SIZE, CORNER_RADIUS, CORNER_RADIUS);
    SelectClipRgn(hdcShadow, hRgnShadow);

    AlphaBlend(hdc, shadowRect.left, shadowRect.top, MAGNIFIER_SIZE, MAGNIFIER_SIZE,
               hdcShadow, 0, 0, MAGNIFIER_SIZE, MAGNIFIER_SIZE, blendShadow);

    SelectObject(hdcShadow, hbmShadowOld);
    DeleteObject(hbmShadow);
    DeleteDC(hdcShadow);
    DeleteObject(hRgnShadow);

    // 绘制放大镜背景（白色圆角矩形）
    RECT magRect = {magX, magY, magX + MAGNIFIER_SIZE, magY + MAGNIFIER_SIZE};

    // 创建圆角矩形区域用于裁剪
    HRGN hRgn = CreateRoundRectRgn(magRect.left, magRect.top, magRect.right, magRect.bottom,
                                   CORNER_RADIUS, CORNER_RADIUS);
    SelectClipRgn(hdc, hRgn);

    HBRUSH hBgBrush = CreateSolidBrush(RGB(255, 255, 255));
    FillRect(hdc, &magRect, hBgBrush);
    DeleteObject(hBgBrush);

    // 绘制圆角边框（灰色）
    HPEN hPen = CreatePen(PS_SOLID, 2, RGB(128, 128, 128));
    HPEN hOldPen = (HPEN)SelectObject(hdc, hPen);
    HBRUSH hOldBrush = (HBRUSH)SelectObject(hdc, (HBRUSH)GetStockObject(NULL_BRUSH));
    RoundRect(hdc, magRect.left, magRect.top, magRect.right, magRect.bottom,
              CORNER_RADIUS, CORNER_RADIUS);
    SelectObject(hdc, hOldBrush);
    SelectObject(hdc, hOldPen);
    DeleteObject(hPen);

    // 获取鼠标位置的像素颜色
    COLORREF pixelColor = 0;
    if (hBackgroundBitmap_) {
        HDC hdcBg = CreateCompatibleDC(hdc);
        HBITMAP hbmBgOld = (HBITMAP)SelectObject(hdcBg, hBackgroundBitmap_);
        pixelColor = GetPixel(hdcBg, mouseX, mouseY);
        SelectObject(hdcBg, hbmBgOld);
        DeleteDC(hdcBg);
    }

    // 重新应用圆角裁剪（用于内容绘制）
    HRGN hContentRgn = CreateRoundRectRgn(magRect.left, magRect.top, magRect.right, magRect.bottom,
                                         CORNER_RADIUS, CORNER_RADIUS);
    SelectClipRgn(hdc, hContentRgn);
    ExtSelectClipRgn(hdc, NULL, RGN_AND); // 确保裁剪生效

    // 计算放大区域的源矩形
    int zoomHalfSize = MAGNIFIER_SIZE / (2 * MAGNIFIER_ZOOM);
    int srcX = mouseX - zoomHalfSize;
    int srcY = mouseY - zoomHalfSize;

    // 绘制放大的内容
    if (hBackgroundBitmap_) {
        HDC hdcBg = CreateCompatibleDC(hdc);
        HBITMAP hbmBgOld = (HBITMAP)SelectObject(hdcBg, hBackgroundBitmap_);

        StretchBlt(hdc, magX, magY, MAGNIFIER_SIZE, MAGNIFIER_SIZE,
                   hdcBg, srcX, srcY, MAGNIFIER_SIZE / MAGNIFIER_ZOOM, MAGNIFIER_SIZE / MAGNIFIER_ZOOM,
                   SRCCOPY);

        SelectObject(hdcBg, hbmBgOld);
        DeleteDC(hdcBg);
    }

    // 绘制中心十字
    HPEN hCrossPen = CreatePen(PS_SOLID, 1, RGB(255, 0, 0));
    HPEN hOldPen2 = (HPEN)SelectObject(hdc, hCrossPen);
    MoveToEx(hdc, magX + MAGNIFIER_SIZE / 2, magY, NULL);
    LineTo(hdc, magX + MAGNIFIER_SIZE / 2, magY + MAGNIFIER_SIZE);
    MoveToEx(hdc, magX, magY + MAGNIFIER_SIZE / 2, NULL);
    LineTo(hdc, magX + MAGNIFIER_SIZE, magY + MAGNIFIER_SIZE / 2);
    SelectObject(hdc, hOldPen2);
    DeleteObject(hCrossPen);

    // 恢复裁剪区域（取消圆角裁剪）
    SelectClipRgn(hdc, NULL);
    DeleteObject(hContentRgn);

    // 绘制RGB值（在放大镜下方，分两行显示）
    int r = GetRValue(pixelColor);
    int g = GetGValue(pixelColor);
    int b = GetBValue(pixelColor);

    // 背景需要更大（两行文本）
    const int RGB_HEIGHT = 35;
    RECT rgbRect = {magX, magY + MAGNIFIER_SIZE + 5, magX + MAGNIFIER_SIZE, magY + MAGNIFIER_SIZE + 5 + RGB_HEIGHT};

    // 半透明黑色背景
    BLENDFUNCTION blend = { AC_SRC_OVER, 0, 200, 0 };
    HDC hdcRgb = CreateCompatibleDC(hdc);
    HBITMAP hbmRgb = CreateCompatibleBitmap(hdc, MAGNIFIER_SIZE, RGB_HEIGHT);
    HBITMAP hbmRgbOld = (HBITMAP)SelectObject(hdcRgb, hbmRgb);

    HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
    RECT fillRect = {0, 0, MAGNIFIER_SIZE, RGB_HEIGHT};
    FillRect(hdcRgb, &fillRect, hBrush);
    DeleteObject(hBrush);

    AlphaBlend(hdc, rgbRect.left, rgbRect.top, MAGNIFIER_SIZE, RGB_HEIGHT,
               hdcRgb, 0, 0, MAGNIFIER_SIZE, RGB_HEIGHT, blend);

    SelectObject(hdcRgb, hbmRgbOld);
    DeleteObject(hbmRgb);
    DeleteDC(hdcRgb);

    // 绘制两行文本
    HFONT hFont = CreateFont(14, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
                            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Arial");
    HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, RGB(255, 255, 255));

    // 第一行：RGB值
    wchar_t rgbText1[64];
    swprintf_s(rgbText1, 64, L"RGB(%d, %d, %d)", r, g, b);
    RECT rgbRect1 = {magX, magY + MAGNIFIER_SIZE + 5, magX + MAGNIFIER_SIZE, magY + MAGNIFIER_SIZE + 20};
    DrawText(hdc, rgbText1, -1, &rgbRect1, DT_CENTER | DT_TOP | DT_SINGLELINE);

    // 第二行：#值
    wchar_t rgbText2[64];
    swprintf_s(rgbText2, 64, L"#%02X%02X%02X", r, g, b);
    RECT rgbRect2 = {magX, magY + MAGNIFIER_SIZE + 20, magX + MAGNIFIER_SIZE, magY + MAGNIFIER_SIZE + 5 + RGB_HEIGHT};
    DrawText(hdc, rgbText2, -1, &rgbRect2, DT_CENTER | DT_TOP | DT_SINGLELINE);

    SelectObject(hdc, hOldFont);
    DeleteObject(hFont);
}

void NativeScreenshotWindow::DrawButtons(HDC hdc) {
    // 绘制确定按钮
    HBRUSH hConfirmBrush = isHoveringConfirm_ ?
        CreateSolidBrush(RGB(0, 120, 215)) : CreateSolidBrush(RGB(0, 100, 180));
    HPEN hPen = CreatePen(PS_SOLID, 2, RGB(255, 255, 255));
    HPEN hOldPen = (HPEN)SelectObject(hdc, hPen);
    HBRUSH hOldBrush = (HBRUSH)SelectObject(hdc, hConfirmBrush);

    RoundRect(hdc, confirmButtonRect_.left, confirmButtonRect_.top,
              confirmButtonRect_.right, confirmButtonRect_.bottom, 5, 5);

    SelectObject(hdc, hOldBrush);
    DeleteObject(hConfirmBrush);

    SetBkMode(hdc, TRANSPARENT);
    SetTextColor(hdc, RGB(255, 255, 255));

    HFONT hFont = CreateFont(16, 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
                            DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
                            DEFAULT_QUALITY, DEFAULT_PITCH | FF_SWISS, L"Microsoft YaHei");
    HFONT hOldFont = (HFONT)SelectObject(hdc, hFont);

    DrawText(hdc, L"确定", -1, &confirmButtonRect_, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    // 绘制取消按钮
    HBRUSH hCancelBrush = isHoveringCancel_ ?
        CreateSolidBrush(RGB(200, 50, 50)) : CreateSolidBrush(RGB(180, 40, 40));
    SelectObject(hdc, hCancelBrush);

    RoundRect(hdc, cancelButtonRect_.left, cancelButtonRect_.top,
              cancelButtonRect_.right, cancelButtonRect_.bottom, 5, 5);

    SelectObject(hdc, hOldBrush);
    DeleteObject(hCancelBrush);

    DrawText(hdc, L"取消", -1, &cancelButtonRect_, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

    SelectObject(hdc, hOldFont);
    DeleteObject(hFont);
    SelectObject(hdc, hOldPen);
    DeleteObject(hPen);
}

void NativeScreenshotWindow::DrawDimmedMask(HDC hdc, const RECT& excludeRect) {
    BLENDFUNCTION blend = { AC_SRC_OVER, 0, 160, 0 };

    auto drawDimmedRegion = [&](const RECT& rect) {
        if (rect.left >= rect.right || rect.top >= rect.bottom) {
            return;
        }

        int width = rect.right - rect.left;
        int height = rect.bottom - rect.top;

        HDC hdcDim = CreateCompatibleDC(hdc);
        HBITMAP hbmDim = CreateCompatibleBitmap(hdc, width, height);
        HBITMAP hbmDimOld = (HBITMAP)SelectObject(hdcDim, hbmDim);

        HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
        RECT fillRect = {0, 0, width, height};
        FillRect(hdcDim, &fillRect, hBrush);
        DeleteObject(hBrush);

        AlphaBlend(hdc, rect.left, rect.top, width, height,
                   hdcDim, 0, 0, width, height, blend);

        SelectObject(hdcDim, hbmDimOld);
        DeleteObject(hbmDim);
        DeleteDC(hdcDim);
    };

    // 四个遮罩区域
    RECT topRect = {0, 0, screenWidth_, excludeRect.top};
    RECT bottomRect = {0, excludeRect.bottom, screenWidth_, screenHeight_};
    RECT leftRect = {0, excludeRect.top, excludeRect.left, excludeRect.bottom};
    RECT rightRect = {excludeRect.right, excludeRect.top, screenWidth_, excludeRect.bottom};

    drawDimmedRegion(topRect);
    drawDimmedRegion(bottomRect);
    drawDimmedRegion(leftRect);
    drawDimmedRegion(rightRect);
}

bool NativeScreenshotWindow::CaptureDesktopBackground() {
    LOG_DEBUG("Capturing desktop background...");

    HDC hdcDesktop = GetDC(NULL);
    if (!hdcDesktop) {
        LOG_DEBUG("Failed to get desktop DC");
        return false;
    }

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

HandleType NativeScreenshotWindow::HitTest(int x, int y) {
    if (state_ != ScreenshotState::Selected) {
        return HandleType::None;
    }

    const int HANDLE_SIZE = 10;

    // 检查控制点
    for (int i = (int)HandleType::TopLeft; i <= (int)HandleType::LeftCenter; i++) {
        RECT handleRect = GetHandleRect((HandleType)i, selectionRect_);
        if (x >= handleRect.left && x <= handleRect.right &&
            y >= handleRect.top && y <= handleRect.bottom) {
            return (HandleType)i;
        }
    }

    // 检查是否在选择框内部
    if (x >= selectionRect_.left && x <= selectionRect_.right &&
        y >= selectionRect_.top && y <= selectionRect_.bottom) {
        return HandleType::Move;
    }

    return HandleType::None;
}

RECT NativeScreenshotWindow::GetHandleRect(HandleType handle, const RECT& rect) {
    const int HANDLE_SIZE = 8;
    const int HALF_SIZE = HANDLE_SIZE / 2;

    int centerX = (rect.left + rect.right) / 2;
    int centerY = (rect.top + rect.bottom) / 2;

    switch (handle) {
        case HandleType::TopLeft:
            return {rect.left - HALF_SIZE, rect.top - HALF_SIZE,
                    rect.left + HALF_SIZE, rect.top + HALF_SIZE};
        case HandleType::TopCenter:
            return {centerX - HALF_SIZE, rect.top - HALF_SIZE,
                    centerX + HALF_SIZE, rect.top + HALF_SIZE};
        case HandleType::TopRight:
            return {rect.right - HALF_SIZE, rect.top - HALF_SIZE,
                    rect.right + HALF_SIZE, rect.top + HALF_SIZE};
        case HandleType::RightCenter:
            return {rect.right - HALF_SIZE, centerY - HALF_SIZE,
                    rect.right + HALF_SIZE, centerY + HALF_SIZE};
        case HandleType::BottomRight:
            return {rect.right - HALF_SIZE, rect.bottom - HALF_SIZE,
                    rect.right + HALF_SIZE, rect.bottom + HALF_SIZE};
        case HandleType::BottomCenter:
            return {centerX - HALF_SIZE, rect.bottom - HALF_SIZE,
                    centerX + HALF_SIZE, rect.bottom + HALF_SIZE};
        case HandleType::BottomLeft:
            return {rect.left - HALF_SIZE, rect.bottom - HALF_SIZE,
                    rect.left + HALF_SIZE, rect.bottom + HALF_SIZE};
        case HandleType::LeftCenter:
            return {rect.left - HALF_SIZE, centerY - HALF_SIZE,
                    rect.left + HALF_SIZE, centerY + HALF_SIZE};
        default:
            return {0, 0, 0, 0};
    }
}

HCURSOR NativeScreenshotWindow::GetHandleCursor(HandleType handle) {
    switch (handle) {
        case HandleType::TopLeft:
        case HandleType::BottomRight:
            return LoadCursor(NULL, IDC_SIZENWSE);
        case HandleType::TopRight:
        case HandleType::BottomLeft:
            return LoadCursor(NULL, IDC_SIZENESW);
        case HandleType::TopCenter:
        case HandleType::BottomCenter:
            return LoadCursor(NULL, IDC_SIZENS);
        case HandleType::LeftCenter:
        case HandleType::RightCenter:
            return LoadCursor(NULL, IDC_SIZEWE);
        case HandleType::Move:
            return LoadCursor(NULL, IDC_SIZEALL);
        default:
            return LoadCursor(NULL, IDC_ARROW);
    }
}

void NativeScreenshotWindow::UpdateSelectionFromDrag(int x, int y) {
    int deltaX = x - dragStartPoint_.x;
    int deltaY = y - dragStartPoint_.y;

    if (activeHandle_ == HandleType::None) {
        // 自由框选：直接设置矩形
        selectionRect_.left = dragStartPoint_.x;
        selectionRect_.top = dragStartPoint_.y;
        selectionRect_.right = x;
        selectionRect_.bottom = y;
    } else {
        // 从预览框拖拽或调整控制点
        switch (activeHandle_) {
            case HandleType::TopLeft:
                selectionRect_.left = dragStartRect_.left + deltaX;
                selectionRect_.top = dragStartRect_.top + deltaY;
                break;
            case HandleType::TopCenter:
                selectionRect_.top = dragStartRect_.top + deltaY;
                break;
            case HandleType::TopRight:
                selectionRect_.right = dragStartRect_.right + deltaX;
                selectionRect_.top = dragStartRect_.top + deltaY;
                break;
            case HandleType::RightCenter:
                selectionRect_.right = dragStartRect_.right + deltaX;
                break;
            case HandleType::BottomRight:
                selectionRect_.right = dragStartRect_.right + deltaX;
                selectionRect_.bottom = dragStartRect_.bottom + deltaY;
                break;
            case HandleType::BottomCenter:
                selectionRect_.bottom = dragStartRect_.bottom + deltaY;
                break;
            case HandleType::BottomLeft:
                selectionRect_.left = dragStartRect_.left + deltaX;
                selectionRect_.bottom = dragStartRect_.bottom + deltaY;
                break;
            case HandleType::LeftCenter:
                selectionRect_.left = dragStartRect_.left + deltaX;
                break;
            case HandleType::Move:
                selectionRect_.left = dragStartRect_.left + deltaX;
                selectionRect_.top = dragStartRect_.top + deltaY;
                selectionRect_.right = dragStartRect_.right + deltaX;
                selectionRect_.bottom = dragStartRect_.bottom + deltaY;
                break;
            default:
                break;
        }
    }

    NormalizeRect(selectionRect_);
}

void NativeScreenshotWindow::DetectWindowAtPoint(POINT pt, RECT& windowRect) {
    HWND hwnd = WindowFromPoint(pt);
    if (!hwnd || hwnd == hwnd_) {
        windowRect = {0, 0, 0, 0};
        hHoveredWindow_ = NULL;
        return;
    }

    // 获取窗口矩形
    GetWindowRect(hwnd, &windowRect);

    // 排除过小的窗口
    int width = windowRect.right - windowRect.left;
    int height = windowRect.bottom - windowRect.top;

    if (width < 50 || height < 50) {
        windowRect = {0, 0, 0, 0};
        hHoveredWindow_ = NULL;
        return;
    }

    // 转换为屏幕坐标
    RECT screenRect;
    screenRect.left = windowRect.left;
    screenRect.top = windowRect.top;
    screenRect.right = windowRect.right;
    screenRect.bottom = windowRect.bottom;

    windowRect = screenRect;
    hHoveredWindow_ = hwnd;
}

void NativeScreenshotWindow::NormalizeRect(RECT& rect) {
    if (rect.left > rect.right) {
        int temp = rect.left;
        rect.left = rect.right;
        rect.right = temp;
    }
    if (rect.top > rect.bottom) {
        int temp = rect.top;
        rect.top = rect.bottom;
        rect.bottom = temp;
    }
}

bool NativeScreenshotWindow::PointInRect(POINT pt, const RECT& rect) {
    return pt.x >= rect.left && pt.x <= rect.right &&
           pt.y >= rect.top && pt.y <= rect.bottom;
}

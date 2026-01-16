#include "hotkey_manager.h"
#include <algorithm>
#include <cctype>
#include <sstream>

HotkeyManager::HotkeyManager() : _nextAtomId(kBaseAtomId) {}

HotkeyManager::~HotkeyManager() {
    UnregisterAll();
}

bool HotkeyManager::RegisterHotkey(const std::string& actionId,
                                   const std::string& shortcut) {
    // 如果已存在，先注销
    if (_hotkeyIds.find(actionId) != _hotkeyIds.end()) {
        UnregisterHotkey(actionId);
    }

    UINT vk, modifiers;
    if (!ParseShortcut(shortcut, &vk, &modifiers)) {
        return false;
    }

    int atomId = GenerateAtomId();
    HWND hwnd = GetActiveWindow();
    if (!hwnd) {
        hwnd = GetForegroundWindow();
    }
    if (!hwnd) {
        // 尝试获取 Flutter 窗口
        hwnd = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"flutter_app");
    }

    if (!RegisterHotKey(hwnd, atomId, modifiers, vk)) {
        // 如果失败，尝试使用其他窗口
        return false;
    }

    _hotkeyIds[actionId] = atomId;
    _actionIds[atomId] = actionId;

    return true;
}

bool HotkeyManager::UnregisterHotkey(const std::string& actionId) {
    auto it = _hotkeyIds.find(actionId);
    if (it == _hotkeyIds.end()) {
        return false;
    }

    int atomId = it->second;

    HWND hwnd = GetActiveWindow();
    if (!hwnd) {
        hwnd = GetForegroundWindow();
    }
    if (!hwnd) {
        hwnd = FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"flutter_app");
    }

    if (!UnregisterHotKey(hwnd, atomId)) {
        return false;
    }

    _actionIds.erase(atomId);
    _hotkeyIds.erase(it);

    return true;
}

void HotkeyManager::UnregisterAll() {
    // 复制一份 map，避免在迭代时修改
    auto hotkeyIdsCopy = _hotkeyIds;

    for (const auto& pair : hotkeyIdsCopy) {
        UnregisterHotkey(pair.first);
    }
}

void HotkeyManager::SetCallback(HotkeyCallback callback) {
    _callback = callback;
}

void HotkeyManager::HandleHotkeyMessage(WPARAM wParam, LPARAM lParam) {
    int atomId = static_cast<int>(wParam);
    auto it = _actionIds.find(atomId);
    if (it != _actionIds.end() && _callback) {
        _callback(it->second);
    }
}

bool HotkeyManager::ParseShortcut(const std::string& shortcut,
                                   UINT* vk,
                                   UINT* modifiers) {
    std::string lower = shortcut;
    std::transform(lower.begin(), lower.end(), lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });

    *modifiers = 0;

    // 检查修饰键
    bool hasCtrl = lower.find("ctrl") != std::string::npos ||
                   lower.find("control") != std::string::npos;
    bool hasShift = lower.find("shift") != std::string::npos;
    bool hasAlt = lower.find("alt") != std::string::npos;

    if (hasCtrl) {
        *modifiers |= MOD_CONTROL;
    }
    if (hasShift) {
        *modifiers |= MOD_SHIFT;
    }
    if (hasAlt) {
        *modifiers |= MOD_ALT;
    }

    // 提取主键
    std::string key;

    // 查找最后一个 '+' 后面的键
    size_t lastPlus = lower.rfind('+');
    if (lastPlus != std::string::npos && lastPlus < lower.length() - 1) {
        key = lower.substr(lastPlus + 1);
    } else {
        // 如果没有 '+'，尝试提取最后一个单词
        size_t lastSpace = lower.rfind(' ');
        if (lastSpace != std::string::npos && lastSpace < lower.length() - 1) {
            key = lower.substr(lastSpace + 1);
        } else {
            key = lower;
        }
    }

    // 去除空格
    key.erase(std::remove(key.begin(), key.end(), ' '), key.end());

    *vk = StringToVirtualKey(key);
    return *vk != 0;
}

UINT HotkeyManager::StringToVirtualKey(const std::string& keyStr) {
    std::string lower = keyStr;
    std::transform(lower.begin(), lower.end(), lower.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });

    // 单字母键
    if (lower.length() == 1 && lower[0] >= 'a' && lower[0] <= 'z') {
        return static_cast<UINT>(toupper(lower[0]));
    }

    // 数字键
    if (lower.length() == 1 && lower[0] >= '0' && lower[0] <= '9') {
        return static_cast<UINT>(lower[0]);
    }

    // 功能键
    if (lower == "f1") return VK_F1;
    if (lower == "f2") return VK_F2;
    if (lower == "f3") return VK_F3;
    if (lower == "f4") return VK_F4;
    if (lower == "f5") return VK_F5;
    if (lower == "f6") return VK_F6;
    if (lower == "f7") return VK_F7;
    if (lower == "f8") return VK_F8;
    if (lower == "f9") return VK_F9;
    if (lower == "f10") return VK_F10;
    if (lower == "f11") return VK_F11;
    if (lower == "f12") return VK_F12;

    // 特殊键
    if (lower == "space" || lower == " ") return VK_SPACE;
    if (lower == "enter" || lower == "return") return VK_RETURN;
    if (lower == "escape" || lower == "esc") return VK_ESCAPE;
    if (lower == "tab") return VK_TAB;
    if (lower == "backspace" || lower == "back") return VK_BACK;
    if (lower == "delete" || lower == "del") return VK_DELETE;
    if (lower == "insert" || lower == "ins") return VK_INSERT;
    if (lower == "home") return VK_HOME;
    if (lower == "end") return VK_END;
    if (lower == "pageup" || lower == "pgup") return VK_PRIOR;
    if (lower == "pagedown" || lower == "pgdn") return VK_NEXT;

    // 方向键
    if (lower == "up" || lower == "arrowup") return VK_UP;
    if (lower == "down" || lower == "arrowdown") return VK_DOWN;
    if (lower == "left" || lower == "arrowleft") return VK_LEFT;
    if (lower == "right" || lower == "arrowright") return VK_RIGHT;

    return 0;  // 未知键
}

int HotkeyManager::GenerateAtomId() {
    return _nextAtomId++;
}

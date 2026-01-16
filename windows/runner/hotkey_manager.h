#ifndef RUNNER_HOTKEY_MANAGER_H_
#define RUNNER_HOTKEY_MANAGER_H_

#include <windows.h>
#include <map>
#include <string>
#include <functional>

// 热键回调函数类型
typedef std::function<void(const std::string&)> HotkeyCallback;

class HotkeyManager {
public:
    HotkeyManager();
    ~HotkeyManager();

    // 注册热键
    // actionId: 操作 ID（如 "regionCapture"）
    // shortcut: 快捷键字符串（如 "Ctrl+Shift+A"）
    // 返回: 成功返回 true，失败返回 false
    bool RegisterHotkey(const std::string& actionId, const std::string& shortcut);

    // 注销热键
    bool UnregisterHotkey(const std::string& actionId);

    // 注销所有热键
    void UnregisterAll();

    // 设置回调函数
    void SetCallback(HotkeyCallback callback);

    // 处理热键消息（应在窗口过程中调用）
    void HandleHotkeyMessage(WPARAM wParam, LPARAM lParam);

private:
    // 解析快捷键字符串，返回虚拟键码和修饰符
    bool ParseShortcut(const std::string& shortcut, UINT* vk, UINT* modifiers);

    // 字符串转虚拟键码
    UINT StringToVirtualKey(const std::string& keyStr);

    // 生成原子 ID
    int GenerateAtomId();

    std::map<std::string, int> _hotkeyIds;  // actionId -> atom ID
    std::map<int, std::string> _actionIds;  // atom ID -> actionId
    HotkeyCallback _callback;
    int _nextAtomId;

    static const int kBaseAtomId = 0x1000;
};

#endif  // RUNNER_HOTKEY_MANAGER_H_

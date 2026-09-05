/// 全局热键 FFI：全部 dart:ffi 声明收敛于本文件。
///
/// 注册序列：`RegisterHotKey(NULL, id, mods, vk)`（NULL hwnd 时
/// `WM_HOTKEY` 投递到调用线程消息队列）；轮询序列：`PeekMessageW`
/// （PM_REMOVE、按 WM_HOTKEY 过滤）取 `wParam` 即注册 id；释放：
/// `UnregisterHotKey`。轮询泵（16ms 周期）位于 [hotkey_impl.dart]，
/// 本文件只提供低层原语与 combo 解析。
library;

import 'dart:ffi';

// ── 常量 ──────────────────────────────────────────────────────────────────────

/// WM_HOTKEY：热键触发消息。
const int wmHotkey = 0x0312;

/// MOD_ALT。
const int modAlt = 0x0001;

/// MOD_CONTROL。
const int modControl = 0x0002;

/// MOD_SHIFT。
const int modShift = 0x0004;

/// MOD_WIN。
const int modWin = 0x0008;

/// PeekMessage：取走并移除消息。
const int pmRemove = 0x0001;

/// 应用可用的热键 id 上限（0x0000-0xBFFF 保留给应用共享热键）。
const int maxHotkeyId = 0xBFFF;

// ── FFI 绑定（本包唯一定义处） ────────────────────────────────────────────────

typedef _RegisterHotKeyNative =
    Int32 Function(IntPtr hWnd, Int32 id, Int32 fsModifiers, Int32 vk);
typedef _RegisterHotKeyDart =
    int Function(int hWnd, int id, int fsModifiers, int vk);

typedef _UnregisterHotKeyNative = Int32 Function(IntPtr hWnd, Int32 id);
typedef _UnregisterHotKeyDart = int Function(int hWnd, int id);

typedef _PeekMessageNative =
    Int32 Function(
      Pointer<MsgStruct> lpMsg,
      IntPtr hWnd,
      Uint32 msgMin,
      Uint32 msgMax,
      Uint32 wRemoveMsg,
    );
typedef _PeekMessageDart =
    int Function(Pointer<MsgStruct> lpMsg, int hWnd, int msgMin, int msgMax, int wRemoveMsg);

/// MSG 结构（x64 布局，显式补齐对齐填充，sizeof = 48）。
///
/// 字段偏移：hwnd 0 / message 8 / wParam 16 / lParam 24 / time 32 /
/// pt 36-44；`pad0`/`pad1` 为对齐填充，不读取。
final class MsgStruct extends Struct {
  /// 窗口句柄（NULL = 线程消息）。
  @IntPtr()
  external int hwnd;

  /// 消息号。
  @Uint32()
  external int message;

  @Uint32()
  external int pad0;

  /// 消息参数（WM_HOTKEY 时为注册 id）。
  @IntPtr()
  external int wParam;

  /// 消息参数（WM_HOTKEY 低 16 位修饰键、高 16 位 VK）。
  @IntPtr()
  external int lParam;

  @Uint32()
  external int time;

  @Uint32()
  external int pointX;

  @Uint32()
  external int pointY;

  @Uint32()
  external int pad1;
}

final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');

final _RegisterHotKeyDart _registerHotKey = _user32
    .lookupFunction<_RegisterHotKeyNative, _RegisterHotKeyDart>('RegisterHotKey');

final _UnregisterHotKeyDart _unregisterHotKey = _user32
    .lookupFunction<_UnregisterHotKeyNative, _UnregisterHotKeyDart>('UnregisterHotKey');

final _PeekMessageDart _peekMessage =
    _user32.lookupFunction<_PeekMessageNative, _PeekMessageDart>('PeekMessageW');

// ── 低层调用封装 ──────────────────────────────────────────────────────────────

/// 注册全局热键；成功返回 true（组合键已被占用等返回 false）。
bool callRegisterHotKey(int id, int fsModifiers, int vk) {
  return _registerHotKey(0, id, fsModifiers, vk) != 0;
}

/// 反注册全局热键；id 不存在时返回 false。
bool callUnregisterHotKey(int id) {
  return _unregisterHotKey(0, id) != 0;
}

/// 取走一条 WM_HOTKEY 消息到 [msg]；队列无匹配消息返回 false。
bool peekHotkeyMessage(Pointer<MsgStruct> msg) {
  return _peekMessage(msg, 0, wmHotkey, wmHotkey, pmRemove) != 0;
}

// ── combo 解析 ────────────────────────────────────────────────────────────────

/// 解析组合键 combo（如 `Ctrl+Shift+A`）为 `(修饰键位掩码, VK 码)`。
///
/// 大小写与空白容错；修饰键为 Ctrl/Alt/Shift/Win 的任意组合（至少一个，
/// 不允许重复），主键为字母 A-Z、数字 0-9 或 F1-F12。无法解析返回 null。
(int, int)? parseHotkeyCombo(String combo) {
  final List<String> tokens = combo
      .split('+')
      .map((String token) => token.trim().toLowerCase())
      .where((String token) => token.isNotEmpty)
      .toList();
  if (tokens.length < 2) {
    return null;
  }
  var mods = 0;
  for (final String token in tokens.sublist(0, tokens.length - 1)) {
    final int? mod = switch (token) {
      'ctrl' || 'control' => modControl,
      'alt' => modAlt,
      'shift' => modShift,
      'win' || 'meta' => modWin,
      _ => null,
    };
    if (mod == null || (mods & mod) != 0) {
      return null;
    }
    mods |= mod;
  }
  final int? vk = vkForKey(tokens.last);
  if (vk == null) {
    return null;
  }
  return (mods, vk);
}

/// 主键名 → VK 码（字母/数字/F1-F12，大小写容错）；未知键返回 null。
int? vkForKey(String key) {
  if (key.length == 1) {
    final int code = key.codeUnitAt(0);
    // a-z → VK 0x41-0x5A（与键码等值的大写形式）。
    if (code >= 0x61 && code <= 0x7A) {
      return code - 0x20;
    }
    // 0-9 → VK 0x30-0x39（与 ASCII 等值）。
    if (code >= 0x30 && code <= 0x39) {
      return code;
    }
    return null;
  }
  final RegExpMatch? match = RegExp(r'^f([1-9]|1[0-2])$').firstMatch(key);
  if (match == null) {
    return null;
  }
  return 0x6F + int.parse(match.group(1)!); // F1=0x70 … F12=0x7B
}

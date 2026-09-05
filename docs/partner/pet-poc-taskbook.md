# 桌面宠物 PoC 任务书（P0）

| | |
|---|---|
| **版本** | v1.0 |
| **日期** | 2026-09-05 |
| **归属** | 宠物项目启动材料（暂存平台仓 `docs/partner/`，宠物仓建立后随 PRD 一起迁移） |
| **工期预估** | 2-3 天 |
| **出口条件** | 四件套全绿 → [PetLink 协议](../protocols/petlink.md) v0.1 升 v1.0 定稿 + Godot 版本锁定 |

> 目标：一次性验证 PetLink 全部前置不确定性的**Godot 侧组合可行性**。
> 平台侧（TCP 监听/配对/面板）不在本 PoC 范围——PetLink 规范已定，等宠物立项后按里程碑实现。

---

## 0. 环境与工程搭建

1. 安装 Godot **4.x stable**（本 PoC 同时承担版本锁定任务：记录实测版本号，定稿后写入宠物仓 README 与边界绝对律附录）；
2. 新建最小工程：单场景 + 单节点挂载 `pet_poc.gd`；项目设置：
   ```text
   display/window/size/viewport_width   = 320
   display/window/size/viewport_height  = 320
   display/window/transparent_bg        = true     # 件二前置
   ```
3. 建议目录：本地独立目录或宠物试验仓（`pet-poc/`），不进平台仓。

## 件一：TCP 帧协议对拍（最高优先级）

**验证目标**：Godot 能按 PetLink 帧格式（4B 大端长度前缀 + UTF-8 JSON）可靠读写 TCP 流，含半包重组。

### 1.1 对拍脚本（Python，充当"平台"侧 TCP server）

保存为 `sparring_server.py`，与 PoC 工程同目录：

```python
"""PetLink 对拍服务器：读帧→解析 JSON-RPC→回 echo 响应。用法：python sparring_server.py [port]"""
import json, socket, struct, sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 47613

def read_frame(conn):
    header = b""
    while len(header) < 4:
        chunk = conn.recv(4 - len(header))
        if not chunk:
            return None
        header += chunk
    (length,) = struct.unpack(">I", header)
    body = b""
    while len(body) < length:
        chunk = conn.recv(length - len(body))
        if not chunk:
            return None
        body += chunk
    return body.decode("utf-8")

def write_frame(conn, obj):
    data = json.dumps(obj, separators=(",", ":")).encode("utf-8")
    conn.sendall(struct.pack(">I", len(data)) + data)

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind(("127.0.0.1", PORT))
    srv.listen(1)
    print(f"sparring server on 127.0.0.1:{PORT}", flush=True)
    conn, _ = srv.accept()
    with conn:
        count = 0
        while True:
            payload = read_frame(conn)
            if payload is None:
                print(f"peer closed after {count} frames", flush=True)
                break
            msg = json.loads(payload)
            print(f"<- {msg.get('method', msg.get('id'))}", flush=True)
            if "id" in msg:  # request → echo response
                write_frame(conn, {"jsonrpc": "2.0", "id": msg["id"], "result": {"echo": msg.get("params")}})
                count += 1
```

### 1.2 Godot 侧帧读写（`pet_poc.gd` 核心片段）

```gdscript
extends Node

var _peer := StreamPeerTCP.new()
var _buf := PackedByteArray()   # 半包重组缓冲

func _ready() -> void:
    var err := _peer.connect_to_host("127.0.0.1", 47613)
    print("connect: ", err)

func _process(_dt: float) -> void:
    if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
        return
    var avail := _peer.get_available_bytes()
    if avail > 0:
        _buf.append_array(_peer.get_partial_data(avail)[1])
        _drain_frames()

func _drain_frames() -> void:
    while _buf.size() >= 4:
        var length := _buf.decode_u32(0)          # 大端？见下方"实测点"
        if _buf.size() < 4 + length:
            return                                # 半包：留在缓冲
        var payload := _buf.slice(4, 4 + length).get_string_from_utf8()
        _buf = _buf.slice(4 + length)
        _on_message(JSON.parse_string(payload))

func send_frame(payload_str: String) -> void:
    var data := payload_str.to_utf8_buffer()
    var header := PackedByteArray()
    header.resize(4)
    header.encode_u32(0, data.size())             # 字节序实测点
    _peer.put_data(header + data)

func _on_message(msg: Dictionary) -> void:
    print("<- ", JSON.stringify(msg))
```

### 1.3 验收断言（四条全过才算绿）

| # | 断言 | 方法 |
|---|---|---|
| 1a | echo 往返：Godot 发 100 条 `{"jsonrpc":"2.0","id":i,"method":"ping","params":{"n":i}}`，全部收到对应 `result.echo.n == i` | 脚本计数，对拍服务器日志核对 |
| 1b | 半包重组：对拍服务器把一条响应**拆成 1+2+剩余** 三次 send（改脚本加 `TCP_NODELAY` 分段发送变体），Godot 仍完整解出 | 服务器侧分段变体 + Godot 侧断言 |
| 1c | 大 payload：单帧 1 MiB JSON 往返成功 | 生成大字符串 |
| 1d | 拒绝超长：服务器发声明 9MiB 的帧头，Godot 侧应主动断开或报错（不尝试分配） | 服务器侧恶意帧变体 |

**⚠️ 实测点（本件的核心目的）**：
- `PackedByteArray.encode_u32` / `StreamPeerTCP` 的**字节序**——Godot 的 `encode_u32` 默认大端，但 `put_var`/`get_var` 是小端且带长度头，**绝不混用**，只用裸 `put_data` + 手工 4 字节头；
- `get_partial_data` 的返回语义（`[error, bytes]`）与空读行为；
- Windows 下 Godot 独立进程的 TCP 收发是否受控制台子系统影响（预期无影响，TCP 与 stdio 无关——这正是从 stdio 改 TCP 的收益）。

## 件二：透明 + 置顶 + 无边框窗口

```gdscript
func _ready() -> void:
    get_window().borderless = true
    get_window().always_on_top = true
    get_window().transparent = true          # Godot 4.x 属性名以实测版本为准
    # 场景根节点挂一个 TextureRect 显示一张带透明的 PNG（先用任意测试图）
```

**验收**：桌面可见 PNG 内容悬浮、无窗口背景/边框、始终置顶；`Alt+Tab` 中窗口行为记录（是否出现在任务栏，`unfocusable`/`popup` 试试效果并记录）。截图留证。

## 件三：点击穿透（勿扰模式的技术底座）

```gdscript
func set_dnd(enabled: bool) -> void:
    if enabled:
        # 全窗穿透：传空区域数组 = 整窗穿透（API 形态以实测为准）
        DisplayServer.window_set_mouse_passthrough(PackedVector2Array())
    else:
        DisplayServer.window_set_mouse_passthrough(PackedVector2Array(), ...)  # 恢复交互
```

**验收**：穿透开启时，点击宠物所在区域落到**下层窗口**（开一个记事本垫在宠物下方实测）；关闭后宠物可正常接收 `_gui_input`。若全窗穿透 API 形态不符预期，改用区域式穿透（传宠物实际占用的多边形）——记录实际可行形态。

## 件四：反向唤起（宠物 → 拉起平台进程）

```gdscript
func open_toolbox() -> void:
    OS.execute("cmd.exe", ["/c", "start", "", "notepad.exe"])   # PoC 用记事本当哑平台
    # 正式实现：OS.shell_open("steam://run/<appid>") 或 OS.execute 同目录 toolbox.exe
```

**验收**：点击宠物内按钮 → 记事本（哑平台）窗口出现。同时记录：`OS.shell_open("steam://...")` 在未装 Steam 时的失败表现（为正式实现的降级路径留据）。

## 产出物清单

```text
pet-poc/
  project.godot + pet_poc.gd + 测试 PNG
  sparring_server.py（含分段/恶意帧变体）
  POC-RESULTS.md   ← 四件套逐项：绿/红 + 实测记录（Godot 版本、API 实际形态、
                      字节序结论、穿透方案、Alt+Tab 行为）+ 截图
```

## 判定与后续

- **四绿**：POC-RESULTS.md 结论节写明 → PetLink v1.0 定稿（平台仓）→ 宠物仓建立（PRD + 边界律副本迁入）→ P1 垂直切片；
- **任一红**：红项单独评估——件一红且无法修复 = PetLink 传输层重评（备选：命名管道/本地 WebSocket）；件二/三红 = 窗口方案重估（GDExtension 调 Win32 的成本评估）；件四红 = 拉起机制换 `steam://run` 直测；
- 无论结果，POC-RESULTS.md 的**实测记录本身是交付物**——API 形态结论直接写进宠物仓 README 与 PRD 技术附录。

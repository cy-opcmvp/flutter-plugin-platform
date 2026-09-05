# PetLink 协议规范

| | |
|---|---|
| **版本** | **v1.0（已定稿）** |
| **日期** | 2026-09-05（v0.1 草案同日；PoC 四件套全绿后定稿） |
| **定稿依据** | P0 PoC 实测（Godot 4.6.3，见宠物侧 POC-RESULTS.md：TCP 帧四断言全过，1MiB 147ms / 超长 7ms 拒绝） |
| **状态** | 事实源（唯一权威版本存放于平台仓；宠物仓持有版本化只读副本） |
| **参与者** | 桌面宠物（Godot 游戏，独立进程）↔ 工具箱平台（Flutter 宿主，独立进程） |
| **关系定位** | 对等伙伴应用（peer），非插件、非主从 |

> 本协议是「底层限制」：宠物侧的高频迭代（属性/装备/换装/桌面 RPG）**永远不触碰本协议**；
> 协议自身的演进受第 12 节演进宪法约束。裁定依据：2026-09-05 双方设计质询（grill 会话）全部裁定。

---

## 1. 目标与非目标

**目标**：
- 让对等的两个本地应用建立可信、版本化、可独立演进的联动通道；
- 覆盖四类场景：宠物操纵平台（唤起/隐藏）、平台感知宠物（模式/状态）、宠物借平台能力（通知/热键/快捷工具）、平台做宠物的面板（设置表单/属性查看）。

**非目标**（与拒绝清单第 11 节互补）：
- 不是远程协议——仅限本机 loopback；
- 不是插件体系——宠物不进入插件注册表/解析器/生命周期状态机；
- 不承载宠物游戏内容数据——RPG 存档等一律不经本协议传输（见边界绝对律）。

## 2. 术语

- **平台**：Flutter 工具箱宿主（Steam 同捆包中的 `toolbox.exe`）。
- **宠物**：Godot 桌面宠物游戏（`pet.exe`），Steam app 的主体。
- **独立模式**：宠物在无平台连接时的完整可玩状态，联动功能静默降级。
- **动词（verb）**：白名单中的 RPC 方法名。**事件（event）**：以 notification 形式承载的状态推送。

## 3. 传输层

- **TCP over 127.0.0.1**。**平台监听**，宠物为客户端。
- 默认端口 **47613**（草案值，实现期可改），双方均可经配置覆盖；宠物连接失败时依次尝试默认端口与配置端口。
- 平台启动时若探测到宠物未运行，可按平台设置经 `steam://run/<appid>`（或直接 exe，见命名规范）拉起；反向同样成立（宠物右键菜单"打开工具箱"拉起平台 exe）。
- **同目录互发现**（Steam 同捆安装布局）：双方优先在自身安装目录探测对方 exe 的存在，用于"拉起"与状态提示；连接仍走 TCP。
- 双方**任一退出，另一方不得退出**：TCP 断开只导致降级（见第 10 节），只有用户主动关闭才关闭。

## 4. 帧格式（与 v2 sidecar 协议同源）

```text
u32 大端 payloadLength（1 .. maxFrameBytes）
payloadLength 字节 UTF-8 JSON
maxFrameBytes = 8 MiB（默认，握手可协商收紧）
```

解码器必须：长度越界立即断开（不等待 payload）、零长帧拒绝、非 UTF-8 拒绝、支持流式半包。

## 5. 消息模型

JSON-RPC 2.0 严格子集（与 v2 `rpc_message_codec` 语义一致）：

- 所有消息为 JSON object，未知字段拒绝，`jsonrpc` 必须为 `"2.0"`；
- `request`：method（白名单动词）+ 可选 params（object）+ id（非负 int 或非空 string）；
- `notification`：无 id；**事件以 notification 承载**（method 为事件名）；
- `success`/`error`：result 与 error 互斥；错误对象 `{code:int, message:string, data?}`；
- **双向对等**：两侧都可发 request 与 notification。

## 6. 握手与鉴权

连接建立后，**宠物必须以 `petlink.handshake` 作为首帧 request**：

```json
{ "method": "petlink.handshake",
  "params": { "petlinkVersion": "1.0", "appId": "<命名规范定义的宠物 appId>",
               "token": "<配对密钥，首次连接可为空>", "maxFrameBytes": 8388608 } }
```

平台响应：
- **已配对且 token 正确** → `result: { "serverVersion": "1.0", "platformState": {…快照…} }`，连接进入就绪；
- **token 缺失/错误** → error `petlink.unauthorized` 并断开。**首次**（平台无该 appId 的配对记录）→ 平台弹一次性确认对话框（"允许此宠物与工具箱联动？"）；用户同意后平台生成 128bit 配对密钥，在本次响应中下发给宠物，双方持久化；拒绝则 error `petlink.not_paired` 断开且不再打扰（可在平台设置中重新发起）。
- **版本不可协商** → error `petlink.version_unsupported`（携带平台支持的版本范围）。

握手完成前，任何其他动词一律 `petlink.unknown_verb` 拒绝。

## 7. 版本协商与兼容承诺

- 握手交换双方主版本；小版本差异必须兼容（小版本只加动词/事件）。
- **N-1 承诺**：平台大版本 N 发布时必须同时兼容 N-1，至少一个平台大版本周期。
- 未知动词的合法响应是 error `petlink.unknown_verb`（而非断开）——这允许新旧版本共存。

## 8. 动词与事件白名单（v1）

### 8.1 宠物 → 平台（request）

| 动词 | 参数 | 结果 | 说明 |
|---|---|---|---|
| `window.show` | `{}` | `{}` | 唤起平台主窗口（右键打开平台的正式通道） |
| `window.hide` | `{}` | `{}` | 隐藏平台主窗口（平台进托盘态/进程常驻） |
| `platform.state` | `{}` | `{ "window": "shown"\|"hidden", "tools": [ …可用工具 ] }` | 平台状态查询 |
| `settings.get` | `{ "keys": [] }` | `{ …键值… }` | 读宠物在平台侧的登记数据（全局开关/窗口位置偏好/安装态） |
| `notify` | `{ "title", "body" }` | `{}` | 借平台发系统通知 |
| `screen.info` | `{}` | `{ "displays": [ { "id", "x", "y", "w", "h", "scale" } ] }` | 多屏/DPI 信息，宠物摆位用 |
| `tools.invoke` | `{ "tool": "screenshot.capture", "args": {} }` | 工具自定义 | **白名单制**：初值仅 `screenshot.capture`；陪伴模式的核心动词 |
| `hotkey.register` | `{ "hotkey", "purpose" }` | `{ "granted": bool }` | 注册全局热键。**词汇冻结、实现待平台热键契约**（roadmap #2）落地后生效 |

### 8.2 平台 → 宠物（request）

| 动词 | 参数 | 结果 | 说明 |
|---|---|---|---|
| `pet.settings-schema` | `{}` | v2 声明式表单描述（FormDescriptor JSON） | 平台用现成 FormRenderer 渲染宠物设置页——宠物不做设置界面 |
| `pet.settings-apply` | `{ "values": {…} }` | `{}` | 平台侧表单提交回写 |
| `pet.state` | `{}` | `{ "mode", "attributes", "equipment", "progress" }` | 只读快照（平台做属性面板，ResultRenderer 呈现） |

### 8.3 事件（双向 notification）

| 事件 | 载荷 | 说明 |
|---|---|---|
| `platform.state-changed` | 同 `platform.state` 结果 | 平台最小化/恢复/退出前推送 |
| `pet.mode-changed` | `{ "mode": "dnd"\|"game"\|"companion" }` | 模式切换上报 |

## 9. 三模式建模

| 模式 | 值 | 协议可见性 |
|---|---|---|
| 勿扰模式 | `dnd` | 鼠标全窗穿透、不可交互——**Godot 内政**，仅模式值协议可见 |
| 游戏模式 | `game` | 鼠标键盘可操作、桌面 RPG——**Godot 内政**，仅模式值协议可见 |
| 陪伴模式 | `companion` | 平台快捷工具与热键的入口（经 `tools.invoke` 触发如截图） |

- 模式切换入口（右键菜单/热键/按钮）由宠物自绘；
- 平台面板展示当前模式（经 `pet.state` / `pet.mode-changed`）；
- 平台**请求**宠物切换模式：v1 不提供（未裁定），列为 v1.1 候选。

## 10. 失败语义

| 场景 | 行为 |
|---|---|
| 宠物崩溃 | 若由平台拉起 → supervisor 指数退避重启（30s 内最多 3 次），超限后目录页标"宠物已停止"+手动重启按钮（`steam://run`）；若独立启动 → 平台仅标记离线，重启归用户/Steam |
| 平台死亡/被杀 | 宠物 TCP 断开 → **立即进入独立模式**（完整可玩），后台以退避间隔静默重连，**永不自杀** |
| 断线重连 | 必须重走完整握手（版本+密钥+快照）；**状态以平台为事实源**，宠物丢弃本地缓存的平台状态 |
| 请求超时 | 默认 10s（草案值）；超时返回 `petlink.timeout`，连接保留（PetLink 不采用 v2 sidecar 的"超时即关通道"语义，因为对等双方有独立模式兜底） |
| 帧违规 | 超长/零长/非 UTF-8/非法 JSON-RPC → 断开连接（协议层污染不可恢复） |

## 11. 拒绝清单（永不提供）

以下能力**永久排除**在 PetLink 之外，任何版本不得加入：

1. 平台主窗口的尺寸/位置/层级操纵（仅 `window.show/hide` 两动词，永不再加窗口动词）；
2. 读写其他插件或平台自身的数据/配置；
3. 触发其他插件的命令（`tools.invoke` 白名单只含平台级快捷工具）；
4. 宠物访问平台侧文件系统；
5. 静默更新对方应用；
6. 经网络转发或远程触达（仅 loopback）。

## 12. 演进宪法

1. **动词/事件新增权仅归平台开发者**（2026-09-05 裁定）；宠物侧只能消费与提案。
2. 新增动词/事件 = 小版本；既有动词**语义变更** = 大版本 + N-1 兼容实现。
3. 每次协议变更：平台仓更新本文件 → 宠物仓副本**必须**同次同步（见边界绝对律的同步义务）→ 双方 conformance 测试同步转绿后才可发布。
4. 拒绝清单的任何条目**不可经版本演进移除**（需双方重新立项并明示推翻）。

## 13. 错误码

| 码 | 含义 |
|---|---|
| `petlink.unauthorized` | token 错误 |
| `petlink.not_paired` | 未配对且用户拒绝/未确认 |
| `petlink.version_unsupported` | 版本不可协商（data 携带支持范围） |
| `petlink.unknown_verb` | 动词不在白名单或未握手 |
| `petlink.tool_unavailable` | `tools.invoke` 的工具不存在/不可用 |
| `petlink.timeout` | 请求超时 |
| `petlink.frame_invalid` | 帧违规（伴随断开） |

标准 JSON-RPC 错误码（-32700/-32600/-32601/-32602/-32603）保留原语义。

## 14. 与 v2 sidecar 协议的关系

帧格式与 JSON-RPC 子集**同源**（4B 前缀 + 严格消息模型）；差异仅在传输（TCP vs stdio）与对等性（双向 request vs 宿主单向）。实现上：平台侧为既有 `RpcTransport` 抽象新增 TCP 实现，不改动 sidecar 既有语义。

## 附录 A：关键时序（ASCII）

```text
首次配对：
pet ── handshake(无token) ──▶ platform
platform ── 弹窗确认（用户同意）──▶ 生成密钥
platform ◀── response(token, 快照) ── pet          双方持久化密钥

陪伴模式触发截图（宠物右键→快捷工具）：
pet ── tools.invoke{screenshot.capture} ──▶ platform
platform ── 执行截图插件 ──▶ 系统
platform ── result ──▶ pet                          宠物可播放反馈动画

平台退出（宠物不陪葬）：
platform ── platform.state-changed{exiting} ──▶ pet
pet    → 进入独立模式，后台退避重连
```

---

*v1.0 定稿于 2026-09-05（PoC 四件套全绿）。*

## 附录 B：实现注意（PoC 实测沉淀，v1.0 增补）

1. **Godot 侧 `StreamPeerTCP` 必须显式 `poll()`**（每帧/每等待循环），否则握手永不完成——宠物侧客户端第一实现纪律；
2. 帧头**手工组包**大端四字节（规避 `encode_u32` 字节序歧义，PoC 验证往返一致）；
3. `window_set_mouse_passthrough` 4.6 语义为「region=可交互多边形，区域外穿透」，`null` 不被接受；空数组/全窗多边形双极性已过 API 实测，极性最终确认属宠物侧人眼验收；
4. 拉起对端进程用**绝对路径/同目录解析**（Steam 同捆天然同目录；Win11 商店别名裸名 spawn 会瞬死）。

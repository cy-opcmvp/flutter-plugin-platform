# python_sample（Python Sidecar 样本：hash 工具）

M4 sidecar 样本：`tools.hashtool`，Windows 目标，`hash.compute` 命令面。仅用 Python 标准库（hashlib），**零 pip 依赖**。

## 文件

- `plugin.json`：`kind=sidecar`，`entrypoint=hash_tool.py`（包内相对路径），`surfaces=["command"]`。
- `hash_tool.py`：脚本实现三件事——
  1. 帧协议：每条消息为 4 字节大端长度前缀（`struct ">I"`）+ UTF-8 JSON，stdout 只写帧，日志走 stderr；
  2. 就绪信号：启动后先发一个纯字符串帧 `ready`；
  3. JSON-RPC 2.0：`hash.compute` 收 `{"text": "..."}` 回 `{md5, sha1, sha256}`（hex 小写）；未知方法 `-32601`，非法参数 `-32602`。
- `hash-tool.scp`：`plugin_cli pack` 的现成产物（自包含包：清单 + 入口脚本）。

## 打包与安装

```bash
cd v2/packages/plugin_cli
dart run plugin_cli validate ../../sidecars/python_sample
dart run plugin_cli pack ../../sidecars/python_sample -o ../../sidecars/python_sample/hash-tool.scp
```

宿主详情页提供 `.scp` 路径安装入口；安装落盘到 `<hostDataRoot>/sidecar-packages/tools.hashtool/` 后经命令桥启动。

## e2e

`v2/apps/toolbox_host/test/sidecar_hash_e2e_test.dart` 用真 Python 全链验证（安装 → 启动 → `hash.compute('abc')` 与 hashlib 参考值断言 → 停止 → 卸载）；无可用解释器时自动跳过。手动帧调试可选：`python hash_tool.py`。

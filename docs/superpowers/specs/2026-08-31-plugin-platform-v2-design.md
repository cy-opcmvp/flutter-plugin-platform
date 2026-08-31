# Flutter Plugin Platform v2 设计规格

**状态：** 已确认，可进入分阶段实施

**日期：** 2026-08-31

**目标：** 构建一个可复用、六端可编译、插件间松耦合，并能逐步扩展桌面 Sidecar 的 Flutter 插件平台 SDK。

## 1. 产品边界

- 核心 SDK 面向 Windows、macOS、Linux、Android、iOS 和 Web。
- Windows 是第一个完成端到端功能的落地平台，但不是核心架构依赖。
- 当前使用者和插件作者均为项目所有者本人，不建设第三方插件市场。
- 旧 API、旧目录、旧数据结构和旧实现不要求兼容。
- 旧实现仅作为需求和行为参考，v2 全部验收前不得执行最终删除。
- MVP 只使用本地配置和本地数据，不实现账号、云同步或远程状态。

## 2. 插件类型

### 2.1 内置 Dart 插件

- 以独立 Dart 或 Flutter package 存在。
- 通过 CLI 创建、校验并登记到宿主。
- 新增和升级代码后需要重新构建宿主应用。
- 应用运行时支持启用、停用和配置，不宣称能够动态卸载已编译代码。
- 可直接贡献 Flutter Widget，适用于复杂界面。

### 2.2 桌面 Sidecar 插件

- 以独立进程运行，MVP 首先支持 Windows。
- 支持在已发布宿主中安装、启动、停止和卸载。
- MVP 使用带帧边界的 JSON-RPC/stdio 通信。
- MVP 支持无界面命令和宿主渲染的声明式表单/结果界面。
- 协议保留其他 UI Surface 类型，但未实现类型必须被明确拒绝。

## 3. 架构原则

1. 核心契约使用纯 Dart，不依赖 Flutter、`dart:ffi`、`win32` 或具体平台包。
2. 平台专属代码位于独立适配包，通过条件导入或联邦式实现隔离。
3. 只有一个 Composition Root，禁止重新引入多个 Service Locator 或重复服务图。
4. 插件通过能力契约组合，禁止直接导入其他插件的实现包。
5. 同一逻辑插件使用统一 ID，平台解析器按目标平台和能力选择实现。
6. 不要求每个插件支持全部平台；不支持必须是可查询、可解释的正常状态。
7. 框架搭建与真实业务插件实现分阶段进行，框架验收前不得迁移业务插件。
8. 实现与验收由不同智能体完成，验收智能体只读检查，不直接修改生产代码。
9. 每个任务必须生成可持久化状态，聊天历史不是唯一事实来源。

## 4. 目标结构

```text
v2/
  pubspec.yaml
  analysis_options.yaml
  apps/
    toolbox_host/
  packages/
    plugin_contracts/
    plugin_runtime/
    plugin_flutter/
    plugin_sidecar/
    platform_capabilities/
    platform_capabilities_windows/
    platform_capabilities_macos/
    platform_capabilities_linux/
    platform_capabilities_android/
    platform_capabilities_ios/
    platform_capabilities_web/
    plugin_devkit/
    plugin_cli/
  plugins/
    calculator/
    screenshot/
  sidecars/
    python_sample/
```

v2 在旧工程旁独立构建。最终切换是否保留 `v2/` 目录，由发布阶段依据打包和维护成本决定；在此之前不移动旧工程文件。

## 5. 核心数据模型

### 5.1 PluginId

- 字符串格式：`^[a-z][a-z0-9]*(\.[a-z0-9]+)+$`。
- ID 是配置目录、数据目录、能力所有者和诊断信息的唯一身份。
- 所有文件路径必须由验证后的 ID 映射，禁止直接拼接未经校验的清单输入。

### 5.2 PluginManifest

必需字段：

```text
id
name
version
apiVersion
kind
targets
entrypoint
provides
requires
surfaces
configSchemaVersion
dataSchemaVersion
```

约束：

- `apiVersion`、能力版本和 schema 版本使用正整数。
- `targets` 至少包含一个平台。
- `builtin` 清单不得声明外部可执行命令。
- `sidecar` 清单必须声明入口和桌面目标平台。
- 未识别字段默认拒绝，未来通过 apiVersion 升级放开。

### 5.3 能力契约

- 能力使用稳定字符串 ID，例如 `image.capture`。
- 提供方声明 `provides`，消费方声明 `requires`。
- 运行时先解析依赖和平台支持，再激活插件。
- 缺少必需能力时插件保持未激活，并返回结构化原因。
- 插件之间不通过共享配置传递业务状态。

## 6. 生命周期

安装状态与运行状态分离：

```text
安装：notInstalled -> installing -> installed -> uninstalling -> notInstalled
运行：discovered -> resolved -> inactive -> activating -> active
                                      active -> deactivating -> inactive
                                      任意转换失败 -> failed
                                      inactive/failed -> disposed
```

- 内置插件在构建产物中视为已安装，只执行运行生命周期。
- Sidecar 同时执行安装和运行生命周期。
- 所有转换必须可验证，非法转换返回稳定错误码。
- 激活失败不得影响其他插件或宿主启动。

## 7. 配置与数据

- 平台公共配置包含主题、语言、时区和平台数据目录等宿主信息。
- 插件按需读取公共配置；写入必须通过平台定义的窄接口。
- 插件私有配置按 PluginId 命名空间隔离。
- 插件私有数据按 PluginId 隔离，并包含 `dataSchemaVersion`。
- 配置包含 `configSchemaVersion` 和迁移入口。
- MVP 不定义云端协议，但序列化结果不能依赖进程内对象地址或平台句柄。

## 8. Sidecar MVP 安全边界

- 安全目标是可信自用插件的故障隔离，不宣称能够安全运行恶意代码。
- 安装包包含清单、入口、资源和完整性摘要；摘要不是数字签名。
- 解包先进入暂存目录，验证所有规范化路径仍位于暂存根目录内。
- 禁止绝对路径、父目录穿越、设备路径和重复冲突路径。
- 安装完成使用原子目录切换。
- 进程管理包含启动超时、请求超时、取消、退出回收和宿主关闭回收。
- MVP 不建设发布者白名单、证书中心、账号系统和 OS 级恶意代码沙箱。

## 9. UI Surface

- 内置插件可贡献 Flutter 页面、设置页、动作和小组件。
- Sidecar MVP 可贡献命令、声明式表单和结构化结果。
- Sidecar 不能直接注入 Flutter Widget。
- 未实现的 `web` 或 `nativeSurface` 返回 `unsupportedSurface`，不得静默降级。

## 10. 平台策略

- 核心契约和运行时在六端编译。
- 计算器作为六端纯 Dart/Flutter 样本。
- 截图插件只在实际实现的平台加载。
- Python Sidecar 首期只在 Windows 完成端到端闭环。
- 宿主必须能展示插件不可用原因。
- 平台清单不能替代代码隔离；不支持平台的专属依赖不能进入其编译图。

## 11. 智能体路由

- Sol xhigh/max：架构、公共契约、生命周期、安装安全、RPC、发布终验。
- Terra high/xhigh：平台适配、复杂集成、普通业务独立验收。
- Luna high：需求明确且已有模板的普通业务代码。
- Luna medium：脚手架展开、机械文档和重复性测试。
- Luna 实现遇到公共接口变更、平台原生代码、进程/文件安全或两轮修复失败时自动升级。
- 实现者与验收者必须是不同智能体和不同上下文。

## 12. 执行与断点约束

- 批量任务开始前必须询问是否创建 Goal。
- 默认同时只运行一个子智能体，不允许嵌套委派。
- 每个任务开始前写入任务卡，结束后写入验证结果和下一动作。
- 状态只允许 `not_started`、`in_progress`、`implemented_unverified`、`verified_pending_acceptance`、`accepted`、`blocked`。
- `accepted` 任务不得重复实现。
- 中断恢复先检查文件和最小验证，不根据旧聊天推测完成度。
- AI 不执行 Git 命令；每个验收门提供建议提交信息，由用户自行提交。

## 13. MVP 验收标准

- Windows 宿主完成端到端运行。
- 六端核心 SDK 可编译并通过契约测试。
- Windows 专属依赖不污染 Web 或其他平台构建。
- 计算器在其六端目标矩阵通过业务测试。
- 截图插件只在声明支持的平台加载。
- Windows Python Sidecar 完成安装、启动、通信、停止、超时和卸载。
- CLI 能创建、校验和打包新插件。
- 新开发者只依据文档即可完成示例插件。
- 删除伪签名、伪沙箱和模拟 IPC，不保留误导性的安全声明。


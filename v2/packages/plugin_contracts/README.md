# plugin_contracts

`plugin_contracts` 定义插件之间以及宿主与插件之间共享的稳定 Dart 契约：

- `PluginId` 与 `PluginFailure`：严格身份校验和可安全共享的结构化失败值。
- `PluginManifest` 与 `PluginManifestCodec`：不可变清单及严格 JSON 映射。
- `PluginTarget`、`PluginKind`：六个目标平台与 Builtin/Sidecar 种类。
- `CapabilityDescriptor`、`CapabilityRequirement`：插件提供/需要的带版本能力。
- `PluginLifecycle`、`PluginLifecycleState`：生命周期接口和状态词汇。

构造器与 codec 会拒绝非法 ID、非正版本、缺失或未知字段、重复集合项及不满足种类约束的清单。公开集合均为不可变快照；失败包含稳定 code、可读 message 和不可变 details，诊断不会暴露完整路径或进程参数。

本包只提供值对象、清单编解码和接口定义，不实现注册表或解析行为，也不依赖 Flutter、平台库或运行时加载机制。


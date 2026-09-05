# plugin_runtime

`plugin_runtime` 提供不执行插件代码的核心运行时模型：

- `LifecycleMachine` 只验证状态转换并返回结构化结果。
- `PluginRegistry` 与 `CapabilityCatalog` 以候选状态校验后原子提交，公开不可变快照。
- `PluginResolver.resolve(manifests, target)` 接收宿主显式目标，过滤不可用插件，解析能力依赖，并生成 provider-before-consumer 的稳定激活顺序。

解析结果保留逐插件结构化不可用原因，例如目标不支持、能力缺失、版本不足、provider 不可用和依赖环。

运行时不会调用 `PluginLifecycle` 对象，不加载 Dart 代码或进程，不访问文件系统、环境变量或平台全局，也不依赖 `plugin_devkit`。测试消费者可按需依赖 `plugin_devkit` 获取 fake 与 matcher；不要反向把 devkit 加入运行时依赖。


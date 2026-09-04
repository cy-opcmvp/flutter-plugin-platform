# Task F1-05 报告：原子插件注册表与能力目录

## 状态

`DONE`

实现纯 Dart、仅状态的内存注册表与派生能力目录；注册、注销与目录更新保持原子，不加载或执行插件。

## 命令证据

| 工作目录 | 命令 | 退出码 | 结果 |
| --- | --- | ---: | --- |
| `v2/packages/plugin_runtime` | `dart test test/registry test/capability`（仅测试文件存在） | 1 | 预期缺失 `PluginRegistry`、`PluginRegistration`、`RegistryMutationResult`、`CapabilityCatalog` 类型/导出 |
| `v2/packages/plugin_runtime` | `dart test test/registry test/capability` | 0 | 8 项通过 |
| `v2/packages/plugin_runtime` | `dart test` | 0 | 21 项通过 |
| `v2/packages/plugin_contracts` | `dart test` | 0 | 48 项通过 |
| `v2` | `dart format --output=none --set-exit-if-changed .` | 0 | 20 个文件，0 changed |
| `v2` | `dart analyze` | 0 | No issues found |

首次 workspace 格式检查退出码为 1，仅两个新增测试文件存在格式差异；使用 `dart format --output=show` 检查后，通过 `apply_patch` 修正，未使用写模式 formatter。

## Mutation 检查

| 临时 mutation | 命令 | 退出码 | 捕获结果 |
| --- | --- | ---: | --- |
| 冲突校验前写入候选 registrations | `dart test test/registry/plugin_registry_test.dart --name "provider conflict"` | 1 | 检出冲突插件残留的部分状态 |
| 注销时不重建 capability catalog | `dart test test/registry/plugin_registry_test.dart --name "unregister removes"` | 1 | 检出已注销插件能力仍可解析 |
| 版本不足比较由 `<` 反转为 `>` | `dart test test/capability/capability_catalog_test.dart` | 1 | exact/higher 与 insufficient 两类断言均失败 |

三项 mutation 均已通过 `apply_patch` 恢复；最终门禁基于恢复后的实现。

## Authored files

- `v2/packages/plugin_runtime/lib/src/registry/plugin_registration.dart`
- `v2/packages/plugin_runtime/lib/src/registry/plugin_registry.dart`
- `v2/packages/plugin_runtime/lib/src/capability/capability_catalog.dart`
- `v2/packages/plugin_runtime/test/registry/plugin_registry_test.dart`
- `v2/packages/plugin_runtime/test/capability/capability_catalog_test.dart`
- `v2/packages/plugin_runtime/lib/plugin_runtime.dart`
- `.superpowers/sdd/2026-08-31-plugin-platform-v2-core-foundation/task-F1-05-report.md`

## Scope 检查

| 项目 | 结果 |
| --- | --- |
| registrations 为不可修改快照；catalog 内部 provider map 不可修改 | 通过 |
| duplicate ID、unknown unregister、duplicate provider code/details 精确且拒绝不改状态 | 通过 |
| catalog build 保持输入迭代顺序，冲突时不返回 partial catalog | 通过 |
| exact/higher 版本可解析；missing/too-low 返回空 provider/descriptor 与稳定详情 | 通过 |
| successful unregister 同时移除 registration 与 owned capabilities | 通过 |
| 无 singleton、service locator、Flutter、I/O、FFI、平台依赖、插件执行或 F1-06 resolver | 通过 |
| 未修改 brief、progress、ledger、baseline、review、accepted 文件或其他 package | 通过 |
| 未运行 Git、未派发子智能体；所有写入均使用 `apply_patch` | 通过 |

## Concerns

无阻塞 concern。

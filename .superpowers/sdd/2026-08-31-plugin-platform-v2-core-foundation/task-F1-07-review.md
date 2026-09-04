# Task F1-07 Review

审查依据为 `task-F1-07-brief.md`、`task-F1-07-report.md` 与完整 `task-F1-07-review-package.md`。五个交付文件的当前 SHA-256 与 review package 第 9–13 行一致。本次未运行 Git、未重复测试或门禁、未派生子智能体。

## Spec Compliance

结论：**Approved**。

- `FakePlugin` 完整实现 `PluginLifecycle` 三项操作；三个方法分别只递增自己的计数一次，并在递增后查询配置、直接抛出同一个 `PluginFailure` 对象（`v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart:3`、`:5`、`:16`、`:22`、`:28`、`:38`）。
- 构造函数使用 `Map.unmodifiable` 建立失败配置的不可修改副本，调用方后续修改原 map 不会改变 fake 行为；公开面只有规定的构造参数、三项计数和生命周期方法，没有 reset、回调、状态机或额外控制（`v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart:6`、`:11`、`:34`）。实现仅依赖 contracts，不含 delay、timer、进程、I/O、平台 API 或 runtime 状态耦合（`:1`、`:16`、`:22`、`:28`）。
- `hasPluginFailureCode` 对 `trim()` 后为空的期望值抛出参数名为 `code` 的 `ArgumentError`；私有 matcher 仅在对象为 `PluginFailure` 且 `item.code` 精确相等时匹配，不读取 message/details（`v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart:4`、`:12`、`:18`）。
- mismatch 对非 `PluginFailure` 明确报告实际类型，对错误 failure code 明确报告实际 code，两种描述可区分；实现类保持私有，只公开工厂函数（`v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart:30`、`:36`、`:42`）。
- `matcher: ^0.12.20` 是 devkit 的直接 normal dependency；公共 matcher 从 `package:matcher/matcher.dart` 导入，`lib/` 没有导入 `package:test`。barrel 仅导出 fake 与 matcher 文件，私有 matcher 不会成为公共类型（`v2/packages/plugin_devkit/pubspec.yaml:7`、`v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart:1`、`v2/packages/plugin_devkit/lib/plugin_devkit.dart:1`）。
- 测试保持单文件、四个场景组；成功与注入失败均按三种操作参数化，没有复制成独立测试函数。成功表精确检查仅目标计数变化；失败表用 `same(failure)` 验证原对象抛出并检查尝试次数为一（`v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart:6`、`:28`、`:45`、`:72`）。matcher 两组覆盖同 code 成功、错误 code/错误类型失败、空白校验及错误码 mismatch 包含实际 code（`:85`、`:99`）。未扩张边界矩阵、mock、延迟或源码检查，符合全局测试精简规则。
- 两项指定 mutation 均有真实检测力：跳过失败前计数递增会被失败表的次数断言捕获；将 matcher 改为比较 message 会被同 code 成功断言捕获。报告与 controller fresh evidence 均确认 mutation 已被检测并恢复（`v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart:79`、`:91`；`task-F1-07-report.md:13`；`task-F1-07-review-package.md:277`）。

## Strengths

- fake 的行为路径极短，计数与抛错顺序直接可见，且配置在构造边界一次性冻结，确定性强（`v2/packages/plugin_devkit/lib/src/fakes/fake_plugin.dart:6`、`:16`、`:38`）。
- matcher 将输入校验、匹配条件和两类 mismatch 描述分开，公开 API 最小且没有测试框架泄漏到生产库（`v2/packages/plugin_devkit/lib/src/matchers/plugin_failure_matcher.dart:4`、`:18`、`:30`）。
- 操作测试使用 record 表统一表达 invoke/counter，八个实际用例由四组主场景产生，覆盖核心契约但没有重复测试膨胀（`v2/packages/plugin_devkit/test/fakes/fake_plugin_test.dart:7`、`:46`、`:85`、`:99`）。

## Critical

无。

## Important

无。

## Minor

- **验证报告的 contracts 计数与 fresh controller evidence 不一致。** `task-F1-07-report.md:9` 写为 49/49，而 `task-F1-07-review-package.md:273`、`:278` 明确记录本次 fresh 结果和已接受的任务前基线均为 48/48。该差异只影响报告数字的准确性：controller 仍记录 exit 0，且实现、测试和契约包均未因此出现功能偏差，因此不构成验收阻塞；报告数字应更正为 48/48。

## Decision

**Approved**

Task quality：**High**。实现与最小测试准确覆盖 F1-07 的绑定行为、公开依赖边界和两项关键 mutation；唯一缺陷是报告中的非阻塞计数笔误。

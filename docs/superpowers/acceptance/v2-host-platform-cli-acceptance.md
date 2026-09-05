# G3 验收报告：M3 Flutter 宿主、平台适配与 CLI（F3-01 ～ F3-08）

**验收日期**: 2026-09-05
**验收方式**: 双门独立验收（A 架构边界 / B 构建证据），两门均为全新上下文只读验收智能体，互不引用对方结论；因单模型环境，Master Plan 的 Sol/Terra 双角色以同一验收体系中两个独立分节执行
**验收输入**: 设计规格 §3/§9/§10/§12/§13、M3 冻结计划、冻结艺术方向文档、v2 全部实现、progress.yaml 偏差裁定、batch2/3/4 实现报告

---

## 最终结论：**Approved**（双门一致）

| 门 | 结论 | Critical | Important | Minor |
|---|---|---|---|---|
| G3-A 架构边界 | Approved | 0 | 0 | 3 |
| G3-B 构建证据 | Approved | 0 | 0 | 1 |

**分门详细报告**：
- A 门：[v2-host-platform-cli-acceptance-a.md](./v2-host-platform-cli-acceptance-a.md)
- B 门：[v2-host-platform-cli-acceptance-b.md](./v2-host-platform-cli-acceptance-b.md)

## 关键证据摘要

- **架构**：Composition Root 唯一；依赖方向全向合规；三 preset 令牌保真 30/30 与冻结文档逐字一致；样式字面量纪律由静态扫描测试固化；Surface 语义无静默降级；G2 三项遗留（decoder 参数 / stdout 单订阅 / 就绪帧）确认全部消化。
- **测试**：14 包全绿，250 测试 0 失败（dart 192 + flutter 58）。
- **构建矩阵**：windows / web / android 三端实构建产物实证（exe 577KB / index.html / app-debug.apk）；macos/linux/ios 如实标注 SKIPPED-LOCAL-UNAVAILABLE，以 compile-graph 静态检查（12 包 0 平台专属导入）+ analyze 为替代证据；无伪造六端全绿声明。
- **工具链**：dart format 131 文件 0 changed；flutter analyze No issues。

## Minor 发现汇总（4 项，不阻塞，登记为 M4 计划输入）

1. devkit pubspec 声明 `plugin_runtime` 但零引用（死依赖）——建议 M4 删除
2. `surface.unsupported` 工厂无生产调用点（宿主以禁用按钮兜底合规）——建议 M4 接入程序化 surface 解析路径
3. 设置页语言自名硬编码（惯例豁免）——建议加注释防扫描误报
4. toolbox_host 导入 `platform_capabilities_windows`——组合根唯一注入点，合规留档

## 偏差裁定汇总

两门对 progress.yaml 中登记的全部 accepted_deviations（devkit Flutter 依赖、自绘 Rect、令牌访问器命名、占位框渲染、宿主平台目录补建等）均裁定接受，无需修复项。

---

**Controller 后续动作**：F3-01～F3-08、G3 与 M3 标记 `accepted`；进入 M4 规划（MVP 真实插件）。建议提交信息：`feat(platform): complete host and platform adapters`。

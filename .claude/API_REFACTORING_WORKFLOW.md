# API 重构工作流程

> 📖 标准化的 API 重构流程，确保不遗漏任何文件

## 🎯 适用场景

当您需要：
- 移除或添加接口方法
- 修改数据模型字段
- 重命名类或方法
- 删除功能模块

## 📋 标准流程

### 阶段 1: 准备（5分钟）

#### 1.1 创建功能分支
```bash
git checkout -b refactor/remove-enable-disable
```

#### 1.2 运行基线检查
```bash
# 确保当前代码是干净的
flutter analyze
flutter test
```

#### 1.3 执行全面搜索
```bash
# 使用检查脚本
.claude\scripts\check_refactoring.bat "enablePlugin|disablePlugin|isPluginEnabled"

# 或手动搜索
grep -rn "enablePlugin" --include="*.dart" lib/
grep -rn "disablePlugin" --include="*.dart" lib/
grep -rn "isPluginEnabled" --include="*.dart" lib/
grep -rn "plugin_enabled\|plugin_disabled" --include="*.dart" lib/
```

#### 1.4 记录所有文件
将搜索结果保存到 `REFACTORING_FILES.md`:
```markdown
## 需要修改的文件

### 接口层
- [ ] lib/core/interfaces/i_plugin_manager.dart

### 实现层
- [ ] lib/core/services/plugin_manager.dart

### 模型层
- [ ] lib/core/models/plugin_models.dart

### UI 层
- [ ] lib/ui/widgets/plugin_card.dart
- [ ] lib/ui/widgets/plugin_details_dialog.dart
- [ ] lib/ui/screens/plugin_management_screen.dart
- [ ] lib/ui/screens/main_platform_screen.dart

### 国际化
- [ ] lib/l10n/app_zh.arb
- [ ] lib/l10n/app_en.arb
```

### 阶段 2: 执行（按顺序）

#### 2.1 修改接口定义
```bash
# 文件: lib/core/interfaces/i_plugin_manager.dart
# 修改: 移除方法定义
```

**修改后立即验证**:
```bash
flutter analyze lib/core/interfaces/i_plugin_manager.dart
```

#### 2.2 修改实现类
```bash
# 文件: lib/core/services/plugin_manager.dart
# 修改: 移除方法实现
```

**修改后立即验证**:
```bash
flutter analyze lib/core/services/plugin_manager.dart
```

#### 2.3 修改数据模型
```bash
# 文件: lib/core/models/plugin_models.dart
# 修改: 移除字段
```

**修改后立即验证**:
```bash
flutter analyze lib/core/models/plugin_models.dart
```

#### 2.4 修改 UI 组件
按照依赖顺序，从底层到顶层：

1. **基础组件**
   - `lib/ui/widgets/plugin_card.dart`
   - `lib/ui/widgets/plugin_details_dialog.dart`

2. **页面组件**
   - `lib/ui/screens/plugin_management_screen.dart`
   - `lib/ui/screens/main_platform_screen.dart` ⚠️

**每个文件修改后立即验证**:
```bash
flutter analyze lib/ui/widgets/plugin_card.dart
flutter analyze lib/ui/widgets/plugin_details_dialog.dart
# ... 依此类推
```

#### 2.5 修改国际化
```bash
# 文件: lib/l10n/app_zh.arb
# 文件: lib/l10n/app_en.arb
# 修改: 移除翻译键
```

**修改后立即重新生成**:
```bash
flutter gen-l10n
```

### 阶段 3: 验证（10分钟）

#### 3.1 全面搜索确认
```bash
# 使用检查脚本
.claude\scripts\check_refactoring.bat "enablePlugin|disablePlugin|isPluginEnabled"

# 应该输出: ✅ 未发现引用
```

#### 3.2 代码分析
```bash
flutter analyze
# 应该输出: No issues found
```

#### 3.3 构建测试
```bash
# 选择您正在开发的目标平台
flutter build windows --debug
# 或
flutter build web
# 或
flutter build macos --debug
```

#### 3.4 运行测试
```bash
flutter test
```

### 阶段 4: 提交（2分钟）

#### 4.1 查看变更
```bash
git status
git diff
```

#### 4.2 提交变更
```bash
git add .
git commit -m "refactor: 移除插件启用/禁用功能

- 从 IPluginManager 接口中移除 enablePlugin/disablePlugin 方法
- 从 PluginInfo 模型中移除 isEnabled 字段
- 简化插件状态管理，统一使用 PluginState
- 更新所有 UI 组件，移除启用/禁用开关
- 更新国际化文件，移除相关翻译键

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

#### 4.5 推送到远程
```bash
git push origin refactor/remove-enable-disable
```

## 🔧 常见问题排查

### 问题 1: 编译失败
**症状**: 修改后编译报错

**排查步骤**:
1. 检查错误消息，定位到具体文件
2. 确认该文件在您的修改清单中
3. 如果不在清单中，添加到清单并修改
4. 如果在清单中，检查修改是否完整

**预防措施**:
- 使用更全面的搜索模式
- 不假设任何文件无关

### 问题 2: 运行时错误
**症状**: 编译通过但运行时崩溃

**排查步骤**:
1. 检查堆栈跟踪，找到调用点
2. 确认调用处的代码是否已更新
3. 检查是否有动态调用（如反射）

**预防措施**:
- 运行完整测试套件
- 手动测试关键流程

### 问题 3: 国际化未更新
**症状**: 使用了已删除的翻译键

**排查步骤**:
1. 检查 ARB 文件是否已更新
2. 运行 `flutter gen-l10n`
3. 检查生成的代码

**预防措施**:
- 修改 ARB 后立即重新生成
- 使用检查脚本搜索翻译键

## 📊 效率对比

### ❌ 传统方式（本次案例）
1. 修改部分文件 ✅
2. 运行编译 ❌ **失败**
3. 搜索遗漏的文件
4. 修复遗漏
5. 再次编译
6. **总耗时**: 30分钟

### ✅ 改进方式（使用检查清单）
1. 全面搜索（5分钟）✅
2. 列出所有文件（2分钟）✅
3. 按顺序修改（15分钟）✅
4. 每步验证（5分钟）✅
5. 一次编译通过 ✅
6. **总耗时**: 27分钟

### ⚡ 最佳方式（使用自动化脚本）
1. 运行搜索脚本（1分钟）✅
2. 按脚本输出的文件列表修改（15分钟）✅
3. 运行验证脚本（1分钟）✅
4. 一次编译通过 ✅
5. **总耗时**: 17分钟

## 🎓 经验教训

### 本次案例的错误

| 步骤 | 实际操作 | 应该这样做 |
|------|---------|-----------|
| 搜索 | 只搜索了方法名 | 搜索所有相关模式（方法、变量、翻译键） |
| 文件选择 | 假设主界面不相关 | 检查所有引用接口的文件 |
| 验证 | 修改完成后才编译 | 每个文件修改后立即验证 |
| 测试 | 只运行了 analyze | 应该包含构建测试 |

### 改进措施

1. **全面搜索**
   ```bash
   # 不只是搜索方法名
   grep -r "enablePlugin"  # ❌ 不够

   # 搜索所有相关模式
   grep -r "enablePlugin|disablePlugin|isPluginEnabled|isEnabled"  # ✅
   ```

2. **不假设无关**
   - 列出所有引用接口的文件
   - 逐一检查，不跳过任何文件

3. **增量验证**
   - 修改一个文件 → 验证一个文件
   - 而不是修改所有文件 → 一次性验证

4. **完整测试**
   - analyze + build + test
   - 而不是只运行 analyze

## 🚀 下次重构时

### 快速开始
```bash
# 1. 创建分支
git checkout -b refactor/your-feature

# 2. 搜索所有引用
.\.claude\scripts\check_refactoring.bat "your-pattern"

# 3. 按输出的文件列表逐一修改

# 4. 每修改一个文件，运行
flutter analyze path/to/modified_file.dart

# 5. 全部修改完成后，运行
.\.claude\scripts\check_refactoring.bat "your-pattern"

# 6. 验证
flutter analyze && flutter build windows --debug

# 7. 提交
git add . && git commit -m "refactor: ..."
```

### 使用检查清单
```bash
# 打开重构检查清单
code .claude/REFACTORING_CHECKLIST.md

# 按清单逐项完成
```

---

**记住**: 快速的方法不一定快，慢就是快，一次做对！

# AI 编码规则 - 代码风格规范

> 📋 **本文档定义了项目中所有代码必须遵守的风格规范，所有 AI 助手和开发者必须遵守**

**版本**: v1.0.0
**生效日期**: 2026-01-20
**适用范围**: 所有 Dart/Flutter 代码
**参考标准**: [Effective Dart](https://dart.dev/guides/language/effective-dart) 和 [Flutter 风格指南](https://flutter.dev/docs/development/data-and-backend/state-mgmt/simple)

---

## 🎯 核心原则

### 1. 一致性优先
代码风格必须保持一致。当有疑问时，遵循项目现有代码的风格。

### 2. 可读性优先
代码应该像文档一样易读。让代码自解释，减少注释的依赖。

### 3. 工具辅助
使用自动化工具强制执行风格规范，减少人工审查负担。

---

## 📐 格式化规范

### 自动格式化

**强制要求**: 所有代码必须使用 `dart format` 格式化

```bash
# 格式化单个文件
dart format path/to/file.dart

# 格式化整个项目
dart format .

# 格式化并显示修改的文件
dart format --output=none --set-exit-if-changed .
```

**格式化规则**:
- 行长度: 80 字符（dart format 默认）
- 缩进: 2 空格（不使用 Tab）
- 尾随逗号: 必须（便于多行编辑）
- 空行: 逻辑块之间保留一个空行

---

### 代码组织

#### Import 顺序

**标准顺序**:
```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. Flutter 框架
import 'package:flutter/material.dart';

// 3. 第三方包（字母顺序）
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 4. 项目内部（相对路径，字母顺序）
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
import 'my_widget.dart';
```

**分组规则**:
- 每组之间保留一个空行
- 组内按字母顺序排列
- 使用相对路径导入项目文件

---

#### 文件结构

**标准结构**:
```dart
// 1. library 指令（可选）
library my_feature.my_widget;

// 2. import 语句
import 'package:flutter/material.dart';

// 3. 文档注释
/// MyWidget does amazing things.
///
/// This widget is used for...
class MyWidget extends StatelessWidget {
  // 4. 公共常量
  static const double defaultSize = 100.0;

  // 5. 公共静态方法
  static MyWidget create() => MyWidget._();

  // 6. 私有常量
  static const double _maxSize = 200.0;

  // 7. 成员变量
  final String title;
  final int count;

  // 8. 构造函数
  const MyWidget({
    required this.title,
    this.count = 0,
  });

  // 9. 私有构造函数
  MyWidget._();

  // 10. 公共方法
  @override
  Widget build(BuildContext context) {
    // ...
  }

  // 11. 私有方法
  void _privateMethod() {
    // ...
  }

  // 12. 子类（嵌套类）
  class _NestedClass {
    // ...
  }
}
```

---

## 🏷️ 命名规范

### 基本原则

| 类型 | 规范 | 示例 |
|------|------|------|
| **类名** | PascalCase（大驼峰） | `MyWidget`, `UserService` |
| **枚举类型** | PascalCase | `MenuState`, `UserRole` |
| **类型别名** | PascalCase | `JsonMap`, `ErrorHandler` |
| **函数名** | camelCase（小驼峰） | `getData()`, `calculateTotal()` |
| **变量名** | camelCase | `userName`, `totalPrice` |
| **常量** | camelCase 或 lowerCamelCase | `maxWidth`, `defaultTimeout` |
| **私有成员** | camelCase + 下划线前缀 | `_privateVar`, `_helper()` |
| **库前缀** | snake_case + 库名 | `math.pi`, `MaterialApp` |

---

### 类名

**规范**: PascalCase，使用名词，避免缩写

```dart
// ✅ 正确
class UserProfileWidget extends StatelessWidget { }
class DatabaseConnectionManager { }
class HttpApiClient { }

// ❌ 错误
class userProfileWidget extends StatelessWidget { }  // 小驼峰
class DBConnMgr { }  // 缩写
class HTTP_Client { }  // 下划线
```

**后缀约定**:
- Widget 类: `XxxWidget` 或 `XxxScreen`
- State 类: `_XxxWidgetState`（私有）
- Model 类: `XxxModel`
- Service 类: `XxxService` 或 `XxxManager`

---

### 函数名

**规范**: camelCase，使用动词开头

```dart
// ✅ 正确
void getUserData() { }
Future<void> saveSettings() async { }
bool isValidInput(String input) { }
String formatPhoneNumber(String number) { }

// ❌ 错误
void GetUserData() { }  // 大写开头
void user_data() { }  // 下划线
void saveDataToLocalStorage() { }  // 过长
```

**异步函数**: 必须返回 `Future<T>`

```dart
// ✅ 正确
Future<String> fetchUserName() async { }
Future<void> initializeApp() async { }

// ❌ 错误
String fetchUserName() async { }  // 缺少 Future
void initializeApp() async { }  // 缺少 Future
```

---

### 变量名

**规范**: camelCase，使用名词，描述性命名

```dart
// ✅ 正确
String userName = 'John';
int maxRetryCount = 3;
bool isActive = false;
final List<String> selectedItems = [];

// ❌ 错误
String n = 'John';  // 过短
int x = 0;  // 无意义
bool flag = true;  // 不描述
final list = [];  // 类型不明确
```

**布尔变量**: 使用 `is/has/can/should` 前缀

```dart
// ✅ 正确
bool isLoading = false;
bool hasData = true;
bool canSubmit = false;
bool shouldRefresh = true;

// ❌ 错误
bool loading = false;
bool data = true;
bool submit = false;
```

**私有变量**: 下划线前缀

```dart
class MyClass {
  String _privateVar = '';  // ✅ 私有
  String publicVar = '';    // ✅ 公共

  void _privateMethod() { }  // ✅ 私有方法
  void publicMethod() { }    // ✅ 公共方法
}
```

---

### 常量

**规范**: camelCase 或 lowerCamelCase

```dart
// ✅ 正确
const double defaultFontSize = 14.0;
const int maxRetries = 3;
const String apiBaseUrl = 'https://api.example.com';

// ❌ 避免（除非非常明确）
const MAX_RETRIES = 3;  // SCREAMING_CASE 在 Dart 中不常见
```

**枚举值**: PascalCase

```dart
enum MenuState {
  closed,
  opening,
  open,
  closing,
}
```

---

## 💬 注释规范

### 文档注释

**规范**: 使用三斜线 `///` 用于公共 API

```dart
/// 用户信息数据模型。
///
/// 包含用户的基本信息，如姓名、邮箱和电话号码。
///
/// 示例:
/// ```dart
/// final user = UserModel(
///   name: 'John Doe',
///   email: 'john@example.com',
///   phone: '123-456-7890',
/// );
/// ```
class UserModel {
  /// 用户的全名。
  final String name;

  /// 用户的电子邮箱地址。
  ///
  /// 必须是有效的邮箱格式。
  final String email;

  /// 用户的电话号码。
  ///
  /// 可选字段，如果用户未提供则为空字符串。
  final String phone;

  const UserModel({
    required this.name,
    required this.email,
    this.phone = '',
  });
}
```

**文档注释内容**:
- 第一行：简短描述（句号结尾）
- 第二段：详细说明
- 示例代码：用 `/// 示例:` 开始
- 参数说明：`@param`
- 返回值说明：`@return`
- 异常说明：`@throws`

---

### 代码注释

**规范**: 使用双斜线 `//`，注释在代码上方

```dart
// 检查用户是否有权限访问资源
if (user.hasPermission) {
  // 允许访问，加载数据
  _loadData();
} else {
  // 拒绝访问，显示错误
  _showError();
}

// ❌ 避免无意义注释
user.name = 'John';  // 设置名字（这是废话）
```

**注释时机**:
- ✅ **为什么**：解释"为什么"这样做，而不是"做了什么"
- ✅ **复杂逻辑**：难以理解的算法或业务逻辑
- ✅ **临时方案**：标记临时方案或待优化代码（`// TODO: ...`）
- ❌ **显而易见**：不要注释显而易见的代码

---

### TODO 注释

**格式**: `// TODO: 描述 - 作者/日期`

```dart
// TODO: 实现分页加载功能 - @claude 2026-01-20
List<Item> getItems() {
  // 临时方案：一次性加载所有数据
  return _fetchAllItems();
}

// TODO: 优化性能 - 当前 O(n²)，应该优化到 O(n log n)
void sortItems(List<Item> items) {
  // ...
}
```

---

## 📏 代码长度规范

### 函数长度

**建议**: 函数体不超过 50 行（不含注释和空行）

```dart
// ✅ 好的函数：短小精悍，职责单一
void saveUserData() {
  _validateInput();
  final user = _buildUserModel();
  _database.save(user);
  _showSuccessMessage();
}

// ❌ 避免：过长函数，职责不清
void processUserData() {
  // 100+ 行代码...
  // 应该拆分成多个小函数
}
```

**拆分建议**:
- 单一职责：每个函数只做一件事
- 提取方法：重复代码提取为函数
- 命名准确：函数名应该准确描述功能

---

### 类长度

**建议**: 单个类不超过 500 行

```dart
// ✅ 好的类：职责清晰，代码组织良好
class UserProfileWidget extends StatelessWidget {
  // 1. 成员变量（10行）

  // 2. 构造函数（10行）

  // 3. build 方法（50行）

  // 4. 辅助方法（每个20-30行，共5个）
  // 总计：~200行
}

// ❌ 避免：过长类
class SuperWidget extends StatefulWidget {
  // 500+ 行代码...
  // 应该拆分成多个小组件
}
```

---

### 参数数量

**建议**: 函数参数不超过 5 个

```dart
// ✅ 好的函数：参数少，清晰
void createUser(String name, String email) { }

// ✅ 使用命名参数
void createUser({
  required String name,
  required String email,
  int age = 0,
  String? phone,
}) { }

// ✅ 使用参数对象
class CreateUserParams {
  final String name;
  final String email;
  final int age;
  final String? phone;
}

void createUser(CreateUserParams params) { }

// ❌ 避免：参数过多
void createUser(String name, String email, int age, String phone, String address, String city, String zip) { }
```

---

## 🎨 UI 代码规范

### Widget 组织

**规范**: 拆分为小组件，提高可读性

```dart
// ✅ 好的 Widget：拆分清晰
class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('User Profile'),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListView(
      children: [
        _buildHeaderSection(context),
        _buildInfoSection(context),
        _buildActionSection(context),
      ],
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    // ...
  }

  Widget _buildInfoSection(BuildContext context) {
    // ...
  }

  Widget _buildActionSection(BuildContext context) {
    // ...
  }
}

// ❌ 避免：所有代码都在 build 中
class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 200+ 行嵌套代码...
        ],
      ),
    );
  }
}
```

---

### Widget 命名

**后缀约定**:
- 页面/屏幕: `XxxScreen`
- 对话框: `XxxDialog`
- 底部表单: `XxxBottomSheet`
- 列表项: `XxxTile` 或 `XxxListItem`
- 卡片: `XxxCard`
- 按钮: `XxxButton`
```dart
class SettingsScreen extends StatelessWidget { }
class ConfirmDialog extends StatelessWidget { }
class AddTaskBottomSheet extends StatelessWidget { }
class TaskTile extends StatelessWidget { }
class UserCard extends StatelessWidget { }
class DeleteButton extends StatelessWidget { }
```

---

### 常量提取

**规范**: 重复使用的 Widget 值提取为常量

```dart
// ✅ 正确：提取常量
class MyWidget extends StatelessWidget {
  static const double _borderRadius = 8.0;
  static const double _spacing = 16.0;
  static const Color _primaryColor = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        color: _primaryColor,
      ),
      padding: EdgeInsets.all(_spacing),
    );
  }
}

// ❌ 避免：魔法数字
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),  // 魔法数字
        color: Color(0xFF2196F3),  // 魔法颜色
      ),
      padding: EdgeInsets.all(16.0),  // 魔法数字
    );
  }
}
```

---

## 🔧 最佳实践

### 1. 使用类型推断

```dart
// ✅ 正确：局部变量使用推断
final name = 'John';  // 推断为 String
final items = <String>[];  // 明确泛型类型
const timeout = Duration(seconds: 30);  // 推断类型

// ✅ 必须明确类型的场景
final Function(String) callback;  // 函数类型
final Map<String, dynamic> data;  // 复杂类型
```

---

### 2. 使用级联操作

```dart
// ✅ 正确：使用级联
final button = Button()
  ..text = 'Click me'
  ..backgroundColor = Colors.blue
  ..onPressed = () {};

// ❌ 避免：重复变量名
final button = Button();
button.text = 'Click me';
button.backgroundColor = Colors.blue;
button.onPressed = () {};
```

---

### 3. 使用扩展方法

```dart
// ✅ 正确：扩展方法提高可读性
extension StringExtension on String {
  bool get isEmail => contains('@');
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

// 使用
if (userEmail.isEmail) {
  print(userName.capitalize());
}
```

---

### 4. 避免嵌套过深

```dart
// ✅ 正确：提前返回
void processData(Data? data) {
  if (data == null) {
    return;
  }

  if (!data.isValid) {
    return;
  }

  // 处理数据
}

// ❌ 避免：嵌套过深
void processData(Data? data) {
  if (data != null) {
    if (data.isValid) {
      // 处理数据
    } else {
      // ...
    }
  } else {
    // ...
  }
}
```

---

### 5. 使用构造函数赋值

```dart
// ✅ 正确：使用构造函数赋值
class UserModel {
  final String name;
  final String email;

  UserModel({
    required this.name,
    required this.email,
  });
}

// ✅ 初始化列表
class MyWidget extends StatelessWidget {
  final List<String> items = const ['Item 1', 'Item 2', 'Item 3'];

  const MyWidget({super.key});
}
```

---

## 🚫 禁止的写法

### 1. 禁止使用 `var`

```dart
// ❌ 错误
var name = 'John';  // 类型不明确
var count = 0;

// ✅ 正确
final name = 'John';  // 类型推断
final count = 0;
int totalCount = 0;  // 明确类型
```

---

### 2. 禁止使用 `dynamic`

```dart
// ❌ 错误
dynamic data = fetchData();  // 类型不安全
List<dynamic> items = [];  // 类型不明确

// ✅ 正确
final data = fetchData();  // 推断类型
final items = <String>[];  // 明确泛型
List<Map<String, dynamic>> data = [];  // 明确类型
```

---

### 3. 禁止使用 `print`

```dart
// ❌ 错误：使用 print
print('Debug info');

// ✅ 正确：使用 debugPrint
debugPrint('Debug info');

// ✅ 或使用日志服务
Log.info('Debug info');
```

---

### 4. 禁止使用 `as!` 和 `as`

```dart
// ❌ 错误：强制类型转换
final user = data as UserModel;  // 运行时错误风险
final list = items as List<String>;  // 不安全

// ✅ 正确：类型检查和转换
if (data is UserModel) {
  final user = data as UserModel;
  // 使用 user
}

// ✅ 或使用模式匹配
if (data case UserModel user) {
  // 使用 user
}
```

---

### 5. 禁止忽略返回值

```dart
// ❌ 错误：忽略 Future
fetchUserData();  // Future 未被 await

// ✅ 正确：处理 Future
await fetchUserData();
// 或
fetchUserData().catchError((e) => print(e));

// ✅ 正确：使用 unawaited（仅当你确定要忽略时）
unawaited(fetchUserData());
```

---

## ✅ 检查清单

### 代码提交前检查

- [ ] 运行 `dart format` 格式化所有代码
- [ ] 运行 `dart analyze` 确保无警告
- [ ] 检查所有公共 API 有文档注释
- [ ] 检查函数长度不超过 50 行
- [ ] 检查类长度不超过 500 行
- [ ] 检查参数数量不超过 5 个
- [ ] 检查变量命名清晰有意义
- [ ] 检查没有使用 `var` 和 `dynamic`
- [ ] 检查没有使用 `print`
- [ ] 检查 Widget 拆分合理

---

## 🔍 代码审查要点

### 审查时关注的要点

1. **命名**: 变量、函数、类名是否清晰描述
2. **长度**: 函数、类是否过长，需要拆分
3. **复杂度**: 逻辑是否过于复杂，难以理解
4. **重复**: 是否有重复代码，可以提取
5. **注释**: 是否注释了"为什么"而非"做了什么"
6. **格式**: 是否运行了 `dart format`
7. **错误处理**: 是否正确处理异常和边界情况

---

## 🛠️ 工具配置

### VS Code 设置

```json
{
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "dart.lineLength": 80,
  "dart.enableSdkFormatter": true,
  "dart.insertArgumentPlaceholders": true,
  "dart.completeFunctionCalls": true,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true
}
```

### Dart 分析配置

**文件**: `analysis_options.yaml`

```yaml
include: package:lints/recommended.yaml

linter:
  rules:
    # 强制规则
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - prefer_final_locals
    - unnecessary_const
    - unnecessary_new
    - prefer_single_quotes
    - sort_pub_dependencies
    - always_declare_return_types
    - avoid_print
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_relative_lib_imports
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_typing_uninitialized_variables
    - unawaited_futures
    - unnecessary_brace_in_string_interps

analyzer:
  errors:
    # 将警告视为错误
    missing_required_param: error
    missing_return: error
    todo: ignore
```

---

## 📚 参考资源

### 官方文档
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Dart 风格指南](https://dart.dev/guides/language/effective-dart/style)
- [Flutter 性能最佳实践](https://flutter.dev/docs/perf/best-practices)

### 相关规范
- [文件组织规范](./FILE_ORGANIZATION_RULES.md)
- [测试规范](./TESTING_RULES.md)
- [国际化规范](./INTERNATIONALIZATION_RULES.md)

---

## 🎯 快速参考

| 场景 | 规范 | 示例 |
|------|------|------|
| **类名** | PascalCase | `UserProfileWidget` |
| **函数名** | camelCase | `getData()` |
| **变量名** | camelCase | `userName` |
| **常量** | camelCase | `maxWidth` |
| **私有成员** | _前缀 | `_privateVar` |
| **布尔变量** | is/has/can | `isValid` |
| **文件格式化** | dart format | `dart format .` |
| **行长度** | 80 字符 | - |
| **函数长度** | ≤50 行 | - |
| **类长度** | ≤500 行 | - |

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 运行 `dart format . && dart analyze` 确保代码符合规范！

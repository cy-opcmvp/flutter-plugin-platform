# AI 编码规则 - 测试规范

> 📋 **本文档定义了项目中所有测试必须遵守的规范，所有 AI 助手和开发者必须遵守**

**版本**: v1.0.0
**生效日期**: 2026-01-20
**适用范围**: 所有测试代码（单元测试、Widget 测试、集成测试）
**最低覆盖率要求**: 80%

---

## 🎯 核心原则

### 1. 测试优先
测试应该与代码同步编写，而不是事后补充。

### 2. 独立性
每个测试应该独立运行，不依赖其他测试的状态。

### 3. 可重复性
测试应该是确定性的，多次运行结果应该一致。

### 4. 快速性
单元测试应该快速运行，避免耗时操作。

---

## 📁 测试文件组织

### 目录结构

```
test/
├── unit/                      # 单元测试
│   ├── core/
│   │   ├── services/
│   │   │   ├── notification_service_test.dart
│   │   │   └── audio_service_test.dart
│   │   ├── models/
│   │   │   ├── plugin_models_test.dart
│   │   │   └── user_model_test.dart
│   │   └── utils/
│   │       └── date_utils_test.dart
│   └── plugins/
│       ├── calculator/
│       │   └── calculator_plugin_test.dart
│       └── screenshot/
│           └── screenshot_plugin_test.dart
│
├── widget/                    # Widget 测试
│   ├── widgets/
│   │   ├── plugin_card_test.dart
│   │   └── settings_screen_test.dart
│   └── screens/
│       ├── main_screen_test.dart
│       └── settings_screen_test.dart
│
├── integration/               # 集成测试
│   ├── plugin_loading_test.dart
│   └── platform_services_test.dart
│
└── test_utils/                # 测试工具（不运行测试）
    ├── mock_classes.dart
    ├── test_data.dart
    └── fixtures/
        ├── sample_plugin.json
        └── sample_config.json
```

---

## 🏷️ 测试文件命名

### 命名规范

| 测试类型 | 文件命名规则 | 示例 |
|---------|-------------|------|
| **单元测试** | `{filename}_test.dart` | `user_model_test.dart` |
| **Widget 测试** | `{widget}_test.dart` | `plugin_card_test.dart` |
| **Screen 测试** | `{screen}_test.dart` | `settings_screen_test.dart` |
| **集成测试** | `{feature}_test.dart` | `plugin_loading_test.dart` |

**对应关系**:
```dart
// 源文件: lib/models/user_model.dart
// 测试文件: test/unit/models/user_model_test.dart

// 源文件: lib/widgets/plugin_card.dart
// 测试文件: test/widget/widgets/plugin_card_test.dart
```

---

## 📊 测试覆盖率要求

### 最低覆盖率标准

| 类型 | 最低覆盖率 | 推荐覆盖率 |
|------|-----------|-----------|
| **核心业务逻辑** | 90% | 95% |
| **工具类/Utils** | 100% | 100% |
| **数据模型** | 100% | 100% |
| **服务层** | 85% | 90% |
| **Widget** | 80% | 85% |
| **插件代码** | 80% | 85% |

### 覆盖率检查

```bash
# 运行测试并生成覆盖率报告
flutter test --coverage

# 将覆盖率转换为 LCov 格式
flutter pub run coverage:format_coverage \
  --lcov \
  --in=coverage \
  --out=coverage/lcov.info \
  --packages=.packages \
  --report-on=lib

# 在浏览器中查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
```

---

## 🧪 单元测试规范

### 基本结构

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/models/user_model.dart';

void main() {
  group('UserModel', () {
    group('构造函数', () {
      test('应该创建默认用户', () {
        // Arrange（准备）
        const expectedName = '';
        const expectedEmail = '';

        // Act（执行）
        final user = const UserModel();

        // Assert（断言）
        expect(user.name, equals(expectedName));
        expect(user.email, equals(expectedEmail));
      });

      test('应该使用提供的参数创建用户', () {
        // Arrange
        const name = 'John Doe';
        const email = 'john@example.com';

        // Act
        final user = const UserModel(
          name: name,
          email: email,
        );

        // Assert
        expect(user.name, equals(name));
        expect(user.email, equals(email));
      });
    });

    group('fromJson', () {
      test('应该从 JSON 创建用户', () {
        // Arrange
        final json = {
          'name': 'John Doe',
          'email': 'john@example.com',
        };

        // Act
        final user = UserModel.fromJson(json);

        // Assert
        expect(user.name, equals('John Doe'));
        expect(user.email, equals('john@example.com'));
      });

      test('缺少必需字段时应该抛出异常', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act & Assert
        expect(
          () => UserModel.fromJson(json),
          throwsA(isA<TypeError>()),
        );
      });
    });

    group('toJson', () {
      test('应该将用户转换为 JSON', () {
        // Arrange
        const user = UserModel(
          name: 'John Doe',
          email: 'john@example.com',
        );

        // Act
        final json = user.toJson();

        // Assert
        expect(json['name'], equals('John Doe'));
        expect(json['email'], equals('john@example.com'));
      });
    });

    group('isValid', () {
      test('有效数据应该返回 true', () {
        // Arrange
        const user = UserModel(
          name: 'John Doe',
          email: 'john@example.com',
        );

        // Act
        final result = user.isValid();

        // Assert
        expect(result, isTrue);
      });

      test('空邮箱应该返回 false', () {
        // Arrange
        const user = UserModel(
          name: 'John Doe',
          email: '',
        );

        // Act
        final result = user.isValid();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
```

---

### AAA 模式

所有测试必须遵循 **AAA 模式**:

1. **Arrange**（准备）: 设置测试数据和环境
2. **Act**（执行）: 执行被测试的代码
3. **Assert**（断言）: 验证结果

```dart
test('计算总价', () {
  // Arrange: 准备测试数据
  const price = 100.0;
  const quantity = 2;

  // Act: 执行被测试的函数
  final total = calculateTotal(price, quantity);

  // Assert: 验证结果
  expect(total, equals(200.0));
});
```

---

### 测试分组

使用 `group()` 组织相关测试:

```dart
void main() {
  group('UserModel', () {
    group('构造函数', () {
      // 测试所有构造函数场景
    });

    group('序列化', () {
      group('fromJson', () {
        // 测试 fromJson
      });

      group('toJson', () {
        // 测试 toJson
      });
    });

    group('验证', () {
      // 测试验证逻辑
    });
  });
}
```

---

## 🎨 Widget 测试规范

### 基本结构

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/widgets/plugin_card.dart';

void main() {
  group('PluginCard Widget', () {
    group('渲染测试', () {
      testWidgets('应该显示插件名称和描述', (tester) async {
        // Arrange
        const pluginName = 'Calculator';
        const description = 'A simple calculator';

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PluginCard(
                name: pluginName,
                description: description,
              ),
            ),
          ),
        );

        // Assert
        expect(find.text(pluginName), findsOneWidget);
        expect(find.text(description), findsOneWidget);
      });

      testWidgets('应该显示图标', (tester) async {
        // Arrange
        const icon = Icons.calculate;

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PluginCard(
                name: 'Calculator',
                description: 'A simple calculator',
                icon: icon,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(icon), findsOneWidget);
      });
    });

    group('交互测试', () {
      testWidgets('点击时应该触发回调', (tester) async {
        // Arrange
        var clicked = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PluginCard(
                name: 'Calculator',
                description: 'A simple calculator',
                onTap: () {
                  clicked = true;
                },
              ),
            ),
          ),
        );

        // Act
        await tester.tap(find.byType(PluginCard));
        await tester.pump();

        // Assert
        expect(clicked, isTrue);
      });
    });

    group('边界情况', () {
      testWidgets('空名称应该显示默认文本', (tester) async {
        // Arrange
        const name = '';
        const defaultText = 'Unknown Plugin';

        // Act
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: PluginCard(
                name: name,
                description: 'Test',
              ),
            ),
          ),
        );

        // Assert
        expect(find.text(defaultText), findsOneWidget);
      });
    });
  });
}
```

---

### Widget 测试要点

1. **使用 `testWidgets`**: Widget 测试必须使用 `testWidgets`
2. **使用 `pumpWidget`**: 必须渲染 Widget
3. **使用 `pump()`**: 状态更新后调用
4. **查找 Widget**: 使用 `find.byType`, `find.text`, `find.byKey`
5. **验证渲染**: 使用 `findsOneWidget`, `findsNothing`, `findsWidgets`

---

## 🎭 Mock 使用规范

### Mock 类定义

使用 `mockito` 包创建 Mock 类:

```dart
import 'package:mockito/mockito.dart';
import 'package:plugin_platform/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

// 或使用 @generateMocks（需要 build_runner）
@GenerateMocks([NotificationService])
import 'notification_service.mocks.dart';
```

---

### Mock 使用示例

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  group('NotificationService', () {
    late MockNotificationService mockService;

    setUp(() {
      mockService = MockNotificationService();
    });

    test('应该调用 showNotification', () async {
      // Arrange
      const id = 'test';
      const title = 'Test Title';
      const body = 'Test Body';

      // Act
      await mockService.showNotification(
        id: id,
        title: title,
        body: body,
      );

      // Assert
      verify(mockService.showNotification(
        id: id,
        title: title,
        body: body,
      )).called(1);
    });

    test('应该返回 true 当通知成功发送时', () async {
      // Arrange
      when(mockService.showNotification(
        id: any,
        title: any,
        body: any,
      )).thenAnswer((_) async => true);

      // Act
      final result = await mockService.showNotification(
        id: 'test',
        title: 'Test',
        body: 'Body',
      );

      // Assert
      expect(result, isTrue);
      verify(mockService.showNotification(
        id: 'test',
        title: 'Test',
        body: 'Body',
      )).called(1);
    });
  });
}
```

---

### Mock 最佳实践

1. **使用 `setUp`**: 在 `setUp` 中初始化 Mock 对象
2. **使用 `any`**: 参数不重要时使用 `any`
3. **验证调用**: 使用 `verify` 确保方法被调用
4. **设置返回值**: 使用 `when` 设置 Mock 行为
5. **重置 Mock**: 使用 `resetMockito` 在需要时

---

## 📦 测试数据管理

### 测试数据文件

**位置**: `test/test_utils/fixtures/`

**示例**:
```json
// fixtures/sample_plugin.json
{
  "id": "com.example.sample",
  "name": "Sample Plugin",
  "version": "1.0.0",
  "type": "tool"
}
```

**使用测试数据**:
```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform/models/plugin_descriptor.dart';

void main() {
  group('PluginDescriptor', () {
    test('应该从 fixture 加载插件', () async {
      // Arrange
      final json = await rootBundle.loadString(
        'test/test_utils/fixtures/sample_plugin.json',
      );
      final data = jsonDecode(json);

      // Act
      final descriptor = PluginDeserializer.fromJson(data);

      // Assert
      expect(descriptor.id, equals('com.example.sample'));
      expect(descriptor.name, equals('Sample Plugin'));
    });
  });
}
```

---

### 测试工具类

**位置**: `test/test_utils/`

**示例**: `test/test_utils/test_data.dart`

```dart
/// 测试数据工厂
class TestData {
  /// 创建测试用户
  static UserModel createTestUser({
    String name = 'Test User',
    String email = 'test@example.com',
  }) {
    return UserModel(
      name: name,
      email: email,
    );
  }

  /// 创建多个测试用户
  static List<UserModel> createTestUsers(int count) {
    return List.generate(
      count,
      (i) => createTestUser(
        name: 'User $i',
        email: 'user$i@example.com',
      ),
    );
  }
}
```

---

## ✅ 测试检查清单

### 单元测试检查

- [ ] 遵循 AAA 模式（Arrange-Act-Assert）
- [ ] 使用 `group()` 组织相关测试
- [ ] 测试正常场景和边界情况
- [ ] 测试错误处理
- [ ] 使用描述性的测试名称
- [ ] 每个测试只测试一件事

---

### Widget 测试检查

- [ ] 使用 `testWidgets`
- [ ] 测试 Widget 渲染
- [ ] 测试用户交互
- [ ] 测试状态变化
- [ ] 测试边界情况
- [ ] 验证 UI 元素存在

---

### 集成测试检查

- [ ] 测试完整流程
- [ ] 测试多个组件协作
- [ ] 测试真实数据交互
- [ ] 测试错误场景
- [ ] 测试性能要求

---

## 🚫 禁止的测试写法

### 1. 禁止测试顺序依赖

```dart
// ❌ 错误：测试依赖执行顺序
test('步骤 1', () {
  _sharedState = 'step1';
});

test('步骤 2', () {
  expect(_sharedState, 'step1');  // 依赖顺序
});

// ✅ 正确：每个测试独立
test('步骤 1', () {
  final state = 'step1';
  expect(state, 'step1');
});

test('步骤 2', () {
  final state = 'step2';  // 独立状态
  expect(state, 'step2');
});
```

---

### 2. 禁止测试时间依赖

```dart
// ❌ 错误：依赖时间
test('应该在 1 秒后完成', () async {
  final start = DateTime.now();
  await someOperation();
  final elapsed = DateTime.now().difference(start);
  expect(elapsed.inSeconds, lessThan(1));
});

// ✅ 正确：使用 Mockito 控制
test('应该完成操作', () async {
  when(mockService.operation()).thenAnswer((_) async => result);
  await myClass.performOperation();
  verify(mockService.operation()).called(1);
});
```

---

### 3. 禁止测试实现细节

```dart
// ❌ 错误：测试私有方法
test('私有方法应该返回正确值', () {
  final myClass = MyClass();
  expect(myClass._privateMethod(), 42);  // 测试实现
});

// ✅ 正确：测试公共 API
test('公共方法应该返回正确结果', () {
  final myClass = MyClass();
  expect(myClass.publicMethod(), 42);  // 测试接口
});
```

---

### 4. 禁止忽略异常

```dart
// ❌ 错误：忽略异常
test('应该处理异常', () {
  final result = riskyOperation();
  expect(result, isNotNull);  // 即使抛异常也通过
});

// ✅ 正确：验证异常
test('应该处理异常', () {
  expect(
    () => riskyOperation(),
    returnsNormally,
  );
});

test('应该抛出异常', () {
  expect(
    () => riskyOperation(),
    throwsA(isA<InvalidArgumentException>()),
  );
});
```

---

## 🔧 测试工具配置

### pubspec.yaml 配置

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter

  # 测试框架
  test: ^1.24.0

  # Mock 工具
  mockito: ^5.4.0
  build_runner: ^2.4.0
  mocktail: ^1.0.0

  # 覆盖率工具
  coverage: ^1.6.0

  # 代码生成
  json_serializable: ^2.6.0
```

---

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/unit/models/user_model_test.dart

# 运行特定分组
flutter test --name "UserModel"

# 运行并生成覆盖率
flutter test --coverage

# 运行集成测试
flutter test integration_test/

# 运行测试并查看报告
flutter test --reporter expanded
```

---

## 📚 参考资源

### 官方文档
- [Flutter 测试文档](https://flutter.dev/docs/cookbook/testing)
- [Flutter Widget 测试](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Mockito 包文档](https://pub.dev/packages/mockito)

### 相关规范
- [代码风格规范](./CODE_STYLE_RULES.md)
- [错误处理规范](./ERROR_HANDLING_RULES.md)
- [Git 提交规范](./GIT_COMMIT_RULES.md)

---

## 🎯 快速参考

| 场景 | 规范 | 示例 |
|------|------|------|
| **测试文件命名** | `{file}_test.dart` | `user_model_test.dart` |
| **测试分组** | `group('描述', () {})` | `group('构造函数', () {})` |
| **测试模式** | AAA 模式 | Arrange-Act-Assert |
| **单元测试** | `test('描述', () {})` | `test('应该返回 true', () {})` |
| **Widget 测试** | `testWidgets('描述', (tester) {})` | `testWidgets('应该渲染', (tester) {})` |
| **Mock 类** | `MockXxx extends Mock` | `MockService extends Mock` |
| **覆盖率** | ≥80% | - |

---

**版本**: v1.0.0
**最后更新**: 2026-01-20
**维护者**: Flutter Plugin Platform 团队

---

💡 **提示**: 运行 `flutter test --coverage` 确保测试覆盖率符合要求！

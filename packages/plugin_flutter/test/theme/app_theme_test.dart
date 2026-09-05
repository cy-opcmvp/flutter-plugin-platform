// 覆盖场景清单（计划 F3-05 Step 2，相似断言合并）：
// 1. 六套主题实例（三方向 x 明暗）关键值逐项对照冻结美术文档表（每方向
//    明暗各 >=10 项：语义色/中性阶/形状/间距/字体/描边）。
// 2. AppTheme.build 注册 ThemeTokens 扩展、ColorScheme 主色与令牌一致。
// 3. ThemeController 初始值、select 切换并触发持久化回调、同值去重。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_flutter/plugin_flutter.dart';

/// 按方向返回令牌实例（测试对照表数据源）。
ThemeTokens _tokensOf(AppThemePreset preset, Brightness brightness) {
  return switch (preset) {
    AppThemePreset.precisionTools => precisionToolsTokens(brightness),
    AppThemePreset.warmLife => warmLifeTokens(brightness),
    AppThemePreset.darkPro => darkProTokens(brightness),
  };
}

/// 冻结文档关键值对照表（每方向 x 明暗各一组）。
///
/// 取值与 `lib/src/theme/presets/` 三份预设文件逐项一致，预设文件内的
/// 每个值均溯源冻结美术文档（本表用于固化「文档值 == 代码值」）。
const Map<AppThemePreset, Map<Brightness, Map<String, Object>>> _expectedTable =
    <AppThemePreset, Map<Brightness, Map<String, Object>>>{
      AppThemePreset.precisionTools: <Brightness, Map<String, Object>>{
        Brightness.light: <String, Object>{
          'primary': Color(0xFF24538F),
          'surface': Color(0xFFFFFFFF),
          'successContainer': Color(0xFFD9F0DF),
          'warningContainer': Color(0xFFFBEACB),
          'n3': Color(0xFFC9D2DB),
          'outlineVariant': Color(0xFFC9D2DB),
          'radiusMd': 8.0,
          'radiusLg': 14.0,
          'strokeFocus': 2.0,
          'space7': 48.0,
          'displaySize': 28.0,
          'bodyLineHeight': 22.0,
        },
        Brightness.dark: <String, Object>{
          'primary': Color(0xFF85B3E8),
          'surface': Color(0xFF1A2028),
          'successContainer': Color(0xFF1E4A2B),
          'warningContainer': Color(0xFF4A370F),
          'n3': Color(0xFF333E4A),
          'outlineVariant': Color(0xFF333E4A),
          'radiusMd': 8.0,
          'radiusLg': 14.0,
          'strokeFocus': 2.0,
          'space7': 48.0,
          'displaySize': 28.0,
          'bodyLineHeight': 22.0,
        },
      },
      AppThemePreset.warmLife: <Brightness, Map<String, Object>>{
        Brightness.light: <String, Object>{
          'primary': Color(0xFFB4512F),
          'surface': Color(0xFFFFFDF8),
          'successContainer': Color(0xFFDFEED4),
          'warningContainer': Color(0xFFF8E9C8),
          'n3': Color(0xFFDFD3C2),
          'outlineVariant': Color(0xFFDFD3C2),
          'radiusSm': 12.0,
          'radiusMd': 20.0,
          'strokeFocus': 2.0,
          'space5': 24.0,
          'displaySize': 30.0,
          'bodyLineHeight': 24.0,
        },
        Brightness.dark: <String, Object>{
          'primary': Color(0xFFE58F68),
          'surface': Color(0xFF2B231C),
          'successContainer': Color(0xFF2C4A20),
          'warningContainer': Color(0xFF4E3B14),
          'n3': Color(0xFF3E3329),
          'outlineVariant': Color(0xFF3E3329),
          'radiusSm': 12.0,
          'radiusMd': 20.0,
          'strokeFocus': 2.0,
          'space5': 24.0,
          'displaySize': 30.0,
          'bodyLineHeight': 24.0,
        },
      },
      AppThemePreset.darkPro: <Brightness, Map<String, Object>>{
        Brightness.dark: <String, Object>{
          'primary': Color(0xFFA18CFF),
          'surface': Color(0xFF1B1927),
          'successContainer': Color(0xFF1C4A2A),
          'warningContainer': Color(0xFF4E3D14),
          'n3': Color(0xFF2B2840),
          'outlineVariant': Color(0xFF2B2840),
          'radiusMd': 6.0,
          'radiusLg': 10.0,
          'strokeFocus': 1.0,
          'space7': 40.0,
          'displaySize': 26.0,
          'bodyLineHeight': 21.0,
        },
        Brightness.light: <String, Object>{
          'primary': Color(0xFF5447B8),
          'surface': Color(0xFFFFFFFF),
          'successContainer': Color(0xFFD9EEDF),
          'warningContainer': Color(0xFFF5E8C9),
          'n3': Color(0xFFD9D6E7),
          'outlineVariant': Color(0xFFD9D6E7),
          'radiusMd': 6.0,
          'radiusLg': 10.0,
          'strokeFocus': 1.0,
          'space7': 40.0,
          'displaySize': 26.0,
          'bodyLineHeight': 21.0,
        },
      },
    };

/// 从令牌实例中按表键取实际值。
Object _actualOf(ThemeTokens tokens, String key) {
  return switch (key) {
    'primary' => tokens.color.primary,
    'surface' => tokens.color.surface,
    'successContainer' => tokens.color.successContainer,
    'warningContainer' => tokens.color.warningContainer,
    'outlineVariant' => tokens.color.outlineVariant,
    'n3' => tokens.neutral.n3,
    'radiusSm' => tokens.shape.radiusSm,
    'radiusMd' => tokens.shape.radiusMd,
    'radiusLg' => tokens.shape.radiusLg,
    'strokeFocus' => tokens.shape.strokeFocus,
    'space5' => tokens.spacing.space5,
    'space7' => tokens.spacing.space7,
    'displaySize' => tokens.typography.display.size,
    'bodyLineHeight' => tokens.typography.body.lineHeight,
    _ => throw StateError('未知对照键：$key'),
  };
}

void main() {
  group('主题令牌与冻结文档对照', () {
    test('六套实例关键值逐项一致', () {
      _expectedTable.forEach((
        AppThemePreset preset,
        Map<Brightness, Map<String, Object>> byBrightness,
      ) {
        byBrightness.forEach((Brightness brightness, Map<String, Object> row) {
          final ThemeTokens tokens = _tokensOf(preset, brightness);
          row.forEach((String key, Object expected) {
            expect(
              _actualOf(tokens, key),
              expected,
              reason: '$preset/$brightness 的 $key 与冻结文档不一致',
            );
          });
        });
      });
    });
  });

  group('AppTheme.build', () {
    testWidgets('注册 ThemeTokens 扩展且 ColorScheme 主色一致', (tester) async {
      BuildContext? captured;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(AppThemePreset.warmLife, Brightness.light),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      final ThemeData theme = Theme.of(captured!);
      final ThemeTokens tokens = ThemeTokens.of(captured!);
      expect(tokens.preset, AppThemePreset.warmLife);
      expect(theme.extension<ThemeTokens>(), same(tokens));
      expect(theme.colorScheme.primary, tokens.color.primary);
    });

    testWidgets('三方向生成对应 preset 实例', (tester) async {
      final Map<AppThemePreset, AppThemePreset> found =
          <AppThemePreset, AppThemePreset>{};
      for (final AppThemePreset preset in AppThemePreset.values) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey<AppThemePreset>(preset),
            theme: AppTheme.build(preset, Brightness.dark),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) {
                  found[preset] = ThemeTokens.of(context).preset;
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
      }
      expect(found, <AppThemePreset, AppThemePreset>{
        for (final AppThemePreset preset in AppThemePreset.values)
          preset: preset,
      });
    });
  });

  group('ThemeController', () {
    test('初始值生效，select 切换并触发持久化回调', () async {
      final List<AppThemePreset> persisted = <AppThemePreset>[];
      final ThemeController controller = ThemeController(
        AppThemePreset.warmLife,
        persist: (AppThemePreset preset) async {
          persisted.add(preset);
        },
      );
      final List<AppThemePreset> notified = <AppThemePreset>[];
      controller.addListener(() => notified.add(controller.value));

      expect(controller.value, AppThemePreset.warmLife);
      controller.select(AppThemePreset.precisionTools);

      expect(controller.value, AppThemePreset.precisionTools);
      expect(persisted, <AppThemePreset>[AppThemePreset.precisionTools]);
      expect(notified, <AppThemePreset>[AppThemePreset.precisionTools]);
    });

    test('选择相同方向不通知也不持久化', () {
      var persistCount = 0;
      var notifyCount = 0;
      final ThemeController controller = ThemeController(
        AppThemePreset.darkPro,
        persist: (AppThemePreset preset) async {
          persistCount++;
        },
      );
      controller.addListener(() => notifyCount++);

      controller.select(AppThemePreset.darkPro);

      expect(controller.value, AppThemePreset.darkPro);
      expect(persistCount, 0);
      expect(notifyCount, 0);
    });
  });
}

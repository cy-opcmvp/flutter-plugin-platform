// 覆盖场景清单（计划 F3-05 Step 2）：
// 1. lib/ 全目录（presets/ 除外）不得出现具体色值 `Color(0x` 与字号
//    `fontSize:` 字面量——样式值只允许在令牌预设文件中落地。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('组件与宿主源码无硬编码样式字面量', () {
    final Directory libDir = resolveLibDir();
    expect(
      libDir.existsSync(),
      isTrue,
      reason: '必须在 plugin_flutter 包根或 v2 workspace 根运行',
    );

    final List<String> violations = <String>[];
    for (final FileSystemEntity entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final String normalized = entity.path.replaceAll('\\', '/');
      if (normalized.contains('/theme/presets/')) {
        continue;
      }
      final String content = entity.readAsStringSync();
      if (content.contains('Color(0x')) {
        violations.add('$normalized 含具体色值字面量');
      }
      if (content.contains('fontSize:')) {
        violations.add('$normalized 含字号字面量');
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          '样式值只允许出现在 lib/src/theme/presets/：\n'
          '${violations.join('\n')}',
    );
  });
}

/// 定位 plugin_flutter 的 lib/ 目录：包根运行用 `lib`，
/// 从 v2 workspace 根逐包运行用 `packages/plugin_flutter/lib`。
Directory resolveLibDir() {
  for (final String candidate in <String>[
    'lib',
    'packages/plugin_flutter/lib',
  ]) {
    final Directory dir = Directory(candidate);
    if (dir.existsSync()) {
      return dir;
    }
  }
  return Directory('lib');
}

/// 令牌字体规格到 [TextStyle] 的唯一转换工厂。
///
/// 样式字面量（字号等）按任务纪律只允许出现在 presets/ 目录（由
/// no_hardcoded_style_test 静态扫描固化），故本转换点置于本目录：
/// 字号 100% 来自 [TokenTypeSpec.size]，行高以倍数（lineHeight / size）
/// 表达，不发明任何新值。
library;

import 'package:flutter/material.dart';

import '../tokens.dart';

/// 按 [spec] 构建字体样式；[familyChain] 首项为主字族、余项为回退链。
TextStyle buildTokenTextStyle(
  TokenTypeSpec spec, {
  required List<String> familyChain,
  Color? color,
}) {
  return TextStyle(
    fontSize: spec.size,
    height: spec.lineHeight / spec.size,
    fontWeight: spec.weight,
    fontFamily: familyChain.first,
    fontFamilyFallback: familyChain.sublist(1),
    color: color,
  );
}

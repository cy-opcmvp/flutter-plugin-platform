import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

/// BuildContext 扩展，提供便捷的本地化访问
extension LocalizationsX on BuildContext {
  /// 获取 AppLocalizations 实例
  /// 使用方式: context.l10n.appTitle
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

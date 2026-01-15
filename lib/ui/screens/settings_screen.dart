/// Settings Screen
///
/// Provides application settings including language selection.
library;

import 'package:flutter/material.dart';
import 'package:plugin_platform/l10n/generated/app_localizations.dart';
import 'package:plugin_platform/main.dart' show PluginPlatformApp;
import 'package:plugin_platform/core/services/locale_provider.dart';

/// Settings Screen
///
/// Allows users to configure application settings such as language.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = PluginPlatformApp.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings_title),
      ),
      body: ListView(
        children: [
          // Language Settings Section
          _buildSection(
            context,
            title: l10n.settings_language,
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.settings_currentLanguage),
                subtitle: Text(
                  localeProvider.getLocaleDisplayName(localeProvider.locale),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context, localeProvider),
              ),
            ],
          ),
          // Theme Settings Section (placeholder for future implementation)
          _buildSection(
            context,
            title: l10n.settings_theme,
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: Text(l10n.settings_theme),
                subtitle: Text(
                  localeProvider.isChinese ? '跟随系统' : 'Follow System',
                ),
                enabled: false, // Disable for now, will be implemented later
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a settings section with title and children
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Show language selection dialog
  void _showLanguageDialog(BuildContext context, LocaleProvider localeProvider) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_changeLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption(
              context,
              localeProvider,
              locale: const Locale('zh', 'CN'),
              name: l10n.settings_languageChinese,
            ),
            const Divider(),
            _buildLanguageOption(
              context,
              localeProvider,
              locale: const Locale('en', 'US'),
              name: l10n.settings_languageEnglish,
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single language option
  Widget _buildLanguageOption(
    BuildContext context,
    LocaleProvider localeProvider, {
    required Locale locale,
    required String name,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isSelected = localeProvider.locale == locale;

    return ListTile(
      title: Text(name),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () async {
        // Close the dialog
        Navigator.of(context).pop();

        // Change the language
        await localeProvider.setLocale(locale);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settings_languageChanged(name)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }
}

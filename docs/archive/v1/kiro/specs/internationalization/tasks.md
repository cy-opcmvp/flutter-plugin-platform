# Implementation Plan

- [x] 1. Set up internationalization infrastructure




  - [x] 1.1 Update pubspec.yaml with localization dependencies

    - Add flutter_localizations SDK dependency
    - Add intl package dependency


    - Enable generate: true in flutter section
    - _Requirements: 1.3_


  - [x] 1.2 Create l10n.yaml configuration file

    - Configure arb-dir, template-arb-file, output settings
    - Set zh_CN as template language

    - _Requirements: 1.2_

  - [x] 1.3 Create Chinese ARB file (app_zh.arb)

    - Create lib/l10n directory
    - Add all translation keys with Chinese text
    - Follow naming conventions (common_, error_, hint_, button_, dialog_, plugin_, pet_, settings_)


    - _Requirements: 9.1-9.8_
  - [ ] 1.4 Create English ARB file (app_en.arb)


    - Add all translation keys with English text
    - Ensure all keys match app_zh.arb
    - _Requirements: 9.1-9.8_
  - [ ]* 1.5 Write property test for ARB key naming convention
    - **Property 5: ARB Key Naming Convention**
    - **Validates: Requirements 9.1-9.8**

- [x] 2. Implement LocaleProvider for language management

  - [x] 2.1 Create LocaleProvider class

    - Implement ChangeNotifier for state management
    - Add locale getter and setLocale method
    - Define supportedLocales list
    - _Requirements: 2.1, 2.2_

  - [x] 2.2 Implement locale persistence

    - Save locale preference to SharedPreferences
    - Load saved locale on app startup
    - _Requirements: 2.2_
  - [ ]* 2.3 Write property test for locale persistence round trip
    - **Property 6: Locale Persistence Round Trip**
    - **Validates: Requirements 2.2**
  - [ ]* 2.4 Write unit tests for LocaleProvider
    - Test setLocale updates locale correctly
    - Test loadSavedLocale retrieves saved value
    - Test default locale is zh_CN
    - _Requirements: 2.1, 2.2_

- [x] 3. Configure MaterialApp with localization



  - [x] 3.1 Update main.dart with localization delegates

    - Add localizationsDelegates configuration
    - Add supportedLocales configuration
    - Wrap app with ChangeNotifierProvider for LocaleProvider
    - _Requirements: 1.4_
  - [x] 3.2 Create BuildContext extension for easy access


    - Add l10n extension getter for AppLocalizations
    - _Requirements: 2.3_
  - [ ]* 3.3 Write property test for default locale
    - **Property 2: Default Locale is Chinese**
    - **Validates: Requirements 2.1**

- [x] 4. Checkpoint - Ensure infrastructure tests pass


  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Localize main_platform_screen.dart



  - [x] 5.1 Replace hardcoded strings in app bar and navigation

    - Localize app title, tab labels, tooltips
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 5.2 Replace hardcoded strings in SnackBar messages

    - Localize mode switch messages
    - Localize plugin operation messages (launch, switch, close, pause)
    - Localize error messages

    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  - [x] 5.3 Replace hardcoded strings in dialogs

    - Localize Desktop Pet dialog content

    - Localize confirmation dialogs
    - _Requirements: 4.1, 4.2, 4.3_
  - [x] 5.4 Replace hardcoded strings in plugin grid

    - Localize empty state messages
    - Localize plugin status and type labels
    - Localize button labels
    - _Requirements: 5.4, 7.1, 7.2, 7.3_

- [x] 6. Localize desktop_pet_screen.dart


  - [x] 6.1 Replace hardcoded strings in unsupported platform UI

    - Localize title, description, limitation messages
    - Localize button labels
    - _Requirements: 8.3_

  - [ ] 6.2 Replace hardcoded strings in context menu
    - Localize menu options
    - Localize quick action labels

    - _Requirements: 8.1_
  - [ ] 6.3 Replace hardcoded strings in SnackBar messages
    - Localize error messages

    - Localize status messages
    - _Requirements: 3.1, 3.2, 8.2_
  - [ ] 6.4 Replace hardcoded strings in platform info dialog
    - Localize capability labels
    - Localize dialog title and content
    - _Requirements: 4.1, 8.4_

- [x] 7. Localize plugin_management_screen.dart


  - [x] 7.1 Replace hardcoded strings in app bar and search

    - Localize title, search hint, filter labels
    - _Requirements: 5.1, 5.2, 5.3, 6.1_

  - [ ] 7.2 Replace hardcoded strings in SnackBar messages
    - Localize enable/disable messages
    - Localize install/uninstall messages
    - Localize error messages

    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 7.3 Replace hardcoded strings in dialogs

    - Localize uninstall confirmation dialog
    - _Requirements: 4.1, 4.3_
  - [ ] 7.4 Replace hardcoded strings in empty states
    - Localize no plugins message
    - Localize no search results message
    - _Requirements: 5.4_

- [x] 8. Localize external_plugin_management_screen.dart


  - [x] 8.1 Replace hardcoded strings in app bar and filters

    - Localize title, search hint, filter labels
    - _Requirements: 5.1, 5.2, 5.3, 6.1_

  - [ ] 8.2 Replace hardcoded strings in SnackBar messages
    - Localize update, rollback, enable, disable, remove messages
    - Localize batch operation messages
    - Localize error messages

    - _Requirements: 3.1, 3.2, 3.3_
  - [ ] 8.3 Replace hardcoded strings in dialogs
    - Localize confirmation dialogs (update, rollback, remove)

    - Localize progress dialogs
    - _Requirements: 4.1, 4.2, 4.3_
  - [ ] 8.4 Replace hardcoded strings in plugin cards
    - Localize status labels, action buttons
    - Localize empty state messages
    - _Requirements: 5.4, 7.1, 7.3_

- [x] 9. Localize widget components



  - [x] 9.1 Localize plugin_card.dart

    - Localize status labels, button text

    - _Requirements: 7.1, 7.3_
  - [x] 9.2 Localize plugin_details_dialog.dart

    - Localize field labels, button text
    - _Requirements: 4.4, 7.1, 7.2_
  - [x] 9.3 Localize desktop_pet_widget.dart

    - Localize any user-facing text
    - _Requirements: 8.1, 8.2_

- [x] 10. Checkpoint - Ensure all localization is complete


  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Final verification and cleanup



  - [x] 11.1 Run flutter gen-l10n to generate localization files

    - Verify AppLocalizations is generated correctly
    - _Requirements: 1.1_

  - [x] 11.2 Verify all hardcoded strings are replaced

    - Search for remaining hardcoded strings in UI files
    - _Requirements: 2.3_
  - [ ]* 11.3 Write widget tests for localization
    - Test MaterialApp has correct localization configuration
    - Test language switch updates UI text
    - _Requirements: 1.4, 2.2_

- [x] 12. Final Checkpoint - Ensure all tests pass



  - Ensure all tests pass, ask the user if questions arise.

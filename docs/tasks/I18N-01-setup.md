# I18N-01: i18n base setup and language picker

- **ID:** `I18N-01`
- **Title:** gen-l10n setup, persisted language choice, language picker in the menu
- **Status:** DONE
- **Depends on:** none
- **Touched paths:**
  - `klunki/pubspec.yaml`, `klunki/pubspec.lock`, `klunki/l10n.yaml`
  - `klunki/lib/l10n/**` (ARB files, generated `app_localizations*.dart`, `locale_controller.dart`)
  - `klunki/lib/app/klunki_app.dart`, `klunki/lib/main.dart`
  - `klunki/lib/ui/language_picker.dart`, `klunki/lib/ui/menu_screen.dart` (one import + AppBar `actions`)
  - `klunki/test/l10n/**`

## Goal
The app is set up for Flutter gen-l10n, the user can pick a language from the
menu, and the choice survives restarts.

## Acceptance criteria
- [x] `flutter_localizations`, `intl` (version pinned by Flutter), `shared_preferences` (approved by the user); `generate: true`.
- [x] `l10n.yaml`: arb-dir `lib/l10n`, template `app_de.arb`, class `AppLocalizations`, `nullable-getter: false`. Generated files live in `lib/l10n/` and are committed.
- [x] Locales: de (template), en, fr, es, zh (offered as `zh-Hans`, strings in `app_zh.arb`), ar, fa. Only four keys so far: `appTitle`, `menuLanguage`, `languagePickerTitle`, `languageSystem`. de/en are real; fr/es/zh/ar/fa are a first machine translation.
- [x] `LocaleController` (`ValueNotifier<Locale?>`, null = system), stored as a BCP-47 tag under the prefs key `locale`. It's loaded in `main()` before `runApp` and injected into `KlunkiApp(localeController: ...)`. `LocaleScope` makes it reachable below the app.
- [x] `MaterialApp` gets its delegates, supported locales and locale from the controller. RTL for ar/fa comes from the framework's `Directionality`.
- [x] Language picker (`SimpleDialog`) lists System plus the 7 endonyms (not translated), with the current choice checked. It opens from the language icon in the menu AppBar.
- [x] Tests in `klunki/test/l10n/`: persistence round trip, picker switches and persists the locale, localized texts change, ar/fa give RTL.

## Notes
- The app title is the brand "Klunki" in every language, so the picker test checks the localized texts that do change (tooltip, picker title) and checks that the title stays "Klunki".
- `KlunkiApp()` without a controller still works and follows the system language, so existing tests are unchanged.
- Not in scope: extracting the existing UI strings (I18N-02), keeping the boards LTR under RTL (I18N-04).

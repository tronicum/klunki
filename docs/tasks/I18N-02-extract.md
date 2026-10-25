# I18N-02: extract the UI strings into ARB files

- **ID:** `I18N-02`
- **Title:** Extract all user-visible app UI strings into gen-l10n ARB files (de source, en translated)
- **Status:** DONE
- **Depends on:** I18N-01
- **Touched paths:**
  - `klunki/lib/l10n/*.arb`, generated `klunki/lib/l10n/app_localizations*.dart`
  - `klunki/lib/ui/**` except `klunki/lib/ui/pairing/**` (new: `klunki/lib/ui/game_titles.dart`)
  - `klunki/test/l10n/**` (new: `l10n_test_utils.dart`, `english_ui_test.dart`, `strings_test.dart`)
  - existing widget tests in `klunki/test/ui/**`, `klunki/test/e2e/muehle_screens_e2e_test.dart`, `klunki/test/widget_test.dart` (locale pinned to `de`)

## Goal
Every user-visible string of the app UI comes from `AppLocalizations`. German stays
the source text, unchanged. English is a real translation. The other locales fall back
to English until I18N-03.

## Acceptance criteria
- [x] `app_de.arb` (template) holds 126 keys: the 4 from I18N-01 plus 122 new ones. Every key has an `@key` description, and placeholders are declared with types. Keys are camelCase and grouped by prefix: `menu*`, `shell*`, `connect4*`, `muehle*`, `quartett*` (shared), `quartettTrumpf*`, `quartettSets*`, `schiffe*`, `debug*`.
- [x] ICU placeholders are used for player marks and coordinates ("{player} ist am Zug", "Spalte {column}"). Plurals cover card counts (`quartettCards`, `quartettPlayerCards`, `quartettTrumpfPot`, `quartettSetsStock`, `quartettSetsYourCards`, `quartettTrumpfPotAgain`) and random placement (`schiffeMoveAutoplace`).
- [x] `app_en.arb` has real English for every key. Game titles: Four in a Row, Mill, Quartett (Trumps), Quartett (Sets), Sink the Fleet. de: 4 Gewinnt, Mühle, Quartett (Trumpf), Quartett (Sets), Schiffe versenken. The mapping is in `lib/ui/game_titles.dart` (`localizedGameTitle`), used by the menu and the GameScreen app bar.
- [x] fr/es/zh/ar/fa contain the English text for all new keys. Each file has an `"@@x-untranslated"` note listing those keys for I18N-03. `flutter gen-l10n` runs clean, with no missing-key warnings.
- [x] Move describers take the strings as a parameter: `MoveDescriber = String Function(AppLocalizations l10n, AcceptedMove move)`. This applies to `describeMuehleMove(l10n, log, m)`, `describeSchiffeMove(l10n, m)`, `QuartettTrumpfScreen.describeMove(l10n, m)` and `QuartettSetsScreen.describeMove(l10n, m)`. `GameScreen` passes its context's `AppLocalizations`. `muehlePhaseName(l10n, phase)` also takes `l10n`.
- [x] `formatQuartettValue(stat, value, {locale})` formats decimals with `intl` for the current language (de: `2,7`, en: `2.7`).
- [x] Tests: the existing widget tests run in `de` through `test/l10n/l10n_test_utils.dart` (`localizedApp(home)`, `klunkiApp()`, `deL10n` / `enL10n`). New tests cover the menu, the Four in a Row screen (status, hint, tooltips, history) and the Schiffe setup in `en`, plus describers in both languages. An ARB consistency test checks that every locale has every template key with the same placeholders and that every template key has a description. A literal guard fails on word-bearing string literals in `Text(` / `tooltip:` / `label:` / `message:` / `semanticLabel:` / `title:` / `content:` under `lib/ui` (excluding `pairing/`).
- [x] `flutter gen-l10n`, `flutter analyze` and `flutter test` (164 tests) are green.

## Left hard-coded, and why
- **Engine strings (I18N-05):** result reasons in the result dialog (`GameResult.reason`); Quartett set names (`QuartettGame.setNames`), card names, stat labels and units (`QuartettStat.label` / `.unit`, e.g. "Höchstgeschwindigkeit", "PS"); ship names (`SchiffeGame.shipName`, e.g. "U-Boot"). Engine game titles (`GameSpec.title`) are only a fallback for unknown ids.
- **Debug console output:** the console log (`DebugConsole.screen` / `handle()`, the line 'Type "help" for commands.') is the English text CLI shared with the terminal. Only the screen chrome (title, menu, tooltips) is localized. The debug menu entries show raw engine ids ("Neu: connect4"), and the undo tooltip stays the command name `undo`.
- **Symbols, not words:** the player marks X / O (`playerMark`), Schiffe coordinates (A–J, 1–10, "E5"), Quartett card ids ("B3"), the history numbering "1.", the "–" placeholder for a missing stat value, and the brand "Klunki" (`appTitle`, already a key). `quartettCardBack` ("QUARTETT") is a key, but its text is the same in de and en.
- **`lib/ui/pairing/**`:** built in parallel (KLD-034) and extracted later.
- **Fallbacks:** `GameScreen._describe` falls back to the move map's `toString()` when a screen passes no describer (debug only).

## Notes
- `tester.pageBack()` looks for the English "Back" tooltip, so it fails under `de`. `game_screen_test` taps `find.byType(BackButton)` instead.
- The Flutter test binding's default locale is en-US. Any new widget test that expects German text must use `localizedApp` / `klunkiApp()` from `test/l10n/l10n_test_utils.dart`.
- Not in scope: real fr/es/zh/ar/fa translations (I18N-03), keeping the boards LTR under RTL (I18N-04), engine strings (I18N-05).

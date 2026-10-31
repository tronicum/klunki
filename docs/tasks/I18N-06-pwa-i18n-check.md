# I18N-06: PWA language check (translations, glyphs, layout)

- **ID:** `I18N-06`
- **Title:** Test what each locale really shows: untranslated text, raw keys, overflow, tofu offline
- **Status:** DONE
- **Depends on:** I18N-03 (translations), I18N-04b (bundled Noto Sans Arabic)
- **Touched paths:**
  - `klunki/test/l10n/coverage_test.dart` (new)
  - `klunki/test/l10n/glyph_coverage_test.dart` (new)
  - `klunki/test/l10n/locale_controller_test.dart` (`?lang=` tests)
  - `klunki/lib/l10n/locale_controller.dart` (`?lang=xx` web override, not persisted)
  - `klunki/lib/ui/pairing/pairing_screen.dart` (overflow fix: "waiting for guest" row)
  - `klunki/tool/pwa_i18n_check.sh`, `klunki/tool/pwa_i18n_check.mjs` (new)
  - `docs/DEMO.md` (section 5: language check)

## Goal
The user reported "missing words or not rendered right in the PWA". This card measures it in a real browser
and guards it with tests.

## Findings (build 3982f2ea18d0a363 = main 5bfdc35, Firefox Nightly headless, 390×844)
- **Online:** all 7 locales fully translated and rendered (menu, picker, Four in a Row). No tofu, no overflow.
- **Installed, then offline** (`offline-warm`): Latin and Arabic fine (Roboto cached by the SW, Arabic bundled).
  **Chinese is tofu everywhere** (zh UI, and the picker's 简体中文 endonym in every locale): Noto Sans SC slices
  are fetched per character from fonts.gstatic.com and were never cached.
- **No internet from the first visit** (`offline`): **all Latin text is invisible or tofu** (Roboto is not
  bundled), Chinese invisible; ar/fa Arabic renders (bundled) but Latin inside it (the player "X") is tofu.
- Flutter tests: "Waiting for the other player…" row in the pairing host view overflowed by 43–85 px in
  de/en/fr/es at 390 and 360 px: fixed with `Flexible`.
- Before I18N-03, fr/es/zh/ar/fa showed English placeholder text (listed in `@@x-untranslated`).

## What the tests do
- `coverage_test.dart`: per locale × {390×844, 360×640}: menu, picker, all five games played to the end (handover,
  restart dialog, history sheet, result dialog), pairing host + join. Fails on visible text/tooltip matching an
  English ARB message (and not the locale's own), raw keys / `{placeholders}`, and any layout exception.
  Locales with a non-empty `@@x-untranslated` only print the English hits (TODO(I18N-03)); strict now.
- `glyph_coverage_test.dart`: parses the cmap of `assets/fonts/**` and checks every ARB character; Arabic must be
  covered (strict), Han is skipped with TODO(I18N-07); prints per locale/script what depends on online fallback.
- `pwa_i18n_check.sh URL OUT [online|offline-warm|offline]`: Firefox over WebDriver BiDi (no driver, no npm),
  logging proxy for external hosts, screenshots per locale, PASS/FAIL. See `docs/DEMO.md` §5.
  Chrome is not supported (not installed here; CDP would need a second driver).

## Left over
- I18N-07: bundle a CJK subset (or mirror Noto Sans SC slices) for offline Chinese. **DONE**
- I18N-08: Roboto is not bundled: a PWA that never was online shows no Latin text. **DONE**, both in
  `I18N-07-08-offline-fonts.md` (PASS 7/7 in all three modes, no fonts.gstatic.com request).

# I18N-07 + I18N-08: every locale renders offline in the PWA (Chinese subset, bundled Roboto)

- **ID:** `I18N-07` (Chinese), `I18N-08` (Latin / Roboto)
- **Title:** Bundle Roboto, a Noto Sans SC subset and a symbol subset so the PWA needs no fonts.gstatic.com
- **Status:** DONE (both)
- **Depends on:** I18N-04b (bundled Noto Sans Arabic), I18N-06 (PWA language check)
- **Touched paths:**
  - `klunki/assets/fonts/Roboto/` (new: Regular, Medium, Bold TTF + `OFL.txt`)
  - `klunki/assets/fonts/NotoSansSC/` (new: subset Regular + Bold TTF, `OFL.txt`, `SOURCE.txt`)
  - `klunki/assets/fonts/NotoSansMath/` (new: subset Regular TTF, `OFL.txt`, `SOURCE.txt`)
  - `klunki/pubspec.yaml`, `klunki/lib/app/fonts.dart`, `klunki/lib/app/theme.dart`,
    `klunki/lib/app/klunki_app.dart`, `klunki/lib/ui/language_picker.dart`
  - `klunki/tool/update_web_fonts.py` (`subset`, `fetch-roboto`)
  - `klunki/test/l10n/glyph_coverage_test.dart` (strict), `klunki/test/l10n/fonts_test.dart`
  - `docs/DEMO.md` (troubleshooting line)

## Goal
I18N-06 measured: Chinese was tofu offline, and on a first visit without internet all Latin text was
invisible (CanvasKit downloads Roboto from fonts.gstatic.com at startup). The user approved downloading
Roboto and Noto Sans SC. Goal: PASS 7/7 in all three check modes with no request to fonts.gstatic.com.

## What was done
- **Roboto (I18N-08):** `web/static/Roboto-{Regular,Medium,Bold}.ttf` from the official
  googlefonts/roboto-3-classic release `v3.016` (the web-optimized statics: Latin, Latin-ext, Greek,
  Cyrillic, 927 code points, ~157 KB each instead of ~397 KB for the full unhinted static), `OFL.txt`
  from the same tag. Medium is needed: the Material 3 type scale uses w500 (titles, labels).
  Declared in `pubspec.yaml` as family **`Roboto`**. That is the supported switch in
  `canvaskit/fonts.dart` (`loadAssetFonts`): when the font manifest has a family named "Roboto", the
  engine skips its own `${fontFallbackBaseUrl}roboto/v32/….woff2` download. Verified: no Roboto request
  anymore in any mode. `withAppFonts` sets `fontFamily: 'Roboto'` on the text themes **on the web only**
  (`kIsWeb`); Android/iOS keep their platform font as the primary family.
- **Symbols:** Roboto has `–`, `…`, `›`, but no `→` (U+2192). A Noto Sans Math subset with exactly the
  characters that neither Roboto nor Noto Sans Arabic has (today only `→`, 5.9 KB) covers it. Before,
  the engine fetched Noto Sans Symbols 2 for it.
- **Chinese (I18N-07):** a Noto Sans SC subset, Regular + Bold (w500 resolves to Regular, as for
  Arabic): every Han / CJK character of all ARB files and of the picker endonyms ("简体中文"), every
  character of the zh strings (incl. `，：！（）、。`), and printable ASCII: 386 code points,
  **93,336 B + 93,472 B = 186,808 B** (target < 1 MB).
  - **How it is subset:** `fontTools`/`pyftsubset` is not installed here (nor harfbuzz), so the tool uses
    the no-install alternative: the Google Fonts CSS API with `text=` (served as TrueType with an old
    user agent). Google subsets the google/fonts Noto Sans SC (OFL) server-side; the tool checks every
    requested code point in the returned cmap. The full ~10 MB source font is never downloaded, so it
    cannot end up in the repo. `SOURCE.txt` records family, Google Fonts version (`v41`) and the
    character list; `OFL.txt` is google/fonts' `ofl/notosanssc/OFL.txt`.
  - **More than 800 characters (2026-11-11):** the CSS API subsets at most 800 characters per request;
    with more it silently serves the full ~10 MB font. The tool splits the sorted characters into parts
    of ≤ 800 and makes one font family per part (`NotoSansSC`, `NotoSansSC2`, …; no merging, which would
    need fontTools). It writes the families into `pubspec.yaml` (between `# BEGIN/END NotoSansSC`) and
    `chineseFontFamilies` / `symbolFontFamilies` in `lib/app/fonts.dart` (the web fallback chain), and
    refuses any downloaded file over 1 MB. `test/l10n/fonts_test.dart` checks that files, pubspec and
    fallback list agree.
- **Fallback, every locale:** `appFontFallback = [NotoSansArabic, NotoSansMath, NotoSansSC]` on
  `textTheme` and `primaryTextTheme` (in `KlunkiTheme.light/dark` via `withAppFonts`; the per-locale
  `MaterialApp.builder` from I18N-04b is gone). One chain for all locales is simpler and also renders
  Arabic or Chinese player names in any UI language. Symbols come before the CJK subset so `→` never
  takes CJK metrics. The picker endonyms carry the same fallback explicitly. The engine asks its
  download service only for code points none of these fonts has.
- **Licenses:** `registerFontLicenses()` registers the four `OFL.txt` files (Roboto, Noto Sans Arabic,
  Noto Sans SC, Noto Sans Math).
- **Tool:** `python3 -I tool/update_web_fonts.py subset` rebuilds both subsets from the ARB files (rerun
  when strings change); `fetch-roboto --version v3.016` refetches Roboto; `list` shows all bundled
  files and marks the engine's Roboto download as skipped.
- **Precache:** no change to `web/pwa_finalize.py` needed; all new font files and their `OFL.txt` are in
  the precache list (30 files instead of 21). `SOURCE.txt` is not a Flutter asset (not in the build).

## Tests
- `glyph_coverage_test.dart` is strict now: per locale every visible character (incl. U+00A0/U+202F,
  which the engine also requests) is in a bundled font; Latin characters (all of de/en/fr/es, the Latin
  in zh/ar/fa) are in Roboto itself; picker endonyms covered; and a dedicated test fails when an ARB
  string introduces a CJK character missing from the Noto Sans SC subset, with the message to rerun
  `python3 -I tool/update_web_fonts.py subset`. Missing characters of other scripts point there too.
- `fonts_test.dart`: fallback chain in all 7 locales, Roboto primary on the web only, picker endonyms,
  all 8 TTFs bundled, four OFL licenses registered once.
- `flutter analyze` clean, `flutter test` green (301 tests). One run had a timing flake in
  `test/e2e/muehle_screens_e2e_test.dart`; it passes alone and in the rerun of the full suite.

## Measured
`flutter build web --release` + `python3 build/web/pwa_finalize.py`, before = main af33863:
- Precache: **21 files, 3,037,131 B → 30 files, 3,718,020 B (+680,889 B ≈ +665 KB)**.
  Roboto 472,572 B, Noto Sans SC 186,808 B, Noto Sans Math 5,888 B, three new OFL.txt 13,162 B,
  manifests +2,365 B, main.dart.js +94 B. CanvasKit is not precached, as before.
- Before, the app also downloaded Roboto (woff2) from gstatic at every first start, and Noto Sans
  SC/TC/HK slices + Noto Sans Symbols 2 for zh (25 external requests in the offline zh run).

## Real-browser check (Firefox Nightly headless, `tool/pwa_i18n_check.sh`, 127.0.0.1:8791)
| Mode | Result | External requests |
|---|---|---|
| online | PASS 7/7 | none |
| offline-warm | PASS 7/7 | none |
| offline (no internet from the first visit) | PASS 7/7 | none |

Negative control: the before build in `offline` mode fails zh with 25 gstatic requests (Roboto,
Noto Sans SC/TC/HK slices, Noto Sans Symbols 2). Screenshots looked at: zh menu + picker, de menu,
fa game (offline): all text rendered, no tofu.

## Notes
- The bundled Roboto is the web static (Latin, Latin-ext, Greek, Cyrillic), the CJK font only a subset:
  a player name with other characters (other scripts, emoji, rare hanzi) still uses the online fallback.
- On Android the asset family "Roboto" shadows the system Roboto for app text (same design, the
  missing glyphs fall back to the system).
- A Flutter upgrade can change the engine's Roboto handling: run `tool/update_web_fonts.py list` and
  the PWA check (`docs/DEMO.md` §5).

# I18N-04: right-to-left polish for Arabic and Farsi

- **ID:** `I18N-04`
- **Title:** RTL layout for ar/fa (boards stay LTR, addresses stay LTR) + font plan for offline web
- **Status:** RTL DONE, Arabic fonts DONE (I18N-04b), Chinese + Latin fonts DONE (I18N-07/08, see `I18N-07-08-offline-fonts.md`)
- **Depends on:** I18N-01, I18N-02, KLD-034
- **Touched paths:**
  - `klunki/lib/ui/ltr.dart` (new: `LtrBoard`, `LtrText`, `ltrIsolate`, `bidiLtr`)
  - `klunki/lib/ui/games/connect4/connect4_board.dart`, `klunki/lib/ui/games/muehle/muehle_board.dart`,
    `klunki/lib/ui/games/schiffe/schiffe_grid.dart`, `klunki/lib/ui/games/schiffe/schiffe_board.dart`,
    `klunki/lib/ui/games/quartett_card.dart`
  - `klunki/lib/ui/pairing/pairing_screen.dart`, `klunki/lib/ui/pairing/network_game_session.dart`
  - `klunki/lib/ui/shell/game_screen.dart`
  - `klunki/test/l10n/rtl_test.dart` (new)
  - I18N-04b: `klunki/assets/fonts/NotoSansArabic/` (new: Regular + Bold TTF, `OFL.txt`),
    `klunki/pubspec.yaml`, `klunki/lib/app/fonts.dart` (new), `klunki/lib/app/klunki_app.dart`,
    `klunki/lib/ui/language_picker.dart`, `klunki/lib/main.dart`, `klunki/test/l10n/fonts_test.dart` (new),
    `klunki/tool/update_web_fonts.py` (new, manual)

## Goal
Under `Locale('ar')` and `Locale('fa')` the app chrome mirrors (Flutter's `Directionality`),
while game boards, grid coordinates, IP addresses and ports stay left-to-right. Taps map to
the same engine indices as in LTR locales.

## Acceptance criteria
- [x] Audit: menu, pairing (host + join), all five game screens, handover cover, result dialog,
      history sheet pumped under ar and fa; played to the end without exceptions (`rtl_test.dart`).
- [x] Directional code: `EdgeInsets.only(right:)` → `EdgeInsetsDirectional.only(end:)`
      (net banner spinner, Schiffe fleet chips); Quartett stat-row colour bar
      `Border(left:)` → `BorderDirectional(start:)`. `Icons.chevron_right` / `Icons.arrow_right`
      already have `matchTextDirection: true` (they flip by themselves); `arrow_upward/downward`
      (higher/lower wins) are not directional. `EdgeInsets.fromLTRB` uses are symmetric, the
      `Alignment.topLeft` gradient on the card back is decorative: left as is.
- [x] Boards LTR via `LtrBoard` (= `Directionality(ltr)`):
  - Four in a Row: the whole board (Row of columns 0–6 + `Positioned(left:)` drop animation).
    Without it, column 0 was on the right but the falling piece animated on the left.
  - Mühle: board painter + point `Stack` (absolute `Positioned(left:)` coordinates were
    already direction-independent; wrapped for robustness). Player panels mirror.
  - Schiffe: `SchiffeGrid` (both grids, labels A–J / 1–10, sunk-ship outlines, and the
    setup drag mapping `_cellAt(dx, dy)` which uses raw x). Without it the cells mirrored
    but outlines and drag previews did not.
  - Quartett stat table: no LTR needed (label/value rows mirror naturally, no coordinates).
  - Status line and hints around the boards stay RTL.
- [x] Numbers: **Western digits (0–9) everywhere** in ar/fa. Reasons: board coordinates (A1–J10,
      columns 1–7) and IP/ports must be Western anyway; gen-l10n int placeholders are plain
      `toString()` (already Western); mixed digit systems on one screen look broken.
      `formatQuartettValue` fell back to Persian digits in fa (`۲٫۷` while ints showed `650`);
      it now uses English formatting when the locale's zero digit is not `0`.
- [x] IP:port: host addresses use `LtrText` (LTR, aligned to the ambient start edge);
      discovered `host:port` inside the subtitle and `pairingConnecting({host})` are wrapped
      in Unicode isolates U+2066…U+2069 (`bidiLtr`, only under RTL so LTR strings are
      unchanged); the manual address field is `textDirection: ltr`. History numbers `12.`
      are LTR (would render `.12` in RTL).
- [x] Tests: `klunki/test/l10n/rtl_test.dart` (17 tests): menu RTL + chevron on the left;
      5 games × ar/fa played to the result dialog + history sheet, status/dialog/sheet RTL;
      Four in a Row ar: column 0 is leftmost and tapping the left edge drops into engine column 0;
      Mühle fa: point 0 left of point 2; Schiffe fa: target grid not mirrored, row labels left,
      coordinate tap at C7 fires row 2/col 6; Quartett digits; pairing host ar: IP text LTR;
      pairing join fa: host:port isolated, manual field LTR. Disabling `LtrBoard` makes the
      three board tests fail.
- [x] No new ARB keys, nothing in `packages/**`.

## Fonts: Arabic DONE (I18N-04b)

The user approved downloading Noto Sans Arabic (Arabic only; Chinese is still PROPOSED below).

**Approach taken: option 2 (asset font + `fontFamilyFallback`), not option 1.** Redirecting
`fontFallbackBaseUrl` turned out impractical with Flutter 3.47.8:
- The same base URL is used for **Roboto**, which CanvasKit downloads at every startup
  (`canvaskit/fonts.dart`: `${fontFallbackBaseUrl}roboto/v32/KFOm….woff2`). With `fonts/`,
  Roboto would also have to be mirrored, which is an extra download that was not approved.
- **Every other fallback font** would then be fetched from `fonts/` and 404: the Noto Sans SC slices
  for "简体中文" in the language picker (shown in every locale), Noto Sans Symbols, emoji in
  player/device names. They are marked "permanently unavailable" and render as tofu even
  online. That is a regression for zh, and for everyone on the picker.

What was done:
- `klunki/assets/fonts/NotoSansArabic/NotoSansArabic-{Regular,Bold}.ttf`: the unhinted static TTFs
  from the official notofonts release `NotoSansArabic-v2.013`
  (github.com/notofonts/arabic/releases), with `OFL.txt` from the same zip. Declared in
  `pubspec.yaml` as family `NotoSansArabic` (Bold = weight 700; w500 resolves to Regular,
  w600+ to Bold).
- `lib/app/fonts.dart`: `themeForLocale` adds `fontFamilyFallback: ['NotoSansArabic']` to
  `textTheme`/`primaryTextTheme` for ar and fa only (`MaterialApp.builder` in `klunki_app.dart`
  uses the resolved locale, so "System" = ar also works). The language picker's endonyms carry
  the same fallback in every locale ("العربية", "فارسی"). The engine only asks the fallback
  service for code points that the style's families cannot resolve, so Arabic text never
  reaches fonts.gstatic.com. The font is used on Android/iOS too (consistent look, same code path).
- License: `registerFontLicenses()` (called in `main()`) adds the OFL text from the bundled
  `OFL.txt` to `LicenseRegistry` (package name "Noto Sans Arabic").
- Precache: no change to `web/pwa_finalize.py` needed. It precaches every build file, so
  `assets/assets/fonts/NotoSansArabic/*` is in the list automatically (21 files instead of 18).
- `tool/update_web_fonts.py` (manual, never run by a build): `list` shows the bundled files
  (size, sha256, validity) and the URLs that this Flutter version's fallback would download
  (`--family "Noto Sans SC"` for the zh work); `fetch --version vX.YYY` refetches the font from
  the notofonts release into a fresh temp dir, validates it, and replaces the files.

Measured (`flutter build web --release` + `pwa_finalize.py`, compared with a build of the
previous commit): precache **2,717,437 → 3,013,420 bytes (+295,983 B ≈ +289 KB)**, of which
Regular 142,140 B, Bold 141,852 B, OFL.txt 4,382 B, manifests +943 B, main.dart.js +6,666 B.
CanvasKit is not part of the precache, as before. The asset fonts are loaded at every web startup
(all locales), from the same origin and the precache.

Verified headless (Firefox WebDriver BiDi, service worker off so every request is visible, app
served on 127.0.0.1:8765, locale stored in localStorage, language picker opened):
- Before (previous commit, ar): `fonts.gstatic.com/s/notosansarabic/v28/….woff2` is requested.
- After (ar and fa): no notosansarabic request. The Arabic text loads
  `assets/assets/fonts/NotoSansArabic/*.ttf` and renders correctly (picker title, "النظام",
  endonyms). The remaining gstatic requests are Roboto (startup, as before, cached by the
  warm-cache message) and three Noto Sans SC slices for "简体中文" (zh, still open).
Manual check: DevTools → Network "Offline" after one online visit, switch to العربية: the
picker and Arabic strings render without tofu.

## Fonts: proposal (Arabic DONE above; Chinese DONE in I18N-07 as a bundled subset, see `I18N-07-08-offline-fonts.md`)

### Problem
Mobile is fine: Android ships Noto Sans CJK and Noto Naskh/Sans Arabic as system fonts, iOS has
PingFang SC and Geeza Pro / SF Arabic, and Flutter uses the system fallback there.
The web build is the problem. CanvasKit has no system fonts. When a glyph is missing, the engine's
font fallback service downloads Noto slices from `configuration.fontFallbackBaseUrl`, which
defaults to `https://fonts.gstatic.com/s/` (see `flutter_web_sdk/lib/ui/src/engine/configuration.dart`,
`font_fallback_data.dart`). For our scripts it uses:
- **Noto Sans Arabic**: one woff2 for Arabic and Persian (`notosansarabic/v28/....woff2`).
- **Noto Sans SC**: split into 101 woff2 slices ("Noto Sans SC 0" … "100"), loaded by codepoint.

Our PWA loads CanvasKit same-origin (KLD-010). The precache does not include these slices, so
offline (or on first start without network) zh/ar/fa text shows tofu boxes. There is one partial
mitigation already: the `klunki-warm-cache` message in `index.html` posts the resources loaded so
far, so slices fetched before that message get cached. That only helps by chance.

### Options
1. **Mirror the engine's own fallback files (recommended for the web).** Set
   `fontFallbackBaseUrl: "fonts/"` in `web/flutter_bootstrap.js`. Ship the exact files under
   `web/fonts/<same relative path>` and add them to the precache in `pwa_finalize.py`. This needs
   no Dart change and no pubspec asset. The engine keeps picking the slices itself, and mobile
   app size stays the same.
   - Arabic: 1 file, est. ~0.1–0.2 MB woff2.
   - SC: only the slices our zh strings touch (by codepoint), est. 0.5–2 MB, or all 101 slices
     at est. ~8–10 MB (too big for the precache).
   - Downside: the file names are pinned to the Flutter version (`v28`, hash names), so a script
     must recompute the list after each Flutter upgrade.
2. **Bundle fonts as pubspec assets + `fontFamilyFallback`** (web only via `kIsWeb`):
   - **Noto Sans Arabic** Regular+Bold TTF (or **Noto Naskh Arabic** for a more traditional
     look; Sans matches Roboto better and is what the engine itself uses), ~0.2–0.4 MB.
   - **Noto Sans SC** Regular: the full static OTF is ~8 MB per weight (variable ~10+ MB), too big.
     A subset to GB2312 level 1 (3,500 common hanzi) is ~1.5–2 MB. A subset to just the ARB
     characters is ~50–200 KB, but it breaks for player/device names and whenever translations
     change (it needs a `pyftsubset`/fonttools build step, which is another tool to install).
   - Downside: the assets ship on Android/iOS too, where they are not needed.
3. Do nothing and document that the "offline web in zh/ar/fa" case needs one online start.

### Recommendation
Option 1, starting with Arabic only (one small file, covers ar + fa completely, est. +0.1–0.2 MB
precache). For zh, wait until I18N-03 has the real translations (today zh/ar/fa are still mostly
English placeholders: 8 distinct hanzi, ~10 Arabic letters), then mirror the slices those strings
need (measure the size; budget ≤ 1 MB). Fall back to a GB2312-L1 subset (option 2) only if user
names in Chinese must render offline.

- License: all Noto fonts are **SIL Open Font License 1.1**. Bundling, subsetting and
  redistributing are allowed; keep `OFL.txt` next to the files and list them in the app's
  licenses (`LicenseRegistry.addLicense`).
- Precache impact: today 18 files + one CanvasKit pair (3.5–7 MB wasm) + Roboto. Arabic adds
  ~2–4 % of that. SC slices for the UI add ~10–25 %. Full SC would more than double it, so no.
- Nothing has been downloaded. The sizes above are estimates and must be measured once
  downloading is approved.

## Notes
- `LtrBoard` wraps inside the board widgets, so all callers (hot-seat, network) get it.
- `bidiLtr` adds the isolate marks only under RTL, so existing de/en string expectations stay
  byte-identical.
- Material `AlertDialog` / `ListTile` / `SegmentedButton` / `AppBar` back button mirror by
  themselves; nothing to change there.

## Definition of done
`flutter analyze` clean, `flutter test` green (193 tests, 17 of them in `rtl_test.dart`).
I18N-04b: `flutter analyze` clean, `flutter test` green (210 tests, 8 of them in `fonts_test.dart`).

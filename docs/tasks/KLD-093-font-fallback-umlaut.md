# KLD-093 — iOS: bold "ä" in "Mit zwei Geräten" (font fallback)

- **ID:** `KLD-093`
- **Title:** The bundled web fallback fonts displaced the system font on iOS; apply them on the web only
- **Status:** DONE
- **Depends on:** I18N-04b, I18N-07, I18N-08 (bundled fonts)
- **Touched paths:**
  - `klunki/lib/app/fonts.dart` (`withAppFonts` web only, new `platformFontFallback`)
  - `klunki/lib/ui/language_picker.dart`
  - `klunki/test/l10n/fonts_test.dart`
  - `docs/tasks/BOARD.md`

## Report

iPhone build ce50323: in the menu section header "Mit zwei Geräten" the "ä"
looked bold next to the other letters.

## Root cause (evidence from the iOS 27 simulator)

`withAppFonts` put `fontFamilyFallback: [NotoSansArabic, NotoSansMath,
NotoSansSC]` on every text style on Android/iOS too. The Material iOS
typography names the family `CupertinoSystemText`, and with a fallback list the
text engine does not resolve that name, so the first families that do resolve
are the bundled ones (a probe screen rendered "Mit zwei Geräten 0123" w500
with different family/fallback combinations):

| glyphs | font that drew them | why |
|---|---|---|
| `0123`, `,-.:` | Noto Sans Arabic Regular | its cmap has digits and some punctuation |
| `A–Z a–z` and the rest of printable ASCII | Noto Sans SC subset, Regular (w500 → 400, only 400/700 bundled) | the subset includes printable ASCII (I18N-07) |
| `ä ö ü ß é …` | the per-character system fallback (heavier face) | in none of the bundled fonts (cmaps checked with a small pure-Python parser) |

So it was neither a decomposed "ä" (the ARB strings are NFC) nor synthetic
bold: the whole Latin text on iOS was Noto Sans SC Regular, and only the
letters outside ASCII came from the system, which looks bold next to it. It hit
every umlaut, ß and accent in all Latin locales (e.g. "Gerät weitergeben",
"Mühle", "schießt"). `fontFamily: null` and no fallback, or naming
`.AppleSystemUIFont` first, both render the whole string in SF.

Android is not affected in practice: Material's Android typography names
"Roboto", which the app bundles (Latin incl. umlauts, 400/500/700).

## Fix

The bundled fallbacks exist for the offline PWA (CanvasKit has no system
fonts). On Android/iOS the platform cascade covers Arabic, Persian, Chinese and
→, so `withAppFonts` now returns the theme unchanged there, and the language
picker uses `platformFontFallback()` (the list on the web, `null` natively).
No private font names. The web is unchanged (Roboto primary + fallbacks), so
the PWA offline guarantees stay.

Checked on the simulator after the fix: German menu in SF throughout; Arabic,
Persian and Chinese menus render with the system fonts.

## Tests

`test/l10n/fonts_test.dart`: native app in all 7 locales has no fallback list,
`withAppFonts(web: false)` leaves the iOS and Android typography untouched,
`platformFontFallback`, picker endonyms; the web test is unchanged. The new
tests fail on the old `fonts.dart` (10 failures).

## Not done

- The Noto Sans SC subset still contains printable ASCII. On the web Roboto
  comes first, so it is never reached; dropping it would need a `subset` rerun
  (network) and is harmless to leave.
- No Android emulator was available here; Android is covered by the reasoning
  above and the theme test.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled fonts (I18N-04b, I18N-07, I18N-08).
///
/// Flutter web (CanvasKit/Skwasm) has no system fonts: CanvasKit fetches
/// Roboto from fonts.gstatic.com at startup, and every glyph missing from it
/// is fetched there too (Noto slices per script). Offline, or on a first
/// visit without internet, the PWA would show no text or tofu. Klunki bundles
/// everything it shows (all SIL OFL 1.1, see `pubspec.yaml`):
///  * Roboto Regular/Medium/Bold (Latin, Greek, Cyrillic): the default family
///    on the web. Because the app declares a family named "Roboto", CanvasKit
///    skips its own Roboto download.
///  * Noto Sans Arabic (ar, fa), a Noto Sans SC subset (the zh strings and
///    "简体中文") and a Noto Sans Math subset (symbols Roboto lacks, e.g. →):
///    the [appFontFallback] of every text theme on the web, in every locale.
///    Text that resolves through it never reaches the download service.
/// The subsets are rebuilt by `tool/update_web_fonts.py subset`;
/// `test/l10n/glyph_coverage_test.dart` fails when a string needs a rerun.
///
/// On Android/iOS the fallbacks are NOT applied (KLD-093): the platform's own
/// font cascade covers Arabic, Chinese and symbols. On iOS a fallback list
/// pushes the system font out entirely: the Material iOS typography names
/// "CupertinoSystemText", which the text engine does not resolve as a family,
/// so the first family that does resolve is Noto Sans Arabic (digits,
/// punctuation), then the Noto Sans SC subset (printable ASCII): Latin text
/// rendered in Noto Sans SC Regular, and every letter neither has (ä, ö, ü,
/// ß, é, ...) came from the per-character system fallback in a heavier face,
/// so "Geräte" showed a bold "ä". Android's primary family is the bundled
/// Roboto (Material typography), which needs no fallback either.

/// Family names declared in pubspec.yaml.
const String robotoFontFamily = 'Roboto';
const String arabicFontFamily = 'NotoSansArabic';
const String chineseFontFamily = 'NotoSansSC';
const String symbolFontFamily = 'NotoSansMath';

/// The families of the subset parts: the font service subsets at most 800
/// characters per request, so a bigger subset comes as NotoSansSC,
/// NotoSansSC2, ... (the first part holds printable ASCII). Written by
/// `tool/update_web_fonts.py subset` together with pubspec.yaml.
const List<String> chineseFontFamilies = ['NotoSansSC'];
const List<String> symbolFontFamilies = ['NotoSansMath'];

/// `fontFamilyFallback` for all app text on the web: Arabic script, symbols,
/// then the Chinese subset (last, so symbols such as → never take its CJK
/// widths). Use [platformFontFallback] in widgets.
const List<String> appFontFallback = [
  arabicFontFamily,
  ...symbolFontFamilies,
  ...chineseFontFamilies,
];

/// Package name -> asset path of each bundled font's license (SIL OFL 1.1).
const Map<String, String> fontLicenseAssets = {
  'Roboto': 'assets/fonts/Roboto/OFL.txt',
  'Noto Sans Arabic': 'assets/fonts/NotoSansArabic/OFL.txt',
  'Noto Sans SC': 'assets/fonts/NotoSansSC/OFL.txt',
  'Noto Sans Math': 'assets/fonts/NotoSansMath/OFL.txt',
};

/// The `fontFamilyFallback` for app text: [appFontFallback] on the web, none
/// on Android/iOS (see the library comment: a fallback list there displaces
/// the system font).
List<String>? platformFontFallback({bool web = kIsWeb}) => web ? appFontFallback : null;

/// [theme] with the bundled fonts on the web ([web]): Roboto as the primary
/// family and [appFontFallback] on its text themes. Unchanged on Android/iOS.
ThemeData withAppFonts(ThemeData theme, {bool web = kIsWeb}) {
  if (!web) return theme;
  TextTheme apply(TextTheme t) => t.apply(
        fontFamily: robotoFontFamily,
        fontFamilyFallback: appFontFallback,
      );
  return theme.copyWith(
    textTheme: apply(theme.textTheme),
    primaryTextTheme: apply(theme.primaryTextTheme),
  );
}

bool _licensesRegistered = false;

/// Adds the bundled fonts' licenses to the app's license page. Idempotent.
void registerFontLicenses() {
  if (_licensesRegistered) return;
  _licensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    for (final e in fontLicenseAssets.entries) {
      final text = await rootBundle.loadString(e.value);
      yield LicenseEntryWithLineBreaks([e.key], text);
    }
  });
}

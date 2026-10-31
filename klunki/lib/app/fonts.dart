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
///    the [appFontFallback] of every text theme, in every locale. Text that
///    resolves through it never reaches the engine's download service.
/// The subsets are rebuilt by `tool/update_web_fonts.py subset`;
/// `test/l10n/glyph_coverage_test.dart` fails when a string needs a rerun.
/// On Android/iOS the fallbacks apply too (same look); the system font stays
/// the primary family there.

/// Family names declared in pubspec.yaml.
const String robotoFontFamily = 'Roboto';
const String arabicFontFamily = 'NotoSansArabic';
const String chineseFontFamily = 'NotoSansSC';
const String symbolFontFamily = 'NotoSansMath';

/// `fontFamilyFallback` for all app text: Arabic script, symbols, then the
/// Chinese subset (last, so symbols such as → never take its CJK widths).
const List<String> appFontFallback = [
  arabicFontFamily,
  symbolFontFamily,
  chineseFontFamily,
];

/// Package name -> asset path of each bundled font's license (SIL OFL 1.1).
const Map<String, String> fontLicenseAssets = {
  'Roboto': 'assets/fonts/Roboto/OFL.txt',
  'Noto Sans Arabic': 'assets/fonts/NotoSansArabic/OFL.txt',
  'Noto Sans SC': 'assets/fonts/NotoSansSC/OFL.txt',
  'Noto Sans Math': 'assets/fonts/NotoSansMath/OFL.txt',
};

/// [theme] with the bundled fonts: [appFontFallback] on its text themes and,
/// on the web ([web]), Roboto as the primary family.
ThemeData withAppFonts(ThemeData theme, {bool web = kIsWeb}) {
  TextTheme apply(TextTheme t) => t.apply(
        fontFamily: web ? robotoFontFamily : null,
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

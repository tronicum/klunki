import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bundled script fonts (I18N-04b).
///
/// Flutter web (CanvasKit/Skwasm) has no system fonts: glyphs missing from
/// Roboto are fetched at runtime from fonts.gstatic.com, so offline the PWA
/// would show tofu for Arabic and Farsi. Klunki bundles Noto Sans Arabic as an
/// asset font and puts it into the theme's `fontFamilyFallback` for ar/fa.
/// Text that resolves through the fallback never reaches the engine's
/// download service. On Android/iOS the same font is used for consistency.

/// Family name declared in pubspec.yaml.
const String arabicFontFamily = 'NotoSansArabic';

/// `fontFamilyFallback` for text that may contain Arabic script.
const List<String> arabicFontFallback = [arabicFontFamily];

/// Asset path of the font license (SIL OFL 1.1).
const String arabicFontLicenseAsset = 'assets/fonts/NotoSansArabic/OFL.txt';

/// Whether [locale]'s language is written in Arabic script (ar, fa).
bool usesArabicScript(Locale locale) =>
    locale.languageCode == 'ar' || locale.languageCode == 'fa';

/// [theme] with [arabicFontFallback] on its text themes when [locale] uses
/// Arabic script; otherwise [theme] unchanged.
ThemeData themeForLocale(ThemeData theme, Locale locale) {
  if (!usesArabicScript(locale)) return theme;
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: arabicFontFallback),
    primaryTextTheme:
        theme.primaryTextTheme.apply(fontFamilyFallback: arabicFontFallback),
  );
}

bool _licensesRegistered = false;

/// Adds the bundled fonts' licenses to the app's license page. Idempotent.
void registerFontLicenses() {
  if (_licensesRegistered) return;
  _licensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString(arabicFontLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Noto Sans Arabic'], text);
  });
}

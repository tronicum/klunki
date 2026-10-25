import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable app language: its [locale] and its endonym (the language's
/// own name, never translated).
class AppLanguage {
  const AppLanguage(this.locale, this.endonym);

  final Locale locale;
  final String endonym;
}

/// The languages offered in the picker, in display order. Simplified Chinese
/// carries its script code; translations live in `app_zh.arb`, which the
/// framework's language-code fallback picks up.
const List<AppLanguage> appLanguages = [
  AppLanguage(Locale('de'), 'Deutsch'),
  AppLanguage(Locale('en'), 'English'),
  AppLanguage(Locale('fr'), 'Français'),
  AppLanguage(Locale('es'), 'Español'),
  AppLanguage(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'), '简体中文'),
  AppLanguage(Locale('ar'), 'العربية'),
  AppLanguage(Locale('fa'), 'فارسی'),
];

/// Holds the user's language choice: `null` follows the system language.
/// The choice is persisted as a BCP-47 tag under [prefsKey].
class LocaleController extends ValueNotifier<Locale?> {
  LocaleController._(this._prefs, super.value);

  /// In-memory controller (no persistence), e.g. for widget tests that do not
  /// care about the language.
  LocaleController.memory([super.value]) : _prefs = null;

  static const String prefsKey = 'locale';

  final SharedPreferences? _prefs;

  /// Loads the saved choice. Pass [prefs] to inject an instance; otherwise
  /// [SharedPreferences.getInstance] is used (tests can seed it with
  /// `SharedPreferences.setMockInitialValues`).
  static Future<LocaleController> load({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return LocaleController._(p, parseTag(p.getString(prefsKey)));
  }

  /// Sets and persists the language; `null` = system.
  Future<void> setLocale(Locale? locale) async {
    value = locale;
    final p = _prefs;
    if (p == null) return;
    if (locale == null) {
      await p.remove(prefsKey);
    } else {
      await p.setString(prefsKey, locale.toLanguageTag());
    }
  }

  /// Parses a tag like `de`, `zh-Hans` or `pt-BR`; null/empty yields null.
  static Locale? parseTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    final parts = tag.split(RegExp('[-_]'));
    String? script;
    String? country;
    for (final part in parts.skip(1)) {
      if (part.length == 4) {
        script = part;
      } else {
        country = part;
      }
    }
    return Locale.fromSubtags(languageCode: parts.first, scriptCode: script, countryCode: country);
  }
}

/// Makes the app's [LocaleController] reachable from anywhere below the app.
class LocaleScope extends InheritedWidget {
  const LocaleScope({super.key, required this.controller, required super.child});

  final LocaleController controller;

  static LocaleController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LocaleScope>()!.controller;

  @override
  bool updateShouldNotify(LocaleScope oldWidget) => controller != oldWidget.controller;
}

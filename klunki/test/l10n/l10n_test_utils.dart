import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player;

/// Locale the widget tests run in: German, the source language, so the tests
/// can keep finding the German texts (the test binding's system locale would
/// be en-US).
const testLocale = Locale('de');

/// The German default player names (KLD-103): A is "Anna", B is "Ben".
String testName(Player p) => p == Player.a ? 'Anna' : 'Ben';

/// German strings, for code under test that takes an [AppLocalizations]
/// without a [BuildContext] (e.g. `describeMove`).
final AppLocalizations deL10n = lookupAppLocalizations(testLocale);

/// English strings.
final AppLocalizations enL10n = lookupAppLocalizations(const Locale('en'));

/// A [MaterialApp] around [home] with the app's localization delegates,
/// pinned to [locale].
Widget localizedApp(Widget home, {Locale locale = testLocale, bool debugShowCheckedModeBanner = true}) => MaterialApp(
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

/// The whole app (menu first) pinned to [locale], without persistence.
Widget klunkiApp({Locale locale = testLocale}) => KlunkiApp(localeController: LocaleController.memory(locale));

/// A [Text] showing [label]: as its text, or (a Quartett stat label that the
/// card lays out over two lines, "Höchst-\ngeschwindigkeit", KLD-092) as its
/// semantics label.
Finder findLabel(String label) =>
    find.byWidgetPredicate((w) => w is Text && (w.data == label || w.semanticsLabel == label), description: 'label "$label"');

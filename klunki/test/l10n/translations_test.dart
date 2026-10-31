// I18N-03: the fr/es/zh/ar/fa translations. Guards against untranslated
// (English) leftovers and smoke-tests every locale at phone width.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../ui/shell/shell_test_utils.dart';
import 'l10n_test_utils.dart';

const translated = ['fr', 'es', 'zh', 'ar', 'fa'];

/// Values that may stay identical to English: the brand, units and symbols,
/// the debug console command, the card back of the Latin-script locales,
/// and words that are spelled the same in French/Spanish.
const sameAsEnglish = {
  'Klunki',
  'km/h',
  '0–100 km/h',
  'kg',
  's',
  'undo',
  'QUARTETT',
  'Menu',
  'Horizontal',
  'Vertical',
  'Point {point}, {player}',
  // KLD-085: the menu's version line ("Version" is French too).
  'Version {version}',
  // GoStrategy (KLD-058b): the game's app name and ranks spelled alike.
  'GoStrategy',
  'General',
  'Colonel',
  'Lieutenant',
  // Quartett decks (KLD-069): train brands and words spelled the same.
  'ICE',
  'TGV',
  'Shinkansen',
  'Trains',
  'Europe',
  'China',
  // Photo credits (KLD-082): French spells these the same.
  'Licence',
  'Source',
};

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

/// True if [value] has no words outside its placeholders (e.g. "{cell} {state}").
bool _onlyPlaceholders(String value) =>
    !RegExp(r'\p{L}{2,}', unicode: true).hasMatch(value.replaceAll(RegExp(r'\{\w+\}'), ''));

void main() {
  final en = _arb('en');

  for (final locale in translated) {
    test('app_$locale.arb: no English leftovers, review marker, no untranslated list', () {
      final arb = _arb(locale);
      expect(arb['@@locale'], locale);
      expect(arb['@@x-review'], 'machine translation, needs native-speaker review');
      expect(arb.containsKey('@@x-untranslated'), isFalse);
      final leftovers = [
        for (final e in arb.entries)
          if (!e.key.startsWith('@') &&
              e.value == en[e.key] &&
              !_onlyPlaceholders(e.value as String) &&
              !sameAsEnglish.contains(e.value))
            '${e.key}: ${e.value}',
      ];
      expect(leftovers, isEmpty);
    });
  }

  group('phone width 390×844', () {
    Future<void> phone(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    for (final code in translated) {
      final locale = Locale(code);
      final l10n = lookupAppLocalizations(locale);

      testWidgets('$code: menu renders without overflow', (tester) async {
        await phone(tester);
        await tester.pumpWidget(klunkiApp(locale: locale));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.menuChooseGame), findsOneWidget);
        expect(find.text(l10n.menuGameConnect4), findsOneWidget);
        expect(find.text(l10n.menuGameSchiffe), findsOneWidget);
      });

      for (final id in ['connect4', 'muehle', 'quartett-trumpf', 'quartett-sets', 'schiffe', 'gostrategy', 'chess']) {
        testWidgets('$code: $id renders and plays to the result dialog without overflow', (tester) async {
          await phone(tester);
          await pumpGame(tester, id, locale: locale);
          expect(tester.takeException(), isNull);
          await playToEnd(tester);
          expect(tester.takeException(), isNull);
          expect(find.byKey(resultDialog), findsOneWidget);
        });
      }
    }
  });
}

import 'package:flutter/material.dart' hide Card;
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'l10n_test_utils.dart';

/// I18N-05: engine ids (result reasons, Quartett sets / stats, ships) map to
/// localized texts.
void main() {
  final locales = {
    for (final l in AppLocalizations.supportedLocales) l.languageCode: lookupAppLocalizations(l),
  };
  const params = {'moves': 50, 'a': 5, 'b': 3};

  group('reason codes', () {
    test('every GameEndReason has a text in every locale', () {
      for (final code in GameEndReason.values) {
        for (final e in locales.entries) {
          final text = localizedEndReason(e.value, code, params);
          expect(text, isNotEmpty, reason: '${e.key} ${code.code}');
          expect(text, isNot(contains('{')), reason: '${e.key} ${code.code}');
        }
      }
    });

    test('de and en texts are distinct per code and carry the params', () {
      for (final l10n in [deL10n, enL10n]) {
        final texts = [for (final c in GameEndReason.values) localizedEndReason(l10n, c, params)];
        expect(texts.toSet(), hasLength(texts.length));
      }
      expect(localizedEndReason(deL10n, GameEndReason.muehleNoRemovalLimit, params), '50 Züge ohne Schlagen');
      expect(localizedEndReason(enL10n, GameEndReason.quartettMostQuartets, params), 'More quartets (5:3)');
      expect(localizedEndReason(deL10n, GameEndReason.connect4FourInARow), 'Vier in einer Reihe');
      expect(localizedEndReason(enL10n, GameEndReason.schiffeAllSunk), 'All ships sunk');
    });

    test('localizedResultReason: empty while running, engine text without a code', () {
      expect(localizedResultReason(deL10n, const GameResult()), isEmpty);
      expect(localizedResultReason(deL10n, const GameResult(draw: true, reason: 'custom')), 'custom');
      expect(
          localizedResultReason(
              deL10n,
              const GameResult(
                  winner: Player.a, reason: 'more quartets (5:3)', code: GameEndReason.quartettMostQuartets, params: {'a': 5, 'b': 3})),
          'Mehr Quartette (5:3)');
    });
  });

  group('Quartett and Schiffe ids', () {
    test('every set letter, stat id and fleet length has its own key (no fallback)', () {
      for (final l10n in [deL10n, enL10n]) {
        final sets = [for (final s in QuartettGame.setNames.keys) localizedSetName(l10n, s)];
        expect(sets.toSet(), hasLength(QuartettGame.setNames.length));
        final labels = [for (final s in QuartettGame.stats) localizedStatLabel(l10n, s.id)];
        expect(labels.toSet(), hasLength(QuartettGame.stats.length));
        for (final s in QuartettGame.stats) {
          expect(localizedStatUnit(l10n, s.id), isNotEmpty);
        }
        final ships = {for (final len in SchiffeGame.defaultFleet) localizedShipName(l10n, len)};
        expect(ships, hasLength(SchiffeGame.defaultFleet.toSet().length));
        expect(ships, isNot(contains(l10n.engineShipOther)));
      }
      // German texts match the engine's own names.
      for (final e in QuartettGame.setNames.entries) {
        expect(localizedSetName(deL10n, e.key), e.value);
      }
      for (final s in QuartettGame.stats) {
        expect(localizedStatLabel(deL10n, s.id), s.label);
        expect(localizedStatUnit(deL10n, s.id), s.unit);
      }
      for (final e in SchiffeGame.shipNames.entries) {
        expect(localizedShipName(deL10n, e.key), e.value);
      }
    });

    test('English names', () {
      expect(localizedSetName(enL10n, 'E'), 'Rally Legends');
      expect(localizedStatLabel(enL10n, 'kmh'), 'Top speed');
      expect(localizedStatUnit(enL10n, 'ps'), 'hp');
      expect(localizedShipName(enL10n, 2), 'Submarine');
      expect(localizedShipName(enL10n, 7), 'Ship');
    });
  });

  testWidgets('a Quartett card in en shows English stat labels, units and set name', (tester) async {
    final card = QuartettGame.cardById('A1')!;
    await tester.pumpWidget(localizedApp(
        Scaffold(body: SingleChildScrollView(child: SizedBox(width: 320, child: QuartettCard(card: card)))),
        locale: const Locale('en')));
    for (final label in ['Power', 'Top speed', 'Displacement', 'Weight', '0–100 km/h']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('650 hp'), findsOneWidget);
    expect(find.text('2.7 s'), findsOneWidget);
    expect(find.text('Supercars'), findsOneWidget);
    expect(find.text(card.name), findsOneWidget, reason: 'car names stay as they are');
    expect(find.text('Leistung'), findsNothing);
  });
}

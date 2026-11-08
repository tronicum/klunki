// KLD-124: how many play a game, board-game-box style: a people chip
// ("2", "2–4") on every menu tile and on top of each rules page, taken from
// the engine registry; screen readers hear "2 Spieler" / "2 bis 4 Spieler".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/player_count_chip.dart';
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' show GameSpec, appGameSpecs, specById;
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n_test_utils.dart';

Finder _chip(String id) => find.byKey(Key('player-count-$id'));

/// What the chip of [spec] shows, straight from the registry.
String _expected(GameSpec spec) {
  final (:min, :max) = offeredPlayers(spec);
  return min == max ? '$min' : '$min–$max';
}

Future<void> _pumpMenu(WidgetTester tester, {Locale locale = testLocale, double scale = 1}) async {
  tester.view.physicalSize = const Size(375, 3600);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(klunkiApp(locale: locale));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.shared.markFirst(SeenTips.maumauIntro);
  });

  test('the range comes from the registry: 2 for two-player games, 2–4 for Ausgewürfelt', () {
    expect(offeredPlayers(specById('connect4')!), (min: 2, max: 2));
    expect(offeredPlayers(specById('dicesheet')!), (min: 2, max: 4));
    // The engine has 4 seats for Wortgewandt; the app offers 2 so far.
    expect(offeredPlayers(specById('wordtiles')!), (min: 2, max: 2));
    for (final spec in appGameSpecs) {
      final r = offeredPlayers(spec);
      expect(r.min, spec.minPlayers, reason: spec.id);
      expect(r.max, inInclusiveRange(r.min, spec.maxPlayers), reason: spec.id);
    }
  });

  testWidgets('every menu tile shows its player count in the illustration, above title and links', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpMenu(tester);
    for (final spec in appGameSpecs) {
      final tile = find.byKey(Key('menu-${spec.id}'));
      final chip = find.descendant(of: tile, matching: _chip(spec.id));
      expect(chip, findsOneWidget, reason: spec.id);
      expect(find.descendant(of: chip, matching: find.text(_expected(spec))), findsOneWidget, reason: spec.id);
      expect(find.descendant(of: chip, matching: find.byIcon(Icons.people_alt_outlined)), findsOneWidget);
      final (:min, :max) = offeredPlayers(spec);
      expect(tester.getSemantics(chip).label.split('\n').first, min == max ? '$min Spieler' : '$min bis $max Spieler', reason: spec.id);
      // In the top end corner of the tile, clear of the play links and "Regeln".
      final c = tester.getRect(chip), t = tester.getRect(tile);
      expect(c.top - t.top, lessThan(12), reason: spec.id);
      expect(t.right - c.right, lessThan(12), reason: spec.id);
      expect(c.bottom, lessThan(tester.getRect(find.byKey(Key('menu-${spec.id}-local'))).top), reason: spec.id);
    }
    expect(find.descendant(of: _chip('dicesheet'), matching: find.text('2–4')), findsOneWidget);
    expect(find.descendant(of: _chip('connect4'), matching: find.text('2')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('ar: the range stays "2–4" (laid out LTR) in the top-left corner, Arabic label', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pumpMenu(tester, locale: const Locale('ar'));
    final text = tester.widget<Text>(find.descendant(of: _chip('dicesheet'), matching: find.text('2–4')));
    expect(text.textDirection, TextDirection.ltr);
    expect(tester.getSemantics(_chip('dicesheet')).label.split('\n').first, 'من 2 إلى 4 لاعبين');
    expect(tester.getSemantics(_chip('connect4')).label.split('\n').first, 'لاعبان');
    final c = tester.getRect(_chip('connect4')), t = tester.getRect(find.byKey(const Key('menu-connect4')));
    expect(c.left - t.left, lessThan(12));
    semantics.dispose();
  });

  testWidgets('large text (1.3) on a small phone: no overflow', (tester) async {
    await _pumpMenu(tester, scale: 1.3);
    expect(tester.takeException(), isNull);
    expect(_chip('dicesheet'), findsOneWidget);
  });

  testWidgets('every rules page shows the same chip in its header', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final spec in appGameSpecs.where((s) => hasRules(s.id))) {
      await tester.pumpWidget(localizedApp(RulesScreen(key: ValueKey(spec.id), gameId: spec.id)));
      await tester.pumpAndSettle();
      final chip = _chip(spec.id);
      expect(chip, findsOneWidget, reason: spec.id);
      expect(find.descendant(of: chip, matching: find.text(_expected(spec))), findsOneWidget, reason: spec.id);
      // Over the illustration at the top of the page, before "Ziel".
      expect(tester.getRect(chip).bottom, lessThan(tester.getRect(find.byKey(const Key('rules-goal'))).top));
      expect(find.byType(PlayerCountChip), findsOneWidget);
    }
    semantics.dispose();
  });
}

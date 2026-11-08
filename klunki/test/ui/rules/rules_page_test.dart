// KLD-123: the rules page of every game (from the game's "Regeln" button
// and from the menu tile), the house rules that are on, the "Neu hier?"
// line and its end.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/rules/rules_registry.dart';
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<GameController> _pumpGame(WidgetTester tester, GameConfig config, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).pop();
  await tester.pumpAndSettle();
}

/// Checks the parts of the open rules page; returns whether it has the
/// "Regelvarianten" section, which is there exactly when a variant is on.
bool _expectParts(WidgetTester tester, GameConfig config) {
  for (final part in ['rules-page', 'rules-goal', 'rules-turn', 'rules-special']) {
    expect(_key(part), findsOneWidget, reason: part);
  }
  final context = tester.element(find.byType(RulesScreen));
  final rules = gameRules[config.gameId]!(context, AppLocalizations.of(context), config);
  final anyOn = rules.houseRules.any((h) => h.on);
  expect(_key('rules-house'), anyOn ? findsOneWidget : findsNothing, reason: 'rules-house');
  return anyOn;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    // Tours of their own would cover the screen.
    SeenTips.shared
      ..markFirst(SeenTips.maumauIntro)
      ..markFirst(SeenTips.wordtilesBench);
  });

  test('every game of the app has a rules page', () {
    expect(gameRules.keys.toSet(), {for (final s in appGameSpecs) s.id});
  });

  group('from the game', () {
    for (final id in gameRules.keys) {
      testWidgets('$id: "Regeln" in the app bar opens the four parts, no overflow', (tester) async {
        await _pumpGame(tester, GameConfig(id, seed: 3));
        expect(_key('shell-rules'), findsOneWidget);
        expect(find.descendant(of: find.byType(AppBar), matching: _key('shell-rules')), findsOneWidget);
        await _tap(tester, 'shell-rules');
        final house = _expectParts(tester, GameConfig(id, seed: 3));
        expect(find.text(deL10n.rulesHouseInGame), house ? findsOneWidget : findsNothing);
        expect(_key('rules-house-menu-note'), findsNothing);
        expect(tester.takeException(), isNull);
        expect(SeenTips.shared.has(SeenTips.rulesOpened(id)), isTrue);
      });
    }
  });

  group('from the menu', () {
    for (final id in gameRules.keys) {
      testWidgets('$id: the tile\'s "Regeln" link shows the defaults', (tester) async {
        tester.view.physicalSize = const Size(390, 844) * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(klunkiApp());
        await tester.pumpAndSettle();
        await _tap(tester, 'menu-$id-rules');
        final house = _expectParts(tester, GameConfig(id));
        expect(find.text(deL10n.rulesHouse), house ? findsOneWidget : findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Mau-Mau: the suggested house rules, and that they can be changed', (tester) async {
      await tester.pumpWidget(klunkiApp());
      await tester.pumpAndSettle();
      await _tap(tester, 'menu-maumau-rules');
      for (final on in ['seven', 'stack7', 'eight', 'ace', 'mau']) {
        expect(_key('rules-house-$on'), findsOneWidget, reason: on);
      }
      expect(_key('rules-house-jackOnJack'), findsNothing, reason: 'off by default');
      expect(_key('rules-house-menu-note'), findsOneWidget);
    });

    testWidgets('Wortgewandt: no rule variant on by default, no Regelvarianten section', (tester) async {
      await tester.pumpWidget(klunkiApp());
      await tester.pumpAndSettle();
      await _tap(tester, 'menu-wordtiles-rules');
      expect(_key('rules-special'), findsOneWidget);
      expect(_key('rules-house'), findsNothing);
      expect(_key('rules-house-menu-note'), findsNothing);
      expect(find.text(deL10n.rulesHouse), findsNothing);
    });
  });

  group('the house rules of the running game', () {
    testWidgets('Mau-Mau: only the switches that are on', (tester) async {
      await _pumpGame(
        tester,
        const GameConfig('maumau', seed: 3, mauMau: MauMauRules(sevenDraws: false, jackOnJack: true, mauCall: false)),
      );
      await _tap(tester, 'shell-rules');
      expect(_key('rules-house-jackOnJack'), findsOneWidget);
      expect(_key('rules-house-eight'), findsOneWidget);
      expect(_key('rules-house-ace'), findsOneWidget);
      for (final off in ['seven', 'stack7', 'mau']) {
        expect(_key('rules-house-$off'), findsNothing, reason: off);
      }
    });

    testWidgets('Mau-Mau: the turn follows "Legen, wenn möglich"', (tester) async {
      bool line(String start) => find.textContaining(start).evaluate().isNotEmpty;
      await _pumpGame(tester, const GameConfig('maumau', seed: 3));
      await _tap(tester, 'shell-rules');
      expect(_key('rules-house-mustPlay'), findsOneWidget);
      expect(line('Passt keine Karte, ziehst du 1 Karte.'), isTrue);
      expect(line('oder willst du keine legen'), isFalse);
    });

    testWidgets('Mau-Mau: "Legen, wenn möglich" off, drawing anyway is in the turn', (tester) async {
      bool line(String start) => find.textContaining(start).evaluate().isNotEmpty;
      await _pumpGame(tester, const GameConfig('maumau', seed: 3, mauMau: MauMauRules(mustPlay: false)));
      await _tap(tester, 'shell-rules');
      expect(_key('rules-house-mustPlay'), findsNothing);
      expect(line('Passt keine Karte oder willst du keine legen, ziehst du 1 Karte.'), isTrue);
      expect(find.text(deL10n.rulesHouseInGame), findsOneWidget, reason: 'other variants are on');
    });

    testWidgets('Mäxchen: 5 lives, "Mäxchen doppelt" off', (tester) async {
      await _pumpGame(tester, const GameConfig('maexchen', seed: 3, lives: 5, maexchenDouble: false));
      await _tap(tester, 'shell-rules');
      expect(find.text(deL10n.rulesMaexchenLives(5)), findsOneWidget);
      expect(_key('rules-house-double'), findsNothing);
      expect(_key('rules-maexchen-order'), findsOneWidget);
    });

    testWidgets('Mäxchen: the defaults, 3 lives and "Mäxchen doppelt"', (tester) async {
      await _pumpGame(tester, const GameConfig('maexchen', seed: 3));
      await _tap(tester, 'shell-rules');
      expect(find.text(deL10n.rulesMaexchenLives(3)), findsOneWidget);
      expect(_key('rules-house-double'), findsOneWidget);
    });

    testWidgets('Wortgewandt: "Joker tauschen" on', (tester) async {
      await _pumpGame(tester, const GameConfig('wordtiles', seed: 3, jokerSwap: true));
      await _tap(tester, 'shell-rules');
      expect(_key('rules-house-joker'), findsOneWidget);
      expect(_key('rules-house-dictionary'), findsNothing);
      for (final p in ['doubleLetter', 'tripleLetter', 'doubleWord', 'tripleWord']) {
        expect(_key('wordtiles-help-premium-$p'), findsOneWidget);
      }
    });

    testWidgets('Quartett (Trumpf): "3 or fewer cards: choose" is on', (tester) async {
      await _pumpGame(tester, const GameConfig('quartett-trumpf', seed: 3));
      await _tap(tester, 'shell-rules');
      expect(_key('rules-house-pickLow'), findsOneWidget);
    });

    testWidgets('chess: no rule variants section; every piece explained', (tester) async {
      await _pumpGame(tester, const GameConfig('chess'));
      await _tap(tester, 'shell-rules');
      expect(find.text(deL10n.rulesSpecial), findsOneWidget);
      expect(_key('rules-house'), findsNothing);
      for (final t in ChessPieceType.values) {
        expect(_key('rules-chess-${t.name}'), findsOneWidget, reason: t.name);
      }
    });

    testWidgets('GoStrategy: the table lists every piece with its count', (tester) async {
      await _pumpGame(tester, const GameConfig('gostrategy'));
      await _tap(tester, 'shell-rules');
      for (final p in GoPiece.values) {
        expect(_key('rules-go-${p.name}'), findsOneWidget, reason: p.name);
        expect(find.descendant(of: _key('rules-go-${p.name}'), matching: find.text(deL10n.rulesGoCount(p.count))),
            findsOneWidget);
      }
      expect(_key('rules-go-zoom'), findsOneWidget);
    });
  });

  group('"Neu hier?" line', () {
    testWidgets('shown to a new player until the rules page was opened', (tester) async {
      await _pumpGame(tester, const GameConfig('connect4'));
      expect(_key('shell-rules-intro'), findsOneWidget);
      expect(find.text(deL10n.rulesNewHere), findsOneWidget);
      await _tap(tester, 'shell-rules-intro');
      _expectParts(tester, const GameConfig('connect4'));
      await _back(tester);
      expect(_key('shell-rules-intro'), findsNothing);
      // The next game: still gone.
      await _pumpGame(tester, const GameConfig('connect4', seed: 2));
      expect(_key('shell-rules-intro'), findsNothing);
      // Another game is new.
      await _pumpGame(tester, const GameConfig('muehle'));
      expect(_key('shell-rules-intro'), findsOneWidget);
    });

    testWidgets('the "Regeln" button ends it too', (tester) async {
      await _pumpGame(tester, const GameConfig('connect4'));
      await _tap(tester, 'shell-rules');
      await _back(tester);
      expect(_key('shell-rules-intro'), findsNothing);
    });

    testWidgets('three games, then no more; "Neues Spiel" counts as a game', (tester) async {
      await _pumpGame(tester, const GameConfig('connect4'));
      expect(_key('shell-rules-intro'), findsOneWidget, reason: 'game 1');
      await _pumpGame(tester, const GameConfig('connect4', seed: 2));
      expect(_key('shell-rules-intro'), findsOneWidget, reason: 'game 2');
      final c = await _pumpGame(tester, const GameConfig('connect4', seed: 3));
      expect(_key('shell-rules-intro'), findsOneWidget, reason: 'game 3');
      c.restart(seed: 4);
      await tester.pumpAndSettle();
      expect(_key('shell-rules-intro'), findsNothing, reason: 'game 4');
      expect(SeenTips.shared.count(SeenTips.gamesStarted('connect4')), 4);
    });

    testWidgets('stored: a fresh start remembers the opened page and the count', (tester) async {
      SeenTips.debugReset(loaded: true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _pumpGame(tester, const GameConfig('connect4'));
      await _pumpGame(tester, const GameConfig('muehle'));
      await _tap(tester, 'shell-rules');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      SeenTips.debugReset(loaded: true);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(SeenTips.shared.has(SeenTips.rulesOpened('muehle')), isTrue);
      expect(SeenTips.shared.count(SeenTips.gamesStarted('connect4')), 1);
    });

    testWidgets('not after the game is over', (tester) async {
      final c = await _pumpGame(tester, const GameConfig('connect4'));
      expect(_key('shell-rules-intro'), findsOneWidget);
      for (final col in [0, 1, 0, 1, 0, 1, 0]) {
        await c.submit({'col': col});
      }
      await tester.pumpAndSettle();
      expect(c.game.isOver, isTrue);
      expect(_key('shell-rules-intro'), findsNothing);
    });
  });

  test('hasRules', () {
    expect(hasRules('connect4'), isTrue);
    expect(hasRules('no-such-game'), isFalse);
  });
}

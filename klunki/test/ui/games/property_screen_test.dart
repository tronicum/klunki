// KLD-060: Baulöwe in hot-seat for 2–4 players, played through the real UI
// (taps on "Würfeln", "Kaufen", the bids, "Meine Straßen", …; never
// `controller.submit` for the moves under test). Dice are scripted with
// `debugScriptDice` so every turn is known.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/games/property/property_board.dart' show PropertyDeedCard;
import 'package:klunki/ui/games/property/property_roll_show.dart';
import 'package:klunki/ui/games/property/property_screen.dart' show propertyNarration;
import 'package:klunki/ui/rules/rules_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart' show UndoMoveButton;
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/ui/shell/seat_game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart' show controllerOf, resultDialog;

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

Future<GameController> _pump(WidgetTester tester, GameConfig config, {List<int> dice = const []}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  (c.game as PropertyGame).debugScriptDice(dice);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

String _cash(WidgetTester tester, int seat) => tester.widget<Text>(_key('property-cash-$seat')).data!;

/// Whether seat [seat]'s token stands on [square] on the board.
bool _tokenOn(int seat, int square) => find
    .descendant(of: _key('property-square-$square'), matching: find.byWidgetPredicate((w) => w is SeatToken && w.seat == seat))
    .evaluate()
    .isNotEmpty;

void main() {
  final berlin = PropertyTheme.berlin;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.propertyIntro);
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('from the menu: options, "Wer spielt?" with 3, the board', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    SeenTips.shared
      ..markFirst(SeenTips.maumauIntro)
      ..markFirst(SeenTips.dicesheetIntro);
    await tester.pumpWidget(klunkiApp());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Baulöwe'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Baulöwe'));
    await tester.pumpAndSettle();
    expect(_key('property-options'), findsOneWidget);
    // The defaults: Berlin, 30 rounds (until trading exists), no rule
    // variants; "Regelvarianten", not "Hausregeln" (KLD-123).
    expect(find.text('Bis nur noch einer übrig ist'), findsOneWidget);
    expect(
        tester.widget<ListTile>(_key('property-rounds-30')).selected, isTrue, reason: '30 rounds by default');
    expect(tester.widget<ListTile>(_key('property-rounds-0')).selected, isFalse);
    expect(find.text('Regelvarianten'), findsOneWidget);
    expect(find.text('Hausregeln'), findsNothing);
    expect(find.text('Auf „Späti-Pause“'), findsOneWidget);
    await _tap(tester, 'property-theme-fantasie');
    await _tap(tester, 'property-free-pot');
    expect(find.textContaining('Topf: Steuern'), findsOneWidget);
    await _tap(tester, 'property-double-start');
    await _tap(tester, 'property-options-next');
    // "Wer spielt?" with the player count (2–4).
    expect(_key('hot-seat-start-dialog'), findsOneWidget);
    expect(_key('seat-players-4'), findsOneWidget);
    expect(_key('seat-players-5'), findsNothing, reason: 'the one-device shell offers 2–4');
    await _tap(tester, 'seat-players-3');
    await tester.tap(find.text('Spielen'));
    await tester.pumpAndSettle();

    final c = controllerOf(tester);
    expect(
        c.config,
        GameConfig('property',
            seed: c.config.seed,
            players: 3,
            property:
                const PropertyOptions(theme: 'fantasie', rounds: 30, free: PropertyFreeSquare.pot, doubleStart: true)));
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(find.text('FANTASIESTADT'), findsOneWidget);
    for (var s = 0; s < 3; s++) {
      expect(_key('property-player-$s'), findsOneWidget);
      expect(_cash(tester, s), '1500 Taler · keine Straße');
      expect(_tokenOn(s, 0), isTrue, reason: 'everyone starts on Start');
    }
    expect(_key('property-player-3'), findsNothing);
    for (var i = 0; i < 40; i++) {
      expect(_key('property-square-$i'), findsOneWidget);
    }
    expect(_key('property-pot'), findsOneWidget, reason: 'the pot is shown with the house rule');
    expect(_key('property-roll'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('roll, buy, end the turn; the next player pays rent', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3), dice: [1, 2, 1, 2]);
    final g = c.game as PropertyGame;
    final street = berlin.squares[3];
    await _tap(tester, 'property-roll');
    expect(g.seats[0].pos, 3);
    expect(_tokenOn(0, 3), isTrue);
    expect(find.text('${street.name} gehört noch niemandem.'), findsOneWidget);
    expect(find.text('Anna würfelt 1 + 2 → ${street.name}'), findsOneWidget, reason: 'the hint line');
    await _tap(tester, 'property-buy');
    expect(g.ownerOf(3), 0);
    expect(_cash(tester, 0), '${1500 - street.price} Taler · 1 Straße');
    expect(find.textContaining('Anna kauft ${street.name} für ${street.price} Taler'), findsOneWidget);
    await _tap(tester, 'property-end');
    expect(find.text('Ben ist am Zug'), findsOneWidget);
    // The hint still tells what Anna did.
    expect(find.textContaining('Anna kauft'), findsOneWidget);

    await _tap(tester, 'property-roll');
    final rent = street.rents[0];
    expect(g.seats[1].cash, 1500 - rent);
    expect(_cash(tester, 1), '${1500 - rent} Taler · keine Straße');
    expect(find.textContaining('Ben zahlt $rent Taler an Anna'), findsOneWidget);
    // History: one line per move, the sentences name the players once.
    await _tap(tester, 'shell-history');
    expect(find.text('Anna würfelt 1 + 2 → ${street.name}'), findsOneWidget);
    expect(find.text('Anna kauft ${street.name} für ${street.price} Taler'), findsOneWidget);
    expect(find.text('Anna: Zug beenden'), findsOneWidget, reason: 'nothing to tell: the button');
    expect(find.descendant(of: _key('history-sheet'), matching: find.textContaining('Ben würfelt 1 + 2')), findsOneWidget);
    expect(find.textContaining('Anna: Anna'), findsNothing);
    expect(find.textContaining('Ben: Ben'), findsNothing);
  });

  testWidgets('decline: the street is auctioned, bids by tap, the winner pays', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3, players: 3), dice: [1, 2]);
    final g = c.game as PropertyGame;
    await _tap(tester, 'property-roll');
    await _tap(tester, 'property-decline');
    expect(_key('property-auction'), findsOneWidget);
    expect(find.text('Noch kein Gebot'), findsOneWidget);
    expect(find.text('Ben ist mit Bieten dran.'), findsOneWidget);
    expect(find.text('Ben ist am Zug'), findsOneWidget, reason: 'the bidder moves now');
    await _tap(tester, 'property-bid-0');
    expect(g.auction!.high, PropertyGame.minFirstBid);
    expect(find.text('Höchstgebot: 10 Taler von Ben'), findsOneWidget);
    expect(find.text('Cleo ist mit Bieten dran.'), findsOneWidget);
    await _tap(tester, 'property-pass');
    expect(find.text('Anna ist mit Bieten dran.'), findsOneWidget);
    await _tap(tester, 'property-bid-1');
    final high = g.auction!.high;
    expect(high, PropertyGame.minFirstBid + 1 + 50);
    await _tap(tester, 'property-pass'); // Ben
    expect(g.auction, isNull);
    expect(g.ownerOf(3), 0);
    expect(g.seats[0].cash, 1500 - high);
    expect(find.text('Anna ist am Zug'), findsOneWidget);
    expect(_key('property-end'), findsOneWidget);
  });

  testWidgets('"Meine Straßen": build on a whole group, the board shows it', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3));
    final g = c.game as PropertyGame;
    await _tap(tester, 'property-manage');
    expect(find.text('Noch keine Straßen.'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    // Test setup (not a move): Anna owns the whole first group.
    g.debugSetSquare(1, 0);
    g.debugSetSquare(3, 0);
    await _tap(tester, 'property-manage');
    expect(_key('property-manage-sheet'), findsOneWidget);
    expect(find.text('Straßen: Anna'), findsOneWidget);
    expect(_key('property-manage-row-1'), findsOneWidget);
    expect(_key('property-manage-row-3'), findsOneWidget);
    final cost = berlin.squares[1].houseCost;
    await _tap(tester, 'property-manage-build-1');
    expect(g.housesOn(1), 1);
    expect(find.text('1 × Späti'), findsOneWidget);
    // Even building: the other street first.
    expect(_key('property-manage-build-1'), findsNothing);
    await _tap(tester, 'property-manage-build-3');
    expect(g.housesOn(3), 1);
    expect(g.seats[0].cash, 1500 - 2 * cost);
    expect(_key('property-manage-sell-1'), findsOneWidget);
    expect(_key('property-manage-mortgage-1'), findsNothing, reason: 'not with buildings in the group');
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.textContaining('Anna baut Späti auf ${berlin.squares[3].name}'), findsOneWidget);
    // The board: one small building in each band.
    for (final i in [1, 3]) {
      expect(
          find.descendant(
              of: _key('property-square-$i'), matching: find.byWidgetPredicate((w) => w is Container && w.margin != null)),
          findsOneWidget);
    }
    expect(c.moves.map((m) => m.move['action']), ['build', 'build']);
  });

  testWidgets('a debt that cannot be paid: bankrupt, the result ranks by money', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3), dice: [1, 2]);
    final g = c.game as PropertyGame;
    // Ben owns Schlesische Straße with a big building; Anna has 10 Taler.
    g.debugSetSquare(1, 1, houses: 5);
    g.debugSetSquare(3, 1, houses: 5);
    g.debugSetCash(0, 10);
    await tester.pumpAndSettle();
    await _tap(tester, 'property-roll');
    expect(g.phase, PropertyPhase.debt);
    expect(_key('property-debt'), findsOneWidget);
    expect(find.textContaining('Anna muss ${berlin.squares[3].rents[5]} Taler zahlen, hat aber nur 10 Taler.'),
        findsOneWidget);
    await _tap(tester, 'property-bankrupt');
    expect(_key('result-dialog'), findsOneWidget);
    expect(find.text('Ben gewinnt!'), findsOneWidget);
    expect(find.text('Alle anderen sind pleite oder ausgestiegen'), findsOneWidget);
    expect(tester.widget<Text>(_key('result-score-0')).data, 'ausgeschieden');
    expect(tester.widget<Text>(_key('result-score-1')).data, endsWith('Taler'));
    expect(find.byKey(resultDialog), findsOneWidget);
  });

  testWidgets('a tap on a square shows its details', (tester) async {
    await _pump(tester, const GameConfig('property', seed: 3));
    final sq = berlin.squares[39];
    await _tap(tester, 'property-square-39');
    expect(_key('property-square-sheet'), findsOneWidget);
    expect(find.text(sq.name), findsWidgets);
    expect(find.text('Preis: ${sq.price} Taler'), findsOneWidget);
    expect(find.text('Gehört noch der Bank'), findsOneWidget);
    expect(find.text('1 × ${berlin.colourGroups[7].big}'), findsOneWidget);
  });

  testWidgets('the deed card: the whole rent table, compact and centred', (tester) async {
    await _pump(tester, const GameConfig('property', seed: 3));
    final sq = berlin.squares[39];
    final g = berlin.colourGroups[sq.group];
    await _tap(tester, 'property-square-39');
    String right(String key) => tester
        .widgetList<Text>(find.descendant(of: _key(key), matching: find.byType(Text)))
        .last
        .data!;
    expect(right('property-deed-rent-0'), '${sq.rents[0]} Taler');
    expect(right('property-deed-rent-group'), '${sq.rents[0] * 2} Taler');
    for (var h = 1; h <= 5; h++) {
      expect(right('property-deed-rent-$h'), '${sq.rents[h]} Taler', reason: '$h buildings');
    }
    expect(find.text('1 × ${g.small}'), findsOneWidget);
    expect(find.text('4 × ${g.smallPlural}'), findsOneWidget);
    expect(find.text('Jedes Gebäude kostet ${sq.houseCost} Taler'), findsOneWidget);
    expect(right('property-deed-mortgage'), '${sq.mortgageValue} Taler');
    // A deed card, not a page.
    final card = tester.getRect(_key('property-deed'));
    expect(card.width, lessThanOrEqualTo(300));
    expect(card.center.dx, closeTo(390 / 2, 1));
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // A station: rent by the number of stations.
    await _tap(tester, 'property-square-5');
    for (var k = 1; k <= 4; k++) {
      expect(right('property-deed-stations-$k'), '${berlin.squares[5].rents[k - 1]} Taler');
    }
    expect(find.text('2 Bahnhöfe'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // A utility: the dice factors.
    await _tap(tester, 'property-square-12');
    expect(right('property-deed-utility-1'), 'Augensumme × 4');
    expect(right('property-deed-utility-2'), 'Augensumme × 10');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the first game shows the tour; "Kurz erklärt" shows it again', (tester) async {
    SeenTips.debugReset();
    await _pump(tester, const GameConfig('property', seed: 3));
    expect(_key('property-coach'), findsOneWidget);
    expect(find.text('Würfle und zieh mit deiner Spielfigur über das Brett.'), findsOneWidget);
    while (_key('property-coach-next').evaluate().isNotEmpty) {
      await _tap(tester, 'property-coach-next');
    }
    await _tap(tester, 'property-coach-done');
    expect(_key('property-coach'), findsNothing);
    expect(SeenTips.shared.has(SeenTips.propertyIntro), isTrue);
    await _tap(tester, 'shell-menu');
    await _tap(tester, 'property-tour');
    expect(_key('property-coach'), findsOneWidget);
  });

  testWidgets('rules page from the menu: the app defaults (30 rounds), "Regelvarianten"', (tester) async {
    tester.view.physicalSize = const Size(390, 2400) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localizedApp(const RulesScreen(gameId: 'property')));
    await tester.pumpAndSettle();
    expect(find.text('30 Runden'), findsOneWidget);
    expect(find.textContaining('Hausregel'), findsNothing);
  });

  // Maintainer feedback on build 2026110911: a roll is shown (dice, then
  // the walk), the card and the question come after.
  group('the roll is shown', () {
    Future<GameController> pumpAt(WidgetTester tester, {int pos = 0, required List<int> dice}) async {
      tester.view.physicalSize = const Size(390, 844) * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final c = GameController.hotSeat(const GameConfig('property', seed: 3));
      addTearDown(c.dispose);
      final g = c.game as PropertyGame;
      g.debugScriptDice(dice);
      if (pos != 0) g.debugSetCash(0, 1500, pos: pos);
      await tester.pumpWidget(localizedApp(buildGameScreen(c)));
      await tester.pumpAndSettle();
      return c;
    }

    Future<void> tapRoll(WidgetTester tester) async {
      await tester.ensureVisible(_key('property-roll'));
      await tester.pumpAndSettle();
      await tester.tap(_key('property-roll'));
      await tester.pump();
    }

    const dice = PropertyRollShow.diceMs, step = PropertyRollShow.stepMs;

    testWidgets('dice, then the token walks square by square, then the card and the question', (tester) async {
      final c = await pumpAt(tester, dice: [1, 2]);
      final street = berlin.squares[3];
      // The story line keeps its height from the start: the board does not
      // move when the first sentences appear.
      final boardAt = tester.getRect(_key('property-board'));
      expect(find.byKey(const Key('shell-hint')), findsNothing);
      expect(find.byKey(const Key('seat-starter')), findsNothing, reason: 'the shell line would go away');
      expect(tester.widget<Text>(_key('property-story')).data, contains('Anna'), reason: 'who starts');
      await tapRoll(tester);
      // The engine has the move at once.
      expect((c.game as PropertyGame).seats[0].pos, 3);
      await tester.pump(const Duration(milliseconds: 300));
      expect(_key('property-dice-rolling'), findsOneWidget);
      expect(_tokenOn(0, 0), isTrue, reason: 'the token waits for the dice');
      expect(_key('property-buy'), findsNothing, reason: 'the question waits');
      expect(_key('property-focus-waiting'), findsOneWidget, reason: 'the card waits');
      expect(tester.widget<FilledButton>(_key('property-rolling')).onPressed, isNull);
      expect(find.text('Anna würfelt 1 + 2 → ${street.name}'), findsNothing, reason: 'the hint waits');
      // Square by square: 1, 2, 3.
      for (var sq = 1; sq <= 3; sq++) {
        await tester.pump(Duration(milliseconds: (sq == 1 ? dice - 300 : 0) + step));
        expect(_key('property-dice'), findsOneWidget, reason: 'the dice lie still');
        expect(_tokenOn(0, sq), isTrue, reason: 'on square $sq');
        expect(_key('property-walking-0'), findsOneWidget);
      }
      await tester.pumpAndSettle();
      expect(_key('property-rolling'), findsNothing);
      expect(_key('property-focus'), findsOneWidget);
      expect(find.text('${street.name} gehört noch niemandem.'), findsOneWidget);
      expect(_key('property-buy'), findsOneWidget);
      expect(find.text('Anna würfelt 1 + 2 → ${street.name}'), findsOneWidget);
      expect(tester.getRect(_key('property-board')), boardAt);
    });

    testWidgets('after the landing: the compact deed card in the centre, the buy question below', (tester) async {
      await pumpAt(tester, dice: [1, 2]);
      await tapRoll(tester);
      await tester.pumpAndSettle();
      final sq = berlin.squares[3];
      String right(String key) => tester
          .widgetList<Text>(find.descendant(of: _key(key), matching: find.byType(Text)))
          .last
          .data!;
      expect(right('property-focus-deed-rent-0'), '${sq.rents[0]}');
      expect(right('property-focus-deed-rent-5'), '${sq.rents[5]}');
      expect(find.descendant(of: _key('property-focus-deed'), matching: find.text('Preis: ${sq.price} Taler')),
          findsOneWidget);
      expect(_key('property-focus-deed-now'), findsNothing, reason: 'unowned: no rent applies');
      // Inside the board centre, and the buy question stays on screen.
      final board = tester.getRect(_key('property-board'));
      final card = tester.getRect(_key('property-focus-deed'));
      expect(card.width, lessThanOrEqualTo(PropertyDeedCard.maxWidth + 0.1));
      expect(board.deflate(board.width / 11).contains(card.topLeft) && board.deflate(board.width / 11).contains(card.bottomRight),
          isTrue);
      expect(_key('property-buy').hitTestable(), findsOneWidget);
      // A tap opens the full card.
      await _tap(tester, 'property-focus');
      expect(_key('property-square-sheet'), findsOneWidget);
      expect(_key('property-deed-rent-group'), findsOneWidget);
    });

    testWidgets('the walk passes Start', (tester) async {
      await pumpAt(tester, pos: 38, dice: [1, 2]);
      await tapRoll(tester);
      await tester.pump(const Duration(milliseconds: dice + step ~/ 2 + 10));
      expect(_tokenOn(0, 39), isTrue);
      await tester.pump(const Duration(milliseconds: step));
      expect(_tokenOn(0, 0), isTrue, reason: 'over Start');
      await tester.pump(const Duration(milliseconds: step));
      expect(_tokenOn(0, 1), isTrue);
      await tester.pumpAndSettle();
      expect(_tokenOn(0, 1), isTrue);
      expect(find.textContaining('Startgeld'), findsOneWidget);
    });

    testWidgets('a tap on the dice or the board skips to the end', (tester) async {
      await pumpAt(tester, dice: [1, 2, 3, 3]);
      await tapRoll(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(_key('property-dice-rolling'));
      await tester.pump();
      expect(_key('property-dice-rolling'), findsNothing);
      expect(_tokenOn(0, 3), isTrue);
      expect(_key('property-buy'), findsOneWidget);
      // A tap on a square while the walk runs skips, it opens no sheet.
      await _tap(tester, 'property-buy');
      await _tap(tester, 'property-end');
      await tapRoll(tester);
      await tester.pump(const Duration(milliseconds: dice + 2 * step));
      expect(_key('property-walking-1'), findsOneWidget);
      await tester.tap(_key('property-square-25'));
      await tester.pump();
      expect(_key('property-square-sheet'), findsNothing);
      expect(_key('property-walking-1'), findsNothing);
      expect(_tokenOn(1, 6), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reduce motion: the result at once', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await pumpAt(tester, dice: [1, 2]);
      await tapRoll(tester);
      await tester.pump();
      expect(_key('property-dice-rolling'), findsNothing);
      expect(_key('property-rolling'), findsNothing);
      expect(_tokenOn(0, 3), isTrue);
      expect(_key('property-buy'), findsOneWidget);
    });

    testWidgets('undo after the roll (back to the question) shows no roll again', (tester) async {
      await UndoSettings.shared().setAllowed('property', true);
      final c = await pumpAt(tester, dice: [1, 2]);
      await tapRoll(tester);
      await tester.pumpAndSettle();
      await _tap(tester, 'property-buy');
      await tester.ensureVisible(find.byType(UndoMoveButton));
      await tester.tap(find.byType(UndoMoveButton));
      await tester.pump();
      expect(_key('property-dice-rolling'), findsNothing);
      expect(_key('property-rolling'), findsNothing);
      // (The undo replays from the seed, without the scripted dice.)
      final g = c.game as PropertyGame;
      expect(g.phase, PropertyPhase.buy);
      expect(_tokenOn(0, g.seats[0].pos), isTrue);
      expect(_key('property-buy'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    test("the pause in the theme's own words (German), else quoted", () {
      const ev = [{'type': 'toPause', 'seat': 0}];
      String name(int s) => 'Anna';
      expect(propertyNarration(deL10n, PropertyGame(), ev, 0, name), ['Anna muss in den Stau auf der A100']);
      expect(propertyNarration(deL10n, PropertyGame(theme: PropertyTheme.byId('fantasie')), ev, 0, name),
          ['Anna muss in die Auszeit']);
      expect(propertyNarration(enL10n, PropertyGame(), ev, 0, name), ['Anna has to go to “Stau auf der A100”']);
    });

    test('the path: a jump to the pause, a card back, a card "back to"', () {
      PropertyRollShow show(int from, List<Map<String, dynamic>> events) =>
          PropertyRollShow.of(seat: 0, from: from, events: events, theme: berlin)!;
      final pause = show(5, [
        {'type': 'rolled', 'dice': [2, 2]},
        {'type': 'threeDoubles'},
        {'type': 'toPause', 'seat': 0},
      ]);
      expect(pause.path, [5, PropertyGame.pauseSquare]);
      expect(pause.jumps, {1});
      final back = berlin.cards.firstWhere((c) => c.kind == PropertyCardKind.back);
      final b = show(5, [
        {'type': 'rolled', 'dice': [1, 1]},
        {'type': 'moved', 'to': 7},
        {'type': 'card', 'id': back.id},
        {'type': 'moved', 'to': (7 - back.value + 40) % 40},
      ]);
      expect(b.path, [5, 6, 7, for (var i = 1; i <= back.value; i++) (7 - i + 40) % 40]);
      expect(b.jumps, isEmpty);
      expect(PropertyRollShow.of(seat: 0, from: 3, events: const [{'type': 'bought'}], theme: berlin), isNull);
      expect(b.totalMs, PropertyRollShow.diceMs + (b.path.length - 1) * PropertyRollShow.stepMs);
    });
  });
}

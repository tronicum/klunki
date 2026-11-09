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
import 'package:klunki/ui/rules/rules_screen.dart';
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
}

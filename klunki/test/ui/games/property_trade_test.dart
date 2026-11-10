// KLD-060 step 3b: trades in Baulöwe through the real UI: "Tauschen", the
// trade sheet (partner, streets, money, free cards, live check by the
// engine), the handover to the partner, "Annehmen" / "Ablehnen", the
// handover back, the history, undo and the 3-offers limit.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/profile/seat_names.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  expect(_key(key), findsOneWidget, reason: key);
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

bool _enabled(WidgetTester tester, String key) {
  final w = tester.widget(_key(key));
  return switch (w) {
    ButtonStyleButton b => b.onPressed != null,
    IconButton b => b.onPressed != null,
    _ => throw StateError('not a button: $key'),
  };
}

Future<GameController> _pump(WidgetTester tester, GameConfig config,
    {void Function(PropertyGame g)? setup, List<int> dice = const []}) async {
  tester.view.physicalSize = const Size(390, 844) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  final g = c.game as PropertyGame;
  g.debugScriptDice(dice);
  setup?.call(g);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pumpAndSettle();
  return c;
}

String _text(WidgetTester tester, String key) => tester.widget<Text>(_key(key)).data!;

void main() {
  final berlin = PropertyTheme.berlin;
  // Two streets of the first group, one of the second, a station.
  final a1 = berlin.squares[1].name, a3 = berlin.squares[3].name, b6 = berlin.squares[6].name;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SeenTips.debugReset();
    SeenTips.shared.markFirst(SeenTips.propertyIntro);
    ExtraSeatNames.debugReset();
    UndoSettings.debugReset();
  });

  testWidgets('the sheet: nothing chosen is not an offer; the engine checks every change', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3), setup: (g) {
      g
        ..debugSetSquare(1, 0)
        ..debugSetSquare(6, 1);
    });
    expect(_key('property-trade'), findsOneWidget, reason: 'Anna may trade before rolling');
    await _tap(tester, 'property-trade');
    expect(_key('property-trade-sheet'), findsOneWidget);
    expect(find.text('Tausch anbieten'), findsOneWidget);
    expect(find.text('Noch 3 Angebote in diesem Zug'), findsOneWidget);
    // Two players: Ben is the partner already.
    expect(tester.widget<ChoiceChip>(_key('property-trade-partner-1')).selected, isTrue);
    expect(find.text('Du gibst'), findsOneWidget);
    expect(find.text('Du bekommst · Ben'), findsOneWidget);
    expect(_key('property-trade-give-1'), findsOneWidget);
    expect(_key('property-trade-get-6'), findsOneWidget);
    expect(_key('property-trade-get-1'), findsNothing, reason: 'only the owner\'s streets');
    expect(_text(tester, 'property-trade-problem'), 'Wähle aus, was ihr tauscht.');
    expect(_enabled(tester, 'property-trade-offer'), isFalse);

    await _tap(tester, 'property-trade-get-6');
    expect(_key('property-trade-problem'), findsNothing);
    expect(_enabled(tester, 'property-trade-offer'), isTrue);
    await _tap(tester, 'property-trade-get-6');
    expect(_enabled(tester, 'property-trade-offer'), isFalse, reason: 'unchosen again');
    expect(c.moves, isEmpty, reason: 'nothing sent yet');
  });

  testWidgets('streets with buildings in their group are shown, but cannot be chosen', (tester) async {
    await _pump(tester, const GameConfig('property', seed: 3), setup: (g) {
      g
        ..debugSetSquare(1, 1, houses: 1)
        ..debugSetSquare(3, 1, houses: 1)
        ..debugSetSquare(6, 1);
    });
    await _tap(tester, 'property-trade');
    expect(find.descendant(of: _key('property-trade-get-1'), matching: find.text('Gebäude in der Farbe: nicht tauschbar')),
        findsOneWidget);
    expect(find.descendant(of: _key('property-trade-get-6'), matching: find.text('Gebäude in der Farbe: nicht tauschbar')),
        findsNothing);
    await _tap(tester, 'property-trade-get-1');
    expect(_text(tester, 'property-trade-problem'), 'Wähle aus, was ihr tauscht.', reason: 'the tap chose nothing');
    expect(_enabled(tester, 'property-trade-offer'), isFalse);
  });

  testWidgets('money: steps, bounded by the cash, back to 0; free cards up to the cards held', (tester) async {
    await _pump(tester, const GameConfig('property', seed: 3), setup: (g) {
      g.debugSetCash(0, 125);
    });
    await _tap(tester, 'property-trade');
    expect(_text(tester, 'property-trade-give-money'), '0 Taler');
    expect(_enabled(tester, 'property-trade-give-money-minus-10'), isFalse);
    await _tap(tester, 'property-trade-give-money-plus-100');
    expect(_text(tester, 'property-trade-give-money'), '100 Taler');
    expect(_key('property-trade-problem'), findsNothing, reason: 'a gift is an offer too');
    await _tap(tester, 'property-trade-give-money-plus-50');
    expect(_text(tester, 'property-trade-give-money'), '125 Taler', reason: 'not more than Anna has');
    expect(_enabled(tester, 'property-trade-give-money-plus-10'), isFalse);
    await _tap(tester, 'property-trade-give-money-minus-10');
    expect(_text(tester, 'property-trade-give-money'), '115 Taler');
    await _tap(tester, 'property-trade-give-money-reset');
    expect(_text(tester, 'property-trade-give-money'), '0 Taler');
    // Ben's money is bounded by Ben's cash.
    for (var i = 0; i < 16; i++) {
      await _tap(tester, 'property-trade-get-money-plus-100');
    }
    expect(_text(tester, 'property-trade-get-money'), '1500 Taler');
    expect(_enabled(tester, 'property-trade-get-money-plus-10'), isFalse);
    // No free cards: no row for them.
    expect(_key('property-trade-give-cards'), findsNothing);
  });

  testWidgets('offer → the device to Ben → accept → back to Anna; no undo across the answer', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3), setup: (g) {
      g
        ..debugSetSquare(1, 0)
        ..debugSetSquare(3, 0, mortgaged: true)
        ..debugSetSquare(6, 1);
    });
    final g = c.game as PropertyGame;
    await _tap(tester, 'property-trade');
    await _tap(tester, 'property-trade-give-3');
    await _tap(tester, 'property-trade-give-money-plus-50');
    await _tap(tester, 'property-trade-get-6');
    await _tap(tester, 'property-trade-offer');
    expect(_key('property-trade-sheet'), findsNothing);
    expect(c.moves.single.move, {
      'action': 'tradeOffer',
      'to': 1,
      'give': {'money': 50, 'squares': [3]},
      'get': {'squares': [6]},
    });
    // The handover: the board is hidden, Ben must take the device.
    expect(_key('property-trade-cover'), findsOneWidget);
    expect(find.text('Tauschangebot von Anna an Ben'), findsOneWidget);
    expect(find.text('Gib das Gerät an Ben weiter'), findsOneWidget);
    expect(_key('property-board'), findsNothing, reason: 'the board is offstage');
    await _tap(tester, 'property-trade-handover');
    expect(_key('property-trade-cover'), findsNothing);
    // Ben sees the whole offer from his side.
    expect(_key('property-trade-answer'), findsOneWidget);
    expect(find.descendant(of: _key('property-trade-answer-give'), matching: find.text(b6)), findsOneWidget);
    expect(find.descendant(of: _key('property-trade-answer-get'), matching: find.text(a3)), findsOneWidget);
    expect(find.descendant(of: _key('property-trade-answer-get'), matching: find.text('50 Taler')), findsOneWidget);
    expect(_key('property-roll'), findsNothing);
    expect(_key('property-trade'), findsNothing, reason: 'no new offer while one waits');
    // "Brett ansehen": the board, a square's card, no other move; back to the offer.
    await _tap(tester, 'property-trade-show-board');
    expect(_key('property-trade-peek'), findsOneWidget);
    expect(_key('property-board'), findsOneWidget);
    expect(_key('property-trade-accept'), findsNothing, reason: 'answers only on the offer');
    expect(_key('property-trade-decline'), findsNothing);
    for (final k in ['property-roll', 'property-end', 'property-trade', 'shell-undo']) {
      expect(_key(k), findsNothing, reason: k);
    }
    expect(tester.widget<TextButton>(_key('property-manage')).onPressed, isNull);
    await _tap(tester, 'property-square-6');
    expect(_key('property-square-sheet'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(c.moves, hasLength(1), reason: 'looking is not a move');
    await _tap(tester, 'property-trade-show-offer');
    expect(_key('property-trade-peek'), findsNothing);
    await _tap(tester, 'property-trade-accept');
    expect([g.ownerOf(3), g.ownerOf(6), g.ownerOf(1)], [1, 0, 0]);
    expect(g.isMortgaged(3), isTrue, reason: 'a mortgaged street moves as it is');
    expect([g.seats[0].cash, g.seats[1].cash], [1450, 1550]);
    // Back to Anna.
    expect(_key('property-trade-cover'), findsOneWidget);
    expect(find.text('Ben nimmt den Tausch an'), findsOneWidget);
    expect(find.text('Gib das Gerät an Anna weiter'), findsOneWidget);
    await _tap(tester, 'property-trade-back');
    expect(_text(tester, 'property-cash-0'), '1450 Taler · 2 Straßen');
    expect(_text(tester, 'property-cash-1'), '1550 Taler · 1 Straße');
    expect(find.textContaining('Tauschangebot von Anna an Ben: $a3, 50 Taler gegen $b6'), findsOneWidget,
        reason: 'the story line');
    expect(c.canUndo, isFalse, reason: 'the answer is final');
    expect(_key('property-roll'), findsOneWidget, reason: 'Anna goes on with her turn');
    expect(_key('property-trade'), findsOneWidget);
    // History: offer and answer.
    await _tap(tester, 'shell-history');
    expect(find.text('Tauschangebot von Anna an Ben: $a3, 50 Taler gegen $b6'), findsOneWidget);
    expect(find.text('Ben nimmt den Tausch an'), findsOneWidget);
    expect(a1, isNotEmpty);
  });

  testWidgets('3 players: choose the partner; decline; the offer can be taken back before the handover',
      (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3, players: 3), setup: (g) {
      g
        ..debugSetSquare(6, 1)
        ..debugSetSquare(8, 2);
    });
    await _tap(tester, 'property-trade');
    expect(tester.widget<ChoiceChip>(_key('property-trade-partner-1')).selected, isFalse);
    expect(_key('property-trade-problem'), findsNothing);
    expect(_enabled(tester, 'property-trade-offer'), isFalse, reason: 'no partner yet');
    await _tap(tester, 'property-trade-partner-2');
    expect(_key('property-trade-get-8'), findsOneWidget);
    expect(_key('property-trade-get-6'), findsNothing);
    await _tap(tester, 'property-trade-get-8');
    // A change of partner clears the other side.
    await _tap(tester, 'property-trade-partner-1');
    expect(_text(tester, 'property-trade-problem'), 'Wähle aus, was ihr tauscht.');
    await _tap(tester, 'property-trade-partner-2');
    await _tap(tester, 'property-trade-get-8');
    await _tap(tester, 'property-trade-give-money-plus-100');
    await _tap(tester, 'property-trade-offer');
    expect(find.text('Gib das Gerät an Cleo weiter'), findsOneWidget);
    // Anna takes it back before passing the device.
    await _tap(tester, 'shell-undo');
    expect(c.moves, isEmpty);
    expect(_key('property-trade-cover'), findsNothing);
    // Undo builds a new engine from the moves (without the test setup).
    final g2 = c.game as PropertyGame;
    expect(g2.tradeOffersLeft, 3);
    g2
      ..debugSetSquare(6, 1)
      ..debugSetSquare(8, 2);
    await tester.pumpAndSettle();

    await _tap(tester, 'property-trade');
    await _tap(tester, 'property-trade-partner-2');
    await _tap(tester, 'property-trade-get-8');
    await _tap(tester, 'property-trade-offer');
    await _tap(tester, 'property-trade-handover');
    await _tap(tester, 'property-trade-decline');
    expect(g2.ownerOf(8), 2);
    expect(find.text('Cleo lehnt den Tausch ab'), findsOneWidget);
    await _tap(tester, 'property-trade-back');
    expect(c.canUndo, isFalse);
    expect(find.textContaining('Cleo lehnt den Tausch ab'), findsOneWidget, reason: 'the story line');
  });

  testWidgets('at most 3 offers a turn; after rolling still possible; a new turn has 3 again', (tester) async {
    final c = await _pump(tester, const GameConfig('property', seed: 3), dice: [2, 2, 1, 3, 1, 3], setup: (g) {
      g.debugSetSquare(6, 1);
    });
    final g = c.game as PropertyGame;
    Future<void> offerAndDecline() async {
      await _tap(tester, 'property-trade');
      await _tap(tester, 'property-trade-get-6');
      await _tap(tester, 'property-trade-offer');
      await _tap(tester, 'property-trade-handover');
      await _tap(tester, 'property-trade-decline');
      await _tap(tester, 'property-trade-back');
    }

    await offerAndDecline();
    await _tap(tester, 'property-trade');
    expect(find.text('Noch 2 Angebote in diesem Zug'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await offerAndDecline();
    // Roll (doubles 2+2: Anna rolls again), then the third offer.
    await _tap(tester, 'property-roll');
    if (g.phase == PropertyPhase.buy) await _tap(tester, 'property-decline');
    while (g.phase == PropertyPhase.auction) {
      await _tap(tester, 'property-pass');
    }
    expect(g.currentSeat, 0);
    await offerAndDecline();
    expect(g.tradeOffersLeft, 0);
    expect(_key('property-trade'), findsNothing, reason: 'no offers left this turn');
    expect(c.moves.where((m) => m.move['action'] == 'tradeOffer'), hasLength(3));
    // Anna's turn ends; Ben has 3 offers.
    await _tap(tester, 'property-roll');
    if (g.phase == PropertyPhase.buy) await _tap(tester, 'property-decline');
    while (g.phase == PropertyPhase.auction) {
      await _tap(tester, 'property-pass');
    }
    await _tap(tester, 'property-end');
    expect(g.currentSeat, 1);
    expect(g.tradeOffersLeft, 3);
    expect(_key('property-trade'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

const feedback = Key('qs-feedback');
const feedbackText = Key('qs-feedback-text');
const cont = Key('qs-continue');
Key handKey(String id) => Key('qs-hand-$id');
Key askKey(String id) => Key('qs-ask-$id');

/// Same construction as the registry entry for `quartett-sets`.
QuartettGame fresh(int seed) => QuartettGame(QuartettMode.sets, seed: seed, handSize: 8);

Set<String> ids(Iterable<dynamic> cards) => {for (final c in cards) c.id as String};

/// First (seed, card) where X's opening ask for card satisfies [test].
(int, String) findOpening(bool Function(QuartettGame g, String card) test) {
  for (var seed = 1; seed < 5000; seed++) {
    final g = fresh(seed);
    if (g.isOver || g.currentPlayer != Player.a) continue;
    for (final m in g.legalMoves) {
      final card = m['card'] as String;
      if (test(g, card)) return (seed, card);
    }
  }
  throw StateError('no matching seed');
}

bool oppHolds(QuartettGame g, String card) => ids(g.handOf(Player.b)).contains(card);

Future<void> ask(WidgetTester tester, String card) async {
  await tester.ensureVisible(find.byKey(askKey(card)));
  await tester.tap(find.byKey(askKey(card)));
  await tester.pump();
  await tester.pump();
}

void expectNoCardsInTree(QuartettGame g) {
  for (final p in Player.values) {
    for (final card in g.handOf(p)) {
      expect(find.byKey(handKey(card.id), skipOffstage: false), findsNothing);
      expect(find.text(card.id, skipOffstage: false), findsNothing);
      expect(find.text(card.name, skipOffstage: false), findsNothing);
    }
  }
}

void main() {
  testWidgets('shows only the active hand, grouped by set, plus public info', (tester) async {
    final c = await pumpGame(tester, 'quartett-sets', seed: 1);
    await tester.pump(); // hint is set post-frame
    final g = c.game as QuartettGame;
    expect(g.currentPlayer, Player.a);
    final own = g.handOf(Player.a), opp = g.handOf(Player.b);
    final ownSets = {for (final card in own) card.set};

    for (final card in own) {
      expect(find.byKey(handKey(card.id), skipOffstage: false), findsOneWidget);
    }
    for (final s in ownSets) {
      expect(find.byKey(Key('qs-set-$s'), skipOffstage: false), findsOneWidget);
    }
    for (final card in opp) {
      expect(find.byKey(handKey(card.id), skipOffstage: false), findsNothing);
      expect(find.text(card.name, skipOffstage: false), findsNothing);
      // Cards of sets X does not hold do not appear at all (not even as a slot).
      if (!ownSets.contains(card.set)) expect(find.text(card.id, skipOffstage: false), findsNothing);
    }
    // Every legal ask has a tappable missing slot.
    for (final m in g.legalMoves) {
      expect(find.byKey(askKey(m['card'] as String), skipOffstage: false), findsOneWidget);
    }

    expect(find.text('O: ${opp.length} Karten'), findsOneWidget);
    expect(find.text('Stapel: ${g.stockSize} Karten'), findsOneWidget);
    expect(
        find.text('Quartette X ${g.quartetsOf(Player.a).length} : ${g.quartetsOf(Player.b).length} O'), findsOneWidget);
    expect(find.text('Tippe auf eine fehlende Karte, um danach zu fragen'), findsOneWidget);
  });

  testWidgets('a hit keeps the same player and moves the card over', (tester) async {
    final (seed, card) = findOpening((g, card) => oppHolds(g, card));
    final c = await pumpGame(tester, 'quartett-sets', seed: seed);
    await ask(tester, card);

    expect(c.moves, hasLength(1));
    expect(c.game.currentPlayer, Player.a);
    expect(c.needsHandover, isFalse);
    expect(find.byKey(handoverContinue), findsNothing);
    expect(find.text('Treffer! O gibt dir $card'), findsOneWidget);
    if (c.moves.last.event.payload['quartet'] == null) {
      expect(find.byKey(handKey(card), skipOffstage: false), findsOneWidget);
    }
    expect(find.text('X ist am Zug'), findsOneWidget);
  });

  testWidgets('a hit that completes a set announces the quartet', (tester) async {
    final (seed, card) = findOpening((g, card) =>
        oppHolds(g, card) && g.handOf(Player.a).where((c) => c.set == card[0]).length == 3);
    final c = await pumpGame(tester, 'quartett-sets', seed: seed);
    final set = card[0];
    await ask(tester, card);

    final name = localizedSetName(deL10n, set);
    expect(find.text('Quartett! $name abgelegt'), findsOneWidget);
    expect((c.game as QuartettGame).quartetsOf(Player.a), contains(set));
    expect(find.descendant(of: find.byKey(const Key('qs-quartets-a')), matching: find.text('$set $name')),
        findsOneWidget);
    expect(find.byKey(Key('qs-set-$set'), skipOffstage: false), findsNothing);
  });

  testWidgets('a miss shows the drawn card to the asker, then "Weiter" leads to the cover', (tester) async {
    final (seed, card) = findOpening((g, card) => !oppHolds(g, card) && g.stockSize > 0);
    final c = await pumpGame(tester, 'quartett-sets', seed: seed);

    await ask(tester, card);
    // Not submitted yet: the asker sees the feedback first.
    expect(c.moves, isEmpty);
    expect(c.needsHandover, isFalse);
    expect(find.text('Fehlanzeige – du ziehst eine Karte'), findsOneWidget);
    expect(find.byKey(const Key('qs-drawn-card')), findsOneWidget);
    final drew = tester.widget<QuartettCard>(find.byKey(const Key('qs-drawn-card'))).card!;
    final copy = fresh(seed);
    final ev = copy.applyMove({'action': 'ask', 'card': card})!;
    expect(drew.id, ev.payload['drew']);
    // Asking is disabled while the feedback is pending.
    final other = (c.game as QuartettGame).legalMoves.map((m) => m['card'] as String).firstWhere((x) => x != card,
        orElse: () => card);
    await tester.ensureVisible(find.byKey(askKey(other)));
    await tester.tap(find.byKey(askKey(other)));
    await tester.pump();
    expect(find.text('Fehlanzeige – du ziehst eine Karte'), findsOneWidget);

    await tester.ensureVisible(find.byKey(cont));
    await tester.tap(find.byKey(cont));
    await tester.pump();
    await tester.pump();
    expect(c.moves, hasLength(1));
    expect(c.game.currentPlayer, Player.b);
    expect(find.byKey(handoverContinue), findsOneWidget);
    expectNoCardsInTree(c.game as QuartettGame);

    await tester.tap(find.byKey(handoverContinue));
    await tester.pump();
    await tester.pump();
    final g = c.game as QuartettGame;
    for (final card in g.handOf(Player.b)) {
      expect(find.byKey(handKey(card.id), skipOffstage: false), findsOneWidget);
    }
    for (final card in g.handOf(Player.a)) {
      expect(find.byKey(handKey(card.id), skipOffstage: false), findsNothing);
    }
    expect(find.byKey(feedback), findsNothing);
    expect(find.text('O ist am Zug'), findsOneWidget);
  });

  testWidgets('history describes asks without the drawn card', (tester) async {
    final (seed, card) = findOpening((g, card) => !oppHolds(g, card) && g.stockSize > 0);
    final c = await pumpGame(tester, 'quartett-sets', seed: seed);
    await ask(tester, card);
    await tester.ensureVisible(find.byKey(cont));
    await tester.tap(find.byKey(cont));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(handoverContinue));
    await tester.pump();
    await tester.tap(find.byKey(const Key('shell-history')));
    await tester.pumpAndSettle();
    final drew = c.moves.single.event.payload['drew'] as String;
    final sheet = find.byKey(const Key('history-sheet'));
    expect(find.descendant(of: sheet, matching: find.textContaining('X: fragt nach $card: Fehlanzeige')),
        findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.textContaining(drew)), findsNothing);
  });

  testWidgets('plays to the end through the UI, then the result dialog shows', (tester) async {
    final c = await pumpGame(tester, 'quartett-sets', seed: 7);
    var asks = 0;
    for (var i = 0; i < 1000; i++) {
      if (find.byKey(resultDialog).evaluate().isNotEmpty) break;
      if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(handoverContinue));
        await tester.pump();
        await tester.pump();
        continue;
      }
      if (find.byKey(cont).evaluate().isNotEmpty) {
        await tester.ensureVisible(find.byKey(cont));
        await tester.tap(find.byKey(cont));
        await tester.pump();
        await tester.pump();
        continue;
      }
      final g = c.game as QuartettGame;
      // Only the player to move sees their hand.
      final opp = g.currentPlayer == Player.a ? Player.b : Player.a;
      expect(find.byKey(handKey(g.handOf(opp).isEmpty ? 'none' : g.handOf(opp).first.id), skipOffstage: false),
          findsNothing);
      await ask(tester, g.legalMoves.first['card'] as String);
      asks++;
    }
    await tester.pumpAndSettle();
    expect(find.byKey(resultDialog), findsOneWidget);
    expect(c.game.isOver, isTrue);
    expect(asks, c.moves.length);
    final g = c.game as QuartettGame;
    expect(g.quartetsOf(Player.a).length + g.quartetsOf(Player.b).length, 8);
    expect(find.text(localizedResultReason(deL10n, c.game.result)), findsOneWidget);
  });
}

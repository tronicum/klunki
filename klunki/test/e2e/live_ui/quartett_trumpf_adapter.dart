// Quartett (Trumpf) adapter for the live UI driver (KLD-089).
//
// Reads what a QuartettTrumpfScreen shows (the reveal's "X wählt PS", the
// headline, both revealed cards; the own card on the table and its caption)
// and plays by tapping `qt-stat-<id>` on the own card, "Weiter"
// (`qt-continue`) and, as a fidget, "Letzter Stich".
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki/ui/shell/game_screen.dart' show playerMark;
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/klunki_engine.dart' as qe show Card;

import '../../l10n/l10n_test_utils.dart';
import 'live_ui_driver.dart';

const _reveal = Key('qt-reveal');
const _cont = Key('qt-continue');
const _ownCard = Key('qt-own-card');
const _lastTrick = Key('qt-last-trick');
const _overlay = Key('qt-last-trick-overlay');
const _overlayClose = Key('qt-last-trick-close');
const _result = Key('result-dialog');

String _outcome(Player? winner) => winner == null ? 'tie' : '${playerMark(winner)} wins';

/// The stat in which [card] ranks best within [deck]: what a player who only
/// sees their own card would pick.
String strongestStat(QuartettDeck deck, qe.Card card) {
  var best = deck.stats.first.id;
  var bestBeaten = -1;
  for (final s in deck.stats) {
    final v = card.stats[s.id]!;
    final beaten = deck.cards.where((o) => s.beats(v, o.stats[s.id]!)).length;
    if (beaten > bestBeaten) {
      bestBeaten = beaten;
      best = s.id;
    }
  }
  return best;
}

class QuartettTrumpfAdapter extends LiveUiAdapter {
  @override
  String get gameId => 'quartett-trumpf';

  final _picked = RegExp(r'^(X|O) wählt (.+)$');

  @override
  TurnRecord? observe(WidgetTester tester, UiDevice d, Game engine, {required bool inSync}) {
    final g = engine as QuartettGame;
    final reveal = d.on(find.byKey(_reveal));
    if (reveal.evaluate().isNotEmpty) {
      Finder inReveal(Finder f) => find.descendant(of: reveal, matching: f);
      // "X wählt PS"
      final texts = [for (final e in inReveal(find.byType(Text)).evaluate()) (e.widget as Text).data ?? ''];
      final picks = [for (final t in texts) ?_picked.firstMatch(t)];
      expect(picks, hasLength(1), reason: '${d.name}: one "… wählt …" line in the reveal: $texts');
      final picker = picks.single.group(1) == 'X' ? Player.a : Player.b;
      final label = picks.single.group(2)!;
      final stats = [for (final s in g.deck.stats) if (localizedStatLabel(deL10n, s.id) == label) s.id];
      expect(stats, hasLength(1), reason: '${d.name}: stat label "$label" in deck ${g.deck.id}');
      // Headline: who won.
      final headline = tester.widget<Text>(inReveal(find.byKey(const Key('qt-reveal-text')))).data!;
      final Player? winner = switch (headline) {
        _ when headline == deL10n.quartettTrumpfWinsTrick('X') => Player.a,
        _ when headline == deL10n.quartettTrumpfWinsTrick('O') => Player.b,
        _ when headline == deL10n.quartettTrumpfTie => null,
        _ => throw TestFailure('${d.name}: unknown headline "$headline"'),
      };
      // Both cards as revealed (X's card under qt-reveal-a).
      String cardId(String side) => tester.widget<QuartettCard>(inReveal(find.byKey(Key('qt-reveal-$side')))).card!.id;
      return TurnRecord(
        index: 0,
        actor: picker,
        action: stats.single,
        outcome: _outcome(winner),
        detail: 'X:${cardId('a')} O:${cardId('b')}',
        nextActor: winner ?? picker,
      );
    }
    final own = d.on(find.byKey(_ownCard));
    if (own.evaluate().isNotEmpty && inSync && !g.isOver) {
      // Whose card is up: the device's player, or (hot-seat) the player to move.
      final viewer = d.me ?? g.currentPlayer;
      final shown = tester.widget<QuartettCard>(own).card!;
      expect(shown.id, g.topCard(viewer)!.id,
          reason: '${d.name}: the table shows ${playerMark(viewer)}\'s top card');
      expect(d.has(find.text(deL10n.quartettTrumpfYourCard(playerMark(viewer)))), isTrue,
          reason: '${d.name}: caption names ${playerMark(viewer)}');
      if (d.networked && g.currentPlayer != d.me) {
        // The status line names the picker ("Warte auf Anna (X)…").
        final mark = playerMark(g.currentPlayer);
        final status = tester.widget<Text>(d.on(find.byKey(const Key('shell-status')))).data!;
        expect(status, contains('($mark)'), reason: '${d.name}: the status names $mark as the picker');
      }
    }
    return null;
  }

  bool _blocked(UiDevice d) => d.dialogOpen || d.hasKey(const Key('handover-cover'));

  @override
  Future<String?> tidy(WidgetTester tester, UiDevice d) async {
    if (!_overlayReady(tester, d) || !_endgame(d, tester)) return null;
    await d.tapKey(tester, _overlayClose);
    await _settle(tester);
    return 'closes Letzter Stich (endgame)';
  }

  @override
  Future<bool> dismiss(WidgetTester tester, UiDevice d) async {
    if (_blocked(d) || !d.hasKey(_cont)) return false;
    await d.tapKey(tester, _cont);
    return true;
  }

  @override
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice d, Random rng) async {
    if (_blocked(d) || d.hasKey(_reveal)) return null;
    final own = d.on(find.byKey(_ownCard));
    if (own.evaluate().isEmpty) return null;
    final card = tester.widget<QuartettCard>(own);
    if (!card.enabled || !d.controller(tester).canAct) return null;
    final deck = (d.controller(tester).game as QuartettGame).deck;
    final stat = rng.nextBool() ? deck.stats[rng.nextInt(deck.stats.length)].id : strongestStat(deck, card.card!);
    await d.tapKey(tester, Key('qt-stat-$stat'));
    return {'action': 'pick', 'stat': stat};
  }

  /// The "Letzter Stich" overlay is fully open (not animating).
  bool _overlayReady(WidgetTester tester, UiDevice d) =>
      d.hasKey(_overlay) &&
      !d.hasKey(_result) &&
      !d.has(find.ancestor(of: find.byKey(_overlay), matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring)));

  /// Few cards left: the game may end soon. A user peeking now would close
  /// the overlay before the result dialog covers it.
  bool _endgame(UiDevice d, WidgetTester tester) {
    final g = d.controller(tester).game as QuartettGame;
    return g.isOver || g.stackSize(Player.a) < 4 || g.stackSize(Player.b) < 4;
  }

  Future<void> _settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100)); // dialog transition
    }
  }

  @override
  Future<String?> fidget(WidgetTester tester, UiDevice d, Random rng) async {
    if (d.hasKey(_overlay)) {
      if (!_overlayReady(tester, d)) return null;
      await d.tapKey(tester, _overlayClose);
      await _settle(tester);
      return 'closes Letzter Stich';
    }
    if (_blocked(d) || !d.hasKey(_lastTrick) || _endgame(d, tester)) return null;
    if (tester.widget<ActionChip>(d.on(find.byKey(_lastTrick))).onPressed == null) return null;
    await d.tapKey(tester, _lastTrick);
    await _settle(tester);
    return 'opens Letzter Stich';
  }

  @override
  List<TurnRecord> engineTurns(GameController c) => [
        for (final (i, m) in c.moves.indexed)
          if (m.event.payload case {'stat': final String stat, 'cards': final Map cards, 'trickWinner': final w})
            TurnRecord(
              index: i,
              actor: m.player,
              action: stat,
              outcome: _outcome(w == null ? null : Player.values.byName(w as String)),
              detail: 'X:${cards['a']} O:${cards['b']}',
              nextActor: w == null ? m.player : Player.values.byName(w as String),
              source: 'engine',
            ),
      ];
}

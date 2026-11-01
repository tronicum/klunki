// Quartett (Trumpf) adapter for the live UI driver (KLD-089).
//
// Reads what a QuartettTrumpfScreen shows (the reveal's "Anna wählt PS", the
// headline, both revealed cards; the own card on the table and its caption)
// and plays by tapping `qt-stat-<id>` on the own card, "Weiter"
// (`qt-continue`) and, as a fidget, "Vorige Runde". KLD-100 (on by default):
// with 2–3 cards it taps one of the face-up cards (`qt-choose-<id>`), as the
// picker before its pick and as the defender for the announced stat.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
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
const _choose = Key('qt-choose');
const _chooseHint = Key('qt-choose-hint');

/// The player as the texts name it (KLD-103): the default names, which
/// the live network devices use too.
String _name(Player p) => p == Player.a ? 'Anna' : 'Ben';

String _outcome(Player? winner) => winner == null ? 'tie' : '${_name(winner)} wins';

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

  final _picked = RegExp(r'^(Anna|Ben) wählt (.+)$');

  @override
  TurnRecord? observe(WidgetTester tester, UiDevice d, Game engine, {required bool inSync}) {
    final g = engine as QuartettGame;
    final reveal = d.on(find.byKey(_reveal));
    if (reveal.evaluate().isNotEmpty) {
      Finder inReveal(Finder f) => find.descendant(of: reveal, matching: f);
      // "Anna wählt PS": exactly one such line (the cue "Anna wählt noch einmal"
      // / "Ben wählt als Nächstes" names no stat), and it is the picked line.
      final texts = [for (final e in inReveal(find.byType(Text)).evaluate()) (e.widget as Text).data ?? ''];
      final labels = {for (final s in g.deck.stats) localizedStatLabel(deL10n, s.id): s.id};
      final picks = [
        for (final t in texts)
          if (_picked.firstMatch(t) case final m? when labels.containsKey(m.group(2))) m,
      ];
      expect(picks, hasLength(1), reason: '${d.name}: one "… wählt <stat>" line in the reveal: $texts');
      expect(tester.widget<Text>(inReveal(find.byKey(const Key('qt-reveal-picked')))).data, picks.single.group(0));
      final picker = picks.single.group(1) == 'Anna' ? Player.a : Player.b;
      final label = picks.single.group(2)!;
      final stats = [for (final s in g.deck.stats) if (localizedStatLabel(deL10n, s.id) == label) s.id];
      expect(stats, hasLength(1), reason: '${d.name}: stat label "$label" in deck ${g.deck.id}');
      // Headline: who won.
      final headline = tester.widget<Text>(inReveal(find.byKey(const Key('qt-reveal-text')))).data!;
      final Player? winner = switch (headline) {
        _ when headline == deL10n.quartettTrumpfWinsTrick('Anna') => Player.a,
        _ when headline == deL10n.quartettTrumpfWinsTrick('Ben') => Player.b,
        _ when headline == deL10n.quartettTrumpfTie => null,
        _ => throw TestFailure('${d.name}: unknown headline "$headline"'),
      };
      // KLD-091: the cue names who picks next, and so does "Weiter".
      final next = winner ?? picker;
      final cue = tester.widget<Text>(inReveal(find.byKey(const Key('qt-next-picker')))).data!;
      final pm = _name(picker);
      if (winner == null) {
        expect(_potAgain(cue, pm), isTrue, reason: '${d.name}: tie cue "$cue" says $pm picks again');
      } else if (winner == picker) {
        expect(cue, deL10n.quartettTrumpfPicksAgain(pm), reason: '${d.name}: the picker won');
      } else {
        expect(cue, deL10n.quartettTrumpfNextPicker(_name(winner)), reason: '${d.name}: the other player won');
      }
      final button = tester.widget<Text>(find.descendant(of: d.on(find.byKey(_cont)), matching: find.byType(Text))).data;
      expect(button, deL10n.quartettTrumpfContinuePicker(_name(next)), reason: '${d.name}: "Weiter" names the next picker');
      // Both cards as revealed (X's card under qt-reveal-a).
      String cardId(String side) => tester.widget<QuartettCard>(inReveal(find.byKey(Key('qt-reveal-$side')))).card!.id;
      return TurnRecord(
        index: 0,
        actor: picker,
        action: stats.single,
        outcome: _outcome(winner),
        detail: 'Anna:${cardId('a')} Ben:${cardId('b')}',
        nextActor: winner ?? picker,
      );
    }
    final choose = d.on(find.byKey(_choose));
    if (choose.evaluate().isNotEmpty && inSync && !g.isOver) {
      // KLD-100: exactly the chooser's own stack, face-up; the hint says why.
      final viewer = d.me ?? g.currentPlayer;
      expect(g.currentPlayer, viewer, reason: '${d.name}: only the player to act chooses');
      expect(g.mustChoose, isTrue, reason: '${d.name}: the choose view only when a choice is due');
      expect(_shownChoices(tester, choose), [for (final c in g.stackOf(viewer)) c.id],
          reason: '${d.name}: ${_name(viewer)} sees its own cards');
      final hint = tester.widget<Text>(d.on(find.byKey(_chooseHint))).data!;
      final stat = g.announcedStat;
      expect(
          hint,
          stat == null
              ? deL10n.quartettTrumpfChooseOwn(g.stackSize(viewer))
              : endsWith(deL10n.quartettTrumpfChooseDefend('', localizedStatLabel(deL10n, stat.id)).trim()),
          reason: '${d.name}: choose hint');
      if (stat != null) defenderViews++;
    }
    final own = d.on(find.byKey(_ownCard));
    if (own.evaluate().isNotEmpty && inSync && !g.isOver) {
      // Whose card is up: the device's player, or (hot-seat) the player to
      // move; the chosen card once a low player chose (KLD-100).
      final viewer = d.me ?? g.currentPlayer;
      final shown = tester.widget<QuartettCard>(own).card!;
      expect(shown.id, g.playedCard(viewer)!.id,
          reason: '${d.name}: the table shows ${_name(viewer)}\'s card');
      expect(d.has(find.text(deL10n.quartettTrumpfYourCard(_name(viewer)))), isTrue,
          reason: '${d.name}: caption names ${_name(viewer)}');
      if (d.networked && g.currentPlayer != d.me) {
        // The status line names the picker ("Warte auf Anna…").
        final name = _name(g.currentPlayer);
        final status = tester.widget<Text>(d.on(find.byKey(const Key('shell-status')))).data!;
        expect(status, contains(name), reason: '${d.name}: the status names $name as the picker');
      }
    }
    return null;
  }

  /// The card ids of the choose view, in order.
  List<String> _shownChoices(WidgetTester tester, Finder choose) => [
        for (final w in tester.widgetList<QuartettCard>(find.descendant(of: choose, matching: find.byType(QuartettCard))))
          w.card!.id,
      ];

  /// KLD-100: how often a device tapped a card to choose it, and how often
  /// the defender's choose view (after an announced stat) was checked.
  int chooseTaps = 0;
  int defenderViews = 0;

  /// "Karten in den Topf (jetzt n), Anna wählt noch einmal" for some pot size n >= 2.
  bool _potAgain(String cue, String mark) => [
        for (var n = 2; n <= 64; n++) deL10n.quartettTrumpfPotAgain(n, mark),
      ].contains(cue);

  static const _badge = Key('shell-status-badge');

  String _status(WidgetTester tester, UiDevice d) =>
      tester.widget<Text>(d.on(find.byKey(const Key('shell-status')))).data!;

  /// KLD-091, network: while newer tricks are queued behind the one shown,
  /// the status line describes the shown one ("Anna wählt als
  /// Nächstes" / "Du wählst als Nächstes (O)") with "noch n Runden";
  /// otherwise it is the live status and there is no badge.
  ///
  /// KLD-092, hot-seat: while a result is shown (applied only on "Weiter")
  /// the status line uses the cue's words ("Ben wählt als Nächstes" / "Anna
  /// wählt noch einmal"), never the live "Anna ist am Zug"; no badge.
  @override
  void checkShown(WidgetTester tester, UiDevice d, TurnRecord shown, {required int behind}) {
    final status = _status(tester, d);
    final badge = d.on(find.descendant(of: find.byKey(_badge), matching: find.byType(Text)));
    if (!d.networked) {
      expect(badge, findsNothing, reason: '${d.name}: no badge in hot-seat ($shown)');
      final next = shown.nextActor!;
      final mark = _name(next);
      String words(String label) =>
          next == shown.actor ? deL10n.quartettTrumpfPicksAgain(label) : deL10n.quartettTrumpfNextPicker(label);
      expect(status, anyOf(words(mark), endsWith(words('($mark)'))),
          reason: '${d.name}: hot-seat status follows the result $shown');
      hotSeatStatusChecks++;
      return;
    }
    if (behind <= 0) {
      expect(badge, findsNothing, reason: '${d.name}: no badge on the newest trick ($shown)');
      final followsReveal = status.endsWith(deL10n.quartettTrumpfNextPicker('')) ||
          Player.values.any((p) => status == deL10n.quartettTrumpfYouPickNext(playerMark(p)));
      expect(followsReveal, isFalse, reason: '${d.name}: live status on the newest trick, got "$status"');
      return;
    }
    expect(d.networked, isTrue, reason: '${d.name}: queued tricks only on a network device');
    final next = shown.nextActor!;
    if (next == d.me) {
      expect(status, deL10n.quartettTrumpfYouPickNext(playerMark(next)), reason: '${d.name}: status follows $shown');
    } else {
      expect(status, deL10n.quartettTrumpfNextPicker(_name(next)),
          reason: '${d.name}: status follows $shown ($behind behind)');
    }
    expect(tester.widget<Text>(badge).data, deL10n.quartettTrumpfTricksBehind(behind),
        reason: '${d.name}: badge counts the $behind queued trick(s)');
    queuedChecks++;
  }

  /// How often [checkShown] saw a trick with newer ones queued behind it.
  int queuedChecks = 0;

  /// How often [checkShown] checked the status line under a hot-seat result.
  int hotSeatStatusChecks = 0;

  /// Hot-seat (KLD-091): a cover only when the device changes hands, and it
  /// says why: the player on turn won the last trick, or (KLD-100) the
  /// defender chooses its card for the announced stat, or the defender's
  /// choice tied and the picker picks again.
  @override
  void checkCover(WidgetTester tester, UiDevice d, GameController c) {
    final g = c.game as QuartettGame;
    final next = g.currentPlayer;
    final last = c.moves.last;
    expect(last.player, isNot(next), reason: '${d.name}: a cover only when the other player acts');
    final payload = last.event.payload as Map;
    final reason = tester.widget<Text>(d.on(find.byKey(const Key('qt-handover-reason')))).data;
    if (payload['announced'] == true) {
      expect(reason, deL10n.quartettTrumpfChooseDefend(_name(g.picker), localizedStatLabel(deL10n, '${payload['stat']}')),
          reason: '${d.name}: the cover names the stat the defender chooses for');
      defenderCovers++;
    } else if (payload['trickWinner'] == null) {
      expect(payload['picker'], next.name, reason: "${d.name}: a tie the defender's choice completed");
      expect(reason, deL10n.quartettTrumpfPicksAgain(_name(next)), reason: '${d.name}: the cover says why');
    } else {
      expect(payload['trickWinner'], next.name);
      expect(reason, deL10n.quartettTrumpfHandoverReason(_name(next)), reason: '${d.name}: the cover says why');
    }
  }

  /// KLD-100: hot-seat covers before the defender's choice.
  int defenderCovers = 0;

  /// Hot-seat: exactly one cover per change of picker (none on a winner
  /// streak or a tie, none after the final trick).
  @override
  void checkCovers(List<int> coversAt, GameController c, String context) {
    final m = c.moves;
    expect(coversAt, [
      for (var i = 0; i + 1 < m.length; i++)
        if (m[i + 1].player != m[i].player) i + 1,
    ], reason: '$context: covers at these move counts');
  }

  bool _blocked(UiDevice d) => d.dialogOpen || d.hasKey(const Key('handover-cover'));

  @override
  Future<String?> tidy(WidgetTester tester, UiDevice d) async {
    if (!_overlayReady(tester, d) || !_endgame(d, tester)) return null;
    await d.tapKey(tester, _overlayClose);
    await _settle(tester);
    return 'closes Vorige Runde (endgame)';
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
    final choose = d.on(find.byKey(_choose));
    if (choose.evaluate().isNotEmpty) {
      // KLD-100: choose one of the own 2–3 cards: the best for the announced
      // stat (defender) or the one with the strongest stat (picker), or any.
      final c = d.controller(tester);
      if (!c.canAct) return null;
      final g = c.game as QuartettGame;
      final cards = [
        for (final w in tester.widgetList<QuartettCard>(find.descendant(of: choose, matching: find.byType(QuartettCard))))
          w.card!,
      ];
      final stat = g.announcedStat;
      double rank(qe.Card card, QuartettStat s) =>
          g.deck.cards.where((o) => s.beats(card.stats[s.id]!, o.stats[s.id]!)).length.toDouble();
      double strength(qe.Card card) =>
          stat != null ? rank(card, stat) : g.deck.stats.map((s) => rank(card, s)).reduce(max);
      final card = rng.nextBool()
          ? cards[rng.nextInt(cards.length)]
          : cards.reduce((x, y) => strength(y) > strength(x) ? y : x);
      await d.tapKey(tester, Key('qt-choose-${card.id}'));
      chooseTaps++;
      return {'action': 'choose', 'card': card.id};
    }
    final own = d.on(find.byKey(_ownCard));
    if (own.evaluate().isEmpty) return null;
    final card = tester.widget<QuartettCard>(own);
    if (!card.enabled || !d.controller(tester).canAct) return null;
    final deck = (d.controller(tester).game as QuartettGame).deck;
    final stat = rng.nextBool() ? deck.stats[rng.nextInt(deck.stats.length)].id : strongestStat(deck, card.card!);
    await d.tapKey(tester, Key('qt-stat-$stat'));
    return {'action': 'pick', 'stat': stat};
  }

  /// The "Vorige Runde" overlay is fully open (not animating).
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
      return 'closes Vorige Runde';
    }
    if (_blocked(d) || !d.hasKey(_lastTrick) || _endgame(d, tester)) return null;
    if (tester.widget<ActionChip>(d.on(find.byKey(_lastTrick))).onPressed == null) return null;
    await d.tapKey(tester, _lastTrick);
    await _settle(tester);
    return 'opens Vorige Runde';
  }

  /// The picker of the round [m] completed: the mover, or (KLD-100, the
  /// defender's choice completed it) the one the payload names.
  static Player _pickerOf(AcceptedMove m) {
    final named = (m.event.payload as Map)['picker'];
    return named is String ? Player.values.byName(named) : m.player;
  }

  @override
  List<TurnRecord> engineTurns(GameController c) => [
        for (final (i, m) in c.moves.indexed)
          if (m.event.payload case {'stat': final String stat, 'cards': final Map cards, 'trickWinner': final w})
            if (_pickerOf(m) case final picker)
              TurnRecord(
                index: i,
                actor: picker,
                action: stat,
                outcome: _outcome(w == null ? null : Player.values.byName(w as String)),
                detail: 'Anna:${cards['a']} Ben:${cards['b']}',
                nextActor: w == null ? picker : Player.values.byName(w as String),
                source: 'engine',
              ),
      ];
}

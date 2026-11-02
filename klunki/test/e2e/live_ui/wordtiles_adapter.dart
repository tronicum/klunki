// Word tile adapter for the live UI driver (KLD-094 step 2).
//
// Reads the last turn a WordTilesScreen shows: the line under the score bar
// (`wordtiles-last-turn`, "X: HAUS für 8 Punkte"), the challenge banner
// (`wordtiles-open`, "X legte HAUS für 8 Punkte.") or the handover cover
// (`wordtiles-cover-turn`). Plays like a user: answers an open placement
// (sometimes challenging it), then lays the best-scoring sample placement
// tile by tile (rack tile, then square; a blank through the letter picker)
// and taps "Legen", or now and then swaps or passes.
//
// The game-ending turn is never on the board (the result dialog opens over
// it), so [engineTurns] leaves it out; the test checks it in the dialog.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'live_ui_driver.dart';

/// The text of [t] as the screen shows it (German, default names Anna / Ben).
String turnText(AppLocalizations l10n, WordTilesTurn t) => switch (t.action) {
      'place' when t.allowed.isNotEmpty =>
        l10n.wordtilesMovePlaceAllowed(t.words.join(', '), t.score, t.allowed.join(', ')),
      'place' => l10n.wordtilesMovePlace(t.words.join(', '), t.score),
      'exchange' => l10n.wordtilesMoveExchange(t.count),
      'pass' => l10n.wordtilesMovePass,
      'challenge' =>
        t.withdrawn ? l10n.wordtilesMoveChallengeWithdrawn(t.words.join(', ')) : l10n.wordtilesMoveChallengeFailed,
      'accept' => l10n.wordtilesMoveAccept,
      _ => t.action,
    };

class WordTilesAdapter extends LiveUiAdapter {
  @override
  String get gameId => 'wordtiles';

  /// How often each kind of turn was tapped (the test checks the mix).
  final Map<String, int> tapped = {};

  final _line = RegExp(r'^(Anna|Ben): (.+)$');
  final _open = RegExp(r'^(Anna|Ben) legte (.+) für (-?\d+) Punkte\.$');

  TurnRecord _record(String name, String text) => TurnRecord(
        index: 0,
        actor: name == 'Anna' ? Player.a : Player.b,
        action: 'turn',
        outcome: text,
        detail: '',
      );

  String? _text(WidgetTester tester, UiDevice d, Key k) {
    final f = d.on(find.byKey(k));
    return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
  }

  /// Turns of each device's log already reported, in order.
  final Expando<int> _reported = Expando('reported');

  /// Turns taken from the device's history instead of its screen: they were
  /// replaced on screen before the driver looked (see [observe]).
  int historyReads = 0;

  /// The turn the screen shows, in turn order: the screen holds only the
  /// latest turn, and two steps can arrive in one frame (a network guest
  /// gets the echo of its own placement and the host's quick answer between
  /// two looks of the driver, KLD-094 step 6 under load). That is no loss for
  /// the player (the history sheet lists every move of the controller), but
  /// the screen line skipped one: such a turn is reported from the device's
  /// own history ([GameController.moves], what the history sheet shows)
  /// before the line on screen. A line matching no turn the device knows is
  /// returned as it is, so the driver still catches a wrong screen.
  @override
  TurnRecord? observe(WidgetTester tester, UiDevice d, Game engine, {required bool inSync}) {
    final shown = _shownTurn(tester, d, engine);
    if (shown == null) return null;
    final c = d.controller(tester);
    final turns = engineTurns(c);
    final k = _reported[c] ?? 0;
    if (k < turns.length && turns[k] == shown) {
      _reported[c] = k + 1;
      return shown;
    }
    if (turns.skip(k + 1).contains(shown)) {
      _reported[c] = k + 1;
      historyReads++;
      return turns[k];
    }
    return shown; // already reported (or a stale frame); the driver logs a change
  }

  TurnRecord? _shownTurn(WidgetTester tester, UiDevice d, Game engine) {
    final line = _text(tester, d, const Key('wordtiles-cover-turn')) ?? _text(tester, d, const Key('wordtiles-last-turn'));
    if (line != null) {
      final m = _line.firstMatch(line);
      expect(m, isNotNull, reason: '${d.name}: last-turn line "$line"');
      return _record(m!.group(1)!, m.group(2)!);
    }
    final banner = d.on(find.byKey(const Key('wordtiles-open')));
    if (banner.evaluate().isNotEmpty) {
      final texts = [
        for (final e in find.descendant(of: banner, matching: find.byType(Text)).evaluate()) (e.widget as Text).data ?? '',
      ];
      final m = texts.map(_open.firstMatch).whereType<RegExpMatch>().firstOrNull;
      expect(m, isNotNull, reason: '${d.name}: challenge banner $texts');
      // The banner shows the open placement: the last turn in the log.
      final g = engine as WordTilesGame;
      expect(g.challengeable, isNotNull, reason: '${d.name}: banner without an open placement');
      return _record(m!.group(1)!, deL10n.wordtilesMovePlace(m.group(2)!, int.parse(m.group(3)!)));
    }
    return null;
  }

  @override
  Future<bool> dismiss(WidgetTester tester, UiDevice device) async => false;

  /// Lets dialogs open or close. A network device never settles (keepalive
  /// timers, the other device's frames): a few fixed frames instead.
  Future<void> settle(WidgetTester tester, UiDevice d) async {
    if (!d.networked) {
      await tester.pumpAndSettle();
      return;
    }
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice d, Random rng) async {
    final c = d.controller(tester);
    final g = c.game as WordTilesGame;
    if (g.isOver) return null;
    if (g.canChallenge) {
      final r = rng.nextDouble();
      if (g.endPending || r < 0.4) {
        if (r < 0.15) {
          tapped.update('challenge', (n) => n + 1, ifAbsent: () => 1);
          await d.tapKey(tester, const Key('wordtiles-challenge'));
          await settle(tester, d);
          await d.tapKey(tester, const Key('wordtiles-challenge-confirm'));
          await settle(tester, d);
          return {'action': 'challenge'};
        }
        tapped.update('accept', (n) => n + 1, ifAbsent: () => 1);
        await d.tapKey(tester, const Key('wordtiles-accept'));
        return {'action': 'accept'};
      }
    }
    final legal = g.legalMoves;
    final r = rng.nextDouble();
    if (r < 0.06) {
      tapped.update('pass', (n) => n + 1, ifAbsent: () => 1);
      await d.tapKey(tester, const Key('wordtiles-pass'));
      await d.tapKey(tester, const Key('wordtiles-pass-confirm'));
      await settle(tester, d);
      return {'action': 'pass'};
    }
    final rack = g.rackOf(g.currentSeat);
    if (r < 0.12 && g.canExchange) {
      tapped.update('exchange', (n) => n + 1, ifAbsent: () => 1);
      final k = 1 + rng.nextInt(rack.length);
      final picks = (List.generate(rack.length, (i) => i)..shuffle(rng)).take(k).toList();
      await d.tapKey(tester, const Key('wordtiles-exchange'));
      for (final i in picks) {
        await d.tapKey(tester, Key('wordtiles-rack-$i'));
      }
      await d.tapKey(tester, const Key('wordtiles-exchange-confirm'));
      return {
        'action': 'exchange',
        'tiles': [for (final i in picks) rack[i]],
      };
    }
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final m in legal) {
      if (m['action'] != 'place') continue;
      final s = g.checkPlacement(m).score;
      if (s > bestScore) {
        best = m;
        bestScore = s;
      }
    }
    if (best == null) {
      tapped.update('pass', (n) => n + 1, ifAbsent: () => 1);
      await d.tapKey(tester, const Key('wordtiles-pass'));
      await d.tapKey(tester, const Key('wordtiles-pass-confirm'));
      await settle(tester, d);
      return {'action': 'pass'};
    }
    tapped.update('place', (n) => n + 1, ifAbsent: () => 1);
    await lay(tester, d, g, best);
    final preview = d.on(find.byKey(const Key('wordtiles-preview')));
    expect(preview, findsOneWidget, reason: '${d.name}: score preview for $best');
    expect(tester.widget<Text>(preview).data, endsWith('$bestScore Punkte'));
    await d.tapKey(tester, const Key('wordtiles-play'));
    return best;
  }

  /// Lays the tiles of [move] like a user: rack tile, then square (a blank
  /// through the letter picker). On a phone the board zooms in on the first
  /// tile; a square outside the zoomed view is reached by zooming out first.
  Future<void> lay(WidgetTester tester, UiDevice d, WordTilesGame g, Map<String, dynamic> move) async {
    final rack = g.rackOf(g.currentSeat);
    final used = <int>{};
    for (final t in (move['tiles'] as List).cast<Map<String, dynamic>>()) {
      final i = [for (var k = 0; k < rack.length; k++) if (rack[k] == t['tile'] && !used.contains(k)) k].first;
      used.add(i);
      await d.tapKey(tester, Key('wordtiles-rack-$i'));
      final sq = Key('wordtiles-sq-${t['row']}-${t['col']}');
      if (!_onScreen(tester, d, sq)) {
        await d.tapKey(tester, const Key('wordtiles-zoom'));
        await settle(tester, d);
      }
      await d.tapKey(tester, sq);
      if (t['tile'] == TileSet.blank) {
        await settle(tester, d);
        await d.tapKey(tester, Key('wordtiles-blank-${t['letter']}'));
        await settle(tester, d);
      }
    }
  }

  /// The square's centre is inside the visible (clipped) board.
  bool _onScreen(WidgetTester tester, UiDevice d, Key sq) {
    final f = d.on(find.byKey(sq));
    if (f.evaluate().isEmpty) return false;
    final hit = tester.hitTestOnBinding(tester.getCenter(f));
    final box = tester.renderObject(f);
    return hit.path.any((e) => e.target == box);
  }

  @override
  List<TurnRecord> engineTurns(GameController c) {
    final g = c.game as WordTilesGame;
    final turns = g.turns;
    final shown = g.isOver ? turns.take(turns.length - 1) : turns;
    return [
      for (final (i, t) in shown.indexed)
        TurnRecord(
          index: i,
          actor: t.seat == 0 ? Player.a : Player.b,
          action: 'turn',
          outcome: turnText(deL10n, t),
          detail: '',
          source: 'engine',
        ),
    ];
  }
}

/// With the word list ("Wörterbuch prüfen", KLD-094 step 5): no challenges;
/// only placements the list accepts, except one early placement with a word
/// the list lacks, which the players let stand with "Trotzdem zulassen" at
/// the notice after "Legen". One swap and one pass (with its confirmation)
/// follow on purpose; then the best accepted sample placement, else a pass,
/// until the game ends.
class WordTilesDictionaryAdapter extends WordTilesAdapter {
  /// How many "Trotzdem zulassen" requests to make (on the empty board).
  final int requests;
  WordTilesDictionaryAdapter({this.requests = 1});

  @override
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice d, Random rng) async {
    final c = d.controller(tester);
    final g = c.game as WordTilesGame;
    if (g.isOver) return null;
    expect(g.canChallenge, isFalse, reason: 'no challenges with the word list');
    final legal = [
      for (final m in g.legalMoves)
        if (m['action'] == 'place') m,
    ];
    if ((tapped['allow'] ?? 0) < requests && g.boardEmpty) {
      // legalMoves only offers words the list knows: build an opening pair
      // through the centre that it lacks.
      final rack = g.rackOf(g.currentSeat);
      Map<String, dynamic>? odd;
      for (var i = 0; i < rack.length && odd == null; i++) {
        for (var j = 0; j < rack.length && odd == null; j++) {
          if (i == j || rack[i] == TileSet.blank || rack[j] == TileSet.blank) continue;
          final m = WordTilesGame.placeMove([PlacedTile(7, 7, rack[i]), PlacedTile(7, 8, rack[j])]);
          if (!g.checkPlacement(m, checkWords: false).ok) continue;
          final unknown = g.unknownWords(m);
          // Not a word the other player declined this turn (no second ask).
          if (unknown.isNotEmpty && g.canRequestAllow(unknown)) odd = m;
        }
      }
      if (odd != null) {
        tapped.update('allow', (n) => n + 1, ifAbsent: () => 1);
        final unknown = g.unknownWords(odd);
        await lay(tester, d, g, odd);
        // The preview shows the score, never whether it is a word.
        expect(d.on(find.byKey(const Key('wordtiles-preview'))), findsOneWidget);
        await d.tapKey(tester, const Key('wordtiles-play'));
        await settle(tester, d);
        expect(d.on(find.byKey(const Key('wordtiles-unknown'))), findsOneWidget, reason: '${d.name}: $odd');
        await d.tapKey(tester, const Key('wordtiles-unknown-allow'));
        await settle(tester, d);
        // KLD-094 step 6: a request to the other player (in hot-seat their
        // agreement follows at once).
        return {
          'action': WordTilesGame.requestAllow,
          'player': g.currentPlayer.name,
          'tiles': odd['tiles'],
          'allow': unknown,
        };
      }
    }
    if ((tapped['exchange'] ?? 0) == 0 && (tapped['allow'] ?? 0) > 0 && g.canExchange) {
      tapped.update('exchange', (n) => n + 1, ifAbsent: () => 1);
      final rack = g.rackOf(g.currentSeat);
      await d.tapKey(tester, const Key('wordtiles-exchange'));
      await d.tapKey(tester, const Key('wordtiles-rack-0'));
      await d.tapKey(tester, const Key('wordtiles-rack-1'));
      await d.tapKey(tester, const Key('wordtiles-exchange-confirm'));
      return {
        'action': 'exchange',
        'tiles': [rack[0], rack[1]],
      };
    }
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final m in legal) {
      final p = g.checkPlacement(m);
      if (p.ok && p.score > bestScore) {
        best = m;
        bestScore = p.score;
      }
    }
    if (best == null || ((tapped['pass'] ?? 0) == 0 && (tapped['exchange'] ?? 0) > 0)) {
      tapped.update('pass', (n) => n + 1, ifAbsent: () => 1);
      await d.tapKey(tester, const Key('wordtiles-pass'));
      await settle(tester, d);
      expect(d.on(find.byKey(const Key('wordtiles-pass-dialog'))), findsOneWidget);
      await d.tapKey(tester, const Key('wordtiles-pass-confirm'));
      await settle(tester, d);
      return {'action': 'pass'};
    }
    tapped.update('place', (n) => n + 1, ifAbsent: () => 1);
    await lay(tester, d, g, best);
    await d.tapKey(tester, const Key('wordtiles-play'));
    await settle(tester, d);
    expect(d.on(find.byKey(const Key('wordtiles-unknown'))), findsNothing, reason: '${d.name}: $best');
    return best;
  }
}

/// Over the network (KLD-094 step 6), each device plays only its own turns
/// from its own view (the guest never sees the host's rack). The first
/// "Trotzdem zulassen" request is declined on the other device (the tiles
/// go back, the placer asks again for another word), the second accepted;
/// both through the answer dialog. Otherwise like [WordTilesDictionaryAdapter].
class WordTilesNetAdapter extends WordTilesDictionaryAdapter {
  /// Requests the other device declines before it accepts one.
  final int declines;
  WordTilesNetAdapter({this.declines = 1}) : super(requests: declines + 1);

  @override
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice d, Random rng) async {
    final c = d.controller(tester);
    final g = c.game as WordTilesGame;
    if (g.isOver) return null;
    final me = d.me!;
    // The guest's view never holds the host's rack.
    if (me == Player.b) expect(g.rackOf(0), isEmpty, reason: '${d.name}: the host rack leaked');
    final request = g.allowRequest;
    if (request != null) {
      if (g.allowRequestAnswerer != WordTilesGame.seatOf(me)) return null; // the placer waits
      final dialog = d.on(find.byKey(const Key('wordtiles-allow-dialog')));
      if (dialog.evaluate().isEmpty) return null; // opens post-frame
      final who = request.seat == 0 ? 'Anna' : 'Ben';
      expect(tester.widget<Text>(d.on(find.byKey(const Key('wordtiles-allow-body')))).data,
          deL10n.wordtilesAllowBody(who, request.allow.join(', ')));
      expect(tester.widget<Text>(d.on(find.byKey(const Key('shell-status')))).data, deL10n.wordtilesAllowYouDecide);
      final decline = (tapped['decline'] ?? 0) < declines;
      tapped.update(decline ? 'decline' : 'agree', (n) => n + 1, ifAbsent: () => 1);
      await d.tapKey(tester, Key(decline ? 'wordtiles-allow-decline' : 'wordtiles-allow-accept'));
      await settle(tester, d);
      return decline ? WordTilesGame.declineAllowMove(me) : WordTilesGame.acceptAllowMove(me);
    }
    if (!c.canAct || g.currentPlayer != me || d.dialogOpen) return null;
    final m = await super.play(tester, d, rng);
    if (m?['action'] == WordTilesGame.requestAllow && (c.game as WordTilesGame).allowRequest != null) {
      // The placer waits for the answer, named in the status line.
      final other = me == Player.a ? 'Ben' : 'Anna';
      expect(tester.widget<Text>(d.on(find.byKey(const Key('shell-status')))).data,
          deL10n.wordtilesAllowDeciding(other));
    }
    return m;
  }
}

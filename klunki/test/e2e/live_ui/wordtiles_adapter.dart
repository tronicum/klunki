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
// KLD-094 step 8 (playtest): in hot-seat it now and then parks a tile it
// does not need on the Bänkchen and leaves it there (sometimes closing the
// bench again; on a small phone always, the open bench lies over the
// board), and before every turn it checks the rack: each seat holds a full
// rack unless the bag is empty, and every tile of the rack on screen is
// reachable (in the rack row or on the open bench).
//
// The game-ending turn is never on the board (the result dialog opens over
// it), so [engineTurns] leaves it out; the test checks it in the dialog.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_board.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'live_ui_driver.dart';

/// The text of [t] as the screen shows it (German, default names Anna / Ben).
String turnText(AppLocalizations l10n, WordTilesTurn t) => t.action == 'place' && t.swaps > 0
    ? l10n.wordtilesMoveJoker(_turnText(l10n, t))
    : _turnText(l10n, t);

String _turnText(AppLocalizations l10n, WordTilesTurn t) => switch (t.action) {
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
  final _open = RegExp(r'^(Anna|Ben) legte (.+) für (-?\d+) Punkte?( \(Joker getauscht\))?\.$');

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

  /// Tiles parked on the bench, and how often its explanation was read.
  int benchTiles = 0, benchCoach = 0;
  final Random _benchRng = Random(5);

  /// KLD-094 step 8: after every completed turn each seat holds
  /// min(7, tiles left) tiles, and the device shows every tile of the rack
  /// it shows (none lost on a closed bench).
  void checkRack(WidgetTester tester, UiDevice d, WordTilesGame g) {
    if (g.isOver) return;
    for (var s = 0; s < g.playerCount; s++) {
      expect(g.rackSizeOf(s) == WordTilesGame.rackSize || g.bagCount == 0, isTrue,
          reason: '${d.name}: seat $s holds ${g.rackSizeOf(s)} tiles, the bag ${g.bagCount}');
    }
    if (g.allowRequest != null) return; // its tiles lie on the board
    final seat = d.me == null ? g.currentSeat : WordTilesGame.seatOf(d.me!);
    final n = g.rackSizeOf(seat);
    for (var i = 0; i < n; i++) {
      expect(d.on(find.byKey(Key('wordtiles-rack-$i'))), findsOneWidget,
          reason: '${d.name}: rack tile $i of $n (${g.rackOf(seat)}) not on screen');
    }
  }

  static const _toggle = Key('wordtiles-bench-toggle');

  /// The bench explanation, if it is up (on the first opening, or at the
  /// start where the bench starts open, KLD-094 step 8c): read to the end.
  Future<void> readCoach(WidgetTester tester, UiDevice d) async {
    if (!d.hasKey(const Key('wordtiles-coach'))) return;
    benchCoach++;
    while (d.hasKey(const Key('wordtiles-coach-next'))) {
      await d.tapKey(tester, const Key('wordtiles-coach-next'));
    }
    await d.tapKey(tester, const Key('wordtiles-coach-done'));
    await settle(tester, d);
  }

  /// Hot-seat, now and then: parks a rack tile not in [keep] on the bench
  /// (opening it first; the first time through its explanation) and
  /// sometimes closes it again (on a small phone always).
  Future<void> fidgetBench(WidgetTester tester, UiDevice d, WordTilesGame g, Set<int> keep) async {
    if (d.networked || _benchRng.nextDouble() > 0.35 || !d.hasKey(_toggle)) return;
    final rack = g.rackOf(g.currentSeat);
    final free = [for (var i = 0; i < rack.length; i++) if (!keep.contains(i)) i];
    if (free.isEmpty) return;
    if (!d.hasKey(const Key('wordtiles-bench-0-0'))) {
      await d.tapKey(tester, _toggle);
      await settle(tester, d);
      await readCoach(tester, d);
    }
    final i = free[_benchRng.nextInt(free.length)];
    bool onBench(int r, int s) => d.has(find.descendant(
        of: find.byKey(Key('wordtiles-bench-$r-$s')),
        matching: find.byWidgetPredicate((w) => '${w.key}'.contains('wordtiles-rack-'))));
    final inRack = d.has(find.descendant(of: find.byKey(const Key('wordtiles-rack')), matching: find.byKey(Key('wordtiles-rack-$i'))));
    final slot = [
      for (var r = 0; r < WordTilesBoard.benchRows; r++)
        for (var s = 0; s < WordTilesBoard.benchSlots; s++) (r, s),
    ].where((x) => !onBench(x.$1, x.$2)).firstOrNull;
    if (inRack && slot != null) {
      await d.tapKey(tester, Key('wordtiles-rack-$i'));
      await d.tapKey(tester, Key('wordtiles-bench-${slot.$1}-${slot.$2}'));
      benchTiles++;
    }
    if (d.hasKey(const Key('wordtiles-bench-overlay')) || _benchRng.nextBool()) {
      await d.tapKey(tester, _toggle);
      await settle(tester, d);
    }
    checkRack(tester, d, g);
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

  /// The game-ending step can bring the device's own last turn with it (a
  /// guest's final pass and the host's answer that ends the game in one
  /// frame): the result dialog then opens before the line showed it. The
  /// device's history has it.
  @override
  List<TurnRecord> unseenAtEnd(WidgetTester tester, UiDevice d, int shown) {
    final c = d.controller(tester);
    if (!c.game.isOver) return const [];
    final turns = engineTurns(c);
    if (shown >= turns.length) return const [];
    _reported[c] = turns.length;
    historyReads += turns.length - shown;
    return turns.sublist(shown);
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
      final text = deL10n.wordtilesMovePlace(m!.group(2)!, int.parse(m.group(3)!));
      // KLD-094 step 9: the banner says "(Joker getauscht)" like the log.
      return _record(m.group(1)!, m.group(4) != null ? deL10n.wordtilesMoveJoker(text) : text);
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
    await readCoach(tester, d);
    checkRack(tester, d, g);
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
  ///
  /// [exclude]: rack tiles already used this turn (a "Joker tauschen" swap).
  Future<void> lay(WidgetTester tester, UiDevice d, WordTilesGame g, Map<String, dynamic> move,
      {Set<int> exclude = const {}, bool fidget = true}) async {
    final rack = g.rackOf(g.currentSeat);
    final tiles = (move['tiles'] as List).cast<Map<String, dynamic>>();
    final used = <int>[];
    for (final t in tiles) {
      used.add([
        for (var k = 0; k < rack.length; k++)
          if (rack[k] == t['tile'] && !used.contains(k) && !exclude.contains(k)) k
      ].first);
    }
    // Not after a staged swap: its letter lies on the board, not in the rack.
    if (fidget) await fidgetBench(tester, d, g, used.toSet());
    for (final (n, t) in tiles.indexed) {
      final i = used[n];
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

/// "Joker tauschen" on (KLD-094 step 9): whenever the player to move holds a
/// letter that a blank on the board stands for (and no placement waits for
/// an answer), it swaps through the UI (the rack tile, then the blank) and
/// lays the best sample placement that fits with the swap; otherwise as
/// [WordTilesAdapter].
class WordTilesJokerAdapter extends WordTilesAdapter {
  @override
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice d, Random rng) async {
    final g = d.controller(tester).game as WordTilesGame;
    if (g.isOver || g.canChallenge || g.endPending || !g.jokerSwap) return super.play(tester, d, rng);
    final rack = g.rackOf(g.currentSeat);
    const n = WordTilesGame.size;
    JokerSwap? swap;
    var from = -1;
    for (var sq = 0; sq < n * n && swap == null; sq++) {
      final t = g.tileAt(sq ~/ n, sq % n);
      if (t == null || !t.blank) continue;
      from = rack.indexOf(t.letter);
      if (from >= 0) swap = JokerSwap(sq ~/ n, sq % n, t.letter);
    }
    if (swap == null) {
      // The sample bot rarely lays a blank: lay one (as the commonest letter)
      // when it can, so there is something to swap later.
      final withBlank = [
        for (final m in g.legalMoves)
          if (m['action'] == 'place' && (m['tiles'] as List).any((t) => (t as Map)['tile'] == TileSet.blank)) m,
      ];
      if (withBlank.isEmpty) return super.play(tester, d, rng);
      final m = withBlank.first;
      await readCoach(tester, d);
      checkRack(tester, d, g);
      tapped.update('place', (k) => k + 1, ifAbsent: () => 1);
      await lay(tester, d, g, m);
      await d.tapKey(tester, const Key('wordtiles-play'));
      return m;
    }
    Map<String, dynamic>? best;
    var bestScore = -1;
    for (final m in g.legalMoves) {
      if (m['action'] != 'place') continue;
      final with_ = {
        ...m,
        'swaps': [swap.toJson()],
      };
      final c = g.checkPlacement(with_);
      if (c.ok && c.score > bestScore) {
        best = with_;
        bestScore = c.score;
      }
    }
    if (best == null) return super.play(tester, d, rng);
    await readCoach(tester, d);
    checkRack(tester, d, g);
    tapped.update('joker', (k) => k + 1, ifAbsent: () => 1);
    await d.tapKey(tester, Key('wordtiles-rack-$from'));
    final sq = Key('wordtiles-sq-${swap.row}-${swap.col}');
    if (!_onScreen(tester, d, sq)) {
      await d.tapKey(tester, const Key('wordtiles-zoom'));
      await settle(tester, d);
    }
    await d.tapKey(tester, sq);
    expect(d.on(find.byKey(Key('wordtiles-swapped-${swap.row}-${swap.col}'))), findsOneWidget,
        reason: '${d.name}: swap staged');
    await lay(tester, d, g, best, exclude: {from}, fidget: false);
    final preview = d.on(find.byKey(const Key('wordtiles-preview')));
    expect(preview, findsOneWidget, reason: '${d.name}: score preview for $best');
    expect(tester.widget<Text>(preview).data, endsWith('$bestScore Punkte'));
    await d.tapKey(tester, const Key('wordtiles-play'));
    return best;
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
    await readCoach(tester, d);
    checkRack(tester, d, g);
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
    await readCoach(tester, d);
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

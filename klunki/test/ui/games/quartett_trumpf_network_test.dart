// Quartett (Trumpf) on a network device (KLD-086): "Weiter" is local only,
// the next picker continues whenever they like, the waiting player gets a
// grace period with a countdown and sees tricks picked meanwhile afterwards,
// in order; "Vorige Runde" peeks at the last trick without blocking.
//
// Most tests run one device against a scripted opponent ([_DeviceTransport],
// one local player, every own submit recorded as the "network message").
// The last test plays host vs guest over real NetworkTransports on
// 127.0.0.1, as in gostrategy_network_test.dart.
@Timeout(Duration(seconds: 90))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';

const _reveal = Key('qt-reveal');
const _cont = Key('qt-continue');
const _ownCard = Key('qt-own-card');
const _lastTrick = Key('qt-last-trick');
Key _statKey(String id) => Key('qt-stat-$id');

/// One device of a network game with a single local player [me]. The
/// opponent's moves come from [remote]; every own [submit] is recorded in
/// [sent] (what would go over the wire).
class _DeviceTransport implements GameTransport {
  _DeviceTransport(int seed, this.me, {required this.fullInformation, bool pickLow = false})
      : _inner = HotSeatTransport(GameConfig('quartett-trumpf', seed: seed, pickLowCards: pickLow));

  final HotSeatTransport _inner;
  final Player me;
  final List<Map<String, dynamic>> sent = [];

  @override
  final bool fullInformation;

  @override
  GameConfig get config => _inner.config;
  @override
  Set<Player> get localPlayers => {me};
  @override
  Game get game => _inner.game;
  @override
  List<AcceptedMove> get moves => _inner.moves;
  @override
  Stream<AcceptedMove> get accepted => _inner.accepted;

  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async {
    if (game.currentPlayer != me) return const SubmitResult.rejected(RejectReason.notYourTurn);
    sent.add(move);
    return _inner.submitSync(move);
  }

  /// The opponent picks [stat].
  void remote(String stat) {
    expect(game.currentPlayer, isNot(me));
    expect(_inner.submitSync({'action': 'pick', 'stat': stat}).isAccepted, isTrue);
  }

  @override
  void dispose() => _inner.dispose();
}

Map<String, dynamic> _pickMove(String stat) => {'action': 'pick', 'stat': stat};

/// Trick winner ('a', 'b' or null) of [stats] played in order from [seed].
List<Object?> _winners(int seed, List<String> stats) {
  final g = QuartettGame(QuartettMode.trumpf, seed: seed);
  return [for (final s in stats) (g.applyMove(_pickMove(s))!.payload as Map)['trickWinner']];
}

/// First seed with two stats such that X wins the first trick and the second
/// trick (X picks again) has winner [second].
(int, String, String) _twoTricks(Object? second) {
  final ids = [for (final s in QuartettDeck.cars.stats) s.id];
  for (var seed = 1; seed < 5000; seed++) {
    for (final s1 in ids) {
      if (_winners(seed, [s1]).single != 'a') continue;
      for (final s2 in ids) {
        if (_winners(seed, [s1, s2]).last == second) return (seed, s1, s2);
      }
    }
  }
  throw StateError('no matching seed');
}

String _picked(String mark, String stat) => '$mark wählt ${localizedStatLabel(deL10n, stat)}';

Future<(GameController, _DeviceTransport)> _pumpDevice(WidgetTester tester, int seed, Player me,
    {bool fullInformation = false}) async {
  final t = _DeviceTransport(seed, me, fullInformation: fullInformation);
  final c = GameController(t);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  return (c, t);
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.pump(); // post-frame hint
}

const _overlay = Key('qt-last-trick-overlay');
const _grace = Key('qt-grace');
const _notice = Key('qt-queued-notice');
const _ms = Duration(milliseconds: 1);

String _graceText(int s) => 'Weiter in $s s';

String _valueOf(String stat, num v) {
  final s = QuartettDeck.cars.statById(stat)!;
  return formatQuartettValue(s, v, unit: localizedStatUnit(deL10n, stat));
}

/// The overlay's value line for trick [stats].last played from [seed].
String _valuesLine(int seed, List<String> stats) {
  final g = QuartettGame(QuartettMode.trumpf, seed: seed);
  Map? p;
  for (final s in stats) {
    p = g.applyMove(_pickMove(s))!.payload as Map;
  }
  final v = p!['values'] as Map;
  final stat = stats.last;
  return '${localizedStatLabel(deL10n, stat)}: X ${_valueOf(stat, v['a'] as num)} – O ${_valueOf(stat, v['b'] as num)}';
}

Future<void> _openOverlay(WidgetTester tester) async {
  await _tap(tester, _lastTrick);
  await tester.pump(const Duration(milliseconds: 300)); // dialog transition
  expect(find.byKey(_overlay), findsOneWidget);
}

Future<void> _settleClose(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
  expect(find.byKey(_overlay), findsNothing);
}

Finder _inOverlay(Finder f) => find.descendant(of: find.byKey(_overlay), matching: f);

/// A whole game from [seed] (picks: the first stat of the picker's card
/// that wins, else the first stat): (stat of each trick, its picker, its
/// winner).
(List<String>, List<Player>, List<Player?>) _wholeGame(int seed) {
  final g = QuartettGame(QuartettMode.trumpf, seed: seed);
  final stats = <String>[], pickers = <Player>[], winners = <Player?>[];
  while (!g.isOver) {
    final p = g.currentPlayer;
    final mine = g.topCard(p)!, theirs = g.topCard(p == Player.a ? Player.b : Player.a)!;
    final s = QuartettDeck.cars.stats.where((s) => s.beats(mine.stats[s.id]!, theirs.stats[s.id]!)).firstOrNull ??
        QuartettDeck.cars.stats.first;
    final w = (g.applyMove(_pickMove(s.id))!.payload as Map)['trickWinner'];
    stats.add(s.id);
    pickers.add(p);
    winners.add(w == null ? null : Player.values.byName(w as String));
  }
  return (stats, pickers, winners);
}

/// First seed whose [_wholeGame] satisfies [test].
(int, List<String>, List<Player>, List<Player?>) _findGame(
    bool Function(List<String> stats, List<Player> pickers, List<Player?> winners) test) {
  for (var seed = 1; seed < 500; seed++) {
    final (s, p, w) = _wholeGame(seed);
    if (test(s, p, w)) return (seed, s, p, w);
  }
  throw StateError('no matching game');
}

/// A device for [me] with every pick of [stats] but the last [rest] already
/// played (as if the game had run that far).
Future<(GameController, _DeviceTransport)> _pumpNearEnd(
    WidgetTester tester, int seed, Player me, List<String> stats, int rest) async {
  final t = _DeviceTransport(seed, me, fullInformation: false);
  for (final s in stats.take(stats.length - rest)) {
    expect(t._inner.submitSync(_pickMove(s)).isAccepted, isTrue);
  }
  final c = GameController(t);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  return (c, t);
}

const _resultDialog = Key('result-dialog');

void main() {
  test('the grace period is 5 s', () {
    expect(quartettRevealGrace, const Duration(seconds: 5));
  });

  testWidgets('the trick winner continues at once; the pick goes out at once, "Weiter" sends nothing',
      (tester) async {
    final (seed, s1, s2) = _twoTricks('a');
    // Host-like device (full information): still no preview, the pick is
    // submitted on the tap.
    final (c, t) = await _pumpDevice(tester, seed, Player.a, fullInformation: true);

    await _tap(tester, _statKey(s1));
    expect(t.sent, [_pickMove(s1)], reason: 'sent on the tap, not on "Weiter"');
    expect(c.moves, hasLength(1));
    expect(find.byKey(_reveal), findsOneWidget);
    expect(find.text('X gewinnt die Runde'), findsOneWidget);
    expect(find.byKey(_grace), findsNothing, reason: 'no countdown for the next picker');

    // The next picker's reveal does not run away.
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(_reveal), findsOneWidget);

    await _tap(tester, _cont);
    expect(t.sent, hasLength(1), reason: '"Weiter" is local only');
    expect(find.byKey(_reveal), findsNothing);
    expect(find.byKey(_statKey(s2)), findsOneWidget);
    expect(find.text('Wähle eine Eigenschaft deiner Karte'), findsOneWidget);

    await _tap(tester, _statKey(s2));
    expect(t.sent, [_pickMove(s1), _pickMove(s2)]);
    expect(c.moves, hasLength(2));
  });

  testWidgets('waiting player: countdown, a trick picked meanwhile is announced, queued and shown next',
      (tester) async {
    final (seed, s1, s2) = _twoTricks('a');
    final (c, t) = await _pumpDevice(tester, seed, Player.b);
    expect(find.text('X wählt …'), findsOneWidget);

    t.remote(s1);
    await tester.pump();
    expect(find.byKey(_reveal), findsOneWidget);
    expect(find.text(_picked('X', s1)), findsOneWidget);
    expect(find.text('X gewinnt die Runde'), findsOneWidget);
    expect(find.byKey(_grace), findsOneWidget);
    expect(find.text(_graceText(5)), findsOneWidget);
    expect(find.byKey(_notice), findsNothing);

    // X continues at once and picks again during O's grace period.
    await tester.pump(const Duration(seconds: 1) + _ms);
    expect(find.text(_graceText(4)), findsOneWidget);
    t.remote(s2);
    await tester.pump();
    expect(c.moves, hasLength(2));
    expect(find.text(_picked('X', s1)), findsOneWidget, reason: 'the first trick stays for the grace period');
    expect(find.text(_picked('X', s2)), findsNothing);
    expect(find.text('X hat gewählt: ${localizedStatLabel(deL10n, s2)}'), findsOneWidget);
    expect(find.text(_graceText(4)), findsOneWidget, reason: 'the countdown keeps running');

    await tester.pump(quartettRevealGrace - const Duration(seconds: 1) - const Duration(milliseconds: 20));
    expect(find.text(_picked('X', s1)), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text(_picked('X', s1)), findsNothing);
    expect(find.text(_picked('X', s2)), findsOneWidget, reason: 'the queued trick comes next');
    expect(find.byKey(_notice), findsNothing);
    expect(find.text(_graceText(5)), findsOneWidget, reason: 'with its own grace');

    // Then O sees the own new top card and who picks, without any button.
    await tester.pump(quartettRevealGrace - const Duration(milliseconds: 100));
    expect(find.byKey(_reveal), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.byKey(_reveal), findsNothing);
    expect(find.byKey(_ownCard), findsOneWidget);
    final top = (c.game as QuartettGame).topCard(Player.b)!;
    expect(find.text(top.name), findsOneWidget);
    expect(find.text('X wählt …'), findsOneWidget);
    expect(t.sent, isEmpty);
  });

  testWidgets('waiting player: a tap skips the countdown and shows the queued trick at once', (tester) async {
    final (seed, s1, s2) = _twoTricks('b');
    final (c, t) = await _pumpDevice(tester, seed, Player.b);

    t.remote(s1);
    await tester.pump();
    t.remote(s2); // O wins this one
    await tester.pump();
    expect(find.text(_picked('X', s1)), findsOneWidget);
    expect(find.byKey(_notice), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    await _tap(tester, _cont);
    expect(find.text(_picked('X', s2)), findsOneWidget);
    expect(find.text('O gewinnt die Runde'), findsOneWidget);
    expect(find.byKey(_grace), findsNothing, reason: 'O picks next: no countdown');

    // O picks next: this reveal stays until "Weiter".
    await tester.pump(const Duration(seconds: 10));
    expect(find.text(_picked('X', s2)), findsOneWidget);
    await _tap(tester, _cont);
    expect(find.byKey(_reveal), findsNothing);
    expect(c.canAct, isTrue);
    expect(find.text('Wähle eine Eigenschaft deiner Karte'), findsOneWidget);
    expect(t.sent, isEmpty, reason: '"Weiter" is local only');
  });

  testWidgets('a tap skips the countdown to the table', (tester) async {
    final (seed, s1, _) = _twoTricks('a');
    final (_, t) = await _pumpDevice(tester, seed, Player.b);
    t.remote(s1);
    await tester.pump();
    expect(find.byKey(_grace), findsOneWidget);
    await _tap(tester, _cont);
    expect(find.byKey(_reveal), findsNothing);
    expect(find.byKey(_ownCard), findsOneWidget);
    expect(t.sent, isEmpty);
  });

  group('"Vorige Runde" overlay', () {
    testWidgets('disabled before the first trick; on the guest it shows the last trick and closes three ways',
        (tester) async {
      final (seed, s1, _) = _twoTricks('a');
      final (c, t) = await _pumpDevice(tester, seed, Player.b);
      expect(tester.widget<ActionChip>(find.byKey(_lastTrick)).onPressed, isNull);

      t.remote(s1);
      await tester.pump();
      final g = c.game as QuartettGame;
      final (ca, cb) = (g.stackSize(Player.a), g.stackSize(Player.b));
      await tester.pump(quartettRevealGrace + _ms);
      await tester.pump();
      expect(find.byKey(_reveal), findsNothing);

      // Close button.
      await _openOverlay(tester);
      expect(_inOverlay(find.text(_picked('X', s1))), findsOneWidget);
      expect(_inOverlay(find.text('X gewinnt die Runde')), findsOneWidget);
      expect(_inOverlay(find.text(_valuesLine(seed, [s1]))), findsOneWidget);
      expect(_inOverlay(find.text('X: $ca Karten · O: $cb Karten')), findsOneWidget);
      expect(_inOverlay(find.byKey(const Key('qt-reveal-a'))), findsOneWidget);
      expect(_inOverlay(find.byKey(const Key('qt-reveal-b'))), findsOneWidget);
      await tester.tap(find.byKey(const Key('qt-last-trick-close')));
      await _settleClose(tester);

      // Tap outside.
      await _openOverlay(tester);
      await tester.tapAt(const Offset(4, 4));
      await _settleClose(tester);

      // Back.
      await _openOverlay(tester);
      await tester.binding.handlePopRoute();
      await _settleClose(tester);
      expect(t.sent, isEmpty);
    });

    testWidgets('on the host (trick winner) it shows the same trick', (tester) async {
      final (seed, s1, _) = _twoTricks('a');
      final (c, t) = await _pumpDevice(tester, seed, Player.a, fullInformation: true);
      await _tap(tester, _statKey(s1));
      final g = c.game as QuartettGame;
      final (ca, cb) = (g.stackSize(Player.a), g.stackSize(Player.b));
      // Reachable during the reveal too.
      await _openOverlay(tester);
      expect(_inOverlay(find.text(_picked('X', s1))), findsOneWidget);
      expect(_inOverlay(find.text(_valuesLine(seed, [s1]))), findsOneWidget);
      expect(_inOverlay(find.text('X: $ca Karten · O: $cb Karten')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qt-last-trick-close')));
      await _settleClose(tester);
      expect(find.byKey(_reveal), findsOneWidget);
      expect(t.sent, hasLength(1));
    });

    testWidgets('a result arriving while it is open is queued, then shown after closing', (tester) async {
      final (seed, s1, s2) = _twoTricks('a');
      final (_, t) = await _pumpDevice(tester, seed, Player.b);
      t.remote(s1);
      await tester.pump();
      await _tap(tester, _cont); // skip to the table

      await _openOverlay(tester);
      t.remote(s2);
      await tester.pump(const Duration(seconds: 10));
      expect(_inOverlay(find.text(_picked('X', s1))), findsOneWidget, reason: 'keeps what the player looks at');
      expect(find.text(_picked('X', s2)), findsNothing);

      await tester.tap(find.byKey(const Key('qt-last-trick-close')));
      await _settleClose(tester);
      expect(find.text(_picked('X', s2)), findsOneWidget, reason: 'nothing skipped');
      expect(find.byKey(_grace), findsOneWidget);
    });

    testWidgets('it pauses a running countdown; the queued trick is not skipped', (tester) async {
      final (seed, s1, s2) = _twoTricks('a');
      final (_, t) = await _pumpDevice(tester, seed, Player.b);
      t.remote(s1);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1) + _ms);
      await _openOverlay(tester);
      t.remote(s2);
      await tester.pump(const Duration(seconds: 20));
      await tester.binding.handlePopRoute();
      await _settleClose(tester);
      expect(find.text(_picked('X', s1)), findsOneWidget, reason: 'the countdown was paused');
      expect(find.byKey(_notice), findsOneWidget);
      await _tap(tester, _cont);
      expect(find.text(_picked('X', s2)), findsOneWidget);
    });

    testWidgets('hot-seat: shows the last submitted trick, not the preview', (tester) async {
      final (seed, s1, s2) = _twoTricks('a');
      final c = GameController.hotSeat(GameConfig('quartett-trumpf', seed: seed, pickLowCards: false));
      addTearDown(c.dispose);
      await tester.pumpWidget(localizedApp(buildGameScreen(c)));
      await tester.pump();
      expect(tester.widget<ActionChip>(find.byKey(_lastTrick)).onPressed, isNull);
      await _tap(tester, _statKey(s1));
      expect(tester.widget<ActionChip>(find.byKey(_lastTrick)).onPressed, isNull, reason: 'preview not applied');
      await _tap(tester, _cont);
      await _tap(tester, _statKey(s2)); // preview of trick 2
      await _openOverlay(tester);
      expect(_inOverlay(find.text(_picked('X', s1))), findsOneWidget);
      expect(_inOverlay(find.text('X: 17 Karten · O: 15 Karten')), findsOneWidget);
      await tester.tap(find.byKey(const Key('qt-last-trick-close')));
      await _settleClose(tester);
      expect(c.moves, hasLength(1));
      await _tap(tester, _cont);
      expect(c.moves, hasLength(2));
    });
  });

  group('status line follows the shown result (KLD-091)', () {
    const badge = Key('shell-status-badge');
    String status(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-status'))).data!;
    String? badgeText(WidgetTester tester) {
      final f = find.descendant(of: find.byKey(badge), matching: find.byType(Text));
      return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
    }

    /// A device for [me] with names, as in a real network game.
    Future<(GameController, _DeviceTransport)> pumpNamed(WidgetTester tester, int seed, Player me) async {
      final t = _DeviceTransport(seed, me, fullInformation: false);
      final c = GameController(t);
      addTearDown(c.dispose);
      await tester.pumpWidget(localizedApp(PlayerLabelsScope(
        labels: PlayerLabels(names: const {Player.a: 'Anna', Player.b: 'Ben'}, local: me),
        child: buildGameScreen(c),
      )));
      await tester.pump();
      return (c, t);
    }

    testWidgets('waiting player: "Anna (X) wählt als Nächstes" + "noch n Runden" until the queue is empty',
        (tester) async {
      final (seed, s1, s2) = _twoTricks('a');
      final (c, t) = await pumpNamed(tester, seed, Player.b);
      await tester.pump();
      expect(status(tester), 'Warte auf Anna (X)…');

      t.remote(s1);
      await tester.pump();
      await tester.pump();
      expect(find.text(_picked('X', s1)), findsOneWidget);
      expect(status(tester), 'Warte auf Anna (X)…', reason: 'the newest trick: live status');
      expect(find.byKey(badge), findsNothing);

      // X goes on twice while O still looks at the first trick.
      t.remote(s2);
      t.remote(s1);
      await tester.pump();
      await tester.pump();
      expect(c.moves, hasLength(3));
      expect(find.text(_picked('X', s1)), findsOneWidget, reason: 'still the first trick');
      expect(status(tester), 'Anna (X) wählt als Nächstes');
      expect(badgeText(tester), 'noch 2 Runden');

      await _tap(tester, _cont);
      expect(find.text(_picked('X', s2)), findsOneWidget);
      expect(status(tester), 'Anna (X) wählt als Nächstes');
      expect(badgeText(tester), 'noch 1 Runde');

      await _tap(tester, _cont);
      expect(find.byKey(_reveal), findsOneWidget, reason: 'the third trick');
      expect(find.byKey(badge), findsNothing);
      final live = c.game.currentPlayer == Player.b ? 'Du bist am Zug (O)' : 'Warte auf Anna (X)…';
      expect(status(tester), live, reason: 'queue empty: live status again');
    });

    testWidgets('several tricks at once: "Du wählst als Nächstes (O)" while an older one is shown', (tester) async {
      final (seed, s1, s2) = _twoTricks('b');
      // X wins s1 and picks s2, which O wins; O's own pick arrives in the
      // same batch (e.g. after a reconnect): the device shows s2 with O's
      // pick still behind it.
      final (c, t) = await pumpNamed(tester, seed, Player.b);
      await tester.pump();
      t.remote(s1);
      t.remote(s2);
      expect(t._inner.submitSync(_pickMove(s1)).isAccepted, isTrue);
      await tester.pump();
      await tester.pump();
      expect(c.moves, hasLength(3));
      expect(find.text(_picked('X', s1)), findsOneWidget);
      expect(status(tester), 'Anna (X) wählt als Nächstes');
      expect(badgeText(tester), 'noch 2 Runden');
      await _tap(tester, _cont);
      expect(find.text(_picked('X', s2)), findsOneWidget);
      expect(status(tester), 'Du wählst als Nächstes (O)');
      expect(badgeText(tester), 'noch 1 Runde');
      await _tap(tester, _cont);
      expect(find.text(_picked('O', s1)), findsOneWidget);
      expect(find.byKey(badge), findsNothing);
    });

    testWidgets('the next picker reads its result with the live status, no badge', (tester) async {
      final (seed, s1, _) = _twoTricks('a');
      await pumpNamed(tester, seed, Player.a);
      await tester.pump();
      await _tap(tester, _statKey(s1));
      expect(find.byKey(_reveal), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('qt-next-picker'))).data, 'X wählt noch einmal');
      expect(status(tester), 'Du bist am Zug (X)');
      expect(find.byKey(badge), findsNothing);
    });
  });

  group('game end (KLD-089): the result waits until every trick was shown', () {
    testWidgets('waiting player: the final tricks queued behind a reveal come before the result', (tester) async {
      // The last two tricks are picked by the same player, who wins the last
      // one: on the other device both are still to show when the game ends.
      final (seed, stats, pickers, _) = _findGame((s, p, w) {
        final n = s.length;
        return n >= 3 && p[n - 1] == p[n - 2] && w[n - 1] == p[n - 1];
      });
      final winner = pickers.last;
      final me = winner == Player.a ? Player.b : Player.a;
      final (c, t) = await _pumpNearEnd(tester, seed, me, stats, 2);
      final mark = playerMark(winner);

      t.remote(stats[stats.length - 2]);
      await tester.pump();
      t.remote(stats.last);
      await tester.pump();
      await tester.pump();
      expect(c.game.isOver, isTrue);
      expect(find.text(_picked(mark, stats[stats.length - 2])), findsOneWidget);
      expect(find.byKey(_notice), findsOneWidget, reason: 'the final trick is queued');
      expect(find.byKey(_resultDialog), findsNothing, reason: 'the result must not cover tricks still to show');

      // The grace runs out: the final trick comes next, still no result.
      await tester.pump(quartettRevealGrace + _ms);
      await tester.pump();
      expect(find.text(_picked(mark, stats.last)), findsOneWidget);
      expect(find.byKey(_resultDialog), findsNothing);

      // "Weiter" (or the end of its grace): now the result.
      await _tap(tester, _cont);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_reveal), findsNothing);
      expect(find.byKey(_resultDialog), findsOneWidget);
    });

    testWidgets('waiting player: the result follows when the grace of the final trick runs out', (tester) async {
      final (seed, stats, pickers, _) = _findGame((s, p, w) => w.last == p.last);
      final winner = pickers.last;
      final me = winner == Player.a ? Player.b : Player.a;
      final (_, t) = await _pumpNearEnd(tester, seed, me, stats, 1);
      t.remote(stats.last);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_reveal), findsOneWidget);
      expect(find.byKey(_resultDialog), findsNothing);
      await tester.pump(quartettRevealGrace + _ms);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_reveal), findsNothing);
      expect(find.byKey(_resultDialog), findsOneWidget);
    });

    testWidgets('the winner of the final trick reads it until "Weiter", then the result', (tester) async {
      final (seed, stats, pickers, _) = _findGame((s, p, w) => w.last == p.last);
      final winner = pickers.last;
      final (c, t) = await _pumpNearEnd(tester, seed, winner, stats, 1);
      await _tap(tester, _statKey(stats.last));
      expect(c.game.isOver, isTrue);
      expect(t.sent, [_pickMove(stats.last)]);
      await tester.pump(const Duration(seconds: 10));
      expect(find.byKey(_reveal), findsOneWidget);
      expect(find.text('${playerMark(winner)} gewinnt die Runde'), findsOneWidget);
      expect(find.byKey(_resultDialog), findsNothing);
      await _tap(tester, _cont);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(_resultDialog), findsOneWidget);
    });

    testWidgets('hot-seat: the final trick is previewed; "Weiter" ends the game, the result follows at once',
        (tester) async {
      final (seed, stats, _, _) = _findGame((s, p, w) => true);
      final c = GameController.hotSeat(GameConfig('quartett-trumpf', seed: seed, pickLowCards: false));
      addTearDown(c.dispose);
      for (final s in stats.take(stats.length - 1)) {
        expect((await c.submit(_pickMove(s))).isAccepted, isTrue);
      }
      c.acknowledgeHandover();
      await tester.pumpWidget(localizedApp(buildGameScreen(c)));
      await tester.pump();
      await _tap(tester, _statKey(stats.last));
      expect(find.byKey(_reveal), findsOneWidget);
      expect(find.byKey(_resultDialog), findsNothing);
      await _tap(tester, _cont);
      await tester.pump(const Duration(milliseconds: 300));
      expect(c.game.isOver, isTrue);
      expect(find.byKey(_resultDialog), findsOneWidget);
    });
  });

  testWidgets('hot-seat keeps the preview: one tap on "Weiter" submits, no grace', (tester) async {
    final (seed, s1, _) = _twoTricks('a');
    final c = GameController.hotSeat(GameConfig('quartett-trumpf', seed: seed, pickLowCards: false));
    addTearDown(c.dispose);
    await tester.pumpWidget(localizedApp(buildGameScreen(c)));
    await tester.pump();
    await _tap(tester, _statKey(s1));
    expect(c.moves, isEmpty, reason: 'hot-seat previews; the pick is submitted on "Weiter"');
    expect(find.byKey(_grace), findsNothing);
    await tester.pump(const Duration(seconds: 10));
    expect(find.byKey(_reveal), findsOneWidget);
    await _tap(tester, _cont);
    expect(c.moves, hasLength(1));
    expect(find.byKey(_reveal), findsNothing);
  });

  group('host vs guest over 127.0.0.1', () {
    const hostKey = Key('device-host');
    const guestKey = Key('device-guest');
    const ping = Duration(milliseconds: 100);
    const timeout = Duration(seconds: 10);

    Finder on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);
    GameController controller(WidgetTester tester, Key device) =>
        tester.widget<GameScreen>(on(device, find.byType(GameScreen))).controller;

    Future<void> until(WidgetTester tester, bool Function() condition, String what) async {
      for (var round = 0;; round++) {
        await tester.pump();
        if (condition()) {
          await tester.pump();
          return;
        }
        if (round > 2000) fail('condition not met: $what');
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      }
    }

    Future<void> tapOn(WidgetTester tester, Key device, Key key) async {
      await tester.ensureVisible(on(device, find.byKey(key)));
      await tester.tap(on(device, find.byKey(key)));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('the host winner picks again during the guest grace; the guest sees both tricks in order',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (host, guest) = (await tester.runAsync(() async {
        final h = await NetworkTransport.host(const GameConfig('quartett-trumpf', seed: 5),
            name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: ping, timeout: timeout);
        final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
            name: 'Ben', pingInterval: ping, timeout: timeout);
        return (h, g);
      }))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        guest.dispose();
        host.dispose();
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
          await tester.pump();
        }
      });

      Widget device(Key key, NetworkTransport t) => Expanded(
            child: KeyedSubtree(key: key, child: localizedApp(NetworkGameSession(transport: t))),
          );
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [device(hostKey, host), device(guestKey, guest)]),
      ));
      await until(tester, () => on(guestKey, find.byKey(_ownCard)).evaluate().isNotEmpty, 'guest shows its card');

      // The host (X) picks a stat that wins, from the real deal.
      final hc = controller(tester, hostKey), gc = controller(tester, guestKey);
      final g = hc.game as QuartettGame;
      final xTop = g.topCard(Player.a)!, oTop = g.topCard(Player.b)!;
      final s1 = QuartettDeck.cars.stats.firstWhere((s) => s.beats(xTop.stats[s.id]!, oTop.stats[s.id]!)).id;

      await tapOn(tester, hostKey, _statKey(s1));
      expect(hc.moves, hasLength(1), reason: 'the host applies its own pick at once');
      await until(tester, () => gc.moves.length == 1, 'guest receives the pick without any "Weiter"');
      expect(on(guestKey, find.text('X gewinnt die Runde')), findsOneWidget);
      expect(on(hostKey, find.text('X gewinnt die Runde')), findsOneWidget);
      expect(on(guestKey, find.byKey(_grace)), findsOneWidget);
      expect(on(hostKey, find.byKey(_grace)), findsNothing);

      // Both see the same trick in "Vorige Runde" (the dialog opens on the
      // device's own navigator).
      final values = on(guestKey, find.byKey(const Key('qt-reveal-a')));
      expect(values, findsOneWidget);
      for (final d in [hostKey, guestKey]) {
        await tapOn(tester, d, _lastTrick);
        await tester.pump(const Duration(milliseconds: 300));
        final line = tester.widget<Text>(on(d, find.byKey(const Key('qt-last-trick-values')))).data!;
        expect(line, startsWith('${localizedStatLabel(deL10n, s1)}: X '));
        expect(on(d, find.descendant(of: find.byKey(_overlay), matching: find.text(_picked('X', s1)))),
            findsOneWidget);
        await tester.tap(on(d, find.byKey(const Key('qt-last-trick-close'))));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(
          tester.widget<Text>(on(hostKey, find.byKey(const Key('qt-reveal-text')))).data, 'X gewinnt die Runde');

      // The host continues at once and picks again during the guest's grace.
      await tapOn(tester, hostKey, _cont);
      expect(gc.moves, hasLength(1), reason: '"Weiter" sends nothing');
      final s2 = QuartettDeck.cars.stats.first.id;
      await tapOn(tester, hostKey, _statKey(s2));
      await until(tester, () => gc.moves.length == 2, 'guest receives the second pick');
      final s1Text = _picked('X', s1);
      final s2Text = _picked('X', s2);
      expect(on(guestKey, find.text(s1Text)), findsOneWidget, reason: 'still in the grace period');
      expect(on(guestKey, find.text(s2Text)), findsNothing);
      expect(on(guestKey, find.byKey(_notice)), findsOneWidget);

      // A tap shows the queued trick.
      await tapOn(tester, guestKey, _cont);
      expect(on(guestKey, find.text(s2Text)), findsOneWidget);
      expect(hc.moves, hasLength(2), reason: 'the guest\'s "Weiter" sends nothing');
    });
  });
}

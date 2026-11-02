// Generic "play a full game through the UI" driver (KLD-089).
//
// A per-game [LiveUiAdapter] knows how to read a game's screen (what the
// player sees right now) and how to turn a chosen move into taps. This
// driver plays complete games with it, like a user would:
//
// * [playHotSeat]: one device, both players, handover covers included.
// * [playNetwork]: a host and a guest device side by side in one widget
//   tree, real NetworkTransports over 127.0.0.1 (optionally through the
//   seeded Wi-Fi latency proxy of e2e_support.dart). Each round the devices
//   act in a random order, sometimes dawdle (so results queue up), and the
//   fake clock is sometimes advanced (so timed reveals run out on their own).
//
// After every pump each device is observed: every turn result that appears
// on its screen is logged once ([TurnRecord]). At the end each device's log
// must equal the engine's history (nothing skipped, duplicated or
// reordered), the engine history must satisfy the game's turn rule, and in
// a network game the moves the host applied must be exactly the ones tapped,
// by the device of the player who made them.
//
// Adapters for the other games are KLD-090.
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';
import '../e2e_support.dart';

/// `KLUNKI_LIVE_UI_VERBOSE=1` prints every device's turn log.
final bool liveUiVerbose = Platform.environment['KLUNKI_LIVE_UI_VERBOSE'] == '1';

/// A network game fails when no device applied or showed anything new for
/// this long (wall clock, and at least 300 rounds): a hang, not a slow machine.
const noProgressLimit = Duration(minutes: 2);

/// Per-test backstop of the live UI files. Only a backstop: hangs are caught
/// by [noProgressLimit] and the per-step waits. A whole network game is a few
/// hundred real socket round trips and frames of two apps; on a machine busy
/// with other test runs it took 6+ min (KLD-109), so the old 8 min budget
/// failed healthy games.
const liveUiTimeout = Timeout(Duration(minutes: 20));

/// One device in a test: the whole tree (hot-seat) or a keyed half (network).
class UiDevice {
  final String name;
  final Key? scope;

  /// The local player of a network device; null for hot-seat (both).
  final Player? me;

  UiDevice(this.name, {this.scope, this.me});

  Finder on(Finder f) => scope == null ? f : find.descendant(of: find.byKey(scope!), matching: f);
  bool has(Finder f) => on(f).evaluate().isNotEmpty;
  bool hasKey(Key k) => has(find.byKey(k));

  GameController controller(WidgetTester tester) => tester.widget<GameScreen>(on(find.byType(GameScreen))).controller;

  bool get networked => me != null;

  /// A real tap (hit-tested like a finger) plus the post-frame pump.
  Future<void> tap(WidgetTester tester, Finder f) async {
    final target = on(f);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, Key k) => tap(tester, find.byKey(k));

  bool resultShown() => hasKey(const Key('result-dialog'));

  /// A dialog is open (or still animating in or out): its barrier takes
  /// every tap meant for the screen below.
  bool get dialogOpen => has(find.byType(Dialog));

  @override
  String toString() => name;
}

/// One turn result: as a device showed it, or as the engine recorded it.
/// Equality ignores [index] and [source].
class TurnRecord {
  final int index;
  final Player actor;

  /// What the actor did, e.g. the chosen stat id.
  final String action;

  /// The outcome as text (e.g. "won by X", "tie"), compared verbatim.
  final String outcome;

  /// Public details that identify the turn (e.g. both card ids).
  final String detail;

  /// Who acts next by the rules, from this record alone (null: unknown).
  final Player? nextActor;

  final String source;

  const TurnRecord({
    required this.index,
    required this.actor,
    required this.action,
    required this.outcome,
    required this.detail,
    this.nextActor,
    this.source = '',
  });

  TurnRecord at(int i, String src) => TurnRecord(
      index: i, actor: actor, action: action, outcome: outcome, detail: detail, nextActor: nextActor, source: src);

  String get key => '${playerMark(actor)}|$action|$outcome|$detail';

  @override
  bool operator ==(Object other) => other is TurnRecord && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => '#${index.toString().padLeft(3)} ${playerMark(actor)} $action → $outcome ($detail)';
}

/// What one player tapped (network: checked against the host's log).
class TappedMove {
  final Player player;
  final Map<String, dynamic> move;
  TappedMove(this.player, this.move);
  @override
  String toString() => '${playerMark(player)} $move';
}

/// Per-game knowledge for the driver.
abstract class LiveUiAdapter {
  String get gameId;

  /// The turn result [device] shows right now, or null (no result on
  /// screen). Also checks what the screen shows against [engine] (the
  /// authoritative game) where that is possible, e.g. whose card is up.
  TurnRecord? observe(WidgetTester tester, UiDevice device, Game engine, {required bool inSync});

  /// Dismisses the result on screen ("Weiter"); false if not possible now.
  Future<bool> dismiss(WidgetTester tester, UiDevice device);

  /// Chooses a move from what [device] shows and taps it. Returns the move
  /// (as submitted), or null if [device] cannot move now.
  Future<Map<String, dynamic>?> play(WidgetTester tester, UiDevice device, Random rng);

  /// Optional clean-up a user would do before going on (e.g. closing a
  /// peek overlay before the game can end). Returns a description, or null.
  Future<String?> tidy(WidgetTester tester, UiDevice device) async => null;

  /// Optional side action a real user might do (e.g. a peek overlay).
  /// Returns a description, or null if it did nothing.
  Future<String?> fidget(WidgetTester tester, UiDevice device, Random rng) async => null;

  /// Checks a turn result while [device] shows it (every observation, not
  /// only the first), e.g. the status line next to it. [behind] is how many
  /// newer turns the device already knows (queued behind the one shown);
  /// -1 for a hot-seat preview that is not submitted yet.
  void checkShown(WidgetTester tester, UiDevice device, TurnRecord shown, {required int behind}) {}

  /// Hot-seat: checks the handover cover on screen against [c] (the
  /// driver already checked that its headline names the player to move).
  void checkCover(WidgetTester tester, UiDevice device, GameController c) {}

  /// Hot-seat, after the game: [coversAt] lists the number of accepted moves
  /// at each handover cover the device showed.
  void checkCovers(List<int> coversAt, GameController c, String context) {}

  /// The authoritative turn list from an accepted move log.
  List<TurnRecord> engineTurns(GameController c);

  /// Checks the game's turn rule over [turns] (e.g. trick winner picks next).
  void checkTurnRule(List<TurnRecord> turns, String context) {
    for (var i = 1; i < turns.length; i++) {
      final want = turns[i - 1].nextActor;
      if (want == null) continue;
      expect(turns[i].actor, want,
          reason: '$context: turn $i should be ${playerMark(want)}\'s after ${turns[i - 1]}, got ${turns[i]}');
    }
  }
}

/// The turn logs of one game, per device.
class LiveUiLog {
  final String label;
  final Map<String, List<TurnRecord>> shown = {};
  final List<String> events = [];
  final List<TappedMove> tapped = [];
  List<TurnRecord> engine = const [];

  LiveUiLog(this.label);

  final Stopwatch _clock = Stopwatch()..start();
  String get _t => (_clock.elapsedMilliseconds / 1000).toStringAsFixed(1).padLeft(6);

  /// Logs [r] as shown on [d]. [context] is what else the screen says at
  /// that moment (e.g. the status line), for the log only.
  void add(UiDevice d, TurnRecord r, {String context = ''}) {
    final list = shown.putIfAbsent(d.name, () => []);
    list.add(r.at(list.length, d.name));
    events.add('$_t ${d.name.padRight(8)} sees  ${list.last}$context');
  }

  /// Turns that [device] showed while its game was already further on
  /// (a queued reveal): (shown index, moves known, status line).
  final Map<String, List<(int, int, String)>> behind = {};

  void note(UiDevice d, String what) => events.add('$_t ${d.name.padRight(8)} $what');

  /// Prints [dump] when `KLUNKI_LIVE_UI_VERBOSE=1`.
  void printIfVerbose() {
    // ignore: avoid_print
    if (liveUiVerbose) print(dump());
  }

  String dump({int? first}) {
    final b = StringBuffer('== $label: ${engine.length} turns ==\n');
    final ev = first == null ? events : events.take(first);
    for (final e in ev) {
      b.writeln(e);
    }
    return b.toString();
  }

  /// Every device showed every turn once, in engine order.
  void expectComplete() {
    for (final MapEntry(key: device, value: list) in shown.entries) {
      for (var i = 0; i < max(list.length, engine.length); i++) {
        final got = i < list.length ? list[i] : null;
        final want = i < engine.length ? engine[i] : null;
        expect(got, want,
            reason: '$label: $device turn $i shows ${got ?? 'nothing'}, engine has ${want ?? 'nothing'}\n'
                '${dump()}');
      }
    }
  }
}

/// Remembers the last result seen on a device so each one is logged once.
class _Watcher {
  TurnRecord? last;
}

void _observe(WidgetTester tester, LiveUiAdapter a, UiDevice d, _Watcher w, LiveUiLog log, Game engine,
    {required bool inSync}) {
  // Under a dialog (the result, a peek overlay) a result is not really
  // shown: the user cannot read it or tap "Weiter". Only results on the
  // uncovered screen count.
  if (d.dialogOpen) return;
  final r = a.observe(tester, d, engine, inSync: inSync);
  // Turns (e.g. Quartett rounds) this device knows of: not every move is
  // one (a KLD-100 choice or announced stat is not).
  final known = r == null ? 0 : a.engineTurns(d.controller(tester)).length;
  if (r != null && r != w.last) {
    final index = log.shown[d.name]?.length ?? 0;
    final status = d.on(find.byKey(const Key('shell-status')));
    final line = status.evaluate().isEmpty ? '' : tester.widget<Text>(status).data ?? '';
    final lag = known - index - 1;
    if (lag > 0) log.behind.putIfAbsent(d.name, () => []).add((index, known, line));
    log.add(d, r, context: '   [status: "$line"${lag > 0 ? ', $lag newer trick(s) already played' : ''}]');
  }
  if (r != null) {
    final shownIndex = (log.shown[d.name]?.length ?? 1) - 1;
    a.checkShown(tester, d, r, behind: known - shownIndex - 1);
  }
  w.last = r;
}

/// Plays one hot-seat game of [config] through the registered screen to the
/// end (both players tapped like users, handover covers acknowledged).
Future<LiveUiLog> playHotSeat(WidgetTester tester, LiveUiAdapter a, GameConfig config,
    {required Random rng, int maxSteps = 5000}) async {
  final c = GameController.hotSeat(config);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  await tester.pump();
  final d = UiDevice('hot-seat');
  final log = LiveUiLog('hot-seat $config');
  final w = _Watcher();
  final coversAt = <int>[];
  final alive = testRunGuard(tester);
  for (var step = 0; step < maxSteps; step++) {
    alive();
    _observe(tester, a, d, w, log, c.game, inSync: true);
    if (d.resultShown()) break;
    if (d.hasKey(const Key('handover-cover'))) {
      final cover = _coverText(tester, d);
      log.note(d, 'cover "$cover"');
      expect(cover, deL10n.shellHandoverPass(c.game.currentPlayer == Player.a ? 'Anna' : 'Ben'),
          reason: '${log.label}: the handover cover names the player to move');
      a.checkCover(tester, d, c);
      coversAt.add(c.moves.length);
      await d.tapKey(tester, const Key('handover-continue'));
      continue;
    }
    if (await a.dismiss(tester, d)) {
      w.last = null;
      continue;
    }
    final player = c.game.currentPlayer;
    final m = await a.play(tester, d, rng);
    if (m == null) fail('${log.label}: nothing to do at step $step\n${log.dump()}');
    log.tapped.add(TappedMove(player, m));
    log.note(d, 'taps ${m.values.last} as ${playerMark(player)}');
  }
  expect(c.game.isOver, isTrue, reason: '${log.label}: did not end in $maxSteps steps');
  log.engine = a.engineTurns(c);
  a.checkTurnRule(log.engine, log.label);
  a.checkCovers(coversAt, c, log.label);
  log.expectComplete();
  return log;
}

String _coverText(WidgetTester tester, UiDevice d) => [
      for (final e in d.on(find.descendant(of: find.byKey(const Key('handover-cover')), matching: find.byType(Text))).evaluate())
        (e.widget as Text).data ?? '',
    ].first;

/// How a network device behaves.
class NetBehaviour {
  /// Chance a device skips its turn to act in a round (results queue up).
  final double dawdle;

  /// Chance the fake clock jumps 1–6 s after a round (grace periods run out).
  final double wait;

  /// Chance of a side action (e.g. opening "Vorige Runde").
  final double fidget;

  const NetBehaviour({this.dawdle = 0.3, this.wait = 0.2, this.fidget = 0.05});
}

/// Plays one network game of [config]: host (X) and guest (O) side by side,
/// each through its real [NetworkGameSession], until both devices have shown
/// every turn of the finished game.
Future<LiveUiLog> playNetwork(WidgetTester tester, LiveUiAdapter a, GameConfig config,
    {required Random rng, NetBehaviour behaviour = const NetBehaviour(), bool proxy = true, int maxRounds = 20000}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (host, guest, wifi) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(config,
        name: 'Anna', address: loopback, wsPort: null, pingInterval: pingInterval, timeout: widgetNetTimeout);
    final p = proxy ? await WifiProxy.start(h.port!, seed: config.seed) : null;
    final g = await NetworkTransport.join(loopback, p?.port ?? h.port!,
        name: 'Ben', pingInterval: pingInterval, timeout: widgetNetTimeout);
    return (h, g, p);
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    // Fire-and-forget like the app (a `bye` through the proxy may never be
    // answered once the proxy is gone), then let the sockets wind down.
    guest.dispose();
    host.dispose();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await wifi?.close();
    });
  });

  const hostKey = Key('device-host'), guestKey = Key('device-guest');
  Widget phone(Key key, NetworkTransport t) => Expanded(
        child: KeyedSubtree(
            key: key, child: localizedApp(NetworkGameSession(transport: t), debugShowCheckedModeBanner: false)),
      );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [phone(hostKey, host), phone(guestKey, guest)]),
  ));
  final devices = [
    UiDevice('host X', scope: hostKey, me: Player.a),
    UiDevice('guest O', scope: guestKey, me: Player.b),
  ];
  final watchers = {for (final d in devices) d.name: _Watcher()};
  final log = LiveUiLog('network $config${proxy ? ' (Wi-Fi proxy)' : ''}');

  final alive = testRunGuard(tester);
  Future<void> net() async {
    alive();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 3)));
    await tester.pump();
    await tester.pump(); // the shell sets its hint post-frame
  }

  // Wait for both screens.
  for (var i = 0; i < 3000 && devices.any((d) => !d.has(find.byType(GameScreen))); i++) {
    await net();
  }
  final hc = devices[0].controller(tester);
  final controllers = {for (final d in devices) d.name: d.controller(tester)};

  bool done() {
    if (!hc.game.isOver) return false;
    final n = hc.moves.length;
    final turns = a.engineTurns(hc).length; // not every move is a turn (KLD-100)
    return devices.every((d) => controllers[d.name]!.moves.length == n && (log.shown[d.name]?.length ?? 0) >= turns);
  }

  final pending = <String, int>{};
  var rounds = 0;
  final wall = Stopwatch()..start();
  // Hang guard on progress, not on the total (KLD-109): a long game on a
  // busy machine legitimately takes many minutes of wall clock (a 100-round
  // game took 6 min under load and failed a fixed 6 min budget), but some
  // device shows or applies something new every few seconds.
  final sinceProgress = Stopwatch()..start();
  var progress = '';
  var roundsSinceProgress = 0;
  var stuck = 0;
  for (; rounds < maxRounds && !done(); rounds++) {
    // Both devices sit on the result dialog: nothing more can be seen or
    // tapped (the dialog is modal). Give pending timers a few rounds, then stop.
    stuck = devices.every((d) => d.resultShown()) ? stuck + 1 : 0;
    if (stuck > 40) break;
    final now = [
      for (final d in devices) '${controllers[d.name]!.moves.length}/${log.shown[d.name]?.length ?? 0}',
    ].join(' ');
    if (now != progress) {
      progress = now;
      sinceProgress.reset();
      roundsSinceProgress = 0;
    } else if (++roundsSinceProgress > 300 && sinceProgress.elapsed > noProgressLimit) {
      fail('${log.label}: no progress for ${noProgressLimit.inSeconds} s '
          '(${wall.elapsed.inSeconds} s in, moves/shown per device: $now)\n${log.dump()}');
    }
    for (final d in devices) {
      final inSync = controllers[d.name]!.moves.length == hc.moves.length;
      _observe(tester, a, d, watchers[d.name]!, log, hc.game, inSync: inSync);
    }
    final order = List.of(devices)..shuffle(rng);
    for (final d in order) {
      if (rng.nextDouble() < behaviour.dawdle) continue;
      if (rng.nextDouble() < behaviour.fidget) {
        final f = await a.fidget(tester, d, rng);
        if (f != null) {
          log.note(d, f);
          continue;
        }
      }
      final tidied = await a.tidy(tester, d);
      if (tidied != null) {
        log.note(d, tidied);
        continue;
      }
      if (await a.dismiss(tester, d)) {
        log.note(d, 'taps Weiter');
        watchers[d.name]!.last = null;
        continue;
      }
      // A pick in flight (guest: waiting for the host's answer) is not
      // tapped again; the screen would ignore it anyway.
      if (pending[d.name] == controllers[d.name]!.moves.length) continue;
      final before = controllers[d.name]!.moves.length;
      final m = await a.play(tester, d, rng);
      if (m != null) {
        pending[d.name] = before;
        log.tapped.add(TappedMove(d.me!, m));
        log.note(d, 'taps ${m.values.last}');
      }
      final inSync = controllers[d.name]!.moves.length == hc.moves.length;
      _observe(tester, a, d, watchers[d.name]!, log, hc.game, inSync: inSync);
    }
    if (rng.nextDouble() < behaviour.wait || hc.game.isOver) {
      final s = 1 + rng.nextInt(6);
      // Step in 250 ms frames so every reveal that comes and goes is seen.
      for (var t = 0; t < s * 4; t++) {
        await tester.pump(const Duration(milliseconds: 250));
        for (final d in devices) {
          final inSync = controllers[d.name]!.moves.length == hc.moves.length;
          _observe(tester, a, d, watchers[d.name]!, log, hc.game, inSync: inSync);
        }
      }
    }
    await net();
  }
  log.engine = a.engineTurns(hc);
  log.expectComplete();
  expect(done(), isTrue, reason: '${log.label}: not finished after $rounds rounds\n${log.dump()}');
  log.events.add('-- finished after $rounds rounds, ${wall.elapsed.inMilliseconds} ms wall clock');

  log.engine = a.engineTurns(hc);
  a.checkTurnRule(log.engine, log.label);
  // The host applied exactly the tapped moves, each by the tapping player.
  expect([for (final m in hc.moves) '${playerMark(m.player)} ${m.move}'],
      [for (final t in log.tapped) '$t'],
      reason: '${log.label}: host log vs taps');
  // Both devices hold the same log (the guest's redacted for a hidden game:
  // e.g. a host's Quartett choice arrives without its card, KLD-100).
  final gc = controllers[devices[1].name]!;
  final redaction = specById(config.gameId)?.redaction;
  final guestPlayer = devices[1].me!;
  expect([for (final m in gc.moves) m.move],
      [for (final m in hc.moves) redaction?.redactMove(m.move, m.player, guestPlayer) ?? m.move]);
  log.expectComplete();
  return log;
}

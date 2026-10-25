// Helpers for the end-to-end "Android vs iOS over local Wi-Fi" tests
// (e2e_muehle_test.dart): a latency proxy that mimics Wi-Fi, a device wrapper
// that hides whether a phone is host or guest, and a match driver that plays
// a scripted Mühle game step by step, checks both phones after every move and
// writes a narrated transcript.
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/debug/muehle_text.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'support.dart';

/// `KLUNKI_E2E_VERBOSE=1 dart test test/e2e_muehle_test.dart` prints the story.
final bool verbose = Platform.environment['KLUNKI_E2E_VERBOSE'] == '1';

/// Short keepalive so a cut is noticed fast, but generous enough for CI.
const pingInterval = Duration(milliseconds: 250);
const netTimeout = Duration(seconds: 3);

/// A TCP pass-through between the two phones that delays every chunk by a
/// seeded random 5–20 ms (per direction, order preserved), like local Wi-Fi.
/// [cut] drops every connection without a `bye` (Wi-Fi loss); new
/// connections are still accepted afterwards (Wi-Fi comes back).
class WifiProxy {
  final ServerSocket _server;
  final int seed;
  final Duration minDelay, maxDelay;
  final List<_Link> _links = [];
  final Stopwatch _clock = Stopwatch()..start();
  int connections = 0;
  int chunks = 0;

  WifiProxy._(this._server, this.seed, this.minDelay, this.maxDelay);

  static Future<WifiProxy> start(
    int targetPort, {
    int seed = 2024,
    Duration minDelay = const Duration(milliseconds: 5),
    Duration maxDelay = const Duration(milliseconds: 20),
  }) async {
    final proxy = WifiProxy._(await ServerSocket.bind(loopback, 0), seed, minDelay, maxDelay);
    proxy._server.listen((client) async {
      client.done.catchError((_) {});
      final Socket upstream;
      try {
        upstream = await Socket.connect(loopback, targetPort);
      } on SocketException {
        client.destroy();
        return;
      }
      upstream.done.catchError((_) {});
      final n = proxy.connections++;
      final link = _Link(client, upstream);
      proxy._links.add(link);
      proxy._pipe(link, client, upstream, Random(seed + 2 * n));
      proxy._pipe(link, upstream, client, Random(seed + 2 * n + 1));
    });
    return proxy;
  }

  int get port => _server.port;

  void _pipe(_Link link, Socket from, Socket to, Random rng) {
    var chain = Future<void>.value();
    var lastDue = 0;
    final spread = maxDelay.inMicroseconds - minDelay.inMicroseconds;
    void forward(List<int> data) {
      final now = _clock.elapsedMicroseconds;
      final due = max(now + minDelay.inMicroseconds + rng.nextInt(spread + 1), lastDue);
      lastDue = due;
      chain = chain.then((_) async {
        final wait = due - _clock.elapsedMicroseconds;
        if (wait > 0) await Future<void>.delayed(Duration(microseconds: wait));
        if (link.cut) return;
        chunks++;
        to.add(data);
      });
    }

    void close() => chain = chain.then((_) => to.destroy());
    from.listen(forward, onDone: close, onError: (_) => close());
  }

  /// Destroys every live connection without a `bye`.
  void cut() {
    for (final l in _links) {
      l.cut = true;
      l.a.destroy();
      l.b.destroy();
    }
    _links.clear();
  }

  Future<void> close() async {
    cut();
    await _server.close();
  }
}

class _Link {
  final Socket a, b;
  bool cut = false;
  _Link(this.a, this.b);
}

/// One phone in the match, either the host or the guest of the session.
class Device {
  final String os; // 'iOS' / 'Android'
  final String name; // 'iPad (iOS)' / 'Pixel (Android)'
  final KlunkiHost? host;
  KlunkiGuest? guest; // replaced when the guest rejoins as a new instance
  final List<NetEvent> events = [];

  Device.host(this.os, this.name, KlunkiHost this.host) {
    host!.events.listen(events.add);
  }

  Device.guest(this.os, this.name, KlunkiGuest g) : host = null {
    attach(g);
  }

  void attach(KlunkiGuest g) {
    guest = g;
    g.events.listen(events.add);
  }

  bool get isHost => host != null;
  String get role => isHost ? 'host' : 'guest';
  Player get player => host?.me ?? guest!.me;
  MuehleGame get game => (host?.game ?? guest!.game) as MuehleGame;
  List<Map<String, dynamic>> get moves => host?.moves ?? guest!.moves;
  bool get online => host?.guestConnected ?? guest!.connected;

  /// Plays [move]; null = accepted, else the host's rejection reason.
  Future<String?> play(Map<String, dynamic> move) async =>
      isHost ? host!.submitLocal(move) : await guest!.submit(move);

  /// Everything the two phones must agree on.
  Map<String, Object?> get state => {
        'moves': moves,
        'board': game.board,
        'currentPlayer': game.currentPlayer,
        'pendingRemoval': game.pendingRemoval,
        'isOver': game.isOver,
        'winner': game.result.winner,
        'reason': game.result.reason,
      };
}

/// The match "iPad (iOS) as X vs Pixel (Android) as O" over a [WifiProxy].
class MuehleMatch {
  static const config = GameConfig('muehle');
  final MuehleText text = MuehleText(); // only for parse
  final MuehleText shadow = MuehleText(); // narrates and double-checks
  final List<String> script = MuehleText().demoScript;
  final List<String> transcript = [];
  late final List<Map<String, dynamic>> scriptMoves = [for (final c in script) text.parse(c)!];

  final Device ios, android;
  final WifiProxy proxy;
  int played = 0;

  MuehleMatch._(this.ios, this.android, this.proxy);

  Device get hostDevice => ios.isHost ? ios : android;
  Device get guestDevice => ios.isHost ? android : ios;
  Device owner(Player p) => ios.player == p ? ios : android;
  Device other(Device d) => identical(d, ios) ? android : ios;

  /// Starts the session. By default the iPad hosts as X and the Pixel joins
  /// as O; [androidHosts] swaps the roles (the Pixel then hosts as O).
  static Future<MuehleMatch> start({bool androidHosts = false, int seed = 2024}) async {
    const iosName = 'iPad (iOS)', androidName = 'Pixel (Android)';
    final host = await KlunkiHost.start(config,
        address: loopback,
        name: androidHosts ? androidName : iosName,
        hostPlayer: androidHosts ? Player.b : Player.a,
        pingInterval: pingInterval,
        timeout: netTimeout);
    final proxy = await WifiProxy.start(host.port, seed: seed);
    final hostDevice = androidHosts
        ? Device.host('Android', androidName, host)
        : Device.host('iOS', iosName, host);
    final guestName = androidHosts ? iosName : androidName;
    final guest = await KlunkiGuest.connect(loopback, proxy.port,
        name: guestName, pingInterval: pingInterval, timeout: netTimeout);
    final guestDevice = Device.guest(androidHosts ? 'iOS' : 'Android', guestName, guest);
    final match = androidHosts
        ? MuehleMatch._(guestDevice, hostDevice, proxy)
        : MuehleMatch._(hostDevice, guestDevice, proxy);
    match.log('[net] ${hostDevice.name} hosts Mühle on 127.0.0.1:${host.port} as '
        '${match.shadow.mark(hostDevice.player)}; Wi-Fi simulated by a proxy on :${proxy.port} '
        '(${proxy.minDelay.inMilliseconds}-${proxy.maxDelay.inMilliseconds} ms, seed $seed)');
    match.log('[net] ${guestDevice.name} joined as ${match.shadow.mark(guestDevice.player)}, '
        'token ${guest.token!.substring(0, 6)}…');
    expect(guest.config, config);
    expect(match.ios.player, Player.a, reason: 'iOS plays X');
    expect(match.android.player, Player.b, reason: 'Android plays O');
    await until(() => host.guestConnected);
    return match;
  }

  void log(String line) {
    transcript.add(line);
    if (verbose) print(line);
  }

  bool get done => played == script.length;
  Player get toMove => shadow.game.currentPlayer;
  Device get nextMover => owner(toMove);

  /// Plays the next scripted move from whichever phone owns the current
  /// player (Mühle: the mill-maker also makes the removal), then checks that
  /// both phones agree. While the guest is offline only the host plays and
  /// only the host is checked.
  Future<void> step() async {
    final index = played;
    final cmd = script[index];
    final move = scriptMoves[index];
    final mover = nextMover;
    final peer = other(mover);
    final peerOnline = mover.online;
    expect(hostDevice.game.currentPlayer, toMove, reason: 'host engine agrees with the script at #$index');
    expect(await mover.play(move), isNull, reason: '${mover.name} plays "$cmd" (#$index)');
    if (peerOnline) {
      await until(() => peer.moves.length == index + 1);
      assertInSync('after #$index "$cmd"');
    } else {
      expect(mover.isHost, isTrue, reason: 'only the host can play while the guest is offline');
      expect(mover.moves.length, index + 1);
    }
    final event = shadow.game.applyMove(Map.of(move))!;
    expect(mover.game.board, shadow.game.board);
    final arrow = peerOnline ? '${mover.os} → ${peer.os}' : '${mover.os} → (offline ${peer.os})';
    log('[$arrow] #${index.toString().padLeft(2)} ${shadow.mark(mover.player)} ${cmd.padRight(5)} '
        '${shadow.narrate(mover.player, move, event)}');
    played++;
  }

  /// Plays scripted moves until [count] are in the log (default: all).
  Future<void> playUntil([int? count]) async {
    while (played < (count ?? script.length)) {
      await step();
    }
  }

  /// Both phones hold the same log, board, turn and pending removal.
  void assertInSync(String when) {
    expect(android.moves, ios.moves, reason: 'move logs equal $when');
    expect(android.game.board, ios.game.board, reason: 'boards equal $when');
    expect(android.game.currentPlayer, ios.game.currentPlayer, reason: 'turn equal $when');
    expect(android.game.pendingRemoval, ios.game.pendingRemoval, reason: 'pendingRemoval equal $when');
    expect(android.state, ios.state, reason: 'full state equal $when');
  }

  /// The game ended as the script says, identically on both phones.
  void assertFinished() {
    assertInSync('at the end');
    for (final d in [ios, android]) {
      expect(d.moves, hasLength(33), reason: '${d.name}: 33 moves');
      expect(d.moves, scriptMoves, reason: '${d.name}: log equals the demo script');
      expect(d.game.isOver, isTrue, reason: '${d.name}: game over');
      expect(d.game.result.winner, Player.b, reason: '${d.name}: O wins');
      expect(d.game.result.reason, 'opponent has fewer than 3 pieces');
      expect(d.events.whereType<NetError>(), isEmpty, reason: '${d.name}: no protocol errors');
    }
    final g = guestDevice.events.whereType<MoveAccepted>().toList();
    expect([for (final e in g) e.index], List.generate(33, (i) => i), reason: 'guest saw every move once, in order');
    final h = hostDevice.events.whereType<MoveAccepted>().toList();
    expect([for (final e in h) e.index], List.generate(33, (i) => i), reason: 'host logged every move once, in order');
    expect([for (final e in h) e.player], [for (final e in g) e.player]);
    log('[end] ${shadow.status()} after ${ios.moves.length} moves; '
        '${proxy.chunks} chunks crossed the simulated Wi-Fi in ${proxy.connections} connection(s)');
    if (verbose) print(shadow.render());
  }

  Future<void> close() async {
    await guestDevice.guest?.close();
    await proxy.close();
    await hostDevice.host!.close();
  }
}

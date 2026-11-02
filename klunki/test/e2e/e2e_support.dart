// Helpers for the app-level e2e tests (KLD-037b): two complete app stacks
// (GameController + NetworkTransport) in one process, talking over TCP on
// 127.0.0.1, optionally through a seeded latency proxy that mimics Wi-Fi.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// `KLUNKI_E2E_VERBOSE=1 flutter test test/e2e` prints a narrated transcript.
final bool verbose = Platform.environment['KLUNKI_E2E_VERBOSE'] == '1';

final loopback = InternetAddress.loopbackIPv4;

/// Short keepalive so a cut is noticed fast, generous enough for a busy CI.
const pingInterval = Duration(milliseconds: 100);
const netTimeout = Duration(seconds: 2);

/// Timeout for transports driven from a `testWidgets` body: a synchronous
/// `tester.pump()` can block the isolate (and so the pongs) for more than
/// 2 s on a loaded machine. Use [netTimeout] only where a cut must be noticed.
const widgetNetTimeout = Duration(seconds: 10);

const muehleConfig = GameConfig('muehle');

/// Polls [condition] with real 2 ms delays until it holds. In a
/// `testWidgets` call it inside `tester.runAsync`.
///
/// Throws only after [limit] of wall clock *and* [minPolls] polls (KLD-109):
/// a starved or sleeping machine spends wall clock without running the
/// event loop, so the polls (each one a turn for the sockets) are counted.
Future<void> until(bool Function() condition,
    {Duration limit = const Duration(seconds: 5), int minPolls = 1000, String? what}) async {
  final sw = Stopwatch()..start();
  for (var polls = 0; !condition(); polls++) {
    if (sw.elapsed > limit && polls >= minPolls) {
      throw TimeoutException('condition not met${what == null ? '' : ': $what'} ($polls polls)', limit);
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

/// One "phone": a [GameController] on top of a [NetworkTransport].
class AppStack {
  final String name; // 'iPad (iOS)' / 'Pixel (Android)'
  NetworkTransport transport;
  GameController controller;

  AppStack(this.name, this.transport) : controller = GameController(transport);

  /// Host "iOS" device: plays X.
  static Future<AppStack> host(
          {String name = 'iPad (iOS)', GameConfig config = muehleConfig, Duration timeout = netTimeout}) async =>
      AppStack(name,
          await NetworkTransport.host(config, name: name, address: loopback, pingInterval: pingInterval, timeout: timeout));

  /// Guest "Android" device: joins [port] and plays O.
  static Future<AppStack> join(int port,
          {String name = 'Pixel (Android)', String? token, Duration timeout = netTimeout}) async =>
      AppStack(name, await joinTransport(port, name: name, token: token, timeout: timeout));

  static Future<NetworkTransport> joinTransport(int port,
          {String name = 'Pixel (Android)', String? token, Duration timeout = netTimeout}) =>
      NetworkTransport.join(loopback, port, name: name, token: token, pingInterval: pingInterval, timeout: timeout);

  /// Replaces the stack after an app restart (the old controller is disposed).
  Future<void> replace(NetworkTransport next) async {
    controller.dispose();
    await transport.close();
    transport = next;
    controller = GameController(next);
  }

  MuehleGame get game => controller.game as MuehleGame;
  int get moveCount => controller.moves.length;
  bool get online => transport.connection.value == NetConnectionState.connected;

  /// Everything the two phones must agree on.
  Map<String, Object?> get state {
    final g = game;
    return {
      'moves': jsonEncode([for (final m in controller.moves) m.move]),
      'indexes': [for (final m in controller.moves) m.index],
      'players': [for (final m in controller.moves) m.player],
      'board': List.of(g.board),
      'currentPlayer': g.currentPlayer,
      'pendingRemoval': g.pendingRemoval,
      'historyLength': g.history.length,
      'isOver': g.isOver,
      'winner': g.result.winner,
      'draw': g.result.draw,
      'reason': g.result.reason,
    };
  }

  Future<void> close() async {
    controller.dispose();
    await transport.close();
  }
}

/// Both stacks hold the same log, board, turn, pending removal and result;
/// exactly one of them may act while the game runs.
void expectInSync(AppStack a, AppStack b, String when) {
  expect(b.state, a.state, reason: 'state equal $when');
  if (!a.game.isOver) {
    expect(a.controller.canAct != b.controller.canAct, isTrue, reason: 'exactly one device may act $when');
  } else {
    expect(a.controller.canAct || b.controller.canAct, isFalse, reason: 'nobody acts after the end');
  }
}

/// A TCP pass-through between the two phones that delays every chunk by a
/// seeded random [minDelay]–[maxDelay] (per direction, order preserved), like
/// local Wi-Fi. [cut] drops every connection without a `bye` (Wi-Fi loss);
/// new connections are still accepted afterwards (Wi-Fi comes back).
/// Same design as `packages/klunki_net/test/e2e_support.dart` (KLD-037a).
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';

final loopback = InternetAddress.loopbackIPv4;

Future<KlunkiHost> startHost(
  GameConfig config, {
  Duration pingInterval = const Duration(milliseconds: 50),
  Duration timeout = const Duration(seconds: 2),
}) =>
    KlunkiHost.start(config, address: loopback, name: 'Host', pingInterval: pingInterval, timeout: timeout);

Future<KlunkiGuest> joinHost(int port, {String name = 'Guest', String? token}) =>
    KlunkiGuest.connect(loopback, port, name: name, token: token);

/// Polls [condition] until it holds (fails after [limit]).
Future<void> until(bool Function() condition, {Duration limit = const Duration(seconds: 5)}) async {
  final sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > limit) throw TimeoutException('condition not met', limit);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

/// The legal moves of [game] as move maps (Four in a Row lists column ints;
/// a Schiffe setup without room for the next ship falls back to autoplace).
List<Map<String, dynamic>> legalMoves(Game game, Random rng) {
  if (game is Connect4Game) return [for (final c in game.legalMoves) {'col': c}];
  final moves = (game as dynamic).legalMoves as List<Map<String, dynamic>>;
  if (moves.isEmpty && game is SchiffeGame && game.phase == SchiffePhase.setup) {
    return [{'action': 'autoplace', 'seed': rng.nextInt(1 << 30)}];
  }
  return moves;
}

/// A hand-driven protocol peer for edge cases: sends raw lines and records
/// every decoded message it receives.
class RawPeer {
  final Socket socket;
  final List<Map<String, dynamic>> received = [];
  final List<String> rawLines = [];
  bool closed = false;
  int _cursor = 0;

  RawPeer(this.socket) {
    socket.done.catchError((_) {});
    socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        rawLines.add(line);
        received.add(jsonDecode(line) as Map<String, dynamic>);
      },
      onError: (_) => closed = true,
      onDone: () => closed = true,
    );
  }

  static Future<RawPeer> connect(int port) async => RawPeer(await Socket.connect(loopback, port));

  void line(String raw) => socket.writeln(raw);
  void send(String type, [Map<String, dynamic> fields = const {}]) =>
      line(jsonEncode({'type': type, 'v': 2, ...fields}));

  /// Next message of [type] after the previous [next] result (others skipped).
  Future<Map<String, dynamic>> next(String type) async {
    while (true) {
      await until(() => _cursor < received.length);
      final m = received[_cursor++];
      if (m['type'] == type) return m;
    }
  }

  void destroy() => socket.destroy();
}

/// A TCP pass-through whose connections can be cut, to simulate Wi-Fi loss.
class Proxy {
  final ServerSocket server;
  final List<Socket> _sockets = [];
  Proxy._(this.server);

  static Future<Proxy> start(int targetPort) async {
    final proxy = Proxy._(await ServerSocket.bind(loopback, 0));
    proxy.server.listen((client) async {
      final upstream = await Socket.connect(loopback, targetPort);
      proxy._sockets.addAll([client, upstream]);
      for (final s in [client, upstream]) {
        s.done.catchError((_) {});
      }
      client.listen(upstream.add, onDone: upstream.destroy, onError: (_) => upstream.destroy());
      upstream.listen(client.add, onDone: client.destroy, onError: (_) => client.destroy());
    });
    return proxy;
  }

  int get port => server.port;

  /// Destroys every connection without a `bye`.
  void cut() {
    for (final s in _sockets) {
      s.destroy();
    }
    _sockets.clear();
  }

  Future<void> close() async {
    cut();
    await server.close();
  }
}

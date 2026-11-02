import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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

/// The fields of a current guest's `hello` (KLD-085: with the build and
/// the fingerprints of every game).
Map<String, dynamic> guestHello(Object? name, {String? token}) => {
      'role': 'guest',
      if (name != null) 'name': name,
      'protocol': protocolVersion,
      if (token != null) 'token': token,
      'build': 'test',
      'games': BuildCompat().gamesJson(),
    };

/// The fields of a current host's `hello` for [config] (KLD-085: with the
/// game's fingerprint).
Map<String, dynamic> hostHello(GameConfig config, {Object? name}) => {
      'role': 'host',
      if (name != null) 'name': name,
      'protocol': protocolVersion,
      'build': 'test',
      'game': compatKey(config),
      'fingerprint': fingerprintOf(config)!.toJson(),
    };

/// Polls [condition] until it holds.
///
/// Fails only after [limit] of wall clock *and* [minPolls] polls (KLD-109):
/// a starved or sleeping machine spends wall clock without running the
/// event loop, so the polls (each one a turn for the sockets) are counted.
Future<void> until(bool Function() condition, {Duration limit = const Duration(seconds: 5), int minPolls = 1000}) async {
  final sw = Stopwatch()..start();
  for (var polls = 0; !condition(); polls++) {
    if (sw.elapsed > limit && polls >= minPolls) throw TimeoutException('condition not met ($polls polls)', limit);
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
  void send(String type, [Map<String, dynamic> fields = const {}, int v = protocolVersion]) =>
      line(jsonEncode({'type': type, 'v': v, ...fields}));

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
        unawaited(s.done.catchError((_) {}));
      }
      client.listen(upstream.add, onDone: upstream.destroy, onError: (_) => upstream.destroy());
      upstream.listen(client.add, onDone: client.destroy, onError: (_) => client.destroy());
    });
    return proxy;
  }

  int get port => server.port;

  /// Resets every connection hard (TCP RST instead of FIN), as a crashed
  /// peer or a NAT dropping the flow does: both ends then see
  /// "connection reset by peer" on reads and on writes still in flight.
  void reset() {
    // Arm every socket first: destroying one ends its stream synchronously,
    // and the pass-through then destroys the other end with a plain FIN.
    for (final s in _sockets) {
      lingerZero(s);
    }
    cut();
  }

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

/// Sets `SO_LINGER {on, 0}` on [socket], so its close sends RST instead of
/// FIN and drops anything unsent: the peer gets ECONNRESET.
void lingerZero(Socket socket) {
  // struct linger { int l_onoff; int l_linger; } is two native ints on
  // macOS and Linux; SO_LINGER differs (0x80 on Darwin/BSD, 13 on Linux).
  final linger = Uint8List(8)..buffer.asByteData().setInt32(0, 1, Endian.host);
  final soLinger = Platform.isLinux || Platform.isAndroid ? 13 : 0x80;
  socket.setRawOption(RawSocketOption(RawSocketOption.levelSocket, soLinger, linger));
}

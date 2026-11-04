// KLD-120: a phone that locks during a network game. The guest reconnects
// by itself (with retries) when the connection drops and when the app comes
// back from the background; a host comes back to its relay room. The
// suspension itself (SIGSTOP) is tested in packages/klunki_net
// (test/suspend_test.dart); here the app's transport reacts to the drop.
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/relay_server.dart';

final _loopback = InternetAddress.loopbackIPv4;
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 1);

/// Polls [condition] until it holds (fails after [limit] and enough polls,
/// so a starved machine does not fail it early, KLD-109).
Future<void> _until(
  bool Function() condition, {
  Duration limit = const Duration(seconds: 10),
  String what = 'condition',
}) async {
  final sw = Stopwatch()..start();
  for (var polls = 0; !condition(); polls++) {
    if (sw.elapsed > limit && polls >= 1000) throw TimeoutException('$what not met', limit);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

/// A TCP pass-through on a fixed port that can cut its connections and stop
/// listening (the host's phone unreachable), then listen again.
class _Proxy {
  ServerSocket? _server;
  final int target;
  final List<Socket> _sockets = [];
  late int port;
  _Proxy._(this.target);

  static Future<_Proxy> start(int target) async {
    final p = _Proxy._(target);
    await p._listen(0);
    return p;
  }

  Future<void> _listen(int at) async {
    final server = _server = await ServerSocket.bind(_loopback, at);
    port = server.port;
    server.listen((client) async {
      final upstream = await Socket.connect(_loopback, target);
      _sockets.addAll([client, upstream]);
      for (final s in [client, upstream]) {
        s.done.catchError((_) {});
      }
      client.listen(upstream.add, onDone: upstream.destroy, onError: (_) => upstream.destroy());
      upstream.listen(client.add, onDone: client.destroy, onError: (_) => client.destroy());
    });
  }

  void cut() {
    for (final s in _sockets) {
      s.destroy();
    }
    _sockets.clear();
  }

  /// Cuts everything and stops listening: connecting fails.
  Future<void> down() async {
    cut();
    await _server?.close();
    _server = null;
  }

  Future<void> up() => _listen(port);

  Future<void> close() => down();
}

Future<NetworkTransport> _host() => NetworkTransport.host(
  const GameConfig('connect4'),
  name: 'Ada',
  address: _loopback,
  pingInterval: _ping,
  timeout: _timeout,
);

Future<NetworkTransport> _guest(int port, {Duration reconnectFor = NetworkTransport.defaultReconnectFor}) =>
    NetworkTransport.join(
      _loopback,
      port,
      name: 'Bea',
      pingInterval: _ping,
      timeout: _timeout,
      reconnectFor: reconnectFor,
    );

/// Records [t]'s connection states.
List<NetConnectionState> _states(NetworkTransport t) {
  final states = <NetConnectionState>[];
  t.connectionChanges.listen(states.add);
  return states;
}

void main() {
  late NetworkTransport host;
  late _Proxy proxy;
  setUp(() async {
    host = await _host();
    proxy = await _Proxy.start(host.port!);
  });
  tearDown(() async {
    await host.close();
    await proxy.close();
  });

  test('the connection drops: the guest reconnects by itself and gets the missed move', () async {
    final guest = await _guest(proxy.port);
    addTearDown(guest.close);
    final states = _states(guest);
    expect((await host.submit({'col': 3})).isAccepted, isTrue);
    await _until(() => guest.moves.length == 1);

    proxy.cut();
    await _until(() => host.connection.value == NetConnectionState.peerMissing, what: 'host notices');
    // The host's move while the guest is away arrives with the rejoin.
    await _until(
      () =>
          guest.connection.value == NetConnectionState.connected &&
          host.connection.value == NetConnectionState.connected,
      what: 'back',
    );
    expect(states, containsAllInOrder([NetConnectionState.reconnecting, NetConnectionState.connected]));
    expect((await guest.submit({'col': 4})).isAccepted, isTrue);
    await _until(() => host.moves.length == 2);
  });

  test('the host is unreachable for a while: the guest keeps trying, then gets back in', () async {
    final guest = await _guest(proxy.port);
    addTearDown(guest.close);
    await proxy.down();
    await _until(() => guest.connection.value == NetConnectionState.reconnecting, what: 'retrying');
    await Future<void>.delayed(const Duration(seconds: 2)); // several failed tries
    expect(guest.connection.value, NetConnectionState.reconnecting);
    expect(guest.reconnectError, isNull);

    await proxy.up();
    await _until(() => guest.connection.value == NetConnectionState.connected, what: 'back');
    expect((await host.submit({'col': 3})).isAccepted, isTrue);
    await _until(() => guest.moves.length == 1);
  });

  test('after reconnectFor the guest shows the button; coming back to the app tries again', () async {
    final guest = await _guest(proxy.port, reconnectFor: const Duration(milliseconds: 800));
    addTearDown(guest.close);
    await proxy.down();
    await _until(() => guest.connection.value == NetConnectionState.reconnecting, what: 'retrying');
    await _until(() => guest.connection.value == NetConnectionState.peerMissing, what: 'gives up');
    expect(guest.reconnectError, isNull, reason: 'nothing that rules out another try');

    await proxy.up();
    guest
      ..appPaused()
      ..appResumed();
    expect(guest.connection.value, NetConnectionState.reconnecting);
    await _until(() => guest.connection.value == NetConnectionState.connected, what: 'back');
  });

  test('back from a long pause: the guest renews a connection that still looks fine', () async {
    final guest = await _guest(proxy.port);
    addTearDown(guest.close);
    final states = _states(guest);
    guest.appPaused();
    guest.appResumed(); // short: nothing to do
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(states, isEmpty);

    guest.appPaused();
    await Future<void>.delayed(_timeout); // the host would have dropped a suspended guest
    guest.appResumed();
    await _until(() => states.contains(NetConnectionState.connected), what: 'renewed');
    expect(states.first, NetConnectionState.reconnecting);
    expect(guest.connection.value, NetConnectionState.connected);
  });

  test('the host says goodbye: no automatic reconnect', () async {
    final guest = await _guest(proxy.port);
    addTearDown(guest.close);
    final states = _states(guest);
    await host.close();
    await _until(() => guest.connection.value == NetConnectionState.peerMissing);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    expect(states, [NetConnectionState.peerMissing]);
    expect(guest.lastDisconnectReason, startsWith('peer left'));
  });

  group('through a relay', () {
    late RelayServer relay;
    Uri url() => Uri.parse('ws://127.0.0.1:${relay.port}/relay');
    setUp(() async => relay = await RelayServer.start(port: 0, address: _loopback));
    tearDown(() => relay.close());

    test('the host comes back from the background: back in its room, the guest rejoins by itself', () async {
      final relayHost = await NetworkTransport.hostRelay(
        const GameConfig('connect4'),
        url(),
        name: 'Ada',
        pingInterval: _ping,
        timeout: _timeout,
      );
      addTearDown(relayHost.close);
      final guest = await NetworkTransport.joinRelay(
        url(),
        relayHost.roomCode!,
        name: 'Bea',
        pingInterval: _ping,
        timeout: _timeout,
      );
      addTearDown(guest.close);
      await _until(() => relayHost.connection.value == NetConnectionState.connected);
      final hostStates = _states(relayHost);
      expect((await relayHost.submit({'col': 3})).isAccepted, isTrue);

      relayHost.appPaused();
      await Future<void>.delayed(_timeout);
      relayHost.appResumed();
      await _until(() => hostStates.contains(NetConnectionState.reconnecting), what: 'coming back');
      await _until(
        () =>
            relayHost.connection.value == NetConnectionState.connected &&
            guest.connection.value == NetConnectionState.connected,
        what: 'both back',
      );
      expect(relayHost.roomLost, isNull);
      expect((await guest.submit({'col': 4})).isAccepted, isTrue);
      await _until(() => relayHost.moves.length == 2);
    });

    test('the relay closes the room: the guest does not retry', () async {
      final relayHost = await NetworkTransport.hostRelay(
        const GameConfig('connect4'),
        url(),
        name: 'Ada',
        pingInterval: _ping,
        timeout: _timeout,
      );
      addTearDown(relayHost.close);
      final guest = await NetworkTransport.joinRelay(
        url(),
        relayHost.roomCode!,
        name: 'Bea',
        pingInterval: _ping,
        timeout: _timeout,
      );
      addTearDown(guest.close);
      final states = _states(guest);
      await relay.close();
      await _until(() => guest.connection.value == NetConnectionState.peerMissing);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(states, [NetConnectionState.peerMissing]);
      expect(guest.lastDisconnectReason, 'relay: relay shutting down');
      expect(relayHost.roomLost, isNotNull);
    });
  });
}

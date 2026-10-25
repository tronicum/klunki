import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../game/legal_moves.dart';

final _loopback = InternetAddress.loopbackIPv4;

Future<NetworkTransport> _host(GameConfig config) => NetworkTransport.host(config,
    name: 'Ada', address: _loopback, pingInterval: const Duration(milliseconds: 50), timeout: const Duration(seconds: 2));

Future<NetworkTransport> _join(int port, {String? token}) => NetworkTransport.join(_loopback, port,
    name: 'Bea', token: token, pingInterval: const Duration(milliseconds: 50), timeout: const Duration(seconds: 2));

/// Polls [condition] until it holds (fails after [limit]).
Future<void> _until(bool Function() condition, {Duration limit = const Duration(seconds: 5)}) async {
  final sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > limit) throw TimeoutException('condition not met', limit);
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

String _log(GameController c) => jsonEncode([for (final m in c.moves) m.move]);

/// A TCP pass-through whose connections can be cut, to simulate Wi-Fi loss.
class _Proxy {
  final ServerSocket server;
  final List<Socket> _sockets = [];
  _Proxy._(this.server);

  static Future<_Proxy> start(int targetPort) async {
    final proxy = _Proxy._(await ServerSocket.bind(_loopback, 0));
    proxy.server.listen((client) async {
      final upstream = await Socket.connect(_loopback, targetPort);
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

/// Plays random legal moves on whichever controller may act until the game
/// is over, checking canAct / needsHandover after every synced step.
Future<void> _playOut(GameController host, GameController guest, Random rng) async {
  var steps = 0;
  while (!host.game.isOver) {
    expect(++steps, lessThan(5000), reason: 'game should end');
    await _until(() => guest.moves.length == host.moves.length);
    expect(host.canAct != guest.canAct, isTrue, reason: 'exactly one device may act');
    expect(host.needsHandover || guest.needsHandover, isFalse);
    final actor = host.canAct ? host : guest;
    final legal = legalMoves(actor.game);
    final r = await actor.submit(legal[rng.nextInt(legal.length)]);
    expect(r.isAccepted, isTrue, reason: '$r');
    expect(actor.lastEvent, same(r.event));
  }
  await _until(() => guest.moves.length == host.moves.length);
}

void _expectSameState(GameController host, GameController guest) {
  expect(guest.game.isOver, isTrue);
  expect(guest.game.result.winner, host.game.result.winner);
  expect(guest.game.result.draw, host.game.result.draw);
  expect(guest.game.result.reason, host.game.result.reason);
  expect(guest.game.history.length, host.game.history.length);
  expect(_log(guest), _log(host));
  expect([for (final m in guest.moves) m.index], [for (var i = 0; i < host.moves.length; i++) i]);
  expect([for (final m in guest.moves) m.player], [for (final m in host.moves) m.player]);
  expect(guest.lastEvent!.winner, host.lastEvent!.winner);
  expect(guest.lastEvent!.draw, host.lastEvent!.draw);
  expect(host.canAct || guest.canAct, isFalse);
}

void main() {
  group('full games over two GameControllers', () {
    for (final id in ['connect4', 'muehle']) {
      test('$id ends identically on both devices', () async {
        final host = await _host(GameConfig(id, seed: 5));
        final hostStates = <NetConnectionState>[];
        host.connectionChanges.listen(hostStates.add);
        final guest = await _join(host.port!);
        await _until(() => host.connection.value == NetConnectionState.connected);
        expect(hostStates, [NetConnectionState.connected]);
        expect(host.peerName, 'Bea');
        expect(guest.peerName, 'Ada');
        expect(host.localPlayers, {Player.a});
        expect(guest.localPlayers, {Player.b});
        expect(guest.config, GameConfig(id, seed: 5));

        final hc = GameController(host), gc = GameController(guest);
        var guestNotified = 0;
        gc.addListener(() => guestNotified++);
        await _playOut(hc, gc, Random(id.hashCode));
        _expectSameState(hc, gc);
        expect(guestNotified, gc.moves.length, reason: 'one notification per accepted move');
        expect((await hc.submit({'col': 0})).reason, RejectReason.gameOver);
        expect((await gc.submit({'col': 0})).reason, RejectReason.gameOver);

        gc.dispose();
        await _until(() => host.connection.value == NetConnectionState.peerMissing);
        expect(host.lastDisconnectReason, contains('guest left'), reason: 'guest said bye');
        hc.dispose();
        expect(host.connection.value, NetConnectionState.closed);
        expect(guest.connection.value, NetConnectionState.closed);
      });
    }
  });

  test('canAct only on the device to move; needsHandover never set (hidden info)', () async {
    final host = await _host(const GameConfig('quartett-trumpf', seed: 3));
    final guest = await _join(host.port!);
    final hc = GameController(host), gc = GameController(guest);
    expect(hc.canAct, isTrue);
    expect(gc.canAct, isFalse);
    final rng = Random(1);
    for (var i = 0; i < 20 && !hc.game.isOver; i++) {
      await _until(() => gc.moves.length == hc.moves.length);
      expect(hc.canAct, hc.game.currentPlayer == Player.a);
      expect(gc.canAct, gc.game.currentPlayer == Player.b);
      expect(hc.canAct != gc.canAct, isTrue);
      final actor = hc.canAct ? hc : gc;
      final legal = legalMoves(actor.game);
      expect((await actor.submit(legal[rng.nextInt(legal.length)])).isAccepted, isTrue);
      expect(hc.needsHandover, isFalse);
      expect(gc.needsHandover, isFalse);
    }
    await _until(() => gc.moves.length == hc.moves.length);
    expect(gc.needsHandover || hc.needsHandover, isFalse);
    gc.dispose();
    hc.dispose();
  });

  test('rejections map to RejectReason and never change state', () async {
    final host = await _host(const GameConfig('connect4'));
    final guest = await _join(host.port!);

    // Not your turn (both sides).
    expect((await guest.submit({'col': 0})).reason, RejectReason.notYourTurn);
    expect((await host.submit({'col': 0})).isAccepted, isTrue);
    await _until(() => guest.moves.length == 1);
    expect((await host.submit({'col': 1})).reason, RejectReason.notYourTurn);

    // Illegal / wrong type / not JSON, sent over the wire by the guest.
    expect((await guest.submit({'col': 42})).reason, RejectReason.illegal);
    expect((await guest.submit({'col': 'x'})).reason, RejectReason.illegal);
    expect((await guest.submit({'nope': true})).reason, RejectReason.illegal);
    expect((await guest.submit({'col': Object()})).reason, RejectReason.illegal);
    expect(guest.connection.value, NetConnectionState.connected, reason: 'connection survives');
    expect(guest.moves, hasLength(1));
    expect(host.moves, hasLength(1));

    final ok = await guest.submit({'col': 1});
    expect(ok.isAccepted, isTrue);
    expect(ok.accepted!.index, 1);
    expect(ok.accepted!.player, Player.b);
    expect(guest.moves.last, same(ok.accepted));
    await _until(() => host.moves.length == 2);
    expect((await host.submit({'col': 99})).reason, RejectReason.illegal);

    // Net reason strings.
    expect(NetworkTransport.mapReason('not your turn'), RejectReason.notYourTurn);
    expect(NetworkTransport.mapReason('illegal move'), RejectReason.illegal);
    expect(NetworkTransport.mapReason('move is not JSON'), RejectReason.illegal);
    expect(NetworkTransport.mapReason('game is over'), RejectReason.gameOver);
    expect(NetworkTransport.mapReason('not connected'), RejectReason.disconnected);
    expect(NetworkTransport.mapReason('disconnected'), RejectReason.disconnected);
    expect(NetworkTransport.mapReason('stale index 1 (log has 2 moves)'), RejectReason.notYourTurn);

    // Host leaves with bye (on the guest's turn): the guest sees peerMissing
    // and its submit is rejected as disconnected.
    expect((await host.submit({'col': 2})).isAccepted, isTrue);
    await _until(() => guest.moves.length == 3);
    await host.close();
    await _until(() => guest.connection.value == NetConnectionState.peerMissing);
    expect(guest.lastDisconnectReason, contains('host closed'));
    expect((await guest.submit({'col': 3})).reason, RejectReason.disconnected);
    guest.dispose();
    expect((await guest.submit({'col': 2})).reason, RejectReason.disconnected);
    expect((await host.submit({'col': 2})).reason, RejectReason.disconnected);
  });

  test('disconnect + reconnect resumes; missed moves are emitted once, in order', () async {
    final host = await _host(const GameConfig('connect4', seed: 2));
    final proxy = await _Proxy.start(host.port!);
    final guest = await _join(proxy.port);
    final hc = GameController(host), gc = GameController(guest);
    final seen = <int>[];
    guest.accepted.listen((m) => seen.add(m.index));
    final guestStates = <NetConnectionState>[];
    guest.connectionChanges.listen(guestStates.add);

    expect((await hc.submit({'col': 0})).isAccepted, isTrue);
    await _until(() => gc.moves.length == 1);
    expect((await gc.submit({'col': 1})).isAccepted, isTrue);
    await _until(() => hc.moves.length == 2);
    final before = guest.game;

    proxy.cut();
    await _until(() => guest.connection.value == NetConnectionState.peerMissing);
    await _until(() => host.connection.value == NetConnectionState.peerMissing);
    expect(gc.canAct, isFalse);

    // The host plays on while the guest is away.
    expect((await hc.submit({'col': 0})).isAccepted, isTrue);
    expect(gc.moves, hasLength(2));
    expect((await gc.submit({'col': 1})).reason, RejectReason.notYourTurn, reason: 'stale local view');

    await guest.reconnect();
    expect(guest.connection.value, NetConnectionState.connected);
    await pumpEventQueue(); // connectionChanges is asynchronous
    expect(guestStates, [NetConnectionState.peerMissing, NetConnectionState.reconnecting, NetConnectionState.connected]);
    await _until(() => host.connection.value == NetConnectionState.connected);
    expect(guest.game, isNot(same(before)), reason: 'replayed instance after Resynced');
    expect(gc.moves, hasLength(3));
    expect(gc.lastEvent, same(gc.moves.last.event));
    expect(gc.canAct, isTrue);

    // Play to the end; the guest saw every index exactly once.
    await _playOut(hc, gc, Random(7));
    _expectSameState(hc, gc);
    await pumpEventQueue();
    expect(seen, [for (var i = 0; i < hc.moves.length; i++) i]);

    gc.dispose();
    hc.dispose();
    await proxy.close();
  });

  test('a disconnected guest submit maps to disconnected; reconnect failure keeps peerMissing', () async {
    final host = await _host(const GameConfig('connect4'));
    final proxy = await _Proxy.start(host.port!);
    final guest = await _join(proxy.port);
    expect((await host.submit({'col': 3})).isAccepted, isTrue);
    await _until(() => guest.moves.length == 1);
    proxy.cut();
    await _until(() => guest.connection.value == NetConnectionState.peerMissing);
    expect((await guest.submit({'col': 3})).reason, RejectReason.disconnected);

    await proxy.server.close(); // nothing listening any more
    await expectLater(guest.reconnect(), throwsA(anything));
    expect(guest.connection.value, NetConnectionState.peerMissing);
    await expectLater(host.reconnect(), throwsStateError);
    guest.dispose();
    host.dispose();
  });
}

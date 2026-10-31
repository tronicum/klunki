import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  group('handshake', () {
    test('guest gets config, its player, token and an empty log', () async {
      final host = await startHost(const GameConfig('quartett-sets', seed: 7));
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final guest = await joinHost(host.port, name: 'Bea');

      expect(guest.config, const GameConfig('quartett-sets', seed: 7));
      expect(guest.me, Player.b);
      expect(host.me, Player.a);
      expect(guest.hostName, 'Host');
      expect(guest.token, isNotNull);
      expect(guest.moves, isEmpty);
      expect(guest.game, isA<QuartettGame>());
      await until(() => hostEvents.isNotEmpty);
      expect(hostEvents.single, isA<PeerConnected>().having((e) => e.name, 'name', 'Bea'));
      expect(host.guestName, 'Bea');

      await guest.close();
      await host.close();
    });

    test('raw handshake messages carry type and v', () async {
      final host = await startHost(const GameConfig('connect4'));
      final peer = await RawPeer.connect(host.port);
      peer.send('hello', {'role': 'guest', 'name': 'Raw', 'protocol': 1});
      final hello = await peer.next('hello');
      final welcome = await peer.next('welcome');
      expect(hello, {'type': 'hello', 'v': 1, 'role': 'host', 'name': 'Host', 'protocol': 1});
      expect(welcome['config'], {'game': 'connect4', 'seed': 0});
      expect(welcome['you'], 'b');
      expect(welcome['moves'], isEmpty);
      expect(welcome['token'], isA<String>());
      peer.destroy();
      await host.close();
    });

    test('host may play B', () async {
      final host = await KlunkiHost.start(const GameConfig('connect4'),
          address: loopback, hostPlayer: Player.b);
      final guest = await joinHost(host.port);
      expect(guest.me, Player.a);
      expect(await guest.submit({'col': 2}), isNull);
      await guest.close();
      await host.close();
    });

    test('a second guest is refused while the session is taken', () async {
      final host = await startHost(const GameConfig('connect4'));
      final guest = await joinHost(host.port, name: 'Bea');
      await expectLater(joinHost(host.port, name: 'Mallory'),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('session full'))));
      expect(guest.connected, isTrue);
      await guest.close();
      await host.close();
    });
  });

  group('moves', () {
    test('Four in a Row: host and guest moves are accepted in order on both sides', () async {
      final host = await startHost(const GameConfig('connect4'));
      final guest = await joinHost(host.port);
      final hostSeen = <MoveAccepted>[], guestSeen = <MoveAccepted>[];
      host.accepted.listen(hostSeen.add);
      guest.accepted.listen(guestSeen.add);

      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'col': 4}), isNull);
      expect(host.submitLocal({'col': 3}), isNull);
      await until(() => guest.moves.length == 3 && guestSeen.length == 3);

      final expected = [
        [0, Player.a, {'col': 3}],
        [1, Player.b, {'col': 4}],
        [2, Player.a, {'col': 3}],
      ];
      for (final seen in [hostSeen, guestSeen]) {
        expect([for (final e in seen) [e.index, e.player, e.move]], expected);
      }
      expect(host.moves, guest.moves);
      expect(guest.game.currentPlayer, Player.b);
      expect((guest.game as Connect4Game).board, (host.game as Connect4Game).board);
      await guest.close();
      await host.close();
    });

    test('Schiffe versenken: setup and shots are accepted in order on both sides', () async {
      final host = await startHost(const GameConfig('schiffe'));
      final guest = await joinHost(host.port);
      expect(host.submitLocal({'action': 'autoplace', 'seed': 1}), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'action': 'autoplace', 'seed': 2}), isNull);
      expect((host.game as SchiffeGame).phase, SchiffePhase.battle);
      expect(host.submitLocal({'action': 'fire', 'row': 0, 'col': 0}), isNull);
      await until(() => guest.moves.length == 3);

      expect(guest.moves, host.moves);
      expect([for (final h in guest.game.history) h['player']], [Player.a, Player.b, Player.a]);
      final hg = host.game as SchiffeGame, gg = guest.game as SchiffeGame;
      expect(gg.phase, SchiffePhase.battle);
      expect(gg.currentPlayer, hg.currentPlayer);
      expect(gg.targetGrid(Player.a), hg.targetGrid(Player.a));
      await guest.close();
      await host.close();
    });

    test('GoStrategy: setups and a move travel in order; views agree on both sides', () async {
      const config = GameConfig('gostrategy', seed: 3);
      expect(GameConfig.fromJson(jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>), config);
      final host = await startHost(config);
      final guest = await joinHost(host.port);
      final setup = GoStrategyGame.setupMove(GoStrategyGame.randomSetup(7));
      expect(host.submitLocal(setup), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'action': 'setup', 'pieces': ['flag']}), 'illegal move');
      expect(await guest.submit({'action': 'autosetup', 'seed': 8}), isNull);
      final hg = host.game as GoStrategyGame, gg = guest.game as GoStrategyGame;
      expect(hg.phase, GoStrategyPhase.play);
      expect(host.submitLocal({'action': 'move', 'from': 60, 'to': 50}), isNull);
      await until(() => guest.moves.length == 3);

      expect(jsonEncode(guest.moves), jsonEncode(host.moves));
      expect([for (final h in gg.history) h['player']], [Player.a, Player.b, Player.a]);
      expect(gg.currentPlayer, Player.b);
      expect(gg.viewFor(Player.b), hg.viewFor(Player.b));
      expect(gg.viewFor(Player.a), hg.viewFor(Player.a));
      // The guest's own view hides X's ranks (the full log is on the wire,
      // see PROTOCOL.md "Known limitations").
      expect(gg.viewFor(Player.b)[99].hidden, isTrue);
      await guest.close();
      await host.close();
    });

    test('out-of-turn and illegal moves are rejected without state change', () async {
      final host = await startHost(const GameConfig('connect4'));
      final guest = await joinHost(host.port);
      final rejected = <MoveRejected>[];
      host.events.listen((e) => e is MoveRejected ? rejected.add(e) : null);

      expect(await guest.submit({'col': 0}), 'not your turn');
      expect(host.submitLocal({'col': 9}), 'illegal move');
      expect(host.submitLocal({'col': 'x'}), 'illegal move');
      expect(host.moves, isEmpty);
      expect(host.submitLocal({'col': 0}), isNull);
      expect(host.submitLocal({'col': 1}), 'not your turn');
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'col': 7}), 'illegal move');
      expect(await guest.submit({'col': 'x'}), 'illegal move');
      expect(await guest.submit({'nope': true}), 'illegal move');

      expect(host.moves, [{'col': 0}]);
      expect(guest.moves, [{'col': 0}]);
      expect(host.game.history.length, 1);
      expect(guest.game.history.length, 1);
      expect(guest.game.currentPlayer, Player.b);
      expect(rejected.length, 4);
      expect(guest.connected, isTrue);
      await guest.close();
      await host.close();
    });

    test('duplicate and stale indices', () async {
      final host = await startHost(const GameConfig('connect4'));
      final peer = await RawPeer.connect(host.port);
      peer.send('hello', {'role': 'guest', 'name': 'Raw', 'protocol': 1});
      await peer.next('welcome');
      host.submitLocal({'col': 3});
      expect(await peer.next('accepted'), {'type': 'accepted', 'v': 1, 'index': 0, 'player': 'a', 'move': {'col': 3}});

      peer.send('move', {'index': 1, 'move': {'col': 4}});
      expect((await peer.next('accepted'))['index'], 1);
      // Resend of the same move: confirmed again, applied once.
      peer.send('move', {'index': 1, 'move': {'col': 4}});
      expect(await peer.next('accepted'), {'type': 'accepted', 'v': 1, 'index': 1, 'player': 'b', 'move': {'col': 4}});
      expect(host.moves.length, 2);
      // Stale index with a different move, and an index from the future.
      peer.send('move', {'index': 0, 'move': {'col': 5}});
      expect((await peer.next('rejected'))['reason'], startsWith('stale index'));
      peer.send('move', {'index': 1, 'move': {'col': 5}});
      expect((await peer.next('rejected'))['reason'], startsWith('stale index'));
      peer.send('move', {'index': 9, 'move': {'col': 5}});
      expect((await peer.next('rejected'))['reason'], startsWith('index ahead'));
      expect(host.moves, [{'col': 3}, {'col': 4}]);
      peer.destroy();
      await host.close();
    });

    test('guest ignores a duplicate accepted and reports a gap as an error', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      final peers = <RawPeer>[];
      fake.listen((s) => peers.add(RawPeer(s)));
      final guestFuture = KlunkiGuest.connect(loopback, fake.port);
      await until(() => peers.isNotEmpty);
      final hostPeer = peers.single;
      await hostPeer.next('hello');
      hostPeer.send('welcome', {'config': {'game': 'connect4', 'seed': 0}, 'you': 'b', 'moves': [], 'token': 't'});
      final guest = await guestFuture;
      final accepted = {'index': 0, 'player': 'a', 'move': {'col': 3}};
      hostPeer.send('accepted', accepted);
      hostPeer.send('accepted', accepted);
      await until(() => guest.moves.length == 1);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      hostPeer.send('accepted', {'index': 5, 'player': 'b', 'move': {'col': 1}});
      expect((await hostPeer.next('error'))['message'], contains('gap'));
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(guest.moves, [{'col': 3}]);
      expect(guest.connected, isFalse);
      await guest.close();
      await fake.close();
    });
  });

  group('full random games', () {
    for (final spec in gameSpecs) {
      test('${spec.id} ends identically on both sides', () async {
        final config = GameConfig(spec.id, seed: 11);
        final host = await startHost(config);
        final guest = await joinHost(host.port);
        final rng = Random(spec.id.hashCode);
        var steps = 0;
        while (!host.game.isOver) {
          expect(++steps, lessThan(5000), reason: 'game should end');
          if (host.game.currentPlayer == host.me) {
            final legal = legalMoves(host.game, rng);
            expect(host.submitLocal(legal[rng.nextInt(legal.length)]), isNull);
            final n = host.moves.length;
            await until(() => guest.moves.length == n);
          } else {
            final legal = legalMoves(guest.game, rng);
            expect(await guest.submit(legal[rng.nextInt(legal.length)]), isNull);
          }
        }
        expect(guest.game.isOver, isTrue);
        expect(guest.game.result.winner, host.game.result.winner);
        expect(guest.game.result.draw, host.game.result.draw);
        expect(guest.game.result.reason, host.game.result.reason);
        expect(jsonEncode(guest.moves), jsonEncode(host.moves));
        expect(guest.game.history.length, host.game.history.length);
        expect(host.submitLocal(legalMoves(host.game, rng).firstOrNull ?? {'col': 0}), isNotNull);
        await guest.close();
        await host.close();
      });
    }
  });

  group('connection loss', () {
    test('guest disconnect + reconnect resumes from the snapshot', () async {
      final host = await startHost(const GameConfig('connect4'));
      final proxy = await Proxy.start(host.port);
      final hostEvents = <NetEvent>[];
      host.events.listen(hostEvents.add);
      final guest = await KlunkiGuest.connect(loopback, proxy.port, name: 'Bea');
      final guestEvents = <NetEvent>[];
      guest.events.listen(guestEvents.add);
      final gameBefore = guest.game;

      host.submitLocal({'col': 3});
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'col': 4}), isNull);

      proxy.cut();
      await until(() => !host.guestConnected && !guest.connected);
      expect(hostEvents.whereType<PeerDisconnected>(), hasLength(1));
      expect(guestEvents.whereType<PeerDisconnected>(), hasLength(1));
      expect(await guest.submit({'col': 4}), 'not connected');

      // The host keeps playing while the guest is away.
      expect(host.submitLocal({'col': 3}), isNull);

      await guest.reconnect();
      expect(guest.connected, isTrue);
      expect(guest.moves, host.moves);
      expect(guest.moves.length, 3);
      expect(identical(guest.game, gameBefore), isFalse);
      await until(() => guestEvents.whereType<Resynced>().isNotEmpty);
      expect(guestEvents.whereType<Resynced>().single.moves, 3);
      expect(guestEvents.whereType<MoveAccepted>().map((e) => e.index), [0, 1, 2]);
      await until(() => hostEvents.whereType<PeerConnected>().length == 2);
      expect(hostEvents.whereType<PeerConnected>().last.reconnect, isTrue);

      expect(await guest.submit({'col': 4}), isNull);
      expect(host.moves.length, 4);
      expect(guest.game.currentPlayer, host.game.currentPlayer);
      await guest.close();
      await proxy.close();
      await host.close();
    });

    test('a new guest instance rejoins with the token; a stranger is refused', () async {
      final host = await startHost(const GameConfig('muehle'));
      final first = await joinHost(host.port, name: 'Bea');
      host.submitLocal({'action': 'place', 'to': 0});
      await until(() => first.moves.length == 1);
      final token = first.token!;
      await first.close();
      await until(() => !host.guestConnected);

      await expectLater(joinHost(host.port, name: 'Mallory'), throwsA(isA<NetException>()));
      final again = await joinHost(host.port, name: 'Bea (phone)', token: token);
      expect(again.moves, host.moves);
      expect(again.me, Player.b);
      expect(await again.submit({'action': 'place', 'to': 1}), isNull);
      await again.close();
      await host.close();
    });

    test('a snapshot that does not replay is reported as divergence', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      fake.listen((s) {
        final peer = RawPeer(s);
        peer.next('hello').then((_) => peer.send('welcome', {
              'config': {'game': 'connect4', 'seed': 0},
              'you': 'b',
              'moves': [{'col': 9}],
              'token': 't',
            }));
      });
      await expectLater(KlunkiGuest.connect(loopback, fake.port),
          throwsA(isA<NetException>().having((e) => e.message, 'message', contains('diverged'))));
      await fake.close();
    });
  });

  group('robustness', () {
    test('malformed line -> error + close', () async {
      final host = await startHost(const GameConfig('connect4'));
      for (final bad in ['garbage', '[1,2]', '{"v":1}', '{"type":"hello","v":2}', '{"type":"move","v":1}']) {
        final peer = await RawPeer.connect(host.port);
        peer.line(bad);
        final error = await peer.next('error');
        expect(error['message'], isA<String>(), reason: bad);
        await until(() => peer.closed);
      }
      await host.close();
    });

    test('malformed message from a joined guest disconnects it', () async {
      final host = await startHost(const GameConfig('connect4'));
      final events = <NetEvent>[];
      host.events.listen(events.add);
      final peer = await RawPeer.connect(host.port);
      peer.send('hello', {'role': 'guest', 'name': 'Raw', 'protocol': 1});
      await peer.next('welcome');
      peer.send('move', {'index': 'zero', 'move': {'col': 1}});
      await peer.next('error');
      await until(() => peer.closed && events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.reason, contains('protocol error'));
      await host.close();
    });

    test('ping/pong keeps an idle session alive', () async {
      final host = await startHost(const GameConfig('connect4'),
          pingInterval: const Duration(milliseconds: 20), timeout: const Duration(milliseconds: 150));
      final guest = await KlunkiGuest.connect(loopback, host.port,
          pingInterval: const Duration(milliseconds: 20), timeout: const Duration(milliseconds: 150));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(host.guestConnected, isTrue);
      expect(guest.connected, isTrue);
      await guest.close();
      await host.close();
    });

    test('host detects a silent guest (ping timeout)', () async {
      final host = await startHost(const GameConfig('connect4'),
          pingInterval: const Duration(milliseconds: 20), timeout: const Duration(milliseconds: 150));
      final events = <NetEvent>[];
      host.events.listen(events.add);
      final peer = await RawPeer.connect(host.port); // never answers ping
      peer.send('hello', {'role': 'guest', 'name': 'Raw', 'protocol': 1});
      await peer.next('welcome');
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.timedOut, isTrue);
      expect(peer.received.where((m) => m['type'] == 'ping'), isNotEmpty);
      await host.close();
    });

    test('guest detects a silent host (ping timeout)', () async {
      final fake = await ServerSocket.bind(loopback, 0);
      fake.listen((s) {
        final peer = RawPeer(s);
        peer.next('hello').then((_) => peer.send('welcome', {
              'config': {'game': 'connect4', 'seed': 0},
              'you': 'b',
              'moves': [],
              'token': 't',
            }));
      });
      final guest = await KlunkiGuest.connect(loopback, fake.port,
          pingInterval: const Duration(milliseconds: 20), timeout: const Duration(milliseconds: 150));
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.timedOut, isTrue);
      expect(guest.connected, isFalse);
      await guest.close();
      await fake.close();
    });

    test('bye is reported with its reason', () async {
      final host = await startHost(const GameConfig('connect4'));
      final guest = await joinHost(host.port);
      final events = <NetEvent>[];
      guest.events.listen(events.add);
      await host.close(reason: 'bedtime');
      await until(() => events.whereType<PeerDisconnected>().isNotEmpty);
      expect(events.whereType<PeerDisconnected>().single.reason, contains('bedtime'));
      await guest.close();
    });
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';
import 'package:test/test.dart';

import 'support.dart';

/// KLD-065: a resign is an ordinary move in the log that either player may
/// send at any time; host and guest end with the same result.
void main() {
  const ping = Duration(milliseconds: 50);
  const timeout = Duration(seconds: 2);

  void expectSameEnd(KlunkiHost host, KlunkiGuest guest, Player resigner) {
    for (final g in [host.game, guest.game]) {
      expect(g.isOver, isTrue);
      expect(g.resignedBy, resigner);
      expect(g.result.code, GameEndReason.commonResigned);
      expect(g.result.params, {'player': resigner.index});
      expect(g.result.winner, resigner == Player.a ? Player.b : Player.a);
    }
    if (guest.redacted) {
      // Hidden information (KLD-064): the guest's log is redacted, but the
      // resign itself is not secret.
      expect(guest.moves, hasLength(host.moves.length));
      expect(guest.moves.last, host.moves.last);
    } else {
      expect(jsonEncode(guest.moves), jsonEncode(host.moves));
    }
    expect(guest.game.result.reason, host.game.result.reason);
  }

  /// A resigned hidden-information game: the guest's view shows the
  /// resignation, the host revealed its secrets and the guest verified the
  /// whole game.
  Future<void> expectVerifiedResign(KlunkiHost host, KlunkiGuest guest, Player resigner) async {
    await until(() => guest.moves.length == host.moves.length);
    expect(guest.redacted, isTrue);
    expectSameEnd(host, guest, resigner);
    expect(guest.entries.last.player, resigner);
    expect(guest.entries.last.event?.winner, resigner == Player.a ? Player.b : Player.a);
    await until(() => guest.verification != Verification.pending);
    expect(guest.verificationError, isNull);
    expect(guest.verification, Verification.verified);
  }

  final transports = <String, Future<(KlunkiHost, KlunkiGuest, Future<void> Function())> Function(GameConfig)>{
    'tcp': (config) async {
      final host = await startHost(config);
      final guest = await joinHost(host.port);
      return (host, guest, () async {});
    },
    'ws': (config) async {
      final host = await startHost(config);
      final guest = await KlunkiGuest.connectWebSocket(webSocketUri(loopback.address, host.wsPort!),
          pingInterval: ping, timeout: timeout);
      return (host, guest, () async {});
    },
    'relay': (config) async {
      final relay = await RelayServer.start(port: 0, address: loopback);
      final url = Uri.parse('ws://${loopback.address}:${relay.port}/relay');
      final host = await KlunkiHost.startRelay(config, url, pingInterval: ping, timeout: timeout);
      final guest = await KlunkiGuest.connectRelay(url, host.roomCode!, pingInterval: ping, timeout: timeout);
      await until(() => host.guestConnected);
      return (host, guest, relay.close);
    },
  };

  for (final MapEntry(key: name, value: open) in transports.entries) {
    group(name, () {
      test('the guest resigns off turn; both sides agree', () async {
        final (host, guest, cleanup) = await open(const GameConfig('connect4'));
        final guestSeen = <MoveAccepted>[];
        guest.accepted.listen(guestSeen.add);
        expect(host.submitLocal({'col': 3}), isNull);
        await until(() => guest.moves.length == 1);
        expect(await guest.submit({'col': 4}), isNull);
        expect(host.game.currentPlayer, Player.a);
        // Not B's turn, but B may resign.
        expect(await guest.submit(Game.resignMove(Player.b)), isNull);
        expectSameEnd(host, guest, Player.b);
        await until(() => guestSeen.length == 3);
        expect(guestSeen.last.player, Player.b);
        expect(guestSeen.last.move, {'action': 'resign', 'player': 'b'});
        expect(host.submitLocal({'col': 3}), 'game is over');
        expect(await guest.submit(Game.resignMove(Player.b)), 'game is over');
        await guest.close();
        await host.close();
        await cleanup();
      });

      test('the host resigns off turn during the setup; both sides agree', () async {
        final (host, guest, cleanup) = await open(const GameConfig('schiffe'));
        final guestSeen = <MoveAccepted>[];
        guest.accepted.listen(guestSeen.add);
        expect(host.submitLocal({'action': 'autoplace', 'seed': 1}), isNull);
        await until(() => guest.moves.length == 1);
        expect(host.game.currentPlayer, Player.b);
        expect(host.submitLocal(Game.resignMove(Player.a)), isNull);
        await until(() => guest.moves.length == 2);
        expectSameEnd(host, guest, Player.a);
        await until(() => guestSeen.length == 2);
        expect(guestSeen.map((e) => e.player), [Player.a, Player.a]);
        await until(() => guest.verification != Verification.pending);
        expect(guest.verification, Verification.verified);
        expect(await guest.submit({'action': 'autoplace', 'seed': 2}), 'game is over');
        await guest.close();
        await host.close();
        await cleanup();
      });
    });
  }

  test('nobody can resign for the other player', () async {
    final host = await startHost(const GameConfig('muehle'));
    final guest = await joinHost(host.port);
    expect(await guest.submit(Game.resignMove(Player.a)), 'not your turn');
    expect(host.submitLocal(Game.resignMove(Player.b)), 'not your turn');
    expect(await guest.submit({'action': 'resign'}), 'not your turn');
    expect(host.submitLocal({'action': 'resign', 'player': 'z'}), 'illegal move');
    expect(host.moves, isEmpty);
    expect(guest.connected, isTrue);
    await guest.close();
    await host.close();
  });

  test('a log with an off-turn resign resumes and replays on a rejoining guest', () async {
    final moves = [
      {'col': 3},
      Game.resignMove(Player.a), // A resigns on B's turn
    ];
    final host = await KlunkiHost.start(const GameConfig('connect4'),
        address: loopback, moves: moves, pingInterval: ping, timeout: timeout);
    final guest = await joinHost(host.port);
    expectSameEnd(host, guest, Player.a);
    final hostSeen = <MoveAccepted>[];
    host.accepted.listen(hostSeen.add);
    expect(host.submitLocal({'col': 1}), 'game is over');
    expect(hostSeen, isEmpty);
    await guest.close();
    await host.close();
  });

  /// KLD-065 with KLD-064: a resign in a hidden-information game is not
  /// redacted, ends the game with a `reveal` and verifies on the guest, in
  /// every phase and also with commitments for setups not yet made.
  group('hidden information', () {
    Future<(KlunkiHost, KlunkiGuest)> open(GameConfig config) async {
      final host = await startHost(config);
      return (host, await joinHost(host.port));
    }

    Future<void> close(KlunkiHost host, KlunkiGuest guest) async {
      await guest.close();
      await host.close();
    }

    test('Schiffe: the guest resigns before anybody placed a ship (off turn)', () async {
      final (host, guest) = await open(const GameConfig('schiffe'));
      expect(host.game.currentPlayer, Player.a);
      expect(await guest.submit(Game.resignMove(Player.b)), isNull);
      await expectVerifiedResign(host, guest, Player.b);
      await close(host, guest);
    });

    test('Schiffe: the host resigns off turn after its committed placements', () async {
      final (host, guest) = await open(const GameConfig('schiffe'));
      final layout = SchiffeGame.randomLayout(7);
      for (var i = 0; i < layout.length; i++) {
        expect(host.submitLocal(layout[i].toMove(i)), isNull);
      }
      await until(() => guest.moves.length == layout.length);
      expect(host.game.currentPlayer, Player.b); // the guest's setup is still missing
      expect(host.submitLocal(Game.resignMove(Player.a)), isNull);
      await expectVerifiedResign(host, guest, Player.a);
      await close(host, guest);
    });

    test('Schiffe: the guest resigns off turn in the battle', () async {
      final (host, guest) = await open(const GameConfig('schiffe'));
      expect(host.submitLocal({'action': 'autoplace', 'seed': 3}), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit({'action': 'autoplace', 'seed': 4}), isNull);
      // Shoot until it is the host's turn (a hit gives another shot).
      final rng = Random(1);
      while (host.game.currentPlayer != Player.a || host.moves.length < 3) {
        final game = host.game.currentPlayer == Player.a ? host.game : guest.game;
        final legal = legalMoves(game, rng);
        final move = legal[rng.nextInt(legal.length)];
        if (host.game.currentPlayer == Player.a) {
          expect(host.submitLocal(move), isNull);
          final n = host.moves.length;
          await until(() => guest.moves.length == n);
        } else {
          expect(await guest.submit(move), isNull);
        }
      }
      expect(await guest.submit(Game.resignMove(Player.b)), isNull);
      await expectVerifiedResign(host, guest, Player.b);
      await close(host, guest);
    });

    for (final mode in ['trumpf', 'sets']) {
      test('Quartett $mode: the guest resigns off turn, the seed is revealed and checked', () async {
        final (host, guest) = await open(GameConfig('quartett-$mode', seed: 11));
        expect(host.game.currentPlayer, Player.a);
        expect(await guest.submit(Game.resignMove(Player.b)), isNull);
        await expectVerifiedResign(host, guest, Player.b);
        await close(host, guest);
      });

      test('Quartett $mode: the host resigns off turn mid-game', () async {
        final (host, guest) = await open(GameConfig('quartett-$mode', seed: 12));
        final rng = Random(2);
        while (host.game.currentPlayer != Player.b || host.moves.isEmpty) {
          expect(host.game.isOver, isFalse);
          final game = host.game.currentPlayer == Player.a ? host.game : guest.game;
          final legal = legalMoves(game, rng);
          final move = legal[rng.nextInt(legal.length)];
          if (host.game.currentPlayer == Player.a) {
            expect(host.submitLocal(move), isNull);
            final n = host.moves.length;
            await until(() => guest.moves.length == n);
          } else {
            expect(await guest.submit(move), isNull);
          }
        }
        expect(host.submitLocal(Game.resignMove(Player.a)), isNull);
        await expectVerifiedResign(host, guest, Player.a);
        await close(host, guest);
      });
    }

    test('GoStrategy: the guest resigns during the setup after the host\'s committed setup', () async {
      final (host, guest) = await open(const GameConfig('gostrategy'));
      expect(host.submitLocal({'action': 'autosetup', 'seed': 5}), isNull);
      await until(() => guest.moves.length == 1);
      expect(await guest.submit(Game.resignMove(Player.b)), isNull);
      await expectVerifiedResign(host, guest, Player.b);
      await close(host, guest);
    });
  });
}

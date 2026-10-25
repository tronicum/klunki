import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../game/legal_moves.dart';

/// A transport where only player A is local, to exercise `notYourTurn`.
class _OnlyATransport extends HotSeatTransport {
  _OnlyATransport(super.config);
  @override
  Set<Player> get localPlayers => const {Player.a};
}

void main() {
  test('accepts legal moves for every game in gameSpecs', () async {
    for (final spec in gameSpecs) {
      final t = HotSeatTransport(GameConfig(spec.id, seed: 7));
      for (var i = 0; i < 40 && !t.game.isOver; i++) {
        final legal = legalMoves(t.game);
        final player = t.game.currentPlayer;
        final r = await t.submit(legal[(i * 5) % legal.length]);
        expect(r.isAccepted, isTrue, reason: '${spec.id} move $i: $r');
        expect(r.accepted!.index, i, reason: spec.id);
        expect(r.accepted!.player, player, reason: spec.id);
        expect(r.event, isNotNull);
      }
      expect(t.moves, isNotEmpty, reason: spec.id);
      // The log replays to the same state.
      final r = replay(t.config, t.moves.map((m) => m.move))!;
      expect(r.history.length, t.game.history.length, reason: spec.id);
      t.dispose();
    }
  });

  test('illegal and malformed moves are rejected without state change', () async {
    final t = HotSeatTransport(const GameConfig('connect4'));
    for (final bad in <Map<String, dynamic>>[
      {'col': 9},
      {'col': -1},
      {'col': 'x'},
      {},
    ]) {
      final r = await t.submit(bad);
      expect(r.isAccepted, isFalse);
      expect(r.reason, RejectReason.illegal);
    }
    expect(t.moves, isEmpty);
    expect(t.game.history, isEmpty);
    expect(t.game.currentPlayer, Player.a);

    final m = HotSeatTransport(const GameConfig('muehle'));
    expect((await m.submit({'action': 'fly', 'to': 0})).reason, RejectReason.illegal);
    expect(m.game.history, isEmpty);
  });

  test('out-of-turn moves are rejected with notYourTurn', () async {
    final t = _OnlyATransport(const GameConfig('connect4'));
    expect((await t.submit({'col': 0})).isAccepted, isTrue);
    final r = await t.submit({'col': 1});
    expect(r.reason, RejectReason.notYourTurn);
    expect(t.moves, hasLength(1));
    expect(t.game.currentPlayer, Player.b);
  });

  test('moves after the game is over are rejected with gameOver', () async {
    final t = HotSeatTransport(const GameConfig('connect4'));
    for (final c in [0, 1, 0, 1, 0, 1, 0]) {
      expect((await t.submit({'col': c})).isAccepted, isTrue);
    }
    expect(t.game.isOver, isTrue);
    expect(t.moves.last.event.winner, Player.a);
    final r = await t.submit({'col': 2});
    expect(r.reason, RejectReason.gameOver);
    expect(t.moves, hasLength(7));
  });

  test('disposed transport rejects with disconnected', () async {
    final t = HotSeatTransport(const GameConfig('connect4'))..dispose();
    expect((await t.submit({'col': 0})).reason, RejectReason.disconnected);
  });

  test('accepted stream delivers every accepted move in order, synchronously', () async {
    final t = HotSeatTransport(const GameConfig('connect4'));
    final seen = <AcceptedMove>[];
    t.accepted.listen(seen.add);
    final f1 = t.submit({'col': 3});
    expect(seen, hasLength(1), reason: 'delivered before submit completes');
    await f1;
    await t.submit({'col': 99}); // rejected: not on the stream
    await t.submit({'col': 4});
    await t.submit({'col': 3});
    expect(seen.map((m) => m.index), [0, 1, 2]);
    expect(seen.map((m) => m.move['col']), [3, 4, 3]);
    expect(seen.map((m) => m.player), [Player.a, Player.b, Player.a]);
    expect(seen, t.moves);
  });

  test('submitted moves are copied', () async {
    final t = HotSeatTransport(const GameConfig('connect4'));
    final move = <String, dynamic>{'col': 2};
    await t.submit(move);
    move['col'] = 5;
    expect(t.moves.single.move['col'], 2);
    expect(() => t.moves.single.move['col'] = 1, throwsUnsupportedError);
  });

  test('undo replays the log minus one', () async {
    final t = HotSeatTransport(const GameConfig('connect4'));
    expect(t.canUndo, isFalse);
    expect(t.undo(), isFalse);
    await t.submit({'col': 0});
    await t.submit({'col': 1});
    expect(t.undo(), isTrue);
    expect(t.moves, hasLength(1));
    expect(t.game.history, hasLength(1));
    expect(t.game.currentPlayer, Player.b);
    final r = await t.submit({'col': 6});
    expect(r.accepted!.index, 1);
  });
}

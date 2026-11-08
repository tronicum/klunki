// KLD-119: hot-seat transport and controller by seat for games with more
// than two seats (seats 2 and 3 have no `Player`); two-seat games unchanged.
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  test('AcceptedMove: the seat is the player index unless given', () {
    const e = GameEvent();
    expect(const AcceptedMove(index: 0, player: Player.a, move: {}, event: e).seat, 0);
    expect(const AcceptedMove(index: 0, player: Player.b, move: {}, event: e).seat, 1);
    expect(const AcceptedMove(index: 0, player: Player.a, seat: 3, move: {}, event: e).seat, 3);
    expect(const AcceptedMove(index: 0, player: Player.a, seat: 3, move: {}, event: e).toString(), contains('seat 3'));
  });

  test('a two-seat game: moves carry seats 0 and 1, the controller works by Player', () async {
    final c = GameController.hotSeat(const GameConfig('connect4'));
    addTearDown(c.dispose);
    expect(c.seatGame, isNull);
    await c.submit({'col': 3});
    await c.submit({'col': 4});
    expect(c.moves.map((m) => (m.player, m.seat)), [(Player.a, 0), (Player.b, 1)]);
    // A two-seat dice game is driven through Game too.
    final d = GameController.hotSeat(const GameConfig('dicesheet'));
    addTearDown(d.dispose);
    expect(d.seatGame, isNull);
    expect(d.canResign, {Player.a, Player.b});
    expect(d.canResignSeats, isEmpty);
  });

  test('four seats: every seat acts, moves carry their seat, undo by seat', () async {
    final c = GameController.hotSeat(const GameConfig('dicesheet', seed: 4, players: 4));
    addTearDown(c.dispose);
    final g = c.seatGame!;
    expect(g.playerCount, 4);
    var notified = 0;
    c.addListener(() => notified++);
    for (var seat = 0; seat < 4; seat++) {
      expect(c.canAct, isTrue);
      expect(g.actorSeat, seat);
      expect((await c.submit(DiceSheetGame.rollMove())).isAccepted, isTrue);
      final game = c.game as DiceSheetGame;
      final r = await c.submit(DiceSheetGame.scoreMove(game.allowedBoxes.first));
      expect(r.isAccepted, isTrue);
      expect(r.accepted!.seat, seat);
    }
    expect(c.moves.map((m) => m.seat), [0, 0, 1, 1, 2, 2, 3, 3]);
    expect(c.moves[4].player, Player.a, reason: 'seat 2 has no Player: A as a placeholder');
    expect(notified, 8);
    expect(c.needsHandover, isFalse, reason: 'no secrets, no cover');

    // Undo takes back seat 3's entry; the roll before it is final.
    expect(c.canUndo, isTrue);
    expect(c.undo(), isTrue);
    expect((c.game as DiceSheetGame).currentSeat, 3);
    expect((c.game as DiceSheetGame).rollsUsed, 1);
    expect(c.canUndo, isFalse);
    expect(c.undo(), isFalse);
  });

  test('four seats: resign by seat, the others play on; the last one in wins', () async {
    final c = GameController.hotSeat(const GameConfig('dicesheet', seed: 2, players: 4));
    addTearDown(c.dispose);
    expect(c.canResignSeats, [0, 1, 2, 3]);
    expect((await c.resignSeat(2)).accepted!.seat, 2);
    expect(c.canResignSeats, [0, 1, 3]);
    expect(c.game.isOver, isFalse);
    await c.resignSeat(0);
    await c.resignSeat(1);
    expect(c.game.isOver, isTrue);
    expect(c.canAct, isFalse);
    expect(c.canResignSeats, isEmpty);
    expect(c.seatGame!.seatResult.winner, 3);
    // Taken back: the game runs again.
    expect(c.undo(), isTrue);
    expect(c.game.isOver, isFalse);
    expect(c.canResignSeats, [1, 3]);
  });

  test('the transport refuses bad seat moves without changing anything', () {
    final t = HotSeatTransport(const GameConfig('dicesheet', players: 3));
    addTearDown(t.dispose);
    expect(t.submitSync({'action': 'resign', 'seat': 7}).reason, RejectReason.illegal);
    expect(t.submitSync({'action': 'resign', 'player': 'a'}).reason, RejectReason.illegal);
    expect(t.submitSync(DiceSheetGame.scoreMove(DiceBox.chance)).reason, RejectReason.illegal);
    expect(t.moves, isEmpty);
    expect(t.submitSync(DiceSheetGame.rollMove()).accepted!.seat, 0);
  });

  test('restart keeps the player count and the house rule', () {
    final c = GameController.hotSeat(const GameConfig('dicesheet', seed: 1, players: 3, extraFives: true));
    addTearDown(c.dispose);
    c.restart(seed: 9);
    expect(c.config, const GameConfig('dicesheet', seed: 9, players: 3, extraFives: true));
    expect(c.seatGame!.playerCount, 3);
  });
}

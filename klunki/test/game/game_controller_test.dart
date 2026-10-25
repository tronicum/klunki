import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'legal_moves.dart';

class _OnlyATransport extends HotSeatTransport {
  _OnlyATransport(super.config);
  @override
  Set<Player> get localPlayers => const {Player.a};
}

void main() {
  test('exposes config, spec and game; notifies on every accepted move', () async {
    final c = GameController.hotSeat(const GameConfig('connect4', seed: 3));
    var notified = 0;
    c.addListener(() => notified++);
    expect(c.spec.id, 'connect4');
    expect(c.config, const GameConfig('connect4', seed: 3));
    expect(c.lastEvent, isNull);
    expect(c.canAct, isTrue);

    final r = await c.submit({'col': 0});
    expect(r.isAccepted, isTrue);
    expect(notified, 1);
    expect(c.moves, hasLength(1));
    expect(c.lastEvent, same(r.event));
    expect(c.game.currentPlayer, Player.b);

    expect((await c.submit({'col': 42})).reason, RejectReason.illegal);
    expect(notified, 1, reason: 'rejections do not notify');
    c.dispose();
  });

  test('canAct is false when the game is over or the player is remote', () async {
    final c = GameController.hotSeat(const GameConfig('connect4'));
    for (final col in [0, 1, 0, 1, 0, 1, 0]) {
      await c.submit({'col': col});
    }
    expect(c.game.isOver, isTrue);
    expect(c.lastEvent!.winner, Player.a);
    expect(c.canAct, isFalse);
    c.dispose();

    final n = GameController(_OnlyATransport(const GameConfig('connect4')));
    expect(n.canAct, isTrue);
    await n.submit({'col': 0});
    expect(n.canAct, isFalse);
    expect(n.canUndo, isTrue, reason: 'subclass of HotSeatTransport');
    n.dispose();
  });

  test('undo takes back one move and notifies', () async {
    final c = GameController.hotSeat(const GameConfig('muehle'));
    expect(c.canUndo, isFalse);
    expect(c.undo(), isFalse);
    await c.submit(legalMoves(c.game).first);
    final second = await c.submit(legalMoves(c.game).first);
    var notified = 0;
    c.addListener(() => notified++);
    expect(c.undo(), isTrue);
    expect(notified, 1);
    expect(c.moves, hasLength(1));
    expect(c.game.history, hasLength(1));
    expect(c.game.currentPlayer, Player.b);
    expect(c.lastEvent, same(c.moves.last.event));
    expect(c.lastEvent, isNot(same(second.event)));
    expect(c.undo(), isTrue);
    expect(c.lastEvent, isNull);
    expect(c.canUndo, isFalse);
    c.dispose();
  });

  test('restart keeps the seed by default, or uses a new one', () async {
    final c = GameController.hotSeat(const GameConfig('quartett-trumpf', seed: 11));
    final firstTop = (c.game as QuartettGame).topCard(Player.a)!.id;
    await c.submit(legalMoves(c.game).first);
    final old = c.transport;
    var notified = 0;
    c.addListener(() => notified++);

    c.restart();
    expect(notified, 1);
    expect(identical(c.transport, old), isFalse);
    expect((await old.submit(legalMoves(c.game).first)).reason, RejectReason.disconnected);
    expect(c.config.seed, 11);
    expect(c.moves, isEmpty);
    expect(c.lastEvent, isNull);
    expect((c.game as QuartettGame).topCard(Player.a)!.id, firstTop);

    c.restart(seed: 99);
    expect(c.config, const GameConfig('quartett-trumpf', seed: 99));
    expect(c.moves, isEmpty);
    // The new transport is wired up.
    await c.submit(legalMoves(c.game).first);
    expect(c.moves, hasLength(1));
    expect(notified, 3);
    c.dispose();
  });

  test('needsHandover toggles only for hidden-information games', () async {
    for (final spec in gameSpecs) {
      final c = GameController.hotSeat(GameConfig(spec.id, seed: 2));
      var raised = 0;
      for (var i = 0; i < 60 && !c.game.isOver; i++) {
        final player = c.game.currentPlayer;
        final legal = legalMoves(c.game);
        await c.submit(legal[(i * 3) % legal.length]);
        final passed = !c.game.isOver && c.game.currentPlayer != player;
        expect(c.needsHandover, spec.hiddenInformation && passed, reason: '${spec.id} move $i');
        if (c.needsHandover) {
          raised++;
          var notified = 0;
          c.addListener(() => notified++);
          c.acknowledgeHandover();
          expect(c.needsHandover, isFalse);
          expect(notified, 1);
        }
      }
      if (spec.hiddenInformation) {
        expect(raised, greaterThan(0), reason: spec.id);
      } else {
        expect(raised, 0, reason: spec.id);
      }
      c.dispose();
    }
  });

  test('undo across a turn change raises the handover cover; restart clears it', () async {
    final c = GameController.hotSeat(const GameConfig('quartett-trumpf', seed: 4));
    while (c.game.currentPlayer == Player.a) {
      await c.submit(legalMoves(c.game).first);
    }
    expect(c.needsHandover, isTrue);
    c.acknowledgeHandover();
    c.undo();
    expect(c.game.currentPlayer, Player.a);
    expect(c.needsHandover, isTrue);
    c.restart();
    expect(c.needsHandover, isFalse);
    c.dispose();
  });
}

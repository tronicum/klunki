import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-065: resigning works the same in every game, through the shared
/// [Game.applyMove].
void main() {
  Map<String, dynamic> resign(Player p) => Game.resignMove(p);
  Player other(Player p) => p == Player.a ? Player.b : Player.a;

  void expectResigned(Game g, Player by) {
    expect(g.isOver, isTrue);
    expect(g.resignedBy, by);
    final r = g.result;
    expect(r.winner, other(by));
    expect(r.draw, isFalse);
    expect(r.code, GameEndReason.commonResigned);
    expect(r.params, {'player': by.index});
    expect(r.reason, '${by == Player.a ? 'Anna' : 'Ben'} resigned');
  }

  test('resign move shape and parsing', () {
    expect(Game.resignMove(Player.b), {'action': 'resign', 'player': 'b'});
    expect(Game.resignerOf({'action': 'resign', 'player': 'a'}), Player.a);
    expect(Game.resignerOf({'action': 'resign'}), isNull);
    expect(Game.resignerOf({'action': 'resign', 'player': 'c'}), isNull);
    expect(Game.resignerOf({'col': 3}), isNull);
    expect(GameEndReason.fromCode('common.resigned'), GameEndReason.commonResigned);
  });

  for (final spec in gameSpecs) {
    group(spec.id, () {
      for (final by in Player.values) {
        test('${by.name} resigns at the start (${by == Player.a ? 'on' : 'off'} turn)', () {
          final g = spec.create(3);
          expect(g.playerOf(resign(by)), by);
          final e = g.applyMove(resign(by));
          expect(e, isNotNull);
          expect(e!.winner, other(by));
          expect(e.payload, {'resigned': by});
          expectResigned(g, by);
        });
      }

      test('resign later in the game, off turn, then nothing is accepted', () {
        final g = spec.create(3);
        final t = DebugConsole.forGame(spec.id, g);
        for (var i = 0; i < 3 && !g.isOver; i++) {
          expect(g.applyMove(t.legalMoves.first), isNotNull);
        }
        expect(g.isOver, isFalse);
        final off = other(g.currentPlayer);
        final historyBefore = g.history.length;
        expect(g.playerOf(resign(off)), off);
        expect(g.applyMove(resign(off)), isNotNull);
        expectResigned(g, off);
        expect(g.history.length, historyBefore, reason: 'resign is not in the play history');
        // Moves after the end are rejected, including another resign.
        expect(g.applyMove(resign(g.currentPlayer)), isNull);
        expect(g.applyMove(resign(off)), isNull);
        expect(t.legalMoves, isEmpty);
        expectResigned(g, off);
      });

      test('malformed resign is rejected and changes nothing', () {
        final g = spec.create(3);
        expect(g.applyMove({'action': 'resign'}), isNull);
        expect(g.applyMove({'action': 'resign', 'player': 'x'}), isNull);
        expect(g.isOver, isFalse);
        expect(g.resignedBy, isNull);
      });

      test('a resign replays from the move log', () {
        final config = GameConfig(spec.id, seed: 5);
        final g = replay(config, [resign(Player.b)])!;
        expectResigned(g, Player.b);
        expect(replay(config, [resign(Player.b), resign(Player.a)]), isNull);
      });
    });
  }

  group('during setup phases', () {
    test('Schiffe: B resigns while A is still placing', () {
      final g = SchiffeGame();
      expect(g.applyMove({'action': 'place', 'ship': 0, 'row': 0, 'col': 0, 'dir': 'h'}), isNotNull);
      expect(g.phase, SchiffePhase.setup);
      expect(g.currentPlayer, Player.a);
      expect(g.applyMove(resign(Player.b)), isNotNull);
      expectResigned(g, Player.b);
      expect(g.applyMove({'action': 'autoplace', 'seed': 1}), isNull);
      expect(g.legalMoves, isEmpty);
    });

    test('GoStrategy: A resigns after its setup, while B sets up', () {
      final g = GoStrategyGame();
      g.applyMove({'action': 'autosetup', 'seed': 1});
      expect(g.currentPlayer, Player.b);
      expect(g.applyMove(resign(Player.a)), isNotNull);
      expectResigned(g, Player.a);
      expect(g.applyMove({'action': 'autosetup', 'seed': 2}), isNull);
      expect(g.phase, GoStrategyPhase.setup);
    });

    test('Mühle: resign while a removal is pending', () {
      final g = MuehleGame();
      for (final m in [
        {'action': 'place', 'to': 0},
        {'action': 'place', 'to': 9},
        {'action': 'place', 'to': 1},
        {'action': 'place', 'to': 10},
        {'action': 'place', 'to': 2},
      ]) {
        expect(g.applyMove(m), isNotNull, reason: '$m');
      }
      expect(g.pendingRemoval, isTrue);
      expect(g.applyMove(resign(Player.b)), isNotNull);
      expectResigned(g, Player.b);
    });
  });

  test('a finished game cannot be resigned', () {
    final g = Connect4Game();
    for (final c in [0, 1, 0, 1, 0, 1, 0]) {
      g.applyMove({'col': c});
    }
    expect(g.result.code, GameEndReason.connect4FourInARow);
    expect(g.applyMove(resign(Player.b)), isNull);
    expect(g.result.code, GameEndReason.connect4FourInARow);
    expect(g.resignedBy, isNull);
  });

  group('debug console', () {
    test('resign, history and undo', () {
      final c = DebugConsole('connect4');
      c.handle('3');
      final out = c.handle('resign x');
      expect(out, contains('Anna resigns. Ben wins.'));
      expect(out, contains('Ben wins (Anna resigned)'));
      expect(c.handle('history'), contains('2. resign X'));
      expect(c.handle('3'), contains('Illegal move'));
      c.handle('undo');
      expect(c.current.game.isOver, isFalse);
      expect(c.handle('resign').split('\n').first, 'Ben resigns. Anna wins.');
    });

    test('unknown resign target is not a move', () {
      expect(DebugConsole('connect4').handle('resign z'), contains('Unknown command'));
    });
  });

  // KLD-064 + KLD-065: the read-only network views carry a resignation in
  // their JSON, play nothing themselves (a resign included) and stay
  // unresigned while the host's view says so.
  group('views', () {
    for (final id in ['schiffe', 'quartett-trumpf', 'quartett-sets', 'gostrategy']) {
      test('$id: a resign reaches the view through its JSON', () {
        final redaction = specById(id)!.redaction!;
        final game = createGame(GameConfig(id, seed: 3));
        final before = redaction.fromView(redaction.view(game, Player.b));
        expect(before.isOver, isFalse);
        expect(before.resignedBy, isNull);
        expect(before.applyMove(resign(Player.b)), isNull, reason: 'views are read-only');
        expect(before.isOver, isFalse);
        expect(game.applyMove(resign(Player.a)), isNotNull);
        for (final viewer in Player.values) {
          final json = redaction.view(game, viewer);
          expect(json['resigned'], 'a');
          final view = redaction.fromView(json);
          expectResigned(view, Player.a);
          expect((view as dynamic).legalMoves, isEmpty);
          expect(redaction.view(view, viewer), json, reason: 'round trip');
        }
        // The resign is public: neither move nor event is redacted.
        final event = GameEvent(winner: Player.b, payload: {'resigned': Player.a});
        final step = redaction.step(game, resign(Player.a), Player.a, event, Player.b);
        expect(step['move'], resign(Player.a));
        expect(step['event'], {'winner': 'b', 'payload': {'resigned': 'a'}});
      });
    }
  });
}

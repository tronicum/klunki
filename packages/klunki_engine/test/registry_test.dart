import 'package:test/test.dart';
import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  test('every spec creates a fresh game with player A to move', () {
    for (final spec in gameSpecs) {
      final g = spec.create(3);
      expect(g.currentPlayer, Player.a, reason: spec.id);
      expect(g.isOver, isFalse, reason: spec.id);
    }
  });

  test('ids match the debug console games', () {
    expect(gameSpecs.map((s) => s.id).toSet(), DebugConsole.games.keys.toSet());
  });

  test('GameConfig round-trips through JSON', () {
    const c = GameConfig('quartett-sets', seed: 42);
    expect(GameConfig.fromJson(c.toJson()), c);
    expect(() => createGame(const GameConfig('nope')), throwsArgumentError);
  });

  test('replay rebuilds the same state; a bad log returns null', () {
    for (final spec in gameSpecs) {
      final config = GameConfig(spec.id, seed: 5);
      final g = createGame(config);
      final moves = <Map<String, dynamic>>[];
      for (var i = 0; i < 30 && !g.isOver; i++) {
        final List<Map<String, dynamic>> legal = g is Connect4Game
            ? [for (final c in g.legalMoves) {'col': c}]
            : (g as dynamic).legalMoves as List<Map<String, dynamic>>;
        final m = legal[(i * 7) % legal.length];
        g.applyMove(m);
        moves.add(m);
      }
      final r = replay(config, moves)!;
      expect(r.currentPlayer, g.currentPlayer, reason: spec.id);
      expect(r.history.length, g.history.length, reason: spec.id);
    }
    expect(replay(const GameConfig('connect4'), [{'col': 9}]), isNull);
  });
}

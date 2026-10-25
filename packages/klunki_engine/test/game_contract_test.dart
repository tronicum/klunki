import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// Behaviour every [Game] must share, regardless of rules. Transports and the
/// UI rely on this: illegal moves are rejected without side effects, and the
/// history is the replay log for network sync.
class _Spec {
  final String name;
  final Game Function() create;
  final Map<String, dynamic> legalFirstMove;
  final List<Map<String, dynamic>> illegalFirstMoves;
  const _Spec(this.name, this.create, this.legalFirstMove, this.illegalFirstMoves);
}

final _specs = <_Spec>[
  _Spec('Connect4Game', Connect4Game.new, {'col': 3}, [
    {'col': -1},
    {'col': 7},
  ]),
  _Spec('MuehleGame', MuehleGame.new, {'action': 'place', 'to': 0}, [
    {'action': 'place', 'to': 24},
    {'action': 'move', 'from': 0, 'to': 1},
    {'action': 'remove', 'at': 0},
  ]),
  // Autoplace completes A's fleet in one move, so the turn passes to B.
  _Spec('SchiffeGame', SchiffeGame.new, {'action': 'autoplace', 'seed': 1}, [
    {'action': 'fire', 'row': 0, 'col': 0},
    {'action': 'place', 'ship': 0, 'row': 0, 'col': 8, 'dir': 'h'},
    {'action': 'place', 'ship': 1, 'row': 0, 'col': 0, 'dir': 'h'},
  ]),
];

void main() {
  for (final spec in _specs) {
    group('${spec.name} contract', () {
      test('starts with player A, not over, no winner', () {
        final g = spec.create();
        expect(g.currentPlayer, Player.a);
        expect(g.isOver, isFalse);
        expect(g.result.winner, isNull);
        expect(g.result.draw, isFalse);
      });

      test('illegal moves return null and change nothing', () {
        final g = spec.create();
        final historyBefore = g.history.length;
        for (final move in spec.illegalFirstMoves) {
          expect(g.applyMove(move), isNull, reason: '$move');
          expect(g.currentPlayer, Player.a, reason: '$move');
          expect(g.history.length, historyBefore, reason: '$move');
        }
      });

      test('a legal move is accepted, logged and passes the turn', () {
        final g = spec.create();
        final historyBefore = g.history.length;
        expect(g.applyMove(spec.legalFirstMove), isNotNull);
        expect(g.history.length, historyBefore + 1);
        expect(g.currentPlayer, Player.b);
      });

      test('history is read-only', () {
        final g = spec.create()..applyMove(spec.legalFirstMove);
        expect(() => g.history.add({}), throwsUnsupportedError);
      });

      test('isOver agrees with result', () {
        final g = spec.create()..applyMove(spec.legalFirstMove);
        expect(g.isOver, g.result.isOver);
      });
    });
  }
}

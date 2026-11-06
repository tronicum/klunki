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
  // A full setup in one move, so the turn passes to B.
  _Spec('GoStrategyGame', GoStrategyGame.new, {'action': 'autosetup', 'seed': 1}, [
    {'action': 'move', 'from': 60, 'to': 50},
    {'action': 'setup', 'pieces': ['flag']},
    {'action': 'autosetup', 'seed': 'x'},
  ]),
  _Spec('ChessGame', ChessGame.new, {'action': 'move', 'from': 'e2', 'to': 'e4'}, [
    {'action': 'move', 'from': 'e2', 'to': 'e5'},
    {'action': 'move', 'from': 'e7', 'to': 'e5'},
    {'action': 'move', 'from': 'i2', 'to': 'i4'},
    {'action': 'move', 'from': 'e2', 'to': 'e4', 'promotion': 'q'},
    {'from': 'e2', 'to': 'e4'},
  ]),
  _Spec('WordTilesGame', WordTilesGame.new, {'action': 'pass'}, [
    {'action': 'place', 'tiles': []},
    {'action': 'place', 'tiles': [{'row': 0, 'col': 0, 'tile': '?', 'letter': 'A'}]},
    {'action': 'exchange', 'tiles': ['#']},
    {'action': 'challenge'},
    {'action': 'accept'},
    {'action': 'pass', 'x': 1},
  ]),
  // A fixed deal: A holds nothing that fits and draws a card that does not
  // fit either, so the turn passes.
  _Spec('MauMauGame', _mauMau, {'action': 'draw'}, [
    {'action': 'pass'},
    {'action': 'play', 'card': 'c7'},
    {'action': 'play', 'card': 'h8'},
    {'action': 'play', 'card': 'x9'},
    {'action': 'draw', 'x': 1},
  ]),
];

MauMauGame _mauMau() => MauMauGame()
  ..debugSetup(
      a: ['c7', 'c8', 'sK', 'sQ', 'cA'], b: ['h8', 'd7', 'd8', 'sA', 'c10'], top: 'h9', stock: ['dK', 'dQ', 'd10']);

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

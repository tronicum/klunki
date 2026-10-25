import 'package:test/test.dart';
import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  group('DebugConsole (connect4)', () {
    test('renders an empty 7x6 board with header and frame', () {
      final c = DebugConsole();
      final lines = c.screen.split('\n');
      expect(lines.first, '4 Gewinnt');
      expect(lines[1], ' 0 1 2 3 4 5 6');
      expect(lines.where((l) => l == '|. . . . . . .|'), hasLength(6));
      expect(lines.last, 'X to move');
    });

    test('a move is narrated, shows up on the bottom row and passes the turn', () {
      final out = DebugConsole().handle('3');
      expect(out, startsWith('X drops into column 3 (lands in row 1 from the bottom).'));
      expect(out, contains('|. . . X . . .|\n+'));
      expect(out, endsWith('O to move'));
    });

    test('reports a win', () {
      final c = DebugConsole();
      for (final m in ['0', '0', '1', '1', '3', '3']) {
        c.handle(m);
      }
      expect(c.handle('2'), contains('X wins (four in a row)'));
    });

    test('illegal and unknown input do not change the game', () {
      final c = DebugConsole();
      expect(c.handle('9'), startsWith('Illegal move'));
      expect(c.handle('bogus'), startsWith('Unknown command'));
      expect(c.handle('history'), 'No moves yet.');
      expect(c.current.game.currentPlayer.name, 'a');
    });

    test('undo replays all but the last move', () {
      final c = DebugConsole()
        ..handle('3')
        ..handle('4');
      final out = c.handle('undo');
      expect(out, contains('|. . . X . . .|'));
      expect(out, endsWith('O to move'));
      expect(c.handle('history'), '1. 3');
    });

    test('new restarts; unknown game is rejected', () {
      final c = DebugConsole()..handle('3');
      expect(c.handle('new'), endsWith('X to move'));
      expect(c.handle('history'), 'No moves yet.');
      expect(c.handle('new nope'), startsWith('Unknown game'));
    });

    test('help lists move syntax and commands', () {
      final out = DebugConsole().handle('help');
      expect(out, contains('drop a piece'));
      expect(out, contains('undo'));
    });
  });

  group('DebugConsole (muehle)', () {
    test('renders board, point numbers and per-player status', () {
      final out = DebugConsole('muehle').screen;
      expect(out, contains('21----------22----------23'));
      expect(out, contains('X: placing, hand 9, board 0'));
      expect(out, endsWith('X to move'));
    });

    test('place, mill, remove', () {
      final c = DebugConsole('muehle');
      for (final m in ['0', '9', '1', '10']) {
        c.handle(m);
      }
      final mill = c.handle('2');
      expect(mill, contains('Mill! X must remove'));
      expect(mill, contains('Mill on 0-1-2! X may remove a piece.'));
      final removed = c.handle('x9');
      expect(removed, startsWith("X removes O's piece on point 9"));
      expect(removed, contains('O: placing, hand 7, board 1'));
      expect(removed, contains('O to move'));
    });

    test('parses move and remove syntax', () {
      final t = MuehleText();
      expect(t.parse('4'), {'action': 'place', 'to': 4});
      expect(t.parse('4-7'), {'action': 'move', 'from': 4, 'to': 7});
      expect(t.parse('X13'), {'action': 'remove', 'at': 13});
      expect(t.parse('a-b'), isNull);
    });
  });

  group('DebugConsole commands', () {
    test('moves lists legal moves in typed form', () {
      final c = DebugConsole();
      expect(c.handle('moves'), 'Legal moves for X: 0 1 2 3 4 5 6');
      for (var i = 0; i < 6; i++) {
        c.handle('0');
      }
      expect(c.handle('moves'), isNot(contains(' 0 ')));
      expect(DebugConsole('muehle').handle('moves'), contains('23'));
    });

    test('auto plays to the end and is reproducible per seed', () {
      for (final id in DebugConsole.games.keys) {
        final a = DebugConsole(id, 3);
        final b = DebugConsole(id, 3);
        expect(a.handle('auto'), b.handle('auto'), reason: id);
        expect(a.current.game.isOver, isTrue, reason: id);
      }
    });

    test('auto n plays exactly n moves', () {
      final c = DebugConsole('muehle')..handle('auto 5');
      expect(c.handle('history').split('\n'), hasLength(5));
    });

    test('every game has a demo that finishes', () {
      for (final id in DebugConsole.games.keys) {
        final out = DebugConsole().demo(id);
        expect(out, contains('DEMO:'), reason: id);
        expect(out, matches(RegExp(r'Result: .+ after \d+ moves\.$')), reason: id);
      }
    });

    test('scripted demos tell the expected story', () {
      expect(DebugConsole().demo('connect4'), contains('Four in a row: X wins!'));
      final m = DebugConsole().demo('muehle');
      expect(m, contains('Mill on 1-4-7!'));
      expect(m, contains('X flies from 20 to 9.'));
      expect(m, endsWith('Result: O wins (opponent has fewer than 3 pieces) after 33 moves.'));
    });

    test('demo rejects unknown games', () {
      expect(DebugConsole().handle('demo nope'), startsWith('Unknown game'));
    });
  });

  group('DebugConsole (schiffe)', () {
    test('parses coordinates, placements and fleet', () {
      final t = SchiffeText();
      expect(t.parse('E5'), {'action': 'fire', 'row': 4, 'col': 4});
      expect(t.parse('j10'), {'action': 'fire', 'row': 9, 'col': 9});
      expect(t.parse('B2h'), {'action': 'place', 'ship': 0, 'row': 1, 'col': 1, 'dir': 'h'});
      expect(t.parse('fleet 4'), {'action': 'autoplace', 'seed': 4});
      expect(t.parse('fleet'), {'action': 'autoplace', 'seed': 0});
      expect(t.parse('K1'), isNull);
      expect(t.parse('A11'), isNull);
    });

    test('placing and firing are narrated', () {
      final c = DebugConsole('schiffe');
      expect(c.handle('A1h'), startsWith('X places a Schlachtschiff (5) at A1 horizontally.'));
      expect(c.handle('fleet 1'), contains('Now O places their fleet (X looks away).'));
      expect(c.handle('fleet 2'), contains('the battle begins, X fires first.'));
      expect(c.handle('E5'), startsWith('X fires at E5:'));
    });

    test("the screen never shows the opponent's ships", () {
      final c = DebugConsole('schiffe')
        ..handle('fleet 1')
        ..handle('fleet 2');
      final screen = c.screen;
      final rows = screen.split('\n').where((l) => RegExp(r'^[A-J] ').hasMatch(l));
      expect(rows, hasLength(10));
      for (final row in rows) {
        final target = row.substring(row.lastIndexOf(RegExp(r'[A-J] ')) + 1);
        expect(target, isNot(contains('#')));
      }
      expect(screen, contains('ships left: X 6, O 6'));
    });

    test('auto play hunts down a whole fleet', () {
      final c = DebugConsole('schiffe', 5)..handle('auto');
      expect(c.current.game.result.reason, 'all ships sunk');
    });
  });

  group('DebugConsole (quartett)', () {
    test('trumpf: stats by number or id, narrated trick', () {
      final t = QuartettTrumpfText();
      expect(t.parse('1'), {'action': 'pick', 'stat': 'ps'});
      expect(t.parse('kg'), {'action': 'pick', 'stat': 'kg'});
      expect(t.parse('6'), isNull);
      final c = DebugConsole('quartett-trumpf');
      expect(c.screen, contains("X's top card:"));
      expect(c.handle('ps'), matches(RegExp(r"^X picks Leistung: X's .+ vs O's .+")));
    });

    test('sets: asks are narrated, the opponent hand stays hidden', () {
      final c = DebugConsole('quartett-sets');
      final g = c.current.game as QuartettGame;
      final opponentCard = g.handOf(Player.b).first;
      expect(c.screen, isNot(contains(opponentCard.name)));
      final ask = c.current.format(c.current.legalMoves.first);
      expect(c.handle(ask), startsWith('X asks O for $ask'));
      expect(QuartettSetsText().parse('b3'), {'action': 'ask', 'card': 'B3'});
      expect(QuartettSetsText().parse('Z9'), isNull);
    });
  });

  group('DebugConsole.forGame (seed hook for network play)', () {
    test('wraps the given instance for every game id', () {
      for (final spec in gameSpecs) {
        final game = createGame(GameConfig(spec.id, seed: 42));
        final text = DebugConsole.forGame(spec.id, game);
        expect(text.id, spec.id);
        expect(identical(text.game, game), isTrue, reason: spec.id);
      }
    });

    test('a seeded Quartett renders the same deal as the seeded adapter', () {
      final game = createGame(const GameConfig('quartett-trumpf', seed: 42));
      expect(DebugConsole.forGame('quartett-trumpf', game).render(), QuartettTrumpfText(42).render());
      final sets = createGame(const GameConfig('quartett-sets', seed: 42));
      expect(DebugConsole.forGame('quartett-sets', sets).render(), QuartettSetsText(42).render());
    });

    test('rejects a game of the wrong type', () {
      expect(() => DebugConsole.forGame('muehle', createGame(const GameConfig('connect4'))), throwsArgumentError);
    });
  });
}

import 'package:test/test.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// Parses compact notation: `p5` = place on 5, `m3-4` = move/fly 3 -> 4,
/// `x9` = remove the piece on 9.
Map<String, dynamic> mv(String s) {
  final body = s.substring(1);
  switch (s[0]) {
    case 'p':
      return {'action': 'place', 'to': int.parse(body)};
    case 'm':
      final parts = body.split('-');
      return {
        'action': 'move',
        'from': int.parse(parts[0]),
        'to': int.parse(parts[1]),
      };
    case 'x':
      return {'action': 'remove', 'at': int.parse(body)};
  }
  throw ArgumentError('bad move notation: $s');
}

/// Plays [moves] on a fresh game (or [g]); every move must be legal.
/// Returns the game and the event of the last move.
(MuehleGame, GameEvent?) play(List<String> moves, [MuehleGame? g]) {
  final game = g ?? MuehleGame();
  GameEvent? last;
  for (final m in moves) {
    last = game.applyMove(mv(m));
    if (last == null)
      fail('illegal move "$m" after ${game.history.length} moves');
  }
  return (game, last);
}

/// 18 placements with no mill for either side.
/// A: 15 5 9 19 13 16 3 8 7 — B: 2 6 20 23 4 21 12 1 11.
/// Empty afterwards: 0 10 14 17 18 22.
const fullPlacement = [
  'p15', 'p2', 'p5', 'p6', 'p9', 'p20', 'p19', 'p23', 'p13', //
  'p4', 'p16', 'p21', 'p3', 'p12', 'p8', 'p1', 'p7', 'p11',
];

void main() {
  group('board geometry', () {
    test('24 points, adjacency is symmetric', () {
      expect(MuehleGame.adjacency.length, 24);
      for (var p = 0; p < 24; p++) {
        for (final n in MuehleGame.adjacency[p]) {
          expect(MuehleGame.adjacency[n], contains(p), reason: '$p<->$n');
        }
      }
      final edges =
          MuehleGame.adjacency.fold<int>(0, (s, l) => s + l.length) ~/ 2;
      expect(edges, 32);
    });

    test('16 distinct mills, each a line of adjacent points', () {
      expect(MuehleGame.mills.length, 16);
      expect(
          MuehleGame.mills
              .map((m) => (m.toList()..sort()).join(','))
              .toSet()
              .length,
          16);
      for (final m in MuehleGame.mills) {
        expect(MuehleGame.adjacency[m[0]], contains(m[1]));
        expect(MuehleGame.adjacency[m[1]], contains(m[2]));
        expect(MuehleGame.adjacency[m[0]], isNot(contains(m[2])));
      }
      // every point lies on exactly two mills
      for (var p = 0; p < 24; p++) {
        expect(MuehleGame.mills.where((m) => m.contains(p)).length, 2);
      }
    });
  });

  group('placing', () {
    test('initial state', () {
      final g = MuehleGame();
      expect(g.board.length, 24);
      expect(g.board.every((c) => c == null), isTrue);
      expect(g.currentPlayer, Player.a);
      expect(g.phaseOf(Player.a), MuehlePhase.placing);
      expect(g.piecesInHand(Player.a), 9);
      expect(g.piecesInHand(Player.b), 9);
      expect(g.legalMoves.length, 24);
      expect(g.isOver, isFalse);
      expect(() => (g.board as List)[0] = Player.a, throwsUnsupportedError);
    });

    test('placement alternates and updates counts', () {
      final g = MuehleGame();
      expect(g.applyMove(mv('p0')), isNotNull);
      expect(g.currentPlayer, Player.b);
      expect(g.applyMove(mv('p5')), isNotNull);
      expect(g.currentPlayer, Player.a);
      expect(g.board[0], Player.a);
      expect(g.board[5], Player.b);
      expect(g.piecesInHand(Player.a), 8);
      expect(g.piecesOnBoard(Player.b), 1);
      expect(g.history.length, 2);
    });

    test('placing on an occupied point (or wrong action) is rejected', () {
      final (g, _) = play(['p0']);
      expect(g.applyMove(mv('p0')), isNull);
      expect(g.applyMove(mv('p24')), isNull);
      expect(g.applyMove(mv('m0-1')), isNull);
      expect(g.applyMove(mv('x0')), isNull);
      expect(g.applyMove({'action': 'place'}), isNull);
      expect(g.currentPlayer, Player.b);
      expect(g.history.length, 1);
    });
  });

  group('mills and removal', () {
    test('mill -> pendingRemoval -> removal -> turn passes', () {
      final (g, e) = play(['p0', 'p9', 'p1', 'p10', 'p2']);
      expect(e!.payload, {'mill': true});
      expect(g.pendingRemoval, isTrue);
      expect(g.currentPlayer, Player.a);
      expect(g.legalMoves, everyElement(containsPair('action', 'remove')));
      expect(g.legalMoves.length, 2);
      // anything but a removal of an opponent piece is rejected
      expect(g.applyMove(mv('p3')), isNull);
      expect(g.applyMove(mv('x0')), isNull); // own piece
      expect(g.applyMove(mv('x4')), isNull); // empty
      final r = g.applyMove(mv('x9'));
      expect(r!.payload, {'removed': 9});
      expect(g.pendingRemoval, isFalse);
      expect(g.board[9], isNull);
      expect(g.currentPlayer, Player.b);
      expect(g.piecesOnBoard(Player.b), 1);
      expect(g.piecesInHand(Player.b), 7);
    });

    test('pieces in a mill are protected', () {
      // B builds mill 21-22-23 (removes A's 10), B also has a free piece on 9.
      final (g, _) = play([
        'p0', 'p21', 'p1', 'p22', 'p10', 'p23', 'x10', //
        'p3', 'p9', 'p2', // A closes 0-1-2
      ]);
      expect(g.pendingRemoval, isTrue);
      expect(g.applyMove(mv('x21')), isNull);
      expect(g.applyMove(mv('x22')), isNull);
      expect(g.legalMoves, [
        {'action': 'remove', 'at': 9},
      ]);
      expect(g.applyMove(mv('x9')), isNotNull);
    });

    test('mill pieces may be taken when all opponent pieces are in mills', () {
      final (g, _) = play([
        'p0', 'p21', 'p1', 'p22', 'p10', 'p23', 'x10', //
        'p2', // A closes 0-1-2; all B pieces sit in 21-22-23
      ]);
      expect(g.pendingRemoval, isTrue);
      expect(g.legalMoves.map((m) => m['at']).toSet(), {21, 22, 23});
      expect(g.applyMove(mv('x22')), isNotNull);
      expect(g.board[22], isNull);
    });
  });

  group('moving', () {
    test('switches to moving after 9+9 placements', () {
      final (g, _) = play(fullPlacement.sublist(0, 17));
      expect(g.phaseOf(Player.a), MuehlePhase.moving);
      expect(g.phaseOf(Player.b), MuehlePhase.placing);
      play([fullPlacement.last], g);
      expect(g.phaseOf(Player.b), MuehlePhase.moving);
      expect(g.piecesInHand(Player.a), 0);
      expect(g.piecesOnBoard(Player.a), 9);
      expect(g.currentPlayer, Player.a);
      expect(g.applyMove(mv('p0')), isNull); // no more placing
      expect(g.legalMoves, everyElement(containsPair('action', 'move')));
    });

    test('only adjacent moves are allowed', () {
      final (g, _) = play(fullPlacement);
      expect(g.applyMove(mv('m9-14')), isNull); // not adjacent
      expect(g.applyMove(mv('m15-0')), isNull); // not adjacent
      expect(g.applyMove(mv('m9-21')), isNull); // occupied
      expect(g.applyMove(mv('m2-14')), isNull); // opponent's piece
      expect(g.history.length, 18);
      for (final m in g.legalMoves) {
        expect(MuehleGame.adjacency[m['from'] as int], contains(m['to']));
      }
      expect(g.applyMove(mv('m9-10')), isNotNull);
      expect(g.board[9], isNull);
      expect(g.board[10], Player.a);
      expect(g.currentPlayer, Player.b);
    });
  });

  group('flying', () {
    // B keeps closing mills (during placing and by opening/closing 19/20),
    // until A is down to exactly 3 pieces.
    const toFlying = [
      'p14', 'p7', 'p9', 'p16', 'p19', 'p4', 'p6', 'p1', 'x19', 'p19', //
      'p3', 'p12', 'p5', 'x19', 'p10', 'p20', 'p2', 'p13', 'x6', 'p0',
      'p22', 'm10-18', 'm20-19', 'x12', 'm14-23', 'm19-20', 'x2', 'm9-10',
      'm20-19', 'x0',
    ];

    test('a player with exactly 3 pieces may jump anywhere', () {
      final (g, _) = play(toFlying);
      expect(g.currentPlayer, Player.a);
      expect(g.piecesOnBoard(Player.a), 3);
      expect(g.phaseOf(Player.a), MuehlePhase.flying);
      expect(g.phaseOf(Player.b), MuehlePhase.moving);

      final empty = [
        for (var i = 0; i < 24; i++)
          if (g.board[i] == null) i
      ];
      expect(g.legalMoves.length, 3 * empty.length);

      final from = g.board.indexOf(Player.a);
      final to =
          empty.firstWhere((p) => !MuehleGame.adjacency[from].contains(p));
      expect(
          g.applyMove({'action': 'move', 'from': from, 'to': to}), isNotNull);
      expect(g.board[to], Player.a);

      // B has more than 3 pieces and still moves adjacently only.
      expect(g.phaseOf(Player.b), MuehlePhase.moving);
      for (final m in g.legalMoves) {
        expect(MuehleGame.adjacency[m['from'] as int], contains(m['to']));
      }
    });
  });

  group('game end', () {
    test('win when the opponent drops below 3 pieces', () {
      const moves = [
        'p21', 'p15', 'p16', 'p1', 'p8', 'p7', 'p5', 'p4', 'x8', 'p23', //
        'p11', 'p20', 'p6', 'x16', 'p12', 'p8', 'x5', 'p10', 'p22', 'p17',
        'p19', 'm21-9', 'm15-16', 'x10', 'm9-0', 'm16-15', 'x17', 'm12-13',
        'm15-16', 'x23', 'm20-9', 'm16-15',
      ];
      final (g, last) = play(moves);
      expect(last!.payload, {'mill': true});
      expect(g.phaseOf(Player.a), MuehlePhase.flying);
      final e = g.applyMove(mv('x13'));
      expect(e!.winner, Player.b);
      expect(e.payload, {'removed': 13});
      expect(g.piecesOnBoard(Player.a), 2);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.b);
      expect(g.result.reason, contains('fewer than 3'));
      expect(g.result.code, GameEndReason.muehleFewerThanThree);
      expect(g.legalMoves, isEmpty);
      expect(g.applyMove(mv('m0-1')), isNull); // game over
    });

    test('win when the opponent is blocked', () {
      // After the last placement every A piece is surrounded.
      const moves = [
        'p4', 'p2', 'p1', 'p19', 'p20', 'p23', 'p3', 'p7', 'p13', //
        'p9', 'p14', 'p18', 'p10', 'p5', 'p6', 'p12', 'p0', 'p11',
      ];
      final (g, _) = play(moves.sublist(0, 17));
      expect(g.isOver, isFalse);
      final e = g.applyMove(mv(moves.last));
      expect(e!.winner, Player.b);
      expect(g.result.winner, Player.b);
      expect(g.result.reason, contains('no legal move'));
      expect(g.result.code, GameEndReason.muehleBlocked);
      expect(g.piecesOnBoard(Player.a), 9);
      expect(g.applyMove(mv('m0-1')), isNull);
    });

    test('draw after 50 moves without a removal', () {
      const moves = [
        ...fullPlacement,
        'm9-10', 'm2-14', 'm19-22', 'm1-0', 'm10-9', 'm12-17', 'm3-10', //
        'm4-3', 'm22-19', 'm21-22', 'm8-12', 'm14-2', 'm13-14', 'm0-1',
        'm14-13', 'm22-21', 'm12-8', 'm17-12', 'm5-4', 'm23-14', 'm9-0',
        'm14-23', 'm10-9', 'm23-14', 'm4-5', 'm21-22', 'm9-10', 'm14-23',
        'm7-4', 'm2-14', 'm16-17',
      ];
      expect(moves.length, 49);
      final (g, _) = play(moves);
      expect(g.isOver, isFalse);
      expect(g.movesSinceRemoval, 49);
      final e = g.applyMove(mv('m14-2'));
      expect(e!.draw, isTrue);
      expect(e.winner, isNull);
      expect(g.result.draw, isTrue);
      expect(g.result.reason, contains('50'));
      expect(g.result.code, GameEndReason.muehleNoRemovalLimit);
expect(g.result.params, {'moves': 50});
      expect(g.applyMove(mv('m17-16')), isNull);
    });

    test('a removal resets the 50-move counter', () {
      final (g, _) = play(['p0', 'p9', 'p1', 'p10', 'p2']);
      expect(g.movesSinceRemoval, 5);
      play(['x9'], g);
      expect(g.movesSinceRemoval, 0);
    });
  });
}

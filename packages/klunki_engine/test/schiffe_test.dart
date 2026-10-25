import 'dart:math';

import 'package:test/test.dart';
import 'package:klunki_engine/game.dart';
import 'package:klunki_engine/schiffe.dart';

Map<String, dynamic> place(int ship, int row, int col, String dir) =>
    {'action': 'place', 'ship': ship, 'row': row, 'col': col, 'dir': dir};

Map<String, dynamic> fire(int row, int col) =>
    {'action': 'fire', 'row': row, 'col': col};

/// Snapshot of observable state, to assert "no change" after illegal moves.
String snapshot(SchiffeGame g) => [
      g.phase,
      g.currentPlayer,
      g.isOver,
      g.history.length,
      g.nextShipIndex(Player.a),
      g.nextShipIndex(Player.b),
      g.ownGrid(Player.a),
      g.ownGrid(Player.b),
    ].toString();

void expectIllegal(SchiffeGame g, Map<String, dynamic> move) {
  final before = snapshot(g);
  expect(g.applyMove(move), isNull, reason: '$move should be illegal');
  expect(snapshot(g), before);
}

/// Checks a set of placements: on board, no overlap, no touching.
void expectValidLayout(List<ShipPlacement> layout, List<int> fleet) {
  expect(layout.map((p) => p.length).toList(), fleet);
  final owner = <String, int>{};
  for (var i = 0; i < layout.length; i++) {
    for (final c in layout[i].cells) {
      expect(c[0], inInclusiveRange(0, 9));
      expect(c[1], inInclusiveRange(0, 9));
      expect(owner.containsKey('${c[0]},${c[1]}'), isFalse, reason: 'overlap');
      owner['${c[0]},${c[1]}'] = i;
    }
  }
  for (final e in owner.entries) {
    final rc = e.key.split(',').map(int.parse).toList();
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final o = owner['${rc[0] + dr},${rc[1] + dc}'];
        if (o != null) expect(o, e.value, reason: 'ships touch at ${e.key}');
      }
    }
  }
}

/// Game with fleet [3,2]: A at (0,0)h + (2,0)h, B at (5,5)h + (7,5)v.
SchiffeGame smallGame({bool extraShotOnHit = true}) {
  final g = SchiffeGame(fleet: [3, 2], extraShotOnHit: extraShotOnHit);
  g.applyMove(place(0, 0, 0, 'h'));
  g.applyMove(place(1, 2, 0, 'h'));
  g.applyMove(place(0, 5, 5, 'h'));
  g.applyMove(place(1, 7, 5, 'v'));
  return g;
}

void main() {
  group('Schiffe versenken — setup', () {
    test('default fleet and names', () {
      expect(SchiffeGame.defaultFleet, [5, 4, 3, 3, 2, 2]);
      expect(SchiffeGame.shipName(5), 'Schlachtschiff');
      expect(SchiffeGame.shipName(2), 'U-Boot');
      final g = SchiffeGame();
      expect(g.phase, SchiffePhase.setup);
      expect(g.currentPlayer, Player.a);
      expect(g.nextShipIndex(Player.a), 0);
    });

    test('valid placement', () {
      final g = SchiffeGame();
      final e = g.applyMove(place(0, 0, 0, 'h'));
      expect(e, isNotNull);
      expect(e!.payload, {'placed': 0, 'length': 5});
      expect(g.nextShipIndex(Player.a), 1);
      final grid = g.ownGrid(Player.a);
      for (var c = 0; c < 5; c++) {
        expect(grid[0][c], SchiffeCell.ship);
      }
      expect(grid[0][5], SchiffeCell.empty);
      expect(g.currentPlayer, Player.a);
      expect(g.history.length, 1);
    });

    test('out of bounds → null, no change', () {
      final g = SchiffeGame();
      expectIllegal(g, place(0, 0, 6, 'h'));
      expectIllegal(g, place(0, 6, 0, 'v'));
      expectIllegal(g, place(0, -1, 0, 'h'));
      expectIllegal(g, place(0, 0, 10, 'v'));
      expectIllegal(g, place(0, 0, 0, 'x'));
      expectIllegal(g, {'action': 'place', 'ship': 0, 'row': '0', 'col': 0, 'dir': 'h'});
    });

    test('overlap and touching (incl. diagonal) → null, no change', () {
      final g = SchiffeGame();
      g.applyMove(place(0, 4, 2, 'h')); // row 4, cols 2..6
      expectIllegal(g, place(1, 2, 4, 'v')); // overlap (rows 2..5 col 4)
      expectIllegal(g, place(1, 5, 2, 'h')); // touches below
      expectIllegal(g, place(1, 0, 7, 'v')); // rows 0..3 col 7: diagonal to (4,6)
      expectIllegal(g, place(1, 5, 7, 'v')); // diagonal below-right
      expectIllegal(g, place(1, 4, 7, 'v')); // directly adjacent right end
      expect(g.applyMove(place(1, 6, 2, 'h')), isNotNull); // one-row gap ok
      expect(g.applyMove(place(2, 0, 8, 'v')), isNotNull); // gap at col 7
    });

    test('wrong ship index → null', () {
      final g = SchiffeGame();
      expectIllegal(g, place(1, 0, 0, 'h'));
      g.applyMove(place(0, 0, 0, 'h'));
      expectIllegal(g, place(0, 5, 0, 'h'));
      expectIllegal(g, place(2, 5, 0, 'h'));
      expectIllegal(g, place(99, 5, 0, 'h'));
    });

    test('setup order: A then B; firing during setup → null', () {
      final g = SchiffeGame(fleet: [3, 2]);
      expectIllegal(g, fire(0, 0));
      g.applyMove(place(0, 0, 0, 'h'));
      expect(g.currentPlayer, Player.a);
      g.applyMove(place(1, 2, 0, 'h'));
      expect(g.currentPlayer, Player.b);
      expect(g.phase, SchiffePhase.setup);
      expect(g.nextShipIndex(Player.a), isNull);
      expect(g.nextShipIndex(Player.b), 0);
      expectIllegal(g, fire(0, 0));
      g.applyMove(place(0, 5, 5, 'h'));
      g.applyMove(place(1, 7, 5, 'v'));
      expect(g.phase, SchiffePhase.battle);
      expect(g.currentPlayer, Player.a);
      expectIllegal(g, place(0, 0, 0, 'h')); // placing during battle
      expectIllegal(g, {'action': 'autoplace', 'seed': 1});
    });

    test('legalMoves during setup are exactly the valid placements', () {
      final g = SchiffeGame(fleet: [5]);
      // 5-long on 10x10: 6*10 horizontal + 6*10 vertical.
      expect(g.legalMoves.length, 120);
      for (final m in g.legalMoves.take(5)) {
        expect(SchiffeGame(fleet: [5]).applyMove(m), isNotNull);
      }
    });

    test('autoplace deterministic and valid', () {
      for (final seed in [0, 1, 2, 42, 1234]) {
        final l1 = SchiffeGame.randomLayout(seed);
        final l2 = SchiffeGame.randomLayout(seed);
        expect(l1.toString(), l2.toString());
        expectValidLayout(l1, SchiffeGame.defaultFleet);

        final g1 = SchiffeGame()..applyMove({'action': 'autoplace', 'seed': seed});
        final g2 = SchiffeGame()..applyMove({'action': 'autoplace', 'seed': seed});
        expect(g1.ownGrid(Player.a).toString(), g2.ownGrid(Player.a).toString());
        expectValidLayout(g1.placements(Player.a), SchiffeGame.defaultFleet);
        expect(g1.currentPlayer, Player.b);
      }
      expect(SchiffeGame.randomLayout(1).toString(),
          isNot(SchiffeGame.randomLayout(2).toString()));
    });

    test('autoplace fills remaining ships after manual placements', () {
      final g = SchiffeGame();
      g.applyMove(place(0, 0, 0, 'h'));
      g.applyMove(place(1, 9, 6, 'h'));
      final e = g.applyMove({'action': 'autoplace', 'seed': 7});
      expect(e, isNotNull);
      expect(e!.payload['autoplaced'], [2, 3, 4, 5]);
      final ps = g.placements(Player.a);
      expect(ps[0].row, 0);
      expect(ps[1].row, 9);
      expectValidLayout(ps, SchiffeGame.defaultFleet);
      g.applyMove({'action': 'autoplace', 'seed': 8});
      expect(g.phase, SchiffePhase.battle);
      expect(g.shipsRemaining(Player.a), 6);
      expect(g.shipsRemaining(Player.b), 6);
    });
  });

  group('Schiffe versenken — battle', () {
    test('miss passes turn', () {
      final g = smallGame();
      final e = g.applyMove(fire(0, 0))!;
      expect(e.payload, {'row': 0, 'col': 0, 'result': 'miss'});
      expect(g.currentPlayer, Player.b);
      expect(g.targetGrid(Player.a)[0][0], ShotMark.miss);
      expect(g.ownGrid(Player.b)[0][0], SchiffeCell.miss);
    });

    test('hit keeps turn, sunk detected', () {
      final g = smallGame();
      var e = g.applyMove(fire(7, 5))!;
      expect(e.payload, {'row': 7, 'col': 5, 'result': 'hit', 'ship': 2});
      expect(g.currentPlayer, Player.a);
      expect(g.targetGrid(Player.a)[7][5], ShotMark.hit);
      expect(g.ownGrid(Player.b)[7][5], SchiffeCell.hit);
      e = g.applyMove(fire(8, 5))!;
      expect(e.payload['result'], 'sunk');
      expect(e.payload['ship'], 2);
      expect(e.winner, isNull);
      expect(g.currentPlayer, Player.a);
      expect(g.targetGrid(Player.a)[7][5], ShotMark.sunk);
      expect(g.targetGrid(Player.a)[8][5], ShotMark.sunk);
      expect(g.ownGrid(Player.b)[8][5], SchiffeCell.sunk);
      expect(g.shipsRemaining(Player.b), 1);
    });

    test('firing same cell twice → null', () {
      final g = smallGame();
      g.applyMove(fire(5, 5)); // hit, A keeps turn
      expectIllegal(g, fire(5, 5));
      g.applyMove(fire(0, 0)); // miss → B
      g.applyMove(fire(9, 9)); // B misses → A
      expectIllegal(g, fire(0, 0));
      expectIllegal(g, fire(10, 0));
      expectIllegal(g, fire(-1, 3));
      expectIllegal(g, {'action': 'boom'});
    });

    test('win when last ship sunk; moves after → null', () {
      final g = smallGame();
      for (final c in [5, 6]) {
        g.applyMove(fire(5, c));
      }
      g.applyMove(fire(7, 5));
      expect(g.isOver, isFalse);
      g.applyMove(fire(5, 7)); // sinks the 3
      final e = g.applyMove(fire(8, 5))!; // sinks the 2 → win
      expect(e.winner, Player.a);
      expect(e.payload['result'], 'sunk');
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.a);
      expect(g.result.reason, 'all ships sunk');
      expect(g.shipsRemaining(Player.b), 0);
      expect(g.legalMoves, isEmpty);
      expectIllegal(g, fire(0, 0));
    });

    test('fleet [2] quick win for B', () {
      final g = SchiffeGame(fleet: [2]);
      g.applyMove(place(0, 0, 0, 'h'));
      g.applyMove(place(0, 9, 8, 'h'));
      g.applyMove(fire(5, 5)); // A misses
      expect(g.applyMove(fire(0, 0))!.payload['result'], 'hit');
      final e = g.applyMove(fire(0, 1))!;
      expect(e.winner, Player.b);
      expect(g.result.winner, Player.b);
    });

    test('extraShotOnHit = false: hit passes turn too', () {
      final g = smallGame(extraShotOnHit: false);
      expect(g.applyMove(fire(5, 5))!.payload['result'], 'hit');
      expect(g.currentPlayer, Player.b);
      g.applyMove(fire(0, 0)); // B hits
      expect(g.currentPlayer, Player.a);
    });

    test('targetGrid never reveals unhit ships', () {
      final g = SchiffeGame()
        ..applyMove({'action': 'autoplace', 'seed': 3})
        ..applyMove({'action': 'autoplace', 'seed': 4});
      for (final p in Player.values) {
        expect(g.targetGrid(p).expand((r) => r).every((m) => m == ShotMark.unknown),
            isTrue);
      }
      final rng = Random(9);
      for (var i = 0; i < 40 && !g.isOver; i++) {
        final moves = g.legalMoves;
        g.applyMove(moves[rng.nextInt(moves.length)]);
      }
      for (final p in Player.values) {
        final opp = p == Player.a ? Player.b : Player.a;
        final own = g.ownGrid(opp);
        final target = g.targetGrid(p);
        for (var r = 0; r < 10; r++) {
          for (var c = 0; c < 10; c++) {
            if (own[r][c] == SchiffeCell.ship || own[r][c] == SchiffeCell.empty) {
              expect(target[r][c], ShotMark.unknown);
            }
          }
        }
      }
    });

    test('legalMoves during battle = unshot cells', () {
      final g = smallGame();
      expect(g.legalMoves.length, 100);
      g.applyMove(fire(0, 0)); // A miss → B
      expect(g.legalMoves.length, 100); // B hasn't shot yet
      g.applyMove(fire(9, 9)); // B miss → A
      expect(g.legalMoves.length, 99);
      expect(g.legalMoves.any((m) => m['row'] == 0 && m['col'] == 0), isFalse);
    });

    test('full random games terminate with a winner', () {
      for (final seed in [1, 2, 3, 4, 5, 6, 7, 8]) {
        for (final extra in [true, false]) {
          final g = SchiffeGame(extraShotOnHit: extra)
            ..applyMove({'action': 'autoplace', 'seed': seed})
            ..applyMove({'action': 'autoplace', 'seed': seed + 100});
          final rng = Random(seed);
          var steps = 0;
          while (!g.isOver) {
            final moves = g.legalMoves;
            expect(moves, isNotEmpty);
            expect(g.applyMove(moves[rng.nextInt(moves.length)]), isNotNull);
            expect(++steps, lessThanOrEqualTo(200));
          }
          expect(g.result.winner, isNotNull);
          final loser = g.result.winner == Player.a ? Player.b : Player.a;
          expect(g.shipsRemaining(loser), 0);
          expect(g.shipsRemaining(g.result.winner!), greaterThan(0));
        }
      }
    });
  });
}

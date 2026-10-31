import 'dart:math';

import 'package:test/test.dart';
import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';

const a = Player.a, b = Player.b;

int sq(int row, int col) => GoStrategyGame.square(row, col);

Map<String, dynamic> mv(int from, int to) => {'action': 'move', 'from': from, 'to': to};

/// Snapshot of observable state, to assert "no change" after illegal moves.
String snapshot(GoStrategyGame g) =>
    [g.phase, g.currentPlayer, g.isOver, g.history.length, g.board, g.movesSinceCapture].toString();

void expectIllegal(GoStrategyGame g, Map<String, dynamic> move) {
  final before = snapshot(g);
  expect(g.applyMove(move), isNull, reason: '$move should be illegal');
  expect(snapshot(g), before);
}

/// A position with [pieces] plus far-away flags for both sides (A's on 99,
/// B's on 0) unless given, so the game does not end by accident.
GoStrategyGame pos(Map<int, (Player, GoPiece)> pieces, {Player toMove = a, int limit = 200}) =>
    GoStrategyGame.position({
      if (!pieces.values.any((p) => p.$1 == a && p.$2 == GoPiece.flag)) 99: (a, GoPiece.flag),
      if (!pieces.values.any((p) => p.$1 == b && p.$2 == GoPiece.flag)) 0: (b, GoPiece.flag),
      ...pieces,
    }, toMove: toMove, noCaptureLimit: limit);

List<String> ids(List<GoPiece> pieces) => [for (final p in pieces) p.id];

void main() {
  group('pieces and board', () {
    test('40 pieces per army with the classic counts', () {
      expect(GoStrategyGame.army, hasLength(40));
      final counts = {for (final p in GoPiece.values) p.id: p.count};
      expect(counts, {
        'marshal': 1, 'general': 1, 'colonel': 2, 'major': 3, 'captain': 4, 'lieutenant': 4, //
        'sergeant': 4, 'miner': 5, 'scout': 8, 'spy': 1, 'bomb': 6, 'flag': 1,
      });
      expect([for (final p in GoPiece.values) p.rank], [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, null, null]);
      expect(GoPiece.bomb.movable, isFalse);
      expect(GoPiece.flag.movable, isFalse);
      expect(GoPiece.scout.movable, isTrue);
      expect(GoPiece.fromId('spy'), GoPiece.spy);
      expect(GoPiece.fromId('nope'), isNull);
    });

    test('lakes are the two 2×2 blocks in rows 4–5', () {
      expect(GoStrategyGame.lakes, {sq(4, 2), sq(4, 3), sq(5, 2), sq(5, 3), sq(4, 6), sq(4, 7), sq(5, 6), sq(5, 7)});
      expect(GoStrategyGame.isLake(sq(4, 4)), isFalse);
    });

    test('home squares: A rows 6–9, B rows 0–3, rotated setup order, no lakes', () {
      expect(GoStrategyGame.setupSquare(a, 0), 60);
      expect(GoStrategyGame.setupSquare(a, 39), 99);
      expect(GoStrategyGame.setupSquare(b, 0), 39);
      expect(GoStrategyGame.setupSquare(b, 39), 0);
      expect(GoStrategyGame.homeSquares(a).toSet(), {for (var i = 60; i < 100; i++) i});
      expect(GoStrategyGame.homeSquares(b).toSet(), {for (var i = 0; i < 40; i++) i});
      for (final p in Player.values) {
        expect(GoStrategyGame.homeSquares(p).where(GoStrategyGame.isLake), isEmpty);
      }
    });

    // KLD-081: the setup editor works on squares; the engine maps them.
    test('setupIndexOf inverts setupSquare; isHome only on the own four rows', () {
      for (final p in Player.values) {
        for (var i = 0; i < 40; i++) {
          expect(GoStrategyGame.setupIndexOf(p, GoStrategyGame.setupSquare(p, i)), i);
        }
      }
      expect([for (var s = 0; s < 100; s++) if (GoStrategyGame.isHome(a, s)) s], [for (var s = 60; s < 100; s++) s]);
      expect([for (var s = 0; s < 100; s++) if (GoStrategyGame.isHome(b, s)) s], [for (var s = 0; s < 40; s++) s]);
      expect(GoStrategyGame.setupIndexOf(a, 59), isNull);
      expect(GoStrategyGame.setupIndexOf(b, 40), isNull);
      expect(GoStrategyGame.setupIndexOf(a, 100), isNull);
      expect(GoStrategyGame.setupIndexOf(b, -1), isNull);
    });

    test('setupFromSquares: the piece placed on a square stands on that square', () {
      for (final p in Player.values) {
        final placement = GoStrategyGame.setupToSquares(p, GoStrategyGame.randomSetup(4));
        // A recognisable arrangement: flag in the own back-left corner (as
        // the owner sees it), a bomb next to it, a scout on the front right.
        final corner = p == a ? sq(9, 0) : sq(0, 9);
        final beside = p == a ? sq(9, 1) : sq(0, 8);
        final front = p == a ? sq(6, 9) : sq(3, 0);
        void swap(int x, int y) {
          final t = placement[x]!;
          placement[x] = placement[y]!;
          placement[y] = t;
        }

        swap(corner, placement.entries.firstWhere((e) => e.value == GoPiece.flag).key);
        if (placement[beside] != GoPiece.bomb) {
          swap(beside, placement.entries.firstWhere((e) => e.value == GoPiece.bomb && e.key != beside).key);
        }
        if (placement[front] != GoPiece.scout) {
          swap(front, placement.entries.firstWhere((e) => e.value == GoPiece.scout).key);
        }
        final list = GoStrategyGame.setupFromSquares(p, placement);
        expect(GoStrategyGame.setupToSquares(p, list), placement);
        final g = GoStrategyGame();
        if (p == b) g.applyMove({'action': 'autosetup', 'seed': 1});
        expect(g.applyMove(GoStrategyGame.setupMove(list)), isNotNull);
        for (final e in placement.entries) {
          expect(g.board[e.key], GoCell(owner: p, piece: e.value), reason: '${p.name} square ${e.key}');
        }
        expect(g.board[corner].piece, GoPiece.flag);
        expect(g.board[beside].piece, GoPiece.bomb);
        expect(g.board[front].piece, GoPiece.scout);
      }
    });

    test('setupFromSquares rejects squares outside the home rows and incomplete placements', () {
      final full = GoStrategyGame.setupToSquares(a, GoStrategyGame.randomSetup(2));
      expect(() => GoStrategyGame.setupFromSquares(b, full), throwsArgumentError);
      expect(() => GoStrategyGame.setupFromSquares(a, {...full}..remove(60)), throwsArgumentError);
      expect(() => GoStrategyGame.setupFromSquares(a, {...full, 50: GoPiece.scout}), throwsArgumentError);
      // The wire format is unchanged: setup order, 40 ids.
      expect(GoStrategyGame.setupMove(GoStrategyGame.setupFromSquares(a, full)),
          GoStrategyGame.setupMove(GoStrategyGame.randomSetup(2)));
    });
  });

  group('setup', () {
    test('validation: list of 40 known ids with the right counts', () {
      expect(GoStrategyGame.setupError(ids(GoStrategyGame.army)), isNull);
      expect(GoStrategyGame.setupError('x'), isNotNull);
      expect(GoStrategyGame.setupError(ids(GoStrategyGame.army).sublist(1)), contains('need 40'));
      expect(GoStrategyGame.setupError([...ids(GoStrategyGame.army), 'scout']), contains('need 40'));
      final unknown = ids(GoStrategyGame.army)..[0] = 'king';
      expect(GoStrategyGame.setupError(unknown), contains('unknown'));
      final twoMarshals = ids(GoStrategyGame.army)..[1] = 'marshal';
      expect(GoStrategyGame.setupError(twoMarshals), contains('marshal'));
      final sevenBombs = ids(GoStrategyGame.army)..[GoStrategyGame.army.indexOf(GoPiece.scout)] = 'bomb';
      expect(GoStrategyGame.isValidSetup(sevenBombs), isFalse);
    });

    test('randomSetup: valid, deterministic, sensible', () {
      expect(GoStrategyGame.randomSetup(5), GoStrategyGame.randomSetup(5));
      expect(GoStrategyGame.randomSetup(5), isNot(GoStrategyGame.randomSetup(6)));
      for (var seed = 0; seed < 100; seed++) {
        final s = GoStrategyGame.randomSetup(seed);
        expect(GoStrategyGame.setupError(ids(s)), isNull, reason: 'seed $seed');
        final flag = s.indexOf(GoPiece.flag);
        expect(flag, greaterThanOrEqualTo(30), reason: 'flag on the back row');
        expect(s.sublist(0, 10).every((p) => p.movable), isTrue, reason: 'front row movable');
        final col = flag - 30;
        for (final n in [if (col > 0) flag - 1, if (col < 9) flag + 1, flag - 10]) {
          expect(s[n], GoPiece.bomb, reason: 'seed $seed: bomb next to the flag');
        }
      }
    });

    test('A then B; pieces land on the home squares in setup order', () {
      final g = GoStrategyGame();
      expect(g.phase, GoStrategyPhase.setup);
      expect(g.currentPlayer, a);
      final sa = GoStrategyGame.randomSetup(1), sb = GoStrategyGame.randomSetup(2);
      final e = g.applyMove(GoStrategyGame.setupMove(sa));
      expect(e!.payload, {'setup': a});
      expect(g.hasSetup(a), isTrue);
      expect(g.hasSetup(b), isFalse);
      expect(g.currentPlayer, b);
      expect(g.phase, GoStrategyPhase.setup);
      expectIllegal(g, mv(60, 50));
      g.applyMove({'action': 'autosetup', 'seed': 2});
      expect(g.phase, GoStrategyPhase.play);
      expect(g.currentPlayer, a);
      for (var i = 0; i < 40; i++) {
        expect(g.board[GoStrategyGame.setupSquare(a, i)], GoCell(owner: a, piece: sa[i]));
        expect(g.board[GoStrategyGame.setupSquare(b, i)], GoCell(owner: b, piece: sb[i]));
      }
      for (var s = 40; s < 60; s++) {
        expect(g.board[s].isEmpty, isTrue);
      }
      expectIllegal(g, {'action': 'autosetup', 'seed': 3});
      expectIllegal(g, GoStrategyGame.setupMove(sa));
    });

    test('invalid setups are rejected without change', () {
      final g = GoStrategyGame();
      expectIllegal(g, {'action': 'setup', 'pieces': ids(GoStrategyGame.army).sublist(0, 39)});
      expectIllegal(g, {'action': 'setup', 'pieces': [...ids(GoStrategyGame.army)]..[0] = 'flag'});
      expectIllegal(g, {'action': 'setup'});
      expectIllegal(g, {'action': 'autosetup', 'seed': 'x'});
      expectIllegal(g, {'action': 'nope'});
    });

    test('legalMoves in setup are sample autosetups', () {
      final g = GoStrategyGame();
      expect(g.legalMoves, hasLength(10));
      expect(g.legalMoves.every((m) => m['action'] == 'autosetup'), isTrue);
      for (final m in g.legalMoves) {
        expect(GoStrategyGame().applyMove(m), isNotNull);
      }
    });

    test('a setup that leaves A without a move loses at once', () {
      // Front row: bombs on every square that faces open ground; the
      // pieces in front of the lakes are boxed in.
      final rest = [for (final p in GoStrategyGame.army) if (p != GoPiece.bomb) p];
      final front = <GoPiece?>[GoPiece.bomb, GoPiece.bomb, null, null, GoPiece.bomb, GoPiece.bomb, null, null, GoPiece.bomb, GoPiece.bomb];
      var k = 0;
      final setup = [for (var i = 0; i < 40; i++) i < 10 && front[i] != null ? front[i]! : rest[k++]];
      expect(GoStrategyGame.isValidSetup(ids(setup)), isTrue);
      final g = GoStrategyGame()
        ..applyMove(GoStrategyGame.setupMove(setup))
        ..applyMove({'action': 'autosetup', 'seed': 1});
      expect(g.result.winner, b);
      expect(g.result.code, GameEndReason.gostrategyNoMoves);
      expect(g.legalMoves, isEmpty);
    });
  });

  group('movement', () {
    test('one step orthogonally onto empty squares; not diagonal, not two', () {
      final g = pos({sq(6, 5): (a, GoPiece.captain), sq(1, 1): (b, GoPiece.sergeant)});
      expect(g.targetsFrom(sq(6, 5)).toSet(), {sq(5, 5), sq(7, 5), sq(6, 4), sq(6, 6)});
      expectIllegal(g, mv(sq(6, 5), sq(5, 4)));
      expectIllegal(g, mv(sq(6, 5), sq(4, 5)));
      expect(g.applyMove(mv(sq(6, 5), sq(5, 5))), isNotNull);
      expect(g.board[sq(5, 5)], GoCell(owner: a, piece: GoPiece.captain, moved: true));
      expect(g.board[sq(6, 5)].isEmpty, isTrue);
      expect(g.currentPlayer, b);
    });

    test('lakes block movement', () {
      final g = pos({sq(5, 4): (a, GoPiece.captain), sq(1, 1): (b, GoPiece.sergeant)});
      expect(g.targetsFrom(sq(5, 4)).toSet(), {sq(4, 4), sq(6, 4), sq(5, 5)});
      expectIllegal(g, mv(sq(5, 4), sq(5, 3)));
    });

    test('bombs and the flag never move; own pieces block; only own pieces move', () {
      final g = pos({
        sq(6, 0): (a, GoPiece.bomb),
        sq(6, 1): (a, GoPiece.captain),
        sq(7, 1): (a, GoPiece.major),
        sq(1, 1): (b, GoPiece.sergeant),
      });
      expect(g.targetsFrom(sq(6, 0)), isEmpty);
      expect(g.targetsFrom(99), isEmpty);
      expectIllegal(g, mv(sq(6, 0), sq(5, 0)));
      expectIllegal(g, mv(99, 89));
      expectIllegal(g, mv(sq(6, 1), sq(7, 1)));
      expectIllegal(g, mv(sq(1, 1), sq(2, 1))); // B's piece on A's turn
      expect(g.targetsFrom(sq(6, 1)).toSet(), {sq(5, 1), sq(6, 2)});
      expect(g.targetsFrom(-1), isEmpty);
      expectIllegal(g, {'action': 'move', 'from': 'x', 'to': 3});
    });

    test('scout runs any distance, stops at lakes and pieces, attacks at the end', () {
      final g = pos({
        sq(9, 0): (a, GoPiece.scout),
        sq(2, 0): (b, GoPiece.sergeant),
        sq(9, 3): (a, GoPiece.captain),
        sq(4, 0): (a, GoPiece.scout),
      });
      // Column a upward: rows 8–5, then the own scout on row 4.
      expect(g.targetsFrom(sq(9, 0)).toSet(), {sq(8, 0), sq(7, 0), sq(6, 0), sq(5, 0), sq(9, 1), sq(9, 2)});
      // Scout on row 4: right stops before the lake, up reaches the enemy.
      expect(g.targetsFrom(sq(4, 0)).toSet(), {sq(4, 1), sq(3, 0), sq(2, 0), sq(5, 0), sq(6, 0), sq(7, 0), sq(8, 0)});
      expectIllegal(g, mv(sq(4, 0), sq(1, 0))); // cannot jump the enemy
      expectIllegal(g, mv(sq(4, 0), sq(4, 3))); // nor the lake
      final e = g.applyMove(mv(sq(4, 0), sq(2, 0)))!;
      expect((e.payload as Map)['fight'], containsPair('outcome', 'defender'));
      expect(g.board[sq(4, 0)].isEmpty, isTrue);
    });

    test('a long scout run reveals the scout, a single step does not', () {
      final g = pos({sq(9, 0): (a, GoPiece.scout), sq(9, 8): (a, GoPiece.scout), sq(1, 1): (b, GoPiece.sergeant)});
      final e = g.applyMove(mv(sq(9, 0), sq(5, 0)))!;
      expect((e.payload as Map)['scout'], isTrue);
      expect(g.viewFor(b)[sq(5, 0)], GoCell(owner: a, piece: GoPiece.scout, revealed: true, moved: true));
      g.applyMove(mv(sq(1, 1), sq(1, 2)));
      g.applyMove(mv(sq(9, 8), sq(8, 8)));
      expect(g.viewFor(b)[sq(8, 8)], GoCell(owner: a, moved: true));
    });
  });

  group('combat', () {
    test('fight table', () {
      const f = GoStrategyGame.fight;
      expect(f(GoPiece.major, GoPiece.captain), GoFightOutcome.attackerWins);
      expect(f(GoPiece.sergeant, GoPiece.captain), GoFightOutcome.defenderWins);
      expect(f(GoPiece.captain, GoPiece.captain), GoFightOutcome.bothLose);
      expect(f(GoPiece.spy, GoPiece.marshal), GoFightOutcome.attackerWins);
      expect(f(GoPiece.marshal, GoPiece.spy), GoFightOutcome.attackerWins);
      expect(f(GoPiece.spy, GoPiece.general), GoFightOutcome.defenderWins);
      expect(f(GoPiece.scout, GoPiece.spy), GoFightOutcome.attackerWins);
      expect(f(GoPiece.spy, GoPiece.spy), GoFightOutcome.bothLose);
      expect(f(GoPiece.miner, GoPiece.bomb), GoFightOutcome.attackerWins);
      expect(f(GoPiece.marshal, GoPiece.bomb), GoFightOutcome.defenderWins);
      expect(f(GoPiece.scout, GoPiece.bomb), GoFightOutcome.defenderWins);
      for (final p in GoPiece.values.where((p) => p.movable)) {
        expect(f(p, GoPiece.flag), GoFightOutcome.flagCaptured);
      }
    });

    /// A attacks from 65 to 55 with [attacker] against [defender].
    (GoStrategyGame, Map) attack(GoPiece attacker, GoPiece defender) {
      final g = pos({sq(6, 5): (a, attacker), sq(5, 5): (b, defender), sq(1, 1): (b, GoPiece.sergeant)});
      final e = g.applyMove(mv(sq(6, 5), sq(5, 5)))!;
      return (g, (e.payload as Map)['fight'] as Map);
    }

    test('higher rank wins and takes the square; both are revealed', () {
      final (g, fight) = attack(GoPiece.major, GoPiece.captain);
      expect(fight, {
        'attacker': 'major',
        'defender': 'captain',
        'attackerRank': 7,
        'defenderRank': 6,
        'attackerPlayer': a,
        'outcome': 'attacker',
        'from': sq(6, 5),
        'to': sq(5, 5),
      });
      expect(g.lastFight, fight);
      expect(g.board[sq(5, 5)], GoCell(owner: a, piece: GoPiece.major, revealed: true, moved: true));
      expect(g.board[sq(6, 5)].isEmpty, isTrue);
      expect(g.viewFor(b)[sq(5, 5)].piece, GoPiece.major);
      expect(g.remaining(b)[GoPiece.captain], 0);
    });

    test('lower rank loses; the defender stays and is revealed', () {
      final (g, fight) = attack(GoPiece.sergeant, GoPiece.captain);
      expect(fight['outcome'], 'defender');
      expect(g.board[sq(6, 5)].isEmpty, isTrue);
      expect(g.board[sq(5, 5)], GoCell(owner: b, piece: GoPiece.captain, revealed: true));
      expect(g.viewFor(a)[sq(5, 5)].piece, GoPiece.captain);
    });

    test('equal ranks remove both', () {
      final (g, fight) = attack(GoPiece.captain, GoPiece.captain);
      expect(fight['outcome'], 'both');
      expect(g.board[sq(6, 5)].isEmpty, isTrue);
      expect(g.board[sq(5, 5)].isEmpty, isTrue);
    });

    test('spy beats the marshal only when attacking', () {
      expect(attack(GoPiece.spy, GoPiece.marshal).$2['outcome'], 'attacker');
      expect(attack(GoPiece.marshal, GoPiece.spy).$2['outcome'], 'attacker');
      expect(attack(GoPiece.spy, GoPiece.marshal).$1.board[sq(5, 5)].piece, GoPiece.spy);
      expect(attack(GoPiece.marshal, GoPiece.spy).$1.board[sq(5, 5)].piece, GoPiece.marshal);
      expect(attack(GoPiece.spy, GoPiece.general).$2['outcome'], 'defender');
    });

    test('miner removes a bomb; anything else dies on it', () {
      final (g, fight) = attack(GoPiece.miner, GoPiece.bomb);
      expect(fight['outcome'], 'attacker');
      expect(fight['defenderRank'], isNull);
      expect(g.board[sq(5, 5)].piece, GoPiece.miner);
      for (final p in [GoPiece.marshal, GoPiece.scout, GoPiece.spy, GoPiece.sergeant]) {
        final (g2, f2) = attack(p, GoPiece.bomb);
        expect(f2['outcome'], 'defender', reason: p.id);
        expect(g2.board[sq(5, 5)], GoCell(owner: b, piece: GoPiece.bomb, revealed: true));
        expect(g2.board[sq(6, 5)].isEmpty, isTrue);
      }
    });

    test('capturing the flag wins; nothing is accepted afterwards', () {
      final g = pos({sq(6, 5): (a, GoPiece.scout), sq(5, 5): (b, GoPiece.flag), sq(1, 1): (b, GoPiece.sergeant)});
      final e = g.applyMove(mv(sq(6, 5), sq(5, 5)))!;
      expect(e.winner, a);
      expect((e.payload as Map)['fight']['outcome'], 'flag');
      expect(g.result.code, GameEndReason.gostrategyFlagCaptured);
      expect(g.result.reason, 'flag captured');
      expect(g.isOver, isTrue);
      expect(g.legalMoves, isEmpty);
      expect(g.targetsFrom(sq(5, 5)), isEmpty);
      expect(g.applyMove(mv(sq(1, 1), sq(2, 1))), isNull);
    });
  });

  group('views', () {
    // KLD-081: attacks onto hidden enemies are targets, also on the remote
    // read-only view (where the enemy's kind is unknown).
    test('targetsFrom includes adjacent hidden enemies, on the game and on the view', () {
      final g = pos({
        sq(6, 5): (a, GoPiece.captain),
        sq(5, 5): (b, GoPiece.lieutenant),
        sq(6, 4): (b, GoPiece.bomb),
        sq(9, 0): (a, GoPiece.scout),
        sq(2, 0): (b, GoPiece.flag),
      });
      expect(g.viewFor(a)[sq(5, 5)].hidden, isTrue);
      expect(g.targetsFrom(sq(6, 5)).toSet(), {sq(5, 5), sq(6, 4), sq(7, 5), sq(6, 6)});
      expect(g.targetsFrom(sq(9, 0)), contains(sq(2, 0)));
      final v = const GoStrategyRedaction().fromView(g.viewJson(a)) as GoStrategyGame;
      expect(v.targetsFrom(sq(6, 5)).toSet(), {sq(5, 5), sq(6, 4), sq(7, 5), sq(6, 6)});
      expect(v.targetsFrom(sq(9, 0)), contains(sq(2, 0)));
      expect(v.legalMoves, anyElement(equals(mv(sq(6, 5), sq(5, 5)))));
    });

    test('viewFor hides unrevealed enemy pieces; board shows everything', () {
      final g = GoStrategyGame()
        ..applyMove({'action': 'autosetup', 'seed': 1})
        ..applyMove({'action': 'autosetup', 'seed': 2});
      final va = g.viewFor(a), vb = g.viewFor(b);
      for (final s in GoStrategyGame.homeSquares(a)) {
        expect(va[s].piece, isNotNull);
        expect(vb[s].hidden, isTrue);
        expect(vb[s].owner, a);
        expect(g.board[s].piece, isNotNull);
      }
      for (final s in GoStrategyGame.homeSquares(b)) {
        expect(va[s].hidden, isTrue);
        expect(vb[s].piece, isNotNull);
      }
      for (final s in GoStrategyGame.lakes) {
        expect(va[s].lake, isTrue);
      }
      expect(g.cellAt(60, viewer: b), vb[60]);
      expect(g.cellAt(60), g.board[60]);
      expect(() => (va as List).add(const GoCell()), throwsUnsupportedError);
    });

    test('moved is public, the rank is not', () {
      final g = pos({sq(6, 5): (a, GoPiece.captain), sq(1, 1): (b, GoPiece.sergeant)});
      expect(g.viewFor(b)[sq(6, 5)], GoCell(owner: a));
      g.applyMove(mv(sq(6, 5), sq(5, 5)));
      expect(g.viewFor(b)[sq(5, 5)], GoCell(owner: a, moved: true));
      expect(g.viewFor(a)[sq(5, 5)].piece, GoPiece.captain);
    });
  });

  group('end of game', () {
    test('two-square rule: at most 3 moves back and forth in a row', () {
      final g = pos({sq(6, 5): (a, GoPiece.captain), sq(0, 9): (b, GoPiece.sergeant)});
      var bSq = sq(0, 9);
      void bMove() {
        expect(g.applyMove(mv(bSq, bSq + 10)), isNotNull);
        bSq += 10;
      }

      expect(g.applyMove(mv(sq(6, 5), sq(5, 5))), isNotNull); // 1
      bMove();
      expect(g.applyMove(mv(sq(5, 5), sq(6, 5))), isNotNull); // 2
      bMove();
      expect(g.applyMove(mv(sq(6, 5), sq(5, 5))), isNotNull); // 3
      bMove();
      expect(g.targetsFrom(sq(5, 5)), isNot(contains(sq(6, 5))));
      expect(g.legalMoves, isNot(contains(mv(sq(5, 5), sq(6, 5)))));
      expectIllegal(g, mv(sq(5, 5), sq(6, 5))); // 4th: forbidden
      expect(g.applyMove(mv(sq(5, 5), sq(5, 4))), isNotNull); // other square: fine
      bMove();
      expect(g.applyMove(mv(sq(5, 4), sq(5, 5))), isNotNull); // new pair, count restarts
    });

    test('the player without a movable piece loses', () {
      final g = pos({sq(6, 5): (a, GoPiece.captain), sq(0, 1): (b, GoPiece.bomb)});
      final e = g.applyMove(mv(sq(6, 5), sq(5, 5)))!;
      expect(e.winner, a);
      expect(g.result.code, GameEndReason.gostrategyNoMoves);
      expect(g.result.reason, 'opponent cannot move');
    });

    test('losing the last movable piece in a fight loses', () {
      final g = pos({sq(6, 5): (a, GoPiece.general), sq(5, 5): (b, GoPiece.major)});
      g.applyMove(mv(sq(6, 5), sq(5, 5)));
      expect(g.result.winner, a);
      expect(g.result.code, GameEndReason.gostrategyNoMoves);
    });

    test('a draw when neither side can move', () {
      final g = pos({sq(6, 5): (a, GoPiece.captain), sq(5, 5): (b, GoPiece.captain), sq(0, 1): (b, GoPiece.bomb)});
      final e = g.applyMove(mv(sq(6, 5), sq(5, 5)))!;
      expect(e.draw, isTrue);
      expect(g.result.draw, isTrue);
      expect(g.result.winner, isNull);
      expect(g.result.code, GameEndReason.gostrategyBothBlocked);
    });

    test('draw after the move limit without a capture; a fight resets it', () {
      final g = pos({
        sq(6, 0): (a, GoPiece.captain),
        sq(6, 9): (a, GoPiece.major),
        sq(3, 0): (b, GoPiece.captain),
        sq(3, 9): (b, GoPiece.sergeant),
      }, limit: 4);
      g.applyMove(mv(sq(6, 9), sq(5, 9)));
      g.applyMove(mv(sq(3, 9), sq(4, 9)));
      expect(g.movesSinceCapture, 2);
      g.applyMove(mv(sq(5, 9), sq(4, 9))); // major beats sergeant
      expect(g.movesSinceCapture, 0);
      g.applyMove(mv(sq(3, 0), sq(4, 0)));
      g.applyMove(mv(sq(6, 0), sq(5, 0)));
      g.applyMove(mv(sq(4, 0), sq(3, 0)));
      expect(g.isOver, isFalse);
      final e = g.applyMove(mv(sq(4, 9), sq(3, 9)))!;
      expect(e.draw, isTrue);
      expect(g.result.code, GameEndReason.gostrategyMoveLimit);
      expect(g.result.params, {'moves': 4});
      expect(g.result.reason, '4 moves without a capture');
      expect(GoStrategyGame().noCaptureLimit, 200);
    });
  });

  group('determinism and history', () {
    List<Map<String, dynamic>> play(int seed, GoStrategyGame g, int n) {
      final rng = Random(seed);
      final moves = <Map<String, dynamic>>[];
      for (var i = 0; i < n && !g.isOver; i++) {
        final legal = g.legalMoves;
        final m = legal[rng.nextInt(legal.length)];
        expect(g.applyMove(m), isNotNull);
        moves.add(m);
      }
      return moves;
    }

    test('same moves give the same game; history logs the player', () {
      final g1 = GoStrategyGame();
      final moves = play(3, g1, 150);
      final g2 = GoStrategyGame();
      for (final m in moves) {
        g2.applyMove(m);
      }
      expect(g2.board, g1.board);
      expect(g2.history, g1.history);
      expect(g1.history.first, {'action': 'autosetup', 'seed': moves.first['seed'], 'player': a});
      expect(g1.history[1]['player'], b);
      expect(g1.history[2], {...moves[2], 'player': a});
      expect(() => g1.history.add({}), throwsUnsupportedError);
      final r = replay(const GameConfig('gostrategy', seed: 9), moves)! as GoStrategyGame;
      expect(r.board, g1.board);
      expect(r.viewFor(b), g1.viewFor(b));
    });

    test('full seeded auto games reach an end with a known code', () {
      for (var seed = 0; seed < 30; seed++) {
        final c = DebugConsole('gostrategy', seed)..handle('auto');
        final g = c.current.game as GoStrategyGame;
        expect(g.isOver, isTrue, reason: 'seed $seed');
        expect(g.result.code!.code, startsWith('gostrategy.'));
      }
    });

    test('random legal play always ends (move limit at the latest)', () {
      final rng = Random(1);
      for (var i = 0; i < 5; i++) {
        final g = GoStrategyGame();
        var n = 0;
        while (!g.isOver) {
          final legal = g.legalMoves;
          expect(legal, isNotEmpty);
          g.applyMove(legal[rng.nextInt(legal.length)]);
          expect(++n, lessThan(20000));
        }
      }
    });
  });

  group('registry', () {
    test('gostrategy is registered as a hidden-information game with an app screen (KLD-058b)', () {
      final spec = specById('gostrategy')!;
      expect(spec.title, 'GoStrategy');
      expect(spec.hiddenInformation, isTrue);
      expect(spec.appReady, isTrue);
      expect(appGameSpecs.map((s) => s.id), contains('gostrategy'));
      expect(createGame(const GameConfig('gostrategy', seed: 4)), isA<GoStrategyGame>());
    });
  });
}

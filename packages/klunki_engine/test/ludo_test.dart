import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-131: Rauswurf, the cross-and-circle race game.
void main() {
  const h = LudoGame.house;

  /// A game with the pawns at [pawns] and the next rolls [rolls]; seat
  /// [seat] to roll.
  LudoGame setup(List<List<int>> pawns,
      {List<int> rolls = const [], int seat = 0, LudoRules rules = const LudoRules()}) {
    final g = LudoGame(playerCount: pawns.length, rules: rules)..debugSetPawns(pawns, seat: seat);
    g.debugScriptRolls(rolls);
    return g;
  }

  GameEvent roll(LudoGame g) {
    final e = g.applyMove(LudoGame.rollMove);
    expect(e, isNotNull, reason: 'roll in ${g.toJson()}');
    return e!;
  }

  GameEvent move(LudoGame g, int pawn) {
    final e = g.applyMove(LudoGame.pawnMove(pawn));
    expect(e, isNotNull, reason: 'move $pawn in ${g.toJson()}');
    return e!;
  }

  /// Plays a whole game with the debug bot; returns the moves.
  List<Map<String, dynamic>> botGame(LudoGame g, int seed) {
    final t = LudoText(game: g);
    final rng = Random(seed);
    final moves = <Map<String, dynamic>>[];
    var n = 0;
    while (!g.isOver && n++ < 5000) {
      final m = t.autoMove(rng);
      expect(g.applyMove(m), isNotNull, reason: 'bot move $m in ${g.toJson()}');
      moves.add(m);
    }
    expect(g.isOver, isTrue);
    return moves;
  }

  group('board', () {
    test('two players sit opposite; three and four take the corners in turn', () {
      expect(LudoGame.cornersFor(2), [0, 2]);
      expect(LudoGame.cornersFor(3), [0, 1, 2]);
      expect(LudoGame.cornersFor(4), [0, 1, 2, 3]);
      final g = LudoGame(playerCount: 2);
      expect(g.trackFieldOf(0, 0), 0);
      expect(g.trackFieldOf(1, 0), 20);
      expect(g.trackFieldOf(1, 25), 5);
      expect(LudoGame(playerCount: 4).trackFieldOf(3, 0), 30);
      expect(() => LudoGame(playerCount: 5), throwsArgumentError);
    });

    test('everybody starts in the house; seat 0 rolls', () {
      final g = LudoGame(playerCount: 3);
      for (var s = 0; s < 3; s++) {
        expect(g.houseCount(s), 4);
      }
      expect(g.actorSeat, 0);
      expect(g.legalMoves, [LudoGame.rollMove]);
      expect(g.isOver, isFalse);
    });
  });

  group('three tries', () {
    test('all in the house: three tries for a 6, then the next seat', () {
      final g = LudoGame()..debugScriptRolls([1, 2, 3]);
      expect(g.needsSix(0), isTrue);
      expect(g.triesAllowed, 3);
      expect(roll(g).payload, {'rolled': 1, 'seat': 0, 'again': true, 'tries': 2});
      expect(g.currentSeat, 0);
      expect(roll(g).payload, containsPair('tries', 1));
      expect(roll(g).payload, {'rolled': 3, 'seat': 0, 'passed': true});
      expect(g.currentSeat, 1);
      expect(g.triesUsed, 0);
    });

    test('a 6 in the second try brings a pawn out', () {
      final g = LudoGame()..debugScriptRolls([4, 6]);
      roll(g);
      roll(g);
      expect(g.die, 6);
      expect(g.movablePawns, [0, 1, 2, 3], reason: 'every pawn in the house may come out');
      move(g, 2);
      expect(g.pawnsOf(0), [h, h, 0, h]);
    });

    test('pawns stuck at the end of the finish lane count as "needs a 6"', () {
      expect(setup([[43, 42, h, h], [h, h, h, h]]).triesAllowed, 3);
      expect(setup([[43, 41, h, h], [h, h, h, h]]).triesAllowed, 1, reason: 'lane 2 can still move 1');
      expect(setup([[5, h, h, h], [h, h, h, h]]).triesAllowed, 1);
    });

    test('off: one try', () {
      final g = LudoGame(rules: const LudoRules(threeTries: false))..debugScriptRolls([2]);
      expect(roll(g).payload, containsPair('passed', true));
      expect(g.currentSeat, 1);
    });

    test('a pawn on the track: a roll that cannot move passes at once', () {
      // Pawn at 39 needs exactly 1–4; a 5 is too much.
      final g = setup([[39, h, h, h], [h, h, h, h]], rolls: [5]);
      expect(roll(g).payload, containsPair('passed', true));
      expect(g.currentSeat, 1);
    });
  });

  group('six', () {
    test('a 6 brings a pawn out and rolls again', () {
      final g = LudoGame()..debugScriptRolls([6, 3]);
      roll(g);
      final e = move(g, 0);
      expect(e.payload, containsPair('again', true));
      expect(g.currentSeat, 0);
      expect(g.mustRoll, isTrue);
      roll(g);
      expect(g.movablePawns, [0]);
      move(g, 0);
      expect(g.pawnsOf(0), [3, h, h, h]);
      expect(g.currentSeat, 1);
    });

    test('a 6 must bring a pawn out while the start field is free', () {
      final g = setup([[12, h, h, h], [h, h, h, h]], rolls: [6]);
      roll(g);
      expect(g.movablePawns, [1, 2, 3]);
      expect(g.applyMove(LudoGame.pawnMove(0)), isNull);
    });

    test('a 6 that cannot move still rolls again', () {
      // No pawn in the house, and 38 + 6 is past the end of the lane.
      final g = setup([[43, 42, 41, 38], [h, h, h, h]], rolls: [6]);
      expect(roll(g).payload, {'rolled': 6, 'seat': 0, 'again': true});
      expect(g.currentSeat, 0);
    });

    test('off: the turn passes after a 6', () {
      final g = LudoGame(rules: const LudoRules(sixAgain: false))..debugScriptRolls([6]);
      roll(g);
      expect(move(g, 0).payload, isNot(contains('again')));
      expect(g.currentSeat, 1);
    });
  });

  group('start field', () {
    test('a pawn on the start field must leave it while pawns wait in the house', () {
      final g = setup([[0, 15, h, h], [h, h, h, h]], rolls: [3]);
      roll(g);
      expect(g.movablePawns, [0]);
      expect(g.applyMove(LudoGame.pawnMove(1)), isNull);
    });

    test('with a 6 too: the start field is blocked, so the start pawn moves', () {
      final g = setup([[0, 15, h, h], [h, h, h, h]], rolls: [6]);
      roll(g);
      expect(g.movablePawns, [0]);
    });

    test('no pawn waiting: any pawn may move', () {
      final g = setup([[0, 15, 43, 42], [h, h, h, h]], rolls: [3]);
      roll(g);
      expect(g.movablePawns, [0, 1]);
    });

    test('the start pawn blocked by an own pawn: the others may move', () {
      final g = setup([[0, 3, h, h], [h, h, h, h]], rolls: [3]);
      roll(g);
      expect(g.movablePawns, [1]);
    });

    test('off: any pawn may move', () {
      final g = setup([[0, 15, h, h], [h, h, h, h]], rolls: [3], rules: const LudoRules(clearStart: false));
      roll(g);
      expect(g.movablePawns, [0, 1]);
    });
  });

  group('capture', () {
    test('landing on another pawn sends it home', () {
      // Seat 1 sits at corner 2: its progress 28 is track field 8.
      final g = setup([[5, 30, h, h], [28, h, h, h]], rolls: [3], seat: 0);
      expect(g.pawnOnField(8), (seat: 1, pawn: 0));
      roll(g);
      final e = move(g, 0);
      expect(e.payload['captured'], {'seat': 1, 'pawn': 0});
      expect(g.pawnsOf(1), [h, h, h, h]);
      expect(g.pawnsOf(0), [8, 30, h, h]);
      expect(g.history.last['captured'], [1, 0]);
    });

    test('a pawn on its own start field can be captured', () {
      final g = setup([[17, 30, 43, 42], [0, h, h, h]], rolls: [3]);
      roll(g);
      move(g, 0);
      expect(g.pawnsOf(1), [h, h, h, h]);
    });

    test('Schlagzwang: a move that captures must be made', () {
      final g = setup([[5, 12, 43, 42], [28, h, h, h]], rolls: [3]);
      roll(g);
      expect(g.movablePawns, [0]);
      expect(g.applyMove(LudoGame.pawnMove(1)), isNull);
    });

    test('Schlagzwang off: any move', () {
      final g = setup([[5, 12, 43, 42], [28, h, h, h]], rolls: [3], rules: const LudoRules(mustCapture: false));
      roll(g);
      expect(g.movablePawns, [0, 1]);
    });

    test('never on an own pawn; jumping over pawns on the track is fine', () {
      // Seat 1 at progress 30 is track field 10.
      final g = setup([[5, 8, 43, 42], [30, h, h, h]], rolls: [3]);
      roll(g);
      // Pawn 0 would land on pawn 1; pawn 1 jumps over seat 1 on field 10.
      expect(g.movablePawns, [1]);
      move(g, 1);
      expect(g.pawnsOf(1), [30, h, h, h]);
    });
  });

  group('finish lane', () {
    test('needs the exact number', () {
      final g = setup([[42, 38, 43, h], [h, h, h, h]], rolls: [2]);
      roll(g);
      expect(g.movablePawns, [1], reason: '42 + 2 is past the end, 38 + 2 = lane 1');
    });

    test('no jumping over a pawn in the finish lane', () {
      final g = setup([[41, 38, 43, 42], [h, h, h, h]], rolls: [4]);
      // 38 + 4 = 42 is taken; 41 + 4 is too far: nothing moves.
      expect(roll(g).payload, containsPair('passed', true));
      final g2 = setup([[41, 37, 14, 20], [h, h, h, h]], rolls: [5]);
      roll(g2);
      // 37 + 5 = 42 would jump over lane 2 (41): not allowed.
      expect(g2.movablePawns, [2, 3]);
      final g3 = setup([[41, 38, 15, 20], [h, h, h, h]], rolls: [2]);
      roll(g3);
      expect(g3.movablePawns, [0, 1, 2, 3]);
    });

    test('the lane belongs to its seat: other pawns are never there', () {
      // Seat 1 at progress 19 is track field 39, right before seat 0's lane.
      final g = setup([[38, h, h, h], [19, h, h, h]], rolls: [3]);
      roll(g);
      expect(g.options.single.captures, isNull);
      move(g, 0);
      expect(g.pawnsOf(0).first, 41);
      expect(g.pawnOnField(39), (seat: 1, pawn: 0));
    });
  });

  group('end', () {
    test('all four pawns home wins', () {
      final g = setup([[43, 42, 41, 38], [10, 43, h, h]], rolls: [2]);
      roll(g);
      final e = move(g, 3);
      expect(e.winner, Player.a);
      expect(g.isOver, isTrue);
      expect(g.legalMoves, isEmpty);
      expect(g.result.code, GameEndReason.ludoAllHome);
      expect(g.result.params, {'a': 4, 'b': 1});
      expect(g.seatResult.places, [1, 2]);
      expect(g.seatResult.params, {'home0': 4, 'home1': 1});
      expect(g.applyMove(LudoGame.rollMove), isNull);
    });

    test('a winning 6 ends the game (no extra roll)', () {
      final g = setup([[43, 42, 41, 34], [h, h, h, h]], rolls: [6]);
      roll(g);
      expect(move(g, 3).payload, isNot(contains('again')));
      expect(g.isOver, isTrue);
    });

    test('4 players: places by pawns home, equal counts share', () {
      final g = setup([[1, 2, 3, 4], [43, 42, 41, 37], [43, 5, h, h], [42, 6, h, h]], rolls: [3], seat: 1);
      roll(g);
      move(g, 3);
      expect(g.seatResult.places, [4, 1, 2, 2]);
      expect(g.result.winner, Player.b);
      expect(g.seatResult.winner, 1);
    });

    test('a winner in seat 2: no Player, draw flag only says "over"', () {
      final g = setup([[1, 2, 3, 4], [5, 6, 7, 8], [43, 42, 41, 39]], rolls: [1], seat: 2);
      roll(g);
      move(g, 3);
      expect(g.result.winner, isNull);
      expect(g.result.draw, isTrue);
      expect(g.seatResult.winner, 2);
    });
  });

  group('seats', () {
    test('turn order 0 → 1 → 2 → 0; seat 2 has no Player', () {
      final g = LudoGame(playerCount: 3)..debugScriptRolls([1, 1, 1, 1, 1, 1, 1, 1, 1]);
      for (final s in [0, 1, 2]) {
        expect(g.currentSeat, s);
        roll(g);
        roll(g);
        roll(g);
      }
      expect(g.currentSeat, 0);
      final g2 = LudoGame(playerCount: 3)..debugSetPawns([[h, h, h, h], [h, h, h, h], [h, h, h, h]], seat: 2);
      expect(() => g2.currentPlayer, throwsStateError);
      expect(g2.actorSeat, 2);
    });

    test('4 players: seat 3 captures seat 0 coming round', () {
      // Seat 3 (corner 3, start 30) at progress 8 = field 38; seat 0 at 0.
      final g = setup([[0, h, h, h], [h, h, h, h], [h, h, h, h], [8, 43, 42, 41]], rolls: [2], seat: 3);
      roll(g);
      move(g, 0);
      expect(g.pawnsOf(0), [h, h, h, h]);
      expect(g.currentSeat, 0);
    });

    test('a seat resigns with 3–4: its pawns leave the board, the others play on', () {
      // Seat 2 (corner 2) at progress 28 is track field 8.
      final g = setup([[5, h, h, h], [h, h, h, h], [28, h, h, h]], rolls: [3]);
      expect(g.pawnOnField(8), (seat: 2, pawn: 0));
      expect(g.applyMove(LudoGame.resignSeatMove(2)), isNotNull);
      expect(g.isSeatOut(2), isTrue);
      expect(g.pawnOnField(8), isNull);
      expect(g.seatOfMove(LudoGame.resignSeatMove(2)), 2);
      roll(g);
      expect(move(g, 0).payload, isNot(contains('captured')));
      expect(g.currentSeat, 1, reason: 'seat 2 is skipped');
      g.debugScriptRolls([1, 1, 1]);
      roll(g);
      roll(g);
      roll(g);
      expect(g.currentSeat, 0);
      expect(g.applyMove(LudoGame.resignSeatMove(1)), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.seatResult.code, 'common.resigned');
      expect(g.seatResult.places, [1, 2, 3], reason: 'the seat that left last ranks best of those out');
      expect(g.result.winner, Player.a);
    });

    test('2 players: the common resign', () {
      final g = LudoGame();
      expect(g.applyMove(Game.resignMove(Player.a)), isNotNull);
      expect(g.result.winner, Player.b);
      expect(g.seatResult.places, [2, 1]);
    });
  });

  group('moves', () {
    test('illegal moves change nothing', () {
      final g = LudoGame()..debugScriptRolls([6]);
      expect(g.applyMove(LudoGame.pawnMove(0)), isNull, reason: 'roll first');
      expect(g.applyMove({'action': 'roll', 'x': 1}), isNull);
      expect(g.applyMove({'action': 'jump'}), isNull);
      roll(g);
      expect(g.applyMove(LudoGame.rollMove), isNull, reason: 'move first');
      expect(g.applyMove(LudoGame.pawnMove(4)), isNull);
      expect(g.applyMove({'action': 'move', 'pawn': '1'}), isNull);
      expect(g.applyMove({'action': 'move', 'pawn': 1, 'x': 1}), isNull);
      expect(g.history, hasLength(1));
      expect(LudoGame.isRoll(LudoGame.rollMove), isTrue);
      expect(LudoGame.isRoll(LudoGame.pawnMove(0)), isFalse);
    });

    test('rules round-trip through the config; defaults are not written', () {
      const c = GameConfig('ludo', seed: 3, players: 4);
      expect(c.toJson(), {'game': 'ludo', 'seed': 3, 'players': 4});
      const off = GameConfig('ludo', ludo: LudoRules(threeTries: false, mustCapture: false, clearStart: false, sixAgain: false));
      expect(off.toJson()['ludo'], {'tries': false, 'capture': false, 'start': false, 'six': false});
      expect(GameConfig.fromJson(off.toJson()), off);
      expect((createGame(off) as LudoGame).rules, off.ludo);
      expect(configProblem(const GameConfig('ludo', players: 5)), isNotNull);
      expect(specById('ludo')!.networkPlay, isFalse);
      expect(specById('ludo')!.hiddenInformation, isFalse);
    });
  });

  group('whole games', () {
    for (final n in [2, 3, 4]) {
      test('$n players: the bot plays to the end; a replay gives the same state', () {
        for (var seed = 0; seed < 5; seed++) {
          final config = GameConfig('ludo', seed: seed, players: n);
          final g = createGame(config) as LudoGame;
          final moves = botGame(g, seed);
          expect(g.seatResult.winner, isNotNull);
          expect(g.homeCount(g.seatResult.winner!), 4);
          final r = replay(config, moves) as LudoGame;
          expect(r.toJson(), g.toJson());
          expect(r.history, g.history);
        }
      });
    }

    test('the same seed rolls the same dice', () {
      List<int> dice(int seed) {
        final g = LudoGame(seed: seed);
        botGame(g, 1);
        return [for (final m in g.history) if (m['action'] == 'roll') m['die'] as int];
      }

      expect(dice(7), dice(7));
      expect(dice(7), isNot(dice(8)));
    });

    test('captures happen in bot games', () {
      var captures = 0;
      for (var seed = 0; seed < 5; seed++) {
        final g = LudoGame(seed: seed, playerCount: 4);
        botGame(g, seed);
        captures += g.history.where((m) => m['captured'] != null).length;
      }
      expect(captures, greaterThan(0));
    });
  });
}

import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-121: Mäxchen, the dice bluffing game.
void main() {
  const roll = MaexchenGame.rollMove;
  const believe = MaexchenGame.believeMove;
  const doubt = MaexchenGame.doubtMove;
  const giveUp = MaexchenGame.giveUpMove;
  Map<String, dynamic> announce(int v) => MaexchenGame.announceMove(v);

  /// A game whose next rolls are [rolls].
  MaexchenGame scripted(List<List<int>> rolls, {int lives = 3, bool double = true}) =>
      MaexchenGame(startLives: lives, maexchenDouble: double)..debugScriptRolls(rolls);

  /// Applies [moves] and expects each to be accepted.
  void play(MaexchenGame g, List<Map<String, dynamic>> moves) {
    for (final m in moves) {
      expect(g.applyMove(m), isNotNull, reason: '$m');
    }
  }

  group('values', () {
    test('order from low to high: 31 … 65, doubles, Mäxchen', () {
      expect(MaexchenGame.ranking,
          [31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65, 11, 22, 33, 44, 55, 66, 21]);
      expect(MaexchenGame.ranking.toSet(), hasLength(21));
      expect(MaexchenGame.beats(32, 31), isTrue);
      expect(MaexchenGame.beats(65, 11), isFalse, reason: 'every double beats every plain value');
      expect(MaexchenGame.beats(11, 65), isTrue);
      expect(MaexchenGame.beats(66, 11), isTrue);
      expect(MaexchenGame.beats(21, 66), isTrue, reason: 'Mäxchen is the highest');
      expect(MaexchenGame.beats(54, 54), isFalse);
      expect(MaexchenGame.isDouble(33), isTrue);
      expect(MaexchenGame.isDouble(21), isFalse);
      expect(MaexchenGame.isValue(12), isFalse);
      expect(MaexchenGame.isValue('54'), isFalse);
    });

    test('a roll reads the higher die first; 2 and 1 is Mäxchen', () {
      expect(MaexchenGame.valueOf(3, 5), 53);
      expect(MaexchenGame.valueOf(5, 3), 53);
      expect(MaexchenGame.valueOf(4, 4), 44);
      expect(MaexchenGame.valueOf(1, 2), 21);
      expect(MaexchenGame.valueOf(1, 3), 31);
      // Every one of the 36 rolls is a value.
      for (var a = 1; a <= 6; a++) {
        for (var b = 1; b <= 6; b++) {
          expect(MaexchenGame.isValue(MaexchenGame.valueOf(a, b)), isTrue);
        }
      }
    });

    test('valuesAbove', () {
      expect(MaexchenGame.valuesAbove(null), MaexchenGame.ranking);
      expect(MaexchenGame.valuesAbove(65).first, 11);
      expect(MaexchenGame.valuesAbove(66), [21]);
      expect(MaexchenGame.valuesAbove(21), isEmpty);
    });
  });

  group('turns', () {
    test('roll, announce, the next player answers', () {
      final g = scripted([[5, 3]]);
      expect(g.phase, MaexchenPhase.roll);
      expect(g.currentPlayer, Player.a);
      expect(g.legalMoves, [roll]);
      final e = g.applyMove(roll)!;
      expect((e.payload as Map)['dice'], [5, 3]);
      expect(g.dice, [5, 3]);
      expect(g.diceValue, 53);
      expect(g.roller, Player.a);
      expect(g.phase, MaexchenPhase.announce);
      expect(g.currentPlayer, Player.a, reason: 'the roller announces');
      expect(g.legalMoves, hasLength(21));
      g.applyMove(announce(54));
      expect(g.announced, 54);
      expect(g.announcer, Player.a);
      expect(g.phase, MaexchenPhase.respond);
      expect(g.currentPlayer, Player.b);
      expect(g.legalMoves, [believe, doubt]);
    });

    test('believing: the believer rolls and must announce higher', () {
      final g = scripted([[5, 3], [1, 1]]);
      play(g, [roll, announce(54), believe]);
      expect(g.phase, MaexchenPhase.roll);
      expect(g.currentPlayer, Player.b);
      play(g, [roll]);
      expect(g.dice, [1, 1]);
      expect(g.roller, Player.b);
      expect(g.legalMoves.first, announce(61));
      expect(g.legalMoves.last, announce(21));
      for (final low in [31, 53, 54]) {
        expect(g.applyMove(announce(low)), isNull, reason: '$low is not higher than 54');
      }
      play(g, [announce(61)]);
      expect(g.currentPlayer, Player.a);
    });

    test('the announcement may be a lie, and any value may start a round', () {
      final g = scripted([[3, 1]]);
      play(g, [roll, announce(66)]);
      expect(g.announced, 66);
      expect(g.diceValue, 31);
    });
  });

  group('doubt', () {
    test('a bluff is caught: the announcer loses a life and starts the next round', () {
      final g = scripted([[4, 1]]);
      play(g, [roll, announce(52)]);
      final e = g.applyMove(doubt)!;
      final end = g.lastRound!;
      expect(end.dice, [4, 1]);
      expect(end.value, 41);
      expect(end.bluff, isTrue);
      expect(end.loser, 0);
      expect(end.lost, 1);
      expect(g.livesOf(Player.a), 2);
      expect(g.livesOf(Player.b), 3);
      expect((e.payload as Map)['roundEnd'], end.toJson());
      expect(g.round, 2);
      expect(g.phase, MaexchenPhase.roll);
      expect(g.currentPlayer, Player.a, reason: 'the loser starts');
      expect(g.announced, isNull);
      expect(g.dice, isNull);
    });

    test('the truth doubted: the doubter loses a life and starts', () {
      final g = scripted([[5, 4]]);
      play(g, [roll, announce(54), doubt]);
      expect(g.lastRound!.bluff, isFalse);
      expect(g.livesOf(Player.b), 2);
      expect(g.currentPlayer, Player.b);
    });

    test('more than announced also counts as true', () {
      final g = scripted([[6, 6]]);
      play(g, [roll, announce(31), doubt]);
      expect(g.lastRound!.bluff, isFalse);
      expect(g.livesOf(Player.b), 2);
    });

    test('only the last dice count, after several believes', () {
      final g = scripted([[6, 6], [2, 1], [3, 2]]);
      play(g, [roll, announce(43), believe, roll, announce(51), believe, roll, announce(52), doubt]);
      expect(g.lastRound!.dice, [3, 2]);
      expect(g.lastRound!.announcer, 0);
      expect(g.lastRound!.challenger, 1);
      expect(g.livesOf(Player.a), 2, reason: '32 is lower than 52');
    });
  });

  group('Mäxchen', () {
    test('cannot be beaten: no believe, the next player doubts or gives up', () {
      final g = scripted([[2, 1]]);
      play(g, [roll, announce(21)]);
      expect(g.legalMoves, [doubt, giveUp]);
      expect(g.applyMove(believe), isNull);
    });

    test('give up: one life, the dice stay hidden, the giver starts', () {
      final g = scripted([[3, 1]]);
      play(g, [roll, announce(21)]);
      final e = g.applyMove(giveUp)!;
      expect(g.livesOf(Player.b), 2);
      expect(g.livesOf(Player.a), 3);
      expect(g.lastRound!.gaveUp, isTrue);
      expect(g.lastRound!.dice, isNull);
      expect(jsonEncode(e.payload), isNot(contains('dice')));
      expect(g.currentPlayer, Player.b);
    });

    test('give up only after an announced Mäxchen', () {
      final g = scripted([[3, 1]]);
      play(g, [roll, announce(66)]);
      expect(g.applyMove(giveUp), isNull);
    });

    test('a true Mäxchen doubted costs 2 lives (house rule on)', () {
      final g = scripted([[1, 2]]);
      play(g, [roll, announce(21), doubt]);
      expect(g.lastRound!.lost, 2);
      expect(g.livesOf(Player.b), 1);
    });

    test('house rule off: a true Mäxchen doubted costs 1 life', () {
      final g = scripted([[1, 2]], double: false);
      play(g, [roll, announce(21), doubt]);
      expect(g.lastRound!.lost, 1);
      expect(g.livesOf(Player.b), 2);
    });

    test('a true Mäxchen announced as less costs only 1 life', () {
      final g = scripted([[2, 1]]);
      play(g, [roll, announce(43), doubt]);
      expect(g.lastRound!.lost, 1);
    });

    test('a bluffed Mäxchen caught costs the announcer 1 life', () {
      final g = scripted([[6, 6]]);
      play(g, [roll, announce(21), doubt]);
      expect(g.lastRound!.bluff, isTrue);
      expect(g.lastRound!.lost, 1);
      expect(g.livesOf(Player.a), 2);
    });

    test('after 66 only Mäxchen is left to announce', () {
      final g = scripted([[3, 1], [3, 1]]);
      play(g, [roll, announce(66), believe, roll]);
      expect(g.legalMoves, [announce(21)]);
    });
  });

  group('lives and the end', () {
    test('a player without lives loses; the other wins', () {
      final g = scripted([[4, 1], [4, 1], [4, 1]]);
      for (var i = 0; i < 2; i++) {
        play(g, [roll, announce(52), doubt]);
        expect(g.isOver, isFalse);
      }
      final e = g.applyMove(roll);
      expect(e, isNotNull);
      play(g, [announce(52)]);
      final last = g.applyMove(doubt)!;
      expect(last.winner, Player.b);
      expect(g.isOver, isTrue);
      expect(g.result.winner, Player.b);
      expect(g.result.code, GameEndReason.maexchenNoLives);
      expect(g.result.params, {'a': 0, 'b': 3});
      expect(g.legalMoves, isEmpty);
      expect(g.applyMove(roll), isNull);
    });

    test('lives never go below zero (2 lives lost with 1 left)', () {
      final g = scripted([[1, 2]], lives: 1);
      play(g, [roll, announce(21), doubt]);
      expect(g.livesOf(Player.b), 0);
      expect(g.result.winner, Player.a);
      expect(g.result.params, {'a': 1, 'b': 0});
    });

    test('5 lives', () {
      final g = MaexchenGame(startLives: 5);
      expect(g.lives, [5, 5]);
      expect(() => MaexchenGame(startLives: 0), throwsArgumentError);
      expect(() => MaexchenGame(startLives: 10), throwsArgumentError);
      expect(() => MaexchenGame(playerCount: 3), throwsArgumentError);
    });

    test('resign ends the game at any time', () {
      final g = scripted([[3, 1]]);
      play(g, [roll]);
      expect(g.applyMove(Game.resignMove(Player.b)), isNotNull);
      expect(g.result.winner, Player.a);
      expect(g.result.code, GameEndReason.commonResigned);
    });
  });

  group('illegal moves change nothing', () {
    String state(MaexchenGame g) => jsonEncode([g.viewJson(Player.a), g.viewJson(Player.b), g.history.length]);

    test('wrong phase, wrong values, unknown actions', () {
      final g = scripted([[5, 3]]);
      final cases = <Map<String, dynamic>>[
        announce(54), believe, doubt, giveUp, {'action': 'jump'}, {},
      ];
      for (final m in cases) {
        final before = state(g);
        expect(g.applyMove(m), isNull, reason: '$m before rolling');
        expect(state(g), before);
      }
      play(g, [roll]);
      for (final m in <Map<String, dynamic>>[
        roll, believe, doubt, announce(12), announce(70), {'action': 'announce', 'value': '54'},
        {'action': 'announce'}, {'action': 'announce', 'value': 5.4},
      ]) {
        final before = state(g);
        expect(g.applyMove(m), isNull, reason: '$m after rolling');
        expect(state(g), before);
      }
      play(g, [announce(54)]);
      for (final m in [roll, announce(61), giveUp]) {
        final before = state(g);
        expect(g.applyMove(m), isNull, reason: '$m while answering');
        expect(state(g), before);
      }
    });
  });

  group('determinism', () {
    List<Map<String, dynamic>> randomGame(int seed, int moveSeed) {
      final t = MaexchenText(game: MaexchenGame(seed: seed));
      final rng = Random(moveSeed);
      final moves = <Map<String, dynamic>>[];
      while (!t.game.isOver) {
        final m = t.autoMove(rng);
        expect(t.game.applyMove(m), isNotNull);
        moves.add(m);
        expect(moves.length, lessThan(2000));
      }
      return moves;
    }

    test('config + seed + moves replay to the same game', () {
      for (final seed in [1, 2, 3, 99]) {
        final moves = randomGame(seed, seed + 7);
        final config = GameConfig('maexchen', seed: seed);
        final a = replay(config, moves)! as MaexchenGame;
        final b = replay(config, moves)! as MaexchenGame;
        expect(a.isOver, isTrue);
        expect(jsonEncode(a.viewJson(Player.a)), jsonEncode(b.viewJson(Player.a)));
        expect(a.result.winner, b.result.winner);
      }
    });

    test('the seed decides the dice; the same seed rolls the same', () {
      List<int> rolls(int seed) {
        final g = MaexchenGame(seed: seed);
        final out = <int>[];
        for (var i = 0; i < 10; i++) {
          g.applyMove(roll);
          out.add(g.diceValue!);
          g.applyMove(announce(MaexchenGame.ranking.first));
          g.applyMove(doubt);
          if (g.isOver) break;
        }
        return out;
      }

      expect(rolls(5), rolls(5));
      expect(rolls(5), isNot(rolls(6)));
    });

    test('every face shows up on both dice', () {
      final first = <int>{}, second = <int>{};
      for (var seed = 0; seed < 200; seed++) {
        final g = MaexchenGame(seed: seed)..applyMove(roll);
        first.add(g.dice![0]);
        second.add(g.dice![1]);
      }
      expect(first, {1, 2, 3, 4, 5, 6});
      expect(second, {1, 2, 3, 4, 5, 6});
    });
  });

  group('config and registry', () {
    test('lives and the house rule in the config JSON, only when not default', () {
      expect(const GameConfig('maexchen', seed: 4).toJson(), {'game': 'maexchen', 'seed': 4});
      const c = GameConfig('maexchen', seed: 4, lives: 5, maexchenDouble: false);
      expect(c.toJson(), {'game': 'maexchen', 'seed': 4, 'lives': 5, 'maexDouble': false});
      expect(GameConfig.fromJson(c.toJson()), c);
      expect(c.copyWith(seed: 9).lives, 5);
      expect(c.copyWith(seed: 9).maexchenDouble, isFalse);
      final g = createGame(c) as MaexchenGame;
      expect(g.startLives, 5);
      expect(g.maexchenDouble, isFalse);
      expect(configProblem(const GameConfig('maexchen', lives: 0)), isNotNull);
      expect(configProblem(const GameConfig('maexchen', players: 3)), isNotNull);
      expect(configProblem(c), isNull);
    });

    test('registered as a hidden-information game with a secret seed', () {
      final spec = specById('maexchen')!;
      expect(spec.hiddenInformation, isTrue);
      expect(spec.redaction!.secretSeed, isTrue);
      expect(spec.rulesVersion, 1);
      expect(spec.maxPlayers, 2);
    });
  });

  group('redaction', () {
    const r = MaexchenRedaction();

    test('the dice are only in the roller\'s view, until a doubt shows them', () {
      final g = scripted([[6, 5], [2, 2]]);
      play(g, [roll]);
      expect(r.view(g, Player.a)['dice'], [6, 5]);
      expect(r.view(g, Player.b), isNot(contains('dice')));
      final view = r.fromView(jsonDecode(jsonEncode(r.view(g, Player.b))) as Map<String, dynamic>) as MaexchenGame;
      expect(view.dice, isNull);
      expect(view.roller, Player.a);
      play(g, [announce(65), believe, roll]);
      expect(r.view(g, Player.a), isNot(contains('dice')));
      expect(r.view(g, Player.b)['dice'], [2, 2]);
      play(g, [announce(22), doubt]);
      expect(r.view(g, Player.a)['last']['dice'], [2, 2]);
      expect(r.view(g, Player.b)['last']['dice'], [2, 2]);
    });

    test('the roll event shows the dice to the roller only', () {
      final g = scripted([[6, 5]]);
      final e = g.applyMove(roll)!;
      expect(r.redactPayload(e.payload, Player.a, Player.a), {'rolled': true, 'dice': [6, 5], 'value': 65});
      expect(r.redactPayload(e.payload, Player.a, Player.b), {'rolled': true});
      expect(r.redactMove(roll, Player.a, Player.b), roll);
    });

    test('views are read-only and refuse bad data', () {
      final g = scripted([[6, 5]]);
      final view = r.fromView(r.view(g, Player.a));
      expect(view.applyMove(roll), isNull);
      expect(() => r.fromView({'viewer': 'a'}), throwsA(isA<BadViewException>()));
      final bad = r.view(g, Player.a)..['seat'] = 5;
      expect(() => r.fromView(bad), throwsA(isA<BadViewException>()));
      final badValue = r.view(scripted([[1, 1]])..applyMove(roll)..applyMove(announce(11)), Player.a)
        ..['announced'] = 12;
      expect(() => r.fromView(badValue), throwsA(isA<BadViewException>()));
    });
  });

  group('debug console', () {
    test('parses and plays a whole game', () {
      final c = DebugConsole('maexchen', 3);
      expect(c.handle('').contains('Mäxchen'), isTrue);
      expect(c.handle('roll'), contains('shakes the cup'));
      expect(c.handle('maexchen'), contains('announces Mäxchen'));
      expect(c.handle('believe'), contains('Illegal move'));
      expect(c.handle('doubt'), contains('doubts it'));
      final out = c.handle('auto');
      expect(out, contains('wins'));
      expect(c.current.game.isOver, isTrue);
    });

    test('formats what it parses', () {
      final t = MaexchenText();
      for (final m in [roll, believe, doubt, giveUp, announce(54), announce(21)]) {
        expect(t.parse(t.format(m)), m);
      }
      expect(t.parse('a 54'), announce(54));
      expect(t.parse('hello'), isNull);
      expect(DebugConsole.forGame('maexchen', MaexchenGame()), isA<MaexchenText>());
    });

    test('demo plays to the end', () {
      expect(DebugConsole('maexchen').demo('maexchen'), contains('Result: '));
    });
  });
}

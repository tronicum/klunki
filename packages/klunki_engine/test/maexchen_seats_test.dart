import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_engine/sha256.dart';
import 'package:test/test.dart';

/// KLD-121 step 2: Mäxchen for 3–4 seats and the rule variant
/// "Unbegrenzte Leben".
void main() {
  const roll = MaexchenGame.rollMove;
  const believe = MaexchenGame.believeMove;
  const doubt = MaexchenGame.doubtMove;
  const giveUp = MaexchenGame.giveUpMove;
  const end = MaexchenGame.endMove;
  Map<String, dynamic> announce(int v) => MaexchenGame.announceMove(v);

  MaexchenGame scripted(List<List<int>> rolls, {int players = 3, int lives = 3, bool unlimited = false}) =>
      MaexchenGame(playerCount: players, startLives: lives, unlimitedLives: unlimited)..debugScriptRolls(rolls);

  void play(MaexchenGame g, List<Map<String, dynamic>> moves) {
    for (final m in moves) {
      expect(g.applyMove(m), isNotNull, reason: '$m');
    }
  }

  /// One round in which [seat]'s announcement of 65 over a lower roll is
  /// doubted by the next seat: [seat] loses a life (the bluffer).
  List<Map<String, dynamic>> bluffCaught() => [roll, announce(65), doubt];

  group('3–4 seats', () {
    test('2 to 4 seats; 1 and 5 are refused', () {
      for (final n in [2, 3, 4]) {
        expect(MaexchenGame(playerCount: n).lives, List.filled(n, 3));
      }
      expect(() => MaexchenGame(playerCount: 1), throwsArgumentError);
      expect(() => MaexchenGame(playerCount: 5), throwsArgumentError);
      expect(createGame(const GameConfig('maexchen', players: 4)), isA<MaexchenGame>());
      expect((createGame(const GameConfig('maexchen', players: 4)) as SeatGame).playerCount, 4);
    });

    test('the cup passes around the table: each announcement goes to the next seat', () {
      final g = scripted([
        [3, 1],
        [4, 1],
        [5, 1],
        [6, 1]
      ], players: 4);
      expect(g.actorSeat, 0);
      play(g, [roll, announce(31)]);
      expect(g.actorSeat, 1);
      expect(g.phase, MaexchenPhase.respond);
      play(g, [believe, roll, announce(41)]);
      expect(g.actorSeat, 2);
      play(g, [believe, roll, announce(51)]);
      expect(g.actorSeat, 3);
      expect(() => g.currentPlayer, throwsStateError, reason: 'seat 3 has no Player');
      play(g, [believe, roll, announce(61)]);
      expect(g.actorSeat, 0, reason: 'after seat 3 comes seat 0');
      expect(g.announcerSeat, 3);
      expect(g.history.last, {'action': 'announce', 'value': 61, 'seat': 3});
    });

    test('the loser starts the next round, also in seat 2+', () {
      // Seat 1 bluffs (65 over 3+1), seat 2 doubts: seat 1 loses and starts.
      final g = scripted([
        [2, 2],
        [3, 1],
        [2, 2]
      ], players: 3);
      play(g, [roll, announce(11), believe, roll, announce(22), doubt]);
      expect(g.lastRound!.loser, 1);
      expect(g.lives, [3, 2, 3]);
      expect(g.actorSeat, 1);
      // Seat 1 says 54 truthfully over a 6+5, seat 2 doubts and loses.
      play(g, [roll, announce(54), doubt]);
      expect(g.lastRound!.loser, 2);
      expect(g.actorSeat, 2);
    });

    test('a seat without lives is out and skipped; the next seat after it starts', () {
      // 3 seats, 1 life: seat 0 bluffs, seat 1 doubts: seat 0 is out.
      final g = scripted([
        [3, 1],
        [3, 1],
        [3, 1]
      ], players: 3, lives: 1);
      play(g, bluffCaught());
      expect(g.isSeatOut(0), isTrue);
      expect(g.outSeats, [0]);
      expect(g.isOver, isFalse);
      expect(g.actorSeat, 1, reason: 'the loser is out: the next seat still in starts');
      // Seat 1 announces, the cup goes to seat 2; seat 2 announces, the cup
      // skips seat 0 and goes to seat 1.
      play(g, [roll, announce(32), believe, roll, announce(41)]);
      expect(g.actorSeat, 1, reason: 'seat 0 is skipped');
      // Seat 1 doubts seat 2's bluff (41 over 3+1): seat 2 is out, seat 1 wins.
      play(g, [doubt]);
      expect(g.isOver, isTrue);
      expect(g.winnerSeats, [1]);
      final r = g.seatResult;
      expect(r.isOver, isTrue);
      expect(r.code, GameEndReason.maexchenNoLives.code);
      expect(r.places, [3, 1, 2], reason: 'by elimination order: the last one out is second');
      expect(r.ranking, [1, 2, 0]);
      expect(r.params['lives1'], 1);
      expect(g.actorSeat, isNull);
      expect(g.legalMoves, isEmpty);
    });

    test('a winner in seat 2+ is over, without a Player', () {
      final g = scripted([
        [3, 1],
        [3, 1]
      ], players: 3, lives: 1);
      // Seat 0 bluffs, seat 1 doubts: seat 0 out. Seat 1 bluffs, seat 2
      // doubts: seat 1 out, seat 2 wins.
      play(g, [...bluffCaught(), ...bluffCaught()]);
      expect(g.isOver, isTrue);
      expect(g.seatResult.winner, 2);
      expect(g.result.winner, isNull);
      expect(g.result.draw, isTrue, reason: 'the two-player result only says it is over');
    });

    test('Mäxchen rules with more seats: give up only after a Mäxchen, a caught fake costs 2', () {
      final g = scripted([
        [2, 1],
        [3, 1]
      ], players: 4);
      play(g, [roll, announce(21)]);
      expect(g.actorSeat, 1);
      expect(g.legalMoves, [doubt, giveUp]);
      play(g, [giveUp]);
      expect(g.lives, [3, 2, 3, 3]);
      expect(g.actorSeat, 1);
      // Seat 1 fakes a Mäxchen, seat 2 catches it: 2 lives.
      play(g, [roll, announce(21), doubt]);
      expect(g.lives, [3, 0, 3, 3]);
      expect(g.isSeatOut(1), isTrue);
      expect(g.actorSeat, 2, reason: 'seat 1 is out: the next seat starts');
    });

    test('a seat resigns: it is out, a round under way starts again, the others play on', () {
      final g = scripted([
        [6, 5],
        [4, 4]
      ], players: 3);
      play(g, [roll, announce(65)]);
      expect(g.actorSeat, 1);
      expect(g.applyMove({'action': 'resign', 'player': 'a'}), isNull, reason: 'with 3–4 seats a resign names a seat');
      final e = g.applyMove(MaexchenGame.resignSeatMove(1))!;
      expect(e.payload, {'resigned': 1, 'roundDropped': true});
      expect(g.isSeatOut(1), isTrue);
      expect(g.announced, isNull);
      expect(g.phase, MaexchenPhase.roll);
      expect(g.actorSeat, 2, reason: 'the seat to move left: the next one starts');
      expect(g.applyMove(MaexchenGame.resignSeatMove(1)), isNull, reason: 'already out');
      play(g, [roll, announce(44)]);
      expect(g.actorSeat, 0, reason: 'seat 1 is skipped');
      play(g, [MaexchenGame.resignSeatMove(2)]);
      expect(g.isOver, isTrue);
      final r = g.seatResult;
      expect(r.code, GameEndReason.commonResigned.code);
      expect(r.places, [1, 3, 2]);
    });

    test('random games with 3 and 4 seats end with one seat in; replays agree', () {
      for (final n in [3, 4]) {
        for (var seed = 0; seed < 40; seed++) {
          final config = GameConfig('maexchen', seed: seed, players: n);
          final g = createGame(config) as MaexchenGame;
          final rng = Random(seed);
          final moves = <Map<String, dynamic>>[];
          var outsSeen = 0;
          while (!g.isOver) {
            final legal = g.legalMoves;
            final m = legal[rng.nextInt(legal.length)];
            final mover = g.actorSeat!;
            expect(g.isSeatOut(mover), isFalse, reason: 'a seat that is out never moves');
            expect(g.applyMove(m), isNotNull);
            moves.add(m);
            expect(g.outSeats.length, greaterThanOrEqualTo(outsSeen));
            outsSeen = g.outSeats.length;
            expect(moves.length, lessThan(5000));
          }
          expect(g.activeSeats, hasLength(1));
          expect(g.outSeats, hasLength(n - 1));
          final r = g.seatResult;
          expect(r.places.toSet(), {for (var p = 1; p <= n; p++) p});
          expect(r.places[g.outSeats.last], 2);
          final again = replay(config, moves) as MaexchenGame;
          expect(again.lives, g.lives);
          expect(again.seatResult.places, r.places);
        }
      }
    });

    test('views: dice only for the roller, seats out listed', () {
      const red = MaexchenRedaction();
      final g = scripted([
        [3, 1],
        [6, 5]
      ], players: 3, lives: 1);
      play(g, [...bluffCaught(), roll]);
      final v = red.view(g, Player.b);
      expect(v['dice'], [6, 5]);
      expect(v['out'], [0]);
      expect(red.view(g, Player.a), isNot(contains('dice')));
      final back = red.fromView(jsonDecode(jsonEncode(v)) as Map<String, dynamic>) as MaexchenGame;
      expect(back.isSeatOut(0), isTrue);
      expect(back.playerCount, 3);
    });
  });

  group('two seats are the game as before', () {
    /// Every move, event and both views of random 2-seat games, hashed.
    /// The value was taken before KLD-121 step 2 (and compared byte for
    /// byte over 300 seeds × lives 1/3/5 × "Mäxchen doppelt" on/off): two
    /// seats deal, play and show exactly as rules 1 did.
    String transcript() {
      final out = StringBuffer();
      for (var seed = 0; seed < 30; seed++) {
        for (final lives in [1, 3, 5]) {
          for (final dbl in [true, false]) {
            final cfg = GameConfig('maexchen', seed: seed, lives: lives, maexchenDouble: dbl);
            out.writeln(jsonEncode(cfg.toJson()));
            final g = createGame(cfg) as MaexchenGame;
            final pick = Random(seed * 7 + lives);
            var n = 0;
            while (!g.isOver && n < 400) {
              final legal = g.legalMoves;
              var m = legal[pick.nextInt(legal.length)];
              if (n == 300 && seed % 5 == 0) m = Game.resignMove(Player.values[pick.nextInt(2)]);
              final e = g.applyMove(m)!;
              out.writeln('${jsonEncode(m)} ${jsonEncode(e.payload, toEncodable: (o) => o.toString())} ${e.winner}');
              out.writeln(jsonEncode(g.viewJson(Player.a)));
              out.writeln(jsonEncode(g.viewJson(Player.b)));
              n++;
            }
            out.writeln('${g.result.winner} ${g.result.code} ${g.result.params} ${g.result.reason} ${g.history}');
          }
        }
      }
      return sha256Hex(out.toString());
    }

    test('moves, rolls, events, views and results unchanged', () {
      expect(transcript(), _twoSeatTranscript);
    });

    test('the default config JSON is unchanged', () {
      expect(const GameConfig('maexchen', seed: 4).toJson(), {'game': 'maexchen', 'seed': 4});
      expect(MaexchenGame().viewJson(Player.a), isNot(contains('unlimited')));
      expect(MaexchenGame().viewJson(Player.a), isNot(contains('lost')));
    });
  });

  group('Unbegrenzte Leben', () {
    test('config JSON: maexUnlimited only when on; round trip', () {
      const off = GameConfig('maexchen', seed: 2);
      expect(off.toJson(), isNot(contains('maexUnlimited')));
      expect(off.maexchenUnlimited, isFalse);
      const on = GameConfig('maexchen', seed: 2, maexchenUnlimited: true, players: 3);
      expect(on.toJson(), {'game': 'maexchen', 'seed': 2, 'players': 3, 'maexUnlimited': true});
      expect(on.publicJson(), {'game': 'maexchen', 'players': 3, 'maexUnlimited': true});
      expect(GameConfig.fromJson(on.toJson()), on);
      expect(on.copyWith(seed: 5).maexchenUnlimited, isTrue);
      expect(on == off, isFalse);
      expect((createGame(on) as MaexchenGame).unlimitedLives, isTrue);
      expect(fingerprintOf(on), fingerprintOf(off), reason: 'house rules are not part of the fingerprint');
    });

    test('nobody drops out; lost lives are counted; the game never ends by itself', () {
      final g = MaexchenGame(seed: 3, playerCount: 4, startLives: 1, unlimitedLives: true);
      final rng = Random(3);
      var rounds = 0;
      while (rounds < 60) {
        final legal = g.legalMoves;
        final e = g.applyMove(legal[rng.nextInt(legal.length)])!;
        final p = e.payload as Map;
        if (p.containsKey('roundEnd')) {
          rounds++;
          expect(p['lost'], g.lost);
        }
        expect(g.isOver, isFalse);
      }
      expect(g.outSeats, isEmpty);
      expect(g.lives, [1, 1, 1, 1], reason: 'lives are not used up');
      expect(g.lost.fold<int>(0, (a, b) => a + b), greaterThanOrEqualTo(60));
      expect(g.legalMoves, isNot(contains(end)), reason: 'ending is not a game move for bots');
    });

    test('a round costs one life on the tally, a caught fake Mäxchen two', () {
      final g = scripted([
        [3, 1],
        [3, 1]
      ], players: 3, lives: 1, unlimited: true);
      final e = g.applyMove(roll)!;
      expect(e.payload, isNot(contains('lost')));
      play(g, [announce(65)]);
      final done = g.applyMove(doubt)!;
      expect((done.payload as Map)['lost'], [1, 0, 0]);
      expect(g.isSeatOut(0), isFalse);
      expect(g.actorSeat, 0, reason: 'the loser starts');
      play(g, [roll, announce(21), doubt]);
      expect(g.lost, [3, 0, 0]);
      expect(g.lastRound!.lost, 2);
    });

    test('the players end it: fewest lives lost wins, ties share a place', () {
      final g = scripted([
        [3, 1],
        [3, 1],
        [3, 1]
      ], players: 4, unlimited: true);
      // Seat 0 bluffs twice (caught by seat 1), then seat 1 once (by seat 2).
      play(g, [...bluffCaught(), ...bluffCaught()]);
      expect(g.actorSeat, 0);
      play(g, [roll, announce(65), believe, roll, announce(66), doubt]);
      // Seat 1 said 66 over 3+1 and is caught by seat 2.
      expect(g.lost, [2, 1, 0, 0]);
      final e = g.applyMove(end)!;
      expect(e.payload, {
        'ended': true,
        'lost': [2, 1, 0, 0]
      });
      expect(g.isOver, isTrue);
      expect(g.ended, isTrue);
      final r = g.seatResult;
      expect(r.code, GameEndReason.maexchenEnded.code);
      expect(r.places, [4, 3, 1, 1]);
      expect(r.winners, [2, 3]);
      expect(r.params['lost0'], 2);
      expect(g.applyMove(roll), isNull);
      expect(g.applyMove(end), isNull);
    });

    test('two seats: the result names the winner, or a draw', () {
      final g = scripted([
        [3, 1]
      ], players: 2, unlimited: true);
      play(g, [...bluffCaught(), end]);
      expect(g.result.winner, Player.b);
      expect(g.result.code, GameEndReason.maexchenEnded);
      expect(g.result.params, {'a': 1, 'b': 0});
      final tie = MaexchenGame(unlimitedLives: true);
      play(tie, [end]);
      expect(tie.result.draw, isTrue);
      expect(tie.seatResult.places, [1, 1]);
    });

    test('"end" is refused without the variant', () {
      final g = MaexchenGame(playerCount: 3);
      expect(g.applyMove(end), isNull);
      expect(MaexchenGame().applyMove(end), isNull);
    });

    test('the view carries the variant and the tally', () {
      const red = MaexchenRedaction();
      final g = scripted([
        [3, 1]
      ], players: 2, unlimited: true);
      play(g, bluffCaught());
      final v = red.view(g, Player.b);
      expect(v['unlimited'], isTrue);
      expect(v['lost'], [1, 0]);
      final back = red.fromView(jsonDecode(jsonEncode(v)) as Map<String, dynamic>) as MaexchenGame;
      expect(back.unlimitedLives, isTrue);
      expect(back.lost, [1, 0]);
      play(g, [end]);
      final over = red.fromView(red.view(g, Player.a)) as MaexchenGame;
      expect(over.isOver, isTrue);
      expect(over.result.winner, Player.b);
    });

    test('replay with the end move', () {
      const config = GameConfig('maexchen', seed: 11, players: 3, maexchenUnlimited: true);
      final g = createGame(config) as MaexchenGame;
      final rng = Random(1);
      final moves = <Map<String, dynamic>>[];
      for (var i = 0; i < 80; i++) {
        final legal = g.legalMoves;
        final m = legal[rng.nextInt(legal.length)];
        g.applyMove(m);
        moves.add(m);
      }
      g.applyMove(end);
      moves.add(end);
      final again = replay(config, moves) as MaexchenGame;
      expect(again.isOver, isTrue);
      expect(again.lost, g.lost);
      expect(again.seatResult.places, g.seatResult.places);
    });
  });
}

const _twoSeatTranscript = 'b344b32d80c6155b0181bf3c5359636083dc843a2b32891893443f092de0de13';

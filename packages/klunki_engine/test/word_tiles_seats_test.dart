import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-088 step 1 / KLD-094: the word tile game with 3–4 seats.
void main() {
  PlacedTile t(int row, int col, String tile, [String? letter]) => PlacedTile(row, col, tile, letter);
  Map<String, dynamic> place(List<PlacedTile> tiles) => WordTilesGame.placeMove(tiles);
  const pass = {'action': 'pass'};
  const challenge = {'action': 'challenge'};

  WordTilesGame setup(List<List<String>> racks,
          {List<String> bag = const [],
          WordCheck check = WordCheck.challenge,
          WordValidator? validator,
          int? scorelessLimit}) =>
      WordTilesGame(
          check: check, validator: validator, playerCount: racks.length, scorelessLimit: scorelessLimit)
        ..debugSetup(racks: racks, bag: bag);

  int tilesInPlay(WordTilesGame g) =>
      g.board.where((x) => x != null).length +
      g.bagCount +
      [for (var s = 0; s < g.playerCount; s++) g.rackSizeOf(s)].fold(0, (a, b) => a + b);

  group('config and registry', () {
    test('players defaults to 2 and is written only when not 2', () {
      const two = GameConfig('wordtiles', seed: 3);
      expect(two.players, 2);
      expect(two.toJson(), {'game': 'wordtiles', 'seed': 3});
      expect(GameConfig.fromJson(two.toJson()), two);
      const four = GameConfig('wordtiles', seed: 3, players: 4);
      expect(four.toJson(), {'game': 'wordtiles', 'seed': 3, 'players': 4});
      expect(four.publicJson(), {'game': 'wordtiles', 'players': 4});
      expect(GameConfig.fromJson(four.toJson()), four);
      expect(four, isNot(two));
      expect(four.copyWith(seed: 9).players, 4);
      expect(two.copyWith(players: 3).players, 3);
    });

    test('only the word tile game and Ausgewürfelt take 3–4 players', () {
      expect(configProblem(const GameConfig('wordtiles', players: 3)), isNull);
      expect(configProblem(const GameConfig('wordtiles', players: 4)), isNull);
      expect(configProblem(const GameConfig('wordtiles', players: 5)), contains('2–4 players'));
      expect(configProblem(const GameConfig('wordtiles', players: 1)), isNotNull);
      for (final s in gameSpecs.where((s) => s.id != 'wordtiles' && s.id != 'dicesheet')) {
        expect(s.maxPlayers, 2, reason: s.id);
        expect(configProblem(GameConfig(s.id, players: 3)), contains('is for 2 players'), reason: s.id);
      }
      expect(specById('wordtiles')!.maxPlayers, 4);
      expect(specById('dicesheet')!.maxPlayers, 4);
    });

    test('a 4-player game deals 4 racks of 7 from the 100 tiles', () {
      for (final tiles in ['de', 'en']) {
        final g = createGame(GameConfig('wordtiles', seed: 5, tiles: tiles, players: 4)) as WordTilesGame;
        expect(g.playerCount, 4);
        expect([for (var s = 0; s < 4; s++) g.rackSizeOf(s)], [7, 7, 7, 7]);
        expect(g.bagCount, 100 - 28, reason: tiles);
        expect(tilesInPlay(g), g.tileSet.size);
        expect(g.scorelessLimit, 8);
      }
    });

    test('scoreless limit: 6 for 2 and 3 seats, 8 for 4', () {
      expect([for (final n in [2, 3, 4]) WordTilesGame(playerCount: n).scorelessLimit], [6, 6, 8]);
      expect(WordTilesGame(playerCount: 4, scorelessLimit: 5).scorelessLimit, 5);
    });

    test('two seats: views and moves are exactly the 2-player ones', () {
      final g = WordTilesGame(seed: 11);
      expect(g.seatViewJson(0), g.viewJson(Player.a));
      expect(g.seatViewJson(1).keys, isNot(contains('viewerSeat')));
      expect(g.seatViewJson(1).keys, isNot(contains('out')));
      // A seat resign is not a 2-player move; the common one still is.
      expect(g.applyMove(WordTilesGame.resignSeatMove(1)), isNull);
      expect(g.requestAllowMoveFor(0, const [], const ['X'])['player'], 'a');
      expect(g.acceptAllowMoveFor(1), WordTilesGame.acceptAllowMove(Player.b));
      expect(g.applyMove(Game.resignMove(Player.b)), isNotNull);
      expect(g.seatResult.places, [1, 2]);
      expect(g.seatResult.code, 'common.resigned');
    });
  });

  group('turn order and end conditions', () {
    test('four seats move in order 0, 1, 2, 3, 0', () {
      final g = WordTilesGame(seed: 1, playerCount: 4);
      final seen = <int>[];
      for (var i = 0; i < 5; i++) {
        seen.add(g.currentSeat);
        expect(g.actorSeat, g.currentSeat);
        expect(g.applyMove(pass), isNotNull);
      }
      expect(seen, [0, 1, 2, 3, 0]);
    });

    test('8 scoreless turns end a 4-player game; every rack is subtracted', () {
      final g = setup([
        ['A'],
        ['Q', 'E'],
        ['X'],
        ['B', 'B'],
      ]);
      for (var i = 0; i < 7; i++) {
        g.applyMove(pass);
      }
      expect(g.isOver, isFalse);
      expect(g.applyMove(pass), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.rackPenalties, [-1, -11, -8, -4]);
      expect(g.scores, [-1, -11, -8, -4]);
      final r = g.seatResult;
      expect(r.code, GameEndReason.wordtilesScoreless.code);
      expect(r.params['turns'], 8);
      expect(r.places, [1, 4, 3, 2]);
      expect(r.ranking, [0, 3, 2, 1]);
      expect(r.winner, 0);
      expect(g.playResult.winner, Player.a);
      expect(g.actorSeat, isNull);
    });

    test('going out with 4 seats: the others pay, the one who went out gets the sum', () {
      final g = setup([
        ['A', 'B'],
        ['Q'],
        ['X', 'E'],
        ['E'],
      ], check: WordCheck.dictionary, validator: const AcceptAllValidator());
      expect(g.applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')])), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.rackPenalties, [20, -10, -9, -1]);
      final r = g.seatResult;
      expect(r.code, GameEndReason.wordtilesPlayedOut.code);
      expect(r.winner, 0);
      expect(r.places, [1, 4, 3, 2]);
      expect(r.params['score0'], g.scoreOf(0));
    });

    test('a shared first place: two winners, no Player winner', () {
      final g = setup([
        ['E'],
        ['E'],
        ['Q'],
      ], scorelessLimit: 3);
      for (var i = 0; i < 3; i++) {
        g.applyMove(pass);
      }
      expect(g.isOver, isTrue);
      expect(g.winnerSeats, [0, 1]);
      expect(g.seatResult.places, [1, 1, 3]);
      expect(g.seatResult.winner, isNull);
      expect(g.playResult.winner, isNull);
      expect(g.playResult.draw, isTrue);
    });

    test('a winner in seat 2+ is reported through seatResult (playResult only says over)', () {
      final g = setup([
        ['Q'],
        ['X'],
        ['E'],
      ], scorelessLimit: 3);
      for (var i = 0; i < 3; i++) {
        g.applyMove(pass);
      }
      expect(g.seatResult.winner, 2);
      expect(g.playResult.isOver, isTrue);
      expect(g.playResult.winner, isNull);
      expect(g.result.isOver, isTrue);
    });

    test('places: competition ranking, seats that left behind (last to leave best)', () {
      expect(SeatResult.placesFor([10, 20, 20, 5]), [3, 1, 1, 4]);
      expect(SeatResult.placesFor([10, 20, 20, 5], out: [1]), [2, 4, 1, 3]);
      expect(SeatResult.placesFor([0, 0, 0, 0], out: [3, 0]), [3, 1, 1, 4]);
    });
  });

  group('challenge and "Trotzdem zulassen" with more seats', () {
    test('only the next seat may challenge; a successful challenge keeps its turn', () {
      final g = setup([
        ['A', 'B', 'E'],
        ['E'],
        ['E'],
      ], bag: ['E', 'E']);
      g.applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')]));
      expect(g.currentSeat, 1);
      expect(g.canChallenge, isTrue);
      expect(g.applyMove(challenge), isNotNull);
      expect(g.boardEmpty, isTrue);
      expect(g.currentSeat, 1);
      expect(g.scoreOf(0), 0);
      g.applyMove(pass);
      expect(g.currentSeat, 2);
      expect(g.canChallenge, isFalse);
    });

    test('the next seat answers a request; the moves name seats', () {
      final g = setup([
        ['A', 'B'],
        ['E'],
        ['E'],
        ['E'],
      ], bag: ['E', 'E'], check: WordCheck.dictionary, validator: WordListValidator(['ba']));
      final tiles = [t(7, 7, 'A'), t(7, 8, 'B')];
      expect(g.applyMove(place(tiles)), isNull, reason: 'AB is not in the list');
      expect(g.applyMove(WordTilesGame.requestAllowMove(Player.a, tiles, ['AB'])), isNull,
          reason: 'with 4 seats the request names a seat');
      expect(g.applyMove(g.requestAllowMoveFor(1, tiles, ['AB'])), isNull, reason: 'not seat 1\'s turn');
      expect(g.applyMove(g.requestAllowMoveFor(0, tiles, ['AB'])), isNotNull);
      expect(g.allowRequestAnswerer, 1);
      expect(g.actorSeat, 1);
      expect(g.legalMoves, [g.acceptAllowMoveFor(1), g.declineAllowMoveFor(1)]);
      expect(g.seatOfMove(g.acceptAllowMoveFor(1)), 1);
      expect(g.applyMove(g.acceptAllowMoveFor(2)), isNull);
      final e = g.applyMove(g.acceptAllowMoveFor(1));
      expect((e!.payload as Map)['agreed'], 1);
      expect(g.turns.last.allowed, ['AB']);
      expect(g.currentSeat, 1);
    });
  });

  group('resign with 3–4 seats', () {
    test('a seat leaves: rack back to the bag, skipped, ranked last; the game goes on', () {
      final g = WordTilesGame(seed: 4, playerCount: 4);
      final bag = g.bagCount;
      expect(g.applyMove(Game.resignMove(Player.b)), isNull, reason: 'the 2-player resign is not a 4-seat move');
      expect(g.seatOfMove(WordTilesGame.resignSeatMove(2)), 2);
      expect(g.applyMove(WordTilesGame.resignSeatMove(2)), isNotNull);
      expect(g.isOver, isFalse);
      expect(g.isSeatOut(2), isTrue);
      expect(g.rackSizeOf(2), 0);
      expect(g.bagCount, bag + 7);
      expect(tilesInPlay(g), 100);
      expect(g.applyMove(WordTilesGame.resignSeatMove(2)), isNull, reason: 'already out');
      final order = <int>[];
      for (var i = 0; i < 4; i++) {
        order.add(g.currentSeat);
        g.applyMove(pass);
      }
      expect(order, [0, 1, 3, 0]);
      expect(g.turns.where((x) => x.action == 'resign').single.seat, 2);
    });

    test('the seat to move leaves: the turn passes on', () {
      final g = WordTilesGame(seed: 4, playerCount: 3);
      g.applyMove(pass);
      expect(g.currentSeat, 1);
      g.applyMove(WordTilesGame.resignSeatMove(1));
      expect(g.currentSeat, 2);
    });

    test('the last seat left wins; the later a seat left, the better its place', () {
      final g = WordTilesGame(seed: 4, playerCount: 4);
      g.applyMove(WordTilesGame.resignSeatMove(3));
      g.applyMove(WordTilesGame.resignSeatMove(0));
      expect(g.isOver, isFalse);
      final e = g.applyMove(WordTilesGame.resignSeatMove(2));
      expect(g.isOver, isTrue);
      expect(e!.winner, Player.b);
      final r = g.seatResult;
      expect(r.code, GameEndReason.commonResigned.code);
      expect(r.places, [3, 1, 2, 4]);
      expect(r.params['seat'], 2);
      expect(g.playResult.winner, Player.b);
      expect(g.applyMove(pass), isNull);
    });

    test('the challenger leaves: the open placement stands (and ends the game if it went out)', () {
      final g = setup([
        ['A', 'B'],
        ['E'],
        ['Q'],
      ]);
      g.applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')]));
      expect(g.endPending, isTrue);
      g.applyMove(WordTilesGame.resignSeatMove(1));
      expect(g.isOver, isTrue);
      expect(g.seatResult.code, GameEndReason.wordtilesPlayedOut.code);
      expect(g.rackPenalties, [10, 0, -10]);
      expect(g.seatResult.places, [1, 3, 2]);
    });
  });

  group('views per seat', () {
    test('each seat sees its own rack only; the view round-trips', () {
      final g = WordTilesGame(seed: 21, playerCount: 4);
      g.applyMove(pass);
      g.applyMove(WordTilesGame.resignSeatMove(3));
      for (var s = 0; s < 3; s++) {
        final j = jsonDecode(jsonEncode(g.seatViewJson(s))) as Map<String, dynamic>;
        expect(j['viewerSeat'], s);
        expect(j.containsKey('viewer'), s < 2);
        expect(j['rack'], g.rackOf(s));
        expect(j['racks'], [7, 7, 7, 0]);
        expect(j['out'], [3]);
        expect(j.containsKey('seed'), isFalse);
        final v = WordTilesView.fromJson(j);
        expect(v.viewerSeat, s);
        expect(v.rackOf(s), g.rackOf(s));
        for (var o = 0; o < 4; o++) {
          if (o != s) expect(v.rackOf(o), isEmpty);
        }
        expect(v.isSeatOut(3), isTrue);
        expect(jsonEncode(v.seatViewJson(s)), jsonEncode(j));
        expect(() => v.seatViewJson((s + 1) % 4), throwsArgumentError);
        expect(v.legalMoves.isNotEmpty, s == g.currentSeat);
        if (s >= 2) expect(() => v.viewer, throwsStateError);
      }
    });

    test('a view with a seat beyond the player count is refused', () {
      final j = WordTilesGame(seed: 2, playerCount: 3).seatViewJson(2)..['viewerSeat'] = 3;
      expect(() => WordTilesView.fromJson(j), throwsA(isA<BadViewException>()));
    });
  });

  group('bot games', () {
    /// Placements that fit the board, whatever the words: two tiles through
    /// the centre on an empty board, else one tile next to the board.
    Iterable<Map<String, dynamic>> candidates(WordTilesGame g) sync* {
      final rack = g.rackOf(g.currentSeat).toSet().toList()..sort();
      PlacedTile tile(int r, int c, String x) => PlacedTile(r, c, x, x == TileSet.blank ? 'E' : null);
      if (g.boardEmpty) {
        for (final x in rack) {
          for (final y in rack) {
            final m = place([tile(7, 7, x), tile(7, 8, y)]);
            if (g.checkPlacement(m, checkWords: false).ok) yield m;
          }
        }
        return;
      }
      for (var i = 0; i < 225; i++) {
        final r = i ~/ 15, c = i % 15;
        for (final x in rack) {
          final m = place([tile(r, c, x)]);
          if (g.checkPlacement(m, checkWords: false).ok) yield m;
        }
      }
    }

    /// A simple bot: answers open questions, else the best listed placement
    /// most of the time, sometimes something random; may resign.
    Map<String, dynamic> botMove(WordTilesGame g, Random rng, {bool resigns = false}) {
      if (resigns && g.activeSeats.length > 2 && rng.nextInt(150) == 0) {
        return WordTilesGame.resignSeatMove(g.activeSeats[rng.nextInt(g.activeSeats.length)]);
      }
      final moves = g.legalMoves;
      final req = g.allowRequestAnswerer;
      if (req != null) return moves[rng.nextInt(moves.length)];
      if (g.canChallenge) return rng.nextInt(5) == 0 ? challenge : {'action': 'accept'};
      if (g.check == WordCheck.dictionary && rng.nextInt(4) == 0) {
        // A placement the list refuses: ask the next seat to allow it.
        for (final m in candidates(g)) {
          final unknown = g.unknownWords(m);
          if (unknown.isNotEmpty && g.canRequestAllow(unknown)) {
            return g.requestAllowMoveFor(g.currentSeat, [
              for (final x in (m['tiles'] as List).cast<Map<String, dynamic>>())
                PlacedTile(x['row'] as int, x['col'] as int, x['tile'] as String, x['letter'] as String?)
            ], unknown);
          }
        }
      }
      if (rng.nextInt(6) == 0) return moves[rng.nextInt(moves.length)];
      Map<String, dynamic>? best;
      var bestScore = -1;
      for (final m in moves) {
        if (m['action'] != 'place') continue;
        final c = g.checkPlacement(m);
        if (c.score > bestScore) {
          best = m;
          bestScore = c.score;
        }
      }
      return best ?? moves.last;
    }

    for (final players in [3, 4]) {
      for (final check in WordCheck.values) {
        test('$players seats, ${check.name}: games end, tiles are conserved, racks refill, replays match', () {
          for (var seed = 0; seed < 4; seed++) {
            final resigns = seed.isOdd;
            final config = GameConfig('wordtiles', seed: seed, players: players);
            final g = check == WordCheck.dictionary
                ? WordTilesGame(
                    seed: seed, playerCount: players, check: check, validator: const _SomeWords())
                : createGame(config) as WordTilesGame;
            final rng = Random(seed * 31 + players);
            final log = <Map<String, dynamic>>[];
            var n = 0;
            while (!g.isOver) {
              expect(++n, lessThan(3000), reason: 'game must end');
              final seat = g.currentSeat;
              final m = botMove(g, rng, resigns: resigns);
              final before = g.turns.length;
              expect(g.applyMove(m), isNotNull, reason: 'bot move $m');
              log.add(m);
              expect(tilesInPlay(g), g.tileSet.size, reason: 'tile conservation after $m');
              final action = m['action'];
              final completed = g.turns.length > before && (action == 'place' || action == 'exchange') &&
                  !g.turns.last.withdrawn;
              if (completed) {
                expect(g.rackSizeOf(seat) == WordTilesGame.rackSize || g.bagCount == 0, isTrue,
                    reason: 'seat $seat refilled after $m');
              }
              if (g.outSeats.isEmpty) {
                for (var s = 0; s < players; s++) {
                  expect(g.rackSizeOf(s) == WordTilesGame.rackSize || g.bagCount == 0, isTrue,
                      reason: 'seat $s holds 7 while the bag has tiles');
                }
              }
              for (final s in g.outSeats) {
                expect(g.rackSizeOf(s), 0);
              }
            }
            final r = g.seatResult;
            expect(r.isOver, isTrue);
            expect(r.places, hasLength(players));
            expect(r.winners, isNotEmpty);
            for (final s in g.outSeats) {
              expect(r.places[s], greaterThan(players - g.outSeats.length));
            }
            // Replay: same moves, same game, seat by seat.
            final again = check == WordCheck.dictionary
                ? WordTilesGame(
                    seed: seed, playerCount: players, check: check, validator: const _SomeWords())
                : createGame(config) as WordTilesGame;
            for (final m in log) {
              expect(again.applyMove(jsonDecode(jsonEncode(m)) as Map<String, dynamic>), isNotNull);
            }
            expect(again.scores, g.scores);
            expect(again.history.length, g.history.length);
            for (var s = 0; s < players; s++) {
              expect(jsonEncode(again.seatViewJson(s)), jsonEncode(g.seatViewJson(s)));
            }
            expect(again.seatResult.toJson(), r.toJson());
          }
        });
      }
    }
  });
}

/// Accepts about two thirds of all words, deterministically: enough refused
/// words for "Trotzdem zulassen" requests, enough accepted ones for a game.
class _SomeWords extends WordValidator {
  const _SomeWords();
  @override
  bool isWord(String word) => word.codeUnits.fold(0, (a, b) => a + b) % 3 != 0;
}

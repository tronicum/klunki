import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-094 step 1: the word tile game engine.
void main() {
  PlacedTile t(int row, int col, String tile, [String? letter]) => PlacedTile(row, col, tile, letter);
  Map<String, dynamic> place(List<PlacedTile> tiles) => WordTilesGame.placeMove(tiles);
  const pass = {'action': 'pass'};
  const challenge = {'action': 'challenge'};
  const accept = {'action': 'accept'};

  /// A game with fixed racks and a fixed bag (drawn from the end).
  WordTilesGame setup(List<List<String>> racks,
      {List<String> bag = const ['E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E'],
      Map<(int, int), BoardTile> board = const {},
      WordCheck check = WordCheck.challenge,
      WordValidator? validator,
      int players = 2}) =>
      WordTilesGame(check: check, validator: validator, playerCount: players)
        ..debugSetup(racks: racks, bag: bag, board: board);

  BoardTile b(String l) => BoardTile(l);

  group('board layout', () {
    test('our own 15×15 layout: 8 TW, 17 DW, 12 TL, 24 DL, symmetric, centre double word', () {
      final count = <Premium, int>{};
      for (var r = 0; r < 15; r++) {
        for (var c = 0; c < 15; c++) {
          final p = WordTilesGame.premiumAt(r, c);
          count[p] = (count[p] ?? 0) + 1;
          expect(WordTilesGame.premiumAt(c, r), p, reason: 'diagonal');
          expect(WordTilesGame.premiumAt(14 - r, c), p, reason: 'horizontal axis');
          expect(WordTilesGame.premiumAt(r, 14 - c), p, reason: 'vertical axis');
        }
      }
      expect(count[Premium.tripleWord], 8);
      expect(count[Premium.doubleWord], 17);
      expect(count[Premium.tripleLetter], 12);
      expect(count[Premium.doubleLetter], 24);
      expect(WordTilesGame.premiumAt(7, 7), Premium.doubleWord);
      // Not the classic arrangement: no triple word in the corners or on the
      // middle of the edges, no double-word diagonal.
      expect(WordTilesGame.premiumAt(0, 0), isNot(Premium.tripleWord));
      expect(WordTilesGame.premiumAt(0, 7), isNot(Premium.tripleWord));
      expect(WordTilesGame.premiumAt(3, 3), isNot(Premium.doubleWord));
    });
  });

  group('tile sets', () {
    // The derivation documented on TileSet, recomputed here so the
    // constants cannot drift from it.
    TileSet derive(String id, Map<String, double> f) {
      final n = {for (final l in f.keys) l: 1};
      final sorted = f.keys.toList()..sort();
      for (var i = f.length; i < 98; i++) {
        String? best;
        var bestV = -1.0;
        for (final l in sorted) {
          final v = pow(f[l]!, 0.9) / (n[l]! + 1);
          if (v > bestV) {
            best = l;
            bestV = v;
          }
        }
        n[best!] = n[best]! + 1;
      }
      final top = (f.values.toList()..sort()).reversed.take(6).toList();
      final ref = top.reduce((a, b) => a + b) / 6;
      final k = 7 / (log(ref / f.values.reduce(min)) / ln2);
      const bands = [1, 2, 3, 4, 5, 6, 8, 10];
      final p = {
        for (final e in f.entries) e.key: bands[min(7, (max(0.0, log(ref / e.value) / ln2) * k).floor())],
      };
      return TileSet(id, n, p);
    }

    test('German: Best (2005) frequencies, ß folded into S', () {
      final de = derive('de', {
        'A': 6.51, 'B': 1.89, 'C': 3.06, 'D': 5.08, 'E': 17.40, 'F': 1.66, 'G': 3.01, 'H': 4.76, 'I': 7.55, //
        'J': 0.27, 'K': 1.21, 'L': 3.44, 'M': 2.53, 'N': 9.78, 'O': 2.51, 'P': 0.79, 'Q': 0.02, 'R': 7.00, //
        'S': 7.27 + 2 * 0.19, 'T': 6.15, 'U': 4.35, 'V': 0.67, 'W': 1.89, 'X': 0.03, 'Y': 0.04, 'Z': 1.13, //
        'Ä': 0.51, 'Ö': 0.36, 'Ü': 0.64,
      });
      expect(TileSet.german.counts, de.counts);
      expect(TileSet.german.points, de.points);
    });

    test('English: dictionary letter frequencies', () {
      final en = derive('en', {
        'A': 7.8, 'B': 2.0, 'C': 4.0, 'D': 3.8, 'E': 11.0, 'F': 1.4, 'G': 3.0, 'H': 2.3, 'I': 8.6, 'J': 0.25, //
        'K': 0.97, 'L': 5.3, 'M': 2.7, 'N': 7.2, 'O': 6.1, 'P': 2.8, 'Q': 0.19, 'R': 7.3, 'S': 8.7, 'T': 6.7, //
        'U': 3.3, 'V': 1.0, 'W': 0.91, 'X': 0.27, 'Y': 1.6, 'Z': 0.44,
      });
      expect(TileSet.english.counts, en.counts);
      expect(TileSet.english.points, en.points);
    });

    test('100 tiles each; umlauts are tiles, ß is not; normalize', () {
      for (final s in TileSet.all) {
        expect(s.size, 100, reason: s.id);
        expect(s.bag(), hasLength(100));
        expect(s.bag().where((x) => x == TileSet.blank), hasLength(2));
        expect(s.counts.keys.toSet(), s.points.keys.toSet());
      }
      expect(TileSet.german.counts.keys, containsAll(['Ä', 'Ö', 'Ü']));
      expect(TileSet.german.counts.containsKey('ß'), isFalse);
      expect(TileSet.german.normalize('Straße'), 'STRASSE');
      expect(TileSet.german.normalize('häuser'), 'HÄUSER');
      expect(TileSet.german.canSpell('Größe'), isTrue);
      expect(TileSet.english.canSpell('Größe'), isFalse);
      expect(TileSet.byId('de'), TileSet.german);
      expect(TileSet.byId('xx'), isNull);
    });
  });

  group('deal and determinism', () {
    test('same seed, same racks and bag; another seed differs', () {
      List<Object> state(WordTilesGame g) => [g.rackOf(0), g.rackOf(1), g.bagCount];
      final a = WordTilesGame(seed: 42), a2 = WordTilesGame(seed: 42), c = WordTilesGame(seed: 43);
      expect(state(a), state(a2));
      expect(state(a), isNot(state(c)));
      expect(a.rackOf(0), hasLength(7));
      expect(a.bagCount, 86);
      // Tiles are conserved: racks + bag = the tile set.
      final all = [...a.rackOf(0), ...a.rackOf(1)]..sort();
      expect(all.length + a.bagCount, 100);
    });

    test('a replayed game (exchanges included) ends in the same state', () {
      final g = WordTilesGame(seed: 9);
      final rng = Random(1);
      while (!g.isOver) {
        final legal = g.legalMoves;
        g.applyMove(legal[rng.nextInt(legal.length)]);
      }
      final r = replay(const GameConfig('wordtiles', seed: 9), g.history) as WordTilesGame;
      expect(r.board, g.board);
      expect(r.scores, g.scores);
      expect(r.rackOf(0), g.rackOf(0));
      expect(r.result.reason, g.result.reason);
      expect(g.history.any((m) => m['action'] == 'exchange'), isTrue);
    });
  });

  group('scoring by hand', () {
    test('first word on the centre double word: BÄR = (2 + 4 + 1) × 2 = 14', () {
      final g = setup([
        ['B', 'Ä', 'R', 'E', 'N', 'S', 'T'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ]);
      final m = place([t(7, 6, 'B'), t(7, 7, 'Ä'), t(7, 8, 'R')]);
      final c = g.checkPlacement(m);
      expect(c.words.map((w) => w.word), ['BÄR']);
      expect(c.score, 14);
      final e = g.applyMove(m)!;
      expect((e.payload as Map)['score'], 14);
      expect(g.scoreOf(0), 14);
      expect(g.rackOf(0), hasLength(7), reason: 'drew three');
      expect(g.currentSeat, 1);
    });

    test('a blank scores 0: B ? R with the blank as Ä = (2 + 0 + 1) × 2 = 6', () {
      final g = setup([
        ['B', '?', 'R', 'E', 'N', 'S', 'T'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ]);
      expect(g.applyMove(place([t(7, 6, 'B'), t(7, 7, '?', 'Ä'), t(7, 8, 'R')])), isNotNull);
      expect(g.scoreOf(0), 6);
      expect(g.tileAt(7, 7), const BoardTile('Ä', blank: true));
    });

    test('letter premiums on new tiles only: KURZ = 9 + 2 + 1 + 6 = 18, then KURZE = 11', () {
      final g = setup([
        ['K', 'U', 'Z', 'A', 'A', 'A', 'A'],
        ['E', 'A', 'A', 'A', 'A', 'A', 'A'],
      ], board: {(3, 7): b('R'), (4, 7): b('E'), (5, 7): b('H'), (6, 7): b('E'), (7, 7): b('N')});
      // (3,5) triple letter K 3×3, (3,6) double letter U 1×2, R on the board,
      // (3,8) double letter Z 3×2.
      expect(g.applyMove(place([t(3, 5, 'K'), t(3, 6, 'U'), t(3, 8, 'Z')])), isNotNull);
      expect(g.scoreOf(0), 18);
      // E on (3,9) triple letter; K and Z now count plain.
      final c = g.checkPlacement(place([t(3, 9, 'E')]));
      expect(c.words.single.word, 'KURZE');
      expect(c.score, 3 + 1 + 1 + 3 + 3);
    });

    test('word premium: UHR down from the board\'s U, R on a double word = 3 × 2 = 6', () {
      final g = setup([
        ['H', 'R', 'A', 'A', 'A', 'A', 'A'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ], board: {(7, 7): b('H'), (7, 8): b('A'), (7, 9): b('U'), (7, 10): b('S')});
      final c = g.checkPlacement(place([t(8, 9, 'H'), t(9, 9, 'R')]));
      expect(c.words.map((w) => w.word), ['UHR']);
      expect(c.score, 6);
    });

    test('cross words: one tile on a double word doubles both words (TA 4 + TO 6 = 10)', () {
      final g = setup([
        ['T', 'A', 'A', 'A', 'A', 'A', 'A'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ], board: {(5, 10): b('A'), (6, 9): b('O')});
      final c = g.checkPlacement(place([t(5, 9, 'T')]));
      expect(c.words.map((w) => '$w'), ['TA (4)', 'TO (6)']);
      expect(c.score, 10);
    });

    test('a main word with cross words: NEU down + HAUSE across = 5 + 5', () {
      final g = setup([
        ['N', 'E', 'U', 'A', 'A', 'A', 'A'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ], board: {(7, 7): b('H'), (7, 8): b('A'), (7, 9): b('U'), (7, 10): b('S')});
      // (6,11) and (8,11) are double letters.
      final c = g.checkPlacement(place([t(6, 11, 'N'), t(7, 11, 'E'), t(8, 11, 'U')]));
      expect(c.words.map((w) => '$w'), ['NEU (5)', 'HAUSE (5)']);
      expect(c.score, 10);
    });

    test('all seven tiles: bingo bonus 50 (GARTENS 8 × 2 + 50 = 66)', () {
      final g = setup([
        ['G', 'A', 'R', 'T', 'E', 'N', 'S'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ]);
      final m = place([for (var i = 0; i < 7; i++) t(7, 4 + i, 'GARTENS'[i])]);
      final c = g.checkPlacement(m);
      expect(c.bingo, isTrue);
      expect(c.score, 66);
      expect((g.applyMove(m)!.payload as Map)['bingo'], isTrue);
      expect(g.scoreOf(0), 66);
    });
  });

  group('illegal placements', () {
    final rack = ['H', 'A', 'U', 'S', '?', 'E', 'N'];
    PlacementError? first(List<PlacedTile> tiles) =>
        setup([rack, rack]).checkPlacement(place(tiles)).error;
    PlacementError? later(List<PlacedTile> tiles) =>
        setup([rack, rack], board: {(7, 7): b('O'), (7, 8): b('B')}).checkPlacement(place(tiles)).error;

    test('first word must cover the centre and have two letters', () {
      expect(first([t(6, 6, 'H'), t(6, 7, 'A')]), PlacementError.firstNotOnCentre);
      expect(first([t(7, 7, 'H')]), PlacementError.firstTooShort);
      expect(first([t(7, 7, 'H'), t(7, 8, 'A')]), isNull);
    });

    test('one line, no gaps, connected, free squares, own tiles', () {
      expect(first([t(7, 7, 'H'), t(8, 8, 'A')]), PlacementError.notInLine);
      expect(first([t(7, 6, 'H'), t(7, 7, 'A'), t(7, 9, 'S')]), PlacementError.gap);
      expect(later([t(7, 6, 'H'), t(7, 9, 'S')]), isNull, reason: 'the gap is filled by board tiles');
      expect(later([t(7, 5, 'H'), t(7, 9, 'S')]), PlacementError.gap);
      expect(later([t(3, 3, 'H'), t(3, 4, 'A')]), PlacementError.notConnected);
      expect(later([t(7, 7, 'H')]), PlacementError.occupied);
      expect(first([t(7, 7, 'H'), t(7, 7, 'A')]), PlacementError.occupied);
      expect(first([t(7, 7, 'Q'), t(7, 8, 'A')]), PlacementError.notOnRack);
      expect(first([t(7, 7, 'H'), t(7, 8, 'H')]), PlacementError.notOnRack);
      expect(first([t(7, 14, 'H'), t(7, 15, 'A')]), PlacementError.offBoard);
      expect(first([]), PlacementError.empty);
    });

    test('malformed tiles: blank without letter, letter tile with one, unknown letters', () {
      final g = setup([rack, rack]);
      for (final tiles in [
        [{'row': 7, 'col': 7, 'tile': '?'}],
        [{'row': 7, 'col': 7, 'tile': '?', 'letter': 'ß'}],
        [{'row': 7, 'col': 7, 'tile': 'H', 'letter': 'H'}],
        [{'row': 7, 'col': 7, 'tile': 'ß'}],
        [{'row': '7', 'col': 7, 'tile': 'H'}],
        'HAUS',
      ]) {
        expect(g.checkPlacement({'action': 'place', 'tiles': tiles}).error, PlacementError.malformed, reason: '$tiles');
        expect(g.applyMove({'action': 'place', 'tiles': tiles}), isNull);
      }
      expect(g.applyMove({...place([t(7, 7, 'H'), t(7, 8, 'A')]), 'extra': 1}), isNull);
      expect(g.history, isEmpty);
      expect(g.rackOf(0), rack);
    });

    test('a refused move changes nothing', () {
      final g = setup([rack, rack]);
      final before = jsonEncode(g.viewJson(Player.a));
      expect(g.applyMove(place([t(0, 0, 'H'), t(0, 1, 'A')])), isNull);
      expect(jsonEncode(g.viewJson(Player.a)), before);
    });
  });

  group('exchange and pass', () {
    test('exchange draws new tiles and returns the old ones to the bag', () {
      final g = WordTilesGame(seed: 5);
      final rack = g.rackOf(0);
      final e = g.applyMove({'action': 'exchange', 'tiles': rack.take(3).toList()});
      expect(e, isNotNull);
      expect(g.rackOf(0), hasLength(7));
      expect(g.bagCount, 86);
      expect(g.currentSeat, 1);
      expect(g.scorelessTurns, 1);
      expect((e!.payload as Map)['count'], 3);
    });

    test('only with at least 7 tiles in the bag, and only own tiles', () {
      final rack = ['A', 'B', 'C', 'D', 'E', 'F', 'G'];
      final six = setup([rack, rack], bag: ['E', 'E', 'E', 'E', 'E', 'E']);
      expect(six.canExchange, isFalse);
      expect(six.applyMove({'action': 'exchange', 'tiles': ['A']}), isNull);
      expect(six.legalMoves.where((m) => m['action'] == 'exchange'), isEmpty);
      final seven = setup([rack, rack], bag: ['E', 'E', 'E', 'E', 'E', 'E', 'E']);
      expect(seven.applyMove({'action': 'exchange', 'tiles': ['Z']}), isNull);
      expect(seven.applyMove({'action': 'exchange', 'tiles': ['A', 'A']}), isNull);
      expect(seven.applyMove({'action': 'exchange', 'tiles': []}), isNull);
      expect(seven.applyMove({'action': 'exchange', 'tiles': ['A', 'B']}), isNotNull);
      expect(seven.rackOf(0), ['C', 'D', 'E', 'F', 'G', 'E', 'E']);
      expect(seven.bagCount, 7);
    });

    test('pass passes the turn', () {
      final g = WordTilesGame();
      expect(g.applyMove(pass), isNotNull);
      expect(g.currentSeat, 1);
      expect(g.turns.single.action, 'pass');
    });
  });

  group('game end', () {
    test('six scoreless turns end it; each rack value is subtracted', () {
      final g = setup([
        ['Q', 'A', 'A', 'A', 'A', 'A', 'A'], // 10 + 6
        ['X', 'Y', 'E', 'E', 'E', 'E', 'E'], // 8 + 8 + 5
      ]);
      for (var i = 0; i < 5; i++) {
        expect(g.applyMove(pass), isNotNull);
      }
      expect(g.isOver, isFalse);
      final e = g.applyMove(pass)!;
      expect(g.isOver, isTrue);
      expect(g.rackPenalties, [-16, -21]);
      expect(g.scores, [-16, -21]);
      expect(e.winner, Player.a);
      expect(g.result.code, GameEndReason.wordtilesScoreless);
      expect(g.result.params, {'a': -16, 'b': -21, 'turns': 6});
      expect(g.applyMove(pass), isNull);
      expect(g.legalMoves, isEmpty);
    });

    test('a scoring placement resets the scoreless count', () {
      final g = setup([
        ['H', 'A', 'A', 'A', 'A', 'A', 'A'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ]);
      for (var i = 0; i < 4; i++) {
        g.applyMove(pass);
      }
      expect(g.applyMove(place([t(7, 7, 'H'), t(7, 8, 'A')])), isNotNull);
      expect(g.scorelessTurns, 0);
    });

    test('going out with the bag empty: the others\' racks go to the player (dictionary mode, at once)', () {
      final g = setup([
        ['A', 'B'],
        ['Q', 'X', 'E'],
      ], bag: [], check: WordCheck.dictionary, validator: WordListValidator(['ab']));
      final e = g.applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')]))!;
      expect(g.isOver, isTrue);
      // AB = (1 + 2) × 2 = 6; O holds Q X E = 19.
      expect(g.rackPenalties, [19, -19]);
      expect(g.scores, [25, -19]);
      expect(e.winner, Player.a);
      expect(g.result.code, GameEndReason.wordtilesPlayedOut);
      expect(g.result.params, {'a': 25, 'b': -19});
    });

    test('challenge mode: going out waits for the next player\'s accept or challenge', () {
      WordTilesGame make() => setup([
            ['A', 'B'],
            ['Q', 'X', 'E'],
          ], bag: []);
      final g = make()..applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')]));
      expect(g.isOver, isFalse);
      expect(g.endPending, isTrue);
      expect(g.legalMoves, [challenge, accept]);
      expect(g.applyMove(pass), isNull);
      expect(g.applyMove(place([t(6, 7, 'E')])), isNull);
      expect(g.applyMove(accept), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.scores, [25, -19]);

      final h = make()..applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')]));
      expect(h.applyMove(challenge), isNotNull);
      expect(h.isOver, isFalse);
      expect(h.boardEmpty, isTrue);
      expect(h.rackOf(0), ['A', 'B']);
      expect(h.currentSeat, 1);
    });

    test('draw on equal scores', () {
      final g = setup([
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
        ['A', 'A', 'A', 'A', 'A', 'A', 'A'],
      ]);
      for (var i = 0; i < 6; i++) {
        g.applyMove(pass);
      }
      expect(g.result.draw, isTrue);
      expect(g.result.winner, isNull);
      expect(g.winnerSeats, [0, 1]);
    });
  });

  group('challenge', () {
    List<List<String>> racks() => [
          ['B', 'Ä', 'R', 'E', 'N', 'S', 'T'],
          ['O', 'H', 'R', 'E', 'N', 'S', 'T'],
        ];
    final bar = place([t(7, 6, 'B'), t(7, 7, 'Ä'), t(7, 8, 'R')]);

    test('without a dictionary the challenger decides: the placement is withdrawn exactly', () {
      final g = setup(racks());
      final bagBefore = g.bagCount;
      g.applyMove(bar);
      expect(g.canChallenge, isTrue);
      expect(g.challengeable!.words, ['BÄR']);
      expect(g.legalMoves.take(2), [challenge, accept]);
      final drawnRack = g.rackOf(0);
      final e = g.applyMove(challenge)!;
      expect((e.payload as Map)['withdrawn'], isTrue);
      expect(g.boardEmpty, isTrue);
      expect(g.rackOf(0), racks()[0]);
      expect(g.bagCount, bagBefore);
      expect(g.scoreOf(0), 0);
      expect(g.currentSeat, 1, reason: 'the challenger plays on');
      expect(g.scorelessTurns, 1);
      expect(g.turns.first.withdrawn, isTrue);
      expect(g.canChallenge, isFalse);
      expect(g.applyMove(challenge), isNull);
      // The tiles drawn back come out again the same way.
      g
        ..applyMove(pass)
        ..applyMove(bar);
      expect(g.rackOf(0), drawnRack);
    });

    test('with a word list: a valid word stands and the challenger loses the turn', () {
      final g = setup(racks(), validator: WordListValidator(['Bär']))..applyMove(bar);
      final e = g.applyMove(challenge)!;
      expect((e.payload as Map)['withdrawn'], isFalse);
      expect(g.scoreOf(0), 14);
      expect(g.currentSeat, 0);
      expect(g.scorelessTurns, 1);
    });

    test('with a word list: an invalid word is withdrawn', () {
      final g = setup(racks(), validator: WordListValidator(['Bier']))..applyMove(bar);
      final e = g.applyMove(challenge)!;
      expect((e.payload as Map)['words'], ['BÄR']);
      expect(g.boardEmpty, isTrue);
      expect(g.currentSeat, 1);
    });

    test('playing on accepts; accept closes the window without passing the turn', () {
      final g = setup(racks())..applyMove(bar);
      expect(g.applyMove(place([t(8, 8, 'E')])), isNotNull, reason: 'implicit accept');
      expect(g.challengeable!.seat, 1);
      expect(g.applyMove(accept), isNotNull);
      expect(g.currentSeat, 0);
      expect(g.canChallenge, isFalse);
      expect(g.applyMove(accept), isNull);
      expect(g.scores, [14, 2]);
    });

    test('dictionary mode refuses unknown words and has no challenges', () {
      final g = setup(racks(), check: WordCheck.dictionary, validator: WordListValidator(['bär', 'hören']));
      expect(g.checkPlacement(place([t(7, 7, 'B'), t(7, 8, 'E')])).error, PlacementError.unknownWord);
      expect(g.applyMove(bar), isNotNull);
      expect(g.canChallenge, isFalse);
      expect(g.applyMove(challenge), isNull);
      expect(g.legalMoves, isNot(contains(challenge)));
      expect(() => WordTilesGame(check: WordCheck.dictionary), throwsArgumentError);
    });
  });

  group('more than two seats (engine level, KLD-088)', () {
    test('three seats take turns; going out collects every other rack', () {
      final g = setup([
        ['A', 'B'],
        ['Q'],
        ['X', 'E'],
      ], bag: [], players: 3, check: WordCheck.dictionary, validator: const AcceptAllValidator());
      expect(g.applyMove(pass), isNotNull);
      expect(g.currentSeat, 1);
      expect(g.applyMove(pass), isNotNull);
      expect(g.currentSeat, 2);
      expect(() => g.currentPlayer, throwsStateError);
      expect(g.applyMove(pass), isNotNull);
      expect(g.applyMove(place([t(7, 7, 'A'), t(7, 8, 'B')])), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.rackPenalties, [19, -10, -9]);
      expect(g.scores, [25, -10, -9]);
      expect(g.winnerSeats, [0]);
      expect(() => WordTilesGame(playerCount: 5), throwsA(anything));
    });
  });

  group('redaction', () {
    const r = WordTilesRedaction();

    test('the opponent\'s rack and the bag are not in the view; the seed is secret', () {
      final g = WordTilesGame(seed: 77);
      final json = r.view(g, Player.b);
      expect(json['rack'], g.rackOf(1));
      expect(json['racks'], [7, 7]);
      expect(json.containsKey('seed'), isFalse);
      expect(jsonEncode(json), isNot(contains(jsonEncode(g.rackOf(0)))));
      expect(r.secretSeed, isTrue);
      final view = r.fromView(jsonDecode(jsonEncode(json)) as Map<String, dynamic>) as WordTilesGame;
      expect(view, isA<WordTilesView>());
      expect(view.rackOf(0), isEmpty);
      expect(view.rackSizeOf(0), 7);
      expect(view.rackOf(1), g.rackOf(1));
      expect(view.bagCount, 86);
      expect(view.seed, 0);
      expect(view.applyMove(pass), isNull);
      expect(view.legalMoves, isEmpty, reason: 'not B\'s turn');
    });

    test('another player\'s exchange shows only the count; placements are public', () {
      final ex = {'action': 'exchange', 'tiles': ['Q', '?']};
      expect(r.redactMove(ex, Player.a, Player.b), {'action': 'exchange', 'count': 2});
      expect(r.redactMove(ex, Player.a, Player.a), ex);
      final p = place([t(7, 7, 'H'), t(7, 8, '?', 'A')]);
      expect(r.redactMove(p, Player.a, Player.b), p);
    });

    test('the view round-trips mid-game with an open challenge, and after a resign', () {
      final g = WordTilesGame(seed: 3);
      final text = WordTilesText(game: g);
      for (var i = 0; i < 9; i++) {
        g.applyMove(text.autoMove(Random(i)));
      }
      g.applyMove(text.legalMoves.firstWhere((m) => m['action'] == 'place'));
      expect(g.canChallenge, isTrue);
      for (final p in Player.values) {
        final json = g.viewJson(p);
        final v = WordTilesView.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
        expect(canonicalJson(v.viewJson(p)), canonicalJson(json));
        expect(v.canChallenge, isTrue);
      }
      g.applyMove(Game.resignMove(Player.b));
      final v = WordTilesView.fromJson(g.viewJson(Player.a));
      expect(v.resignedBy, Player.b);
      expect(v.result.code, GameEndReason.commonResigned);
    });

    test('malformed views are refused', () {
      final good = WordTilesGame().viewJson(Player.a);
      for (final bad in [
        {...good, 'tileSet': 'xx'},
        {...good, 'players': 7},
        {...good, 'board': ['...']},
        {...good, 'rack': ['A']},
        {...good, 'seat': 3},
        {...good, 'end': {'code': 'chess.checkmate'}},
      ]) {
        expect(() => WordTilesView.fromJson(bad), throwsA(isA<BadViewException>()), reason: '$bad');
      }
    });
  });

  group('text adapter', () {
    test('notation: column first across, row first down, lower case = blank, board letters typed too', () {
      final g = setup([
        ['B', '?', 'R', 'E', 'N', 'S', 'T'],
        ['O', 'H', 'R', 'E', 'N', 'S', 'T'],
      ]);
      final text = WordTilesText(game: g);
      final m = text.parse('g8 BäR')!;
      expect(m, place([t(7, 6, 'B'), t(7, 7, '?', 'Ä'), t(7, 8, 'R')]));
      expect(text.format(m), 'g8 BäR');
      g.applyMove(m);
      final down = text.parse('7i ORE')!;
      expect(down, place([t(6, 8, 'O'), t(8, 8, 'E')]));
      expect(text.format(down), '7i ORE');
      expect(text.parse('7i OXE'), isNull, reason: 'board letter does not match');
      expect(text.parse('pass'), pass);
      expect(text.parse('exchange QX?'), {'action': 'exchange', 'tiles': ['Q', 'X', '?']});
      expect(text.parse('challenge'), challenge);
      expect(text.parse('z9 HAUS'), isNull);
      expect(text.render(), contains('Ben rack: O H R E N S T'));
      expect(text.render(), contains('Anna\'s BÄR can be challenged.'));
    });

    test('debug console plays a whole game to a known end', () {
      final c = DebugConsole('wordtiles', 1);
      expect(c.handle('auto'), isNotEmpty);
      final g = c.current.game as WordTilesGame;
      expect(g.isOver, isTrue);
      expect(GameEndReason.values, contains(g.result.code));
    });
  });
}

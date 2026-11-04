import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-094 step 9: the house rule "Joker tauschen" (rules version 4).
void main() {
  PlacedTile t(int row, int col, String tile, [String? letter]) => PlacedTile(row, col, tile, letter);
  const pass = {'action': 'pass'};

  /// HAUS across row 7 (cols 6–9), the A a blank.
  final haus = <(int, int), BoardTile>{
    (7, 6): const BoardTile('H'),
    (7, 7): const BoardTile('A', blank: true),
    (7, 8): const BoardTile('U'),
    (7, 9): const BoardTile('S'),
  };
  const bag = ['E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E', 'E'];

  WordTilesGame setup(List<List<String>> racks,
          {bool joker = true,
          Map<(int, int), BoardTile>? board,
          WordCheck check = WordCheck.challenge,
          WordValidator? validator}) =>
      WordTilesGame(check: check, validator: validator, jokerSwap: joker)
        ..debugSetup(racks: racks, bag: bag, board: board ?? haus);

  const rackA = ['A', 'N', 'B', 'C', 'D', 'R', 'T'];
  const rackB = ['O', 'H', 'R', 'E', 'N', 'S', 'T'];
  const swapA = JokerSwap(7, 7, 'A');

  group('Joker tauschen', () {
    test('config: key `joker` only when on, so the default config is unchanged', () {
      expect(const GameConfig('wordtiles', seed: 3).toJson(), {'game': 'wordtiles', 'seed': 3});
      const on = GameConfig('wordtiles', seed: 3, jokerSwap: true);
      expect(on.toJson(), {'game': 'wordtiles', 'seed': 3, 'joker': true});
      expect(on.publicJson(), {'game': 'wordtiles', 'joker': true});
      expect(GameConfig.fromJson(on.toJson()), on);
      expect(on.copyWith(seed: 4).jokerSwap, isTrue);
      expect((createGame(on) as WordTilesGame).jokerSwap, isTrue);
      expect((createGame(const GameConfig('wordtiles')) as WordTilesGame).jokerSwap, isFalse);
      expect(WordTilesGame().viewJson(Player.a).containsKey('jokerSwap'), isFalse);
      expect(specById('wordtiles')!.rulesVersion, 4);
    });

    test('a swap: the real letter goes on the square, the blank onto the rack; it then scores as a letter', () {
      final g = setup([rackA, rackB]);
      expect(g.canSwapJokerAt(7, 7, 'A'), isTrue);
      expect(g.canSwapJokerAt(7, 7, 'B'), isFalse);
      expect(g.canSwapJokerAt(7, 6, 'H'), isFalse, reason: 'not a blank');
      // AN down through the swapped square: A (1) + N (1).
      final move = WordTilesGame.placeMove([t(8, 7, 'N')], swaps: [swapA]);
      expect(move['swaps'], [
        {'row': 7, 'col': 7, 'tile': 'A'},
      ]);
      final c = g.checkPlacement(move);
      expect(c.ok, isTrue);
      expect(c.words.single.word, 'AN');
      expect(c.score, 2);
      expect(c.swaps, [swapA]);
      // Without the swap the blank A scores 0.
      expect(g.checkPlacement(WordTilesGame.placeMove([t(8, 7, 'N')])).score, 1);
      final e = g.applyMove(move)!;
      expect((e.payload as Map)['swaps'], [swapA.toJson()]);
      expect(g.tileAt(7, 7), const BoardTile('A'));
      expect(List.of(g.rackOf(0))..sort(), ['?', 'B', 'C', 'D', 'E', 'R', 'T']);
      expect(g.scoreOf(0), 2);
      expect(g.turns.last.swaps, 1);
      expect(g.turns.last.toJson()['swaps'], 1);
      expect(g.currentSeat, 1);
    });

    test('the blank taken may be laid in the same placement, with any letter', () {
      final g = setup([rackA, rackB]);
      final move = WordTilesGame.placeMove([t(8, 7, '?', 'E'), t(9, 7, 'R')], swaps: [swapA]);
      expect(g.checkPlacement(move).words.single.word, 'AER');
      expect(g.applyMove(move), isNotNull);
      expect(g.tileAt(8, 7), const BoardTile('E', blank: true));
      expect(g.rackOf(0), isNot(contains('?')));
      expect(g.rackOf(0), isNot(contains('A')));
      expect(g.rackSizeOf(0), 7);
    });

    test('refused: option off, wrong letter, not a blank, letter not on the rack, same square twice', () {
      final off = setup([rackA, rackB], joker: false);
      final move = WordTilesGame.placeMove([t(8, 7, 'N')], swaps: [swapA]);
      expect(off.checkPlacement(move).error, PlacementError.malformed);
      expect(off.applyMove(move), isNull);
      expect(off.canSwapJokerAt(7, 7, 'A'), isFalse);

      final g = setup([rackA, rackB]);
      Map<String, dynamic> m(List<JokerSwap> s) => WordTilesGame.placeMove([t(8, 7, 'N')], swaps: s);
      expect(g.checkPlacement(m([const JokerSwap(7, 7, 'B')])).error, PlacementError.malformed, reason: 'wrong letter');
      expect(g.checkPlacement(m([const JokerSwap(7, 8, 'U')])).error, PlacementError.malformed, reason: 'not a blank');
      expect(g.checkPlacement(m([const JokerSwap(3, 3, 'A')])).error, PlacementError.malformed, reason: 'empty');
      expect(g.checkPlacement(m([const JokerSwap(20, 3, 'A')])).error, PlacementError.malformed, reason: 'off board');
      expect(g.checkPlacement(m([swapA, swapA])).error, PlacementError.malformed, reason: 'twice');
      final noA = setup([
        ['N', 'B', 'C', 'D', 'R', 'T', 'E'],
        rackB,
      ]);
      expect(noA.checkPlacement(m([swapA])).error, PlacementError.notOnRack);
      // Malformed swap lists.
      for (final bad in [
        [],
        'x',
        [
          {'row': 7, 'col': 7},
        ],
        [
          {'row': 7, 'col': 7, 'tile': '?'},
        ],
        [
          {'row': 7, 'col': 7, 'tile': 'A', 'letter': 'A'},
        ],
      ]) {
        expect(g.applyMove({'action': 'place', 'tiles': move['tiles'], 'swaps': bad}), isNull, reason: '$bad');
      }
      expect(g.history, isEmpty);
    });

    test('no swap alone, none with an exchange or a pass', () {
      final g = setup([rackA, rackB]);
      expect(g.applyMove(WordTilesGame.placeMove(const [], swaps: [swapA])), isNull);
      expect(g.checkPlacement(WordTilesGame.placeMove(const [], swaps: [swapA])).error, PlacementError.empty);
      expect(
          g.applyMove({
            'action': 'exchange',
            'tiles': ['B'],
            'swaps': [swapA.toJson()],
          }),
          isNull);
      expect(
          g.applyMove({
            'action': 'pass',
            'swaps': [swapA.toJson()],
          }),
          isNull);
      expect(g.tileAt(7, 7), const BoardTile('A', blank: true));
      expect(g.history, isEmpty);
    });

    test('several swaps in one turn', () {
      final board = {
        ...haus,
        (8, 9): const BoardTile('E', blank: true), // SE down from the S
      };
      final g = setup([
        ['A', 'E', 'N', 'B', 'C', 'D', 'R'],
        rackB,
      ], board: board);
      const swapE = JokerSwap(8, 9, 'E');
      final move = WordTilesGame.placeMove([t(8, 7, '?', 'N'), t(8, 8, '?', 'O')], swaps: [swapA, swapE]);
      final c = g.checkPlacement(move);
      expect(c.ok, isTrue, reason: '${c.error}');
      expect([for (final w in c.words) w.word], containsAll(['NOE', 'AN', 'UO']));
      expect(g.applyMove(move), isNotNull);
      expect(g.tileAt(7, 7), const BoardTile('A'));
      expect(g.tileAt(8, 9), const BoardTile('E'));
      expect(g.turns.last.swaps, 2);
      expect(g.rackOf(0), isNot(contains('?')));
      // Two swaps need two letters: one E for two E blanks is refused.
      final twoE = setup([
        ['E', 'N', 'B', 'C', 'D', 'R', 'T'],
        rackB,
      ], board: {
        ...board,
        (7, 7): const BoardTile('E', blank: true),
      });
      expect(
          twoE.checkPlacement(WordTilesGame.placeMove([t(8, 7, 'N')], swaps: [const JokerSwap(7, 7, 'E'), swapE])).error,
          PlacementError.notOnRack);
    });

    test('replay: the same moves (through JSON) give the same game', () {
      final a = setup([rackA, rackB]);
      a.applyMove(WordTilesGame.placeMove([t(8, 7, '?', 'E'), t(9, 7, 'R')], swaps: [swapA]));
      a.applyMove(pass);
      final b = setup([rackA, rackB]);
      for (final m in jsonDecode(jsonEncode(a.history)) as List) {
        expect(b.applyMove(m as Map<String, dynamic>), isNotNull);
      }
      expect(canonicalJson(b.viewJson(Player.a)), canonicalJson(a.viewJson(Player.a)));
      expect(canonicalJson(b.viewJson(Player.b)), canonicalJson(a.viewJson(Player.b)));
      // A real game from a config replays too.
      const config = GameConfig('wordtiles', seed: 9, jokerSwap: true);
      final g = createGame(config) as WordTilesGame;
      final text = WordTilesText(game: g);
      for (var i = 0; i < 6 && !g.isOver; i++) {
        g.applyMove(text.autoMove(Random(i)));
      }
      final again = replay(config, g.history) as WordTilesGame;
      expect(canonicalJson(again.viewJson(Player.a)), canonicalJson(g.viewJson(Player.a)));
    });

    test('redaction: the swap is public; the view keeps the option and round-trips', () {
      const r = WordTilesRedaction();
      final g = setup([rackA, rackB]);
      final move = WordTilesGame.placeMove([t(8, 7, 'N')], swaps: [swapA]);
      expect(r.redactMove(move, Player.a, Player.b), move);
      g.applyMove(move);
      final json = r.view(g, Player.b);
      expect(json['jokerSwap'], isTrue);
      expect((json['board'] as List)[7], contains('HAUS'), reason: 'the A is a real letter now');
      expect(jsonEncode(json), isNot(contains(jsonEncode(g.rackOf(0)))));
      final v = WordTilesView.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(v.jokerSwap, isTrue);
      expect(v.turns.last.swaps, 1);
      expect(canonicalJson(v.viewJson(Player.b)), canonicalJson(json));
    });

    test('a withdrawn placement (challenge) puts the blank back', () {
      final g = setup([rackA, rackB]);
      g.applyMove(WordTilesGame.placeMove([t(8, 7, '?', 'E'), t(9, 7, 'R')], swaps: [swapA]));
      expect(g.canChallenge, isTrue);
      g.applyMove(const {'action': 'challenge'});
      expect(g.tileAt(7, 7), const BoardTile('A', blank: true));
      expect(g.tileAt(8, 7), isNull);
      expect(g.rackOf(0), rackA);
      expect(g.scoreOf(0), 0);
      expect(g.bagCount, bag.length);
    });

    test('"Trotzdem zulassen" carries the swaps; accepting lays them', () {
      final list = WordListValidator(['HAUS']);
      final g = setup([rackA, rackB], check: WordCheck.dictionary, validator: list);
      final tiles = [t(8, 7, 'N')];
      final req = g.requestAllowMoveFor(0, tiles, ['AN'], swaps: [swapA]);
      expect(g.unknownWords(WordTilesGame.placeMove(tiles, swaps: [swapA])), ['AN']);
      expect(g.applyMove(req), isNotNull);
      expect(g.allowRequest!.swaps, [swapA]);
      expect(g.tileAt(7, 7)!.blank, isTrue, reason: 'nothing changes before the answer');
      final view = WordTilesView.fromJson(jsonDecode(jsonEncode(g.viewJson(Player.b))) as Map<String, dynamic>);
      expect(view.allowRequest!.swaps, [swapA]);
      expect(g.applyMove(g.acceptAllowMoveFor(1)), isNotNull);
      expect(g.tileAt(7, 7), const BoardTile('A'));
      expect(g.turns.last.swaps, 1);
      expect(g.turns.last.allowed, ['AN']);
    });

    test('text adapter: "… joker h8"', () {
      final g = setup([rackA, rackB]);
      final text = WordTilesText(game: g);
      expect(text.moveHelp, contains('joker'));
      final m = text.parse('8h AN joker h8')!;
      expect(m, WordTilesGame.placeMove([t(8, 7, 'N')], swaps: [swapA]));
      expect(text.format(m), 'h9 N joker h8');
      expect(text.parse(text.format(m)), m);
      expect(text.parse('8h AN joker g8'), isNull, reason: 'not a blank');
      expect(text.parse('8h AN joker'), isNull);
      expect(text.narrate(Player.a, m, g.applyMove(m)!), contains('took 1 blank'));
    });
  });
}

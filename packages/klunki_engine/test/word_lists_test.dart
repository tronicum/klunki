import 'dart:convert';
import 'dart:typed_data';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-094 step 4: word lists, the check at "Legen" with `allow`, tile set
/// and word list per game.
void main() {
  PlacedTile t(int row, int col, String tile, [String? letter]) => PlacedTile(row, col, tile, letter);

  SortedWordListValidator list(List<String> words, {bool trailingNewline = true}) {
    final text = words.join('\n') + (trailingNewline ? '\n' : '');
    return SortedWordListValidator.fromUtf8(Uint8List.fromList(utf8.encode(text)));
  }

  group('SortedWordListValidator', () {
    // Sorted by code point, as the build tool writes it (Ä Ö Ü after Z).
    final words = ['AB', 'HAUS', 'HAUSE', 'HÄUSER', 'STRASSE', 'ZU', 'ÄRGER', 'ÖL', 'ÜBER'];

    test('finds every word, first and last included, and nothing else', () {
      final v = list(words);
      expect(v.length, words.length);
      for (final w in words) {
        expect(v.isWord(w), isTrue, reason: w);
      }
      for (final w in ['', 'A', 'HAU', 'HAUSES', 'HAEUSER', 'STRAßE', 'Haus', 'ZZ', 'ÜBERALL', 'ÄA']) {
        expect(v.isWord(w), isFalse, reason: w);
      }
    });

    test('umlauts are letters of their own; ß comes in as SS via TileSet.normalize', () {
      final v = list(words);
      expect(v.isWord(TileSet.german.normalize('Häuser')), isTrue);
      expect(v.isWord(TileSet.german.normalize('Straße')), isTrue);
      expect(v.isWord(TileSet.german.normalize('Hauser')), isFalse);
    });

    test('works without a final line feed and with one word', () {
      expect(list(words, trailingNewline: false).isWord('ÜBER'), isTrue);
      expect(list(words, trailingNewline: false).length, words.length);
      expect(list(['QI']).isWord('QI'), isTrue);
      expect(list(['QI']).isWord('Q'), isFalse);
      expect(list([]).isWord('QI'), isFalse);
    });

    test('refuses an unsorted or duplicated list', () {
      expect(() => list(['B', 'A']), throwsFormatException);
      expect(() => list(['A', 'A']), throwsFormatException);
      expect(() => list(['ÄB', 'ZU']), throwsFormatException, reason: 'Ä sorts after Z');
    });
  });

  group('check at "Legen" (dictionary mode with allow)', () {
    late WordTilesGame g;
    final birne = [t(7, 5, 'B'), t(7, 6, 'I'), t(7, 7, 'R'), t(7, 8, 'N'), t(7, 9, 'E')];
    final brine = [t(7, 5, 'B'), t(7, 6, 'R'), t(7, 7, 'I'), t(7, 8, 'N'), t(7, 9, 'E')];

    setUp(() {
      g = WordTilesGame(check: WordCheck.dictionary, validator: list(['BIRNE', 'HAUS']))
        ..debugSetup(racks: [
          ['B', 'I', 'R', 'N', 'E', 'S', 'T'],
          ['H', 'A', 'U', 'S', 'E', 'N', 'T'],
        ], bag: List.filled(20, 'E'));
    });

    test('a known word is placed without asking', () {
      final move = WordTilesGame.placeMove(birne);
      expect(g.unknownWords(move), isEmpty);
      final e = g.applyMove(move)!;
      expect((e.payload as Map).containsKey('allowed'), isFalse);
      expect(g.turns.single.allowed, isEmpty);
      expect(g.canChallenge, isFalse, reason: 'the check at "Legen" replaces the challenge');
    });

    test('an unknown word is refused unless allowed; the allowed word is logged', () {
      final move = WordTilesGame.placeMove(brine);
      expect(g.unknownWords(move), ['BRINE']);
      expect(g.checkPlacement(move).error, PlacementError.unknownWord);
      expect(g.checkPlacement(move, checkWords: false).ok, isTrue, reason: 'the preview never tells');
      expect(g.applyMove(move), isNull);
      // "Zurücknehmen": nothing was submitted, the same player is still on.
      expect(g.currentSeat, 0);
      final allowed = WordTilesGame.placeMove(brine, allow: ['BRINE']);
      final e = g.applyMove(allowed)!;
      expect((e.payload as Map)['allowed'], ['BRINE']);
      expect(g.turns.single.allowed, ['BRINE']);
      expect(g.scoreOf(0), greaterThan(0));
      expect(g.currentSeat, 1);
    });

    test('allow must name exactly the unknown words', () {
      expect(g.applyMove(WordTilesGame.placeMove(birne, allow: ['BIRNE'])), isNull, reason: 'a known word');
      expect(g.applyMove(WordTilesGame.placeMove(brine, allow: ['BRINE', 'XYZ'])), isNull);
      expect(g.applyMove({...WordTilesGame.placeMove(brine), 'allow': 'BRINE'}), isNull);
      expect(g.applyMove({...WordTilesGame.placeMove(brine), 'allow': []}), isNull);
      expect(g.applyMove({...WordTilesGame.placeMove(brine), 'allow': ['BRINE', 'BRINE']}), isNull);
      expect(g.history, isEmpty);
    });

    test('allow is refused in challenge mode', () {
      final c = WordTilesGame()
        ..debugSetup(racks: [
          ['B', 'R', 'I', 'N', 'E', 'S', 'T'],
          ['H', 'A', 'U', 'S', 'E', 'N', 'T'],
        ]);
      expect(c.applyMove(WordTilesGame.placeMove(brine, allow: ['BRINE'])), isNull);
      expect(c.unknownWords(WordTilesGame.placeMove(brine)), isEmpty);
    });

    test('the allowed words survive the view (network later) and replay', () {
      g.applyMove(WordTilesGame.placeMove(brine, allow: ['BRINE']));
      final view = WordTilesView.fromJson(jsonDecode(jsonEncode(g.viewJson(Player.b))) as Map<String, dynamic>);
      expect(view.turns.single.allowed, ['BRINE']);
    });
  });

  group('tile set and word list per game (GameConfig)', () {
    tearDown(WordLists.clear);

    test('JSON keeps tiles and dict, old configs read as German without a list', () {
      const c = GameConfig('wordtiles', seed: 5, tiles: 'en', dictionary: true);
      expect(c.toJson(), {'game': 'wordtiles', 'seed': 5, 'tiles': 'en', 'dict': true});
      expect(GameConfig.fromJson(c.toJson()), c);
      expect(c.copyWith(seed: 6).tiles, 'en');
      expect(c.copyWith(seed: 6).dictionary, isTrue);
      final old = GameConfig.fromJson({'game': 'wordtiles', 'seed': 5});
      expect(old.tiles, isNull);
      expect(old.dictionary, isFalse);
      expect(const GameConfig('wordtiles').toJson().containsKey('dict'), isFalse);
    });

    test('the tile set follows the config; without a list: challenge mode', () {
      final en = createGame(const GameConfig('wordtiles', seed: 3, tiles: 'en')) as WordTilesGame;
      expect(en.tileSet, TileSet.english);
      expect(en.check, WordCheck.challenge);
      final de = createGame(const GameConfig('wordtiles', seed: 3)) as WordTilesGame;
      expect(de.tileSet, TileSet.german);
      expect(configProblem(const GameConfig('wordtiles', tiles: 'xx')), isNotNull);
    });

    test('dict needs the registered list of that tile set', () {
      const c = GameConfig('wordtiles', seed: 3, tiles: 'en', dictionary: true);
      expect(configProblem(c), isNotNull);
      expect(() => createGame(c), throwsArgumentError);
      final v = list(['QI']);
      WordLists.register('en', v);
      expect(configProblem(c), isNull);
      final g = createGame(c) as WordTilesGame;
      expect(g.check, WordCheck.dictionary);
      expect(g.validator, same(v));
      expect(replay(c, const []), isA<WordTilesGame>());
    });

    test('the word list revisions are part of the fingerprint data', () {
      expect(WordTilesGame.gameplayData().last, contains(startsWith('de=')));
      expect(specById('wordtiles')!.rulesVersion, 2);
    });
  });
}

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
      // Rules 3 (step 6): a place with `allow` alone is refused; the other
      // player has to agree.
      expect(g.applyMove(WordTilesGame.placeMove(brine, allow: ['BRINE'])), isNull);
      expect(g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE'])), isNotNull);
      final e = g.applyMove(WordTilesGame.acceptAllowMove(Player.b))!;
      expect((e.payload as Map)['allowed'], ['BRINE']);
      expect((e.payload as Map)['agreed'], 1);
      expect(g.turns.single.allowed, ['BRINE']);
      expect(g.scoreOf(0), greaterThan(0));
      expect(g.currentSeat, 1);
    });

    test('allow must name exactly the unknown words', () {
      Map<String, dynamic> ask(List<PlacedTile> tiles, Object? allow) =>
          {...WordTilesGame.requestAllowMove(Player.a, tiles, const ['X']), 'allow': allow};
      expect(g.applyMove(ask(birne, ['BIRNE'])), isNull, reason: 'a known word');
      expect(g.applyMove(ask(brine, ['BRINE', 'XYZ'])), isNull);
      expect(g.applyMove(ask(brine, 'BRINE')), isNull);
      expect(g.applyMove(ask(brine, [])), isNull);
      expect(g.applyMove(ask(brine, ['BRINE', 'BRINE'])), isNull);
      expect(g.history, isEmpty);
    });

    test('allow is refused in challenge mode', () {
      final c = WordTilesGame()
        ..debugSetup(racks: [
          ['B', 'R', 'I', 'N', 'E', 'S', 'T'],
          ['H', 'A', 'U', 'S', 'E', 'N', 'T'],
        ]);
      expect(c.applyMove(WordTilesGame.placeMove(brine, allow: ['BRINE'])), isNull);
      expect(c.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE'])), isNull);
      expect(c.unknownWords(WordTilesGame.placeMove(brine)), isEmpty);
    });

    test('the allowed words survive the view and replay', () {
      g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']));
      g.applyMove(WordTilesGame.acceptAllowMove(Player.b));
      final view = WordTilesView.fromJson(jsonDecode(jsonEncode(g.viewJson(Player.b))) as Map<String, dynamic>);
      expect(view.turns.single.allowed, ['BRINE']);
    });
  });

  group('"Trotzdem zulassen" needs the other player (KLD-094 step 6)', () {
    late WordTilesGame g;
    final brine = [t(7, 5, 'B'), t(7, 6, 'R'), t(7, 7, 'I'), t(7, 8, 'N'), t(7, 9, 'E')];
    final bie = [t(7, 5, 'B'), t(7, 6, 'I'), t(7, 7, 'E')];

    setUp(() {
      g = WordTilesGame(check: WordCheck.dictionary, validator: list(['BIRNE', 'HAUS']))
        ..debugSetup(racks: [
          ['B', 'I', 'R', 'N', 'E', 'S', 'T'],
          ['H', 'A', 'U', 'S', 'E', 'N', 'T'],
        ], bag: List.filled(20, 'E'));
    });

    test('the request names its player; the turn stays; nothing else until it is answered', () {
      final req = WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']);
      expect(g.playerOf(req), Player.a);
      expect(g.playerOf(WordTilesGame.acceptAllowMove(Player.b)), Player.b);
      expect(g.applyMove(WordTilesGame.requestAllowMove(Player.b, brine, ['BRINE'])), isNull, reason: 'not on turn');
      final e = g.applyMove(req)!;
      expect((e.payload as Map)['allow'], ['BRINE']);
      expect((e.payload as Map)['score'], greaterThan(0));
      expect(g.currentSeat, 0);
      expect(g.allowRequest!.allow, ['BRINE']);
      expect(g.allowRequest!.words, ['BRINE']);
      expect(g.allowRequestAnswerer, 1);
      expect(g.turns, isEmpty, reason: 'no turn yet');
      // The requester waits: no other move, no second request, no own answer.
      expect(g.applyMove(const {'action': 'pass'}), isNull);
      expect(g.applyMove(WordTilesGame.placeMove([t(7, 7, 'R'), t(7, 8, 'E')])), isNull);
      expect(g.applyMove(req), isNull);
      expect(g.applyMove(WordTilesGame.acceptAllowMove(Player.a)), isNull);
      expect(g.applyMove(WordTilesGame.declineAllowMove(Player.a)), isNull);
      expect(g.applyMove({...WordTilesGame.acceptAllowMove(Player.b), 'x': 1}), isNull);
      expect(g.legalMoves, [WordTilesGame.acceptAllowMove(Player.b), WordTilesGame.declineAllowMove(Player.b)]);
      expect(g.checkPlacement(WordTilesGame.placeMove(bie)).error, PlacementError.notNow);
    });

    test('decline: tiles stay on the rack, same turn; the same request is refused until the turn changes', () {
      final rack = g.rackOf(0);
      g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']));
      final e = g.applyMove(WordTilesGame.declineAllowMove(Player.b))!;
      expect(e.payload, {'action': 'declineAllow', 'seat': 1, 'placer': 0, 'allow': ['BRINE']});
      expect(g.allowRequest, isNull);
      expect(g.currentSeat, 0);
      expect(g.rackOf(0), rack);
      expect(g.scoreOf(0), 0);
      expect(g.tileAt(7, 7), isNull);
      expect(g.scorelessTurns, 0, reason: 'a declined request is no turn');
      expect(g.canRequestAllow(['BRINE']), isFalse);
      expect(g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE'])), isNull);
      // Another unknown word may be asked for.
      expect(g.canRequestAllow(['BIE']), isTrue);
      expect(g.applyMove(WordTilesGame.requestAllowMove(Player.a, bie, ['BIE'])), isNotNull);
      g.applyMove(WordTilesGame.declineAllowMove(Player.b));
      // A pass ends the turn; next turn (back to A after B) the words may be asked for again.
      g.applyMove(const {'action': 'pass'});
      g.applyMove(const {'action': 'pass'});
      expect(g.canRequestAllow(['BRINE']), isTrue);
    });

    test('accept lays the tiles like a placement, with the agreed words', () {
      g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']));
      final score = g.allowRequest!.score;
      final e = g.applyMove(WordTilesGame.acceptAllowMove(Player.b))!;
      final p = e.payload as Map;
      expect(p['action'], 'place');
      expect(p['seat'], 0);
      expect(p['score'], score);
      expect(p['drew'], 5);
      expect(g.scoreOf(0), score);
      expect(g.tileAt(7, 7)!.letter, 'I');
      expect(g.currentSeat, 1);
      expect(g.turns.single.allowed, ['BRINE']);
      expect(g.allowRequest, isNull);
    });

    test('the open request is in both views and survives a JSON round trip', () {
      g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']));
      for (final viewer in Player.values) {
        final view = WordTilesView.fromJson(jsonDecode(jsonEncode(g.viewJson(viewer))) as Map<String, dynamic>);
        expect(view.allowRequest!.allow, ['BRINE']);
        expect(view.allowRequest!.tiles.map((x) => x.letter).join(), 'BRINE');
        expect(view.allowRequestAnswerer, 1);
        expect(view.viewJson(viewer), g.viewJson(viewer));
        expect(view.legalMoves, viewer == Player.b ? hasLength(2) : isEmpty);
      }
      g.applyMove(WordTilesGame.declineAllowMove(Player.b));
      final view = WordTilesView.fromJson(jsonDecode(jsonEncode(g.viewJson(Player.a))) as Map<String, dynamic>);
      expect(view.canRequestAllow(['BRINE']), isFalse, reason: 'the declined words are in the view');
      expect(view.viewJson(Player.a), g.viewJson(Player.a));
    });

    test('a resign while a request is open ends the game', () {
      g.applyMove(WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']));
      expect(g.applyMove(Game.resignMove(Player.b)), isNotNull);
      expect(g.isOver, isTrue);
      expect(g.allowRequest, isNull);
    });

    test('replay of the log reproduces the game', () {
      final moves = [
        WordTilesGame.requestAllowMove(Player.a, brine, ['BRINE']),
        WordTilesGame.declineAllowMove(Player.b),
        WordTilesGame.requestAllowMove(Player.a, bie, ['BIE']),
        WordTilesGame.acceptAllowMove(Player.b),
      ];
      for (final m in moves) {
        expect(g.applyMove(m), isNotNull, reason: '$m');
      }
      expect(g.history, hasLength(4));
      expect(g.turns.single.words, ['BIE']);
    });

    test('a view looks up the registered list when it was given none', () {
      addTearDown(WordLists.clear);
      final view = WordTilesView.fromJson(jsonDecode(jsonEncode(g.viewJson(Player.a))) as Map<String, dynamic>);
      expect(view.unknownWords(WordTilesGame.placeMove(brine)), isEmpty, reason: 'no list registered yet');
      WordLists.register('de', list(['BIRNE']));
      expect(view.unknownWords(WordTilesGame.placeMove(brine)), ['BRINE']);
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
      expect(specById('wordtiles')!.rulesVersion, 5); // 4 with "Joker tauschen", 5 with "Restpunkte abziehen" optional
      expect(WordTilesGame.gameplayData().last, contains(contains('sha256:')));
    });
  });
}

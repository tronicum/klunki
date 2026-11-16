import 'dart:convert';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-132: tile sets beyond de/en: per-set normalisation, alphabet order,
/// words across read right to left, blanks of letters without case.
void main() {
  PlacedTile t(int row, int col, String tile, [String? letter]) => PlacedTile(row, col, tile, letter);

  /// A small right-to-left set (Arabic letters), enough tiles for the tests.
  const rtlSet = TileSet('rtl-test', {'ك': 4, 'ت': 4, 'ا': 4, 'ب': 4, 'ل': 4},
      {'ك': 3, 'ت': 1, 'ا': 1, 'ب': 2, 'ل': 1},
      alphabet: ['ا', 'ب', 'ت', 'ك', 'ل'], fold: {'أ': 'ا', 'َ': ''}, rtl: true);

  group('normalisation and order', () {
    test('de/en keep their old normalisation and code point order', () {
      expect(TileSet.german.normalize('Straße'), 'STRASSE');
      expect(TileSet.german.normalize('STRAẞE'), 'STRASSE');
      expect(TileSet.english.normalize('quiz'), 'QUIZ');
      expect(TileSet.german.letters.last, 'Ü');
      expect(TileSet.german.letters.first, 'A');
      expect(TileSet.german.cased, isTrue);
      expect(TileSet.german.rtl, isFalse);
    });

    test('a fold table drops and replaces characters; alphabet order wins over code points', () {
      expect(rtlSet.normalize('كَتَب'), 'كتب');
      expect(rtlSet.normalize('أب'), 'اب');
      expect(rtlSet.canSpell('كَتَب'), isTrue);
      expect(rtlSet.letters, ['ا', 'ب', 'ت', 'ك', 'ل']);
      expect(rtlSet.bag().first, 'ا');
      expect(rtlSet.cased, isFalse);
    });

    test('every set: 100 tiles, an alphabet that names each letter once, a fold onto its letters', () {
      for (final t in TileSet.all) {
        expect(t.size, 100, reason: t.id);
        expect(t.letters.toSet(), t.counts.keys.toSet(), reason: t.id);
        expect(t.letters, hasLength(t.counts.length), reason: t.id);
        expect(t.points.keys.toSet(), t.counts.keys.toSet(), reason: t.id);
        for (final l in t.letters) {
          expect(t.normalize(l), l, reason: '${t.id} $l');
        }
      }
      expect(TileSet.all.map((t) => t.id), ['de', 'en', 'fr', 'es', 'ar', 'fa'].take(TileSet.all.length));
    });

    test('French: accents and ligatures fold onto A–Z', () {
      expect(TileSet.french.normalize('Noël'), 'NOEL');
      expect(TileSet.french.normalize('cœur'), 'COEUR');
      expect(TileSet.french.normalize('garçon'), 'GARCON');
      expect(TileSet.french.normalize('ÉTÉ'), 'ETE');
      expect(TileSet.french.normalize('naïf'), 'NAIF');
      expect(TileSet.french.canSpell('aujourd’hui'), isFalse);
      expect(TileSet.french.canSpell('porte-monnaie'), isFalse);
    });

    test('Spanish: Ñ stays a letter (after N), accents and Ü fold', () {
      expect(TileSet.spanish.normalize('niño'), 'NIÑO');
      expect(TileSet.spanish.normalize('corazón'), 'CORAZON');
      expect(TileSet.spanish.normalize('pingüino'), 'PINGUINO');
      expect(TileSet.spanish.letters.indexOf('Ñ'), TileSet.spanish.letters.indexOf('N') + 1);
      expect(TileSet.spanish.canSpell('chorro'), isTrue, reason: 'CH and RR are two tiles each');
    });

    test('fold, alphabet and direction are part of the fingerprint data', () {
      final d = rtlSet.gameplayData();
      expect(d[3], ['أ>ا', 'َ>']);
      expect(d.last, isTrue);
    });
  });

  group('right to left', () {
    // كتب across row 7: ك at col 8, ت at col 7, ب at col 6 (read from the right).
    final ktb = [t(7, 8, 'ك'), t(7, 7, 'ت'), t(7, 6, 'ب')];

    WordTilesGame game({WordValidator? validator}) => WordTilesGame(
        tileSet: rtlSet,
        check: validator == null ? WordCheck.challenge : WordCheck.dictionary,
        validator: validator)
      ..debugSetup(racks: [
        ['ك', 'ت', 'ب', 'ا', 'ل', 'ا', 'ل'],
        ['ك', 'ت', 'ب', 'ا', 'ل', 'ا', 'ب'],
      ], bag: List.filled(10, 'ا'));

    test('a word across is read from its square furthest right', () {
      final g = game();
      final c = g.checkPlacement(WordTilesGame.placeMove(ktb));
      expect(c.ok, isTrue, reason: '${c.error}');
      expect(c.words.single.word, 'كتب');
      expect(c.words.single.col, 8, reason: 'starts on the right');
      expect(c.words.single.across, isTrue);
    });

    test('down stays top to bottom', () {
      final g = game();
      final c = g.checkPlacement(WordTilesGame.placeMove([t(6, 7, 'ك'), t(7, 7, 'ت'), t(8, 7, 'ب')]));
      expect(c.words.single.word, 'كتب');
      expect(c.words.single.row, 6);
    });

    test('the dictionary check sees the right-to-left word', () {
      final g = game(validator: WordListValidator(['كتب'], rtlSet));
      expect(g.applyMove(WordTilesGame.placeMove(ktb)), isNotNull);
      // The mirrored order is no word.
      final h = game(validator: WordListValidator(['كتب'], rtlSet));
      expect(h.applyMove(WordTilesGame.placeMove([t(7, 6, 'ك'), t(7, 7, 'ت'), t(7, 8, 'ب')])), isNull);
    });

    test('a blank survives the view (letters without case list their squares)', skip: 'KLD-132 stage 3: needs a registered set', () {
      final g = WordTilesGame(tileSet: rtlSet)
        ..debugSetup(racks: [
          ['ك', '?', 'ب', 'ا', 'ل', 'ا', 'ل'],
          ['ك', 'ت', 'ب', 'ا', 'ل', 'ا', 'ب'],
        ], bag: List.filled(10, 'ا'));
      expect(g.applyMove(WordTilesGame.placeMove([t(7, 8, 'ك'), t(7, 7, '?', 'ت'), t(7, 6, 'ب')])), isNotNull);
      final json = g.viewJson(Player.b);
      expect(json['blanks'], [
        [7, 7]
      ]);
      final v = WordTilesView.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(v.tileAt(7, 7), const BoardTile('ت', blank: true));
      expect(v.tileAt(7, 8), const BoardTile('ك'));
      expect(v.viewJson(Player.b)['blanks'], json['blanks']);
    });

    test('a Latin set has no `blanks` in its view', () {
      final g = WordTilesGame()
        ..debugSetup(racks: [
          ['H', '?', 'U', 'S', 'E', 'N', 'R'],
          ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
        ]);
      expect(g.applyMove(WordTilesGame.placeMove([t(7, 6, 'H'), t(7, 7, '?', 'A'), t(7, 8, 'U'), t(7, 9, 'S')])),
          isNotNull);
      expect(g.viewJson(Player.b).containsKey('blanks'), isFalse);
      expect(g.viewJson(Player.b)['board'][7], '......HaUS.....');
    });
  });
}

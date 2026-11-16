import 'dart:convert';
import 'dart:io' show gzip;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/ui/games/wordtiles/word_list_loader.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// KLD-132: the word lists of every tile language. Each bundled word must be
/// what the engine makes of it ([TileSet.normalize] — so the build tool's
/// fold tables equal the engine's) and spellable with the set's tiles;
/// common words (also inflected forms) are in, names and abbreviations out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<List<String>> words(String id) async {
    final data = await rootBundle.load(WordListLoader.assetOf(id));
    final text = utf8.decode(gzip.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes)));
    return text.split('\n')..removeLast();
  }

  test('every tile set has a list, and every list a tile set', () {
    expect(WordListLoader.available, {for (final t in TileSet.all) t.id});
    expect(WordLists.revisions.keys.toSet(), WordListLoader.available);
  });

  for (final id in ['fr', 'es', 'ar', 'fa']) {
    test('$id: every word is normalized, 2–15 letters, spellable', () async {
      final set = TileSet.byId(id)!;
      final list = await words(id);
      expect(list.length, greaterThan(50000), reason: id);
      for (final w in list) {
        if (set.normalize(w) != w || w.length < 2 || w.length > 15 || !set.canSpell(w)) {
          fail('$id: bad word "$w"');
        }
      }
    });
  }

  // Samples (also in `build_word_lists.py check`).
  const present = {
    'fr': ['maison', 'maisons', 'été', 'allions', 'iront', 'Noël', 'cœur', 'œufs', 'chevaux', 'fraîche', 'déjà',
        'garçon', 'où', 'zoo'],
    'es': ['casa', 'casas', 'niño', 'niños', 'año', 'cantábamos', 'fuimos', 'dámelo', 'cuéntamelo', 'comértelo',
        'dígaselo', 'árbol', 'árboles', 'corazón', 'pingüino', 'español', 'zorro'],
    'ar': ['كتاب', 'الكتاب', 'كِتَابَانِ', 'كتب', 'مدرسة', 'المدرسة', 'مدارس', 'قمر', 'شمس', 'سماء', 'يكتب', 'كتبوا',
        'سيّارة', 'معلمون', 'معلمات', 'شجرة', 'أمّ', 'إسلام'],
    'fa': ['کتاب', 'کتاب‌ها', 'خانه', 'آب', 'آسمان', 'مادر', 'پدر', 'بچه', 'چشم', 'می‌روم', 'رفتم', 'گل', 'ژاله',
        'كتاب'],
  };
  const absent = {
    'fr': ['Bruxelles', 'Québec', 'Marx', 'France', 'SNCF', 'km', 'kg', 'etc', 'qu', 'vs'],
    'es': ['Madrid', 'España', 'Carlos', 'km', 'ONU', 'OTAN'],
    // Clitics (و ب ل ك ف, the future س, attached pronouns), names of the names section.
    'ar': ['وكتاب', 'بالكتاب', 'فكتب', 'لكتاب', 'ككتاب', 'سيكتب', 'كتابه', 'كتبه', 'مدرسته', 'بلقيس', 'الأمازون'],
    // Offensive and foreign words, possessive and copula clitics.
    'fa': ['بتمرگ', 'آلیس', 'کتابم', 'کتاب‌هایشان', 'خوبم'],
  };
  for (final id in present.keys) {
    test('$id: common and inflected words are in, names and abbreviations out', () async {
      final list = await WordListLoader.ensure(id);
      final set = TileSet.byId(id)!;
      for (final w in present[id]!) {
        expect(list.isWord(set.normalize(w)), isTrue, reason: w);
      }
      for (final w in absent[id]!) {
        expect(list.isWord(set.normalize(w)), isFalse, reason: w);
      }
    });
  }
}

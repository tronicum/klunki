// I18N-06/07/08: can the PWA draw every character of every language offline?
//
// Flutter web (CanvasKit) has no system fonts. Whatever the bundled fonts
// (assets/fonts/**) do not cover is downloaded at runtime from
// fonts.gstatic.com (Noto slices per script) and shows tofu (□) offline.
// Klunki bundles Roboto (Latin), Noto Sans Arabic, a Noto Sans SC subset and a
// Noto Sans Math subset (symbols), see lib/app/fonts.dart.
//
// This test parses the cmap of every bundled TTF/OTF and checks the
// characters used in the ARB values (+ the picker endonyms), strictly:
//  * every visible character of every locale is in a bundled font;
//  * Latin characters (all of de/en/fr/es, the Latin in zh/ar/fa) are in
//    Roboto itself, so Latin text never mixes in a fallback font;
//  * every CJK character is in the Noto Sans SC subset. The subsets are
//    built from the ARB files: a new string needs
//    `python3 -I tool/update_web_fonts.py subset` (from klunki/).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/locale_controller.dart';

/// Unicode code points covered by a TrueType/OpenType font (cmap formats 4
/// and 12, Unicode subtables).
Set<int> cmapCodePoints(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  final numTables = d.getUint16(4);
  int? cmap;
  for (var i = 0; i < numTables; i++) {
    final rec = 12 + 16 * i;
    final tag = String.fromCharCodes(bytes.sublist(rec, rec + 4));
    if (tag == 'cmap') cmap = d.getUint32(rec + 8);
  }
  if (cmap == null) throw const FormatException('no cmap table');
  final out = <int>{};
  final n = d.getUint16(cmap + 2);
  for (var i = 0; i < n; i++) {
    final platform = d.getUint16(cmap + 4 + 8 * i);
    final encoding = d.getUint16(cmap + 6 + 8 * i);
    final unicode = platform == 0 || (platform == 3 && (encoding == 1 || encoding == 10));
    if (!unicode) continue;
    final sub = cmap + d.getUint32(cmap + 8 + 8 * i);
    final format = d.getUint16(sub);
    if (format == 4) {
      final segX2 = d.getUint16(sub + 6);
      final ends = sub + 14;
      final starts = ends + segX2 + 2;
      final deltas = starts + segX2;
      final offsets = deltas + segX2;
      for (var s = 0; s < segX2 ~/ 2; s++) {
        final end = d.getUint16(ends + 2 * s);
        final start = d.getUint16(starts + 2 * s);
        final delta = d.getInt16(deltas + 2 * s);
        final roAt = offsets + 2 * s;
        final ro = d.getUint16(roAt);
        for (var c = start; c <= end && c != 0xFFFF; c++) {
          final glyph = ro == 0
              ? (c + delta) & 0xFFFF
              : (() {
                  final g = d.getUint16(roAt + ro + 2 * (c - start));
                  return g == 0 ? 0 : (g + delta) & 0xFFFF;
                })();
          if (glyph != 0) out.add(c);
        }
      }
    } else if (format == 12) {
      final groups = d.getUint32(sub + 12);
      for (var g = 0; g < groups; g++) {
        final start = d.getUint32(sub + 16 + 12 * g);
        final end = d.getUint32(sub + 20 + 12 * g);
        for (var c = start; c <= end; c++) {
          out.add(c);
        }
      }
    }
  }
  return out;
}

/// Coarse script of a code point (what decides which fallback font is used).
String scriptOf(int c) {
  if (c >= 0x0600 && c <= 0x06FF || c >= 0x0750 && c <= 0x077F || c >= 0xFB50 && c <= 0xFDFF || c >= 0xFE70 && c <= 0xFEFF) {
    return 'Arabic';
  }
  if (c >= 0x4E00 && c <= 0x9FFF || c >= 0x3400 && c <= 0x4DBF) return 'Han';
  if (c >= 0x3000 && c <= 0x303F || c >= 0xFF00 && c <= 0xFFEF) return 'CJK punctuation';
  if (c < 0x0250 || c >= 0x1E00 && c <= 0x1EFF) return 'Latin';
  if (c >= 0x2000 && c <= 0x206F) return 'General punctuation';
  return 'Other';
}

/// What to do when [script] has characters missing from the bundled fonts.
const fixHint = {
  'Han': 'rerun `python3 -I tool/update_web_fonts.py subset` (from klunki/) to rebuild the Noto Sans SC subset',
  'CJK punctuation': 'rerun `python3 -I tool/update_web_fonts.py subset` (from klunki/) to rebuild the Noto Sans SC subset',
  'Arabic': 'Noto Sans Arabic lacks it: check the character or update the font (tool/update_web_fonts.py fetch)',
};
const subsetHint = 'rerun `python3 -I tool/update_web_fonts.py subset` (from klunki/): it rebuilds the Noto Sans SC '
    'and Noto Sans Math subsets from the ARB files';

/// Characters the user can see in [languageCode]: ARB values without
/// placeholders and ICU syntax.
Set<int> arbCharacters(String languageCode) {
  final arb = jsonDecode(File('lib/l10n/app_$languageCode.arb').readAsStringSync()) as Map<String, dynamic>;
  final out = <int>{};
  for (final e in arb.entries) {
    if (e.key.startsWith('@') || e.value is! String) continue;
    var v = e.value as String;
    // `{n, plural, =1{` / `other{` / `{name}` / closing braces.
    v = v.replaceAll(RegExp(r'\{\w+,\s*(plural|select)\s*,'), ' ');
    v = v.replaceAll(RegExp(r'(=\d+|zero|one|two|few|many|other)\{'), ' ');
    v = v.replaceAll(RegExp(r'\{\w+\}'), ' ');
    v = v.replaceAll(RegExp(r'[{}]'), ' ');
    out.addAll(v.runes);
  }
  return out;
}

/// Characters that need a glyph. Controls, zero-width and bidi marks do not;
/// U+00A0 / U+202F (no-break spaces) do: the engine requests a fallback font
/// for any code point its fonts lack.
bool needsGlyph(int c) => c > 0x20 && !(c >= 0x200B && c <= 0x200F) && !(c >= 0x2066 && c <= 0x2069);

bool isLatin(int c) => scriptOf(c) == 'Latin';
bool isCjk(int c) => scriptOf(c) == 'Han' || scriptOf(c) == 'CJK punctuation';

const locales = ['de', 'en', 'fr', 'es', 'zh', 'ar', 'fa'];

void main() {
  Set<int> coverageOf(String dir) {
    final d = Directory('assets/fonts/$dir');
    if (!d.existsSync()) return <int>{};
    return {
      for (final f in d.listSync().whereType<File>().where((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf')))
        ...cmapCodePoints(f.readAsBytesSync()),
    };
  }

  final roboto = coverageOf('Roboto');
  final arabic = coverageOf('NotoSansArabic');
  final chinese = coverageOf('NotoSansSC');
  final symbols = coverageOf('NotoSansMath');
  final covered = {...roboto, ...arabic, ...chinese, ...symbols};
  final endonyms = {for (final l in appLanguages) ...l.endonym.runes};

  /// Missing code points of [chars] (not in [fonts]), grouped by script.
  Map<String, List<int>> missingByScript(Iterable<int> chars, [Set<int>? fonts]) {
    final out = <String, List<int>>{};
    for (final c in chars.where(needsGlyph).where((c) => !(fonts ?? covered).contains(c))) {
      (out[scriptOf(c)] ??= []).add(c);
    }
    return out;
  }

  String show(List<int> cs) =>
      cs.take(40).map((c) => '${String.fromCharCode(c)} U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(', ') +
      (cs.length > 40 ? ' … (${cs.length} total)' : '');

  String explain(Map<String, List<int>> missing) => missing.entries
      .map((e) => '${e.value.length} ${e.key}: ${show(e.value)} -> ${fixHint[e.key] ?? subsetHint}')
      .join('\n');

  test('cmap parser reads the bundled fonts', () {
    expect(roboto, containsAll([0x41, 0x7A, 0xE4, 0xDF, 0xE9, 0xF1, 0x2026, 0x2013, 0x203A])); // A z ä ß é ñ … – ›
    expect(arabic, containsAll([0x0627, 0x06CC])); // ا ARABIC LETTER ALEF, ی FARSI YEH
    expect(chinese, containsAll([0x7B80, 0x4F53, 0x4E2D, 0x6587])); // 简体中文
    expect(symbols, contains(0x2192)); // →
    expect(roboto, isNot(contains(0x4E2D)));
  });

  for (final code in locales) {
    test('$code: every character is in a bundled font', () {
      final missing = missingByScript(arbCharacters(code));
      expect(missing, isEmpty, reason: explain(missing));
    });
  }

  test('picker endonyms: every character is in a bundled font', () {
    final missing = missingByScript(endonyms);
    expect(missing, isEmpty, reason: explain(missing));
  });

  for (final code in locales) {
    test('$code: Latin characters are in Roboto', () {
      final latin = arbCharacters(code).where(isLatin);
      final missing = missingByScript(latin, roboto)['Latin'] ?? const [];
      expect(missing, isEmpty,
          reason: '${show(missing)}: not in assets/fonts/Roboto (web/static Roboto from roboto-3-classic). '
              'Use the full static Roboto (tool/update_web_fonts.py fetch-roboto) or avoid the character.');
    });
  }

  test('Noto Sans SC subset has every CJK character of every ARB file and the endonyms', () {
    final cjk = {for (final code in locales) ...arbCharacters(code).where(isCjk), ...endonyms.where(isCjk)};
    final missing = cjk.where((c) => !chinese.contains(c)).toList()..sort();
    expect(missing, isEmpty,
        reason: '${missing.length} CJK character(s) not in assets/fonts/NotoSansSC: ${show(missing)}.\n'
            'A string introduced new characters: $subsetHint.');
  });

  test('report: bundled fonts', () {
    // ignore: avoid_print
    print('Bundled: Roboto ${roboto.length}, Noto Sans Arabic ${arabic.length}, '
        'Noto Sans SC subset ${chinese.length}, Noto Sans Math subset ${symbols.length} code points');
  });
}

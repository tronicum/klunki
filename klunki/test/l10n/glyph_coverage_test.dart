// I18N-06: can the PWA draw every character of every language offline?
//
// Flutter web (CanvasKit) has no system fonts. Whatever the bundled fonts
// (assets/fonts/**) do not cover is downloaded at runtime from
// fonts.gstatic.com: Roboto for Latin, Noto Sans SC slices for Chinese, ...
// That works online and after the service worker has cached those exact
// files, but shows tofu (□) offline otherwise.
//
// This test parses the cmap of every bundled TTF/OTF and checks the
// characters used in the ARB values (+ the picker endonyms):
//  * scripts with a bundled font (Arabic, I18N-04b) must be fully covered;
//  * scripts without one are reported (printed) and their test is skipped
//    with the task that would bundle them (Han: I18N-07).
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

/// Task that would bundle a font for [script] (shown in skip messages).
const bundlingTask = {
  'Arabic': 'I18N-04b',
  'Han': 'I18N-07',
  'CJK punctuation': 'I18N-07',
  'Latin': 'not planned (Roboto, loaded online by the engine, then cached by klunki_sw.js)',
  'General punctuation': 'not planned (Roboto / Noto Symbols, online)',
};

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

/// Invisible / control characters that need no glyph.
bool needsGlyph(int c) =>
    c > 0x20 && !(c >= 0x200B && c <= 0x200F) && !(c >= 0x2066 && c <= 0x2069) && c != 0x00A0 && c != 0x202F;

void main() {
  final fontFiles = Directory('assets/fonts').existsSync()
      ? Directory('assets/fonts')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf'))
          .toList()
      : <File>[];
  final covered = <int>{};
  for (final f in fontFiles) {
    covered.addAll(cmapCodePoints(f.readAsBytesSync()));
  }
  final endonyms = {for (final l in appLanguages) ...l.endonym.runes};

  /// Missing code points of [chars], grouped by script.
  Map<String, List<int>> missingByScript(Set<int> chars) {
    final out = <String, List<int>>{};
    for (final c in chars.where(needsGlyph).where((c) => !covered.contains(c))) {
      (out[scriptOf(c)] ??= []).add(c);
    }
    return out;
  }

  String show(List<int> cs) =>
      cs.take(40).map((c) => '${String.fromCharCode(c)} U+${c.toRadixString(16).toUpperCase().padLeft(4, '0')}').join(', ') +
      (cs.length > 40 ? ' … (${cs.length} total)' : '');

  test('cmap parser reads the bundled Arabic font', () {
    if (fontFiles.isEmpty) {
      markTestSkipped('no fonts bundled under assets/fonts');
      return;
    }
    expect(covered, contains(0x0627)); // ا ARABIC LETTER ALEF
    expect(covered, contains(0x06CC)); // ی FARSI YEH
    expect(covered, isNot(contains(0x4E2D))); // 中: no CJK font bundled
  });

  test('report: which characters depend on the online font fallback', () {
    final lines = <String>['Bundled fonts: ${fontFiles.map((f) => f.path).join(', ')}'];
    for (final code in ['de', 'en', 'fr', 'es', 'zh', 'ar', 'fa']) {
      final missing = missingByScript(arbCharacters(code));
      for (final e in missing.entries) {
        lines.add('$code: ${e.value.length} ${e.key} char(s) not bundled -> online fallback '
            '(${bundlingTask[e.key] ?? 'no task'}): ${show(e.value)}');
      }
    }
    final endo = missingByScript(endonyms);
    for (final e in endo.entries) {
      lines.add('picker endonyms (every locale): ${e.value.length} ${e.key} char(s) not bundled: ${show(e.value)}');
    }
    // ignore: avoid_print
    print(lines.join('\n'));
  });

  for (final code in ['ar', 'fa']) {
    test('$code: every Arabic-script character is in a bundled font (I18N-04b)', () {
      if (fontFiles.isEmpty) {
        markTestSkipped('no fonts bundled yet (I18N-04b)');
        return;
      }
      final missing = missingByScript(arbCharacters(code))['Arabic'] ?? const [];
      expect(missing, isEmpty, reason: show(missing));
    });
  }

  test('picker endonyms: Arabic script bundled', () {
    final missing = missingByScript(endonyms)['Arabic'] ?? const [];
    expect(missing, isEmpty, reason: show(missing));
  });

  final zhMissing = missingByScript({...arbCharacters('zh'), ...endonyms});
  final han = [...?zhMissing['Han'], ...?zhMissing['CJK punctuation']];
  test('zh: every Chinese character is in a bundled font',
      () => expect(han, isEmpty, reason: show(han)),
      skip: han.isEmpty
          ? false
          : 'TODO(I18N-07): ${han.length} Han/CJK characters come from fonts.gstatic.com '
              '(Noto Sans SC slices), tofu offline unless cached. Not yet approved.');
}

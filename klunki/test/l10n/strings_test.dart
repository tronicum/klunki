// Guards for the extracted strings (I18N-02): every ARB file carries every
// template key, and lib/ui has no hard-coded user-visible literals left.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync()) as Map<String, dynamic>;

Set<String> _keys(Map<String, dynamic> arb) => {for (final k in arb.keys) if (!k.startsWith('@')) k};

/// Placeholder names used in an ICU message (`{player}`, `{count, plural, ...}`).
Set<String> _placeholders(String message) =>
    {for (final m in RegExp(r'\{(\w+)[,}]').allMatches(message)) m.group(1)!};

void main() {
  final template = _arb('de');
  final keys = _keys(template);

  test('template keys have descriptions and declare their placeholders', () {
    for (final k in keys) {
      final meta = template['@$k'] as Map<String, dynamic>?;
      expect(meta?['description'], isA<String>(), reason: '@$k description');
      final used = _placeholders(template[k] as String);
      final declared = ((meta?['placeholders'] as Map?) ?? const {}).keys.toSet();
      expect(declared, used, reason: '$k placeholders');
    }
  });

  for (final locale in ['en', 'fr', 'es', 'zh', 'ar', 'fa']) {
    test('app_$locale.arb has every template key with the same placeholders', () {
      final arb = _arb(locale);
      expect(_keys(arb), keys);
      for (final k in keys) {
        expect(_placeholders(arb[k] as String), _placeholders(template[k] as String), reason: '$locale $k');
      }
    });
  }

  test('lib/ui has no hard-coded user-visible string literals', () {
    // Literal right after a text-bearing parameter or a Text( constructor.
    final pattern = RegExp(
      r"(?:\bText\(|\b(?:tooltip|label|message|semanticLabel|title|content|hintText|labelText):\s*(?:const\s+)?(?:Text\()?)\s*'((?:[^'\\]|\\.)*)'",
    );
    final offenders = <String>[];
    final files = Directory('lib/ui')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.contains('/pairing/'));
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in pattern.allMatches(lines[i])) {
          // Ignore interpolations; what is left must not contain words.
          final rest = m.group(1)!.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
          if (RegExp(r'[A-Za-zÄÖÜäöüß]{2,}').hasMatch(rest)) offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty);
  });
}

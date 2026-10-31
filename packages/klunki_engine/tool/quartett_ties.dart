// Prints, per Quartett deck, the validation result and the tie rate of each
// stat (share of card pairs with equal values) with the tied cards (KLD-069).
//
//   dart run packages/klunki_engine/tool/quartett_ties.dart
import 'package:klunki_engine/klunki_engine.dart';

void main() {
  for (final d in QuartettDeck.all) {
    final problems = d.validate();
    print('${d.id} (${d.name}): ${problems.isEmpty ? 'valid' : problems.join('; ')}');
    for (final s in d.stats) {
      final byValue = <num, List<String>>{};
      for (final c in d.cards) {
        (byValue[c.stats[s.id]!] ??= []).add(c.id);
      }
      final tied = [
        for (final e in byValue.entries)
          if (e.value.length > 1) '${e.key}: ${e.value.join('/')}'
      ];
      print('  ${s.id.padRight(12)} ${(d.tieRate(s.id) * 100).toStringAsFixed(1).padLeft(4)} %'
          '${tied.isEmpty ? '' : '   ${tied.join(', ')}'}');
    }
  }
}

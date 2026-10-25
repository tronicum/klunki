import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart';
import 'schiffe_grid.dart';

/// History text for a Schiffe move. Placements never reveal coordinates
/// (the history sheet is visible to both players).
String describeSchiffeMove(AcceptedMove m) {
  final who = playerMark(m.player);
  final payload = m.event.payload is Map ? m.event.payload as Map : const {};
  switch (m.move['action']) {
    case 'place':
      return '$who platziert ein Schiff';
    case 'autoplace':
      final n = (payload['autoplaced'] as List?)?.length ?? 0;
      return n == 1 ? '$who platziert ein Schiff zufällig' : '$who platziert $n Schiffe zufällig';
    case 'fire':
      final at = svCellName(m.move['row'] as int, m.move['col'] as int);
      final len = payload['ship'];
      final result = switch (payload['result']) {
        'miss' => 'Wasser',
        'hit' => 'Treffer',
        _ => '${len is int ? SchiffeGame.shipName(len) : 'Schiff'} versenkt',
      };
      return '$who schießt auf $at: $result';
  }
  return m.move.toString();
}

import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../transport/game_transport.dart';
import 'schiffe_grid.dart';

/// History text for a Schiffe move, without the player (the shell prefixes
/// it). Placements never reveal coordinates
/// (the history sheet is visible to both players).
String describeSchiffeMove(AcceptedMove m) {
  final payload = m.event.payload is Map ? m.event.payload as Map : const {};
  switch (m.move['action']) {
    case 'place':
      return 'platziert ein Schiff';
    case 'autoplace':
      final n = (payload['autoplaced'] as List?)?.length ?? 0;
      return n == 1 ? 'platziert ein Schiff zufällig' : 'platziert $n Schiffe zufällig';
    case 'fire':
      final at = svCellName(m.move['row'] as int, m.move['col'] as int);
      final len = payload['ship'];
      final result = switch (payload['result']) {
        'miss' => 'Wasser',
        'hit' => 'Treffer',
        _ => '${len is int ? SchiffeGame.shipName(len) : 'Schiff'} versenkt',
      };
      return 'schießt auf $at: $result';
  }
  return m.move.toString();
}

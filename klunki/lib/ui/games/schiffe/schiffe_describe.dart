import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../transport/game_transport.dart';
import 'schiffe_grid.dart';

/// History text for a Schiffe move in the language of [l10n], without the player (the shell prefixes
/// it). Placements never reveal coordinates
/// (the history sheet is visible to both players).
String describeSchiffeMove(AppLocalizations l10n, AcceptedMove m) {
  final payload = m.event.payload is Map ? m.event.payload as Map : const {};
  switch (m.move['action']) {
    case 'place':
      return l10n.schiffeMovePlace;
    case 'autoplace':
      final n = (payload['autoplaced'] as List?)?.length ?? 0;
      return l10n.schiffeMoveAutoplace(n);
    case 'fire':
      final at = svCellName(m.move['row'] as int, m.move['col'] as int);
      final len = payload['ship'];
      final result = switch (payload['result']) {
        'miss' => l10n.schiffeLookWater,
        'hit' => l10n.schiffeLookHit,
        _ => l10n.schiffeShipSunk(len is int ? SchiffeGame.shipName(len) : l10n.schiffeLookShip),
      };
      return l10n.schiffeMoveFire(at, result);
  }
  return m.move.toString();
}

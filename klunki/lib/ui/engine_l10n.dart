import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// Localized texts for strings that come from the engine (I18N-05).
///
/// The engine keeps its own English / German texts for the CLI, the debug
/// console and the network log; the app maps the engine's stable ids to
/// [AppLocalizations] here. Car names on Quartett cards are content and are
/// not translated.

/// Localized text for a [GameEndReason] with its [params] (see the enum docs).
String localizedEndReason(AppLocalizations l10n, GameEndReason code, [Map<String, int> params = const {}]) {
  int p(String name) => params[name] ?? 0;
  return switch (code) {
    GameEndReason.connect4FourInARow => l10n.engineReasonConnect4FourInARow,
    GameEndReason.connect4BoardFull => l10n.engineReasonConnect4BoardFull,
    GameEndReason.muehleFewerThanThree => l10n.engineReasonMuehleFewerThanThree,
    GameEndReason.muehleBlocked => l10n.engineReasonMuehleBlocked,
    GameEndReason.muehleNoRemovalLimit => l10n.engineReasonMuehleNoRemovalLimit(p('moves')),
    GameEndReason.quartettBothStacksEmpty => l10n.engineReasonQuartettBothStacksEmpty,
    GameEndReason.quartettAllCards => l10n.engineReasonQuartettAllCards,
    GameEndReason.quartettTrickLimitEqual => l10n.engineReasonQuartettTrickLimitEqual(p('a'), p('b')),
    GameEndReason.quartettTrickLimitMoreCards => l10n.engineReasonQuartettTrickLimitMoreCards(p('a'), p('b')),
    GameEndReason.quartettAllQuartetsEqual => l10n.engineReasonQuartettAllQuartetsEqual(p('a'), p('b')),
    GameEndReason.quartettMostQuartets => l10n.engineReasonQuartettMostQuartets(p('a'), p('b')),
    GameEndReason.schiffeAllSunk => l10n.engineReasonSchiffeAllSunk,
    GameEndReason.gostrategyFlagCaptured => l10n.engineReasonGostrategyFlagCaptured,
    GameEndReason.gostrategyNoMoves => l10n.engineReasonGostrategyNoMoves,
    GameEndReason.gostrategyBothBlocked => l10n.engineReasonGostrategyBothBlocked,
    GameEndReason.gostrategyMoveLimit => l10n.engineReasonGostrategyMoveLimit(p('moves')),
  };
}

/// Localized reason of [result]: empty while the game runs, the engine's
/// English text for a result without a code.
String localizedResultReason(AppLocalizations l10n, GameResult result) {
  final code = result.code;
  return code == null ? result.reason : localizedEndReason(l10n, code, result.params);
}

/// Localized name of a Quartett set letter `A`–`H`; the engine's name (or the
/// letter) for anything else.
String localizedSetName(AppLocalizations l10n, String set) => switch (set) {
      'A' => l10n.engineSetA,
      'B' => l10n.engineSetB,
      'C' => l10n.engineSetC,
      'D' => l10n.engineSetD,
      'E' => l10n.engineSetE,
      'F' => l10n.engineSetF,
      'G' => l10n.engineSetG,
      'H' => l10n.engineSetH,
      _ => QuartettGame.setNames[set] ?? set,
    };

/// Localized label of a Quartett stat id; the engine label (or the id) for
/// unknown ids.
String localizedStatLabel(AppLocalizations l10n, String statId) => switch (statId) {
      'ps' => l10n.engineStatPs,
      'kmh' => l10n.engineStatKmh,
      'ccm' => l10n.engineStatCcm,
      'kg' => l10n.engineStatKg,
      'sec0to100' => l10n.engineStatSec0to100,
      _ => QuartettGame.statById(statId)?.label ?? statId,
    };

/// Localized unit of a Quartett stat id (de "PS", en "hp"); the engine unit
/// for unknown ids.
String localizedStatUnit(AppLocalizations l10n, String statId) => switch (statId) {
      'ps' => l10n.engineUnitPs,
      'kmh' => l10n.engineUnitKmh,
      'ccm' => l10n.engineUnitCcm,
      'kg' => l10n.engineUnitKg,
      'sec0to100' => l10n.engineUnitSec,
      _ => QuartettGame.statById(statId)?.unit ?? '',
    };

/// Localized ship name by length (Schiffe versenken fleet 5, 4, 3, 3, 2, 2).
String localizedShipName(AppLocalizations l10n, int length) => switch (length) {
      5 => l10n.engineShip5,
      4 => l10n.engineShip4,
      3 => l10n.engineShip3,
      2 => l10n.engineShip2,
      _ => l10n.engineShipOther,
    };

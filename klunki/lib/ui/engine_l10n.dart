import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'shell/player_labels.dart';

/// Localized texts for strings that come from the engine (I18N-05).
///
/// The engine keeps its own English / German texts for the CLI, the debug
/// console and the network log; the app maps the engine's stable ids to
/// [AppLocalizations] here. Car names on Quartett cards are content and are
/// not translated.

/// Localized text for a [GameEndReason] with its [params] (see the enum docs).
/// [playerLabel] names a player for reasons about one (resign: "Anna hat
/// aufgegeben"); default: the regional default name ([defaultPlayerName]).
String localizedEndReason(AppLocalizations l10n, GameEndReason code,
    [Map<String, int> params = const {}, String Function(Player p)? playerLabel]) {
  int p(String name) => params[name] ?? 0;
  String label(Player player) => playerLabel?.call(player) ?? defaultPlayerName(l10n, player);
  return switch (code) {
    GameEndReason.commonResigned => l10n.engineReasonCommonResigned(label(p('player') == 1 ? Player.b : Player.a)),
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
    GameEndReason.chessCheckmate => l10n.engineReasonChessCheckmate,
    GameEndReason.chessStalemate => l10n.engineReasonChessStalemate,
    GameEndReason.chessInsufficientMaterial => l10n.engineReasonChessInsufficientMaterial,
    GameEndReason.chessSeventyFiveMoves => l10n.engineReasonChessSeventyFiveMoves(p('moves')),
    GameEndReason.chessThreefoldRepetition => l10n.engineReasonChessThreefoldRepetition(p('times')),
    GameEndReason.chessDrawAgreed => l10n.engineReasonChessDrawAgreed,
    GameEndReason.wordtilesPlayedOut => l10n.engineReasonWordtilesPlayedOut(p('a'), p('b')),
    GameEndReason.wordtilesScoreless => l10n.engineReasonWordtilesScoreless(p('turns'), p('a'), p('b')),
    GameEndReason.maumauEmptyHand => l10n.engineReasonMaumauEmptyHand,
    GameEndReason.maexchenNoLives => l10n.engineReasonMaexchenNoLives,
    GameEndReason.dicesheetAllFilled => l10n.engineReasonDicesheetAllFilled,
    GameEndReason.propertyLastSolvent => l10n.engineReasonPropertyLastSolvent,
    GameEndReason.propertyRoundLimit => l10n.engineReasonPropertyRoundLimit(p('rounds')),
  };
}

/// Localized reason of [result]: empty while the game runs, the engine's
/// English text for a result without a code.
String localizedResultReason(AppLocalizations l10n, GameResult result, {String Function(Player p)? playerLabel}) {
  final code = result.code;
  return code == null ? result.reason : localizedEndReason(l10n, code, result.params, playerLabel);
}

/// Localized name of a Quartett set letter `A`–`H` of [deck] (KLD-069;
/// default: the car deck); the engine's name (or the letter) for anything
/// else.
String localizedSetName(AppLocalizations l10n, String set, [String deck = QuartettDeck.defaultId]) {
  final i = set.length == 1 ? 'ABCDEFGH'.indexOf(set) : -1;
  final names = switch (deck) {
    'cars' => [
        l10n.engineSetA, l10n.engineSetB, l10n.engineSetC, l10n.engineSetD,
        l10n.engineSetE, l10n.engineSetF, l10n.engineSetG, l10n.engineSetH,
      ],
    'trains' => [
        l10n.quartettSetTrainsA, l10n.quartettSetTrainsB, l10n.quartettSetTrainsC, l10n.quartettSetTrainsD,
        l10n.quartettSetTrainsE, l10n.quartettSetTrainsF, l10n.quartettSetTrainsG, l10n.quartettSetTrainsH,
      ],
    'rockets' => [
        l10n.quartettSetRocketsA, l10n.quartettSetRocketsB, l10n.quartettSetRocketsC, l10n.quartettSetRocketsD,
        l10n.quartettSetRocketsE, l10n.quartettSetRocketsF, l10n.quartettSetRocketsG, l10n.quartettSetRocketsH,
      ],
    'planes' => [
        l10n.quartettSetPlanesA, l10n.quartettSetPlanesB, l10n.quartettSetPlanesC, l10n.quartettSetPlanesD,
        l10n.quartettSetPlanesE, l10n.quartettSetPlanesF, l10n.quartettSetPlanesG, l10n.quartettSetPlanesH,
      ],
    _ => null,
  };
  if (names != null && i >= 0) return names[i];
  return QuartettDeck.byId(deck)?.setNames[set] ?? set;
}

/// Localized name of a Quartett deck id (KLD-069); the engine's name (or the
/// id) for unknown ids.
String localizedDeckName(AppLocalizations l10n, String deck) => switch (deck) {
      'cars' => l10n.quartettDeckCars,
      'trains' => l10n.quartettDeckTrains,
      'rockets' => l10n.quartettDeckRockets,
      'planes' => l10n.quartettDeckPlanes,
      _ => QuartettDeck.byId(deck)?.name ?? deck,
    };

/// The engine's stat with [statId] in any deck (a stat id means the same in
/// every deck), or null.
QuartettStat? _anyStat(String statId) {
  for (final d in QuartettDeck.all) {
    final s = d.statById(statId);
    if (s != null) return s;
  }
  return null;
}

/// Soft hyphen (U+00AD): marks where a long stat label may be hyphenated on
/// a card (KLD-092, "Höchst\u00ADgeschwindig\u00ADkeit").
const softHyphen = '\u00AD';

/// Localized label of a Quartett stat id (any deck); the engine label (or the
/// id) for unknown ids. Plain text: the soft hyphens of the ARB are removed
/// (for running text, history, semantics and tests).
String localizedStatLabel(AppLocalizations l10n, String statId) =>
    localizedStatLabelHyphenated(l10n, statId).replaceAll(softHyphen, '');

/// [localizedStatLabel] with the soft hyphens ([softHyphen]) of the ARB, the
/// places where the card may break a long word (see `HyphenatedLabel`).
String localizedStatLabelHyphenated(AppLocalizations l10n, String statId) => switch (statId) {
      'ps' => l10n.engineStatPs,
      'kmh' => l10n.engineStatKmh,
      'ccm' => l10n.engineStatCcm,
      'kg' => l10n.engineStatKg,
      'sec0to100' => l10n.engineStatSec0to100,
      'kw' => l10n.quartettStatKw,
      'lengthM' => l10n.quartettStatLengthM,
      'massT' => l10n.quartettStatMassT,
      'tractiveKn' => l10n.quartettStatTractiveKn,
      'built' => l10n.quartettStatBuilt,
      'heightM' => l10n.quartettStatHeightM,
      'thrustKn' => l10n.quartettStatThrustKn,
      'leoT' => l10n.quartettStatLeoT,
      'launchMassT' => l10n.quartettStatLaunchMassT,
      'flights' => l10n.quartettStatFlights,
      'successPct' => l10n.quartettStatSuccessPct,
      'rangeKm' => l10n.quartettStatRangeKm,
      'wingspanM' => l10n.quartettStatWingspanM,
      'mtowT' => l10n.quartettStatMtowT,
      _ => _anyStat(statId)?.label ?? statId,
    };

/// Localized unit of a Quartett stat id (de "PS", en "hp"); the engine unit
/// for the other ids (SI symbols like `kW`, `t`, `m` and `%` read the same in
/// every language; launch counts have none).
String localizedStatUnit(AppLocalizations l10n, String statId) => switch (statId) {
      'ps' => l10n.engineUnitPs,
      'kmh' => l10n.engineUnitKmh,
      'ccm' => l10n.engineUnitCcm,
      'kg' => l10n.engineUnitKg,
      'sec0to100' => l10n.engineUnitSec,
      'built' => l10n.quartettUnitBuilt,
      _ => _anyStat(statId)?.unit ?? '',
    };

/// Localized ship name by length (Schiffe versenken fleet 5, 4, 3, 3, 2, 2).
String localizedShipName(AppLocalizations l10n, int length) => switch (length) {
      5 => l10n.engineShip5,
      4 => l10n.engineShip4,
      3 => l10n.engineShip3,
      2 => l10n.engineShip2,
      _ => l10n.engineShipOther,
    };

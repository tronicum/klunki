import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

import 'shell/player_labels.dart';

/// Localized texts for strings that come from the engine (I18N-05).
///
/// The engine keeps its own English / German texts for the CLI, the debug
/// console and the network log; the app maps the engine's stable ids to
/// [AppLocalizations] here. Vehicle names on Quartett cards are content and
/// are not translated; animal names are ([localizedCardName], KLD-128).

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
    GameEndReason.chessTimeout => l10n.engineReasonChessTimeout(label(p('player') == 1 ? Player.b : Player.a)),
    GameEndReason.chessTimeoutDraw =>
      l10n.engineReasonChessTimeoutDraw(label(p('player') == 1 ? Player.b : Player.a)),
    // KLD-125: 3–4 players (a seat result: `score0…3`, no `a` / `b`) say
    // why without the score; the ranking under it has every score.
    GameEndReason.wordtilesPlayedOut => params.containsKey('a')
        ? l10n.engineReasonWordtilesPlayedOut(p('a'), p('b'))
        : l10n.engineReasonWordtilesPlayedOutSeats,
    GameEndReason.wordtilesScoreless => params.containsKey('a')
        ? l10n.engineReasonWordtilesScoreless(p('turns'), p('a'), p('b'))
        : l10n.engineReasonWordtilesScorelessSeats(p('turns')),
    GameEndReason.maumauEmptyHand => l10n.engineReasonMaumauEmptyHand,
    GameEndReason.maexchenNoLives => l10n.engineReasonMaexchenNoLives,
    GameEndReason.maexchenEnded => l10n.engineReasonMaexchenEnded,
    GameEndReason.dicesheetAllFilled => l10n.engineReasonDicesheetAllFilled,
    GameEndReason.propertyLastSolvent => l10n.engineReasonPropertyLastSolvent,
    GameEndReason.propertyRoundLimit => l10n.engineReasonPropertyRoundLimit(p('rounds')),
    GameEndReason.ludoAllHome => l10n.engineReasonLudoAllHome,
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
    'animals' => [
        l10n.quartettSetAnimalsA, l10n.quartettSetAnimalsB, l10n.quartettSetAnimalsC, l10n.quartettSetAnimalsD,
        l10n.quartettSetAnimalsE, l10n.quartettSetAnimalsF, l10n.quartettSetAnimalsG, l10n.quartettSetAnimalsH,
      ],
    'motorcycles' => [
        l10n.quartettSetMotorcyclesA, l10n.quartettSetMotorcyclesB, l10n.quartettSetMotorcyclesC,
        l10n.quartettSetMotorcyclesD, l10n.quartettSetMotorcyclesE, l10n.quartettSetMotorcyclesF,
        l10n.quartettSetMotorcyclesG, l10n.quartettSetMotorcyclesH,
      ],
    'special' => [
        l10n.quartettSetSpecialA, l10n.quartettSetSpecialB, l10n.quartettSetSpecialC, l10n.quartettSetSpecialD,
        l10n.quartettSetSpecialE, l10n.quartettSetSpecialF, l10n.quartettSetSpecialG, l10n.quartettSetSpecialH,
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
      'animals' => l10n.quartettDeckAnimals,
      'motorcycles' => l10n.quartettDeckMotorcycles,
      'special' => l10n.quartettDeckSpecial,
      _ => QuartettDeck.byId(deck)?.name ?? deck,
    };

/// The name of a Quartett [card] as shown (KLD-128): animal names are
/// translated, the vehicle decks keep the engine's name (real model names),
/// except the type word of three special vehicles (KLD-130).
/// Display only: the engine's German [Card.name] stays the card's name in
/// the game, the network and the compat fingerprint (the German ARB names
/// equal the engine's names, a test checks it). Plain text: the soft
/// hyphens of the ARB are removed (running text, semantics, tests).
String localizedCardName(AppLocalizations l10n, Card card) =>
    localizedCardNameHyphenated(l10n, card).replaceAll(softHyphen, '');

/// [localizedCardName] with the soft hyphens ([softHyphen]) of the ARB, where
/// a narrow card may break a long name ("Wander-albatros", see
/// `HyphenatedLabel`).
String localizedCardNameHyphenated(AppLocalizations l10n, Card card) => switch (card.deck) {
      'animals' => _animalName(l10n, card.id) ?? card.name,
      'special' => _specialVehicleName(l10n, card.id) ?? card.name,
      _ => card.name,
    };

/// KLD-130: the three rescue vehicles whose model name says little carry a
/// translated type word ("Rettungswagen Sprinter"); the other special
/// vehicles keep their model names.
String? _specialVehicleName(AppLocalizations l10n, String id) => switch (id) {
      'E1' => l10n.quartettSpecialE1,
      'E2' => l10n.quartettSpecialE2,
      'E4' => l10n.quartettSpecialE4,
      _ => null,
    };

String? _animalName(AppLocalizations l10n, String id) => switch (id) {
      'A1' => l10n.quartettAnimalA1,
      'A2' => l10n.quartettAnimalA2,
      'A3' => l10n.quartettAnimalA3,
      'A4' => l10n.quartettAnimalA4,
      'B1' => l10n.quartettAnimalB1,
      'B2' => l10n.quartettAnimalB2,
      'B3' => l10n.quartettAnimalB3,
      'B4' => l10n.quartettAnimalB4,
      'C1' => l10n.quartettAnimalC1,
      'C2' => l10n.quartettAnimalC2,
      'C3' => l10n.quartettAnimalC3,
      'C4' => l10n.quartettAnimalC4,
      'D1' => l10n.quartettAnimalD1,
      'D2' => l10n.quartettAnimalD2,
      'D3' => l10n.quartettAnimalD3,
      'D4' => l10n.quartettAnimalD4,
      'E1' => l10n.quartettAnimalE1,
      'E2' => l10n.quartettAnimalE2,
      'E3' => l10n.quartettAnimalE3,
      'E4' => l10n.quartettAnimalE4,
      'F1' => l10n.quartettAnimalF1,
      'F2' => l10n.quartettAnimalF2,
      'F3' => l10n.quartettAnimalF3,
      'F4' => l10n.quartettAnimalF4,
      'G1' => l10n.quartettAnimalG1,
      'G2' => l10n.quartettAnimalG2,
      'G3' => l10n.quartettAnimalG3,
      'G4' => l10n.quartettAnimalG4,
      'H1' => l10n.quartettAnimalH1,
      'H2' => l10n.quartettAnimalH2,
      'H3' => l10n.quartettAnimalH3,
      'H4' => l10n.quartettAnimalH4,
      _ => null,
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
      // KLD-128: animal weight wins high (unlike the cars' `kg`), same word.
      'weightKg' => l10n.engineStatKg,
      'lifeYears' => l10n.quartettStatLifeYears,
      'gestationD' => l10n.quartettStatGestationD,
      // KLD-129: motorcycles ("ps", "kmh" and "kg" as in the car deck).
      'nm' => l10n.quartettStatNm,
      'rangeKmBike' => l10n.quartettStatRangeKmBike,
      'valueEur' => l10n.quartettStatValueEur,
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
      'weightKg' => l10n.engineUnitKg,
      'lifeYears' => l10n.quartettUnitYears,
      'gestationD' => l10n.quartettUnitDays,
      'nm' => l10n.quartettUnitNm,
      'valueEur' => l10n.quartettUnitEur,
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

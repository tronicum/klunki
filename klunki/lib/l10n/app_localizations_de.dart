// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get menuLanguage => 'Sprache';

  @override
  String get languagePickerTitle => 'Sprache wählen';

  @override
  String get languageSystem => 'System';

  @override
  String get menuChooseGame => 'Wähle ein Spiel';

  @override
  String get menuPassDevice => 'Gerät weitergeben';

  @override
  String get menuDebugConsole => 'Debug-Konsole';

  @override
  String get menuGameConnect4 => '4 Gewinnt';

  @override
  String get menuGameMuehle => 'Mühle';

  @override
  String get menuGameQuartettTrumpf => 'Quartett (Trumpf)';

  @override
  String get menuGameQuartettSets => 'Quartett (Sets)';

  @override
  String get menuGameSchiffe => 'Schiffe versenken';

  @override
  String shellToMove(String player) {
    return '$player ist am Zug';
  }

  @override
  String shellHasWon(String player) {
    return '$player hat gewonnen';
  }

  @override
  String get shellDraw => 'Unentschieden';

  @override
  String shellWins(String player) {
    return '$player gewinnt!';
  }

  @override
  String get shellMenu => 'Menü';

  @override
  String get shellPlayAgain => 'Nochmal';

  @override
  String get shellUndo => 'Zug zurück';

  @override
  String get shellNewGame => 'Neues Spiel';

  @override
  String get shellNewGameTitle => 'Neues Spiel?';

  @override
  String get shellNewGameBody => 'Das laufende Spiel wird abgebrochen.';

  @override
  String get shellCancel => 'Abbrechen';

  @override
  String get shellRestart => 'Neu starten';

  @override
  String get shellMoves => 'Züge';

  @override
  String get shellNoMoves => 'Noch keine Züge.';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player: $move';
  }

  @override
  String shellHandoverPass(String player) {
    return 'Gib das Gerät an $player weiter';
  }

  @override
  String shellHandoverContinue(String player) {
    return 'Ich bin $player – weiter';
  }

  @override
  String connect4Column(int column) {
    return 'Spalte $column';
  }

  @override
  String get connect4HintTapColumn => 'Tippe auf eine Spalte';

  @override
  String get muehlePhasePlacing => 'Setzen';

  @override
  String get muehlePhaseMoving => 'Ziehen';

  @override
  String get muehlePhaseFlying => 'Springen';

  @override
  String muehleMovePlace(int point) {
    return 'setzt auf $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return 'entfernt Stein auf $point';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return 'zieht $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return 'springt $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return 'Mühle! Entferne einen Stein von $player';
  }

  @override
  String get muehleHintPlace => 'Setze einen Stein';

  @override
  String get muehleHintTarget =>
      'Wähle ein Ziel (oder tippe den Stein erneut zum Abwählen)';

  @override
  String get muehleHintSelectFly => 'Wähle einen Stein zum Springen';

  @override
  String get muehleHintSelectMove => 'Wähle einen Stein zum Ziehen';

  @override
  String muehlePointEmpty(int point) {
    return 'Punkt $point, leer';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return 'Punkt $point, $player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return 'Hand: $hand · Brett: $board';
  }

  @override
  String muehleCaptured(int count) {
    return 'Geschlagen: $count';
  }

  @override
  String get quartettNoGame => 'Kein Quartett-Spiel';

  @override
  String get quartettContinue => 'Weiter';

  @override
  String get quartettHigherWins => 'höher gewinnt';

  @override
  String get quartettLowerWins => 'niedriger gewinnt';

  @override
  String get quartettCardBack => 'QUARTETT';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return '$player: $_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return 'wählt $stat';
  }

  @override
  String get quartettTrumpfHintPick => 'Wähle eine Eigenschaft deiner Karte';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Topf: $_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return 'Stapel von $player';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'Deine Karte ($player)';
  }

  @override
  String get quartettTrumpfTie => 'Gleichstand – Karten in den Topf';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player gewinnt den Stich';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'gewinnt';

  @override
  String get quartettTrumpfOutcomeLose => 'verliert';

  @override
  String get quartettTrumpfOutcomeTie => 'Gleichstand';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player wählt $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Im Topf: $_temp0 – $player wählt noch einmal';
  }

  @override
  String get quartettSetsHit => 'Treffer';

  @override
  String get quartettSetsMiss => 'Fehlanzeige';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return 'fragt nach $card: $result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return 'fragt nach $card: $result – Quartett $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return 'Tippe auf „Weiter“ und gib das Gerät an $player weiter';
  }

  @override
  String get quartettSetsHintAsk =>
      'Tippe auf eine fehlende Karte, um danach zu fragen';

  @override
  String get quartettSetsNoQuartet => 'noch kein Quartett';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Stapel: $_temp0';
  }

  @override
  String quartettSetsScore(int a, int b) {
    return 'Quartette X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player fragt nach $card: $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return 'Treffer! $player gibt dir $card';
  }

  @override
  String get quartettSetsMissDraw => 'Fehlanzeige – du ziehst eine Karte';

  @override
  String get quartettSetsMissEmpty => 'Fehlanzeige – der Stapel ist leer';

  @override
  String get quartettSetsAskAgain => 'Du darfst noch einmal fragen.';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return '$player hat $card nicht.';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return 'Quartett! $set abgelegt';
  }

  @override
  String get quartettSetsDrawn => 'Gezogen:';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Deine Karten ($player): $_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – fehlt: $missing';
  }

  @override
  String get quartettSetsAskSlot => 'fragen';

  @override
  String get quartettSetsMissingSlot => 'fehlt';

  @override
  String get schiffeHintSetup =>
      'Aufstellung: tippe aufs Meer (oder ziehe und lass los), um das Schiff zu setzen. Schiffe dürfen sich nicht berühren.';

  @override
  String get schiffeHintAllSunk => 'Alle Schiffe versenkt.';

  @override
  String schiffeHintWaiting(String player) {
    return 'Warte auf $player …';
  }

  @override
  String get schiffeHintExtraShot =>
      'Treffer! Nochmal – tippe auf ein Feld im Gegner-Meer.';

  @override
  String get schiffeHintFire =>
      'Tippe auf ein unbekanntes Feld im Gegner-Meer, um zu schießen.';

  @override
  String get schiffeLookWater => 'Wasser';

  @override
  String get schiffeLookShip => 'Schiff';

  @override
  String get schiffeLookMiss => 'Fehlschuss';

  @override
  String get schiffeLookShipHit => 'Schiff getroffen';

  @override
  String get schiffeLookHit => 'Treffer';

  @override
  String get schiffeLookSunk => 'versenkt';

  @override
  String get schiffeLookUnknown => 'unbekannt';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => 'Flotte komplett';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship ($length)';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship ($length) · gesetzt';
  }

  @override
  String schiffeSetupProgress(int index, int total, String player) {
    return 'Schiff $index von $total · $player stellt auf';
  }

  @override
  String get schiffeHorizontal => 'Horizontal';

  @override
  String get schiffeVertical => 'Vertikal';

  @override
  String get schiffeRandom => 'Zufällig';

  @override
  String get schiffeFleet => 'Flotte';

  @override
  String schiffeExtraShotSunk(String ship) {
    return '$ship versenkt – Treffer! Nochmal';
  }

  @override
  String get schiffeExtraShot => 'Treffer! Nochmal';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return 'Deine Flotte: $own · Gegner ($player): $opponent Schiffe übrig';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return '$player schoss zuletzt auf $cell: $result';
  }

  @override
  String get schiffeTargetSection => 'Gegner';

  @override
  String get schiffeOwnSection => 'Dein Meer';

  @override
  String get schiffeMovePlace => 'platziert ein Schiff';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'platziert $count Schiffe zufällig',
      one: 'platziert ein Schiff zufällig',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return 'schießt auf $cell: $result';
  }

  @override
  String schiffeShipSunk(String ship) {
    return '$ship versenkt';
  }

  @override
  String get debugConsoleTitle => 'Debug-Konsole';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => 'Spiel / Demo';

  @override
  String debugNewGame(String game) {
    return 'Neu: $game';
  }

  @override
  String get debugLegalMoves => 'Legale Züge';

  @override
  String get debugAutoPlay => 'Zu Ende spielen (zufällig)';

  @override
  String get debugDemo => 'Demo: alle Spiele';
}

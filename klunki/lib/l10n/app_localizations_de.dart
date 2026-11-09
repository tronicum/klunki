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
  String get menuDescConnect4 =>
      'Vier in einer Reihe – waagerecht, senkrecht oder schräg.';

  @override
  String get menuDescMuehle =>
      'Bilde Dreierreihen und schlage gegnerische Steine.';

  @override
  String get menuDescQuartettTrumpf =>
      'Vergleicht Werte – der bessere Wert gewinnt beide Karten.';

  @override
  String get menuDescQuartettSets =>
      'Erfrage Karten und sammle vollständige Vierer-Sets.';

  @override
  String get menuDescSchiffe =>
      'Versteckt eure Flotten und schießt abwechselnd.';

  @override
  String get menuSectionNetwork => 'Mit anderen Geräten spielen';

  @override
  String get menuPlayOnOneDevice => 'Ein Gerät';

  @override
  String get menuPlayWithOthers => 'Mit anderen';

  @override
  String get hotSeatPassDeviceHint =>
      'Ihr gebt das Gerät weiter – was verdeckt ist, bleibt geheim.';

  @override
  String get roomStartSubtitle => 'Andere kommen mit dem Raumcode dazu';

  @override
  String get roomJoinSubtitle => 'Code scannen oder eintippen';

  @override
  String get roomAdvanced => 'Erweitert';

  @override
  String get roomDirectWaitingHint =>
      'Andere tippen auf „Raum beitreten“ und scannen diesen QR-Code. Geräte im selben WLAN finden den Raum auch unter „Räume in der Nähe“.';

  @override
  String get roomViaRelay => 'Raum über einen Server öffnen';

  @override
  String get roomViaRelayHelper =>
      'Mit Raumcode, auch für Mitspieler im Browser. Dafür braucht ihr einen Server (z. B. einen Rechner, auf dem „klunki relay“ läuft). Ausgeschaltet läuft der Raum direkt auf diesem Gerät, und Geräte im selben WLAN finden ihn von selbst.';

  @override
  String get roomTypeCode => 'Raumcode eintippen';

  @override
  String shellToMove(String player) {
    return '$player ist am Zug';
  }

  @override
  String shellHasWon(String player) {
    return '$player hat gewonnen';
  }

  @override
  String get shellYourTurn => 'Du bist am Zug';

  @override
  String shellWaitingFor(String player) {
    return 'Warte auf $player…';
  }

  @override
  String get shellYouHaveWon => 'Du hast gewonnen';

  @override
  String get shellDraw => 'Unentschieden';

  @override
  String shellWins(String player) {
    return '$player gewinnt!';
  }

  @override
  String get shellYouWin => 'Du gewinnst!';

  @override
  String get shellMenu => 'Menü';

  @override
  String get shellPlayAgain => 'Nochmal';

  @override
  String get shellUndo => 'Zug zurücknehmen';

  @override
  String get shellTakeBack => 'Zug zurücknehmen';

  @override
  String get undoAllowedSetting => 'Zug zurücknehmen erlauben';

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
  String get quartettTrumpfTie => 'Gleichstand – Stechen!';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player gewinnt die Runde';
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
    return 'Karten in den Topf (jetzt $count), $player wählt noch einmal';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player wählt …';
  }

  @override
  String get quartettTrumpfLastTrick => 'Vorige Runde';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'Weiter in $seconds s';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player hat gewählt: $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return '$player wählt als Nächstes';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player wählt noch einmal';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'Weiter – $player wählt';
  }

  @override
  String get quartettTrumpfYouPickNext => 'Du wählst als Nächstes';

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Runden',
      one: '1 Runde',
    );
    return 'noch $_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return '$player hat die Runde gewonnen';
  }

  @override
  String quartettTrumpfChooseOwn(int count) {
    return 'Du hast nur noch $count Karten – wähle eine aus.';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return '$player spielt $stat. Wähle deine Karte.';
  }

  @override
  String get quartettTrumpfMoveChoose => 'wählt eine Karte';

  @override
  String quartettTrumpfHintDefending(String player) {
    return '$player wählt eine Karte …';
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
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return 'Quartette $nameA $a : $b $nameB';
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
  String get schiffeHintSetup => 'Tippe aufs Meer, um das Schiff zu setzen.';

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
  String get schiffeRotate => 'Drehen';

  @override
  String schiffeRotateSemantics(String orientation) {
    return 'Drehen, aktuell $orientation';
  }

  @override
  String get schiffeRemove => 'Entfernen';

  @override
  String get schiffeRemoveTooltip => 'Zurück in den Hafen';

  @override
  String get schiffeReset => 'Zurücksetzen';

  @override
  String get schiffeDone => 'Fertig';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return '$placed von $total Schiffen gesetzt · $player stellt auf';
  }

  @override
  String schiffeHintSelected(String ship) {
    return '$ship ausgewählt: ziehen zum Verschieben, nochmal antippen zum Drehen.';
  }

  @override
  String get schiffeHintReady =>
      'Flotte steht. Schiff antippen zum Verschieben oder Drehen – oder „Fertig“.';

  @override
  String schiffeHintEarly(String player) {
    return 'Du kannst schon aufstellen. „Fertig“ geht, sobald $player fertig ist.';
  }

  @override
  String get schiffeInvalidPlace =>
      'Passt dort nicht: Schiffe müssen ganz aufs Meer und dürfen sich nicht berühren.';

  @override
  String get schiffeInvalidRotate => 'Drehen geht hier nicht – zu wenig Platz.';

  @override
  String get schiffeSubmitFailed =>
      'Die Aufstellung wurde nicht angenommen. Tippe nochmal „Fertig“.';

  @override
  String get schiffeSelected => 'ausgewählt';

  @override
  String get schiffeHarbour => 'Hafen';

  @override
  String get schiffeHintSetupMore =>
      'Tippe aufs Meer für das nächste Schiff. Schiff antippen zum Verschieben oder Drehen.';

  @override
  String get schiffeCoachTap => 'Antippen: verschieben oder drehen';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Schiffe',
      one: 'noch 1 Schiff',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return 'Vorschau: $ship, $orientation. Tippen dreht es.';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count dieser Art',
      one: 'das letzte dieser Art',
    );
    return '$_temp0';
  }

  @override
  String get schiffeInvalidTouch =>
      'Schiffe dürfen sich nicht berühren, auch nicht über Eck – lass ein Feld Abstand.';

  @override
  String get schiffeInvalidOffBoard => 'Passt nicht aufs Spielfeld.';

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

  @override
  String get pairingDeviceNameHelper => 'So sieht dich dein Mitspieler';

  @override
  String get playerNameTitle => 'Wie heißt du?';

  @override
  String get playerNameLabel => 'Dein Name';

  @override
  String playerLabel(String name, String mark) {
    return '$name ($mark)';
  }

  @override
  String get playerDefaultNameA => 'Anna';

  @override
  String get playerDefaultNameB => 'Ben';

  @override
  String get hotSeatStartTitle => 'Wer spielt?';

  @override
  String get hotSeatStartPlay => 'Spielen';

  @override
  String get hotSeatNamesTitle => 'Spielernamen';

  @override
  String hotSeatNameLabel(int number) {
    return 'Spieler $number';
  }

  @override
  String get hotSeatStartsHint => 'beginnt';

  @override
  String get hotSeatNamesHelper => 'Leer lassen für den Standardnamen.';

  @override
  String get pairingChooseGame => 'Spiel wählen';

  @override
  String get roomStart => 'Raum starten';

  @override
  String roomStartFailed(String error) {
    return 'Raum konnte nicht gestartet werden: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'Nicht automatisch sichtbar – andere scannen den QR-Code.';

  @override
  String get pairingNoDiscoveryHost =>
      'Keine automatische Suche auf diesem Gerät – andere scannen den QR-Code.';

  @override
  String roomOfPlayer(String name, String game) {
    return 'Raum von $name: $game';
  }

  @override
  String pairingNoAddress(int port) {
    return 'Keine WLAN-Adresse gefunden. Ist das Gerät mit dem WLAN verbunden? Port: $port';
  }

  @override
  String get pairingAddresses => 'Adressen (zum Eintippen):';

  @override
  String get pairingProbablyWifi => 'wahrscheinlich WLAN';

  @override
  String get pairingWaitingForGuest => 'Warte auf Mitspieler…';

  @override
  String get pairingCancel => 'Abbrechen';

  @override
  String get roomNearby => 'Räume in der Nähe';

  @override
  String get pairingNoDiscoveryJoin =>
      'Automatische Suche ist auf diesem Gerät nicht verfügbar. Scanne den QR-Code oder gib unter „Erweitert“ die Adresse ein.';

  @override
  String get pairingBrowseFailed =>
      'Suche im Netzwerk nicht möglich. Scanne den QR-Code oder gib unter „Erweitert“ die Adresse ein.';

  @override
  String get pairingSearching => 'Suche nach Räumen…';

  @override
  String get pairingOtherVersion => 'andere Klunki-Version';

  @override
  String get pairingManualLabel => 'IP, IP:Port oder klunki://-Link';

  @override
  String get pairingInvalidAddress =>
      'Ungültige Adresse. Beispiel: 192.168.1.20 oder 192.168.1.20:4747';

  @override
  String get pairingConnect => 'Verbinden';

  @override
  String pairingConnecting(String host) {
    return 'Verbinde mit $host…';
  }

  @override
  String get pairingTimeout => 'Zeitüberschreitung';

  @override
  String pairingJoinFailed(String host, String error) {
    return 'Verbindung zu $host fehlgeschlagen ($error).';
  }

  @override
  String get pairingJoinHints =>
      'Tipps: Sind beide Geräte im selben WLAN? Gäste-WLANs blockieren oft Verbindungen zwischen Geräten. iOS: Ist „Lokales Netzwerk“ für Klunki erlaubt (Einstellungen › Datenschutz)?';

  @override
  String pairingStatus(String name, String peer) {
    return 'Du: $name · Gegner: $peer';
  }

  @override
  String netBarYou(String name) {
    return 'Du: $name';
  }

  @override
  String netBarOpponent(String peer) {
    return 'Gegner: $peer';
  }

  @override
  String get pairingOpponent => 'Gegner';

  @override
  String pairingPeerLeft(String peer) {
    return '$peer hat das Spiel verlassen';
  }

  @override
  String pairingPeerLost(String peer) {
    return 'Verbindung zu $peer unterbrochen';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. Warte, bis er wieder beitritt…';
  }

  @override
  String get pairingReconnecting => 'Verbindung wird wiederhergestellt …';

  @override
  String get pairingReconnect => 'Neu verbinden';

  @override
  String get networkVerificationFailed =>
      'Spielverlauf konnte nicht bestätigt werden';

  @override
  String get pairingReconnectFailed =>
      'Neu verbinden fehlgeschlagen. Ist das andere Gerät noch im Spiel?';

  @override
  String get pairingBrowserJoin =>
      'Im Browser beitreten (Adresse eingeben oder Link einfügen):';

  @override
  String get pairingCopyLink => 'Link kopieren';

  @override
  String get pairingLinkCopied => 'Link kopiert';

  @override
  String get webJoinHttpsWarning =>
      'Im Browser über https kann Klunki nur sichere Server (wss://) erreichen – nutze die App oder die lokale http-Version.';

  @override
  String get webJoinAddressLabel => 'IP, IP:Port, ws://- oder klunki://-Link';

  @override
  String webJoinAddressHelper(int port) {
    return 'Der Port ist der Browser-Port (WebSocket) des anderen Geräts, ohne Angabe $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Ungültige Adresse. Beispiel: 192.168.1.20, 192.168.1.20:4748 oder klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Tipps: Ist dieses Gerät im selben WLAN wie das Gerät mit dem Raum? Gäste-WLANs blockieren oft Verbindungen zwischen Geräten. Die Seite muss über http:// geöffnet sein, nicht über https://. Auf dem anderen Gerät muss eine Klunki-Version mit Browser-Unterstützung laufen (sie zeigt „Im Browser beitreten“).';

  @override
  String get engineReasonConnect4FourInARow => 'Vier in einer Reihe';

  @override
  String get engineReasonConnect4BoardFull => 'Brett voll';

  @override
  String get engineReasonMuehleFewerThanThree =>
      'Gegner hat weniger als 3 Steine';

  @override
  String get engineReasonMuehleBlocked => 'Gegner kann nicht mehr ziehen';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves Züge ohne Schlagen';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => 'Beide Stapel leer';

  @override
  String get engineReasonQuartettAllCards => 'Gegner hat keine Karten mehr';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return 'Rundenlimit erreicht, gleich viele Karten ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Rundenlimit erreicht, mehr Karten ($a:$b)';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return 'Alle Quartette abgelegt, $a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return 'Mehr Quartette ($a:$b)';
  }

  @override
  String get engineReasonSchiffeAllSunk => 'Alle Schiffe versenkt';

  @override
  String get engineReasonGostrategyFlagCaptured => 'Fahne erobert';

  @override
  String get engineReasonGostrategyNoMoves => 'Gegner hat keinen Zug mehr';

  @override
  String get engineReasonGostrategyBothBlocked => 'Keine Seite kann ziehen';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves Züge ohne Kampf';
  }

  @override
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy =>
      'Verdeckte Armeen – finde und erobere die gegnerische Fahne.';

  @override
  String get goPieceMarshal => 'Marschall';

  @override
  String get goPieceGeneral => 'General';

  @override
  String get goPieceColonel => 'Oberst';

  @override
  String get goPieceMajor => 'Major';

  @override
  String get goPieceCaptain => 'Hauptmann';

  @override
  String get goPieceLieutenant => 'Leutnant';

  @override
  String get goPieceSergeant => 'Feldwebel';

  @override
  String get goPieceMiner => 'Mineur';

  @override
  String get goPieceScout => 'Aufklärer';

  @override
  String get goPieceSpy => 'Spion';

  @override
  String get goPieceBomb => 'Bombe';

  @override
  String get goPieceFlag => 'Fahne';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece ($rank)';
  }

  @override
  String goSetupTitle(String player) {
    return 'Stelle deine Armee auf ($player)';
  }

  @override
  String get goSetupHint =>
      'Tippe zwei Figuren an oder ziehe eine auf ein anderes Feld deiner vier Reihen, um sie zu tauschen. Dann „Fertig“.';

  @override
  String goSetupSelected(String piece) {
    return '$piece gewählt – tippe ein anderes Feld deiner vier Reihen zum Tauschen.';
  }

  @override
  String get goSetupShuffle => 'Neu mischen';

  @override
  String get goSetupDone => 'Fertig';

  @override
  String goSetupFirst(String player) {
    return '$player stellt zuerst auf – du kannst schon vorbereiten.';
  }

  @override
  String goWaitingSetup(String player) {
    return 'Warte, bis $player aufgestellt hat …';
  }

  @override
  String get goLegendTitle => 'Figuren';

  @override
  String get goLegendRules =>
      'Höherer Rang gewinnt, bei gleichem Rang fallen beide. Der Spion schlägt den Marschall, wenn er angreift. Nur Mineure entschärfen Bomben. Aufklärer ziehen beliebig weit geradeaus. Bomben und Fahne bleiben stehen.';

  @override
  String get goHintSelect =>
      'Tippe eine deiner Figuren an, dann ein markiertes Feld.';

  @override
  String goHintSelected(String piece) {
    return '$piece: tippe ein markiertes Feld.';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece kann gerade nicht ziehen.';
  }

  @override
  String goHintWaiting(String player) {
    return 'Warte auf $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return 'Noch $moves Züge ohne Kampf, dann ist es unentschieden.';
  }

  @override
  String get goArmyOwn => 'Deine Armee';

  @override
  String goArmyEnemy(String player) {
    return 'Gegner: $player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return '$left von $total übrig';
  }

  @override
  String goFightBy(String player) {
    return 'Angriff von $player';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner schlägt $loser';
  }

  @override
  String get goFightBoth => 'Beide fallen';

  @override
  String goFightDefused(String piece) {
    return '$piece entschärft die Bombe';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece läuft auf eine Bombe';
  }

  @override
  String get goFightFlag => 'Fahne erobert!';

  @override
  String get goMoveSetup => 'stellt die Armee auf';

  @override
  String goMoveStep(String from, String to) {
    return 'zieht $from–$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return 'greift an ($from–$to): $result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell: $content';
  }

  @override
  String get goCellFree => 'frei';

  @override
  String get goCellLake => 'See';

  @override
  String goCellHidden(String player) {
    return 'verdeckte Figur von $player';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece von $player';
  }

  @override
  String goCellMoved(String content) {
    return '$content, bewegt';
  }

  @override
  String gameNotInApp(String game) {
    return '$game gibt es in der App noch nicht.';
  }

  @override
  String get engineSetA => 'Supersportwagen';

  @override
  String get engineSetB => 'Hypercars';

  @override
  String get engineSetC => 'Klassiker';

  @override
  String get engineSetD => 'Muscle Cars';

  @override
  String get engineSetE => 'Rallye-Legenden';

  @override
  String get engineSetF => 'Gran Turismo';

  @override
  String get engineSetG => 'Elektro';

  @override
  String get engineSetH => 'Kleine Flitzer';

  @override
  String get engineStatPs => 'Leistung';

  @override
  String get engineStatKmh => 'Höchst­geschwindig­keit';

  @override
  String get engineStatCcm => 'Hub­raum';

  @override
  String get engineStatKg => 'Gewicht';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => 'PS';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cm³';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => 'Schlachtschiff';

  @override
  String get engineShip4 => 'Kreuzer';

  @override
  String get engineShip3 => 'Zerstörer';

  @override
  String get engineShip2 => 'U-Boot';

  @override
  String get engineShipOther => 'Schiff';

  @override
  String get roomStartIntro =>
      'Andere tippen auf „Raum beitreten“ und geben den Raumcode ein.';

  @override
  String get relayRoomCode => 'Raumcode';

  @override
  String get relayWaitingHint =>
      'Andere tippen auf „Raum beitreten“ und scannen den QR-Code oder geben den Raumcode ein. Oder sie öffnen den Link.';

  @override
  String relayInfo(String address) {
    return 'Server: $address';
  }

  @override
  String get roomCodeHelper =>
      '5 Zeichen – das andere Gerät zeigt den Code bei seinem Raum.';

  @override
  String get relayCodeInvalid =>
      'Ungültiger Raumcode: 5 Buchstaben oder Ziffern (ohne 0, O, 1, I, L).';

  @override
  String get roomJoin => 'Raum beitreten';

  @override
  String relayJoining(String code) {
    return 'Trete Raum $code bei…';
  }

  @override
  String get relayAddressLabel => 'Server';

  @override
  String get relayAddressHelper =>
      'Adresse des Servers, z. B. 192.168.1.20:4749 (im WLAN) oder wss://spiele.example (im Internet)';

  @override
  String get relayAddressInvalid =>
      'Ungültige Server-Adresse. Beispiel: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'Kein Raum mit dem Code $code. Stimmt der Code, und ist der Raum noch offen?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'Raum $code ist schon voll: Dort spielen bereits zwei.';
  }

  @override
  String relayErrorHostAway(String code) {
    return 'Das Gerät, das Raum $code gestartet hat, ist gerade nicht erreichbar. Versuch es gleich noch einmal.';
  }

  @override
  String get relayErrorRoomClosed =>
      'Der Raum wurde geschlossen: Wer ihn gestartet hat, ist gegangen. Das Spiel ist beendet.';

  @override
  String get relayErrorExpired =>
      'Der Raum ist abgelaufen (10 Minuten ohne Aktivität).';

  @override
  String relayErrorUnreachable(String address) {
    return 'Kein Server erreichbar unter $address.';
  }

  @override
  String get relayErrorLost => 'Die Verbindung zum Server ist abgebrochen.';

  @override
  String get relayStartHint =>
      'Räume mit Raumcode brauchen einen Server. Starte ihn auf einem Rechner im WLAN und öffne Klunki über dessen Adresse:';

  @override
  String relayRoomLost(String reason) {
    return '$reason Starte einen neuen Raum.';
  }

  @override
  String relayFromLink(String address) {
    return 'Server aus Link: $address';
  }

  @override
  String get relayLinkSaveDefault => 'Als Standard speichern';

  @override
  String get relayLinkUseSaved => 'Gespeicherten Server verwenden';

  @override
  String get relayLinkForeign =>
      'Achtung: Dieser Link führt zu einem fremden Server, nicht zum Server dieser Seite. Tritt nur bei, wenn du dem Absender vertraust: Ein fremder Server sieht alle Spielzüge.';

  @override
  String get pairingSeatTaken =>
      'Platz belegt: In diesem Spiel spielt schon jemand. Nur wer zuerst beigetreten ist, kann wieder einsteigen.';

  @override
  String get qrScanButton => 'QR-Code scannen';

  @override
  String get qrScanHint =>
      'Richte die Kamera auf den QR-Code des anderen Geräts.';

  @override
  String get qrScanNotKlunki =>
      'Kein Klunki-Code. Scanne den QR-Code, den das andere Gerät bei seinem Raum zeigt.';

  @override
  String get qrScanTorchOn => 'Licht einschalten';

  @override
  String get qrScanTorchOff => 'Licht ausschalten';

  @override
  String get qrScanPermissionDenied => 'Klunki darf die Kamera nicht benutzen.';

  @override
  String get qrScanPermissionHint =>
      'Du kannst den Kamerazugriff für Klunki in den Einstellungen des Geräts erlauben.';

  @override
  String get qrScanUnavailable => 'Die Kamera ist nicht verfügbar.';

  @override
  String get qrScanTypeInstead => 'Code eintippen';

  @override
  String get relayChange => 'ändern';

  @override
  String get relayNotSet => 'Kein Server eingerichtet – Adresse eingeben';

  @override
  String relayUseDefault(String address) {
    return 'Standard: $address';
  }

  @override
  String get relaySave => 'Übernehmen';

  @override
  String get relayClubCodeLabel => 'Clubcode';

  @override
  String get relayClubCodeHelper =>
      'Wird nur für diesen Server gespeichert. Der Clubcode kommt nie in Raum-Links oder QR-Codes.';

  @override
  String get relayErrorClubMissing =>
      'Dieser Server braucht einen Clubcode. Frag die Person, die den Server betreibt.';

  @override
  String get relayErrorClubWrong =>
      'Dieser Server kennt den Clubcode nicht. Frag die Person, die den Server betreibt.';

  @override
  String get serverKindLan =>
      'Server im WLAN (ein Rechner, auf dem „klunki relay“ läuft)';

  @override
  String get serverKindInternet => 'Server im Internet';

  @override
  String get serverHelpLink => 'Wie geht das?';

  @override
  String get serverClubCodeRemove => 'Clubcode entfernen';

  @override
  String get serverClubCodeRetry => 'Mit Clubcode versuchen';

  @override
  String get helpTitle => 'So spielt ihr zusammen';

  @override
  String get helpSectionRoomsTitle => 'Mit anderen spielen';

  @override
  String get helpSectionRoomsBody =>
      'Eine Person tippt auf „Raum starten“ und wählt ein Spiel. Klunki zeigt dann einen Raumcode und einen QR-Code.\n\nDie andere Person tippt auf „Raum beitreten“ und scannt den QR-Code oder tippt den Raumcode ein. Schon geht es los.';

  @override
  String get helpSectionWifiTitle => 'Im selben WLAN';

  @override
  String get helpSectionWifiBody =>
      'Hat einer von euch die App? Dann braucht ihr im WLAN keinen Server: Die App ist selbst der Server, auch für Mitspieler im Browser (QR-Code).\n\nGeräte im selben WLAN finden sich von selbst.';

  @override
  String get helpSectionServerTitle => 'Wann braucht ihr einen Server?';

  @override
  String get helpSectionServerBody =>
      'Nur wenn alle im Browser spielen oder wenn ihr nicht im selben WLAN seid. Der Server reicht die Spielzüge zwischen euren Geräten weiter.\n\nKlunki erkennt an der Adresse, was für ein Server es ist: „Server im WLAN“ oder „Server im Internet“.';

  @override
  String get helpSectionOwnServerTitle => 'Eigener Server im WLAN';

  @override
  String get helpSectionOwnServerBody =>
      'Ihr könnt auch einen eigenen Server auf einem Rechner im WLAN laufen lassen. Ein fertiges Programm für Mac, Windows und Linux ist in Vorbereitung. Die Adresse tragt ihr dann in Klunki unter „Erweitert“ bei „ändern“ ein.';

  @override
  String get helpSectionComingTitle => 'Bald einfacher (in Vorbereitung)';

  @override
  String get helpSectionComingBody =>
      'Diese Wege zu einem Server sind in Vorbereitung:\n• Server im Internet für Freundeskreise (mit Cloudflare, kostenlos)\n• Fertiges Programm zum Herunterladen für Mac, Windows und Linux\n• Docker für NAS oder Raspberry Pi\n\nServer im Internet sind meist mit einem Clubcode geschützt.';

  @override
  String get helpSectionClubTitle => 'Was ist ein Clubcode?';

  @override
  String get helpSectionClubBody =>
      'Ein Clubcode ist wie ein Schlüssel für einen Server: Nur wer ihn kennt, kann dort Räume starten oder beitreten. Du bekommst ihn von der Person, die den Server betreibt.\n\nKlunki fragt erst danach, wenn ein Server ihn braucht, und merkt ihn sich für diesen Server.';

  @override
  String get helpSectionDataTitle => 'Was passiert mit meinen Daten?';

  @override
  String get helpSectionDataBody =>
      'Der Server reicht nur die Spielzüge weiter und speichert nichts davon dauerhaft. Spielt ihr direkt im selben WLAN, läuft gar nichts über einen fremden Server.\n\nDer Clubcode bleibt auf deinem Gerät und kommt nie in Raum-Links oder QR-Codes. Beim Server unter „ändern“ kannst du ihn sehen, ändern oder entfernen.';

  @override
  String get joinDirectTitle => 'Direkt mit einem Gerät verbinden';

  @override
  String get joinDirectHelper =>
      'Für ein Gerät, auf dem der Raum direkt läuft (App oder Terminal): seine Adresse (IP) eingeben.';

  @override
  String get shellResign => 'Aufgeben';

  @override
  String get shellResignTitle => 'Wirklich aufgeben?';

  @override
  String shellResignBody(String player) {
    return 'Das Spiel endet für beide – $player gewinnt.';
  }

  @override
  String get shellLeaveTitle => 'Spiel verlassen?';

  @override
  String get shellLeaveBody =>
      'Die Verbindung wird getrennt, das Spiel endet für beide.';

  @override
  String get shellLeave => 'Verlassen';

  @override
  String get shellResignWho =>
      'Wer gibt auf? Die Partie endet sofort, die andere Seite gewinnt.';

  @override
  String shellResignPlayer(String player) {
    return '$player gibt auf';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return '$player hat aufgegeben';
  }

  @override
  String get engineReasonCommonYouResigned => 'Du hast aufgegeben';

  @override
  String get quartettDeckCars => 'Autos';

  @override
  String get quartettDeckTrains => 'Züge';

  @override
  String get quartettDeckRockets => 'Raketen';

  @override
  String get quartettDeckPlanes => 'Flugzeuge';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => 'Shinkansen';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => 'Europas Schnelle';

  @override
  String get quartettSetTrainsE => 'Asien & Amerika';

  @override
  String get quartettSetTrainsF => 'E-Loks';

  @override
  String get quartettSetTrainsG => 'Dampf-Legenden';

  @override
  String get quartettSetTrainsH => 'Güter-Riesen';

  @override
  String get quartettSetRocketsA => 'Mondraketen';

  @override
  String get quartettSetRocketsB => 'Wiederverwendbar';

  @override
  String get quartettSetRocketsC => 'Europa';

  @override
  String get quartettSetRocketsD => 'USA-Klassiker';

  @override
  String get quartettSetRocketsE => 'Russland';

  @override
  String get quartettSetRocketsF => 'China';

  @override
  String get quartettSetRocketsG => 'Japan & Indien';

  @override
  String get quartettSetRocketsH => 'Kleine Träger';

  @override
  String get quartettSetPlanesA => 'Großraumjets';

  @override
  String get quartettSetPlanesB => 'Mittelstrecke';

  @override
  String get quartettSetPlanesC => 'Überschall';

  @override
  String get quartettSetPlanesD => 'Propeller-Klassiker';

  @override
  String get quartettSetPlanesE => 'Frachtriesen';

  @override
  String get quartettSetPlanesF => 'Business & Sport';

  @override
  String get quartettSetPlanesG => 'Pioniere';

  @override
  String get quartettSetPlanesH => 'Rekord-Exoten';

  @override
  String get quartettStatKw => 'Leistung';

  @override
  String get quartettStatLengthM => 'Länge';

  @override
  String get quartettStatMassT => 'Gewicht';

  @override
  String get quartettStatTractiveKn => 'Anfahr­zug­kraft';

  @override
  String get quartettStatHeightM => 'Höhe';

  @override
  String get quartettStatThrustKn => 'Start­schub';

  @override
  String get quartettStatLeoT => 'Nutz­last (LEO)';

  @override
  String get quartettStatLaunchMassT => 'Start­masse';

  @override
  String get quartettStatFlights => 'Starts';

  @override
  String get quartettStatRangeKm => 'Reich­weite';

  @override
  String get quartettStatWingspanM => 'Spann­weite';

  @override
  String get quartettStatMtowT => 'Start­gewicht';

  @override
  String get quartettDeckPickerTitle => 'Kartendeck wählen';

  @override
  String get quartettDeckLabel => 'Kartendeck';

  @override
  String quartettDeckSets(int sets) {
    return '$sets Sets à 4 Karten';
  }

  @override
  String get quartettDeckPlay => 'Spielen';

  @override
  String get quartettGalleryOpen => 'Karten ansehen';

  @override
  String get quartettGalleryTitle => 'Quartett-Karten';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return 'Karte $index von $total';
  }

  @override
  String get quartettGalleryPrevious => 'Vorherige Karte';

  @override
  String get quartettGalleryNext => 'Nächste Karte';

  @override
  String get quartettGalleryTopMenu => 'Top 5 nach Wert';

  @override
  String quartettGalleryTopTitle(String stat) {
    return 'Top 5: $stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return 'Karte $id: $name, Set $set';
  }

  @override
  String get quartettStatBuilt => 'Gebaut';

  @override
  String get quartettStatSuccessPct => 'Erfolgs­quote';

  @override
  String get quartettUnitBuilt => 'Stk.';

  @override
  String quartettPhotoCredit(String author, String license) {
    return 'Foto: $author, $license';
  }

  @override
  String get quartettPhotoCreditTitle => 'Bildnachweis';

  @override
  String get quartettPhotoCreditTooltip => 'Bildnachweis anzeigen';

  @override
  String get quartettPhotoModified => 'Für die App verkleinert.';

  @override
  String get quartettPhotoShareAlike =>
      'Die verkleinerte Fassung steht unter derselben Lizenz.';

  @override
  String get quartettPhotoLicense => 'Lizenz';

  @override
  String get quartettPhotoSource => 'Quelle';

  @override
  String get quartettPhotoClose => 'Schließen';

  @override
  String get quartettWikipediaRead => 'Auf Wikipedia lesen';

  @override
  String get quartettImageCreditsTitle => 'Bildnachweise';

  @override
  String get quartettImageCreditsIntro =>
      'Die Fotos stammen von Wikimedia Commons und stehen unter freien Lizenzen. Sie sind in der App enthalten; nur die Links brauchen Internet.';

  @override
  String get quartettLinkFailed => 'Der Link konnte nicht geöffnet werden.';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return 'Hinweis: Andere Geräte können „$host“ nicht erreichen. Öffne die Seite über die WLAN-Adresse dieses Rechners (z. B. $example) oder seinen .local-Namen (z. B. $mdnsExample), damit Link und QR-Code auf anderen Geräten funktionieren.';
  }

  @override
  String relayLoopbackShort(String host) {
    return '„$host“ ist nur auf diesem Gerät erreichbar – andere Geräte brauchen die WLAN-Adresse oder den .local-Namen des Rechners.';
  }

  @override
  String get loopbackHowTitle => 'Wie finde ich die Adresse?';

  @override
  String get loopbackHowMacSettings =>
      'Systemeinstellungen › WLAN › Details … › IP-Adresse. Oder im Terminal:';

  @override
  String get loopbackHowMacMdns =>
      'Der .local-Name steht unter Systemeinstellungen › Allgemein › Freigaben („Lokaler Hostname“).';

  @override
  String get loopbackHowWindowsSettings =>
      'Einstellungen › Netzwerk und Internet › WLAN › Eigenschaften (IPv4-Adresse). Oder in der Eingabeaufforderung (cmd), „IPv4-Adresse“ des WLAN-Adapters:';

  @override
  String get loopbackHowWindowsMdns =>
      'Der .local-Name ist unter Windows 10/11 <Computername>.local.';

  @override
  String get loopbackHowLinuxTerminal => 'Im Terminal:';

  @override
  String get loopbackHowLinuxSettings =>
      'Oder Einstellungen › Netzwerk › WLAN › Details. Der .local-Name ist <Hostname>.local, wenn Avahi läuft.';

  @override
  String loopbackHowRelay(String command) {
    return 'Tipp: Die Konsole von „$command“ zeigt diese Adressen beim Start an.';
  }

  @override
  String get loopbackHowCopy => 'Befehl kopieren';

  @override
  String get loopbackHowCopied => 'Befehl kopiert';

  @override
  String get goSetupInvalid =>
      'Nur deine vier Reihen unten nehmen Figuren auf.';

  @override
  String get versionMismatchBoth =>
      'Die Spielversionen passen nicht zusammen – bitte beide Apps aktualisieren (Browser: neu laden).';

  @override
  String get versionMismatchUpdateOther =>
      'Die Spielversionen passen nicht zusammen: Das andere Gerät hat eine ältere Version. Bitte dort die App aktualisieren (Browser: neu laden).';

  @override
  String get versionMismatchUpdateThis =>
      'Die Spielversionen passen nicht zusammen: Dieses Gerät hat eine ältere Version. Bitte diese App aktualisieren (Browser: neu laden).';

  @override
  String versionMismatchGuestRefused(String reason) {
    return 'Ein Gerät wollte beitreten, wurde aber abgewiesen: $reason';
  }

  @override
  String menuVersion(String version) {
    return 'Version $version';
  }

  @override
  String aboutBuildDetails(String build, String protocol, String games) {
    return 'Build-Nummer $build · Protokoll $protocol · Spieldaten $games';
  }

  @override
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  ) {
    return '$nameA hat $versionA, $nameB hat $versionB.';
  }

  @override
  String versionMismatchVersionsDevices(String versionA, String versionB) {
    return 'Dieses Gerät hat $versionA, das andere Gerät hat $versionB.';
  }

  @override
  String get aboutTitle => 'Über Klunki';

  @override
  String get aboutPrivacy => 'Datenschutz';

  @override
  String get aboutImpressum => 'Impressum';

  @override
  String get aboutSupport => 'Support';

  @override
  String get aboutLicense =>
      'Klunki ist freie Software unter der GNU AGPL 3.0.';

  @override
  String get aboutSourceCode => 'Quellcode';

  @override
  String get aboutLicenses => 'Open-Source-Lizenzen';

  @override
  String get aboutOpenInBrowser => 'Im Browser öffnen';

  @override
  String get aboutPrivacyOffline =>
      'Diese Fassung ist in der App gespeichert, damit du sie auch ohne Internet lesen kannst. Maßgeblich ist die Seite im Web:';

  @override
  String get menuGameChess => 'Schach';

  @override
  String get menuDescChess =>
      'Der Klassiker: setze den gegnerischen König matt.';

  @override
  String get chessWhite => 'Weiß';

  @override
  String get chessBlack => 'Schwarz';

  @override
  String get chessColorLabel => 'Deine Farbe';

  @override
  String get chessColorRandom => 'Zufällig';

  @override
  String get chessColorHelper => 'Weiß beginnt. Bei „Zufällig“ wird ausgelost.';

  @override
  String get chessYouPlayWhite => 'Du spielst Weiß.';

  @override
  String get chessYouPlayBlack => 'Du spielst Schwarz.';

  @override
  String get chessCheck => 'Schach!';

  @override
  String get chessHintSelect => 'Tippe eine Figur an, um sie zu ziehen.';

  @override
  String get chessHintTarget => 'Tippe ein markiertes Feld an.';

  @override
  String get chessPromotionTitle => 'Bauer umwandeln in …';

  @override
  String get chessFlipBoard => 'Brett drehen';

  @override
  String get chessAutoFlip => 'Brett zur Seite am Zug drehen';

  @override
  String chessSquareEmpty(String square) {
    return '$square: leer';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square: $piece ($side)';
  }

  @override
  String get chessPieceKing => 'König';

  @override
  String get chessPieceQueen => 'Dame';

  @override
  String get chessPieceRook => 'Turm';

  @override
  String get chessPieceBishop => 'Läufer';

  @override
  String get chessPieceKnight => 'Springer';

  @override
  String get chessPiecePawn => 'Bauer';

  @override
  String get chessOfferDraw => 'Remis anbieten';

  @override
  String get chessOfferDrawTitle => 'Remis anbieten?';

  @override
  String chessOfferDrawBody(String player) {
    return '$player kann annehmen oder ablehnen. Bei Annahme endet das Spiel unentschieden.';
  }

  @override
  String get chessOfferDrawConfirm => 'Anbieten';

  @override
  String get chessDrawOfferTitle => 'Remis-Angebot';

  @override
  String chessDrawOfferBody(String player) {
    return '$player bietet ein Remis an. Bei Annahme endet das Spiel unentschieden.';
  }

  @override
  String get chessDrawAccept => 'Annehmen';

  @override
  String get chessDrawDecline => 'Ablehnen';

  @override
  String chessHintDrawOffered(String player) {
    return 'Remis angeboten – $player entscheidet.';
  }

  @override
  String chessHintDrawDeclined(String player) {
    return '$player lehnt das Remis ab.';
  }

  @override
  String get chessMoveDrawOffer => 'Remis angeboten';

  @override
  String get chessMoveDrawDecline => 'Remis abgelehnt';

  @override
  String get chessMoveDrawAccept => 'Remis angenommen';

  @override
  String get engineReasonChessDrawAgreed => 'Remis vereinbart';

  @override
  String get engineReasonChessCheckmate => 'Schachmatt';

  @override
  String get engineReasonChessStalemate => 'Patt';

  @override
  String get engineReasonChessInsufficientMaterial =>
      'Zu wenig Material zum Mattsetzen';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves Züge ohne Schlagen oder Bauernzug';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return '$times-mal dieselbe Stellung';
  }

  @override
  String get menuGameWordTiles => 'Wortgewandt';

  @override
  String get menuDescWordTiles => 'Wörter aus Buchstaben legen';

  @override
  String menuPreviewGame(String game) {
    return 'Vorschau: $game';
  }

  @override
  String get wordtilesPlay => 'Legen';

  @override
  String get wordtilesRecall => 'Alle Steine zurücknehmen';

  @override
  String get wordtilesShuffle => 'Steine mischen';

  @override
  String get wordtilesExchange => 'Tauschen';

  @override
  String wordtilesExchangeConfirm(int count) {
    return '$count tauschen';
  }

  @override
  String get wordtilesPass => 'Passen';

  @override
  String get wordtilesZoomIn => 'Vergrößern';

  @override
  String get wordtilesZoomOut => 'Ganzes Brett';

  @override
  String wordtilesBag(int count) {
    return 'Beutel: $count Steine';
  }

  @override
  String wordtilesScore(String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$player: $_temp0';
  }

  @override
  String get wordtilesHintPlace =>
      'Ziehe Steine aufs Brett oder tippe einen Stein und dann ein Feld.';

  @override
  String get wordtilesHintFirst =>
      'Das erste Wort muss über den Stern in der Mitte gehen.';

  @override
  String wordtilesHintZoom(String hint) {
    return '$hint Mit zwei Fingern zoomst du.';
  }

  @override
  String get wordtilesHintSelected => 'Tippe ein freies Feld an.';

  @override
  String get wordtilesHintExchange =>
      'Wähle die Steine, die zurück in den Beutel sollen.';

  @override
  String get wordtilesHintAnswer => 'Nimm das Wort an oder zweifle es an.';

  @override
  String wordtilesExchangeNotNow(int count) {
    return 'Tauschen geht nur, solange mindestens $count Steine im Beutel sind.';
  }

  @override
  String wordtilesPreview(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$words: $_temp0';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$words: $_temp0 (mit $bonus Bonus für alle Steine)';
  }

  @override
  String get wordtilesErrorLine =>
      'Die Steine müssen in einer Reihe oder Spalte liegen.';

  @override
  String get wordtilesErrorGap =>
      'Zwischen den Steinen ist noch ein Feld frei.';

  @override
  String get wordtilesErrorShort =>
      'Das erste Wort braucht mindestens zwei Buchstaben.';

  @override
  String get wordtilesErrorConnect =>
      'Die Steine müssen an ein Wort auf dem Brett anschließen.';

  @override
  String get wordtilesErrorUnknownWord => 'Ein Wort steht nicht im Wörterbuch.';

  @override
  String get wordtilesErrorAnswerFirst =>
      'Nimm zuerst das letzte Wort an oder zweifle es an.';

  @override
  String get wordtilesErrorOther => 'So kannst du die Steine nicht legen.';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$player legte $words für $_temp0.';
  }

  @override
  String get wordtilesAccept => 'Annehmen';

  @override
  String get wordtilesChallenge => 'Anzweifeln';

  @override
  String get wordtilesChallengeTitle => 'Wort anzweifeln?';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return 'Ohne Wörterbuch zählt dein Einwand: $player nimmt die Steine zurück und bekommt keine Punkte. Dann bist du am Zug.';
  }

  @override
  String get wordtilesChallengeBodyDict =>
      'Das Wörterbuch entscheidet. Steht das Wort darin, verlierst du deinen Zug.';

  @override
  String wordtilesEndPending(String player) {
    return '$player hat alle Steine gelegt. Nimmst du an, ist das Spiel aus.';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$words für $_temp0';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Steine getauscht',
      one: '1 Stein getauscht',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => 'gepasst';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return 'angezweifelt: $words zurückgenommen';
  }

  @override
  String get wordtilesMoveChallengeFailed =>
      'angezweifelt, aber die Wörter gelten';

  @override
  String get wordtilesMoveAccept => 'angenommen';

  @override
  String get wordtilesBlankTitle => 'Welchen Buchstaben zeigt der Joker?';

  @override
  String get wordtilesPremiumDoubleLetter => '2B';

  @override
  String get wordtilesPremiumTripleLetter => '3B';

  @override
  String get wordtilesPremiumDoubleWord => '2W';

  @override
  String get wordtilesPremiumTripleWord => '3W';

  @override
  String get wordtilesOptionTiles => 'Buchstaben';

  @override
  String get wordtilesOptionDictionary => 'Wörterbuch prüfen';

  @override
  String get wordtilesOptionDictionaryOn =>
      'Jedes gelegte Wort wird nachgeschlagen. Steht eins nicht drin, entscheidet ihr gemeinsam: zurücknehmen oder trotzdem zulassen.';

  @override
  String get wordtilesOptionDictionaryOff =>
      'Ohne Wörterbuch entscheidet ihr selbst: Ein Wort kann angezweifelt werden.';

  @override
  String get wordtilesOptionsNext => 'Weiter';

  @override
  String get wordtilesDictLoading => 'Wörterbuch wird geladen …';

  @override
  String get wordtilesDictLoadFailed =>
      'Das Wörterbuch konnte nicht geladen werden.';

  @override
  String get wordtilesUnknownTitle => 'Nicht im Wörterbuch';

  @override
  String wordtilesUnknownBody(String words, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '„$words“ stehen nicht im Wörterbuch.',
      one: '„$words“ steht nicht im Wörterbuch.',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesUnknownAsk =>
      'Ihr könnt die Steine zurücknehmen. Seid ihr euch einig, dass es trotzdem zählt, lasst es zu.';

  @override
  String get wordtilesUnknownWithdraw => 'Zurücknehmen';

  @override
  String get wordtilesUnknownAllow => 'Trotzdem zulassen';

  @override
  String wordtilesMovePlaceAllowed(String words, int score, String allowed) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$words für $_temp0 (zugelassen: $allowed)';
  }

  @override
  String get wordtilesBench => 'Bänkchen';

  @override
  String get wordtilesBenchClear => 'Alle Steine vom Bänkchen zurück';

  @override
  String get wordtilesBenchHint =>
      'Zieh Steine hierher und probier Wörter aus.';

  @override
  String get wordtilesCoachBench1 =>
      'Das Bänkchen ist dein Notizzettel: Zieh Steine hierher und probier Wörter aus.';

  @override
  String get wordtilesCoachBench2 =>
      'Hier zählen nur die Punkte der Buchstaben. Ob es ein echtes Wort ist, prüft das Bänkchen nicht.';

  @override
  String get wordtilesCoachBench3 =>
      'Mit diesem Knopf legst du alle Steine zurück. Dein Bänkchen siehst nur du.';

  @override
  String wordtilesCoachStep(int step, int count) {
    return '$step von $count';
  }

  @override
  String get wordtilesCoachNext => 'Weiter';

  @override
  String get wordtilesCoachDone => 'Verstanden';

  @override
  String get wordtilesCoachSkip => 'Überspringen';

  @override
  String get wordtilesPassTitle => 'Passen?';

  @override
  String wordtilesPassBody(int count, int limit) {
    return 'Dein Zug endet ohne Punkte. Züge ohne Punkte in Folge: $count von $limit. Bei $limit ist das Spiel aus.';
  }

  @override
  String get wordtilesBlankScore => 'Der Joker zählt 0 Punkte.';

  @override
  String get wordtilesHelpGoal =>
      'Legt Wörter wie im Kreuzworträtsel. Jeder Buchstabe hat Punkte (die kleine Zahl). Das erste Wort geht über den Stern in der Mitte, jedes weitere schließt an.';

  @override
  String get wordtilesHelpPremium => 'Bonusfelder';

  @override
  String get wordtilesHelpDoubleLetter => 'Buchstabe zählt doppelt';

  @override
  String get wordtilesHelpTripleLetter => 'Buchstabe zählt dreifach';

  @override
  String get wordtilesHelpDoubleWord => 'ganzes Wort zählt doppelt';

  @override
  String get wordtilesHelpTripleWord => 'ganzes Wort zählt dreifach';

  @override
  String get wordtilesHelpPremiumOnce =>
      'Bonusfelder zählen nur in dem Zug, in dem ein Stein darauf gelegt wird.';

  @override
  String wordtilesHelpBingo(int count, int bonus) {
    return 'Alle $count Steine in einem Zug gelegt: $bonus Punkte extra.';
  }

  @override
  String get wordtilesHelpBlank =>
      'Der Joker (leerer Stein) wird zu jedem Buchstaben, den du wählst, zählt aber 0 Punkte. Er zeigt eine kleine 0.';

  @override
  String wordtilesHelpSwap(int count) {
    return 'Tauschen: Steine zurück in den Beutel, neue ziehen. Geht nur, solange mindestens $count Steine im Beutel sind, und kostet den Zug.';
  }

  @override
  String wordtilesHelpPass(int limit) {
    return 'Passen: Du setzt einen Zug aus. Nach $limit Zügen in Folge ohne Punkte ist das Spiel aus.';
  }

  @override
  String get wordtilesHelpDictionary =>
      'Mit „Wörterbuch prüfen“ wird jedes Wort beim Legen nachgeschlagen. Steht eins nicht drin, nehmt ihr die Steine zurück oder lasst es gemeinsam zu: „Trotzdem zulassen“. Zugelassene Wörter stehen im Verlauf.';

  @override
  String get wordtilesHelpChallenge =>
      'Ohne Wörterbuch kann das letzte Wort angezweifelt werden: Dann kommen die Steine zurück und es gibt keine Punkte.';

  @override
  String get wordtilesHelpBench =>
      'Auf dem Bänkchen probierst du Wörter aus. Es zeigt nur die Punkte der Buchstaben, nicht ob es ein Wort ist.';

  @override
  String get wordtilesHelpZoom =>
      'Mit zwei Fingern zoomst du das Brett und schiebst es hin und her. Einen eben gelegten Stein ziehst du einfach woandershin; antippen nimmt ihn zurück.';

  @override
  String get wordtilesHelpEnd =>
      'Das Spiel ist aus, wenn der Beutel leer ist und jemand alle Steine gelegt hat. Die Punkte der übrigen Steine werden abgezogen; wer fertig ist, bekommt sie dazu.';

  @override
  String wordtilesResultRack(String points) {
    return 'Reststeine: $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return 'Bestes Wort: $word ($player, $_temp0)';
  }

  @override
  String wordtilesResultAllowed(String words) {
    return 'Trotzdem zugelassen: $words';
  }

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return 'Alle Steine gelegt, Endstand $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '$turns Züge ohne Punkte, Endstand $a : $b';
  }

  @override
  String get webBetaBadge => 'Beta';

  @override
  String get aboutWebBeta =>
      'Web-Beta – Spiele mit mehreren Geräten gibt es in der App.';

  @override
  String get networkUnavailableWeb =>
      'Im Browser noch nicht verfügbar – mit der App könnt ihr auf mehreren Geräten spielen.';

  @override
  String get appBetaTeaser => 'App-Beta in Vorbereitung.';

  @override
  String get appBetaIos => 'App für iPhone und iPad testen';

  @override
  String get appBetaAndroid => 'App für Android laden';

  @override
  String wordtilesOptionsSummaryDict(String language) {
    return '$language · Wörterbuch prüfen';
  }

  @override
  String wordtilesOptionsSummaryFree(String language) {
    return '$language · ohne Wörterbuch';
  }

  @override
  String wordtilesOpenPlacementJoker(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$player legte $words für $_temp0 (Joker getauscht).';
  }

  @override
  String get wordtilesOptionJoker => 'Joker tauschen';

  @override
  String get wordtilesOptionJokerExplain =>
      'Regelvariante: Wer den Buchstaben hat, für den ein Joker auf dem Brett steht, darf ihn dorthin legen und den Joker nehmen. Danach legt man im selben Zug noch Steine.';

  @override
  String wordtilesOptionsSummaryJoker(String summary) {
    return '$summary · Joker tauschen';
  }

  @override
  String get wordtilesHintJoker =>
      'Ziehe den passenden Buchstaben auf einen Joker auf dem Brett, um den Joker zu nehmen.';

  @override
  String get wordtilesJokerStaged =>
      'Joker genommen. Lege jetzt noch Steine, sonst gilt der Tausch nicht.';

  @override
  String wordtilesMoveJoker(String move) {
    return '$move (Joker getauscht)';
  }

  @override
  String wordtilesUnknownAskNet(String player) {
    return 'Du kannst die Steine zurücknehmen oder $player fragen, ob es trotzdem zählt.';
  }

  @override
  String wordtilesUnknownDeclinedBefore(String player) {
    return '$player hat das schon abgelehnt. Nimm die Steine zurück.';
  }

  @override
  String get wordtilesAllowTitle => 'Trotzdem zulassen?';

  @override
  String wordtilesAllowBody(String player, String words) {
    return '$player möchte „$words“ zulassen – einverstanden?';
  }

  @override
  String get wordtilesAllowAccept => 'Annehmen';

  @override
  String get wordtilesAllowDecline => 'Ablehnen';

  @override
  String wordtilesAllowDeciding(String player) {
    return '$player entscheidet…';
  }

  @override
  String get wordtilesAllowYouDecide => 'Du entscheidest';

  @override
  String wordtilesAllowLine(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return '$player möchte „$words“ zulassen ($_temp0).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '$player lehnt „$words“ ab.';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return 'möchte $words zulassen ($_temp0)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score Punkte',
      one: '$score Punkt',
    );
    return 'einverstanden: $words zählt ($_temp0)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'abgelehnt: $words';
  }

  @override
  String get menuGameMauMau => 'Mau-Mau';

  @override
  String get menuDescMauMau =>
      'Passende Karten ablegen, bis keine mehr übrig ist';

  @override
  String get engineReasonMaumauEmptyHand => 'Alle Karten abgelegt';

  @override
  String get maumauSuitClubs => 'Kreuz';

  @override
  String get maumauSuitSpades => 'Pik';

  @override
  String get maumauSuitHearts => 'Herz';

  @override
  String get maumauSuitDiamonds => 'Karo';

  @override
  String get maumauRankJack => 'Bube';

  @override
  String get maumauRankQueen => 'Dame';

  @override
  String get maumauRankKing => 'König';

  @override
  String get maumauRankAce => 'Ass';

  @override
  String get maumauRankLetterJack => 'B';

  @override
  String get maumauRankLetterQueen => 'D';

  @override
  String get maumauRankLetterKing => 'K';

  @override
  String get maumauRankLetterAce => 'A';

  @override
  String maumauCardName(String suit, String rank) {
    return '$suit $rank';
  }

  @override
  String get maumauOptionsIntro => 'Welche Regeln sollen gelten?';

  @override
  String get maumauOptionsNext => 'Weiter';

  @override
  String get maumauOptionSeven => '7: zwei Karten ziehen';

  @override
  String get maumauOptionSevenExplain =>
      'Nach einer 7 muss der andere 2 Karten ziehen.';

  @override
  String get maumauOptionStack => '7 auf 7';

  @override
  String get maumauOptionStackExplain =>
      'Wer selbst eine 7 hat, legt sie drauf. Dann muss der andere 4 Karten ziehen.';

  @override
  String get maumauOptionEight => '8: aussetzen';

  @override
  String get maumauOptionEightExplain =>
      'Nach einer 8 muss der andere einmal aussetzen.';

  @override
  String get maumauOptionJackInfo =>
      'Bube: passt fast immer. Wer ihn legt, wünscht sich eine Farbe.';

  @override
  String get maumauOptionJackOnJack => 'Bube auf Bube';

  @override
  String get maumauOptionJackOnJackExplain =>
      'Ein Bube darf auch auf einem Buben liegen.';

  @override
  String get maumauOptionAce => 'Ass: noch mal';

  @override
  String get maumauOptionAceExplain =>
      'Wer ein Ass legt, ist gleich noch mal dran.';

  @override
  String get maumauOptionMau => '„Mau!“ sagen';

  @override
  String get maumauOptionMauExplain =>
      'Bei der vorletzten Karte erst „Mau!“ drücken. Wer es vergisst, zieht eine Strafkarte.';

  @override
  String maumauOpponentCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return '$player: $_temp0';
  }

  @override
  String maumauYourCards(int count) {
    return 'Deine Karten ($count)';
  }

  @override
  String maumauStock(int count) {
    return 'Stapel: $count';
  }

  @override
  String maumauStockLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Stapel zum Ziehen, $_temp0';
  }

  @override
  String get maumauDiscard => 'Ablage';

  @override
  String maumauWish(String suit) {
    return 'Wunsch: $suit';
  }

  @override
  String get maumauDraw => 'Karte ziehen';

  @override
  String maumauDrawPenalty(int count) {
    return '$count Karten ziehen';
  }

  @override
  String get maumauKeep => 'Behalten';

  @override
  String get maumauPass => 'Passen';

  @override
  String get maumauMauButton => 'Mau!';

  @override
  String get maumauContinue => 'Weiter';

  @override
  String get maumauPickSuitTitle => 'Welche Farbe wünschst du dir?';

  @override
  String get maumauDrewNoFit => 'Gezogen – die Karte passt leider nicht.';

  @override
  String maumauDrewPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: '1 Karte',
    );
    return 'Du hast $_temp0 gezogen. Neu in deiner Hand:';
  }

  @override
  String get maumauHintPlay => 'Lege eine passende Karte oder ziehe eine.';

  @override
  String maumauHintWish(String suit) {
    return 'Gewünscht ist $suit. Lege so eine Karte oder ziehe eine.';
  }

  @override
  String maumauHintPenalty(int count) {
    return 'Du musst $count Karten ziehen.';
  }

  @override
  String maumauHintPenaltyStack(int count) {
    return 'Lege eine 7 oder ziehe $count Karten.';
  }

  @override
  String get maumauHintDrawn =>
      'Die gezogene Karte passt. Lege sie oder behalte sie.';

  @override
  String get maumauHintPass => 'Nichts mehr zum Ziehen. Du musst passen.';

  @override
  String get maumauHintMau =>
      'Vorletzte Karte: erst „Mau!“ drücken, dann legen.';

  @override
  String maumauLastPlayed(String player, String card) {
    return '$player hat $card gelegt.';
  }

  @override
  String maumauLastPlayedWish(String player, String card, String suit) {
    return '$player hat $card gelegt und wünscht sich $suit.';
  }

  @override
  String maumauLastDrew(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: 'eine Karte',
    );
    return '$player hat $_temp0 gezogen.';
  }

  @override
  String maumauLastDrewPenalty(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Strafkarten',
      one: 'eine Strafkarte',
    );
    return '$player hat $_temp0 gezogen.';
  }

  @override
  String maumauLastKept(String player) {
    return '$player hat eine Karte gezogen und behalten.';
  }

  @override
  String maumauLastPassed(String player) {
    return '$player hat gepasst.';
  }

  @override
  String maumauExtraMau(String player) {
    return '„Mau!“, sagt $player.';
  }

  @override
  String maumauExtraForgotMau(String player) {
    return '$player hat „Mau!“ vergessen und zieht eine Strafkarte.';
  }

  @override
  String maumauExtraPenalty(String player, int count) {
    return '$player muss $count Karten ziehen.';
  }

  @override
  String get coachNext => 'Weiter';

  @override
  String get coachDone => 'Los geht’s!';

  @override
  String get coachSkip => 'Überspringen';

  @override
  String get maumauCoachPlay =>
      'Tippe auf eine passende Karte, um sie zu legen. Passende Karten stehen höher und haben einen Rahmen.';

  @override
  String get maumauCoachDraw =>
      'Passt keine? Dann tippe auf den Stapel und ziehe eine Karte.';

  @override
  String get maumauCoachWin => 'Wer zuerst keine Karten mehr hat, gewinnt.';

  @override
  String get maumauCoachWinMau =>
      'Wer zuerst keine Karten mehr hat, gewinnt. Vor der vorletzten Karte „Mau!“ drücken.';

  @override
  String maumauChainBadge(String sum, int count) {
    return '$sum = $count Karten ziehen';
  }

  @override
  String maumauExtraPenaltyStacked(String player, int count) {
    return 'Die 7er zählen zusammen: $player muss jetzt $count Karten ziehen.';
  }

  @override
  String maumauExtraAgain(String player) {
    return '$player muss aussetzen.';
  }

  @override
  String maumauExtraAce(String player) {
    return '$player ist gleich noch mal dran.';
  }

  @override
  String get maumauExtraReshuffled => 'Die Ablage wurde neu gemischt.';

  @override
  String maumauMovePlay(String card) {
    return 'legt $card';
  }

  @override
  String maumauMovePlayWish(String card, String suit) {
    return 'legt $card, wünscht sich $suit';
  }

  @override
  String maumauMoveDraw(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Karten',
      one: 'eine Karte',
    );
    return 'zieht $_temp0';
  }

  @override
  String get maumauMovePass => 'passt';

  @override
  String get maumauMoveKeep => 'behält die gezogene Karte';

  @override
  String get menuGameMaexchen => 'Mäxchen';

  @override
  String get menuDescMaexchen => 'Würfeln, flunkern, durchschauen';

  @override
  String get engineReasonMaexchenNoLives => 'Keine Leben mehr übrig';

  @override
  String get maexchenOptionLives => 'Leben zu Beginn';

  @override
  String get maexchenOptionDouble => 'Mäxchen doppelt';

  @override
  String get maexchenOptionDoubleExplain =>
      'Alles mit Mäxchen zählt doppelt: Wer ein echtes Mäxchen anzweifelt oder mit einem falschen Mäxchen erwischt wird, verliert 2 Leben.';

  @override
  String get maexchenOptionsNext => 'Weiter';

  @override
  String get maexchenRoll => 'Würfeln';

  @override
  String get maexchenPeek => 'Nachschauen';

  @override
  String get maexchenCover => 'Becher zu';

  @override
  String get maexchenPickTitle => 'Was sagst du an?';

  @override
  String maexchenAnnounce(String value) {
    return '$value ansagen';
  }

  @override
  String get maexchenOrder =>
      'Von klein nach groß: 31, 32 … 65, dann Pasch 11 … 66, dann Mäxchen (21).';

  @override
  String get maexchenBelieve => 'Glauben';

  @override
  String get maexchenDoubt => 'Anzweifeln';

  @override
  String get maexchenGiveUp => 'Leben abgeben';

  @override
  String maexchenAnnounced(String player, String value) {
    return '$player sagt $value';
  }

  @override
  String get maexchenNewRound => 'Neue Runde: jede Zahl ist erlaubt';

  @override
  String get maexchenHintRoll =>
      'Tippe auf Würfeln, dann schau heimlich unter den Becher.';

  @override
  String maexchenHintBelieved(String value) {
    return 'Du glaubst $value. Würfle und sag mehr als $value an.';
  }

  @override
  String get maexchenHintAnnounceFirst =>
      'Schau heimlich nach und sag eine Zahl an. Flunkern ist erlaubt!';

  @override
  String maexchenHintAnnounceHigher(String value) {
    return 'Sag mehr als $value an. Flunkern ist erlaubt!';
  }

  @override
  String maexchenHintRespond(String player, String value) {
    return '$player sagt $value. Glaubst du das?';
  }

  @override
  String maexchenHintRespondMaexchen(String player) {
    return '$player sagt Mäxchen! Höher geht es nicht: anzweifeln oder ein Leben abgeben?';
  }

  @override
  String maexchenUnderCup(String value) {
    return 'Unter dem Becher: $value';
  }

  @override
  String maexchenVerdictBluff(String player) {
    return 'Geflunkert! $player verliert ein Leben.';
  }

  @override
  String maexchenVerdictTrue(String player) {
    return 'Stimmt! $player verliert ein Leben.';
  }

  @override
  String maexchenVerdictTrueTwo(String player) {
    return 'Echtes Mäxchen! $player verliert 2 Leben.';
  }

  @override
  String maexchenVerdictBluffTwo(String player) {
    return 'Falsches Mäxchen! $player verliert 2 Leben.';
  }

  @override
  String maexchenVerdictGaveUp(String player) {
    return '$player gibt ein Leben ab. Der Becher bleibt zu.';
  }

  @override
  String maexchenLivesOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Leben',
      one: '1 Leben',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenRoundLabel(int round) {
    return 'Runde $round';
  }

  @override
  String get maexchenMoveRoll => 'würfelt';

  @override
  String maexchenMoveAnnounce(String value) {
    return 'sagt $value';
  }

  @override
  String get maexchenMoveBelieve => 'glaubt es';

  @override
  String get maexchenMoveDoubt => 'zweifelt an';

  @override
  String get maexchenMoveGiveUp => 'gibt ein Leben ab';

  @override
  String get maexchenMaexchenName => 'Mäxchen';

  @override
  String get maexchenMaexchenCall => 'Mäxchen!';

  @override
  String get maexchenAnnouncedLabel => 'Angesagt';

  @override
  String get maexchenPickFirst => 'Wähle eine Zahl';

  @override
  String get maexchenShakeHint => 'oder schüttle das Handy';

  @override
  String get shakeToRollSetting => 'Schütteln zum Würfeln';

  @override
  String get shakeToRollExplain =>
      'Schüttle das Handy wie einen Würfelbecher, statt auf Würfeln zu tippen.';

  @override
  String get confirmMoveSetting => 'Zug bestätigen';

  @override
  String get confirmMoveHelper =>
      'Ein Zug zählt erst nach einem Tipp auf „Ziehen“.';

  @override
  String get confirmMoveCommit => 'Ziehen';

  @override
  String get confirmMoveBack => 'Anders ziehen';

  @override
  String get confirmMoveHint =>
      'Passt der Zug? Tippe auf „Ziehen“ oder „Anders ziehen“.';

  @override
  String get confirmMoveOn => 'Zug bestätigen ist an.';

  @override
  String get confirmMoveOff => 'Zug bestätigen ist aus.';

  @override
  String get rulesButton => 'Regeln';

  @override
  String rulesTitle(String game) {
    return 'Spielregeln: $game';
  }

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spieler',
      one: '1 Spieler',
    );
    return '$_temp0';
  }

  @override
  String playerCountRange(int min, int max) {
    return '$min bis $max Spieler';
  }

  @override
  String get rulesGoal => 'Ziel';

  @override
  String get rulesTurn => 'So läuft ein Zug';

  @override
  String get rulesSpecial => 'Regeln';

  @override
  String get rulesHouse => 'Regelvarianten';

  @override
  String get rulesHouseInGame => 'Regelvarianten in diesem Spiel';

  @override
  String get rulesHouseMenuNote =>
      'So ist es vorgeschlagen. Vor dem Spiel könnt ihr die Regelvarianten ändern.';

  @override
  String get rulesNewHere => 'Neu hier? So geht’s';

  @override
  String get rulesCoachHere => 'Alle Regeln findest du hier.';

  @override
  String get rulesConnect4Goal =>
      'Bring 4 deiner Steine in eine Reihe: waagerecht, senkrecht oder schräg.';

  @override
  String get rulesConnect4Turn =>
      'Tippe auf eine Spalte. Dein Stein fällt nach unten auf den untersten freien Platz.\nDann ist der andere dran.\nSpieler 1 fängt an.';

  @override
  String get rulesConnect4Special =>
      'Das Brett hat 7 Spalten und 6 Reihen.\nIn eine volle Spalte passt kein Stein mehr.\nIst das Brett voll und keiner hat 4 in einer Reihe, ist es unentschieden.';

  @override
  String get rulesMuehleGoal =>
      'Nimm dem anderen so lange Steine weg, bis er nur noch 2 hat. Oder sperr seine Steine ein, sodass er nicht mehr ziehen kann.';

  @override
  String get rulesMuehleTurn =>
      'Jeder hat 9 Steine. Spieler 1 fängt an.\nZuerst setzt ihr abwechselnd je einen Stein auf einen freien Punkt.\nSind alle Steine gesetzt, schiebst du einen Stein entlang einer Linie auf den freien Punkt daneben.\nHast du nur noch 3 Steine, darfst du springen: auf jeden freien Punkt.';

  @override
  String get rulesMuehleMill =>
      '3 Steine in einer Linie sind eine Mühle. Dann nimmst du dem anderen einen Stein weg.';

  @override
  String get rulesMuehleSpecial =>
      'Steine in einer Mühle sind geschützt. Nur wenn alle Steine des anderen in Mühlen stehen, darfst du einen davon nehmen.\nÖffnest du eine Mühle und schließt sie wieder, zählt sie noch einmal.\n50 Züge hintereinander ohne Wegnehmen (beide zusammengezählt): unentschieden.';

  @override
  String get rulesTrumpfGoal =>
      'Gewinne alle Karten. Wer keine Karte mehr hat, verliert.';

  @override
  String get rulesTrumpfTurn =>
      'Jeder bekommt 16 Karten als verdeckten Stapel. Gespielt wird immer die oberste Karte.\nWer dran ist, wählt eine Eigenschaft seiner Karte, zum Beispiel die Geschwindigkeit.\nDer bessere Wert gewinnt die Runde. Meist ist der höhere besser, bei manchen der niedrigere. Das steht auf der Karte.\nWer die Runde gewinnt, legt beide Karten unter seinen Stapel und wählt als Nächstes.\nSpieler 1 wählt zuerst.';

  @override
  String get rulesTrumpfSpecial =>
      'Gleicher Wert: Stechen! Beide Karten kommen in den Topf, und wer gewählt hat, wählt noch einmal. Wer die nächste Runde gewinnt, bekommt auch den ganzen Topf.\nNach 200 Runden gewinnt, wer mehr Karten hat. Bei gleich vielen ist es unentschieden.\nSind beide Stapel leer, ist es auch unentschieden.';

  @override
  String get rulesTrumpfPickLow => 'Mit 3 Karten oder weniger: aussuchen';

  @override
  String get rulesTrumpfPickLowText =>
      'Hast du nur noch 2 oder 3 Karten, siehst du alle und suchst aus, welche du spielst. Wer wählt, sucht zuerst die Karte aus und dann die Eigenschaft. Der andere sucht seine Karte aus, wenn er die Eigenschaft kennt.';

  @override
  String get rulesSetsGoal =>
      'Sammle Quartette: alle 4 Karten einer Gruppe. Wer am Ende mehr Quartette hat, gewinnt.';

  @override
  String get rulesSetsTurn =>
      'Jeder bekommt 8 Karten. Die anderen 16 liegen verdeckt als Stapel.\nFrag den anderen nach einer Karte, die dir fehlt. Von dieser Gruppe musst du schon eine Karte haben.\nHat der andere die Karte, gibt er sie dir, und du darfst noch einmal fragen.\nHat er sie nicht, heißt es Fehlanzeige: Du ziehst eine Karte vom Stapel, und der andere ist dran.\nSpieler 1 fragt zuerst.';

  @override
  String get rulesSetsSpecial =>
      'Hast du alle 4 Karten einer Gruppe, legst du das Quartett sofort ab.\nZiehst du die gefragte Karte vom Stapel, ist trotzdem der andere dran.\nHast du keine Karten mehr, ziehst du eine vom Stapel.\nSind alle 8 Quartette abgelegt, ist das Spiel aus. Bei 4 zu 4 ist es unentschieden.';

  @override
  String get rulesSchiffeGoal =>
      'Versenke alle Schiffe des anderen, bevor er deine versenkt.';

  @override
  String get rulesSchiffeTurn =>
      'Zuerst stellt jeder seine Flotte geheim auf sein Meer mit 10 mal 10 Feldern. Spieler 1 fängt an.\nDann schießt ihr abwechselnd: Tippe auf ein Feld im Meer des anderen.\nAuf jedes Feld schießt du nur einmal.';

  @override
  String get rulesSchiffeMiss => 'Wasser: daneben. Jetzt ist der andere dran.';

  @override
  String get rulesSchiffeHit => 'Treffer! Du darfst noch einmal schießen.';

  @override
  String get rulesSchiffeSunk =>
      'Versenkt: Alle Felder des Schiffs sind getroffen. Du erfährst, welches Schiff es war.';

  @override
  String get rulesSchiffeFleet => 'Die Flotte';

  @override
  String rulesSchiffeShip(int count, String ship, int length) {
    return '$count × $ship ($length Felder)';
  }

  @override
  String get rulesSchiffeSpecial =>
      'Schiffe liegen gerade: waagerecht oder senkrecht.\nSchiffe dürfen sich nicht berühren, auch nicht über Eck.';

  @override
  String get rulesGoGoal =>
      'Erobere die Fahne des anderen. Du gewinnst auch, wenn der andere nicht mehr ziehen kann.';

  @override
  String get rulesGoTurn =>
      'Zuerst stellt jeder seine 40 Figuren geheim auf seine 4 Reihen. Den Rang einer Figur sieht nur ihr Besitzer.\nSpieler 1 stellt zuerst auf und zieht zuerst.\nIn deinem Zug ziehst du eine Figur 1 Feld nach vorne, hinten, links oder rechts. Nie schräg.\nIn die beiden Seen in der Mitte kann keine Figur.';

  @override
  String get rulesGoFightTitle => 'Wer schlägt wen?';

  @override
  String get rulesGoFight =>
      'Ziehst du auf eine Figur des anderen, kämpfen beide. Danach sehen beide, welche Figuren es waren.\nDer höhere Rang gewinnt. Der Verlierer fliegt raus.\nGleicher Rang: Beide fliegen raus.';

  @override
  String get rulesGoPieces => 'Die Figuren';

  @override
  String rulesGoRank(int rank) {
    return 'Rang $rank';
  }

  @override
  String rulesGoCount(int count) {
    return '$count ×';
  }

  @override
  String get rulesGoMarshal =>
      'Die stärkste Figur. Verliert nur gegen den Spion, wenn der angreift.';

  @override
  String get rulesGoScout =>
      'Läuft geradeaus beliebig weit über freie Felder und darf am Ende angreifen. Läuft er mehr als 1 Feld, sehen beide, dass er ein Aufklärer ist.';

  @override
  String get rulesGoMiner =>
      'Entschärft Bomben: Greift er eine an, nimmt er ihren Platz ein.';

  @override
  String get rulesGoSpy =>
      'Die schwächste Figur. Greift der Spion aber den Marschall an, gewinnt er.';

  @override
  String get rulesGoBomb =>
      'Zieht nie. Wer sie angreift, fliegt raus, die Bombe bleibt. Nur der Mineur entschärft sie.';

  @override
  String get rulesGoFlag => 'Zieht nie. Wer sie angreift, gewinnt das Spiel.';

  @override
  String get rulesGoSpecial =>
      'Eine Figur darf höchstens 3-mal hintereinander zwischen denselben zwei Feldern hin und her ziehen.\nHat eine Figur gezogen, weiß der andere: Sie ist keine Bombe und keine Fahne.\n200 Züge hintereinander ohne Kampf: unentschieden. Ebenso, wenn keiner mehr ziehen kann.';

  @override
  String get rulesGoZoom =>
      'Mit zwei Fingern zoomst du das Brett und schiebst es hin und her. Die Lupe zoomt auf deine gewählte Figur; noch einmal antippen zeigt das ganze Brett.';

  @override
  String get rulesChessGoal =>
      'Setz den König des anderen schachmatt: Er wird angegriffen und kann nicht mehr entkommen.';

  @override
  String get rulesChessTurn =>
      'Weiß fängt an, dann zieht ihr abwechselnd.\nTippe auf eine deiner Figuren und dann auf ein Feld. Steht dort eine Figur des anderen, schlägst du sie.\nNur der Springer darf über andere Figuren springen.';

  @override
  String get rulesChessPieces => 'So ziehen die Figuren';

  @override
  String get rulesChessKing => '1 Feld in jede Richtung.';

  @override
  String get rulesChessQueen => 'Beliebig weit gerade oder schräg.';

  @override
  String get rulesChessRook => 'Beliebig weit gerade.';

  @override
  String get rulesChessBishop => 'Beliebig weit schräg.';

  @override
  String get rulesChessKnight =>
      'Wie ein L: 2 Felder gerade, dann 1 zur Seite. Er springt über Figuren.';

  @override
  String get rulesChessPawn =>
      '1 Feld nach vorne, beim ersten Zug auch 2. Er schlägt 1 Feld schräg nach vorne.';

  @override
  String get rulesChessSpecial =>
      'Schach: Dein König wird angegriffen. Du musst ihn sofort retten. Ein Zug, nach dem dein König im Schach steht, geht nicht.\nSchachmatt: Der König steht im Schach und kann nicht gerettet werden. Wer mattsetzt, gewinnt.\nRochade: König und Turm haben noch nicht gezogen, und zwischen ihnen ist alles frei. Der König geht 2 Felder zum Turm, der Turm springt neben ihn. Nicht erlaubt, wenn der König im Schach steht oder über ein angegriffenes Feld gehen müsste.\nEn passant: Zieht ein Bauer 2 Felder und landet neben deinem Bauern, darfst du ihn gleich im nächsten Zug schräg schlagen, als wäre er nur 1 Feld gezogen.\nUmwandlung: Erreicht ein Bauer die letzte Reihe, wird er eine Dame, ein Turm, ein Läufer oder ein Springer. Du suchst aus.';

  @override
  String get rulesChessDrawTitle => 'Unentschieden (Remis)';

  @override
  String get rulesChessDraw =>
      'Patt: Wer dran ist, kann nicht ziehen, steht aber nicht im Schach.\nEs sind zu wenig Figuren übrig, um mattzusetzen.\nDieselbe Stellung kommt zum 3. Mal.\n75 Züge von jedem ohne Schlagen und ohne Bauernzug.\nRemis vereinbart: Wer dran ist, kann Remis anbieten. Der andere nimmt an oder lehnt ab.';

  @override
  String get rulesWordtilesWin =>
      'Wer am Ende die meisten Punkte hat, gewinnt.';

  @override
  String get rulesWordtilesTurn =>
      'Du hast 7 Steine auf deiner Bank.\nLeg 1 bis 7 Steine in eine Reihe oder Spalte, ohne Lücke.\nDu bekommst die Punkte aller neuen Wörter, auch der Wörter quer dazu.\nDanach ziehst du Steine aus dem Beutel, bis du wieder 7 hast.';

  @override
  String get rulesWordtilesChallengeAfter =>
      'Wer angezweifelt hat, ist danach normal dran.';

  @override
  String get rulesWordtilesScoreless =>
      'Endet das Spiel, weil niemand mehr Punkte macht, verliert jeder die Punkte seiner übrigen Steine.';

  @override
  String get rulesMaumauGoal => 'Werde als Erster alle deine Karten los.';

  @override
  String get rulesMaumauTurn =>
      'Es gibt 32 Karten. Jeder bekommt 5, eine liegt offen in der Mitte. Spieler 1 fängt an.\nLeg eine Karte mit gleicher Farbe oder gleichem Wert darauf, zum Beispiel Herz auf Herz oder 9 auf 9.\nPasst keine Karte oder willst du keine legen, ziehst du 1 Karte. Passt sie, darfst du sie legen oder behalten. Passt sie nicht, ist der andere dran.\nIst der Stapel leer, werden die abgelegten Karten gemischt und zum neuen Stapel.';

  @override
  String get rulesMaumauJack =>
      'Bube: passt auf jede Karte außer auf einen Buben. Du wünschst dir eine Farbe. Dann muss diese Farbe kommen oder ein Bube.';

  @override
  String get rulesMaumauSpecial =>
      'Die erste Karte in der Mitte gilt nicht als Sonderkarte.\n9, 10, Dame und König sind normale Karten.\nWer die letzte Karte ablegt, gewinnt – auch mit einer Sonderkarte.';

  @override
  String get rulesMaexchenGoal =>
      'Verlier nicht alle deine Leben. Wer zuletzt noch Leben hat, gewinnt.';

  @override
  String get rulesMaexchenTurn =>
      'Würfle mit 2 Würfeln unter dem Becher. Nur du siehst sie.\nSag einen Wert an. Er muss höher sein als die letzte Ansage. Du darfst auch flunkern!\nDer andere glaubt dir oder zweifelt an.\nGlaubt er dir, würfelt er selbst und muss noch höher ansagen.\nZweifelt er, wird der Becher gehoben. Ist der Wurf kleiner als die Ansage, verliert der Ansager ein Leben. Sonst verliert der Zweifler eins.';

  @override
  String get rulesMaexchenOrderTitle => 'Welcher Wurf ist höher?';

  @override
  String get rulesMaexchenOrder =>
      'Der höhere Würfel zählt zuerst: 3 und 1 ist 31.\nVon klein nach groß: 31, 32, 41, 42, 43 und so weiter bis 65.\nHöher sind die Pasche: 11, 22, 33, 44, 55, 66.\nAm höchsten ist 21: das Mäxchen!';

  @override
  String get rulesMaexchenSpecial =>
      'Die erste Ansage einer Runde darf jeder Wert sein.\nWird ein Mäxchen angesagt, kannst du nicht glauben. Du zweifelst an oder gibst ein Leben ab, ohne nachzuschauen.\nWer ein Leben verliert, fängt die nächste Runde an.\nSchütteln: Statt auf „Würfeln“ zu tippen, kannst du das Handy schütteln wie einen Becher.';

  @override
  String rulesMaexchenLives(int count) {
    return 'Jeder fängt mit $count Leben an.';
  }

  @override
  String get shakeConsentTitle => 'Würfeln durch Schütteln?';

  @override
  String get shakeConsentBody =>
      'Dein Browser fragt gleich, ob Klunki die Bewegung des Handys spüren darf. Das nutzen wir nur zum Würfeln, es bleibt auf dem Gerät.';

  @override
  String get shakeConsentYes => 'Ja, Schütteln erlauben';

  @override
  String get shakeConsentNo => 'Nein, nur tippen';

  @override
  String get wordtilesHelp => 'So geht’s';

  @override
  String get wordtilesHelpJoker =>
      'Joker tauschen (Regelvariante): Hast du den Buchstaben, für den ein Joker auf dem Brett steht, ziehe ihn auf den Joker. Der Joker kommt zu deinen Steinen, und du legst im selben Zug noch Steine (der Joker darf gleich mit). Ohne Legen gilt der Tausch nicht. Das schon gelegte Wort und seine Punkte bleiben.';

  @override
  String get wordtilesHelpJokerOn => 'In diesem Spiel an.';

  @override
  String get wordtilesHelpJokerOff =>
      'In diesem Spiel aus. Ihr könnt sie vor dem Spiel einschalten.';

  @override
  String get menuGameDiceSheet => 'Ausgewürfelt';

  @override
  String get menuDescDiceSheet => 'Fünf Würfel, ein Blatt, bis zu vier';

  @override
  String get engineReasonDicesheetAllFilled => 'Alle Felder sind ausgefüllt';

  @override
  String get playerDefaultNameC => 'Cleo';

  @override
  String get playerDefaultNameD => 'Dani';

  @override
  String get seatPlayerCount => 'Wie viele spielen mit?';

  @override
  String get seatResignWho => 'Wer gibt auf? Die anderen spielen weiter.';

  @override
  String get seatOut => 'aufgegeben';

  @override
  String seatPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points Punkte',
      one: '$points Punkt',
    );
    return '$_temp0';
  }

  @override
  String get seatSharedFirst => 'Gleichstand auf Platz 1!';

  @override
  String get seatReasonOthersResigned => 'Alle anderen haben aufgegeben';

  @override
  String get dicesheetBoxOnes => 'Einser';

  @override
  String get dicesheetBoxTwos => 'Zweier';

  @override
  String get dicesheetBoxThrees => 'Dreier';

  @override
  String get dicesheetBoxFours => 'Vierer';

  @override
  String get dicesheetBoxFives => 'Fünfer';

  @override
  String get dicesheetBoxSixes => 'Sechser';

  @override
  String get dicesheetBoxThreeKind => 'Dreierpasch';

  @override
  String get dicesheetBoxFourKind => 'Viererpasch';

  @override
  String get dicesheetBoxFullHouse => 'Full House';

  @override
  String get dicesheetBoxSmallStraight => 'Kleine Straße';

  @override
  String get dicesheetBoxLargeStraight => 'Große Straße';

  @override
  String get dicesheetBoxFiveKind => 'Fünferpasch';

  @override
  String get dicesheetBoxChance => 'Chance';

  @override
  String dicesheetMoveRoll(String dice) {
    return 'würfelt $dice';
  }

  @override
  String dicesheetMoveRollKeep(String dice, int count) {
    return 'würfelt $dice (behält $count)';
  }

  @override
  String dicesheetMoveScore(String box, int points) {
    return '$box: $points';
  }

  @override
  String dicesheetMoveScoreBonus(String box, int points, int bonus) {
    return '$box: $points (+$bonus)';
  }

  @override
  String dicesheetLastScore(String player, String box, int points) {
    return '$player: $points bei $box.';
  }

  @override
  String get dicesheetHintRoll => 'Tippe auf Würfeln.';

  @override
  String get dicesheetHintKeep =>
      'Tippe Würfel an, die liegen bleiben sollen, und würfle nochmal. Oder wähle ein Feld im Blatt.';

  @override
  String get dicesheetHintPick => 'Wähle ein Feld im Blatt.';

  @override
  String get dicesheetHintJoker =>
      'Fünferpasch als Joker: Trag ihn in eines der erlaubten Felder ein.';

  @override
  String dicesheetRollButton(int count) {
    return 'Würfeln (noch $count)';
  }

  @override
  String get dicesheetPickBox => 'Feld im Blatt wählen';

  @override
  String dicesheetDie(int value) {
    return 'Würfel $value';
  }

  @override
  String dicesheetDieKept(int value) {
    return 'Würfel $value, behalten';
  }

  @override
  String get dicesheetKept => 'behalten';

  @override
  String dicesheetRound(int round, int total) {
    return 'Runde $round/$total';
  }

  @override
  String dicesheetScoreAction(String box, int points) {
    return '$box: $points eintragen';
  }

  @override
  String get dicesheetBonus => 'Bonus';

  @override
  String dicesheetBonusRule(String bonus, int at) {
    return '$bonus ab $at';
  }

  @override
  String get dicesheetExtraFives => 'Extra-Fünfer';

  @override
  String get dicesheetTotal => 'Gesamt';

  @override
  String get dicesheetOptionExtraFives => 'Extra-Fünfer (Regelvariante)';

  @override
  String get dicesheetOptionExtraFivesExplain =>
      'Noch ein Fünferpasch, wenn dort schon 50 stehen: 100 Punkte extra. Er ist dann ein Joker und kommt zuerst ins obere Feld seiner Zahl.';

  @override
  String get rulesDicesheetGoal =>
      'Hol mit fünf Würfeln möglichst viele Punkte auf dein Blatt.\nNach 13 Runden ist jedes Feld voll. Wer die meisten Punkte hat, gewinnt. Bei gleich vielen Punkten teilt ihr euch den Platz.';

  @override
  String get rulesDicesheetTurn =>
      '2 bis 4 spielen an einem Gerät, reihum.\nDu würfelst mit allen fünf Würfeln. Du darfst bis zu dreimal würfeln.\nVor dem 2. und 3. Wurf tippst du die Würfel an, die liegen bleiben sollen. Die anderen würfelst du neu.\nDann trägst du in genau ein leeres Feld deines Blatts ein, was die Würfel dort bringen. Das Blatt zeigt dir, wie viele Punkte jedes Feld bringt.\nPasst nichts, streichst du ein Feld: Es bekommt 0.';

  @override
  String get rulesDicesheetUpperTitle => 'Oben: Einser bis Sechser';

  @override
  String get rulesDicesheetUpper =>
      'Es zählen nur die Würfel mit der Zahl des Felds, zusammengezählt.';

  @override
  String rulesDicesheetBonus(int at, int bonus) {
    return 'Kommst du oben auf $at Punkte oder mehr, gibt es $bonus Punkte Bonus.';
  }

  @override
  String get rulesDicesheetLowerTitle => 'Unten';

  @override
  String get rulesDicesheetThreeKind =>
      'Mindestens 3 gleiche. Alle Augen zählen.';

  @override
  String get rulesDicesheetFourKind =>
      'Mindestens 4 gleiche. Alle Augen zählen.';

  @override
  String rulesDicesheetFullHouse(int points) {
    return '3 gleiche und 2 gleiche: $points Punkte.';
  }

  @override
  String rulesDicesheetSmallStraight(int points) {
    return '4 Zahlen in einer Reihe: $points Punkte.';
  }

  @override
  String rulesDicesheetLargeStraight(int points) {
    return '5 Zahlen in einer Reihe: $points Punkte.';
  }

  @override
  String rulesDicesheetFiveKind(int points) {
    return '5 gleiche: $points Punkte.';
  }

  @override
  String get rulesDicesheetChance => 'Passt immer. Alle Augen zählen.';

  @override
  String get rulesDicesheetSpecial =>
      'Jedes Feld füllst du nur einmal.\nEin Wurf gilt sofort. „Zug zurücknehmen“ nimmt nur den Eintrag ins Blatt zurück, solange noch nicht weitergewürfelt wurde.\nWer aufgibt, ist raus. Die anderen spielen weiter.\nSchütteln: Statt auf „Würfeln“ zu tippen, kannst du das Handy schütteln.';

  @override
  String rulesDicesheetExtraFives(int bonus) {
    return 'Noch ein Fünferpasch, wenn dort schon 50 stehen: $bonus Punkte extra. Ist das Feld Fünferpasch schon gefüllt (auch mit 0), ist ein Fünferpasch ein Joker: zuerst ins obere Feld seiner Zahl; ist das voll, in ein freies unteres Feld mit vollen Punkten; sonst mit 0 in ein oberes Feld.';
  }

  @override
  String get dicesheetStartTitle => 'Wer fängt an?';

  @override
  String get dicesheetStartFirst => 'Erster Spieler';

  @override
  String get dicesheetStartOrder => 'Reihenfolge festlegen';

  @override
  String get dicesheetStartRandom => 'Zufall';

  @override
  String get dicesheetStartFirstExplain =>
      'Wer in der Liste oben steht, fängt an. Dann geht es reihum.';

  @override
  String get dicesheetStartOrderExplain =>
      'Im nächsten Schritt bringt ihr die Namen in eure Reihenfolge.';

  @override
  String get dicesheetStartRandomExplain =>
      'Das Spiel lost aus, wer anfängt. Dann geht es reihum.';

  @override
  String get seatOrderHint =>
      'So wie die Namen hier stehen, seid ihr dran. Mit den Pfeilen änderst du die Reihenfolge.';

  @override
  String get seatMoveUp => 'Nach oben';

  @override
  String get seatMoveDown => 'Nach unten';

  @override
  String get seatRandomStartHint => 'Wer anfängt, lost das Spiel aus.';

  @override
  String seatStarts(String player) {
    return 'Los geht’s: $player fängt an.';
  }

  @override
  String seatStartsRandom(String player) {
    return 'Ausgelost: $player fängt an!';
  }

  @override
  String get rulesDicesheetStart =>
      'Wer anfängt, wählt ihr vor dem Spiel: wer oben in der Liste steht, eure eigene Reihenfolge oder der Zufall.';

  @override
  String get maumauOptionMustPlay => 'Legen, wenn möglich';

  @override
  String get maumauOptionMustPlayExplain =>
      'Ziehen darfst du nur, wenn keine Karte passt. Die Karten nach einer 7 darfst du immer ziehen.';

  @override
  String get maumauHintMustPlay => 'Du hast eine passende Karte – leg sie.';

  @override
  String get maumauHintNoFit => 'Keine Karte passt. Zieh eine vom Stapel.';

  @override
  String get rulesMaumauTurnMustPlay =>
      'Es gibt 32 Karten. Jeder bekommt 5, eine liegt offen in der Mitte. Spieler 1 fängt an.\nLeg eine Karte mit gleicher Farbe oder gleichem Wert darauf, zum Beispiel Herz auf Herz oder 9 auf 9.\nPasst keine Karte, ziehst du 1 Karte. Passt sie, darfst du sie legen oder behalten. Passt sie nicht, ist der andere dran.\nIst der Stapel leer, werden die abgelegten Karten gemischt und zum neuen Stapel.';

  @override
  String get dicesheetBeginnerOption => 'Anfängermodus';

  @override
  String get dicesheetBeginnerExplain =>
      'Das Feld, das gerade gut passt, leuchtet im Blatt. Du darfst trotzdem jedes Feld wählen.';

  @override
  String get dicesheetTipsOption => 'Tipps';

  @override
  String get dicesheetTipsExplain =>
      'Eine Sprechblase sagt, welches Feld gerade gut passt und warum, und welche Würfel du behalten kannst.';

  @override
  String get dicesheetTipLabel => 'Tipp';

  @override
  String get dicesheetTipShow => 'Tipp zeigen';

  @override
  String dicesheetTipBonus(String box, int points, int goal) {
    return 'Tipp: $box – $points Punkte helfen dir beim Bonus ($goal).';
  }

  @override
  String dicesheetTipAllDice(String box, int points) {
    return 'Tipp: $box – alle Würfel zählen, das gibt $points Punkte.';
  }

  @override
  String dicesheetTipFixed(String box, int points) {
    return 'Tipp: $box – das gibt $points Punkte. Nimm sie!';
  }

  @override
  String dicesheetTipPoints(String box, int points) {
    return 'Tipp: $box – das gibt $points Punkte.';
  }

  @override
  String dicesheetTipLeastLoss(String box, int points) {
    return 'Tipp: Kein gutes Feld? $box gibt nur $points Punkte, aber da verlierst du am wenigsten.';
  }

  @override
  String dicesheetTipStrike(String box) {
    return 'Tipp: Kein gutes Feld? Streich $box, da verlierst du am wenigsten.';
  }

  @override
  String dicesheetTipRicher(String box, int points) {
    return '$box gäbe jetzt $points Punkte, ist aber später mehr wert.';
  }

  @override
  String get dicesheetTipSaveChance => 'Spar dir die Chance für später.';

  @override
  String get dicesheetTipOnce =>
      'Jedes Feld gibt es nur einmal – auch die Chance.';

  @override
  String get dicesheetTipKeep =>
      'Tipp: Behalte diese Würfel und würfle die anderen noch mal:';

  @override
  String get dicesheetTipRerollAll =>
      'Tipp: Nichts passt gut zusammen. Würfle alle noch einmal.';

  @override
  String get dicesheetTipStop => 'Super Wurf! Du musst nicht mehr würfeln.';

  @override
  String get dicesheetTipsEnd => 'Tipps ausschalten';

  @override
  String get dicesheetTipsEnded =>
      'Tipps aus. Du kannst sie in den Optionen wieder einschalten.';

  @override
  String dicesheetFreeBoxes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'noch $count Felder frei',
      one: 'noch 1 Feld frei',
    );
    return '$_temp0';
  }

  @override
  String rulesDicesheetOnce(int count) {
    return 'Jedes Feld füllst du nur einmal. $count Felder, $count Runden.';
  }

  @override
  String get rulesDicesheetBeginner =>
      'Anfängermodus (im ersten Spiel an): Das Feld, das gerade gut passt, leuchtet im Blatt. Tipps (in den ersten 5 Spielen an): Eine Sprechblase sagt, warum, und welche Würfel du behalten kannst. Beides kannst du in den Optionen ein- und ausschalten. Du darfst trotzdem jedes Feld wählen.';

  @override
  String dicesheetCoachRoll(int count) {
    return 'Du hast bis zu $count Würfe pro Runde.';
  }

  @override
  String get dicesheetCoachKeep =>
      'Tippe Würfel an, die liegen bleiben sollen.';

  @override
  String get dicesheetCoachSheet =>
      'Dann trägst du den Wurf in ein Feld ein. Die Zahl zeigt, wie viele Punkte es gibt.';

  @override
  String dicesheetCoachOnce(int count) {
    return 'Jedes Feld nur einmal – $count Felder, $count Runden. Am meisten Punkte gewinnt.';
  }

  @override
  String get dicesheetCoachReplay => 'Kurz erklärt';
}

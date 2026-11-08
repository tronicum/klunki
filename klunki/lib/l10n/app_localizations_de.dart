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
  String get shellUndo => 'Zug zurück';

  @override
  String get shellTakeBack => 'Zug zurück';

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
  String get wordtilesHelp => 'So geht’s';

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
      'Hausregel: Wer den Buchstaben hat, für den ein Joker auf dem Brett steht, darf ihn dorthin legen und den Joker nehmen. Danach legt man im selben Zug noch Steine.';

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
  String get wordtilesHelpJoker =>
      'Joker tauschen (Hausregel): Hast du den Buchstaben, für den ein Joker auf dem Brett steht, ziehe ihn auf den Joker. Der Joker kommt zu deinen Steinen, und du legst im selben Zug noch Steine (der Joker darf gleich mit). Ohne Legen gilt der Tausch nicht. Das schon gelegte Wort und seine Punkte bleiben.';

  @override
  String get wordtilesHelpJokerOn => 'In diesem Spiel an.';

  @override
  String get wordtilesHelpJokerOff =>
      'In diesem Spiel aus. Ihr könnt sie vor dem Spiel einschalten.';

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
}

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
  String get menuPlayOverWifi => 'Über WLAN spielen';

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
  String get menuSectionHotSeat => 'Zu zweit an einem Gerät';

  @override
  String get menuSectionNetwork => 'Mit zwei Geräten';

  @override
  String get menuNetworkSubtitle => 'Spiel hosten oder beitreten';

  @override
  String get menuHiddenInfo =>
      'Geheime Karten oder Flotte – ihr reicht das Gerät weiter';

  @override
  String shellToMove(String player) {
    return '$player ist am Zug';
  }

  @override
  String shellHasWon(String player) {
    return '$player hat gewonnen';
  }

  @override
  String shellYourTurn(String mark) {
    return 'Du bist am Zug ($mark)';
  }

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
  String quartettTrumpfYouPickNext(String player) {
    return 'Du wählst als Nächstes ($player)';
  }

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
    return '$ship ausgewählt: tippe ein Feld oder ziehe das Schiff, um es zu verschieben. Nochmal tippen oder „Drehen“ dreht es.';
  }

  @override
  String get schiffeHintReady =>
      'Flotte steht. Tippe ein Schiff, um es zu ändern – oder „Fertig“.';

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
  String get pairingTitle => 'Über WLAN spielen';

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
  String get hotSeatNamesTitle => 'Spielernamen';

  @override
  String hotSeatNameLabel(String mark) {
    return 'Spieler $mark';
  }

  @override
  String get hotSeatNamesHelper =>
      'Optional – leer lassen, um nur X und O zu zeigen.';

  @override
  String get pairingModeHost => 'Hosten';

  @override
  String get pairingModeJoin => 'Beitreten';

  @override
  String get pairingChooseGame => 'Spiel wählen';

  @override
  String get pairingHostGame => 'Spiel hosten';

  @override
  String pairingHostStartFailed(String error) {
    return 'Spiel konnte nicht gestartet werden: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'Nicht automatisch sichtbar – Mitspieler gibt die Adresse ein.';

  @override
  String get pairingNoDiscoveryHost =>
      'Keine automatische Suche auf diesem Gerät – Mitspieler gibt die Adresse ein.';

  @override
  String pairingHosting(String name, String game) {
    return '$name hostet $game';
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
  String get pairingGamesOnNetwork => 'Spiele im Netzwerk';

  @override
  String get pairingNoDiscoveryJoin =>
      'Automatische Suche ist auf diesem Gerät nicht verfügbar. Adresse unten eingeben.';

  @override
  String get pairingBrowseFailed =>
      'Suche im Netzwerk nicht möglich. Adresse unten eingeben.';

  @override
  String get pairingSearching => 'Suche nach Spielen…';

  @override
  String get pairingOtherVersion => 'andere Klunki-Version';

  @override
  String get pairingOrEnterAddress => 'Oder Adresse eingeben';

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
  String pairingStatus(String name, String mark, String peer, String peerMark) {
    return 'Du ($name, $mark) · Gegner: $peer ($peerMark)';
  }

  @override
  String netBarYou(String name) {
    return 'Du ($name)';
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
  String get pairingReconnecting => 'Verbinde neu…';

  @override
  String get pairingReconnect => 'Neu verbinden';

  @override
  String get networkVerificationFailed =>
      'Spielverlauf konnte nicht bestätigt werden';

  @override
  String get pairingReconnectFailed =>
      'Neu verbinden fehlgeschlagen. Ist der Host noch im Spiel?';

  @override
  String get pairingBrowserJoin =>
      'Im Browser beitreten (Adresse eingeben oder Link einfügen):';

  @override
  String get pairingCopyLink => 'Link kopieren';

  @override
  String get pairingLinkCopied => 'Link kopiert';

  @override
  String get webJoinIntro =>
      'Tritt im Browser einem Spiel bei, das ein iPhone, iPad, Android-Gerät oder das Terminal (klunki host) hostet. Der Host zeigt Adresse und Link unter „Im Browser beitreten“.';

  @override
  String get webJoinHttpsWarning =>
      'Im Browser über https kann Klunki nur sichere Relays (wss://) erreichen – nutze die App oder die lokale http-Version.';

  @override
  String get webJoinAddressLabel => 'IP, IP:Port, ws://- oder klunki://-Link';

  @override
  String webJoinAddressHelper(int port) {
    return 'Der Port ist der Browser-Port (WebSocket) des Hosts, ohne Angabe $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Ungültige Adresse. Beispiel: 192.168.1.20, 192.168.1.20:4748 oder klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Tipps: Ist dieses Gerät im selben WLAN wie der Host? Gäste-WLANs blockieren oft Verbindungen zwischen Geräten. Die Seite muss über http:// geöffnet sein, nicht über https://. Auf dem Host muss eine Klunki-Version mit Browser-Unterstützung laufen (sie zeigt „Im Browser beitreten“).';

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
  String goArmyOwn(String mark) {
    return 'Deine Armee ($mark)';
  }

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
  String get relayHostIntro =>
      'Ein zweiter Browser im selben WLAN tritt mit dem Raumcode bei.';

  @override
  String get relayRoomCode => 'Raumcode';

  @override
  String get relayWaitingHint =>
      'Öffne den Link auf dem zweiten Gerät oder scanne den QR-Code. Oder öffne dort Klunki und gib den Raumcode ein.';

  @override
  String relayInfo(String address) {
    return 'Relay: $address';
  }

  @override
  String get relayJoinTitle => 'Mit Raumcode beitreten';

  @override
  String get relayCodeHelper =>
      '5 Zeichen. Der Browser, der das Spiel hostet, zeigt den Code.';

  @override
  String get relayCodeInvalid =>
      'Ungültiger Raumcode: 5 Buchstaben oder Ziffern (ohne 0, O, 1, I, L).';

  @override
  String get relayJoin => 'Raum beitreten';

  @override
  String relayJoining(String code) {
    return 'Trete Raum $code bei…';
  }

  @override
  String get relayAddressLabel => 'Relay-Adresse';

  @override
  String get relayAddressHelper =>
      'Rechner im WLAN, auf dem „klunki relay“ läuft, z. B. 192.168.1.20:4749';

  @override
  String get relayAddressAdvanced => 'Erweitert: Relay-Adresse';

  @override
  String get relayAddressInvalid =>
      'Ungültige Relay-Adresse. Beispiel: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'Kein Raum mit dem Code $code. Stimmt der Code, und wartet der Host noch?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'Raum $code ist schon voll: Dort spielen bereits zwei.';
  }

  @override
  String get relayErrorHostLeft =>
      'Der Host hat den Raum verlassen. Das Spiel ist beendet.';

  @override
  String get relayErrorExpired =>
      'Der Raum ist abgelaufen (10 Minuten ohne Aktivität).';

  @override
  String relayErrorUnreachable(String address) {
    return 'Kein Relay erreichbar unter $address.';
  }

  @override
  String get relayErrorLost => 'Die Verbindung zum Relay ist abgebrochen.';

  @override
  String get relayStartHint =>
      'Browser gegen Browser braucht ein Relay. Starte es auf einem Rechner im WLAN und öffne Klunki über dessen Adresse:';

  @override
  String relayRoomLost(String reason) {
    return '$reason Starte ein neues Spiel.';
  }

  @override
  String relayFromLink(String address) {
    return 'Relay aus Link: $address';
  }

  @override
  String get relayLinkSaveDefault => 'Als Standard speichern';

  @override
  String get relayLinkUseSaved => 'Gespeichertes Relay verwenden';

  @override
  String get relayLinkForeign =>
      'Achtung: Dieser Link führt zu einem fremden Relay, nicht zum Server dieser Seite. Tritt nur bei, wenn du dem Absender vertraust: Ein fremdes Relay sieht alle Spielzüge.';

  @override
  String get pairingSeatTaken =>
      'Platz belegt: In diesem Spiel spielt schon jemand. Nur wer zuerst beigetreten ist, kann wieder einsteigen.';

  @override
  String get webJoinDirectTitle =>
      'Oder mit einem Host-Gerät verbinden (App oder Terminal)';

  @override
  String get qrScanButton => 'QR-Code scannen';

  @override
  String get qrScanHint => 'Richte die Kamera auf den QR-Code des Gastgebers.';

  @override
  String get qrScanNotKlunki =>
      'Kein Klunki-Code. Scanne den QR-Code, den das Spiel beim Hosten zeigt.';

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
  String get relayGroupTitle => 'Über Relay spielen (Raumcode)';

  @override
  String get relayChange => 'ändern';

  @override
  String get relayNotSet => 'Kein Relay eingerichtet – Adresse eingeben';

  @override
  String relayUseDefault(String address) {
    return 'Standard: $address';
  }

  @override
  String get relaySave => 'Übernehmen';

  @override
  String get relayJoinIntro =>
      'Der Raumcode kommt von einem Browser, der „Spiel hosten“ gewählt hat.';

  @override
  String get joinDirectTitle => 'Direkt mit einem Gerät verbinden';

  @override
  String get joinDirectHelper =>
      'Für ein Handy, Tablet oder Terminal, das selbst hostet: Geräte-Adresse (IP) eingeben.';

  @override
  String get shellResign => 'Aufgeben';

  @override
  String get shellResignTitle => 'Wirklich aufgeben?';

  @override
  String shellResignBody(String player) {
    return 'Die Partie endet sofort, $player gewinnt.';
  }

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
  String get menuGameChess => 'Schach';

  @override
  String get menuDescChess =>
      'Der Klassiker: setze den gegnerischen König matt.';

  @override
  String get chessWhite => 'Weiß';

  @override
  String get chessBlack => 'Schwarz';

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
}

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
      'Diese Seite ist über https geöffnet. Von dort erlauben Browser keine ws://-Verbindung ins WLAN. Öffne Klunki über http://.';

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
    return 'Stichlimit erreicht, gleich viele Karten ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Stichlimit erreicht, mehr Karten ($a:$b)';
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
  String get engineReasonGostrategyFlagCaptured => 'Flagge erobert';

  @override
  String get engineReasonGostrategyNoMoves => 'Gegner hat keinen Zug mehr';

  @override
  String get engineReasonGostrategyBothBlocked => 'Keine Seite kann ziehen';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves Züge ohne Kampf';
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
  String get engineStatKmh => 'Höchstgeschwindigkeit';

  @override
  String get engineStatCcm => 'Hubraum';

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
  String get webJoinDirectTitle =>
      'Oder mit einem Host-Gerät verbinden (App oder Terminal)';
}

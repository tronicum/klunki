import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('zh'),
  ];

  /// App name; a brand, not translated.
  ///
  /// In de, this message translates to:
  /// **'Klunki'**
  String get appTitle;

  /// Tooltip of the language icon in the menu's app bar.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get menuLanguage;

  /// Title of the language picker dialog.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get languagePickerTitle;

  /// Picker entry: follow the device language.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Headline above the game list in the menu.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Spiel'**
  String get menuChooseGame;

  /// Menu subtitle of hidden-information games: players hand the device over between turns.
  ///
  /// In de, this message translates to:
  /// **'Gerät weitergeben'**
  String get menuPassDevice;

  /// Menu button that opens the text debug console (debug builds only).
  ///
  /// In de, this message translates to:
  /// **'Debug-Konsole'**
  String get menuDebugConsole;

  /// Game title: connect four in a row (generic name, no brand).
  ///
  /// In de, this message translates to:
  /// **'4 Gewinnt'**
  String get menuGameConnect4;

  /// Game title: Nine Men's Morris (generic name).
  ///
  /// In de, this message translates to:
  /// **'Mühle'**
  String get menuGameMuehle;

  /// Game title: car quartet, compare stats (trumps) variant.
  ///
  /// In de, this message translates to:
  /// **'Quartett (Trumpf)'**
  String get menuGameQuartettTrumpf;

  /// Game title: car quartet, collect complete sets of four by asking for cards.
  ///
  /// In de, this message translates to:
  /// **'Quartett (Sets)'**
  String get menuGameQuartettSets;

  /// Game title: battleship-style game (generic name, no brand).
  ///
  /// In de, this message translates to:
  /// **'Schiffe versenken'**
  String get menuGameSchiffe;

  /// Menu tile one-liner for 4 Gewinnt (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Vier in einer Reihe – waagerecht, senkrecht oder schräg.'**
  String get menuDescConnect4;

  /// Menu tile one-liner for Mühle (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Bilde Dreierreihen und schlage gegnerische Steine.'**
  String get menuDescMuehle;

  /// Menu tile one-liner for Quartett (Trumpf) (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Vergleicht Werte – der bessere Wert gewinnt beide Karten.'**
  String get menuDescQuartettTrumpf;

  /// Menu tile one-liner for Quartett (Sets) (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Erfrage Karten und sammle vollständige Vierer-Sets.'**
  String get menuDescQuartettSets;

  /// Menu tile one-liner for Schiffe versenken (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Versteckt eure Flotten und schießt abwechselnd.'**
  String get menuDescSchiffe;

  /// Menu section header above the hot-seat game tiles (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Zu zweit an einem Gerät'**
  String get menuSectionHotSeat;

  /// Menu: heading of the device-vs-device section with the two room buttons (KLD-098).
  ///
  /// In de, this message translates to:
  /// **'Mit anderen Geräten spielen'**
  String get menuSectionNetwork;

  /// KLD-098: subtitle of the menu button roomStart.
  ///
  /// In de, this message translates to:
  /// **'Andere kommen mit dem Raumcode dazu'**
  String get roomStartSubtitle;

  /// KLD-098: subtitle of the menu button roomJoin.
  ///
  /// In de, this message translates to:
  /// **'Code scannen oder eintippen'**
  String get roomJoinSubtitle;

  /// KLD-098: collapsible section with the technical details (relay address, IP addresses, direct connection).
  ///
  /// In de, this message translates to:
  /// **'Erweitert'**
  String get roomAdvanced;

  /// KLD-098: waiting screen of a room running directly on this device (no room code): how the others get in. Quoted texts are roomJoin and roomNearby.
  ///
  /// In de, this message translates to:
  /// **'Andere tippen auf „Raum beitreten“ und scannen diesen QR-Code. Geräte im selben WLAN finden den Raum auch unter „Räume in der Nähe“.'**
  String get roomDirectWaitingHint;

  /// KLD-098: app, start-a-room screen, under "Erweitert": switch to open the room through the relay (with a room code) instead of directly on this device. Remembered.
  ///
  /// In de, this message translates to:
  /// **'Raum über ein Relay öffnen'**
  String get roomViaRelay;

  /// KLD-098: explanation below roomViaRelay. "klunki relay" is the command and stays as is.
  ///
  /// In de, this message translates to:
  /// **'Mit Raumcode, auch für Mitspieler im Browser. Dafür muss auf einem Rechner „klunki relay“ laufen. Ausgeschaltet läuft der Raum direkt auf diesem Gerät, und Geräte im selben WLAN finden ihn von selbst.'**
  String get roomViaRelayHelper;

  /// KLD-098: join screen: heading above the room code field.
  ///
  /// In de, this message translates to:
  /// **'Raumcode eintippen'**
  String get roomTypeCode;

  /// Tooltip/semantics of the eye-off badge on hidden-information game tiles (secret hand or fleet, the device is passed between turns) (KLD-062).
  ///
  /// In de, this message translates to:
  /// **'Geheime Karten oder Flotte – ihr reicht das Gerät weiter'**
  String get menuHiddenInfo;

  /// Status line: whose turn it is. player = mark X or O.
  ///
  /// In de, this message translates to:
  /// **'{player} ist am Zug'**
  String shellToMove(String player);

  /// Status line after the game ended with a winner.
  ///
  /// In de, this message translates to:
  /// **'{player} hat gewonnen'**
  String shellHasWon(String player);

  /// Status line in a network game when this device is to move; mark = own mark (X, O).
  ///
  /// In de, this message translates to:
  /// **'Du bist am Zug ({mark})'**
  String shellYourTurn(String mark);

  /// Status line in a network game while the other player is to move; player = "Ben (O)".
  ///
  /// In de, this message translates to:
  /// **'Warte auf {player}…'**
  String shellWaitingFor(String player);

  /// Status line in a network game after this device won.
  ///
  /// In de, this message translates to:
  /// **'Du hast gewonnen'**
  String get shellYouHaveWon;

  /// Status line / result dialog title for a draw.
  ///
  /// In de, this message translates to:
  /// **'Unentschieden'**
  String get shellDraw;

  /// Result dialog title.
  ///
  /// In de, this message translates to:
  /// **'{player} gewinnt!'**
  String shellWins(String player);

  /// Result dialog headline in a network game when this device won.
  ///
  /// In de, this message translates to:
  /// **'Du gewinnst!'**
  String get shellYouWin;

  /// Result dialog button: back to the menu.
  ///
  /// In de, this message translates to:
  /// **'Menü'**
  String get shellMenu;

  /// Result dialog button: start a new game of the same kind.
  ///
  /// In de, this message translates to:
  /// **'Nochmal'**
  String get shellPlayAgain;

  /// App bar tooltip: take back the last move (hot-seat).
  ///
  /// In de, this message translates to:
  /// **'Zug zurück'**
  String get shellUndo;

  /// App bar tooltip: restart the game.
  ///
  /// In de, this message translates to:
  /// **'Neues Spiel'**
  String get shellNewGame;

  /// Title of the confirm dialog before restarting a running game.
  ///
  /// In de, this message translates to:
  /// **'Neues Spiel?'**
  String get shellNewGameTitle;

  /// Body of the restart confirm dialog.
  ///
  /// In de, this message translates to:
  /// **'Das laufende Spiel wird abgebrochen.'**
  String get shellNewGameBody;

  /// Dialog button: cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get shellCancel;

  /// Restart confirm dialog button.
  ///
  /// In de, this message translates to:
  /// **'Neu starten'**
  String get shellRestart;

  /// Title of the move history sheet and tooltip of its app bar button.
  ///
  /// In de, this message translates to:
  /// **'Züge'**
  String get shellMoves;

  /// Move history sheet when empty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Züge.'**
  String get shellNoMoves;

  /// One line in the move history: player mark, then the move text.
  ///
  /// In de, this message translates to:
  /// **'{player}: {move}'**
  String shellHistoryEntry(String player, String move);

  /// Handover cover headline (hot-seat, hidden-information games).
  ///
  /// In de, this message translates to:
  /// **'Gib das Gerät an {player} weiter'**
  String shellHandoverPass(String player);

  /// Handover cover button, pressed by the next player.
  ///
  /// In de, this message translates to:
  /// **'Ich bin {player} – weiter'**
  String shellHandoverContinue(String player);

  /// Move history text and accessibility label of a column (1-based).
  ///
  /// In de, this message translates to:
  /// **'Spalte {column}'**
  String connect4Column(int column);

  /// Hint line while the player can drop a piece.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Spalte'**
  String get connect4HintTapColumn;

  /// Mill phase: placing stones.
  ///
  /// In de, this message translates to:
  /// **'Setzen'**
  String get muehlePhasePlacing;

  /// Mill phase: moving stones to adjacent points.
  ///
  /// In de, this message translates to:
  /// **'Ziehen'**
  String get muehlePhaseMoving;

  /// Mill phase: three stones left, may jump anywhere.
  ///
  /// In de, this message translates to:
  /// **'Springen'**
  String get muehlePhaseFlying;

  /// History text (after the player mark): placed a stone.
  ///
  /// In de, this message translates to:
  /// **'setzt auf {point}'**
  String muehleMovePlace(int point);

  /// History text: removed an opponent stone after a mill.
  ///
  /// In de, this message translates to:
  /// **'entfernt Stein auf {point}'**
  String muehleMoveRemove(int point);

  /// History text: moved a stone.
  ///
  /// In de, this message translates to:
  /// **'zieht {from}→{to}'**
  String muehleMoveMove(int from, int to);

  /// History text: jumped a stone (three left).
  ///
  /// In de, this message translates to:
  /// **'springt {from}→{to}'**
  String muehleMoveFly(int from, int to);

  /// Hint after closing a mill. player = opponent mark.
  ///
  /// In de, this message translates to:
  /// **'Mühle! Entferne einen Stein von {player}'**
  String muehleHintRemove(String player);

  /// Hint in the placing phase.
  ///
  /// In de, this message translates to:
  /// **'Setze einen Stein'**
  String get muehleHintPlace;

  /// Hint after selecting a stone.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Ziel (oder tippe den Stein erneut zum Abwählen)'**
  String get muehleHintTarget;

  /// Hint in the flying phase.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Stein zum Springen'**
  String get muehleHintSelectFly;

  /// Hint in the moving phase.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Stein zum Ziehen'**
  String get muehleHintSelectMove;

  /// Accessibility label of an empty board point.
  ///
  /// In de, this message translates to:
  /// **'Punkt {point}, leer'**
  String muehlePointEmpty(int point);

  /// Accessibility label of an occupied board point.
  ///
  /// In de, this message translates to:
  /// **'Punkt {point}, {player}'**
  String muehlePointOwned(int point, String player);

  /// Player panel: stones still in hand and on the board.
  ///
  /// In de, this message translates to:
  /// **'Hand: {hand} · Brett: {board}'**
  String muehleCounts(int hand, int board);

  /// Player panel: opponent stones this player has taken.
  ///
  /// In de, this message translates to:
  /// **'Geschlagen: {count}'**
  String muehleCaptured(int count);

  /// Fallback text if the controller holds a different game (should not happen).
  ///
  /// In de, this message translates to:
  /// **'Kein Quartett-Spiel'**
  String get quartettNoGame;

  /// Button that closes a reveal / feedback panel.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get quartettContinue;

  /// Tooltip on a stat: the higher value wins.
  ///
  /// In de, this message translates to:
  /// **'höher gewinnt'**
  String get quartettHigherWins;

  /// Tooltip on a stat: the lower value wins.
  ///
  /// In de, this message translates to:
  /// **'niedriger gewinnt'**
  String get quartettLowerWins;

  /// Label printed on the back of a card.
  ///
  /// In de, this message translates to:
  /// **'QUARTETT'**
  String get quartettCardBack;

  /// Number of cards.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Karte} other{{count} Karten}}'**
  String quartettCards(int count);

  /// Chip: how many cards a player holds.
  ///
  /// In de, this message translates to:
  /// **'{player}: {count, plural, =1{1 Karte} other{{count} Karten}}'**
  String quartettPlayerCards(String player, int count);

  /// History text: the stat a player picked (stat label comes from the engine).
  ///
  /// In de, this message translates to:
  /// **'wählt {stat}'**
  String quartettTrumpfMovePick(String stat);

  /// Hint while the player chooses a stat.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Eigenschaft deiner Karte'**
  String get quartettTrumpfHintPick;

  /// Chip: cards in the pot after ties.
  ///
  /// In de, this message translates to:
  /// **'Topf: {count, plural, =1{1 Karte} other{{count} Karten}}'**
  String quartettTrumpfPot(int count);

  /// Caption above the opponent's face-down stack.
  ///
  /// In de, this message translates to:
  /// **'Stapel von {player}'**
  String quartettTrumpfOpponentStack(String player);

  /// Caption above the player's own top card.
  ///
  /// In de, this message translates to:
  /// **'Deine Karte ({player})'**
  String quartettTrumpfYourCard(String player);

  /// Reveal headline for a tie: a tie-break (Stechen), the next card decides. Not a "Stich" (Quartett has rounds, KLD-092).
  ///
  /// In de, this message translates to:
  /// **'Gleichstand – Stechen!'**
  String get quartettTrumpfTie;

  /// Reveal headline for a won round (Runde, not Stich, KLD-092).
  ///
  /// In de, this message translates to:
  /// **'{player} gewinnt die Runde'**
  String quartettTrumpfWinsTrick(String player);

  /// Reveal: outcome word above a card.
  ///
  /// In de, this message translates to:
  /// **'gewinnt'**
  String get quartettTrumpfOutcomeWin;

  /// Reveal: outcome word above a card.
  ///
  /// In de, this message translates to:
  /// **'verliert'**
  String get quartettTrumpfOutcomeLose;

  /// Reveal: outcome word above a card.
  ///
  /// In de, this message translates to:
  /// **'Gleichstand'**
  String get quartettTrumpfOutcomeTie;

  /// Reveal: player mark plus outcome word above a card.
  ///
  /// In de, this message translates to:
  /// **'{player} – {outcome}'**
  String quartettTrumpfSideOutcome(String player, String outcome);

  /// Reveal: which stat was picked by whom.
  ///
  /// In de, this message translates to:
  /// **'{player} wählt {stat}'**
  String quartettTrumpfPicked(String player, String stat);

  /// Reveal after a tie (second line under the tie-break headline): the cards go to the pot (count = pot size now) and who picks again.
  ///
  /// In de, this message translates to:
  /// **'Karten in den Topf (jetzt {count}), {player} wählt noch einmal'**
  String quartettTrumpfPotAgain(int count, String player);

  /// Quartett (Trumpf), network: hint while the opponent picks a stat. player = "Ben (O)".
  ///
  /// In de, this message translates to:
  /// **'{player} wählt …'**
  String quartettTrumpfHintWaiting(String player);

  /// Quartett (Trumpf): button on the table that re-opens the result of the previous round. "Vorige Runde", not "Letzte Runde" (that would be the final round).
  ///
  /// In de, this message translates to:
  /// **'Vorige Runde'**
  String get quartettTrumpfLastTrick;

  /// Quartett (Trumpf), network: countdown under the reveal before it moves on by itself.
  ///
  /// In de, this message translates to:
  /// **'Weiter in {seconds} s'**
  String quartettTrumpfGraceSeconds(int seconds);

  /// Quartett (Trumpf), network: the opponent already picked the next stat; its result follows after the countdown.
  ///
  /// In de, this message translates to:
  /// **'{player} hat gewählt: {stat}'**
  String quartettTrumpfQueuedPick(String player, String stat);

  /// Quartett (Trumpf) reveal and network status line: who picks after the round shown, when that is not the picker (the winner). player = mark (reveal) or "Ben (O)" (status line).
  ///
  /// In de, this message translates to:
  /// **'{player} wählt als Nächstes'**
  String quartettTrumpfNextPicker(String player);

  /// Quartett (Trumpf) reveal: the picker won the round (or tied) and picks again. player = mark.
  ///
  /// In de, this message translates to:
  /// **'{player} wählt noch einmal'**
  String quartettTrumpfPicksAgain(String player);

  /// Quartett (Trumpf): the "Weiter" button under a round result, naming who picks next. player = mark.
  ///
  /// In de, this message translates to:
  /// **'Weiter – {player} wählt'**
  String quartettTrumpfContinuePicker(String player);

  /// Quartett (Trumpf), network status line while an older round is still shown: this device's player picks after it. player = mark.
  ///
  /// In de, this message translates to:
  /// **'Du wählst als Nächstes ({player})'**
  String quartettTrumpfYouPickNext(String player);

  /// Quartett (Trumpf), network: badge next to the status line while more rounds are queued behind the one shown (count >= 1).
  ///
  /// In de, this message translates to:
  /// **'noch {count, plural, =1{1 Runde} other{{count} Runden}}'**
  String quartettTrumpfTricksBehind(int count);

  /// Quartett (Trumpf), hot-seat handover cover: why the device goes to that player. player = "Ben (O)" or the mark.
  ///
  /// In de, this message translates to:
  /// **'{player} hat die Runde gewonnen'**
  String quartettTrumpfHandoverReason(String player);

  /// Ask result: the opponent had the card.
  ///
  /// In de, this message translates to:
  /// **'Treffer'**
  String get quartettSetsHit;

  /// Ask result: the opponent did not have the card.
  ///
  /// In de, this message translates to:
  /// **'Fehlanzeige'**
  String get quartettSetsMiss;

  /// History text of an ask. card = card id like B3, result = hit/miss word.
  ///
  /// In de, this message translates to:
  /// **'fragt nach {card}: {result}'**
  String quartettSetsMoveAsk(String card, String result);

  /// History text of an ask that completed a set. set = set name from the engine.
  ///
  /// In de, this message translates to:
  /// **'fragt nach {card}: {result} – Quartett {set}'**
  String quartettSetsMoveAskQuartet(String card, String result, String set);

  /// Hint after a miss, before the handover.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf „Weiter“ und gib das Gerät an {player} weiter'**
  String quartettSetsHintContinue(String player);

  /// Hint while the player can ask.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine fehlende Karte, um danach zu fragen'**
  String get quartettSetsHintAsk;

  /// Shown next to a player without laid-down quartets.
  ///
  /// In de, this message translates to:
  /// **'noch kein Quartett'**
  String get quartettSetsNoQuartet;

  /// Chip: cards left in the draw stock.
  ///
  /// In de, this message translates to:
  /// **'Stapel: {count, plural, =1{1 Karte} other{{count} Karten}}'**
  String quartettSetsStock(int count);

  /// Chip: quartets laid down by X and O.
  ///
  /// In de, this message translates to:
  /// **'Quartette X {a} : {b} O'**
  String quartettSetsScore(int a, int b);

  /// Feedback for a move that arrived from the other device.
  ///
  /// In de, this message translates to:
  /// **'{player} fragt nach {card}: {result}'**
  String quartettSetsOtherAsked(String player, String card, String result);

  /// Feedback after a hit.
  ///
  /// In de, this message translates to:
  /// **'Treffer! {player} gibt dir {card}'**
  String quartettSetsHitGives(String player, String card);

  /// Feedback after a miss with cards left in the stock.
  ///
  /// In de, this message translates to:
  /// **'Fehlanzeige – du ziehst eine Karte'**
  String get quartettSetsMissDraw;

  /// Feedback after a miss with an empty stock.
  ///
  /// In de, this message translates to:
  /// **'Fehlanzeige – der Stapel ist leer'**
  String get quartettSetsMissEmpty;

  /// Feedback after a hit.
  ///
  /// In de, this message translates to:
  /// **'Du darfst noch einmal fragen.'**
  String get quartettSetsAskAgain;

  /// Feedback after a miss.
  ///
  /// In de, this message translates to:
  /// **'{player} hat {card} nicht.'**
  String quartettSetsNotHeld(String player, String card);

  /// Announcement of a completed set. set = set name from the engine.
  ///
  /// In de, this message translates to:
  /// **'Quartett! {set} abgelegt'**
  String quartettSetsQuartetLaid(String set);

  /// Label above the card drawn after a miss.
  ///
  /// In de, this message translates to:
  /// **'Gezogen:'**
  String get quartettSetsDrawn;

  /// Heading above the player's hand.
  ///
  /// In de, this message translates to:
  /// **'Deine Karten ({player}): {count, plural, =1{1 Karte} other{{count} Karten}}'**
  String quartettSetsYourCards(String player, int count);

  /// Per set: cards held out of four and how many are missing.
  ///
  /// In de, this message translates to:
  /// **'{have}/4 – fehlt: {missing}'**
  String quartettSetsProgress(int have, int missing);

  /// Missing card slot that can be tapped to ask for it.
  ///
  /// In de, this message translates to:
  /// **'fragen'**
  String get quartettSetsAskSlot;

  /// Missing card slot that cannot be asked for right now.
  ///
  /// In de, this message translates to:
  /// **'fehlt'**
  String get quartettSetsMissingSlot;

  /// Hint during fleet placement.
  ///
  /// In de, this message translates to:
  /// **'Aufstellung: tippe aufs Meer (oder ziehe und lass los), um das Schiff zu setzen. Schiffe dürfen sich nicht berühren.'**
  String get schiffeHintSetup;

  /// Hint when the game is over.
  ///
  /// In de, this message translates to:
  /// **'Alle Schiffe versenkt.'**
  String get schiffeHintAllSunk;

  /// Hint while the other player is to move.
  ///
  /// In de, this message translates to:
  /// **'Warte auf {player} …'**
  String schiffeHintWaiting(String player);

  /// Hint after a hit (extra shot).
  ///
  /// In de, this message translates to:
  /// **'Treffer! Nochmal – tippe auf ein Feld im Gegner-Meer.'**
  String get schiffeHintExtraShot;

  /// Hint during the battle.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein unbekanntes Feld im Gegner-Meer, um zu schießen.'**
  String get schiffeHintFire;

  /// Cell state / shot result: water (miss).
  ///
  /// In de, this message translates to:
  /// **'Wasser'**
  String get schiffeLookWater;

  /// Cell state: own ship.
  ///
  /// In de, this message translates to:
  /// **'Schiff'**
  String get schiffeLookShip;

  /// Cell state: shot into water.
  ///
  /// In de, this message translates to:
  /// **'Fehlschuss'**
  String get schiffeLookMiss;

  /// Cell state: own ship cell that was hit.
  ///
  /// In de, this message translates to:
  /// **'Schiff getroffen'**
  String get schiffeLookShipHit;

  /// Cell state / shot result: hit.
  ///
  /// In de, this message translates to:
  /// **'Treffer'**
  String get schiffeLookHit;

  /// Cell state / shot result: sunk.
  ///
  /// In de, this message translates to:
  /// **'versenkt'**
  String get schiffeLookSunk;

  /// Cell state: target cell not shot at yet.
  ///
  /// In de, this message translates to:
  /// **'unbekannt'**
  String get schiffeLookUnknown;

  /// Accessibility label of a grid cell: coordinate like E5, then its state.
  ///
  /// In de, this message translates to:
  /// **'{cell} {state}'**
  String schiffeCellLabel(String cell, String state);

  /// Setup title once all ships are placed.
  ///
  /// In de, this message translates to:
  /// **'Flotte komplett'**
  String get schiffeFleetComplete;

  /// Ship name (from the engine) with its length.
  ///
  /// In de, this message translates to:
  /// **'{ship} ({length})'**
  String schiffeShipWithLength(String ship, int length);

  /// Fleet list entry of a placed ship.
  ///
  /// In de, this message translates to:
  /// **'{ship} ({length}) · gesetzt'**
  String schiffeShipPlaced(String ship, int length);

  /// Rotate button: current orientation.
  ///
  /// In de, this message translates to:
  /// **'Horizontal'**
  String get schiffeHorizontal;

  /// Rotate button: current orientation.
  ///
  /// In de, this message translates to:
  /// **'Vertikal'**
  String get schiffeVertical;

  /// Button: place the remaining ships randomly.
  ///
  /// In de, this message translates to:
  /// **'Zufällig'**
  String get schiffeRandom;

  /// Heading of the fleet list during setup.
  ///
  /// In de, this message translates to:
  /// **'Flotte'**
  String get schiffeFleet;

  /// Banner after sinking a ship (extra shot).
  ///
  /// In de, this message translates to:
  /// **'{ship} versenkt – Treffer! Nochmal'**
  String schiffeExtraShotSunk(String ship);

  /// Banner after a hit (extra shot).
  ///
  /// In de, this message translates to:
  /// **'Treffer! Nochmal'**
  String get schiffeExtraShot;

  /// Battle info: ships left on both sides.
  ///
  /// In de, this message translates to:
  /// **'Deine Flotte: {own} · Gegner ({player}): {opponent} Schiffe übrig'**
  String schiffeRemaining(int own, String player, int opponent);

  /// Battle info: the opponent's last shot.
  ///
  /// In de, this message translates to:
  /// **'{player} schoss zuletzt auf {cell}: {result}'**
  String schiffeIncoming(String player, String cell, String result);

  /// Title above the target grid.
  ///
  /// In de, this message translates to:
  /// **'Gegner'**
  String get schiffeTargetSection;

  /// Title above the own grid.
  ///
  /// In de, this message translates to:
  /// **'Dein Meer'**
  String get schiffeOwnSection;

  /// History text: placed one ship (never reveals coordinates).
  ///
  /// In de, this message translates to:
  /// **'platziert ein Schiff'**
  String get schiffeMovePlace;

  /// History text: random placement.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{platziert ein Schiff zufällig} other{platziert {count} Schiffe zufällig}}'**
  String schiffeMoveAutoplace(int count);

  /// History text of a shot.
  ///
  /// In de, this message translates to:
  /// **'schießt auf {cell}: {result}'**
  String schiffeMoveFire(String cell, String result);

  /// KLD-068. Schiffe setup: button that turns the selected ship (or the next ship to place) by 90°.
  ///
  /// In de, this message translates to:
  /// **'Drehen'**
  String get schiffeRotate;

  /// KLD-068. Schiffe setup: screen-reader label of the rotate button; orientation = schiffeHorizontal/schiffeVertical.
  ///
  /// In de, this message translates to:
  /// **'Drehen, aktuell {orientation}'**
  String schiffeRotateSemantics(String orientation);

  /// KLD-068. Schiffe setup: button that takes the selected ship off the board.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get schiffeRemove;

  /// KLD-068. Schiffe setup: tooltip of the remove button (the ship goes back to the harbour/tray).
  ///
  /// In de, this message translates to:
  /// **'Zurück in den Hafen'**
  String get schiffeRemoveTooltip;

  /// KLD-068. Schiffe setup: button that clears the board (all ships back to the harbour).
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get schiffeReset;

  /// KLD-068. Schiffe setup: button that confirms the fleet layout (enabled when all ships are placed).
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get schiffeDone;

  /// KLD-068. Schiffe setup: progress line under the title.
  ///
  /// In de, this message translates to:
  /// **'{placed} von {total} Schiffen gesetzt · {player} stellt auf'**
  String schiffeSetupCount(int placed, int total, String player);

  /// KLD-068. Schiffe setup hint while a placed ship is selected; ship = e.g. "Kreuzer (4)".
  ///
  /// In de, this message translates to:
  /// **'{ship} ausgewählt: tippe ein Feld oder ziehe das Schiff, um es zu verschieben. Nochmal tippen oder „Drehen“ dreht es.'**
  String schiffeHintSelected(String ship);

  /// KLD-068. Schiffe setup hint when all ships are placed.
  ///
  /// In de, this message translates to:
  /// **'Flotte steht. Tippe ein Schiff, um es zu ändern – oder „Fertig“.'**
  String get schiffeHintReady;

  /// KLD-068. Schiffe network setup hint while the opponent still places: the own fleet can be arranged already.
  ///
  /// In de, this message translates to:
  /// **'Du kannst schon aufstellen. „Fertig“ geht, sobald {player} fertig ist.'**
  String schiffeHintEarly(String player);

  /// KLD-068. Schiffe setup: short message after an invalid placement or move.
  ///
  /// In de, this message translates to:
  /// **'Passt dort nicht: Schiffe müssen ganz aufs Meer und dürfen sich nicht berühren.'**
  String get schiffeInvalidPlace;

  /// KLD-068. Schiffe setup: short message after a rotation that does not fit.
  ///
  /// In de, this message translates to:
  /// **'Drehen geht hier nicht – zu wenig Platz.'**
  String get schiffeInvalidRotate;

  /// KLD-068. Schiffe setup: message when the host rejected the submitted layout.
  ///
  /// In de, this message translates to:
  /// **'Die Aufstellung wurde nicht angenommen. Tippe nochmal „Fertig“.'**
  String get schiffeSubmitFailed;

  /// KLD-068. Schiffe setup: screen-reader suffix of the selected ship (cell and harbour labels).
  ///
  /// In de, this message translates to:
  /// **'ausgewählt'**
  String get schiffeSelected;

  /// KLD-068. Schiffe setup: heading of the list of ships (placed and still in the harbour).
  ///
  /// In de, this message translates to:
  /// **'Hafen'**
  String get schiffeHarbour;

  /// Shot result: which ship was sunk (name from the engine).
  ///
  /// In de, this message translates to:
  /// **'{ship} versenkt'**
  String schiffeShipSunk(String ship);

  /// App bar title of the debug console.
  ///
  /// In de, this message translates to:
  /// **'Debug-Konsole'**
  String get debugConsoleTitle;

  /// Tooltip of the undo button; it sends the console command "undo".
  ///
  /// In de, this message translates to:
  /// **'undo'**
  String get debugUndo;

  /// Tooltip of the debug console menu.
  ///
  /// In de, this message translates to:
  /// **'Spiel / Demo'**
  String get debugMenu;

  /// Debug menu entry: start a game (game = engine id).
  ///
  /// In de, this message translates to:
  /// **'Neu: {game}'**
  String debugNewGame(String game);

  /// Debug menu entry.
  ///
  /// In de, this message translates to:
  /// **'Legale Züge'**
  String get debugLegalMoves;

  /// Debug menu entry.
  ///
  /// In de, this message translates to:
  /// **'Zu Ende spielen (zufällig)'**
  String get debugAutoPlay;

  /// Debug menu entry: narrated demo of all games.
  ///
  /// In de, this message translates to:
  /// **'Demo: alle Spiele'**
  String get debugDemo;

  /// Helper text below the device name field.
  ///
  /// In de, this message translates to:
  /// **'So sieht dich dein Mitspieler'**
  String get pairingDeviceNameHelper;

  /// Title of the player name dialog (first visit of "play over Wi-Fi", or the menu person button).
  ///
  /// In de, this message translates to:
  /// **'Wie heißt du?'**
  String get playerNameTitle;

  /// Label of the player name field (pairing screens, name dialog) and tooltip of the menu person button.
  ///
  /// In de, this message translates to:
  /// **'Dein Name'**
  String get playerNameLabel;

  /// A named player with its mark, e.g. "Anna (X)"; used inside other sentences (status line, result, history).
  ///
  /// In de, this message translates to:
  /// **'{name} ({mark})'**
  String playerLabel(String name, String mark);

  /// Hot-seat game: title of the player names dialog and tooltip of its app bar button.
  ///
  /// In de, this message translates to:
  /// **'Spielernamen'**
  String get hotSeatNamesTitle;

  /// Hot-seat player names dialog: label of the name field of one player; mark = X or O.
  ///
  /// In de, this message translates to:
  /// **'Spieler {mark}'**
  String hotSeatNameLabel(String mark);

  /// Hot-seat player names dialog: hint that the names are optional.
  ///
  /// In de, this message translates to:
  /// **'Optional – leer lassen, um nur X und O zu zeigen.'**
  String get hotSeatNamesHelper;

  /// Heading above the game list when starting a room.
  ///
  /// In de, this message translates to:
  /// **'Spiel wählen'**
  String get pairingChooseGame;

  /// KLD-098: menu button, screen title and start button: open a room others join (over the relay or directly on this device). No "host" wording.
  ///
  /// In de, this message translates to:
  /// **'Raum starten'**
  String get roomStart;

  /// KLD-098: the room could not be opened; error = technical message.
  ///
  /// In de, this message translates to:
  /// **'Raum konnte nicht gestartet werden: {error}'**
  String roomStartFailed(String error);

  /// Room on this device: advertising via mDNS failed; others scan the QR code.
  ///
  /// In de, this message translates to:
  /// **'Nicht automatisch sichtbar – andere scannen den QR-Code.'**
  String get pairingNotAdvertised;

  /// Room on this device: no mDNS discovery here; others scan the QR code.
  ///
  /// In de, this message translates to:
  /// **'Keine automatische Suche auf diesem Gerät – andere scannen den QR-Code.'**
  String get pairingNoDiscoveryHost;

  /// KLD-098: a room's headline (waiting screen) and a room found nearby; name = player name of whoever started it, game = game title.
  ///
  /// In de, this message translates to:
  /// **'Raum von {name}: {game}'**
  String roomOfPlayer(String name, String game);

  /// Room on this device: no LAN address found, so no QR code; port = TCP port.
  ///
  /// In de, this message translates to:
  /// **'Keine WLAN-Adresse gefunden. Ist das Gerät mit dem WLAN verbunden? Port: {port}'**
  String pairingNoAddress(int port);

  /// Room on this device, under "Erweitert": heading above the list of IP:port addresses.
  ///
  /// In de, this message translates to:
  /// **'Adressen (zum Eintippen):'**
  String get pairingAddresses;

  /// Subtitle of the first (best guess) address.
  ///
  /// In de, this message translates to:
  /// **'wahrscheinlich WLAN'**
  String get pairingProbablyWifi;

  /// Room waiting screen: status while nobody has joined yet.
  ///
  /// In de, this message translates to:
  /// **'Warte auf Mitspieler…'**
  String get pairingWaitingForGuest;

  /// Button: close the room / stop connecting.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get pairingCancel;

  /// KLD-098: join screen (app): heading above the rooms found on the local Wi-Fi.
  ///
  /// In de, this message translates to:
  /// **'Räume in der Nähe'**
  String get roomNearby;

  /// Join screen: this device has no mDNS discovery. The quoted word is roomAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Automatische Suche ist auf diesem Gerät nicht verfügbar. Scanne den QR-Code oder gib unter „Erweitert“ die Adresse ein.'**
  String get pairingNoDiscoveryJoin;

  /// Join screen: mDNS browsing failed. The quoted word is roomAdvanced.
  ///
  /// In de, this message translates to:
  /// **'Suche im Netzwerk nicht möglich. Scanne den QR-Code oder gib unter „Erweitert“ die Adresse ein.'**
  String get pairingBrowseFailed;

  /// Join screen: no room found nearby yet, still searching.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Räumen…'**
  String get pairingSearching;

  /// Join screen: a room found nearby runs another protocol version and cannot be joined.
  ///
  /// In de, this message translates to:
  /// **'andere Klunki-Version'**
  String get pairingOtherVersion;

  /// Label of the manual address field.
  ///
  /// In de, this message translates to:
  /// **'IP, IP:Port oder klunki://-Link'**
  String get pairingManualLabel;

  /// Error below the manual address field.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Adresse. Beispiel: 192.168.1.20 oder 192.168.1.20:4747'**
  String get pairingInvalidAddress;

  /// Button: connect to the typed address.
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
  String get pairingConnect;

  /// Join in progress; host = host name or address.
  ///
  /// In de, this message translates to:
  /// **'Verbinde mit {host}…'**
  String pairingConnecting(String host);

  /// Join failure reason: no answer within the time limit.
  ///
  /// In de, this message translates to:
  /// **'Zeitüberschreitung'**
  String get pairingTimeout;

  /// Join failed; host = host name or address, error = reason. Followed by pairingJoinHints.
  ///
  /// In de, this message translates to:
  /// **'Verbindung zu {host} fehlgeschlagen ({error}).'**
  String pairingJoinFailed(String host, String error);

  /// Troubleshooting hints shown with every failed join.
  ///
  /// In de, this message translates to:
  /// **'Tipps: Sind beide Geräte im selben WLAN? Gäste-WLANs blockieren oft Verbindungen zwischen Geräten. iOS: Ist „Lokales Netzwerk“ für Klunki erlaubt (Einstellungen › Datenschutz)?'**
  String get pairingJoinHints;

  /// Network game connection bar; name = own player name, mark / peerMark = player marks (X, O), peer = the other player's name.
  ///
  /// In de, this message translates to:
  /// **'Du ({name}, {mark}) · Gegner: {peer} ({peerMark})'**
  String pairingStatus(String name, String mark, String peer, String peerMark);

  /// KLD-067: network connection bar, this device's player next to its coloured token (the token shows the mark); name = own player name.
  ///
  /// In de, this message translates to:
  /// **'Du ({name})'**
  String netBarYou(String name);

  /// KLD-067: network connection bar, the other player next to its coloured token; peer = the other player's name.
  ///
  /// In de, this message translates to:
  /// **'Gegner: {peer}'**
  String netBarOpponent(String peer);

  /// Connection bar: fallback name of the other device.
  ///
  /// In de, this message translates to:
  /// **'Gegner'**
  String get pairingOpponent;

  /// Connection banner: the other player left; peer = their name.
  ///
  /// In de, this message translates to:
  /// **'{peer} hat das Spiel verlassen'**
  String pairingPeerLeft(String peer);

  /// Connection banner: the connection dropped; peer = the other player's name.
  ///
  /// In de, this message translates to:
  /// **'Verbindung zu {peer} unterbrochen'**
  String pairingPeerLost(String peer);

  /// Host's connection banner; reason = pairingPeerLeft or pairingPeerLost.
  ///
  /// In de, this message translates to:
  /// **'{reason}. Warte, bis er wieder beitritt…'**
  String pairingWaitForRejoin(String reason);

  /// Connection banner while the guest reconnects.
  ///
  /// In de, this message translates to:
  /// **'Verbinde neu…'**
  String get pairingReconnecting;

  /// Guest's button in the connection banner.
  ///
  /// In de, this message translates to:
  /// **'Neu verbinden'**
  String get pairingReconnect;

  /// Guest's banner after a hidden-information network game (KLD-064) when the host's revealed secrets do not match its commitments or the replayed game differs from what the host reported.
  ///
  /// In de, this message translates to:
  /// **'Spielverlauf konnte nicht bestätigt werden'**
  String get networkVerificationFailed;

  /// Error below the connection banner when reconnecting failed.
  ///
  /// In de, this message translates to:
  /// **'Neu verbinden fehlgeschlagen. Ist das andere Gerät noch im Spiel?'**
  String get pairingReconnectFailed;

  /// Room on this device, under "Erweitert": heading above the WebSocket address and the klunki:// link for browser guests (the PWA cannot scan the QR code).
  ///
  /// In de, this message translates to:
  /// **'Im Browser beitreten (Adresse eingeben oder Link einfügen):'**
  String get pairingBrowserJoin;

  /// Tooltip of the button that copies the klunki:// join link.
  ///
  /// In de, this message translates to:
  /// **'Link kopieren'**
  String get pairingCopyLink;

  /// Snackbar after copying the join link.
  ///
  /// In de, this message translates to:
  /// **'Link kopiert'**
  String get pairingLinkCopied;

  /// Browser join screen: warning when the page was opened over https (browsers block ws:// from https pages).
  ///
  /// In de, this message translates to:
  /// **'Diese Seite ist über https geöffnet. Von dort erlauben Browser keine ws://-Verbindung ins WLAN. Öffne Klunki über http://.'**
  String get webJoinHttpsWarning;

  /// Browser join screen: label of the address field (IP, IP:port, ws:// URL or klunki:// link).
  ///
  /// In de, this message translates to:
  /// **'IP, IP:Port, ws://- oder klunki://-Link'**
  String get webJoinAddressLabel;

  /// Browser join screen: helper below the address field; port = the default WebSocket port (4748).
  ///
  /// In de, this message translates to:
  /// **'Der Port ist der Browser-Port (WebSocket) des anderen Geräts, ohne Angabe {port}.'**
  String webJoinAddressHelper(int port);

  /// Browser join screen: the typed address could not be parsed.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Adresse. Beispiel: 192.168.1.20, 192.168.1.20:4748 oder klunki://join?h=…'**
  String get webJoinInvalidAddress;

  /// Troubleshooting hints shown with every failed direct browser join (same Wi-Fi, http not https, version with browser support).
  ///
  /// In de, this message translates to:
  /// **'Tipps: Ist dieses Gerät im selben WLAN wie das Gerät mit dem Raum? Gäste-WLANs blockieren oft Verbindungen zwischen Geräten. Die Seite muss über http:// geöffnet sein, nicht über https://. Auf dem anderen Gerät muss eine Klunki-Version mit Browser-Unterstützung laufen (sie zeigt „Im Browser beitreten“).'**
  String get webJoinHints;

  /// Result reason (4 Gewinnt): four markers lined up.
  ///
  /// In de, this message translates to:
  /// **'Vier in einer Reihe'**
  String get engineReasonConnect4FourInARow;

  /// Result reason (4 Gewinnt): draw, no column left.
  ///
  /// In de, this message translates to:
  /// **'Brett voll'**
  String get engineReasonConnect4BoardFull;

  /// Result reason (Mühle): the loser is down to two pieces.
  ///
  /// In de, this message translates to:
  /// **'Gegner hat weniger als 3 Steine'**
  String get engineReasonMuehleFewerThanThree;

  /// Result reason (Mühle): the loser has no legal move.
  ///
  /// In de, this message translates to:
  /// **'Gegner kann nicht mehr ziehen'**
  String get engineReasonMuehleBlocked;

  /// Result reason (Mühle): draw after the move limit without a removal.
  ///
  /// In de, this message translates to:
  /// **'{moves} Züge ohne Schlagen'**
  String engineReasonMuehleNoRemovalLimit(int moves);

  /// Result reason (Quartett Trumpf): draw, the last cards went into the pot.
  ///
  /// In de, this message translates to:
  /// **'Beide Stapel leer'**
  String get engineReasonQuartettBothStacksEmpty;

  /// Result reason (Quartett Trumpf): the winner holds all cards.
  ///
  /// In de, this message translates to:
  /// **'Gegner hat keine Karten mehr'**
  String get engineReasonQuartettAllCards;

  /// Result reason (Quartett Trumpf): draw at the round limit. a/b = stack sizes of X/O.
  ///
  /// In de, this message translates to:
  /// **'Rundenlimit erreicht, gleich viele Karten ({a}:{b})'**
  String engineReasonQuartettTrickLimitEqual(int a, int b);

  /// Result reason (Quartett Trumpf): the larger stack wins at the round limit. a/b = stack sizes of X/O.
  ///
  /// In de, this message translates to:
  /// **'Rundenlimit erreicht, mehr Karten ({a}:{b})'**
  String engineReasonQuartettTrickLimitMoreCards(int a, int b);

  /// Result reason (Quartett Sets): draw with equal quartet counts. a/b = quartets of X/O.
  ///
  /// In de, this message translates to:
  /// **'Alle Quartette abgelegt, {a}:{b}'**
  String engineReasonQuartettAllQuartetsEqual(int a, int b);

  /// Result reason (Quartett Sets): more quartets win. a/b = quartets of X/O.
  ///
  /// In de, this message translates to:
  /// **'Mehr Quartette ({a}:{b})'**
  String engineReasonQuartettMostQuartets(int a, int b);

  /// Result reason (Schiffe versenken): the whole fleet is sunk.
  ///
  /// In de, this message translates to:
  /// **'Alle Schiffe versenkt'**
  String get engineReasonSchiffeAllSunk;

  /// Result reason (GoStrategy): the winner captured the enemy flag.
  ///
  /// In de, this message translates to:
  /// **'Fahne erobert'**
  String get engineReasonGostrategyFlagCaptured;

  /// Result reason (GoStrategy): the loser had no legal move on their turn.
  ///
  /// In de, this message translates to:
  /// **'Gegner hat keinen Zug mehr'**
  String get engineReasonGostrategyNoMoves;

  /// Result reason (GoStrategy): draw, neither player can move.
  ///
  /// In de, this message translates to:
  /// **'Keine Seite kann ziehen'**
  String get engineReasonGostrategyBothBlocked;

  /// Result reason (GoStrategy): draw after the move limit without a fight.
  ///
  /// In de, this message translates to:
  /// **'{moves} Züge ohne Kampf'**
  String engineReasonGostrategyMoveLimit(int moves);

  /// Game title: the hidden-rank capture-the-flag game; "GoStrategy" is the app name of the game (no brand), not translated (KLD-058b).
  ///
  /// In de, this message translates to:
  /// **'GoStrategy'**
  String get menuGameGoStrategy;

  /// Menu tile one-liner for GoStrategy (KLD-058b).
  ///
  /// In de, this message translates to:
  /// **'Verdeckte Armeen – finde und erobere die gegnerische Fahne.'**
  String get menuDescGoStrategy;

  /// GoStrategy piece name (rank 10).
  ///
  /// In de, this message translates to:
  /// **'Marschall'**
  String get goPieceMarshal;

  /// GoStrategy piece name (rank 9).
  ///
  /// In de, this message translates to:
  /// **'General'**
  String get goPieceGeneral;

  /// GoStrategy piece name (rank 8).
  ///
  /// In de, this message translates to:
  /// **'Oberst'**
  String get goPieceColonel;

  /// GoStrategy piece name (rank 7).
  ///
  /// In de, this message translates to:
  /// **'Major'**
  String get goPieceMajor;

  /// GoStrategy piece name (rank 6).
  ///
  /// In de, this message translates to:
  /// **'Hauptmann'**
  String get goPieceCaptain;

  /// GoStrategy piece name (rank 5).
  ///
  /// In de, this message translates to:
  /// **'Leutnant'**
  String get goPieceLieutenant;

  /// GoStrategy piece name (rank 4).
  ///
  /// In de, this message translates to:
  /// **'Feldwebel'**
  String get goPieceSergeant;

  /// GoStrategy piece name (rank 3, defuses bombs).
  ///
  /// In de, this message translates to:
  /// **'Mineur'**
  String get goPieceMiner;

  /// GoStrategy piece name (rank 2, runs any distance in a straight line).
  ///
  /// In de, this message translates to:
  /// **'Aufklärer'**
  String get goPieceScout;

  /// GoStrategy piece name (rank 1, beats the marshal when attacking).
  ///
  /// In de, this message translates to:
  /// **'Spion'**
  String get goPieceSpy;

  /// GoStrategy piece name (immobile, destroys attackers except miners).
  ///
  /// In de, this message translates to:
  /// **'Bombe'**
  String get goPieceBomb;

  /// GoStrategy piece name (immobile, capturing it wins).
  ///
  /// In de, this message translates to:
  /// **'Fahne'**
  String get goPieceFlag;

  /// GoStrategy piece with its rank, e.g. "Hauptmann (6)". rank = digits.
  ///
  /// In de, this message translates to:
  /// **'{piece} ({rank})'**
  String goPieceRank(String piece, String rank);

  /// GoStrategy setup headline. player = mark X or O.
  ///
  /// In de, this message translates to:
  /// **'Stelle deine Armee auf ({player})'**
  String goSetupTitle(String player);

  /// GoStrategy setup hint line.
  ///
  /// In de, this message translates to:
  /// **'Tippe zwei Figuren an oder ziehe eine auf ein anderes Feld deiner vier Reihen, um sie zu tauschen. Dann „Fertig“.'**
  String get goSetupHint;

  /// GoStrategy setup hint after the first piece of a swap was tapped. piece = piece name.
  ///
  /// In de, this message translates to:
  /// **'{piece} gewählt – tippe ein anderes Feld deiner vier Reihen zum Tauschen.'**
  String goSetupSelected(String piece);

  /// GoStrategy setup button: new random setup.
  ///
  /// In de, this message translates to:
  /// **'Neu mischen'**
  String get goSetupShuffle;

  /// GoStrategy setup button: submit the setup.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get goSetupDone;

  /// GoStrategy network: the other player sets up first; this player can already arrange. player = "Anna (X)".
  ///
  /// In de, this message translates to:
  /// **'{player} stellt zuerst auf – du kannst schon vorbereiten.'**
  String goSetupFirst(String player);

  /// GoStrategy network: waiting for the other player's setup. player = "Ben (O)".
  ///
  /// In de, this message translates to:
  /// **'Warte, bis {player} aufgestellt hat …'**
  String goWaitingSetup(String player);

  /// GoStrategy setup: heading of the piece list.
  ///
  /// In de, this message translates to:
  /// **'Figuren'**
  String get goLegendTitle;

  /// GoStrategy setup: short rules legend under the piece list.
  ///
  /// In de, this message translates to:
  /// **'Höherer Rang gewinnt, bei gleichem Rang fallen beide. Der Spion schlägt den Marschall, wenn er angreift. Nur Mineure entschärfen Bomben. Aufklärer ziehen beliebig weit geradeaus. Bomben und Fahne bleiben stehen.'**
  String get goLegendRules;

  /// GoStrategy hint: how to move.
  ///
  /// In de, this message translates to:
  /// **'Tippe eine deiner Figuren an, dann ein markiertes Feld.'**
  String get goHintSelect;

  /// GoStrategy hint with a piece selected. piece = "Hauptmann (6)".
  ///
  /// In de, this message translates to:
  /// **'{piece}: tippe ein markiertes Feld.'**
  String goHintSelected(String piece);

  /// GoStrategy hint: the selected piece has no legal move. piece = "Hauptmann (6)".
  ///
  /// In de, this message translates to:
  /// **'{piece} kann gerade nicht ziehen.'**
  String goHintNoTargets(String piece);

  /// GoStrategy hint while the other player moves. player = "Ben (O)".
  ///
  /// In de, this message translates to:
  /// **'Warte auf {player} …'**
  String goHintWaiting(String player);

  /// GoStrategy: shown near the move limit. moves = digits, moves left without a fight before the draw.
  ///
  /// In de, this message translates to:
  /// **'Noch {moves} Züge ohne Kampf, dann ist es unentschieden.'**
  String goMoveLimit(String moves);

  /// GoStrategy panel heading: the viewer's army. mark = X or O.
  ///
  /// In de, this message translates to:
  /// **'Deine Armee ({mark})'**
  String goArmyOwn(String mark);

  /// GoStrategy panel heading: the opponent's army. player = "Ben (O)" or "O".
  ///
  /// In de, this message translates to:
  /// **'Gegner: {player}'**
  String goArmyEnemy(String player);

  /// GoStrategy panel: pieces left of an army. left/total = digits.
  ///
  /// In de, this message translates to:
  /// **'{left} von {total} übrig'**
  String goArmyLeft(String left, String total);

  /// GoStrategy fight reveal headline. player = "Anna (X)" or "X".
  ///
  /// In de, this message translates to:
  /// **'Angriff von {player}'**
  String goFightBy(String player);

  /// GoStrategy fight outcome. winner/loser = "Hauptmann (6)".
  ///
  /// In de, this message translates to:
  /// **'{winner} schlägt {loser}'**
  String goFightBeats(String winner, String loser);

  /// GoStrategy fight outcome: equal ranks, both pieces removed.
  ///
  /// In de, this message translates to:
  /// **'Beide fallen'**
  String get goFightBoth;

  /// GoStrategy fight outcome: a miner removes a bomb. piece = "Mineur (3)".
  ///
  /// In de, this message translates to:
  /// **'{piece} entschärft die Bombe'**
  String goFightDefused(String piece);

  /// GoStrategy fight outcome: the attacker hits a bomb and is removed. piece = "Hauptmann (6)".
  ///
  /// In de, this message translates to:
  /// **'{piece} läuft auf eine Bombe'**
  String goFightBomb(String piece);

  /// GoStrategy fight outcome: the flag was captured (game won).
  ///
  /// In de, this message translates to:
  /// **'Fahne erobert!'**
  String get goFightFlag;

  /// GoStrategy move history: a player submitted the setup (positions stay secret).
  ///
  /// In de, this message translates to:
  /// **'stellt die Armee auf'**
  String get goMoveSetup;

  /// GoStrategy move history: a quiet move. from/to = squares like a4 (LTR).
  ///
  /// In de, this message translates to:
  /// **'zieht {from}–{to}'**
  String goMoveStep(String from, String to);

  /// GoStrategy move history: an attack. from/to = squares (LTR), result = goFight* text.
  ///
  /// In de, this message translates to:
  /// **'greift an ({from}–{to}): {result}'**
  String goMoveAttack(String from, String to, String result);

  /// GoStrategy board square for screen readers. cell = a1–j10 (LTR), content = goCell* text.
  ///
  /// In de, this message translates to:
  /// **'{cell}: {content}'**
  String goCellLabel(String cell, String content);

  /// GoStrategy square content for screen readers: empty land square.
  ///
  /// In de, this message translates to:
  /// **'frei'**
  String get goCellFree;

  /// GoStrategy square content for screen readers: lake (no piece may enter).
  ///
  /// In de, this message translates to:
  /// **'See'**
  String get goCellLake;

  /// GoStrategy square content: an enemy piece of unknown rank. player = "O" or "Ben (O)".
  ///
  /// In de, this message translates to:
  /// **'verdeckte Figur von {player}'**
  String goCellHidden(String player);

  /// GoStrategy square content: a known piece. piece = "Hauptmann (6)", player = "X".
  ///
  /// In de, this message translates to:
  /// **'{piece} von {player}'**
  String goCellPiece(String piece, String player);

  /// GoStrategy square content suffix: the piece has moved (so it is no bomb or flag).
  ///
  /// In de, this message translates to:
  /// **'{content}, bewegt'**
  String goCellMoved(String content);

  /// Shown instead of a game screen when a network game uses a game the app cannot show yet (e.g. a CLI host plays GoStrategy).
  ///
  /// In de, this message translates to:
  /// **'{game} gibt es in der App noch nicht.'**
  String gameNotInApp(String game);

  /// Quartett set name, set A.
  ///
  /// In de, this message translates to:
  /// **'Supersportwagen'**
  String get engineSetA;

  /// Quartett set name, set B.
  ///
  /// In de, this message translates to:
  /// **'Hypercars'**
  String get engineSetB;

  /// Quartett set name, set C.
  ///
  /// In de, this message translates to:
  /// **'Klassiker'**
  String get engineSetC;

  /// Quartett set name, set D.
  ///
  /// In de, this message translates to:
  /// **'Muscle Cars'**
  String get engineSetD;

  /// Quartett set name, set E.
  ///
  /// In de, this message translates to:
  /// **'Rallye-Legenden'**
  String get engineSetE;

  /// Quartett set name, set F.
  ///
  /// In de, this message translates to:
  /// **'Gran Turismo'**
  String get engineSetF;

  /// Quartett set name, set G.
  ///
  /// In de, this message translates to:
  /// **'Elektro'**
  String get engineSetG;

  /// Quartett set name, set H (small, quick cars).
  ///
  /// In de, this message translates to:
  /// **'Kleine Flitzer'**
  String get engineSetH;

  /// Quartett stat label: engine power.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get engineStatPs;

  /// Quartett stat label: top speed.
  ///
  /// In de, this message translates to:
  /// **'Höchst­geschwindig­keit'**
  String get engineStatKmh;

  /// Quartett stat label: engine displacement.
  ///
  /// In de, this message translates to:
  /// **'Hub­raum'**
  String get engineStatCcm;

  /// Quartett stat label: weight.
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get engineStatKg;

  /// Quartett stat label: acceleration time from 0 to 100 km/h.
  ///
  /// In de, this message translates to:
  /// **'0–100 km/h'**
  String get engineStatSec0to100;

  /// Unit of engine power (metric horsepower).
  ///
  /// In de, this message translates to:
  /// **'PS'**
  String get engineUnitPs;

  /// Unit of top speed.
  ///
  /// In de, this message translates to:
  /// **'km/h'**
  String get engineUnitKmh;

  /// Unit of displacement.
  ///
  /// In de, this message translates to:
  /// **'cm³'**
  String get engineUnitCcm;

  /// Unit of weight.
  ///
  /// In de, this message translates to:
  /// **'kg'**
  String get engineUnitKg;

  /// Unit of the acceleration time (seconds).
  ///
  /// In de, this message translates to:
  /// **'s'**
  String get engineUnitSec;

  /// Schiffe versenken: name of the 5-cell ship.
  ///
  /// In de, this message translates to:
  /// **'Schlachtschiff'**
  String get engineShip5;

  /// Schiffe versenken: name of the 4-cell ship.
  ///
  /// In de, this message translates to:
  /// **'Kreuzer'**
  String get engineShip4;

  /// Schiffe versenken: name of the 3-cell ships.
  ///
  /// In de, this message translates to:
  /// **'Zerstörer'**
  String get engineShip3;

  /// Schiffe versenken: name of the 2-cell ships.
  ///
  /// In de, this message translates to:
  /// **'U-Boot'**
  String get engineShip2;

  /// Schiffe versenken: name of a ship with a length outside the default fleet.
  ///
  /// In de, this message translates to:
  /// **'Schiff'**
  String get engineShipOther;

  /// KLD-098: start-a-room screen (relay room): how the others get in. The quoted text is roomJoin.
  ///
  /// In de, this message translates to:
  /// **'Andere tippen auf „Raum beitreten“ und geben den Raumcode ein.'**
  String get roomStartIntro;

  /// Room code: label above the code on the waiting screen and of the code field.
  ///
  /// In de, this message translates to:
  /// **'Raumcode'**
  String get relayRoomCode;

  /// KLD-098: relay room waiting screen: how the others get in (the quoted text is roomJoin).
  ///
  /// In de, this message translates to:
  /// **'Andere tippen auf „Raum beitreten“ und scannen den QR-Code oder geben den Raumcode ein. Oder sie öffnen den Link.'**
  String get relayWaitingHint;

  /// Small line with the relay address (host:port).
  ///
  /// In de, this message translates to:
  /// **'Relay: {address}'**
  String relayInfo(String address);

  /// KLD-098: helper below the room code field.
  ///
  /// In de, this message translates to:
  /// **'5 Zeichen – das andere Gerät zeigt den Code bei seinem Raum.'**
  String get roomCodeHelper;

  /// Error for a malformed room code.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger Raumcode: 5 Buchstaben oder Ziffern (ohne 0, O, 1, I, L).'**
  String get relayCodeInvalid;

  /// KLD-098: menu button, screen title and join button: join someone else's room (scan the QR code or type the room code).
  ///
  /// In de, this message translates to:
  /// **'Raum beitreten'**
  String get roomJoin;

  /// Progress while joining a room; code is grouped like "K7Q 2M".
  ///
  /// In de, this message translates to:
  /// **'Trete Raum {code} bei…'**
  String relayJoining(String code);

  /// Label of the relay address field.
  ///
  /// In de, this message translates to:
  /// **'Relay-Adresse'**
  String get relayAddressLabel;

  /// Helper under the relay address field.
  ///
  /// In de, this message translates to:
  /// **'Rechner im WLAN, auf dem „klunki relay“ läuft, z. B. 192.168.1.20:4749'**
  String get relayAddressHelper;

  /// Error for a malformed relay address.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Relay-Adresse. Beispiel: 192.168.1.20:4749'**
  String get relayAddressInvalid;

  /// Room-code join: no open room with this code; code = the grouped code.
  ///
  /// In de, this message translates to:
  /// **'Kein Raum mit dem Code {code}. Stimmt der Code, und ist der Raum noch offen?'**
  String relayErrorUnknownCode(String code);

  /// Relay error: the room already has a guest.
  ///
  /// In de, this message translates to:
  /// **'Raum {code} ist schon voll: Dort spielen bereits zwei.'**
  String relayErrorRoomFull(String code);

  /// KLD-098: the room was closed because whoever started it left; the game is over.
  ///
  /// In de, this message translates to:
  /// **'Der Raum wurde geschlossen: Wer ihn gestartet hat, ist gegangen. Das Spiel ist beendet.'**
  String get relayErrorRoomClosed;

  /// Relay: the room expired after 10 idle minutes.
  ///
  /// In de, this message translates to:
  /// **'Der Raum ist abgelaufen (10 Minuten ohne Aktivität).'**
  String get relayErrorExpired;

  /// Relay not reachable; address = host:port or ws:// URL.
  ///
  /// In de, this message translates to:
  /// **'Kein Relay erreichbar unter {address}.'**
  String relayErrorUnreachable(String address);

  /// Relay: the connection to the relay broke (relay stopped, network loss).
  ///
  /// In de, this message translates to:
  /// **'Die Verbindung zum Relay ist abgebrochen.'**
  String get relayErrorLost;

  /// Shown when no relay is reachable, followed by the start command.
  ///
  /// In de, this message translates to:
  /// **'Räume mit Raumcode brauchen ein Relay. Starte es auf einem Rechner im WLAN und öffne Klunki über dessen Adresse:'**
  String get relayStartHint;

  /// Relay room lost while waiting; reason = the relay error text.
  ///
  /// In de, this message translates to:
  /// **'{reason} Starte einen neuen Raum.'**
  String relayRoomLost(String reason);

  /// KLD-075 room join: the relay a ?room= link or scanned room QR names, used for this join only (not saved); address = host:port.
  ///
  /// In de, this message translates to:
  /// **'Relay aus Link: {address}'**
  String relayFromLink(String address);

  /// KLD-075 room join: button that saves the link's relay as the default relay setting.
  ///
  /// In de, this message translates to:
  /// **'Als Standard speichern'**
  String get relayLinkSaveDefault;

  /// KLD-075 room join: button that ignores the link's relay and goes back to the saved/default relay.
  ///
  /// In de, this message translates to:
  /// **'Gespeichertes Relay verwenden'**
  String get relayLinkUseSaved;

  /// KLD-075 PWA: warning when a ?room= link names a relay other than the page's own server (possible phishing/abuse).
  ///
  /// In de, this message translates to:
  /// **'Achtung: Dieser Link führt zu einem fremden Relay, nicht zum Server dieser Seite. Tritt nur bei, wenn du dem Absender vertraust: Ein fremdes Relay sieht alle Spielzüge.'**
  String get relayLinkForeign;

  /// KLD-071: joining failed because the host's seat is taken ("session full"): only the original guest (with its session token) can rejoin.
  ///
  /// In de, this message translates to:
  /// **'Platz belegt: In diesem Spiel spielt schon jemand. Nur wer zuerst beigetreten ist, kann wieder einsteigen.'**
  String get pairingSeatTaken;

  /// Join screen (app): button that opens the camera to scan the other device's QR code; also the scanner screen title.
  ///
  /// In de, this message translates to:
  /// **'QR-Code scannen'**
  String get qrScanButton;

  /// Scanner screen: instruction below the viewfinder.
  ///
  /// In de, this message translates to:
  /// **'Richte die Kamera auf den QR-Code des anderen Geräts.'**
  String get qrScanHint;

  /// Scanner screen: the scanned QR code is not a Klunki join code; scanning continues.
  ///
  /// In de, this message translates to:
  /// **'Kein Klunki-Code. Scanne den QR-Code, den das andere Gerät bei seinem Raum zeigt.'**
  String get qrScanNotKlunki;

  /// Scanner screen: tooltip of the torch button (torch is off).
  ///
  /// In de, this message translates to:
  /// **'Licht einschalten'**
  String get qrScanTorchOn;

  /// Scanner screen: tooltip of the torch button (torch is on).
  ///
  /// In de, this message translates to:
  /// **'Licht ausschalten'**
  String get qrScanTorchOff;

  /// Scanner screen: camera permission was denied.
  ///
  /// In de, this message translates to:
  /// **'Klunki darf die Kamera nicht benutzen.'**
  String get qrScanPermissionDenied;

  /// Scanner screen: how to allow the camera again (system settings).
  ///
  /// In de, this message translates to:
  /// **'Du kannst den Kamerazugriff für Klunki in den Einstellungen des Geräts erlauben.'**
  String get qrScanPermissionHint;

  /// Scanner screen: no camera or the camera could not be started.
  ///
  /// In de, this message translates to:
  /// **'Die Kamera ist nicht verfügbar.'**
  String get qrScanUnavailable;

  /// Scanner screen: button back to the join screen to type the room code instead.
  ///
  /// In de, this message translates to:
  /// **'Code eintippen'**
  String get qrScanTypeInstead;

  /// Relay line: action that opens the relay address dialog (lower case, after "Relay: <address> ·").
  ///
  /// In de, this message translates to:
  /// **'ändern'**
  String get relayChange;

  /// Relay line when no relay address is set (native app before the first relay).
  ///
  /// In de, this message translates to:
  /// **'Kein Relay eingerichtet – Adresse eingeben'**
  String get relayNotSet;

  /// Relay dialog: button back to the default relay (the page's own server); address = host:port.
  ///
  /// In de, this message translates to:
  /// **'Standard: {address}'**
  String relayUseDefault(String address);

  /// Relay dialog: confirm button.
  ///
  /// In de, this message translates to:
  /// **'Übernehmen'**
  String get relaySave;

  /// Join screens, under "Erweitert": heading of the direct connection to a device the room runs on (IP address).
  ///
  /// In de, this message translates to:
  /// **'Direkt mit einem Gerät verbinden'**
  String get joinDirectTitle;

  /// Join screens, under "Erweitert": helper below joinDirectTitle.
  ///
  /// In de, this message translates to:
  /// **'Für ein Gerät, auf dem der Raum direkt läuft (App oder Terminal): seine Adresse (IP) eingeben.'**
  String get joinDirectHelper;

  /// KLD-065 resign: app bar action (tooltip) and the confirm button of the resign dialog.
  ///
  /// In de, this message translates to:
  /// **'Aufgeben'**
  String get shellResign;

  /// KLD-065 resign: title of the confirmation dialog.
  ///
  /// In de, this message translates to:
  /// **'Wirklich aufgeben?'**
  String get shellResignTitle;

  /// KLD-065/KLD-099 resign dialog (network game): the game ends for both devices; player = the opponent's label, e.g. "Anna (X)".
  ///
  /// In de, this message translates to:
  /// **'Das Spiel endet für beide – {player} gewinnt.'**
  String shellResignBody(String player);

  /// KLD-099 leave confirmation: title of the dialog shown on back/leave while a game is running (network, or a hot-seat game under way).
  ///
  /// In de, this message translates to:
  /// **'Spiel verlassen?'**
  String get shellLeaveTitle;

  /// KLD-099 leave confirmation (network game): what leaving does.
  ///
  /// In de, this message translates to:
  /// **'Die Verbindung wird getrennt, das Spiel endet für beide.'**
  String get shellLeaveBody;

  /// KLD-099 leave confirmation: the confirm button.
  ///
  /// In de, this message translates to:
  /// **'Verlassen'**
  String get shellLeave;

  /// KLD-065 resign dialog (hot-seat): asks which of the two players gives up.
  ///
  /// In de, this message translates to:
  /// **'Wer gibt auf? Die Partie endet sofort, die andere Seite gewinnt.'**
  String get shellResignWho;

  /// KLD-065 resign dialog (hot-seat): button for one player; player = label, e.g. "Anna (X)" or "X".
  ///
  /// In de, this message translates to:
  /// **'{player} gibt auf'**
  String shellResignPlayer(String player);

  /// Result reason (any game): a player resigned; player = label, e.g. "Anna (X)" or "X".
  ///
  /// In de, this message translates to:
  /// **'{player} hat aufgegeben'**
  String engineReasonCommonResigned(String player);

  /// Result reason on the device of the player who resigned (network game).
  ///
  /// In de, this message translates to:
  /// **'Du hast aufgegeben'**
  String get engineReasonCommonYouResigned;

  /// KLD-069 Quartett deck name: cars.
  ///
  /// In de, this message translates to:
  /// **'Autos'**
  String get quartettDeckCars;

  /// KLD-069 Quartett deck name: trains.
  ///
  /// In de, this message translates to:
  /// **'Züge'**
  String get quartettDeckTrains;

  /// KLD-069 Quartett deck name: rockets (launch vehicles).
  ///
  /// In de, this message translates to:
  /// **'Raketen'**
  String get quartettDeckRockets;

  /// KLD-069 Quartett deck name: planes.
  ///
  /// In de, this message translates to:
  /// **'Flugzeuge'**
  String get quartettDeckPlanes;

  /// KLD-069 Quartett set name, trains deck, set A: German high-speed trains (brand name, keep).
  ///
  /// In de, this message translates to:
  /// **'ICE'**
  String get quartettSetTrainsA;

  /// KLD-069 Quartett set name, trains deck, set B: Japanese high-speed trains.
  ///
  /// In de, this message translates to:
  /// **'Shinkansen'**
  String get quartettSetTrainsB;

  /// KLD-069 Quartett set name, trains deck, set C: French high-speed trains (brand name, keep).
  ///
  /// In de, this message translates to:
  /// **'TGV'**
  String get quartettSetTrainsC;

  /// KLD-069 Quartett set name, trains deck, set D: European high-speed trains.
  ///
  /// In de, this message translates to:
  /// **'Europas Schnelle'**
  String get quartettSetTrainsD;

  /// KLD-069 Quartett set name, trains deck, set E: High-speed trains from Asia and America.
  ///
  /// In de, this message translates to:
  /// **'Asien & Amerika'**
  String get quartettSetTrainsE;

  /// KLD-069 Quartett set name, trains deck, set F: Electric locomotives.
  ///
  /// In de, this message translates to:
  /// **'E-Loks'**
  String get quartettSetTrainsF;

  /// KLD-069 Quartett set name, trains deck, set G: Famous steam locomotives.
  ///
  /// In de, this message translates to:
  /// **'Dampf-Legenden'**
  String get quartettSetTrainsG;

  /// KLD-069 Quartett set name, trains deck, set H: Heavy freight locomotives.
  ///
  /// In de, this message translates to:
  /// **'Güter-Riesen'**
  String get quartettSetTrainsH;

  /// KLD-069 Quartett set name, rockets deck, set A: Moon rockets.
  ///
  /// In de, this message translates to:
  /// **'Mondraketen'**
  String get quartettSetRocketsA;

  /// KLD-069 Quartett set name, rockets deck, set B: Rockets with reusable boosters.
  ///
  /// In de, this message translates to:
  /// **'Wiederverwendbar'**
  String get quartettSetRocketsB;

  /// KLD-069 Quartett set name, rockets deck, set C: European rockets.
  ///
  /// In de, this message translates to:
  /// **'Europa'**
  String get quartettSetRocketsC;

  /// KLD-069 Quartett set name, rockets deck, set D: Classic US rockets.
  ///
  /// In de, this message translates to:
  /// **'USA-Klassiker'**
  String get quartettSetRocketsD;

  /// KLD-069 Quartett set name, rockets deck, set E: Russian/Soviet rockets.
  ///
  /// In de, this message translates to:
  /// **'Russland'**
  String get quartettSetRocketsE;

  /// KLD-069 Quartett set name, rockets deck, set F: Chinese rockets.
  ///
  /// In de, this message translates to:
  /// **'China'**
  String get quartettSetRocketsF;

  /// KLD-069 Quartett set name, rockets deck, set G: Japanese and Indian rockets.
  ///
  /// In de, this message translates to:
  /// **'Japan & Indien'**
  String get quartettSetRocketsG;

  /// KLD-069 Quartett set name, rockets deck, set H: Small launch vehicles.
  ///
  /// In de, this message translates to:
  /// **'Kleine Träger'**
  String get quartettSetRocketsH;

  /// KLD-069 Quartett set name, planes deck, set A: Wide-body airliners.
  ///
  /// In de, this message translates to:
  /// **'Großraumjets'**
  String get quartettSetPlanesA;

  /// KLD-069 Quartett set name, planes deck, set B: Narrow-body medium-haul airliners.
  ///
  /// In de, this message translates to:
  /// **'Mittelstrecke'**
  String get quartettSetPlanesB;

  /// KLD-069 Quartett set name, planes deck, set C: Supersonic aircraft.
  ///
  /// In de, this message translates to:
  /// **'Überschall'**
  String get quartettSetPlanesC;

  /// KLD-069 Quartett set name, planes deck, set D: Propeller aircraft.
  ///
  /// In de, this message translates to:
  /// **'Propeller-Klassiker'**
  String get quartettSetPlanesD;

  /// KLD-069 Quartett set name, planes deck, set E: Giant cargo aircraft.
  ///
  /// In de, this message translates to:
  /// **'Frachtriesen'**
  String get quartettSetPlanesE;

  /// KLD-069 Quartett set name, planes deck, set F: Business jets and light aircraft.
  ///
  /// In de, this message translates to:
  /// **'Business & Sport'**
  String get quartettSetPlanesF;

  /// KLD-069 Quartett set name, planes deck, set G: Pioneer aircraft (1903–1927).
  ///
  /// In de, this message translates to:
  /// **'Pioniere'**
  String get quartettSetPlanesG;

  /// KLD-069 Quartett set name, planes deck, set H: Unusual record aircraft.
  ///
  /// In de, this message translates to:
  /// **'Rekord-Exoten'**
  String get quartettSetPlanesH;

  /// KLD-069 Quartett stat label: power in kW (trains).
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get quartettStatKw;

  /// KLD-069 Quartett stat label: length in metres (trains, planes).
  ///
  /// In de, this message translates to:
  /// **'Länge'**
  String get quartettStatLengthM;

  /// KLD-069 Quartett stat label: weight in tonnes, lower wins (trains).
  ///
  /// In de, this message translates to:
  /// **'Gewicht'**
  String get quartettStatMassT;

  /// KLD-069 Quartett stat label: starting tractive effort in kN (trains).
  ///
  /// In de, this message translates to:
  /// **'Anfahr­zug­kraft'**
  String get quartettStatTractiveKn;

  /// KLD-069 Quartett stat label: height in metres (rockets).
  ///
  /// In de, this message translates to:
  /// **'Höhe'**
  String get quartettStatHeightM;

  /// KLD-069 Quartett stat label: liftoff thrust in kN (rockets).
  ///
  /// In de, this message translates to:
  /// **'Start­schub'**
  String get quartettStatThrustKn;

  /// KLD-069 Quartett stat label: payload to low Earth orbit in tonnes (rockets).
  ///
  /// In de, this message translates to:
  /// **'Nutz­last (LEO)'**
  String get quartettStatLeoT;

  /// KLD-069 Quartett stat label: launch mass in tonnes (rockets).
  ///
  /// In de, this message translates to:
  /// **'Start­masse'**
  String get quartettStatLaunchMassT;

  /// KLD-069 Quartett stat label: number of launches (rockets).
  ///
  /// In de, this message translates to:
  /// **'Starts'**
  String get quartettStatFlights;

  /// KLD-069 Quartett stat label: range in km (planes).
  ///
  /// In de, this message translates to:
  /// **'Reich­weite'**
  String get quartettStatRangeKm;

  /// KLD-069 Quartett stat label: wingspan in metres (planes).
  ///
  /// In de, this message translates to:
  /// **'Spann­weite'**
  String get quartettStatWingspanM;

  /// KLD-069 Quartett stat label: maximum take-off weight in tonnes (planes).
  ///
  /// In de, this message translates to:
  /// **'Start­gewicht'**
  String get quartettStatMtowT;

  /// KLD-069 deck picker title (before a Quartett game).
  ///
  /// In de, this message translates to:
  /// **'Kartendeck wählen'**
  String get quartettDeckPickerTitle;

  /// KLD-069 heading of the deck choice in the network host setup.
  ///
  /// In de, this message translates to:
  /// **'Kartendeck'**
  String get quartettDeckLabel;

  /// KLD-069 deck info line: number of sets of 4 cards.
  ///
  /// In de, this message translates to:
  /// **'{sets} Sets à 4 Karten'**
  String quartettDeckSets(int sets);

  /// KLD-069 deck picker button: start the game.
  ///
  /// In de, this message translates to:
  /// **'Spielen'**
  String get quartettDeckPlay;

  /// KLD-069 button/link: open the view-only card gallery.
  ///
  /// In de, this message translates to:
  /// **'Karten ansehen'**
  String get quartettGalleryOpen;

  /// KLD-069 card gallery title (list of decks).
  ///
  /// In de, this message translates to:
  /// **'Quartett-Karten'**
  String get quartettGalleryTitle;

  /// KLD-069 full-size card view title: position in the deck.
  ///
  /// In de, this message translates to:
  /// **'Karte {index} von {total}'**
  String quartettGalleryCardOf(int index, int total);

  /// KLD-069 full-size card view: button for the previous card.
  ///
  /// In de, this message translates to:
  /// **'Vorherige Karte'**
  String get quartettGalleryPrevious;

  /// KLD-069 full-size card view: button for the next card.
  ///
  /// In de, this message translates to:
  /// **'Nächste Karte'**
  String get quartettGalleryNext;

  /// KLD-069 deck gallery: menu to show the best 5 cards of a stat.
  ///
  /// In de, this message translates to:
  /// **'Top 5 nach Wert'**
  String get quartettGalleryTopMenu;

  /// KLD-069 deck gallery: title of the best-5 list; stat = stat label.
  ///
  /// In de, this message translates to:
  /// **'Top 5: {stat}'**
  String quartettGalleryTopTitle(String stat);

  /// KLD-069 screen-reader label of a small card in the gallery; id e.g. B3, name = vehicle name, set = set name.
  ///
  /// In de, this message translates to:
  /// **'Karte {id}: {name}, Set {set}'**
  String quartettCardSemantics(String id, String name, String set);

  /// KLD-082 Quartett stat label: number built of the type/class, higher wins (trains, planes).
  ///
  /// In de, this message translates to:
  /// **'Gebaut'**
  String get quartettStatBuilt;

  /// KLD-082 Quartett stat label: share of successful launches in percent, higher wins (rockets).
  ///
  /// In de, this message translates to:
  /// **'Erfolgs­quote'**
  String get quartettStatSuccessPct;

  /// KLD-082 unit after the number built, short (de "Stk." = pieces), e.g. "11.000 Stk.".
  ///
  /// In de, this message translates to:
  /// **'Stk.'**
  String get quartettUnitBuilt;

  /// KLD-082 credit line of a card photo; author = photographer/author from Wikimedia Commons, license = licence short name (e.g. "CC BY-SA 4.0"), both untranslated.
  ///
  /// In de, this message translates to:
  /// **'Foto: {author}, {license}'**
  String quartettPhotoCredit(String author, String license);

  /// KLD-082 title of the photo credit dialog of a Quartett card.
  ///
  /// In de, this message translates to:
  /// **'Bildnachweis'**
  String get quartettPhotoCreditTitle;

  /// KLD-082 tooltip / screen-reader label of the small (i) button on a card photo.
  ///
  /// In de, this message translates to:
  /// **'Bildnachweis anzeigen'**
  String get quartettPhotoCreditTooltip;

  /// KLD-082 credit dialog: the photo was scaled down for the app (an adaptation in licence terms).
  ///
  /// In de, this message translates to:
  /// **'Für die App verkleinert.'**
  String get quartettPhotoModified;

  /// KLD-082 credit dialog, share-alike licences only: the resized photo keeps the same licence.
  ///
  /// In de, this message translates to:
  /// **'Die verkleinerte Fassung steht unter derselben Lizenz.'**
  String get quartettPhotoShareAlike;

  /// KLD-082 button: open the licence text (web page).
  ///
  /// In de, this message translates to:
  /// **'Lizenz'**
  String get quartettPhotoLicense;

  /// KLD-082 button: open the photo page on Wikimedia Commons.
  ///
  /// In de, this message translates to:
  /// **'Quelle'**
  String get quartettPhotoSource;

  /// KLD-082 button: close the credit dialog.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get quartettPhotoClose;

  /// KLD-082 button on the full-size card: open the Wikipedia article about the vehicle.
  ///
  /// In de, this message translates to:
  /// **'Auf Wikipedia lesen'**
  String get quartettWikipediaRead;

  /// KLD-082 title of the screen that lists the credits of all card photos.
  ///
  /// In de, this message translates to:
  /// **'Bildnachweise'**
  String get quartettImageCreditsTitle;

  /// KLD-082 intro text of the image credits screen.
  ///
  /// In de, this message translates to:
  /// **'Die Fotos stammen von Wikimedia Commons und stehen unter freien Lizenzen. Sie sind in der App enthalten; nur die Links brauchen Internet.'**
  String get quartettImageCreditsIntro;

  /// KLD-082 snack bar when a web link could not be opened.
  ///
  /// In de, this message translates to:
  /// **'Der Link konnte nicht geöffnet werden.'**
  String get quartettLinkFailed;

  /// KLD-083: host waiting screen in the browser when the page/relay is localhost (127.x, ::1, *.localhost). host = the loopback host (kept LTR); example = a generic LAN URL (http://192.168.x.x:8081), mdnsExample = a generic .local URL (both kept LTR).
  ///
  /// In de, this message translates to:
  /// **'Hinweis: Andere Geräte können „{host}“ nicht erreichen. Öffne die Seite über die WLAN-Adresse dieses Rechners (z. B. {example}) oder seinen .local-Namen (z. B. {mdnsExample}), damit Link und QR-Code auf anderen Geräten funktionieren.'**
  String relayLoopbackHint(String host, String example, String mdnsExample);

  /// KLD-083: small warning under the relay line (and on the native waiting screen) when the relay address is localhost; host = the loopback host (kept LTR).
  ///
  /// In de, this message translates to:
  /// **'„{host}“ ist nur auf diesem Gerät erreichbar – andere Geräte brauchen die WLAN-Adresse oder den .local-Namen des Rechners.'**
  String relayLoopbackShort(String host);

  /// KLD-083: collapsible help in the localhost warning: how to find this computer's address.
  ///
  /// In de, this message translates to:
  /// **'Wie finde ich die Adresse?'**
  String get loopbackHowTitle;

  /// KLD-083 help, macOS: where the Wi-Fi IP is shown (System Settings menu names as in the OS language); a terminal command follows (untranslated).
  ///
  /// In de, this message translates to:
  /// **'Systemeinstellungen › WLAN › Details … › IP-Adresse. Oder im Terminal:'**
  String get loopbackHowMacSettings;

  /// KLD-083 help, macOS: where the .local name (Bonjour) is shown.
  ///
  /// In de, this message translates to:
  /// **'Der .local-Name steht unter Systemeinstellungen › Allgemein › Freigaben („Lokaler Hostname“).'**
  String get loopbackHowMacMdns;

  /// KLD-083 help, Windows: where the IPv4 address is shown; the command `ipconfig` follows.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen › Netzwerk und Internet › WLAN › Eigenschaften (IPv4-Adresse). Oder in der Eingabeaufforderung (cmd), „IPv4-Adresse“ des WLAN-Adapters:'**
  String get loopbackHowWindowsSettings;

  /// KLD-083 help, Windows: the .local name.
  ///
  /// In de, this message translates to:
  /// **'Der .local-Name ist unter Windows 10/11 <Computername>.local.'**
  String get loopbackHowWindowsMdns;

  /// KLD-083 help, Linux: label before the commands `hostname -I` / `ip -4 addr show`.
  ///
  /// In de, this message translates to:
  /// **'Im Terminal:'**
  String get loopbackHowLinuxTerminal;

  /// KLD-083 help, Linux: settings path and the .local name with Avahi.
  ///
  /// In de, this message translates to:
  /// **'Oder Einstellungen › Netzwerk › WLAN › Details. Der .local-Name ist <Hostname>.local, wenn Avahi läuft.'**
  String get loopbackHowLinuxSettings;

  /// KLD-083 help: the relay console prints the addresses; command = `klunki relay` (kept LTR).
  ///
  /// In de, this message translates to:
  /// **'Tipp: Die Konsole von „{command}“ zeigt diese Adressen beim Start an.'**
  String loopbackHowRelay(String command);

  /// KLD-083: tooltip of the copy button next to a terminal command.
  ///
  /// In de, this message translates to:
  /// **'Befehl kopieren'**
  String get loopbackHowCopy;

  /// KLD-083: snackbar after copying a terminal command.
  ///
  /// In de, this message translates to:
  /// **'Befehl kopiert'**
  String get loopbackHowCopied;

  /// KLD-081 GoStrategy setup on the board: hint when a piece is dropped or placed outside the own four home rows.
  ///
  /// In de, this message translates to:
  /// **'Nur deine vier Reihen unten nehmen Figuren auf.'**
  String get goSetupInvalid;

  /// KLD-085: joining failed because the two devices run builds that do not fit together (protocol, game rules or Quartett deck data); which one is older is unknown. "Browser: reload" is for the PWA.
  ///
  /// In de, this message translates to:
  /// **'Die Spielversionen passen nicht zusammen – bitte beide Apps aktualisieren (Browser: neu laden).'**
  String get versionMismatchBoth;

  /// KLD-085: like versionMismatchBoth, and the other device runs the older build.
  ///
  /// In de, this message translates to:
  /// **'Die Spielversionen passen nicht zusammen: Das andere Gerät hat eine ältere Version. Bitte dort die App aktualisieren (Browser: neu laden).'**
  String get versionMismatchUpdateOther;

  /// KLD-085: like versionMismatchBoth, and this device runs the older build.
  ///
  /// In de, this message translates to:
  /// **'Die Spielversionen passen nicht zusammen: Dieses Gerät hat eine ältere Version. Bitte diese App aktualisieren (Browser: neu laden).'**
  String get versionMismatchUpdateThis;

  /// KLD-085: host waiting screen: a guest with an incompatible build tried to join and was refused; the host keeps waiting. reason is one of the versionMismatch texts.
  ///
  /// In de, this message translates to:
  /// **'Ein Gerät wollte beitreten, wurde aber abgewiesen: {reason}'**
  String versionMismatchGuestRefused(String reason);

  /// KLD-085: menu footer, the app version line so two devices can be compared by eye (e.g. "1.0.0+1 · abc1234 · P3 · ba13a678": version, build, protocol, game data code).
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String menuVersion(String version);

  /// Game title: chess (KLD-059).
  ///
  /// In de, this message translates to:
  /// **'Schach'**
  String get menuGameChess;

  /// Menu tile one-liner for chess (KLD-059).
  ///
  /// In de, this message translates to:
  /// **'Der Klassiker: setze den gegnerischen König matt.'**
  String get menuDescChess;

  /// Chess: the side name of player A (moves first), used instead of the mark X in the status line, result and resign dialog ("Weiß ist am Zug", "Anna (Weiß)").
  ///
  /// In de, this message translates to:
  /// **'Weiß'**
  String get chessWhite;

  /// Chess: the side name of player B, used instead of the mark O.
  ///
  /// In de, this message translates to:
  /// **'Schwarz'**
  String get chessBlack;

  /// Chess: badge while the side to move is in check.
  ///
  /// In de, this message translates to:
  /// **'Schach!'**
  String get chessCheck;

  /// Chess hint: nothing selected yet.
  ///
  /// In de, this message translates to:
  /// **'Tippe eine Figur an, um sie zu ziehen.'**
  String get chessHintSelect;

  /// Chess hint: a piece is selected, its legal targets are marked.
  ///
  /// In de, this message translates to:
  /// **'Tippe ein markiertes Feld an.'**
  String get chessHintTarget;

  /// Chess: title of the promotion picker (queen, rook, bishop, knight).
  ///
  /// In de, this message translates to:
  /// **'Bauer umwandeln in …'**
  String get chessPromotionTitle;

  /// Chess: tooltip of the button that turns the board by 180 degrees.
  ///
  /// In de, this message translates to:
  /// **'Brett drehen'**
  String get chessFlipBoard;

  /// Chess: tooltip of the toggle that turns the board to the side to move after every move (hot-seat).
  ///
  /// In de, this message translates to:
  /// **'Brett zur Seite am Zug drehen'**
  String get chessAutoFlip;

  /// Chess: screen reader label of an empty square; square = "e4".
  ///
  /// In de, this message translates to:
  /// **'{square}: leer'**
  String chessSquareEmpty(String square);

  /// Chess: screen reader label of an occupied square; square = "e4", piece = piece name, side = White/Black.
  ///
  /// In de, this message translates to:
  /// **'{square}: {piece} ({side})'**
  String chessSquarePiece(String square, String piece, String side);

  /// Chess piece name.
  ///
  /// In de, this message translates to:
  /// **'König'**
  String get chessPieceKing;

  /// Chess piece name.
  ///
  /// In de, this message translates to:
  /// **'Dame'**
  String get chessPieceQueen;

  /// Chess piece name.
  ///
  /// In de, this message translates to:
  /// **'Turm'**
  String get chessPieceRook;

  /// Chess piece name.
  ///
  /// In de, this message translates to:
  /// **'Läufer'**
  String get chessPieceBishop;

  /// Chess piece name.
  ///
  /// In de, this message translates to:
  /// **'Springer'**
  String get chessPieceKnight;

  /// Chess piece name.
  ///
  /// In de, this message translates to:
  /// **'Bauer'**
  String get chessPiecePawn;

  /// Result reason (chess): checkmate.
  ///
  /// In de, this message translates to:
  /// **'Schachmatt'**
  String get engineReasonChessCheckmate;

  /// Result reason (chess): draw, the side to move has no legal move and is not in check.
  ///
  /// In de, this message translates to:
  /// **'Patt'**
  String get engineReasonChessStalemate;

  /// Result reason (chess): draw, neither side can checkmate any more.
  ///
  /// In de, this message translates to:
  /// **'Zu wenig Material zum Mattsetzen'**
  String get engineReasonChessInsufficientMaterial;

  /// Result reason (chess): draw by the 75-move rule (moves = 75).
  ///
  /// In de, this message translates to:
  /// **'{moves} Züge ohne Schlagen oder Bauernzug'**
  String engineReasonChessSeventyFiveMoves(int moves);

  /// Result reason (chess): draw, the same position occurred for the third time (times = 3).
  ///
  /// In de, this message translates to:
  /// **'{times}-mal dieselbe Stellung'**
  String engineReasonChessThreefoldRepetition(int times);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

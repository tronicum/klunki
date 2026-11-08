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

  /// Menu: heading of the device-vs-device section with the two room buttons (KLD-098).
  ///
  /// In de, this message translates to:
  /// **'Mit anderen Geräten spielen'**
  String get menuSectionNetwork;

  /// KLD-105: link at the bottom of a menu game tile: start the game on this device (hot-seat), like tapping the tile. Short: two columns on a phone.
  ///
  /// In de, this message translates to:
  /// **'Ein Gerät'**
  String get menuPlayOnOneDevice;

  /// KLD-105: link at the bottom of a menu game tile: start a room for this game ("Raum starten" with the game preselected). Short: two columns on a phone.
  ///
  /// In de, this message translates to:
  /// **'Mit anderen'**
  String get menuPlayWithOthers;

  /// KLD-105: line in the "Wer spielt?" dialog (hotSeatStartTitle) of hidden-information games (cards, fleet, ranks, letter racks): the players pass the device and the handover screen keeps the secrets.
  ///
  /// In de, this message translates to:
  /// **'Ihr gebt das Gerät weiter – was verdeckt ist, bleibt geheim.'**
  String get hotSeatPassDeviceHint;

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
  /// **'Raum über einen Server öffnen'**
  String get roomViaRelay;

  /// KLD-098: explanation below roomViaRelay. "klunki relay" is the command and stays as is.
  ///
  /// In de, this message translates to:
  /// **'Mit Raumcode, auch für Mitspieler im Browser. Dafür braucht ihr einen Server (z. B. einen Rechner, auf dem „klunki relay“ läuft). Ausgeschaltet läuft der Raum direkt auf diesem Gerät, und Geräte im selben WLAN finden ihn von selbst.'**
  String get roomViaRelayHelper;

  /// KLD-098: join screen: heading above the room code field.
  ///
  /// In de, this message translates to:
  /// **'Raumcode eintippen'**
  String get roomTypeCode;

  /// Status line: whose turn it is (game on this device). player = player name, e.g. "Anna" (any name: keep the sentence free of grammatical gender and possessive endings).
  ///
  /// In de, this message translates to:
  /// **'{player} ist am Zug'**
  String shellToMove(String player);

  /// Status line after the game ended with a winner.
  ///
  /// In de, this message translates to:
  /// **'{player} hat gewonnen'**
  String shellHasWon(String player);

  /// Status line in a network game when this device is to move (KLD-106: no player mark; the token in the pill shows the player).
  ///
  /// In de, this message translates to:
  /// **'Du bist am Zug'**
  String get shellYourTurn;

  /// Status line in a network game while the other player is to move; player = "Ben".
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

  /// Tooltip of the take-back button (shellTakeBack) in the game area: take back the last move (hot-seat).
  ///
  /// In de, this message translates to:
  /// **'Zug zurück'**
  String get shellUndo;

  /// Label of the button in the game area (under the board or in the board's control row, KLD-117) that takes back the last move (hot-seat). Short: it sits in a row with icon buttons.
  ///
  /// In de, this message translates to:
  /// **'Zug zurück'**
  String get shellTakeBack;

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

  /// Quartett (Trumpf), network: hint while the opponent picks a stat. player = "Ben".
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

  /// Quartett (Trumpf) reveal and network status line: who picks after the round shown, when that is not the picker (the winner). player = player name, e.g. "Ben".
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

  /// Quartett (Trumpf), network status line while an older round is still shown: this device's player picks after it (KLD-106: no mark).
  ///
  /// In de, this message translates to:
  /// **'Du wählst als Nächstes'**
  String get quartettTrumpfYouPickNext;

  /// Quartett (Trumpf), network: badge next to the status line while more rounds are queued behind the one shown (count >= 1).
  ///
  /// In de, this message translates to:
  /// **'noch {count, plural, =1{1 Runde} other{{count} Runden}}'**
  String quartettTrumpfTricksBehind(int count);

  /// Quartett (Trumpf), hot-seat handover cover: why the device goes to that player. player = player name, e.g. "Ben".
  ///
  /// In de, this message translates to:
  /// **'{player} hat die Runde gewonnen'**
  String quartettTrumpfHandoverReason(String player);

  /// Quartett (Trumpf), KLD-100 house rule: hint for a player with 2–3 cards left who chooses which card to play (all their cards are shown face-up). count = number of cards (2 or 3).
  ///
  /// In de, this message translates to:
  /// **'Du hast nur noch {count} Karten – wähle eine aus.'**
  String quartettTrumpfChooseOwn(int count);

  /// Quartett (Trumpf), KLD-100: hint (and hot-seat handover cover) for the defender with 2–3 cards: the opponent announced a stat, now the defender chooses which of their cards to play. player = the defender's name, e.g. "Ben" ("Ben (2)" when both players have the same name); stat = stat label.
  ///
  /// In de, this message translates to:
  /// **'{player} spielt {stat}. Wähle deine Karte.'**
  String quartettTrumpfChooseDefend(String player, String stat);

  /// History text: a player chose which card to play (KLD-100). Never names the card.
  ///
  /// In de, this message translates to:
  /// **'wählt eine Karte'**
  String get quartettTrumpfMoveChoose;

  /// Quartett (Trumpf), network, KLD-100: hint while the opponent (2–3 cards) chooses their card for the announced stat. player = name or mark.
  ///
  /// In de, this message translates to:
  /// **'{player} wählt eine Karte …'**
  String quartettTrumpfHintDefending(String player);

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

  /// Chip: quartets laid down by player A and player B. nameA / nameB = player names ("Anna", "Ben").
  ///
  /// In de, this message translates to:
  /// **'Quartette {nameA} {a} : {b} {nameB}'**
  String quartettSetsScore(String nameA, String nameB, int a, int b);

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
  /// **'Tippe aufs Meer, um das Schiff zu setzen.'**
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
  /// **'{ship} ausgewählt: ziehen zum Verschieben, nochmal antippen zum Drehen.'**
  String schiffeHintSelected(String ship);

  /// KLD-068. Schiffe setup hint when all ships are placed.
  ///
  /// In de, this message translates to:
  /// **'Flotte steht. Schiff antippen zum Verschieben oder Drehen – oder „Fertig“.'**
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

  /// KLD-107. Schiffe setup hint once a ship is on the board and none is selected: how to place the next one and that placed ships can be moved and turned.
  ///
  /// In de, this message translates to:
  /// **'Tippe aufs Meer für das nächste Schiff. Schiff antippen zum Verschieben oder Drehen.'**
  String get schiffeHintSetupMore;

  /// KLD-107. Schiffe setup: small one-time tip bubble next to the first placed ship (very short).
  ///
  /// In de, this message translates to:
  /// **'Antippen: verschieben oder drehen'**
  String get schiffeCoachTap;

  /// KLD-107. Schiffe setup: second line of the disabled "Fertig" button: how many ships are still in the harbour.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{noch 1 Schiff} other{noch {count} Schiffe}}'**
  String schiffeDoneLeft(int count);

  /// KLD-107. Schiffe setup: screen-reader label of the next-ship preview box (tapping it turns the ship); ship = e.g. "Kreuzer (4)", orientation = schiffeHorizontal/schiffeVertical.
  ///
  /// In de, this message translates to:
  /// **'Vorschau: {ship}, {orientation}. Tippen dreht es.'**
  String schiffePreviewSemantics(String ship, String orientation);

  /// KLD-107. Schiffe setup: screen-reader text of the "×2" badge on the preview: how many ships of this kind are still in the harbour (including this one).
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{das letzte dieser Art} other{noch {count} dieser Art}}'**
  String schiffePreviewLeft(int count);

  /// KLD-107. Schiffe setup: reason after a placement, move or turn that would touch or cover another ship. The rule: no contact at all, not even diagonally (corner to corner); one free cell between ships.
  ///
  /// In de, this message translates to:
  /// **'Schiffe dürfen sich nicht berühren, auch nicht über Eck – lass ein Feld Abstand.'**
  String get schiffeInvalidTouch;

  /// KLD-107. Schiffe setup: reason after a placement or move that would stick out of the 10×10 board.
  ///
  /// In de, this message translates to:
  /// **'Passt nicht aufs Spielfeld.'**
  String get schiffeInvalidOffBoard;

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

  /// A player name with its mark, e.g. "Anna (Weiß)" in chess, or "Anna (1)" / "Anna (2)" (the player number, as on the token) when both players have the same name (KLD-106); used inside other sentences (status line, result, history).
  ///
  /// In de, this message translates to:
  /// **'{name} ({mark})'**
  String playerLabel(String name, String mark);

  /// KLD-103: default name of player A (moves first; mark X, chess White) in hot-seat games and the suggested own name when starting a room. A short, common given name of the region, used inside sentences ("Anna ist am Zug"). Must differ from playerDefaultNameB. Avoid names that read as a common word.
  ///
  /// In de, this message translates to:
  /// **'Anna'**
  String get playerDefaultNameA;

  /// KLD-103: default name of player B (mark O, chess Black) in hot-seat games and the suggested own name when joining a room; see playerDefaultNameA.
  ///
  /// In de, this message translates to:
  /// **'Ben'**
  String get playerDefaultNameB;

  /// KLD-103: title of the player names dialog shown when a game on this device starts.
  ///
  /// In de, this message translates to:
  /// **'Wer spielt?'**
  String get hotSeatStartTitle;

  /// KLD-103: button of the player names dialog at the start of a game on this device: start the game with these names.
  ///
  /// In de, this message translates to:
  /// **'Spielen'**
  String get hotSeatStartPlay;

  /// Game on this device: title of the player names dialog (app bar button during the game) and tooltip of that button.
  ///
  /// In de, this message translates to:
  /// **'Spielernamen'**
  String get hotSeatNamesTitle;

  /// Player names dialog (game on this device): label of the name field of one player, numbered in turn order (1 = player A, who starts in every game; 2 = player B). The player's token (colour, symbol) is shown in the field.
  ///
  /// In de, this message translates to:
  /// **'Spieler {number}'**
  String hotSeatNameLabel(int number);

  /// KLD-103: Player names dialog (game on this device): small hint under the field of player 1, who makes the first move in every game. Short; no gendered verb (Arabic: a noun phrase).
  ///
  /// In de, this message translates to:
  /// **'beginnt'**
  String get hotSeatStartsHint;

  /// Player names dialog (game on this device): an empty field means the default name (playerDefaultNameA / playerDefaultNameB).
  ///
  /// In de, this message translates to:
  /// **'Leer lassen für den Standardnamen.'**
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

  /// Network game connection bar, read out by screen readers (KLD-106: names only, no marks); name = own player name, peer = the other player's name.
  ///
  /// In de, this message translates to:
  /// **'Du: {name} · Gegner: {peer}'**
  String pairingStatus(String name, String peer);

  /// KLD-067: network connection bar, this device's player next to its coloured token (the token shows the player number 1 / 2 or the game's piece); name = own player name. Same shape as netBarOpponent (KLD-106).
  ///
  /// In de, this message translates to:
  /// **'Du: {name}'**
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
  /// **'Verbindung wird wiederhergestellt …'**
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

  /// Browser join and host screens: shown when the page was opened over https (browsers block ws:// relays and hosts from https pages; only wss:// works). Also the error when such a connection is attempted.
  ///
  /// In de, this message translates to:
  /// **'Im Browser über https kann Klunki nur sichere Server (wss://) erreichen – nutze die App oder die lokale http-Version.'**
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

  /// GoStrategy setup headline. player = player name, e.g. "Anna".
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

  /// GoStrategy network: the other player sets up first; this player can already arrange. player = "Anna".
  ///
  /// In de, this message translates to:
  /// **'{player} stellt zuerst auf – du kannst schon vorbereiten.'**
  String goSetupFirst(String player);

  /// GoStrategy network: waiting for the other player's setup. player = "Ben".
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

  /// GoStrategy hint while the other player moves. player = "Ben".
  ///
  /// In de, this message translates to:
  /// **'Warte auf {player} …'**
  String goHintWaiting(String player);

  /// GoStrategy: shown near the move limit. moves = digits, moves left without a fight before the draw.
  ///
  /// In de, this message translates to:
  /// **'Noch {moves} Züge ohne Kampf, dann ist es unentschieden.'**
  String goMoveLimit(String moves);

  /// GoStrategy panel heading: the viewer's army (KLD-106: no mark or name).
  ///
  /// In de, this message translates to:
  /// **'Deine Armee'**
  String get goArmyOwn;

  /// GoStrategy panel heading: the opponent's army. player = "Ben" or "O".
  ///
  /// In de, this message translates to:
  /// **'Gegner: {player}'**
  String goArmyEnemy(String player);

  /// GoStrategy panel: pieces left of an army. left/total = digits.
  ///
  /// In de, this message translates to:
  /// **'{left} von {total} übrig'**
  String goArmyLeft(String left, String total);

  /// GoStrategy fight reveal headline. player = "Anna" or "X".
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

  /// GoStrategy square content: an enemy piece of unknown rank. player = "O" or "Ben".
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
  /// **'Server: {address}'**
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
  /// **'Server'**
  String get relayAddressLabel;

  /// Helper under the relay address field.
  ///
  /// In de, this message translates to:
  /// **'Adresse des Servers, z. B. 192.168.1.20:4749 (im WLAN) oder wss://spiele.example (im Internet)'**
  String get relayAddressHelper;

  /// Error for a malformed relay address.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Server-Adresse. Beispiel: 192.168.1.20:4749'**
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

  /// KLD-120, relay: the room exists, but the device that started it is away for the moment (e.g. its phone is locked); trying again soon may work.
  ///
  /// In de, this message translates to:
  /// **'Das Gerät, das Raum {code} gestartet hat, ist gerade nicht erreichbar. Versuch es gleich noch einmal.'**
  String relayErrorHostAway(String code);

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
  /// **'Kein Server erreichbar unter {address}.'**
  String relayErrorUnreachable(String address);

  /// Relay: the connection to the relay broke (relay stopped, network loss).
  ///
  /// In de, this message translates to:
  /// **'Die Verbindung zum Server ist abgebrochen.'**
  String get relayErrorLost;

  /// Shown when no relay is reachable, followed by the start command.
  ///
  /// In de, this message translates to:
  /// **'Räume mit Raumcode brauchen einen Server. Starte ihn auf einem Rechner im WLAN und öffne Klunki über dessen Adresse:'**
  String get relayStartHint;

  /// Relay room lost while waiting; reason = the relay error text.
  ///
  /// In de, this message translates to:
  /// **'{reason} Starte einen neuen Raum.'**
  String relayRoomLost(String reason);

  /// KLD-075 room join: the relay a ?room= link or scanned room QR names, used for this join only (not saved); address = host:port.
  ///
  /// In de, this message translates to:
  /// **'Server aus Link: {address}'**
  String relayFromLink(String address);

  /// KLD-075 room join: button that saves the link's relay as the default relay setting.
  ///
  /// In de, this message translates to:
  /// **'Als Standard speichern'**
  String get relayLinkSaveDefault;

  /// KLD-075 room join: button that ignores the link's relay and goes back to the saved/default relay.
  ///
  /// In de, this message translates to:
  /// **'Gespeicherten Server verwenden'**
  String get relayLinkUseSaved;

  /// KLD-075 PWA: warning when a ?room= link names a relay other than the page's own server (possible phishing/abuse).
  ///
  /// In de, this message translates to:
  /// **'Achtung: Dieser Link führt zu einem fremden Server, nicht zum Server dieser Seite. Tritt nur bei, wenn du dem Absender vertraust: Ein fremder Server sieht alle Spielzüge.'**
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
  /// **'Kein Server eingerichtet – Adresse eingeben'**
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

  /// Relay dialog (KLD-112): label of the optional club code field (server access code of a self-hosted relay, `klunki relay --codes`).
  ///
  /// In de, this message translates to:
  /// **'Clubcode'**
  String get relayClubCodeLabel;

  /// Relay dialog (KLD-112): helper under the club code field; the code is never shared in room links or QR codes.
  ///
  /// In de, this message translates to:
  /// **'Wird nur für diesen Server gespeichert. Der Clubcode kommt nie in Raum-Links oder QR-Codes.'**
  String get relayClubCodeHelper;

  /// Room start/join error (KLD-112): the relay requires a club code and none was entered. KLD-113: the club code field is shown right under it.
  ///
  /// In de, this message translates to:
  /// **'Dieser Server braucht einen Clubcode. Frag die Person, die den Server betreibt.'**
  String get relayErrorClubMissing;

  /// Room start/join error (KLD-112): the relay does not accept the entered club code (unknown, revoked, or too many wrong tries).
  ///
  /// In de, this message translates to:
  /// **'Dieser Server kennt den Clubcode nicht. Frag die Person, die den Server betreibt.'**
  String get relayErrorClubWrong;

  /// KLD-113: what kind of server an address names, shown under the server address: a computer at home (private IP, .local name). The command name stays as is.
  ///
  /// In de, this message translates to:
  /// **'Server im WLAN (ein Rechner, auf dem „klunki relay“ läuft)'**
  String get serverKindLan;

  /// KLD-113: the kind of server for any other address (e.g. wss://spiele.example).
  ///
  /// In de, this message translates to:
  /// **'Server im Internet'**
  String get serverKindInternet;

  /// KLD-113: link in the server dialog and the club code prompt that opens the help screen.
  ///
  /// In de, this message translates to:
  /// **'Wie geht das?'**
  String get serverHelpLink;

  /// KLD-113: tooltip of the button next to a saved club code in the server dialog.
  ///
  /// In de, this message translates to:
  /// **'Clubcode entfernen'**
  String get serverClubCodeRemove;

  /// KLD-113: button under the club code field that appears when a server asks for a club code; joins / starts the room again with it.
  ///
  /// In de, this message translates to:
  /// **'Mit Clubcode versuchen'**
  String get serverClubCodeRetry;

  /// KLD-113: title of the help screen (reached from 'Über Klunki' and the server dialog); also the entry in 'Über Klunki'. All help* keys are also used by the website FAQ (de, en); keep them plain text, paragraphs separated by a blank line.
  ///
  /// In de, this message translates to:
  /// **'So spielt ihr zusammen'**
  String get helpTitle;

  /// KLD-113 help section 1 title.
  ///
  /// In de, this message translates to:
  /// **'Mit anderen spielen'**
  String get helpSectionRoomsTitle;

  /// KLD-113 help section 1: how rooms work. Button names must match roomStart / roomJoin.
  ///
  /// In de, this message translates to:
  /// **'Eine Person tippt auf „Raum starten“ und wählt ein Spiel. Klunki zeigt dann einen Raumcode und einen QR-Code.\n\nDie andere Person tippt auf „Raum beitreten“ und scannt den QR-Code oder tippt den Raumcode ein. Schon geht es los.'**
  String get helpSectionRoomsBody;

  /// KLD-113 help section 2 title.
  ///
  /// In de, this message translates to:
  /// **'Im selben WLAN'**
  String get helpSectionWifiTitle;

  /// KLD-113 help section 2: on the same Wi-Fi no server is needed, the app is the server.
  ///
  /// In de, this message translates to:
  /// **'Hat einer von euch die App? Dann braucht ihr im WLAN keinen Server: Die App ist selbst der Server, auch für Mitspieler im Browser (QR-Code).\n\nGeräte im selben WLAN finden sich von selbst.'**
  String get helpSectionWifiBody;

  /// KLD-113 help section 3 title.
  ///
  /// In de, this message translates to:
  /// **'Wann braucht ihr einen Server?'**
  String get helpSectionServerTitle;

  /// KLD-113 help section 3: when a server is needed. The two quoted names must match serverKindLan (without the parenthesis) and serverKindInternet.
  ///
  /// In de, this message translates to:
  /// **'Nur wenn alle im Browser spielen oder wenn ihr nicht im selben WLAN seid. Der Server reicht die Spielzüge zwischen euren Geräten weiter.\n\nKlunki erkennt an der Adresse, was für ein Server es ist: „Server im WLAN“ oder „Server im Internet“.'**
  String get helpSectionServerBody;

  /// KLD-113 help section 4 title.
  ///
  /// In de, this message translates to:
  /// **'Eigener Server im WLAN'**
  String get helpSectionOwnServerTitle;

  /// KLD-113 help section 4: own server on the Wi-Fi (no command line: a ready-made server program is in preparation). Button names must match roomAdvanced / relayChange.
  ///
  /// In de, this message translates to:
  /// **'Ihr könnt auch einen eigenen Server auf einem Rechner im WLAN laufen lassen. Ein fertiges Programm für Mac, Windows und Linux ist in Vorbereitung. Die Adresse tragt ihr dann in Klunki unter „Erweitert“ bei „ändern“ ein.'**
  String get helpSectionOwnServerBody;

  /// KLD-113 help section 5 title: ready-made servers, not available yet.
  ///
  /// In de, this message translates to:
  /// **'Bald einfacher (in Vorbereitung)'**
  String get helpSectionComingTitle;

  /// KLD-113 help section 5: the ways to get a server that are in preparation (one line each, starting with •). No links yet.
  ///
  /// In de, this message translates to:
  /// **'Diese Wege zu einem Server sind in Vorbereitung:\n• Server im Internet für Freundeskreise (mit Cloudflare, kostenlos)\n• Fertiges Programm zum Herunterladen für Mac, Windows und Linux\n• Docker für NAS oder Raspberry Pi\n\nServer im Internet sind meist mit einem Clubcode geschützt.'**
  String get helpSectionComingBody;

  /// KLD-113 help section 6 title.
  ///
  /// In de, this message translates to:
  /// **'Was ist ein Clubcode?'**
  String get helpSectionClubTitle;

  /// KLD-113 help section 6: what a club code is and who gives it.
  ///
  /// In de, this message translates to:
  /// **'Ein Clubcode ist wie ein Schlüssel für einen Server: Nur wer ihn kennt, kann dort Räume starten oder beitreten. Du bekommst ihn von der Person, die den Server betreibt.\n\nKlunki fragt erst danach, wenn ein Server ihn braucht, und merkt ihn sich für diesen Server.'**
  String get helpSectionClubBody;

  /// KLD-113 help section 7 title.
  ///
  /// In de, this message translates to:
  /// **'Was passiert mit meinen Daten?'**
  String get helpSectionDataTitle;

  /// KLD-113 help section 7: what happens with data; the club code is never in room links or QR codes.
  ///
  /// In de, this message translates to:
  /// **'Der Server reicht nur die Spielzüge weiter und speichert nichts davon dauerhaft. Spielt ihr direkt im selben WLAN, läuft gar nichts über einen fremden Server.\n\nDer Clubcode bleibt auf deinem Gerät und kommt nie in Raum-Links oder QR-Codes. Beim Server unter „ändern“ kannst du ihn sehen, ändern oder entfernen.'**
  String get helpSectionDataBody;

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

  /// KLD-065/KLD-099 resign dialog (network game): the game ends for both devices; player = the opponent's label, e.g. "Anna".
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

  /// KLD-065 resign dialog (hot-seat): button for one player; player = label, e.g. "Anna" or "X".
  ///
  /// In de, this message translates to:
  /// **'{player} gibt auf'**
  String shellResignPlayer(String player);

  /// Result reason (any game): a player resigned; player = label, e.g. "Anna" or "X".
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

  /// KLD-085, KLD-116: menu footer and About screen, the app version: version and commit ("1.0.0 (b8752a9)"; "(dev)" for a build without a commit).
  ///
  /// In de, this message translates to:
  /// **'Version {version}'**
  String menuVersion(String version);

  /// KLD-116: small print under the version line on the About screen, to compare two devices in detail: build number (YYYYMMDDNN from CI, 1 for local builds), network protocol, short code over every game's rules and data.
  ///
  /// In de, this message translates to:
  /// **'Build-Nummer {build} · Protokoll {protocol} · Spieldaten {games}'**
  String aboutBuildDetails(String build, String protocol, String games);

  /// KLD-116: second line of a version mismatch message: who has which app version, so people see who needs to update. nameA is this device's player, nameB the other one. Versions are like "1.0.0 (b8752a9)" (version and commit). No gendered grammar.
  ///
  /// In de, this message translates to:
  /// **'{nameA} hat {versionA}, {nameB} hat {versionB}.'**
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  );

  /// KLD-116: like versionMismatchVersions when the other player's name is not known (the refusal came before the names were exchanged). versionA: this device, versionB: the other device.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät hat {versionA}, das andere Gerät hat {versionB}.'**
  String versionMismatchVersionsDevices(String versionA, String versionB);

  /// KLD-102: menu footer button and title of the About screen (version, privacy, Impressum, support, licences).
  ///
  /// In de, this message translates to:
  /// **'Über Klunki'**
  String get aboutTitle;

  /// KLD-102: About screen link to the privacy policy (opens the copy stored in the app).
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get aboutPrivacy;

  /// KLD-102: About screen link to the Impressum (German legal notice, the word stays recognisable).
  ///
  /// In de, this message translates to:
  /// **'Impressum'**
  String get aboutImpressum;

  /// KLD-102: About screen link to the support page (help and contact).
  ///
  /// In de, this message translates to:
  /// **'Support'**
  String get aboutSupport;

  /// KLD-102: About screen licence line; also the legalese on the licence page.
  ///
  /// In de, this message translates to:
  /// **'Klunki ist freie Software unter der GNU AGPL 3.0.'**
  String get aboutLicense;

  /// KLD-102: About screen link to the source code on GitHub.
  ///
  /// In de, this message translates to:
  /// **'Quellcode'**
  String get aboutSourceCode;

  /// KLD-102: About screen button that opens the list of open source licences (Flutter licence page).
  ///
  /// In de, this message translates to:
  /// **'Open-Source-Lizenzen'**
  String get aboutLicenses;

  /// KLD-102: privacy screen action: open the web page in the browser.
  ///
  /// In de, this message translates to:
  /// **'Im Browser öffnen'**
  String get aboutOpenInBrowser;

  /// KLD-102: privacy screen note above the stored text; the web address follows. The text itself is German or (all other languages) English.
  ///
  /// In de, this message translates to:
  /// **'Diese Fassung ist in der App gespeichert, damit du sie auch ohne Internet lesen kannst. Maßgeblich ist die Seite im Web:'**
  String get aboutPrivacyOffline;

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

  /// Chess: the side name White (moves first; player A unless a network host chose Black, KLD-059 step 4a), used instead of the mark X in the status line, result and resign dialog ("Weiß ist am Zug", "Anna (Weiß)").
  ///
  /// In de, this message translates to:
  /// **'Weiß'**
  String get chessWhite;

  /// Chess: the side name Black (player B unless a network host chose Black), used instead of the mark O.
  ///
  /// In de, this message translates to:
  /// **'Schwarz'**
  String get chessBlack;

  /// KLD-059 step 4a: title of the colour choice when starting a chess room (the host's own colour: Weiß / Schwarz / Zufällig).
  ///
  /// In de, this message translates to:
  /// **'Deine Farbe'**
  String get chessColorLabel;

  /// KLD-059 step 4a: the third option of the colour choice: the app decides at random who plays White.
  ///
  /// In de, this message translates to:
  /// **'Zufällig'**
  String get chessColorRandom;

  /// KLD-059 step 4a: line under the colour choice: White moves first; Random draws lots.
  ///
  /// In de, this message translates to:
  /// **'Weiß beginnt. Bei „Zufällig“ wird ausgelost.'**
  String get chessColorHelper;

  /// KLD-059 step 4a: network chess: this device plays White (waiting room and the hint line at game start).
  ///
  /// In de, this message translates to:
  /// **'Du spielst Weiß.'**
  String get chessYouPlayWhite;

  /// KLD-059 step 4a: network chess: this device plays Black (waiting room and the hint line at game start).
  ///
  /// In de, this message translates to:
  /// **'Du spielst Schwarz.'**
  String get chessYouPlayBlack;

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

  /// KLD-059 step 3: button (tooltip) to offer the opponent a draw.
  ///
  /// In de, this message translates to:
  /// **'Remis anbieten'**
  String get chessOfferDraw;

  /// KLD-059 step 3: title of the dialog that confirms a draw offer.
  ///
  /// In de, this message translates to:
  /// **'Remis anbieten?'**
  String get chessOfferDrawTitle;

  /// KLD-059 step 3: body of the dialog that confirms a draw offer; {player} is the opponent who will decide.
  ///
  /// In de, this message translates to:
  /// **'{player} kann annehmen oder ablehnen. Bei Annahme endet das Spiel unentschieden.'**
  String chessOfferDrawBody(String player);

  /// KLD-059 step 3: confirm button of the draw offer dialog.
  ///
  /// In de, this message translates to:
  /// **'Anbieten'**
  String get chessOfferDrawConfirm;

  /// KLD-059 step 3: title of the dialog that shows the opponent's draw offer.
  ///
  /// In de, this message translates to:
  /// **'Remis-Angebot'**
  String get chessDrawOfferTitle;

  /// KLD-059 step 3: body of the dialog that shows a draw offer; {player} made the offer.
  ///
  /// In de, this message translates to:
  /// **'{player} bietet ein Remis an. Bei Annahme endet das Spiel unentschieden.'**
  String chessDrawOfferBody(String player);

  /// KLD-059 step 3: button that accepts a draw offer (the game ends drawn).
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get chessDrawAccept;

  /// KLD-059 step 3: button that declines a draw offer (the game goes on).
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get chessDrawDecline;

  /// KLD-059 step 3: hint line while a draw offer waits for {player} (the opponent) to answer.
  ///
  /// In de, this message translates to:
  /// **'Remis angeboten – {player} entscheidet.'**
  String chessHintDrawOffered(String player);

  /// KLD-059 step 3: hint line after {player} declined a draw offer (until the next move).
  ///
  /// In de, this message translates to:
  /// **'{player} lehnt das Remis ab.'**
  String chessHintDrawDeclined(String player);

  /// KLD-059 step 3: move history entry for a draw offer (after "Anna (Weiß): ").
  ///
  /// In de, this message translates to:
  /// **'Remis angeboten'**
  String get chessMoveDrawOffer;

  /// KLD-059 step 3: move history entry for a declined draw offer.
  ///
  /// In de, this message translates to:
  /// **'Remis abgelehnt'**
  String get chessMoveDrawDecline;

  /// KLD-059 step 3: move history entry for an accepted draw offer.
  ///
  /// In de, this message translates to:
  /// **'Remis angenommen'**
  String get chessMoveDrawAccept;

  /// Result reason (chess): draw, one player offered a draw and the other accepted (KLD-059 step 3).
  ///
  /// In de, this message translates to:
  /// **'Remis vereinbart'**
  String get engineReasonChessDrawAgreed;

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

  /// Game title: the crossword-style word tile game (KLD-094). Name chosen by the maintainer: Wortgewandt (= eloquent, skilled with words). Translate as a short, natural game name in that spirit (en Wordsmith), not literally; no brand names.
  ///
  /// In de, this message translates to:
  /// **'Wortgewandt'**
  String get menuGameWordTiles;

  /// Menu tile one-liner for the word tile game (KLD-094).
  ///
  /// In de, this message translates to:
  /// **'Wörter aus Buchstaben legen'**
  String get menuDescWordTiles;

  /// Debug builds only: menu button that opens a game that is not in the app yet (KLD-094).
  ///
  /// In de, this message translates to:
  /// **'Vorschau: {game}'**
  String menuPreviewGame(String game);

  /// Word tiles: button that plays the tiles laid on the board.
  ///
  /// In de, this message translates to:
  /// **'Legen'**
  String get wordtilesPlay;

  /// Word tiles: tooltip of the button that takes all tiles laid this turn back to the rack.
  ///
  /// In de, this message translates to:
  /// **'Alle Steine zurücknehmen'**
  String get wordtilesRecall;

  /// Word tiles: tooltip of the button that shuffles the rack.
  ///
  /// In de, this message translates to:
  /// **'Steine mischen'**
  String get wordtilesShuffle;

  /// Word tiles: button to swap rack tiles with the bag.
  ///
  /// In de, this message translates to:
  /// **'Tauschen'**
  String get wordtilesExchange;

  /// Word tiles: confirm button of the swap, with the number of tiles chosen.
  ///
  /// In de, this message translates to:
  /// **'{count} tauschen'**
  String wordtilesExchangeConfirm(int count);

  /// Word tiles: button to pass the turn.
  ///
  /// In de, this message translates to:
  /// **'Passen'**
  String get wordtilesPass;

  /// Word tiles: tooltip of the zoom button (board shown whole).
  ///
  /// In de, this message translates to:
  /// **'Vergrößern'**
  String get wordtilesZoomIn;

  /// Word tiles: tooltip of the zoom button (board zoomed in).
  ///
  /// In de, this message translates to:
  /// **'Ganzes Brett'**
  String get wordtilesZoomOut;

  /// Word tiles: tiles left in the bag (tooltip and screen reader text of the bag counter).
  ///
  /// In de, this message translates to:
  /// **'Beutel: {count} Steine'**
  String wordtilesBag(int count);

  /// Word tiles: a player's score (screen reader text of the score bar).
  ///
  /// In de, this message translates to:
  /// **'{player}: {score, plural, one{{score} Punkt} other{{score} Punkte}}'**
  String wordtilesScore(String player, int score);

  /// Word tiles: hint line while the player can lay tiles.
  ///
  /// In de, this message translates to:
  /// **'Ziehe Steine aufs Brett oder tippe einen Stein und dann ein Feld.'**
  String get wordtilesHintPlace;

  /// Word tiles: hint and error: the first word must cover the centre square (marked with a star).
  ///
  /// In de, this message translates to:
  /// **'Das erste Wort muss über den Stern in der Mitte gehen.'**
  String get wordtilesHintFirst;

  /// Word tiles: the hint line (hint: wordtilesHintPlace) plus a short sentence that two fingers zoom the board; shown while the board is not zoomed (KLD-094 step 8g).
  ///
  /// In de, this message translates to:
  /// **'{hint} Mit zwei Fingern zoomst du.'**
  String wordtilesHintZoom(String hint);

  /// Word tiles: hint after a rack tile was tapped.
  ///
  /// In de, this message translates to:
  /// **'Tippe ein freies Feld an.'**
  String get wordtilesHintSelected;

  /// Word tiles: hint while choosing tiles to swap.
  ///
  /// In de, this message translates to:
  /// **'Wähle die Steine, die zurück in den Beutel sollen.'**
  String get wordtilesHintExchange;

  /// Word tiles: hint while the last placement can be challenged.
  ///
  /// In de, this message translates to:
  /// **'Nimm das Wort an oder zweifle es an.'**
  String get wordtilesHintAnswer;

  /// Word tiles: why swapping is not possible now (count = 7).
  ///
  /// In de, this message translates to:
  /// **'Tauschen geht nur, solange mindestens {count} Steine im Beutel sind.'**
  String wordtilesExchangeNotNow(int count);

  /// Word tiles: live preview of the words laid and their score.
  ///
  /// In de, this message translates to:
  /// **'{words}: {score, plural, one{{score} Punkt} other{{score} Punkte}}'**
  String wordtilesPreview(String words, int score);

  /// Word tiles: live preview when all rack tiles are laid (bonus = 50).
  ///
  /// In de, this message translates to:
  /// **'{words}: {score, plural, one{{score} Punkt} other{{score} Punkte}} (mit {bonus} Bonus für alle Steine)'**
  String wordtilesPreviewBingo(String words, int score, int bonus);

  /// Word tiles: placement error: not in one row or column.
  ///
  /// In de, this message translates to:
  /// **'Die Steine müssen in einer Reihe oder Spalte liegen.'**
  String get wordtilesErrorLine;

  /// Word tiles: placement error: an empty square between the tiles.
  ///
  /// In de, this message translates to:
  /// **'Zwischen den Steinen ist noch ein Feld frei.'**
  String get wordtilesErrorGap;

  /// Word tiles: placement error: the first word has one letter only.
  ///
  /// In de, this message translates to:
  /// **'Das erste Wort braucht mindestens zwei Buchstaben.'**
  String get wordtilesErrorShort;

  /// Word tiles: placement error: the tiles touch no tile on the board.
  ///
  /// In de, this message translates to:
  /// **'Die Steine müssen an ein Wort auf dem Brett anschließen.'**
  String get wordtilesErrorConnect;

  /// Word tiles: placement error (dictionary mode): a word is not in the word list.
  ///
  /// In de, this message translates to:
  /// **'Ein Wort steht nicht im Wörterbuch.'**
  String get wordtilesErrorUnknownWord;

  /// Word tiles: placement error: the last placement must be accepted or challenged first.
  ///
  /// In de, this message translates to:
  /// **'Nimm zuerst das letzte Wort an oder zweifle es an.'**
  String get wordtilesErrorAnswerFirst;

  /// Word tiles: placement error for every other case.
  ///
  /// In de, this message translates to:
  /// **'So kannst du die Steine nicht legen.'**
  String get wordtilesErrorOther;

  /// Word tiles: the last placement, which the player to move may challenge.
  ///
  /// In de, this message translates to:
  /// **'{player} legte {words} für {score, plural, one{{score} Punkt} other{{score} Punkte}}.'**
  String wordtilesOpenPlacement(String player, String words, int score);

  /// Word tiles: button: accept the last placement.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get wordtilesAccept;

  /// Word tiles: button: challenge the last placement.
  ///
  /// In de, this message translates to:
  /// **'Anzweifeln'**
  String get wordtilesChallenge;

  /// Word tiles: title of the challenge confirmation.
  ///
  /// In de, this message translates to:
  /// **'Wort anzweifeln?'**
  String get wordtilesChallengeTitle;

  /// Word tiles: challenge confirmation without a dictionary (the challenger's call is final).
  ///
  /// In de, this message translates to:
  /// **'Ohne Wörterbuch zählt dein Einwand: {player} nimmt die Steine zurück und bekommt keine Punkte. Dann bist du am Zug.'**
  String wordtilesChallengeBodyFree(String player);

  /// Word tiles: challenge confirmation with a dictionary.
  ///
  /// In de, this message translates to:
  /// **'Das Wörterbuch entscheidet. Steht das Wort darin, verlierst du deinen Zug.'**
  String get wordtilesChallengeBodyDict;

  /// Word tiles: the last placement used the last tile; accepting it ends the game.
  ///
  /// In de, this message translates to:
  /// **'{player} hat alle Steine gelegt. Nimmst du an, ist das Spiel aus.'**
  String wordtilesEndPending(String player);

  /// Word tiles: a placement in the move list and the last-turn line (after "{player}: ").
  ///
  /// In de, this message translates to:
  /// **'{words} für {score, plural, one{{score} Punkt} other{{score} Punkte}}'**
  String wordtilesMovePlace(String words, int score);

  /// Word tiles: a swap in the move list (count = tiles swapped).
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Stein getauscht} other{{count} Steine getauscht}}'**
  String wordtilesMoveExchange(int count);

  /// Word tiles: a pass in the move list.
  ///
  /// In de, this message translates to:
  /// **'gepasst'**
  String get wordtilesMovePass;

  /// Word tiles: a successful challenge in the move list; the words were taken back.
  ///
  /// In de, this message translates to:
  /// **'angezweifelt: {words} zurückgenommen'**
  String wordtilesMoveChallengeWithdrawn(String words);

  /// Word tiles: a failed challenge in the move list (dictionary mode).
  ///
  /// In de, this message translates to:
  /// **'angezweifelt, aber die Wörter gelten'**
  String get wordtilesMoveChallengeFailed;

  /// Word tiles: an explicit accept in the move list.
  ///
  /// In de, this message translates to:
  /// **'angenommen'**
  String get wordtilesMoveAccept;

  /// Word tiles: title of the letter picker for a blank tile.
  ///
  /// In de, this message translates to:
  /// **'Welchen Buchstaben zeigt der Joker?'**
  String get wordtilesBlankTitle;

  /// Word tiles: very short label (2–3 characters) on a double-letter square.
  ///
  /// In de, this message translates to:
  /// **'2B'**
  String get wordtilesPremiumDoubleLetter;

  /// Word tiles: very short label (2–3 characters) on a triple-letter square.
  ///
  /// In de, this message translates to:
  /// **'3B'**
  String get wordtilesPremiumTripleLetter;

  /// Word tiles: very short label (2–3 characters) on a double-word square.
  ///
  /// In de, this message translates to:
  /// **'2W'**
  String get wordtilesPremiumDoubleWord;

  /// Word tiles: very short label (2–3 characters) on a triple-word square.
  ///
  /// In de, this message translates to:
  /// **'3W'**
  String get wordtilesPremiumTripleWord;

  /// Word tiles start options: label of the tile language choice (Deutsch / English).
  ///
  /// In de, this message translates to:
  /// **'Buchstaben'**
  String get wordtilesOptionTiles;

  /// Word tiles start options: switch to check every laid word against the bundled word list.
  ///
  /// In de, this message translates to:
  /// **'Wörterbuch prüfen'**
  String get wordtilesOptionDictionary;

  /// Word tiles start options: what the dictionary check does (shown while it is on).
  ///
  /// In de, this message translates to:
  /// **'Jedes gelegte Wort wird nachgeschlagen. Steht eins nicht drin, entscheidet ihr gemeinsam: zurücknehmen oder trotzdem zulassen.'**
  String get wordtilesOptionDictionaryOn;

  /// Word tiles start options: how words are judged without the dictionary (shown while it is off).
  ///
  /// In de, this message translates to:
  /// **'Ohne Wörterbuch entscheidet ihr selbst: Ein Wort kann angezweifelt werden.'**
  String get wordtilesOptionDictionaryOff;

  /// Word tiles start options: button to go on to the player names.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get wordtilesOptionsNext;

  /// Word tiles: shown while the word list loads at game start.
  ///
  /// In de, this message translates to:
  /// **'Wörterbuch wird geladen …'**
  String get wordtilesDictLoading;

  /// Word tiles: the word list could not be loaded (the game does not start).
  ///
  /// In de, this message translates to:
  /// **'Das Wörterbuch konnte nicht geladen werden.'**
  String get wordtilesDictLoadFailed;

  /// Word tiles: title of the notice after "Legen" when a word is not in the word list.
  ///
  /// In de, this message translates to:
  /// **'Nicht im Wörterbuch'**
  String get wordtilesUnknownTitle;

  /// Word tiles: which laid words the word list does not know. words = the words, comma separated; count = how many.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{„{words}“ steht nicht im Wörterbuch.} other{„{words}“ stehen nicht im Wörterbuch.}}'**
  String wordtilesUnknownBody(String words, int count);

  /// Word tiles: the joint decision after an unknown word (both players are at the device).
  ///
  /// In de, this message translates to:
  /// **'Ihr könnt die Steine zurücknehmen. Seid ihr euch einig, dass es trotzdem zählt, lasst es zu.'**
  String get wordtilesUnknownAsk;

  /// Word tiles: unknown word notice, the tiles go back to the rack and the turn goes on.
  ///
  /// In de, this message translates to:
  /// **'Zurücknehmen'**
  String get wordtilesUnknownWithdraw;

  /// Word tiles: unknown word notice, the players agree the word counts (house rule).
  ///
  /// In de, this message translates to:
  /// **'Trotzdem zulassen'**
  String get wordtilesUnknownAllow;

  /// Word tiles history: a placement with words the players allowed although the word list lacks them.
  ///
  /// In de, this message translates to:
  /// **'{words} für {score, plural, one{{score} Punkt} other{{score} Punkte}} (zugelassen: {allowed})'**
  String wordtilesMovePlaceAllowed(String words, int score, String allowed);

  /// Word tiles: the collapsible practice rows next to the rack ("Bänkchen") where a player tries out words; private like the rack.
  ///
  /// In de, this message translates to:
  /// **'Bänkchen'**
  String get wordtilesBench;

  /// Word tiles: tooltip, moves every tile from the practice rows back to the rack.
  ///
  /// In de, this message translates to:
  /// **'Alle Steine vom Bänkchen zurück'**
  String get wordtilesBenchClear;

  /// Word tiles: shown in the empty practice rows.
  ///
  /// In de, this message translates to:
  /// **'Zieh Steine hierher und probier Wörter aus.'**
  String get wordtilesBenchHint;

  /// Word tiles: one-time explanation of the bench ("Bänkchen"), step 1 of 3: what it is for. Plain words for children.
  ///
  /// In de, this message translates to:
  /// **'Das Bänkchen ist dein Notizzettel: Zieh Steine hierher und probier Wörter aus.'**
  String get wordtilesCoachBench1;

  /// Word tiles: bench explanation, step 2: it shows only the letter points and does not check words.
  ///
  /// In de, this message translates to:
  /// **'Hier zählen nur die Punkte der Buchstaben. Ob es ein echtes Wort ist, prüft das Bänkchen nicht.'**
  String get wordtilesCoachBench2;

  /// Word tiles: bench explanation, step 3: the button shown next to the text (an arrow down) puts all tiles back; the bench is private.
  ///
  /// In de, this message translates to:
  /// **'Mit diesem Knopf legst du alle Steine zurück. Dein Bänkchen siehst nur du.'**
  String get wordtilesCoachBench3;

  /// Word tiles: bench explanation, step counter in the title ("1 von 3").
  ///
  /// In de, this message translates to:
  /// **'{step} von {count}'**
  String wordtilesCoachStep(int step, int count);

  /// Word tiles: bench explanation, button to the next step.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get wordtilesCoachNext;

  /// Word tiles: bench explanation, button on the last step that closes it.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get wordtilesCoachDone;

  /// Word tiles: bench explanation, button that closes it before the last step.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get wordtilesCoachSkip;

  /// Word tiles: title of the light confirmation before passing.
  ///
  /// In de, this message translates to:
  /// **'Passen?'**
  String get wordtilesPassTitle;

  /// Word tiles: pass confirmation. count = scoreless turns in a row including this pass; limit = scoreless turns that end the game (6).
  ///
  /// In de, this message translates to:
  /// **'Dein Zug endet ohne Punkte. Züge ohne Punkte in Folge: {count} von {limit}. Bei {limit} ist das Spiel aus.'**
  String wordtilesPassBody(int count, int limit);

  /// Word tiles: blank letter picker, reminds that the blank scores nothing.
  ///
  /// In de, this message translates to:
  /// **'Der Joker zählt 0 Punkte.'**
  String get wordtilesBlankScore;

  /// Word tiles rules sheet: the basic idea.
  ///
  /// In de, this message translates to:
  /// **'Legt Wörter wie im Kreuzworträtsel. Jeder Buchstabe hat Punkte (die kleine Zahl). Das erste Wort geht über den Stern in der Mitte, jedes weitere schließt an.'**
  String get wordtilesHelpGoal;

  /// Word tiles rules sheet: heading of the premium squares legend.
  ///
  /// In de, this message translates to:
  /// **'Bonusfelder'**
  String get wordtilesHelpPremium;

  /// Word tiles rules sheet: what the double letter square (2B) does.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe zählt doppelt'**
  String get wordtilesHelpDoubleLetter;

  /// Word tiles rules sheet: what the triple letter square (3B) does.
  ///
  /// In de, this message translates to:
  /// **'Buchstabe zählt dreifach'**
  String get wordtilesHelpTripleLetter;

  /// Word tiles rules sheet: what the double word square (2W) does.
  ///
  /// In de, this message translates to:
  /// **'ganzes Wort zählt doppelt'**
  String get wordtilesHelpDoubleWord;

  /// Word tiles rules sheet: what the triple word square (3W) does.
  ///
  /// In de, this message translates to:
  /// **'ganzes Wort zählt dreifach'**
  String get wordtilesHelpTripleWord;

  /// Word tiles rules sheet: premium squares count only in the turn a tile is laid on them.
  ///
  /// In de, this message translates to:
  /// **'Bonusfelder zählen nur in dem Zug, in dem ein Stein darauf gelegt wird.'**
  String get wordtilesHelpPremiumOnce;

  /// Word tiles rules sheet: the bonus for laying the whole rack. count = rack size (7), bonus = 50.
  ///
  /// In de, this message translates to:
  /// **'Alle {count} Steine in einem Zug gelegt: {bonus} Punkte extra.'**
  String wordtilesHelpBingo(int count, int bonus);

  /// Word tiles rules sheet: the blank tile.
  ///
  /// In de, this message translates to:
  /// **'Der Joker (leerer Stein) wird zu jedem Buchstaben, den du wählst, zählt aber 0 Punkte. Er zeigt eine kleine 0.'**
  String get wordtilesHelpBlank;

  /// Word tiles rules sheet: swapping tiles. count = tiles that must be in the bag (7).
  ///
  /// In de, this message translates to:
  /// **'Tauschen: Steine zurück in den Beutel, neue ziehen. Geht nur, solange mindestens {count} Steine im Beutel sind, und kostet den Zug.'**
  String wordtilesHelpSwap(int count);

  /// Word tiles rules sheet: passing. limit = scoreless turns in a row that end the game (6).
  ///
  /// In de, this message translates to:
  /// **'Passen: Du setzt einen Zug aus. Nach {limit} Zügen in Folge ohne Punkte ist das Spiel aus.'**
  String wordtilesHelpPass(int limit);

  /// Word tiles rules sheet: the dictionary check and "Trotzdem zulassen" (keep the button names in quotes as in wordtilesOptionDictionary / wordtilesUnknownAllow).
  ///
  /// In de, this message translates to:
  /// **'Mit „Wörterbuch prüfen“ wird jedes Wort beim Legen nachgeschlagen. Steht eins nicht drin, nehmt ihr die Steine zurück oder lasst es gemeinsam zu: „Trotzdem zulassen“. Zugelassene Wörter stehen im Verlauf.'**
  String get wordtilesHelpDictionary;

  /// Word tiles rules sheet: challenging without the dictionary.
  ///
  /// In de, this message translates to:
  /// **'Ohne Wörterbuch kann das letzte Wort angezweifelt werden: Dann kommen die Steine zurück und es gibt keine Punkte.'**
  String get wordtilesHelpChallenge;

  /// Word tiles rules sheet: the practice rows ("Bänkchen", see wordtilesBench).
  ///
  /// In de, this message translates to:
  /// **'Auf dem Bänkchen probierst du Wörter aus. Es zeigt nur die Punkte der Buchstaben, nicht ob es ein Wort ist.'**
  String get wordtilesHelpBench;

  /// Word tiles rules sheet: two fingers zoom and move the board; a tile laid this turn moves by dragging it, no hold (KLD-094 step 8h); a tap takes it back.
  ///
  /// In de, this message translates to:
  /// **'Mit zwei Fingern zoomst du das Brett und schiebst es hin und her. Einen eben gelegten Stein ziehst du einfach woandershin; antippen nimmt ihn zurück.'**
  String get wordtilesHelpZoom;

  /// Word tiles rules sheet: how the game ends and the rack penalties.
  ///
  /// In de, this message translates to:
  /// **'Das Spiel ist aus, wenn der Beutel leer ist und jemand alle Steine gelegt hat. Die Punkte der übrigen Steine werden abgezogen; wer fertig ist, bekommt sie dazu.'**
  String get wordtilesHelpEnd;

  /// Word tiles result: points for the tiles left on a rack at the end (negative), or gained by the player who went out (positive). points = signed number, e.g. "−7" or "+12".
  ///
  /// In de, this message translates to:
  /// **'Reststeine: {points}'**
  String wordtilesResultRack(String points);

  /// Word tiles result: the highest-scoring single word of the game. word = the word, player = who laid it, score = its points.
  ///
  /// In de, this message translates to:
  /// **'Bestes Wort: {word} ({player}, {score, plural, one{{score} Punkt} other{{score} Punkte}})'**
  String wordtilesResultBestWord(String word, String player, int score);

  /// Word tiles result: words the players let stand with "Trotzdem zulassen" during the game. words = comma separated.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem zugelassen: {words}'**
  String wordtilesResultAllowed(String words);

  /// Result reason (word tiles): a player laid the last tile with the bag empty; a, b = final scores.
  ///
  /// In de, this message translates to:
  /// **'Alle Steine gelegt, Endstand {a} : {b}'**
  String engineReasonWordtilesPlayedOut(int a, int b);

  /// Result reason (word tiles): too many turns in a row without points (turns = 6); a, b = final scores.
  ///
  /// In de, this message translates to:
  /// **'{turns} Züge ohne Punkte, Endstand {a} : {b}'**
  String engineReasonWordtilesScoreless(int turns, int a, int b);

  /// KLD-108: small badge next to "Klunki" in the menu app bar, only in the GitHub Pages web build (KLUNKI_WEB_CHANNEL=pages-beta).
  ///
  /// In de, this message translates to:
  /// **'Beta'**
  String get webBetaBadge;

  /// KLD-108: one line in "Über Klunki", only in the GitHub Pages web build.
  ///
  /// In de, this message translates to:
  /// **'Web-Beta – Spiele mit mehreren Geräten gibt es in der App.'**
  String get aboutWebBeta;

  /// KLD-108: sheet when a greyed-out "Mit anderen" / "Raum starten" / "Raum beitreten" is tapped in a browser that cannot reach a relay (https page, no wss:// relay).
  ///
  /// In de, this message translates to:
  /// **'Im Browser noch nicht verfügbar – mit der App könnt ihr auf mehreren Geräten spielen.'**
  String get networkUnavailableWeb;

  /// KLD-108: teaser line under networkUnavailableWeb.
  ///
  /// In de, this message translates to:
  /// **'App-Beta in Vorbereitung.'**
  String get appBetaTeaser;

  /// KLD-108: button in the sheet, only when a test link for iPhone/iPad is configured (KLUNKI_IOS_BETA_URL).
  ///
  /// In de, this message translates to:
  /// **'App für iPhone und iPad testen'**
  String get appBetaIos;

  /// KLD-108: button in the sheet, only when an Android download link is configured (KLUNKI_ANDROID_URL).
  ///
  /// In de, this message translates to:
  /// **'App für Android laden'**
  String get appBetaAndroid;

  /// KLD-094 step 6: the options of a network Wortgewandt game in one line (room and game header): tile language endonym ("Deutsch", "English") and the word list on.
  ///
  /// In de, this message translates to:
  /// **'{language} · Wörterbuch prüfen'**
  String wordtilesOptionsSummaryDict(String language);

  /// KLD-094 step 6: like wordtilesOptionsSummaryDict, without the word list (challenge mode).
  ///
  /// In de, this message translates to:
  /// **'{language} · ohne Wörterbuch'**
  String wordtilesOptionsSummaryFree(String language);

  /// Word tiles: like wordtilesOpenPlacement, when that placement came with "Joker tauschen" (KLD-094 step 9).
  ///
  /// In de, this message translates to:
  /// **'{player} legte {words} für {score, plural, one{{score} Punkt} other{{score} Punkte}} (Joker getauscht).'**
  String wordtilesOpenPlacementJoker(String player, String words, int score);

  /// Word tiles start options: switch for the house rule 'Joker tauschen' (KLD-094 step 9): a player holding the letter a laid blank stands for may put it there and take the blank.
  ///
  /// In de, this message translates to:
  /// **'Joker tauschen'**
  String get wordtilesOptionJoker;

  /// Word tiles start options: the line under the 'Joker tauschen' switch that explains the house rule (off by default).
  ///
  /// In de, this message translates to:
  /// **'Hausregel: Wer den Buchstaben hat, für den ein Joker auf dem Brett steht, darf ihn dorthin legen und den Joker nehmen. Danach legt man im selben Zug noch Steine.'**
  String get wordtilesOptionJokerExplain;

  /// Word tiles: the options line of a network game (wordtilesOptionsSummaryDict / Free) when the host turned on 'Joker tauschen'; {summary} is that line.
  ///
  /// In de, this message translates to:
  /// **'{summary} · Joker tauschen'**
  String wordtilesOptionsSummaryJoker(String summary);

  /// Word tiles hint line ('Joker tauschen' on): the player to move holds a letter that a blank on the board stands for.
  ///
  /// In de, this message translates to:
  /// **'Ziehe den passenden Buchstaben auf einen Joker auf dem Brett, um den Joker zu nehmen.'**
  String get wordtilesHintJoker;

  /// Word tiles: the line under the board after a staged 'Joker tauschen' while no tile is laid yet; the swap only counts together with a placement.
  ///
  /// In de, this message translates to:
  /// **'Joker genommen. Lege jetzt noch Steine, sonst gilt der Tausch nicht.'**
  String get wordtilesJokerStaged;

  /// Word tiles history: a placement that came with 'Joker tauschen'; {move} is the placement text (wordtilesMovePlace).
  ///
  /// In de, this message translates to:
  /// **'{move} (Joker getauscht)'**
  String wordtilesMoveJoker(String move);

  /// KLD-094 step 6: the unknown-word notice over the network (instead of wordtilesUnknownAsk): "Trotzdem zulassen" sends a request to the other player ({player}).
  ///
  /// In de, this message translates to:
  /// **'Du kannst die Steine zurücknehmen oder {player} fragen, ob es trotzdem zählt.'**
  String wordtilesUnknownAskNet(String player);

  /// KLD-094 step 6: the unknown-word notice when the other player ({player}) already declined these words in this turn: only "Zurücknehmen" is left.
  ///
  /// In de, this message translates to:
  /// **'{player} hat das schon abgelehnt. Nimm die Steine zurück.'**
  String wordtilesUnknownDeclinedBefore(String player);

  /// KLD-094 step 6: title of the dialog on the other device when a player asks to allow a word the list lacks.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem zulassen?'**
  String get wordtilesAllowTitle;

  /// KLD-094 step 6: the request dialog: {player} (who laid the tiles) asks to allow {words}; the reader answers with Annehmen / Ablehnen. Placeholders keep their quotes as in German.
  ///
  /// In de, this message translates to:
  /// **'{player} möchte „{words}“ zulassen – einverstanden?'**
  String wordtilesAllowBody(String player, String words);

  /// KLD-094 step 6: button in the request dialog: agree, the word counts.
  ///
  /// In de, this message translates to:
  /// **'Annehmen'**
  String get wordtilesAllowAccept;

  /// KLD-094 step 6: button in the request dialog: the tiles go back, the other player is still on turn.
  ///
  /// In de, this message translates to:
  /// **'Ablehnen'**
  String get wordtilesAllowDecline;

  /// KLD-094 step 6: status line of the player who asked, while {player} decides about the request.
  ///
  /// In de, this message translates to:
  /// **'{player} entscheidet…'**
  String wordtilesAllowDeciding(String player);

  /// KLD-094 step 6: status line of the player who has to answer a request.
  ///
  /// In de, this message translates to:
  /// **'Du entscheidest'**
  String get wordtilesAllowYouDecide;

  /// KLD-094 step 6: the line above the board on both devices while a request is open.
  ///
  /// In de, this message translates to:
  /// **'{player} möchte „{words}“ zulassen ({score, plural, one{{score} Punkt} other{{score} Punkte}}).'**
  String wordtilesAllowLine(String player, String words, int score);

  /// KLD-094 step 6: the line above the board right after {player} declined a request.
  ///
  /// In de, this message translates to:
  /// **'{player} lehnt „{words}“ ab.'**
  String wordtilesAllowDeclined(String player, String words);

  /// KLD-094 step 6: history entry after "{player}: " for a request to allow words.
  ///
  /// In de, this message translates to:
  /// **'möchte {words} zulassen ({score, plural, one{{score} Punkt} other{{score} Punkte}})'**
  String wordtilesMoveAllowRequest(String words, int score);

  /// KLD-094 step 6: history entry after "{player}: " when the other player agreed (the placement counts).
  ///
  /// In de, this message translates to:
  /// **'einverstanden: {words} zählt ({score, plural, one{{score} Punkt} other{{score} Punkte}})'**
  String wordtilesMoveAllowAccept(String words, int score);

  /// KLD-094 step 6: history entry after "{player}: " when the other player declined a request.
  ///
  /// In de, this message translates to:
  /// **'abgelehnt: {words}'**
  String wordtilesMoveAllowDecline(String words);

  /// Game title: the traditional shedding card game Mau-Mau (KLD-118). A traditional generic name; keep "Mau-Mau" unless the language has its own common name for this game.
  ///
  /// In de, this message translates to:
  /// **'Mau-Mau'**
  String get menuGameMauMau;

  /// Menu tile one-liner for Mau-Mau (KLD-118).
  ///
  /// In de, this message translates to:
  /// **'Passende Karten ablegen, bis keine mehr übrig ist'**
  String get menuDescMauMau;

  /// Result reason (Mau-Mau, KLD-118): the winner laid the last card.
  ///
  /// In de, this message translates to:
  /// **'Alle Karten abgelegt'**
  String get engineReasonMaumauEmptyHand;

  /// Mau-Mau (KLD-118): the suit clubs of the French deck, used in card names and on its own (suit picker, "Wunsch: …").
  ///
  /// In de, this message translates to:
  /// **'Kreuz'**
  String get maumauSuitClubs;

  /// Mau-Mau (KLD-118): the suit spades of the French deck, used in card names and on its own (suit picker, "Wunsch: …").
  ///
  /// In de, this message translates to:
  /// **'Pik'**
  String get maumauSuitSpades;

  /// Mau-Mau (KLD-118): the suit hearts of the French deck, used in card names and on its own (suit picker, "Wunsch: …").
  ///
  /// In de, this message translates to:
  /// **'Herz'**
  String get maumauSuitHearts;

  /// Mau-Mau (KLD-118): the suit diamonds of the French deck, used in card names and on its own (suit picker, "Wunsch: …").
  ///
  /// In de, this message translates to:
  /// **'Karo'**
  String get maumauSuitDiamonds;

  /// Mau-Mau (KLD-118): the rank jack as a word in a sentence (card names like "Pik Bube").
  ///
  /// In de, this message translates to:
  /// **'Bube'**
  String get maumauRankJack;

  /// Mau-Mau (KLD-118): the rank queen as a word in a sentence (card names like "Pik Bube").
  ///
  /// In de, this message translates to:
  /// **'Dame'**
  String get maumauRankQueen;

  /// Mau-Mau (KLD-118): the rank king as a word in a sentence (card names like "Pik Bube").
  ///
  /// In de, this message translates to:
  /// **'König'**
  String get maumauRankKing;

  /// Mau-Mau (KLD-118): the rank ace as a word in a sentence (card names like "Pik Bube").
  ///
  /// In de, this message translates to:
  /// **'Ass'**
  String get maumauRankAce;

  /// Mau-Mau (KLD-118): the one-letter index of the jack printed in the card corners (de B/D/K/A, en J/Q/K/A, fr V/D/R/A). Exactly one character.
  ///
  /// In de, this message translates to:
  /// **'B'**
  String get maumauRankLetterJack;

  /// Mau-Mau (KLD-118): the one-letter index of the queen printed in the card corners (de B/D/K/A, en J/Q/K/A, fr V/D/R/A). Exactly one character.
  ///
  /// In de, this message translates to:
  /// **'D'**
  String get maumauRankLetterQueen;

  /// Mau-Mau (KLD-118): the one-letter index of the king printed in the card corners (de B/D/K/A, en J/Q/K/A, fr V/D/R/A). Exactly one character.
  ///
  /// In de, this message translates to:
  /// **'K'**
  String get maumauRankLetterKing;

  /// Mau-Mau (KLD-118): the one-letter index of the ace printed in the card corners (de B/D/K/A, en J/Q/K/A, fr V/D/R/A). Exactly one character.
  ///
  /// In de, this message translates to:
  /// **'A'**
  String get maumauRankLetterAce;

  /// Mau-Mau (KLD-118): a card in a sentence, e.g. "Herz 7", "Pik Bube". suit = maumauSuit*, rank = "7"…"10" or maumauRank*.
  ///
  /// In de, this message translates to:
  /// **'{suit} {rank}'**
  String maumauCardName(String suit, String rank);

  /// Mau-Mau start options (KLD-118): line above the house-rule switches.
  ///
  /// In de, this message translates to:
  /// **'Welche Regeln sollen gelten?'**
  String get maumauOptionsIntro;

  /// Mau-Mau start options (KLD-118): button that goes on to "Wer spielt?".
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get maumauOptionsNext;

  /// Mau-Mau house rule switch (KLD-118): a 7 makes the next player draw two cards.
  ///
  /// In de, this message translates to:
  /// **'7: zwei Karten ziehen'**
  String get maumauOptionSeven;

  /// Explains maumauOptionSeven. "der andere" = the other player; no gendered words for players in other languages.
  ///
  /// In de, this message translates to:
  /// **'Nach einer 7 muss der andere 2 Karten ziehen.'**
  String get maumauOptionSevenExplain;

  /// Mau-Mau house rule switch (KLD-118): sevens can be stacked.
  ///
  /// In de, this message translates to:
  /// **'7 auf 7'**
  String get maumauOptionStack;

  /// Explains maumauOptionStack.
  ///
  /// In de, this message translates to:
  /// **'Wer selbst eine 7 hat, legt sie drauf. Dann muss der andere 4 Karten ziehen.'**
  String get maumauOptionStackExplain;

  /// Mau-Mau house rule switch (KLD-118): an 8 makes the next player miss a turn.
  ///
  /// In de, this message translates to:
  /// **'8: aussetzen'**
  String get maumauOptionEight;

  /// Explains maumauOptionEight.
  ///
  /// In de, this message translates to:
  /// **'Nach einer 8 muss der andere einmal aussetzen.'**
  String get maumauOptionEightExplain;

  /// Mau-Mau start options (KLD-118): the jack rule, always on (a plain line, not a switch). "Farbe" = suit.
  ///
  /// In de, this message translates to:
  /// **'Bube: passt fast immer. Wer ihn legt, wünscht sich eine Farbe.'**
  String get maumauOptionJackInfo;

  /// Mau-Mau house rule switch (KLD-118): a jack may be laid on a jack.
  ///
  /// In de, this message translates to:
  /// **'Bube auf Bube'**
  String get maumauOptionJackOnJack;

  /// Explains maumauOptionJackOnJack.
  ///
  /// In de, this message translates to:
  /// **'Ein Bube darf auch auf einem Buben liegen.'**
  String get maumauOptionJackOnJackExplain;

  /// Mau-Mau house rule switch (KLD-118): an ace lets the same player lay again.
  ///
  /// In de, this message translates to:
  /// **'Ass: noch mal'**
  String get maumauOptionAce;

  /// Explains maumauOptionAce.
  ///
  /// In de, this message translates to:
  /// **'Wer ein Ass legt, ist gleich noch mal dran.'**
  String get maumauOptionAceExplain;

  /// Mau-Mau house rule switch (KLD-118): say "Mau!" on the second-to-last card. "Mau!" stays as it is.
  ///
  /// In de, this message translates to:
  /// **'„Mau!“ sagen'**
  String get maumauOptionMau;

  /// Explains maumauOptionMau.
  ///
  /// In de, this message translates to:
  /// **'Bei der vorletzten Karte erst „Mau!“ drücken. Wer es vergisst, zieht eine Strafkarte.'**
  String get maumauOptionMauExplain;

  /// Mau-Mau (KLD-118): the other player's hand size next to the card backs.
  ///
  /// In de, this message translates to:
  /// **'{player}: {count, plural, =1{1 Karte} other{{count} Karten}}'**
  String maumauOpponentCards(String player, int count);

  /// Mau-Mau (KLD-118): heading over the own hand (hot-seat: the player to move).
  ///
  /// In de, this message translates to:
  /// **'Deine Karten ({count})'**
  String maumauYourCards(int count);

  /// Mau-Mau (KLD-118): label under the face-down draw pile.
  ///
  /// In de, this message translates to:
  /// **'Stapel: {count}'**
  String maumauStock(int count);

  /// Mau-Mau (KLD-118): screen-reader label of the draw pile.
  ///
  /// In de, this message translates to:
  /// **'Stapel zum Ziehen, {count, plural, =1{1 Karte} other{{count} Karten}}'**
  String maumauStockLabel(int count);

  /// Mau-Mau (KLD-118): label under the face-up discard pile.
  ///
  /// In de, this message translates to:
  /// **'Ablage'**
  String get maumauDiscard;

  /// Mau-Mau (KLD-118): badge under the discard pile after a jack; suit = maumauSuit*.
  ///
  /// In de, this message translates to:
  /// **'Wunsch: {suit}'**
  String maumauWish(String suit);

  /// Mau-Mau (KLD-118): button that draws a card.
  ///
  /// In de, this message translates to:
  /// **'Karte ziehen'**
  String get maumauDraw;

  /// Mau-Mau (KLD-118): button (and badge under the pile) when a 7 makes the player draw count (2, 4, …) cards.
  ///
  /// In de, this message translates to:
  /// **'{count} Karten ziehen'**
  String maumauDrawPenalty(int count);

  /// Mau-Mau (KLD-118): button that keeps a drawn card that would fit (ends the turn).
  ///
  /// In de, this message translates to:
  /// **'Behalten'**
  String get maumauKeep;

  /// Mau-Mau (KLD-118): button when nothing is left to draw and no card fits.
  ///
  /// In de, this message translates to:
  /// **'Passen'**
  String get maumauPass;

  /// Mau-Mau (KLD-118): toggle button, pressed before laying the second-to-last card. Usually kept as "Mau!".
  ///
  /// In de, this message translates to:
  /// **'Mau!'**
  String get maumauMauButton;

  /// Mau-Mau (KLD-118): button under drawn cards that ends the turn.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get maumauContinue;

  /// Mau-Mau (KLD-118): title of the suit picker after laying a jack. "Farbe" = suit.
  ///
  /// In de, this message translates to:
  /// **'Welche Farbe wünschst du dir?'**
  String get maumauPickSuitTitle;

  /// Mau-Mau (KLD-118): shown to the drawer over the drawn card when it does not fit (the turn ends).
  ///
  /// In de, this message translates to:
  /// **'Gezogen – die Karte passt leider nicht.'**
  String get maumauDrewNoFit;

  /// Mau-Mau (KLD-118): shown after drawing the cards of a 7 (chain); the hand below shows the new cards framed.
  ///
  /// In de, this message translates to:
  /// **'Du hast {count, plural, =1{1 Karte} other{{count} Karten}} gezogen. Neu in deiner Hand:'**
  String maumauDrewPenalty(int count);

  /// Mau-Mau hint line (KLD-118): the normal turn.
  ///
  /// In de, this message translates to:
  /// **'Lege eine passende Karte oder ziehe eine.'**
  String get maumauHintPlay;

  /// Mau-Mau hint line (KLD-118): a jack wished a suit.
  ///
  /// In de, this message translates to:
  /// **'Gewünscht ist {suit}. Lege so eine Karte oder ziehe eine.'**
  String maumauHintWish(String suit);

  /// Mau-Mau hint line (KLD-118): a 7 was laid and the player has no 7 to answer.
  ///
  /// In de, this message translates to:
  /// **'Du musst {count} Karten ziehen.'**
  String maumauHintPenalty(int count);

  /// Mau-Mau hint line (KLD-118): a 7 was laid and the player may answer with a 7.
  ///
  /// In de, this message translates to:
  /// **'Lege eine 7 oder ziehe {count} Karten.'**
  String maumauHintPenaltyStack(int count);

  /// Mau-Mau hint line (KLD-118): the drawn card fits.
  ///
  /// In de, this message translates to:
  /// **'Die gezogene Karte passt. Lege sie oder behalte sie.'**
  String get maumauHintDrawn;

  /// Mau-Mau hint line (KLD-118): no card left to draw and none fits.
  ///
  /// In de, this message translates to:
  /// **'Nichts mehr zum Ziehen. Du musst passen.'**
  String get maumauHintPass;

  /// Mau-Mau hint line (KLD-118, house rule "Mau"): before the second-to-last card.
  ///
  /// In de, this message translates to:
  /// **'Vorletzte Karte: erst „Mau!“ drücken, dann legen.'**
  String get maumauHintMau;

  /// Mau-Mau (KLD-118): what happened last; card = maumauCardName. No gendered words for the player.
  ///
  /// In de, this message translates to:
  /// **'{player} hat {card} gelegt.'**
  String maumauLastPlayed(String player, String card);

  /// Mau-Mau (KLD-118): a jack was laid with a wish.
  ///
  /// In de, this message translates to:
  /// **'{player} hat {card} gelegt und wünscht sich {suit}.'**
  String maumauLastPlayedWish(String player, String card, String suit);

  /// Mau-Mau (KLD-118): the player drew cards (never says which).
  ///
  /// In de, this message translates to:
  /// **'{player} hat {count, plural, =1{eine Karte} other{{count} Karten}} gezogen.'**
  String maumauLastDrew(String player, int count);

  /// Mau-Mau (KLD-118): the player drew the cards of a 7.
  ///
  /// In de, this message translates to:
  /// **'{player} hat {count, plural, =1{eine Strafkarte} other{{count} Strafkarten}} gezogen.'**
  String maumauLastDrewPenalty(String player, int count);

  /// Mau-Mau (KLD-118): the player drew a fitting card and kept it.
  ///
  /// In de, this message translates to:
  /// **'{player} hat eine Karte gezogen und behalten.'**
  String maumauLastKept(String player);

  /// Mau-Mau (KLD-118): nothing left to draw, the player passed.
  ///
  /// In de, this message translates to:
  /// **'{player} hat gepasst.'**
  String maumauLastPassed(String player);

  /// Mau-Mau (KLD-118, house rule): the player said "Mau!" with the second-to-last card.
  ///
  /// In de, this message translates to:
  /// **'„Mau!“, sagt {player}.'**
  String maumauExtraMau(String player);

  /// Mau-Mau (KLD-118, house rule): the player forgot "Mau!".
  ///
  /// In de, this message translates to:
  /// **'{player} hat „Mau!“ vergessen und zieht eine Strafkarte.'**
  String maumauExtraForgotMau(String player);

  /// Mau-Mau (KLD-118): after a 7; player = the one who has to draw. French: "À {player} de …" (no "que" before the name).
  ///
  /// In de, this message translates to:
  /// **'{player} muss {count} Karten ziehen.'**
  String maumauExtraPenalty(String player, int count);

  /// Coach marks (KLD-118, reusable "how to play" tour): button to the next step.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get coachNext;

  /// Coach marks: button on the last step that closes the tour and starts playing.
  ///
  /// In de, this message translates to:
  /// **'Los geht’s!'**
  String get coachDone;

  /// Coach marks: button that closes the tour early.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get coachSkip;

  /// Mau-Mau tour step 1, pointing at the own hand.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine passende Karte, um sie zu legen. Passende Karten stehen höher und haben einen Rahmen.'**
  String get maumauCoachPlay;

  /// Mau-Mau tour step 2, pointing at the draw pile (tapping it draws).
  ///
  /// In de, this message translates to:
  /// **'Passt keine? Dann tippe auf den Stapel und ziehe eine Karte.'**
  String get maumauCoachDraw;

  /// Mau-Mau tour step 3 (no "Mau!" house rule).
  ///
  /// In de, this message translates to:
  /// **'Wer zuerst keine Karten mehr hat, gewinnt.'**
  String get maumauCoachWin;

  /// Mau-Mau tour step 3 with the "Mau!" house rule on.
  ///
  /// In de, this message translates to:
  /// **'Wer zuerst keine Karten mehr hat, gewinnt. Vor der vorletzten Karte „Mau!“ drücken.'**
  String get maumauCoachWinMau;

  /// Mau-Mau: badge under the discard pile while several 7s are stacked; sum = "2 + 2 + 2" (2 per 7), count = the total to draw (4, 6 or 8).
  ///
  /// In de, this message translates to:
  /// **'{sum} = {count} Karten ziehen'**
  String maumauChainBadge(String sum, int count);

  /// Mau-Mau: after a 7 laid on a 7 (the draw penalty adds up); player = the one who has to draw, count = the new total (4, 6, 8). French: "à {player} de …".
  ///
  /// In de, this message translates to:
  /// **'Die 7er zählen zusammen: {player} muss jetzt {count} Karten ziehen.'**
  String maumauExtraPenaltyStacked(String player, int count);

  /// Mau-Mau (KLD-118): after an 8; player = the one who misses the turn.
  ///
  /// In de, this message translates to:
  /// **'{player} muss aussetzen.'**
  String maumauExtraAgain(String player);

  /// Mau-Mau (KLD-118): after an ace (on by default): the same player lays again; player = the one who laid the ace.
  ///
  /// In de, this message translates to:
  /// **'{player} ist gleich noch mal dran.'**
  String maumauExtraAce(String player);

  /// Mau-Mau (KLD-118): the draw pile ran out; the discard pile became the new draw pile.
  ///
  /// In de, this message translates to:
  /// **'Die Ablage wurde neu gemischt.'**
  String get maumauExtraReshuffled;

  /// Mau-Mau history entry after "{player}: " (KLD-118).
  ///
  /// In de, this message translates to:
  /// **'legt {card}'**
  String maumauMovePlay(String card);

  /// Mau-Mau history entry after "{player}: " for a jack (KLD-118).
  ///
  /// In de, this message translates to:
  /// **'legt {card}, wünscht sich {suit}'**
  String maumauMovePlayWish(String card, String suit);

  /// Mau-Mau history entry after "{player}: " (KLD-118).
  ///
  /// In de, this message translates to:
  /// **'zieht {count, plural, =1{eine Karte} other{{count} Karten}}'**
  String maumauMoveDraw(int count);

  /// Mau-Mau history entry after "{player}: " (KLD-118).
  ///
  /// In de, this message translates to:
  /// **'passt'**
  String get maumauMovePass;

  /// Mau-Mau history entry after "{player}: " (KLD-118).
  ///
  /// In de, this message translates to:
  /// **'behält die gezogene Karte'**
  String get maumauMoveKeep;

  /// Game title: the dice bluffing game (KLD-121), traditional German name Mäxchen (also Meiern). Other languages: the name this game has there (en Mia), no brand names.
  ///
  /// In de, this message translates to:
  /// **'Mäxchen'**
  String get menuGameMaexchen;

  /// Menu tile one-liner for Mäxchen (KLD-121).
  ///
  /// In de, this message translates to:
  /// **'Würfeln, flunkern, durchschauen'**
  String get menuDescMaexchen;

  /// Result reason (Mäxchen, KLD-121): the losing player has no lives left.
  ///
  /// In de, this message translates to:
  /// **'Keine Leben mehr übrig'**
  String get engineReasonMaexchenNoLives;

  /// Mäxchen start option: how many lives each player has at the start (3 or 5).
  ///
  /// In de, this message translates to:
  /// **'Leben zu Beginn'**
  String get maexchenOptionLives;

  /// Mäxchen start option (house rule, on by default): everything about Mäxchen counts double (a doubted real Mäxchen costs the doubter 2 lives, a caught fake Mäxchen costs the bluffer 2). Mäxchen = the highest roll, 2 and 1.
  ///
  /// In de, this message translates to:
  /// **'Mäxchen doppelt'**
  String get maexchenOptionDouble;

  /// Explains the house rule "Mäxchen doppelt" under its switch: both cases cost 2 lives.
  ///
  /// In de, this message translates to:
  /// **'Alles mit Mäxchen zählt doppelt: Wer ein echtes Mäxchen anzweifelt oder mit einem falschen Mäxchen erwischt wird, verliert 2 Leben.'**
  String get maexchenOptionDoubleExplain;

  /// Button that closes the Mäxchen start options and goes on to the player names.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get maexchenOptionsNext;

  /// Mäxchen button: shake the cup (roll the two dice under it).
  ///
  /// In de, this message translates to:
  /// **'Würfeln'**
  String get maexchenRoll;

  /// Mäxchen button: lift the cup to look at the own dice secretly.
  ///
  /// In de, this message translates to:
  /// **'Nachschauen'**
  String get maexchenPeek;

  /// Mäxchen button: put the cup back over the dice.
  ///
  /// In de, this message translates to:
  /// **'Becher zu'**
  String get maexchenCover;

  /// Mäxchen: heading over the values the player may announce.
  ///
  /// In de, this message translates to:
  /// **'Was sagst du an?'**
  String get maexchenPickTitle;

  /// Mäxchen button: announce the chosen value. value = e.g. "54" or the name of the highest value.
  ///
  /// In de, this message translates to:
  /// **'{value} ansagen'**
  String maexchenAnnounce(String value);

  /// Mäxchen: the order of the values, low to high, under the announcement picker. "Pasch" = doubles.
  ///
  /// In de, this message translates to:
  /// **'Von klein nach groß: 31, 32 … 65, dann Pasch 11 … 66, dann Mäxchen (21).'**
  String get maexchenOrder;

  /// Mäxchen button: believe the announcement (then roll and announce higher).
  ///
  /// In de, this message translates to:
  /// **'Glauben'**
  String get maexchenBelieve;

  /// Mäxchen button: doubt the announcement; the cup is lifted.
  ///
  /// In de, this message translates to:
  /// **'Anzweifeln'**
  String get maexchenDoubt;

  /// Mäxchen button after an announced Mäxchen: lose one life without lifting the cup. Not "Aufgeben" (that is resigning the game).
  ///
  /// In de, this message translates to:
  /// **'Leben abgeben'**
  String get maexchenGiveUp;

  /// Mäxchen: what the player announced, e.g. "Anna sagt 54". value = number or the name of the highest value.
  ///
  /// In de, this message translates to:
  /// **'{player} sagt {value}'**
  String maexchenAnnounced(String player, String value);

  /// Mäxchen: banner at the start of a round, no announcement yet.
  ///
  /// In de, this message translates to:
  /// **'Neue Runde: jede Zahl ist erlaubt'**
  String get maexchenNewRound;

  /// Mäxchen hint for the player who rolls.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf Würfeln, dann schau heimlich unter den Becher.'**
  String get maexchenHintRoll;

  /// Mäxchen hint after believing an announcement: roll and announce more. value = the announcement.
  ///
  /// In de, this message translates to:
  /// **'Du glaubst {value}. Würfle und sag mehr als {value} an.'**
  String maexchenHintBelieved(String value);

  /// Mäxchen hint for the roller at the start of a round.
  ///
  /// In de, this message translates to:
  /// **'Schau heimlich nach und sag eine Zahl an. Flunkern ist erlaubt!'**
  String get maexchenHintAnnounceFirst;

  /// Mäxchen hint for the roller: announce more than the last value. value = the last announcement.
  ///
  /// In de, this message translates to:
  /// **'Sag mehr als {value} an. Flunkern ist erlaubt!'**
  String maexchenHintAnnounceHigher(String value);

  /// Mäxchen hint for the player who answers an announcement.
  ///
  /// In de, this message translates to:
  /// **'{player} sagt {value}. Glaubst du das?'**
  String maexchenHintRespond(String player, String value);

  /// Mäxchen hint when the other player announced the highest value (Mäxchen): it cannot be beaten.
  ///
  /// In de, this message translates to:
  /// **'{player} sagt Mäxchen! Höher geht es nicht: anzweifeln oder ein Leben abgeben?'**
  String maexchenHintRespondMaexchen(String player);

  /// Mäxchen: the real value under the lifted cup. value = number or the name of the highest value.
  ///
  /// In de, this message translates to:
  /// **'Unter dem Becher: {value}'**
  String maexchenUnderCup(String value);

  /// Mäxchen reveal: the announcement was a lie; the player who announced it loses a life.
  ///
  /// In de, this message translates to:
  /// **'Geflunkert! {player} verliert ein Leben.'**
  String maexchenVerdictBluff(String player);

  /// Mäxchen reveal: the announcement was true; the doubting player loses a life.
  ///
  /// In de, this message translates to:
  /// **'Stimmt! {player} verliert ein Leben.'**
  String maexchenVerdictTrue(String player);

  /// Mäxchen reveal: a real Mäxchen was doubted (house rule on); the doubting player loses 2 lives.
  ///
  /// In de, this message translates to:
  /// **'Echtes Mäxchen! {player} verliert 2 Leben.'**
  String maexchenVerdictTrueTwo(String player);

  /// Mäxchen reveal: a fake Mäxchen was caught (house rule "Mäxchen doppelt" on); the player who announced it loses 2 lives.
  ///
  /// In de, this message translates to:
  /// **'Falsches Mäxchen! {player} verliert 2 Leben.'**
  String maexchenVerdictBluffTwo(String player);

  /// Mäxchen: the player gave up a life after an announced Mäxchen; the dice stay hidden.
  ///
  /// In de, this message translates to:
  /// **'{player} gibt ein Leben ab. Der Becher bleibt zu.'**
  String maexchenVerdictGaveUp(String player);

  /// Mäxchen: accessibility label of a player's hearts. count = lives left.
  ///
  /// In de, this message translates to:
  /// **'{player}: {count, plural, =1{1 Leben} other{{count} Leben}}'**
  String maexchenLivesOf(String player, int count);

  /// Mäxchen: the round number.
  ///
  /// In de, this message translates to:
  /// **'Runde {round}'**
  String maexchenRoundLabel(int round);

  /// Mäxchen move history: the player rolled.
  ///
  /// In de, this message translates to:
  /// **'würfelt'**
  String get maexchenMoveRoll;

  /// Mäxchen move history: the player announced a value.
  ///
  /// In de, this message translates to:
  /// **'sagt {value}'**
  String maexchenMoveAnnounce(String value);

  /// Mäxchen move history: the player believed the announcement.
  ///
  /// In de, this message translates to:
  /// **'glaubt es'**
  String get maexchenMoveBelieve;

  /// Mäxchen move history: the player doubted the announcement.
  ///
  /// In de, this message translates to:
  /// **'zweifelt an'**
  String get maexchenMoveDoubt;

  /// Mäxchen move history: the player gave up a life after an announced Mäxchen.
  ///
  /// In de, this message translates to:
  /// **'gibt ein Leben ab'**
  String get maexchenMoveGiveUp;

  /// Mäxchen: the name of the highest value (2 and 1), shown in the picker and inside sentences.
  ///
  /// In de, this message translates to:
  /// **'Mäxchen'**
  String get maexchenMaexchenName;

  /// Mäxchen: the big button label for announcing the highest value, called out loud.
  ///
  /// In de, this message translates to:
  /// **'Mäxchen!'**
  String get maexchenMaexchenCall;

  /// Mäxchen: small caption over the current announcement.
  ///
  /// In de, this message translates to:
  /// **'Angesagt'**
  String get maexchenAnnouncedLabel;

  /// Mäxchen: the announce button before a value is chosen (disabled); tells the player to pick a value first.
  ///
  /// In de, this message translates to:
  /// **'Wähle eine Zahl'**
  String get maexchenPickFirst;

  /// Dice games: small hint next to the roll button when shaking the phone rolls too (starts lowercase, follows the button).
  ///
  /// In de, this message translates to:
  /// **'oder schüttle das Handy'**
  String get maexchenShakeHint;

  /// Dice games: setting (switch) in the start options: shaking the phone rolls the dice.
  ///
  /// In de, this message translates to:
  /// **'Schütteln zum Würfeln'**
  String get shakeToRollSetting;

  /// Dice games: explanation under the shake-to-roll switch.
  ///
  /// In de, this message translates to:
  /// **'Schüttle das Handy wie einen Würfelbecher, statt auf Würfeln zu tippen.'**
  String get shakeToRollExplain;

  /// KLD-122: the setting "confirm move": a move only counts after the player taps confirmMoveCommit. Switch label in "Wer spielt?" (per player), on "Raum starten" (this device, network) and the tooltip of the in-game toggle.
  ///
  /// In de, this message translates to:
  /// **'Zug bestätigen'**
  String get confirmMoveSetting;

  /// KLD-122: explanation under the confirm-move switch; names the button confirmMoveCommit in quotes (keep it equal to that translation).
  ///
  /// In de, this message translates to:
  /// **'Ein Zug zählt erst nach einem Tipp auf „Ziehen“.'**
  String get confirmMoveHelper;

  /// KLD-122: button under the board that makes a pending (shown, not yet sent) move count. Short verb, matches the quote in confirmMoveHelper and confirmMoveHint.
  ///
  /// In de, this message translates to:
  /// **'Ziehen'**
  String get confirmMoveCommit;

  /// KLD-122: button next to confirmMoveCommit: takes the pending move back so the player can choose again. Short.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get confirmMoveBack;

  /// KLD-122: hint line while a move waits for confirmation; quotes confirmMoveCommit and confirmMoveBack.
  ///
  /// In de, this message translates to:
  /// **'Passt der Zug? Tippe auf „Ziehen“ oder „Zurück“.'**
  String get confirmMoveHint;

  /// KLD-122: snack bar after turning the confirm-move toggle on during a network game.
  ///
  /// In de, this message translates to:
  /// **'Zug bestätigen ist an.'**
  String get confirmMoveOn;

  /// KLD-122: snack bar after turning the confirm-move toggle off during a network game.
  ///
  /// In de, this message translates to:
  /// **'Zug bestätigen ist aus.'**
  String get confirmMoveOff;

  /// KLD-123: label of the rules button (book icon + this word) in every game's app bar and on each menu tile. One short word.
  ///
  /// In de, this message translates to:
  /// **'Regeln'**
  String get rulesButton;

  /// KLD-123: title of a game's rules page. game = game title, e.g. "Mühle".
  ///
  /// In de, this message translates to:
  /// **'Spielregeln: {game}'**
  String rulesTitle(String game);

  /// KLD-123: rules page section: how to win.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get rulesGoal;

  /// KLD-123: rules page section: what a player does on a turn.
  ///
  /// In de, this message translates to:
  /// **'So läuft ein Zug'**
  String get rulesTurn;

  /// KLD-123: rules page section: special rules.
  ///
  /// In de, this message translates to:
  /// **'Besondere Regeln'**
  String get rulesSpecial;

  /// KLD-123: rules page section (opened from the menu): the suggested house rules.
  ///
  /// In de, this message translates to:
  /// **'Hausregeln'**
  String get rulesHouse;

  /// KLD-123: rules page section (opened in a game): the house rules switched on in this game.
  ///
  /// In de, this message translates to:
  /// **'Hausregeln in diesem Spiel'**
  String get rulesHouseInGame;

  /// KLD-123: rules page, house rules section of a game without house rules.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Spiel gibt es keine Hausregeln.'**
  String get rulesHouseNoneForGame;

  /// KLD-123: rules page, house rules section when all house rules are off.
  ///
  /// In de, this message translates to:
  /// **'Gerade ist keine Hausregel an.'**
  String get rulesHouseNoneOn;

  /// KLD-123: rules page opened from the menu, under the house rules of a game where they are chosen before the start.
  ///
  /// In de, this message translates to:
  /// **'So ist es vorgeschlagen. Vor dem Spiel könnt ihr die Hausregeln ändern.'**
  String get rulesHouseMenuNote;

  /// KLD-123: tappable line under the status line for new players of a game; opens the rules page.
  ///
  /// In de, this message translates to:
  /// **'Neu hier? So geht’s'**
  String get rulesNewHere;

  /// KLD-123: last step of the Mau-Mau first-time tour, pointing at the rules button.
  ///
  /// In de, this message translates to:
  /// **'Alle Regeln findest du hier.'**
  String get rulesCoachHere;

  /// KLD-123: Four in a Row rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Bring 4 deiner Steine in eine Reihe: waagerecht, senkrecht oder schräg.'**
  String get rulesConnect4Goal;

  /// KLD-123: Four in a Row rules, a turn. Lines separated by \n are shown as a list.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Spalte. Dein Stein fällt nach unten auf den untersten freien Platz.\nDann ist der andere dran.\nSpieler 1 fängt an.'**
  String get rulesConnect4Turn;

  /// KLD-123: Four in a Row rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Das Brett hat 7 Spalten und 6 Reihen.\nIn eine volle Spalte passt kein Stein mehr.\nIst das Brett voll und keiner hat 4 in einer Reihe, ist es unentschieden.'**
  String get rulesConnect4Special;

  /// KLD-123: Nine Men's Morris rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Nimm dem anderen so lange Steine weg, bis er nur noch 2 hat. Oder sperr seine Steine ein, sodass er nicht mehr ziehen kann.'**
  String get rulesMuehleGoal;

  /// KLD-123: Nine Men's Morris rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Jeder hat 9 Steine. Spieler 1 fängt an.\nZuerst setzt ihr abwechselnd je einen Stein auf einen freien Punkt.\nSind alle Steine gesetzt, schiebst du einen Stein entlang einer Linie auf den freien Punkt daneben.\nHast du nur noch 3 Steine, darfst du springen: auf jeden freien Punkt.'**
  String get rulesMuehleTurn;

  /// KLD-123: Nine Men's Morris rules: what a mill is (next to a small picture).
  ///
  /// In de, this message translates to:
  /// **'3 Steine in einer Linie sind eine Mühle. Dann nimmst du dem anderen einen Stein weg.'**
  String get rulesMuehleMill;

  /// KLD-123: Nine Men's Morris rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Steine in einer Mühle sind geschützt. Nur wenn alle Steine des anderen in Mühlen stehen, darfst du einen davon nehmen.\nÖffnest du eine Mühle und schließt sie wieder, zählt sie noch einmal.\n50 Züge hintereinander ohne Wegnehmen (beide zusammengezählt): unentschieden.'**
  String get rulesMuehleSpecial;

  /// KLD-123: Quartett (Trumpf) rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Gewinne alle Karten. Wer keine Karte mehr hat, verliert.'**
  String get rulesTrumpfGoal;

  /// KLD-123: Quartett (Trumpf) rules, a turn (list, \n). Use "Runde" (round), never "Stich".
  ///
  /// In de, this message translates to:
  /// **'Jeder bekommt 16 Karten als verdeckten Stapel. Gespielt wird immer die oberste Karte.\nWer dran ist, wählt eine Eigenschaft seiner Karte, zum Beispiel die Geschwindigkeit.\nDer bessere Wert gewinnt die Runde. Meist ist der höhere besser, bei manchen der niedrigere. Das steht auf der Karte.\nWer die Runde gewinnt, legt beide Karten unter seinen Stapel und wählt als Nächstes.\nSpieler 1 wählt zuerst.'**
  String get rulesTrumpfTurn;

  /// KLD-123: Quartett (Trumpf) rules, special rules (list, \n). German: a tie is "Stechen", never "Stich".
  ///
  /// In de, this message translates to:
  /// **'Gleicher Wert: Stechen! Beide Karten kommen in den Topf, und wer gewählt hat, wählt noch einmal. Wer die nächste Runde gewinnt, bekommt auch den ganzen Topf.\nNach 200 Runden gewinnt, wer mehr Karten hat. Bei gleich vielen ist es unentschieden.\nSind beide Stapel leer, ist es auch unentschieden.'**
  String get rulesTrumpfSpecial;

  /// KLD-123: Quartett (Trumpf) house rule title (KLD-100).
  ///
  /// In de, this message translates to:
  /// **'Mit 3 Karten oder weniger: aussuchen'**
  String get rulesTrumpfPickLow;

  /// KLD-123: Quartett (Trumpf) house rule text (KLD-100).
  ///
  /// In de, this message translates to:
  /// **'Hast du nur noch 2 oder 3 Karten, siehst du alle und suchst aus, welche du spielst. Wer wählt, sucht zuerst die Karte aus und dann die Eigenschaft. Der andere sucht seine Karte aus, wenn er die Eigenschaft kennt.'**
  String get rulesTrumpfPickLowText;

  /// KLD-123: Quartett (Sets) rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Sammle Quartette: alle 4 Karten einer Gruppe. Wer am Ende mehr Quartette hat, gewinnt.'**
  String get rulesSetsGoal;

  /// KLD-123: Quartett (Sets) rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Jeder bekommt 8 Karten. Die anderen 16 liegen verdeckt als Stapel.\nFrag den anderen nach einer Karte, die dir fehlt. Von dieser Gruppe musst du schon eine Karte haben.\nHat der andere die Karte, gibt er sie dir, und du darfst noch einmal fragen.\nHat er sie nicht, heißt es Fehlanzeige: Du ziehst eine Karte vom Stapel, und der andere ist dran.\nSpieler 1 fragt zuerst.'**
  String get rulesSetsTurn;

  /// KLD-123: Quartett (Sets) rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Hast du alle 4 Karten einer Gruppe, legst du das Quartett sofort ab.\nZiehst du die gefragte Karte vom Stapel, ist trotzdem der andere dran.\nHast du keine Karten mehr, ziehst du eine vom Stapel.\nSind alle 8 Quartette abgelegt, ist das Spiel aus. Bei 4 zu 4 ist es unentschieden.'**
  String get rulesSetsSpecial;

  /// KLD-123: Sink the Fleet rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Versenke alle Schiffe des anderen, bevor er deine versenkt.'**
  String get rulesSchiffeGoal;

  /// KLD-123: Sink the Fleet rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Zuerst stellt jeder seine Flotte geheim auf sein Meer mit 10 mal 10 Feldern. Spieler 1 fängt an.\nDann schießt ihr abwechselnd: Tippe auf ein Feld im Meer des anderen.\nAuf jedes Feld schießt du nur einmal.'**
  String get rulesSchiffeTurn;

  /// KLD-123: Sink the Fleet rules, next to a miss square.
  ///
  /// In de, this message translates to:
  /// **'Wasser: daneben. Jetzt ist der andere dran.'**
  String get rulesSchiffeMiss;

  /// KLD-123: Sink the Fleet rules, next to a hit square.
  ///
  /// In de, this message translates to:
  /// **'Treffer! Du darfst noch einmal schießen.'**
  String get rulesSchiffeHit;

  /// KLD-123: Sink the Fleet rules, next to a sunk square.
  ///
  /// In de, this message translates to:
  /// **'Versenkt: Alle Felder des Schiffs sind getroffen. Du erfährst, welches Schiff es war.'**
  String get rulesSchiffeSunk;

  /// KLD-123: Sink the Fleet rules, heading above the list of ships.
  ///
  /// In de, this message translates to:
  /// **'Die Flotte'**
  String get rulesSchiffeFleet;

  /// KLD-123: Sink the Fleet rules, one kind of ship. ship = ship name (engineShip*), e.g. "Kreuzer"; count = how many, length = squares.
  ///
  /// In de, this message translates to:
  /// **'{count} × {ship} ({length} Felder)'**
  String rulesSchiffeShip(int count, String ship, int length);

  /// KLD-123: Sink the Fleet rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Schiffe liegen gerade: waagerecht oder senkrecht.\nSchiffe dürfen sich nicht berühren, auch nicht über Eck.'**
  String get rulesSchiffeSpecial;

  /// KLD-123: GoStrategy rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Erobere die Fahne des anderen. Du gewinnst auch, wenn der andere nicht mehr ziehen kann.'**
  String get rulesGoGoal;

  /// KLD-123: GoStrategy rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Zuerst stellt jeder seine 40 Figuren geheim auf seine 4 Reihen. Den Rang einer Figur sieht nur ihr Besitzer.\nSpieler 1 stellt zuerst auf und zieht zuerst.\nIn deinem Zug ziehst du eine Figur 1 Feld nach vorne, hinten, links oder rechts. Nie schräg.\nIn die beiden Seen in der Mitte kann keine Figur.'**
  String get rulesGoTurn;

  /// KLD-123: GoStrategy rules, heading above the fight rules.
  ///
  /// In de, this message translates to:
  /// **'Wer schlägt wen?'**
  String get rulesGoFightTitle;

  /// KLD-123: GoStrategy rules, fights (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Ziehst du auf eine Figur des anderen, kämpfen beide. Danach sehen beide, welche Figuren es waren.\nDer höhere Rang gewinnt. Der Verlierer fliegt raus.\nGleicher Rang: Beide fliegen raus.'**
  String get rulesGoFight;

  /// KLD-123: GoStrategy rules, heading above the piece table.
  ///
  /// In de, this message translates to:
  /// **'Die Figuren'**
  String get rulesGoPieces;

  /// KLD-123: GoStrategy piece table: the rank of a piece.
  ///
  /// In de, this message translates to:
  /// **'Rang {rank}'**
  String rulesGoRank(int rank);

  /// KLD-123: GoStrategy piece table: how many of this piece each player has.
  ///
  /// In de, this message translates to:
  /// **'{count} ×'**
  String rulesGoCount(int count);

  /// KLD-123: GoStrategy piece table: the marshal.
  ///
  /// In de, this message translates to:
  /// **'Die stärkste Figur. Verliert nur gegen den Spion, wenn der angreift.'**
  String get rulesGoMarshal;

  /// KLD-123: GoStrategy piece table: the scout.
  ///
  /// In de, this message translates to:
  /// **'Läuft geradeaus beliebig weit über freie Felder und darf am Ende angreifen. Läuft er mehr als 1 Feld, sehen beide, dass er ein Aufklärer ist.'**
  String get rulesGoScout;

  /// KLD-123: GoStrategy piece table: the miner.
  ///
  /// In de, this message translates to:
  /// **'Entschärft Bomben: Greift er eine an, nimmt er ihren Platz ein.'**
  String get rulesGoMiner;

  /// KLD-123: GoStrategy piece table: the spy.
  ///
  /// In de, this message translates to:
  /// **'Die schwächste Figur. Greift der Spion aber den Marschall an, gewinnt er.'**
  String get rulesGoSpy;

  /// KLD-123: GoStrategy piece table: the bomb.
  ///
  /// In de, this message translates to:
  /// **'Zieht nie. Wer sie angreift, fliegt raus, die Bombe bleibt. Nur der Mineur entschärft sie.'**
  String get rulesGoBomb;

  /// KLD-123: GoStrategy piece table: the flag.
  ///
  /// In de, this message translates to:
  /// **'Zieht nie. Wer sie angreift, gewinnt das Spiel.'**
  String get rulesGoFlag;

  /// KLD-123: GoStrategy rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Eine Figur darf höchstens 3-mal hintereinander zwischen denselben zwei Feldern hin und her ziehen.\nHat eine Figur gezogen, weiß der andere: Sie ist keine Bombe und keine Fahne.\n200 Züge hintereinander ohne Kampf: unentschieden. Ebenso, wenn keiner mehr ziehen kann.'**
  String get rulesGoSpecial;

  /// KLD-123: chess rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Setz den König des anderen schachmatt: Er wird angegriffen und kann nicht mehr entkommen.'**
  String get rulesChessGoal;

  /// KLD-123: chess rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Weiß fängt an, dann zieht ihr abwechselnd.\nTippe auf eine deiner Figuren und dann auf ein Feld. Steht dort eine Figur des anderen, schlägst du sie.\nNur der Springer darf über andere Figuren springen.'**
  String get rulesChessTurn;

  /// KLD-123: chess rules, heading above the pieces.
  ///
  /// In de, this message translates to:
  /// **'So ziehen die Figuren'**
  String get rulesChessPieces;

  /// KLD-123: chess rules: the king (shown after the piece name).
  ///
  /// In de, this message translates to:
  /// **'1 Feld in jede Richtung.'**
  String get rulesChessKing;

  /// KLD-123: chess rules: the queen.
  ///
  /// In de, this message translates to:
  /// **'Beliebig weit gerade oder schräg.'**
  String get rulesChessQueen;

  /// KLD-123: chess rules: the rook.
  ///
  /// In de, this message translates to:
  /// **'Beliebig weit gerade.'**
  String get rulesChessRook;

  /// KLD-123: chess rules: the bishop.
  ///
  /// In de, this message translates to:
  /// **'Beliebig weit schräg.'**
  String get rulesChessBishop;

  /// KLD-123: chess rules: the knight.
  ///
  /// In de, this message translates to:
  /// **'Wie ein L: 2 Felder gerade, dann 1 zur Seite. Er springt über Figuren.'**
  String get rulesChessKnight;

  /// KLD-123: chess rules: the pawn.
  ///
  /// In de, this message translates to:
  /// **'1 Feld nach vorne, beim ersten Zug auch 2. Er schlägt 1 Feld schräg nach vorne.'**
  String get rulesChessPawn;

  /// KLD-123: chess rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Schach: Dein König wird angegriffen. Du musst ihn sofort retten. Ein Zug, nach dem dein König im Schach steht, geht nicht.\nSchachmatt: Der König steht im Schach und kann nicht gerettet werden. Wer mattsetzt, gewinnt.\nRochade: König und Turm haben noch nicht gezogen, und zwischen ihnen ist alles frei. Der König geht 2 Felder zum Turm, der Turm springt neben ihn. Nicht erlaubt, wenn der König im Schach steht oder über ein angegriffenes Feld gehen müsste.\nEn passant: Zieht ein Bauer 2 Felder und landet neben deinem Bauern, darfst du ihn gleich im nächsten Zug schräg schlagen, als wäre er nur 1 Feld gezogen.\nUmwandlung: Erreicht ein Bauer die letzte Reihe, wird er eine Dame, ein Turm, ein Läufer oder ein Springer. Du suchst aus.'**
  String get rulesChessSpecial;

  /// KLD-123: chess rules, heading above the kinds of draw.
  ///
  /// In de, this message translates to:
  /// **'Unentschieden (Remis)'**
  String get rulesChessDrawTitle;

  /// KLD-123: chess rules, kinds of draw (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Patt: Wer dran ist, kann nicht ziehen, steht aber nicht im Schach.\nEs sind zu wenig Figuren übrig, um mattzusetzen.\nDieselbe Stellung kommt zum 3. Mal.\n75 Züge von jedem ohne Schlagen und ohne Bauernzug.\nRemis vereinbart: Wer dran ist, kann Remis anbieten. Der andere nimmt an oder lehnt ab.'**
  String get rulesChessDraw;

  /// KLD-123: word tile game rules, goal (after wordtilesHelpGoal).
  ///
  /// In de, this message translates to:
  /// **'Wer am Ende die meisten Punkte hat, gewinnt.'**
  String get rulesWordtilesWin;

  /// KLD-123: word tile game rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Du hast 7 Steine auf deiner Bank.\nLeg 1 bis 7 Steine in eine Reihe oder Spalte, ohne Lücke.\nDu bekommst die Punkte aller neuen Wörter, auch der Wörter quer dazu.\nDanach ziehst du Steine aus dem Beutel, bis du wieder 7 hast.'**
  String get rulesWordtilesTurn;

  /// KLD-123: word tile game rules, after the challenge rule.
  ///
  /// In de, this message translates to:
  /// **'Wer angezweifelt hat, ist danach normal dran.'**
  String get rulesWordtilesChallengeAfter;

  /// KLD-123: word tile game rules, the end after scoreless turns.
  ///
  /// In de, this message translates to:
  /// **'Endet das Spiel, weil niemand mehr Punkte macht, verliert jeder die Punkte seiner übrigen Steine.'**
  String get rulesWordtilesScoreless;

  /// KLD-123: Mau-Mau rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Werde als Erster alle deine Karten los.'**
  String get rulesMaumauGoal;

  /// KLD-123: Mau-Mau rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Es gibt 32 Karten. Jeder bekommt 5, eine liegt offen in der Mitte. Spieler 1 fängt an.\nLeg eine Karte mit gleicher Farbe oder gleichem Wert darauf, zum Beispiel Herz auf Herz oder 9 auf 9.\nPasst keine Karte oder willst du keine legen, ziehst du 1 Karte. Passt sie, darfst du sie legen oder behalten. Passt sie nicht, ist der andere dran.\nIst der Stapel leer, werden die abgelegten Karten gemischt und zum neuen Stapel.'**
  String get rulesMaumauTurn;

  /// KLD-123: Mau-Mau rules: the jack (next to a card picture).
  ///
  /// In de, this message translates to:
  /// **'Bube: passt auf jede Karte außer auf einen Buben. Du wünschst dir eine Farbe. Dann muss diese Farbe kommen oder ein Bube.'**
  String get rulesMaumauJack;

  /// KLD-123: Mau-Mau rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Die erste Karte in der Mitte gilt nicht als Sonderkarte.\n9, 10, Dame und König sind normale Karten.\nWer die letzte Karte ablegt, gewinnt – auch mit einer Sonderkarte.'**
  String get rulesMaumauSpecial;

  /// KLD-123: dice bluffing game rules, goal.
  ///
  /// In de, this message translates to:
  /// **'Verlier nicht alle deine Leben. Wer zuletzt noch Leben hat, gewinnt.'**
  String get rulesMaexchenGoal;

  /// KLD-123: dice bluffing game rules, a turn (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Würfle mit 2 Würfeln unter dem Becher. Nur du siehst sie.\nSag einen Wert an. Er muss höher sein als die letzte Ansage. Du darfst auch flunkern!\nDer andere glaubt dir oder zweifelt an.\nGlaubt er dir, würfelt er selbst und muss noch höher ansagen.\nZweifelt er, wird der Becher gehoben. Ist der Wurf kleiner als die Ansage, verliert der Ansager ein Leben. Sonst verliert der Zweifler eins.'**
  String get rulesMaexchenTurn;

  /// KLD-123: dice bluffing game rules, heading above the value order.
  ///
  /// In de, this message translates to:
  /// **'Welcher Wurf ist höher?'**
  String get rulesMaexchenOrderTitle;

  /// KLD-123: dice bluffing game rules, value order (list, \n). Keep the numbers.
  ///
  /// In de, this message translates to:
  /// **'Der höhere Würfel zählt zuerst: 3 und 1 ist 31.\nVon klein nach groß: 31, 32, 41, 42, 43 und so weiter bis 65.\nHöher sind die Pasche: 11, 22, 33, 44, 55, 66.\nAm höchsten ist 21: das Mäxchen!'**
  String get rulesMaexchenOrder;

  /// KLD-123: dice bluffing game rules, special rules (list, \n).
  ///
  /// In de, this message translates to:
  /// **'Die erste Ansage einer Runde darf jeder Wert sein.\nWird ein Mäxchen angesagt, kannst du nicht glauben. Du zweifelst an oder gibst ein Leben ab, ohne nachzuschauen.\nWer ein Leben verliert, fängt die nächste Runde an.\nSchütteln: Statt auf „Würfeln“ zu tippen, kannst du das Handy schütteln wie einen Becher.'**
  String get rulesMaexchenSpecial;

  /// KLD-123: dice bluffing game rules, the lives setting.
  ///
  /// In de, this message translates to:
  /// **'Jeder fängt mit {count} Leben an.'**
  String rulesMaexchenLives(int count);

  /// KLD-123: title of the one-time card before the browser (iOS Safari) asks for motion access for shake-to-roll.
  ///
  /// In de, this message translates to:
  /// **'Würfeln durch Schütteln?'**
  String get shakeConsentTitle;

  /// KLD-123: text of the shake consent card; the browser shows its own fixed prompt right after "yes".
  ///
  /// In de, this message translates to:
  /// **'Dein Browser fragt gleich, ob Klunki die Bewegung des Handys spüren darf. Das nutzen wir nur zum Würfeln, es bleibt auf dem Gerät.'**
  String get shakeConsentBody;

  /// KLD-123: shake consent card: yes (the browser asks next).
  ///
  /// In de, this message translates to:
  /// **'Ja, Schütteln erlauben'**
  String get shakeConsentYes;

  /// KLD-123: shake consent card: no (shaking is switched off; tapping the roll button still rolls).
  ///
  /// In de, this message translates to:
  /// **'Nein, nur tippen'**
  String get shakeConsentNo;

  /// Word tiles: title / tooltip of the short rules sheet.
  ///
  /// In de, this message translates to:
  /// **'So geht’s'**
  String get wordtilesHelp;

  /// Word tiles rules sheet: the house rule 'Joker tauschen' (KLD-094 step 9).
  ///
  /// In de, this message translates to:
  /// **'Joker tauschen (Hausregel): Hast du den Buchstaben, für den ein Joker auf dem Brett steht, ziehe ihn auf den Joker. Der Joker kommt zu deinen Steinen, und du legst im selben Zug noch Steine (der Joker darf gleich mit). Ohne Legen gilt der Tausch nicht. Das schon gelegte Wort und seine Punkte bleiben.'**
  String get wordtilesHelpJoker;

  /// Word tiles rules sheet: under wordtilesHelpJoker, the house rule is on in this game.
  ///
  /// In de, this message translates to:
  /// **'In diesem Spiel an.'**
  String get wordtilesHelpJokerOn;

  /// Word tiles rules sheet: under wordtilesHelpJoker, the house rule is off in this game (it is chosen before the game).
  ///
  /// In de, this message translates to:
  /// **'In diesem Spiel aus. Ihr könnt sie vor dem Spiel einschalten.'**
  String get wordtilesHelpJokerOff;

  /// KLD-119: title of the five-dice score-sheet game (maintainer: "Ausgewürfelt"). Never the brand name of the commercial game.
  ///
  /// In de, this message translates to:
  /// **'Ausgewürfelt'**
  String get menuGameDiceSheet;

  /// KLD-119: one-line menu description of the five-dice game.
  ///
  /// In de, this message translates to:
  /// **'Fünf Würfel, ein Blatt, bis zu vier'**
  String get menuDescDiceSheet;

  /// KLD-119: why the five-dice game ended: every box of every sheet is filled.
  ///
  /// In de, this message translates to:
  /// **'Alle Felder sind ausgefüllt'**
  String get engineReasonDicesheetAllFilled;

  /// KLD-119: default name of player 3 in games for 3–4 players on one device; see playerDefaultNameA. Must differ from A, B and D.
  ///
  /// In de, this message translates to:
  /// **'Cleo'**
  String get playerDefaultNameC;

  /// KLD-119: default name of player 4; see playerDefaultNameC.
  ///
  /// In de, this message translates to:
  /// **'Dani'**
  String get playerDefaultNameD;

  /// KLD-119: "Wer spielt?" of a game for 2–4 players: label above the player count choice (2 · 3 · 4).
  ///
  /// In de, this message translates to:
  /// **'Wie viele spielen mit?'**
  String get seatPlayerCount;

  /// KLD-119: resign dialog of a game with 3–4 players: who gives up; the others play on.
  ///
  /// In de, this message translates to:
  /// **'Wer gibt auf? Die anderen spielen weiter.'**
  String get seatResignWho;

  /// KLD-119: in the final ranking, instead of the points of a player who gave up.
  ///
  /// In de, this message translates to:
  /// **'aufgegeben'**
  String get seatOut;

  /// KLD-119: points of a player in the final ranking.
  ///
  /// In de, this message translates to:
  /// **'{points, plural, one{{points} Punkt} other{{points} Punkte}}'**
  String seatPoints(int points);

  /// KLD-119: result headline and status when two or more players share the first place.
  ///
  /// In de, this message translates to:
  /// **'Gleichstand auf Platz 1!'**
  String get seatSharedFirst;

  /// KLD-119: result reason when everyone but one player gave up.
  ///
  /// In de, this message translates to:
  /// **'Alle anderen haben aufgegeben'**
  String get seatReasonOthersResigned;

  /// KLD-119: score sheet box "Ones" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Einser'**
  String get dicesheetBoxOnes;

  /// KLD-119: score sheet box "Twos" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Zweier'**
  String get dicesheetBoxTwos;

  /// KLD-119: score sheet box "Threes" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Dreier'**
  String get dicesheetBoxThrees;

  /// KLD-119: score sheet box "Fours" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Vierer'**
  String get dicesheetBoxFours;

  /// KLD-119: score sheet box "Fives" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Fünfer'**
  String get dicesheetBoxFives;

  /// KLD-119: score sheet box "Sixes" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Sechser'**
  String get dicesheetBoxSixes;

  /// KLD-119: score sheet box "Three of a Kind" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Dreierpasch'**
  String get dicesheetBoxThreeKind;

  /// KLD-119: score sheet box "Four of a Kind" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Viererpasch'**
  String get dicesheetBoxFourKind;

  /// KLD-119: score sheet box "Full House" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Full House'**
  String get dicesheetBoxFullHouse;

  /// KLD-119: score sheet box "Small Straight" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Kleine Straße'**
  String get dicesheetBoxSmallStraight;

  /// KLD-119: score sheet box "Large Straight" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Große Straße'**
  String get dicesheetBoxLargeStraight;

  /// KLD-119: score sheet box "Five of a Kind" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Fünferpasch'**
  String get dicesheetBoxFiveKind;

  /// KLD-119: score sheet box "Chance" (row label; keep it short, the column is narrow with 4 players).
  ///
  /// In de, this message translates to:
  /// **'Chance'**
  String get dicesheetBoxChance;

  /// KLD-119: move history: a roll; {dice} are the five values, e.g. "3 3 5 1 6". No gendered verb.
  ///
  /// In de, this message translates to:
  /// **'würfelt {dice}'**
  String dicesheetMoveRoll(String dice);

  /// KLD-119: move history: a roll keeping {count} dice.
  ///
  /// In de, this message translates to:
  /// **'würfelt {dice} (behält {count})'**
  String dicesheetMoveRollKeep(String dice, int count);

  /// KLD-119: move history: a box filled with {points}.
  ///
  /// In de, this message translates to:
  /// **'{box}: {points}'**
  String dicesheetMoveScore(String box, int points);

  /// KLD-119: move history: a box filled, plus the extra-fives bonus.
  ///
  /// In de, this message translates to:
  /// **'{box}: {points} (+{bonus})'**
  String dicesheetMoveScoreBonus(String box, int points, int bonus);

  /// KLD-119: hint line after a player filled a box (the next player has not rolled yet). Phrase without gender agreement for the name.
  ///
  /// In de, this message translates to:
  /// **'{player}: {points} bei {box}.'**
  String dicesheetLastScore(String player, String box, int points);

  /// KLD-119: hint before the first roll of a turn; names the roll button (dicesheetRollButton starts with this word).
  ///
  /// In de, this message translates to:
  /// **'Tippe auf Würfeln.'**
  String get dicesheetHintRoll;

  /// KLD-119: hint after the first or second roll.
  ///
  /// In de, this message translates to:
  /// **'Tippe Würfel an, die liegen bleiben sollen, und würfle nochmal. Oder wähle ein Feld im Blatt.'**
  String get dicesheetHintKeep;

  /// KLD-119: hint after the third roll.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Feld im Blatt.'**
  String get dicesheetHintPick;

  /// KLD-119: hint when a five of a kind is a joker (house rule Extra-Fünfer): only some boxes are allowed.
  ///
  /// In de, this message translates to:
  /// **'Fünferpasch als Joker: Trag ihn in eines der erlaubten Felder ein.'**
  String get dicesheetHintJoker;

  /// KLD-119: the big roll button with the rolls left this turn (3, 2 or 1).
  ///
  /// In de, this message translates to:
  /// **'Würfeln (noch {count})'**
  String dicesheetRollButton(int count);

  /// KLD-119: the roll button after the third roll (disabled): now a box must be chosen.
  ///
  /// In de, this message translates to:
  /// **'Feld im Blatt wählen'**
  String get dicesheetPickBox;

  /// KLD-119: screen reader label of a die.
  ///
  /// In de, this message translates to:
  /// **'Würfel {value}'**
  String dicesheetDie(int value);

  /// KLD-119: screen reader label of a kept die.
  ///
  /// In de, this message translates to:
  /// **'Würfel {value}, behalten'**
  String dicesheetDieKept(int value);

  /// KLD-119: small label under a die that stays on the table for the next roll.
  ///
  /// In de, this message translates to:
  /// **'behalten'**
  String get dicesheetKept;

  /// KLD-119: the round in the score sheet header, e.g. "Runde 3/13".
  ///
  /// In de, this message translates to:
  /// **'Runde {round}/{total}'**
  String dicesheetRound(int round, int total);

  /// KLD-119: screen reader label of a suggested score in the sheet (tap writes it).
  ///
  /// In de, this message translates to:
  /// **'{box}: {points} eintragen'**
  String dicesheetScoreAction(String box, int points);

  /// KLD-119: the bonus row under the upper section.
  ///
  /// In de, this message translates to:
  /// **'Bonus'**
  String get dicesheetBonus;

  /// KLD-119: small line under dicesheetBonus: the bonus points (passed as "+35", isolated left-to-right) and from which upper sum, e.g. "+35 ab 63".
  ///
  /// In de, this message translates to:
  /// **'{bonus} ab {at}'**
  String dicesheetBonusRule(String bonus, int at);

  /// KLD-119: the sheet row with the extra-fives bonus (house rule on).
  ///
  /// In de, this message translates to:
  /// **'Extra-Fünfer'**
  String get dicesheetExtraFives;

  /// KLD-119: the totals row of the sheet.
  ///
  /// In de, this message translates to:
  /// **'Gesamt'**
  String get dicesheetTotal;

  /// KLD-119: house rule switch in the start options.
  ///
  /// In de, this message translates to:
  /// **'Extra-Fünfer (Hausregel)'**
  String get dicesheetOptionExtraFives;

  /// KLD-119: explanation under the house rule switch.
  ///
  /// In de, this message translates to:
  /// **'Noch ein Fünferpasch, wenn dort schon 50 stehen: 100 Punkte extra. Er ist dann ein Joker und kommt zuerst ins obere Feld seiner Zahl.'**
  String get dicesheetOptionExtraFivesExplain;

  /// KLD-119/KLD-123: five-dice score game rules, goal (lines separated by \n).
  ///
  /// In de, this message translates to:
  /// **'Hol mit fünf Würfeln möglichst viele Punkte auf dein Blatt.\nNach 13 Runden ist jedes Feld voll. Wer die meisten Punkte hat, gewinnt. Bei gleich vielen Punkten teilt ihr euch den Platz.'**
  String get rulesDicesheetGoal;

  /// KLD-119/KLD-123: five-dice score game rules, a turn (lines separated by \n).
  ///
  /// In de, this message translates to:
  /// **'2 bis 4 spielen an einem Gerät, reihum.\nDu würfelst mit allen fünf Würfeln. Du darfst bis zu dreimal würfeln.\nVor dem 2. und 3. Wurf tippst du die Würfel an, die liegen bleiben sollen. Die anderen würfelst du neu.\nDann trägst du in genau ein leeres Feld deines Blatts ein, was die Würfel dort bringen. Das Blatt zeigt dir, wie viele Punkte jedes Feld bringt.\nPasst nichts, streichst du ein Feld: Es bekommt 0.'**
  String get rulesDicesheetTurn;

  /// KLD-119/KLD-123: five-dice rules, heading of the upper section (Ones to Sixes).
  ///
  /// In de, this message translates to:
  /// **'Oben: Einser bis Sechser'**
  String get rulesDicesheetUpperTitle;

  /// KLD-119/KLD-123: five-dice rules, how an upper box scores.
  ///
  /// In de, this message translates to:
  /// **'Es zählen nur die Würfel mit der Zahl des Felds, zusammengezählt.'**
  String get rulesDicesheetUpper;

  /// KLD-119/KLD-123: five-dice rules, the upper bonus. at = 63, bonus = 35.
  ///
  /// In de, this message translates to:
  /// **'Kommst du oben auf {at} Punkte oder mehr, gibt es {bonus} Punkte Bonus.'**
  String rulesDicesheetBonus(int at, int bonus);

  /// KLD-119/KLD-123: five-dice rules, heading of the lower section.
  ///
  /// In de, this message translates to:
  /// **'Unten'**
  String get rulesDicesheetLowerTitle;

  /// KLD-119/KLD-123: five-dice rules, the three of a kind box (shown under its name with an example).
  ///
  /// In de, this message translates to:
  /// **'Mindestens 3 gleiche. Alle Augen zählen.'**
  String get rulesDicesheetThreeKind;

  /// KLD-119/KLD-123: five-dice rules, the four of a kind box.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 4 gleiche. Alle Augen zählen.'**
  String get rulesDicesheetFourKind;

  /// KLD-119/KLD-123: five-dice rules, the full house box. points = 25.
  ///
  /// In de, this message translates to:
  /// **'3 gleiche und 2 gleiche: {points} Punkte.'**
  String rulesDicesheetFullHouse(int points);

  /// KLD-119/KLD-123: five-dice rules, the small straight box. points = 30.
  ///
  /// In de, this message translates to:
  /// **'4 Zahlen in einer Reihe: {points} Punkte.'**
  String rulesDicesheetSmallStraight(int points);

  /// KLD-119/KLD-123: five-dice rules, the large straight box. points = 40.
  ///
  /// In de, this message translates to:
  /// **'5 Zahlen in einer Reihe: {points} Punkte.'**
  String rulesDicesheetLargeStraight(int points);

  /// KLD-119/KLD-123: five-dice rules, the five of a kind box. points = 50.
  ///
  /// In de, this message translates to:
  /// **'5 gleiche: {points} Punkte.'**
  String rulesDicesheetFiveKind(int points);

  /// KLD-119/KLD-123: five-dice rules, the chance box.
  ///
  /// In de, this message translates to:
  /// **'Passt immer. Alle Augen zählen.'**
  String get rulesDicesheetChance;

  /// KLD-119/KLD-123: five-dice rules, special rules (lines separated by \n); "Zug zurück" and "Würfeln" are the button labels.
  ///
  /// In de, this message translates to:
  /// **'Jedes Feld füllst du nur einmal.\nEin Wurf gilt sofort. „Zug zurück“ nimmt nur den Eintrag ins Blatt zurück, solange noch nicht weitergewürfelt wurde.\nWer aufgibt, ist raus. Die anderen spielen weiter.\nSchütteln: Statt auf „Würfeln“ zu tippen, kannst du das Handy schütteln.'**
  String get rulesDicesheetSpecial;

  /// KLD-119/KLD-123: five-dice rules, the house rule "Extra-Fünfer" in full (title is dicesheetOptionExtraFives). bonus = 100.
  ///
  /// In de, this message translates to:
  /// **'Noch ein Fünferpasch, wenn dort schon 50 stehen: {bonus} Punkte extra. Ist das Feld Fünferpasch schon gefüllt (auch mit 0), ist ein Fünferpasch ein Joker: zuerst ins obere Feld seiner Zahl; ist das voll, in ein freies unteres Feld mit vollen Punkten; sonst mit 0 in ein oberes Feld.'**
  String rulesDicesheetExtraFives(int bonus);
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

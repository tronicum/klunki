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

  /// Menu card that opens the pairing screen for network play on the local Wi-Fi (not on web).
  ///
  /// In de, this message translates to:
  /// **'Über WLAN spielen'**
  String get menuPlayOverWifi;

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

  /// Reveal headline for a tie.
  ///
  /// In de, this message translates to:
  /// **'Gleichstand – Karten in den Topf'**
  String get quartettTrumpfTie;

  /// Reveal headline for a won trick.
  ///
  /// In de, this message translates to:
  /// **'{player} gewinnt den Stich'**
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

  /// Reveal after a tie: pot size and who picks next.
  ///
  /// In de, this message translates to:
  /// **'Im Topf: {count, plural, =1{1 Karte} other{{count} Karten}} – {player} wählt noch einmal'**
  String quartettTrumpfPotAgain(int count, String player);

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

  /// Setup subtitle.
  ///
  /// In de, this message translates to:
  /// **'Schiff {index} von {total} · {player} stellt auf'**
  String schiffeSetupProgress(int index, int total, String player);

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

  /// App bar title of the pairing screen (host or join a game on the local Wi-Fi).
  ///
  /// In de, this message translates to:
  /// **'Über WLAN spielen'**
  String get pairingTitle;

  /// Pairing screen body on web, where there are no sockets.
  ///
  /// In de, this message translates to:
  /// **'Netzwerkspiel ist im Browser nicht verfügbar'**
  String get pairingWebUnavailable;

  /// Label of the editable device name field.
  ///
  /// In de, this message translates to:
  /// **'Gerätename'**
  String get pairingDeviceName;

  /// Helper text below the device name field.
  ///
  /// In de, this message translates to:
  /// **'So sieht dich dein Mitspieler'**
  String get pairingDeviceNameHelper;

  /// Segmented button: host a game on this device.
  ///
  /// In de, this message translates to:
  /// **'Hosten'**
  String get pairingModeHost;

  /// Segmented button: join a game hosted on another device.
  ///
  /// In de, this message translates to:
  /// **'Beitreten'**
  String get pairingModeJoin;

  /// Heading above the game list when hosting.
  ///
  /// In de, this message translates to:
  /// **'Spiel wählen'**
  String get pairingChooseGame;

  /// Button: start hosting the chosen game.
  ///
  /// In de, this message translates to:
  /// **'Spiel hosten'**
  String get pairingHostGame;

  /// Error when the host session could not be started; error = technical message.
  ///
  /// In de, this message translates to:
  /// **'Spiel konnte nicht gestartet werden: {error}'**
  String pairingHostStartFailed(String error);

  /// Host: advertising via mDNS failed; the guest has to type the address.
  ///
  /// In de, this message translates to:
  /// **'Nicht automatisch sichtbar – Mitspieler gibt die Adresse ein.'**
  String get pairingNotAdvertised;

  /// Host: this device has no mDNS discovery; the guest has to type the address.
  ///
  /// In de, this message translates to:
  /// **'Keine automatische Suche auf diesem Gerät – Mitspieler gibt die Adresse ein.'**
  String get pairingNoDiscoveryHost;

  /// Host waiting screen headline; name = device name, game = game title.
  ///
  /// In de, this message translates to:
  /// **'{name} hostet {game}'**
  String pairingHosting(String name, String game);

  /// Host: no LAN address found, so no QR code; port = TCP port.
  ///
  /// In de, this message translates to:
  /// **'Keine WLAN-Adresse gefunden. Ist das Gerät mit dem WLAN verbunden? Port: {port}'**
  String pairingNoAddress(int port);

  /// Host: heading above the list of IP:port addresses.
  ///
  /// In de, this message translates to:
  /// **'Adressen (zum Eintippen):'**
  String get pairingAddresses;

  /// Subtitle of the first (best guess) address.
  ///
  /// In de, this message translates to:
  /// **'wahrscheinlich WLAN'**
  String get pairingProbablyWifi;

  /// Host status while no guest has joined yet.
  ///
  /// In de, this message translates to:
  /// **'Warte auf Mitspieler…'**
  String get pairingWaitingForGuest;

  /// Button: stop hosting / stop connecting.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get pairingCancel;

  /// Join: heading above the discovered hosts.
  ///
  /// In de, this message translates to:
  /// **'Spiele im Netzwerk'**
  String get pairingGamesOnNetwork;

  /// Join: this device has no mDNS discovery.
  ///
  /// In de, this message translates to:
  /// **'Automatische Suche ist auf diesem Gerät nicht verfügbar. Adresse unten eingeben.'**
  String get pairingNoDiscoveryJoin;

  /// Join: mDNS browsing failed.
  ///
  /// In de, this message translates to:
  /// **'Suche im Netzwerk nicht möglich. Adresse unten eingeben.'**
  String get pairingBrowseFailed;

  /// Join: no host found yet, still searching.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Spielen…'**
  String get pairingSearching;

  /// Join: a discovered host speaks another protocol version and cannot be joined.
  ///
  /// In de, this message translates to:
  /// **'andere Klunki-Version'**
  String get pairingOtherVersion;

  /// Join: heading above the manual address field.
  ///
  /// In de, this message translates to:
  /// **'Oder Adresse eingeben'**
  String get pairingOrEnterAddress;

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

  /// Network game connection bar; me / peerMark = player marks (X, O), peer = the other device's name.
  ///
  /// In de, this message translates to:
  /// **'Du bist {me} · Gegner: {peer} ({peerMark})'**
  String pairingStatus(String me, String peer, String peerMark);

  /// Connection bar: fallback name of the other device.
  ///
  /// In de, this message translates to:
  /// **'Gegner'**
  String get pairingOpponent;

  /// Connection banner: the other side left.
  ///
  /// In de, this message translates to:
  /// **'Gegner hat das Spiel verlassen'**
  String get pairingPeerLeft;

  /// Connection banner: the connection dropped.
  ///
  /// In de, this message translates to:
  /// **'Verbindung zum Gegner unterbrochen'**
  String get pairingPeerLost;

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

  /// Error below the connection banner when reconnecting failed.
  ///
  /// In de, this message translates to:
  /// **'Neu verbinden fehlgeschlagen. Ist der Host noch im Spiel?'**
  String get pairingReconnectFailed;
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

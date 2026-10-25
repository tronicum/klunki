// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get menuLanguage => '语言';

  @override
  String get languagePickerTitle => '选择语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get menuChooseGame => 'Choose a game';

  @override
  String get menuPassDevice => 'Pass the device';

  @override
  String get menuDebugConsole => 'Debug console';

  @override
  String get menuPlayOverWifi => 'Play over Wi-Fi';

  @override
  String get menuGameConnect4 => 'Four in a Row';

  @override
  String get menuGameMuehle => 'Mill';

  @override
  String get menuGameQuartettTrumpf => 'Quartett (Trumps)';

  @override
  String get menuGameQuartettSets => 'Quartett (Sets)';

  @override
  String get menuGameSchiffe => 'Sink the Fleet';

  @override
  String shellToMove(String player) {
    return '$player\'s turn';
  }

  @override
  String shellHasWon(String player) {
    return '$player has won';
  }

  @override
  String get shellDraw => 'Draw';

  @override
  String shellWins(String player) {
    return '$player wins!';
  }

  @override
  String get shellMenu => 'Menu';

  @override
  String get shellPlayAgain => 'Play again';

  @override
  String get shellUndo => 'Undo move';

  @override
  String get shellNewGame => 'New game';

  @override
  String get shellNewGameTitle => 'New game?';

  @override
  String get shellNewGameBody => 'The current game will be abandoned.';

  @override
  String get shellCancel => 'Cancel';

  @override
  String get shellRestart => 'Restart';

  @override
  String get shellMoves => 'Moves';

  @override
  String get shellNoMoves => 'No moves yet.';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player: $move';
  }

  @override
  String shellHandoverPass(String player) {
    return 'Pass the device to $player';
  }

  @override
  String shellHandoverContinue(String player) {
    return 'I\'m $player – continue';
  }

  @override
  String connect4Column(int column) {
    return 'Column $column';
  }

  @override
  String get connect4HintTapColumn => 'Tap a column';

  @override
  String get muehlePhasePlacing => 'Placing';

  @override
  String get muehlePhaseMoving => 'Moving';

  @override
  String get muehlePhaseFlying => 'Flying';

  @override
  String muehleMovePlace(int point) {
    return 'places on $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return 'removes stone on $point';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return 'moves $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return 'flies $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return 'Mill! Remove a stone of $player';
  }

  @override
  String get muehleHintPlace => 'Place a stone';

  @override
  String get muehleHintTarget =>
      'Choose a target (or tap the stone again to deselect)';

  @override
  String get muehleHintSelectFly => 'Choose a stone to fly';

  @override
  String get muehleHintSelectMove => 'Choose a stone to move';

  @override
  String muehlePointEmpty(int point) {
    return 'Point $point, empty';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return 'Point $point, $player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return 'Hand: $hand · Board: $board';
  }

  @override
  String muehleCaptured(int count) {
    return 'Captured: $count';
  }

  @override
  String get quartettNoGame => 'Not a Quartett game';

  @override
  String get quartettContinue => 'Continue';

  @override
  String get quartettHigherWins => 'higher wins';

  @override
  String get quartettLowerWins => 'lower wins';

  @override
  String get quartettCardBack => 'QUARTETT';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$player: $_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return 'picks $stat';
  }

  @override
  String get quartettTrumpfHintPick => 'Pick a stat of your card';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Pot: $_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return '$player\'s stack';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'Your card ($player)';
  }

  @override
  String get quartettTrumpfTie => 'Tie – cards go to the pot';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player wins the trick';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'wins';

  @override
  String get quartettTrumpfOutcomeLose => 'loses';

  @override
  String get quartettTrumpfOutcomeTie => 'tie';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player picks $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'In the pot: $_temp0 – $player picks again';
  }

  @override
  String get quartettSetsHit => 'Hit';

  @override
  String get quartettSetsMiss => 'Go fish';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return 'asks for $card: $result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return 'asks for $card: $result – quartet $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return 'Tap “Continue” and pass the device to $player';
  }

  @override
  String get quartettSetsHintAsk => 'Tap a missing card to ask for it';

  @override
  String get quartettSetsNoQuartet => 'no quartet yet';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Stock: $_temp0';
  }

  @override
  String quartettSetsScore(int a, int b) {
    return 'Quartets X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player asks for $card: $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return 'Hit! $player gives you $card';
  }

  @override
  String get quartettSetsMissDraw => 'Go fish – you draw a card';

  @override
  String get quartettSetsMissEmpty => 'Go fish – the stock is empty';

  @override
  String get quartettSetsAskAgain => 'You may ask again.';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return '$player doesn\'t have $card.';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return 'Quartet! $set laid down';
  }

  @override
  String get quartettSetsDrawn => 'Drawn:';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Your cards ($player): $_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – missing: $missing';
  }

  @override
  String get quartettSetsAskSlot => 'ask';

  @override
  String get quartettSetsMissingSlot => 'missing';

  @override
  String get schiffeHintSetup =>
      'Setup: tap the sea (or drag and release) to place the ship. Ships must not touch.';

  @override
  String get schiffeHintAllSunk => 'All ships sunk.';

  @override
  String schiffeHintWaiting(String player) {
    return 'Waiting for $player …';
  }

  @override
  String get schiffeHintExtraShot =>
      'Hit! Again – tap a cell in the opponent\'s sea.';

  @override
  String get schiffeHintFire =>
      'Tap an unknown cell in the opponent\'s sea to fire.';

  @override
  String get schiffeLookWater => 'water';

  @override
  String get schiffeLookShip => 'ship';

  @override
  String get schiffeLookMiss => 'miss';

  @override
  String get schiffeLookShipHit => 'ship hit';

  @override
  String get schiffeLookHit => 'hit';

  @override
  String get schiffeLookSunk => 'sunk';

  @override
  String get schiffeLookUnknown => 'unknown';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => 'Fleet complete';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship ($length)';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship ($length) · placed';
  }

  @override
  String schiffeSetupProgress(int index, int total, String player) {
    return 'Ship $index of $total · $player is placing';
  }

  @override
  String get schiffeHorizontal => 'Horizontal';

  @override
  String get schiffeVertical => 'Vertical';

  @override
  String get schiffeRandom => 'Random';

  @override
  String get schiffeFleet => 'Fleet';

  @override
  String schiffeExtraShotSunk(String ship) {
    return '$ship sunk – hit! Again';
  }

  @override
  String get schiffeExtraShot => 'Hit! Again';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return 'Your fleet: $own · Opponent ($player): $opponent ships left';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return '$player last fired at $cell: $result';
  }

  @override
  String get schiffeTargetSection => 'Opponent';

  @override
  String get schiffeOwnSection => 'Your sea';

  @override
  String get schiffeMovePlace => 'places a ship';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'places $count ships at random',
      one: 'places a ship at random',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return 'fires at $cell: $result';
  }

  @override
  String schiffeShipSunk(String ship) {
    return '$ship sunk';
  }

  @override
  String get debugConsoleTitle => 'Debug console';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => 'Game / demo';

  @override
  String debugNewGame(String game) {
    return 'New: $game';
  }

  @override
  String get debugLegalMoves => 'Legal moves';

  @override
  String get debugAutoPlay => 'Play to the end (random)';

  @override
  String get debugDemo => 'Demo: all games';

  @override
  String get pairingTitle => 'Play over Wi-Fi';

  @override
  String get pairingWebUnavailable =>
      'Network play is not available in the browser';

  @override
  String get pairingDeviceName => 'Device name';

  @override
  String get pairingDeviceNameHelper => 'This is how the other player sees you';

  @override
  String get pairingModeHost => 'Host';

  @override
  String get pairingModeJoin => 'Join';

  @override
  String get pairingChooseGame => 'Choose a game';

  @override
  String get pairingHostGame => 'Host game';

  @override
  String pairingHostStartFailed(String error) {
    return 'Could not start the game: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'Not automatically visible – the other player enters the address.';

  @override
  String get pairingNoDiscoveryHost =>
      'No automatic search on this device – the other player enters the address.';

  @override
  String pairingHosting(String name, String game) {
    return '$name is hosting $game';
  }

  @override
  String pairingNoAddress(int port) {
    return 'No Wi-Fi address found. Is the device connected to Wi-Fi? Port: $port';
  }

  @override
  String get pairingAddresses => 'Addresses (to type in):';

  @override
  String get pairingProbablyWifi => 'probably Wi-Fi';

  @override
  String get pairingWaitingForGuest => 'Waiting for the other player…';

  @override
  String get pairingCancel => 'Cancel';

  @override
  String get pairingGamesOnNetwork => 'Games on the network';

  @override
  String get pairingNoDiscoveryJoin =>
      'Automatic search is not available on this device. Enter the address below.';

  @override
  String get pairingBrowseFailed =>
      'Cannot search the network. Enter the address below.';

  @override
  String get pairingSearching => 'Searching for games…';

  @override
  String get pairingOtherVersion => 'different Klunki version';

  @override
  String get pairingOrEnterAddress => 'Or enter an address';

  @override
  String get pairingManualLabel => 'IP, IP:port or klunki:// link';

  @override
  String get pairingInvalidAddress =>
      'Invalid address. Example: 192.168.1.20 or 192.168.1.20:4747';

  @override
  String get pairingConnect => 'Connect';

  @override
  String pairingConnecting(String host) {
    return 'Connecting to $host…';
  }

  @override
  String get pairingTimeout => 'Timed out';

  @override
  String pairingJoinFailed(String host, String error) {
    return 'Connecting to $host failed ($error).';
  }

  @override
  String get pairingJoinHints =>
      'Tips: Are both devices on the same Wi-Fi? Guest networks often block connections between devices. iOS: Is “Local Network” allowed for Klunki (Settings › Privacy)?';

  @override
  String pairingStatus(String me, String peer, String peerMark) {
    return 'You are $me · Opponent: $peer ($peerMark)';
  }

  @override
  String get pairingOpponent => 'Opponent';

  @override
  String get pairingPeerLeft => 'Opponent left the game';

  @override
  String get pairingPeerLost => 'Connection to the opponent lost';

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. Waiting for them to rejoin…';
  }

  @override
  String get pairingReconnecting => 'Reconnecting…';

  @override
  String get pairingReconnect => 'Reconnect';

  @override
  String get pairingReconnectFailed =>
      'Reconnecting failed. Is the host still in the game?';
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get appSubtitle => 'game collection';

  @override
  String get menuLanguage => 'Language';

  @override
  String get languagePickerTitle => 'Choose language';

  @override
  String get languageSystem => 'System';

  @override
  String get menuChooseGame => 'Choose a game';

  @override
  String get menuDebugConsole => 'Debug console';

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
  String get menuDescConnect4 => 'Four in a line – across, down or diagonal.';

  @override
  String get menuDescMuehle =>
      'Form rows of three and capture your opponent\'s pieces.';

  @override
  String get menuDescQuartettTrumpf =>
      'Compare values – the better value wins both cards.';

  @override
  String get menuDescQuartettSets =>
      'Ask for cards and collect complete sets of four.';

  @override
  String get menuDescSchiffe => 'Hide your fleets and take turns firing.';

  @override
  String get menuSectionNetwork => 'Play with other devices';

  @override
  String get menuPlayOnOneDevice => 'One device';

  @override
  String get menuPlayWithOthers => 'With others';

  @override
  String get hotSeatPassDeviceHint =>
      'You pass the device around – hidden things stay secret.';

  @override
  String get roomStartSubtitle => 'Others join with the room code';

  @override
  String get roomJoinSubtitle => 'Scan or type the code';

  @override
  String get roomAdvanced => 'Advanced';

  @override
  String get roomDirectWaitingHint =>
      'Others tap “Join a room” and scan this QR code. Devices on the same Wi-Fi also find the room under “Rooms nearby”.';

  @override
  String get roomViaRelay => 'Open the room through a server';

  @override
  String get roomViaRelayHelper =>
      'With a room code, also for players in a browser. Needs a server (for example a computer running “klunki relay”). When off, the room runs on this device and devices on the same Wi-Fi find it by themselves.';

  @override
  String get roomTypeCode => 'Type the room code';

  @override
  String shellToMove(String player) {
    return '$player to move';
  }

  @override
  String shellHasWon(String player) {
    return '$player has won';
  }

  @override
  String get shellYourTurn => 'Your turn';

  @override
  String shellWaitingFor(String player) {
    return 'Waiting for $player…';
  }

  @override
  String get shellYouHaveWon => 'You have won';

  @override
  String get shellDraw => 'Draw';

  @override
  String shellWins(String player) {
    return '$player wins!';
  }

  @override
  String get shellYouWin => 'You win!';

  @override
  String get shellMenu => 'Menu';

  @override
  String get shellPlayAgain => 'Play again';

  @override
  String get shellUndo => 'Undo move';

  @override
  String get shellTakeBack => 'Take back';

  @override
  String get undoAllowedSetting => 'Allow taking back moves';

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
    return 'Stack of $player';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'Your card ($player)';
  }

  @override
  String get quartettTrumpfTie => 'Tie – tie-break!';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player wins the round';
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
    return 'Cards go to the pot (now $count), $player picks again';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player is picking …';
  }

  @override
  String get quartettTrumpfLastTrick => 'Previous round';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'Continuing in $seconds s';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player has picked: $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return '$player picks next';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player picks again';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'Continue – $player picks';
  }

  @override
  String get quartettTrumpfYouPickNext => 'You pick next';

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more rounds',
      one: '1 more round',
    );
    return '$_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return '$player won the round';
  }

  @override
  String quartettTrumpfChooseOwn(int count) {
    return 'You only have $count cards left – choose one.';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return '$player plays $stat. Choose your card.';
  }

  @override
  String get quartettTrumpfMoveChoose => 'chooses a card';

  @override
  String quartettTrumpfHintDefending(String player) {
    return '$player is choosing a card …';
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
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return 'Quartets $nameA $a : $b $nameB';
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
  String get schiffeHintSetup => 'Tap the sea to place the ship.';

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
  String get schiffeRotate => 'Rotate';

  @override
  String schiffeRotateSemantics(String orientation) {
    return 'Rotate, currently $orientation';
  }

  @override
  String get schiffeRemove => 'Remove';

  @override
  String get schiffeRemoveTooltip => 'Back to the harbour';

  @override
  String get schiffeReset => 'Reset';

  @override
  String get schiffeDone => 'Done';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return '$placed of $total ships placed · $player is placing';
  }

  @override
  String schiffeHintSelected(String ship) {
    return '$ship selected: drag to move, tap again to turn.';
  }

  @override
  String get schiffeHintReady =>
      'Fleet ready. Tap a ship to move or turn it – or “Done”.';

  @override
  String schiffeHintEarly(String player) {
    return 'You can already place your ships. “Done” works once $player has finished.';
  }

  @override
  String get schiffeInvalidPlace =>
      'Doesn’t fit there: ships must be fully on the sea and must not touch.';

  @override
  String get schiffeInvalidRotate => 'Can’t rotate here – not enough room.';

  @override
  String get schiffeSubmitFailed =>
      'The setup was not accepted. Tap “Done” again.';

  @override
  String get schiffeSelected => 'selected';

  @override
  String get schiffeHarbour => 'Harbour';

  @override
  String get schiffeHintSetupMore =>
      'Tap the sea for the next ship. Tap a ship to move or turn it.';

  @override
  String get schiffeCoachTap => 'Tap it: move or turn';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ships left',
      one: '1 ship left',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return 'Preview: $ship, $orientation. Tap to turn it.';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of this kind left',
      one: 'the last of its kind',
    );
    return '$_temp0';
  }

  @override
  String get schiffeInvalidTouch =>
      'Ships must not touch, not even at the corners – leave one free cell between them.';

  @override
  String get schiffeInvalidOffBoard => 'Does not fit on the board.';

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
  String get pairingDeviceNameHelper => 'This is how the other player sees you';

  @override
  String get playerNameTitle => 'What’s your name?';

  @override
  String get playerNameLabel => 'Your name';

  @override
  String playerLabel(String name, String mark) {
    return '$name ($mark)';
  }

  @override
  String get playerDefaultNameA => 'Anna';

  @override
  String get playerDefaultNameB => 'Ben';

  @override
  String get hotSeatStartTitle => 'Who is playing?';

  @override
  String get hotSeatStartPlay => 'Play';

  @override
  String get hotSeatNamesTitle => 'Player names';

  @override
  String hotSeatNameLabel(int number) {
    return 'Player $number';
  }

  @override
  String get hotSeatStartsHint => 'starts';

  @override
  String get hotSeatNamesHelper => 'Leave empty for the default name.';

  @override
  String get pairingChooseGame => 'Choose a game';

  @override
  String get roomStart => 'Start a room';

  @override
  String roomStartFailed(String error) {
    return 'Could not start the room: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'Not visible automatically – others scan the QR code.';

  @override
  String get pairingNoDiscoveryHost =>
      'No automatic search on this device – others scan the QR code.';

  @override
  String roomOfPlayer(String name, String game) {
    return '$name’s room: $game';
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
  String get roomNearby => 'Rooms nearby';

  @override
  String get pairingNoDiscoveryJoin =>
      'Automatic search is not available on this device. Scan the QR code or enter the address under “Advanced”.';

  @override
  String get pairingBrowseFailed =>
      'Searching the network failed. Scan the QR code or enter the address under “Advanced”.';

  @override
  String get pairingSearching => 'Looking for rooms…';

  @override
  String get pairingOtherVersion => 'different Klunki version';

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
  String pairingStatus(String name, String peer) {
    return 'You: $name · Opponent: $peer';
  }

  @override
  String netBarYou(String name) {
    return 'You: $name';
  }

  @override
  String netBarOpponent(String peer) {
    return 'Opponent: $peer';
  }

  @override
  String get pairingOpponent => 'Opponent';

  @override
  String pairingPeerLeft(String peer) {
    return '$peer left the game';
  }

  @override
  String pairingPeerLost(String peer) {
    return 'Connection to $peer lost';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. Waiting for them to rejoin…';
  }

  @override
  String get pairingReconnecting => 'Reconnecting…';

  @override
  String get pairingReconnect => 'Reconnect';

  @override
  String get networkVerificationFailed =>
      'The game record could not be verified';

  @override
  String get pairingReconnectFailed =>
      'Reconnecting failed. Is the other device still in the game?';

  @override
  String get pairingBrowserJoin =>
      'Join in a browser (type the address or paste the link):';

  @override
  String get pairingCopyLink => 'Copy link';

  @override
  String get pairingLinkCopied => 'Link copied';

  @override
  String get webJoinHttpsWarning =>
      'In a browser over https, Klunki can only reach secure servers (wss://) – use the app or the local http version.';

  @override
  String get webJoinAddressLabel => 'IP, IP:port, ws:// or klunki:// link';

  @override
  String webJoinAddressHelper(int port) {
    return 'The port is the other device’s browser port (WebSocket), $port if left out.';
  }

  @override
  String get webJoinInvalidAddress =>
      'Invalid address. Example: 192.168.1.20, 192.168.1.20:4748 or klunki://join?h=…';

  @override
  String get webJoinHints =>
      'Tips: Is this device on the same Wi-Fi as the device with the room? Guest networks often block connections between devices. The page must be opened over http://, not https://. The other device must run a Klunki version with browser support (it shows “Join in a browser”).';

  @override
  String get engineReasonConnect4FourInARow => 'Four in a row';

  @override
  String get engineReasonConnect4BoardFull => 'Board full';

  @override
  String get engineReasonMuehleFewerThanThree =>
      'Opponent has fewer than 3 pieces';

  @override
  String get engineReasonMuehleBlocked => 'Opponent cannot move';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves moves without a capture';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => 'Both stacks empty';

  @override
  String get engineReasonQuartettAllCards => 'Opponent has no cards left';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return 'Round limit reached, equal stacks ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'Round limit reached, more cards ($a:$b)';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return 'All quartets laid down, $a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return 'More quartets ($a:$b)';
  }

  @override
  String get engineReasonSchiffeAllSunk => 'All ships sunk';

  @override
  String get engineReasonGostrategyFlagCaptured => 'Flag captured';

  @override
  String get engineReasonGostrategyNoMoves => 'Opponent has no move left';

  @override
  String get engineReasonGostrategyBothBlocked => 'Neither side can move';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves moves without a fight';
  }

  @override
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy =>
      'Hidden armies – find and capture the enemy flag.';

  @override
  String get goPieceMarshal => 'Marshal';

  @override
  String get goPieceGeneral => 'General';

  @override
  String get goPieceColonel => 'Colonel';

  @override
  String get goPieceMajor => 'Major';

  @override
  String get goPieceCaptain => 'Captain';

  @override
  String get goPieceLieutenant => 'Lieutenant';

  @override
  String get goPieceSergeant => 'Sergeant';

  @override
  String get goPieceMiner => 'Miner';

  @override
  String get goPieceScout => 'Scout';

  @override
  String get goPieceSpy => 'Spy';

  @override
  String get goPieceBomb => 'Bomb';

  @override
  String get goPieceFlag => 'Flag';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece ($rank)';
  }

  @override
  String goSetupTitle(String player) {
    return 'Set up your army ($player)';
  }

  @override
  String get goSetupHint =>
      'Tap two pieces, or drag one onto another square of your four rows, to swap them. Then “Done”.';

  @override
  String goSetupSelected(String piece) {
    return '$piece selected – tap another square of your four rows to swap.';
  }

  @override
  String get goSetupShuffle => 'Shuffle';

  @override
  String get goSetupDone => 'Done';

  @override
  String goSetupFirst(String player) {
    return '$player sets up first – you can prepare meanwhile.';
  }

  @override
  String goWaitingSetup(String player) {
    return 'Waiting for $player to set up …';
  }

  @override
  String get goLegendTitle => 'Pieces';

  @override
  String get goLegendRules =>
      'Higher rank wins; with equal ranks both fall. The spy beats the marshal when it attacks. Only miners defuse bombs. Scouts move any distance in a straight line. Bombs and the flag never move.';

  @override
  String get goHintSelect => 'Tap one of your pieces, then a marked square.';

  @override
  String goHintSelected(String piece) {
    return '$piece: tap a marked square.';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece cannot move right now.';
  }

  @override
  String goHintWaiting(String player) {
    return 'Waiting for $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return '$moves more moves without a fight and it is a draw.';
  }

  @override
  String get goArmyOwn => 'Your army';

  @override
  String goArmyEnemy(String player) {
    return 'Opponent: $player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return '$left of $total left';
  }

  @override
  String goFightBy(String player) {
    return 'Attack by $player';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner beats $loser';
  }

  @override
  String get goFightBoth => 'Both fall';

  @override
  String goFightDefused(String piece) {
    return '$piece defuses the bomb';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece hits a bomb';
  }

  @override
  String get goFightFlag => 'Flag captured!';

  @override
  String get goMoveSetup => 'sets up the army';

  @override
  String goMoveStep(String from, String to) {
    return 'moves $from–$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return 'attacks ($from–$to): $result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell: $content';
  }

  @override
  String get goCellFree => 'empty';

  @override
  String get goCellLake => 'lake';

  @override
  String goCellHidden(String player) {
    return 'hidden piece of $player';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece of $player';
  }

  @override
  String goCellMoved(String content) {
    return '$content, moved';
  }

  @override
  String gameNotInApp(String game) {
    return '$game is not available in the app yet.';
  }

  @override
  String get engineSetA => 'Supercars';

  @override
  String get engineSetB => 'Hypercars';

  @override
  String get engineSetC => 'Classics';

  @override
  String get engineSetD => 'Muscle Cars';

  @override
  String get engineSetE => 'Rally Legends';

  @override
  String get engineSetF => 'Grand Tourers';

  @override
  String get engineSetG => 'Electric';

  @override
  String get engineSetH => 'Pocket Rockets';

  @override
  String get engineStatPs => 'Power';

  @override
  String get engineStatKmh => 'Top speed';

  @override
  String get engineStatCcm => 'Displace­ment';

  @override
  String get engineStatKg => 'Weight';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => 'hp';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cc';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => 'Battleship';

  @override
  String get engineShip4 => 'Cruiser';

  @override
  String get engineShip3 => 'Destroyer';

  @override
  String get engineShip2 => 'Submarine';

  @override
  String get engineShipOther => 'Ship';

  @override
  String get roomStartIntro =>
      'Others tap “Join a room” and enter the room code.';

  @override
  String get relayRoomCode => 'Room code';

  @override
  String get relayWaitingHint =>
      'Others tap “Join a room” and scan the QR code or enter the room code. Or they open the link.';

  @override
  String relayInfo(String address) {
    return 'Server: $address';
  }

  @override
  String get roomCodeHelper =>
      '5 characters – the other device shows the code with its room.';

  @override
  String get relayCodeInvalid =>
      'Invalid room code: 5 letters or digits (no 0, O, 1, I, L).';

  @override
  String get roomJoin => 'Join a room';

  @override
  String relayJoining(String code) {
    return 'Joining room $code…';
  }

  @override
  String get relayAddressLabel => 'Server';

  @override
  String get relayAddressHelper =>
      'The server\'s address, e.g. 192.168.1.20:4749 (on the Wi-Fi) or wss://spiele.example (on the internet)';

  @override
  String get relayAddressInvalid =>
      'Invalid server address. Example: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'No room with the code $code. Is the code right, and is the room still open?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'Room $code is already full: two are playing there.';
  }

  @override
  String relayErrorHostAway(String code) {
    return 'The device that started room $code can\'t be reached right now. Try again in a moment.';
  }

  @override
  String get relayErrorRoomClosed =>
      'The room was closed: whoever started it has left. The game is over.';

  @override
  String get relayErrorExpired =>
      'The room expired (10 minutes without activity).';

  @override
  String relayErrorUnreachable(String address) {
    return 'No server reachable at $address.';
  }

  @override
  String get relayErrorLost => 'The connection to the server was lost.';

  @override
  String get relayStartHint =>
      'Rooms with a room code need a server. Start it on a computer on the Wi-Fi and open Klunki from its address:';

  @override
  String relayRoomLost(String reason) {
    return '$reason Start a new room.';
  }

  @override
  String relayFromLink(String address) {
    return 'Server from link: $address';
  }

  @override
  String get relayLinkSaveDefault => 'Save as default';

  @override
  String get relayLinkUseSaved => 'Use saved server';

  @override
  String get relayLinkForeign =>
      'Caution: this link points to a different server, not to this page\'s server. Only join if you trust the sender: a foreign server sees every move.';

  @override
  String get pairingSeatTaken =>
      'Seat taken: someone is already playing in this game. Only the player who joined first can rejoin.';

  @override
  String get qrScanButton => 'Scan QR code';

  @override
  String get qrScanHint => 'Point the camera at the other device’s QR code.';

  @override
  String get qrScanNotKlunki =>
      'Not a Klunki code. Scan the QR code the other device shows with its room.';

  @override
  String get qrScanTorchOn => 'Turn on light';

  @override
  String get qrScanTorchOff => 'Turn off light';

  @override
  String get qrScanPermissionDenied =>
      'Klunki is not allowed to use the camera.';

  @override
  String get qrScanPermissionHint =>
      'You can allow camera access for Klunki in the device settings.';

  @override
  String get qrScanUnavailable => 'The camera is not available.';

  @override
  String get qrScanTypeInstead => 'Type the code';

  @override
  String get relayChange => 'change';

  @override
  String get relayNotSet => 'No server set up – enter an address';

  @override
  String relayUseDefault(String address) {
    return 'Default: $address';
  }

  @override
  String get relaySave => 'Apply';

  @override
  String get relayClubCodeLabel => 'Club code';

  @override
  String get relayClubCodeHelper =>
      'Saved for this server only. The club code never goes into room links or QR codes.';

  @override
  String get relayErrorClubMissing =>
      'This server needs a club code. Ask the person who runs the server.';

  @override
  String get relayErrorClubWrong =>
      'This server doesn\'t know the club code. Ask the person who runs the server.';

  @override
  String get serverKindLan =>
      'Server on the Wi-Fi (a computer running “klunki relay”)';

  @override
  String get serverKindInternet => 'Server on the internet';

  @override
  String get serverHelpLink => 'How does this work?';

  @override
  String get serverClubCodeRemove => 'Remove club code';

  @override
  String get serverClubCodeRetry => 'Try with club code';

  @override
  String get helpTitle => 'How to play together';

  @override
  String get helpSectionRoomsTitle => 'Playing with others';

  @override
  String get helpSectionRoomsBody =>
      'One person taps “Start a room” and picks a game. Klunki then shows a room code and a QR code.\n\nThe other person taps “Join a room” and scans the QR code or types the room code. Off you go.';

  @override
  String get helpSectionWifiTitle => 'On the same Wi-Fi';

  @override
  String get helpSectionWifiBody =>
      'Does one of you have the app? Then you need no server on the Wi-Fi: the app is the server itself, also for players in a browser (QR code).\n\nDevices on the same Wi-Fi find each other by themselves.';

  @override
  String get helpSectionServerTitle => 'When do you need a server?';

  @override
  String get helpSectionServerBody =>
      'Only if everyone plays in a browser or you are not on the same Wi-Fi. The server passes the moves between your devices.\n\nKlunki tells from the address what kind of server it is: “Server on the Wi-Fi” or “Server on the internet”.';

  @override
  String get helpSectionOwnServerTitle => 'Your own server on the Wi-Fi';

  @override
  String get helpSectionOwnServerBody =>
      'You can also run your own server on a computer on the Wi-Fi. A ready-made program for Mac, Windows and Linux is in preparation. You then enter its address in Klunki under “Advanced” with “change”.';

  @override
  String get helpSectionComingTitle => 'Easier soon (in preparation)';

  @override
  String get helpSectionComingBody =>
      'These ways to get a server are in preparation:\n• A server on the internet for a circle of friends (with Cloudflare, free)\n• A ready-made program to download for Mac, Windows and Linux\n• Docker for a NAS or Raspberry Pi\n\nServers on the internet are usually protected with a club code.';

  @override
  String get helpSectionClubTitle => 'What is a club code?';

  @override
  String get helpSectionClubBody =>
      'A club code is like a key to a server: only people who know it can start or join rooms there. You get it from the person who runs the server.\n\nKlunki only asks for it when a server needs one, and remembers it for that server.';

  @override
  String get helpSectionDataTitle => 'What happens to my data?';

  @override
  String get helpSectionDataBody =>
      'The server only passes the moves along and keeps none of them for good. If you play directly on the same Wi-Fi, nothing goes through someone else\'s server.\n\nThe club code stays on your device and never goes into room links or QR codes. You can see, change or remove it with “change” next to the server.';

  @override
  String get joinDirectTitle => 'Connect directly to a device';

  @override
  String get joinDirectHelper =>
      'For a device the room runs on directly (app or terminal): enter its address (IP).';

  @override
  String get shellResign => 'Resign';

  @override
  String get shellResignTitle => 'Really resign?';

  @override
  String shellResignBody(String player) {
    return 'The game ends for both of you – $player wins.';
  }

  @override
  String get shellLeaveTitle => 'Leave the game?';

  @override
  String get shellLeaveBody =>
      'The connection will be closed and the game ends for both of you.';

  @override
  String get shellLeave => 'Leave';

  @override
  String get shellResignWho =>
      'Who resigns? The game ends now and the other side wins.';

  @override
  String shellResignPlayer(String player) {
    return '$player resigns';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return '$player resigned';
  }

  @override
  String get engineReasonCommonYouResigned => 'You resigned';

  @override
  String get quartettDeckCars => 'Cars';

  @override
  String get quartettDeckTrains => 'Trains';

  @override
  String get quartettDeckRockets => 'Rockets';

  @override
  String get quartettDeckPlanes => 'Planes';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => 'Shinkansen';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => 'Europe\'s fastest';

  @override
  String get quartettSetTrainsE => 'Asia & America';

  @override
  String get quartettSetTrainsF => 'Electric locos';

  @override
  String get quartettSetTrainsG => 'Steam legends';

  @override
  String get quartettSetTrainsH => 'Freight giants';

  @override
  String get quartettSetRocketsA => 'Moon rockets';

  @override
  String get quartettSetRocketsB => 'Reusable';

  @override
  String get quartettSetRocketsC => 'Europe';

  @override
  String get quartettSetRocketsD => 'US classics';

  @override
  String get quartettSetRocketsE => 'Russia';

  @override
  String get quartettSetRocketsF => 'China';

  @override
  String get quartettSetRocketsG => 'Japan & India';

  @override
  String get quartettSetRocketsH => 'Small launchers';

  @override
  String get quartettSetPlanesA => 'Wide-bodies';

  @override
  String get quartettSetPlanesB => 'Medium haul';

  @override
  String get quartettSetPlanesC => 'Supersonic';

  @override
  String get quartettSetPlanesD => 'Propeller classics';

  @override
  String get quartettSetPlanesE => 'Cargo giants';

  @override
  String get quartettSetPlanesF => 'Business & sport';

  @override
  String get quartettSetPlanesG => 'Pioneers';

  @override
  String get quartettSetPlanesH => 'Record oddities';

  @override
  String get quartettStatKw => 'Power';

  @override
  String get quartettStatLengthM => 'Length';

  @override
  String get quartettStatMassT => 'Weight';

  @override
  String get quartettStatTractiveKn => 'Tractive ef­fort';

  @override
  String get quartettStatHeightM => 'Height';

  @override
  String get quartettStatThrustKn => 'Lift­off thrust';

  @override
  String get quartettStatLeoT => 'Payload (LEO)';

  @override
  String get quartettStatLaunchMassT => 'Launch mass';

  @override
  String get quartettStatFlights => 'Laun­ches';

  @override
  String get quartettStatRangeKm => 'Range';

  @override
  String get quartettStatWingspanM => 'Wing­span';

  @override
  String get quartettStatMtowT => 'Take-off weight';

  @override
  String get quartettDeckPickerTitle => 'Choose a deck';

  @override
  String get quartettDeckLabel => 'Deck';

  @override
  String quartettDeckSets(int sets) {
    return '$sets sets of 4 cards';
  }

  @override
  String get quartettDeckPlay => 'Play';

  @override
  String get quartettGalleryOpen => 'Browse cards';

  @override
  String get quartettGalleryTitle => 'Quartett cards';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return 'Card $index of $total';
  }

  @override
  String get quartettGalleryPrevious => 'Previous card';

  @override
  String get quartettGalleryNext => 'Next card';

  @override
  String get quartettGalleryTopMenu => 'Top 5 by stat';

  @override
  String quartettGalleryTopTitle(String stat) {
    return 'Top 5: $stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return 'Card $id: $name, set $set';
  }

  @override
  String get quartettStatBuilt => 'Built';

  @override
  String get quartettStatSuccessPct => 'Success rate';

  @override
  String get quartettUnitBuilt => 'units';

  @override
  String quartettPhotoCredit(String author, String license) {
    return 'Photo: $author, $license';
  }

  @override
  String get quartettPhotoCreditTitle => 'Image credit';

  @override
  String get quartettPhotoCreditTooltip => 'Show image credit';

  @override
  String get quartettPhotoModified => 'Resized for the app.';

  @override
  String get quartettPhotoShareAlike =>
      'The resized version is under the same licence.';

  @override
  String get quartettPhotoLicense => 'Licence';

  @override
  String get quartettPhotoSource => 'Source';

  @override
  String get quartettPhotoClose => 'Close';

  @override
  String get quartettWikipediaRead => 'Read on Wikipedia';

  @override
  String get quartettImageCreditsTitle => 'Image credits';

  @override
  String get quartettImageCreditsIntro =>
      'The photos come from Wikimedia Commons and are under free licences. They are part of the app; only the links need the internet.';

  @override
  String get quartettLinkFailed => 'The link could not be opened.';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return 'Note: other devices can\'t reach “$host”. Open the page via this computer\'s Wi-Fi address (e.g. $example) or its .local name (e.g. $mdnsExample) so the link and QR code work on other devices.';
  }

  @override
  String relayLoopbackShort(String host) {
    return '“$host” only works on this device – other devices need this computer\'s Wi-Fi address or .local name.';
  }

  @override
  String get loopbackHowTitle => 'How do I find the address?';

  @override
  String get loopbackHowMacSettings =>
      'System Settings › Wi-Fi › Details… › IP address. Or in Terminal:';

  @override
  String get loopbackHowMacMdns =>
      'The .local name is in System Settings › General › Sharing (“Local hostname”).';

  @override
  String get loopbackHowWindowsSettings =>
      'Settings › Network & internet › Wi-Fi › properties (IPv4 address). Or in Command Prompt (cmd), “IPv4 Address” of the Wi-Fi adapter:';

  @override
  String get loopbackHowWindowsMdns =>
      'On Windows 10/11 the .local name is <computer name>.local.';

  @override
  String get loopbackHowLinuxTerminal => 'In a terminal:';

  @override
  String get loopbackHowLinuxSettings =>
      'Or Settings › Network › Wi-Fi › details. The .local name is <hostname>.local if Avahi is running.';

  @override
  String loopbackHowRelay(String command) {
    return 'Tip: the “$command” console prints these addresses when it starts.';
  }

  @override
  String get loopbackHowCopy => 'Copy command';

  @override
  String get loopbackHowCopied => 'Command copied';

  @override
  String get goSetupInvalid => 'Only your four rows at the bottom take pieces.';

  @override
  String get versionMismatchBoth =>
      'The game versions don\'t match – please update both apps (browser: reload the page).';

  @override
  String get versionMismatchUpdateOther =>
      'The game versions don\'t match: the other device has an older version. Please update the app there (browser: reload the page).';

  @override
  String get versionMismatchUpdateThis =>
      'The game versions don\'t match: this device has an older version. Please update this app (browser: reload the page).';

  @override
  String versionMismatchGuestRefused(String reason) {
    return 'A device tried to join but was turned away: $reason';
  }

  @override
  String menuVersion(String version) {
    return 'Version $version';
  }

  @override
  String aboutBuildDetails(String build, String protocol, String games) {
    return 'Build number $build · protocol $protocol · game data $games';
  }

  @override
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  ) {
    return '$nameA has $versionA, $nameB has $versionB.';
  }

  @override
  String versionMismatchVersionsDevices(String versionA, String versionB) {
    return 'This device has $versionA, the other device has $versionB.';
  }

  @override
  String get aboutTitle => 'About Klunki';

  @override
  String get aboutPrivacy => 'Privacy';

  @override
  String get aboutImpressum => 'Legal notice (Impressum)';

  @override
  String get aboutSupport => 'Support';

  @override
  String get aboutLicense => 'Klunki is free software under the GNU AGPL 3.0.';

  @override
  String get aboutSourceCode => 'Source code';

  @override
  String get aboutLicenses => 'Open source licences';

  @override
  String get aboutOpenInBrowser => 'Open in browser';

  @override
  String get aboutPrivacyOffline =>
      'This copy is stored in the app so you can read it without internet. The page on the web is authoritative:';

  @override
  String get menuGameChess => 'Chess';

  @override
  String get menuDescChess => 'The classic: checkmate the opposing king.';

  @override
  String get chessWhite => 'White';

  @override
  String get chessBlack => 'Black';

  @override
  String get chessColorLabel => 'Your colour';

  @override
  String get chessColorRandom => 'Random';

  @override
  String get chessColorHelper => 'White starts. “Random” lets chance decide.';

  @override
  String get chessYouPlayWhite => 'You play White.';

  @override
  String get chessYouPlayBlack => 'You play Black.';

  @override
  String get chessCheck => 'Check!';

  @override
  String get chessHintSelect => 'Tap a piece to move it.';

  @override
  String get chessHintTarget => 'Tap a highlighted square.';

  @override
  String get chessPromotionTitle => 'Promote pawn to …';

  @override
  String get chessFlipBoard => 'Flip board';

  @override
  String get chessAutoFlip => 'Turn the board to the side to move';

  @override
  String chessSquareEmpty(String square) {
    return '$square: empty';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square: $piece ($side)';
  }

  @override
  String get chessPieceKing => 'King';

  @override
  String get chessPieceQueen => 'Queen';

  @override
  String get chessPieceRook => 'Rook';

  @override
  String get chessPieceBishop => 'Bishop';

  @override
  String get chessPieceKnight => 'Knight';

  @override
  String get chessPiecePawn => 'Pawn';

  @override
  String get chessOfferDraw => 'Offer a draw';

  @override
  String get chessOfferDrawTitle => 'Offer a draw?';

  @override
  String chessOfferDrawBody(String player) {
    return '$player can accept or decline. If accepted, the game ends in a draw.';
  }

  @override
  String get chessOfferDrawConfirm => 'Offer';

  @override
  String get chessDrawOfferTitle => 'Draw offer';

  @override
  String chessDrawOfferBody(String player) {
    return '$player offers a draw. If you accept, the game ends in a draw.';
  }

  @override
  String get chessDrawAccept => 'Accept';

  @override
  String get chessDrawDecline => 'Decline';

  @override
  String chessHintDrawOffered(String player) {
    return 'Draw offered – $player decides.';
  }

  @override
  String chessHintDrawDeclined(String player) {
    return '$player declined the draw.';
  }

  @override
  String get chessMoveDrawOffer => 'Draw offered';

  @override
  String get chessMoveDrawDecline => 'Draw declined';

  @override
  String get chessMoveDrawAccept => 'Draw accepted';

  @override
  String get engineReasonChessDrawAgreed => 'Draw agreed';

  @override
  String get engineReasonChessCheckmate => 'Checkmate';

  @override
  String get engineReasonChessStalemate => 'Stalemate';

  @override
  String get engineReasonChessInsufficientMaterial =>
      'Not enough material to checkmate';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves moves without a capture or pawn move';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return 'Same position $times times';
  }

  @override
  String get menuGameWordTiles => 'Wordsmith';

  @override
  String get menuDescWordTiles => 'Lay words from letter tiles';

  @override
  String menuPreviewGame(String game) {
    return 'Preview: $game';
  }

  @override
  String get wordtilesPlay => 'Play';

  @override
  String get wordtilesRecall => 'Take all tiles back';

  @override
  String get wordtilesShuffle => 'Shuffle tiles';

  @override
  String get wordtilesExchange => 'Swap';

  @override
  String wordtilesExchangeConfirm(int count) {
    return 'Swap $count';
  }

  @override
  String get wordtilesPass => 'Pass';

  @override
  String get wordtilesZoomIn => 'Zoom in';

  @override
  String get wordtilesZoomOut => 'Whole board';

  @override
  String wordtilesBag(int count) {
    return 'Bag: $count tiles';
  }

  @override
  String wordtilesScore(String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player: $_temp0';
  }

  @override
  String get wordtilesHintPlace =>
      'Drag tiles onto the board, or tap a tile and then a square.';

  @override
  String get wordtilesHintFirst =>
      'The first word must cross the star in the centre.';

  @override
  String wordtilesHintZoom(String hint) {
    return '$hint Pinch with two fingers to zoom.';
  }

  @override
  String get wordtilesHintSelected => 'Tap a free square.';

  @override
  String get wordtilesHintExchange =>
      'Pick the tiles to put back into the bag.';

  @override
  String get wordtilesHintAnswer => 'Accept the word or challenge it.';

  @override
  String wordtilesExchangeNotNow(int count) {
    return 'You can only swap while the bag holds at least $count tiles.';
  }

  @override
  String wordtilesPreview(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words: $_temp0';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words: $_temp0 (incl. $bonus bonus for all tiles)';
  }

  @override
  String get wordtilesErrorLine =>
      'The tiles must be in one row or one column.';

  @override
  String get wordtilesErrorGap => 'There is an empty square between the tiles.';

  @override
  String get wordtilesErrorShort =>
      'The first word needs at least two letters.';

  @override
  String get wordtilesErrorConnect =>
      'The tiles must connect to a word on the board.';

  @override
  String get wordtilesErrorUnknownWord => 'A word is not in the dictionary.';

  @override
  String get wordtilesErrorAnswerFirst =>
      'First accept or challenge the last word.';

  @override
  String get wordtilesErrorOther => 'You can’t place the tiles like that.';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player played $words for $_temp0.';
  }

  @override
  String get wordtilesAccept => 'Accept';

  @override
  String get wordtilesChallenge => 'Challenge';

  @override
  String get wordtilesChallengeTitle => 'Challenge the word?';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return 'Without a dictionary your call decides: $player takes the tiles back and scores nothing. Then it is your turn.';
  }

  @override
  String get wordtilesChallengeBodyDict =>
      'The dictionary decides. If the word is in it, you lose your turn.';

  @override
  String wordtilesEndPending(String player) {
    return '$player has played all tiles. If you accept, the game ends.';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words for $_temp0';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'swapped $count tiles',
      one: 'swapped 1 tile',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => 'passed';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return 'challenged: $words taken back';
  }

  @override
  String get wordtilesMoveChallengeFailed => 'challenged, but the words stand';

  @override
  String get wordtilesMoveAccept => 'accepted';

  @override
  String get wordtilesBlankTitle => 'Which letter is the blank?';

  @override
  String get wordtilesPremiumDoubleLetter => '2L';

  @override
  String get wordtilesPremiumTripleLetter => '3L';

  @override
  String get wordtilesPremiumDoubleWord => '2W';

  @override
  String get wordtilesPremiumTripleWord => '3W';

  @override
  String get wordtilesOptionTiles => 'Letters';

  @override
  String get wordtilesOptionDictionary => 'Check the dictionary';

  @override
  String get wordtilesOptionDictionaryOn =>
      'Every word laid is looked up. If one is missing, you decide together: take it back or allow it anyway.';

  @override
  String get wordtilesOptionDictionaryOff =>
      'Without a dictionary you judge yourselves: a word can be challenged.';

  @override
  String get wordtilesOptionsNext => 'Next';

  @override
  String get wordtilesDictLoading => 'Loading the dictionary …';

  @override
  String get wordtilesDictLoadFailed => 'The dictionary could not be loaded.';

  @override
  String get wordtilesUnknownTitle => 'Not in the dictionary';

  @override
  String wordtilesUnknownBody(String words, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '“$words” are not in the dictionary.',
      one: '“$words” is not in the dictionary.',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesUnknownAsk =>
      'You can take the tiles back. If you both agree it counts anyway, allow it.';

  @override
  String get wordtilesUnknownWithdraw => 'Take back';

  @override
  String get wordtilesUnknownAllow => 'Allow anyway';

  @override
  String wordtilesMovePlaceAllowed(String words, int score, String allowed) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$words for $_temp0 (allowed: $allowed)';
  }

  @override
  String get wordtilesBench => 'Bench';

  @override
  String get wordtilesBenchClear => 'Move all tiles back from the bench';

  @override
  String get wordtilesBenchHint => 'Drag tiles here to try out words.';

  @override
  String get wordtilesCoachBench1 =>
      'The bench is your notepad: drag tiles here and try out words.';

  @override
  String get wordtilesCoachBench2 =>
      'It only adds up the letter points. It does not check whether it is a real word.';

  @override
  String get wordtilesCoachBench3 =>
      'This button puts all tiles back. Only you can see your bench.';

  @override
  String wordtilesCoachStep(int step, int count) {
    return '$step of $count';
  }

  @override
  String get wordtilesCoachNext => 'Next';

  @override
  String get wordtilesCoachDone => 'Got it';

  @override
  String get wordtilesCoachSkip => 'Skip';

  @override
  String get wordtilesPassTitle => 'Pass?';

  @override
  String wordtilesPassBody(int count, int limit) {
    return 'Your turn ends without points. Scoreless turns in a row: $count of $limit. At $limit the game ends.';
  }

  @override
  String get wordtilesBlankScore => 'The blank scores 0 points.';

  @override
  String get wordtilesHelpGoal =>
      'Lay words like in a crossword. Every letter has points (the small number). The first word goes over the star in the middle, every further word connects.';

  @override
  String get wordtilesHelpPremium => 'Premium squares';

  @override
  String get wordtilesHelpDoubleLetter => 'Letter counts double';

  @override
  String get wordtilesHelpTripleLetter => 'Letter counts triple';

  @override
  String get wordtilesHelpDoubleWord => 'Whole word counts double';

  @override
  String get wordtilesHelpTripleWord => 'Whole word counts triple';

  @override
  String get wordtilesHelpPremiumOnce =>
      'Premium squares count only in the turn a tile is laid on them.';

  @override
  String wordtilesHelpBingo(int count, int bonus) {
    return 'All $count tiles laid in one turn: $bonus extra points.';
  }

  @override
  String get wordtilesHelpBlank =>
      'The blank becomes any letter you choose but scores 0 points. It shows a small 0.';

  @override
  String wordtilesHelpSwap(int count) {
    return 'Swap: tiles back into the bag, draw new ones. Only while at least $count tiles are in the bag, and it uses up the turn.';
  }

  @override
  String wordtilesHelpPass(int limit) {
    return 'Pass: you skip a turn. After $limit scoreless turns in a row the game ends.';
  }

  @override
  String get wordtilesHelpDictionary =>
      'With “Check the dictionary” every word is looked up when laid. If one is missing, take the tiles back or allow it together: “Allow anyway”. Allowed words appear in the history.';

  @override
  String get wordtilesHelpChallenge =>
      'Without the dictionary the last word can be challenged: the tiles go back and score nothing.';

  @override
  String get wordtilesHelpBench =>
      'Try out words on the bench. It shows only the letter points, not whether it is a word.';

  @override
  String get wordtilesHelpZoom =>
      'Zoom the board with two fingers and move it around. Drag a tile you just laid to move it; a tap takes it back.';

  @override
  String get wordtilesHelpEnd =>
      'The game ends when the bag is empty and someone has laid all tiles. The points of the tiles left are subtracted; whoever finished gets them added.';

  @override
  String get wordtilesHelpEndNoRest =>
      'The game ends when the bag is empty and someone has laid all tiles. Tiles left over do not count.';

  @override
  String wordtilesResultRack(String points) {
    return 'Tiles left: $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return 'Best word: $word ($player, $_temp0)';
  }

  @override
  String wordtilesResultAllowed(String words) {
    return 'Allowed anyway: $words';
  }

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return 'All tiles played, final score $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '$turns turns without points, final score $a : $b';
  }

  @override
  String get engineReasonWordtilesPlayedOutSeats => 'All tiles played';

  @override
  String engineReasonWordtilesScorelessSeats(int turns) {
    return '$turns turns without points';
  }

  @override
  String get webBetaBadge => 'Beta';

  @override
  String get aboutWebBeta =>
      'Web beta – games on several devices are in the app.';

  @override
  String get networkUnavailableWeb =>
      'Not available in the browser yet – with the app you can play on several devices.';

  @override
  String get appBetaTeaser => 'App beta coming soon.';

  @override
  String get appBetaIos => 'Try the iPhone and iPad app';

  @override
  String get appBetaAndroid => 'Get the Android app';

  @override
  String wordtilesOptionsSummaryDict(String language) {
    return '$language · dictionary check';
  }

  @override
  String wordtilesOptionsSummaryFree(String language) {
    return '$language · no dictionary';
  }

  @override
  String wordtilesOpenPlacementJoker(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player played $words for $_temp0 (blank swapped).';
  }

  @override
  String get wordtilesOptionJoker => 'Swap the blank';

  @override
  String get wordtilesOptionJokerExplain =>
      'Rule variant: if you hold the letter a blank on the board stands for, you may put it there and take the blank. Then you still lay tiles in the same turn.';

  @override
  String get wordtilesOptionRest => 'Deduct leftover tiles';

  @override
  String get wordtilesOptionRestExplain =>
      'Rule variant: at the end everyone loses the points of the tiles left on their rack; whoever laid all tiles gets them added. Off: only the words laid count.';

  @override
  String wordtilesOptionsSummaryJoker(String summary) {
    return '$summary · swap the blank';
  }

  @override
  String wordtilesOptionsSummaryNoRest(String summary) {
    return '$summary · no leftover deduction';
  }

  @override
  String get wordtilesHintJoker =>
      'Drag the matching letter onto a blank on the board to take the blank.';

  @override
  String get wordtilesJokerStaged =>
      'Blank taken. Now lay tiles too, or the swap does not count.';

  @override
  String wordtilesMoveJoker(String move) {
    return '$move (blank swapped)';
  }

  @override
  String wordtilesUnknownAskNet(String player) {
    return 'You can take the tiles back or ask $player to let it count anyway.';
  }

  @override
  String wordtilesUnknownDeclinedBefore(String player) {
    return '$player already declined it. Take the tiles back.';
  }

  @override
  String get wordtilesAllowTitle => 'Allow anyway?';

  @override
  String wordtilesAllowBody(String player, String words) {
    return '$player would like to allow “$words” – do you agree?';
  }

  @override
  String get wordtilesAllowAccept => 'Accept';

  @override
  String get wordtilesAllowDecline => 'Decline';

  @override
  String wordtilesAllowDeciding(String player) {
    return '$player decides…';
  }

  @override
  String get wordtilesAllowYouDecide => 'Your decision';

  @override
  String wordtilesAllowLine(String player, String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return '$player would like to allow “$words” ($_temp0).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '$player declined “$words”.';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return 'asks to allow $words ($_temp0)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    String _temp0 = intl.Intl.pluralLogic(
      score,
      locale: localeName,
      other: '$score points',
      one: '$score point',
    );
    return 'agreed: $words counts ($_temp0)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'declined: $words';
  }

  @override
  String get menuGameMauMau => 'Mau-Mau';

  @override
  String get menuDescMauMau => 'Play matching cards until your hand is empty';

  @override
  String get engineReasonMaumauEmptyHand => 'All cards played';

  @override
  String get maumauSuitClubs => 'Clubs';

  @override
  String get maumauSuitSpades => 'Spades';

  @override
  String get maumauSuitHearts => 'Hearts';

  @override
  String get maumauSuitDiamonds => 'Diamonds';

  @override
  String get maumauRankJack => 'Jack';

  @override
  String get maumauRankQueen => 'Queen';

  @override
  String get maumauRankKing => 'King';

  @override
  String get maumauRankAce => 'Ace';

  @override
  String get maumauRankLetterJack => 'J';

  @override
  String get maumauRankLetterQueen => 'Q';

  @override
  String get maumauRankLetterKing => 'K';

  @override
  String get maumauRankLetterAce => 'A';

  @override
  String maumauCardName(String suit, String rank) {
    return '$rank of $suit';
  }

  @override
  String get maumauOptionsIntro => 'Which rules do you want to play with?';

  @override
  String get maumauOptionsNext => 'Next';

  @override
  String get maumauOptionSeven => '7: draw two';

  @override
  String get maumauOptionSevenExplain =>
      'After a 7, the other player draws 2 cards.';

  @override
  String get maumauOptionStack => '7 on 7';

  @override
  String get maumauOptionStackExplain =>
      'Whoever has a 7 lays it on top. Then the other player draws 4 cards.';

  @override
  String get maumauOptionEight => '8: miss a turn';

  @override
  String get maumauOptionEightExplain =>
      'After an 8, the other player misses a turn.';

  @override
  String get maumauOptionJackInfo =>
      'Jack: fits almost anywhere. Whoever plays it wishes for a suit.';

  @override
  String get maumauOptionJackOnJack => 'Jack on jack';

  @override
  String get maumauOptionJackOnJackExplain => 'A jack may also go on a jack.';

  @override
  String get maumauOptionAce => 'Ace: go again';

  @override
  String get maumauOptionAceExplain =>
      'Whoever plays an ace takes another turn right away.';

  @override
  String get maumauOptionMau => 'Say “Mau!”';

  @override
  String get maumauOptionMauExplain =>
      'On your second-to-last card, press “Mau!” first. Forget it and you draw a penalty card.';

  @override
  String maumauOpponentCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$player: $_temp0';
  }

  @override
  String maumauYourCards(int count) {
    return 'Your cards ($count)';
  }

  @override
  String maumauStock(int count) {
    return 'Pile: $count';
  }

  @override
  String maumauStockLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'Draw pile, $_temp0';
  }

  @override
  String get maumauDiscard => 'Discard pile';

  @override
  String maumauWish(String suit) {
    return 'Wish: $suit';
  }

  @override
  String get maumauDraw => 'Draw a card';

  @override
  String maumauDrawPenalty(int count) {
    return 'Draw $count cards';
  }

  @override
  String get maumauKeep => 'Keep it';

  @override
  String get maumauPass => 'Pass';

  @override
  String get maumauMauButton => 'Mau!';

  @override
  String get maumauContinue => 'Continue';

  @override
  String get maumauPickSuitTitle => 'Which suit do you wish for?';

  @override
  String get maumauDrewNoFit => 'You drew this card. It does not fit.';

  @override
  String maumauDrewPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return 'You drew $_temp0. New in your hand:';
  }

  @override
  String get maumauHintPlay => 'Play a matching card or draw one.';

  @override
  String maumauHintWish(String suit) {
    return '$suit was wished for. Play one of those or draw a card.';
  }

  @override
  String maumauHintPenalty(int count) {
    return 'You have to draw $count cards.';
  }

  @override
  String maumauHintPenaltyStack(int count) {
    return 'Play a 7 or draw $count cards.';
  }

  @override
  String get maumauHintDrawn => 'The card you drew fits. Play it or keep it.';

  @override
  String get maumauHintPass => 'Nothing left to draw. You have to pass.';

  @override
  String get maumauHintMau =>
      'Second-to-last card: press “Mau!” first, then play.';

  @override
  String maumauLastPlayed(String player, String card) {
    return '$player played the $card.';
  }

  @override
  String maumauLastPlayedWish(String player, String card, String suit) {
    return '$player played the $card and wishes for $suit.';
  }

  @override
  String maumauLastDrew(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: 'a card',
    );
    return '$player drew $_temp0.';
  }

  @override
  String maumauLastDrewPenalty(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count penalty cards',
      one: 'a penalty card',
    );
    return '$player drew $_temp0.';
  }

  @override
  String maumauLastKept(String player) {
    return '$player drew a card and kept it.';
  }

  @override
  String maumauLastPassed(String player) {
    return '$player passed.';
  }

  @override
  String maumauExtraMau(String player) {
    return '$player says “Mau!”';
  }

  @override
  String maumauExtraForgotMau(String player) {
    return '$player forgot “Mau!” and draws a penalty card.';
  }

  @override
  String maumauExtraPenalty(String player, int count) {
    return '$player has to draw $count cards.';
  }

  @override
  String get coachNext => 'Next';

  @override
  String get coachDone => 'Let’s play!';

  @override
  String get coachSkip => 'Skip';

  @override
  String get maumauCoachPlay =>
      'Tap a matching card to play it. Matching cards stand higher and have a frame.';

  @override
  String get maumauCoachDraw =>
      'Nothing matches? Tap the draw pile to draw a card.';

  @override
  String get maumauCoachWin => 'Whoever gets rid of all cards first wins.';

  @override
  String get maumauCoachWinMau =>
      'Whoever gets rid of all cards first wins. Before the second-to-last card, press “Mau!”.';

  @override
  String maumauChainBadge(String sum, int count) {
    return 'Draw $sum = $count cards';
  }

  @override
  String maumauExtraPenaltyStacked(String player, int count) {
    return 'The 7s add up: $player now has to draw $count cards.';
  }

  @override
  String maumauExtraAgain(String player) {
    return '$player misses a turn.';
  }

  @override
  String maumauExtraAce(String player) {
    return '$player goes again.';
  }

  @override
  String get maumauExtraReshuffled =>
      'The discard pile was shuffled into a new draw pile.';

  @override
  String maumauMovePlay(String card) {
    return 'plays the $card';
  }

  @override
  String maumauMovePlayWish(String card, String suit) {
    return 'plays the $card, wishes for $suit';
  }

  @override
  String maumauMoveDraw(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: 'a card',
    );
    return 'draws $_temp0';
  }

  @override
  String get maumauMovePass => 'passes';

  @override
  String get maumauMoveKeep => 'keeps the drawn card';

  @override
  String get menuGameMaexchen => 'Mia';

  @override
  String get menuDescMaexchen => 'Roll the dice, bluff, catch the bluffs';

  @override
  String get engineReasonMaexchenNoLives => 'No lives left';

  @override
  String get maexchenOptionLives => 'Lives at the start';

  @override
  String get maexchenOptionDouble => 'Double Mia';

  @override
  String get maexchenOptionDoubleExplain =>
      'Everything about Mia counts double: doubting a real Mia or getting caught with a fake one costs 2 lives.';

  @override
  String get maexchenOptionsNext => 'Next';

  @override
  String get maexchenRoll => 'Roll';

  @override
  String get maexchenPeek => 'Peek';

  @override
  String get maexchenCover => 'Cover';

  @override
  String get maexchenPickTitle => 'What do you announce?';

  @override
  String maexchenAnnounce(String value) {
    return 'Announce $value';
  }

  @override
  String get maexchenOrder =>
      'Low to high: 31, 32 … 65, then doubles 11 … 66, then Mia (21).';

  @override
  String get maexchenBelieve => 'Believe';

  @override
  String get maexchenDoubt => 'Doubt';

  @override
  String get maexchenGiveUp => 'Give up a life';

  @override
  String maexchenAnnounced(String player, String value) {
    return '$player says $value';
  }

  @override
  String get maexchenNewRound => 'New round: any value goes';

  @override
  String get maexchenHintRoll => 'Tap Roll, then peek under the cup in secret.';

  @override
  String maexchenHintBelieved(String value) {
    return 'You believe $value. Roll and announce more than $value.';
  }

  @override
  String get maexchenHintAnnounceFirst =>
      'Peek in secret and announce a value. Bluffing is allowed!';

  @override
  String maexchenHintAnnounceHigher(String value) {
    return 'Announce more than $value. Bluffing is allowed!';
  }

  @override
  String maexchenHintRespond(String player, String value) {
    return '$player says $value. Do you believe it?';
  }

  @override
  String maexchenHintRespondMaexchen(String player) {
    return '$player says Mia! Nothing beats it: doubt, or give up a life?';
  }

  @override
  String maexchenUnderCup(String value) {
    return 'Under the cup: $value';
  }

  @override
  String maexchenVerdictBluff(String player) {
    return 'A bluff! $player loses a life.';
  }

  @override
  String maexchenVerdictTrue(String player) {
    return 'It was true! $player loses a life.';
  }

  @override
  String maexchenVerdictTrueTwo(String player) {
    return 'A real Mia! $player loses 2 lives.';
  }

  @override
  String maexchenVerdictBluffTwo(String player) {
    return 'A fake Mia! $player loses 2 lives.';
  }

  @override
  String maexchenVerdictGaveUp(String player) {
    return '$player gives up a life. The cup stays closed.';
  }

  @override
  String maexchenLivesOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lives',
      one: '1 life',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenRoundLabel(int round) {
    return 'Round $round';
  }

  @override
  String get maexchenMoveRoll => 'rolls';

  @override
  String maexchenMoveAnnounce(String value) {
    return 'announces $value';
  }

  @override
  String get maexchenMoveBelieve => 'believes it';

  @override
  String get maexchenMoveDoubt => 'doubts it';

  @override
  String get maexchenMoveGiveUp => 'gives up a life';

  @override
  String get maexchenMaexchenName => 'Mia';

  @override
  String get maexchenMaexchenCall => 'Mia!';

  @override
  String get maexchenAnnouncedLabel => 'Announced';

  @override
  String get maexchenPickFirst => 'Choose a number';

  @override
  String get maexchenShakeHint => 'or shake the phone';

  @override
  String get shakeToRollSetting => 'Shake to roll';

  @override
  String get shakeToRollExplain =>
      'Shake the phone like a dice cup instead of tapping Roll.';

  @override
  String get confirmMoveSetting => 'Confirm move';

  @override
  String get confirmMoveHelper => 'A move only counts after a tap on “Move”.';

  @override
  String get confirmMoveCommit => 'Move';

  @override
  String get confirmMoveBack => 'Other move';

  @override
  String get confirmMoveHint =>
      'Is this the right move? Tap “Move” or “Other move”.';

  @override
  String get confirmMoveOn => 'Confirm move is on.';

  @override
  String get confirmMoveOff => 'Confirm move is off.';

  @override
  String get rulesButton => 'Rules';

  @override
  String get menuCards => 'Cards';

  @override
  String rulesTitle(String game) {
    return 'Rules: $game';
  }

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count players',
      one: '1 player',
    );
    return '$_temp0';
  }

  @override
  String playerCountRange(int min, int max) {
    return '$min to $max players';
  }

  @override
  String get rulesGoal => 'Goal';

  @override
  String get rulesTurn => 'How a turn works';

  @override
  String get rulesSpecial => 'Rules';

  @override
  String get rulesHouse => 'Rule variants';

  @override
  String get rulesHouseInGame => 'Rule variants in this game';

  @override
  String get rulesHouseMenuNote =>
      'These are the suggested ones. You can change the rule variants before the game.';

  @override
  String get rulesNewHere => 'New here? How to play';

  @override
  String get rulesCoachHere => 'You can find all the rules here.';

  @override
  String get rulesConnect4Goal =>
      'Get 4 of your discs in a row: across, up and down, or diagonally.';

  @override
  String get rulesConnect4Turn =>
      'Tap a column. Your disc drops down to the lowest free space.\nThen it is the other player’s turn.\nPlayer 1 starts.';

  @override
  String get rulesConnect4Special =>
      'The board has 7 columns and 6 rows.\nA full column takes no more discs.\nIf the board is full and nobody has 4 in a row, it is a draw.';

  @override
  String get rulesMuehleGoal =>
      'Take the other player’s pieces until only 2 are left. Or block their pieces so they cannot move any more.';

  @override
  String get rulesMuehleTurn =>
      'Each player has 9 pieces. Player 1 starts.\nFirst you take turns putting one piece on a free point.\nOnce all pieces are placed, you slide a piece along a line to the free point next to it.\nWith only 3 pieces left, you may jump: to any free point.';

  @override
  String get rulesMuehleMill =>
      '3 pieces on one line make a mill. Then you take one of the other player’s pieces.';

  @override
  String get rulesMuehleSpecial =>
      'Pieces in a mill are safe. Only if all the other player’s pieces are in mills may you take one of them.\nIf you open a mill and close it again, it counts again.\n50 moves in a row without taking a piece (both players counted): a draw.';

  @override
  String get rulesTrumpfGoal =>
      'Win all the cards. Whoever runs out of cards loses.';

  @override
  String get rulesTrumpfTurn =>
      'Each player gets 16 cards as a face-down pile. You always play the top card.\nThe player whose turn it is picks a property of their card, for example the speed.\nThe better value wins the round. Usually higher is better, for some properties lower. The card says which.\nThe winner of the round puts both cards under their pile and picks next.\nPlayer 1 picks first.';

  @override
  String get rulesTrumpfSpecial =>
      'Same value: tie-break! Both cards go into the pot, and the same player picks again. Whoever wins the next round also gets the whole pot.\nAfter 200 rounds, whoever has more cards wins. With the same number it is a draw.\nIf both piles are empty, it is a draw too.';

  @override
  String get rulesTrumpfPickLow => '3 cards or fewer: choose';

  @override
  String get rulesTrumpfPickLowText =>
      'With only 2 or 3 cards left, you see all of them and choose which one to play. The picker chooses the card first and then the property. The other player chooses their card after hearing the property.';

  @override
  String get rulesSetsGoal =>
      'Collect quartets: all 4 cards of a set. Whoever has more quartets at the end wins.';

  @override
  String get rulesSetsTurn =>
      'Each player gets 8 cards. The other 16 lie face down as the pile.\nAsk the other player for a card you are missing. You must already have a card of that set.\nIf they have the card, they give it to you, and you may ask again.\nIf not, it is a miss: you draw a card from the pile, and it is the other player’s turn.\nPlayer 1 asks first.';

  @override
  String get rulesSetsSpecial =>
      'With all 4 cards of a set, you lay the quartet down at once.\nIf you draw the card you asked for, it is still the other player’s turn.\nIf you have no cards left, you draw one from the pile.\nWhen all 8 quartets are down, the game is over. 4 to 4 is a draw.';

  @override
  String get rulesSchiffeGoal =>
      'Sink all the other player’s ships before they sink yours.';

  @override
  String get rulesSchiffeTurn =>
      'First each player secretly places their fleet on their own sea of 10 by 10 squares. Player 1 starts.\nThen you take turns shooting: tap a square in the other player’s sea.\nYou shoot at each square only once.';

  @override
  String get rulesSchiffeMiss =>
      'Water: a miss. Now it is the other player’s turn.';

  @override
  String get rulesSchiffeHit => 'Hit! You may shoot again.';

  @override
  String get rulesSchiffeSunk =>
      'Sunk: every square of the ship is hit. You find out which ship it was.';

  @override
  String get rulesSchiffeFleet => 'The fleet';

  @override
  String rulesSchiffeShip(int count, String ship, int length) {
    return '$count × $ship ($length squares)';
  }

  @override
  String get rulesSchiffeSpecial =>
      'Ships lie straight: across or up and down.\nShips must not touch, not even at a corner.';

  @override
  String get rulesGoGoal =>
      'Capture the other player’s flag. You also win if the other player cannot move any more.';

  @override
  String get rulesGoTurn =>
      'First each player secretly sets up their 40 pieces on their 4 rows. Only the owner sees a piece’s rank.\nPlayer 1 sets up first and moves first.\nOn your turn you move one piece 1 square forward, back, left or right. Never diagonally.\nNo piece can go into the two lakes in the middle.';

  @override
  String get rulesGoFightTitle => 'Who beats whom?';

  @override
  String get rulesGoFight =>
      'If you move onto the other player’s piece, they fight. Afterwards both players see which pieces they were.\nThe higher rank wins. The loser is out.\nSame rank: both are out.';

  @override
  String get rulesGoPieces => 'The pieces';

  @override
  String rulesGoRank(int rank) {
    return 'Rank $rank';
  }

  @override
  String rulesGoCount(int count) {
    return '$count ×';
  }

  @override
  String get rulesGoMarshal =>
      'The strongest piece. Loses only to the spy, when the spy attacks.';

  @override
  String get rulesGoScout =>
      'Runs straight over any number of free squares and may attack at the end. If it runs more than 1 square, both players see that it is a scout.';

  @override
  String get rulesGoMiner =>
      'Defuses bombs: if it attacks one, it takes its place.';

  @override
  String get rulesGoSpy =>
      'The weakest piece. But if the spy attacks the marshal, the spy wins.';

  @override
  String get rulesGoBomb =>
      'Never moves. Any attacker is out and the bomb stays. Only the miner defuses it.';

  @override
  String get rulesGoFlag => 'Never moves. Whoever attacks it wins the game.';

  @override
  String get rulesGoSpecial =>
      'A piece may move back and forth between the same two squares at most 3 times in a row.\nOnce a piece has moved, the other player knows: it is not a bomb and not the flag.\n200 moves in a row without a fight: a draw. Also when nobody can move.';

  @override
  String get rulesGoZoom =>
      'Zoom the board with two fingers and move it around. The magnifier zooms in on your selected piece; tap it again to see the whole board.';

  @override
  String get rulesChessGoal =>
      'Checkmate the other player’s king: it is attacked and cannot escape.';

  @override
  String get rulesChessTurn =>
      'White starts, then you take turns.\nTap one of your pieces and then a square. If one of the other player’s pieces stands there, you capture it.\nOnly the knight may jump over other pieces.';

  @override
  String get rulesChessPieces => 'How the pieces move';

  @override
  String get rulesChessKing => '1 square in any direction.';

  @override
  String get rulesChessQueen => 'Any distance straight or diagonally.';

  @override
  String get rulesChessRook => 'Any distance straight.';

  @override
  String get rulesChessBishop => 'Any distance diagonally.';

  @override
  String get rulesChessKnight =>
      'Like an L: 2 squares straight, then 1 to the side. It jumps over pieces.';

  @override
  String get rulesChessPawn =>
      '1 square forward, on its first move also 2. It captures 1 square diagonally forward.';

  @override
  String get rulesChessSpecial =>
      'Check: your king is attacked. You must save it at once. A move that leaves your king in check is not allowed.\nCheckmate: the king is in check and cannot be saved. Whoever gives checkmate wins.\nCastling: king and rook have not moved yet, and everything between them is free. The king moves 2 squares towards the rook, the rook jumps next to it. Not allowed while the king is in check or if it would cross an attacked square.\nEn passant: if a pawn moves 2 squares and lands next to your pawn, you may capture it diagonally on your very next move, as if it had moved only 1 square.\nPromotion: when a pawn reaches the last row, it becomes a queen, a rook, a bishop or a knight. You choose.';

  @override
  String get rulesChessDrawTitle => 'Draw';

  @override
  String get rulesChessDraw =>
      'Stalemate: the player whose turn it is cannot move but is not in check.\nThere are too few pieces left to give checkmate.\nThe same position comes up for the 3rd time.\n75 moves by each player without a capture or a pawn move.\nAgreed draw: the player whose turn it is can offer a draw. The other player accepts or declines.';

  @override
  String get rulesWordtilesWin =>
      'Whoever has the most points at the end wins.';

  @override
  String get rulesWordtilesTurn =>
      'You have 7 tiles on your rack.\nLay 1 to 7 tiles in one row or column, with no gap.\nYou score all new words, also the words across them.\nThen you draw tiles from the bag until you have 7 again.';

  @override
  String get rulesWordtilesChallengeAfter =>
      'The player who challenged then takes their turn as usual.';

  @override
  String get rulesWordtilesPlayers =>
      'Two, three or four players on one device take turns. In a room you play as two.';

  @override
  String get rulesWordtilesChallengeNext =>
      'Only the next player can challenge.';

  @override
  String get rulesWordtilesScoreless =>
      'If the game ends because nobody scores any more, everyone loses the points of their remaining tiles.';

  @override
  String get rulesWordtilesNoRestTitle => 'No leftover deduction';

  @override
  String get rulesWordtilesNoRest =>
      'Nothing is deducted or added at the end: only the words laid count.';

  @override
  String get rulesMaumauGoal => 'Be the first to get rid of all your cards.';

  @override
  String get rulesMaumauTurn =>
      'There are 32 cards. Each player gets 5, one lies face up in the middle. Player 1 starts.\nPut a card of the same suit or the same value on it, for example hearts on hearts or 9 on 9.\nIf no card fits or you do not want to play one, you draw 1 card. If it fits, you may play it or keep it. If not, it is the other player’s turn.\nWhen the pile is empty, the played cards are shuffled into a new pile.';

  @override
  String get rulesMaumauJack =>
      'Jack: fits on any card except a jack. You wish for a suit. Then that suit must come next, or a jack.';

  @override
  String get rulesMaumauSpecial =>
      'The first card in the middle does not count as a special card.\n9, 10, queen and king are normal cards.\nWhoever plays their last card wins, also with a special card.';

  @override
  String get rulesMaexchenGoal =>
      'Do not lose all your lives. Whoever still has lives at the end wins.';

  @override
  String get rulesMaexchenTurn =>
      'Roll 2 dice under the cup. Only you see them.\nAnnounce a value. It must be higher than the last announcement. You may also bluff!\nThe other player believes you or doubts.\nIf they believe you, they roll themselves and must announce even higher.\nIf they doubt, the cup is lifted. If the roll is lower than announced, the announcer loses a life. Otherwise the doubter loses one.';

  @override
  String get rulesMaexchenOrderTitle => 'Which roll is higher?';

  @override
  String get rulesMaexchenOrder =>
      'The higher die counts first: 3 and 1 is 31.\nFrom low to high: 31, 32, 41, 42, 43 and so on up to 65.\nHigher are the doubles: 11, 22, 33, 44, 55, 66.\nThe highest is 21: Mia!';

  @override
  String get rulesMaexchenSpecial =>
      'The first announcement of a round may be any value.\nIf Mia is announced, you cannot believe it. You doubt, or you give up a life without looking.\nWhoever loses a life starts the next round.\nShaking: instead of tapping “Roll”, you can shake the phone like a cup.';

  @override
  String rulesMaexchenLives(int count) {
    return 'Everyone starts with $count lives.';
  }

  @override
  String get shakeConsentTitle => 'Roll by shaking?';

  @override
  String get shakeConsentBody =>
      'Your browser will ask in a moment whether Klunki may sense the phone moving. We only use this for rolling the dice, and it stays on the device.';

  @override
  String get shakeConsentYes => 'Yes, allow shaking';

  @override
  String get shakeConsentNo => 'No, just tap';

  @override
  String get wordtilesHelp => 'How to play';

  @override
  String get wordtilesHelpJoker =>
      'Swap the blank (rule variant): if you hold the letter a blank on the board stands for, drag it onto the blank. The blank joins your tiles, and you still lay tiles in the same turn (the blank may be one of them). Without laying, the swap does not count. The old word and its points stay.';

  @override
  String get wordtilesHelpJokerOn => 'On in this game.';

  @override
  String get wordtilesHelpJokerOff =>
      'Off in this game. You can turn it on before a game.';

  @override
  String get menuGameDiceSheet => 'Rolled Out';

  @override
  String get menuDescDiceSheet => 'Five dice, one sheet, up to four players';

  @override
  String get engineReasonDicesheetAllFilled => 'Every box is filled';

  @override
  String get playerDefaultNameC => 'Cleo';

  @override
  String get playerDefaultNameD => 'Dan';

  @override
  String get seatPlayerCount => 'How many are playing?';

  @override
  String get seatResignWho => 'Who gives up? The others play on.';

  @override
  String get seatOut => 'gave up';

  @override
  String seatPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points',
      one: '$points point',
    );
    return '$_temp0';
  }

  @override
  String get seatSharedFirst => 'A tie for first place!';

  @override
  String get seatReasonOthersResigned => 'Everyone else gave up';

  @override
  String get dicesheetBoxOnes => 'Ones';

  @override
  String get dicesheetBoxTwos => 'Twos';

  @override
  String get dicesheetBoxThrees => 'Threes';

  @override
  String get dicesheetBoxFours => 'Fours';

  @override
  String get dicesheetBoxFives => 'Fives';

  @override
  String get dicesheetBoxSixes => 'Sixes';

  @override
  String get dicesheetBoxThreeKind => 'Three of a Kind';

  @override
  String get dicesheetBoxFourKind => 'Four of a Kind';

  @override
  String get dicesheetBoxFullHouse => 'Full House';

  @override
  String get dicesheetBoxSmallStraight => 'Small Straight';

  @override
  String get dicesheetBoxLargeStraight => 'Large Straight';

  @override
  String get dicesheetBoxFiveKind => 'Five of a Kind';

  @override
  String get dicesheetBoxChance => 'Chance';

  @override
  String dicesheetMoveRoll(String dice) {
    return 'rolls $dice';
  }

  @override
  String dicesheetMoveRollKeep(String dice, int count) {
    return 'rolls $dice (keeps $count)';
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
    return '$player: $points for $box.';
  }

  @override
  String get dicesheetHintRoll => 'Tap Roll.';

  @override
  String get dicesheetHintKeep =>
      'Tap the dice you want to keep and roll again. Or pick a box on the sheet.';

  @override
  String get dicesheetHintPick => 'Pick a box on the sheet.';

  @override
  String get dicesheetHintJoker =>
      'Five of a Kind as a joker: write it into one of the allowed boxes.';

  @override
  String dicesheetRollButton(int count) {
    return 'Roll ($count left)';
  }

  @override
  String get dicesheetPickBox => 'Pick a box on the sheet';

  @override
  String dicesheetDie(int value) {
    return 'Die $value';
  }

  @override
  String dicesheetDieKept(int value) {
    return 'Die $value, kept';
  }

  @override
  String get dicesheetKept => 'kept';

  @override
  String dicesheetRound(int round, int total) {
    return 'Round $round/$total';
  }

  @override
  String dicesheetScoreAction(String box, int points) {
    return 'Write $points into $box';
  }

  @override
  String get dicesheetBonus => 'Bonus';

  @override
  String dicesheetBonusRule(String bonus, int at) {
    return '$bonus from $at';
  }

  @override
  String get dicesheetExtraFives => 'Extra fives';

  @override
  String get dicesheetTotal => 'Total';

  @override
  String get dicesheetOptionExtraFives => 'Extra fives (rule variant)';

  @override
  String get dicesheetOptionExtraFivesExplain =>
      'Another Five of a Kind when that box already holds 50: 100 extra points. It is a joker then and goes into the top box of its number first.';

  @override
  String get rulesDicesheetGoal =>
      'Score as many points as you can on your sheet with five dice.\nAfter 13 rounds every box is filled. The most points wins. With equal points you share the place.';

  @override
  String get rulesDicesheetTurn =>
      '2 to 4 play on one device, taking turns.\nRoll all five dice. You may roll up to three times.\nBefore the 2nd and 3rd roll, tap the dice you want to keep. Roll the others again.\nThen write what the dice score into exactly one empty box of your sheet. The sheet shows you how many points each box gives.\nIf nothing fits, cross out a box: it gets 0.';

  @override
  String get rulesDicesheetUpperTitle => 'Top: Ones to Sixes';

  @override
  String get rulesDicesheetUpper =>
      'Only the dice showing the box\'s number count, added up.';

  @override
  String rulesDicesheetBonus(int at, int bonus) {
    return 'With $at points or more in the top part you get a $bonus-point bonus.';
  }

  @override
  String get rulesDicesheetLowerTitle => 'Bottom';

  @override
  String get rulesDicesheetThreeKind => 'At least 3 the same. All dice count.';

  @override
  String get rulesDicesheetFourKind => 'At least 4 the same. All dice count.';

  @override
  String rulesDicesheetFullHouse(int points) {
    return '3 the same and 2 the same: $points points.';
  }

  @override
  String rulesDicesheetSmallStraight(int points) {
    return '4 numbers in a row: $points points.';
  }

  @override
  String rulesDicesheetLargeStraight(int points) {
    return '5 numbers in a row: $points points.';
  }

  @override
  String rulesDicesheetFiveKind(int points) {
    return '5 the same: $points points.';
  }

  @override
  String get rulesDicesheetChance => 'Always fits. All dice count.';

  @override
  String get rulesDicesheetSpecial =>
      'You fill each box only once.\nA roll counts at once. “Undo move” only takes back what you wrote on the sheet, as long as nobody has rolled since.\nWhoever resigns is out. The others play on.\nShaking: instead of tapping “Roll”, you can shake the phone.';

  @override
  String rulesDicesheetExtraFives(int bonus) {
    return 'Another Five of a Kind when that box already holds 50: $bonus extra points. Once the Five of a Kind box is filled (even with 0), a Five of a Kind is a joker: into the top box of its number first; if that is full, into a free bottom box at full points; otherwise into a top box with 0.';
  }

  @override
  String get dicesheetStartTitle => 'Who starts?';

  @override
  String get dicesheetStartFirst => 'First player';

  @override
  String get dicesheetStartOrder => 'Set the order';

  @override
  String get dicesheetStartRandom => 'Random';

  @override
  String get dicesheetStartFirstExplain =>
      'The name at the top of the list starts. Then you take turns.';

  @override
  String get dicesheetStartOrderExplain =>
      'In the next step you put the names in your order.';

  @override
  String get dicesheetStartRandomExplain =>
      'The game draws who starts. Then you take turns.';

  @override
  String get seatOrderHint =>
      'You play in the order of the names here. Use the arrows to change it.';

  @override
  String get seatMoveUp => 'Move up';

  @override
  String get seatMoveDown => 'Move down';

  @override
  String get seatRandomStartHint => 'The game draws who starts.';

  @override
  String seatStarts(String player) {
    return 'Let’s go: $player starts.';
  }

  @override
  String seatStartsRandom(String player) {
    return 'Drawn: $player starts!';
  }

  @override
  String get rulesDicesheetStart =>
      'Before the game you choose who starts: the name at the top of the list, your own order, or chance.';

  @override
  String get maumauOptionMustPlay => 'Lay a card if you can';

  @override
  String get maumauOptionMustPlayExplain =>
      'You may only draw when no card fits. After a 7 you may always take the cards.';

  @override
  String get maumauHintMustPlay => 'You have a card that fits – lay it.';

  @override
  String get maumauHintNoFit => 'No card fits. Draw one from the pile.';

  @override
  String get rulesMaumauTurnMustPlay =>
      'There are 32 cards. Each player gets 5, one lies face up in the middle. Player 1 starts.\nPut a card of the same suit or the same value on it, for example hearts on hearts or 9 on 9.\nIf no card fits, you draw 1 card. If it fits, you may play it or keep it. If not, it is the other player’s turn.\nWhen the pile is empty, the played cards are shuffled into a new pile.';

  @override
  String get dicesheetBeginnerOption => 'Beginner mode';

  @override
  String get dicesheetBeginnerExplain =>
      'The box that fits well right now lights up on the sheet. You can still pick any box.';

  @override
  String get dicesheetTipsOption => 'Tips';

  @override
  String get dicesheetTipsExplain =>
      'A speech bubble says which box fits well right now and why, and which dice to keep.';

  @override
  String get dicesheetTipLabel => 'Tip';

  @override
  String get dicesheetTipShow => 'Show tip';

  @override
  String dicesheetTipBonus(String box, int points, int goal) {
    return 'Tip: $box – $points points help you toward the bonus ($goal).';
  }

  @override
  String dicesheetTipAllDice(String box, int points) {
    return 'Tip: $box – all dice count, that gives $points points.';
  }

  @override
  String dicesheetTipFixed(String box, int points) {
    return 'Tip: $box – that gives $points points. Take them!';
  }

  @override
  String dicesheetTipPoints(String box, int points) {
    return 'Tip: $box – that gives $points points.';
  }

  @override
  String dicesheetTipLeastLoss(String box, int points) {
    return 'Tip: No good box? $box gives only $points points, but you lose the least there.';
  }

  @override
  String dicesheetTipStrike(String box) {
    return 'Tip: No good box? Cross out $box, you lose the least there.';
  }

  @override
  String dicesheetTipRicher(String box, int points) {
    return '$box would give $points points now, but it is worth more later.';
  }

  @override
  String get dicesheetTipSaveChance => 'Save Chance for later.';

  @override
  String get dicesheetTipOnce => 'Each box can be used only once – Chance too.';

  @override
  String get dicesheetTipKeep =>
      'Tip: Keep these dice and roll the others again:';

  @override
  String get dicesheetTipRerollAll =>
      'Tip: Nothing goes well together. Roll all of them again.';

  @override
  String get dicesheetTipStop => 'Great roll! You don’t need to roll again.';

  @override
  String get dicesheetTipsEnd => 'Turn tips off';

  @override
  String get dicesheetTipsEnded =>
      'Tips off. You can turn them back on in the options.';

  @override
  String dicesheetFreeBoxes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count boxes left',
      one: '1 box left',
    );
    return '$_temp0';
  }

  @override
  String rulesDicesheetOnce(int count) {
    return 'You fill each box only once. $count boxes, $count rounds.';
  }

  @override
  String get rulesDicesheetBeginner =>
      'Beginner mode (on in your first game): the box that fits well right now lights up on the sheet. Tips (on in your first 5 games): a speech bubble says why and which dice to keep. You can turn both on or off in the options. You can still pick any box.';

  @override
  String dicesheetCoachRoll(int count) {
    return 'You have up to $count rolls per turn.';
  }

  @override
  String get dicesheetCoachKeep => 'Tap the dice that should stay.';

  @override
  String get dicesheetCoachSheet =>
      'Then you write the roll into one box. The number shows how many points it gives.';

  @override
  String dicesheetCoachOnce(int count) {
    return 'Each box only once – $count boxes, $count rounds. The most points wins.';
  }

  @override
  String get dicesheetCoachReplay => 'Quick tour';

  @override
  String get menuGameProperty => 'Housing Corp';

  @override
  String get menuDescProperty => 'Buy streets, collect rent, build';

  @override
  String get engineReasonPropertyLastSolvent =>
      'Everyone else is bankrupt or out';

  @override
  String engineReasonPropertyRoundLimit(int rounds) {
    return 'After $rounds rounds the biggest fortune wins';
  }

  @override
  String propertyMoney(int amount) {
    return '$amount coins';
  }

  @override
  String get propertyOptionsBoard => 'Board';

  @override
  String get propertyThemeBerlin => 'Berlin';

  @override
  String get propertyThemeFantasie => 'Fantasy Town';

  @override
  String get propertyThemeGermanNote =>
      'Street names and cards are in German for now.';

  @override
  String get propertyOptionsLength => 'Game length';

  @override
  String get propertyOptionsUntilEnd => 'Until only one is left';

  @override
  String propertyOptionsRounds(int rounds) {
    return '$rounds rounds';
  }

  @override
  String get propertyOptionsRoundsExplain =>
      'With a round limit, whoever owns the most wins at the end.';

  @override
  String get propertyOptionsVariants => 'Rule variants';

  @override
  String propertyFreeTitle(String square) {
    return 'On “$square”';
  }

  @override
  String get propertyFreeNone => 'Nothing happens';

  @override
  String get propertyFreePot => 'Pot of taxes and fines';

  @override
  String propertyFreePotSeed(String amount) {
    return 'Pot, starts with $amount';
  }

  @override
  String propertyFreeBonus(String amount) {
    return 'A fixed $amount';
  }

  @override
  String get propertyFreeExplain =>
      'Pot: taxes and card fines go into the middle. Whoever lands on the square takes it all.';

  @override
  String propertyFreeBonusExplain(String square, String amount) {
    return 'Landing on “$square” pays $amount.';
  }

  @override
  String get propertyRuleDoubleStart => 'Double salary on Start';

  @override
  String propertyRuleDoubleStartExplain(String amount) {
    return 'Landing exactly on Start pays $amount.';
  }

  @override
  String get propertyRuleNoRentInPause => 'No rent during the break';

  @override
  String get propertyRuleNoRentInPauseExplain =>
      'Whoever sits in the break gets no rent.';

  @override
  String get propertyRuleBankruptAuction => 'Auction on bankruptcy';

  @override
  String get propertyRuleBankruptAuctionExplain =>
      'When someone goes bankrupt to the bank, their streets are auctioned instead of returned.';

  @override
  String get propertyRoll => 'Roll';

  @override
  String propertyBuy(String amount) {
    return 'Buy for $amount';
  }

  @override
  String get propertyDecline => 'Don’t buy – auction';

  @override
  String get propertyTooPoor => 'Not enough money to buy';

  @override
  String propertyFreeToBuy(String square) {
    return '$square belongs to nobody yet.';
  }

  @override
  String propertyAuctionTitle(String square) {
    return 'Auction: $square';
  }

  @override
  String propertyAuctionHigh(String amount, String player) {
    return 'Highest bid: $amount by $player';
  }

  @override
  String get propertyAuctionNone => 'No bid yet';

  @override
  String propertyAuctionTurn(String player) {
    return '$player’s turn to bid.';
  }

  @override
  String propertyBid(String amount) {
    return 'Bid $amount';
  }

  @override
  String get propertyPass => 'Drop out';

  @override
  String get propertyEndTurn => 'End turn';

  @override
  String propertyPayBail(String amount) {
    return 'Pay $amount and leave';
  }

  @override
  String get propertyUseCard => 'Use free card';

  @override
  String propertyInPause(String player, String square) {
    return '$player is stuck in “$square”: roll doubles, pay or use a free card.';
  }

  @override
  String get propertyManage => 'My streets';

  @override
  String propertyManageOf(String player) {
    return 'Streets: $player';
  }

  @override
  String propertyDebt(String player, String amount, String cash) {
    return '$player owes $amount but has only $cash. Sell buildings or mortgage streets.';
  }

  @override
  String get propertyBankrupt => 'Declare bankruptcy';

  @override
  String propertyBuild(String amount) {
    return 'Build ($amount)';
  }

  @override
  String propertySell(String amount) {
    return 'Sell (+$amount)';
  }

  @override
  String propertyMortgage(String amount) {
    return 'Mortgage (+$amount)';
  }

  @override
  String propertyUnmortgage(String amount) {
    return 'Lift mortgage ($amount)';
  }

  @override
  String get propertyManageEmpty => 'No streets yet.';

  @override
  String get propertyMortgaged => 'mortgaged';

  @override
  String propertyOwnerLine(String player) {
    return 'Owned by $player';
  }

  @override
  String get propertyOwnerNone => 'Still belongs to the bank';

  @override
  String propertyPrice(String amount) {
    return 'Price: $amount';
  }

  @override
  String propertyRent(String amount) {
    return 'Rent: $amount';
  }

  @override
  String propertyHouseCost(String amount) {
    return 'Each building costs $amount';
  }

  @override
  String get propertyStationRents => 'Rent by number of stations owned';

  @override
  String propertyTax(String amount) {
    return 'Pay: $amount';
  }

  @override
  String propertyCardSquare(String deck) {
    return 'Draw a card: $deck';
  }

  @override
  String propertyStartSquare(String amount) {
    return 'Passing pays $amount.';
  }

  @override
  String get propertyPauseSquare =>
      'Break: out with doubles, money or a free card. Just visiting? Nothing happens.';

  @override
  String get propertyGoToPauseSquare => 'Off to the break!';

  @override
  String get propertyOut => 'out';

  @override
  String propertyStreets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count streets',
      one: '1 street',
      zero: 'no streets',
    );
    return '$_temp0';
  }

  @override
  String get propertyCoachRoll => 'Roll and move your token around the board.';

  @override
  String get propertyCoachBoard =>
      'Land on a free street and you may buy it. Whoever lands on your street pays you rent. Tap a square for more.';

  @override
  String get propertyCoachPlayers =>
      'Here you see everyone’s money. Whoever runs out of money is bankrupt.';

  @override
  String get propertyCoachManage =>
      'Own a whole colour and you build here – then the rent goes up a lot.';

  @override
  String get propertyCoachReplay => 'Quick tour';

  @override
  String propertyEvRolled(String player, int a, int b) {
    return '$player rolls $a + $b';
  }

  @override
  String propertyEvSalary(String player, String amount) {
    return '$player collects $amount salary';
  }

  @override
  String propertyEvCard(String text) {
    return 'Card: “$text”';
  }

  @override
  String propertyEvCollected(String player, String amount) {
    return '$player gets $amount';
  }

  @override
  String propertyEvPot(String player, String amount) {
    return '$player takes the pot: $amount';
  }

  @override
  String propertyEvPaidBank(String player, String amount) {
    return '$player pays $amount to the bank';
  }

  @override
  String propertyEvPaidPot(String player, String amount) {
    return '$player pays $amount into the pot';
  }

  @override
  String propertyEvPaid(String player, String amount, String other) {
    return '$player pays $amount to $other';
  }

  @override
  String propertyEvBought(String player, String square, String amount) {
    return '$player buys $square for $amount';
  }

  @override
  String propertyEvBid(String player, String amount) {
    return '$player bids $amount';
  }

  @override
  String propertyEvPassed(String player) {
    return '$player drops out';
  }

  @override
  String propertyEvUnsold(String square) {
    return 'No bids: $square stays with the bank';
  }

  @override
  String propertyEvBuilt(String player, String building, String square) {
    return '$player builds $building on $square';
  }

  @override
  String propertyEvSold(String player, String square, String amount) {
    return '$player sells on $square: +$amount';
  }

  @override
  String propertyEvMortgaged(String player, String square, String amount) {
    return '$player mortgages $square: +$amount';
  }

  @override
  String propertyEvUnmortgaged(String player, String square, String amount) {
    return '$player lifts the mortgage on $square: −$amount';
  }

  @override
  String propertyEvToPause(String player, String square) {
    return '$player has to go to “$square”';
  }

  @override
  String get propertyEvThreeDoubles => 'Three doubles in a row!';

  @override
  String propertyEvLeftPause(String player) {
    return '$player is free again';
  }

  @override
  String propertyEvStayInPause(String player, int tries) {
    return 'No doubles: $player stays in the break ($tries/3)';
  }

  @override
  String propertyEvBankrupt(String player) {
    return '$player is bankrupt';
  }

  @override
  String propertyEvResigned(String player) {
    return '$player gives up';
  }

  @override
  String get rulesPropertyGoal =>
      'Buy streets, collect rent and build on them.\nThe last one still in the game wins. With a round limit the biggest fortune wins at the end.';

  @override
  String rulesPropertyTurn(String salary) {
    return 'Roll two dice and move that many squares.\nLand on a free street and you may buy it. If you don’t, it is auctioned: the highest bid gets it.\nIf someone else owns the street, you pay rent.\nRoll doubles and you roll again.\nPassing Start pays $salary.';
  }

  @override
  String rulesPropertySpecial(String bail) {
    return 'Own a whole colour group and the rent is doubled, and you may build: evenly, first 4 small, then 1 big building per street.\nCards give money, cost money or send you across the board.\nThree doubles in a row send you to the break. You get out with doubles, with $bail or with a free card.\nShort of money? Sell buildings for half the price or mortgage streets. You are bankrupt only when even that is not enough.\nA mortgage pays half the price; lifting it costs 10 % more. A mortgaged street brings no rent.';
  }

  @override
  String get propertyDeedRent => 'Rent';

  @override
  String get propertyDeedRentGroup => 'With the whole colour group';

  @override
  String get propertyDeedMortgageValue => 'Mortgage value';

  @override
  String propertyDeedStations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '$_temp0';
  }

  @override
  String get propertyDeedUtilityOne => 'With one of the two';

  @override
  String get propertyDeedUtilityBoth => 'With both';

  @override
  String propertyDeedDiceTimes(int factor) {
    return 'Dice total × $factor';
  }

  @override
  String get maexchenOptionUnlimited => 'Unlimited lives';

  @override
  String get maexchenOptionUnlimitedExplain =>
      'Nobody drops out. Every lost life is counted. You play until you end the game: whoever lost the fewest lives wins.';

  @override
  String get maexchenEndGame => 'End game';

  @override
  String get maexchenEndGameTitle => 'End the game?';

  @override
  String get maexchenEndGameBody =>
      'Whoever lost the fewest lives wins. A tie shares the place.';

  @override
  String get maexchenEndGameConfirm => 'End';

  @override
  String get engineReasonMaexchenEnded =>
      'You ended the game. Whoever lost the fewest lives wins.';

  @override
  String maexchenLostOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lost $count lives',
      one: 'lost 1 life',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenResultLost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'lost $count lives',
      one: 'lost 1 life',
    );
    return '$_temp0';
  }

  @override
  String maexchenResultLives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lives left',
      one: '1 life left',
    );
    return '$_temp0';
  }

  @override
  String get maexchenResultOut => 'out';

  @override
  String get rulesMaexchenPlayers =>
      'Two, three or four players on one device. The cup goes round the table: you always announce to the next player. Whoever has no lives left is out and gets skipped.';

  @override
  String get rulesMaexchenGoalUnlimited =>
      'Lose as few lives as you can. You play until you end the game.';

  @override
  String get rulesMaexchenEndHow =>
      '“End game” is in the menu with the three dots.';

  @override
  String propertyInPausePhrase(String player, String place) {
    return '$player $place: roll doubles, pay or use a free card.';
  }

  @override
  String propertyEvToPausePhrase(String player, String place) {
    return '$player has to go $place';
  }

  @override
  String get propertyTrade => 'Trade';

  @override
  String get propertyTradeTitle => 'Offer a trade';

  @override
  String get propertyTradeWith => 'With whom?';

  @override
  String get propertyTradeGive => 'You give';

  @override
  String get propertyTradeGet => 'You get';

  @override
  String get propertyTradeMoney => 'Money';

  @override
  String get propertyTradeMoneyReset => 'Back to 0';

  @override
  String get propertyTradeFreeCards => 'Free cards';

  @override
  String propertyTradeCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count free cards',
      one: '1 free card',
    );
    return '$_temp0';
  }

  @override
  String get propertyTradeNothing => 'nothing';

  @override
  String get propertyTradeNoStreets => 'No streets';

  @override
  String get propertyTradeOffer => 'Make offer';

  @override
  String propertyTradeOffersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers left this turn',
      one: '1 offer left this turn',
    );
    return '$_temp0';
  }

  @override
  String get propertyTradeEmpty => 'Pick what you want to swap.';

  @override
  String get propertyTradeHouses => 'Buildings in this colour: not tradable';

  @override
  String propertyTradeTooMany(int count) {
    return 'Already $count offers this turn.';
  }

  @override
  String get propertyTradeNotNow => 'No trading right now.';

  @override
  String get propertyTradeNoMoney => 'Not that much money.';

  @override
  String propertyTradeOfferFor(String player, String other) {
    return 'Trade offer from $player to $other';
  }

  @override
  String get propertyTradeAccept => 'Accept';

  @override
  String get propertyTradeDecline => 'Decline';

  @override
  String propertyEvTradeOffered(
    String player,
    String other,
    String give,
    String get,
  ) {
    return 'Trade offer from $player to $other: $give for $get';
  }

  @override
  String propertyEvTraded(String player) {
    return '$player accepts the trade';
  }

  @override
  String propertyEvTradeDeclined(String player) {
    return '$player declines the trade';
  }

  @override
  String get propertyCoachTrade =>
      'Missing one street for a whole colour? Offer a trade here.';

  @override
  String rulesPropertyTrade(int count) {
    return 'On your turn you may offer a trade before or after rolling: streets, money and free cards, up to $count offers per turn.\nStreets with buildings in their colour cannot be traded: sell the buildings first. Mortgaged streets stay mortgaged.\nThe device goes to the other player, who accepts or declines. An answered trade cannot be taken back.';
  }

  @override
  String get propertyTradeShowBoard => 'Look at the board';

  @override
  String get propertyTradeShowOffer => 'Back to the offer';

  @override
  String get chessClockLabel => 'Chess clock';

  @override
  String get chessClockNone => 'No clock';

  @override
  String chessClockMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String chessClockMinutesIncrement(int minutes, int seconds) {
    return '$minutes min + $seconds s';
  }

  @override
  String get chessClockHelper =>
      'The clock runs for the side to move. When the time is up, the game is lost.';

  @override
  String chessClockSemantics(String player, String time) {
    return 'Clock of $player: $time';
  }

  @override
  String get chessClockPause => 'Pause';

  @override
  String get chessClockPausedTitle => 'Paused – the clocks are stopped';

  @override
  String get chessClockResume => 'Continue';

  @override
  String chessClockPauseAsk(String player) {
    return '$player would like a break.';
  }

  @override
  String chessClockResumeAsk(String player) {
    return '$player would like to go on.';
  }

  @override
  String chessClockWaiting(String player) {
    return 'Asked – $player decides.';
  }

  @override
  String chessClockRefusedHint(String player) {
    return '$player said no.';
  }

  @override
  String get chessMoveTimeout => 'Time is up';

  @override
  String get chessMovePauseAsk => 'Asked for a break';

  @override
  String get chessMoveResumeAsk => 'Asked to go on';

  @override
  String get chessMovePaused => 'Break';

  @override
  String get chessMoveResumed => 'Go on';

  @override
  String get chessMoveClockRefused => 'Declined';

  @override
  String engineReasonChessTimeout(String player) {
    return '$player ran out of time';
  }

  @override
  String engineReasonChessTimeoutDraw(String player) {
    return '$player ran out of time, but a lone king cannot give mate';
  }

  @override
  String rulesChessClockTitle(String time) {
    return 'Chess clock: $time';
  }

  @override
  String get rulesChessClock =>
      'Each side has its own thinking time. The clock runs for the side to move and switches with every move – with “Confirm move” only on “Move”.\nWhen the time is up, the other side wins. If that side has only the king left, it is a draw.\nPause stops both clocks; over the network only when both agree.\n“Take back” also turns the clock back.';

  @override
  String rulesChessClockIncrement(int seconds) {
    return '$seconds seconds are added after each of your own moves.';
  }

  @override
  String maexchenSummaryLives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lives',
      one: '1 life',
    );
    return '$_temp0';
  }

  @override
  String maexchenEndAsk(String player) {
    return '$player would like to end the game.';
  }

  @override
  String get maexchenEndContinue => 'Keep playing';

  @override
  String maexchenEndWaiting(String player) {
    return 'Asked – $player decides.';
  }

  @override
  String maexchenEndRefused(String player) {
    return '$player wants to keep playing.';
  }

  @override
  String get maexchenMoveEndRequest => 'asks to end the game';

  @override
  String roomRuleOff(String rule) {
    return 'without $rule';
  }
}

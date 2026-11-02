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
  String get roomViaRelay => 'Open the room through a relay';

  @override
  String get roomViaRelayHelper =>
      'With a room code, also for players in a browser. Needs a computer running “klunki relay”. When off, the room runs on this device and devices on the same Wi-Fi find it by themselves.';

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
      'In a browser over https, Klunki can only reach secure relays (wss://) – use the app or the local http version.';

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
    return 'Relay: $address';
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
  String get relayAddressLabel => 'Relay address';

  @override
  String get relayAddressHelper =>
      'Computer on the Wi-Fi running \"klunki relay\", e.g. 192.168.1.20:4749';

  @override
  String get relayAddressInvalid =>
      'Invalid relay address. Example: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'No room with the code $code. Is the code right, and is the room still open?';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'Room $code is already full: two are playing there.';
  }

  @override
  String get relayErrorRoomClosed =>
      'The room was closed: whoever started it has left. The game is over.';

  @override
  String get relayErrorExpired =>
      'The room expired (10 minutes without activity).';

  @override
  String relayErrorUnreachable(String address) {
    return 'No relay reachable at $address.';
  }

  @override
  String get relayErrorLost => 'The connection to the relay was lost.';

  @override
  String get relayStartHint =>
      'Rooms with a room code need a relay. Start it on a computer on the Wi-Fi and open Klunki from its address:';

  @override
  String relayRoomLost(String reason) {
    return '$reason Start a new room.';
  }

  @override
  String relayFromLink(String address) {
    return 'Relay from link: $address';
  }

  @override
  String get relayLinkSaveDefault => 'Save as default';

  @override
  String get relayLinkUseSaved => 'Use saved relay';

  @override
  String get relayLinkForeign =>
      'Caution: this link points to a different relay, not to this page\'s server. Only join if you trust the sender: a foreign relay sees every move.';

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
  String get relayNotSet => 'No relay set up – enter an address';

  @override
  String relayUseDefault(String address) {
    return 'Default: $address';
  }

  @override
  String get relaySave => 'Apply';

  @override
  String get relayClubCodeLabel => 'Club code (only if needed)';

  @override
  String get relayClubCodeHelper =>
      'Only for servers that ask for a club code. The club code never goes into room links or QR codes.';

  @override
  String get relayErrorClubMissing =>
      'This server needs a club code. Enter it under “Advanced” with “change”. Ask the person who runs the server.';

  @override
  String get relayErrorClubWrong =>
      'This server doesn\'t know the club code. Ask the person who runs the server.';

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
    return '$player: $score points';
  }

  @override
  String get wordtilesHintPlace =>
      'Drag tiles onto the board, or tap a tile and then a square.';

  @override
  String get wordtilesHintFirst =>
      'The first word must cross the star in the centre.';

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
    return '$words: $score points';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    return '$words: $score points (incl. $bonus bonus for all tiles)';
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
    return '$player played $words for $score points.';
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
    return '$words for $score points';
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
    return '$words for $score points (allowed: $allowed)';
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
  String get wordtilesHelp => 'How to play';

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
  String get wordtilesHelpEnd =>
      'The game ends when the bag is empty and someone has laid all tiles. The points of the tiles left are subtracted; whoever finished gets them added.';

  @override
  String wordtilesResultRack(String points) {
    return 'Tiles left: $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    return 'Best word: $word ($player, $score points)';
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
    return '$player would like to allow “$words” ($score points).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '$player declined “$words”.';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    return 'asks to allow $words ($score points)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    return 'agreed: $words counts ($score points)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'declined: $words';
  }
}

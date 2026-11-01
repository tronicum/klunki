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
  String get menuChooseGame => '选择游戏';

  @override
  String get menuPassDevice => '轮流传递设备';

  @override
  String get menuDebugConsole => '调试控制台';

  @override
  String get menuPlayOverWifi => '通过 Wi-Fi 对战';

  @override
  String get menuGameConnect4 => '四子棋';

  @override
  String get menuGameMuehle => '九子棋';

  @override
  String get menuGameQuartettTrumpf => '四张卡（比大小）';

  @override
  String get menuGameQuartettSets => '四张卡（集套）';

  @override
  String get menuGameSchiffe => '海战棋';

  @override
  String get menuDescConnect4 => '四子连成一线就能获胜。';

  @override
  String get menuDescMuehle => '连成三子一线，吃掉对方的棋子。';

  @override
  String get menuDescQuartettTrumpf => '选一项属性，胜者赢得两张牌。';

  @override
  String get menuDescQuartettSets => '向对方要牌，集齐四张同系列的牌。';

  @override
  String get menuDescSchiffe => '布置舰队，轮流开火。';

  @override
  String get menuSectionHotSeat => '两人用一台设备';

  @override
  String get menuSectionNetwork => '两台设备';

  @override
  String get menuNetworkSubtitle => '创建或加入游戏';

  @override
  String get menuHiddenInfo => '手牌或舰队不能给对方看——轮流传递设备';

  @override
  String shellToMove(String player) {
    return '轮到 $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player 获胜';
  }

  @override
  String shellYourTurn(String mark) {
    return '轮到你了（$mark）';
  }

  @override
  String shellWaitingFor(String player) {
    return '等待 $player…';
  }

  @override
  String get shellYouHaveWon => '你获胜了';

  @override
  String get shellDraw => '平局';

  @override
  String shellWins(String player) {
    return '$player 赢了！';
  }

  @override
  String get shellYouWin => '你赢了！';

  @override
  String get shellMenu => '菜单';

  @override
  String get shellPlayAgain => '再来一局';

  @override
  String get shellUndo => '悔棋';

  @override
  String get shellNewGame => '新游戏';

  @override
  String get shellNewGameTitle => '开始新游戏？';

  @override
  String get shellNewGameBody => '当前对局将被放弃。';

  @override
  String get shellCancel => '取消';

  @override
  String get shellRestart => '重新开始';

  @override
  String get shellMoves => '走法记录';

  @override
  String get shellNoMoves => '还没有走法。';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player：$move';
  }

  @override
  String shellHandoverPass(String player) {
    return '请把设备交给 $player';
  }

  @override
  String shellHandoverContinue(String player) {
    return '我是 $player – 继续';
  }

  @override
  String connect4Column(int column) {
    return '第 $column 列';
  }

  @override
  String get connect4HintTapColumn => '点击一列';

  @override
  String get muehlePhasePlacing => '布子';

  @override
  String get muehlePhaseMoving => '走子';

  @override
  String get muehlePhaseFlying => '飞子';

  @override
  String muehleMovePlace(int point) {
    return '落子于 $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return '吃掉 $point 的棋子';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return '走子 $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return '飞子 $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return '成三！吃掉 $player 的一枚棋子';
  }

  @override
  String get muehleHintPlace => '放一枚棋子';

  @override
  String get muehleHintTarget => '选择目标（或再次点击棋子取消选择）';

  @override
  String get muehleHintSelectFly => '选择要飞的棋子';

  @override
  String get muehleHintSelectMove => '选择要走的棋子';

  @override
  String muehlePointEmpty(int point) {
    return '点 $point，空';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return '点 $point，$player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return '手中：$hand · 盘上：$board';
  }

  @override
  String muehleCaptured(int count) {
    return '吃子：$count';
  }

  @override
  String get quartettNoGame => '不是四张卡游戏';

  @override
  String get quartettContinue => '继续';

  @override
  String get quartettHigherWins => '大者胜';

  @override
  String get quartettLowerWins => '小者胜';

  @override
  String get quartettCardBack => '四张卡';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张牌',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张牌',
    );
    return '$player：$_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return '选择 $stat';
  }

  @override
  String get quartettTrumpfHintPick => '选择你这张牌的一项属性';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张牌',
    );
    return '奖池：$_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return '$player 的牌堆';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return '你的牌（$player）';
  }

  @override
  String get quartettTrumpfTie => '平手 – 牌进入奖池';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player 赢得这一轮';
  }

  @override
  String get quartettTrumpfOutcomeWin => '胜';

  @override
  String get quartettTrumpfOutcomeLose => '负';

  @override
  String get quartettTrumpfOutcomeTie => '平';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player 选择 $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张牌',
    );
    return '奖池中：$_temp0 – $player 再选一次';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player 正在选择 …';
  }

  @override
  String get quartettTrumpfLastTrick => '上一墩';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return '$seconds 秒后继续';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player 已选择：$stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return '下一个由 $player 选择';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player 再选一次';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return '继续 – $player 选择';
  }

  @override
  String quartettTrumpfYouPickNext(String player) {
    return '下一个由你选择（$player）';
  }

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 轮',
    );
    return '$_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return '$player 赢得了这一轮';
  }

  @override
  String get quartettSetsHit => '有';

  @override
  String get quartettSetsMiss => '没有';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return '要 $card：$result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return '要 $card：$result – 集齐 $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return '点击“继续”，然后把设备交给 $player';
  }

  @override
  String get quartettSetsHintAsk => '点击缺少的牌来索要';

  @override
  String get quartettSetsNoQuartet => '还没有集齐一套';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张牌',
    );
    return '牌堆：$_temp0';
  }

  @override
  String quartettSetsScore(int a, int b) {
    return '套数 X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player 要 $card：$result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return '有！$player 给你 $card';
  }

  @override
  String get quartettSetsMissDraw => '没有 – 你摸一张牌';

  @override
  String get quartettSetsMissEmpty => '没有 – 牌堆已空';

  @override
  String get quartettSetsAskAgain => '你可以再要一次。';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return '$player 没有 $card。';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return '集齐一套！已放下 $set';
  }

  @override
  String get quartettSetsDrawn => '摸到：';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张牌',
    );
    return '你的牌（$player）：$_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – 缺：$missing';
  }

  @override
  String get quartettSetsAskSlot => '索要';

  @override
  String get quartettSetsMissingSlot => '缺少';

  @override
  String get schiffeHintSetup => '布阵：点击海面（或拖动后松开）放置舰船。舰船之间不能相邻。';

  @override
  String get schiffeHintAllSunk => '所有舰船已被击沉。';

  @override
  String schiffeHintWaiting(String player) {
    return '等待 $player…';
  }

  @override
  String get schiffeHintExtraShot => '命中！再来 – 点击对方海域的一格。';

  @override
  String get schiffeHintFire => '点击对方海域中未知的一格开火。';

  @override
  String get schiffeLookWater => '水';

  @override
  String get schiffeLookShip => '舰船';

  @override
  String get schiffeLookMiss => '未命中';

  @override
  String get schiffeLookShipHit => '舰船被击中';

  @override
  String get schiffeLookHit => '命中';

  @override
  String get schiffeLookSunk => '击沉';

  @override
  String get schiffeLookUnknown => '未知';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => '舰队已就位';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship（$length）';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship（$length）· 已放置';
  }

  @override
  String get schiffeHorizontal => '横向';

  @override
  String get schiffeVertical => '纵向';

  @override
  String get schiffeRandom => '随机';

  @override
  String get schiffeFleet => '舰队';

  @override
  String schiffeExtraShotSunk(String ship) {
    return '$ship被击沉 – 命中！再来';
  }

  @override
  String get schiffeExtraShot => '命中！再来';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return '你的舰队：$own · 对手（$player）：剩 $opponent 艘';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return '$player 上一炮打在 $cell：$result';
  }

  @override
  String get schiffeTargetSection => '对手';

  @override
  String get schiffeOwnSection => '你的海域';

  @override
  String get schiffeMovePlace => '放置了一艘船';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '随机放置了 $count 艘船',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return '炮击 $cell：$result';
  }

  @override
  String get schiffeRotate => '旋转';

  @override
  String schiffeRotateSemantics(String orientation) {
    return '旋转，当前$orientation';
  }

  @override
  String get schiffeRemove => '移除';

  @override
  String get schiffeRemoveTooltip => '放回港口';

  @override
  String get schiffeReset => '重置';

  @override
  String get schiffeDone => '完成';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return '已放置 $placed/$total 艘 · $player 布阵中';
  }

  @override
  String schiffeHintSelected(String ship) {
    return '已选中$ship：点击格子或拖动舰船来移动。再点一次或点“旋转”可转向。';
  }

  @override
  String get schiffeHintReady => '舰队已就位。点击舰船可修改，或点“完成”。';

  @override
  String schiffeHintEarly(String player) {
    return '你可以先布阵。$player 完成后即可点“完成”。';
  }

  @override
  String get schiffeInvalidPlace => '放不下：舰船必须完全在海面上，且不能相邻。';

  @override
  String get schiffeInvalidRotate => '这里无法旋转：空间不够。';

  @override
  String get schiffeSubmitFailed => '布阵未被接受。请再点一次“完成”。';

  @override
  String get schiffeSelected => '已选中';

  @override
  String get schiffeHarbour => '港口';

  @override
  String schiffeShipSunk(String ship) {
    return '$ship被击沉';
  }

  @override
  String get debugConsoleTitle => '调试控制台';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => '游戏 / 演示';

  @override
  String debugNewGame(String game) {
    return '新建：$game';
  }

  @override
  String get debugLegalMoves => '合法走法';

  @override
  String get debugAutoPlay => '随机下到结束';

  @override
  String get debugDemo => '演示：所有游戏';

  @override
  String get pairingTitle => '通过 Wi-Fi 对战';

  @override
  String get pairingDeviceNameHelper => '对方会看到这个名字';

  @override
  String get playerNameTitle => '你叫什么名字？';

  @override
  String get playerNameLabel => '你的名字';

  @override
  String playerLabel(String name, String mark) {
    return '$name（$mark）';
  }

  @override
  String get hotSeatNamesTitle => '玩家名字';

  @override
  String hotSeatNameLabel(String mark) {
    return '玩家 $mark';
  }

  @override
  String get hotSeatNamesHelper => '可选 – 留空则只显示 X 和 O。';

  @override
  String get pairingModeHost => '创建';

  @override
  String get pairingModeJoin => '加入';

  @override
  String get pairingChooseGame => '选择游戏';

  @override
  String get pairingHostGame => '创建对局';

  @override
  String pairingHostStartFailed(String error) {
    return '无法开始对局：$error';
  }

  @override
  String get pairingNotAdvertised => '无法被自动发现 – 请对方输入地址。';

  @override
  String get pairingNoDiscoveryHost => '此设备不支持自动搜索 – 请对方输入地址。';

  @override
  String pairingHosting(String name, String game) {
    return '$name 创建了 $game';
  }

  @override
  String pairingNoAddress(int port) {
    return '找不到 Wi-Fi 地址。设备是否已连接 Wi-Fi？端口：$port';
  }

  @override
  String get pairingAddresses => '地址（手动输入）：';

  @override
  String get pairingProbablyWifi => '可能是 Wi-Fi';

  @override
  String get pairingWaitingForGuest => '等待对方加入…';

  @override
  String get pairingCancel => '取消';

  @override
  String get pairingGamesOnNetwork => '网络中的对局';

  @override
  String get pairingNoDiscoveryJoin => '此设备不支持自动搜索。请在下方输入地址。';

  @override
  String get pairingBrowseFailed => '无法搜索网络。请在下方输入地址。';

  @override
  String get pairingSearching => '正在搜索对局…';

  @override
  String get pairingOtherVersion => 'Klunki 版本不同';

  @override
  String get pairingOrEnterAddress => '或输入地址';

  @override
  String get pairingManualLabel => 'IP、IP:端口或 klunki:// 链接';

  @override
  String get pairingInvalidAddress =>
      '地址无效。例如：192.168.1.20 或 192.168.1.20:4747';

  @override
  String get pairingConnect => '连接';

  @override
  String pairingConnecting(String host) {
    return '正在连接 $host…';
  }

  @override
  String get pairingTimeout => '连接超时';

  @override
  String pairingJoinFailed(String host, String error) {
    return '连接 $host 失败（$error）。';
  }

  @override
  String get pairingJoinHints =>
      '提示：两台设备是否在同一 Wi-Fi 下？访客网络常会阻止设备之间的连接。iOS：是否已允许 Klunki 使用“本地网络”（设置 › 隐私）？';

  @override
  String pairingStatus(String name, String mark, String peer, String peerMark) {
    return '你（$name，$mark）· 对手：$peer（$peerMark）';
  }

  @override
  String netBarYou(String name) {
    return '你（$name）';
  }

  @override
  String netBarOpponent(String peer) {
    return '对手：$peer';
  }

  @override
  String get pairingOpponent => '对手';

  @override
  String pairingPeerLeft(String peer) {
    return '$peer 已离开对局';
  }

  @override
  String pairingPeerLost(String peer) {
    return '与 $peer 的连接已中断';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason。等待对方重新加入…';
  }

  @override
  String get pairingReconnecting => '正在重新连接…';

  @override
  String get pairingReconnect => '重新连接';

  @override
  String get networkVerificationFailed => '无法确认对局记录';

  @override
  String get pairingReconnectFailed => '重新连接失败。主机还在对局中吗？';

  @override
  String get pairingBrowserJoin => '在浏览器中加入（输入地址或粘贴链接）：';

  @override
  String get pairingCopyLink => '复制链接';

  @override
  String get pairingLinkCopied => '链接已复制';

  @override
  String get webJoinIntro =>
      '在浏览器中加入由 iPhone、iPad、Android 设备或终端（klunki host）主持的游戏。主机会在“在浏览器中加入”下显示地址和链接。';

  @override
  String get webJoinHttpsWarning =>
      '此页面是通过 https 打开的。浏览器会阻止从这里到本地网络的 ws:// 连接。请通过 http:// 打开 Klunki。';

  @override
  String get webJoinAddressLabel => 'IP、IP:端口、ws:// 或 klunki:// 链接';

  @override
  String webJoinAddressHelper(int port) {
    return '端口是主机的浏览器端口（WebSocket）；未填写时为 $port。';
  }

  @override
  String get webJoinInvalidAddress =>
      '地址无效。例如：192.168.1.20、192.168.1.20:4748 或 klunki://join?h=…';

  @override
  String get webJoinHints =>
      '提示：此设备与主机是否在同一 Wi-Fi 下？访客网络常会阻止设备之间的连接。页面必须通过 http:// 打开，而不是 https://。主机必须运行支持浏览器的 Klunki 版本（会显示“在浏览器中加入”）。';

  @override
  String get engineReasonConnect4FourInARow => '四子连线';

  @override
  String get engineReasonConnect4BoardFull => '棋盘已满';

  @override
  String get engineReasonMuehleFewerThanThree => '对手棋子少于 3 枚';

  @override
  String get engineReasonMuehleBlocked => '对手无路可走';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves 步内无吃子';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => '双方牌堆都已空';

  @override
  String get engineReasonQuartettAllCards => '对手没有牌了';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return '达到轮数上限，牌数相同（$a:$b）';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return '达到轮数上限，牌数更多（$a:$b）';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return '所有套牌已放下，$a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return '套数更多（$a:$b）';
  }

  @override
  String get engineReasonSchiffeAllSunk => '所有舰船已被击沉';

  @override
  String get engineReasonGostrategyFlagCaptured => '军旗被夺';

  @override
  String get engineReasonGostrategyNoMoves => '对手已无棋可走';

  @override
  String get engineReasonGostrategyBothBlocked => '双方都无法移动';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves 步内无交战';
  }

  @override
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy => '暗藏的军队——找到并夺取对方的军旗。';

  @override
  String get goPieceMarshal => '元帅';

  @override
  String get goPieceGeneral => '将军';

  @override
  String get goPieceColonel => '上校';

  @override
  String get goPieceMajor => '少校';

  @override
  String get goPieceCaptain => '上尉';

  @override
  String get goPieceLieutenant => '中尉';

  @override
  String get goPieceSergeant => '中士';

  @override
  String get goPieceMiner => '工兵';

  @override
  String get goPieceScout => '侦察兵';

  @override
  String get goPieceSpy => '间谍';

  @override
  String get goPieceBomb => '炸弹';

  @override
  String get goPieceFlag => '军旗';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece（$rank）';
  }

  @override
  String goSetupTitle(String player) {
    return '布阵（$player）';
  }

  @override
  String get goSetupHint => '点两个棋子，或把一个棋子拖到你四行中的另一格，即可交换，然后点“完成”。';

  @override
  String goSetupSelected(String piece) {
    return '已选$piece——再点你四行中的另一格来交换。';
  }

  @override
  String get goSetupShuffle => '随机重排';

  @override
  String get goSetupDone => '完成';

  @override
  String goSetupFirst(String player) {
    return '$player先布阵——你可以先做准备。';
  }

  @override
  String goWaitingSetup(String player) {
    return '等待$player布阵……';
  }

  @override
  String get goLegendTitle => '棋子';

  @override
  String get goLegendRules =>
      '军衔高者胜，军衔相同则同归于尽。间谍主动进攻时可击败元帅。只有工兵能排除炸弹。侦察兵可沿直线移动任意格。炸弹和军旗不能移动。';

  @override
  String get goHintSelect => '点你的一个棋子，再点一个标记的格子。';

  @override
  String goHintSelected(String piece) {
    return '$piece：点一个标记的格子。';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece现在不能移动。';
  }

  @override
  String goHintWaiting(String player) {
    return '等待$player……';
  }

  @override
  String goMoveLimit(String moves) {
    return '再走$moves步无交战即为平局。';
  }

  @override
  String goArmyOwn(String mark) {
    return '你的军队（$mark）';
  }

  @override
  String goArmyEnemy(String player) {
    return '对手：$player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return '剩余 $left/$total';
  }

  @override
  String goFightBy(String player) {
    return '$player发起进攻';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner击败$loser';
  }

  @override
  String get goFightBoth => '同归于尽';

  @override
  String goFightDefused(String piece) {
    return '$piece排除了炸弹';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece踩中了炸弹';
  }

  @override
  String get goFightFlag => '夺得军旗！';

  @override
  String get goMoveSetup => '布阵';

  @override
  String goMoveStep(String from, String to) {
    return '从$from走到$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return '进攻（$from–$to）：$result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell：$content';
  }

  @override
  String get goCellFree => '空';

  @override
  String get goCellLake => '湖';

  @override
  String goCellHidden(String player) {
    return '$player的暗子';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$player的$piece';
  }

  @override
  String goCellMoved(String content) {
    return '$content，已移动';
  }

  @override
  String gameNotInApp(String game) {
    return '应用中暂未提供$game。';
  }

  @override
  String get engineSetA => '超级跑车';

  @override
  String get engineSetB => '极限超跑';

  @override
  String get engineSetC => '经典车';

  @override
  String get engineSetD => '肌肉车';

  @override
  String get engineSetE => '拉力传奇';

  @override
  String get engineSetF => '豪华 GT';

  @override
  String get engineSetG => '电动车';

  @override
  String get engineSetH => '小钢炮';

  @override
  String get engineStatPs => '功率';

  @override
  String get engineStatKmh => '最高时速';

  @override
  String get engineStatCcm => '排量';

  @override
  String get engineStatKg => '重量';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => '马力';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cm³';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => '战列舰';

  @override
  String get engineShip4 => '巡洋舰';

  @override
  String get engineShip3 => '驱逐舰';

  @override
  String get engineShip2 => '潜艇';

  @override
  String get engineShipOther => '舰船';

  @override
  String get relayHostIntro => '同一 Wi-Fi 下的另一个浏览器用房间码加入。';

  @override
  String get relayRoomCode => '房间码';

  @override
  String get relayWaitingHint => '在第二台设备上打开链接或扫描二维码。也可以在那里打开 Klunki 并输入房间码。';

  @override
  String relayInfo(String address) {
    return '中继：$address';
  }

  @override
  String get relayJoinTitle => '用房间码加入';

  @override
  String get relayCodeHelper => '5 个字符。创建游戏的浏览器会显示该码。';

  @override
  String get relayCodeInvalid => '房间码无效：5 个字母或数字（不含 0、O、1、I、L）。';

  @override
  String get relayJoin => '加入房间';

  @override
  String relayJoining(String code) {
    return '正在加入房间 $code…';
  }

  @override
  String get relayAddressLabel => '中继地址';

  @override
  String get relayAddressHelper =>
      '同一 Wi-Fi 中运行 “klunki relay” 的电脑，例如 192.168.1.20:4749';

  @override
  String get relayAddressAdvanced => '高级：中继地址';

  @override
  String get relayAddressInvalid => '中继地址无效。示例：192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return '没有房间码为 $code 的房间。请确认房间码正确，且主机仍在等待。';
  }

  @override
  String relayErrorRoomFull(String code) {
    return '房间 $code 已满：已有两人在玩。';
  }

  @override
  String get relayErrorHostLeft => '主机已离开房间，游戏结束。';

  @override
  String get relayErrorExpired => '房间已过期（10 分钟无活动）。';

  @override
  String relayErrorUnreachable(String address) {
    return '无法连接 $address 上的中继。';
  }

  @override
  String get relayErrorLost => '与中继的连接已断开。';

  @override
  String get relayStartHint =>
      '浏览器对战浏览器需要一个中继。请在同一 Wi-Fi 的电脑上启动它，并通过它的地址打开 Klunki：';

  @override
  String relayRoomLost(String reason) {
    return '$reason请开始新游戏。';
  }

  @override
  String relayFromLink(String address) {
    return '链接中的中继：$address';
  }

  @override
  String get relayLinkSaveDefault => '设为默认';

  @override
  String get relayLinkUseSaved => '使用已保存的中继';

  @override
  String get relayLinkForeign =>
      '注意：此链接指向另一个中继，而不是本页面的服务器。只有信任发送者时才加入：外部中继能看到每一步棋。';

  @override
  String get pairingSeatTaken => '位置已被占用：已有人在玩这局游戏。只有最先加入的玩家才能重新加入。';

  @override
  String get webJoinDirectTitle => '或连接到主机设备（应用或终端）';

  @override
  String get qrScanButton => '扫描二维码';

  @override
  String get qrScanHint => '将摄像头对准主机的二维码。';

  @override
  String get qrScanNotKlunki => '不是 Klunki 二维码。请扫描游戏创建时显示的二维码。';

  @override
  String get qrScanTorchOn => '打开手电筒';

  @override
  String get qrScanTorchOff => '关闭手电筒';

  @override
  String get qrScanPermissionDenied => 'Klunki 无权使用摄像头。';

  @override
  String get qrScanPermissionHint => '你可以在设备设置中允许 Klunki 使用摄像头。';

  @override
  String get qrScanUnavailable => '摄像头不可用。';

  @override
  String get qrScanTypeInstead => '输入代码';

  @override
  String get relayGroupTitle => '通过中继游戏（房间码）';

  @override
  String get relayChange => '更改';

  @override
  String get relayNotSet => '未设置中继，请输入地址';

  @override
  String relayUseDefault(String address) {
    return '默认：$address';
  }

  @override
  String get relaySave => '应用';

  @override
  String get relayJoinIntro => '房间码来自选择了“创建对局”的浏览器。';

  @override
  String get joinDirectTitle => '直接连接设备';

  @override
  String get joinDirectHelper => '适用于自己主持游戏的手机、平板或终端：输入设备地址（IP）。';

  @override
  String get shellResign => '认输';

  @override
  String get shellResignTitle => '确定要认输吗？';

  @override
  String shellResignBody(String player) {
    return '对局立即结束，$player 获胜。';
  }

  @override
  String get shellResignWho => '谁认输？对局立即结束，另一方获胜。';

  @override
  String shellResignPlayer(String player) {
    return '$player 认输';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return '$player 已认输';
  }

  @override
  String get engineReasonCommonYouResigned => '你已认输';

  @override
  String get quartettDeckCars => '汽车';

  @override
  String get quartettDeckTrains => '火车';

  @override
  String get quartettDeckRockets => '火箭';

  @override
  String get quartettDeckPlanes => '飞机';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => '新干线';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => '欧洲高速列车';

  @override
  String get quartettSetTrainsE => '亚洲与美洲';

  @override
  String get quartettSetTrainsF => '电力机车';

  @override
  String get quartettSetTrainsG => '蒸汽传奇';

  @override
  String get quartettSetTrainsH => '货运巨人';

  @override
  String get quartettSetRocketsA => '登月火箭';

  @override
  String get quartettSetRocketsB => '可重复使用';

  @override
  String get quartettSetRocketsC => '欧洲';

  @override
  String get quartettSetRocketsD => '美国经典';

  @override
  String get quartettSetRocketsE => '俄罗斯';

  @override
  String get quartettSetRocketsF => '中国';

  @override
  String get quartettSetRocketsG => '日本与印度';

  @override
  String get quartettSetRocketsH => '小型运载火箭';

  @override
  String get quartettSetPlanesA => '宽体客机';

  @override
  String get quartettSetPlanesB => '中程客机';

  @override
  String get quartettSetPlanesC => '超音速';

  @override
  String get quartettSetPlanesD => '螺旋桨经典';

  @override
  String get quartettSetPlanesE => '货运巨无霸';

  @override
  String get quartettSetPlanesF => '公务与运动';

  @override
  String get quartettSetPlanesG => '先驱';

  @override
  String get quartettSetPlanesH => '纪录奇机';

  @override
  String get quartettStatKw => '功率';

  @override
  String get quartettStatLengthM => '长度';

  @override
  String get quartettStatMassT => '重量';

  @override
  String get quartettStatTractiveKn => '起动牵引力';

  @override
  String get quartettStatHeightM => '高度';

  @override
  String get quartettStatThrustKn => '起飞推力';

  @override
  String get quartettStatLeoT => '近地轨道运载能力';

  @override
  String get quartettStatLaunchMassT => '起飞质量';

  @override
  String get quartettStatFlights => '发射次数';

  @override
  String get quartettStatRangeKm => '航程';

  @override
  String get quartettStatWingspanM => '翼展';

  @override
  String get quartettStatMtowT => '起飞重量';

  @override
  String get quartettDeckPickerTitle => '选择卡组';

  @override
  String get quartettDeckLabel => '卡组';

  @override
  String quartettDeckSets(int sets) {
    return '$sets 组，每组 4 张';
  }

  @override
  String get quartettDeckPlay => '开始游戏';

  @override
  String get quartettGalleryOpen => '浏览卡牌';

  @override
  String get quartettGalleryTitle => '卡牌图鉴';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return '第 $index 张，共 $total 张';
  }

  @override
  String get quartettGalleryPrevious => '上一张';

  @override
  String get quartettGalleryNext => '下一张';

  @override
  String get quartettGalleryTopMenu => '按数值前 5 名';

  @override
  String quartettGalleryTopTitle(String stat) {
    return '前 5 名：$stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return '卡牌 $id：$name，$set';
  }

  @override
  String get quartettStatBuilt => '建造数量';

  @override
  String get quartettStatSuccessPct => '成功率';

  @override
  String get quartettUnitBuilt => '台';

  @override
  String quartettPhotoCredit(String author, String license) {
    return '照片：$author，$license';
  }

  @override
  String get quartettPhotoCreditTitle => '图片来源';

  @override
  String get quartettPhotoCreditTooltip => '显示图片来源';

  @override
  String get quartettPhotoModified => '已为应用缩小。';

  @override
  String get quartettPhotoShareAlike => '缩小后的版本采用相同的许可证。';

  @override
  String get quartettPhotoLicense => '许可证';

  @override
  String get quartettPhotoSource => '来源';

  @override
  String get quartettPhotoClose => '关闭';

  @override
  String get quartettWikipediaRead => '在维基百科上阅读';

  @override
  String get quartettImageCreditsTitle => '图片来源列表';

  @override
  String get quartettImageCreditsIntro =>
      '照片来自维基共享资源，采用自由许可证。它们已包含在应用中；只有链接需要联网。';

  @override
  String get quartettLinkFailed => '无法打开链接。';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return '提示：其他设备无法访问“$host”。请通过这台电脑的 Wi-Fi 地址（例如 $example）或其 .local 名称（例如 $mdnsExample）打开页面，这样链接和二维码才能在其他设备上使用。';
  }

  @override
  String relayLoopbackShort(String host) {
    return '“$host”仅在本设备上可用——其他设备需要这台电脑的 Wi-Fi 地址或 .local 名称。';
  }

  @override
  String get loopbackHowTitle => '如何找到地址？';

  @override
  String get loopbackHowMacSettings => '系统设置 › Wi-Fi › 详细信息… › IP 地址。或在终端中运行：';

  @override
  String get loopbackHowMacMdns => '.local 名称见系统设置 › 通用 › 共享（“本地主机名”）。';

  @override
  String get loopbackHowWindowsSettings =>
      '设置 › 网络和 Internet › WLAN › 属性（IPv4 地址）。或在命令提示符（cmd）中查看 WLAN 适配器的“IPv4 地址”：';

  @override
  String get loopbackHowWindowsMdns =>
      '在 Windows 10/11 上，.local 名称为 <计算机名>.local。';

  @override
  String get loopbackHowLinuxTerminal => '在终端中：';

  @override
  String get loopbackHowLinuxSettings =>
      '或 设置 › 网络 › Wi-Fi › 详细信息。如果 Avahi 正在运行，.local 名称为 <主机名>.local。';

  @override
  String loopbackHowRelay(String command) {
    return '提示：“$command”控制台启动时会显示这些地址。';
  }

  @override
  String get loopbackHowCopy => '复制命令';

  @override
  String get loopbackHowCopied => '命令已复制';

  @override
  String get goSetupInvalid => '只有你下方的四行可以放棋子。';

  @override
  String get versionMismatchBoth => '游戏版本不匹配——请更新两台设备上的应用（浏览器：重新加载页面）。';

  @override
  String get versionMismatchUpdateOther =>
      '游戏版本不匹配：另一台设备的版本较旧。请在那台设备上更新应用（浏览器：重新加载页面）。';

  @override
  String get versionMismatchUpdateThis =>
      '游戏版本不匹配：本设备的版本较旧。请更新此应用（浏览器：重新加载页面）。';

  @override
  String versionMismatchGuestRefused(String reason) {
    return '有设备尝试加入，但被拒绝：$reason';
  }

  @override
  String menuVersion(String version) {
    return '版本 $version';
  }

  @override
  String get menuGameChess => '国际象棋';

  @override
  String get menuDescChess => '经典棋局：将死对方的王。';

  @override
  String get chessWhite => '白方';

  @override
  String get chessBlack => '黑方';

  @override
  String get chessCheck => '将军！';

  @override
  String get chessHintSelect => '点一个棋子来走棋。';

  @override
  String get chessHintTarget => '点一个标记的格子。';

  @override
  String get chessPromotionTitle => '兵升变为……';

  @override
  String get chessFlipBoard => '翻转棋盘';

  @override
  String get chessAutoFlip => '棋盘转向走棋一方';

  @override
  String chessSquareEmpty(String square) {
    return '$square：空';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square：$piece（$side）';
  }

  @override
  String get chessPieceKing => '王';

  @override
  String get chessPieceQueen => '后';

  @override
  String get chessPieceRook => '车';

  @override
  String get chessPieceBishop => '象';

  @override
  String get chessPieceKnight => '马';

  @override
  String get chessPiecePawn => '兵';

  @override
  String get engineReasonChessCheckmate => '将死';

  @override
  String get engineReasonChessStalemate => '逼和';

  @override
  String get engineReasonChessInsufficientMaterial => '子力不足，无法将死';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves回合没有吃子或走兵';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return '同一局面出现$times次';
  }
}

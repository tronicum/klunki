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
  String get menuDebugConsole => '调试控制台';

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
  String get menuSectionNetwork => '与其他设备一起玩';

  @override
  String get menuPlayOnOneDevice => '一台设备';

  @override
  String get menuPlayWithOthers => '和其他人一起';

  @override
  String get hotSeatPassDeviceHint => '轮流传递设备——隐藏的牌不能给对方看。';

  @override
  String get roomStartSubtitle => '其他人用房间码加入';

  @override
  String get roomJoinSubtitle => '扫码或输入房间码';

  @override
  String get roomAdvanced => '高级';

  @override
  String get roomDirectWaitingHint =>
      '其他人点“加入房间”并扫描这个二维码。同一 Wi-Fi 下的设备也能在“附近的房间”中找到它。';

  @override
  String get roomViaRelay => '通过中继创建房间';

  @override
  String get roomViaRelayHelper =>
      '使用房间码，浏览器里的玩家也能加入。需要一台运行“klunki relay”的电脑。关闭时，房间直接在本设备上运行，同一 Wi-Fi 下的设备会自动找到它。';

  @override
  String get roomTypeCode => '输入房间码';

  @override
  String shellToMove(String player) {
    return '轮到 $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player 获胜';
  }

  @override
  String get shellYourTurn => '轮到你了';

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
  String get quartettTrumpfTie => '平手 – 加赛！';

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
    return '牌进入奖池（现有 $count 张），$player 再选一次';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player 正在选择 …';
  }

  @override
  String get quartettTrumpfLastTrick => '上一轮';

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
  String get quartettTrumpfYouPickNext => '下一个由你选择';

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
  String quartettTrumpfChooseOwn(int count) {
    return '你只剩 $count 张牌了 – 选一张。';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return '$player 选了 $stat。选择你的牌。';
  }

  @override
  String get quartettTrumpfMoveChoose => '选择一张牌';

  @override
  String quartettTrumpfHintDefending(String player) {
    return '$player 正在选牌 …';
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
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return '套数 $nameA $a : $b $nameB';
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
  String get schiffeHintSetup => '点击海面放置舰船。';

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
    return '已选中$ship：拖动来移动，再点一次转向。';
  }

  @override
  String get schiffeHintReady => '舰队已就位。点击舰船可移动或转向，或点“完成”。';

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
  String get schiffeHintSetupMore => '点击海面放置下一艘。点击舰船可移动或转向。';

  @override
  String get schiffeCoachTap => '点它：移动或转向';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 艘',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return '$ship，$orientation。点击可转向。';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '这样的还剩 $count 艘',
    );
    return '$_temp0';
  }

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
  String get playerDefaultNameA => '小红';

  @override
  String get playerDefaultNameB => '小明';

  @override
  String get hotSeatStartTitle => '谁来玩？';

  @override
  String get hotSeatStartPlay => '开始';

  @override
  String get hotSeatNamesTitle => '玩家名字';

  @override
  String hotSeatNameLabel(int number) {
    return '玩家 $number';
  }

  @override
  String get hotSeatStartsHint => '先走';

  @override
  String get hotSeatNamesHelper => '留空则使用默认名字。';

  @override
  String get pairingChooseGame => '选择游戏';

  @override
  String get roomStart => '创建房间';

  @override
  String roomStartFailed(String error) {
    return '无法创建房间：$error';
  }

  @override
  String get pairingNotAdvertised => '无法被自动发现——其他人请扫描二维码。';

  @override
  String get pairingNoDiscoveryHost => '此设备不支持自动查找——其他人请扫描二维码。';

  @override
  String roomOfPlayer(String name, String game) {
    return '$name 的房间：$game';
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
  String get roomNearby => '附近的房间';

  @override
  String get pairingNoDiscoveryJoin => '此设备不支持自动查找。请扫描二维码，或在“高级”中输入地址。';

  @override
  String get pairingBrowseFailed => '无法在网络中查找。请扫描二维码，或在“高级”中输入地址。';

  @override
  String get pairingSearching => '正在查找房间…';

  @override
  String get pairingOtherVersion => 'Klunki 版本不同';

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
  String pairingStatus(String name, String peer) {
    return '你：$name · 对手：$peer';
  }

  @override
  String netBarYou(String name) {
    return '你：$name';
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
  String get pairingReconnectFailed => '重新连接失败。另一台设备还在游戏中吗？';

  @override
  String get pairingBrowserJoin => '在浏览器中加入（输入地址或粘贴链接）：';

  @override
  String get pairingCopyLink => '复制链接';

  @override
  String get pairingLinkCopied => '链接已复制';

  @override
  String get webJoinHttpsWarning =>
      '在浏览器中通过 https 打开时，Klunki 只能连接安全中继（wss://）——请使用应用或本地 http 版本。';

  @override
  String get webJoinAddressLabel => 'IP、IP:端口、ws:// 或 klunki:// 链接';

  @override
  String webJoinAddressHelper(int port) {
    return '端口是另一台设备的浏览器端口（WebSocket），不填则为 $port。';
  }

  @override
  String get webJoinInvalidAddress =>
      '地址无效。例如：192.168.1.20、192.168.1.20:4748 或 klunki://join?h=…';

  @override
  String get webJoinHints =>
      '提示：此设备与房间所在的设备是否在同一 Wi-Fi 下？访客网络常会阻止设备之间的连接。页面必须通过 http:// 打开，而不是 https://。另一台设备必须运行支持浏览器的 Klunki 版本（会显示“在浏览器中加入”）。';

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
  String get goArmyOwn => '你的军队';

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
  String get roomStartIntro => '其他人点“加入房间”并输入房间码。';

  @override
  String get relayRoomCode => '房间码';

  @override
  String get relayWaitingHint => '其他人点“加入房间”，扫描二维码或输入房间码。也可以打开链接。';

  @override
  String relayInfo(String address) {
    return '中继：$address';
  }

  @override
  String get roomCodeHelper => '5 个字符——另一台设备会在它的房间里显示房间码。';

  @override
  String get relayCodeInvalid => '房间码无效：5 个字母或数字（不含 0、O、1、I、L）。';

  @override
  String get roomJoin => '加入房间';

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
  String get relayAddressInvalid => '中继地址无效。示例：192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return '没有房间码为 $code 的房间。请确认房间码正确，且房间仍然开着。';
  }

  @override
  String relayErrorRoomFull(String code) {
    return '房间 $code 已满：已有两人在玩。';
  }

  @override
  String get relayErrorRoomClosed => '房间已关闭：创建房间的人已离开。游戏结束。';

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
      '带房间码的房间需要一个中继。请在同一 Wi-Fi 的电脑上启动它，并通过它的地址打开 Klunki：';

  @override
  String relayRoomLost(String reason) {
    return '$reason请创建新房间。';
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
  String get qrScanButton => '扫描二维码';

  @override
  String get qrScanHint => '将摄像头对准另一台设备上的二维码。';

  @override
  String get qrScanNotKlunki => '不是 Klunki 二维码。请扫描另一台设备在房间里显示的二维码。';

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
  String get joinDirectTitle => '直接连接设备';

  @override
  String get joinDirectHelper => '适用于房间直接运行在其上的设备（应用或终端）：输入它的地址（IP）。';

  @override
  String get shellResign => '认输';

  @override
  String get shellResignTitle => '确定要认输吗？';

  @override
  String shellResignBody(String player) {
    return '对局对双方都结束，$player 获胜。';
  }

  @override
  String get shellLeaveTitle => '离开对局？';

  @override
  String get shellLeaveBody => '连接将断开，对局对双方都结束。';

  @override
  String get shellLeave => '离开';

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
  String get aboutTitle => '关于 Klunki';

  @override
  String get aboutPrivacy => '隐私';

  @override
  String get aboutImpressum => '法定信息（Impressum）';

  @override
  String get aboutSupport => '支持';

  @override
  String get aboutLicense => 'Klunki 是自由开源的应用，许可证为 GNU AGPL 3.0。';

  @override
  String get aboutSourceCode => '源代码';

  @override
  String get aboutLicenses => '开源许可证';

  @override
  String get aboutOpenInBrowser => '在浏览器中打开';

  @override
  String get aboutPrivacyOffline => '此版本（English）保存在应用中，无需联网即可阅读。以网页为准：';

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

  @override
  String get menuGameWordTiles => '文字高手';

  @override
  String get menuDescWordTiles => '用字母牌在棋盘上组字得分';

  @override
  String menuPreviewGame(String game) {
    return '试玩：$game';
  }

  @override
  String get wordtilesPlay => '出牌';

  @override
  String get wordtilesRecall => '取回所有牌';

  @override
  String get wordtilesShuffle => '重排字母牌';

  @override
  String get wordtilesExchange => '换牌';

  @override
  String wordtilesExchangeConfirm(int count) {
    return '换 $count 张';
  }

  @override
  String get wordtilesPass => '过';

  @override
  String get wordtilesZoomIn => '放大';

  @override
  String get wordtilesZoomOut => '全盘';

  @override
  String wordtilesBag(int count) {
    return '牌堆：$count 张';
  }

  @override
  String wordtilesScore(String player, int score) {
    return '$player：$score 分';
  }

  @override
  String get wordtilesHintPlace => '把字母牌拖到棋盘上，或先点一张牌再点一个格。';

  @override
  String get wordtilesHintFirst => '第一组字必须经过中间格。';

  @override
  String get wordtilesHintSelected => '点一个空格。';

  @override
  String get wordtilesHintExchange => '选出要放回牌堆的牌。';

  @override
  String get wordtilesHintAnswer => '接受或否认这组字。';

  @override
  String wordtilesExchangeNotNow(int count) {
    return '牌堆不少于 $count 张牌时才能换牌。';
  }

  @override
  String wordtilesPreview(String words, int score) {
    return '$words：$score 分';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    return '$words：$score 分（含全部出牌奖 $bonus 分）';
  }

  @override
  String get wordtilesErrorLine => '牌必须在同一横行或同一纵列。';

  @override
  String get wordtilesErrorGap => '牌之间还有空格。';

  @override
  String get wordtilesErrorShort => '第一组字不能少于两个字母。';

  @override
  String get wordtilesErrorConnect => '牌必须与棋盘上的字相连。';

  @override
  String get wordtilesErrorUnknownWord => '有字不在字典里。';

  @override
  String get wordtilesErrorAnswerFirst => '请先接受或否认上一组字。';

  @override
  String get wordtilesErrorOther => '不能这样出牌。';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    return '$player 出了 $words，得 $score 分。';
  }

  @override
  String get wordtilesAccept => '接受';

  @override
  String get wordtilesChallenge => '否认';

  @override
  String get wordtilesChallengeTitle => '否认这组字？';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return '没有字典时以你为准：$player 取回这些牌，不得分。然后轮到你。';
  }

  @override
  String get wordtilesChallengeBodyDict => '以字典为准。字典里有这组字时，你本轮不能出牌。';

  @override
  String wordtilesEndPending(String player) {
    return '$player 已出完所有牌。如果你接受，本局结束。';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    return '$words，$score 分';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '换了 $count 张牌',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => '过了本轮';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return '否认：$words 已取回';
  }

  @override
  String get wordtilesMoveChallengeFailed => '否认，但这组字有效';

  @override
  String get wordtilesMoveAccept => '接受了';

  @override
  String get wordtilesBlankTitle => '空白牌是什么字母？';

  @override
  String get wordtilesPremiumDoubleLetter => '字×2';

  @override
  String get wordtilesPremiumTripleLetter => '字×3';

  @override
  String get wordtilesPremiumDoubleWord => '组×2';

  @override
  String get wordtilesPremiumTripleWord => '组×3';

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return '所有牌已出完，比分 $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '连续 $turns 轮没有得分，比分 $a : $b';
  }

  @override
  String get webBetaBadge => '试用版';

  @override
  String get aboutWebBeta => '网页试用版 – 多设备对战请使用应用。';

  @override
  String get networkUnavailableWeb => '浏览器中暂不可用 – 使用应用可在多台设备上玩。';

  @override
  String get appBetaTeaser => '应用试用版即将推出。';

  @override
  String get appBetaIos => '试用 iPhone 和 iPad 应用';

  @override
  String get appBetaAndroid => '下载 Android 应用';
}

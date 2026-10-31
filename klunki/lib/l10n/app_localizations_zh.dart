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
  String schiffeSetupProgress(int index, int total, String player) {
    return '第 $index/$total 艘 · $player 布阵中';
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
  String get webJoinDirectTitle => '或连接到主机设备（应用或终端）';
}

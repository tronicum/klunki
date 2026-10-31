// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get menuLanguage => 'زبان';

  @override
  String get languagePickerTitle => 'انتخاب زبان';

  @override
  String get languageSystem => 'زبان سیستم';

  @override
  String get menuChooseGame => 'یک بازی انتخاب کن';

  @override
  String get menuPassDevice => 'دستگاه را دست‌به‌دست کنید';

  @override
  String get menuDebugConsole => 'کنسول اشکال‌زدایی';

  @override
  String get menuPlayOverWifi => 'بازی از طریق Wi-Fi';

  @override
  String get menuGameConnect4 => 'چهار در یک ردیف';

  @override
  String get menuGameMuehle => 'دوز نُه‌مهره';

  @override
  String get menuGameQuartettTrumpf => 'کوارتت (مقایسه)';

  @override
  String get menuGameQuartettSets => 'کوارتت (دسته‌ها)';

  @override
  String get menuGameSchiffe => 'نبرد دریایی';

  @override
  String get menuDescConnect4 => 'چهار در یک ردیف – افقی، عمودی یا مورب.';

  @override
  String get menuDescMuehle => 'ردیف‌های سه‌تایی بساز و مهره‌های حریف را بگیر.';

  @override
  String get menuDescQuartettTrumpf =>
      'مقدارها را مقایسه کنید – مقدار بهتر هر دو کارت را می‌برد.';

  @override
  String get menuDescQuartettSets =>
      'کارت بخواه و دسته‌های کامل چهارتایی جمع کن.';

  @override
  String get menuDescSchiffe => 'ناوگان‌تان را پنهان کنید و به نوبت شلیک کنید.';

  @override
  String get menuSectionHotSeat => 'دو نفر، یک دستگاه';

  @override
  String get menuSectionNetwork => 'با دو دستگاه';

  @override
  String get menuNetworkSubtitle => 'میزبانی یا پیوستن به بازی';

  @override
  String get menuHiddenInfo =>
      'کارت‌ها یا ناوگان مخفی – دستگاه را دست‌به‌دست کنید';

  @override
  String shellToMove(String player) {
    return 'نوبت $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player برنده شد';
  }

  @override
  String shellYourTurn(String mark) {
    return 'نوبت توست ($mark)';
  }

  @override
  String shellWaitingFor(String player) {
    return 'در انتظار $player…';
  }

  @override
  String get shellYouHaveWon => 'تو برنده شدی';

  @override
  String get shellDraw => 'مساوی';

  @override
  String shellWins(String player) {
    return '$player می‌برد!';
  }

  @override
  String get shellYouWin => 'تو می‌بری!';

  @override
  String get shellMenu => 'منو';

  @override
  String get shellPlayAgain => 'دوباره';

  @override
  String get shellUndo => 'برگرداندن حرکت';

  @override
  String get shellNewGame => 'بازی جدید';

  @override
  String get shellNewGameTitle => 'بازی جدید؟';

  @override
  String get shellNewGameBody => 'بازی فعلی رها می‌شود.';

  @override
  String get shellCancel => 'لغو';

  @override
  String get shellRestart => 'شروع دوباره';

  @override
  String get shellMoves => 'حرکت‌ها';

  @override
  String get shellNoMoves => 'هنوز حرکتی نیست.';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player: $move';
  }

  @override
  String shellHandoverPass(String player) {
    return 'دستگاه را به $player بده';
  }

  @override
  String shellHandoverContinue(String player) {
    return 'من $player هستم – ادامه';
  }

  @override
  String connect4Column(int column) {
    return 'ستون $column';
  }

  @override
  String get connect4HintTapColumn => 'روی یک ستون بزن';

  @override
  String get muehlePhasePlacing => 'چیدن';

  @override
  String get muehlePhaseMoving => 'حرکت';

  @override
  String get muehlePhaseFlying => 'پرش';

  @override
  String muehleMovePlace(int point) {
    return 'می‌گذارد روی $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return 'مهرهٔ $point را برمی‌دارد';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return 'حرکت $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return 'پرش $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return 'دوز! یک مهره از $player بردار';
  }

  @override
  String get muehleHintPlace => 'یک مهره بگذار';

  @override
  String get muehleHintTarget =>
      'مقصد را انتخاب کن (یا برای لغو دوباره روی مهره بزن)';

  @override
  String get muehleHintSelectFly => 'مهره‌ای برای پرش انتخاب کن';

  @override
  String get muehleHintSelectMove => 'مهره‌ای برای حرکت انتخاب کن';

  @override
  String muehlePointEmpty(int point) {
    return 'خانهٔ $point، خالی';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return 'خانهٔ $point، $player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return 'در دست: $hand · روی صفحه: $board';
  }

  @override
  String muehleCaptured(int count) {
    return 'گرفته‌شده: $count';
  }

  @override
  String get quartettNoGame => 'بازی کوارتت نیست';

  @override
  String get quartettContinue => 'ادامه';

  @override
  String get quartettHigherWins => 'بیشتر می‌برد';

  @override
  String get quartettLowerWins => 'کمتر می‌برد';

  @override
  String get quartettCardBack => 'کوارتت';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return '$player: $_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return '$stat را انتخاب می‌کند';
  }

  @override
  String get quartettTrumpfHintPick => 'یکی از ویژگی‌های کارتت را انتخاب کن';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return 'پاتیل: $_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return 'دستهٔ $player';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'کارت تو ($player)';
  }

  @override
  String get quartettTrumpfTie => 'مساوی – کارت‌ها به پاتیل می‌روند';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player این دست را می‌برد';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'می‌برد';

  @override
  String get quartettTrumpfOutcomeLose => 'می‌بازد';

  @override
  String get quartettTrumpfOutcomeTie => 'مساوی';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player $stat را انتخاب می‌کند';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return 'در پاتیل: $_temp0 – $player دوباره انتخاب می‌کند';
  }

  @override
  String get quartettSetsHit => 'دارد';

  @override
  String get quartettSetsMiss => 'ندارد';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return '$card را می‌خواهد: $result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return '$card را می‌خواهد: $result – کوارتت $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return 'روی «ادامه» بزن و دستگاه را به $player بده';
  }

  @override
  String get quartettSetsHintAsk => 'روی کارت گم‌شده بزن تا آن را بخواهی';

  @override
  String get quartettSetsNoQuartet => 'هنوز کوارتتی نیست';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return 'دسته: $_temp0';
  }

  @override
  String quartettSetsScore(int a, int b) {
    return 'کوارتت‌ها X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player $card را می‌خواهد: $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return 'دارد! $player $card را به تو می‌دهد';
  }

  @override
  String get quartettSetsMissDraw => 'ندارد – یک کارت برمی‌داری';

  @override
  String get quartettSetsMissEmpty => 'ندارد – دسته خالی است';

  @override
  String get quartettSetsAskAgain => 'می‌توانی دوباره بخواهی.';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return '$player $card را ندارد.';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return 'کوارتت! $set زمین گذاشته شد';
  }

  @override
  String get quartettSetsDrawn => 'برداشته‌شده:';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return 'کارت‌های تو ($player): $_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – کم: $missing';
  }

  @override
  String get quartettSetsAskSlot => 'بخواه';

  @override
  String get quartettSetsMissingSlot => 'کم';

  @override
  String get schiffeHintSetup =>
      'چیدمان: روی دریا بزن (یا بکش و رها کن) تا کشتی را بگذاری. کشتی‌ها نباید به هم بچسبند.';

  @override
  String get schiffeHintAllSunk => 'همهٔ کشتی‌ها غرق شدند.';

  @override
  String schiffeHintWaiting(String player) {
    return 'منتظر $player…';
  }

  @override
  String get schiffeHintExtraShot =>
      'اصابت! دوباره – روی خانه‌ای در دریای حریف بزن.';

  @override
  String get schiffeHintFire =>
      'برای شلیک روی یک خانهٔ ناشناخته در دریای حریف بزن.';

  @override
  String get schiffeLookWater => 'آب';

  @override
  String get schiffeLookShip => 'کشتی';

  @override
  String get schiffeLookMiss => 'خطا';

  @override
  String get schiffeLookShipHit => 'کشتی آسیب‌دیده';

  @override
  String get schiffeLookHit => 'اصابت';

  @override
  String get schiffeLookSunk => 'غرق شد';

  @override
  String get schiffeLookUnknown => 'ناشناخته';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => 'ناوگان کامل است';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship ($length)';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship ($length) · چیده شد';
  }

  @override
  String schiffeSetupProgress(int index, int total, String player) {
    return 'کشتی $index از $total · $player می‌چیند';
  }

  @override
  String get schiffeHorizontal => 'افقی';

  @override
  String get schiffeVertical => 'عمودی';

  @override
  String get schiffeRandom => 'تصادفی';

  @override
  String get schiffeFleet => 'ناوگان';

  @override
  String schiffeExtraShotSunk(String ship) {
    return '$ship غرق شد – اصابت! دوباره';
  }

  @override
  String get schiffeExtraShot => 'اصابت! دوباره';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return 'ناوگان تو: $own · حریف ($player): $opponent کشتی مانده';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return 'آخرین شلیک $player به $cell: $result';
  }

  @override
  String get schiffeTargetSection => 'حریف';

  @override
  String get schiffeOwnSection => 'دریای تو';

  @override
  String get schiffeMovePlace => 'یک کشتی می‌گذارد';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کشتی را تصادفی می‌گذارد',
      one: 'یک کشتی را تصادفی می‌گذارد',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return 'شلیک به $cell: $result';
  }

  @override
  String schiffeShipSunk(String ship) {
    return '$ship غرق شد';
  }

  @override
  String get debugConsoleTitle => 'کنسول اشکال‌زدایی';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => 'بازی / نمایش';

  @override
  String debugNewGame(String game) {
    return 'جدید: $game';
  }

  @override
  String get debugLegalMoves => 'حرکت‌های مجاز';

  @override
  String get debugAutoPlay => 'بازی تا آخر (تصادفی)';

  @override
  String get debugDemo => 'نمایش: همهٔ بازی‌ها';

  @override
  String get pairingTitle => 'بازی از طریق Wi-Fi';

  @override
  String get pairingDeviceNameHelper => 'بازیکن دیگر تو را با این نام می‌بیند';

  @override
  String get playerNameTitle => 'اسمت چیست؟';

  @override
  String get playerNameLabel => 'نام تو';

  @override
  String playerLabel(String name, String mark) {
    return '$name ($mark)';
  }

  @override
  String get hotSeatNamesTitle => 'نام بازیکنان';

  @override
  String hotSeatNameLabel(String mark) {
    return 'بازیکن $mark';
  }

  @override
  String get hotSeatNamesHelper =>
      'اختیاری – خالی بگذار تا فقط X و O نمایش داده شود.';

  @override
  String get pairingModeHost => 'میزبانی';

  @override
  String get pairingModeJoin => 'پیوستن';

  @override
  String get pairingChooseGame => 'انتخاب بازی';

  @override
  String get pairingHostGame => 'میزبانی بازی';

  @override
  String pairingHostStartFailed(String error) {
    return 'شروع بازی ممکن نشد: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'خودکار دیده نمی‌شود – بازیکن دیگر نشانی را وارد می‌کند.';

  @override
  String get pairingNoDiscoveryHost =>
      'جست‌وجوی خودکار روی این دستگاه نیست – بازیکن دیگر نشانی را وارد می‌کند.';

  @override
  String pairingHosting(String name, String game) {
    return '$name میزبان $game است';
  }

  @override
  String pairingNoAddress(int port) {
    return 'نشانی Wi-Fi پیدا نشد. آیا دستگاه به Wi-Fi وصل است؟ پورت: $port';
  }

  @override
  String get pairingAddresses => 'نشانی‌ها (برای تایپ):';

  @override
  String get pairingProbablyWifi => 'احتمالاً Wi-Fi';

  @override
  String get pairingWaitingForGuest => 'منتظر بازیکن دیگر…';

  @override
  String get pairingCancel => 'لغو';

  @override
  String get pairingGamesOnNetwork => 'بازی‌ها در شبکه';

  @override
  String get pairingNoDiscoveryJoin =>
      'جست‌وجوی خودکار روی این دستگاه در دسترس نیست. نشانی را پایین وارد کن.';

  @override
  String get pairingBrowseFailed =>
      'جست‌وجو در شبکه ممکن نیست. نشانی را پایین وارد کن.';

  @override
  String get pairingSearching => 'در جست‌وجوی بازی…';

  @override
  String get pairingOtherVersion => 'نسخهٔ دیگری از Klunki';

  @override
  String get pairingOrEnterAddress => 'یا نشانی را وارد کن';

  @override
  String get pairingManualLabel => 'IP، IP:پورت یا پیوند klunki://';

  @override
  String get pairingInvalidAddress =>
      'نشانی نامعتبر. نمونه: 192.168.1.20 یا 192.168.1.20:4747';

  @override
  String get pairingConnect => 'اتصال';

  @override
  String pairingConnecting(String host) {
    return 'در حال اتصال به $host…';
  }

  @override
  String get pairingTimeout => 'مهلت تمام شد';

  @override
  String pairingJoinFailed(String host, String error) {
    return 'اتصال به $host ناموفق بود ($error).';
  }

  @override
  String get pairingJoinHints =>
      'نکته‌ها: آیا هر دو دستگاه روی یک Wi-Fi هستند؟ شبکه‌های مهمان اغلب اتصال بین دستگاه‌ها را مسدود می‌کنند. iOS: آیا «شبکهٔ محلی» برای Klunki مجاز است (تنظیمات › حریم خصوصی)؟';

  @override
  String pairingStatus(String name, String mark, String peer, String peerMark) {
    return 'تو ($name، $mark) · حریف: $peer ($peerMark)';
  }

  @override
  String netBarYou(String name) {
    return 'تو ($name)';
  }

  @override
  String netBarOpponent(String peer) {
    return 'حریف: $peer';
  }

  @override
  String get pairingOpponent => 'حریف';

  @override
  String pairingPeerLeft(String peer) {
    return '$peer بازی را ترک کرد';
  }

  @override
  String pairingPeerLost(String peer) {
    return 'اتصال با $peer قطع شد';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. منتظر بازگشت او…';
  }

  @override
  String get pairingReconnecting => 'اتصال دوباره…';

  @override
  String get pairingReconnect => 'اتصال دوباره';

  @override
  String get networkVerificationFailed => 'تأیید روند بازی ممکن نشد';

  @override
  String get pairingReconnectFailed =>
      'اتصال دوباره ناموفق بود. آیا میزبان هنوز در بازی است؟';

  @override
  String get pairingBrowserJoin =>
      'پیوستن از مرورگر (نشانی را بنویس یا پیوند را جای‌گذاری کن):';

  @override
  String get pairingCopyLink => 'رونوشت پیوند';

  @override
  String get pairingLinkCopied => 'پیوند رونوشت شد';

  @override
  String get webJoinIntro =>
      'در مرورگر به بازی‌ای بپیوند که یک iPhone، iPad، دستگاه Android یا ترمینال (klunki host) میزبان آن است. میزبان نشانی و پیوند را زیر «پیوستن از مرورگر» نشان می‌دهد.';

  @override
  String get webJoinHttpsWarning =>
      'این صفحه با https باز شده است. از آنجا مرورگرها اتصال ws:// به شبکهٔ محلی را مسدود می‌کنند. Klunki را با http:// باز کن.';

  @override
  String get webJoinAddressLabel => 'IP، IP:پورت، پیوند ws:// یا klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'پورت، پورت مرورگر (WebSocket) میزبان است؛ بدون آن: $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'نشانی نامعتبر. نمونه: 192.168.1.20، 192.168.1.20:4748 یا klunki://join?h=…';

  @override
  String get webJoinHints =>
      'نکته‌ها: آیا این دستگاه با میزبان روی یک Wi-Fi است؟ شبکه‌های مهمان اغلب اتصال بین دستگاه‌ها را مسدود می‌کنند. صفحه باید با http:// باز شود، نه https://. روی میزبان باید نسخه‌ای از Klunki با پشتیبانی از مرورگر اجرا شود (که «پیوستن از مرورگر» را نشان می‌دهد).';

  @override
  String get engineReasonConnect4FourInARow => 'چهار در یک ردیف';

  @override
  String get engineReasonConnect4BoardFull => 'صفحه پر است';

  @override
  String get engineReasonMuehleFewerThanThree => 'حریف کمتر از 3 مهره دارد';

  @override
  String get engineReasonMuehleBlocked => 'حریف نمی‌تواند حرکت کند';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves حرکت بدون گرفتن مهره';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => 'هر دو دسته خالی است';

  @override
  String get engineReasonQuartettAllCards => 'حریف دیگر کارتی ندارد';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return 'سقف دست‌ها، کارت برابر ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'سقف دست‌ها، کارت بیشتر ($a:$b)';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return 'همهٔ کوارتت‌ها زمین گذاشته شد، $a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return 'کوارتت بیشتر ($a:$b)';
  }

  @override
  String get engineReasonSchiffeAllSunk => 'همهٔ کشتی‌ها غرق شدند';

  @override
  String get engineReasonGostrategyFlagCaptured => 'پرچم تصرف شد';

  @override
  String get engineReasonGostrategyNoMoves => 'حریف دیگر هیچ حرکتی ندارد';

  @override
  String get engineReasonGostrategyBothBlocked =>
      'هیچ‌یک از دو طرف نمی‌تواند حرکت کند';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves حرکت بدون نبرد';
  }

  @override
  String gameNotInApp(String game) {
    return '$game هنوز در برنامه در دسترس نیست.';
  }

  @override
  String get engineSetA => 'سوپراسپرت‌ها';

  @override
  String get engineSetB => 'هایپرکارها';

  @override
  String get engineSetC => 'کلاسیک‌ها';

  @override
  String get engineSetD => 'ماسل‌کارها';

  @override
  String get engineSetE => 'اسطوره‌های رالی';

  @override
  String get engineSetF => 'گرن‌توریسموها';

  @override
  String get engineSetG => 'برقی‌ها';

  @override
  String get engineSetH => 'کوچک‌های تندرو';

  @override
  String get engineStatPs => 'قدرت';

  @override
  String get engineStatKmh => 'حداکثر سرعت';

  @override
  String get engineStatCcm => 'حجم موتور';

  @override
  String get engineStatKg => 'وزن';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => 'اسب';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cm³';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => 'ناو جنگی';

  @override
  String get engineShip4 => 'رزمناو';

  @override
  String get engineShip3 => 'ناوشکن';

  @override
  String get engineShip2 => 'زیردریایی';

  @override
  String get engineShipOther => 'کشتی';

  @override
  String get relayHostIntro =>
      'مرورگر دوم در همان شبکهٔ Wi-Fi با کد اتاق وارد می‌شود.';

  @override
  String get relayRoomCode => 'کد اتاق';

  @override
  String get relayWaitingHint =>
      'پیوند را در دستگاه دوم باز کن یا کد QR را اسکن کن. یا Klunki را آنجا باز کن و کد اتاق را وارد کن.';

  @override
  String relayInfo(String address) {
    return 'رله: $address';
  }

  @override
  String get relayJoinTitle => 'پیوستن با کد اتاق';

  @override
  String get relayCodeHelper =>
      '۵ نویسه. مرورگری که میزبان بازی است کد را نشان می‌دهد.';

  @override
  String get relayCodeInvalid =>
      'کد اتاق نامعتبر است: ۵ حرف یا رقم (بدون 0، O، 1، I، L).';

  @override
  String get relayJoin => 'ورود به اتاق';

  @override
  String relayJoining(String code) {
    return 'در حال ورود به اتاق $code…';
  }

  @override
  String get relayAddressLabel => 'نشانی رله';

  @override
  String get relayAddressHelper =>
      'رایانه‌ای در Wi-Fi که «klunki relay» را اجرا می‌کند، مثلاً 192.168.1.20:4749';

  @override
  String get relayAddressAdvanced => 'پیشرفته: نشانی رله';

  @override
  String get relayAddressInvalid =>
      'نشانی رله نامعتبر است. نمونه: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'اتاقی با کد $code وجود ندارد. آیا کد درست است و میزبان هنوز منتظر است؟';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'اتاق $code پر است: دو نفر در آن بازی می‌کنند.';
  }

  @override
  String get relayErrorHostLeft => 'میزبان اتاق را ترک کرد. بازی تمام شد.';

  @override
  String get relayErrorExpired => 'اتاق منقضی شد (۱۰ دقیقه بدون فعالیت).';

  @override
  String relayErrorUnreachable(String address) {
    return 'هیچ رله‌ای در $address در دسترس نیست.';
  }

  @override
  String get relayErrorLost => 'اتصال به رله قطع شد.';

  @override
  String get relayStartHint =>
      'بازی مرورگر با مرورگر به رله نیاز دارد. آن را روی رایانه‌ای در Wi-Fi اجرا کن و Klunki را از نشانی آن باز کن:';

  @override
  String relayRoomLost(String reason) {
    return '$reason یک بازی تازه شروع کن.';
  }

  @override
  String relayFromLink(String address) {
    return 'رله از پیوند: $address';
  }

  @override
  String get relayLinkSaveDefault => 'ذخیره به‌عنوان پیش‌فرض';

  @override
  String get relayLinkUseSaved => 'استفاده از رله ذخیره‌شده';

  @override
  String get relayLinkForeign =>
      'توجه: این پیوند به رله دیگری اشاره می‌کند، نه به سرور این صفحه. فقط اگر به فرستنده اعتماد داری بپیوند: رله بیگانه همه حرکت‌ها را می‌بیند.';

  @override
  String get pairingSeatTaken =>
      'جا پر است: کسی از قبل این بازی را بازی می‌کند. فقط کسی که اول پیوسته می‌تواند دوباره وارد شود.';

  @override
  String get webJoinDirectTitle =>
      'یا به دستگاه میزبان وصل شو (برنامه یا ترمینال)';

  @override
  String get qrScanButton => 'اسکن کد QR';

  @override
  String get qrScanHint => 'دوربین را به سمت کد QR میزبان بگیر.';

  @override
  String get qrScanNotKlunki =>
      'این کد Klunki نیست. کد QR را که بازی هنگام میزبانی نشان می‌دهد اسکن کن.';

  @override
  String get qrScanTorchOn => 'روشن کردن چراغ';

  @override
  String get qrScanTorchOff => 'خاموش کردن چراغ';

  @override
  String get qrScanPermissionDenied =>
      'Klunki اجازهٔ استفاده از دوربین را ندارد.';

  @override
  String get qrScanPermissionHint =>
      'می‌توانی دسترسی Klunki به دوربین را در تنظیمات دستگاه مجاز کنی.';

  @override
  String get qrScanUnavailable => 'دوربین در دسترس نیست.';

  @override
  String get qrScanTypeInstead => 'کد را وارد کن';

  @override
  String get relayGroupTitle => 'بازی از طریق رله (کد اتاق)';

  @override
  String get relayChange => 'تغییر';

  @override
  String get relayNotSet => 'هیچ رله‌ای تنظیم نشده – نشانی را وارد کن';

  @override
  String relayUseDefault(String address) {
    return 'پیش‌فرض: $address';
  }

  @override
  String get relaySave => 'اعمال';

  @override
  String get relayJoinIntro =>
      'کد اتاق از مرورگری می‌آید که «میزبانی بازی» را انتخاب کرده است.';

  @override
  String get joinDirectTitle => 'اتصال مستقیم به یک دستگاه';

  @override
  String get joinDirectHelper =>
      'برای گوشی، تبلت یا ترمینالی که خودش میزبان است: نشانی دستگاه (IP) را وارد کن.';

  @override
  String get shellResign => 'تسلیم';

  @override
  String get shellResignTitle => 'واقعاً تسلیم می‌شوی؟';

  @override
  String shellResignBody(String player) {
    return 'بازی همین حالا تمام می‌شود و $player برنده می‌شود.';
  }

  @override
  String get shellResignWho =>
      'چه کسی تسلیم می‌شود؟ بازی همین حالا تمام می‌شود و طرف مقابل برنده می‌شود.';

  @override
  String shellResignPlayer(String player) {
    return '$player تسلیم می‌شود';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return '$player تسلیم شد';
  }

  @override
  String get engineReasonCommonYouResigned => 'تو تسلیم شدی';
}

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
  String get menuDebugConsole => 'کنسول اشکال‌زدایی';

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
  String get menuSectionNetwork => 'بازی با دستگاه‌های دیگر';

  @override
  String get menuPlayOnOneDevice => 'روی یک دستگاه';

  @override
  String get menuPlayWithOthers => 'با دیگران';

  @override
  String get hotSeatPassDeviceHint =>
      'دستگاه را دست‌به‌دست می‌کنید – چیزهای پنهان مخفی می‌مانند.';

  @override
  String get roomStartSubtitle => 'بقیه با کد اتاق می‌آیند';

  @override
  String get roomJoinSubtitle => 'کد را اسکن یا تایپ کن';

  @override
  String get roomAdvanced => 'پیشرفته';

  @override
  String get roomDirectWaitingHint =>
      'بقیه «ورود به اتاق» را می‌زنند و این کد QR را اسکن می‌کنند. دستگاه‌های همان Wi-Fi اتاق را در «اتاق‌های نزدیک» هم پیدا می‌کنند.';

  @override
  String get roomViaRelay => 'باز کردن اتاق از راه سرور';

  @override
  String get roomViaRelayHelper =>
      'با کد اتاق، برای بازیکنان در مرورگر هم. به یک سرور نیاز دارد (مثلاً رایانه‌ای که «klunki relay» روی آن اجرا شود). وقتی خاموش است، اتاق روی همین دستگاه اجرا می‌شود و دستگاه‌های همان Wi-Fi خودشان آن را پیدا می‌کنند.';

  @override
  String get roomTypeCode => 'تایپ کد اتاق';

  @override
  String shellToMove(String player) {
    return 'نوبت $player';
  }

  @override
  String shellHasWon(String player) {
    return '$player برنده شد';
  }

  @override
  String get shellYourTurn => 'نوبت توست';

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
  String get shellTakeBack => 'برگشت';

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
  String get quartettTrumpfTie => 'مساوی – دور تعیین‌کننده!';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player این دور را می‌برد';
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
    return 'کارت‌ها به پاتیل می‌روند (اکنون $count)، $player دوباره انتخاب می‌کند';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player انتخاب می‌کند …';
  }

  @override
  String get quartettTrumpfLastTrick => 'دور قبلی';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'ادامه تا $seconds ثانیه';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player انتخاب کرد: $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return 'انتخاب بعدی با $player';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player دوباره انتخاب می‌کند';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'ادامه – $player انتخاب می‌کند';
  }

  @override
  String get quartettTrumpfYouPickNext => 'انتخاب بعدی با توست';

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دور دیگر',
      one: 'یک دور دیگر',
    );
    return '$_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return '$player این دور را برد';
  }

  @override
  String quartettTrumpfChooseOwn(int count) {
    return 'فقط $count کارت برایت مانده – یکی را انتخاب کن.';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return '$player $stat را بازی می‌کند. کارتت را انتخاب کن.';
  }

  @override
  String get quartettTrumpfMoveChoose => 'یک کارت انتخاب می‌کند';

  @override
  String quartettTrumpfHintDefending(String player) {
    return '$player یک کارت انتخاب می‌کند …';
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
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return 'کوارتت‌ها $nameA $a : $b $nameB';
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
  String get schiffeHintSetup => 'روی دریا بزن تا کشتی را بگذاری.';

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
  String get schiffeRotate => 'چرخاندن';

  @override
  String schiffeRotateSemantics(String orientation) {
    return 'چرخاندن، اکنون $orientation';
  }

  @override
  String get schiffeRemove => 'برداشتن';

  @override
  String get schiffeRemoveTooltip => 'بازگشت به بندر';

  @override
  String get schiffeReset => 'بازنشانی';

  @override
  String get schiffeDone => 'تمام';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return '$placed از $total کشتی گذاشته شد · $player می‌چیند';
  }

  @override
  String schiffeHintSelected(String ship) {
    return '$ship انتخاب شد: بکش برای جابه‌جایی، دوباره بزن برای چرخاندن.';
  }

  @override
  String get schiffeHintReady =>
      'ناوگان آماده است. روی کشتی بزن تا جابه‌جا یا چرخانده شود، یا «تمام».';

  @override
  String schiffeHintEarly(String player) {
    return 'می‌توانی از حالا بچینی. «تمام» وقتی کار می‌کند که $player تمام کرده باشد.';
  }

  @override
  String get schiffeInvalidPlace =>
      'آنجا جا نمی‌شود: کشتی‌ها باید کامل روی دریا باشند و به هم نچسبند.';

  @override
  String get schiffeInvalidRotate => 'اینجا نمی‌شود چرخاند؛ جا کافی نیست.';

  @override
  String get schiffeSubmitFailed => 'چیدمان پذیرفته نشد. دوباره «تمام» را بزن.';

  @override
  String get schiffeSelected => 'انتخاب‌شده';

  @override
  String get schiffeHarbour => 'بندر';

  @override
  String get schiffeHintSetupMore =>
      'برای کشتی بعدی روی دریا بزن. روی کشتی بزن تا جابه‌جا یا چرخانده شود.';

  @override
  String get schiffeCoachTap => 'رویش بزن: جابه‌جا یا چرخاندن';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کشتی مانده',
      one: 'یک کشتی مانده',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return 'پیش‌نمایش: $ship، $orientation. بزن تا بچرخد.';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تا از این نوع مانده',
      one: 'آخرین از این نوع',
    );
    return '$_temp0';
  }

  @override
  String get schiffeInvalidTouch =>
      'کشتی‌ها نباید به هم بچسبند، حتی از گوشه – یک خانهٔ خالی بینشان بگذار.';

  @override
  String get schiffeInvalidOffBoard => 'در صفحه جا نمی‌شود.';

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
  String get playerDefaultNameA => 'آرزو';

  @override
  String get playerDefaultNameB => 'بابک';

  @override
  String get hotSeatStartTitle => 'چه کسی بازی می‌کند؟';

  @override
  String get hotSeatStartPlay => 'شروع';

  @override
  String get hotSeatNamesTitle => 'نام بازیکنان';

  @override
  String hotSeatNameLabel(int number) {
    return 'بازیکن $number';
  }

  @override
  String get hotSeatStartsHint => 'شروع می‌کند';

  @override
  String get hotSeatNamesHelper => 'خالی بگذار تا نام پیش‌فرض استفاده شود.';

  @override
  String get pairingChooseGame => 'انتخاب بازی';

  @override
  String get roomStart => 'باز کردن اتاق';

  @override
  String roomStartFailed(String error) {
    return 'اتاق باز نشد: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'به‌طور خودکار دیده نمی‌شود – بقیه کد QR را اسکن می‌کنند.';

  @override
  String get pairingNoDiscoveryHost =>
      'جستجوی خودکار روی این دستگاه نیست – بقیه کد QR را اسکن می‌کنند.';

  @override
  String roomOfPlayer(String name, String game) {
    return 'اتاق $name: $game';
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
  String get roomNearby => 'اتاق‌های نزدیک';

  @override
  String get pairingNoDiscoveryJoin =>
      'جستجوی خودکار روی این دستگاه در دسترس نیست. کد QR را اسکن کن یا نشانی را در «پیشرفته» وارد کن.';

  @override
  String get pairingBrowseFailed =>
      'جستجو در شبکه ممکن نیست. کد QR را اسکن کن یا نشانی را در «پیشرفته» وارد کن.';

  @override
  String get pairingSearching => 'در حال جستجوی اتاق‌ها…';

  @override
  String get pairingOtherVersion => 'نسخهٔ دیگری از Klunki';

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
  String pairingStatus(String name, String peer) {
    return 'تو: $name · حریف: $peer';
  }

  @override
  String netBarYou(String name) {
    return 'تو: $name';
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
      'اتصال دوباره ناموفق بود. آیا دستگاه دیگر هنوز در بازی است؟';

  @override
  String get pairingBrowserJoin =>
      'پیوستن از مرورگر (نشانی را بنویس یا پیوند را جای‌گذاری کن):';

  @override
  String get pairingCopyLink => 'رونوشت پیوند';

  @override
  String get pairingLinkCopied => 'پیوند رونوشت شد';

  @override
  String get webJoinHttpsWarning =>
      'در مرورگر با https، Klunki فقط به سرورهای امن (wss://) دسترسی دارد – از اپ یا نسخهٔ http محلی استفاده کن.';

  @override
  String get webJoinAddressLabel => 'IP، IP:پورت، پیوند ws:// یا klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'درگاه، درگاه مرورگر (WebSocket) دستگاه دیگر است؛ اگر ننویسی $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'نشانی نامعتبر. نمونه: 192.168.1.20، 192.168.1.20:4748 یا klunki://join?h=…';

  @override
  String get webJoinHints =>
      'نکته‌ها: آیا این دستگاه با دستگاهِ اتاق روی یک Wi-Fi است؟ شبکه‌های مهمان اغلب اتصال بین دستگاه‌ها را مسدود می‌کنند. صفحه باید با http:// باز شود، نه https://. روی دستگاه دیگر باید نسخه‌ای از Klunki با پشتیبانی از مرورگر اجرا شود (که «پیوستن از مرورگر» را نشان می‌دهد).';

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
    return 'سقف دورها، کارت برابر ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'سقف دورها، کارت بیشتر ($a:$b)';
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
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy =>
      'ارتش‌های پنهان – پرچم حریف را پیدا کن و تصرف کن.';

  @override
  String get goPieceMarshal => 'مارشال';

  @override
  String get goPieceGeneral => 'ژنرال';

  @override
  String get goPieceColonel => 'سرهنگ';

  @override
  String get goPieceMajor => 'سرگرد';

  @override
  String get goPieceCaptain => 'سروان';

  @override
  String get goPieceLieutenant => 'ستوان';

  @override
  String get goPieceSergeant => 'گروهبان';

  @override
  String get goPieceMiner => 'مین‌یاب';

  @override
  String get goPieceScout => 'دیده‌بان';

  @override
  String get goPieceSpy => 'جاسوس';

  @override
  String get goPieceBomb => 'بمب';

  @override
  String get goPieceFlag => 'پرچم';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece ($rank)';
  }

  @override
  String goSetupTitle(String player) {
    return 'ارتشت را بچین ($player)';
  }

  @override
  String get goSetupHint =>
      'دو مهره را لمس کن یا یکی را روی خانهٔ دیگری از چهار ردیف خودت بکش تا جابه‌جا شوند، سپس «تمام».';

  @override
  String goSetupSelected(String piece) {
    return '$piece انتخاب شد – خانهٔ دیگری از چهار ردیف خودت را برای جابه‌جایی لمس کن.';
  }

  @override
  String get goSetupShuffle => 'چیدمان تصادفی';

  @override
  String get goSetupDone => 'تمام';

  @override
  String goSetupFirst(String player) {
    return '$player اول می‌چیند – تو هم می‌توانی آماده شوی.';
  }

  @override
  String goWaitingSetup(String player) {
    return 'در انتظار چیدمان $player …';
  }

  @override
  String get goLegendTitle => 'مهره‌ها';

  @override
  String get goLegendRules =>
      'درجهٔ بالاتر می‌برد و با درجهٔ برابر هر دو می‌افتند. جاسوس اگر حمله کند مارشال را می‌زند. فقط مین‌یاب‌ها بمب را خنثی می‌کنند. دیده‌بان‌ها هر قدر بخواهند در خط مستقیم می‌روند. بمب‌ها و پرچم حرکت نمی‌کنند.';

  @override
  String get goHintSelect =>
      'یکی از مهره‌هایت را لمس کن، بعد یک خانهٔ علامت‌دار را.';

  @override
  String goHintSelected(String piece) {
    return '$piece: یک خانهٔ علامت‌دار را لمس کن.';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece الان نمی‌تواند حرکت کند.';
  }

  @override
  String goHintWaiting(String player) {
    return 'در انتظار $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return '$moves حرکت دیگر بدون نبرد، بازی مساوی می‌شود.';
  }

  @override
  String get goArmyOwn => 'ارتش تو';

  @override
  String goArmyEnemy(String player) {
    return 'حریف: $player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return '$left از $total مانده';
  }

  @override
  String goFightBy(String player) {
    return 'حمله از طرف $player';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner $loser را می‌زند';
  }

  @override
  String get goFightBoth => 'هر دو می‌افتند';

  @override
  String goFightDefused(String piece) {
    return '$piece بمب را خنثی می‌کند';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece روی بمب می‌رود';
  }

  @override
  String get goFightFlag => 'پرچم تصرف شد!';

  @override
  String get goMoveSetup => 'ارتش را می‌چیند';

  @override
  String goMoveStep(String from, String to) {
    return 'حرکت $from–$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return 'حمله ($from–$to): $result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell: $content';
  }

  @override
  String get goCellFree => 'خالی';

  @override
  String get goCellLake => 'دریاچه';

  @override
  String goCellHidden(String player) {
    return 'مهرهٔ پنهان $player';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece از $player';
  }

  @override
  String goCellMoved(String content) {
    return '$content، حرکت‌کرده';
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
  String get roomStartIntro =>
      'بقیه «ورود به اتاق» را می‌زنند و کد اتاق را وارد می‌کنند.';

  @override
  String get relayRoomCode => 'کد اتاق';

  @override
  String get relayWaitingHint =>
      'بقیه «ورود به اتاق» را می‌زنند و کد QR را اسکن می‌کنند یا کد اتاق را وارد می‌کنند. یا پیوند را باز می‌کنند.';

  @override
  String relayInfo(String address) {
    return 'سرور: $address';
  }

  @override
  String get roomCodeHelper =>
      '۵ نویسه – دستگاه دیگر کد را کنار اتاقش نشان می‌دهد.';

  @override
  String get relayCodeInvalid =>
      'کد اتاق نامعتبر است: ۵ حرف یا رقم (بدون 0، O، 1، I، L).';

  @override
  String get roomJoin => 'ورود به اتاق';

  @override
  String relayJoining(String code) {
    return 'در حال ورود به اتاق $code…';
  }

  @override
  String get relayAddressLabel => 'سرور';

  @override
  String get relayAddressHelper =>
      'نشانی سرور، مثلاً 192.168.1.20:4749 (در Wi-Fi) یا wss://spiele.example (در اینترنت)';

  @override
  String get relayAddressInvalid =>
      'نشانی سرور نامعتبر است. نمونه: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'اتاقی با کد $code وجود ندارد. آیا کد درست است و اتاق هنوز باز است؟';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'اتاق $code پر است: دو نفر در آن بازی می‌کنند.';
  }

  @override
  String relayErrorHostAway(String code) {
    return 'دستگاهی که اتاق $code را باز کرده، الان در دسترس نیست. کمی بعد دوباره امتحان کن.';
  }

  @override
  String get relayErrorRoomClosed =>
      'اتاق بسته شد: کسی که آن را باز کرده بود رفت. بازی تمام شد.';

  @override
  String get relayErrorExpired => 'اتاق منقضی شد (۱۰ دقیقه بدون فعالیت).';

  @override
  String relayErrorUnreachable(String address) {
    return 'هیچ سروری در $address در دسترس نیست.';
  }

  @override
  String get relayErrorLost => 'اتصال به سرور قطع شد.';

  @override
  String get relayStartHint =>
      'اتاق‌های کددار به سرور نیاز دارند. آن را روی رایانه‌ای در Wi-Fi اجرا کن و Klunki را از نشانی آن باز کن:';

  @override
  String relayRoomLost(String reason) {
    return '$reason یک اتاق تازه باز کن.';
  }

  @override
  String relayFromLink(String address) {
    return 'سرور از پیوند: $address';
  }

  @override
  String get relayLinkSaveDefault => 'ذخیره به‌عنوان پیش‌فرض';

  @override
  String get relayLinkUseSaved => 'استفاده از سرور ذخیره‌شده';

  @override
  String get relayLinkForeign =>
      'توجه: این پیوند به سرور دیگری اشاره می‌کند، نه به سرور این صفحه. فقط اگر به فرستنده اعتماد داری بپیوند: سرور بیگانه همه حرکت‌ها را می‌بیند.';

  @override
  String get pairingSeatTaken =>
      'جا پر است: کسی از قبل این بازی را بازی می‌کند. فقط کسی که اول پیوسته می‌تواند دوباره وارد شود.';

  @override
  String get qrScanButton => 'اسکن کد QR';

  @override
  String get qrScanHint => 'دوربین را به سمت کد QR دستگاه دیگر بگیر.';

  @override
  String get qrScanNotKlunki =>
      'این کد Klunki نیست. کد QR را که دستگاه دیگر کنار اتاقش نشان می‌دهد اسکن کن.';

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
  String get relayChange => 'تغییر';

  @override
  String get relayNotSet => 'هیچ سروری تنظیم نشده – نشانی را وارد کن';

  @override
  String relayUseDefault(String address) {
    return 'پیش‌فرض: $address';
  }

  @override
  String get relaySave => 'اعمال';

  @override
  String get relayClubCodeLabel => 'کد باشگاه';

  @override
  String get relayClubCodeHelper =>
      'فقط برای همین سرور ذخیره می‌شود. کد باشگاه هرگز در پیوند یا کد QR اتاق نمی‌آید.';

  @override
  String get relayErrorClubMissing =>
      'این سرور کد باشگاه می‌خواهد. از کسی که سرور را اداره می‌کند بپرس.';

  @override
  String get relayErrorClubWrong =>
      'این سرور این کد باشگاه را نمی‌شناسد. از کسی که سرور را اداره می‌کند بپرس.';

  @override
  String get serverKindLan =>
      'سرور در Wi-Fi (رایانه‌ای که «klunki relay» روی آن اجرا می‌شود)';

  @override
  String get serverKindInternet => 'سرور در اینترنت';

  @override
  String get serverHelpLink => 'چطور کار می‌کند؟';

  @override
  String get serverClubCodeRemove => 'حذف کد باشگاه';

  @override
  String get serverClubCodeRetry => 'امتحان با کد باشگاه';

  @override
  String get helpTitle => 'چطور با هم بازی کنید';

  @override
  String get helpSectionRoomsTitle => 'بازی با دیگران';

  @override
  String get helpSectionRoomsBody =>
      'یک نفر «باز کردن اتاق» را می‌زند و یک بازی انتخاب می‌کند. Klunki سپس یک کد اتاق و یک کد QR نشان می‌دهد.\n\nنفر دیگر «ورود به اتاق» را می‌زند و کد QR را اسکن می‌کند یا کد اتاق را تایپ می‌کند. بازی شروع می‌شود.';

  @override
  String get helpSectionWifiTitle => 'در همان Wi-Fi';

  @override
  String get helpSectionWifiBody =>
      'یکی از شما اپ را دارد؟ پس در Wi-Fi به سرور نیازی ندارید: خود اپ سرور است، حتی برای بازیکنان در مرورگر (کد QR).\n\nدستگاه‌های همان Wi-Fi خودشان همدیگر را پیدا می‌کنند.';

  @override
  String get helpSectionServerTitle => 'کی به سرور نیاز دارید؟';

  @override
  String get helpSectionServerBody =>
      'فقط وقتی همه در مرورگر بازی می‌کنند یا در یک Wi-Fi نیستید. سرور حرکت‌ها را بین دستگاه‌های شما جابه‌جا می‌کند.\n\nKlunki از روی نشانی می‌فهمد چه سروری است: «سرور در Wi-Fi» یا «سرور در اینترنت».';

  @override
  String get helpSectionOwnServerTitle => 'سرور خودتان در Wi-Fi';

  @override
  String get helpSectionOwnServerBody =>
      'می‌توانید سرور خودتان را هم روی رایانه‌ای در Wi-Fi اجرا کنید. یک برنامهٔ آماده برای Mac، Windows و Linux در دست آماده‌سازی است. سپس نشانی آن را در Klunki در «پیشرفته» با «تغییر» وارد کنید.';

  @override
  String get helpSectionComingTitle => 'به‌زودی ساده‌تر (در دست آماده‌سازی)';

  @override
  String get helpSectionComingBody =>
      'این راه‌ها برای داشتن سرور در دست آماده‌سازی‌اند:\n• سرور در اینترنت برای گروه دوستان (با Cloudflare، رایگان)\n• برنامهٔ آماده برای دانلود برای Mac، Windows و Linux\n• Docker برای NAS یا Raspberry Pi\n\nسرورهای اینترنتی معمولاً با کد باشگاه محافظت می‌شوند.';

  @override
  String get helpSectionClubTitle => 'کد باشگاه چیست؟';

  @override
  String get helpSectionClubBody =>
      'کد باشگاه مثل کلید یک سرور است: فقط کسی که آن را می‌داند می‌تواند آنجا اتاق باز کند یا وارد اتاق شود. آن را از کسی می‌گیری که سرور را اداره می‌کند.\n\nKlunki فقط وقتی سروری به آن نیاز دارد آن را می‌پرسد و برای همان سرور به خاطر می‌سپارد.';

  @override
  String get helpSectionDataTitle => 'با داده‌های من چه می‌شود؟';

  @override
  String get helpSectionDataBody =>
      'سرور فقط حرکت‌ها را جابه‌جا می‌کند و چیزی از آن‌ها را برای همیشه نگه نمی‌دارد. اگر مستقیم در همان Wi-Fi بازی کنید، هیچ چیز از سرور غریبه نمی‌گذرد.\n\nکد باشگاه روی دستگاه تو می‌ماند و هرگز در پیوند یا کد QR اتاق نمی‌آید. با «تغییر» کنار سرور می‌توانی آن را ببینی، عوض کنی یا حذف کنی.';

  @override
  String get joinDirectTitle => 'اتصال مستقیم به یک دستگاه';

  @override
  String get joinDirectHelper =>
      'برای دستگاهی که اتاق مستقیم روی آن اجرا می‌شود (برنامه یا ترمینال): نشانی آن (IP) را وارد کن.';

  @override
  String get shellResign => 'تسلیم';

  @override
  String get shellResignTitle => 'واقعاً تسلیم می‌شوی؟';

  @override
  String shellResignBody(String player) {
    return 'بازی برای هر دو نفر تمام می‌شود و $player برنده می‌شود.';
  }

  @override
  String get shellLeaveTitle => 'از بازی خارج می‌شوید؟';

  @override
  String get shellLeaveBody =>
      'اتصال قطع می‌شود و بازی برای هر دو نفر تمام می‌شود.';

  @override
  String get shellLeave => 'خروج';

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

  @override
  String get quartettDeckCars => 'خودروها';

  @override
  String get quartettDeckTrains => 'قطارها';

  @override
  String get quartettDeckRockets => 'موشک‌ها';

  @override
  String get quartettDeckPlanes => 'هواپیماها';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => 'شینکانسن';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => 'سریع‌های اروپا';

  @override
  String get quartettSetTrainsE => 'آسیا و آمریکا';

  @override
  String get quartettSetTrainsF => 'لوکوموتیوهای برقی';

  @override
  String get quartettSetTrainsG => 'اسطوره‌های بخار';

  @override
  String get quartettSetTrainsH => 'غول‌های باری';

  @override
  String get quartettSetRocketsA => 'موشک‌های ماه';

  @override
  String get quartettSetRocketsB => 'قابل استفاده مجدد';

  @override
  String get quartettSetRocketsC => 'اروپا';

  @override
  String get quartettSetRocketsD => 'کلاسیک‌های آمریکا';

  @override
  String get quartettSetRocketsE => 'روسیه';

  @override
  String get quartettSetRocketsF => 'چین';

  @override
  String get quartettSetRocketsG => 'ژاپن و هند';

  @override
  String get quartettSetRocketsH => 'پرتابگرهای کوچک';

  @override
  String get quartettSetPlanesA => 'پهن‌پیکرها';

  @override
  String get quartettSetPlanesB => 'میان‌برد';

  @override
  String get quartettSetPlanesC => 'مافوق صوت';

  @override
  String get quartettSetPlanesD => 'کلاسیک‌های ملخی';

  @override
  String get quartettSetPlanesE => 'غول‌های باری هوایی';

  @override
  String get quartettSetPlanesF => 'تجاری و ورزشی';

  @override
  String get quartettSetPlanesG => 'پیشگامان';

  @override
  String get quartettSetPlanesH => 'عجایب رکورددار';

  @override
  String get quartettStatKw => 'توان';

  @override
  String get quartettStatLengthM => 'طول';

  @override
  String get quartettStatMassT => 'وزن';

  @override
  String get quartettStatTractiveKn => 'نیروی کشش';

  @override
  String get quartettStatHeightM => 'ارتفاع';

  @override
  String get quartettStatThrustKn => 'رانش برخاست';

  @override
  String get quartettStatLeoT => 'محموله (LEO)';

  @override
  String get quartettStatLaunchMassT => 'جرم پرتاب';

  @override
  String get quartettStatFlights => 'پرتاب‌ها';

  @override
  String get quartettStatRangeKm => 'برد';

  @override
  String get quartettStatWingspanM => 'طول بال';

  @override
  String get quartettStatMtowT => 'وزن برخاست';

  @override
  String get quartettDeckPickerTitle => 'دسته کارت را انتخاب کن';

  @override
  String get quartettDeckLabel => 'دسته کارت';

  @override
  String quartettDeckSets(int sets) {
    return '$sets سری 4 کارتی';
  }

  @override
  String get quartettDeckPlay => 'بازی کن';

  @override
  String get quartettGalleryOpen => 'دیدن کارت‌ها';

  @override
  String get quartettGalleryTitle => 'کارت‌های کوارتت';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return 'کارت $index از $total';
  }

  @override
  String get quartettGalleryPrevious => 'کارت قبلی';

  @override
  String get quartettGalleryNext => 'کارت بعدی';

  @override
  String get quartettGalleryTopMenu => '5 برتر بر اساس مقدار';

  @override
  String quartettGalleryTopTitle(String stat) {
    return '5 برتر: $stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return 'کارت $id: $name، سری $set';
  }

  @override
  String get quartettStatBuilt => 'تعداد ساخت';

  @override
  String get quartettStatSuccessPct => 'نرخ موفقیت';

  @override
  String get quartettUnitBuilt => 'عدد';

  @override
  String quartettPhotoCredit(String author, String license) {
    return 'عکس: $author، $license';
  }

  @override
  String get quartettPhotoCreditTitle => 'منبع تصویر';

  @override
  String get quartettPhotoCreditTooltip => 'نمایش منبع تصویر';

  @override
  String get quartettPhotoModified => 'برای برنامه کوچک شده است.';

  @override
  String get quartettPhotoShareAlike => 'نسخهٔ کوچک‌شده تحت همان مجوز است.';

  @override
  String get quartettPhotoLicense => 'مجوز';

  @override
  String get quartettPhotoSource => 'منبع';

  @override
  String get quartettPhotoClose => 'بستن';

  @override
  String get quartettWikipediaRead => 'خواندن در ویکی‌پدیا';

  @override
  String get quartettImageCreditsTitle => 'منابع تصاویر';

  @override
  String get quartettImageCreditsIntro =>
      'عکس‌ها از ویکی‌مدیا کامنز هستند و مجوز آزاد دارند. آن‌ها در برنامه گنجانده شده‌اند؛ فقط پیوندها به اینترنت نیاز دارند.';

  @override
  String get quartettLinkFailed => 'پیوند باز نشد.';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return 'توجه: دستگاه‌های دیگر نمی‌توانند به «$host» دسترسی داشته باشند. صفحه را از طریق نشانی وای‌فای این رایانه (مثلاً $example) یا نام .local آن (مثلاً $mdnsExample) باز کن تا پیوند و کد QR روی دستگاه‌های دیگر کار کند.';
  }

  @override
  String relayLoopbackShort(String host) {
    return '«$host» فقط روی همین دستگاه کار می‌کند – دستگاه‌های دیگر به نشانی وای‌فای یا نام .local این رایانه نیاز دارند.';
  }

  @override
  String get loopbackHowTitle => 'چطور نشانی را پیدا کنم؟';

  @override
  String get loopbackHowMacSettings =>
      'تنظیمات سیستم › Wi-Fi › جزئیات… › نشانی IP. یا در ترمینال:';

  @override
  String get loopbackHowMacMdns =>
      'نام .local در تنظیمات سیستم › عمومی › اشتراک‌گذاری («نام میزبان محلی») است.';

  @override
  String get loopbackHowWindowsSettings =>
      'تنظیمات › شبکه و اینترنت › Wi-Fi › ویژگی‌ها (نشانی IPv4). یا در خط فرمان (cmd)، «نشانی IPv4» آداپتور Wi-Fi:';

  @override
  String get loopbackHowWindowsMdns =>
      'در Windows 10/11 نام .local برابر <نام رایانه>.local است.';

  @override
  String get loopbackHowLinuxTerminal => 'در ترمینال:';

  @override
  String get loopbackHowLinuxSettings =>
      'یا تنظیمات › شبکه › Wi-Fi › جزئیات. اگر Avahi در حال اجرا باشد، نام .local برابر <نام میزبان>.local است.';

  @override
  String loopbackHowRelay(String command) {
    return 'نکته: کنسول «$command» این نشانی‌ها را هنگام شروع نشان می‌دهد.';
  }

  @override
  String get loopbackHowCopy => 'کپی فرمان';

  @override
  String get loopbackHowCopied => 'فرمان کپی شد';

  @override
  String get goSetupInvalid => 'فقط چهار ردیف پایینِ خودت مهره می‌پذیرند.';

  @override
  String get versionMismatchBoth =>
      'نسخه‌های بازی با هم سازگار نیستند – لطفاً هر دو برنامه را به‌روز کن (مرورگر: صفحه را دوباره بارگیری کن).';

  @override
  String get versionMismatchUpdateOther =>
      'نسخه‌های بازی با هم سازگار نیستند: دستگاه دیگر نسخهٔ قدیمی‌تری دارد. لطفاً برنامه را آنجا به‌روز کن (مرورگر: صفحه را دوباره بارگیری کن).';

  @override
  String get versionMismatchUpdateThis =>
      'نسخه‌های بازی با هم سازگار نیستند: این دستگاه نسخهٔ قدیمی‌تری دارد. لطفاً این برنامه را به‌روز کن (مرورگر: صفحه را دوباره بارگیری کن).';

  @override
  String versionMismatchGuestRefused(String reason) {
    return 'دستگاهی خواست بپیوندد اما رد شد: $reason';
  }

  @override
  String menuVersion(String version) {
    return 'نسخه $version';
  }

  @override
  String aboutBuildDetails(String build, String protocol, String games) {
    return 'شمارهٔ ساخت $build · پروتکل $protocol · داده‌های بازی $games';
  }

  @override
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  ) {
    return 'نسخهٔ $nameA: $versionA، نسخهٔ $nameB: $versionB.';
  }

  @override
  String versionMismatchVersionsDevices(String versionA, String versionB) {
    return 'نسخهٔ این دستگاه: $versionA، نسخهٔ دستگاه دیگر: $versionB.';
  }

  @override
  String get aboutTitle => 'درباره Klunki';

  @override
  String get aboutPrivacy => 'حریم خصوصی';

  @override
  String get aboutImpressum => 'اطلاعات حقوقی (Impressum)';

  @override
  String get aboutSupport => 'پشتیبانی';

  @override
  String get aboutLicense => 'Klunki نرم‌افزار آزاد تحت مجوز GNU AGPL 3.0 است.';

  @override
  String get aboutSourceCode => 'کد منبع';

  @override
  String get aboutLicenses => 'مجوزهای متن‌باز';

  @override
  String get aboutOpenInBrowser => 'باز کردن در مرورگر';

  @override
  String get aboutPrivacyOffline =>
      'این نسخه (به انگلیسی) در برنامه ذخیره شده تا بدون اینترنت هم بخوانی. مرجع، صفحهٔ وب است:';

  @override
  String get menuGameChess => 'شطرنج';

  @override
  String get menuDescChess => 'بازی کلاسیک: شاه حریف را مات کن.';

  @override
  String get chessWhite => 'سفید';

  @override
  String get chessBlack => 'سیاه';

  @override
  String get chessColorLabel => 'رنگ تو';

  @override
  String get chessColorRandom => 'تصادفی';

  @override
  String get chessColorHelper =>
      'سفید شروع می‌کند. با «تصادفی» قرعه تصمیم می‌گیرد.';

  @override
  String get chessYouPlayWhite => 'تو با سفید بازی می‌کنی.';

  @override
  String get chessYouPlayBlack => 'تو با سیاه بازی می‌کنی.';

  @override
  String get chessCheck => 'کیش!';

  @override
  String get chessHintSelect => 'روی یک مهره بزن تا آن را حرکت دهی.';

  @override
  String get chessHintTarget => 'روی یک خانهٔ علامت‌دار بزن.';

  @override
  String get chessPromotionTitle => 'ارتقای پیاده به …';

  @override
  String get chessFlipBoard => 'چرخاندن صفحه';

  @override
  String get chessAutoFlip => 'چرخاندن صفحه به سمت نوبت';

  @override
  String chessSquareEmpty(String square) {
    return '$square: خالی';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square: $piece ($side)';
  }

  @override
  String get chessPieceKing => 'شاه';

  @override
  String get chessPieceQueen => 'وزیر';

  @override
  String get chessPieceRook => 'رخ';

  @override
  String get chessPieceBishop => 'فیل';

  @override
  String get chessPieceKnight => 'اسب';

  @override
  String get chessPiecePawn => 'پیاده';

  @override
  String get chessOfferDraw => 'پیشنهاد مساوی';

  @override
  String get chessOfferDrawTitle => 'پیشنهاد مساوی بدهی؟';

  @override
  String chessOfferDrawBody(String player) {
    return '$player می‌تواند بپذیرد یا رد کند. با پذیرفتن، بازی مساوی تمام می‌شود.';
  }

  @override
  String get chessOfferDrawConfirm => 'پیشنهاد بده';

  @override
  String get chessDrawOfferTitle => 'پیشنهاد مساوی';

  @override
  String chessDrawOfferBody(String player) {
    return '$player پیشنهاد مساوی داده است. اگر بپذیری، بازی مساوی تمام می‌شود.';
  }

  @override
  String get chessDrawAccept => 'پذیرفتن';

  @override
  String get chessDrawDecline => 'رد کردن';

  @override
  String chessHintDrawOffered(String player) {
    return 'مساوی پیشنهاد شد؛ $player تصمیم می‌گیرد.';
  }

  @override
  String chessHintDrawDeclined(String player) {
    return '$player پیشنهاد مساوی را رد کرد.';
  }

  @override
  String get chessMoveDrawOffer => 'پیشنهاد مساوی';

  @override
  String get chessMoveDrawDecline => 'رد مساوی';

  @override
  String get chessMoveDrawAccept => 'پذیرش مساوی';

  @override
  String get engineReasonChessDrawAgreed => 'مساوی با توافق';

  @override
  String get engineReasonChessCheckmate => 'کیش و مات';

  @override
  String get engineReasonChessStalemate => 'پات';

  @override
  String get engineReasonChessInsufficientMaterial =>
      'مهرهٔ کافی برای مات وجود ندارد';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves حرکت بدون گرفتن مهره یا حرکت پیاده';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return 'تکرار یک وضعیت $times بار';
  }

  @override
  String get menuGameWordTiles => 'سخنور';

  @override
  String get menuDescWordTiles => 'با حروف واژه بساز';

  @override
  String menuPreviewGame(String game) {
    return 'پیش‌نمایش: $game';
  }

  @override
  String get wordtilesPlay => 'بگذار';

  @override
  String get wordtilesRecall => 'برگرداندن همهٔ کاشی‌ها';

  @override
  String get wordtilesShuffle => 'بُر زدن کاشی‌ها';

  @override
  String get wordtilesExchange => 'تعویض';

  @override
  String wordtilesExchangeConfirm(int count) {
    return 'تعویض $count';
  }

  @override
  String get wordtilesPass => 'پاس';

  @override
  String get wordtilesZoomIn => 'بزرگ‌نمایی';

  @override
  String get wordtilesZoomOut => 'کل صفحه';

  @override
  String wordtilesBag(int count) {
    return 'کیسه: $count کاشی';
  }

  @override
  String wordtilesScore(String player, int score) {
    return '$player: $score امتیاز';
  }

  @override
  String get wordtilesHintPlace =>
      'کاشی‌ها را روی صفحه بکش، یا یک کاشی و بعد یک خانه را لمس کن.';

  @override
  String get wordtilesHintFirst => 'واژهٔ اول باید از ستارهٔ وسط بگذرد.';

  @override
  String wordtilesHintZoom(String hint) {
    return '$hint با دو انگشت صفحه را بزرگ و کوچک کن.';
  }

  @override
  String get wordtilesHintSelected => 'یک خانهٔ خالی را لمس کن.';

  @override
  String get wordtilesHintExchange =>
      'کاشی‌هایی را که به کیسه برمی‌گردند انتخاب کن.';

  @override
  String get wordtilesHintAnswer => 'واژه را بپذیر یا به آن اعتراض کن.';

  @override
  String wordtilesExchangeNotNow(int count) {
    return 'تعویض فقط وقتی ممکن است که دست‌کم $count کاشی در کیسه باشد.';
  }

  @override
  String wordtilesPreview(String words, int score) {
    return '$words: $score امتیاز';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    return '$words: $score امتیاز (با $bonus امتیاز جایزه برای همهٔ کاشی‌ها)';
  }

  @override
  String get wordtilesErrorLine => 'کاشی‌ها باید در یک ردیف یا یک ستون باشند.';

  @override
  String get wordtilesErrorGap => 'بین کاشی‌ها یک خانهٔ خالی مانده است.';

  @override
  String get wordtilesErrorShort => 'واژهٔ اول دست‌کم دو حرف لازم دارد.';

  @override
  String get wordtilesErrorConnect =>
      'کاشی‌ها باید به واژه‌ای روی صفحه وصل باشند.';

  @override
  String get wordtilesErrorUnknownWord => 'یکی از واژه‌ها در واژه‌نامه نیست.';

  @override
  String get wordtilesErrorAnswerFirst =>
      'اول واژهٔ قبلی را بپذیر یا به آن اعتراض کن.';

  @override
  String get wordtilesErrorOther => 'نمی‌توانی کاشی‌ها را این‌طور بگذاری.';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    return '$player $words را با $score امتیاز گذاشت.';
  }

  @override
  String get wordtilesAccept => 'پذیرفتن';

  @override
  String get wordtilesChallenge => 'اعتراض';

  @override
  String get wordtilesChallengeTitle => 'به واژه اعتراض می‌کنی؟';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return 'بدون واژه‌نامه نظر تو تعیین می‌کند: $player کاشی‌ها را پس می‌گیرد و امتیازی نمی‌گیرد. بعد نوبت توست.';
  }

  @override
  String get wordtilesChallengeBodyDict =>
      'واژه‌نامه تعیین می‌کند. اگر واژه در آن باشد، نوبتت را از دست می‌دهی.';

  @override
  String wordtilesEndPending(String player) {
    return '$player همهٔ کاشی‌هایش را گذاشت. اگر بپذیری، بازی تمام می‌شود.';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    return '$words با $score امتیاز';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کاشی عوض شد',
      one: 'یک کاشی عوض شد',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => 'پاس داد';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return 'اعتراض کرد: $words پس گرفته شد';
  }

  @override
  String get wordtilesMoveChallengeFailed => 'اعتراض کرد، ولی واژه‌ها درست‌اند';

  @override
  String get wordtilesMoveAccept => 'پذیرفت';

  @override
  String get wordtilesBlankTitle => 'کاشی خالی کدام حرف باشد؟';

  @override
  String get wordtilesPremiumDoubleLetter => 'ح×2';

  @override
  String get wordtilesPremiumTripleLetter => 'ح×3';

  @override
  String get wordtilesPremiumDoubleWord => 'و×2';

  @override
  String get wordtilesPremiumTripleWord => 'و×3';

  @override
  String get wordtilesOptionTiles => 'حروف';

  @override
  String get wordtilesOptionDictionary => 'بررسی با واژه‌نامه';

  @override
  String get wordtilesOptionDictionaryOn =>
      'هر واژه‌ای که گذاشته شود در واژه‌نامه جست‌وجو می‌شود. اگر نبود، با هم تصمیم می‌گیرید: پس گرفتن یا پذیرفتن به‌هرحال.';

  @override
  String get wordtilesOptionDictionaryOff =>
      'بدون واژه‌نامه خودتان داوری می‌کنید: می‌توان به یک واژه اعتراض کرد.';

  @override
  String get wordtilesOptionsNext => 'بعدی';

  @override
  String get wordtilesDictLoading => 'در حال بارگذاری واژه‌نامه…';

  @override
  String get wordtilesDictLoadFailed => 'واژه‌نامه بارگذاری نشد.';

  @override
  String get wordtilesUnknownTitle => 'در واژه‌نامه نیست';

  @override
  String wordtilesUnknownBody(String words, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«$words» در واژه‌نامه نیست.',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesUnknownAsk =>
      'می‌توانید حرف‌ها را پس بگیرید. اگر هر دو موافقید که به‌هرحال حساب شود، بپذیرید.';

  @override
  String get wordtilesUnknownWithdraw => 'پس گرفتن';

  @override
  String get wordtilesUnknownAllow => 'به‌هرحال بپذیر';

  @override
  String wordtilesMovePlaceAllowed(String words, int score, String allowed) {
    return '$words با $score امتیاز (پذیرفته: $allowed)';
  }

  @override
  String get wordtilesBench => 'نیمکت تمرین';

  @override
  String get wordtilesBenchClear => 'برگرداندن همه حرف‌ها از نیمکت';

  @override
  String get wordtilesBenchHint =>
      'حرف‌ها را اینجا بکشید تا واژه‌ها را امتحان کنید.';

  @override
  String get wordtilesCoachBench1 =>
      'نیمکت تمرین مثل دفترچهٔ یادداشت شماست: حرف‌ها را اینجا بکشید و واژه‌ها را امتحان کنید.';

  @override
  String get wordtilesCoachBench2 =>
      'فقط امتیاز حرف‌ها را جمع می‌زند و بررسی نمی‌کند که واژه درست است یا نه.';

  @override
  String get wordtilesCoachBench3 =>
      'با این دکمه همهٔ حرف‌ها برمی‌گردند. نیمکت شما را فقط خودتان می‌بینید.';

  @override
  String wordtilesCoachStep(int step, int count) {
    return '$step از $count';
  }

  @override
  String get wordtilesCoachNext => 'بعدی';

  @override
  String get wordtilesCoachDone => 'فهمیدم';

  @override
  String get wordtilesCoachSkip => 'رد شدن';

  @override
  String get wordtilesPassTitle => 'نوبت را رد می‌کنی؟';

  @override
  String wordtilesPassBody(int count, int limit) {
    return 'نوبتت بدون امتیاز تمام می‌شود. نوبت‌های پشت‌سرهم بدون امتیاز: $count از $limit. با $limit بازی تمام می‌شود.';
  }

  @override
  String get wordtilesBlankScore => 'کاشی خالی 0 امتیاز دارد.';

  @override
  String get wordtilesHelp => 'روش بازی';

  @override
  String get wordtilesHelpGoal =>
      'مثل جدول کلمات متقاطع واژه بگذارید. هر حرف امتیاز دارد (عدد کوچک). واژهٔ اول از روی ستارهٔ وسط می‌گذرد و هر واژهٔ بعدی به واژه‌های روی صفحه وصل می‌شود.';

  @override
  String get wordtilesHelpPremium => 'خانه‌های جایزه';

  @override
  String get wordtilesHelpDoubleLetter => 'امتیاز حرف دوبرابر';

  @override
  String get wordtilesHelpTripleLetter => 'امتیاز حرف سه‌برابر';

  @override
  String get wordtilesHelpDoubleWord => 'امتیاز کل واژه دوبرابر';

  @override
  String get wordtilesHelpTripleWord => 'امتیاز کل واژه سه‌برابر';

  @override
  String get wordtilesHelpPremiumOnce =>
      'خانه‌های جایزه فقط در نوبتی حساب می‌شوند که کاشی روی آن‌ها گذاشته شود.';

  @override
  String wordtilesHelpBingo(int count, int bonus) {
    return 'هر $count کاشی در یک نوبت: $bonus امتیاز اضافه.';
  }

  @override
  String get wordtilesHelpBlank =>
      'کاشی خالی هر حرفی می‌شود که انتخاب کنی، اما 0 امتیاز دارد. یک 0 کوچک رویش دیده می‌شود.';

  @override
  String wordtilesHelpSwap(int count) {
    return 'عوض کردن: کاشی‌ها را به کیسه برگردان و کاشی تازه بردار. فقط تا وقتی که دست‌کم $count کاشی در کیسه باشد، و نوبت را می‌گیرد.';
  }

  @override
  String wordtilesHelpPass(int limit) {
    return 'رد کردن: یک نوبت را رد می‌کنی. بعد از $limit نوبت پشت‌سرهم بدون امتیاز، بازی تمام می‌شود.';
  }

  @override
  String get wordtilesHelpDictionary =>
      'با «بررسی با واژه‌نامه» هر واژه هنگام گذاشتن جست‌وجو می‌شود. اگر نبود، کاشی‌ها را پس بگیرید یا با هم بپذیرید: «به‌هرحال بپذیر». واژه‌های پذیرفته‌شده در تاریخچه می‌آیند.';

  @override
  String get wordtilesHelpChallenge =>
      'بدون واژه‌نامه می‌توان به واژهٔ آخر اعتراض کرد: کاشی‌ها پس گرفته می‌شوند و امتیازی ندارند.';

  @override
  String get wordtilesHelpBench =>
      'روی نیمکت تمرین واژه‌ها را امتحان می‌کنی. فقط امتیاز حرف‌ها را نشان می‌دهد، نه این‌که واژه هست یا نه.';

  @override
  String get wordtilesHelpZoom =>
      'با دو انگشت صفحه را بزرگ و کوچک و جابه‌جا می‌کنی. کاشی‌ای را که تازه گذاشته‌ای مستقیم بکش تا جابه‌جا شود؛ یک لمس آن را برمی‌گرداند.';

  @override
  String get wordtilesHelpEnd =>
      'بازی وقتی تمام می‌شود که کیسه خالی باشد و کسی همهٔ کاشی‌هایش را گذاشته باشد. امتیاز کاشی‌های باقی‌مانده کم می‌شود و کسی که تمام کرده آن را می‌گیرد.';

  @override
  String wordtilesResultRack(String points) {
    return 'کاشی‌های باقی‌مانده: $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    return 'بهترین واژه: $word ($player، $score امتیاز)';
  }

  @override
  String wordtilesResultAllowed(String words) {
    return 'پذیرفته‌شده به‌هرحال: $words';
  }

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return 'همهٔ کاشی‌ها گذاشته شد، نتیجهٔ نهایی $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '$turns نوبت بدون امتیاز، نتیجهٔ نهایی $a : $b';
  }

  @override
  String get webBetaBadge => 'آزمایشی';

  @override
  String get aboutWebBeta =>
      'نسخهٔ آزمایشی وب – بازی روی چند دستگاه در اپ ممکن است.';

  @override
  String get networkUnavailableWeb =>
      'هنوز در مرورگر در دسترس نیست – با اپ می‌شود روی چند دستگاه بازی کرد.';

  @override
  String get appBetaTeaser => 'نسخهٔ آزمایشی اپ در حال آماده‌سازی است.';

  @override
  String get appBetaIos => 'امتحان اپ برای iPhone و iPad';

  @override
  String get appBetaAndroid => 'دریافت اپ برای Android';

  @override
  String wordtilesOptionsSummaryDict(String language) {
    return '$language · با واژه‌نامه';
  }

  @override
  String wordtilesOptionsSummaryFree(String language) {
    return '$language · بدون واژه‌نامه';
  }

  @override
  String wordtilesOpenPlacementJoker(String player, String words, int score) {
    return '$player $words را با $score امتیاز گذاشت (با عوض کردن کاشی خالی).';
  }

  @override
  String get wordtilesOptionJoker => 'عوض کردن کاشی خالی';

  @override
  String get wordtilesOptionJokerExplain =>
      'قانون خانگی: اگر حرفی را داری که یک کاشی خالیِ روی صفحه به جای آن است، می‌توانی آن را همان‌جا بگذاری و کاشی خالی را برداری. بعد در همان نوبت کاشی هم می‌گذاری.';

  @override
  String wordtilesOptionsSummaryJoker(String summary) {
    return '$summary · عوض کردن کاشی خالی';
  }

  @override
  String get wordtilesHintJoker =>
      'حرف همانند را روی یک کاشی خالیِ صفحه بکش تا کاشی خالی را برداری.';

  @override
  String get wordtilesJokerStaged =>
      'کاشی خالی برداشته شد. حالا کاشی هم بگذار، وگرنه تعویض حساب نمی‌شود.';

  @override
  String wordtilesMoveJoker(String move) {
    return '$move (با عوض کردن کاشی خالی)';
  }

  @override
  String get wordtilesHelpJoker =>
      'عوض کردن کاشی خالی (قانون خانگی): اگر حرفی را داری که یک کاشی خالیِ روی صفحه به جای آن است، آن را روی کاشی خالی بکش. کاشی خالی به کاشی‌های تو می‌آید و در همان نوبت کاشی هم می‌گذاری (کاشی خالی هم می‌تواند جزو آن‌ها باشد). بدون گذاشتن کاشی، تعویض حساب نمی‌شود. واژهٔ قبلی و امتیازش می‌ماند.';

  @override
  String get wordtilesHelpJokerOn => 'در این بازی روشن است.';

  @override
  String get wordtilesHelpJokerOff =>
      'در این بازی خاموش است. می‌توانید پیش از بازی روشنش کنید.';

  @override
  String wordtilesUnknownAskNet(String player) {
    return 'می‌توانی حرف‌ها را پس بگیری یا از $player بپرسی که به‌هرحال حساب شود یا نه.';
  }

  @override
  String wordtilesUnknownDeclinedBefore(String player) {
    return '$player قبلاً رد کرده است. حرف‌ها را پس بگیر.';
  }

  @override
  String get wordtilesAllowTitle => 'به‌هرحال پذیرفته شود؟';

  @override
  String wordtilesAllowBody(String player, String words) {
    return '$player می‌خواهد «$words» پذیرفته شود؛ موافقی؟';
  }

  @override
  String get wordtilesAllowAccept => 'پذیرفتن';

  @override
  String get wordtilesAllowDecline => 'رد کردن';

  @override
  String wordtilesAllowDeciding(String player) {
    return '$player تصمیم می‌گیرد…';
  }

  @override
  String get wordtilesAllowYouDecide => 'تصمیم با توست';

  @override
  String wordtilesAllowLine(String player, String words, int score) {
    return '$player می‌خواهد «$words» پذیرفته شود ($score امتیاز).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '$player «$words» را رد کرد.';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    return 'درخواست پذیرش $words ($score امتیاز)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    return 'موافقت: $words حساب شد ($score امتیاز)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'رد شد: $words';
  }

  @override
  String get menuGameMauMau => 'Mau-Mau';

  @override
  String get menuDescMauMau => 'کارت‌های جور بازی کن تا دستت خالی شود';

  @override
  String get engineReasonMaumauEmptyHand => 'همهٔ کارت‌ها بازی شد';

  @override
  String get maumauSuitClubs => 'خاج';

  @override
  String get maumauSuitSpades => 'پیک';

  @override
  String get maumauSuitHearts => 'دل';

  @override
  String get maumauSuitDiamonds => 'خشت';

  @override
  String get maumauRankJack => 'سرباز';

  @override
  String get maumauRankQueen => 'بی‌بی';

  @override
  String get maumauRankKing => 'شاه';

  @override
  String get maumauRankAce => 'آس';

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
    return '$rank $suit';
  }

  @override
  String get maumauOptionsIntro => 'با کدام قانون‌ها بازی کنیم؟';

  @override
  String get maumauOptionsNext => 'بعدی';

  @override
  String get maumauOptionSeven => '7: دو کارت برداشتن';

  @override
  String get maumauOptionSevenExplain =>
      'بعد از 7، طرف مقابل 2 کارت برمی‌دارد.';

  @override
  String get maumauOptionStack => '7 روی 7';

  @override
  String get maumauOptionStackExplain =>
      'هر کس 7 دارد، آن را رویش می‌گذارد. آن‌وقت طرف مقابل 4 کارت برمی‌دارد.';

  @override
  String get maumauOptionEight => '8: یک نوبت رد';

  @override
  String get maumauOptionEightExplain => 'بعد از 8، نوبت طرف مقابل رد می‌شود.';

  @override
  String get maumauOptionJackInfo =>
      'سرباز: تقریباً همیشه جور است. هر کس آن را بازی کند، یک خال می‌خواهد.';

  @override
  String get maumauOptionJackOnJack => 'سرباز روی سرباز';

  @override
  String get maumauOptionJackOnJackExplain =>
      'سرباز را می‌شود روی سرباز هم گذاشت.';

  @override
  String get maumauOptionAce => 'آس: دوباره';

  @override
  String get maumauOptionAceExplain =>
      'هر کس آس بازی کند، فوراً دوباره نوبت دارد.';

  @override
  String get maumauOptionMau => 'گفتن «Mau!»';

  @override
  String get maumauOptionMauExplain =>
      'با کارت یکی‌مانده‌به‌آخر اول «Mau!» را بزن. اگر یادت برود، یک کارت جریمه برمی‌داری.';

  @override
  String maumauOpponentCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return '$player: $_temp0';
  }

  @override
  String maumauYourCards(int count) {
    return 'کارت‌های تو ($count)';
  }

  @override
  String maumauStock(int count) {
    return 'دسته: $count';
  }

  @override
  String maumauStockLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return 'دستهٔ برداشتن، $_temp0';
  }

  @override
  String get maumauDiscard => 'کارت‌های بازی‌شده';

  @override
  String maumauWish(String suit) {
    return 'خواسته: $suit';
  }

  @override
  String get maumauDraw => 'یک کارت بردار';

  @override
  String maumauDrawPenalty(int count) {
    return '$count کارت بردار';
  }

  @override
  String get maumauKeep => 'نگه دار';

  @override
  String get maumauPass => 'رد کن';

  @override
  String get maumauMauButton => 'Mau!';

  @override
  String get maumauContinue => 'ادامه';

  @override
  String get maumauPickSuitTitle => 'کدام خال را می‌خواهی؟';

  @override
  String get maumauDrewNoFit => 'این کارت را برداشتی. جور نیست.';

  @override
  String maumauDrewPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return '$_temp0 برمی‌داری:';
  }

  @override
  String get maumauHintPlay => 'یک کارت جور بازی کن یا یک کارت بردار.';

  @override
  String maumauHintWish(String suit) {
    return 'خال خواسته‌شده: $suit. از همین خال بازی کن یا کارت بردار.';
  }

  @override
  String maumauHintPenalty(int count) {
    return 'باید $count کارت برداری.';
  }

  @override
  String maumauHintPenaltyStack(int count) {
    return 'یک 7 بازی کن یا $count کارت بردار.';
  }

  @override
  String get maumauHintDrawn => 'کارت برداشته جور است. بازی‌اش کن یا نگهش دار.';

  @override
  String get maumauHintPass => 'چیزی برای برداشتن نمانده. باید رد کنی.';

  @override
  String get maumauHintMau =>
      'کارت یکی‌مانده‌به‌آخر: اول «Mau!» را بزن، بعد بازی کن.';

  @override
  String maumauLastPlayed(String player, String card) {
    return '$player $card را بازی کرد.';
  }

  @override
  String maumauLastPlayedWish(String player, String card, String suit) {
    return '$player $card را بازی کرد و $suit می‌خواهد.';
  }

  @override
  String maumauLastDrew(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return '$player $_temp0 برداشت.';
  }

  @override
  String maumauLastDrewPenalty(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت جریمه',
      one: 'یک کارت جریمه',
    );
    return '$player $_temp0 برداشت.';
  }

  @override
  String maumauLastKept(String player) {
    return '$player یک کارت برداشت و نگهش داشت.';
  }

  @override
  String maumauLastPassed(String player) {
    return '$player رد کرد.';
  }

  @override
  String maumauExtraMau(String player) {
    return '$player می‌گوید «Mau!».';
  }

  @override
  String maumauExtraForgotMau(String player) {
    return '$player «Mau!» را فراموش کرد و یک کارت جریمه برمی‌دارد.';
  }

  @override
  String maumauExtraPenalty(String player, int count) {
    return '$player باید $count کارت بردارد.';
  }

  @override
  String maumauExtraAgain(String player) {
    return 'نوبت $player رد می‌شود.';
  }

  @override
  String maumauExtraAce(String player) {
    return '$player دوباره نوبت دارد.';
  }

  @override
  String get maumauExtraReshuffled =>
      'کارت‌های بازی‌شده بُر خوردند و دستهٔ تازه شدند.';

  @override
  String maumauMovePlay(String card) {
    return '$card را بازی کرد';
  }

  @override
  String maumauMovePlayWish(String card, String suit) {
    return '$card را بازی کرد، $suit می‌خواهد';
  }

  @override
  String maumauMoveDraw(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کارت',
      one: 'یک کارت',
    );
    return '$_temp0 برداشت';
  }

  @override
  String get maumauMovePass => 'رد کرد';

  @override
  String get maumauMoveKeep => 'کارت برداشته را نگه داشت';

  @override
  String get menuGameMaexchen => 'میا';

  @override
  String get menuDescMaexchen => 'تاس بیندازید، بلوف بزنید، دست را رو کنید';

  @override
  String get engineReasonMaexchenNoLives => 'دیگر جانی نمانده';

  @override
  String get maexchenOptionLives => 'جان‌ها در شروع';

  @override
  String get maexchenOptionDouble => 'میای دوبل';

  @override
  String get maexchenOptionDoubleExplain =>
      'هر چیزی دربارهٔ میا دوبل حساب می‌شود: شک به یک میای واقعی یا لو رفتن یک میای تقلبی 2 جان می‌گیرد.';

  @override
  String get maexchenOptionsNext => 'بعدی';

  @override
  String get maexchenRoll => 'تاس بینداز';

  @override
  String get maexchenPeek => 'نگاه کن';

  @override
  String get maexchenCover => 'بپوشان';

  @override
  String get maexchenPickTitle => 'چه اعلام می‌کنی؟';

  @override
  String maexchenAnnounce(String value) {
    return '$value را اعلام کن';
  }

  @override
  String get maexchenOrder =>
      'از کوچک به بزرگ: 31، 32 … 65، بعد جفت‌ها 11 … 66، بعد میا (21).';

  @override
  String get maexchenBelieve => 'باور می‌کنم';

  @override
  String get maexchenDoubt => 'شک دارم';

  @override
  String get maexchenGiveUp => 'یک جان بده';

  @override
  String maexchenAnnounced(String player, String value) {
    return '$player می‌گوید $value';
  }

  @override
  String get maexchenNewRound => 'دور جدید: هر عددی مجاز است';

  @override
  String get maexchenHintRoll =>
      'تاس بینداز را بزن، بعد یواشکی زیر لیوان را نگاه کن.';

  @override
  String maexchenHintBelieved(String value) {
    return '$value را باور کردی. تاس بینداز و بیشتر از $value اعلام کن.';
  }

  @override
  String get maexchenHintAnnounceFirst =>
      'یواشکی نگاه کن و یک عدد اعلام کن. بلوف زدن مجاز است!';

  @override
  String maexchenHintAnnounceHigher(String value) {
    return 'بیشتر از $value اعلام کن. بلوف زدن مجاز است!';
  }

  @override
  String maexchenHintRespond(String player, String value) {
    return '$player می‌گوید $value. باور می‌کنی؟';
  }

  @override
  String maexchenHintRespondMaexchen(String player) {
    return '$player می‌گوید میا! بالاتر از این نیست: شک می‌کنی یا یک جان می‌دهی؟';
  }

  @override
  String maexchenUnderCup(String value) {
    return 'زیر لیوان: $value';
  }

  @override
  String maexchenVerdictBluff(String player) {
    return 'بلوف بود! $player یک جان از دست می‌دهد.';
  }

  @override
  String maexchenVerdictTrue(String player) {
    return 'راست بود! $player یک جان از دست می‌دهد.';
  }

  @override
  String maexchenVerdictTrueTwo(String player) {
    return 'میای واقعی! $player 2 جان از دست می‌دهد.';
  }

  @override
  String maexchenVerdictBluffTwo(String player) {
    return 'میای تقلبی! $player 2 جان از دست می‌دهد.';
  }

  @override
  String maexchenVerdictGaveUp(String player) {
    return '$player یک جان می‌دهد. لیوان بسته می‌ماند.';
  }

  @override
  String maexchenLivesOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جان',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenRoundLabel(int round) {
    return 'دور $round';
  }

  @override
  String get maexchenMoveRoll => 'تاس می‌اندازد';

  @override
  String maexchenMoveAnnounce(String value) {
    return '$value را اعلام می‌کند';
  }

  @override
  String get maexchenMoveBelieve => 'باور می‌کند';

  @override
  String get maexchenMoveDoubt => 'شک می‌کند';

  @override
  String get maexchenMoveGiveUp => 'یک جان می‌دهد';

  @override
  String get maexchenMaexchenName => 'میا';

  @override
  String get maexchenMaexchenCall => 'میا!';

  @override
  String get maexchenAnnouncedLabel => 'اعلام‌شده';

  @override
  String get maexchenPickFirst => 'یک عدد انتخاب کن';

  @override
  String get maexchenShakeHint => 'یا گوشی را تکان بده';

  @override
  String get shakeToRollSetting => 'تکان دادن برای ریختن تاس';

  @override
  String get shakeToRollExplain =>
      'گوشی را مثل لیوان تاس تکان بده، به جای زدن روی «تاس بینداز».';

  @override
  String get confirmMoveSetting => 'تأیید حرکت';

  @override
  String get confirmMoveHelper => 'حرکت فقط بعد از زدن «حرکت بده» حساب می‌شود.';

  @override
  String get confirmMoveCommit => 'حرکت بده';

  @override
  String get confirmMoveBack => 'برگشت';

  @override
  String get confirmMoveHint =>
      'این حرکت درست است؟ روی «حرکت بده» یا «برگشت» بزن.';

  @override
  String get confirmMoveOn => 'تأیید حرکت: روشن است.';

  @override
  String get confirmMoveOff => 'تأیید حرکت: خاموش است.';
}

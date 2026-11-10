// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Klunki';

  @override
  String get appSubtitle => 'مجموعة ألعاب';

  @override
  String get menuLanguage => 'اللغة';

  @override
  String get languagePickerTitle => 'اختر اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get menuChooseGame => 'اختر لعبة';

  @override
  String get menuDebugConsole => 'وحدة تصحيح الأخطاء';

  @override
  String get menuGameConnect4 => 'أربعة في صف';

  @override
  String get menuGameMuehle => 'الطاحونة';

  @override
  String get menuGameQuartettTrumpf => 'الرباعيات (مقارنة)';

  @override
  String get menuGameQuartettSets => 'الرباعيات (مجموعات)';

  @override
  String get menuGameSchiffe => 'معركة السفن';

  @override
  String get menuDescConnect4 =>
      'أربع في صف واحد – أفقيًا أو عموديًا أو قطريًا.';

  @override
  String get menuDescMuehle => 'كوِّن صفوفًا من ثلاث واستولِ على قطع خصمك.';

  @override
  String get menuDescQuartettTrumpf =>
      'قارنوا القيم – القيمة الأفضل تربح البطاقتين.';

  @override
  String get menuDescQuartettSets =>
      'اطلب البطاقات واجمع مجموعات كاملة من أربع.';

  @override
  String get menuDescSchiffe => 'أخفوا أساطيلكم وأطلقوا النار بالتناوب.';

  @override
  String get menuSectionNetwork => 'العب مع أجهزة أخرى';

  @override
  String get menuPlayOnOneDevice => 'على جهاز واحد';

  @override
  String get menuPlayWithOthers => 'مع الآخرين';

  @override
  String get hotSeatPassDeviceHint => 'تتبادلون الجهاز – ما هو مخفي يبقى سرًا.';

  @override
  String get roomStartSubtitle => 'ينضم الآخرون برمز الغرفة';

  @override
  String get roomJoinSubtitle => 'امسح الرمز أو اكتبه';

  @override
  String get roomAdvanced => 'متقدم';

  @override
  String get roomDirectWaitingHint =>
      'يضغط الآخرون على «انضم إلى غرفة» ويمسحون رمز QR هذا. وتجد الأجهزة على شبكة Wi-Fi نفسها الغرفة أيضًا تحت «غرف قريبة».';

  @override
  String get roomViaRelay => 'افتح الغرفة عبر خادم';

  @override
  String get roomViaRelayHelper =>
      'برمز غرفة، ويصلح أيضًا للاعبين في المتصفح. يتطلب خادمًا (مثلًا حاسوبًا يعمل عليه «klunki relay»). عند الإيقاف تعمل الغرفة على هذا الجهاز، وتجدها الأجهزة على شبكة Wi-Fi نفسها تلقائيًا.';

  @override
  String get roomTypeCode => 'اكتب رمز الغرفة';

  @override
  String shellToMove(String player) {
    return 'دور $player';
  }

  @override
  String shellHasWon(String player) {
    return 'الفوز لـ$player';
  }

  @override
  String get shellYourTurn => 'دورك';

  @override
  String shellWaitingFor(String player) {
    return 'في انتظار $player…';
  }

  @override
  String get shellYouHaveWon => 'لقد فزت';

  @override
  String get shellDraw => 'تعادل';

  @override
  String shellWins(String player) {
    return 'الفوز لـ$player!';
  }

  @override
  String get shellYouWin => 'أنت تفوز!';

  @override
  String get shellMenu => 'القائمة';

  @override
  String get shellPlayAgain => 'مرة أخرى';

  @override
  String get shellUndo => 'تراجع عن الحركة';

  @override
  String get shellTakeBack => 'تراجع';

  @override
  String get undoAllowedSetting => 'السماح بالتراجع عن الحركة';

  @override
  String get shellNewGame => 'لعبة جديدة';

  @override
  String get shellNewGameTitle => 'لعبة جديدة؟';

  @override
  String get shellNewGameBody => 'سيتم إلغاء اللعبة الحالية.';

  @override
  String get shellCancel => 'إلغاء';

  @override
  String get shellRestart => 'إعادة البدء';

  @override
  String get shellMoves => 'الحركات';

  @override
  String get shellNoMoves => 'لا حركات بعد.';

  @override
  String shellHistoryEntry(String player, String move) {
    return '$player: $move';
  }

  @override
  String shellHandoverPass(String player) {
    return 'مرّر الجهاز إلى $player';
  }

  @override
  String shellHandoverContinue(String player) {
    return 'أنا $player – متابعة';
  }

  @override
  String connect4Column(int column) {
    return 'العمود $column';
  }

  @override
  String get connect4HintTapColumn => 'انقر على عمود';

  @override
  String get muehlePhasePlacing => 'الوضع';

  @override
  String get muehlePhaseMoving => 'التحريك';

  @override
  String get muehlePhaseFlying => 'القفز';

  @override
  String muehleMovePlace(int point) {
    return 'يضع على $point';
  }

  @override
  String muehleMoveRemove(int point) {
    return 'يزيل الحجر من $point';
  }

  @override
  String muehleMoveMove(int from, int to) {
    return 'يحرّك $from→$to';
  }

  @override
  String muehleMoveFly(int from, int to) {
    return 'يقفز $from→$to';
  }

  @override
  String muehleHintRemove(String player) {
    return 'طاحونة! أزل حجرًا من $player';
  }

  @override
  String get muehleHintPlace => 'ضع حجرًا';

  @override
  String get muehleHintTarget =>
      'اختر هدفًا (أو انقر الحجر مرة أخرى لإلغاء التحديد)';

  @override
  String get muehleHintSelectFly => 'اختر حجرًا للقفز';

  @override
  String get muehleHintSelectMove => 'اختر حجرًا لتحريكه';

  @override
  String muehlePointEmpty(int point) {
    return 'النقطة $point، فارغة';
  }

  @override
  String muehlePointOwned(int point, String player) {
    return 'النقطة $point، $player';
  }

  @override
  String muehleCounts(int hand, int board) {
    return 'في اليد: $hand · على اللوحة: $board';
  }

  @override
  String muehleCaptured(int count) {
    return 'المأسورة: $count';
  }

  @override
  String get quartettNoGame => 'ليست لعبة رباعيات';

  @override
  String get quartettContinue => 'متابعة';

  @override
  String get quartettHigherWins => 'الأعلى يفوز';

  @override
  String get quartettLowerWins => 'الأدنى يفوز';

  @override
  String get quartettCardBack => 'رباعيات';

  @override
  String quartettCards(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return '$_temp0';
  }

  @override
  String quartettPlayerCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return '$player: $_temp0';
  }

  @override
  String quartettTrumpfMovePick(String stat) {
    return 'يختار $stat';
  }

  @override
  String get quartettTrumpfHintPick => 'اختر خاصية من بطاقتك';

  @override
  String quartettTrumpfPot(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return 'الوعاء: $_temp0';
  }

  @override
  String quartettTrumpfOpponentStack(String player) {
    return 'كومة $player';
  }

  @override
  String quartettTrumpfYourCard(String player) {
    return 'بطاقتك ($player)';
  }

  @override
  String get quartettTrumpfTie => 'تعادل – جولة فاصلة!';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return 'الجولة لصالح $player';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'فوز';

  @override
  String get quartettTrumpfOutcomeLose => 'خسارة';

  @override
  String get quartettTrumpfOutcomeTie => 'تعادل';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return 'اختيار $player: $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
    return 'البطاقات إلى الوعاء (الآن $count)، والاختيار مرة أخرى لـ$player';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return 'بانتظار اختيار $player …';
  }

  @override
  String get quartettTrumpfLastTrick => 'الجولة السابقة';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'المتابعة خلال $seconds ث';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return 'اختيار $player: $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return 'الاختيار التالي لـ$player';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return 'الاختيار مرة أخرى لـ$player';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'متابعة – الاختيار لـ$player';
  }

  @override
  String get quartettTrumpfYouPickNext => 'أنت تختار التالي';

  @override
  String quartettTrumpfTricksBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جولة متبقية',
      many: '$count جولة متبقية',
      few: '$count جولات متبقية',
      two: 'جولتان متبقيتان',
      one: 'جولة واحدة متبقية',
      zero: 'لا جولات متبقية',
    );
    return '$_temp0';
  }

  @override
  String quartettTrumpfHandoverReason(String player) {
    return 'الجولة كانت لصالح $player';
  }

  @override
  String quartettTrumpfChooseOwn(int count) {
    return 'لم يبقَ لديك سوى $count بطاقات – اختر واحدة.';
  }

  @override
  String quartettTrumpfChooseDefend(String player, String stat) {
    return 'اختيار $player: $stat. اختر بطاقتك.';
  }

  @override
  String get quartettTrumpfMoveChoose => 'يختار بطاقة';

  @override
  String quartettTrumpfHintDefending(String player) {
    return 'بانتظار بطاقة $player …';
  }

  @override
  String get quartettSetsHit => 'إصابة';

  @override
  String get quartettSetsMiss => 'لا يوجد';

  @override
  String quartettSetsMoveAsk(String card, String result) {
    return 'يطلب $card: $result';
  }

  @override
  String quartettSetsMoveAskQuartet(String card, String result, String set) {
    return 'يطلب $card: $result – رباعية $set';
  }

  @override
  String quartettSetsHintContinue(String player) {
    return 'انقر «متابعة» ومرّر الجهاز إلى $player';
  }

  @override
  String get quartettSetsHintAsk => 'انقر بطاقة ناقصة لتطلبها';

  @override
  String get quartettSetsNoQuartet => 'لا رباعية بعد';

  @override
  String quartettSetsStock(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return 'الكومة: $_temp0';
  }

  @override
  String quartettSetsScore(String nameA, String nameB, int a, int b) {
    return 'الرباعيات $nameA $a : $b $nameB';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return 'سؤال $player عن $card: $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return 'إصابة! تحصل على $card من $player';
  }

  @override
  String get quartettSetsMissDraw => 'لا يوجد – تسحب بطاقة';

  @override
  String get quartettSetsMissEmpty => 'لا يوجد – الكومة فارغة';

  @override
  String get quartettSetsAskAgain => 'يمكنك الطلب مرة أخرى.';

  @override
  String quartettSetsNotHeld(String player, String card) {
    return 'ليست لدى $player البطاقة $card.';
  }

  @override
  String quartettSetsQuartetLaid(String set) {
    return 'رباعية! تم وضع $set';
  }

  @override
  String get quartettSetsDrawn => 'المسحوبة:';

  @override
  String quartettSetsYourCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة',
      many: '$count بطاقة',
      few: '$count بطاقات',
      two: 'بطاقتان',
      one: 'بطاقة واحدة',
      zero: 'لا بطاقات',
    );
    return 'بطاقاتك ($player): $_temp0';
  }

  @override
  String quartettSetsProgress(int have, int missing) {
    return '$have/4 – ناقص: $missing';
  }

  @override
  String get quartettSetsAskSlot => 'اطلب';

  @override
  String get quartettSetsMissingSlot => 'ناقصة';

  @override
  String get schiffeHintSetup => 'انقر على البحر لوضع السفينة.';

  @override
  String get schiffeHintAllSunk => 'غرقت كل السفن.';

  @override
  String schiffeHintWaiting(String player) {
    return 'بانتظار $player…';
  }

  @override
  String get schiffeHintExtraShot =>
      'إصابة! مرة أخرى – انقر خانة في بحر الخصم.';

  @override
  String get schiffeHintFire => 'انقر خانة مجهولة في بحر الخصم لإطلاق النار.';

  @override
  String get schiffeLookWater => 'ماء';

  @override
  String get schiffeLookShip => 'سفينة';

  @override
  String get schiffeLookMiss => 'خطأ';

  @override
  String get schiffeLookShipHit => 'سفينة مصابة';

  @override
  String get schiffeLookHit => 'إصابة';

  @override
  String get schiffeLookSunk => 'غرقت';

  @override
  String get schiffeLookUnknown => 'مجهولة';

  @override
  String schiffeCellLabel(String cell, String state) {
    return '$cell $state';
  }

  @override
  String get schiffeFleetComplete => 'الأسطول جاهز';

  @override
  String schiffeShipWithLength(String ship, int length) {
    return '$ship ($length)';
  }

  @override
  String schiffeShipPlaced(String ship, int length) {
    return '$ship ($length) · موضوعة';
  }

  @override
  String get schiffeHorizontal => 'أفقي';

  @override
  String get schiffeVertical => 'عمودي';

  @override
  String get schiffeRandom => 'عشوائي';

  @override
  String get schiffeFleet => 'الأسطول';

  @override
  String schiffeExtraShotSunk(String ship) {
    return 'غرقت $ship – إصابة! مرة أخرى';
  }

  @override
  String get schiffeExtraShot => 'إصابة! مرة أخرى';

  @override
  String schiffeRemaining(int own, String player, int opponent) {
    return 'أسطولك: $own · الخصم ($player): بقي $opponent';
  }

  @override
  String schiffeIncoming(String player, String cell, String result) {
    return 'آخر طلقة من $player على $cell: $result';
  }

  @override
  String get schiffeTargetSection => 'الخصم';

  @override
  String get schiffeOwnSection => 'بحرك';

  @override
  String get schiffeMovePlace => 'يضع سفينة';

  @override
  String schiffeMoveAutoplace(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'يضع $count سفينة عشوائيًا',
      many: 'يضع $count سفينة عشوائيًا',
      few: 'يضع $count سفن عشوائيًا',
      two: 'يضع سفينتين عشوائيًا',
      one: 'يضع سفينة واحدة عشوائيًا',
      zero: 'لا يضع أي سفينة',
    );
    return '$_temp0';
  }

  @override
  String schiffeMoveFire(String cell, String result) {
    return 'يطلق على $cell: $result';
  }

  @override
  String get schiffeRotate => 'تدوير';

  @override
  String schiffeRotateSemantics(String orientation) {
    return 'تدوير، حاليًا $orientation';
  }

  @override
  String get schiffeRemove => 'إزالة';

  @override
  String get schiffeRemoveTooltip => 'العودة إلى الميناء';

  @override
  String get schiffeReset => 'إعادة ضبط';

  @override
  String get schiffeDone => 'تم';

  @override
  String schiffeSetupCount(int placed, int total, String player) {
    return 'تم وضع $placed من $total سفن · دور $player في التوزيع';
  }

  @override
  String schiffeHintSelected(String ship) {
    return 'تم اختيار $ship: اسحب للنقل، وانقر مرة أخرى للتدوير.';
  }

  @override
  String get schiffeHintReady =>
      'الأسطول جاهز. انقر على سفينة لنقلها أو تدويرها، أو على «تم».';

  @override
  String schiffeHintEarly(String player) {
    return 'يمكنك البدء بالتوزيع. يعمل «تم» بعد أن ينتهي $player.';
  }

  @override
  String get schiffeInvalidPlace =>
      'لا تتسع هنا: يجب أن تكون السفن كلها في البحر وألا تتلامس.';

  @override
  String get schiffeInvalidRotate =>
      'لا يمكن التدوير هنا، لا توجد مساحة كافية.';

  @override
  String get schiffeSubmitFailed => 'لم يُقبل التوزيع. انقر على «تم» مرة أخرى.';

  @override
  String get schiffeSelected => 'محددة';

  @override
  String get schiffeHarbour => 'الميناء';

  @override
  String get schiffeHintSetupMore =>
      'انقر على البحر للسفينة التالية. انقر على سفينة لنقلها أو تدويرها.';

  @override
  String get schiffeCoachTap => 'انقر عليها: نقل أو تدوير';

  @override
  String schiffeDoneLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count سفينة',
      many: 'بقيت $count سفينة',
      few: 'بقيت $count سفن',
      two: 'بقيت سفينتان',
      one: 'بقيت سفينة واحدة',
      zero: 'لم تبقَ سفن',
    );
    return '$_temp0';
  }

  @override
  String schiffePreviewSemantics(String ship, String orientation) {
    return 'معاينة: $ship، $orientation. انقر لتدويرها.';
  }

  @override
  String schiffePreviewLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count من هذا النوع',
      many: 'بقيت $count من هذا النوع',
      few: 'بقيت $count من هذا النوع',
      two: 'بقيت اثنتان من هذا النوع',
      one: 'الأخيرة من هذا النوع',
      zero: 'لم يبقَ شيء من هذا النوع',
    );
    return '$_temp0';
  }

  @override
  String get schiffeInvalidTouch =>
      'يجب ألا تتلامس السفن ولو عند الزوايا – اترك خانة فارغة بينها.';

  @override
  String get schiffeInvalidOffBoard => 'لا تتسع داخل اللوحة.';

  @override
  String schiffeShipSunk(String ship) {
    return 'غرقت $ship';
  }

  @override
  String get debugConsoleTitle => 'وحدة تصحيح الأخطاء';

  @override
  String get debugUndo => 'undo';

  @override
  String get debugMenu => 'لعبة / عرض';

  @override
  String debugNewGame(String game) {
    return 'جديد: $game';
  }

  @override
  String get debugLegalMoves => 'الحركات المسموحة';

  @override
  String get debugAutoPlay => 'اللعب حتى النهاية (عشوائيًا)';

  @override
  String get debugDemo => 'عرض: كل الألعاب';

  @override
  String get pairingDeviceNameHelper => 'هكذا يراك اللاعب الآخر';

  @override
  String get playerNameTitle => 'ما اسمك؟';

  @override
  String get playerNameLabel => 'اسمك';

  @override
  String playerLabel(String name, String mark) {
    return '$name ($mark)';
  }

  @override
  String get playerDefaultNameA => 'أمل';

  @override
  String get playerDefaultNameB => 'باسم';

  @override
  String get hotSeatStartTitle => 'من يلعب؟';

  @override
  String get hotSeatStartPlay => 'ابدأ';

  @override
  String get hotSeatNamesTitle => 'أسماء اللاعبين';

  @override
  String hotSeatNameLabel(int number) {
    return 'اللاعب $number';
  }

  @override
  String get hotSeatStartsHint => 'الدور الأول';

  @override
  String get hotSeatNamesHelper => 'اتركه فارغًا لاستخدام الاسم الافتراضي.';

  @override
  String get pairingChooseGame => 'اختر لعبة';

  @override
  String get roomStart => 'افتح غرفة';

  @override
  String roomStartFailed(String error) {
    return 'تعذّر فتح الغرفة: $error';
  }

  @override
  String get pairingNotAdvertised => 'غير مرئي تلقائيًا – يمسح الآخرون رمز QR.';

  @override
  String get pairingNoDiscoveryHost =>
      'لا بحث تلقائي على هذا الجهاز – يمسح الآخرون رمز QR.';

  @override
  String roomOfPlayer(String name, String game) {
    return 'غرفة $name: $game';
  }

  @override
  String pairingNoAddress(int port) {
    return 'لم يُعثر على عنوان Wi-Fi. هل الجهاز متصل بشبكة Wi-Fi؟ المنفذ: $port';
  }

  @override
  String get pairingAddresses => 'العناوين (للإدخال يدويًا):';

  @override
  String get pairingProbablyWifi => 'على الأرجح Wi-Fi';

  @override
  String get pairingWaitingForGuest => 'بانتظار اللاعب الآخر…';

  @override
  String get pairingCancel => 'إلغاء';

  @override
  String get roomNearby => 'غرف قريبة';

  @override
  String get pairingNoDiscoveryJoin =>
      'البحث التلقائي غير متاح على هذا الجهاز. امسح رمز QR أو أدخل العنوان تحت «متقدم».';

  @override
  String get pairingBrowseFailed =>
      'تعذّر البحث في الشبكة. امسح رمز QR أو أدخل العنوان تحت «متقدم».';

  @override
  String get pairingSearching => 'جارٍ البحث عن غرف…';

  @override
  String get pairingOtherVersion => 'إصدار مختلف من Klunki';

  @override
  String get pairingManualLabel => 'IP أو IP:منفذ أو رابط klunki://';

  @override
  String get pairingInvalidAddress =>
      'عنوان غير صالح. مثال: 192.168.1.20 أو 192.168.1.20:4747';

  @override
  String get pairingConnect => 'اتصال';

  @override
  String pairingConnecting(String host) {
    return 'جارٍ الاتصال بـ $host…';
  }

  @override
  String get pairingTimeout => 'انتهت المهلة';

  @override
  String pairingJoinFailed(String host, String error) {
    return 'فشل الاتصال بـ $host ($error).';
  }

  @override
  String get pairingJoinHints =>
      'نصائح: هل الجهازان على شبكة Wi-Fi نفسها؟ غالبًا ما تحظر شبكات الضيوف الاتصال بين الأجهزة. iOS: هل «الشبكة المحلية» مسموحة لـ Klunki (الإعدادات › الخصوصية)؟';

  @override
  String pairingStatus(String name, String peer) {
    return 'أنت: $name · الخصم: $peer';
  }

  @override
  String netBarYou(String name) {
    return 'أنت: $name';
  }

  @override
  String netBarOpponent(String peer) {
    return 'الخصم: $peer';
  }

  @override
  String get pairingOpponent => 'الخصم';

  @override
  String pairingPeerLeft(String peer) {
    return 'غادر $peer اللعبة';
  }

  @override
  String pairingPeerLost(String peer) {
    return 'انقطع الاتصال بـ $peer';
  }

  @override
  String pairingWaitForRejoin(String reason) {
    return '$reason. بانتظار عودته…';
  }

  @override
  String get pairingReconnecting => 'جارٍ إعادة الاتصال…';

  @override
  String get pairingReconnect => 'إعادة الاتصال';

  @override
  String get networkVerificationFailed => 'تعذّر تأكيد سجل اللعبة';

  @override
  String get pairingReconnectFailed =>
      'فشلت إعادة الاتصال. هل ما زال الجهاز الآخر في اللعبة؟';

  @override
  String get pairingBrowserJoin =>
      'الانضمام من متصفح (اكتب العنوان أو الصق الرابط):';

  @override
  String get pairingCopyLink => 'نسخ الرابط';

  @override
  String get pairingLinkCopied => 'تم نسخ الرابط';

  @override
  String get webJoinHttpsWarning =>
      'في المتصفح عبر https لا يصل Klunki إلا إلى خوادم آمنة (wss://) – استخدم التطبيق أو نسخة http المحلية.';

  @override
  String get webJoinAddressLabel => 'IP أو IP:منفذ أو رابط ws:// أو klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'المنفذ هو منفذ المتصفح (WebSocket) للجهاز الآخر، وإن لم يُذكر فهو $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'عنوان غير صالح. مثال: 192.168.1.20 أو 192.168.1.20:4748 أو klunki://join?h=…';

  @override
  String get webJoinHints =>
      'نصائح: هل هذا الجهاز على شبكة Wi-Fi نفسها التي عليها جهاز الغرفة؟ غالبًا ما تحظر شبكات الضيوف الاتصال بين الأجهزة. يجب فتح الصفحة عبر http:// وليس https://. يجب أن يعمل على الجهاز الآخر إصدار من Klunki يدعم المتصفح (يعرض «الانضمام من متصفح»).';

  @override
  String get engineReasonConnect4FourInARow => 'أربعة في صف';

  @override
  String get engineReasonConnect4BoardFull => 'اللوحة ممتلئة';

  @override
  String get engineReasonMuehleFewerThanThree => 'لدى الخصم أقل من 3 أحجار';

  @override
  String get engineReasonMuehleBlocked => 'لا يستطيع الخصم التحرك';

  @override
  String engineReasonMuehleNoRemovalLimit(int moves) {
    return '$moves حركة بلا أسر';
  }

  @override
  String get engineReasonQuartettBothStacksEmpty => 'الكومتان فارغتان';

  @override
  String get engineReasonQuartettAllCards => 'لم يبقَ لدى الخصم بطاقات';

  @override
  String engineReasonQuartettTrickLimitEqual(int a, int b) {
    return 'بلغ حد الجولات، عدد متساوٍ ($a:$b)';
  }

  @override
  String engineReasonQuartettTrickLimitMoreCards(int a, int b) {
    return 'بلغ حد الجولات، بطاقات أكثر ($a:$b)';
  }

  @override
  String engineReasonQuartettAllQuartetsEqual(int a, int b) {
    return 'وُضعت كل الرباعيات، $a:$b';
  }

  @override
  String engineReasonQuartettMostQuartets(int a, int b) {
    return 'رباعيات أكثر ($a:$b)';
  }

  @override
  String get engineReasonSchiffeAllSunk => 'غرقت كل السفن';

  @override
  String get engineReasonGostrategyFlagCaptured => 'تم الاستيلاء على العلم';

  @override
  String get engineReasonGostrategyNoMoves => 'لم تعد للخصم أي حركة';

  @override
  String get engineReasonGostrategyBothBlocked => 'لا يستطيع أي طرف التحرك';

  @override
  String engineReasonGostrategyMoveLimit(int moves) {
    return '$moves حركة بلا قتال';
  }

  @override
  String get menuGameGoStrategy => 'GoStrategy';

  @override
  String get menuDescGoStrategy =>
      'جيوش مخفية – اعثر على علم الخصم واستولِ عليه.';

  @override
  String get goPieceMarshal => 'مشير';

  @override
  String get goPieceGeneral => 'جنرال';

  @override
  String get goPieceColonel => 'عقيد';

  @override
  String get goPieceMajor => 'رائد';

  @override
  String get goPieceCaptain => 'نقيب';

  @override
  String get goPieceLieutenant => 'ملازم';

  @override
  String get goPieceSergeant => 'رقيب';

  @override
  String get goPieceMiner => 'خبير ألغام';

  @override
  String get goPieceScout => 'كشّاف';

  @override
  String get goPieceSpy => 'جاسوس';

  @override
  String get goPieceBomb => 'قنبلة';

  @override
  String get goPieceFlag => 'علم';

  @override
  String goPieceRank(String piece, String rank) {
    return '$piece ($rank)';
  }

  @override
  String goSetupTitle(String player) {
    return 'رتّب جيشك ($player)';
  }

  @override
  String get goSetupHint =>
      'المس قطعتين أو اسحب قطعة إلى مربع آخر في صفوفك الأربعة لتبديلهما، ثم «تم».';

  @override
  String goSetupSelected(String piece) {
    return 'تم اختيار $piece – المس مربعًا آخر في صفوفك الأربعة للتبديل.';
  }

  @override
  String get goSetupShuffle => 'خلط من جديد';

  @override
  String get goSetupDone => 'تم';

  @override
  String goSetupFirst(String player) {
    return 'الترتيب أولًا لـ$player – يمكنك التحضير في الأثناء.';
  }

  @override
  String goWaitingSetup(String player) {
    return 'بانتظار ترتيب $player …';
  }

  @override
  String get goLegendTitle => 'القطع';

  @override
  String get goLegendRules =>
      'الرتبة الأعلى تفوز، وعند التساوي يسقط الاثنان. الجاسوس يهزم المشير إذا هاجم. خبراء الألغام وحدهم يفككون القنابل. الكشافون يتحركون أي مسافة في خط مستقيم. القنابل والعلم لا تتحرك.';

  @override
  String get goHintSelect => 'المس إحدى قطعك، ثم مربعًا مميزًا.';

  @override
  String goHintSelected(String piece) {
    return '$piece: المس مربعًا مميزًا.';
  }

  @override
  String goHintNoTargets(String piece) {
    return '$piece لا يستطيع التحرك الآن.';
  }

  @override
  String goHintWaiting(String player) {
    return 'بانتظار $player …';
  }

  @override
  String goMoveLimit(String moves) {
    return '$moves حركة أخرى بلا قتال وتنتهي بالتعادل.';
  }

  @override
  String get goArmyOwn => 'جيشك';

  @override
  String goArmyEnemy(String player) {
    return 'الخصم: $player';
  }

  @override
  String goArmyLeft(String left, String total) {
    return 'تبقّى $left من $total';
  }

  @override
  String goFightBy(String player) {
    return 'هجوم من $player';
  }

  @override
  String goFightBeats(String winner, String loser) {
    return '$winner يهزم $loser';
  }

  @override
  String get goFightBoth => 'يسقط الاثنان';

  @override
  String goFightDefused(String piece) {
    return '$piece يفكك القنبلة';
  }

  @override
  String goFightBomb(String piece) {
    return '$piece يصطدم بقنبلة';
  }

  @override
  String get goFightFlag => 'تم الاستيلاء على العلم!';

  @override
  String get goMoveSetup => 'يرتّب الجيش';

  @override
  String goMoveStep(String from, String to) {
    return 'يتحرك $from–$to';
  }

  @override
  String goMoveAttack(String from, String to, String result) {
    return 'يهاجم ($from–$to): $result';
  }

  @override
  String goCellLabel(String cell, String content) {
    return '$cell: $content';
  }

  @override
  String get goCellFree => 'فارغ';

  @override
  String get goCellLake => 'بحيرة';

  @override
  String goCellHidden(String player) {
    return 'قطعة مخفية لـ$player';
  }

  @override
  String goCellPiece(String piece, String player) {
    return '$piece لـ$player';
  }

  @override
  String goCellMoved(String content) {
    return '$content، تحرّكت';
  }

  @override
  String gameNotInApp(String game) {
    return '$game غير متاح في التطبيق بعد.';
  }

  @override
  String get engineSetA => 'سيارات فائقة';

  @override
  String get engineSetB => 'سيارات خارقة';

  @override
  String get engineSetC => 'كلاسيكيات';

  @override
  String get engineSetD => 'سيارات العضلات';

  @override
  String get engineSetE => 'أساطير الرالي';

  @override
  String get engineSetF => 'سيارات جي تي';

  @override
  String get engineSetG => 'كهربائية';

  @override
  String get engineSetH => 'صواريخ صغيرة';

  @override
  String get engineStatPs => 'القدرة';

  @override
  String get engineStatKmh => 'السرعة القصوى';

  @override
  String get engineStatCcm => 'سعة المحرك';

  @override
  String get engineStatKg => 'الوزن';

  @override
  String get engineStatSec0to100 => '0–100 km/h';

  @override
  String get engineUnitPs => 'حصان';

  @override
  String get engineUnitKmh => 'km/h';

  @override
  String get engineUnitCcm => 'cm³';

  @override
  String get engineUnitKg => 'kg';

  @override
  String get engineUnitSec => 's';

  @override
  String get engineShip5 => 'بارجة';

  @override
  String get engineShip4 => 'طرّاد';

  @override
  String get engineShip3 => 'مدمّرة';

  @override
  String get engineShip2 => 'غوّاصة';

  @override
  String get engineShipOther => 'سفينة';

  @override
  String get roomStartIntro =>
      'يضغط الآخرون على «انضم إلى غرفة» ويُدخلون رمز الغرفة.';

  @override
  String get relayRoomCode => 'رمز الغرفة';

  @override
  String get relayWaitingHint =>
      'يضغط الآخرون على «انضم إلى غرفة» ويمسحون رمز QR أو يُدخلون رمز الغرفة. أو يفتحون الرابط.';

  @override
  String relayInfo(String address) {
    return 'الخادم: $address';
  }

  @override
  String get roomCodeHelper => '5 رموز – يعرض الجهاز الآخر الرمز مع غرفته.';

  @override
  String get relayCodeInvalid =>
      'رمز غرفة غير صالح: 5 أحرف أو أرقام (بدون 0 وO و1 وI وL).';

  @override
  String get roomJoin => 'انضم إلى غرفة';

  @override
  String relayJoining(String code) {
    return 'جارٍ الانضمام إلى الغرفة $code…';
  }

  @override
  String get relayAddressLabel => 'الخادم';

  @override
  String get relayAddressHelper =>
      'عنوان الخادم، مثلًا 192.168.1.20:4749 (في شبكة Wi-Fi) أو wss://spiele.example (على الإنترنت)';

  @override
  String get relayAddressInvalid =>
      'عنوان خادم غير صالح. مثال: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'لا توجد غرفة بالرمز $code. هل الرمز صحيح، وهل ما زالت الغرفة مفتوحة؟';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'الغرفة $code ممتلئة: يلعب فيها اثنان بالفعل.';
  }

  @override
  String relayErrorHostAway(String code) {
    return 'الجهاز الذي فتح الغرفة $code غير متاح الآن. حاول مرة أخرى بعد لحظة.';
  }

  @override
  String get relayErrorRoomClosed =>
      'أُغلقت الغرفة: غادر من فتحها. انتهت اللعبة.';

  @override
  String get relayErrorExpired => 'انتهت صلاحية الغرفة (10 دقائق دون نشاط).';

  @override
  String relayErrorUnreachable(String address) {
    return 'لا يوجد خادم متاح على $address.';
  }

  @override
  String get relayErrorLost => 'انقطع الاتصال بالخادم.';

  @override
  String get relayStartHint =>
      'تحتاج الغرف ذات الرمز إلى خادم. شغّله على حاسوب في شبكة Wi-Fi وافتح Klunki من عنوانه:';

  @override
  String relayRoomLost(String reason) {
    return '$reason افتح غرفة جديدة.';
  }

  @override
  String relayFromLink(String address) {
    return 'الخادم من الرابط: $address';
  }

  @override
  String get relayLinkSaveDefault => 'حفظ كافتراضي';

  @override
  String get relayLinkUseSaved => 'استخدام الخادم المحفوظ';

  @override
  String get relayLinkForeign =>
      'تنبيه: هذا الرابط يشير إلى خادم آخر، وليس إلى خادم هذه الصفحة. انضم فقط إذا كنت تثق بالمرسل: الخادم الغريب يرى كل النقلات.';

  @override
  String get pairingSeatTaken =>
      'المقعد مشغول: هناك من يلعب هذه المباراة بالفعل. يمكن فقط لمن انضم أولاً أن يعود.';

  @override
  String get qrScanButton => 'مسح رمز QR';

  @override
  String get qrScanHint => 'وجّه الكاميرا نحو رمز QR على الجهاز الآخر.';

  @override
  String get qrScanNotKlunki =>
      'هذا ليس رمز Klunki. امسح رمز QR الذي يعرضه الجهاز الآخر مع غرفته.';

  @override
  String get qrScanTorchOn => 'تشغيل الضوء';

  @override
  String get qrScanTorchOff => 'إطفاء الضوء';

  @override
  String get qrScanPermissionDenied => 'لا يُسمح لـ Klunki باستخدام الكاميرا.';

  @override
  String get qrScanPermissionHint =>
      'يمكنك السماح لـ Klunki بالوصول إلى الكاميرا من إعدادات الجهاز.';

  @override
  String get qrScanUnavailable => 'الكاميرا غير متاحة.';

  @override
  String get qrScanTypeInstead => 'اكتب الرمز';

  @override
  String get relayChange => 'تغيير';

  @override
  String get relayNotSet => 'لم يُضبط خادم – أدخل عنوانًا';

  @override
  String relayUseDefault(String address) {
    return 'الافتراضي: $address';
  }

  @override
  String get relaySave => 'تطبيق';

  @override
  String get relayClubCodeLabel => 'رمز النادي';

  @override
  String get relayClubCodeHelper =>
      'يُحفظ لهذا الخادم فقط. لا يوضع رمز النادي أبدًا في روابط الغرف أو رموز QR.';

  @override
  String get relayErrorClubMissing =>
      'هذا الخادم يحتاج إلى رمز النادي. اسأل من يدير الخادم.';

  @override
  String get relayErrorClubWrong =>
      'هذا الخادم لا يعرف رمز النادي هذا. اسأل من يدير الخادم.';

  @override
  String get serverKindLan =>
      'خادم في شبكة Wi-Fi (حاسوب يعمل عليه «klunki relay»)';

  @override
  String get serverKindInternet => 'خادم على الإنترنت';

  @override
  String get serverHelpLink => 'كيف يعمل هذا؟';

  @override
  String get serverClubCodeRemove => 'إزالة رمز النادي';

  @override
  String get serverClubCodeRetry => 'المحاولة برمز النادي';

  @override
  String get helpTitle => 'كيف تلعبون معًا';

  @override
  String get helpSectionRoomsTitle => 'اللعب مع الآخرين';

  @override
  String get helpSectionRoomsBody =>
      'يضغط شخص على «افتح غرفة» ويختار لعبة. يعرض Klunki عندها رمز غرفة ورمز QR.\n\nيضغط الشخص الآخر على «انضم إلى غرفة» ويمسح رمز QR أو يكتب رمز الغرفة. وتبدأ اللعبة.';

  @override
  String get helpSectionWifiTitle => 'على شبكة Wi-Fi نفسها';

  @override
  String get helpSectionWifiBody =>
      'هل لدى أحدكم التطبيق؟ إذن لا تحتاجون إلى خادم في شبكة Wi-Fi: التطبيق نفسه هو الخادم، حتى للاعبين في المتصفح (رمز QR).\n\nالأجهزة على شبكة Wi-Fi نفسها تجد بعضها تلقائيًا.';

  @override
  String get helpSectionServerTitle => 'متى تحتاجون إلى خادم؟';

  @override
  String get helpSectionServerBody =>
      'فقط إذا كان الجميع يلعبون في المتصفح أو إذا لم تكونوا على شبكة Wi-Fi نفسها. ينقل الخادم النقلات بين أجهزتكم.\n\nيعرف Klunki من العنوان نوع الخادم: «خادم في شبكة Wi-Fi» أو «خادم على الإنترنت».';

  @override
  String get helpSectionOwnServerTitle => 'خادم خاص بكم في شبكة Wi-Fi';

  @override
  String get helpSectionOwnServerBody =>
      'يمكنكم أيضًا تشغيل خادم خاص بكم على حاسوب في شبكة Wi-Fi. برنامج جاهز لـ Mac وWindows وLinux قيد التحضير. بعد ذلك أدخلوا عنوانه في Klunki في «متقدم» عبر «تغيير».';

  @override
  String get helpSectionComingTitle => 'قريبًا أسهل (قيد التحضير)';

  @override
  String get helpSectionComingBody =>
      'هذه الطرق للحصول على خادم قيد التحضير:\n• خادم على الإنترنت لمجموعات الأصدقاء (مع Cloudflare، مجانًا)\n• برنامج جاهز للتنزيل لأجهزة Mac وWindows وLinux\n• Docker لأجهزة NAS أو Raspberry Pi\n\nالخوادم على الإنترنت محمية غالبًا برمز النادي.';

  @override
  String get helpSectionClubTitle => 'ما هو رمز النادي؟';

  @override
  String get helpSectionClubBody =>
      'رمز النادي مثل مفتاح للخادم: فقط من يعرفه يمكنه فتح الغرف أو الانضمام إليها هناك. تحصل عليه من الشخص الذي يدير الخادم.\n\nلا يطلبه Klunki إلا عندما يحتاج إليه خادم، ويتذكره لهذا الخادم.';

  @override
  String get helpSectionDataTitle => 'ماذا يحدث لبياناتي؟';

  @override
  String get helpSectionDataBody =>
      'الخادم ينقل النقلات فقط ولا يحفظ منها شيئًا بشكل دائم. إذا لعبتم مباشرة على شبكة Wi-Fi نفسها، فلا يمر شيء عبر خادم غريب.\n\nيبقى رمز النادي على جهازك ولا يوضع أبدًا في روابط الغرف أو رموز QR. يمكنك رؤيته أو تغييره أو إزالته عبر «تغيير» بجانب الخادم.';

  @override
  String get joinDirectTitle => 'الاتصال مباشرة بجهاز';

  @override
  String get joinDirectHelper =>
      'لجهاز تعمل عليه الغرفة مباشرة (تطبيق أو طرفية): أدخل عنوانه (IP).';

  @override
  String get shellResign => 'استسلام';

  @override
  String get shellResignTitle => 'هل تريد الاستسلام حقًا؟';

  @override
  String shellResignBody(String player) {
    return 'تنتهي اللعبة للطرفين، ويفوز $player.';
  }

  @override
  String get shellLeaveTitle => 'مغادرة اللعبة؟';

  @override
  String get shellLeaveBody => 'سينقطع الاتصال وتنتهي اللعبة للطرفين.';

  @override
  String get shellLeave => 'مغادرة';

  @override
  String get shellResignWho =>
      'من يستسلم؟ تنتهي اللعبة الآن ويفوز الطرف الآخر.';

  @override
  String shellResignPlayer(String player) {
    return 'استسلام $player';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return 'استسلام $player';
  }

  @override
  String get engineReasonCommonYouResigned => 'لقد استسلمت';

  @override
  String get quartettDeckCars => 'سيارات';

  @override
  String get quartettDeckTrains => 'قطارات';

  @override
  String get quartettDeckRockets => 'صواريخ';

  @override
  String get quartettDeckPlanes => 'طائرات';

  @override
  String get quartettSetTrainsA => 'ICE';

  @override
  String get quartettSetTrainsB => 'شينكانسن';

  @override
  String get quartettSetTrainsC => 'TGV';

  @override
  String get quartettSetTrainsD => 'سريعات أوروبا';

  @override
  String get quartettSetTrainsE => 'آسيا وأمريكا';

  @override
  String get quartettSetTrainsF => 'قاطرات كهربائية';

  @override
  String get quartettSetTrainsG => 'أساطير البخار';

  @override
  String get quartettSetTrainsH => 'عمالقة الشحن';

  @override
  String get quartettSetRocketsA => 'صواريخ القمر';

  @override
  String get quartettSetRocketsB => 'قابلة لإعادة الاستخدام';

  @override
  String get quartettSetRocketsC => 'أوروبا';

  @override
  String get quartettSetRocketsD => 'كلاسيكيات أمريكية';

  @override
  String get quartettSetRocketsE => 'روسيا';

  @override
  String get quartettSetRocketsF => 'الصين';

  @override
  String get quartettSetRocketsG => 'اليابان والهند';

  @override
  String get quartettSetRocketsH => 'صواريخ إطلاق صغيرة';

  @override
  String get quartettSetPlanesA => 'طائرات عريضة البدن';

  @override
  String get quartettSetPlanesB => 'المدى المتوسط';

  @override
  String get quartettSetPlanesC => 'فوق صوتية';

  @override
  String get quartettSetPlanesD => 'كلاسيكيات المراوح';

  @override
  String get quartettSetPlanesE => 'عمالقة الشحن الجوي';

  @override
  String get quartettSetPlanesF => 'الأعمال والرياضة';

  @override
  String get quartettSetPlanesG => 'الرواد';

  @override
  String get quartettSetPlanesH => 'غرائب الأرقام القياسية';

  @override
  String get quartettStatKw => 'القدرة';

  @override
  String get quartettStatLengthM => 'الطول';

  @override
  String get quartettStatMassT => 'الوزن';

  @override
  String get quartettStatTractiveKn => 'قوة الجر';

  @override
  String get quartettStatHeightM => 'الارتفاع';

  @override
  String get quartettStatThrustKn => 'قوة الدفع عند الإقلاع';

  @override
  String get quartettStatLeoT => 'الحمولة (LEO)';

  @override
  String get quartettStatLaunchMassT => 'كتلة الإطلاق';

  @override
  String get quartettStatFlights => 'عمليات الإطلاق';

  @override
  String get quartettStatRangeKm => 'المدى';

  @override
  String get quartettStatWingspanM => 'باع الجناحين';

  @override
  String get quartettStatMtowT => 'وزن الإقلاع';

  @override
  String get quartettDeckPickerTitle => 'اختر مجموعة البطاقات';

  @override
  String get quartettDeckLabel => 'مجموعة البطاقات';

  @override
  String quartettDeckSets(int sets) {
    return '$sets مجموعات من 4 بطاقات';
  }

  @override
  String get quartettDeckPlay => 'العب';

  @override
  String get quartettGalleryOpen => 'تصفح البطاقات';

  @override
  String get quartettGalleryTitle => 'بطاقات الرباعيات';

  @override
  String quartettGalleryCardOf(int index, int total) {
    return 'البطاقة $index من $total';
  }

  @override
  String get quartettGalleryPrevious => 'البطاقة السابقة';

  @override
  String get quartettGalleryNext => 'البطاقة التالية';

  @override
  String get quartettGalleryTopMenu => 'أفضل 5 حسب القيمة';

  @override
  String quartettGalleryTopTitle(String stat) {
    return 'أفضل 5: $stat';
  }

  @override
  String quartettCardSemantics(String id, String name, String set) {
    return 'البطاقة $id: $name، مجموعة $set';
  }

  @override
  String get quartettStatBuilt => 'عدد المصنوع';

  @override
  String get quartettStatSuccessPct => 'نسبة النجاح';

  @override
  String get quartettUnitBuilt => 'وحدة';

  @override
  String quartettPhotoCredit(String author, String license) {
    return 'صورة: $author، $license';
  }

  @override
  String get quartettPhotoCreditTitle => 'مصدر الصورة';

  @override
  String get quartettPhotoCreditTooltip => 'عرض مصدر الصورة';

  @override
  String get quartettPhotoModified => 'تم تصغيرها للتطبيق.';

  @override
  String get quartettPhotoShareAlike => 'النسخة المصغرة تخضع للترخيص نفسه.';

  @override
  String get quartettPhotoLicense => 'الترخيص';

  @override
  String get quartettPhotoSource => 'المصدر';

  @override
  String get quartettPhotoClose => 'إغلاق';

  @override
  String get quartettWikipediaRead => 'اقرأ على ويكيبيديا';

  @override
  String get quartettImageCreditsTitle => 'مصادر الصور';

  @override
  String get quartettImageCreditsIntro =>
      'الصور مأخوذة من ويكيميديا كومنز وتخضع لتراخيص حرة. وهي مضمنة في التطبيق؛ الروابط فقط تحتاج إلى الإنترنت.';

  @override
  String get quartettLinkFailed => 'تعذر فتح الرابط.';

  @override
  String relayLoopbackHint(String host, String example, String mdnsExample) {
    return 'ملاحظة: لا تستطيع الأجهزة الأخرى الوصول إلى «$host». افتح الصفحة عبر عنوان الواي فاي لهذا الحاسوب (مثلًا $example) أو اسمه .local (مثلًا $mdnsExample) حتى يعمل الرابط ورمز QR على الأجهزة الأخرى.';
  }

  @override
  String relayLoopbackShort(String host) {
    return '«$host» يعمل على هذا الجهاز فقط – تحتاج الأجهزة الأخرى إلى عنوان الواي فاي أو اسم .local لهذا الحاسوب.';
  }

  @override
  String get loopbackHowTitle => 'كيف أجد العنوان؟';

  @override
  String get loopbackHowMacSettings =>
      'إعدادات النظام › Wi-Fi › التفاصيل… › عنوان IP. أو في الطرفية:';

  @override
  String get loopbackHowMacMdns =>
      'اسم .local موجود في إعدادات النظام › عام › المشاركة («اسم المضيف المحلي»).';

  @override
  String get loopbackHowWindowsSettings =>
      'الإعدادات › الشبكة والإنترنت › Wi-Fi › الخصائص (عنوان IPv4). أو في موجه الأوامر (cmd)، «عنوان IPv4» لمحول Wi-Fi:';

  @override
  String get loopbackHowWindowsMdns =>
      'في Windows 10/11 يكون اسم .local هو <اسم الحاسوب>.local.';

  @override
  String get loopbackHowLinuxTerminal => 'في الطرفية:';

  @override
  String get loopbackHowLinuxSettings =>
      'أو الإعدادات › الشبكة › Wi-Fi › التفاصيل. اسم .local هو <اسم المضيف>.local إذا كان Avahi يعمل.';

  @override
  String loopbackHowRelay(String command) {
    return 'تلميح: تعرض وحدة تحكم «$command» هذه العناوين عند البدء.';
  }

  @override
  String get loopbackHowCopy => 'نسخ الأمر';

  @override
  String get loopbackHowCopied => 'تم نسخ الأمر';

  @override
  String get goSetupInvalid => 'صفوفك الأربعة في الأسفل فقط تقبل القطع.';

  @override
  String get versionMismatchBoth =>
      'إصدارات اللعبة غير متوافقة – يُرجى تحديث التطبيقين (المتصفح: أعد تحميل الصفحة).';

  @override
  String get versionMismatchUpdateOther =>
      'إصدارات اللعبة غير متوافقة: الجهاز الآخر يستخدم إصدارًا أقدم. يُرجى تحديث التطبيق عليه (المتصفح: أعد تحميل الصفحة).';

  @override
  String get versionMismatchUpdateThis =>
      'إصدارات اللعبة غير متوافقة: هذا الجهاز يستخدم إصدارًا أقدم. يُرجى تحديث هذا التطبيق (المتصفح: أعد تحميل الصفحة).';

  @override
  String versionMismatchGuestRefused(String reason) {
    return 'حاول جهاز الانضمام لكنه رُفض: $reason';
  }

  @override
  String menuVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String aboutBuildDetails(String build, String protocol, String games) {
    return 'رقم البناء $build · البروتوكول $protocol · بيانات اللعب $games';
  }

  @override
  String versionMismatchVersions(
    String nameA,
    String versionA,
    String nameB,
    String versionB,
  ) {
    return 'إصدار $nameA: $versionA، إصدار $nameB: $versionB.';
  }

  @override
  String versionMismatchVersionsDevices(String versionA, String versionB) {
    return 'إصدار هذا الجهاز: $versionA، إصدار الجهاز الآخر: $versionB.';
  }

  @override
  String get aboutTitle => 'حول Klunki';

  @override
  String get aboutPrivacy => 'الخصوصية';

  @override
  String get aboutImpressum => 'البيانات القانونية (Impressum)';

  @override
  String get aboutSupport => 'الدعم';

  @override
  String get aboutLicense => 'Klunki برنامج حر مرخّص بموجب GNU AGPL 3.0.';

  @override
  String get aboutSourceCode => 'الشيفرة المصدرية';

  @override
  String get aboutLicenses => 'تراخيص المصادر المفتوحة';

  @override
  String get aboutOpenInBrowser => 'فتح في المتصفح';

  @override
  String get aboutPrivacyOffline =>
      'هذه النسخة (بالإنجليزية) محفوظة في التطبيق لتقرأها دون إنترنت. المرجع هو الصفحة على الويب:';

  @override
  String get menuGameChess => 'شطرنج';

  @override
  String get menuDescChess => 'اللعبة الكلاسيكية: أوقِع ملك الخصم في كش مات.';

  @override
  String get chessWhite => 'الأبيض';

  @override
  String get chessBlack => 'الأسود';

  @override
  String get chessColorLabel => 'لونك';

  @override
  String get chessColorRandom => 'عشوائي';

  @override
  String get chessColorHelper => 'الأبيض يبدأ. مع «عشوائي» تقرّر القرعة.';

  @override
  String get chessYouPlayWhite => 'أنت تلعب بالأبيض.';

  @override
  String get chessYouPlayBlack => 'أنت تلعب بالأسود.';

  @override
  String get chessCheck => 'كش ملك!';

  @override
  String get chessHintSelect => 'المس قطعة لتحريكها.';

  @override
  String get chessHintTarget => 'المس مربعًا مُعلَّمًا.';

  @override
  String get chessPromotionTitle => 'ترقية البيدق إلى …';

  @override
  String get chessFlipBoard => 'اقلب الرقعة';

  @override
  String get chessAutoFlip => 'أدِر الرقعة نحو الطرف الذي عليه الدور';

  @override
  String chessSquareEmpty(String square) {
    return '$square: فارغ';
  }

  @override
  String chessSquarePiece(String square, String piece, String side) {
    return '$square: $piece ($side)';
  }

  @override
  String get chessPieceKing => 'ملك';

  @override
  String get chessPieceQueen => 'وزير';

  @override
  String get chessPieceRook => 'رخ';

  @override
  String get chessPieceBishop => 'فيل';

  @override
  String get chessPieceKnight => 'حصان';

  @override
  String get chessPiecePawn => 'بيدق';

  @override
  String get chessOfferDraw => 'عرض التعادل';

  @override
  String get chessOfferDrawTitle => 'عرض التعادل؟';

  @override
  String chessOfferDrawBody(String player) {
    return 'القرار عند $player: القبول أو الرفض. عند القبول تنتهي اللعبة بالتعادل.';
  }

  @override
  String get chessOfferDrawConfirm => 'اعرض';

  @override
  String get chessDrawOfferTitle => 'عرض تعادل';

  @override
  String chessDrawOfferBody(String player) {
    return 'عرض تعادل من $player. عند القبول تنتهي اللعبة بالتعادل.';
  }

  @override
  String get chessDrawAccept => 'قبول';

  @override
  String get chessDrawDecline => 'رفض';

  @override
  String chessHintDrawOffered(String player) {
    return 'تم عرض التعادل، والقرار عند $player.';
  }

  @override
  String chessHintDrawDeclined(String player) {
    return 'التعادل مرفوض من $player.';
  }

  @override
  String get chessMoveDrawOffer => 'عرض التعادل';

  @override
  String get chessMoveDrawDecline => 'رفض التعادل';

  @override
  String get chessMoveDrawAccept => 'قبول التعادل';

  @override
  String get engineReasonChessDrawAgreed => 'تعادل بالاتفاق';

  @override
  String get engineReasonChessCheckmate => 'كش مات';

  @override
  String get engineReasonChessStalemate => 'تعادل بالجمود';

  @override
  String get engineReasonChessInsufficientMaterial => 'قطع غير كافية للكش مات';

  @override
  String engineReasonChessSeventyFiveMoves(int moves) {
    return '$moves نقلة دون أسر أو تحريك بيدق';
  }

  @override
  String engineReasonChessThreefoldRepetition(int times) {
    return 'تكرار الوضع نفسه $times مرات';
  }

  @override
  String get menuGameWordTiles => 'فصاحة';

  @override
  String get menuDescWordTiles => 'كوّن كلمات من الحروف';

  @override
  String menuPreviewGame(String game) {
    return 'معاينة: $game';
  }

  @override
  String get wordtilesPlay => 'العب';

  @override
  String get wordtilesRecall => 'استرجاع كل البلاطات';

  @override
  String get wordtilesShuffle => 'خلط البلاطات';

  @override
  String get wordtilesExchange => 'تبديل';

  @override
  String wordtilesExchangeConfirm(int count) {
    return 'تبديل $count';
  }

  @override
  String get wordtilesPass => 'تمرير';

  @override
  String get wordtilesZoomIn => 'تكبير';

  @override
  String get wordtilesZoomOut => 'اللوحة كاملة';

  @override
  String wordtilesBag(int count) {
    return 'الكيس: $count بلاطة';
  }

  @override
  String wordtilesScore(String player, int score) {
    return '$player: $score نقطة';
  }

  @override
  String get wordtilesHintPlace =>
      'اسحب البلاطات إلى اللوحة، أو المس بلاطة ثم خانة.';

  @override
  String get wordtilesHintFirst => 'يجب أن تمر الكلمة الأولى بالنجمة في الوسط.';

  @override
  String wordtilesHintZoom(String hint) {
    return '$hint بإصبعين تكبّر اللوحة وتصغّرها.';
  }

  @override
  String get wordtilesHintSelected => 'المس خانة فارغة.';

  @override
  String get wordtilesHintExchange => 'اختر البلاطات التي تعود إلى الكيس.';

  @override
  String get wordtilesHintAnswer => 'اقبل الكلمة أو اعترض عليها.';

  @override
  String wordtilesExchangeNotNow(int count) {
    return 'التبديل ممكن فقط ما دام في الكيس $count بلاطات على الأقل.';
  }

  @override
  String wordtilesPreview(String words, int score) {
    return '$words: $score نقطة';
  }

  @override
  String wordtilesPreviewBingo(String words, int score, int bonus) {
    return '$words: $score نقطة (منها $bonus مكافأة لكل البلاطات)';
  }

  @override
  String get wordtilesErrorLine =>
      'يجب أن تكون البلاطات في صف واحد أو عمود واحد.';

  @override
  String get wordtilesErrorGap => 'توجد خانة فارغة بين البلاطات.';

  @override
  String get wordtilesErrorShort => 'تحتاج الكلمة الأولى إلى حرفين على الأقل.';

  @override
  String get wordtilesErrorConnect => 'يجب أن تتصل البلاطات بكلمة على اللوحة.';

  @override
  String get wordtilesErrorUnknownWord => 'إحدى الكلمات ليست في القاموس.';

  @override
  String get wordtilesErrorAnswerFirst =>
      'اقبل الكلمة الأخيرة أو اعترض عليها أولاً.';

  @override
  String get wordtilesErrorOther => 'لا يمكنك وضع البلاطات هكذا.';

  @override
  String wordtilesOpenPlacement(String player, String words, int score) {
    return 'من $player: $words مقابل $score نقطة.';
  }

  @override
  String get wordtilesAccept => 'قبول';

  @override
  String get wordtilesChallenge => 'اعتراض';

  @override
  String get wordtilesChallengeTitle => 'الاعتراض على الكلمة؟';

  @override
  String wordtilesChallengeBodyFree(String player) {
    return 'بدون قاموس يُحسم الأمر برأيك: تعود البلاطات إلى $player بلا نقاط. ثم يأتي دورك.';
  }

  @override
  String get wordtilesChallengeBodyDict =>
      'القاموس يحسم. إذا كانت الكلمة فيه، تخسر دورك.';

  @override
  String wordtilesEndPending(String player) {
    return 'لم تبقَ بلاطات لدى $player. إذا قبلت، تنتهي اللعبة.';
  }

  @override
  String wordtilesMovePlace(String words, int score) {
    return '$words مقابل $score نقطة';
  }

  @override
  String wordtilesMoveExchange(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بُدّلت $count بلاطة',
      many: 'بُدّلت $count بلاطة',
      few: 'بُدّلت $count بلاطات',
      two: 'بُدّلت بلاطتان',
      one: 'بُدّلت بلاطة واحدة',
      zero: 'لم تُبدَّل بلاطات',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesMovePass => 'مرّر الدور';

  @override
  String wordtilesMoveChallengeWithdrawn(String words) {
    return 'اعتراض: سُحبت $words';
  }

  @override
  String get wordtilesMoveChallengeFailed => 'اعتراض، لكن الكلمات صحيحة';

  @override
  String get wordtilesMoveAccept => 'قَبِل';

  @override
  String get wordtilesBlankTitle => 'أي حرف تمثّل البلاطة الفارغة؟';

  @override
  String get wordtilesPremiumDoubleLetter => 'ح×2';

  @override
  String get wordtilesPremiumTripleLetter => 'ح×3';

  @override
  String get wordtilesPremiumDoubleWord => 'ك×2';

  @override
  String get wordtilesPremiumTripleWord => 'ك×3';

  @override
  String get wordtilesOptionTiles => 'الحروف';

  @override
  String get wordtilesOptionDictionary => 'التحقق من القاموس';

  @override
  String get wordtilesOptionDictionaryOn =>
      'يُبحث عن كل كلمة توضع. إن لم تكن في القاموس تقرّرون معًا: سحبها أو قبولها رغم ذلك.';

  @override
  String get wordtilesOptionDictionaryOff =>
      'بدون قاموس تحكمون بأنفسكم: يمكن الاعتراض على كلمة.';

  @override
  String get wordtilesOptionsNext => 'التالي';

  @override
  String get wordtilesDictLoading => 'جارٍ تحميل القاموس…';

  @override
  String get wordtilesDictLoadFailed => 'تعذّر تحميل القاموس.';

  @override
  String get wordtilesUnknownTitle => 'ليست في القاموس';

  @override
  String wordtilesUnknownBody(String words, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '«$words» ليست في القاموس.',
    );
    return '$_temp0';
  }

  @override
  String get wordtilesUnknownAsk =>
      'يمكنكم سحب الحروف. إن اتفقتم على أنها تُحسب رغم ذلك فاقبلوها.';

  @override
  String get wordtilesUnknownWithdraw => 'سحب';

  @override
  String get wordtilesUnknownAllow => 'اقبل رغم ذلك';

  @override
  String wordtilesMovePlaceAllowed(String words, int score, String allowed) {
    return '$words مقابل $score نقطة (مقبولة: $allowed)';
  }

  @override
  String get wordtilesBench => 'مقعد التجربة';

  @override
  String get wordtilesBenchClear => 'إعادة كل الحروف من المقعد';

  @override
  String get wordtilesBenchHint => 'اسحب الحروف إلى هنا لتجرّب كلمات.';

  @override
  String get wordtilesCoachBench1 =>
      'مقعد التجربة مثل ورقة ملاحظات: اسحب الحروف إلى هنا وجرّب كلمات.';

  @override
  String get wordtilesCoachBench2 =>
      'يجمع نقاط الحروف فقط، ولا يتحقق إن كانت الكلمة صحيحة.';

  @override
  String get wordtilesCoachBench3 =>
      'بهذا الزر تعود كل الحروف. لا أحد غيرك يرى مقعدك.';

  @override
  String wordtilesCoachStep(int step, int count) {
    return '$step من $count';
  }

  @override
  String get wordtilesCoachNext => 'التالي';

  @override
  String get wordtilesCoachDone => 'فهمت';

  @override
  String get wordtilesCoachSkip => 'تخطي';

  @override
  String get wordtilesPassTitle => 'تمرير الدور؟';

  @override
  String wordtilesPassBody(int count, int limit) {
    return 'ينتهي دورك بلا نقاط. أدوار متتالية بلا نقاط: $count من $limit. عند $limit تنتهي اللعبة.';
  }

  @override
  String get wordtilesBlankScore => 'البلاطة الفارغة تساوي 0 نقاط.';

  @override
  String get wordtilesHelpGoal =>
      'ضعوا كلمات كما في الكلمات المتقاطعة. لكل حرف نقاط (الرقم الصغير). تمرّ الكلمة الأولى على النجمة في الوسط، وكل كلمة بعدها تتصل بما على اللوح.';

  @override
  String get wordtilesHelpPremium => 'مربعات المكافأة';

  @override
  String get wordtilesHelpDoubleLetter => 'الحرف يُحسب مرتين';

  @override
  String get wordtilesHelpTripleLetter => 'الحرف يُحسب ثلاث مرات';

  @override
  String get wordtilesHelpDoubleWord => 'الكلمة كلها تُحسب مرتين';

  @override
  String get wordtilesHelpTripleWord => 'الكلمة كلها تُحسب ثلاث مرات';

  @override
  String get wordtilesHelpPremiumOnce =>
      'تُحسب مربعات المكافأة فقط في الدور الذي يوضع فيه حرف عليها.';

  @override
  String wordtilesHelpBingo(int count, int bonus) {
    return 'وضع الحروف الـ$count كلها في دور واحد: $bonus نقطة إضافية.';
  }

  @override
  String get wordtilesHelpBlank =>
      'البلاطة الفارغة تصير أي حرف تختاره لكنها تساوي 0 نقاط. يظهر عليها 0 صغير.';

  @override
  String wordtilesHelpSwap(int count) {
    return 'التبديل: أعد حروفًا إلى الكيس واسحب غيرها. ممكن فقط ما دام في الكيس $count حروف على الأقل، ويستهلك الدور.';
  }

  @override
  String wordtilesHelpPass(int limit) {
    return 'التمرير: تتخطى دورًا. بعد $limit أدوار متتالية بلا نقاط تنتهي اللعبة.';
  }

  @override
  String get wordtilesHelpDictionary =>
      'مع «التحقق من القاموس» يُبحث عن كل كلمة عند وضعها. إن لم تكن فيه، اسحبوا الحروف أو اقبلوها معًا: «اقبل رغم ذلك». تظهر الكلمات المقبولة في السجل.';

  @override
  String get wordtilesHelpChallenge =>
      'بدون قاموس يمكن الاعتراض على الكلمة الأخيرة: تُسحب الحروف ولا تُحسب نقاط.';

  @override
  String get wordtilesHelpBench =>
      'على مقعد التجربة تجرّب الكلمات. يعرض نقاط الحروف فقط، لا إن كانت كلمة.';

  @override
  String get wordtilesHelpZoom =>
      'بإصبعين تكبّر اللوحة وتصغّرها وتحرّكها. لنقل بلاطة وضعتها للتو، اسحبها مباشرة؛ لمسة واحدة تعيدها.';

  @override
  String get wordtilesHelpEnd =>
      'تنتهي اللعبة حين يفرغ الكيس ويضع أحدهم كل حروفه. تُطرح نقاط الحروف الباقية، ومن أنهى يحصل عليها.';

  @override
  String get wordtilesHelpEndNoRest =>
      'تنتهي اللعبة حين يفرغ الكيس ويضع أحدهم كل حروفه. لا تُحتسب الحروف الباقية.';

  @override
  String wordtilesResultRack(String points) {
    return 'الحروف الباقية: $points';
  }

  @override
  String wordtilesResultBestWord(String word, String player, int score) {
    return 'أفضل كلمة: $word ($player، $score نقطة)';
  }

  @override
  String wordtilesResultAllowed(String words) {
    return 'قُبلت رغم ذلك: $words';
  }

  @override
  String engineReasonWordtilesPlayedOut(int a, int b) {
    return 'وُضعت كل البلاطات، النتيجة النهائية $a : $b';
  }

  @override
  String engineReasonWordtilesScoreless(int turns, int a, int b) {
    return '$turns أدوار بلا نقاط، النتيجة النهائية $a : $b';
  }

  @override
  String get engineReasonWordtilesPlayedOutSeats => 'وُضعت كل البلاطات';

  @override
  String engineReasonWordtilesScorelessSeats(int turns) {
    return '$turns أدوار بلا نقاط';
  }

  @override
  String get webBetaBadge => 'تجريبي';

  @override
  String get aboutWebBeta =>
      'نسخة الويب التجريبية – اللعب على عدة أجهزة متاح في التطبيق.';

  @override
  String get networkUnavailableWeb =>
      'غير متاح في المتصفح بعد – مع التطبيق يمكن اللعب على عدة أجهزة.';

  @override
  String get appBetaTeaser => 'النسخة التجريبية من التطبيق قيد التحضير.';

  @override
  String get appBetaIos => 'تجربة التطبيق على iPhone وiPad';

  @override
  String get appBetaAndroid => 'تنزيل التطبيق على Android';

  @override
  String wordtilesOptionsSummaryDict(String language) {
    return '$language · مع التحقق من القاموس';
  }

  @override
  String wordtilesOptionsSummaryFree(String language) {
    return '$language · بدون قاموس';
  }

  @override
  String wordtilesOpenPlacementJoker(String player, String words, int score) {
    return 'من $player: $words مقابل $score نقطة (مع تبديل بلاطة فارغة).';
  }

  @override
  String get wordtilesOptionJoker => 'تبديل البلاطة الفارغة';

  @override
  String get wordtilesOptionJokerExplain =>
      'قاعدة بديلة: إن كان معك الحرف الذي تمثّله بلاطة فارغة على اللوحة، فضعه مكانها وخذ البلاطة الفارغة. بعد ذلك تضع بلاطات في الدور نفسه.';

  @override
  String get wordtilesOptionRest => 'خصم الحروف الباقية';

  @override
  String get wordtilesOptionRestExplain =>
      'قاعدة بديلة: في النهاية تُطرح نقاط الحروف الباقية عند كل لاعب، ومن وضع كل حروفه يحصل عليها. عند الإيقاف: تُحتسب الكلمات الموضوعة فقط.';

  @override
  String wordtilesOptionsSummaryJoker(String summary) {
    return '$summary · تبديل البلاطة الفارغة';
  }

  @override
  String wordtilesOptionsSummaryNoRest(String summary) {
    return '$summary · دون خصم الحروف الباقية';
  }

  @override
  String get wordtilesHintJoker =>
      'اسحب الحرف المطابق إلى بلاطة فارغة على اللوحة لتأخذ البلاطة الفارغة.';

  @override
  String get wordtilesJokerStaged =>
      'البلاطة الفارغة معك الآن. ضع بلاطات أيضًا، وإلا فلن يُحسب التبديل.';

  @override
  String wordtilesMoveJoker(String move) {
    return '$move (مع تبديل بلاطة فارغة)';
  }

  @override
  String wordtilesUnknownAskNet(String player) {
    return 'يمكنك سحب الحروف، أو طلب موافقة $player على احتسابها رغم ذلك.';
  }

  @override
  String wordtilesUnknownDeclinedBefore(String player) {
    return 'سبق الرفض من $player، لذا يجب سحب الحروف.';
  }

  @override
  String get wordtilesAllowTitle => 'قبول رغم ذلك؟';

  @override
  String wordtilesAllowBody(String player, String words) {
    return 'طلب من $player: قبول «$words» رغم ذلك. موافقة؟';
  }

  @override
  String get wordtilesAllowAccept => 'قبول';

  @override
  String get wordtilesAllowDecline => 'رفض';

  @override
  String wordtilesAllowDeciding(String player) {
    return 'القرار عند $player…';
  }

  @override
  String get wordtilesAllowYouDecide => 'القرار لك';

  @override
  String wordtilesAllowLine(String player, String words, int score) {
    return 'طلب من $player: قبول «$words» ($score نقطة).';
  }

  @override
  String wordtilesAllowDeclined(String player, String words) {
    return '«$words» مرفوضة من $player.';
  }

  @override
  String wordtilesMoveAllowRequest(String words, int score) {
    return 'طلب قبول $words ($score نقطة)';
  }

  @override
  String wordtilesMoveAllowAccept(String words, int score) {
    return 'موافقة: احتساب $words ($score نقطة)';
  }

  @override
  String wordtilesMoveAllowDecline(String words) {
    return 'رفض: $words';
  }

  @override
  String get menuGameMauMau => 'Mau-Mau';

  @override
  String get menuDescMauMau => 'ضع أوراقًا مطابقة حتى تنفد أوراقك';

  @override
  String get engineReasonMaumauEmptyHand => 'نفدت كل الأوراق';

  @override
  String get maumauSuitClubs => 'سباتي';

  @override
  String get maumauSuitSpades => 'بستوني';

  @override
  String get maumauSuitHearts => 'قلوب';

  @override
  String get maumauSuitDiamonds => 'ديناري';

  @override
  String get maumauRankJack => 'ولد';

  @override
  String get maumauRankQueen => 'بنت';

  @override
  String get maumauRankKing => 'شايب';

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
  String get maumauOptionsIntro => 'ما القواعد المطلوبة؟';

  @override
  String get maumauOptionsNext => 'التالي';

  @override
  String get maumauOptionSeven => '7: سحب ورقتين';

  @override
  String get maumauOptionSevenExplain => 'بعد الـ7 على الطرف الآخر سحب ورقتين.';

  @override
  String get maumauOptionStack => '7 فوق 7';

  @override
  String get maumauOptionStackExplain =>
      'من لديه 7 يضعها فوقها، وعندها على الطرف الآخر سحب 4 أوراق.';

  @override
  String get maumauOptionEight => '8: تخطي الدور';

  @override
  String get maumauOptionEightExplain => 'بعد الـ8 يُتخطّى دور الطرف الآخر.';

  @override
  String get maumauOptionJackInfo =>
      'الولد: يناسب كل ورقة تقريبًا، ومن يضعه يطلب شكلًا.';

  @override
  String get maumauOptionJackOnJack => 'ولد فوق ولد';

  @override
  String get maumauOptionJackOnJackExplain => 'يجوز وضع الولد فوق ولد آخر.';

  @override
  String get maumauOptionAce => 'آس: دور إضافي';

  @override
  String get maumauOptionAceExplain => 'من يضع الآس يلعب مرة أخرى فورًا.';

  @override
  String get maumauOptionMau => 'قول «Mau!»';

  @override
  String get maumauOptionMauExplain =>
      'مع الورقة قبل الأخيرة اضغط «Mau!» أولًا. من ينسَ يسحب ورقة عقوبة.';

  @override
  String maumauOpponentCards(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتان',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return '$player: $_temp0';
  }

  @override
  String maumauYourCards(int count) {
    return 'أوراقك ($count)';
  }

  @override
  String maumauStock(int count) {
    return 'الكومة: $count';
  }

  @override
  String maumauStockLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتان',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'كومة السحب، $_temp0';
  }

  @override
  String get maumauDiscard => 'الأوراق المرمية';

  @override
  String maumauWish(String suit) {
    return 'المطلوب: $suit';
  }

  @override
  String get maumauDraw => 'اسحب ورقة';

  @override
  String maumauDrawPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتين',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'اسحب $_temp0';
  }

  @override
  String get maumauKeep => 'احتفظ بها';

  @override
  String get maumauPass => 'مرّر';

  @override
  String get maumauMauButton => 'Mau!';

  @override
  String get maumauContinue => 'متابعة';

  @override
  String get maumauPickSuitTitle => 'أي شكل تطلب؟';

  @override
  String get maumauDrewNoFit => 'الورقة المسحوبة لا تناسب.';

  @override
  String maumauDrewPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتين',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'سحبت $_temp0. الجديدة في يدك:';
  }

  @override
  String get maumauHintPlay => 'ضع ورقة مطابقة أو اسحب ورقة.';

  @override
  String maumauHintWish(String suit) {
    return 'المطلوب: $suit. ضع ورقة منه أو اسحب ورقة.';
  }

  @override
  String maumauHintPenalty(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتين',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'عليك سحب $_temp0.';
  }

  @override
  String maumauHintPenaltyStack(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتين',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'ضع 7 أو اسحب $_temp0.';
  }

  @override
  String get maumauHintDrawn => 'الورقة المسحوبة مناسبة. ضعها أو احتفظ بها.';

  @override
  String get maumauHintPass => 'لا شيء للسحب. عليك التمرير.';

  @override
  String get maumauHintMau => 'الورقة قبل الأخيرة: اضغط «Mau!» أولًا ثم ضعها.';

  @override
  String maumauLastPlayed(String player, String card) {
    return 'ورقة $player: $card.';
  }

  @override
  String maumauLastPlayedWish(String player, String card, String suit) {
    return 'ورقة $player: $card، والمطلوب: $suit.';
  }

  @override
  String maumauLastDrew(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتان',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'سحب $player: $_temp0.';
  }

  @override
  String maumauLastDrewPenalty(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتان',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'عقوبة على $player: $_temp0.';
  }

  @override
  String maumauLastKept(String player) {
    return 'سحب $player: ورقة واحدة، مع الاحتفاظ بها.';
  }

  @override
  String maumauLastPassed(String player) {
    return 'تمرير من $player.';
  }

  @override
  String maumauExtraMau(String player) {
    return '«Mau!» من $player.';
  }

  @override
  String maumauExtraForgotMau(String player) {
    return 'نسيان «Mau!» من $player: ورقة عقوبة.';
  }

  @override
  String maumauExtraPenalty(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتين',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'على $player سحب $_temp0.';
  }

  @override
  String get coachNext => 'التالي';

  @override
  String get coachDone => 'لنبدأ!';

  @override
  String get coachSkip => 'تخطي';

  @override
  String get maumauCoachPlay =>
      'اضغط على ورقة مطابقة لتضعها. الأوراق المطابقة أعلى ولها إطار.';

  @override
  String get maumauCoachDraw =>
      'لا توجد ورقة مطابقة؟ اضغط على كومة السحب لتسحب ورقة.';

  @override
  String get maumauCoachWin => 'يفوز من يتخلص من كل أوراقه أولًا.';

  @override
  String get maumauCoachWinMau =>
      'يفوز من يتخلص من كل أوراقه أولًا. قبل الورقة قبل الأخيرة اضغط «Mau!».';

  @override
  String maumauChainBadge(String sum, int count) {
    return 'اسحب $sum = $count أوراق';
  }

  @override
  String maumauExtraPenaltyStacked(String player, int count) {
    return 'السبعات تتراكم: على $player الآن سحب $count أوراق.';
  }

  @override
  String maumauExtraAgain(String player) {
    return 'تخطي دور $player.';
  }

  @override
  String maumauExtraAce(String player) {
    return 'دور إضافي: $player.';
  }

  @override
  String get maumauExtraReshuffled =>
      'خُلطت الأوراق المرمية في كومة سحب جديدة.';

  @override
  String maumauMovePlay(String card) {
    return 'ورقة: $card';
  }

  @override
  String maumauMovePlayWish(String card, String suit) {
    return 'ورقة: $card، المطلوب: $suit';
  }

  @override
  String maumauMoveDraw(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ورقة',
      many: '$count ورقة',
      few: '$count أوراق',
      two: 'ورقتان',
      one: 'ورقة واحدة',
      zero: 'لا أوراق',
    );
    return 'سحب $_temp0';
  }

  @override
  String get maumauMovePass => 'تمرير';

  @override
  String get maumauMoveKeep => 'الاحتفاظ بالورقة المسحوبة';

  @override
  String get menuGameMaexchen => 'ميا';

  @override
  String get menuDescMaexchen => 'ارموا النرد، خادعوا، واكشفوا الخدعة';

  @override
  String get engineReasonMaexchenNoLives => 'لم تبقَ أي أرواح';

  @override
  String get maexchenOptionLives => 'الأرواح في البداية';

  @override
  String get maexchenOptionDouble => 'ميا مضاعفة';

  @override
  String get maexchenOptionDoubleExplain =>
      'كل ما يخص ميا يُحسب مضاعفًا: الشكّ في ميا حقيقية أو كشف ميا مزيفة يكلّف روحين.';

  @override
  String get maexchenOptionsNext => 'التالي';

  @override
  String get maexchenRoll => 'ارمِ النرد';

  @override
  String get maexchenPeek => 'انظر';

  @override
  String get maexchenCover => 'غطِّ';

  @override
  String get maexchenPickTitle => 'ماذا تعلن؟';

  @override
  String maexchenAnnounce(String value) {
    return 'أعلن $value';
  }

  @override
  String get maexchenOrder =>
      'من الأصغر إلى الأكبر: 31، 32 … 65، ثم الأزواج 11 … 66، ثم ميا (21).';

  @override
  String get maexchenBelieve => 'أصدّق';

  @override
  String get maexchenDoubt => 'أشكّ';

  @override
  String get maexchenGiveUp => 'التخلّي عن روح';

  @override
  String maexchenAnnounced(String player, String value) {
    return 'إعلان $player: $value';
  }

  @override
  String get maexchenNewRound => 'جولة جديدة: أي قيمة مسموحة';

  @override
  String get maexchenHintRoll => 'اضغط ارمِ النرد، ثم انظر تحت الكوب سرًّا.';

  @override
  String maexchenHintBelieved(String value) {
    return 'صدّقتَ $value. ارمِ النرد وأعلن أكثر من $value.';
  }

  @override
  String get maexchenHintAnnounceFirst =>
      'انظر سرًّا وأعلن قيمة. الخداع مسموح!';

  @override
  String maexchenHintAnnounceHigher(String value) {
    return 'أعلن أكثر من $value. الخداع مسموح!';
  }

  @override
  String maexchenHintRespond(String player, String value) {
    return 'إعلان $player: $value. هل تصدّق؟';
  }

  @override
  String maexchenHintRespondMaexchen(String player) {
    return 'إعلان $player: ميا! لا شيء أعلى منها: تشكّ أم تتخلّى عن روح؟';
  }

  @override
  String maexchenUnderCup(String value) {
    return 'تحت الكوب: $value';
  }

  @override
  String maexchenVerdictBluff(String player) {
    return 'خدعة! روح أقل لدى $player.';
  }

  @override
  String maexchenVerdictTrue(String player) {
    return 'كان صحيحًا! روح أقل لدى $player.';
  }

  @override
  String maexchenVerdictTrueTwo(String player) {
    return 'ميا حقيقية! روحان أقل لدى $player.';
  }

  @override
  String maexchenVerdictBluffTwo(String player) {
    return 'ميا مزيفة! روحان أقل لدى $player.';
  }

  @override
  String maexchenVerdictGaveUp(String player) {
    return 'روح أقل لدى $player. يبقى الكوب مغطّى.';
  }

  @override
  String maexchenLivesOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أرواح',
      two: 'روحان',
      one: 'روح واحدة',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenRoundLabel(int round) {
    return 'الجولة $round';
  }

  @override
  String get maexchenMoveRoll => 'رمي النرد';

  @override
  String maexchenMoveAnnounce(String value) {
    return 'إعلان $value';
  }

  @override
  String get maexchenMoveBelieve => 'تصديق';

  @override
  String get maexchenMoveDoubt => 'تشكيك';

  @override
  String get maexchenMoveGiveUp => 'التخلّي عن روح';

  @override
  String get maexchenMaexchenName => 'ميا';

  @override
  String get maexchenMaexchenCall => 'ميا!';

  @override
  String get maexchenAnnouncedLabel => 'المُعلَن';

  @override
  String get maexchenPickFirst => 'اختر رقمًا';

  @override
  String get maexchenShakeHint => 'أو هزّ الهاتف';

  @override
  String get shakeToRollSetting => 'الهز لرمي النرد';

  @override
  String get shakeToRollExplain =>
      'هزّ الهاتف مثل كوب النرد بدلًا من الضغط على «ارمِ النرد».';

  @override
  String get confirmMoveSetting => 'تأكيد الحركة';

  @override
  String get confirmMoveHelper => 'لا تُحتسب الحركة إلا بعد لمس «تحريك».';

  @override
  String get confirmMoveCommit => 'تحريك';

  @override
  String get confirmMoveBack => 'حركة أخرى';

  @override
  String get confirmMoveHint =>
      'هل هذه الحركة صحيحة؟ المس «تحريك» أو «حركة أخرى».';

  @override
  String get confirmMoveOn => 'تأكيد الحركة: مفعّل.';

  @override
  String get confirmMoveOff => 'تأكيد الحركة: متوقف.';

  @override
  String get rulesButton => 'القواعد';

  @override
  String get menuCards => 'البطاقات';

  @override
  String rulesTitle(String game) {
    return 'قواعد اللعبة: $game';
  }

  @override
  String playerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لاعب',
      many: '$count لاعبًا',
      few: '$count لاعبين',
      two: 'لاعبان',
      one: 'لاعب واحد',
      zero: 'لا لاعبين',
    );
    return '$_temp0';
  }

  @override
  String playerCountRange(int min, int max) {
    return 'من $min إلى $max لاعبين';
  }

  @override
  String get rulesGoal => 'الهدف';

  @override
  String get rulesTurn => 'كيف يسير الدور';

  @override
  String get rulesSpecial => 'القواعد';

  @override
  String get rulesHouse => 'القواعد البديلة';

  @override
  String get rulesHouseInGame => 'القواعد البديلة في هذه اللعبة';

  @override
  String get rulesHouseMenuNote =>
      'هذا هو الاقتراح. يمكنكم تغيير القواعد البديلة قبل اللعب.';

  @override
  String get rulesNewHere => 'جديد هنا؟ هكذا تلعب';

  @override
  String get rulesCoachHere => 'تجد كل القواعد هنا.';

  @override
  String get rulesConnect4Goal =>
      'ضع 4 من أقراصك في صف: أفقيًا أو عموديًا أو مائلًا.';

  @override
  String get rulesConnect4Turn =>
      'انقر على عمود. يسقط قرصك إلى أدنى مكان فارغ.\nثم يأتي دور الطرف الآخر.\nالبداية مع اللاعب 1.';

  @override
  String get rulesConnect4Special =>
      'في اللوحة 7 أعمدة و6 صفوف.\nالعمود الممتلئ لا يتسع لقرص آخر.\nإذا امتلأت اللوحة ولم تكن 4 في صف عند أحد، فالنتيجة تعادل.';

  @override
  String get rulesMuehleGoal =>
      'أزل أحجار الطرف الآخر حتى لا يبقى منها إلا 2. أو حاصر أحجاره حتى لا تبقى له حركة.';

  @override
  String get rulesMuehleTurn =>
      'لكل لاعب 9 أحجار. البداية مع اللاعب 1.\nأولًا تضعون بالتناوب حجرًا واحدًا على نقطة فارغة.\nبعد وضع كل الأحجار تحرّك حجرًا على خط إلى النقطة الفارغة المجاورة.\nإذا بقي لديك 3 أحجار فقط، يمكنك القفز: إلى أي نقطة فارغة.';

  @override
  String get rulesMuehleMill =>
      '3 أحجار على خط واحد تصنع طاحونة. عندها تزيل حجرًا من أحجار الطرف الآخر.';

  @override
  String get rulesMuehleSpecial =>
      'الأحجار في الطاحونة محميّة. فقط إذا كانت كل أحجار الطرف الآخر في طواحين، يمكنك أخذ واحد منها.\nإذا فتحت طاحونة ثم أغلقتها مرة أخرى، تُحسب من جديد.\n50 حركة متتالية بلا إزالة حجر (لكلا اللاعبين معًا): تعادل.';

  @override
  String get rulesTrumpfGoal => 'اربح كل البطاقات. من تنفد بطاقاته يخسر.';

  @override
  String get rulesTrumpfTurn =>
      'يحصل كل لاعب على 16 بطاقة في كومة مقلوبة. تُلعب دائمًا البطاقة العليا.\nصاحب الدور يختار خاصية من بطاقته، مثل السرعة.\nالقيمة الأفضل تربح الجولة. غالبًا الأعلى أفضل، وفي بعض الخصائص الأقل. هذا مكتوب على البطاقة.\nالرابح في الجولة يضع البطاقتين تحت كومته ويختار في المرة التالية.\nالاختيار الأول للاعب 1.';

  @override
  String get rulesTrumpfSpecial =>
      'قيمة متساوية: جولة فاصلة! تذهب البطاقتان إلى الوعاء، ويختار صاحب الاختيار مرة أخرى. الرابح في الجولة التالية يأخذ الوعاء كله أيضًا.\nبعد 200 جولة يفوز من لديه بطاقات أكثر. عند التساوي فالنتيجة تعادل.\nإذا فرغت الكومتان، فالنتيجة تعادل أيضًا.';

  @override
  String get rulesTrumpfPickLow => '3 بطاقات أو أقل: اختر';

  @override
  String get rulesTrumpfPickLowText =>
      'إذا بقي لديك 2 أو 3 بطاقات فقط، ترى كلها وتختار أيها تلعب. صاحب الاختيار يختار البطاقة أولًا ثم الخاصية. والطرف الآخر يختار بطاقته بعد معرفة الخاصية.';

  @override
  String get rulesSetsGoal =>
      'اجمع رباعيات: البطاقات الـ4 كلها من مجموعة واحدة. يفوز في النهاية من لديه رباعيات أكثر.';

  @override
  String get rulesSetsTurn =>
      'يحصل كل لاعب على 8 بطاقات. البطاقات الـ16 الأخرى في كومة مقلوبة.\nاطلب من الطرف الآخر بطاقة تنقصك. يجب أن تكون لديك بطاقة من هذه المجموعة.\nإذا كانت البطاقة عند الطرف الآخر، تنتقل إليك، ويمكنك الطلب مرة أخرى.\nإذا لم تكن عنده، فالجواب «لا يوجد»: تسحب بطاقة من الكومة، ثم يأتي دور الطرف الآخر.\nالطلب الأول للاعب 1.';

  @override
  String get rulesSetsSpecial =>
      'إذا اكتملت لديك البطاقات الـ4 من مجموعة، تضع الرباعية فورًا.\nإذا سحبت من الكومة البطاقة التي طلبتها، يأتي مع ذلك دور الطرف الآخر.\nإذا لم تبقَ لديك بطاقات، تسحب بطاقة من الكومة.\nعند وضع الرباعيات الـ8 كلها تنتهي اللعبة. 4 مقابل 4 تعادل.';

  @override
  String get rulesSchiffeGoal => 'أغرق كل سفن الطرف الآخر قبل أن تغرق سفنك.';

  @override
  String get rulesSchiffeTurn =>
      'أولًا يضع كل لاعب أسطوله سرًّا في بحره، وهو 10 × 10 خانات. البداية مع اللاعب 1.\nثم تطلقون النار بالتناوب: انقر خانة في بحر الطرف الآخر.\nتطلق النار على كل خانة مرة واحدة فقط.';

  @override
  String get rulesSchiffeMiss => 'ماء: خطأ. الآن دور الطرف الآخر.';

  @override
  String get rulesSchiffeHit => 'إصابة! يمكنك إطلاق النار مرة أخرى.';

  @override
  String get rulesSchiffeSunk =>
      'غرقت: كل خانات السفينة مصابة. تعرف أي سفينة كانت.';

  @override
  String get rulesSchiffeFleet => 'الأسطول';

  @override
  String rulesSchiffeShip(int count, String ship, int length) {
    return '$count × $ship (الطول: $length)';
  }

  @override
  String get rulesSchiffeSpecial =>
      'السفن مستقيمة: أفقية أو عمودية.\nيجب ألا تتلامس السفن، ولا حتى عند الزوايا.';

  @override
  String get rulesGoGoal =>
      'استولِ على علم الطرف الآخر. تفوز أيضًا إذا لم تبقَ للطرف الآخر أي حركة.';

  @override
  String get rulesGoTurn =>
      'أولًا يضع كل لاعب قطعه الـ40 سرًّا في صفوفه الأربعة. رتبة القطعة لا يراها إلا صاحبها.\nاللاعب 1 يضع قطعه أولًا ويتحرك أولًا.\nفي دورك تحرّك قطعة واحدة مربعًا واحدًا إلى الأمام أو الخلف أو اليسار أو اليمين. لا تتحرك مائلًا أبدًا.\nلا تدخل أي قطعة البحيرتين في الوسط.';

  @override
  String get rulesGoFightTitle => 'من يغلب من؟';

  @override
  String get rulesGoFight =>
      'إذا تحركت إلى قطعة للطرف الآخر، تتقاتل القطعتان. بعدها يرى اللاعبان أي قطعتين كانتا.\nالرتبة الأعلى تفوز. والخاسرة تخرج من اللعبة.\nرتبة متساوية: تخرج القطعتان.';

  @override
  String get rulesGoPieces => 'القطع';

  @override
  String rulesGoRank(int rank) {
    return 'الرتبة $rank';
  }

  @override
  String rulesGoCount(int count) {
    return '$count ×';
  }

  @override
  String get rulesGoMarshal =>
      'أقوى قطعة. لا يخسر إلا أمام الجاسوس عندما يهاجمه الجاسوس.';

  @override
  String get rulesGoScout =>
      'يسير مستقيمًا أي عدد من المربعات الفارغة، ويمكنه الهجوم في النهاية. إذا سار أكثر من مربع واحد، يرى اللاعبان أنه كشّاف.';

  @override
  String get rulesGoMiner => 'يفكّك القنابل: إذا هاجم قنبلة، يأخذ مكانها.';

  @override
  String get rulesGoSpy =>
      'أضعف قطعة. لكن إذا هاجم الجاسوس المشير، يفوز الجاسوس.';

  @override
  String get rulesGoBomb =>
      'لا تتحرك أبدًا. كل قطعة تهاجمها تخرج، وتبقى القنبلة. خبير الألغام وحده يفكّكها.';

  @override
  String get rulesGoFlag => 'لا يتحرك أبدًا. من يهاجمه يفوز باللعبة.';

  @override
  String get rulesGoSpecial =>
      'يمكن للقطعة أن تتحرك ذهابًا وإيابًا بين المربعين نفسيهما 3 مرات متتالية على الأكثر.\nإذا تحركت قطعة، يعرف الطرف الآخر: ليست قنبلة ولا علمًا.\n200 حركة متتالية بلا قتال: تعادل. وكذلك إذا لم تبقَ لأحد أي حركة.';

  @override
  String get rulesGoZoom =>
      'بإصبعين تكبّر اللوحة وتصغّرها وتحرّكها. العدسة المكبّرة تكبّر القطعة المختارة؛ لمسة أخرى عليها تعرض اللوحة كلها.';

  @override
  String get rulesChessGoal =>
      'اجعل ملك الطرف الآخر «كش مات»: يكون مهدَّدًا ولا مهرب له.';

  @override
  String get rulesChessTurn =>
      'الأبيض يبدأ، ثم تلعبون بالتناوب.\nالمس قطعة من قطعك ثم مربعًا. إذا كانت هناك قطعة للطرف الآخر، تأسرها.\nالحصان وحده يمكنه القفز فوق القطع الأخرى.';

  @override
  String get rulesChessPieces => 'كيف تتحرك القطع';

  @override
  String get rulesChessKing => 'مربع واحد في أي اتجاه.';

  @override
  String get rulesChessQueen => 'أي مسافة مستقيمًا أو مائلًا.';

  @override
  String get rulesChessRook => 'أي مسافة مستقيمًا.';

  @override
  String get rulesChessBishop => 'أي مسافة مائلًا.';

  @override
  String get rulesChessKnight =>
      'مثل حرف L: مربعان مستقيمًا، ثم مربع واحد إلى الجانب. يقفز فوق القطع.';

  @override
  String get rulesChessPawn =>
      'مربع واحد إلى الأمام، وفي حركته الأولى مربعان أيضًا. يأسر مربعًا واحدًا مائلًا إلى الأمام.';

  @override
  String get rulesChessSpecial =>
      'كش: ملكك مهدَّد. يجب أن تنقذه فورًا. لا تجوز حركة تترك ملكك في كش.\nكش مات: الملك في كش ولا يمكن إنقاذه. من يصنع كش مات يفوز.\nالتبييت: لم يتحرك الملك ولا الرخ بعد، وكل ما بينهما فارغ. يتحرك الملك مربعين نحو الرخ، ويقفز الرخ إلى جانبه. لا يجوز إذا كان الملك في كش أو كان سيمر على مربع مهدَّد.\nالأخذ بالمرور: إذا تحرك بيدق مربعين ووصل إلى جانب بيدقك، يمكنك أسره مائلًا في حركتك التالية مباشرة، كأنه تحرك مربعًا واحدًا فقط.\nالترقية: إذا وصل بيدق إلى الصف الأخير، يصير وزيرًا أو رخًا أو فيلًا أو حصانًا. أنت تختار.';

  @override
  String get rulesChessDrawTitle => 'التعادل';

  @override
  String get rulesChessDraw =>
      'الجمود: صاحب الدور لا يستطيع الحركة، لكنه ليس في كش.\nبقيت قطع قليلة جدًا لا تكفي لكش مات.\nالوضع نفسه يتكرر للمرة الثالثة.\n75 حركة لكل لاعب بلا أسر ولا تحريك بيدق.\nتعادل بالاتفاق: صاحب الدور يمكنه عرض التعادل. والطرف الآخر يقبل أو يرفض.';

  @override
  String get rulesWordtilesWin => 'يفوز من لديه أكثر النقاط في النهاية.';

  @override
  String get rulesWordtilesTurn =>
      'لديك 7 بلاطات.\nضع من 1 إلى 7 بلاطات في صف واحد أو عمود واحد، بلا فراغ.\nتحصل على نقاط كل الكلمات الجديدة، ومنها الكلمات المتقاطعة معها.\nبعدها تسحب بلاطات من الكيس حتى يصير لديك 7 من جديد.';

  @override
  String get rulesWordtilesChallengeAfter =>
      'بعد الاعتراض يلعب المعترض دوره كالعادة.';

  @override
  String get rulesWordtilesPlayers =>
      'من اثنين إلى أربعة على جهاز واحد، كلٌّ في دوره. في الغرفة يلعب اثنان فقط.';

  @override
  String get rulesWordtilesChallengeNext =>
      'الاعتراض فقط لمن يأتي دوره بعد ذلك.';

  @override
  String get rulesWordtilesScoreless =>
      'إذا انتهت اللعبة لأن أحدًا لم يعد يحصل على نقاط، تُطرح من كل لاعب نقاط بلاطاته الباقية.';

  @override
  String get rulesWordtilesNoRestTitle => 'دون خصم الحروف الباقية';

  @override
  String get rulesWordtilesNoRest =>
      'لا يُطرح ولا يُضاف شيء في النهاية: تُحتسب الكلمات الموضوعة فقط.';

  @override
  String get rulesMaumauGoal => 'تخلّص من كل أوراقك قبل الطرف الآخر.';

  @override
  String get rulesMaumauTurn =>
      'في اللعبة 32 ورقة. يحصل كل لاعب على 5، وورقة مكشوفة في الوسط. البداية مع اللاعب 1.\nضع فوقها ورقة من الشكل نفسه أو بالقيمة نفسها، مثل قلوب على قلوب أو 9 على 9.\nإذا لم تناسب أي ورقة أو لم ترد أن تضع ورقة، تسحب ورقة واحدة. إذا ناسبت، يمكنك وضعها أو الاحتفاظ بها. وإذا لم تناسب، يأتي دور الطرف الآخر.\nإذا فرغت كومة السحب، تُخلط الأوراق المرمية وتصير كومة جديدة.';

  @override
  String get rulesMaumauJack =>
      'الولد: يناسب كل ورقة إلا الولد. تطلب شكلًا. بعدها يجب أن تأتي ورقة من هذا الشكل أو ولد.';

  @override
  String get rulesMaumauSpecial =>
      'الورقة الأولى في الوسط لا تُعدّ ورقة خاصة.\n9 و10 والبنت والشايب أوراق عادية.\nمن يضع ورقته الأخيرة يفوز، حتى لو كانت ورقة خاصة.';

  @override
  String get rulesMaexchenGoal =>
      'لا تخسر كل أرواحك. يفوز من تبقى له أرواح في النهاية.';

  @override
  String get rulesMaexchenTurn =>
      'ارمِ نردين تحت الكوب. لا يراهما أحد غيرك.\nأعلن قيمة. يجب أن تكون أعلى من الإعلان السابق. الخداع مسموح أيضًا!\nالطرف الآخر يصدّقك أو يشكّ.\nعند التصديق يرمي الطرف الآخر النرد بنفسه ويجب أن يعلن قيمة أعلى.\nعند الشك يُرفع الكوب. إذا كانت الرمية أقل من الإعلان، يخسر المُعلِن روحًا. وإلا يخسر الشاكّ روحًا.';

  @override
  String get rulesMaexchenOrderTitle => 'أي رمية أعلى؟';

  @override
  String get rulesMaexchenOrder =>
      'النرد الأعلى يُحسب أولًا: 3 و1 تساوي 31.\nمن الأصغر إلى الأكبر: 31، 32، 41، 42، 43 وهكذا حتى 65.\nأعلى منها الأزواج: 11، 22، 33، 44، 55، 66.\nالأعلى على الإطلاق 21: ميا!';

  @override
  String get rulesMaexchenSpecial =>
      'الإعلان الأول في الجولة يمكن أن يكون أي قيمة.\nإذا أُعلنت ميا، لا يمكنك التصديق. إما أن تشكّ أو تتخلّى عن روح دون أن تنظر.\nمن يخسر روحًا يبدأ الجولة التالية.\nالهز: بدلًا من الضغط على «ارمِ النرد» يمكنك هزّ الهاتف مثل الكوب.';

  @override
  String rulesMaexchenLives(int count) {
    return 'عدد الأرواح لكل لاعب في البداية: $count.';
  }

  @override
  String get shakeConsentTitle => 'رمي النرد بالهز؟';

  @override
  String get shakeConsentBody =>
      'سيسأل المتصفح بعد قليل إن كان Klunki يستطيع الإحساس بحركة الهاتف. نستخدم ذلك لرمي النرد فقط، ويبقى على الجهاز.';

  @override
  String get shakeConsentYes => 'نعم، اسمح بالهز';

  @override
  String get shakeConsentNo => 'لا، اللمس فقط';

  @override
  String get wordtilesHelp => 'طريقة اللعب';

  @override
  String get wordtilesHelpJoker =>
      'تبديل البلاطة الفارغة (قاعدة بديلة): إن كان معك الحرف الذي تمثّله بلاطة فارغة على اللوحة، فاسحبه إليها. تنضمّ البلاطة الفارغة إلى بلاطاتك، وتضع بلاطات في الدور نفسه (ويمكن أن تكون البلاطة الفارغة منها). بلا وضع بلاطات لا يُحسب التبديل. تبقى الكلمة القديمة ونقاطها.';

  @override
  String get wordtilesHelpJokerOn => 'مفعّلة في هذه اللعبة.';

  @override
  String get wordtilesHelpJokerOff =>
      'غير مفعّلة في هذه اللعبة. يمكنكم تفعيلها قبل اللعبة.';

  @override
  String get menuGameDiceSheet => 'رمية النرد';

  @override
  String get menuDescDiceSheet => 'خمسة نرود وورقة واحدة، حتى أربعة لاعبين';

  @override
  String get engineReasonDicesheetAllFilled => 'امتلأت كل الخانات';

  @override
  String get playerDefaultNameC => 'سلمى';

  @override
  String get playerDefaultNameD => 'كريم';

  @override
  String get seatPlayerCount => 'كم عدد اللاعبين؟';

  @override
  String get seatResignWho => 'من يستسلم؟ يواصل الآخرون اللعب.';

  @override
  String get seatOut => 'استسلام';

  @override
  String seatPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points نقطة',
      few: '$points نقاط',
      two: 'نقطتان',
      one: 'نقطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get seatSharedFirst => 'تعادل على المركز الأول!';

  @override
  String get seatReasonOthersResigned => 'استسلم جميع الآخرين';

  @override
  String get dicesheetBoxOnes => 'الآحاد';

  @override
  String get dicesheetBoxTwos => 'الاثنينات';

  @override
  String get dicesheetBoxThrees => 'الثلاثات';

  @override
  String get dicesheetBoxFours => 'الأربعات';

  @override
  String get dicesheetBoxFives => 'الخمسات';

  @override
  String get dicesheetBoxSixes => 'الستات';

  @override
  String get dicesheetBoxThreeKind => 'ثلاثة متشابهة';

  @override
  String get dicesheetBoxFourKind => 'أربعة متشابهة';

  @override
  String get dicesheetBoxFullHouse => 'البيت الكامل';

  @override
  String get dicesheetBoxSmallStraight => 'سلسلة صغيرة';

  @override
  String get dicesheetBoxLargeStraight => 'سلسلة كبيرة';

  @override
  String get dicesheetBoxFiveKind => 'خمسة متشابهة';

  @override
  String get dicesheetBoxChance => 'الفرصة';

  @override
  String dicesheetMoveRoll(String dice) {
    return 'رمية: $dice';
  }

  @override
  String dicesheetMoveRollKeep(String dice, int count) {
    return 'رمية: $dice (مع إبقاء $count)';
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
    return '$player: $points في $box.';
  }

  @override
  String get dicesheetHintRoll => 'المس «ارمِ».';

  @override
  String get dicesheetHintKeep =>
      'المس النرود التي تريد إبقاءها وارمِ مرة أخرى. أو اختر خانة في الورقة.';

  @override
  String get dicesheetHintPick => 'اختر خانة في الورقة.';

  @override
  String get dicesheetHintJoker =>
      'خمسة متشابهة كورقة رابحة: اكتبها في إحدى الخانات المسموحة.';

  @override
  String dicesheetRollButton(int count) {
    return 'ارمِ (باقٍ $count)';
  }

  @override
  String get dicesheetPickBox => 'اختر خانة في الورقة';

  @override
  String dicesheetDie(int value) {
    return 'نرد $value';
  }

  @override
  String dicesheetDieKept(int value) {
    return 'نرد $value، محفوظ';
  }

  @override
  String get dicesheetKept => 'محفوظ';

  @override
  String dicesheetRound(int round, int total) {
    return 'الجولة $round/$total';
  }

  @override
  String dicesheetScoreAction(String box, int points) {
    return 'اكتب $points في $box';
  }

  @override
  String get dicesheetBonus => 'مكافأة';

  @override
  String dicesheetBonusRule(String bonus, int at) {
    return '$bonus من $at';
  }

  @override
  String get dicesheetExtraFives => 'خمسة إضافية';

  @override
  String get dicesheetTotal => 'المجموع';

  @override
  String get dicesheetOptionExtraFives => 'خمسة إضافية (قاعدة بديلة)';

  @override
  String get dicesheetOptionExtraFivesExplain =>
      'خمسة متشابهة أخرى وفي خانتها 50 بالفعل: 100 نقطة إضافية. وتصبح ورقة رابحة تذهب أولاً إلى الخانة العلوية لرقمها.';

  @override
  String get rulesDicesheetGoal =>
      'اجمع على ورقتك أكبر عدد ممكن من النقاط بخمسة نرود.\nبعد 13 جولة تمتلئ كل الخانات. يفوز صاحب أكبر عدد من النقاط. عند تساوي النقاط تتقاسمون المركز.';

  @override
  String get rulesDicesheetTurn =>
      'يلعب من 2 إلى 4 على جهاز واحد بالتناوب.\nارمِ النرود الخمسة كلها. يمكنك الرمي حتى ثلاث مرات.\nقبل الرمية الثانية والثالثة المس النرود التي تريد إبقاءها. ثم ارمِ الباقي من جديد.\nبعدها اكتب ما تساويه النرود في خانة فارغة واحدة فقط من ورقتك. تُظهر لك الورقة كم نقطة تعطي كل خانة.\nإن لم يناسب شيء، اشطب خانة: تأخذ صفرًا.';

  @override
  String get rulesDicesheetUpperTitle => 'الأعلى: الآحاد حتى الستات';

  @override
  String get rulesDicesheetUpper =>
      'تُحسب فقط النرود التي تظهر رقم الخانة، مجموعةً معًا.';

  @override
  String rulesDicesheetBonus(int at, int bonus) {
    return 'إذا بلغ القسم العلوي $at نقطة أو أكثر تحصل على مكافأة $bonus نقطة.';
  }

  @override
  String get rulesDicesheetLowerTitle => 'الأسفل';

  @override
  String get rulesDicesheetThreeKind => '3 متشابهة على الأقل. تُحسب كل النرود.';

  @override
  String get rulesDicesheetFourKind => '4 متشابهة على الأقل. تُحسب كل النرود.';

  @override
  String rulesDicesheetFullHouse(int points) {
    return '3 متشابهة و2 متشابهة: $points نقطة.';
  }

  @override
  String rulesDicesheetSmallStraight(int points) {
    return '4 أرقام متتالية: $points نقطة.';
  }

  @override
  String rulesDicesheetLargeStraight(int points) {
    return '5 أرقام متتالية: $points نقطة.';
  }

  @override
  String rulesDicesheetFiveKind(int points) {
    return '5 متشابهة: $points نقطة.';
  }

  @override
  String get rulesDicesheetChance => 'تناسب دائمًا. تُحسب كل النرود.';

  @override
  String get rulesDicesheetSpecial =>
      'تملأ كل خانة مرة واحدة فقط.\nالرمية تُحسب فورًا. «تراجع عن الحركة» يسترجع فقط ما كتبته في الورقة، ما دام أحد لم يرمِ بعد.\nمن يستسلم يخرج من اللعبة. ويواصل الآخرون اللعب.\nالهز: بدلًا من الضغط على «ارمِ» يمكنك هزّ الهاتف.';

  @override
  String rulesDicesheetExtraFives(int bonus) {
    return 'خمسة متشابهة أخرى وفي خانتها 50 بالفعل: $bonus نقطة إضافية. بعد أن تُملأ خانة الخمسة المتشابهة (ولو بصفر) تصبح الخمسة المتشابهة ورقة رابحة: أولاً في الخانة العلوية لرقمها؛ وإن كانت ممتلئة ففي خانة سفلية فارغة بكامل النقاط؛ وإلا فبصفر في خانة علوية.';
  }

  @override
  String get dicesheetStartTitle => 'من يبدأ؟';

  @override
  String get dicesheetStartFirst => 'اللاعب الأول';

  @override
  String get dicesheetStartOrder => 'تحديد الترتيب';

  @override
  String get dicesheetStartRandom => 'عشوائي';

  @override
  String get dicesheetStartFirstExplain =>
      'يبدأ الاسم الأول في القائمة. ثم بالتناوب.';

  @override
  String get dicesheetStartOrderExplain =>
      'في الخطوة التالية ترتّبون الأسماء كما تريدون.';

  @override
  String get dicesheetStartRandomExplain =>
      'تختار اللعبة بالقرعة من يبدأ. ثم بالتناوب.';

  @override
  String get seatOrderHint =>
      'تلعبون بترتيب الأسماء هنا. غيّر الترتيب بالأسهم.';

  @override
  String get seatMoveUp => 'إلى الأعلى';

  @override
  String get seatMoveDown => 'إلى الأسفل';

  @override
  String get seatRandomStartHint => 'تختار اللعبة بالقرعة من يبدأ.';

  @override
  String seatStarts(String player) {
    return 'هيا: البداية مع $player.';
  }

  @override
  String seatStartsRandom(String player) {
    return 'القرعة: البداية مع $player!';
  }

  @override
  String get rulesDicesheetStart =>
      'قبل اللعب تختارون من يبدأ: الاسم الأول في القائمة، أو ترتيبكم الخاص، أو القرعة.';

  @override
  String get maumauOptionMustPlay => 'العب ورقة إن أمكن';

  @override
  String get maumauOptionMustPlayExplain =>
      'لا يمكنك السحب إلا إذا لم تناسب أي ورقة. بعد الـ7 يمكنك دائمًا سحب الأوراق.';

  @override
  String get maumauHintMustPlay => 'لديك ورقة مناسبة – العبها.';

  @override
  String get maumauHintNoFit => 'لا تناسب أي ورقة. اسحب ورقة من الكومة.';

  @override
  String get rulesMaumauTurnMustPlay =>
      'في اللعبة 32 ورقة. يحصل كل لاعب على 5، وورقة مكشوفة في الوسط. البداية مع اللاعب 1.\nضع فوقها ورقة من الشكل نفسه أو بالقيمة نفسها، مثل قلوب على قلوب أو 9 على 9.\nإذا لم تناسب أي ورقة، تسحب ورقة واحدة. إذا ناسبت، يمكنك وضعها أو الاحتفاظ بها. وإذا لم تناسب، يأتي دور الطرف الآخر.\nإذا فرغت كومة السحب، تُخلط الأوراق المرمية وتصير كومة جديدة.';

  @override
  String get dicesheetBeginnerOption => 'وضع المبتدئين';

  @override
  String get dicesheetBeginnerExplain =>
      'تضيء الخانة التي تناسب الآن. يمكنك مع ذلك اختيار أي خانة.';

  @override
  String get dicesheetTipsOption => 'نصائح';

  @override
  String get dicesheetTipsExplain =>
      'فقاعة تقول أي خانة تناسب الآن ولماذا، وأي نرود تُبقيها.';

  @override
  String get dicesheetTipLabel => 'نصيحة';

  @override
  String get dicesheetTipShow => 'اعرض النصيحة';

  @override
  String dicesheetTipBonus(String box, int points, int goal) {
    return 'نصيحة: $box – $points نقطة تساعدك على المكافأة ($goal).';
  }

  @override
  String dicesheetTipAllDice(String box, int points) {
    return 'نصيحة: $box – كل النرود تُحسب، وهذا يعطي $points نقطة.';
  }

  @override
  String dicesheetTipFixed(String box, int points) {
    return 'نصيحة: $box – هذا يعطي $points نقطة. خذها!';
  }

  @override
  String dicesheetTipPoints(String box, int points) {
    return 'نصيحة: $box – هذا يعطي $points نقطة.';
  }

  @override
  String dicesheetTipLeastLoss(String box, int points) {
    return 'نصيحة: لا توجد خانة جيدة؟ $box تعطي $points نقطة فقط، لكنك تخسر فيها أقل شيء.';
  }

  @override
  String dicesheetTipStrike(String box) {
    return 'نصيحة: لا توجد خانة جيدة؟ اشطب $box، فهناك تخسر أقل شيء.';
  }

  @override
  String dicesheetTipRicher(String box, int points) {
    return '$box تعطي الآن $points نقطة، لكنها أنفع لاحقًا.';
  }

  @override
  String get dicesheetTipSaveChance => 'احتفظ بالفرصة لوقت لاحق.';

  @override
  String get dicesheetTipOnce =>
      'كل خانة تُستعمل مرة واحدة فقط، والفرصة أيضًا.';

  @override
  String get dicesheetTipKeep => 'نصيحة: أبقِ هذه النرود وارمِ الباقي من جديد:';

  @override
  String get dicesheetTipRerollAll =>
      'نصيحة: لا شيء يتناسب جيدًا. ارمِ كل النرود من جديد.';

  @override
  String get dicesheetTipStop => 'رمية رائعة! لا داعي للرمي مرة أخرى.';

  @override
  String get dicesheetTipsEnd => 'إيقاف النصائح';

  @override
  String get dicesheetTipsEnded =>
      'تم إيقاف النصائح. يمكنك تشغيلها من جديد في الخيارات.';

  @override
  String dicesheetFreeBoxes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count خانة',
      few: 'بقيت $count خانات',
      two: 'بقيت خانتان',
      one: 'بقيت خانة واحدة',
    );
    return '$_temp0';
  }

  @override
  String rulesDicesheetOnce(int count) {
    return 'تملأ كل خانة مرة واحدة فقط. $count خانة، $count جولة.';
  }

  @override
  String get rulesDicesheetBeginner =>
      'وضع المبتدئين (يعمل في أول مباراة): تضيء الخانة التي تناسب الآن. النصائح (تعمل في أول 5 مباريات): فقاعة تقول لماذا وأي نرود تُبقيها. يمكنك تشغيل الاثنين أو إيقافهما في الخيارات. يمكنك مع ذلك اختيار أي خانة.';

  @override
  String dicesheetCoachRoll(int count) {
    return 'لديك حتى $count رميات في كل جولة.';
  }

  @override
  String get dicesheetCoachKeep => 'المس النرود التي يجب أن تبقى.';

  @override
  String get dicesheetCoachSheet =>
      'ثم تكتب الرمية في خانة. الرقم يُظهر كم نقطة تعطي.';

  @override
  String dicesheetCoachOnce(int count) {
    return 'كل خانة مرة واحدة فقط: $count خانة، $count جولة. يفوز صاحب أكبر عدد من النقاط.';
  }

  @override
  String get dicesheetCoachReplay => 'جولة سريعة';

  @override
  String get menuGameProperty => 'ملك البناء';

  @override
  String get menuDescProperty => 'شراء الشوارع وجمع الإيجار والبناء';

  @override
  String get engineReasonPropertyLastSolvent =>
      'جميع الآخرين مفلسون أو خارج اللعبة';

  @override
  String engineReasonPropertyRoundLimit(int rounds) {
    return 'بعد $rounds جولة تفوز الثروة الأكبر';
  }

  @override
  String propertyMoney(int amount) {
    return '$amount قطعة نقدية';
  }

  @override
  String get propertyOptionsBoard => 'اللوحة';

  @override
  String get propertyThemeBerlin => 'برلين';

  @override
  String get propertyThemeFantasie => 'مدينة الخيال';

  @override
  String get propertyThemeGermanNote =>
      'أسماء الشوارع والبطاقات بالألمانية حاليًا.';

  @override
  String get propertyOptionsLength => 'مدة اللعب';

  @override
  String get propertyOptionsUntilEnd => 'حتى يبقى لاعب واحد';

  @override
  String propertyOptionsRounds(int rounds) {
    return '$rounds جولة';
  }

  @override
  String get propertyOptionsRoundsExplain =>
      'مع حد للجولات، يفوز في النهاية صاحب الثروة الأكبر.';

  @override
  String get propertyOptionsVariants => 'القواعد البديلة';

  @override
  String propertyFreeTitle(String square) {
    return 'على «$square»';
  }

  @override
  String get propertyFreeNone => 'لا شيء يحدث';

  @override
  String get propertyFreePot => 'صندوق الضرائب والغرامات';

  @override
  String propertyFreePotSeed(String amount) {
    return 'صندوق يبدأ بـ $amount';
  }

  @override
  String propertyFreeBonus(String amount) {
    return '$amount ثابتة';
  }

  @override
  String get propertyFreeExplain =>
      'الصندوق: الضرائب وغرامات البطاقات تذهب إلى الوسط، ومن يقف على المربع يأخذ كل شيء.';

  @override
  String propertyFreeBonusExplain(String square, String amount) {
    return 'الوقوف على «$square» يعطي $amount.';
  }

  @override
  String get propertyRuleDoubleStart => 'راتب مضاعف عند الوقوف على البداية';

  @override
  String propertyRuleDoubleStartExplain(String amount) {
    return 'الوقوف تمامًا على البداية يعطي $amount.';
  }

  @override
  String get propertyRuleNoRentInPause => 'لا إيجار أثناء الاستراحة';

  @override
  String get propertyRuleNoRentInPauseExplain =>
      'من يجلس في الاستراحة لا يحصل على إيجار.';

  @override
  String get propertyRuleBankruptAuction => 'مزاد عند الإفلاس';

  @override
  String get propertyRuleBankruptAuctionExplain =>
      'عندما يفلس لاعب أمام البنك، تُباع شوارعه بالمزاد بدل إعادتها.';

  @override
  String get propertyRoll => 'رمي النرد';

  @override
  String propertyBuy(String amount) {
    return 'شراء مقابل $amount';
  }

  @override
  String get propertyDecline => 'عدم الشراء – مزاد';

  @override
  String get propertyTooPoor => 'المال غير كافٍ للشراء';

  @override
  String propertyFreeToBuy(String square) {
    return '$square لا يملكه أحد بعد.';
  }

  @override
  String propertyAuctionTitle(String square) {
    return 'مزاد: $square';
  }

  @override
  String propertyAuctionHigh(String amount, String player) {
    return 'أعلى عرض: $amount من $player';
  }

  @override
  String get propertyAuctionNone => 'لا عروض بعد';

  @override
  String propertyAuctionTurn(String player) {
    return 'دور المزايدة: $player';
  }

  @override
  String propertyBid(String amount) {
    return 'عرض $amount';
  }

  @override
  String get propertyPass => 'الانسحاب';

  @override
  String get propertyEndTurn => 'إنهاء الدور';

  @override
  String propertyPayBail(String amount) {
    return 'دفع $amount والخروج';
  }

  @override
  String get propertyUseCard => 'استخدام البطاقة المجانية';

  @override
  String propertyInPause(String player, String square) {
    return 'استراحة $player في «$square»: زوج متطابق أو دفع أو بطاقة مجانية.';
  }

  @override
  String get propertyManage => 'شوارعي';

  @override
  String propertyManageOf(String player) {
    return 'شوارع: $player';
  }

  @override
  String propertyDebt(String player, String amount, String cash) {
    return 'دين $player: $amount، والمتوفر $cash فقط. بيع مبانٍ أو رهن شوارع.';
  }

  @override
  String get propertyBankrupt => 'إعلان الإفلاس';

  @override
  String propertyBuild(String amount) {
    return 'بناء ($amount)';
  }

  @override
  String propertySell(String amount) {
    return 'بيع (+$amount)';
  }

  @override
  String propertyMortgage(String amount) {
    return 'رهن (+$amount)';
  }

  @override
  String propertyUnmortgage(String amount) {
    return 'فك الرهن ($amount)';
  }

  @override
  String get propertyManageEmpty => 'لا شوارع بعد.';

  @override
  String get propertyMortgaged => 'مرهون';

  @override
  String propertyOwnerLine(String player) {
    return 'المالك: $player';
  }

  @override
  String get propertyOwnerNone => 'لا يزال ملك البنك';

  @override
  String propertyPrice(String amount) {
    return 'السعر: $amount';
  }

  @override
  String propertyRent(String amount) {
    return 'الإيجار: $amount';
  }

  @override
  String propertyHouseCost(String amount) {
    return 'كل مبنى يكلف $amount';
  }

  @override
  String get propertyStationRents => 'الإيجار حسب عدد المحطات';

  @override
  String propertyTax(String amount) {
    return 'ادفع: $amount';
  }

  @override
  String propertyCardSquare(String deck) {
    return 'سحب بطاقة: $deck';
  }

  @override
  String propertyStartSquare(String amount) {
    return 'المرور يعطي $amount.';
  }

  @override
  String get propertyPauseSquare =>
      'استراحة: الخروج بزوج متطابق أو بالمال أو ببطاقة. مجرد زيارة؟ لا شيء يحدث.';

  @override
  String get propertyGoToPauseSquare => 'إلى الاستراحة!';

  @override
  String get propertyOut => 'خارج اللعبة';

  @override
  String propertyStreets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count شارع',
      many: '$count شارعًا',
      few: '$count شوارع',
      two: 'شارعان',
      one: 'شارع واحد',
      zero: 'لا شوارع',
    );
    return '$_temp0';
  }

  @override
  String get propertyCoachRoll => 'ارمِ النرد وحرّك قطعتك على اللوحة.';

  @override
  String get propertyCoachBoard =>
      'إذا وقفت على شارع حر يمكنك شراؤه، ومن يقف على شارعك يدفع لك الإيجار. المس مربعًا لمعرفة المزيد.';

  @override
  String get propertyCoachPlayers => 'هنا ترى مال الجميع. من ينفد ماله يُفلس.';

  @override
  String get propertyCoachManage =>
      'إذا امتلكت لونًا كاملًا تبني هنا، فيرتفع الإيجار كثيرًا.';

  @override
  String get propertyCoachReplay => 'جولة سريعة';

  @override
  String propertyEvRolled(String player, int a, int b) {
    return 'رمية $player: $a + $b';
  }

  @override
  String propertyEvSalary(String player, String amount) {
    return 'راتب $player: $amount';
  }

  @override
  String propertyEvCard(String text) {
    return 'بطاقة: «$text»';
  }

  @override
  String propertyEvCollected(String player, String amount) {
    return 'لـ$player: $amount';
  }

  @override
  String propertyEvPot(String player, String amount) {
    return 'الصندوق لـ$player: $amount';
  }

  @override
  String propertyEvPaidBank(String player, String amount) {
    return 'دفعة $player للبنك: $amount';
  }

  @override
  String propertyEvPaidPot(String player, String amount) {
    return 'دفعة $player للصندوق: $amount';
  }

  @override
  String propertyEvPaid(String player, String amount, String other) {
    return 'دفعة من $player إلى $other: $amount';
  }

  @override
  String propertyEvBought(String player, String square, String amount) {
    return 'شراء $player: $square مقابل $amount';
  }

  @override
  String propertyEvBid(String player, String amount) {
    return 'عرض $player: $amount';
  }

  @override
  String propertyEvPassed(String player) {
    return 'انسحاب $player من المزاد';
  }

  @override
  String propertyEvUnsold(String square) {
    return 'لا عروض: $square يبقى للبنك';
  }

  @override
  String propertyEvBuilt(String player, String building, String square) {
    return 'بناء $player: $building في $square';
  }

  @override
  String propertyEvSold(String player, String square, String amount) {
    return 'بيع $player في $square: +$amount';
  }

  @override
  String propertyEvMortgaged(String player, String square, String amount) {
    return 'رهن $player: $square +$amount';
  }

  @override
  String propertyEvUnmortgaged(String player, String square, String amount) {
    return 'فك رهن $player: $square −$amount';
  }

  @override
  String propertyEvToPause(String player, String square) {
    return 'ذهاب $player إلى «$square»';
  }

  @override
  String get propertyEvThreeDoubles => 'ثلاثة أزواج متتالية!';

  @override
  String propertyEvLeftPause(String player) {
    return 'خروج $player من الاستراحة';
  }

  @override
  String propertyEvStayInPause(String player, int tries) {
    return 'لا زوج: بقاء $player في الاستراحة ($tries/3)';
  }

  @override
  String propertyEvBankrupt(String player) {
    return 'إفلاس $player';
  }

  @override
  String propertyEvResigned(String player) {
    return 'انسحاب $player';
  }

  @override
  String get rulesPropertyGoal =>
      'اشترِ الشوارع واجمع الإيجار وابنِ عليها.\nيفوز آخر من يبقى في اللعبة. مع حد للجولات تفوز الثروة الأكبر في النهاية.';

  @override
  String rulesPropertyTurn(String salary) {
    return 'ارمِ نردين وتقدّم بعدد المربعات.\nإذا وقفت على شارع حر يمكنك شراؤه، وإلا يُباع بالمزاد لصاحب أعلى عرض.\nإذا كان الشارع لغيرك تدفع الإيجار.\nمع زوج متطابق ترمي مرة أخرى.\nالمرور بالبداية يعطي $salary.';
  }

  @override
  String rulesPropertySpecial(String bail) {
    return 'إذا امتلكت مجموعة لونية كاملة يتضاعف الإيجار ويمكنك البناء بالتساوي: أولًا 4 مبانٍ صغيرة ثم مبنى كبير واحد لكل شارع.\nالبطاقات تعطي مالًا أو تأخذه أو تنقلك على اللوحة.\nثلاثة أزواج متتالية ترسلك إلى الاستراحة. تخرج بزوج متطابق أو بدفع $bail أو ببطاقة مجانية.\nينقصك المال؟ بِع المباني بنصف السعر أو ارهن الشوارع. لا تُفلس إلا إذا لم يكفِ ذلك.\nالرهن يعطي نصف السعر، وفكّه يكلف 10 % أكثر. الشارع المرهون لا يجلب إيجارًا.';
  }

  @override
  String get propertyDeedRent => 'الإيجار';

  @override
  String get propertyDeedRentGroup => 'مع المجموعة كاملة';

  @override
  String get propertyDeedMortgageValue => 'قيمة الرهن';

  @override
  String propertyDeedStations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محطة',
      few: '$count محطات',
      two: 'محطتان',
      one: 'محطة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get propertyDeedUtilityOne => 'مع واحد من الاثنين';

  @override
  String get propertyDeedUtilityBoth => 'مع الاثنين';

  @override
  String propertyDeedDiceTimes(int factor) {
    return 'مجموع النرد × $factor';
  }

  @override
  String get maexchenOptionUnlimited => 'أرواح بلا حدود';

  @override
  String get maexchenOptionUnlimitedExplain =>
      'لا يخرج أحد من اللعبة. تُحسب كل روح مفقودة. تلعبون حتى تُنهوا اللعبة: يفوز من خسر أقل عدد من الأرواح.';

  @override
  String get maexchenEndGame => 'إنهاء اللعبة';

  @override
  String get maexchenEndGameTitle => 'إنهاء اللعبة؟';

  @override
  String get maexchenEndGameBody =>
      'يفوز من خسر أقل عدد من الأرواح. عند التعادل تتشاركون المركز.';

  @override
  String get maexchenEndGameConfirm => 'إنهاء';

  @override
  String get engineReasonMaexchenEnded =>
      'أنهيتم اللعبة. يفوز من خسر أقل عدد من الأرواح.';

  @override
  String maexchenLostOf(String player, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أرواح مفقودة',
      two: 'روحان مفقودتان',
      one: 'روح واحدة مفقودة',
      zero: 'لا أرواح مفقودة',
    );
    return '$player: $_temp0';
  }

  @override
  String maexchenResultLost(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count أرواح مفقودة',
      two: 'روحان مفقودتان',
      one: 'روح واحدة مفقودة',
      zero: 'لا أرواح مفقودة',
    );
    return '$_temp0';
  }

  @override
  String maexchenResultLives(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count أرواح',
      two: 'بقيت روحان',
      one: 'بقيت روح واحدة',
    );
    return '$_temp0';
  }

  @override
  String get maexchenResultOut => 'خارج اللعبة';

  @override
  String get rulesMaexchenPlayers =>
      'من لاعبَين إلى أربعة على جهاز واحد. يدور الكوب حول الطاولة: تُعلن دائمًا لمن يليك. من لم تبقَ له أرواح يخرج ويُتخطّى دوره.';

  @override
  String get rulesMaexchenGoalUnlimited =>
      'اخسر أقل عدد ممكن من الأرواح. تلعبون حتى تُنهوا اللعبة.';

  @override
  String get rulesMaexchenEndHow =>
      '«إنهاء اللعبة» في القائمة ذات النقاط الثلاث.';

  @override
  String get propertyTrade => 'تبادل';

  @override
  String get propertyTradeTitle => 'عرض تبادل';

  @override
  String get propertyTradeWith => 'مع من؟';

  @override
  String get propertyTradeGive => 'منك';

  @override
  String get propertyTradeGet => 'لك';

  @override
  String get propertyTradeMoney => 'المال';

  @override
  String get propertyTradeMoneyReset => 'إعادة إلى 0';

  @override
  String get propertyTradeFreeCards => 'البطاقات المجانية';

  @override
  String propertyTradeCardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بطاقة مجانية',
      few: '$count بطاقات مجانية',
      two: 'بطاقتان مجانيتان',
      one: 'بطاقة مجانية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get propertyTradeNothing => 'لا شيء';

  @override
  String get propertyTradeNoStreets => 'لا شوارع';

  @override
  String get propertyTradeOffer => 'تقديم العرض';

  @override
  String propertyTradeOffersLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقي $count عرضًا في هذا الدور',
      few: 'بقيت $count عروض في هذا الدور',
      two: 'بقي عرضان في هذا الدور',
      one: 'بقي عرض واحد في هذا الدور',
    );
    return '$_temp0';
  }

  @override
  String get propertyTradeEmpty => 'لم يُختر شيء للتبادل بعد.';

  @override
  String get propertyTradeHouses => 'توجد مبانٍ في هذا اللون: لا يمكن تبادله';

  @override
  String propertyTradeTooMany(int count) {
    return 'تم تقديم $count عروض في هذا الدور.';
  }

  @override
  String get propertyTradeNotNow => 'لا يمكن التبادل الآن.';

  @override
  String get propertyTradeNoMoney => 'المال غير كافٍ.';

  @override
  String propertyTradeOfferFor(String player, String other) {
    return 'عرض تبادل من $player إلى $other';
  }

  @override
  String get propertyTradeAccept => 'قبول';

  @override
  String get propertyTradeDecline => 'رفض';

  @override
  String propertyEvTradeOffered(
    String player,
    String other,
    String give,
    String get,
  ) {
    return 'عرض تبادل من $player إلى $other: $give مقابل $get';
  }

  @override
  String propertyEvTraded(String player) {
    return 'قبول التبادل من $player';
  }

  @override
  String propertyEvTradeDeclined(String player) {
    return 'رفض التبادل من $player';
  }

  @override
  String get propertyCoachTrade =>
      'ينقصك شارع واحد لإكمال لون؟ من هنا يُعرض تبادل.';

  @override
  String rulesPropertyTrade(int count) {
    return 'في دورك يمكن عرض تبادل قبل الرمي أو بعده: شوارع ومال وبطاقات مجانية، حتى $count عروض في الدور.\nالشوارع التي في لونها مبانٍ لا تُتبادل: يجب بيع المباني أولًا. الشارع المرهون يبقى مرهونًا.\nينتقل الجهاز إلى الطرف الآخر للقبول أو الرفض. لا يمكن التراجع عن تبادل تمّ الرد عليه.';
  }
}

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
  String get menuLanguage => 'اللغة';

  @override
  String get languagePickerTitle => 'اختر اللغة';

  @override
  String get languageSystem => 'لغة النظام';

  @override
  String get menuChooseGame => 'اختر لعبة';

  @override
  String get menuPassDevice => 'تمرير الجهاز';

  @override
  String get menuDebugConsole => 'وحدة تصحيح الأخطاء';

  @override
  String get menuPlayOverWifi => 'اللعب عبر Wi-Fi';

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
  String get menuSectionHotSeat => 'لاعبان على جهاز واحد';

  @override
  String get menuSectionNetwork => 'بجهازين';

  @override
  String get menuNetworkSubtitle => 'استضف لعبة أو انضم إليها';

  @override
  String get menuHiddenInfo => 'بطاقات أو أسطول سري – تتبادلون الجهاز';

  @override
  String shellToMove(String player) {
    return 'دور $player';
  }

  @override
  String shellHasWon(String player) {
    return 'فاز $player';
  }

  @override
  String shellYourTurn(String mark) {
    return 'دورك ($mark)';
  }

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
    return '$player يفوز!';
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
  String get quartettTrumpfTie => 'تعادل – البطاقات إلى الوعاء';

  @override
  String quartettTrumpfWinsTrick(String player) {
    return '$player يربح الجولة';
  }

  @override
  String get quartettTrumpfOutcomeWin => 'يفوز';

  @override
  String get quartettTrumpfOutcomeLose => 'يخسر';

  @override
  String get quartettTrumpfOutcomeTie => 'تعادل';

  @override
  String quartettTrumpfSideOutcome(String player, String outcome) {
    return '$player – $outcome';
  }

  @override
  String quartettTrumpfPicked(String player, String stat) {
    return '$player يختار $stat';
  }

  @override
  String quartettTrumpfPotAgain(int count, String player) {
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
    return 'في الوعاء: $_temp0 – $player يختار مرة أخرى';
  }

  @override
  String quartettTrumpfHintWaiting(String player) {
    return '$player يختار …';
  }

  @override
  String get quartettTrumpfLastTrick => 'الجولة الأخيرة';

  @override
  String quartettTrumpfGraceSeconds(int seconds) {
    return 'المتابعة خلال $seconds ث';
  }

  @override
  String quartettTrumpfQueuedPick(String player, String stat) {
    return '$player اختار: $stat';
  }

  @override
  String quartettTrumpfNextPicker(String player) {
    return '$player يختار التالي';
  }

  @override
  String quartettTrumpfPicksAgain(String player) {
    return '$player يختار مرة أخرى';
  }

  @override
  String quartettTrumpfContinuePicker(String player) {
    return 'متابعة – $player يختار';
  }

  @override
  String quartettTrumpfYouPickNext(String player) {
    return 'أنت تختار التالي ($player)';
  }

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
    return '$player ربح الجولة';
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
  String quartettSetsScore(int a, int b) {
    return 'الرباعيات X $a : $b O';
  }

  @override
  String quartettSetsOtherAsked(String player, String card, String result) {
    return '$player يطلب $card: $result';
  }

  @override
  String quartettSetsHitGives(String player, String card) {
    return 'إصابة! $player يعطيك $card';
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
  String get schiffeHintSetup =>
      'التوزيع: انقر على البحر (أو اسحب وأفلت) لوضع السفينة. يجب ألا تتلامس السفن.';

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
    return 'تم وضع $placed من $total سفن · $player يوزّع';
  }

  @override
  String schiffeHintSelected(String ship) {
    return 'تم اختيار $ship: انقر على خانة أو اسحب السفينة لنقلها. انقر عليها مرة أخرى أو على «تدوير» لتدويرها.';
  }

  @override
  String get schiffeHintReady =>
      'الأسطول جاهز. انقر على سفينة لتغييرها، أو على «تم».';

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
  String get pairingTitle => 'اللعب عبر Wi-Fi';

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
  String get hotSeatNamesTitle => 'أسماء اللاعبين';

  @override
  String hotSeatNameLabel(String mark) {
    return 'اللاعب $mark';
  }

  @override
  String get hotSeatNamesHelper => 'اختياري – اتركه فارغًا لعرض X و O فقط.';

  @override
  String get pairingModeHost => 'استضافة';

  @override
  String get pairingModeJoin => 'انضمام';

  @override
  String get pairingChooseGame => 'اختر لعبة';

  @override
  String get pairingHostGame => 'استضف اللعبة';

  @override
  String pairingHostStartFailed(String error) {
    return 'تعذّر بدء اللعبة: $error';
  }

  @override
  String get pairingNotAdvertised =>
      'غير ظاهر تلقائيًا – يُدخل اللاعب الآخر العنوان.';

  @override
  String get pairingNoDiscoveryHost =>
      'لا بحث تلقائي على هذا الجهاز – يُدخل اللاعب الآخر العنوان.';

  @override
  String pairingHosting(String name, String game) {
    return '$name يستضيف $game';
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
  String get pairingGamesOnNetwork => 'ألعاب على الشبكة';

  @override
  String get pairingNoDiscoveryJoin =>
      'البحث التلقائي غير متاح على هذا الجهاز. أدخل العنوان أدناه.';

  @override
  String get pairingBrowseFailed =>
      'تعذّر البحث في الشبكة. أدخل العنوان أدناه.';

  @override
  String get pairingSearching => 'جارٍ البحث عن ألعاب…';

  @override
  String get pairingOtherVersion => 'إصدار مختلف من Klunki';

  @override
  String get pairingOrEnterAddress => 'أو أدخل عنوانًا';

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
  String pairingStatus(String name, String mark, String peer, String peerMark) {
    return 'أنت ($name، $mark) · الخصم: $peer ($peerMark)';
  }

  @override
  String netBarYou(String name) {
    return 'أنت ($name)';
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
      'فشلت إعادة الاتصال. هل المضيف ما زال في اللعبة؟';

  @override
  String get pairingBrowserJoin =>
      'الانضمام من متصفح (اكتب العنوان أو الصق الرابط):';

  @override
  String get pairingCopyLink => 'نسخ الرابط';

  @override
  String get pairingLinkCopied => 'تم نسخ الرابط';

  @override
  String get webJoinIntro =>
      'انضم من المتصفح إلى لعبة يستضيفها iPhone أو iPad أو جهاز Android أو الطرفية (klunki host). يعرض المضيف العنوان والرابط تحت «الانضمام من متصفح».';

  @override
  String get webJoinHttpsWarning =>
      'فُتحت هذه الصفحة عبر https. من هناك تحظر المتصفحات اتصالات ws:// بالشبكة المحلية. افتح Klunki عبر http://.';

  @override
  String get webJoinAddressLabel => 'IP أو IP:منفذ أو رابط ws:// أو klunki://';

  @override
  String webJoinAddressHelper(int port) {
    return 'المنفذ هو منفذ المتصفح (WebSocket) لدى المضيف؛ بدونه: $port.';
  }

  @override
  String get webJoinInvalidAddress =>
      'عنوان غير صالح. مثال: 192.168.1.20 أو 192.168.1.20:4748 أو klunki://join?h=…';

  @override
  String get webJoinHints =>
      'نصائح: هل هذا الجهاز على شبكة Wi-Fi نفسها التي عليها المضيف؟ غالبًا ما تحظر شبكات الضيوف الاتصال بين الأجهزة. يجب فتح الصفحة عبر http:// وليس https://. يجب أن يعمل على المضيف إصدار من Klunki يدعم المتصفح (يعرض «الانضمام من متصفح»).';

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
    return '$player يرتّب أولًا – يمكنك التحضير في الأثناء.';
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
  String goArmyOwn(String mark) {
    return 'جيشك ($mark)';
  }

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
  String get relayHostIntro =>
      'ينضم متصفح ثانٍ على شبكة Wi-Fi نفسها برمز الغرفة.';

  @override
  String get relayRoomCode => 'رمز الغرفة';

  @override
  String get relayWaitingHint =>
      'افتح الرابط على الجهاز الثاني أو امسح رمز QR. أو افتح Klunki هناك وأدخل رمز الغرفة.';

  @override
  String relayInfo(String address) {
    return 'المُرحِّل: $address';
  }

  @override
  String get relayJoinTitle => 'الانضمام برمز الغرفة';

  @override
  String get relayCodeHelper => '5 رموز. يعرض المتصفح المستضيف للعبة الرمز.';

  @override
  String get relayCodeInvalid =>
      'رمز غرفة غير صالح: 5 أحرف أو أرقام (بدون 0 وO و1 وI وL).';

  @override
  String get relayJoin => 'انضم إلى الغرفة';

  @override
  String relayJoining(String code) {
    return 'جارٍ الانضمام إلى الغرفة $code…';
  }

  @override
  String get relayAddressLabel => 'عنوان المُرحِّل';

  @override
  String get relayAddressHelper =>
      'حاسوب على شبكة Wi-Fi يشغّل «klunki relay»، مثلًا 192.168.1.20:4749';

  @override
  String get relayAddressAdvanced => 'متقدم: عنوان المُرحِّل';

  @override
  String get relayAddressInvalid =>
      'عنوان مُرحِّل غير صالح. مثال: 192.168.1.20:4749';

  @override
  String relayErrorUnknownCode(String code) {
    return 'لا توجد غرفة بالرمز $code. هل الرمز صحيح، وهل ما زال المضيف ينتظر؟';
  }

  @override
  String relayErrorRoomFull(String code) {
    return 'الغرفة $code ممتلئة: يلعب فيها اثنان بالفعل.';
  }

  @override
  String get relayErrorHostLeft => 'غادر المضيف الغرفة. انتهت اللعبة.';

  @override
  String get relayErrorExpired => 'انتهت صلاحية الغرفة (10 دقائق دون نشاط).';

  @override
  String relayErrorUnreachable(String address) {
    return 'لا يوجد مُرحِّل متاح على $address.';
  }

  @override
  String get relayErrorLost => 'انقطع الاتصال بالمُرحِّل.';

  @override
  String get relayStartHint =>
      'يتطلب اللعب بين متصفحين مُرحِّلًا. شغّله على حاسوب في شبكة Wi-Fi وافتح Klunki من عنوانه:';

  @override
  String relayRoomLost(String reason) {
    return '$reason ابدأ لعبة جديدة.';
  }

  @override
  String relayFromLink(String address) {
    return 'المرحّل من الرابط: $address';
  }

  @override
  String get relayLinkSaveDefault => 'حفظ كافتراضي';

  @override
  String get relayLinkUseSaved => 'استخدام المرحّل المحفوظ';

  @override
  String get relayLinkForeign =>
      'تنبيه: هذا الرابط يشير إلى مرحّل آخر، وليس إلى خادم هذه الصفحة. انضم فقط إذا كنت تثق بالمرسل: المرحّل الغريب يرى كل النقلات.';

  @override
  String get pairingSeatTaken =>
      'المقعد مشغول: هناك من يلعب هذه المباراة بالفعل. يمكن فقط لمن انضم أولاً أن يعود.';

  @override
  String get webJoinDirectTitle => 'أو اتصل بجهاز مضيف (تطبيق أو طرفية)';

  @override
  String get qrScanButton => 'مسح رمز QR';

  @override
  String get qrScanHint => 'وجّه الكاميرا نحو رمز QR الخاص بالمضيف.';

  @override
  String get qrScanNotKlunki =>
      'هذا ليس رمز Klunki. امسح رمز QR الذي تعرضه اللعبة عند الاستضافة.';

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
  String get relayGroupTitle => 'اللعب عبر المُرحِّل (رمز الغرفة)';

  @override
  String get relayChange => 'تغيير';

  @override
  String get relayNotSet => 'لم يُضبط مُرحِّل – أدخل عنوانًا';

  @override
  String relayUseDefault(String address) {
    return 'الافتراضي: $address';
  }

  @override
  String get relaySave => 'تطبيق';

  @override
  String get relayJoinIntro => 'يأتي رمز الغرفة من متصفح اختار «استضف اللعبة».';

  @override
  String get joinDirectTitle => 'الاتصال مباشرة بجهاز';

  @override
  String get joinDirectHelper =>
      'لهاتف أو جهاز لوحي أو طرفية تستضيف بنفسها: أدخل عنوان الجهاز (IP).';

  @override
  String get shellResign => 'استسلام';

  @override
  String get shellResignTitle => 'هل تريد الاستسلام حقًا؟';

  @override
  String shellResignBody(String player) {
    return 'تنتهي اللعبة الآن ويفوز $player.';
  }

  @override
  String get shellResignWho =>
      'من يستسلم؟ تنتهي اللعبة الآن ويفوز الطرف الآخر.';

  @override
  String shellResignPlayer(String player) {
    return '$player يستسلم';
  }

  @override
  String engineReasonCommonResigned(String player) {
    return 'استسلم $player';
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
  String get menuGameChess => 'شطرنج';

  @override
  String get menuDescChess => 'اللعبة الكلاسيكية: أوقِع ملك الخصم في كش مات.';

  @override
  String get chessWhite => 'الأبيض';

  @override
  String get chessBlack => 'الأسود';

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
}

// KLD-118 follow-up: the Mau-Mau "how to play" tour (once per device, never
// over the handover cover, again from the ? button) and the button
// hierarchy (what to do now filled, the alternative outlined).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/theme.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/profile/seen_tips.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

Future<GameController> _pump(
  WidgetTester tester, {
  List<String> a = const ['h7', 'cJ', 'h10', 'sK', 'd9', 'hQ'],
  List<String> b = const ['d7', 's8', 'c9', 'dA', 'h8'],
  String top = 'hK',
  List<String> stock = const ['c7', 'sQ', 'dK', 's10', 'c10', 'cA'],
}) async {
  tester.view.physicalSize = const Size(375, 667) * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(GameConfig('maumau', seed: 1));
  addTearDown(c.dispose);
  (c.game as MauMauGame).debugSetup(a: a, b: b, top: top, stock: stock);
  await tester.pumpWidget(
    MaterialApp(
      theme: KlunkiTheme.light,
      locale: const Locale('de'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: PlayerLabelsScope(
        labels: const PlayerLabels(names: {Player.a: 'Anna', Player.b: 'Ben'}),
        child: buildGameScreen(c),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return c;
}

Finder _key(String k) => find.byKey(Key(k));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

bool _filled(WidgetTester tester, String key) => tester.widget(_key(key)) is FilledButton;
bool _outlined(WidgetTester tester, String key) => tester.widget(_key(key)) is OutlinedButton;

void main() {
  group('tour', () {
    setUp(SeenTips.debugReset); // a fresh install

    testWidgets('shows once, three steps, never again', (tester) async {
      await _pump(tester);
      expect(_key('maumau-coach'), findsOneWidget);
      expect(_key('maumau-coach-step-1'), findsOneWidget);
      expect(
        find.text(
          'Tippe auf eine passende Karte, um sie zu legen. Passende Karten stehen höher und haben einen Rahmen.',
        ),
        findsOneWidget,
      );
      expect(SeenTips.shared.has(SeenTips.maumauIntro), isTrue);
      await _tap(tester, 'maumau-coach-next');
      expect(_key('maumau-coach-step-2'), findsOneWidget);
      await _tap(tester, 'maumau-coach-next');
      expect(_key('maumau-coach-step-3'), findsOneWidget);
      expect(_key('maumau-coach-skip'), findsNothing);
      expect(find.textContaining('„Mau!“'), findsOneWidget); // the house rule is on
      await _tap(tester, 'maumau-coach-done');
      expect(_key('maumau-coach'), findsNothing);
      // The game goes on as before.
      await tester.tapAt(tester.getTopLeft(_key('maumau-hand-h7')) + const Offset(10, 40));
      await tester.pumpAndSettle();
      expect(_key('handover-cover'), findsOneWidget);

      // Another game: no tour.
      await _pump(tester);
      expect(_key('maumau-coach'), findsNothing);
    });

    testWidgets('can be skipped', (tester) async {
      await _pump(tester);
      await _tap(tester, 'maumau-coach-skip');
      expect(_key('maumau-coach'), findsNothing);
      expect(SeenTips.shared.has(SeenTips.maumauIntro), isTrue);
    });

    testWidgets('never over the handover cover; after it on the next hand', (tester) async {
      SeenTips.shared.markFirst(SeenTips.maumauIntro);
      final c = await _pump(tester);
      await tester.tapAt(tester.getTopLeft(_key('maumau-hand-h7')) + const Offset(10, 40));
      await tester.pumpAndSettle();
      expect(_key('handover-cover'), findsOneWidget);
      SeenTips.debugReset(); // as if not seen yet
      await tester.pumpAndSettle();
      expect(_key('maumau-coach'), findsNothing);
      await _tap(tester, 'handover-continue');
      expect(_key('maumau-coach'), findsOneWidget);
      expect(c.game.currentPlayer, Player.b);
      expect(_key('maumau-hand-d7'), findsOneWidget, reason: "Ben's own hand under the tour");
    });

    testWidgets('the ? button shows it again', (tester) async {
      SeenTips.shared.markFirst(SeenTips.maumauIntro);
      await _pump(tester);
      expect(_key('maumau-coach'), findsNothing);
      await _tap(tester, 'maumau-help');
      expect(_key('maumau-coach-step-1'), findsOneWidget);
      await _tap(tester, 'maumau-coach-skip');
      expect(_key('maumau-coach'), findsNothing);
    });
  });

  group('buttons', () {
    setUp(() => SeenTips.shared.markFirst(SeenTips.maumauIntro));

    testWidgets('a card fits: drawing is the outlined alternative', (tester) async {
      await _pump(tester);
      expect(_outlined(tester, 'maumau-draw'), isTrue);
      expect(_key('maumau-stock-active'), findsOneWidget);
    });

    testWidgets('nothing fits at all: draw filled, the pile glows', (tester) async {
      await _pump(tester, a: const ['c8', 's9', 'd10', 'cQ', 'd8'], top: 'hK');
      expect(_filled(tester, 'maumau-draw'), isTrue);
      expect(_key('maumau-keep'), findsNothing);
      expect(_key('maumau-pass'), findsNothing);
      expect(_key('maumau-mau'), findsNothing);
    });

    testWidgets('"Mau!" due: filled, pressed: outlined with a tick', (tester) async {
      await _pump(tester, a: const ['h7', 'sK'], top: 'hK', stock: const ['dK']);
      expect(_filled(tester, 'maumau-mau'), isTrue);
      expect(_outlined(tester, 'maumau-draw'), isTrue);
      await _tap(tester, 'maumau-mau');
      expect(_outlined(tester, 'maumau-mau'), isTrue);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await _tap(tester, 'maumau-mau');
      expect(_filled(tester, 'maumau-mau'), isTrue);
    });

    testWidgets('"Mau!" not shown before it is due', (tester) async {
      await _pump(tester, a: const ['h7', 'sK', 'c8'], top: 'hK', stock: const ['dK']);
      expect(_key('maumau-mau'), findsNothing);
    });
  });
}

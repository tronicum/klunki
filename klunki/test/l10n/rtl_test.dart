// I18N-04: right-to-left layout for Arabic (ar) and Farsi (fa). The app
// chrome mirrors, the game boards and network addresses stay left-to-right.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/ui/games/quartett_card.dart';
import 'package:klunki/ui/games/schiffe/schiffe_grid.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_net/klunki_net.dart' show NetException;

import '../ui/pairing/pairing_test_utils.dart';
import '../ui/shell/shell_test_utils.dart';
import 'l10n_test_utils.dart';

const ar = Locale('ar');
const fa = Locale('fa');

TextDirection dirOf(WidgetTester tester, Finder f) => Directionality.of(tester.element(f));

Future<GameController> pumpIn(WidgetTester tester, String id, Locale locale, {Size? size}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  final c = GameController.hotSeat(GameConfig(id, seed: 1));
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c), locale: locale));
  await tester.pump();
  return c;
}

Future<void> continueHandover(WidgetTester tester) async {
  expect(find.byKey(handoverContinue), findsOneWidget);
  await tester.tap(find.byKey(handoverContinue));
  await tester.pump();
}

void main() {
  testWidgets('menu in ar is RTL: rows mirrored, chevron flipped', (tester) async {
    await tester.pumpWidget(klunkiApp(locale: ar));
    await tester.pumpAndSettle();
    final row = find.byKey(const Key('menu-connect4'));
    expect(row, findsOneWidget);
    expect(dirOf(tester, row), TextDirection.rtl);
    // The trailing chevron sits on the left in RTL.
    final chevron = find.descendant(of: row, matching: find.byIcon(Icons.chevron_right));
    expect(tester.getCenter(chevron).dx, lessThan(tester.getCenter(row).dx));
  });

  for (final locale in [ar, fa]) {
    for (final id in ['connect4', 'muehle', 'quartett-trumpf', 'quartett-sets', 'schiffe']) {
      testWidgets('$id in ${locale.languageCode}: status RTL, plays to the result dialog, history opens',
          (tester) async {
        await pumpIn(tester, id, locale, size: const Size(900, 1200));
        expect(tester.takeException(), isNull);
        expect(dirOf(tester, find.byKey(const Key('shell-status'))), TextDirection.rtl);
        await playToEnd(tester);
        expect(tester.takeException(), isNull);
        expect(find.byKey(resultDialog), findsOneWidget);
        expect(dirOf(tester, find.byKey(resultDialog)), TextDirection.rtl);
        // Leave the dialog via "Nochmal" and look at the (empty) history sheet.
        await tester.tap(find.descendant(of: find.byKey(resultDialog), matching: find.byType(FilledButton)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('shell-history')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('history-sheet')), findsOneWidget);
        expect(dirOf(tester, find.byKey(const Key('history-sheet'))), TextDirection.rtl);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Connect Four in ar: board is not mirrored, leftmost column is engine column 0', (tester) async {
    final c = await pumpIn(tester, 'connect4', ar);
    final col0 = find.byKey(const Key('c4-column-0'));
    final col6 = find.byKey(const Key('c4-column-6'));
    expect(dirOf(tester, col0), TextDirection.ltr);
    expect(tester.getCenter(col0).dx, lessThan(tester.getCenter(col6).dx));
    // Hint text around the board stays RTL.
    expect(dirOf(tester, find.byKey(const Key('shell-status'))), TextDirection.rtl);

    // Tap the left edge of the board: the piece lands in engine column 0.
    final left = tester.getRect(col0);
    await tester.tapAt(Offset(left.left + 4, left.center.dy));
    await tester.pump(const Duration(seconds: 1));
    expect(c.moves.single.move['col'], 0);
    expect((c.game as Connect4Game).board[0][0], Player.a);
  });

  testWidgets('Mühle in fa: board points are not mirrored', (tester) async {
    await pumpIn(tester, 'muehle', fa);
    // Point 0 is the top-left corner of the outer ring, point 2 the top-right.
    final p0 = find.byKey(const Key('muehle-point-0'));
    final p2 = find.byKey(const Key('muehle-point-2'));
    expect(dirOf(tester, p0), TextDirection.ltr);
    expect(tester.getCenter(p0).dx, lessThan(tester.getCenter(p2).dx));
  });

  testWidgets('Schiffe in fa: target grid A–J/1–10 is not mirrored and taps hit the right cell', (tester) async {
    final c = await pumpIn(tester, 'schiffe', fa, size: const Size(1180, 820));
    await tester.tap(find.byKey(const Key('sv-random')));
    await tester.pump();
    await continueHandover(tester);
    await tester.tap(find.byKey(const Key('sv-random')));
    await tester.pump();
    await continueHandover(tester);
    final g = c.game as SchiffeGame;
    expect(g.phase, SchiffePhase.battle);

    Finder target(int r, int col) => find.byKey(Key('sv-target-$r-$col'));
    expect(dirOf(tester, target(0, 0)), TextDirection.ltr);
    expect(tester.getCenter(target(0, 0)).dx, lessThan(tester.getCenter(target(0, 9)).dx));
    expect(tester.getCenter(target(0, 0)).dy, lessThan(tester.getCenter(target(9, 0)).dy));
    // Row letters sit left of column 1 (the label column comes first in LTR).
    final grid = find.ancestor(of: target(0, 0), matching: find.byType(SchiffeGrid));
    final labelA = find.descendant(of: grid, matching: find.text('A'));
    expect(tester.getCenter(labelA).dx, lessThan(tester.getCenter(target(0, 0)).dx));

    // Tap the cell at the grid position of C7 (row 2, col 6) by coordinates.
    final rect = tester.getRect(target(0, 0));
    final at = rect.topLeft + Offset(rect.width * 6.5, rect.height * 2.5);
    await tester.tapAt(at);
    await tester.pump();
    final shot = c.moves.last.move;
    expect([shot['row'], shot['col']], [2, 6]);
  });

  test('Quartett values use Western digits in ar and fa (fa would default to Persian digits)', () {
    final stat = QuartettDeck.cars.stats.first;
    expect(formatQuartettValue(stat, 2.7, locale: 'fa'), '2.7 ${stat.unit}');
    expect(formatQuartettValue(stat, 2.7, locale: 'ar'), '2.7 ${stat.unit}');
    expect(formatQuartettValue(stat, 650, locale: 'fa'), '650 ${stat.unit}');
    expect(formatQuartettValue(stat, 2.7), '2,7 ${stat.unit}');
  });

  testWidgets('pairing host in ar: IP:port text is laid out LTR', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    await tester.pumpWidget(localizedApp(
      PairingScreen(deps: testDeps(discovery: FakeDiscovery(), created: created)),
      locale: ar,
    ));
    expect(dirOf(tester, find.byKey(const Key('pair-name'))), TextDirection.rtl);
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
        what: 'host waiting view');

    final port = created.hosts.single.port!;
    final text = find.descendant(of: find.byKey(const Key('pair-address-text-0')), matching: find.byType(Text));
    final t = tester.widget<Text>(text);
    expect(t.data, '192.168.0.10:$port');
    expect(t.textDirection, TextDirection.ltr);
    // Aligned to the RTL start edge (right), like the text around it.
    expect(t.textAlign, TextAlign.right);
    await unmountAndSettleSockets(tester, created);
  });

  testWidgets('pairing join in fa: discovered host:port is isolated LTR inside the subtitle', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final created = CreatedTransports();
    final discovery = FakeDiscovery();
    await tester.pumpWidget(localizedApp(
      PairingScreen(deps: testDeps(discovery: discovery, created: created)),
      locale: fa,
    ));
    await tester.tap(find.text(lookupAppLocalizations(fa).pairingModeJoin));
    await tester.pump();
    discovery.addHost(const KlunkiHostInfo(
        name: 'iPad', host: '192.168.0.20', port: 4747, protocol: klunkiProtocolVersion, gameId: 'connect4'));
    await tester.pump();
    expect(find.textContaining('\u2066192.168.0.20:4747\u2069'), findsOneWidget);
    final manual = tester.widget<TextField>(find.byKey(const Key('pair-manual')));
    expect(manual.textDirection, TextDirection.ltr);
    await unmountAndSettleSockets(tester, created);
  });

  testWidgets('room join in ar (KLD-057b): code field LTR, code and relay address isolated LTR in the errors',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Object error = const NetException('relay: no room with code K7Q2M');
    await tester.pumpWidget(localizedApp(
      WebJoinScreen(
        pageUrl: Uri.parse('http://192.168.1.5:8000/'),
        deps: WebJoinDeps(
          joinTransport: (url, {required name}) => Future.error(StateError('unused')),
          relayJoin: (relay, code, {required name}) => Future.error(error),
        ),
      ),
      locale: ar,
    ));
    await tester.pump();
    expect(dirOf(tester, find.byKey(const Key('room-code'))), TextDirection.rtl);
    expect(tester.widget<TextField>(find.byKey(const Key('room-code'))).textDirection, TextDirection.ltr);
    Future<String> errorFor(Object e) async {
      error = e;
      await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
      await tester.testTextInput.receiveAction(TextInputAction.go);
      await tester.pump();
      await tester.pump();
      return tester.widget<Text>(find.byKey(const Key('room-error'))).data!;
    }

    expect(await errorFor(const NetException('relay: no room with code K7Q2M')), contains('\u2066K7Q 2M\u2069'));
    expect(await errorFor(const NetException('cannot connect: refused')), contains('\u2066192.168.1.5:8000\u2069'));
    final command = tester.widget<SelectableText>(find.byKey(const Key('relay-start-command')));
    expect(command.textDirection, TextDirection.ltr);
  });
}

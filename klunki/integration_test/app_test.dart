// On-device/simulator integration test of the real app (KLD-038c): menu,
// all five games hot-seat to the result dialog, the language picker with
// persistence across an app restart, and the native plugins
// (shared_preferences, network interfaces, mDNS advertising).
//
//   cd klunki
//   flutter test integration_test/app_test.dart -d <simulator-or-device-id>
//   # with screenshots on an iOS simulator (they share the Mac's disk):
//   flutter test integration_test/app_test.dart -d <sim-id> \
//     --dart-define=KLUNKI_SCREENSHOT_DIR=$PWD/build/e2e_screenshots/iphone \
//     --dart-define=KLUNKI_SCREENSHOT_PREFIX=iphone
//
// Not part of `flutter test` (that only runs test/).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/main.dart' as app;
import 'package:klunki/net/local_ip.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/shell/game_screen.dart' show playerMark;
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../test/e2e/muehle_script.dart';
import 'support.dart';

const _timeout = Timeout(Duration(minutes: 5));

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Forgets the saved language, so every test starts in the system language.
  Future<void> resetLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocaleController.prefsKey);
  }

  /// Starts the app the way `main()` does (saved language from the real
  /// shared_preferences) and waits for the menu. The player name is preset
  /// in memory (KLD-056), so "Raum starten" skips its first-run dialog.
  Future<LocaleController> startApp(WidgetTester tester) async {
    final controller = await LocaleController.load();
    await tester.pumpWidget(KlunkiApp(
      localeController: controller,
      playerNameController: PlayerNameController.memory(name: 'iPhone'),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
    return controller;
  }

  /// "Restarts" the app: unmounts the widget tree, then starts it again.
  Future<LocaleController> restartApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    return startApp(tester);
  }

  AppLocalizations l10nAt(WidgetTester tester, Finder f) => AppLocalizations.of(tester.element(f.first));

  Future<void> openGameFromMenu(WidgetTester tester, String id) async {
    await tapAndSettle(tester, find.byKey(Key('menu-$id')));
    // "Wer spielt?" (KLD-103): start with the default names.
    await pumpUntilFound(tester, find.byKey(const Key('hot-seat-names-ok')), what: '$id player names');
    await tapAndSettle(tester, find.byKey(const Key('hot-seat-names-ok')));
    await pumpUntilFound(tester, find.byKey(const Key('shell-status')), what: '$id screen');
  }

  /// The result dialog shows the controller's result; "Menü" goes back.
  Future<void> expectResultAndLeave(WidgetTester tester, {Player? winner}) async {
    await pumpUntilFound(tester, find.byKey(resultDialog), what: 'result dialog');
    await tester.pumpAndSettle();
    final c = controllerOf(tester);
    final r = c.game.result;
    expect(c.game.isOver, isTrue);
    if (winner != null) expect(r.winner, winner);
    final l10n = l10nAt(tester, find.byKey(resultDialog));
    final headline = r.draw || r.winner == null ? l10n.shellDraw : l10n.shellWins(playerMark(r.winner!));
    expect(find.descendant(of: find.byKey(resultDialog), matching: find.text(headline)), findsOneWidget);
    log('RESULT ${c.config.gameId}: $headline (${r.reason}) after ${c.moves.length} moves');
    await screenshot(binding, tester, '${c.config.gameId}_result');
    await tapAndSettle(tester, find.descendant(of: find.byKey(resultDialog), matching: find.text(l10n.shellMenu)));
    expect(find.byType(MenuScreen), findsOneWidget);
  }

  testWidgets('app start: main() shows the menu with all five games', timeout: _timeout, (tester) async {
    await resetLanguage();
    await app.main();
    await tester.pumpAndSettle();

    expect(find.byType(MenuScreen), findsOneWidget);
    expect(gameSpecs, hasLength(5));
    for (final spec in gameSpecs) {
      expect(find.byKey(Key('menu-${spec.id}')), findsOneWidget, reason: spec.id);
    }
    expect(find.byKey(const Key('menu-room-start'), skipOffstage: false), findsOneWidget,
        reason: 'rooms are offered on native platforms');
    expect(find.byKey(const Key('menu-room-join'), skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('language-button')), findsOneWidget);
    await screenshot(binding, tester, 'menu');
  });

  group('hot-seat to the end', () {
    testWidgets('Four in a Row by taps on the columns', timeout: _timeout, (tester) async {
      await resetLanguage();
      await startApp(tester);
      await openGameFromMenu(tester, 'connect4');
      final c = controllerOf(tester);

      // X stacks column 1, O column 2: X has four in a column after 7 drops.
      const columns = [0, 1, 0, 1, 0, 1, 0];
      for (var i = 0; i < columns.length; i++) {
        await tester.tap(find.byKey(Key('c4-column-${columns[i]}')));
        await pumpUntil(tester, () => c.moves.length == i + 1, what: 'drop #${i + 1}');
        await tester.pumpAndSettle();
      }
      expect((c.game as Connect4Game).board[0].take(4).toList(), List.filled(4, Player.a));
      await expectResultAndLeave(tester, winner: Player.a);
    });

    testWidgets('Mühle: the scripted 33-move game by taps on the points', timeout: _timeout, (tester) async {
      await resetLanguage();
      await startApp(tester);
      await openGameFromMenu(tester, 'muehle');
      final c = controllerOf(tester);

      for (final s in muehleScript) {
        for (final p in s.taps) {
          await tester.tap(find.byKey(Key('muehle-point-$p')));
          await tester.pump();
          await tester.pump();
        }
        await pumpUntil(tester, () => c.moves.length == s.index + 1, what: 'Mühle $s applied from taps');
        expect(c.moves.last.move, s.move, reason: '$s');
        if (s.index == 16) await screenshot(binding, tester, 'muehle_midgame');
      }
      expect(c.game.result.reason, muehleScriptReason);
      await expectResultAndLeave(tester, winner: muehleScriptWinner);
    });

    for (final id in ['quartett-trumpf', 'quartett-sets', 'schiffe']) {
      testWidgets('$id via the controller with the handover cover', timeout: _timeout, (tester) async {
        await resetLanguage();
        await startApp(tester);
        await openGameFromMenu(tester, id);
        var handovers = 0;

        if (id == 'schiffe') {
          // Both fleets with "Zufällig" + "Fertig", with the handover in between.
          await tapAndSettle(tester, find.byKey(const Key('sv-random')));
          await tapAndSettle(tester, find.byKey(const Key('sv-done')));
          await pumpUntilFound(tester, find.byKey(handoverContinue), what: 'handover after Anna fleet');
          await screenshot(binding, tester, 'handover_cover');
          await tapAndSettle(tester, find.byKey(handoverContinue));
          await tapAndSettle(tester, find.byKey(const Key('sv-random')));
          await tapAndSettle(tester, find.byKey(const Key('sv-done')));
          await pumpUntilFound(tester, find.byKey(handoverContinue), what: 'handover after Ben fleet');
          await tapAndSettle(tester, find.byKey(handoverContinue));
          handovers = 2;
          expect((controllerOf(tester).game as SchiffeGame).phase, SchiffePhase.battle);
          await screenshot(binding, tester, 'schiffe_battle');
        }

        handovers += await playToEndViaController(tester);
        expect(handovers, greaterThan(0), reason: 'the device was passed at least once');
        log('HANDOVERS $id: $handovers');
        await expectResultAndLeave(tester);
      });
    }
  });

  testWidgets('language picker: English, Arabic (RTL), System; persists across a restart', timeout: _timeout,
      (tester) async {
    await resetLanguage();
    final prefs = await SharedPreferences.getInstance();
    var controller = await startApp(tester);
    expect(controller.value, isNull, reason: 'starts in the system language');

    Future<void> pick(String key) async {
      await tapAndSettle(tester, find.byKey(const Key('language-button')));
      await tapAndSettle(tester, find.byKey(Key('language-$key')));
    }

    TextDirection direction() => Directionality.of(tester.element(find.byType(Scaffold).first));

    // English.
    await pick('en');
    expect(controller.value, const Locale('en'));
    expect(prefs.getString(LocaleController.prefsKey), 'en');
    expect(find.byTooltip('Language'), findsOneWidget);
    controller = await restartApp(tester);
    expect(controller.value, const Locale('en'), reason: 'English survives the restart');
    expect(find.byTooltip('Language'), findsOneWidget);
    expect(direction(), TextDirection.ltr);

    // Arabic: right to left.
    await pick('ar');
    expect(direction(), TextDirection.rtl);
    expect(find.byTooltip('اللغة'), findsOneWidget);
    controller = await restartApp(tester);
    expect(controller.value, const Locale('ar'), reason: 'Arabic survives the restart');
    expect(direction(), TextDirection.rtl);
    await screenshot(binding, tester, 'menu_arabic');

    // Back to System: the saved choice is removed.
    await pick('system');
    expect(controller.value, isNull);
    expect(prefs.getString(LocaleController.prefsKey), isNull);
    controller = await restartApp(tester);
    expect(controller.value, isNull, reason: 'System survives the restart');
    expect(find.byTooltip('اللغة'), findsNothing);
  });

  testWidgets('platform channels: shared_preferences, local IPs and mDNS on the pairing host screen',
      timeout: _timeout, (tester) async {
    await resetLanguage();

    // shared_preferences round trip through the native store.
    final prefs = await SharedPreferences.getInstance();
    final probe = 'probe-${DateTime.now().microsecondsSinceEpoch}';
    expect(await prefs.setString('klunki_it_probe', probe), isTrue);
    await prefs.reload();
    expect(prefs.getString('klunki_it_probe'), probe);
    await prefs.remove('klunki_it_probe');

    // Network interfaces through dart:io on the device.
    final addresses = await localIPv4Addresses();
    log('LOCAL_IPS $addresses');
    expect(addresses, isNotEmpty, reason: 'the device has a LAN IPv4 address');

    // Host screen: address list + QR + mDNS advertising.
    await startApp(tester);
    await tester.ensureVisible(find.byKey(const Key('menu-room-start')));
    await tapAndSettle(tester, find.byKey(const Key('menu-room-start')));
    expect(find.byKey(const Key('player-name-dialog')), findsNothing, reason: 'the name is already set');
    expect(tester.widget<TextField>(find.byKey(const Key('pair-name'))).controller?.text, 'iPhone');
    await tapAndSettle(tester, find.byKey(const Key('pair-game-muehle')));
    await tester.tap(find.byKey(const Key('pair-host-start')));
    await pumpUntilFound(tester, find.byKey(const Key('pair-host-waiting')), what: 'hosting');
    await tester.pump(const Duration(seconds: 2)); // give bonsoir time to register (or fail)
    await tester.pump();

    // Under "Erweitert" (KLD-098), found while collapsed.
    final first = tester.widget<Text>(find.descendant(
      of: find.byKey(const Key('pair-address-text-0'), skipOffstage: false),
      matching: find.byType(Text, skipOffstage: false),
      skipOffstage: false,
    ));
    log('HOST_ADDRESS ${first.data}');
    expect(first.data, startsWith('${addresses.first}:'));
    expect(find.byKey(const Key('pair-qr')), findsOneWidget);
    final l10n = l10nAt(tester, find.byKey(const Key('pair-host-waiting')));
    expect(find.text(l10n.pairingNotAdvertised), findsNothing, reason: 'mDNS advertising works');
    expect(find.text(l10n.pairingNoDiscoveryHost), findsNothing, reason: 'mDNS is available');
    await screenshot(binding, tester, 'pairing_host');

    await tapAndSettle(tester, find.byKey(const Key('pair-host-cancel')));
    expect(find.byKey(const Key('pair-host-start')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(MenuScreen), findsOneWidget);
  });
}

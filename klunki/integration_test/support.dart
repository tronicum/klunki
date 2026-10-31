// Shared helpers for the on-device integration tests (KLD-038c). Not a test
// file itself (no `_test` suffix), so `flutter test integration_test` only
// runs app_test.dart and network_test.dart.
//
// The tests run in IntegrationTestWidgetsFlutterBinding: real time, real
// platform channels, real sockets. So waiting is done by polling with real
// delays (see [pumpUntil]), never with fake time.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/ui/shell/game_screen.dart';

import '../test/game/legal_moves.dart';

const resultDialog = Key('result-dialog');
const handoverContinue = Key('handover-continue');

/// `--dart-define=KLUNKI_SCREENSHOT_DIR=/abs/path`: where [screenshot] writes
/// its PNGs. iOS simulator apps share the Mac's file system, so a Mac path
/// works there; elsewhere (Android, real devices) the PNG goes to the app's
/// temp directory and the path is printed.
const screenshotDir = String.fromEnvironment('KLUNKI_SCREENSHOT_DIR');

/// File name prefix for screenshots (e.g. `iphone`, `ipad`).
const screenshotPrefix = String.fromEnvironment('KLUNKI_SCREENSHOT_PREFIX', defaultValue: 'device');

/// Prints one tagged line the e2e scripts grep for.
void log(String line) {
  // ignore: avoid_print
  print('KLUNKI_IT $line');
}

/// Real-time pumping until [condition] holds; fails after [timeout].
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 20),
  Duration step = const Duration(milliseconds: 50),
  required String what,
}) async {
  final sw = Stopwatch()..start();
  while (!condition()) {
    if (sw.elapsed > timeout) fail('timed out after ${timeout.inSeconds}s waiting for: $what');
    await Future<void>.delayed(step);
    await tester.pump();
  }
}

/// [pumpUntil] for a finder.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder,
        {Duration timeout = const Duration(seconds: 20),
        Duration step = const Duration(milliseconds: 50),
        String? what}) =>
    pumpUntil(tester, () => finder.evaluate().isNotEmpty, timeout: timeout, step: step, what: what ?? '$finder');

/// Taps [finder] and settles (animations included). Only the state after
/// the tap must be able to settle; the current one may show a spinner.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300)); // scroll animation
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// The controller of the (single) [GameScreen] on screen.
GameController controllerOf(WidgetTester tester) => tester.widget<GameScreen>(find.byType(GameScreen)).controller;

/// Submits the first legal move through the controller and waits until the
/// move is accepted and the screen has rebuilt.
Future<void> playFirstLegalMove(WidgetTester tester) async {
  final c = controllerOf(tester);
  final before = c.moves.length;
  final moves = legalMoves(c.game);
  expect(moves, isNotEmpty, reason: 'a legal move exists');
  await c.submit(moves.first);
  await pumpUntil(tester, () => c.moves.length > before, what: 'move accepted');
  await tester.pump(); // post-frame: result dialog route
}

/// Plays the first legal move through the controller, tapping the handover
/// cover whenever it shows, until the result dialog opens. Returns the
/// number of handovers acknowledged.
Future<int> playToEndViaController(WidgetTester tester, {int maxSteps = 3000}) async {
  var handovers = 0;
  for (var i = 0; i < maxSteps; i++) {
    if (find.byKey(resultDialog).evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return handovers;
    }
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
      // The cover hides the board; nothing of the previous player shows.
      await tester.tap(find.byKey(handoverContinue));
      await tester.pump();
      handovers++;
    } else if (controllerOf(tester).game.isOver) {
      await tester.pump(const Duration(milliseconds: 50));
    } else {
      await playFirstLegalMove(tester);
    }
  }
  fail('game did not end within $maxSteps steps');
}

/// Takes a screenshot through the integration_test plugin (never fails the
/// test; a missing screenshot is only logged).
Future<void> screenshot(IntegrationTestWidgetsFlutterBinding binding, WidgetTester tester, String name) async {
  try {
    if (Platform.isAndroid) {
      // Android renders into a SurfaceView, which the plugin cannot read.
      await binding.convertFlutterSurfaceToImage();
    }
    // No pumpAndSettle: spinners (e.g. "waiting for the guest") never settle.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    final bytes = await binding.takeScreenshot('${screenshotPrefix}_$name');
    final dir = screenshotDir.isNotEmpty ? Directory(screenshotDir) : Directory('${Directory.systemTemp.path}/klunki_screenshots');
    await dir.create(recursive: true);
    final file = File('${dir.path}/${screenshotPrefix}_$name.png');
    await file.writeAsBytes(bytes);
    log('SCREENSHOT ${file.path}');
  } catch (e) {
    log('SCREENSHOT_FAILED $name: $e');
  }
}

/// FNV-1a (32 bit) of [text], as 8 hex digits: a short fingerprint of a move
/// list that both devices can print and the script can compare.
String fnv1a(String text) {
  var h = 0x811c9dc5;
  for (final b in utf8.encode(text)) {
    h ^= b;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

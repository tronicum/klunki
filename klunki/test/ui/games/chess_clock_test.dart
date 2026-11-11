// KLD-126: the chess clock in hot-seat, through the real chess screen with
// a fake time source: the two clocks, the running one highlighted, red with
// tenths under 10 s, "Zug bestätigen" (the clock switches only on
// "Ziehen"), the flag fall and its result, the pause cover (also when the
// app goes to the background), undo, and the choice in "Wer spielt?".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/profile/chess_clock_settings.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/profile/undo_settings.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/ui/games/chess/chess_clock_view.dart';
import 'package:klunki/ui/shell/confirm_move.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';

Finder _sq(String s) => find.byKey(Key('chess-sq-$s'));
String _clockText(WidgetTester tester, Player p) =>
    tester.widget<Text>(find.byKey(Key('chess-clock-text-${p.name}'))).data!;
BoxDecoration _face(WidgetTester tester, Player p) =>
    tester.widget<AnimatedContainer>(find.byKey(Key('chess-clock-${p.name}'))).decoration! as BoxDecoration;

Future<void> _tapMove(WidgetTester tester, String from, String to) async {
  await tester.tap(_sq(from));
  await tester.pump();
  await tester.tap(_sq(to));
  await tester.pump();
  await tester.pump();
}

/// A hot-seat chess screen with [control] and a fake clock; [advance] moves
/// the fake time and the test's timers together.
class _Clocked {
  int now = 0;
  late final GameController controller;
  HotSeatTransport get transport => controller.transport as HotSeatTransport;

  Future<void> pump(WidgetTester tester, ChessTimeControl control, {bool confirm = false}) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final config = GameConfig('chess', chessClock: control);
    controller = GameController(HotSeatTransport(config, clockNow: () => now),
        transportFactory: (c) => HotSeatTransport(c, clockNow: () => now));
    addTearDown(controller.dispose);
    await tester.pumpWidget(ConfirmMoveScope(
        settings: ConfirmMoveSettings.memory(hotSeatA: confirm, hotSeatB: confirm),
        child: localizedApp(buildGameScreen(controller))));
    await tester.pump();
  }

  /// Stops the clock's timers before the test ends (the flutter_test
  /// binding checks for pending timers before the tear-downs run).
  void stop() => transport.dispose();

  Future<void> advance(WidgetTester tester, int ms) async {
    now += ms;
    await tester.pump(Duration(milliseconds: ms));
    await tester.pump();
  }
}

void main() {
  setUp(() {
    ChessClockSettings.debugReset();
    UndoSettings.debugReset();
  });

  test('formatChessClock: m:ss, a started second shows, tenths under 10 s', () {
    expect(formatChessClock(300000), '5:00');
    expect(formatChessClock(299001), '5:00');
    expect(formatChessClock(299000), '4:59');
    expect(formatChessClock(10000), '0:10');
    expect(formatChessClock(9999), '9.9');
    expect(formatChessClock(400), '0.4');
    expect(formatChessClock(0), '0.0');
    expect(formatChessClock(-50), '0.0');
    expect(formatChessClock(3600000), '1:00:00');
  });

  testWidgets('two clocks: the running one highlighted, counting down; red with tenths under 10 s', (tester) async {
    final t = _Clocked();
    await t.pump(tester, const ChessTimeControl(5 * 60000));
    final scheme = Theme.of(tester.element(find.byKey(const Key('chess-clock-a')))).colorScheme;
    expect(_clockText(tester, Player.a), '5:00');
    expect(_clockText(tester, Player.b), '5:00');
    expect(_face(tester, Player.a).color, scheme.primary, reason: 'White runs');
    expect(_face(tester, Player.b).color, scheme.surfaceContainerHighest);
    await t.advance(tester, 2000);
    expect(_clockText(tester, Player.a), '4:58');
    await _tapMove(tester, 'e2', 'e4');
    expect(t.controller.moves, hasLength(1));
    expect(_face(tester, Player.b).color, scheme.primary, reason: 'the clock switched');
    await t.advance(tester, 300000 - 9500);
    expect(_clockText(tester, Player.b), '9.5');
    expect(_face(tester, Player.b).color, scheme.error);
    expect(_clockText(tester, Player.a), '4:58');
    await t.advance(tester, 100);
    expect(_clockText(tester, Player.b), '9.4', reason: 'repaints each tenth');
    // Screen readers hear the name and the time.
    expect(find.bySemanticsLabel(RegExp(r'^Uhr von .*: 9\.4$')), findsOneWidget);
    t.stop();
  });

  testWidgets('"Zug bestätigen": the clock switches only on "Ziehen"; the pending move costs the mover',
      (tester) async {
    final t = _Clocked();
    await t.pump(tester, const ChessTimeControl(5 * 60000, 10000), confirm: true);
    await t.advance(tester, 3000);
    await _tapMove(tester, 'e2', 'e4');
    expect(t.controller.moves, isEmpty);
    expect(t.transport.clock!.running, Player.a);
    await t.advance(tester, 4000);
    expect(_clockText(tester, Player.a), '4:53');
    await tester.tap(find.byKey(const Key('confirm-move-commit')));
    await tester.pump();
    await tester.pump();
    expect(t.controller.moves, hasLength(1));
    expect(t.transport.clock!.running, Player.b);
    expect(_clockText(tester, Player.a), '5:03', reason: '7 s used, 10 s added');
    t.stop();
  });

  testWidgets('flag fall: the time-out ends the game, "Zeit abgelaufen" in the result; final for undo',
      (tester) async {
    final t = _Clocked();
    await t.pump(tester, const ChessTimeControl(3000));
    await _tapMove(tester, 'e2', 'e4');
    await t.advance(tester, 1000);
    await t.advance(tester, 2000);
    await tester.pump(const Duration(milliseconds: 500));
    expect(t.controller.game.isOver, isTrue);
    expect(t.controller.moves.last.move, ChessGame.timeoutMove(Player.b));
    expect(t.controller.game.result.winner, Player.a);
    expect(find.byKey(const Key('result-dialog')), findsOneWidget);
    expect(find.textContaining('Zeit abgelaufen bei'), findsOneWidget);
    expect(_clockText(tester, Player.b), '0.0');
    expect(t.controller.canUndo, isFalse, reason: 'the time is up');
  });

  testWidgets('a move after the flag fell (its timer not run yet: a sleeping device) ends on time', (tester) async {
    final t = _Clocked();
    await t.pump(tester, const ChessTimeControl(3000));
    t.now += 4000; // real time went on, the timer did not fire
    await _tapMove(tester, 'e2', 'e4');
    expect(t.controller.moves.single.move, ChessGame.timeoutMove(Player.a));
    expect(t.controller.game.result.winner, Player.b);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('result-dialog')), findsOneWidget);
  });

  testWidgets('pause cover: both clocks stop, nothing moves; "Weiter" goes on; the app in the background pauses',
      (tester) async {
    final t = _Clocked();
    await t.pump(tester, const ChessTimeControl(5 * 60000));
    await t.advance(tester, 1000);
    await tester.tap(find.byKey(const Key('chess-pause')));
    await tester.pump();
    expect(find.byKey(const Key('chess-pause-cover')), findsOneWidget);
    expect(find.text('Pause – die Uhren stehen'), findsOneWidget);
    await t.advance(tester, 60000);
    expect(_clockText(tester, Player.a), '4:59');
    expect(t.transport.clock!.ticking, isFalse);
    await tester.tap(find.byKey(const Key('chess-resume')));
    await tester.pump();
    expect(find.byKey(const Key('chess-pause-cover')), findsNothing);
    await t.advance(tester, 1000);
    expect(_clockText(tester, Player.a), '4:58');
    // A call, the phone locked: the cover comes up by itself.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(t.transport.clockPaused, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const Key('chess-pause-cover')), findsOneWidget, reason: 'stays until "Weiter"');
    t.stop();
  });

  testWidgets('"Zug zurücknehmen" puts the clock back to before the move', (tester) async {
    final t = _Clocked();
    await t.pump(tester, const ChessTimeControl(5 * 60000, 10000));
    await t.advance(tester, 5000);
    await _tapMove(tester, 'e2', 'e4');
    await t.advance(tester, 7000);
    expect(_clockText(tester, Player.b), '4:53');
    expect(t.controller.undo(), isTrue);
    await tester.pump();
    expect(t.transport.clock!.running, Player.a);
    expect(_clockText(tester, Player.a), '4:55');
    expect(_clockText(tester, Player.b), '5:00');
    await t.advance(tester, 1000);
    expect(_clockText(tester, Player.a), '4:54');
    t.stop();
  });

  testWidgets('no clock: no clock faces, no pause button', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final c = GameController.hotSeat(const GameConfig('chess'));
    addTearDown(c.dispose);
    await tester.pumpWidget(localizedApp(buildGameScreen(c)));
    await tester.pump();
    expect(find.byKey(const Key('chess-clock-a')), findsNothing);
    expect(find.byKey(const Key('chess-pause')), findsNothing);
  });

  testWidgets('"Wer spielt?": the clock choice starts the game with it and is remembered', (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(KlunkiApp(
      localeController: LocaleController.memory(testLocale),
      playerNameController: PlayerNameController.memory(name: 'Anna'),
      hotSeatNames: HotSeatNamesController.memory(),
    ));
    await tester.ensureVisible(find.byKey(const Key('menu-chess-local')));
    await tester.tap(find.byKey(const Key('menu-chess-local')));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('chess-clock-none'))).selected, isTrue, reason: 'default');
    expect(find.text('15 Min + 10 s'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('chess-clock-900+10')));
    await tester.tap(find.byKey(const Key('chess-clock-900+10')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    // The clock ticks: no pumpAndSettle from here on.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final c = controllerOf(tester);
    expect(c.config.chessClock, const ChessTimeControl(15 * 60000, 10000));
    expect(ChessClockSettings.shared().control, const ChessTimeControl(15 * 60000, 10000));
    expect(find.byKey(const Key('chess-clock-a')), findsOneWidget);
    // Leave the game so its timers stop.
    c.transport.dispose();
  });
}

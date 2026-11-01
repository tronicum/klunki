// KLD-099: resigning and leaving a running game ask first, in the shared
// game shell. Network: always while the game runs (it ends for both
// devices); hot-seat: once the game is under way. The dialog closes itself
// when the game ends underneath it (e.g. the opponent resigns).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/legal_move_board.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import 'shell_test_utils.dart';

const _resign = Key('shell-resign');
const _resignDialog = Key('resign-dialog');
const _leaveDialog = Key('leave-dialog');
const _home = Key('home');

/// One device of a network game with the single local player [me]: own moves
/// are recorded in [sent] (what would go over the wire), the opponent plays
/// through [remote].
class _DeviceTransport implements GameTransport {
  _DeviceTransport(String gameId, this.me) : _inner = HotSeatTransport(GameConfig(gameId, seed: 1));

  final HotSeatTransport _inner;
  final Player me;
  final List<Map<String, dynamic>> sent = [];

  @override
  bool get fullInformation => false;
  @override
  GameConfig get config => _inner.config;
  @override
  Set<Player> get localPlayers => {me};
  @override
  Game get game => _inner.game;
  @override
  List<AcceptedMove> get moves => _inner.moves;
  @override
  Stream<AcceptedMove> get accepted => _inner.accepted;

  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async {
    if (Game.resignerOf(move) == null && game.currentPlayer != me) {
      return const SubmitResult.rejected(RejectReason.notYourTurn);
    }
    sent.add(move);
    return _inner.submitSync(move);
  }

  /// The opponent's move arrives.
  void remote(Map<String, dynamic> move) => expect(_inner.submitSync(move).isAccepted, isTrue);

  @override
  void dispose() => _inner.dispose();
}

/// Pushes the game screen over a home page, so back has somewhere to go.
Future<void> _pushGame(WidgetTester tester, GameController c, {PlayerLabels labels = const PlayerLabels()}) async {
  await tester.pumpWidget(localizedApp(Builder(
    builder: (context) => Scaffold(
      key: _home,
      body: Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PlayerLabelsScope(labels: labels, child: buildGameScreen(c)),
          )),
          child: const Text('open'),
        ),
      ),
    ),
  )));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.byType(GameScreen), findsOneWidget);
}

Future<(GameController, _DeviceTransport)> _network(WidgetTester tester, {String gameId = 'connect4'}) async {
  final t = _DeviceTransport(gameId, Player.b);
  final c = GameController(t);
  addTearDown(c.dispose);
  await _pushGame(tester, c,
      labels: const PlayerLabels(local: Player.b, names: {Player.a: 'Ada', Player.b: 'Bea'}));
  return (c, t);
}

Future<GameController> _hotSeat(WidgetTester tester, {String gameId = 'connect4'}) async {
  final c = GameController.hotSeat(GameConfig(gameId, seed: 1));
  addTearDown(c.dispose);
  await _pushGame(tester, c);
  return c;
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton));
  await tester.pumpAndSettle();
}

bool get _onHome => find.byKey(_home).evaluate().isNotEmpty && find.byType(GameScreen).evaluate().isEmpty;

void main() {
  group('network', () {
    testWidgets('resign: dialog, cancel keeps the game running', (tester) async {
      final (c, t) = await _network(tester);
      await tester.tap(find.byKey(_resign));
      await tester.pumpAndSettle();
      expect(find.byKey(_resignDialog), findsOneWidget);
      expect(find.text('Wirklich aufgeben?'), findsOneWidget);
      expect(find.text('Das Spiel endet für beide – Ada (X) gewinnt.'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Abbrechen'), findsOneWidget);
      final confirm = tester.widget<FilledButton>(find.byKey(const Key('resign-confirm')));
      expect(confirm.style?.backgroundColor?.resolve({}), Theme.of(tester.element(find.byKey(_resignDialog))).colorScheme.error,
          reason: 'destructive');

      await tester.tap(find.byKey(const Key('resign-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(_resignDialog), findsNothing);
      expect(t.sent, isEmpty);
      expect(c.game.isOver, isFalse);
      // The game goes on: the opponent moves, then this device.
      t.remote(legalMovesOf(c.game).first);
      await tester.pump();
      await playMove(tester);
      expect(t.sent, hasLength(1));
    });

    testWidgets('resign: confirm sends the resign', (tester) async {
      final (c, t) = await _network(tester);
      await tester.tap(find.byKey(_resign));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resign-confirm')));
      await tester.pumpAndSettle();
      expect(t.sent, [Game.resignMove(Player.b)]);
      expect(c.game.resignedBy, Player.b);
      expect(find.byKey(resultDialog), findsOneWidget);
      expect(find.text('Du hast aufgegeben'), findsOneWidget);
    });

    testWidgets('back button: "Spiel verlassen?", cancel stays, confirm leaves', (tester) async {
      final (c, _) = await _network(tester);
      await _back(tester);
      expect(find.byKey(_leaveDialog), findsOneWidget);
      expect(find.text('Spiel verlassen?'), findsOneWidget);
      expect(find.text('Die Verbindung wird getrennt, das Spiel endet für beide.'), findsOneWidget);
      expect(find.text('Verlassen'), findsOneWidget);

      await tester.tap(find.byKey(const Key('leave-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(_leaveDialog), findsNothing);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(c.game.isOver, isFalse);

      await _back(tester);
      await tester.tap(find.byKey(const Key('leave-confirm')));
      await tester.pumpAndSettle();
      expect(_onHome, isTrue);
    });

    testWidgets('even before the first move', (tester) async {
      final (c, _) = await _network(tester);
      expect(c.moves, isEmpty);
      await _back(tester);
      expect(find.byKey(_leaveDialog), findsOneWidget);
    });

    testWidgets('system back (Android back / predictive back) asks too', (tester) async {
      await _network(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(_leaveDialog), findsOneWidget);
      // A second back closes the dialog, not the game.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(_leaveDialog), findsNothing);
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('iOS: the back swipe is held back while the game runs', (tester) async {
      final (c, t) = await _network(tester);
      PageRoute<Object?> route() => ModalRoute.of(tester.element(find.byType(GameScreen)))! as PageRoute<Object?>;
      expect((route() as MaterialPageRoute<void>).popGestureEnabled, isFalse);
      t.remote(Game.resignMove(Player.a));
      await tester.pumpAndSettle();
      expect(c.game.isOver, isTrue);
      expect((route() as MaterialPageRoute<void>).popGestureEnabled, isTrue, reason: 'game over: leave freely');
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('the opponent resigns while the resign dialog is open: it closes, the result shows', (tester) async {
      final (c, t) = await _network(tester);
      await tester.tap(find.byKey(_resign));
      await tester.pumpAndSettle();
      expect(find.byKey(_resignDialog), findsOneWidget);

      t.remote(Game.resignMove(Player.a));
      await tester.pumpAndSettle();
      expect(find.byKey(_resignDialog), findsNothing);
      expect(find.byKey(resultDialog), findsOneWidget);
      expect(find.text('Du gewinnst!'), findsOneWidget);
      expect(t.sent, isEmpty, reason: 'no resign of our own');
      expect(c.game.resignedBy, Player.a);

      // "Menü" leaves without asking: the game is over.
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      expect(_onHome, isTrue);
    });

    testWidgets('the game ends while the leave dialog is open: it closes, the game stays', (tester) async {
      final (c, t) = await _network(tester);
      await _back(tester);
      expect(find.byKey(_leaveDialog), findsOneWidget);
      t.remote(Game.resignMove(Player.a));
      await tester.pumpAndSettle();
      expect(find.byKey(_leaveDialog), findsNothing);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byKey(resultDialog), findsOneWidget);
      expect(c.game.isOver, isTrue);
    });
  });

  group('hot-seat', () {
    testWidgets('untouched board: back leaves without asking', (tester) async {
      await _hotSeat(tester);
      await _back(tester);
      expect(find.byKey(_leaveDialog), findsNothing);
      expect(_onHome, isTrue);
    });

    testWidgets('one move by one side only: still no dialog', (tester) async {
      await _hotSeat(tester);
      await playMove(tester);
      await _back(tester);
      expect(_onHome, isTrue);
    });

    testWidgets('under way (each side moved): back asks, cancel stays, confirm leaves', (tester) async {
      final c = await _hotSeat(tester);
      await playMove(tester);
      await playMove(tester);
      expect(c.moves.map((m) => m.player).toSet(), {Player.a, Player.b});
      await _back(tester);
      expect(find.byKey(_leaveDialog), findsOneWidget);
      expect(find.text('Spiel verlassen?'), findsOneWidget);
      expect(find.text('Das laufende Spiel wird abgebrochen.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('leave-cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(GameScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(_leaveDialog), findsOneWidget);
      await tester.tap(find.byKey(const Key('leave-confirm')));
      await tester.pumpAndSettle();
      expect(_onHome, isTrue);
    });

    testWidgets('after the game: back leaves without asking', (tester) async {
      final c = await _hotSeat(tester);
      await playMove(tester);
      await playMove(tester);
      await c.resign(Player.a);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      expect(_onHome, isTrue);
    });

    for (final id in appGameSpecs.map((s) => s.id)) {
      testWidgets('$id: mid-game back asks, the untouched board does not', (tester) async {
        final c = await _hotSeat(tester, gameId: id);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(_leaveDialog), findsNothing);
        expect(_onHome, isTrue);

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        for (var i = 0; i < 4; i++) {
          if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
            await tester.tap(find.byKey(handoverContinue));
            await tester.pump();
          }
          await playMove(tester);
        }
        expect(c.game.isOver, isFalse);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(_leaveDialog), findsOneWidget);
      });
    }
  });
}

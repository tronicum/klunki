// KLD-122: "Zug bestätigen" in hot-seat chess, played through the real UI:
// chosen per player in "Wer spielt?" (Anna on, Ben off), changed in the
// game's "Spielernamen" dialog, tap and drag, a capture, promotion with
// confirmation, and a draw offer / resign / undo that drop the pending move.
// The network side is in chess_network_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/klunki_app.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/ui/games/chess/chess_board.dart';
import 'package:klunki/ui/player_name_dialog.dart';
import 'package:klunki/ui/shell/confirm_move.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import '../shell/shell_test_utils.dart';
import '../../support/shell_menu.dart';

Finder _sq(String s) => find.byKey(Key('chess-sq-$s'));
ChessSquareView _view(WidgetTester tester, String s) => tester.widget<ChessSquareView>(_sq(s));
const _bar = Key('confirm-move-bar');
const _commit = Key('confirm-move-commit');
const _back = Key('confirm-move-back');

Future<void> _tapKey(WidgetTester tester, Key k) async {
  await tester.tap(find.byKey(k));
  await tester.pump();
  await tester.pump();
}

Future<void> _tapMove(WidgetTester tester, String from, String to) async {
  await tester.tap(_sq(from));
  await tester.pump();
  await tester.tap(_sq(to));
  await tester.pump();
  await tester.pump();
}

Future<void> _dragMove(WidgetTester tester, String from, String to) async {
  await tester.drag(_sq(from), tester.getCenter(_sq(to)) - tester.getCenter(_sq(from)));
  await tester.pump();
  await tester.pump();
}

String _hint(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('shell-hint'))).data!;

ChessGame _game(GameController c) => c.game as ChessGame;

const _wp = ChessPiece(ChessColor.white, ChessPieceType.pawn);
const _bp = ChessPiece(ChessColor.black, ChessPieceType.pawn);

/// A hot-seat chess screen with [settings] (no menu).
Future<GameController> _pumpChess(WidgetTester tester, ConfirmMoveSettings settings) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final c = GameController.hotSeat(const GameConfig('chess'));
  addTearDown(c.dispose);
  await tester.pumpWidget(ConfirmMoveScope(settings: settings, child: localizedApp(buildGameScreen(c))));
  await tester.pump();
  return c;
}

Future<void> _setup(WidgetTester tester, GameController c, List<String> moves) async {
  for (final m in moves) {
    final r = await c.submit({'action': 'move', 'from': m.substring(0, 2), 'to': m.substring(2)});
    expect(r.isAccepted, isTrue, reason: m);
  }
  await tester.pump();
}

void main() {
  setUp(() {
    ConfirmMoveSettings.debugReset();
    // Only taps a finger could make.
    WidgetController.hitTestWarningShouldBeFatal = true;
  });
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('"Wer spielt?": Anna on, Ben off; Anna\'s moves wait (tap, drag, capture), Ben\'s go at once',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final settings = ConfirmMoveSettings.memory();
    await tester.pumpWidget(ConfirmMoveScope(
      settings: settings,
      child: KlunkiApp(
        localeController: LocaleController.memory(testLocale),
        playerNameController: PlayerNameController.memory(name: 'Anna'),
        hotSeatNames: HotSeatNamesController.memory(),
      ),
    ));
    await tester.ensureVisible(find.byKey(const Key('menu-chess-local')));
    await tester.tap(find.byKey(const Key('menu-chess-local')));
    await tester.pumpAndSettle();
    // One switch per player, on by default in hot-seat too; the helper once.
    for (final m in ['X', 'O']) {
      expect(tester.widget<SwitchListTile>(find.byKey(Key('hot-seat-confirm-$m'))).value, isTrue, reason: m);
    }
    expect(find.text('Ein Zug zählt erst nach einem Tipp auf „Ziehen“.'), findsOneWidget);
    // Ben turns it off.
    await tester.tap(find.byKey(const Key('hot-seat-confirm-O')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    await tester.pumpAndSettle();
    expect(settings.hotSeat(Player.a), isTrue);
    expect(settings.hotSeat(Player.b), isFalse);
    expect(settings.network, isTrue, reason: 'the network choice is separate');
    final c = controllerOf(tester);
    // No network toggle in hot-seat.
    expect(find.byKey(const Key('shell-confirm-move')), findsNothing);

    // Anna taps e2-e4: shown, not played.
    await _tapMove(tester, 'e2', 'e4');
    expect(c.moves, isEmpty);
    expect(find.byKey(_bar), findsOneWidget);
    expect(_view(tester, 'e4').piece, _wp);
    expect(_view(tester, 'e4').pendingTo, isTrue);
    expect(_view(tester, 'e2').piece, isNull);
    expect(_view(tester, 'e2').pendingFrom, _wp);
    expect(find.byKey(const Key('chess-pending-from')), findsOneWidget);
    expect(_hint(tester), 'Passt der Zug? Tippe auf „Ziehen“ oder „Anders ziehen“.');
    expect(find.text('Ziehen'), findsOneWidget);
    expect(find.text('Anders ziehen'), findsOneWidget);
    // "Anders ziehen": as before.
    await _tapKey(tester, _back);
    expect(find.byKey(_bar), findsNothing);
    expect(_view(tester, 'e2').piece, _wp);
    expect(_view(tester, 'e4').piece, isNull);
    expect(_hint(tester), 'Tippe eine Figur an, um sie zu ziehen.');
    // Dragged instead, then "Ziehen".
    await _dragMove(tester, 'd2', 'd4');
    expect(c.moves, isEmpty);
    expect(_view(tester, 'd4').pendingTo, isTrue);
    await _tapKey(tester, _commit);
    expect(_game(c).sanHistory, ['d4']);
    expect(find.byKey(_bar), findsNothing);

    // Ben (off): the move counts at once, tap and drag alike.
    await _tapMove(tester, 'e7', 'e5');
    expect(_game(c).sanHistory, ['d4', 'e5']);
    expect(find.byKey(_bar), findsNothing);

    // Anna captures: the taken pawn small and faint on its square.
    await _tapMove(tester, 'd4', 'e5');
    expect(_view(tester, 'e5').piece, _wp);
    expect(_view(tester, 'e5').pendingCapture, _bp);
    expect(find.byKey(const Key('chess-pending-capture')), findsOneWidget);
    expect(_game(c).sanHistory, hasLength(2));
    await _tapKey(tester, _commit);
    expect(_game(c).sanHistory, ['d4', 'e5', 'dxe5']);

    // Ben's choice changes in "Spielernamen" during the game.
    await _dragMove(tester, 'b8', 'c6');
    expect(_game(c).sanHistory.last, 'Nc6');
    await tapShellMenuItem(tester, 'shell-names');
    expect(tester.widget<SwitchListTile>(find.byKey(const Key('hot-seat-confirm-X'))).value, isTrue);
    await tester.tap(find.byKey(const Key('hot-seat-confirm-X')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hot-seat-confirm-O')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    await tester.pumpAndSettle();
    expect(settings.hotSeat(Player.a), isFalse);
    expect(settings.hotSeat(Player.b), isTrue);
    await _tapMove(tester, 'g1', 'f3');
    expect(_game(c).sanHistory.last, 'Nf3', reason: 'Anna now off');
    await _tapMove(tester, 'g8', 'f6');
    expect(find.byKey(_bar), findsOneWidget, reason: 'Ben now on');
    expect(_game(c).sanHistory.last, 'Nf3');
    await _tapKey(tester, _commit);
    expect(_game(c).sanHistory.last, 'Nf6');
  });

  testWidgets('the hot-seat choice is saved and comes back', (tester) async {
    SharedPreferences.setMockInitialValues({});
    ConfirmMoveSettings.debugReset(loaded: true);
    final s = ConfirmMoveSettings.shared();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect((s.network, s.hotSeat(Player.a), s.hotSeat(Player.b)), (true, true, true), reason: 'the defaults: on');
    await s.setHotSeat(Player.a, false);
    await s.setNetwork(false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ConfirmMoveSettings.prefsKeyHotSeatA), isFalse);
    expect(prefs.getBool(ConfirmMoveSettings.prefsKeyNetwork), isFalse);
    // A fresh start reads them back.
    ConfirmMoveSettings.debugReset(loaded: true);
    final again = ConfirmMoveSettings.shared();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    expect((again.network, again.hotSeat(Player.a), again.hotSeat(Player.b)), (false, false, true));
    expect(prefs.getBool(ConfirmMoveSettings.prefsKeyHotSeatB), isNull, reason: 'only a choice is stored');
  });

  testWidgets('promotion: the piece first, then "Ziehen" shows and plays it; "Anders ziehen" keeps the pawn',
      (tester) async {
    final c = await _pumpChess(tester, ConfirmMoveSettings.memory(hotSeatA: true));
    await _setup(tester, c, ['a2a4', 'b7b5', 'a4b5', 'a7a6', 'b5a6', 'c8b7', 'a6b7', 'b8c6']);
    // Cancel in the picker: nothing pending.
    await _tapMove(tester, 'b7', 'a8');
    expect(find.byKey(const Key('chess-promotion')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chess-promote-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bar), findsNothing);
    // A knight: on a8 with the rook faint under it, not played yet.
    await _tapMove(tester, 'b7', 'a8');
    await tester.tap(find.byKey(const Key('chess-promote-n')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bar), findsOneWidget);
    expect(_view(tester, 'a8').piece, const ChessPiece(ChessColor.white, ChessPieceType.knight));
    expect(_view(tester, 'a8').pendingCapture, const ChessPiece(ChessColor.black, ChessPieceType.rook));
    expect(_view(tester, 'b7').pendingFrom, _wp);
    expect(c.moves, hasLength(8));
    await _tapKey(tester, _back);
    expect(_view(tester, 'b7').piece, _wp);
    expect(_view(tester, 'a8').piece, const ChessPiece(ChessColor.black, ChessPieceType.rook));
    // Dragged this time, a queen, "Ziehen".
    await _dragMove(tester, 'b7', 'a8');
    await tester.tap(find.byKey(const Key('chess-promote-q')));
    await tester.pumpAndSettle();
    expect(_view(tester, 'a8').piece, const ChessPiece(ChessColor.white, ChessPieceType.queen));
    expect(c.moves, hasLength(8));
    await _tapKey(tester, _commit);
    expect(_game(c).sanHistory.last, 'bxa8=Q');
  });

  testWidgets('a draw offer, an undo or a resign drops the pending move', (tester) async {
    final c = await _pumpChess(tester, ConfirmMoveSettings.memory(hotSeatA: true, hotSeatB: true));
    await _tapMove(tester, 'e2', 'e4');
    await _tapKey(tester, _commit);
    await _tapMove(tester, 'e7', 'e5');
    expect(find.byKey(_bar), findsOneWidget);
    // "Zug zurücknehmen" takes back Anna's e4; Ben's pending move is gone too.
    await _tapKey(tester, const Key('shell-undo'));
    expect(find.byKey(_bar), findsNothing);
    expect(c.moves, isEmpty);
    expect(_view(tester, 'e7').piece, _bp);
    expect(_view(tester, 'e2').piece, _wp);

    // Pending, then a draw offer instead.
    await _tapMove(tester, 'e2', 'e4');
    expect(find.byKey(_bar), findsOneWidget);
    await tester.tap(find.byKey(const Key('chess-offer-draw')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('chess-offer-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(_bar), findsNothing);
    expect(c.moves.single.move['action'], 'offerDraw');
    expect(_view(tester, 'e2').piece, _wp);
    await tester.tap(find.byKey(const Key('chess-draw-decline')));
    await tester.pumpAndSettle();

    // Pending, then Anna resigns.
    await _tapMove(tester, 'e2', 'e4');
    expect(find.byKey(_bar), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell-resign')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('resign-a')));
    await tester.pumpAndSettle();
    expect(c.game.isOver, isTrue);
    expect(find.byKey(_bar), findsNothing);
    expect([for (final m in c.moves) m.move['action']], ['offerDraw', 'declineDraw', 'resign']);
  });
}

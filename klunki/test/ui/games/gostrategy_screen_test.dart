import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_board.dart';
import 'package:klunki/ui/games/gostrategy/gostrategy_pieces.dart';
import 'package:klunki/ui/games/gostrategy_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

/// Hot-seat transport over a prepared [GoStrategyGame.position] (tests only:
/// a position is not reproducible from a [GameConfig], so there is no undo).
class PositionTransport implements GameTransport {
  PositionTransport(this._game);

  final GoStrategyGame _game;
  final List<AcceptedMove> _moves = [];
  final StreamController<AcceptedMove> _accepted = StreamController.broadcast(sync: true);

  @override
  GameConfig get config => const GameConfig('gostrategy', seed: 1);
  @override
  Set<Player> get localPlayers => const {Player.a, Player.b};
  @override
  Game get game => _game;
  // A prepared position cannot be replayed from [config]: no preview copies.
  @override
  bool get fullInformation => false;
  @override
  List<AcceptedMove> get moves => List.unmodifiable(_moves);
  @override
  Stream<AcceptedMove> get accepted => _accepted.stream;

  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async {
    if (_game.isOver) return const SubmitResult.rejected(RejectReason.gameOver);
    // The player to move, or the resigner for a resign (KLD-065).
    final player = _game.playerOf(move);
    final event = _game.applyMove(Map.unmodifiable(move));
    if (event == null) return const SubmitResult.rejected(RejectReason.illegal);
    final m = AcceptedMove(index: _moves.length, player: player, move: move, event: event);
    _moves.add(m);
    _accepted.add(m);
    return SubmitResult.accepted(m);
  }

  @override
  void dispose() => _accepted.close();
}

Finder cell(int sq) => find.byKey(Key('go-cell-$sq'));
Finder setupCell(int i) => find.byKey(Key('go-setup-$i'));
GoSquareView squareOf(WidgetTester t, int sq) => t.widget<GoSquareView>(cell(sq));
GoStrategyGame gameOf(GameController c) => c.game as GoStrategyGame;
const reveal = Key('go-reveal');

/// Taps and pumps twice (the hint line is updated after the frame).
Future<void> tapOn(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

Future<void> tapKey(WidgetTester tester, String key) => tapOn(tester, find.byKey(Key(key)));

Future<void> acknowledge(WidgetTester tester) async {
  expect(find.byKey(handoverContinue), findsOneWidget);
  await tapOn(tester, find.byKey(handoverContinue));
}

/// Lets a running fight reveal run out (it starts on the next frame).
Future<void> finishReveal(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(goRevealDuration);
  await tester.pump(const Duration(milliseconds: 500));
}

double revealValue(WidgetTester tester) =>
    (tester.widget<AnimatedBuilder>(find.descendant(of: find.byKey(reveal), matching: find.byType(AnimatedBuilder)).first)
            .listenable as Animation<double>)
        .value;

/// The arrangement the setup editor shows, read from its tiles.
List<GoPiece> shownSetup(WidgetTester tester) => [
      for (var i = 0; i < 40; i++)
        tester.widget<GoPieceTile>(find.descendant(of: setupCell(i), matching: find.byType(GoPieceTile))).piece!,
    ];

/// Pumps a hot-seat game over [game] (a prepared position).
Future<GameController> pumpPosition(WidgetTester tester, GoStrategyGame game, {bool reduceMotion = false}) async {
  final c = GameController(PositionTransport(game));
  addTearDown(c.dispose);
  Widget screen = GoStrategyScreen(controller: c);
  if (reduceMotion) {
    screen = Builder(
      builder: (context) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: GoStrategyScreen(controller: c)),
    );
  }
  await tester.pumpWidget(localizedApp(screen));
  await tester.pump();
  return c;
}

/// Phone portrait size (the board above the armies panel).
void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Both armies set up through "Fertig" (with the handover in between).
Future<void> setUpBoth(WidgetTester tester, GameController c) async {
  await tapKey(tester, 'go-done');
  await acknowledge(tester);
  await tapKey(tester, 'go-done');
  await acknowledge(tester);
  expect(gameOf(c).phase, GoStrategyPhase.play);
}

void main() {
  group('setup', () {
    testWidgets('starts from a random setup with legend and counts; shuffle and swap; Fertig submits', (tester) async {
      phone(tester);
      final c = await pumpGame(tester, 'gostrategy');
      expect(find.text('Stelle deine Armee auf (X)'), findsOneWidget);
      expect(find.text('Tippe zwei Figuren an, um sie zu tauschen. Dann „Fertig“.'), findsOneWidget);
      expect(find.byKey(const Key('go-legend')), findsOneWidget);
      expect(find.text('Hauptmann ×4'), findsOneWidget);
      expect(find.text('Aufklärer ×8'), findsOneWidget);
      expect(find.text('Bombe ×6'), findsOneWidget);
      expect(find.textContaining('Nur Mineure entschärfen Bomben'), findsOneWidget);

      // The initial arrangement is the seeded random setup of X.
      final first = shownSetup(tester);
      expect(first, GoStrategyGame.randomSetup(c.config.seed * 2));

      // Shuffle gives another valid arrangement.
      await tapKey(tester, 'go-shuffle');
      final shuffled = shownSetup(tester);
      expect(GoStrategyGame.isValidSetup([for (final p in shuffled) p.id]), isTrue);
      expect(shuffled, isNot(first));

      // Swap: tap index 0, then 39.
      await tapOn(tester, setupCell(0));
      expect(find.textContaining('gewählt – tippe eine zweite Figur'), findsOneWidget);
      await tapOn(tester, setupCell(39));
      final swapped = shownSetup(tester);
      expect(swapped[0], shuffled[39]);
      expect(swapped[39], shuffled[0]);
      expect(swapped.sublist(1, 39), shuffled.sublist(1, 39));
      // Tapping the same tile twice deselects (no swap).
      await tapOn(tester, setupCell(5));
      await tapOn(tester, setupCell(5));
      expect(shownSetup(tester), swapped);

      await tapKey(tester, 'go-done');
      expect(c.moves.single.move, GoStrategyGame.setupMove(swapped));
      expect(describeGoStrategyMove(deL10n, c.moves.single), 'stellt die Armee auf');
      // X's army sits on rows 6–9 in setup order.
      final truth = gameOf(c).board;
      for (var i = 0; i < 40; i++) {
        expect(truth[GoStrategyGame.setupSquare(Player.a, i)].piece, swapped[i]);
      }
    });

    testWidgets('hot-seat: the cover hides X\'s setup; O gets a fresh editor and sees nothing of X', (tester) async {
      phone(tester);
      final c = await pumpGame(tester, 'gostrategy');
      final xSetup = shownSetup(tester);
      await tapKey(tester, 'go-done');
      expect(c.needsHandover, isTrue);
      expect(find.text('Gib das Gerät an O weiter'), findsOneWidget);
      expect(find.byKey(const Key('go-cover-fight')), findsNothing, reason: 'no fight yet');
      expect(setupCell(0).hitTestable(), findsNothing);
      await acknowledge(tester);

      expect(find.text('Stelle deine Armee auf (O)'), findsOneWidget);
      expect(shownSetup(tester), GoStrategyGame.randomSetup(c.config.seed * 2 + 1));
      // Only O's own (blue) tiles anywhere, no X piece.
      for (final t in tester.widgetList<GoPieceTile>(find.byType(GoPieceTile))) {
        expect(t.owner, Player.b);
      }
      expect(xSetup, isNotEmpty);

      await tapKey(tester, 'go-done');
      expect(c.needsHandover, isTrue);
      await acknowledge(tester);
      // X's turn: X's own pieces known, O's all hidden backs.
      expect(find.text('X ist am Zug'), findsOneWidget);
      for (final sq in GoStrategyGame.homeSquares(Player.b)) {
        final v = squareOf(tester, sq);
        expect(v.cell.owner, Player.b);
        expect(v.cell.piece, isNull, reason: 'O piece on $sq is hidden');
      }
      for (final sq in GoStrategyGame.homeSquares(Player.a)) {
        expect(squareOf(tester, sq).cell.piece, isNotNull);
      }
    });
  });

  group('board', () {
    testWidgets('rotated per player: own army at the bottom, LTR in every locale', (tester) async {
      phone(tester);
      final c = await pumpGame(tester, 'gostrategy');
      await setUpBoth(tester, c);
      // X: square 0 (row 0) at the top left, 99 at the bottom right.
      expect(tester.getCenter(cell(0)).dy, lessThan(tester.getCenter(cell(99)).dy));
      expect(tester.getCenter(cell(0)).dx, lessThan(tester.getCenter(cell(9)).dx));

      // X moves, O takes over: the board is turned by 180°.
      final m = gameOf(c).legalMoves.first;
      await tapOn(tester, cell(m['from'] as int));
      await tapOn(tester, cell(m['to'] as int));
      await acknowledge(tester);
      expect(find.text('O ist am Zug'), findsOneWidget);
      expect(tester.getCenter(cell(0)).dy, greaterThan(tester.getCenter(cell(99)).dy));
      expect(tester.getCenter(cell(0)).dx, greaterThan(tester.getCenter(cell(9)).dx));
      // O's own front row (squares 30–39) is now just above the lakes, below them O's back row.
      expect(tester.getCenter(cell(39)).dy, greaterThan(tester.getCenter(cell(42)).dy));
    });

    testWidgets('in ar the board stays LTR (square 0 left of square 9 for X)', (tester) async {
      phone(tester);
      final c = await pumpGame(tester, 'gostrategy', locale: const Locale('ar'));
      await setUpBoth(tester, c);
      expect(tester.getCenter(cell(0)).dx, lessThan(tester.getCenter(cell(9)).dx));
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap a piece: legal targets highlighted; tap a target: the move', (tester) async {
      phone(tester);
      // X captain on 64 (open front), X bomb on 70; O flag far away.
      final c = await pumpPosition(
        tester,
        GoStrategyGame.position({
          64: (Player.a, GoPiece.captain),
          70: (Player.a, GoPiece.bomb),
          99: (Player.a, GoPiece.flag),
          0: (Player.b, GoPiece.flag),
          9: (Player.b, GoPiece.sergeant),
        }),
      );
      expect(find.text('Tippe eine deiner Figuren an, dann ein markiertes Feld.'), findsOneWidget);
      await tapOn(tester, cell(64));
      expect(squareOf(tester, 64).selected, isTrue);
      final marked = {for (var sq = 0; sq < 100; sq++) if (squareOf(tester, sq).target) sq};
      expect(marked, gameOf(c).targetsFrom(64).toSet());
      expect(marked, {54, 74, 63, 65});
      expect(find.text('Hauptmann (6): tippe ein markiertes Feld.'), findsOneWidget);

      // A bomb cannot move.
      await tapOn(tester, cell(70));
      expect(find.text('Bombe kann gerade nicht ziehen.'), findsOneWidget);

      // Not a target: tapping an empty square deselects.
      await tapOn(tester, cell(64));
      await tapOn(tester, cell(20));
      expect(squareOf(tester, 64).selected, isFalse);
      expect(c.moves, isEmpty);

      await tapOn(tester, cell(64));
      await tapOn(tester, cell(54));
      expect(c.moves.single.move, {'action': 'move', 'from': 64, 'to': 54});
      expect(describeGoStrategyMove(deL10n, c.moves.single), contains('zieht'));
      expect(c.needsHandover, isTrue);
      await acknowledge(tester);
      // O sees X's captain as a moved hidden piece with the marker.
      final v = squareOf(tester, 54);
      expect(v.cell.owner, Player.a);
      expect(v.cell.piece, isNull);
      expect(v.cell.moved, isTrue);
      expect(find.descendant(of: cell(54), matching: find.byKey(goMovedMarkerKey)), findsOneWidget);
      expect(squareOf(tester, 54).lastMove, isTrue);
    });

    testWidgets('a scout shows the whole free line, up to and including an enemy', (tester) async {
      phone(tester);
      await pumpPosition(
        tester,
        GoStrategyGame.position({
          90: (Player.a, GoPiece.scout),
          99: (Player.a, GoPiece.flag),
          30: (Player.b, GoPiece.sergeant),
          9: (Player.b, GoPiece.flag),
        }),
      );
      await tapOn(tester, cell(90));
      final marked = {for (var sq = 0; sq < 100; sq++) if (squareOf(tester, sq).target) sq};
      // Up column 0 to the enemy on 30 (attack ring), right along row 9 to 98.
      expect(marked, {80, 70, 60, 50, 40, 30, 91, 92, 93, 94, 95, 96, 97, 98});
      expect(find.descendant(of: cell(30), matching: find.byKey(const Key('go-target-attack'))), findsOneWidget);
      expect(find.descendant(of: cell(50), matching: find.byKey(const Key('go-target-dot'))), findsOneWidget);
    });
  });

  group('fight reveal', () {
    GoStrategyGame duel() => GoStrategyGame.position({
          64: (Player.a, GoPiece.captain),
          54: (Player.b, GoPiece.lieutenant),
          99: (Player.a, GoPiece.flag),
          0: (Player.b, GoPiece.flag),
          9: (Player.b, GoPiece.miner),
        });

    testWidgets('attack: the cover shows the outcome, then O sees the animated reveal', (tester) async {
      phone(tester);
      final c = await pumpPosition(tester, duel());
      await tapOn(tester, cell(64));
      expect(squareOf(tester, 54).target, isTrue);
      await tapOn(tester, cell(54));
      expect(describeGoStrategyMove(deL10n, c.moves.single), endsWith(': Hauptmann (6) schlägt Leutnant (5)'));

      // X sees the outcome on the cover before passing the device.
      expect(c.needsHandover, isTrue);
      expect(find.byKey(const Key('go-cover-fight')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('go-cover-fight')), matching: find.text('Hauptmann (6) schlägt Leutnant (5)')),
          findsOneWidget);
      expect(find.text('Angriff von X'), findsOneWidget);

      await acknowledge(tester);
      expect(find.byKey(reveal), findsOneWidget);
      // Animated: starts transparent, then fully visible.
      double cardOpacity() => tester
          .widget<Opacity>(find.ancestor(of: find.byKey(const Key('go-fight-card')), matching: find.byType(Opacity)).first)
          .opacity;
      expect(cardOpacity(), lessThan(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(revealValue(tester), inExclusiveRange(0.2, 0.8));
      expect(cardOpacity(), 1);
      expect(find.descendant(of: find.byKey(reveal), matching: find.text('Hauptmann (6) schlägt Leutnant (5)')), findsOneWidget);
      // Taps on the board are swallowed by the reveal meanwhile.
      await tester.tap(find.byKey(reveal), warnIfMissed: false);
      await tester.pump();
      expect(find.byKey(reveal), findsNothing, reason: 'a tap dismisses it');
      expect(c.moves, hasLength(1));
      // The captain stands on 54, revealed for O.
      expect(squareOf(tester, 54).cell.piece, GoPiece.captain);
      expect(squareOf(tester, 54).cell.owner, Player.a);
    });

    testWidgets('reduced motion: the reveal shows at once without animation; a tap dismisses it', (tester) async {
      phone(tester);
      final c = await pumpPosition(tester, duel(), reduceMotion: true);
      await c.submit({'action': 'move', 'from': 64, 'to': 54});
      await tester.pump();
      await acknowledge(tester);
      expect(find.byKey(reveal), findsOneWidget);
      final opacities = tester.widgetList<Opacity>(
          find.ancestor(of: find.byKey(const Key('go-fight-card')), matching: find.byType(Opacity)));
      expect(opacities.every((o) => o.opacity == 1), isTrue);
      final scale = tester.widget<Transform>(
          find.ancestor(of: find.byKey(const Key('go-fight-card')), matching: find.byType(Transform)).first);
      expect(scale.transform.getMaxScaleOnAxis(), 1);
      expect(find.descendant(of: find.byKey(reveal), matching: find.text('Hauptmann (6) schlägt Leutnant (5)')), findsOneWidget);
      await tapOn(tester, find.byKey(reveal));
      expect(find.byKey(reveal), findsNothing);
    });

    test('fight texts', () {
      GoFight f(GoPiece a, GoPiece d) => GoFight(
            attackerPlayer: Player.a,
            attacker: a,
            defender: d,
            outcome: GoStrategyGame.fight(a, d),
            from: 0,
            to: 1,
          );
      expect(goFightText(deL10n, f(GoPiece.captain, GoPiece.lieutenant)), 'Hauptmann (6) schlägt Leutnant (5)');
      expect(goFightText(deL10n, f(GoPiece.lieutenant, GoPiece.captain)), 'Hauptmann (6) schlägt Leutnant (5)');
      expect(goFightText(deL10n, f(GoPiece.major, GoPiece.major)), 'Beide fallen');
      expect(goFightText(deL10n, f(GoPiece.miner, GoPiece.bomb)), 'Mineur (3) entschärft die Bombe');
      expect(goFightText(deL10n, f(GoPiece.general, GoPiece.bomb)), 'General (9) läuft auf eine Bombe');
      expect(goFightText(deL10n, f(GoPiece.spy, GoPiece.marshal)), 'Spion (1) schlägt Marschall (10)');
      expect(goFightText(deL10n, f(GoPiece.scout, GoPiece.flag)), 'Fahne erobert!');
      expect(goFightText(enL10n, f(GoPiece.captain, GoPiece.lieutenant)), 'Captain (6) beats Lieutenant (5)');
      expect(goSquareName(60), 'a4');
      expect(goSquareName(0), 'a10');
      expect(goSquareName(99), 'j1');
    });
  });

  group('panel', () {
    testWidgets('pieces left per side and the move-limit hint', (tester) async {
      phone(tester);
      final c = await pumpPosition(
        tester,
        GoStrategyGame.position({
          64: (Player.a, GoPiece.captain),
          54: (Player.b, GoPiece.lieutenant),
          99: (Player.a, GoPiece.flag),
          0: (Player.b, GoPiece.flag),
          9: (Player.b, GoPiece.miner),
        }, noCaptureLimit: 20),
      );
      expect(find.text('2 von 40 übrig'), findsOneWidget); // X
      expect(find.text('3 von 40 übrig'), findsOneWidget); // O
      expect(tester.widget<Text>(find.byKey(const Key('go-left-O-lieutenant'))).data, '×1');
      expect(find.byKey(const Key('go-move-limit')), findsOneWidget);
      expect(find.text('Noch 20 Züge ohne Kampf, dann ist es unentschieden.'), findsOneWidget);
      await c.submit({'action': 'move', 'from': 64, 'to': 54});
      await tester.pump();
      await acknowledge(tester);
      expect(find.byKey(reveal), findsOneWidget);
      await finishReveal(tester);
      expect(find.byKey(reveal), findsNothing, reason: 'the reveal ends by itself');
      expect(tester.widget<Text>(find.byKey(const Key('go-left-O-lieutenant'))).data, '×0');
      expect(find.text('2 von 40 übrig'), findsNWidgets(2));
    });
  });

  group('end', () {
    testWidgets('scripted hot-seat game to the flag: reveal and the result dialog', (tester) async {
      phone(tester);
      // X scout on 90 runs up the free a-file and captures O's flag on 0
      // after one O move.
      final c = await pumpPosition(
        tester,
        GoStrategyGame.position({
          90: (Player.a, GoPiece.scout),
          99: (Player.a, GoPiece.flag),
          0: (Player.b, GoPiece.flag),
          19: (Player.b, GoPiece.sergeant),
        }),
      );
      await tapOn(tester, cell(90));
      await tapOn(tester, cell(10));
      expect(gameOf(c).cellAt(10, viewer: Player.b).revealed, isTrue, reason: 'a long scout run reveals it');
      await acknowledge(tester);
      await tapOn(tester, cell(19));
      await tapOn(tester, cell(29));
      await acknowledge(tester);
      await tapOn(tester, cell(10));
      await tapOn(tester, cell(0));
      expect(gameOf(c).isOver, isTrue);
      expect(c.needsHandover, isFalse);
      // The reveal plays at once (no cover at the end) and the result follows.
      expect(find.byKey(reveal), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(resultDialog), findsOneWidget);
      expect(find.text('X gewinnt!'), findsOneWidget);
      expect(find.text('Fahne erobert'), findsOneWidget);
    });

    testWidgets('a full seeded hot-seat game through the controller ends in the result dialog', (tester) async {
      phone(tester);
      final c = await pumpGame(tester, 'gostrategy', seed: 3);
      await playToEnd(tester);
      expect(gameOf(c).isOver, isTrue);
      expect(find.byKey(resultDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // KLD-065: the shell's "Aufgeben" in GoStrategy (hot-seat; the network
  // case is in gostrategy_network_test.dart).
  group('resign', () {
    Finder inResult(String text) => find.descendant(of: find.byKey(resultDialog), matching: find.text(text));

    Future<void> resignAs(WidgetTester tester, Player p) async {
      await tester.tap(find.byKey(const Key('shell-resign')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('resign-dialog')), findsOneWidget);
      await tester.tap(find.byKey(Key('resign-${p.name}')));
      await tester.pumpAndSettle();
    }

    testWidgets('during the setup, with the cover up: O resigns, the cover goes, X\'s army stays hidden',
        (tester) async {
      phone(tester);
      final c = await pumpGame(tester, 'gostrategy');
      await tapKey(tester, 'go-done');
      expect(c.needsHandover, isTrue);
      await resignAs(tester, Player.b);

      expect(gameOf(c).isOver, isTrue);
      expect(gameOf(c).resignedBy, Player.b);
      expect(c.moves.last.move, {'action': 'resign', 'player': 'b'});
      expect(c.needsHandover, isFalse);
      expect(find.byKey(const Key('handover-cover'), skipOffstage: false), findsNothing);
      expect(inResult('X gewinnt!'), findsOneWidget);
      expect(inResult('O hat aufgegeben'), findsOneWidget);
      await tester.tap(find.text('Menü'));
      await tester.pumpAndSettle();
      // No setup editor any more, and the board still shows only O's view.
      expect(find.byKey(const Key('go-done')), findsNothing);
      expect(find.byKey(const Key('shell-resign')), findsNothing);
      for (final sq in GoStrategyGame.homeSquares(Player.a)) {
        expect(squareOf(tester, sq).cell.owner, Player.a);
        expect(squareOf(tester, sq).cell.piece, isNull, reason: 'X piece on $sq stays hidden');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('mid-game, while the fight is on the cover: X resigns, no reveal, O wins', (tester) async {
      phone(tester);
      final c = await pumpPosition(
        tester,
        GoStrategyGame.position({
          64: (Player.a, GoPiece.captain),
          54: (Player.b, GoPiece.lieutenant),
          99: (Player.a, GoPiece.flag),
          0: (Player.b, GoPiece.flag),
          9: (Player.b, GoPiece.miner),
        }),
      );
      await tapOn(tester, cell(64));
      await tapOn(tester, cell(54));
      expect(c.needsHandover, isTrue);
      expect(find.byKey(const Key('go-cover-fight')), findsOneWidget);
      await resignAs(tester, Player.a);

      expect(gameOf(c).resignedBy, Player.a);
      expect(c.moves, hasLength(2));
      expect(c.moves.last.player, Player.a);
      expect(c.needsHandover, isFalse);
      expect(find.byKey(const Key('handover-cover'), skipOffstage: false), findsNothing);
      expect(find.byKey(reveal), findsNothing, reason: 'the resign is the last move, not the fight');
      expect(inResult('O gewinnt!'), findsOneWidget);
      expect(inResult('X hat aufgegeben'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('no square ever shows an unrevealed enemy rank (hot-seat, many turns)', (tester) async {
    phone(tester);
    final c = await pumpGame(tester, 'gostrategy', seed: 5);
    for (var step = 0; step < 120 && !gameOf(c).isOver; step++) {
      if (c.needsHandover) {
        await acknowledge(tester);
      }
      final g = gameOf(c);
      if (g.phase == GoStrategyPhase.play && !c.needsHandover) {
        final me = g.currentPlayer;
        for (var sq = 0; sq < 100; sq++) {
          final v = squareOf(tester, sq);
          expect(v.cell, g.viewFor(me)[sq]);
          if (v.cell.owner != null && v.cell.owner != me && !v.cell.revealed) {
            expect(find.descendant(of: cell(sq), matching: find.byType(GoPieceTile)), findsOneWidget);
            expect(tester.widget<GoPieceTile>(find.descendant(of: cell(sq), matching: find.byType(GoPieceTile))).piece,
                isNull);
          }
        }
      }
      final moves = g.legalMoves;
      await c.submit(moves[(step * 13) % moves.length]);
      await tester.pump();
    }
    await finishReveal(tester);
  });
}

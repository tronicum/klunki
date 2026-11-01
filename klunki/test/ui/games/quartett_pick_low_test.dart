// KLD-100: Quartett (Trumpf) house rule "with 3 or fewer cards you choose
// which card to play" in the Trumpf screen: hot-seat (picker and defender,
// the defender behind the handover cover) and one network device against a
// scripted opponent.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki/ui/games/quartett_trumpf_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../shell/shell_test_utils.dart';
import '../../l10n/l10n_test_utils.dart';

const _reveal = Key('qt-reveal');
const _cont = Key('qt-continue');
const _ownCard = Key('qt-own-card');
const _choose = Key('qt-choose');
const _chooseHint = Key('qt-choose-hint');
const _reason = Key('qt-handover-reason');
Key _cardKey(String id) => Key('qt-choose-$id');
Key _statKey(String id) => Key('qt-stat-$id');

Player _other(Player p) => p == Player.a ? Player.b : Player.a;

/// Moves (first-legal from a random walk) from the start of a rule-on game
/// with [seed] to the first position where [stop] holds; null if the game
/// ends first.
List<Map<String, dynamic>>? _movesTo(int seed, bool Function(QuartettGame) stop) {
  final g = createGame(GameConfig('quartett-trumpf', seed: seed)) as QuartettGame;
  final rng = Random(seed);
  final moves = <Map<String, dynamic>>[];
  while (!stop(g)) {
    if (g.isOver) return null;
    final legal = g.legalMoves;
    final m = legal[rng.nextInt(legal.length)];
    moves.add(m);
    g.applyMove(m);
  }
  return moves;
}

/// First (seed, moves) reaching [stop].
(int, List<Map<String, dynamic>>) _find(bool Function(QuartettGame) stop) {
  for (var seed = 1; seed < 500; seed++) {
    final m = _movesTo(seed, stop);
    if (m != null) return (seed, m);
  }
  throw StateError('no matching game');
}

/// The picker is low (2–3 cards) and has to choose; the defender is not.
bool _pickerLow(QuartettGame g) => g.announcedStat == null && g.mustChoose && !g.choosesCard(_other(g.picker));

/// The picker is to pick (no choice) and the defender is low.
bool _defenderLow(QuartettGame g) =>
    g.announcedStat == null && !g.mustChoose && !g.choosesCard(g.picker) && g.choosesCard(_other(g.picker));

/// A hot-seat game of [seed] with [moves] already played.
Future<GameController> _pumpHotSeat(WidgetTester tester, int seed, List<Map<String, dynamic>> moves) async {
  final t = HotSeatTransport(GameConfig('quartett-trumpf', seed: seed));
  for (final m in moves) {
    expect(t.submitSync(m).isAccepted, isTrue);
  }
  final c = GameController(t);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  await tester.pump(); // post-frame hint
  return c;
}

Future<void> _tap(WidgetTester tester, Key key) async {
  await tester.ensureVisible(find.byKey(key));
  await tester.tap(find.byKey(key));
  await tester.pump();
  await tester.pump();
}

String _text(WidgetTester tester, Key key) => tester.widget<Text>(find.byKey(key)).data!;

/// One device of a network game with the single local player [me]; the
/// opponent's moves come from [remote] (cf. quartett_trumpf_network_test).
class _Device implements GameTransport {
  _Device(int seed, this.me, List<Map<String, dynamic>> moves)
    : _inner = HotSeatTransport(GameConfig('quartett-trumpf', seed: seed)) {
    for (final m in moves) {
      expect(_inner.submitSync(m).isAccepted, isTrue);
    }
  }

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
    if (game.currentPlayer != me) return const SubmitResult.rejected(RejectReason.notYourTurn);
    sent.add(move);
    return _inner.submitSync(move);
  }

  void remote(Map<String, dynamic> move) {
    expect(game.currentPlayer, isNot(me));
    expect(_inner.submitSync(move).isAccepted, isTrue);
  }

  @override
  void dispose() => _inner.dispose();
}

Future<(GameController, _Device)> _pumpDevice(
  WidgetTester tester,
  int seed,
  Player me,
  List<Map<String, dynamic>> moves,
) async {
  final t = _Device(seed, me, moves);
  final c = GameController(t);
  addTearDown(c.dispose);
  await tester.pumpWidget(localizedApp(buildGameScreen(c)));
  await tester.pump();
  await tester.pump();
  return (c, t);
}

QuartettGame c0(GameTransport t) => t.game as QuartettGame;

void main() {
  group('hot-seat', () {
    testWidgets('a low picker sees its cards, chooses one, then picks a stat of it', (tester) async {
      final (seed, moves) = _find((g) => _pickerLow(g) && g.stackSize(g.picker) == 3);
      final c = await _pumpHotSeat(tester, seed, moves);
      final g = c.game as QuartettGame;
      final me = g.picker, opp = _other(me);
      final cards = g.stackOf(me);

      expect(find.byKey(_choose), findsOneWidget);
      expect(find.byKey(_ownCard), findsNothing);
      expect(_text(tester, _chooseHint), 'Du hast nur noch 3 Karten – wähle eine aus.');
      expect(find.text('Du hast nur noch 3 Karten – wähle eine aus.'), findsOneWidget, reason: 'one hint, above the cards');
      for (final card in cards) {
        expect(find.byKey(_cardKey(card.id)), findsOneWidget);
        expect(find.text(card.name), findsOneWidget);
      }
      expect(find.text(g.topCard(opp)!.name, skipOffstage: false), findsNothing);

      // Choose the last card: the turn stays (no cover), its stats are tappable.
      final chosen = cards.last;
      await _tap(tester, _cardKey(chosen.id));
      expect(g.chosenCard(me), chosen);
      expect(find.byKey(handoverContinue), findsNothing);
      expect(find.byKey(_choose), findsNothing);
      expect(find.descendant(of: find.byKey(_ownCard), matching: find.text(chosen.name)), findsOneWidget);
      expect(c.moves.last.move, {'action': 'choose', 'card': chosen.id});
      expect(QuartettTrumpfScreen.describeMove(deL10n, c.moves.last), 'wählt eine Karte');

      // The pick is previewed with the chosen card.
      await _tap(tester, _statKey('ps'));
      expect(find.byKey(_reveal), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(Key('qt-reveal-${me.name}')), matching: find.text(chosen.name)),
        findsOneWidget,
      );
      final tricks = g.tricks;
      await _tap(tester, _cont);
      expect(g.tricks, tricks + 1);
    });

    testWidgets('a low defender chooses behind the handover cover, knowing the stat; the round is previewed', (
      tester,
    ) async {
      final (seed, moves) = _find(_defenderLow);
      final c = await _pumpHotSeat(tester, seed, moves);
      final g = c.game as QuartettGame;
      final picker = g.picker, defender = _other(picker);
      final pickerCard = g.topCard(picker)!;
      final cards = g.stackOf(defender);
      expect(find.byKey(_choose), findsNothing, reason: 'the picker plays its top card');

      // The pick only announces the stat: no preview, the device changes hands.
      await _tap(tester, _statKey('kg'));
      expect(find.byKey(_reveal), findsNothing);
      expect(g.announcedStat?.id, 'kg');
      expect(g.currentPlayer, defender);
      expect(find.byKey(handoverContinue), findsOneWidget);
      expect(_text(tester, _reason), endsWith('spielt Gewicht. Wähle deine Karte.'));
      expect(find.text(cards.first.name), findsNothing, reason: 'behind the cover');

      await _tap(tester, handoverContinue);
      expect(find.byKey(_choose), findsOneWidget);
      expect(_text(tester, _chooseHint), endsWith('spielt Gewicht. Wähle deine Karte.'));
      expect(find.text(pickerCard.name, skipOffstage: false), findsNothing, reason: "the picker's card stays hidden");
      for (final card in cards) {
        expect(find.byKey(_cardKey(card.id)), findsOneWidget);
      }

      final kg = QuartettDeck.cars.statById('kg')!;
      final best = cards.reduce((x, y) => kg.beats(y.stats['kg']!, x.stats['kg']!) ? y : x);
      await _tap(tester, _cardKey(best.id));
      expect(find.byKey(_reveal), findsOneWidget, reason: 'previewed like a pick');
      expect(g.announcedStat, isNotNull, reason: 'applied only on "Weiter"');
      expect(
        find.descendant(of: find.byKey(Key('qt-reveal-${defender.name}')), matching: find.text(best.name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(Key('qt-reveal-${picker.name}')), matching: find.text(pickerCard.name)),
        findsOneWidget,
      );
      final tricks = g.tricks;
      await _tap(tester, _cont);
      expect(g.tricks, tricks + 1);
      expect(g.announcedStat, isNull);
      final w = (c.moves.last.event.payload as Map)['trickWinner'];
      if (w == defender.name) {
        expect(find.byKey(handoverContinue), findsNothing, reason: 'the defender won and keeps the device');
      } else {
        expect(find.byKey(handoverContinue), findsOneWidget);
        expect(find.byKey(_reason), findsOneWidget);
      }
    });

    testWidgets('phone width: the choose view lays out without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final (seed, moves) = _find((g) => _pickerLow(g) && g.stackSize(g.picker) == 3);
      await _pumpHotSeat(tester, seed, moves);
      expect(find.byKey(_choose), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rule off: a low player plays its top card as before', (tester) async {
      QuartettGame? g0;
      final moves = <Map<String, dynamic>>[];
      for (var seed = 3; g0 == null || g0.isOver; seed++) {
        g0 = QuartettGame(QuartettMode.trumpf, seed: seed);
        moves.clear();
        final rng = Random(seed);
        while (!g0.isOver && (g0.stackSize(g0.currentPlayer) > 3 || g0.stackSize(g0.currentPlayer) < 2)) {
          moves.add(g0.legalMoves[rng.nextInt(5)]);
          g0.applyMove(moves.last);
        }
      }
      final t = HotSeatTransport(GameConfig('quartett-trumpf', seed: g0.seed, pickLowCards: false));
      for (final m in moves) {
        expect(t.submitSync(m).isAccepted, isTrue);
      }
      expect(c0(t).choosesCard(t.game.currentPlayer), isFalse);
      final c = GameController(t);
      addTearDown(c.dispose);
      await tester.pumpWidget(localizedApp(buildGameScreen(c)));
      await tester.pump();
      expect(find.byKey(_choose), findsNothing);
      expect(find.byKey(_ownCard), findsOneWidget);
    });
  });

  group('network device', () {
    testWidgets('the local defender chooses after the remote pick; the round is revealed from the event', (
      tester,
    ) async {
      final (seed, moves) = _find(_defenderLow);
      final g0 = createGame(GameConfig('quartett-trumpf', seed: seed)) as QuartettGame;
      for (final m in moves) {
        g0.applyMove(m);
      }
      final me = _other(g0.picker);
      final (c, t) = await _pumpDevice(tester, seed, me, moves);
      final g = c.game as QuartettGame;
      expect(find.byKey(_choose), findsNothing, reason: 'not my turn');

      t.remote({'action': 'pick', 'stat': 'ps'});
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_choose), findsOneWidget);
      expect(_text(tester, _chooseHint), endsWith('spielt Leistung. Wähle deine Karte.'));
      final card = g.stackOf(me).last;
      await _tap(tester, _cardKey(card.id));
      expect(t.sent, [
        {'action': 'choose', 'card': card.id},
      ]);
      expect(find.byKey(_reveal), findsOneWidget);
      expect(
        find.descendant(of: find.byKey(Key('qt-reveal-${me.name}')), matching: find.text(card.name)),
        findsOneWidget,
      );
    });

    testWidgets('the local picker waits while the remote defender chooses', (tester) async {
      final (seed, moves) = _find(_defenderLow);
      final g0 = createGame(GameConfig('quartett-trumpf', seed: seed)) as QuartettGame;
      for (final m in moves) {
        g0.applyMove(m);
      }
      final me = g0.picker;
      final (c, t) = await _pumpDevice(tester, seed, me, moves);
      final g = c.game as QuartettGame;
      await _tap(tester, _statKey('ps'));
      expect(t.sent, [
        {'action': 'pick', 'stat': 'ps'},
      ]);
      expect(find.byKey(_reveal), findsNothing);
      expect(find.byKey(_choose), findsNothing);
      expect(find.textContaining('wählt eine Karte …'), findsOneWidget);
      expect(find.byKey(_ownCard), findsOneWidget);

      t.remote({'action': 'choose', 'card': g.stackOf(_other(me)).first.id});
      await tester.pump();
      await tester.pump();
      expect(find.byKey(_reveal), findsOneWidget);
      await tester.pump(quartettRevealGrace);
      await tester.pump();
    });

    testWidgets('the local low picker chooses, then picks; the remote side never sees the choice', (tester) async {
      final (seed, moves) = _find(_pickerLow);
      final g0 = createGame(GameConfig('quartett-trumpf', seed: seed)) as QuartettGame;
      for (final m in moves) {
        g0.applyMove(m);
      }
      final me = g0.picker;
      final (c, t) = await _pumpDevice(tester, seed, me, moves);
      final g = c.game as QuartettGame;
      final card = g.stackOf(me).first;
      await _tap(tester, _cardKey(card.id));
      expect(t.sent.single, {'action': 'choose', 'card': card.id});
      expect(find.byKey(_reveal), findsNothing);
      expect(find.descendant(of: find.byKey(_ownCard), matching: find.text(card.name)), findsOneWidget);
      await _tap(tester, _statKey('ps'));
      expect(t.sent.last, {'action': 'pick', 'stat': 'ps'});
      expect(find.byKey(_reveal), findsOneWidget);
      await _tap(tester, _cont);
    });
  });
}

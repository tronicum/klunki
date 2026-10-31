import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';
import 'package:test/test.dart';

/// KLD-064: per-player views and redaction of the hidden-information games.
void main() {
  final hidden = [for (final s in gameSpecs) if (s.hiddenInformation) s];

  test('exactly the hidden-information games have a redaction', () {
    for (final s in gameSpecs) {
      expect(s.redaction != null, s.hiddenInformation, reason: s.id);
    }
    expect(hidden.map((s) => s.id), containsAll(['schiffe', 'gostrategy', 'quartett-trumpf', 'quartett-sets']));
    expect([for (final s in hidden) if (s.redaction!.secretSeed) s.id], ['quartett-trumpf', 'quartett-sets']);
  });

  for (final spec in hidden) {
    group(spec.id, () {
      test('views round-trip and agree with the engine for the viewer, all game long', () {
        final redaction = spec.redaction!;
        final rng = Random(spec.id.hashCode);
        final game = spec.create(17);
        var n = 0;
        while (true) {
          for (final viewer in Player.values) {
            final json = redaction.view(game, viewer);
            final view = redaction.fromView(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
            expect(canonicalJson((view as dynamic).viewJson(viewer)), canonicalJson(json), reason: 'move $n');
            expect(view.currentPlayer, game.currentPlayer);
            expect(view.isOver, game.isOver);
            expect(view.result.winner, game.result.winner);
            expect(view.result.code, game.result.code);
            expect(view.applyMove(_moves(game, rng).firstOrNull ?? const {}), isNull, reason: 'views are read-only');
            if (!game.isOver && game.currentPlayer == viewer) {
              expect(canonicalJson((view as dynamic).legalMoves), canonicalJson((game as dynamic).legalMoves));
            }
            _sameForViewer(game, view, viewer);
          }
          if (game.isOver) break;
          expect(++n, lessThan(5000));
          final legal = _moves(game, rng);
          expect(game.applyMove(legal[rng.nextInt(legal.length)]), isNotNull);
        }
      });

      test('the mover\'s own moves and public moves are not redacted', () {
        final r = spec.redaction!;
        for (final move in [
          {'action': 'fire', 'row': 1, 'col': 2},
          {'action': 'move', 'from': 60, 'to': 50},
          {'action': 'pick', 'stat': 'ps'},
          {'action': 'ask', 'card': 'A1'},
        ]) {
          expect(r.redactMove(move, Player.a, Player.b), move);
        }
        final setup = {'action': 'autoplace', 'seed': 5};
        expect(r.redactMove(setup, Player.a, Player.a), setup);
      });
    });
  }

  test('Schiffe: the opponent sees which ship was placed, not where', () {
    const r = SchiffeRedaction();
    expect(r.redactMove({'action': 'place', 'ship': 2, 'row': 3, 'col': 4, 'dir': 'v'}, Player.a, Player.b),
        {'action': 'place', 'ship': 2});
    expect(r.redactMove({'action': 'autoplace', 'seed': 9}, Player.a, Player.b), {'action': 'autoplace'});
    final g = SchiffeGame()..applyMove({'action': 'autoplace', 'seed': 1});
    final json = jsonEncode(r.view(g, Player.b));
    for (final p in g.placements(Player.a)) {
      expect(json, isNot(contains('[${p.length},${p.row},${p.col},"${p.dir}"]')));
    }
    final view = r.fromView(r.view(g, Player.b)) as SchiffeGame;
    expect(view.nextShipIndex(Player.a), isNull);
    expect(view.shipsRemaining(Player.a), 6);
    expect(view.ownGrid(Player.a).expand((row) => row).toSet(), {SchiffeCell.empty});
  });

  test('GoStrategy: the opponent learns that a setup was made, not which', () {
    const r = GoStrategyRedaction();
    final setup = GoStrategyGame.setupMove(GoStrategyGame.randomSetup(1));
    expect(r.redactMove(setup, Player.a, Player.b), {'action': 'setup'});
    expect(r.redactMove({'action': 'autosetup', 'seed': 3}, Player.a, Player.b), {'action': 'setup'});
    final g = GoStrategyGame()..applyMove(setup);
    final json = r.view(g, Player.b);
    expect(jsonEncode(json['cells']), isNot(contains('"p"')));
    expect(((json['remaining'] as Map)['a'] as Map)['marshal'], 1, reason: 'counts are public');
  });

  test('Quartett: the deal is not in the view; the opponent\'s draw is hidden', () {
    const r = QuartettRedaction();
    final g = QuartettGame(QuartettMode.sets, seed: 4, handSize: 8);
    final json = jsonEncode(r.view(g, Player.b));
    for (final c in g.handOf(Player.a)) {
      expect(json, isNot(contains('"${c.id}"')));
    }
    expect(r.redactPayload({'card': 'A1', 'hit': false, 'drew': 'B2'}, Player.a, Player.b),
        {'card': 'A1', 'hit': false, 'drew': true});
    expect(r.redactPayload({'card': 'A1', 'hit': false, 'drew': 'B2'}, Player.b, Player.b),
        {'card': 'A1', 'hit': false, 'drew': 'B2'});
    final view = r.fromView(r.view(g, Player.b)) as QuartettGame;
    expect(view, isA<QuartettView>());
    expect(view.seed, 0);
    expect(view.handOf(Player.a).map((c) => c.id).toSet(), {'?'});
  });

  test('malformed views are refused with BadViewException', () {
    for (final spec in hidden) {
      expect(() => spec.redaction!.fromView({'viewer': 'x'}), throwsA(isA<BadViewException>()), reason: spec.id);
      expect(() => spec.redaction!.fromView({}), throwsA(isA<BadViewException>()), reason: spec.id);
    }
  });

  test('canonicalJson sorts keys and maps players to names', () {
    expect(canonicalJson({'b': 1, 'a': {'d': Player.a, 'c': [Player.b]}}), '{"a":{"c":["b"],"d":"a"},"b":1}');
    final e = eventFromJson(eventToJson(const GameEvent(winner: Player.b, payload: {'x': 1})));
    expect(e.winner, Player.b);
    expect(e.payload, {'x': 1});
  });
}

List<Map<String, dynamic>> _moves(Game game, Random rng) {
  final moves = (game as dynamic).legalMoves as List<Map<String, dynamic>>;
  if (moves.isEmpty && game is SchiffeGame && game.phase == SchiffePhase.setup) {
    return [{'action': 'autoplace', 'seed': rng.nextInt(1 << 30)}];
  }
  return moves;
}

/// What the screens read for [viewer] matches the engine.
void _sameForViewer(Game game, Game view, Player viewer) {
  final opp = viewer == Player.a ? Player.b : Player.a;
  switch ((game, view)) {
    case (SchiffeGame g, SchiffeGame v):
      expect(v.phase, g.phase);
      expect(v.ownGrid(viewer), g.ownGrid(viewer));
      expect(v.targetGrid(viewer), g.targetGrid(viewer));
      expect(v.targetGrid(opp), g.targetGrid(opp), reason: 'the shots at the viewer are public');
      expect(v.placements(viewer).map((p) => p.toString()), g.placements(viewer).map((p) => p.toString()));
      expect(v.shipsRemaining(opp), g.shipsRemaining(opp));
      expect(v.nextShipIndex(opp), g.nextShipIndex(opp));
      expect(v.placements(opp), isEmpty);
    case (QuartettGame g, QuartettGame v):
      expect(v.topCard(viewer), g.topCard(viewer));
      expect(v.topCard(opp), isNull);
      expect(v.stackSize(opp), g.stackSize(opp));
      expect(v.potSize, g.potSize);
      expect(v.tricks, g.tricks);
      expect(v.handOf(viewer), g.handOf(viewer));
      expect(v.handOf(opp).length, g.handOf(opp).length);
      expect(v.stockSize, g.stockSize);
      expect(v.quartetsOf(opp), g.quartetsOf(opp));
    case (GoStrategyGame g, GoStrategyGame v):
      expect(v.phase, g.phase);
      expect(v.viewFor(viewer), g.viewFor(viewer));
      expect(v.remaining(opp), g.remaining(opp));
      expect(v.movesSinceCapture, g.movesSinceCapture);
      for (var sq = 0; sq < 100; sq++) {
        if (g.currentPlayer == viewer) expect(v.targetsFrom(sq), g.targetsFrom(sq));
      }
    default:
      fail('unexpected ${game.runtimeType} / ${view.runtimeType}');
  }
}

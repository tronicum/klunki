part of 'quartett.dart';

/// A Quartett game as one player sees it (KLD-064): built from
/// [QuartettGame.viewJson] on the remote side of a network game. It knows the
/// viewer's own top card (Trumpf) or hand (Sets), the counts and the laid-down
/// quartets; every other card is [QuartettGame.hiddenCard]. [seed] is 0 (the
/// real seed stays with the host until the game is over). Read-only:
/// [applyMove] returns null.
class QuartettView extends QuartettGame {
  /// The player whose view this is.
  final Player viewer;

  QuartettView._(this.viewer, QuartettMode mode, int handSize) : super(mode, handSize: handSize) {
    for (final p in Player.values) {
      _stacks[p]!.clear();
      _hands[p]!.clear();
      _quartets[p]!.clear();
    }
    _pot.clear();
    _stock.clear();
    _history.clear();
  }

  /// Rebuilds the view from [QuartettGame.viewJson]; throws
  /// [BadViewException] if [j] is malformed.
  factory QuartettView.fromJson(Map<String, dynamic> j) {
    try {
      final viewer = playerIn(j['viewer']);
      final mode = QuartettMode.values.byName(j['mode'] as String);
      final handSize = j['handSize'] as int;
      if (handSize < 1 || handSize > 16) throw BadViewException('bad hand size $handSize');
      final v = QuartettView._(viewer, mode, handSize);
      Card card(Object? id) => QuartettGame._byId[id] ?? (throw BadViewException('unknown card $id'));
      List<Card> hidden(Object? n) => List.filled(n as int, QuartettGame.hiddenCard);
      if (mode == QuartettMode.trumpf) {
        final stacks = j['stacks'] as Map;
        for (final p in Player.values) {
          v._stacks[p]!.addAll(hidden(stacks[p.name]));
        }
        final top = j['top'];
        if (top != null) {
          if (v._stacks[viewer]!.isEmpty) throw const BadViewException('top card of an empty stack');
          v._stacks[viewer]![0] = card(top);
        }
        v._pot.addAll(hidden(j['pot']));
        v._tricks = j['tricks'] as int;
      } else {
        final hand = [for (final id in j['hand'] as List) card(id)];
        final hands = j['hands'] as Map;
        if (hands[viewer.name] != hand.length) throw const BadViewException('hand size mismatch');
        v._hands[viewer]!.addAll(hand);
        final opp = QuartettGame._other(viewer);
        v._hands[opp]!.addAll(hidden(hands[opp.name]));
        v._stock.addAll(hidden(j['stock']));
        final quartets = j['quartets'] as Map;
        for (final p in Player.values) {
          v._quartets[p]!.addAll((quartets[p.name] as List).cast<String>());
        }
      }
      v._current = playerIn(j['current']);
      final r = resultFromJson(j['result']);
      v
        .._winner = r.winner
        .._draw = r.draw
        .._reason = r.reason
        .._code = r.code
        .._params = r.params;
      return v;
    } on BadViewException {
      rethrow;
    } catch (e) {
      throw BadViewException('malformed Quartett view: $e');
    }
  }

  @override
  int get seed => 0;

  /// The viewer's top card; null for the opponent (face down).
  @override
  Card? topCard(Player p) => p == viewer ? super.topCard(p) : null;

  /// Only the cards the viewer knows (its own top card).
  @override
  List<Card> stackOf(Player p) => [for (final c in _stacks[p]!) if (!identical(c, QuartettGame.hiddenCard)) c];

  /// The viewer's legal moves on its turn; empty on the opponent's turn.
  @override
  List<Map<String, dynamic>> get legalMoves => _current == viewer ? super.legalMoves : const [];

  @override
  GameEvent? applyMove(Map<String, dynamic> move) => null;

  @override
  Map<String, dynamic> viewJson(Player viewer) {
    if (viewer != this.viewer) throw ArgumentError.value(viewer, 'viewer', 'not the view of this player');
    return super.viewJson(viewer);
  }

  @override
  String toString() => 'QuartettView(${viewer.name}, ${mode.name})';
}

/// Redaction for both Quartett modes: the seed (and with it the deal) stays
/// secret; moves are public; in Sets the card drawn by the opponent is
/// hidden (`drew: true`). Trumpf payloads are public: both cards of a trick
/// are shown in the fight.
class QuartettRedaction extends Redaction {
  const QuartettRedaction();

  @override
  bool get secretSeed => true;

  @override
  Map<String, dynamic> view(Game game, Player viewer) => (game as QuartettGame).viewJson(viewer);

  @override
  Game fromView(Map<String, dynamic> view) => QuartettView.fromJson(view);

  @override
  Object? redactPayload(Object? payload, Player mover, Player viewer) {
    final p = jsonSafe(payload);
    if (mover == viewer || p is! Map<String, dynamic> || p['drew'] == null) return p;
    return {...p, 'drew': true};
  }
}

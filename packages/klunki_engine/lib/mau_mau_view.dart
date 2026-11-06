part of 'mau_mau.dart';

/// A Mau-Mau game as one player sees it (KLD-118, for network play in a
/// later step): built from [MauMauGame.viewJson]. It knows the viewer's own
/// hand, the top card, the counts, the wish and a pending 7 chain; the
/// opponent's cards are [MauMauGame.hiddenCard], the draw pile and the
/// discard pile below the top card only counts. [seed] is 0. Read-only:
/// [applyMove] returns null.
class MauMauView extends MauMauGame {
  /// The player whose view this is.
  final Player viewer;

  int _stockCount = 0;
  int _discardCount = 1;

  MauMauView._(this.viewer, MauMauRules rules) : super._empty(rules);

  /// Rebuilds the view from [MauMauGame.viewJson]; throws
  /// [BadViewException] if [j] is malformed.
  factory MauMauView.fromJson(Map<String, dynamic> j) {
    try {
      final viewer = playerIn(j['viewer']);
      final v = MauMauView._(viewer, MauMauRules.fromJson(j['rules']));
      MauMauCard card(Object? id) =>
          (id is String ? MauMauCard.byId(id) : null) ?? (throw BadViewException('unknown card $id'));
      final hand = [for (final id in j['hand'] as List) card(id)];
      final hands = j['hands'] as Map;
      if (hands[viewer.name] != hand.length) throw const BadViewException('hand size mismatch');
      v._hands[viewer]!.addAll(hand);
      final opp = MauMauGame._other(viewer);
      final oppCount = hands[opp.name] as int;
      if (oppCount < 0 || oppCount > 32) throw BadViewException('bad hand size $oppCount');
      v._hands[opp]!.addAll(List.filled(oppCount, MauMauGame.hiddenCard));
      v._discard.add(card(j['top']));
      v._discardCount = j['discard'] as int;
      v._stockCount = j['stock'] as int;
      if (v._discardCount < 1 || v._stockCount < 0) throw const BadViewException('bad pile sizes');
      final wish = j['wish'];
      if (wish != null) {
        v._wish = (wish is String ? MauMauSuit.byCode(wish) : null) ?? (throw BadViewException('bad wish $wish'));
      }
      v._penalty = j['penalty'] as int? ?? 0;
      v._hasDrawn = j['hasDrawn'] == true;
      final drawn = j['drawn'];
      if (drawn != null) {
        final c = card(drawn);
        if (!hand.contains(c)) throw BadViewException('drawn card $drawn not held');
        v._drawn = c;
      }
      v._current = playerIn(j['current']);
      final r = resultFromJson(j['result']);
      v._winner = r.winner;
      final resigned = j['resigned'];
      if (resigned != null) v._restoreResign(playerIn(resigned));
      return v;
    } on BadViewException {
      rethrow;
    } catch (e) {
      throw BadViewException('malformed Mau-Mau view: $e');
    }
  }

  @override
  int get seed => 0;

  @override
  int get stockCount => _stockCount;

  @override
  int get discardCount => _discardCount;

  @override
  int get drawable => _stockCount + _discardCount - 1;

  /// Only the viewer's own cards; the opponent's hand is [handCount].
  @override
  List<MauMauCard> handOf(Player p) => p == viewer ? super.handOf(p) : const [];

  /// The viewer's legal moves on its turn; empty on the opponent's turn.
  @override
  List<Map<String, dynamic>> get legalMoves => currentPlayer == viewer ? super.legalMoves : const [];

  @override
  GameEvent? applyMove(Map<String, dynamic> move) => null;

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) => null;

  void _restoreResign(Player p) => super.applyMove(Game.resignMove(p));

  @override
  Map<String, dynamic> viewJson(Player viewer) {
    if (viewer != this.viewer) throw ArgumentError.value(viewer, 'viewer', 'not the view of this player');
    return super.viewJson(viewer);
  }

  @override
  String toString() => 'MauMauView(${viewer.name})';
}

/// Redaction for Mau-Mau: the seed (and with it the deal and every draw)
/// stays secret; plays are public (the card is laid face up); the cards the
/// opponent drew are hidden (only `count` stays).
class MauMauRedaction extends Redaction {
  const MauMauRedaction();

  @override
  bool get secretSeed => true;

  @override
  Map<String, dynamic> view(Game game, Player viewer) => (game as MauMauGame).viewJson(viewer);

  @override
  Game fromView(Map<String, dynamic> view) => MauMauView.fromJson(view);

  @override
  Object? redactPayload(Object? payload, Player mover, Player viewer) {
    final p = jsonSafe(payload);
    if (mover == viewer || p is! Map<String, dynamic> || p['drew'] == null) return p;
    return {
      for (final e in p.entries)
        if (e.key != 'drew' && e.key != 'fits') e.key: e.value,
      'count': (p['drew'] as List).length,
    };
  }
}

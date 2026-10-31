/// Hidden information over the network (KLD-064): per-player views and
/// redaction, so a remote player only ever holds what it may know.
///
/// The host (referee) runs the full engine. For every accepted move it sends
/// the other player a *redacted step*: the move as that player may see it
/// ([Redaction.redactMove]), the event as that player may see it
/// ([Redaction.redactPayload]) and the player's view of the game after the
/// move ([Redaction.view]). The remote side turns the view back into a game
/// object with [Redaction.fromView]: an instance of the same game interface
/// (`SchiffeGame`, `QuartettGame`, `GoStrategyGame`), so screens and text
/// adapters render it unchanged, but it holds no hidden data and cannot
/// apply moves (`applyMove` returns null; the host decides).
///
/// Pure functions only; hashing and commitments live in `klunki_net`.
library;

import 'dart:convert';

import 'game.dart';

/// How one hidden-information game is redacted for a player. One instance
/// per game kind, registered in `GameSpec.redaction`.
abstract class Redaction {
  const Redaction();

  /// True when the game's seed is secret (it decides a hidden deal) and must
  /// not be sent to the remote player before the game is over.
  bool get secretSeed => false;

  /// Everything [viewer] may know about [game] right now, as JSON. Must not
  /// contain the opponent's hidden data.
  Map<String, dynamic> view(Game game, Player viewer);

  /// A read-only game object for a [view] produced by [view].
  Game fromView(Map<String, dynamic> view);

  /// [move] by [mover] as [viewer] may see it. The mover's own moves are
  /// never redacted.
  Map<String, dynamic> redactMove(Map<String, dynamic> move, Player mover, Player viewer) =>
      jsonSafe(move) as Map<String, dynamic>;

  /// The event payload of [mover]'s move as [viewer] may see it (JSON).
  Object? redactPayload(Object? payload, Player mover, Player viewer) => jsonSafe(payload);

  /// The redacted step for [viewer] after [mover] played [move] on [game]
  /// (already applied, with [event]): `{move, event, view}`.
  Map<String, dynamic> step(Game game, Map<String, dynamic> move, Player mover, GameEvent event, Player viewer) => {
        'move': redactMove(move, mover, viewer),
        'event': eventToJson(GameEvent(
            winner: event.winner, draw: event.draw, payload: redactPayload(event.payload, mover, viewer))),
        'view': view(game, viewer),
      };
}

/// Thrown by [Redaction.fromView] for a view that does not fit the game.
class BadViewException implements Exception {
  final String message;
  const BadViewException(this.message);
  @override
  String toString() => 'BadViewException: $message';
}

/// [v] with every [Player] replaced by its name and every map key turned
/// into a string, recursively: the JSON form of payloads and moves.
Object? jsonSafe(Object? v) => switch (v) {
      Player p => p.name,
      Map m => <String, dynamic>{for (final e in m.entries) '${e.key}': jsonSafe(e.value)},
      List l => [for (final x in l) jsonSafe(x)],
      _ => v,
    };

/// JSON of [v] ([jsonSafe]) with map keys sorted at every level, so equal
/// data always encodes to the same string (commitments, comparisons).
String canonicalJson(Object? v) => jsonEncode(_sorted(jsonSafe(v)));

Object? _sorted(Object? v) => switch (v) {
      Map m => {for (final k in (m.keys.cast<String>().toList()..sort())) k: _sorted(m[k])},
      List l => [for (final x in l) _sorted(x)],
      _ => v,
    };

/// `{winner?, draw?, payload}` for [e] ([jsonSafe] payload).
Map<String, dynamic> eventToJson(GameEvent e) => {
      if (e.winner != null) 'winner': e.winner!.name,
      if (e.draw) 'draw': true,
      'payload': jsonSafe(e.payload),
    };

/// Inverse of [eventToJson].
GameEvent eventFromJson(Map<String, dynamic> j) =>
    GameEvent(winner: playerOrNull(j['winner']), draw: j['draw'] == true, payload: j['payload']);

/// `{winner?, draw?, reason?, code?, params?}` for [r].
Map<String, dynamic> resultToJson(GameResult r) => {
      if (r.winner != null) 'winner': r.winner!.name,
      if (r.draw) 'draw': true,
      if (r.reason.isNotEmpty) 'reason': r.reason,
      if (r.code != null) 'code': r.code!.code,
      if (r.params.isNotEmpty) 'params': r.params,
    };

/// Inverse of [resultToJson].
GameResult resultFromJson(Object? j) {
  if (j is! Map) return const GameResult();
  final code = j['code'];
  final params = j['params'];
  return GameResult(
    winner: playerOrNull(j['winner']),
    draw: j['draw'] == true,
    reason: j['reason'] is String ? j['reason'] as String : '',
    code: code is String ? GameEndReason.fromCode(code) : null,
    params: params is Map ? {for (final e in params.entries) '${e.key}': (e.value as num).toInt()} : const {},
  );
}

/// `'a'` → A, `'b'` → B, anything else → null.
Player? playerOrNull(Object? name) => switch (name) {
      'a' => Player.a,
      'b' => Player.b,
      _ => null,
    };

/// Like [playerOrNull] but throws [BadViewException] for anything else.
Player playerIn(Object? name) => playerOrNull(name) ?? (throw BadViewException('bad player $name'));

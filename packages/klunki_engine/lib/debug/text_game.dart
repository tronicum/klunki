import 'dart:math';

import '../game.dart';

/// Text adapter for one game: renders the state as plain text, parses typed
/// commands into engine moves and narrates what a move did. Used by the debug
/// console in both the terminal CLI and the Flutter debug screen.
abstract class TextGame {
  /// Short id used on the command line, e.g. `connect4`.
  String get id;
  String get title;

  /// One-line command syntax shown by `help`.
  String get moveHelp;

  Game get game;

  /// Fresh game, same adapter.
  TextGame restart();

  String render();

  /// Parses [input] into a move map, or null if it is not a move command.
  /// Legality is decided by the engine, not here.
  Map<String, dynamic>? parse(String input);

  /// Legal moves for the current player, as engine move maps.
  List<Map<String, dynamic>> get legalMoves;

  /// Inverse of [parse]: the command a player would type for [move].
  String format(Map<String, dynamic> move);

  /// One plain-language sentence about what [mover]'s [move] did. Called
  /// after the engine applied it, so the game already shows the new state.
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event);

  /// [format] that also knows the shared resign move: `resign X`.
  String formatMove(Map<String, dynamic> move) {
    final r = Game.resignerOf(move);
    return r != null ? 'resign ${mark(r)}' : format(move);
  }

  /// [narrate] that also knows the shared resign move.
  String narrateMove(Player mover, Map<String, dynamic> move, GameEvent event) {
    final r = Game.resignerOf(move);
    if (r == null) return narrate(mover, move, event);
    return '${playerName(r)} resigns. ${playerName(event.winner)} wins.';
  }

  /// The resign move typed as `resign` (for [byDefault], else the player to move)
  /// or `resign x` / `resign o`; null if [input] is not a resign command.
  Map<String, dynamic>? parseResign(String input, {Player? byDefault}) {
    final words = input.trim().toLowerCase().split(RegExp(r'\s+'));
    if (words.first != 'resign' || words.length > 2) return null;
    if (words.length == 1) return Game.resignMove(byDefault ?? game.currentPlayer);
    for (final p in Player.values) {
      if (words[1] == mark(p).toLowerCase() || words[1] == p.name || words[1] == playerName(p).toLowerCase()) {
        return Game.resignMove(p);
      }
    }
    return null;
  }

  /// Whether the board is worth showing after this event in a demo.
  bool isHighlight(GameEvent event) => event.winner != null || event.draw;

  /// Move picked by `auto` and unscripted demos. Random legal by default;
  /// games may play smarter so demos read like real games.
  Map<String, dynamic> autoMove(Random rng) {
    final legal = legalMoves;
    return legal[rng.nextInt(legal.length)];
  }

  /// A scripted game for `demo`, or null to auto-play with [autoMove].
  List<String>? get demoScript => null;

  /// Label for [p] on the board, e.g. `X` / `O`.
  String mark(Player? p) => switch (p) {
        Player.a => 'X',
        Player.b => 'O',
        null => '.',
      };

  /// Player names for the sentences, e.g. the handles of a network game (the
  /// CLI sets them); a player without one is [playerNameOf] ("Anna" / "Ben").
  Map<Player, String> names = const {};

  /// Name of [p] in sentences (KLD-103): [names], else "Anna" (A) / "Ben"
  /// (B), the app's default names; [mark] stays the symbol on the board.
  String playerName(Player? p) => names[p] ?? playerNameOf(p);

  String status() {
    final r = game.result;
    if (r.draw) return 'Draw (${r.reason})';
    // A resignation names the player as this adapter does ([names]).
    final resigned = r.code == GameEndReason.commonResigned ? game.resignedBy : null;
    final reason = resigned != null ? '${playerName(resigned)} resigned' : r.reason;
    if (r.winner != null) return '${playerName(r.winner)} wins ($reason)';
    return '${playerName(game.currentPlayer)} to move';
  }
}

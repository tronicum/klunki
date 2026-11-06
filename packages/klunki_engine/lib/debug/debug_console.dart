import 'dart:math';

import '../chess.dart';
import '../connect4.dart';
import '../game.dart';
import '../gostrategy.dart';
import '../mau_mau.dart';
import '../muehle.dart';
import '../quartett.dart';
import '../schiffe.dart';
import '../word_tiles.dart';

import 'chess_text.dart';
import 'connect4_text.dart';
import 'gostrategy_text.dart';
import 'mau_mau_text.dart';
import 'muehle_text.dart';
import 'quartett_text.dart';
import 'schiffe_text.dart';
import 'text_game.dart';
import 'word_tiles_text.dart';

/// Line-based debug console over the engines. Frontend-agnostic: feed it
/// lines with [handle], print what it returns. The terminal CLI and the
/// Flutter debug screen are both thin shells around this.
class DebugConsole {
  /// Available games by id. Add new [TextGame] adapters here.
  static final Map<String, TextGame Function()> games = {
    'connect4': Connect4Text.new,
    'muehle': MuehleText.new,
    'quartett-trumpf': QuartettTrumpfText.new,
    'quartett-sets': QuartettSetsText.new,
    'schiffe': SchiffeText.new,
    'gostrategy': GoStrategyText.new,
    'chess': ChessText.new,
    'wordtiles': WordTilesText.new,
    'maumau': MauMauText.new,
  };

  /// A text adapter around an existing [game] (e.g. `createGame(GameConfig(id, seed: s))`
  /// from a network session), so seeded games render the deal actually played.
  /// Throws [ArgumentError] for an unknown id or a game of the wrong type.
  static TextGame forGame(String gameId, Game game) => switch ((gameId, game)) {
        ('connect4', Connect4Game g) => Connect4Text(game: g),
        ('muehle', MuehleGame g) => MuehleText(game: g),
        ('quartett-trumpf', QuartettGame g) when g.mode == QuartettMode.trumpf => QuartettTrumpfText.forGame(g),
        ('quartett-sets', QuartettGame g) when g.mode == QuartettMode.sets => QuartettSetsText.forGame(g),
        ('schiffe', SchiffeGame g) => SchiffeText(game: g),
        ('gostrategy', GoStrategyGame g) => GoStrategyText(game: g),
        ('chess', ChessGame g) => ChessText(game: g),
        ('wordtiles', WordTilesGame g) => WordTilesText(game: g),
        ('maumau', MauMauGame g) => MauMauText.forGame(g),
        _ => throw ArgumentError.value(gameId, 'gameId', 'no text adapter for ${game.runtimeType}'),
      };

  /// Safety cap for `auto` / `demo` on games without a natural end.
  static const int autoMoveLimit = 2000;

  TextGame _current;

  /// Accepted moves of the current game, used for `undo` (replay minus one).
  final List<Map<String, dynamic>> _moves = [];

  /// Drives `auto`; seeded so a debug session can be reproduced.
  Random _rng;

  /// [deck] picks the Quartett deck (KLD-069) for the Quartett games; other
  /// games ignore it. Throws [ArgumentError] for an unknown deck.
  DebugConsole([String gameId = 'connect4', int seed = 1, String? deck])
      : _current = _make(gameId, deck),
        _rng = Random(seed);

  /// A fresh text game of [gameId], with [deck] for the Quartett games.
  static TextGame _make(String gameId, String? deck) {
    if (deck == null) return games[gameId]!();
    final d = QuartettDeck.byId(deck);
    if (d == null) throw ArgumentError.value(deck, 'deck', 'unknown deck (${deckIds.join(', ')})');
    return switch (gameId) {
      'quartett-trumpf' => QuartettTrumpfText(0, d),
      'quartett-sets' => QuartettSetsText(0, 8, d),
      _ => games[gameId]!(),
    };
  }

  /// Ids of the Quartett decks (`--deck`, `new quartett-trumpf trains`).
  static List<String> get deckIds => [for (final d in QuartettDeck.all) d.id];

  TextGame get current => _current;

  /// Board plus status line.
  String get screen => '${_current.title}\n${_current.render()}\n${_current.status()}';

  /// Handles one input line and returns the text to show.
  String handle(String line) {
    final input = line.trim();
    final words = input.split(RegExp(r'\s+'));
    switch (words.first) {
      case '':
        return screen;
      case 'help' || '?':
        return _help();
      case 'new':
        if (words.length > 1) {
          if (!games.containsKey(words[1])) return _unknownGame(words[1]);
          final deck = words.length > 2 ? words[2] : null;
          if (deck != null && QuartettDeck.byId(deck) == null) {
            return 'Unknown deck "$deck". Decks: ${deckIds.join(', ')}';
          }
          _current = _make(words[1], deck);
        } else {
          _current = _current.restart();
        }
        _moves.clear();
        return screen;
      case 'undo':
        if (_moves.isEmpty) return 'Nothing to undo.\n$screen';
        _moves.removeLast();
        _current = _current.restart();
        for (final m in _moves) {
          _current.game.applyMove(m);
        }
        return screen;
      case 'history':
        if (_moves.isEmpty) return 'No moves yet.';
        return [for (var i = 0; i < _moves.length; i++) '${i + 1}. ${_current.formatMove(_moves[i])}'].join('\n');
      case 'moves':
        final legal = _current.legalMoves.map(_current.format).toList();
        if (legal.isEmpty) return 'No legal moves (${_current.status()}).';
        final shown = legal.length > 60 ? [...legal.take(60), '… (${legal.length} total)'] : legal;
        return 'Legal moves for ${_current.playerName(_current.game.currentPlayer)}: ${shown.join(' ')}';
      case 'auto':
        final n = words.length > 1 ? int.tryParse(words[1]) : null;
        if (words.length > 1 && n == null) return 'Usage: auto [n]';
        return _auto(n ?? autoMoveLimit);
      case 'demo':
        final ids = words.length > 1 ? words.sublist(1) : games.keys.toList();
        final unknown = ids.where((id) => !games.containsKey(id));
        if (unknown.isNotEmpty) return _unknownGame(unknown.first);
        return [for (final id in ids) demo(id)].join('\n\n');
    }

    final move = _current.parseResign(input) ?? _current.parse(input);
    if (move == null) return 'Unknown command "$input". Type "help".';
    final narration = _apply(move);
    if (narration == null) return 'Illegal move "$input".\n$screen';
    return '$narration\n\n$screen';
  }

  /// Applies [move] and returns its narration, or null if it was illegal.
  String? _apply(Map<String, dynamic> move) {
    final mover = _current.game.playerOf(move);
    final event = _current.game.applyMove(move);
    if (event == null) return null;
    _moves.add(move);
    return _current.narrateMove(mover, move, event);
  }

  String _auto(int n) {
    final out = <String>[];
    for (var i = 0; i < n && !_current.game.isOver; i++) {
      if (_current.legalMoves.isEmpty) break;
      final move = _current.autoMove(_rng);
      out.add('${_current.format(move).padLeft(6)}  ${_apply(move)}');
    }
    return [...out, '', screen].join('\n');
  }

  /// A full game of [gameId], narrated move by move, with the board shown at
  /// the start, at highlights and at the end. Uses the game's script if it has
  /// one, otherwise [TextGame.autoMove] from a fixed seed.
  String demo(String gameId, {int seed = 7}) {
    final t = games[gameId]!();
    final rng = Random(seed);
    final script = t.demoScript;
    final b = StringBuffer()
      ..writeln('═' * 60)
      ..writeln(' DEMO: ${t.title}${script == null ? ' (auto-play, seed $seed)' : ''}')
      ..writeln('═' * 60)
      ..writeln(t.render())
      ..writeln();
    var turn = 0;
    while (!t.game.isOver && turn < (script?.length ?? autoMoveLimit)) {
      final move = script != null ? t.parse(script[turn])! : t.autoMove(rng);
      final mover = t.game.currentPlayer;
      final event = t.game.applyMove(move);
      if (event == null) throw StateError('demo move ${t.format(move)} is illegal');
      turn++;
      b.writeln('${'$turn.'.padLeft(4)} ${t.narrate(mover, move, event)}');
      if (t.isHighlight(event) && !t.game.isOver) {
        b
          ..writeln()
          ..writeln(t.render())
          ..writeln();
      }
    }
    b
      ..writeln()
      ..writeln(t.render())
      ..write('Result: ${t.status()} after $turn moves.');
    return b.toString();
  }

  String _unknownGame(String id) => 'Unknown game "$id". Games: ${games.keys.join(', ')}';

  String _help() => '''
${_current.title} moves:
  ${_current.moveHelp}
Commands:
  new [game]    restart, or switch game (${games.keys.join(', ')})
  new quartett-trumpf|quartett-sets <deck>   Quartett with a deck (${deckIds.join(', ')})
  moves         list legal moves
  auto [n]      play n random legal moves (default: to the end)
  resign [x|o]  give up (default: the player to move); the other player wins
  undo          take back the last move
  history       list accepted moves
  demo [games]  narrated full game of each (or the given) game
  help          this text''';
}

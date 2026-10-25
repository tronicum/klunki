import 'package:klunki_engine/klunki_engine.dart';

/// Legal moves of [game] as move maps (Connect4 returns column ints, the
/// other engines return maps already).
List<Map<String, dynamic>> legalMoves(Game game) {
  if (game is Connect4Game) return [for (final c in game.legalMoves) {'col': c}];
  return ((game as dynamic).legalMoves as List).cast<Map<String, dynamic>>();
}

import 'dart:math';

import '../game.dart';
import '../maexchen.dart';
import 'text_game.dart';

/// Text adapter for Mäxchen (KLD-121). The debug console sees everything,
/// so [render] shows the dice under the cup too (marked as secret).
class MaexchenText extends TextGame {
  MaexchenText({MaexchenGame? game}) : game = game ?? MaexchenGame();

  @override
  final MaexchenGame game;

  @override
  String get id => 'maexchen';
  @override
  String get title => 'Mäxchen';
  @override
  String get moveHelp => 'roll | announce <value> (e.g. "54", "21" = Mäxchen) | believe | doubt | giveup';

  @override
  MaexchenText restart() =>
      MaexchenText(game: MaexchenGame(startLives: game.startLives, maexchenDouble: game.maexchenDouble));

  static String valueName(int v) => v == MaexchenGame.maexchen ? 'Mäxchen (21)' : '$v';

  String _hearts(Player p) => '${'♥' * game.livesOf(p)}${'·' * (game.startLives - game.livesOf(p))}';

  @override
  String render() {
    final b = StringBuffer();
    for (final p in Player.values) {
      b.writeln('${mark(p)} ${playerName(p).padRight(6)} ${_hearts(p)}');
    }
    b.writeln('Round ${game.round}');
    final a = game.announced;
    b.writeln(a == null ? 'No announcement yet.' : 'Announced: ${valueName(a)} by ${playerName(game.announcer)}');
    final d = game.dice;
    if (d != null) {
      b.writeln('Under the cup (secret, ${playerName(game.roller)} rolled): ${d[0]} ${d[1]} = ${valueName(game.diceValue!)}');
    }
    final last = game.lastRound;
    if (last != null) b.write('Last round: ${_roundEnd(last)}');
    return b.toString().trimRight();
  }

  @override
  Map<String, dynamic>? parse(String input) {
    final words = input.trim().toLowerCase().split(RegExp(r'\s+'));
    switch (words.first) {
      case 'roll' || 'r':
        return MaexchenGame.rollMove;
      case 'believe' || 'b':
        return MaexchenGame.believeMove;
      case 'doubt' || 'd':
        return MaexchenGame.doubtMove;
      case 'giveup' || 'g':
        return MaexchenGame.giveUpMove;
      case 'maexchen' || 'mäxchen':
        return MaexchenGame.announceMove(MaexchenGame.maexchen);
      case 'announce' || 'a':
        final v = words.length == 2 ? int.tryParse(words[1]) : null;
        return v == null ? null : MaexchenGame.announceMove(v);
    }
    final v = words.length == 1 ? int.tryParse(words.first) : null;
    return v == null ? null : MaexchenGame.announceMove(v);
  }

  @override
  List<Map<String, dynamic>> get legalMoves => game.legalMoves;

  @override
  String format(Map<String, dynamic> move) => switch (move['action']) {
        'announce' => '${move['value']}',
        'giveUp' => 'giveup',
        final a => '$a',
      };

  String _roundEnd(MaexchenRoundEnd e) {
    final loser = playerName(Player.values[e.loser]);
    final lives = e.lost == 1 ? 'a life' : '${e.lost} lives';
    if (e.gaveUp) return '${playerName(Player.values[e.challenger])} gives up against Mäxchen and loses a life.';
    final shown = 'The cup shows ${e.dice![0]} ${e.dice![1]} = ${valueName(e.value!)}';
    return e.bluff ? '$shown: a bluff! $loser loses $lives.' : '$shown: true! $loser loses $lives.';
  }

  @override
  String narrate(Player mover, Map<String, dynamic> move, GameEvent event) {
    final who = playerName(mover);
    final s = switch (move['action']) {
      'roll' => '$who shakes the cup and peeks.',
      'announce' => '$who announces ${valueName(move['value'] as int)}.',
      'believe' => '$who believes it and takes the cup.',
      'doubt' => '$who doubts it. ${_roundEnd(game.lastRound!)}',
      'giveUp' => _roundEnd(game.lastRound!),
      _ => '$who: $move',
    };
    if (event.winner != null) return '$s ${playerName(event.winner)} wins!';
    return s;
  }

  @override
  bool isHighlight(GameEvent event) => event.payload is Map && (event.payload as Map).containsKey('roundEnd');

  /// Plays like a careful person: announces the truth when it is high
  /// enough, else bluffs a little above; doubts high announcements more
  /// often than low ones.
  @override
  Map<String, dynamic> autoMove(Random rng) {
    switch (game.phase) {
      case MaexchenPhase.roll:
        return MaexchenGame.rollMove;
      case MaexchenPhase.announce:
        final options = MaexchenGame.valuesAbove(game.announced);
        final real = game.diceValue!;
        if (options.contains(real)) return MaexchenGame.announceMove(real);
        return MaexchenGame.announceMove(options[rng.nextInt(min(2, options.length))]);
      case MaexchenPhase.respond:
        final a = game.announced!;
        if (a == MaexchenGame.maexchen) return rng.nextBool() ? MaexchenGame.doubtMove : MaexchenGame.giveUpMove;
        final risk = MaexchenGame.rankOf(a) / (MaexchenGame.ranking.length - 1);
        return rng.nextDouble() < risk ? MaexchenGame.doubtMove : MaexchenGame.believeMove;
    }
  }
}

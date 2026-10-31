import 'dart:io';

import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart' show QuartettDeck;

/// Terminal debug frontend.
///
///   dart run klunki_engine:klunki                    # interactive, 4 Gewinnt
///   dart run klunki_engine:klunki muehle             # interactive, other game
///   dart run klunki_engine:klunki connect4 3 3 4 4   # play moves, print, exit
///   dart run klunki_engine:klunki demo [games…]      # narrated demo games
///   dart run klunki_engine:klunki quartett-trumpf --deck trains   # Quartett deck
///
/// In scripted mode each argument after the game id is one console line.
void main(List<String> args) {
  if (args.isNotEmpty && args.first == 'demo') {
    stdout.writeln(DebugConsole().handle(args.join(' ')));
    return;
  }
  args = List.of(args);
  String? deck;
  final at = args.indexOf('--deck');
  if (at >= 0) {
    if (at + 1 >= args.length || QuartettDeck.byId(args[at + 1]) == null) {
      stderr.writeln('--deck needs one of: ${DebugConsole.deckIds.join(', ')}');
      exitCode = 64;
      return;
    }
    deck = args[at + 1];
    args.removeRange(at, at + 2);
  }
  final gameId = args.isEmpty ? 'connect4' : args.first;
  if (!DebugConsole.games.containsKey(gameId)) {
    stderr.writeln('Unknown game "$gameId". Games: ${DebugConsole.games.keys.join(', ')}');
    exitCode = 64;
    return;
  }
  final console = DebugConsole(gameId, 1, deck);

  if (args.length > 1) {
    for (final line in args.skip(1)) {
      stdout
        ..writeln('> $line')
        ..writeln(console.handle(line))
        ..writeln();
    }
    return;
  }

  stdout
    ..writeln(console.screen)
    ..writeln('Type "help" for commands, "quit" to exit.');
  while (true) {
    stdout.write('> ');
    final line = stdin.readLineSync();
    if (line == null || line.trim() == 'quit' || line.trim() == 'exit') return;
    stdout.writeln(console.handle(line));
  }
}

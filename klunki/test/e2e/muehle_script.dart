// The scripted Mühle game both e2e layers play (KLD-037a protocol level,
// KLD-037b app level, KLD-038a on simulators): the engine's 33-move
// "Zwickmühle" demo (MuehleText.demoScript). X (player A, the "iOS" host)
// is ground down to 2 pieces; O (player B, the "Android" guest) wins.
//
// Pure Dart on purpose (no Flutter imports) so KLD-038a can copy it into
// klunki/integration_test/.
import 'package:klunki_engine/debug.dart';
import 'package:klunki_engine/klunki_engine.dart';

/// One scripted step: the console command, the move map, and the board
/// points to tap in the UI for it (one tap for place/remove, two for a move:
/// select the stone, then the target).
class ScriptStep {
  final int index;
  final String command;
  final Map<String, dynamic> move;
  final List<int> taps;

  const ScriptStep(this.index, this.command, this.move, this.taps);

  @override
  String toString() => '#$index "$command"';
}

/// The 33 steps of the demo game, in order.
final List<ScriptStep> muehleScript = _build();

/// Number of moves in [muehleScript].
const muehleScriptLength = 33;

/// How the scripted game ends.
const muehleScriptWinner = Player.b;
const muehleScriptReason = 'opponent has fewer than 3 pieces';

List<ScriptStep> _build() {
  final text = MuehleText();
  final steps = <ScriptStep>[];
  for (final cmd in text.demoScript) {
    final move = text.parse(cmd)!;
    final taps = switch (move['action']) {
      'place' => [move['to'] as int],
      'remove' => [move['at'] as int],
      _ => [move['from'] as int, move['to'] as int],
    };
    steps.add(ScriptStep(steps.length, cmd, Map.unmodifiable(move), List.unmodifiable(taps)));
  }
  assert(steps.length == muehleScriptLength);
  return List.unmodifiable(steps);
}

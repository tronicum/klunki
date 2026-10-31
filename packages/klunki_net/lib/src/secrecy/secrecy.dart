import 'dart:convert';
import 'dart:math';

import 'package:klunki_engine/klunki_engine.dart';

import '../events.dart';
import 'sha256.dart';

/// Commitments, view hashes and the end-of-game check for hidden-information
/// games (KLD-064, see PROTOCOL.md, "Hidden information").

/// 16 random bytes as hex (`Random.secure`).
String newSalt() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// The commitment to [value] under [label] (`seed` or `move:<index>`) with
/// [salt]: hex SHA-256 of `klunki-commit-v2\n<label>\n<salt>\n<canonical JSON>`.
String commitment(String salt, String label, Object? value) =>
    sha256Hex('klunki-commit-v2\n$label\n$salt\n${canonicalJson(value)}');

/// Hash of a player view (first 128 bits of SHA-256 over the canonical
/// JSON, as hex): what the snapshot carries per log entry instead of the
/// whole view.
String viewHash(Map<String, dynamic> view) => sha256Hex('klunki-view-v2\n${canonicalJson(view)}').substring(0, 32);

/// One log entry as the remote (guest) player sees it.
class RedactedStep {
  final Player player;
  final Map<String, dynamic> move;
  final Map<String, dynamic> event;
  final String viewHash;

  /// Set when [move] hides a secret of the host ([commitment] of the full
  /// move under `move:<index>`).
  final String? commit;

  const RedactedStep(this.player, this.move, this.event, this.viewHash, this.commit);

  Map<String, dynamic> toJson() =>
      {'player': player.name, 'move': move, 'event': event, 'viewHash': viewHash, if (commit != null) 'commit': commit};

  factory RedactedStep.fromJson(Map<String, dynamic> j) {
    final commit = j['commit'];
    final hash = j['viewHash'];
    if (hash is! String || (commit != null && commit is! String)) {
      throw const ProtocolException('log entry needs "viewHash" (and a string "commit")');
    }
    return RedactedStep(playerFromName(j['player']), j['move'] as Map<String, dynamic>,
        j['event'] as Map<String, dynamic>, hash, commit as String?);
  }
}

/// A secret move the host reveals at the end.
class RevealedMove {
  final Map<String, dynamic> move;
  final String salt;
  const RevealedMove(this.move, this.salt);
}

Map<String, dynamic> _copy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

/// Replays a finished hidden-information game from the host's reveal and
/// checks everything the guest ([me]) was told. Returns null if all of it
/// holds, otherwise what did not:
///
/// * the seed (if secret) matches [seedCommit];
/// * every committed move is revealed and matches its commitment, and no
///   other move is "revealed";
/// * replaying the full game from the start reproduces, for every step, the
///   player, the redacted move, the redacted event and the hash of [me]'s
///   view that the host reported, and the start view [startViewHash];
/// * the game is over at the end.
String? verifyRedactedGame({
  required String gameId,
  required Player me,
  required int seed,
  required String startViewHash,
  required List<RedactedStep> steps,
  required Map<int, RevealedMove> secrets,
  String? seedSalt,
  String? seedCommit,
}) {
  final spec = specById(gameId);
  final redaction = spec?.redaction;
  if (spec == null || redaction == null) return 'not a hidden-information game: $gameId';
  if (redaction.secretSeed) {
    if (seedCommit == null || seedSalt == null) return 'seed commitment missing';
    if (commitment(seedSalt, 'seed', seed) != seedCommit) return 'the seed does not match its commitment';
  }
  final full = <Map<String, dynamic>>[];
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    final secret = secrets[i];
    if (step.commit == null) {
      if (secret != null) return 'move $i was revealed but never committed';
      full.add(_copy(step.move));
      continue;
    }
    if (secret == null) return 'committed move $i was not revealed';
    if (commitment(secret.salt, 'move:$i', secret.move) != step.commit) {
      return 'move $i does not match its commitment';
    }
    full.add(_copy(secret.move));
  }
  if (secrets.keys.any((i) => i < 0 || i >= steps.length)) return 'revealed a move outside the log';

  final Game game;
  try {
    game = createGame(GameConfig(gameId, seed: seed));
  } catch (e) {
    return 'cannot create the game: $e';
  }
  if (viewHash(redaction.view(game, me)) != startViewHash) return 'the start position does not match';
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    final mover = game.currentPlayer;
    if (mover != step.player) return 'move $i was reported for the wrong player';
    final GameEvent? event;
    try {
      event = game.applyMove(_copy(full[i]));
    } catch (e) {
      return 'move $i does not replay: $e';
    }
    if (event == null) return 'move $i is not legal on replay';
    final expected = redaction.step(game, full[i], mover, event, me);
    if (canonicalJson(expected['move']) != canonicalJson(step.move)) return 'move $i was reported differently';
    if (canonicalJson(expected['event']) != canonicalJson(step.event)) return 'the outcome of move $i was misreported';
    if (viewHash(expected['view'] as Map<String, dynamic>) != step.viewHash) {
      return 'the position after move $i was misreported';
    }
  }
  if (!game.isOver) return 'the game is not over';
  return null;
}

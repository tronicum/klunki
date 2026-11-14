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
///
/// At a table (KLD-088) the entry names its [seat] (`seat` on the wire)
/// instead of a player, and [commit] covers any move whose redacted form
/// differs from the real one for this viewer: a secret of the host or of
/// another guest.
class RedactedStep {
  /// The seat that moved ([Player]'s index in a two-player game).
  final int seat;

  /// True for a table entry (written with `seat`, not `player`).
  final bool bySeat;
  final Map<String, dynamic> move;
  final Map<String, dynamic> event;
  final String viewHash;

  /// Set when [move] hides a secret of another seat ([commitment] of the
  /// full move under `move:<index>`).
  final String? commit;

  RedactedStep(Player player, this.move, this.event, this.viewHash, this.commit)
      : seat = player.index,
        bySeat = false;

  /// A table entry (KLD-088).
  const RedactedStep.bySeat(this.seat, this.move, this.event, this.viewHash, this.commit) : bySeat = true;

  /// The player who moved; throws for seat 2+.
  Player get player => switch (seat) {
        0 => Player.a,
        1 => Player.b,
        _ => throw StateError('seat $seat has no Player (KLD-088)'),
      };

  Map<String, dynamic> toJson() => {
        if (bySeat) 'seat': seat else 'player': player.name,
        'move': move,
        'event': event,
        'viewHash': viewHash,
        if (commit != null) 'commit': commit,
      };

  /// [bySeat]: a table's entry (`seat` instead of `player`).
  factory RedactedStep.fromJson(Map<String, dynamic> j, {bool bySeat = false}) {
    final commit = j['commit'];
    final hash = j['viewHash'];
    if (hash is! String || (commit != null && commit is! String)) {
      throw const ProtocolException('log entry needs "viewHash" (and a string "commit")');
    }
    if (bySeat) {
      final seat = j['seat'];
      if (seat is! int) throw const ProtocolException('log entry needs an int "seat"');
      return RedactedStep.bySeat(
          seat, j['move'] as Map<String, dynamic>, j['event'] as Map<String, dynamic>, hash, commit as String?);
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
///
/// [config] is the game's public config (as the guest got it in `welcome`):
/// when given, the game is created from it with the revealed [seed], so
/// every start option counts (Mau-Mau's house rules, Wortgewandt's
/// "Restpunkte abziehen", …) and [gameId] and the single options below are
/// ignored. Without it the game is built from those single options (older
/// callers and tests).
String? verifyRedactedGame({
  GameConfig? config,
  required String gameId,
  String? deck,
  bool pickLowCards = true,
  String? tiles,
  bool dictionary = false,
  bool jokerSwap = false,
  int lives = 3,
  bool maexchenDouble = true,
  bool maexchenUnlimited = false,
  Player? me,
  int? seat,
  required int seed,
  required String startViewHash,
  required List<RedactedStep> steps,
  required Map<int, RevealedMove> secrets,
  String? seedSalt,
  String? seedCommit,
}) {
  // A table (KLD-088): the viewer is a seat, every step names its seat.
  if ((me == null) == (seat == null)) throw ArgumentError('give either me or seat');
  final viewer = seat ?? me!.index;
  final id = config?.gameId ?? gameId;
  final spec = specById(id);
  final redaction = spec?.redaction;
  if (spec == null || redaction == null) return 'not a hidden-information game: $id';
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
    game = createGame(config?.copyWith(seed: seed) ??
        GameConfig(gameId,
            seed: seed,
        deck: deck,
        pickLowCards: pickLowCards,
        tiles: tiles,
        dictionary: dictionary,
        jokerSwap: jokerSwap,
        lives: lives,
        maexchenDouble: maexchenDouble,
        maexchenUnlimited: maexchenUnlimited));
  } catch (e) {
    return 'cannot create the game: $e';
  }
  if (seat != null && (game is! SeatGame || !redaction.seats)) return 'not a game for a table: $id';
  final start = seat == null ? redaction.view(game, me!) : redaction.seatView(game, viewer);
  if (viewHash(start) != startViewHash) return 'the start position does not match';
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    // A resign (and an answer) names its player or seat (KLD-065).
    final mover = seat == null ? game.playerOf(full[i]).index : (game as SeatGame).seatOfMove(full[i]);
    if (mover != step.seat) return 'move $i was reported for the wrong player';
    final GameEvent? event;
    try {
      event = game.applyMove(_copy(full[i]));
    } catch (e) {
      return 'move $i does not replay: $e';
    }
    if (event == null) return 'move $i is not legal on replay';
    final expected = seat == null
        ? redaction.step(game, full[i], Player.values[mover], event, me!)
        : redaction.seatStep(game, full[i], mover, event, viewer);
    if (canonicalJson(expected['move']) != canonicalJson(step.move)) return 'move $i was reported differently';
    if (canonicalJson(expected['event']) != canonicalJson(step.event)) return 'the outcome of move $i was misreported';
    if (viewHash(expected['view'] as Map<String, dynamic>) != step.viewHash) {
      return 'the position after move $i was misreported';
    }
  }
  if (!game.isOver) return 'the game is not over';
  return null;
}

import 'package:klunki_engine/klunki_engine.dart';

/// A paused hot-seat game (KLD-079): everything needed to rebuild it on
/// this device later, as small JSON.
///
/// ```json
/// {"format": 1, "gameId": "chess", "rulesVersion": 4,
///  "fingerprint": {"rules": 4, "rev": 1, "content": "…"},
///  "config": {"game": "chess", "seed": 7, "clock": "300+0"},
///  "moves": [{…}, …], "names": ["Mia", null],
///  "savedAt": "2026-11-14T10:00:00.000", "clock": {…}, "clockBefore": [{…}, …]}
/// ```
///
/// [config] (the [GameConfig] JSON with seed, house rules and player count)
/// plus [moves] is a full replay (`replay(config, moves)`): the engines are
/// deterministic. [names] are the typed hot-seat names per seat (null = the
/// default name of the app language, as in the name stores). [clock] (chess
/// with a clock, KLD-126) is the clock when the game was saved, [clockBefore]
/// the clock before each move (hot-seat undo); time is not in the move log.
///
/// [rulesVersion] and [fingerprint] are this build's [GameSpec.rulesVersion]
/// and [fingerprintOf] when the game was saved: a later build with other
/// rules, deck data or board theme cannot replay the log the same way, so
/// such a save is offered for deletion only ([SavedGame.isOutdated]).
class SavedGame {
  /// The JSON layout of a save; a newer layout is unreadable here.
  static const int currentFormat = 1;

  final GameConfig config;
  final int rulesVersion;
  final GameFingerprint? fingerprint;
  final List<Map<String, dynamic>> moves;
  final List<String?> names;
  final DateTime savedAt;
  final ChessClockSnapshot? clock;
  final List<ChessClockSnapshot> clockBefore;

  const SavedGame({
    required this.config,
    required this.rulesVersion,
    required this.fingerprint,
    required this.moves,
    required this.names,
    required this.savedAt,
    this.clock,
    this.clockBefore = const [],
  });

  /// A save of the game [config] + [moves] made with this build.
  factory SavedGame.now(GameConfig config, List<Map<String, dynamic>> moves,
          {List<String?> names = const [], ChessClockSnapshot? clock, List<ChessClockSnapshot> clockBefore = const [],
          DateTime? savedAt}) =>
      SavedGame(
          config: config,
          rulesVersion: specById(config.gameId)?.rulesVersion ?? 0,
          fingerprint: fingerprintOf(config),
          moves: moves,
          names: names,
          savedAt: savedAt ?? DateTime.now(),
          clock: clock,
          clockBefore: clockBefore);

  String get gameId => config.gameId;

  /// Whether this build plays the game differently than the one that saved
  /// it (another rules version, deck or theme data), or does not know it.
  bool get isOutdated {
    final spec = specById(gameId);
    if (spec == null || !spec.appReady || spec.rulesVersion != rulesVersion) return true;
    final now = fingerprintOf(config);
    return now == null || (fingerprint != null && now != fingerprint);
  }

  Map<String, dynamic> toJson() => {
        'format': currentFormat,
        'gameId': gameId,
        'rulesVersion': rulesVersion,
        if (fingerprint != null) 'fingerprint': fingerprint!.toJson(),
        'config': config.toJson(),
        'moves': moves,
        'names': names,
        'savedAt': savedAt.toIso8601String(),
        if (clock != null) 'clock': clock!.toJson(),
        if (clockBefore.isNotEmpty) 'clockBefore': [for (final c in clockBefore) c.toJson()],
      };

  /// The save in [json], or null when it is not one this build can read (a
  /// newer format, damaged data). Never throws.
  static SavedGame? tryParse(Object? json) {
    try {
      if (json is! Map) return null;
      final format = json['format'], rules = json['rulesVersion'], config = json['config'], moves = json['moves'];
      if (format is! int || format > currentFormat || rules is! int || config is! Map || moves is! List) return null;
      final cfg = GameConfig.fromJson(Map<String, dynamic>.from(config));
      if (json['gameId'] != cfg.gameId) return null;
      final names = json['names'];
      final before = json['clockBefore'];
      final clockBefore = <ChessClockSnapshot>[
        if (before is List)
          for (final c in before) ChessClockSnapshot.tryParse(c) ?? (throw const FormatException('clockBefore')),
      ];
      return SavedGame(
        config: cfg,
        rulesVersion: rules,
        fingerprint: GameFingerprint.tryParse(json['fingerprint']),
        moves: [for (final m in moves) Map<String, dynamic>.from(m as Map)],
        names: [if (names is List) for (final n in names) n is String ? n : null],
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        clock: ChessClockSnapshot.tryParse(json['clock']),
        clockBefore: clockBefore,
      );
    } catch (_) {
      return null;
    }
  }
}

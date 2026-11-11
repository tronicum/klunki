import 'game.dart';

/// A chess time control (KLD-126): [baseMs] per player plus [incrementMs]
/// added after each of the player's own board moves (Fischer increment).
///
/// Config form ([id], `GameConfig.chessClock`, JSON key `clock`): whole
/// seconds `"<base>+<increment>"`, e.g. `"300+0"` (5 minutes) or `"900+10"`
/// (15 minutes + 10 s per move).
class ChessTimeControl {
  final int baseMs;
  final int incrementMs;
  const ChessTimeControl(this.baseMs, [this.incrementMs = 0]);

  /// The choices the app offers ("Ohne Uhr" is no time control at all).
  static const List<ChessTimeControl> presets = [
    ChessTimeControl(5 * 60000),
    ChessTimeControl(10 * 60000),
    ChessTimeControl(15 * 60000, 10000),
    ChessTimeControl(30 * 60000),
  ];

  /// `"<base s>+<increment s>"`.
  String get id => '${baseMs ~/ 1000}+${incrementMs ~/ 1000}';

  /// The control for [id], or null if malformed (base 1 s … 24 h,
  /// increment 0 … 10 min).
  static ChessTimeControl? tryParse(Object? id) {
    if (id is! String) return null;
    final m = RegExp(r'^(\d{1,5})\+(\d{1,3})$').firstMatch(id);
    if (m == null) return null;
    final base = int.parse(m[1]!), inc = int.parse(m[2]!);
    if (base < 1 || base > 86400 || inc > 600) return null;
    return ChessTimeControl(base * 1000, inc * 1000);
  }

  @override
  bool operator ==(Object other) => other is ChessTimeControl && other.baseMs == baseMs && other.incrementMs == incrementMs;

  @override
  int get hashCode => Object.hash(baseMs, incrementMs);

  @override
  String toString() => 'ChessTimeControl($id)';
}

/// What the clock shows at one moment: both players' remaining time, whose
/// clock runs and whether the clocks stand still. Sent by a network host as
/// `clock` (KLD-126, PROTOCOL.md): `{"a": ms, "b": ms, "run": "a"|"b"|null,
/// "paused": bool, "spent": ms}`.
class ChessClockSnapshot {
  final int a;
  final int b;

  /// How long the running player has used of the current turn so far (ms):
  /// a guest measures its think time from the start of its turn even when a
  /// snapshot arrives in the middle of it (a pause, a reconnect).
  final int spent;

  /// The player whose clock is running, or null (not started yet, game over).
  final Player? running;

  /// True while the clocks stand still although a player is to move (a
  /// pause, a network guest that is away).
  final bool paused;
  const ChessClockSnapshot({required this.a, required this.b, this.running, this.paused = false, this.spent = 0});

  int of(Player p) => p == Player.a ? a : b;

  Map<String, dynamic> toJson() => {'a': a, 'b': b, 'run': running?.name, 'paused': paused, 'spent': spent};

  /// The snapshot in [json], or null if malformed.
  static ChessClockSnapshot? tryParse(Object? json) {
    if (json is! Map) return null;
    final a = json['a'], b = json['b'], run = json['run'], paused = json['paused'], spent = json['spent'] ?? 0;
    if (a is! int || b is! int || paused is! bool || spent is! int || spent < 0) return null;
    if (run != null && run != 'a' && run != 'b') return null;
    final running = run == null ? null : (run == 'a' ? Player.a : Player.b);
    return ChessClockSnapshot(a: a, b: b, running: running, paused: paused, spent: spent);
  }

  @override
  bool operator ==(Object other) =>
      other is ChessClockSnapshot &&
      other.a == a &&
      other.b == b &&
      other.running == running &&
      other.paused == paused &&
      other.spent == spent;

  @override
  int get hashCode => Object.hash(a, b, running, paused, spent);

  @override
  String toString() => 'ChessClockSnapshot(a: $a, b: $b, run: ${running?.name}, paused: $paused, spent: $spent)';
}

/// A two-player chess clock (KLD-126). Pure and deterministic: every method
/// takes the current time [now] in milliseconds from any monotonic source
/// (a `Stopwatch` in the app, a fake in tests), so the clock never reads a
/// wall clock itself.
///
/// The running player's clock counts down from [start] on; [moveMade]
/// stops it, adds the increment and starts the other one. The clocks stand
/// still while [paused] (an agreed pause, the hot-seat pause cover) or
/// [held] (a network host whose guest is away); the two are independent.
/// [stop] ends the clock for good (game over).
///
/// Time is not part of a game's move log: the clock lives next to it (the
/// hot-seat transport, the network host). Only a flag fall reaches the log,
/// as the move [ChessGame.timeoutMove].
class ChessClock {
  final ChessTimeControl control;
  final Map<Player, int> _remaining;
  Player? _running;
  int _since = 0; // when the running clock last started ticking
  int _turnStart = 0; // the running player's time when the turn began
  bool _paused = false;
  bool _held = false;
  bool _stopped = false;

  ChessClock(this.control) : _remaining = {Player.a: control.baseMs, Player.b: control.baseMs};

  /// A clock showing [snapshot] at [now] (a network guest's mirror of the
  /// host's clock, the hot-seat undo).
  ChessClock.fromSnapshot(this.control, ChessClockSnapshot snapshot, int now)
      : _remaining = {Player.a: snapshot.a, Player.b: snapshot.b},
        _running = snapshot.running,
        _since = now,
        _turnStart = (snapshot.running == null ? 0 : snapshot.of(snapshot.running!)) + snapshot.spent,
        _paused = snapshot.paused;

  Player? get running => _stopped ? null : _running;
  bool get paused => _paused;
  bool get held => _held;
  bool get stopped => _stopped;

  /// Whether a clock is counting down now.
  bool get ticking => !_stopped && _running != null && !_paused && !_held;

  /// [player]'s remaining time at [now] in ms (negative once the flag fell
  /// and nobody stopped the clock yet).
  int remainingOf(Player player, int now) =>
      _remaining[player]! - (ticking && _running == player ? now - _since : 0);

  /// The player whose time ran out at [now], or null.
  Player? flagged(int now) {
    final r = running;
    return r != null && remainingOf(r, now) <= 0 ? r : null;
  }

  /// Milliseconds from [now] until the running player's flag falls, or null
  /// when no clock ticks.
  int? untilFlag(int now) => ticking ? remainingOf(_running!, now) : null;

  void _settle(int now) {
    if (ticking) _remaining[_running!] = _remaining[_running!]! - (now - _since);
    _since = now;
  }

  /// Starts [player]'s clock (White's, when the game begins). Ignored once
  /// a clock runs or after [stop].
  void start(Player player, int now) {
    if (_stopped || _running != null) return;
    _running = player;
    _since = now;
    _turnStart = _remaining[player]!;
  }

  /// How long the running player has used of the current turn at [now]
  /// (pauses not counted); 0 when no clock runs.
  int turnElapsed(int now) {
    final r = running;
    return r == null ? 0 : _turnStart - remainingOf(r, now);
  }

  /// [mover] made a board move at [now]: [mover]'s clock stops, the
  /// increment is added and the other player's clock starts. The turn costs
  /// [turnElapsed], or [charge] ms when given (a network host's lag rule,
  /// PROTOCOL.md). Returns the time charged. Before [start] and after
  /// [stop] nothing happens (returns 0).
  int moveMade(Player mover, int now, {int? charge}) {
    if (_stopped || _running == null) return 0;
    _settle(now);
    var spent = 0;
    if (_running == mover) {
      spent = charge ?? (_turnStart - _remaining[mover]!);
      _remaining[mover] = _turnStart - spent;
    }
    _remaining[mover] = _remaining[mover]! + control.incrementMs;
    final next = mover == Player.a ? Player.b : Player.a;
    _running = next;
    _turnStart = _remaining[next]!;
    return spent;
  }

  /// Pauses or resumes both clocks ([paused]).
  void setPaused(bool paused, int now) {
    if (paused == _paused) return;
    _settle(now);
    _paused = paused;
  }

  /// Holds or releases both clocks ([held]; a network guest away).
  void setHeld(bool held, int now) {
    if (held == _held) return;
    _settle(now);
    _held = held;
  }

  /// Stops the clock for good (game over); [remainingOf] keeps the values
  /// of [now].
  void stop(int now) {
    if (_stopped) return;
    _settle(now);
    _stopped = true;
  }

  /// The clock at [now]; [paused] in it means "standing still" ([paused] or
  /// [held]).
  ChessClockSnapshot snapshot(int now) => ChessClockSnapshot(
      a: remainingOf(Player.a, now),
      b: remainingOf(Player.b, now),
      running: running,
      paused: _paused || _held,
      spent: turnElapsed(now));
}

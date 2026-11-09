import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../transport/game_transport.dart';
import '../transport/hot_seat_transport.dart';

/// The one object a game screen talks to. Wraps a [GameTransport], mirrors
/// its accepted moves and notifies listeners on every change.
///
/// State changes come from the transport's `accepted` stream, so local and
/// remote moves are handled the same way. [undo], [restart] and
/// [acknowledgeHandover] notify directly.
class GameController extends ChangeNotifier {
  final GameTransport Function(GameConfig) _transportFactory;
  GameTransport _transport;
  StreamSubscription<AcceptedMove>? _sub;
  GameEvent? _lastEvent;
  bool _needsHandover = false;
  bool _disposed = false;

  /// [transportFactory] is used by [restart]; defaults to hot-seat.
  GameController(GameTransport transport, {GameTransport Function(GameConfig)? transportFactory})
      : _transport = transport,
        _transportFactory = transportFactory ?? HotSeatTransport.new {
    _attach();
  }

  /// Convenience: a hot-seat game for [config].
  GameController.hotSeat(GameConfig config) : this(HotSeatTransport(config));

  GameTransport get transport => _transport;
  Game get game => _transport.game;
  GameConfig get config => _transport.config;
  GameSpec get spec => specById(config.gameId)!;

  /// Event of the most recent accepted move (null after a restart or an undo
  /// back to the start).
  GameEvent? get lastEvent => _lastEvent;

  /// Accepted move log.
  List<AcceptedMove> get moves => _transport.moves;

  /// The player to move is local and the game is not over. Ignores
  /// [needsHandover]; the cover screen blocks input while that is set.
  /// A game with more than two seats is played on one device only (every
  /// seat is local, KLD-119).
  bool get canAct {
    if (game.isOver) return false;
    if (seatGame != null) return seatGame!.actorSeat != null;
    return _transport.localPlayers.contains(game.currentPlayer);
  }

  /// The game as a [SeatGame] when it has more than two seats (KLD-088,
  /// KLD-119), else null: such a game is driven by seat ([SeatGame.actorSeat],
  /// [resignSeat]) because `currentPlayer` throws for seats 2 and 3. A
  /// two-seat game runs through [Game] as always.
  SeatGame? get seatGame {
    final g = game;
    return g is SeatGame && (g as SeatGame).playerCount > 2 ? g as SeatGame : null;
  }

  /// The seats that may resign now in a [seatGame]: every seat still in
  /// while the game runs (all of them sit at this device).
  List<int> get canResignSeats {
    final g = seatGame;
    if (g == null || game.isOver) return const [];
    return [for (var s = 0; s < g.playerCount; s++) if (!g.isSeatOut(s)) s];
  }

  /// Seat [seat] of a [seatGame] leaves; the others play on (a normal move,
  /// so hot-seat undo takes it back).
  Future<SubmitResult> resignSeat(int seat) => submit({'action': 'resign', 'seat': seat});

  /// Who is to move as a number, null once over: the seat expected to act
  /// for any [SeatGame] (also with two seats: the word tile game's answerer
  /// of an open "Trotzdem zulassen" request, KLD-094, who is not
  /// `currentPlayer`), else the player's index. The handover cover follows
  /// it, so the device goes to whoever has to act next.
  int? get _turn {
    final g = game;
    if (g.isOver) return null;
    if (g is SeatGame) return (g as SeatGame).actorSeat;
    return g.currentPlayer.index;
  }

  /// Undo is available (hot-seat only, with at least one move).
  bool get canUndo {
    final t = _transport;
    return t is HotSeatTransport && t.canUndo;
  }

  /// A hidden-information game on a shared device just passed the turn to the
  /// other player: show a cover until [acknowledgeHandover].
  bool get needsHandover => _needsHandover;

  bool get _sharedDeviceSecrets => spec.hiddenInformation && _transport.localPlayers.length > 1;

  Future<SubmitResult> submit(Map<String, dynamic> move) => _transport.submit(move);

  /// A private copy of the game with every accepted move replayed, for
  /// previewing a move before it is submitted; null when this device only
  /// holds a redacted view (network guest of a hidden-information game,
  /// KLD-064): such a screen submits and shows the outcome from the event.
  Game? previewCopy() => _transport.fullInformation ? replay(config, moves.map((m) => m.move)) : null;

  /// Players who may resign now (KLD-065): the local players while the game
  /// runs, regardless of whose turn it is.
  Set<Player> get canResign => game.isOver ? const {} : _transport.localPlayers;

  /// [player] gives up; the other player wins. A normal move in the log
  /// (hot-seat undo takes it back).
  Future<SubmitResult> resign(Player player) => submit(Game.resignMove(player));

  void acknowledgeHandover() {
    if (!_needsHandover) return;
    _needsHandover = false;
    notifyListeners();
  }

  /// Takes back the last move (hot-seat only). Returns false if not possible.
  bool undo() {
    final t = _transport;
    if (t is! HotSeatTransport) return false;
    final before = _turn;
    if (!t.undo()) return false;
    final log = t.moves;
    _lastEvent = log.isEmpty ? null : log.last.event;
    _toMove = _turn;
    if (_sharedDeviceSecrets && _turn != before) _needsHandover = true;
    notifyListeners();
    return true;
  }

  /// Starts a fresh game of the same kind, with the same [seed] unless one is
  /// given. Disposes the old transport.
  void restart({int? seed}) {
    final next = config.copyWith(seed: seed);
    _detach();
    _transport.dispose();
    _transport = _transportFactory(next);
    _lastEvent = null;
    _needsHandover = false;
    _attach();
    notifyListeners();
  }

  void _attach() {
    _toMove = _turn;
    _sub = _transport.accepted.listen(_onAccepted);
  }

  void _detach() {
    _sub?.cancel();
    _sub = null;
  }

  void _onAccepted(AcceptedMove m) {
    if (_disposed) return;
    _lastEvent = m.event;
    final before = _toMove;
    _toMove = _turn;
    if (game.isOver) {
      _needsHandover = false; // e.g. a resign while the cover was up
    } else if (_sharedDeviceSecrets && _toMove != before) {
      // The turn passed to another player. Usually by the mover's own
      // move; with "Trotzdem zulassen" (KLD-094) the request hands the
      // device to the player who answers, a refusal hands it back to the
      // placer, and an agreement needs no cover (the answerer plays next);
      // a move that leaves the turn where it was needs no cover.
      _needsHandover = true;
    }
    notifyListeners();
  }

  /// Who was to move after the last accepted move ([_turn]; null once over).
  int? _toMove;

  @override
  void dispose() {
    _disposed = true;
    _detach();
    _transport.dispose();
    super.dispose();
  }
}

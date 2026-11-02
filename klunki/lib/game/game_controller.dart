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
  bool get canAct => !game.isOver && _transport.localPlayers.contains(game.currentPlayer);

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
    final before = game.currentPlayer;
    if (!t.undo()) return false;
    final log = t.moves;
    _lastEvent = log.isEmpty ? null : log.last.event;
    _toMove = game.isOver ? null : game.currentPlayer;
    if (_sharedDeviceSecrets && game.currentPlayer != before) _needsHandover = true;
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
    _toMove = game.isOver ? null : game.currentPlayer;
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
    _toMove = game.isOver ? null : game.currentPlayer;
    if (game.isOver) {
      _needsHandover = false; // e.g. a resign while the cover was up
    } else if (_sharedDeviceSecrets && game.currentPlayer != before) {
      // The turn passed to the other player. Usually by the mover's own
      // move; with KLD-094 step 6 also by the other player's answer
      // ("Trotzdem zulassen" agreed, then the turn passes), while a move
      // that leaves the turn where it was needs no cover.
      _needsHandover = true;
    }
    notifyListeners();
  }

  /// The player to move after the last accepted move (null once over).
  Player? _toMove;

  @override
  void dispose() {
    _disposed = true;
    _detach();
    _transport.dispose();
    super.dispose();
  }
}

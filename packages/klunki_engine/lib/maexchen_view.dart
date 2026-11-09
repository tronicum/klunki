part of 'maexchen.dart';

/// A Mäxchen game as one player sees it (KLD-121): built from
/// [MaexchenGame.viewJson] on the remote side of a network game. It knows
/// everything but the dice under the cup when someone else rolled them
/// ([dice] is null then). Read-only: [applyMove] returns null (the host
/// applies moves and sends the next view).
class MaexchenView extends MaexchenGame {
  /// The player whose view this is.
  final Player viewer;

  MaexchenView._(this.viewer,
      {required super.startLives,
      required super.maexchenDouble,
      required super.unlimitedLives,
      required super.playerCount});

  /// Rebuilds the view from [MaexchenGame.viewJson]; throws
  /// [BadViewException] if [j] is malformed.
  factory MaexchenView.fromJson(Map<String, dynamic> j) {
    try {
      final viewer = playerIn(j['viewer']);
      final view = MaexchenView._(viewer,
          startLives: j['startLives'] as int,
          maexchenDouble: j['double'] == true,
          unlimitedLives: j['unlimited'] == true,
          playerCount: j['players'] as int);
      final lives = (j['lives'] as List).cast<int>();
      if (lives.length != view.playerCount) throw const BadViewException('bad lives');
      view._lives.setAll(0, lives);
      final lost = j['lost'];
      if (lost != null) {
        final l = (lost as List).cast<int>();
        if (l.length != view.playerCount) throw const BadViewException('bad lost');
        view._lost.setAll(0, l);
      }
      // Seats out: listed with 3–4 seats; with two the one without lives.
      final out = j['out'];
      if (out != null) {
        for (final s in out as List) {
          view._out.add(view._checkSeat(s));
        }
      } else {
        for (var s = 0; s < view.playerCount; s++) {
          if (lives[s] == 0) view._out.add(s);
        }
      }
      view._ended = j['ended'] == true;
      view._othersResigned = j['othersResigned'] == true;
      view._phase = MaexchenPhase.values.byName(j['phase'] as String);
      view._seat = view._checkSeat(j['seat']);
      view._round = j['round'] as int;
      if (j['announced'] != null) {
        if (!MaexchenGame.isValue(j['announced'])) throw BadViewException('bad value ${j['announced']}');
        view._announced = j['announced'] as int;
        view._announcer = view._checkSeat(j['announcer']);
      }
      if (j['roller'] != null) view._roller = view._checkSeat(j['roller']);
      final dice = j['dice'];
      if (dice != null) {
        final d = (dice as List).cast<int>();
        if (d.length != 2 || d.any((x) => x < 1 || x > 6)) throw BadViewException('bad dice $d');
        view._dice = d;
      }
      if (j['last'] != null) view._lastRound = MaexchenRoundEnd.fromJson(j['last']);
      if (j['winner'] != null) view._winnerSeat = view._checkSeat(j['winner']);
      final resigned = j['resigned'];
      if (resigned != null) view._restoreResign(resigned);
      return view;
    } on BadViewException {
      rethrow;
    } catch (e) {
      throw BadViewException('malformed Mäxchen view: $e');
    }
  }

  int _checkSeat(Object? s) {
    if (s is! int || s < 0 || s >= playerCount) throw BadViewException('bad seat $s');
    return s;
  }

  /// The viewer's legal moves on its turn; empty on the other's turn.
  @override
  List<Map<String, dynamic>> get legalMoves => currentPlayer == viewer ? super.legalMoves : const [];

  /// Read-only: the host applies every move, a resign included, and sends
  /// the next view.
  @override
  GameEvent? applyMove(Map<String, dynamic> move) => null;

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) => null;

  void _restoreResign(Object? name) => super.applyMove(Game.resignMove(playerIn(name)));

  @override
  Map<String, dynamic> viewJson(Player viewer) {
    if (viewer != this.viewer) throw ArgumentError.value(viewer, 'viewer', 'not the view of this player');
    return super.viewJson(viewer);
  }

  @override
  String toString() => 'MaexchenView(${viewer.name})';
}

/// Redaction for Mäxchen: moves carry no secrets (the dice come from the
/// secret seed), but the event of a `roll` holds the dice, which only the
/// roller may see; a doubt shows them to everyone.
class MaexchenRedaction extends Redaction {
  const MaexchenRedaction();

  @override
  bool get secretSeed => true;

  @override
  Map<String, dynamic> view(Game game, Player viewer) => (game as MaexchenGame).viewJson(viewer);

  @override
  Game fromView(Map<String, dynamic> view) => MaexchenView.fromJson(view);

  @override
  Object? redactPayload(Object? payload, Player mover, Player viewer) {
    if (mover != viewer && payload is Map && payload['rolled'] == true) return {'rolled': true};
    return super.redactPayload(payload, mover, viewer);
  }
}

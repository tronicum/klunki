part of 'schiffe.dart';

List<Object> _placementJson(ShipPlacement p) => [p.length, p.row, p.col, p.dir];

ShipPlacement _placementFrom(Object? j) {
  if (j is! List || j.length != 4 || j[0] is! int || j[1] is! int || j[2] is! int || (j[3] != 'h' && j[3] != 'v')) {
    throw BadViewException('bad ship $j');
  }
  return ShipPlacement(length: j[0] as int, row: j[1] as int, col: j[2] as int, horizontal: j[3] == 'h');
}

/// A Schiffe-versenken game as one player sees it (KLD-064): built from
/// [SchiffeGame.viewJson] on the remote side of a network game. It has the
/// viewer's own fleet and every shot with its result, but none of the
/// opponent's unhit ship cells: [targetGrid] of the viewer comes from the
/// reported results, [ownGrid] of the opponent shows only those results,
/// [placements] of the opponent is empty. Read-only: [applyMove] returns
/// null (the host applies moves and sends the next view).
class SchiffeView extends SchiffeGame {
  /// The player whose view this is.
  final Player viewer;
  final List<List<ShotMark>> _target;
  final int _oppPlaced;
  final int _oppRemaining;

  SchiffeView._(this.viewer, List<int> fleet, bool extraShotOnHit, this._target, this._oppPlaced, this._oppRemaining)
      : super(fleet: fleet, extraShotOnHit: extraShotOnHit);

  /// Rebuilds the view from [SchiffeGame.viewJson]; throws
  /// [BadViewException] if [j] is malformed.
  factory SchiffeView.fromJson(Map<String, dynamic> j) {
    try {
      final viewer = playerIn(j['viewer']);
      final fleet = (j['fleet'] as List).cast<int>();
      final target = j['target'] as String, incoming = j['incoming'] as String;
      const n = SchiffeGame.size * SchiffeGame.size;
      if (target.length != n || incoming.length != n) throw const BadViewException('bad grid size');
      final marks = List.generate(SchiffeGame.size, (r) => List.generate(SchiffeGame.size, (c) {
            final m = int.parse(target[r * SchiffeGame.size + c]);
            if (m >= ShotMark.values.length) throw BadViewException('bad mark $m');
            return ShotMark.values[m];
          }));
      final view = SchiffeView._(viewer, fleet, j['extraShotOnHit'] == true, marks, j['oppPlaced'] as int,
          j['oppRemaining'] as int);
      final own = view._sides[viewer]!;
      for (final s in j['own'] as List) {
        SchiffeGame._addShip(own, _placementFrom(s));
      }
      final opp = view._sides[SchiffeGame._other(viewer)]!;
      for (var r = 0; r < SchiffeGame.size; r++) {
        for (var c = 0; c < SchiffeGame.size; c++) {
          if (incoming[r * SchiffeGame.size + c] == '1') {
            own.shot[r][c] = true;
            final idx = own.shipAt[r][c];
            if (idx != null) own.ships[idx].hits++;
          }
          opp.shot[r][c] = marks[r][c] != ShotMark.unknown;
        }
      }
      view._phase = SchiffePhase.values.byName(j['phase'] as String);
      view._current = playerIn(j['current']);
      view._winner = playerOrNull(j['winner']);
      view._restoreResign(j['resigned']);
      return view;
    } on BadViewException {
      rethrow;
    } catch (e) {
      throw BadViewException('malformed Schiffe view: $e');
    }
  }

  Player get _opp => SchiffeGame._other(viewer);

  @override
  int? nextShipIndex(Player p) =>
      p == viewer ? super.nextShipIndex(p) : (_oppPlaced < fleet.length ? _oppPlaced : null);

  @override
  int shipsRemaining(Player p) => p == viewer ? super.shipsRemaining(p) : _oppRemaining;

  @override
  List<ShipPlacement> placements(Player p) => p == viewer ? super.placements(p) : const [];

  /// The opponent's grid as far as the viewer knows it: shot results only.
  @override
  List<List<SchiffeCell>> ownGrid(Player p) => p == viewer
      ? super.ownGrid(p)
      : [
          for (final row in _target)
            [
              for (final m in row)
                switch (m) {
                  ShotMark.unknown => SchiffeCell.empty,
                  ShotMark.miss => SchiffeCell.miss,
                  ShotMark.hit => SchiffeCell.hit,
                  ShotMark.sunk => SchiffeCell.sunk,
                }
            ]
        ];

  @override
  List<List<ShotMark>> targetGrid(Player p) =>
      p == viewer ? [for (final row in _target) List.of(row)] : super.targetGrid(p);

  /// The viewer's legal moves on its turn; empty on the opponent's turn
  /// (only the host knows those).
  @override
  List<Map<String, dynamic>> get legalMoves => _current == viewer ? super.legalMoves : const [];

  /// Read-only: the host applies every move, a resign included, and sends
  /// the next view (KLD-065: a resign arrives as `resigned` in the view).
  @override
  GameEvent? applyMove(Map<String, dynamic> move) => null;

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) => null;

  /// Restores the resignation reported in the host's view.
  void _restoreResign(Object? name) {
    if (name != null) super.applyMove(Game.resignMove(playerIn(name)));
  }

  @override
  Map<String, dynamic> viewJson(Player viewer) {
    if (viewer != this.viewer) throw ArgumentError.value(viewer, 'viewer', 'not the view of this player');
    return super.viewJson(viewer);
  }

  @override
  String toString() => 'SchiffeView(${viewer.name}, ${_opp.name} hidden)';
}

/// Redaction for Schiffe versenken: the opponent sees that a ship was placed
/// (index and length, both public by the fleet rules) but not where; shots
/// and their results are public.
class SchiffeRedaction extends Redaction {
  const SchiffeRedaction();

  @override
  Map<String, dynamic> view(Game game, Player viewer) => (game as SchiffeGame).viewJson(viewer);

  @override
  Game fromView(Map<String, dynamic> view) => SchiffeView.fromJson(view);

  @override
  Map<String, dynamic> redactMove(Map<String, dynamic> move, Player mover, Player viewer) {
    if (mover == viewer) return super.redactMove(move, mover, viewer);
    return switch (move['action']) {
      'place' => {'action': 'place', 'ship': move['ship']},
      'autoplace' => {'action': 'autoplace'},
      _ => super.redactMove(move, mover, viewer),
    };
  }
}

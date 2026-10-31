part of 'gostrategy.dart';

Object? _cellJson(GoCell c) => c.isEmpty
    ? null
    : {
        'o': c.owner!.name,
        if (c.piece != null) 'p': c.piece!.id,
        if (c.revealed) 'r': true,
        if (c.moved) 'm': true,
      };

/// A GoStrategy game as one player sees it (KLD-064): built from
/// [GoStrategyGame.viewJson] on the remote side of a network game. Own
/// pieces are known; enemy pieces only by owner (plus kind once revealed).
/// [board] and [viewFor] both return what the viewer knows. Read-only:
/// [applyMove] returns null; [legalMoves] and [targetsFrom] answer only on
/// the viewer's turn.
class GoStrategyView extends GoStrategyGame {
  /// The player whose view this is.
  final Player viewer;
  final List<GoCell> _cells;
  final Map<Player, Map<GoPiece, int>> _remaining;

  GoStrategyView._(this.viewer, this._cells, this._remaining, int noCaptureLimit)
      : super(noCaptureLimit: noCaptureLimit);

  /// Rebuilds the view from [GoStrategyGame.viewJson]; throws
  /// [BadViewException] if [j] is malformed.
  factory GoStrategyView.fromJson(Map<String, dynamic> j) {
    try {
      final viewer = playerIn(j['viewer']);
      final raw = j['cells'] as List;
      if (raw.length != GoStrategyGame.squareCount) throw const BadViewException('need 100 cells');
      final cells = <GoCell>[];
      for (var sq = 0; sq < raw.length; sq++) {
        final c = raw[sq];
        if (GoStrategyGame.isLake(sq)) {
          if (c != null) throw BadViewException('piece on lake $sq');
          cells.add(const GoCell(lake: true));
        } else if (c == null) {
          cells.add(const GoCell());
        } else {
          final m = c as Map;
          final owner = playerIn(m['o']);
          final piece = m['p'] == null ? null : GoPiece.fromId(m['p']) ?? (throw BadViewException('bad piece ${m['p']}'));
          if (owner == viewer && piece == null) throw BadViewException('own piece without kind on $sq');
          cells.add(GoCell(owner: owner, piece: piece, revealed: m['r'] == true, moved: m['m'] == true));
        }
      }
      final rem = j['remaining'] as Map;
      final remaining = {
        for (final p in Player.values)
          p: {
            for (final k in GoPiece.values) k: ((rem[p.name] as Map)[k.id] as int?) ?? 0,
          },
      };
      final v = GoStrategyView._(viewer, cells, remaining, j['noCaptureLimit'] as int);
      for (var sq = 0; sq < cells.length; sq++) {
        final c = cells[sq];
        if (c.owner == null) continue;
        // Enemy pieces of unknown kind get a placeholder kind; [_cell] and
        // [remaining] answer from the view, so it is never shown.
        v._board[sq] = _Unit(c.piece ?? GoPiece.flag, c.owner!)
          ..revealed = c.revealed
          ..moved = c.moved;
      }
      v._phase = GoStrategyPhase.values.byName(j['phase'] as String);
      v._current = playerIn(j['current']);
      final setup = j['setup'] as Map, last = j['lastMove'] as Map, streak = j['streak'] as Map;
      for (final p in Player.values) {
        v._setupDone[p] = setup[p.name] == true;
        final l = last[p.name];
        v._lastMove[p] = l == null ? null : ((l as List)[0] as int, l[1] as int);
        v._streak[p] = streak[p.name] as int;
      }
      v._movesSinceCapture = j['sinceCapture'] as int;
      final fight = j['lastFight'];
      v._lastFight = fight == null ? null : Map<String, dynamic>.from(fight as Map);
      final r = resultFromJson(j['result']);
      v
        .._winner = r.winner
        .._draw = r.draw
        .._reason = r.reason
        .._code = r.code
        .._params = r.params;
      return v;
    } on BadViewException {
      rethrow;
    } catch (e) {
      throw BadViewException('malformed GoStrategy view: $e');
    }
  }

  /// What the viewer knows about [sq], whoever asks.
  @override
  GoCell _cell(int sq, Player? viewer) => _cells[sq];

  @override
  Map<GoPiece, int> remaining(Player p) => Map.of(_remaining[p]!);

  @override
  List<int> targetsFrom(int from) => _current == viewer ? super.targetsFrom(from) : const [];

  @override
  List<Map<String, dynamic>> get legalMoves => _current == viewer ? super.legalMoves : const [];

  @override
  GameEvent? applyMove(Map<String, dynamic> move) => null;

  @override
  Map<String, dynamic> viewJson(Player viewer) {
    if (viewer != this.viewer) throw ArgumentError.value(viewer, 'viewer', 'not the view of this player');
    return super.viewJson(viewer);
  }

  @override
  String toString() => 'GoStrategyView(${viewer.name})';
}

/// Redaction for GoStrategy: the opponent learns that a setup was made, not
/// which (neither the pieces nor the autosetup seed). Moves and fights are
/// public (a fight reveals both pieces).
class GoStrategyRedaction extends Redaction {
  const GoStrategyRedaction();

  @override
  Map<String, dynamic> view(Game game, Player viewer) => (game as GoStrategyGame).viewJson(viewer);

  @override
  Game fromView(Map<String, dynamic> view) => GoStrategyView.fromJson(view);

  @override
  Map<String, dynamic> redactMove(Map<String, dynamic> move, Player mover, Player viewer) {
    if (mover == viewer) return super.redactMove(move, mover, viewer);
    return switch (move['action']) {
      'setup' || 'autosetup' => {'action': 'setup'},
      _ => super.redactMove(move, mover, viewer),
    };
  }
}

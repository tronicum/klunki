import 'dart:math';

import 'game.dart';

/// Phase of a Schiffe-versenken game. Game over is reported via
/// [SchiffeGame.isOver]; the phase stays [battle] after the last shot.
enum SchiffePhase { setup, battle }

/// A cell of a player's *own* grid (ships + incoming shots).
enum SchiffeCell { empty, ship, miss, hit, sunk }

/// A cell of a player's *target* grid: only what that player knows about the
/// opponent's ocean.
enum ShotMark { unknown, miss, hit, sunk }

/// A ship position: top-left cell plus direction.
class ShipPlacement {
  final int length;
  final int row;
  final int col;

  /// `true` = horizontal (extends to increasing col), `false` = vertical
  /// (extends to increasing row).
  final bool horizontal;

  const ShipPlacement({
    required this.length,
    required this.row,
    required this.col,
    required this.horizontal,
  });

  String get dir => horizontal ? 'h' : 'v';

  /// All cells as `[row, col]` pairs.
  List<List<int>> get cells => List.generate(
      length, (i) => horizontal ? [row, col + i] : [row + i, col]);

  /// The equivalent `place` move for ship [index].
  Map<String, dynamic> toMove(int index) =>
      {'action': 'place', 'ship': index, 'row': row, 'col': col, 'dir': dir};

  @override
  String toString() => 'ShipPlacement($length @ $row,$col $dir)';
}

class _Ship {
  final ShipPlacement placement;
  int hits = 0;
  _Ship(this.placement);
  bool get sunk => hits >= placement.length;
}

class _Side {
  final List<_Ship> ships = [];

  /// Index into [ships] per cell, or null for water.
  final List<List<int?>> shipAt =
      List.generate(SchiffeGame.size, (_) => List.filled(SchiffeGame.size, null));

  /// Incoming shots.
  final List<List<bool>> shot =
      List.generate(SchiffeGame.size, (_) => List.filled(SchiffeGame.size, false));

  int get remaining => ships.where((s) => !s.sunk).length;
}

/// Schiffe versenken, classic German rules.
///
/// * 10×10 grid per player, rows/cols 0–9.
/// * Ships are straight, fully on the board, must not overlap and must not
///   touch each other — not even diagonally.
/// * Setup: A places the whole fleet (in fleet order), then B.
/// * Battle: A fires first. A hit (or sink) grants another shot when
///   [extraShotOnHit] is true (default); a miss passes the turn.
/// * Whoever sinks all opposing ships wins.
class SchiffeGame extends Game {
  static const int size = 10;

  /// 1×5, 1×4, 2×3, 2×2 = 6 ships, 19 cells.
  static const List<int> defaultFleet = [5, 4, 3, 3, 2, 2];

  /// German ship names by length.
  static const Map<int, String> shipNames = {
    5: 'Schlachtschiff',
    4: 'Kreuzer',
    3: 'Zerstörer',
    2: 'U-Boot',
  };

  static String shipName(int length) => shipNames[length] ?? 'Schiff';

  final List<int> fleet;
  final bool extraShotOnHit;

  final Map<Player, _Side> _sides = {Player.a: _Side(), Player.b: _Side()};
  SchiffePhase _phase = SchiffePhase.setup;
  Player _current = Player.a;
  Player? _winner;
  final List<Map<String, dynamic>> _history = [];

  SchiffeGame({List<int> fleet = defaultFleet, this.extraShotOnHit = true})
      : fleet = List.unmodifiable(fleet) {
    if (fleet.isEmpty || fleet.any((l) => l < 1 || l > size)) {
      throw ArgumentError.value(fleet, 'fleet', 'lengths must be 1..$size');
    }
  }

  SchiffePhase get phase => _phase;

  @override
  Player get currentPlayer => _current;

  @override
  GameResult get result =>
      GameResult(
          winner: _winner,
          reason: _winner != null ? 'all ships sunk' : '',
          code: _winner != null ? GameEndReason.schiffeAllSunk : null);

  @override
  bool get isOver => _winner != null;

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  /// Index of the next ship [p] must place, or null when the fleet is placed.
  int? nextShipIndex(Player p) {
    final n = _sides[p]!.ships.length;
    return n < fleet.length ? n : null;
  }

  /// Number of [p]'s ships that are not yet sunk (placed ships only).
  int shipsRemaining(Player p) => _sides[p]!.remaining;

  /// Placements of [p]'s ships so far (own view — never show the opponent's).
  List<ShipPlacement> placements(Player p) =>
      List.unmodifiable(_sides[p]!.ships.map((s) => s.placement));

  /// [p]'s own grid: ships plus incoming shots. `grid[row][col]`.
  List<List<SchiffeCell>> ownGrid(Player p) {
    final side = _sides[p]!;
    return List.generate(size, (r) => List.generate(size, (c) {
          final idx = side.shipAt[r][c];
          final shot = side.shot[r][c];
          if (idx == null) return shot ? SchiffeCell.miss : SchiffeCell.empty;
          if (!shot) return SchiffeCell.ship;
          return side.ships[idx].sunk ? SchiffeCell.sunk : SchiffeCell.hit;
        }));
  }

  /// What [p] knows about the opponent's grid. `grid[row][col]`. Never
  /// reveals unhit ship cells.
  List<List<ShotMark>> targetGrid(Player p) {
    final side = _sides[_other(p)]!;
    return List.generate(size, (r) => List.generate(size, (c) {
          if (!side.shot[r][c]) return ShotMark.unknown;
          final idx = side.shipAt[r][c];
          if (idx == null) return ShotMark.miss;
          return side.ships[idx].sunk ? ShotMark.sunk : ShotMark.hit;
        }));
  }

  // ---------------------------------------------------------------- moves

  /// Legal moves for [currentPlayer]. Setup: every valid placement of the
  /// next ship (autoplace is a convenience and not listed). Battle: every
  /// unshot cell of the opponent. Empty when the game is over.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    if (_phase == SchiffePhase.setup) {
      final idx = nextShipIndex(_current);
      if (idx == null) return const [];
      final occupied = _occupiedOf(_sides[_current]!);
      final out = <Map<String, dynamic>>[];
      for (final h in [true, false]) {
        for (var r = 0; r < size; r++) {
          for (var c = 0; c < size; c++) {
            final p = ShipPlacement(
                length: fleet[idx], row: r, col: c, horizontal: h);
            if (_fits(occupied, p)) out.add(p.toMove(idx));
          }
        }
      }
      return out;
    }
    final target = _sides[_other(_current)]!;
    return [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (!target.shot[r][c]) {'action': 'fire', 'row': r, 'col': c},
    ];
  }

  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (isOver) return null;
    switch (move['action']) {
      case 'place':
        return _place(move);
      case 'autoplace':
        return _autoplace(move);
      case 'fire':
        return _fire(move);
      default:
        return null;
    }
  }

  GameEvent? _place(Map<String, dynamic> move) {
    if (_phase != SchiffePhase.setup) return null;
    final ship = move['ship'], row = move['row'], col = move['col'];
    final dir = move['dir'];
    if (ship is! int || row is! int || col is! int) return null;
    if (dir != 'h' && dir != 'v') return null;
    final side = _sides[_current]!;
    if (ship != nextShipIndex(_current)) return null;
    final p = ShipPlacement(
        length: fleet[ship], row: row, col: col, horizontal: dir == 'h');
    if (!_fits(_occupiedOf(side), p)) return null;

    final player = _current;
    _addShip(side, p);
    _history.add({...move, 'player': player});
    _afterPlacement(player);
    return GameEvent(payload: {'placed': ship, 'length': p.length});
  }

  GameEvent? _autoplace(Map<String, dynamic> move) {
    if (_phase != SchiffePhase.setup) return null;
    final seed = move['seed'];
    if (seed is! int) return null;
    final side = _sides[_current]!;
    final start = side.ships.length;
    final layout = _generate(
        fleet.sublist(start), Random(seed), _occupiedOf(side));
    if (layout == null) return null; // existing ships leave no room
    final player = _current;
    for (final p in layout) {
      _addShip(side, p);
    }
    _history.add({...move, 'player': player});
    _afterPlacement(player);
    return GameEvent(payload: {
      'autoplaced': [for (var i = start; i < fleet.length; i++) i],
    });
  }

  void _afterPlacement(Player player) {
    if (nextShipIndex(player) != null) return;
    if (player == Player.a) {
      _current = Player.b;
    } else {
      _phase = SchiffePhase.battle;
      _current = Player.a;
    }
  }

  GameEvent? _fire(Map<String, dynamic> move) {
    if (_phase != SchiffePhase.battle) return null;
    final row = move['row'], col = move['col'];
    if (row is! int || col is! int) return null;
    if (!_inBounds(row, col)) return null;
    final target = _sides[_other(_current)]!;
    if (target.shot[row][col]) return null;

    final player = _current;
    target.shot[row][col] = true;
    _history.add({'action': 'fire', 'row': row, 'col': col, 'player': player});

    final idx = target.shipAt[row][col];
    if (idx == null) {
      _current = _other(player);
      return GameEvent(payload: {'row': row, 'col': col, 'result': 'miss'});
    }
    final ship = target.ships[idx];
    ship.hits++;
    final payload = <String, dynamic>{
      'row': row,
      'col': col,
      'result': ship.sunk ? 'sunk' : 'hit',
      'ship': ship.placement.length,
    };
    if (target.remaining == 0) {
      _winner = player;
      return GameEvent(winner: player, payload: payload);
    }
    if (!extraShotOnHit) _current = _other(player);
    return GameEvent(payload: payload);
  }

  // -------------------------------------------------------------- helpers

  static bool _inBounds(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;

  static void _addShip(_Side side, ShipPlacement p) {
    final idx = side.ships.length;
    side.ships.add(_Ship(p));
    for (final cell in p.cells) {
      side.shipAt[cell[0]][cell[1]] = idx;
    }
  }

  static List<List<bool>> _occupiedOf(_Side side) => List.generate(
      size, (r) => List.generate(size, (c) => side.shipAt[r][c] != null));

  /// True if [p] lies on the board and neither overlaps nor touches
  /// (8-neighbourhood) any occupied cell.
  static bool _fits(List<List<bool>> occupied, ShipPlacement p) {
    for (final cell in p.cells) {
      if (!_inBounds(cell[0], cell[1])) return false;
    }
    for (final cell in p.cells) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          final r = cell[0] + dr, c = cell[1] + dc;
          if (_inBounds(r, c) && occupied[r][c]) return false;
        }
      }
    }
    return true;
  }

  static void _mark(List<List<bool>> occupied, ShipPlacement p, bool v) {
    for (final cell in p.cells) {
      occupied[cell[0]][cell[1]] = v;
    }
  }

  /// A valid random layout (no overlap, no touching) of [fleet] on an empty
  /// board, deterministic for [seed]. Index i of the result is ship i.
  static List<ShipPlacement> randomLayout(int seed,
      {List<int> fleet = defaultFleet}) {
    final empty = List.generate(size, (_) => List.filled(size, false));
    final layout = _generate(fleet, Random(seed), empty);
    if (layout == null) {
      throw ArgumentError.value(fleet, 'fleet', 'does not fit on the board');
    }
    return layout;
  }

  /// Places [lengths] in order around [occupied] (not modified). Fast random
  /// restarts first, then an exhaustive randomized backtracking search, so it
  /// succeeds whenever any valid layout exists. Deterministic for [rng].
  static List<ShipPlacement>? _generate(
      List<int> lengths, Random rng, List<List<bool>> occupied) {
    for (var attempt = 0; attempt < 200; attempt++) {
      final occ = [for (final row in occupied) [...row]];
      final out = <ShipPlacement>[];
      var ok = true;
      for (final len in lengths) {
        ShipPlacement? found;
        for (var tries = 0; tries < 100 && found == null; tries++) {
          final p = ShipPlacement(
              length: len,
              row: rng.nextInt(size),
              col: rng.nextInt(size),
              horizontal: rng.nextBool());
          if (_fits(occ, p)) found = p;
        }
        if (found == null) {
          ok = false;
          break;
        }
        _mark(occ, found, true);
        out.add(found);
      }
      if (ok) return out;
    }
    final occ = [for (final row in occupied) [...row]];
    final out = <ShipPlacement>[];
    bool search(int i) {
      if (i == lengths.length) return true;
      final candidates = <ShipPlacement>[
        for (final h in [true, false])
          for (var r = 0; r < size; r++)
            for (var c = 0; c < size; c++)
              ShipPlacement(length: lengths[i], row: r, col: c, horizontal: h),
      ]..shuffle(rng);
      for (final p in candidates) {
        if (!_fits(occ, p)) continue;
        _mark(occ, p, true);
        out.add(p);
        if (search(i + 1)) return true;
        out.removeLast();
        _mark(occ, p, false);
      }
      return false;
    }

    return search(0) ? out : null;
  }
}

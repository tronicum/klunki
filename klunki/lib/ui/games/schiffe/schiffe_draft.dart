import 'package:klunki_engine/klunki_engine.dart' hide Card;

/// The local, editable fleet layout of one player during the Schiffe setup
/// (KLD-068). Nothing here is sent anywhere: the board submits the `place`
/// moves only when the player taps "Fertig" ([moves]).
///
/// Slot i holds ship i of [fleet] (null = still in the harbour). The first
/// [locked] slots are ships the engine already accepted (e.g. after a
/// hot-seat undo); they stay where they are.
class SchiffeDraft {
  final List<int> fleet;
  final List<ShipPlacement?> _slots;
  final int locked;

  SchiffeDraft(this.fleet, List<ShipPlacement> committed)
      : locked = committed.length,
        _slots = [...committed, for (var i = committed.length; i < fleet.length; i++) null];

  List<ShipPlacement?> get slots => List.unmodifiable(_slots);
  ShipPlacement? operator [](int i) => _slots[i];

  bool isLocked(int i) => i < locked;
  bool isPlaced(int i) => _slots[i] != null;

  /// All ships are on the board (and therefore valid: every edit is checked).
  bool get complete => _slots.every((s) => s != null);

  int get placedCount => _slots.where((s) => s != null).length;

  /// Index of the first ship still in the harbour, or null.
  int? get firstUnplaced {
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i] == null) return i;
    }
    return null;
  }

  /// Index of the ship covering cell ([r], [c]), or null.
  int? shipAt(int r, int c) {
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i]?.indexOf(r, c) != null) return i;
    }
    return null;
  }

  Iterable<ShipPlacement> _others(int except) sync* {
    for (var i = 0; i < _slots.length; i++) {
      final s = _slots[i];
      if (i != except && s != null) yield s;
    }
  }

  /// Whether ship [i] may stand at [p] (ignoring its own current position).
  bool canPlace(int i, ShipPlacement p) =>
      !isLocked(i) && p.length == fleet[i] && SchiffeGame.fitsAmong(p, _others(i));

  /// Puts (or moves) ship [i] to [p]; false (and no change) if invalid.
  bool place(int i, ShipPlacement p) {
    if (!canPlace(i, p)) return false;
    _slots[i] = p;
    return true;
  }

  /// The cell a turn of a ship of [length] goes around first: its middle
  /// (KLD-107: every turn is "in place").
  static int middle(int length) => length ~/ 2;

  /// Turns placed ship [i] by 90°: around cell [pivot] (default: its
  /// [middle]) first, then around every other cell of the ship (first cell
  /// first), taking the first valid result. False (and no change) if no
  /// turn fits.
  bool rotate(int i, {int? pivot}) {
    final s = _slots[i];
    if (s == null || isLocked(i)) return false;
    final first = pivot ?? middle(s.length);
    final pivots = [first, for (var k = 0; k < s.length; k++) if (k != first) k];
    for (final k in pivots) {
      if (place(i, s.rotated(pivot: k))) return true;
    }
    return false;
  }

  /// Ship [i] back to the harbour.
  void remove(int i) {
    if (!isLocked(i)) _slots[i] = null;
  }

  /// Every unlocked ship back to the harbour.
  void reset() {
    for (var i = locked; i < _slots.length; i++) {
      _slots[i] = null;
    }
  }

  /// Places every unlocked ship at random (all of them, also ones already
  /// on the board), deterministic for [seed]. False if no layout fits.
  bool randomize(int seed) {
    final out = SchiffeGame.completeLayout([..._slots.take(locked), for (var i = locked; i < fleet.length; i++) null], seed,
        fleet: fleet);
    if (out == null) return false;
    _slots.setAll(0, out);
    return true;
  }

  /// The `place` moves for the ships the engine does not have yet, in fleet
  /// order (the engine expects that order); empty unless [complete].
  List<Map<String, dynamic>> moves() =>
      complete ? [for (var i = locked; i < fleet.length; i++) _slots[i]!.toMove(i)] : const [];
}

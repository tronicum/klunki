import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time tips already shown on this device (KLD-107), e.g. the Schiffe
/// "tap it: move or turn" bubble. Per install, not per player. Persisted as
/// a string list under [prefsKey]; without storage it lasts for the session.
class SeenTips {
  SeenTips._();

  static const String prefsKey = 'seenTips';

  /// The Schiffe setup tip after the first placed ship.
  static const String schiffeMove = 'schiffeMove';

  static SeenTips? _shared;

  /// The app's instance (loads the stored list in the background).
  static SeenTips get shared => _shared ??= (SeenTips._().._load());

  final Set<String> _seen = {};
  SharedPreferences? _prefs;

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final stored = p.getStringList(prefsKey) ?? const [];
      final marked = _seen.difference(stored.toSet()).isNotEmpty;
      _seen.addAll(stored);
      if (marked) await _save(); // tips marked before storage was ready
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  Future<void> _save() async => _prefs?.setStringList(prefsKey, _seen.toList()..sort());

  bool has(String tip) => _seen.contains(tip);

  /// Marks [tip] as shown; true if it was not shown before (show it now).
  bool markFirst(String tip) {
    if (!_seen.add(tip)) return false;
    _save();
    return true;
  }

  /// Tests: a fresh install (memory only, nothing seen), or with [loaded]
  /// a fresh start that reads the stored list again.
  @visibleForTesting
  static void debugReset({bool loaded = false}) {
    _shared = loaded ? (SeenTips._().._load()) : SeenTips._();
  }
}

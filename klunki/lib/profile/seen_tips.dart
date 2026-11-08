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

  /// The Wortgewandt "Bänkchen" explanation the first time it is opened
  /// (KLD-094 step 8).
  static const String wordtilesBench = 'wordtilesBench';

  /// The Mau-Mau "how to play" tour the first time a hand is shown
  /// (KLD-118).
  static const String maumauIntro = 'maumauIntro';

  /// The Ausgewürfelt "how to play" tour before the first roll of a game
  /// (KLD-119).
  static const String dicesheetIntro = 'dicesheetIntro';

  /// The web on iOS: the card that explains the browser's motion prompt
  /// before shaking to roll is allowed (KLD-123), answered once.
  static const String shakeConsent = 'shakeConsent';

  /// The rules page of [gameId] was opened (KLD-123): no more "Neu hier?"
  /// line in that game.
  static String rulesOpened(String gameId) => 'rules:$gameId';

  /// Games of [gameId] started on this device ([count], KLD-123).
  static String gamesStarted(String gameId) => 'games:$gameId';

  /// Prefs key of the counters ([countUp]), "key=n" strings.
  static const String countsKey = 'tipCounts';

  static SeenTips? _shared;

  /// The app's instance (loads the stored list in the background).
  static SeenTips get shared => _shared ??= (SeenTips._().._load());

  final Set<String> _seen = {};
  final Map<String, int> _counts = {};
  SharedPreferences? _prefs;

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final stored = p.getStringList(prefsKey) ?? const [];
      final marked = _seen.difference(stored.toSet()).isNotEmpty;
      _seen.addAll(stored);
      if (marked) await _save(); // tips marked before storage was ready
      final counted = _counts.isNotEmpty;
      for (final e in p.getStringList(countsKey) ?? const <String>[]) {
        final i = e.lastIndexOf('=');
        final n = i < 0 ? null : int.tryParse(e.substring(i + 1));
        if (n != null) _counts.update(e.substring(0, i), (v) => v + n, ifAbsent: () => n);
      }
      if (counted) await _saveCounts(); // counted before storage was ready
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  Future<void> _save() async => _prefs?.setStringList(prefsKey, _seen.toList()..sort());

  Future<void> _saveCounts() async =>
      _prefs?.setStringList(countsKey, [for (final e in _counts.entries) '${e.key}=${e.value}']..sort());

  /// How often [key] was counted ([countUp]).
  int count(String key) => _counts[key] ?? 0;

  /// Counts [key] once more; returns the new count.
  int countUp(String key) {
    final n = _counts.update(key, (v) => v + 1, ifAbsent: () => 1);
    _saveCounts();
    return n;
  }

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

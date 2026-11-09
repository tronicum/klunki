import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Zug zurücknehmen erlauben" (KLD-117 follow-up): whether the hot-seat
/// undo button ([UndoMoveButton]) is offered in a game. One device setting
/// per game id, for both players, on by default; chosen in "Wer spielt?"
/// (Ausgewürfelt: in its start options).
///
/// Undo exists only on one device (a [HotSeatTransport]); a network game
/// has none, so the setting needs no config key, no rules version and no
/// protocol change. Persisted as `undoAllowed.<gameId>` (only when off or
/// chosen); without storage it lasts for the session.
class UndoSettings extends ChangeNotifier {
  UndoSettings._();

  /// In-memory (no persistence): tests. [off]: the games with undo off.
  UndoSettings.memory({Set<String> off = const {}}) {
    for (final id in off) {
      _allowed[id] = false;
    }
  }

  static const bool defaultAllowed = true;
  static const String prefsPrefix = 'undoAllowed.';

  SharedPreferences? _prefs;
  final Map<String, bool> _allowed = {};

  /// Chosen before storage was loaded: these win over the stored values.
  final Set<String> _chosen = {};

  static UndoSettings? _shared;

  /// The app's instance: the default first, the stored values as soon as
  /// they are loaded.
  static UndoSettings shared() => _shared ??= (UndoSettings._().._load());

  /// Tests: a fresh install (memory only), or with [loaded] a fresh start
  /// that reads the stored values again.
  @visibleForTesting
  static void debugReset({bool loaded = false}) => _shared = loaded ? (UndoSettings._().._load()) : UndoSettings.memory();

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      var changed = false;
      for (final key in p.getKeys()) {
        if (!key.startsWith(prefsPrefix)) continue;
        final id = key.substring(prefsPrefix.length);
        final v = p.getBool(key);
        if (v == null || _chosen.contains(id) || allowed(id) == v) continue;
        _allowed[id] = v;
        changed = true;
      }
      for (final id in _chosen) {
        await p.setBool('$prefsPrefix$id', allowed(id));
      }
      if (changed) notifyListeners();
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// Whether "Zug zurücknehmen" is offered in [gameId].
  bool allowed(String gameId) => _allowed[gameId] ?? defaultAllowed;

  Future<void> setAllowed(String gameId, bool on) async {
    _chosen.add(gameId);
    if (allowed(gameId) == on) return;
    _allowed[gameId] = on;
    notifyListeners();
    await _prefs?.setBool('$prefsPrefix$gameId', on);
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// "Schütteln zum Würfeln" (KLD-121 follow-up): shaking the phone rolls the
/// dice, besides the "Würfeln" button. On by default; one setting for every
/// dice game (Mäxchen now, the five-dice game next). Persisted under
/// [prefsKey]; without storage it lasts for the session.
class ShakeSettings extends ChangeNotifier {
  ShakeSettings._();

  /// In-memory (no persistence), with the default: tests.
  ShakeSettings.memory();

  static const bool defaultEnabled = true;
  static const String prefsKey = 'shakeToRoll';

  SharedPreferences? _prefs;
  bool _enabled = defaultEnabled;
  bool _chosen = false;

  static ShakeSettings? _shared;

  /// The app's instance: the default first, the stored value as soon as it
  /// is loaded.
  static ShakeSettings shared() => _shared ??= (ShakeSettings._().._load());

  /// Tests: a fresh install (memory only), or with [loaded] a fresh start
  /// that reads the stored value again.
  @visibleForTesting
  static void debugReset({bool loaded = false}) => _shared = loaded ? (ShakeSettings._().._load()) : ShakeSettings.memory();

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final v = p.getBool(prefsKey);
      if (v != null && !_chosen && v != _enabled) {
        _enabled = v;
        notifyListeners();
      }
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  bool get enabled => _enabled;

  Future<void> setEnabled(bool on) async {
    _chosen = true;
    if (_enabled == on) return;
    _enabled = on;
    notifyListeners();
    await _prefs?.setBool(prefsKey, on);
  }
}

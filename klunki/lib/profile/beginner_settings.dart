import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The "Anfängermodus" of Ausgewürfelt (KLD-119): tips which box to fill
/// and which dice to keep ([DiceSheetAdvisor]). One device setting, on by
/// default until a player turns it off ("Anfängermodus beenden" in the tip,
/// or the switch in the start options). Persisted under [prefsKey]; without
/// storage it lasts for the session.
class BeginnerSettings extends ChangeNotifier {
  BeginnerSettings._();

  /// In-memory (no persistence), with the default: tests.
  BeginnerSettings.memory();

  static const bool defaultEnabled = true;
  static const String prefsKey = 'dicesheetBeginner';

  SharedPreferences? _prefs;
  bool _enabled = defaultEnabled;
  bool _chosen = false;

  static BeginnerSettings? _shared;

  /// The app's instance: the default first, the stored value as soon as it
  /// is loaded.
  static BeginnerSettings shared() => _shared ??= (BeginnerSettings._().._load());

  /// Tests: a fresh install (memory only), or with [loaded] a fresh start
  /// that reads the stored value again.
  @visibleForTesting
  static void debugReset({bool loaded = false}) => _shared = loaded ? (BeginnerSettings._().._load()) : BeginnerSettings.memory();

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

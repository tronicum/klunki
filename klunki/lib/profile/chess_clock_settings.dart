import 'package:flutter/foundation.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The chess clock last chosen on this device (KLD-126): "Wer spielt?" and
/// "Raum starten" start with it. Default: no clock ("Ohne Uhr"). Persisted
/// as `chessClock` (the [ChessTimeControl.id], `"none"` for no clock);
/// without storage it lasts for the session.
class ChessClockSettings extends ChangeNotifier {
  ChessClockSettings._();

  /// In-memory (no persistence): tests.
  ChessClockSettings.memory([this._control]) : _chosen = true;

  static const String prefsKey = 'chessClock';

  SharedPreferences? _prefs;
  ChessTimeControl? _control;
  bool _chosen = false;

  static ChessClockSettings? _shared;

  /// The app's instance.
  static ChessClockSettings shared() => _shared ??= (ChessClockSettings._().._load());

  /// Tests: a fresh install (memory only).
  @visibleForTesting
  static void debugReset() => _shared = ChessClockSettings.memory();

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      if (_chosen) {
        await p.setString(prefsKey, _control?.id ?? 'none');
        return;
      }
      final stored = ChessTimeControl.tryParse(p.getString(prefsKey));
      if (stored != _control) {
        _control = stored;
        notifyListeners();
      }
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// The time control to start with; null = no clock.
  ChessTimeControl? get control => _control;

  Future<void> setControl(ChessTimeControl? control) async {
    _chosen = true;
    if (control == _control) return;
    _control = control;
    notifyListeners();
    await _prefs?.setString(prefsKey, control?.id ?? 'none');
  }
}

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the app opens a room (KLD-098): [value] true = through the relay
/// (room code, browsers can join), false (the default) = directly on this
/// device (TCP + mDNS, QR code, no server needed). Chosen once under
/// "Erweitert" on "Raum starten" and remembered under [prefsKey]. The PWA
/// has no choice (a page can only open rooms through the relay).
class RoomSettings extends ValueNotifier<bool> {
  RoomSettings._(this._prefs, super.value);

  /// In-memory (no persistence): tests and the fallback without storage.
  RoomSettings.memory([super.value = false]) : _prefs = null;

  static const String prefsKey = 'roomViaRelay';

  SharedPreferences? _prefs;

  static RoomSettings? _shared;

  /// The app's instance: starts with the default and fills in from storage
  /// as soon as it is loaded.
  static RoomSettings shared() => _shared ??= (RoomSettings._(null, false).._load());

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final saved = p.getBool(prefsKey);
      if (saved != null) value = saved;
    } catch (_) {
      // No storage: stay in memory.
    }
  }

  /// Rooms through the relay ([viaRelay] true) or on this device (and save it).
  Future<void> set(bool viaRelay) async {
    value = viaRelay;
    await _prefs?.setBool(prefsKey, viaRelay);
  }
}

import 'package:flutter/foundation.dart';
import 'package:klunki_net/guest_web.dart' show parseRelayUrl;
import 'package:shared_preferences/shared_preferences.dart';

/// The one relay address for hosting and joining by room code (KLD-057b,
/// KLD-052): "Spiel hosten", "Mit Raumcode beitreten" and a scanned room
/// link all read and change this one setting.
///
/// [value] is the address the player chose (null: none). Which relay is used
/// is [relayFor]: the chosen one, else the screen's default (in the PWA the
/// page's own server; natively there is none). Persisted under [prefsKey].
class RelaySettings extends ValueNotifier<Uri?> {
  RelaySettings._(this._prefs, super.value);

  /// In-memory (no persistence): tests and the fallback without storage.
  RelaySettings.memory([super.value]) : _prefs = null;

  static const String prefsKey = 'relayAddress';

  SharedPreferences? _prefs;

  static RelaySettings? _shared;

  /// The app's instance: starts empty and fills in from storage as soon as
  /// it is loaded (a screen opened before that sees the change).
  static RelaySettings shared() => _shared ??= (RelaySettings._(null, null).._load());

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final saved = p.getString(prefsKey);
      // Something chosen meanwhile wins over the stored value.
      if (value == null && saved != null) value = parseRelayUrl(saved);
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// The relay to use: the chosen one, else [fallback].
  Uri? relayFor(Uri? fallback) => value ?? fallback;

  /// Chooses [relay] (and saves it).
  Future<void> set(Uri relay) async {
    value = relay;
    await _prefs?.setString(prefsKey, relay.toString());
  }

  /// Back to the default (the page's own server in the PWA).
  Future<void> reset() async {
    value = null;
    await _prefs?.remove(prefsKey);
  }
}

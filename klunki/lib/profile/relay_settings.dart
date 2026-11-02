import 'package:flutter/foundation.dart';
import 'package:klunki_net/guest_web.dart' show normalizeClubCode, parseRelayUrl;
import 'package:shared_preferences/shared_preferences.dart';

/// The one relay address for hosting and joining by room code (KLD-057b,
/// KLD-052): "Raum starten", the room-code join and a scanned room
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
      _loadClubCode(p);
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

  // ---- club code (KLD-112) -----------------------------------------------

  /// Storage keys of the club code and of the relay it belongs to.
  static const String clubCodeKey = 'relayClubCode';
  static const String clubRelayKey = 'relayClubCodeRelay';

  String? _clubCode;
  Uri? _clubRelay;

  /// The club code entered for [relay] (sent only to that relay, never to
  /// another one, e.g. a relay from a link), or null.
  String? clubCodeFor(Uri? relay) => relay != null && relay == _clubRelay ? _clubCode : null;

  /// Saves [code] for [relay]; empty or null clears it.
  Future<void> setClubCode(Uri relay, String? code) async {
    final t = code?.trim() ?? '';
    // Normalised when it looks like a code; else kept as typed (the relay
    // then answers "not accepted", which tells the player more than a
    // silently dropped code).
    final c = t.isEmpty ? null : normalizeClubCode(t) ?? t;
    _clubCode = c;
    _clubRelay = c == null ? null : relay;
    if (c == null) {
      await _prefs?.remove(clubCodeKey);
      await _prefs?.remove(clubRelayKey);
    } else {
      await _prefs?.setString(clubCodeKey, c);
      await _prefs?.setString(clubRelayKey, relay.toString());
    }
    notifyListeners();
  }

  void _loadClubCode(SharedPreferences p) {
    if (_clubCode != null) return; // entered meanwhile
    final code = p.getString(clubCodeKey), relay = p.getString(clubRelayKey);
    if (code == null || relay == null) return;
    _clubCode = code.trim().isEmpty ? null : normalizeClubCode(code) ?? code.trim();
    _clubRelay = _clubCode == null ? null : Uri.tryParse(relay);
  }
}

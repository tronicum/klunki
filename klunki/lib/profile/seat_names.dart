import 'package:flutter/foundation.dart';
import 'package:klunki_net/klunki_net.dart' show sanitizePlayerName;
import 'package:shared_preferences/shared_preferences.dart';

/// Hot-seat names of players 3 and 4 and the last player count (KLD-119,
/// games for 3–4 players on one device). Players 1 and 2 stay in the
/// two-player store (`HotSeatNamesController`), so a name typed for a
/// two-player game shows up here too and the other way round.
///
/// A null name means the regional default name (`playerDefaultNameC/D`),
/// which is never stored so it follows the app language. Persisted under
/// [prefsKeys] and [prefsKeyPlayers]; without storage it lasts for the
/// session.
class ExtraSeatNames extends ChangeNotifier {
  ExtraSeatNames._();

  /// In-memory (no persistence): tests.
  ExtraSeatNames.memory();

  /// Keys of the names of player 3 and 4.
  static const List<String> prefsKeys = ['hotSeatName3', 'hotSeatName4'];
  static const String prefsKeyPlayers = 'hotSeatPlayers';

  SharedPreferences? _prefs;
  List<String?> _names = const [null, null];
  int _players = 2;
  bool _changed = false;

  static ExtraSeatNames? _shared;

  /// The app's instance: empty first, the stored values as soon as they are
  /// loaded.
  static ExtraSeatNames shared() => _shared ??= (ExtraSeatNames._().._load());

  /// Tests: a fresh install (memory only).
  @visibleForTesting
  static void debugReset() => _shared = ExtraSeatNames.memory();

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      if (_changed) return;
      _names = [for (final k in prefsKeys) _orNull(p.getString(k))];
      _players = (p.getInt(prefsKeyPlayers) ?? 2).clamp(2, 4);
      notifyListeners();
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// The typed name of seat 2 or 3 (players 3 and 4), or null.
  String? nameOf(int seat) => seat >= 2 && seat < 4 ? _names[seat - 2] : null;

  /// The player count chosen last ("Wer spielt?" starts with it).
  int get players => _players;

  /// Cleans and saves the names of players 3 and 4 (an empty one is
  /// cleared) and the player count.
  Future<void> set({String? third, String? fourth, int? players}) async {
    _changed = true;
    _names = [_orNull(third), _orNull(fourth)];
    if (players != null) _players = players.clamp(2, 4);
    notifyListeners();
    final p = _prefs;
    if (p == null) return;
    for (var i = 0; i < 2; i++) {
      final v = _names[i];
      if (v == null) {
        await p.remove(prefsKeys[i]);
      } else {
        await p.setString(prefsKeys[i], v);
      }
    }
    await p.setInt(prefsKeyPlayers, _players);
  }

  static String? _orNull(String? raw) {
    final s = sanitizePlayerName(raw);
    return s.isEmpty ? null : s;
  }
}

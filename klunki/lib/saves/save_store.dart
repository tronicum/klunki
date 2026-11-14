import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_game.dart';

/// One stored save: the parsed [game], or null when the stored data can't be
/// read by this build (a newer format, damaged data); such an entry can only
/// be deleted.
class SaveEntry {
  final String gameId;
  final SavedGame? game;
  const SaveEntry(this.gameId, this.game);

  /// Whether "Weiterspielen" can rebuild it ([SavedGame.isOutdated]; a
  /// replay that fails is found when it is opened).
  bool get resumable => game != null && !game!.isOutdated;
}

/// The paused hot-seat games (KLD-079), in `shared_preferences` (web:
/// localStorage).
///
/// Slot model: **one save per game** (key [prefsPrefix] + game id), so at
/// most one per game in the menu (12 today). The running hot-seat game
/// writes its slot after every accepted move; a new game of the same kind
/// takes the slot over with its first move (opening a game and leaving it
/// without a move keeps the old save); a finished game deletes it.
///
/// Without storage (tests, blocked site data) the saves live in memory for
/// the session.
class SaveStore extends ChangeNotifier {
  SaveStore._(this._prefs, this._entries);

  /// In-memory store (no persistence), for tests.
  SaveStore.memory()
      : _prefs = null,
        _entries = {};

  static const String prefsPrefix = 'savedGame.';

  final SharedPreferences? _prefs;
  final Map<String, SaveEntry> _entries;

  /// Loads every stored save. Pass [prefs] to inject an instance; otherwise
  /// [SharedPreferences.getInstance] is used. Never throws: without storage
  /// the store is in memory.
  static Future<SaveStore> load({SharedPreferences? prefs}) async {
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      final entries = <String, SaveEntry>{};
      for (final key in p.getKeys()) {
        if (!key.startsWith(prefsPrefix)) continue;
        final id = key.substring(prefsPrefix.length);
        SavedGame? game;
        try {
          final raw = p.getString(key);
          game = raw == null ? null : SavedGame.tryParse(jsonDecode(raw));
          if (game != null && game.gameId != id) game = null;
        } catch (_) {
          game = null;
        }
        entries[id] = SaveEntry(id, game);
      }
      return SaveStore._(p, entries);
    } catch (_) {
      return SaveStore.memory();
    }
  }

  /// Every save, the most recent first (unreadable ones last).
  List<SaveEntry> get entries {
    final list = _entries.values.toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => (b.game?.savedAt ?? epoch).compareTo(a.game?.savedAt ?? epoch));
    return list;
  }

  bool get isEmpty => _entries.isEmpty;
  int get length => _entries.length;

  SaveEntry? entryFor(String gameId) => _entries[gameId];

  bool _notifyScheduled = false;

  /// Listeners hear of a change in a microtask: a game screen saves while
  /// it is being disposed, when the menu must not rebuild synchronously.
  void _changed() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  /// Stores [game] in its game's slot (replacing the one there).
  Future<void> save(SavedGame game) async {
    _entries[game.gameId] = SaveEntry(game.gameId, game);
    _changed();
    try {
      await _prefs?.setString('$prefsPrefix${game.gameId}', jsonEncode(game.toJson()));
    } catch (_) {
      // Storage full or blocked: the save stays in memory for the session.
    }
  }

  /// Deletes the save of [gameId] (nothing if there is none).
  Future<void> remove(String gameId) async {
    if (_entries.remove(gameId) == null) return;
    _changed();
    try {
      await _prefs?.remove('$prefsPrefix$gameId');
    } catch (_) {}
  }
}

/// Makes the app's [SaveStore] reachable below the app; without one (tests,
/// network sessions) nothing is saved and the menu has no "Weiterspielen".
class SavedGamesScope extends InheritedNotifier<SaveStore> {
  const SavedGamesScope({super.key, required SaveStore store, required super.child}) : super(notifier: store);

  /// The store, rebuilding [context] when the saves change.
  static SaveStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SavedGamesScope>()?.notifier;

  /// The store without a dependency (callbacks, `initState`).
  static SaveStore? read(BuildContext context) => context.getInheritedWidgetOfExactType<SavedGamesScope>()?.notifier;
}

import 'package:flutter/widgets.dart';
import 'package:klunki_net/klunki_net.dart' show sanitizePlayerName;
import 'package:shared_preferences/shared_preferences.dart';

import 'player_name_suggestion.dart';

export 'package:klunki_net/klunki_net.dart' show maxPlayerNameLength, sanitizePlayerName;

/// The user's player name (handle) for network games (KLD-056).
///
/// `null` = not chosen yet: a room screen then asks once ("Wie heißt
/// du?", prefilled with [suggestion]). Stored values are always cleaned by
/// [sanitizePlayerName] (1–20 characters, any script, no control or bidi
/// characters) and persisted under [prefsKey].
class PlayerNameController extends ValueNotifier<String?> {
  PlayerNameController._(this._prefs, String? value, this.suggestion) : super(value);

  /// In-memory controller (no persistence), for tests and as a fallback.
  /// [name] is cleaned; an empty result means "not chosen yet".
  PlayerNameController.memory({String? name, this.suggestion = defaultPlayerNameSuggestion})
      : _prefs = null,
        super(_orNull(name));

  static const String prefsKey = 'playerName';

  final SharedPreferences? _prefs;

  /// Default for the name field: the device name natively, "Browser" on the web.
  final String Function() suggestion;

  /// Loads the saved name. Pass [prefs] to inject an instance; otherwise
  /// [SharedPreferences.getInstance] is used.
  static Future<PlayerNameController> load({
    SharedPreferences? prefs,
    String Function() suggestion = defaultPlayerNameSuggestion,
  }) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return PlayerNameController._(p, _orNull(p.getString(prefsKey)), suggestion);
  }

  /// True once the user chose a name.
  bool get hasName => value != null;

  /// The cleaned [suggestion] ("Klunki" if even that is empty).
  String get suggested => _orNull(suggestion()) ?? 'Klunki';

  /// The name to use now: the chosen one, else [suggested].
  String get name => value ?? suggested;

  /// Cleans and saves [raw]. Returns false (and changes nothing) when nothing
  /// is left after cleaning.
  Future<bool> setName(String raw) async {
    final clean = _orNull(raw);
    if (clean == null) return false;
    value = clean;
    await _prefs?.setString(prefsKey, clean);
    return true;
  }

  static String? _orNull(String? raw) {
    final s = sanitizePlayerName(raw);
    return s.isEmpty ? null : s;
  }
}

/// Names the two hot-seat players typed, player A ([x], mark X) and player B
/// ([o], mark O); null = the regional default name ("Anna" / "Ben", KLD-103),
/// which is never stored so it follows the app language.
@immutable
class HotSeatNames {
  const HotSeatNames({this.x, this.o});

  static const HotSeatNames none = HotSeatNames();

  final String? x;
  final String? o;

  @override
  bool operator ==(Object other) => other is HotSeatNames && other.x == x && other.o == o;

  @override
  int get hashCode => Object.hash(x, o);

  @override
  String toString() => 'HotSeatNames($x, $o)';
}

/// The last-used hot-seat names (KLD-056). Starting a hot-seat game shows
/// them in "Wer spielt?" (KLD-103); the players change them there or through
/// the game's "Spielernamen" action.
/// Same cleaning as [PlayerNameController]; persisted under [prefsKeyX] /
/// [prefsKeyO].
class HotSeatNamesController extends ValueNotifier<HotSeatNames> {
  HotSeatNamesController._(this._prefs, super.value);

  /// In-memory controller (no persistence).
  HotSeatNamesController.memory([super.value = HotSeatNames.none]) : _prefs = null;

  static const String prefsKeyX = 'hotSeatNameX';
  static const String prefsKeyO = 'hotSeatNameO';

  final SharedPreferences? _prefs;

  static Future<HotSeatNamesController> load({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    return HotSeatNamesController._(
        p, HotSeatNames(x: _orNull(p.getString(prefsKeyX)), o: _orNull(p.getString(prefsKeyO))));
  }

  /// Cleans and saves both names; an empty one is cleared (default name).
  Future<void> setNames(String? x, String? o) async {
    final next = HotSeatNames(x: _orNull(x), o: _orNull(o));
    value = next;
    final p = _prefs;
    if (p == null) return;
    for (final (key, v) in [(prefsKeyX, next.x), (prefsKeyO, next.o)]) {
      if (v == null) {
        await p.remove(key);
      } else {
        await p.setString(key, v);
      }
    }
  }

  static String? _orNull(String? raw) {
    final s = sanitizePlayerName(raw);
    return s.isEmpty ? null : s;
  }
}

/// Makes the app's name controllers reachable below the app.
class PlayerNameScope extends InheritedWidget {
  const PlayerNameScope({super.key, required this.controller, required this.hotSeat, required super.child});

  final PlayerNameController controller;
  final HotSeatNamesController hotSeat;

  static PlayerNameScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerNameScope>();

  @override
  bool updateShouldNotify(PlayerNameScope oldWidget) =>
      controller != oldWidget.controller || hotSeat != oldWidget.hotSeat;
}

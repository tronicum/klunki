import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two learning aids of Ausgewürfelt (KLD-119), device settings:
///
/// * [enabled], the "Anfängermodus": the box [DiceSheetAdvisor] recommends
///   glows in the sheet (and is scrolled into view). On by default for the
///   first [autoGamesBeginner] game on this device.
/// * [tips], the "Tipps": the bubble above the dice that says which box
///   fits and why, and the "Tipp" button for which dice to keep. On by
///   default for the first [autoGamesTips] games; the bubble has
///   "Tipps ausschalten".
///
/// The games are counted by [countGame] when one ends ([gamesPlayed]). An
/// explicit choice (the switches in the start options, "Tipps ausschalten"
/// in the bubble) wins over the automatic default for good. Persisted under
/// [prefsKey], [prefsKeyTips] (explicit choices only) and [prefsKeyGames];
/// without storage it lasts for the session.
class BeginnerSettings extends ChangeNotifier {
  BeginnerSettings._();

  /// In-memory (no persistence): tests. [games] ended games so far,
  /// [beginner] / [tips] an explicit choice (null: none).
  BeginnerSettings.memory({this._games = 0, this._beginner, this._tips});

  /// Games with the Anfängermodus on by default.
  static const int autoGamesBeginner = 1;

  /// Games with the tips on by default.
  static const int autoGamesTips = 5;

  static const String prefsKey = 'dicesheetBeginner';
  static const String prefsKeyTips = 'dicesheetTips';
  static const String prefsKeyGames = 'dicesheetGames';

  SharedPreferences? _prefs;
  int _games = 0;

  /// The player's explicit choices, null while there is none.
  bool? _beginner;
  bool? _tips;

  /// Set before storage was loaded: these win over the stored values.
  bool _beginnerSet = false;
  bool _tipsSet = false;
  int _gamesCountedEarly = 0;

  static BeginnerSettings? _shared;

  /// The app's instance: the defaults first, the stored values as soon as
  /// they are loaded.
  static BeginnerSettings shared() => _shared ??= (BeginnerSettings._().._load());

  /// Tests: a fresh install (memory only, [games] ended games so far), or
  /// with [loaded] a fresh start that reads the stored values again.
  @visibleForTesting
  static void debugReset({bool loaded = false, int games = 0}) =>
      _shared = loaded ? (BeginnerSettings._().._load()) : BeginnerSettings.memory(games: games);

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final before = (enabled, tips);
      if (_beginnerSet) {
        await p.setBool(prefsKey, _beginner!);
      } else {
        _beginner = p.getBool(prefsKey);
      }
      if (_tipsSet) {
        await p.setBool(prefsKeyTips, _tips!);
      } else {
        _tips = p.getBool(prefsKeyTips);
      }
      _games = (p.getInt(prefsKeyGames) ?? 0) + _gamesCountedEarly;
      if (_gamesCountedEarly > 0) await p.setInt(prefsKeyGames, _games);
      if ((enabled, tips) != before) notifyListeners();
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// Anfängermodus (the recommended box glows): the explicit choice, else
  /// on for the first [autoGamesBeginner] game.
  bool get enabled => _beginner ?? _games < autoGamesBeginner;

  /// Tipps (the bubble and the "Tipp" button): the explicit choice, else on
  /// for the first [autoGamesTips] games.
  bool get tips => _tips ?? _games < autoGamesTips;

  /// Ausgewürfelt games that ended on this device.
  int get gamesPlayed => _games;

  /// A game ended (won, lost or given up): the automatic defaults turn off
  /// after their number of games.
  Future<void> countGame() async {
    final before = (enabled, tips);
    _games++;
    if (_prefs == null) _gamesCountedEarly++;
    if ((enabled, tips) != before) notifyListeners();
    await _prefs?.setInt(prefsKeyGames, _games);
  }

  Future<void> setEnabled(bool on) async {
    _beginnerSet = true;
    final before = enabled;
    _beginner = on;
    if (enabled != before) notifyListeners();
    await _prefs?.setBool(prefsKey, on);
  }

  Future<void> setTips(bool on) async {
    _tipsSet = true;
    final before = tips;
    _tips = on;
    if (tips != before) notifyListeners();
    await _prefs?.setBool(prefsKeyTips, on);
  }
}

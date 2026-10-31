import 'package:flutter/foundation.dart';
import 'package:klunki_engine/klunki_engine.dart' show QuartettDeck;
import 'package:shared_preferences/shared_preferences.dart';

/// The last chosen Quartett deck (KLD-069): preselected in the deck picker
/// before a hot-seat game and in the network host setup. [value] is a
/// [QuartettDeck] id, the car deck until something is chosen. Persisted
/// under [prefsKey]; an unknown stored id (a deck removed later) is ignored.
class QuartettDeckSettings extends ValueNotifier<String> {
  QuartettDeckSettings._(this._prefs, super.value);

  /// In-memory (no persistence): tests and the fallback without storage.
  QuartettDeckSettings.memory([super.value = QuartettDeck.defaultId]) : _prefs = null;

  static const String prefsKey = 'quartettDeck';

  SharedPreferences? _prefs;
  bool _chosen = false;

  static QuartettDeckSettings? _shared;

  /// The app's instance: starts with the car deck and switches to the stored
  /// deck as soon as storage is loaded (unless one was chosen meanwhile).
  static QuartettDeckSettings shared() =>
      _shared ??= (QuartettDeckSettings._(null, QuartettDeck.defaultId).._load());

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final saved = p.getString(prefsKey);
      if (!_chosen && saved != null && QuartettDeck.byId(saved) != null) value = saved;
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// The chosen deck.
  QuartettDeck get deck => QuartettDeck.byId(value) ?? QuartettDeck.cars;

  /// Chooses [deck] (an id of [QuartettDeck.all]) and saves it.
  Future<void> set(String deck) async {
    if (QuartettDeck.byId(deck) == null) throw ArgumentError.value(deck, 'deck', 'unknown deck');
    _chosen = true;
    value = deck;
    await _prefs?.setString(prefsKey, deck);
  }
}

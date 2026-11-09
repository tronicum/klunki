import 'package:flutter/widgets.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player;
import 'package:shared_preferences/shared_preferences.dart';

/// "Zug bestätigen" (KLD-122): a move only counts after the player taps
/// "Ziehen"; until then it is only shown on the board and "Anders ziehen" takes it
/// back. A UI preference: nothing reaches the engine, the transport or the
/// other device before the confirmation, so it needs no rules or protocol
/// change and each device (each hot-seat player) chooses for itself.
///
/// * [network]: this device's choice for network games (default on: over
///   the network a misplaced piece cannot be taken back).
/// * [hotSeat]: per seat for games on one device, chosen in "Wer spielt?"
///   (e.g. Anna on, Ben off). Default on as well (a slip of the finger is
///   caught before the other player sees it); a player turns it off.
///
/// One setting for every game that offers it (see `confirmMoveGames`), not
/// one per game. Persisted under [prefsKeyNetwork], [prefsKeyHotSeatA] and
/// [prefsKeyHotSeatB]; without storage it lasts for the session.
class ConfirmMoveSettings extends ChangeNotifier {
  ConfirmMoveSettings._(this._prefs);

  /// In-memory (no persistence): tests and the fallback without storage.
  ConfirmMoveSettings.memory(
      {bool network = defaultNetwork, bool hotSeatA = defaultHotSeat, bool hotSeatB = defaultHotSeat})
      : _prefs = null {
    _network = network;
    _hotSeat = {Player.a: hotSeatA, Player.b: hotSeatB};
  }

  static const bool defaultNetwork = true;
  static const bool defaultHotSeat = true;
  static const String prefsKeyNetwork = 'confirmMoveNetwork';
  static const String prefsKeyHotSeatA = 'confirmMoveHotSeatA';
  static const String prefsKeyHotSeatB = 'confirmMoveHotSeatB';

  SharedPreferences? _prefs;
  bool _network = defaultNetwork;
  Map<Player, bool> _hotSeat = {Player.a: defaultHotSeat, Player.b: defaultHotSeat};

  /// Values set before storage was loaded win over the stored ones.
  final Set<String> _chosen = {};

  static ConfirmMoveSettings? _shared;

  /// The app's instance: starts with the defaults and fills in from storage
  /// as soon as it is loaded.
  static ConfirmMoveSettings shared() => _shared ??= (ConfirmMoveSettings._(null).._load());

  /// Tests: a fresh install (memory only, the defaults), or with [loaded] a
  /// fresh start that reads the stored values again.
  @visibleForTesting
  static void debugReset({bool loaded = false}) =>
      _shared = loaded ? (ConfirmMoveSettings._(null).._load()) : ConfirmMoveSettings.memory();

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      final n = p.getBool(prefsKeyNetwork), a = p.getBool(prefsKeyHotSeatA), b = p.getBool(prefsKeyHotSeatB);
      if (n != null && !_chosen.contains(prefsKeyNetwork)) _network = n;
      if (a != null && !_chosen.contains(prefsKeyHotSeatA)) _hotSeat = {..._hotSeat, Player.a: a};
      if (b != null && !_chosen.contains(prefsKeyHotSeatB)) _hotSeat = {..._hotSeat, Player.b: b};
      notifyListeners();
    } catch (_) {
      // No storage (e.g. blocked site data): stay in memory.
    }
  }

  /// This device in a network game.
  bool get network => _network;

  /// [player]'s choice in a hot-seat game.
  bool hotSeat(Player player) => _hotSeat[player] ?? defaultHotSeat;

  /// Whether [player]'s moves wait for "Ziehen": [onNetwork] = a network game
  /// (the device's choice), else the hot-seat choice of that seat.
  bool confirmFor(Player player, {required bool onNetwork}) => onNetwork ? network : hotSeat(player);

  Future<void> setNetwork(bool on) async {
    _chosen.add(prefsKeyNetwork);
    if (_network == on) return;
    _network = on;
    notifyListeners();
    await _prefs?.setBool(prefsKeyNetwork, on);
  }

  Future<void> setHotSeat(Player player, bool on) async {
    final key = player == Player.a ? prefsKeyHotSeatA : prefsKeyHotSeatB;
    _chosen.add(key);
    if (hotSeat(player) == on) return;
    _hotSeat = {..._hotSeat, player: on};
    notifyListeners();
    await _prefs?.setBool(key, on);
  }
}

/// Puts a [ConfirmMoveSettings] below it (tests: one per simulated device);
/// without a scope [of] uses [ConfirmMoveSettings.shared].
class ConfirmMoveScope extends InheritedNotifier<ConfirmMoveSettings> {
  const ConfirmMoveScope({super.key, required ConfirmMoveSettings settings, required super.child})
      : super(notifier: settings);

  /// The nearest scope's settings, else the app's; rebuilds [context] when
  /// they change.
  static ConfirmMoveSettings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ConfirmMoveScope>()?.notifier ?? ConfirmMoveSettings.shared();
}

import 'package:flutter/widgets.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../ltr.dart';

/// How the game shell names the players (KLD-056). The [GameScreen] asks the
/// nearest [PlayerLabelsScope]; without one it uses [marks] ("X" / "O", the
/// look before KLD-056).
///
/// * [names]: optional display names per player (network: both handles;
///   hot-seat: the names the players typed). A player without a name is
///   shown by its mark only.
/// * [local]: the one player on this device (network), so the shell can say
///   "Du bist am Zug" / "Du gewinnst!". Null when both play here (hot-seat).
///
/// The mark stays visible next to every name ("Anna (X)"): it is what maps
/// a player to colours and pieces on the board.
@immutable
class PlayerLabels {
  const PlayerLabels({this.names = const {}, this.local});

  /// Marks only, no local player: hot-seat without names.
  static const PlayerLabels marks = PlayerLabels();

  final Map<Player, String> names;
  final Player? local;

  /// The player mark, as everywhere in the UI: A is "X", B is "O".
  static String markOf(Player p) => p == Player.a ? 'X' : 'O';

  String? nameOf(Player p) {
    final n = names[p];
    return n == null || n.isEmpty ? null : n;
  }

  bool isLocal(Player p) => local == p;

  /// "Anna (X)" (the name bidi-isolated where needed, see [bidiName]) or "X".
  String label(BuildContext context, AppLocalizations l10n, Player p) {
    final n = nameOf(p);
    return n == null ? markOf(p) : l10n.playerLabel(bidiName(context, n), markOf(p));
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerLabels &&
      other.local == local &&
      other.names.length == names.length &&
      names.entries.every((e) => other.names[e.key] == e.value);

  @override
  int get hashCode => Object.hash(local, Object.hashAllUnordered(names.entries.map((e) => Object.hash(e.key, e.value))));
}

/// Provides [PlayerLabels] to the game shell below it.
class PlayerLabelsScope extends InheritedWidget {
  const PlayerLabelsScope({super.key, required this.labels, required super.child});

  final PlayerLabels labels;

  /// The nearest labels, [PlayerLabels.marks] if there is no scope.
  static PlayerLabels of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerLabelsScope>()?.labels ?? PlayerLabels.marks;

  @override
  bool updateShouldNotify(PlayerLabelsScope oldWidget) => labels != oldWidget.labels;
}

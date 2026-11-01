import 'package:flutter/widgets.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../ltr.dart';

/// How the game shell names the players (KLD-056, KLD-102). The [GameScreen]
/// asks the nearest [PlayerLabelsScope]; without one it uses [defaults].
///
/// * [names]: display names per player (network: both handles; hot-seat:
///   the names the players typed). A player without a name gets the
///   regional default name ([defaultPlayerName]: "Anna" / "Ben").
/// * [local]: the one player on this device (network), so the shell can say
///   "Du bist am Zug" / "Du gewinnst!". Null when both play here (hot-seat).
///
/// Sentences show the name only ("Anna ist am Zug"); the player's colour and
/// symbol stay next to it as tokens (players legend, pieces, the turn pill).
/// The mark joins the name ("Anna (Weiß)") only where it carries meaning or
/// is needed to tell the players apart ([withMark]):
///
/// * [markNames]: a game's own words for the marks (chess, KLD-059: "Weiß" /
///   "Schwarz" instead of X / O); see [withMarkNames];
/// * both players have the same name ("Anna (X)" / "Anna (O)").
@immutable
class PlayerLabels {
  const PlayerLabels({this.names = const {}, this.local, this.markNames = const {}});

  /// Default names only, no local player: hot-seat without typed names.
  static const PlayerLabels defaults = PlayerLabels();

  final Map<Player, String> names;
  final Player? local;
  final Map<Player, String> markNames;

  /// These labels with the marks shown as [marks] (e.g. "Weiß" / "Schwarz").
  PlayerLabels withMarkNames(Map<Player, String> marks) => PlayerLabels(names: names, local: local, markNames: marks);

  /// The mark of [p] as shown in texts: the game's [markNames] word, else
  /// [markOf].
  String mark(Player p) => markNames[p] ?? markOf(p);

  /// The player mark (the symbol on the player's token): A is "X", B is "O".
  static String markOf(Player p) => p == Player.a ? 'X' : 'O';

  /// The name given for [p], or null (then [name] is the default name).
  String? nameOf(Player p) {
    final n = names[p];
    return n == null || n.isEmpty ? null : n;
  }

  /// The name shown for [p]: [nameOf], else the regional default name.
  String name(AppLocalizations l10n, Player p) => nameOf(p) ?? defaultPlayerName(l10n, p);

  bool isLocal(Player p) => local == p;

  /// The player inside a sentence: "Anna" (bidi-isolated where needed, see
  /// [bidiName]), with the mark when [withMark] ("Anna (Weiß)").
  String label(BuildContext context, AppLocalizations l10n, Player p) {
    final n = bidiName(context, name(l10n, p));
    return withMark(l10n) ? l10n.playerLabel(n, mark(p)) : n;
  }

  /// Whether [label] adds the mark: the game names its marks, or both
  /// players have the same name (ignoring case).
  bool withMark(AppLocalizations l10n) =>
      markNames.isNotEmpty || name(l10n, Player.a).toLowerCase() == name(l10n, Player.b).toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is PlayerLabels &&
      other.local == local &&
      other.names.length == names.length &&
      names.entries.every((e) => other.names[e.key] == e.value) &&
      other.markNames.length == markNames.length &&
      markNames.entries.every((e) => other.markNames[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
        local,
        Object.hashAllUnordered(names.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAllUnordered(markNames.entries.map((e) => Object.hash(e.key, e.value))),
      );
}

/// The regional default name of [p] (KLD-102): in German "Anna" for A and
/// "Ben" for B; every locale has its own pair (`playerDefaultNameA` / `B`).
/// Presentation only: the engine and the protocol still know the players as
/// A and B; a room only sends the name its player confirmed (KLD-056).
String defaultPlayerName(AppLocalizations l10n, Player p) =>
    p == Player.a ? l10n.playerDefaultNameA : l10n.playerDefaultNameB;

/// Provides [PlayerLabels] to the game shell below it.
class PlayerLabelsScope extends InheritedWidget {
  const PlayerLabelsScope({super.key, required this.labels, required super.child});

  final PlayerLabels labels;

  /// The nearest labels, [PlayerLabels.defaults] if there is no scope.
  static PlayerLabels of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PlayerLabelsScope>()?.labels ?? PlayerLabels.defaults;

  @override
  bool updateShouldNotify(PlayerLabelsScope oldWidget) => labels != oldWidget.labels;
}

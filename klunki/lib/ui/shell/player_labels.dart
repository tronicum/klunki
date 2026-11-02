import 'package:flutter/widgets.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart';

import '../ltr.dart';

/// How the game shell names the players (KLD-056, KLD-103). The [GameScreen]
/// asks the nearest [PlayerLabelsScope]; without one it uses [defaults].
///
/// * [names]: display names per player (network: both handles; hot-seat:
///   the names the players typed). A player without a name gets the
///   regional default name ([defaultPlayerName]: "Anna" / "Ben").
/// * [local]: the one player on this device (network), so the shell can say
///   "Du bist am Zug" / "Du gewinnst!". Null when both play here (hot-seat).
///
/// Sentences show the name only ("Anna ist am Zug"); the player's colour and
/// number (or the game's own piece) stay next to it as tokens (players
/// legend, pieces, the turn pill). The mark joins the name ("Anna (Weiß)")
/// only where it carries meaning or is needed to tell the players apart
/// ([withMark]):
///
/// * [markNames]: a game's own words for the marks (chess, KLD-059: "Weiß" /
///   "Schwarz"); see [withMarkNames];
/// * both players have the same name: the player number, as on the token
///   and in "Spieler 1 / 2" ("Anna (1)" / "Anna (2)", KLD-106).
///
/// [tokens]: whose token (colour, piece) a player shows, when it is not
/// its own: in network chess the host (A) may play Black (KLD-059 step 4a),
/// then A shows B's black king and B the white one ([tokenSidesOf]).
@immutable
class PlayerLabels {
  const PlayerLabels({this.names = const {}, this.local, this.markNames = const {}, this.tokens = const {}});

  /// Default names only, no local player: hot-seat without typed names.
  static const PlayerLabels defaults = PlayerLabels();

  final Map<Player, String> names;
  final Player? local;
  final Map<Player, String> markNames;
  final Map<Player, Player> tokens;

  /// These labels with the marks shown as [marks] (e.g. "Weiß" / "Schwarz")
  /// and, when given, the token sides [tokens].
  PlayerLabels withMarkNames(Map<Player, String> marks, {Map<Player, Player>? tokens}) =>
      PlayerLabels(names: names, local: local, markNames: marks, tokens: tokens ?? this.tokens);

  /// The player whose token [p] shows (see [tokens]); [p] itself by default.
  Player tokenOf(Player p) => tokens[p] ?? p;

  /// The mark of [p] as shown in texts: the game's [markNames] word, else
  /// the player number [numberOf].
  String mark(Player p) => markNames[p] ?? numberOf(p);

  /// The player number shown on the player's token and in "Spieler 1 / 2"
  /// (KLD-106): A (who starts in every game but network chess with the
  /// host on Black) is "1", B is "2".
  static String numberOf(Player p) => p == Player.a ? '1' : '2';

  /// The internal player mark: A is "X", B is "O". Widget keys, preference
  /// keys and engine-facing text only; never shown in the app (KLD-106).
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
  bool withMark(AppLocalizations l10n) => markNames.isNotEmpty || sameNames(l10n);

  /// Whether both players have the same name (ignoring case).
  bool sameNames(AppLocalizations l10n) => name(l10n, Player.a).toLowerCase() == name(l10n, Player.b).toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is PlayerLabels &&
      other.local == local &&
      other.names.length == names.length &&
      names.entries.every((e) => other.names[e.key] == e.value) &&
      other.markNames.length == markNames.length &&
      markNames.entries.every((e) => other.markNames[e.key] == e.value) &&
      other.tokens.length == tokens.length &&
      tokens.entries.every((e) => other.tokens[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
        local,
        Object.hashAllUnordered(names.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAllUnordered(markNames.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAllUnordered(tokens.entries.map((e) => Object.hash(e.key, e.value))),
      );
}

/// The regional default name of [p] (KLD-103): in German "Anna" for A and
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

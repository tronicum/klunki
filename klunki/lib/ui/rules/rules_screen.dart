import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../app/theme.dart';
import '../../profile/seen_tips.dart';
import '../game_titles.dart';
import '../game_visuals.dart';
import 'rules_model.dart';
import 'rules_registry.dart';

/// Whether [gameId] has a rules page ([gameRules]).
bool hasRules(String gameId) => gameRules.containsKey(gameId);

/// Opens the rules page of [gameId] (KLD-123). [config] is the running
/// game's config (its house rules are shown); null from the menu (the
/// defaults). Marks the page as seen for the "Neu hier?" line.
Future<void> openRules(BuildContext context, String gameId, {GameConfig? config}) {
  SeenTips.shared.markFirst(SeenTips.rulesOpened(gameId));
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => RulesScreen(gameId: gameId, config: config),
  ));
}

/// "Spielregeln" of one game (KLD-123), the same parts for every game:
/// Ziel, So läuft ein Zug, Besondere Regeln and the house rules that are on
/// (in this game, or the suggested ones from the menu).
///
/// Keys: `rules-page`, `rules-goal`, `rules-turn`, `rules-special`,
/// `rules-house`, `rules-house-<id>`, `rules-house-none`,
/// `rules-house-menu-note`.
class RulesScreen extends StatelessWidget {
  final String gameId;

  /// The running game's config; null: opened from the menu.
  final GameConfig? config;

  const RulesScreen({super.key, required this.gameId, this.config});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final accent = palette.accent(gameId);
    final inGame = config != null;
    final rules = gameRules[gameId]!(context, l10n, config ?? GameConfig(gameId));
    final title = localizedGameTitle(l10n, gameId, fallback: specById(gameId)?.title ?? gameId);
    final on = [for (final h in rules.houseRules) if (h.on) h];
    final muted = theme.colorScheme.onSurfaceVariant;

    Widget section(String key, IconData icon, String heading, List<Widget> children) => Padding(
          key: Key(key),
          padding: const EdgeInsets.only(top: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: accent.onSurface(theme.brightness)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(heading, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ...children,
            ],
          ),
        );

    Widget lead(Widget? picture) => SizedBox(
          width: 44,
          child: Center(
            child: picture ??
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: accent.onSurface(theme.brightness), shape: BoxShape.circle),
                  ),
                ),
          ),
        );

    Widget item(RuleItem i) {
      if (i.child case final child?) {
        return Padding(key: i.key, padding: const EdgeInsets.symmetric(vertical: 6), child: child);
      }
      if (i.heading) {
        return Padding(
          key: i.key,
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Text(i.text!, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        );
      }
      return Padding(
        key: i.key,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: i.lead == null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            lead(i.lead),
            const SizedBox(width: 10),
            Expanded(child: Text(i.text!, style: theme.textTheme.bodyLarge)),
          ],
        ),
      );
    }

    Widget house(HouseRule h) => Padding(
          key: Key('rules-house-${h.id}'),
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              lead(h.lead ?? Icon(Icons.check_circle, size: 24, color: accent.onSurface(theme.brightness))),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(h.text, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: accent.color,
        foregroundColor: accent.onColor,
        title: Text(l10n.rulesTitle(title)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            // All of it built (no lazy list): short pages, and tests and
            // screen readers find every part.
            child: SingleChildScrollView(
              key: const Key('rules-page'),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The menu illustration of the game, on its accent.
                ExcludeSemantics(
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [accent.container, Color.lerp(accent.container, accent.color, 0.2)!],
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: CustomPaint(painter: visualsOf(gameId).illustration(palette)),
                  ),
                ),
                section('rules-goal', Icons.emoji_events_outlined, l10n.rulesGoal, [
                  for (final i in rules.goal) item(i),
                ]),
                section('rules-turn', Icons.touch_app_outlined, l10n.rulesTurn, [
                  for (final i in rules.turn) item(i),
                ]),
                section('rules-special', Icons.auto_awesome_outlined, l10n.rulesSpecial, [
                  for (final i in rules.special) item(i),
                ]),
                section('rules-house', Icons.home_outlined, inGame ? l10n.rulesHouseInGame : l10n.rulesHouse, [
                  if (rules.houseRules.isEmpty)
                    Text(l10n.rulesHouseNoneForGame, key: const Key('rules-house-none'), style: theme.textTheme.bodyLarge)
                  else if (on.isEmpty)
                    Text(l10n.rulesHouseNoneOn, key: const Key('rules-house-none'), style: theme.textTheme.bodyLarge)
                  else
                    for (final h in on) house(h),
                  if (!inGame && rules.choosable)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l10n.rulesHouseMenuNote,
                        key: const Key('rules-house-menu-note'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                      ),
                    ),
                ]),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Regeln" button of the game screen's app bar (KLD-123): the book
/// icon with the word under it, one app-bar button wide, so it fits next to
/// the other actions on a phone and stays in the same place in every game.
class RulesButton extends StatelessWidget {
  final VoidCallback onPressed;
  const RulesButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = IconTheme.of(context).color;
    return Semantics(
      button: true,
      label: l10n.rulesButton,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: 28,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 2, end: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_outlined, size: 22, color: color),
                Text(
                  l10n.rulesButton,
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

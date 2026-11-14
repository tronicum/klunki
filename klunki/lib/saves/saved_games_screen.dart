import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../app/theme.dart';
import '../l10n/app_localizations.dart';
import '../profile/player_name_controller.dart';
import '../profile/seat_names.dart';
import '../transport/hot_seat_transport.dart';
import '../ui/game_titles.dart';
import '../ui/game_visuals.dart';
import '../ui/games/wordtiles/wordtiles_options.dart' show loadWordListWithProgress;
import '../ui/shell/screen_registry.dart' show GameSession;
import '../ui/shell/seat_labels.dart' show defaultSeatName;
import 'save_store.dart';
import 'saved_game.dart';

/// The menu's "Weiterspielen" card (KLD-079): shown only while there are
/// saved games in the app's [SavedGamesScope]; opens [SavedGamesScreen].
class SavedGamesMenuCard extends StatelessWidget {
  const SavedGamesMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = SavedGamesScope.maybeOf(context);
    if (store == null || store.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        key: const Key('menu-saved-games'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(Icons.play_circle_outline, size: 32, color: theme.colorScheme.primary),
          title: Text(l10n.savesTitle, style: theme.textTheme.titleMedium),
          subtitle: Text(l10n.savesMenuCount(store.length)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const SavedGamesScreen())),
        ),
      ),
    );
  }
}

/// "Weiterspielen" (KLD-079): the saved hot-seat games, the most recent
/// first (game, players, date, number of moves). Tapping one resumes it
/// ([resumeSavedGame]); the bin deletes it after a question. A save this
/// build cannot replay says "Kann nicht fortgesetzt werden" and can only be
/// deleted.
class SavedGamesScreen extends StatelessWidget {
  const SavedGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final store = SavedGamesScope.maybeOf(context);
    final entries = store?.entries ?? const <SaveEntry>[];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.savesTitle)),
      body: KlunkiBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.savesEmpty, key: const Key('saves-empty'), textAlign: TextAlign.center),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        for (final e in entries) ...[_SaveTile(entry: e), const SizedBox(height: 8)],
                        const SizedBox(height: 8),
                        Text(
                          l10n.savesHint,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveTile extends StatelessWidget {
  final SaveEntry entry;
  const _SaveTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context);
    final id = entry.gameId;
    final accent = palette.accent(id);
    final game = entry.game;
    final title = savedGameTitle(l10n, id);
    final muted = theme.colorScheme.onSurfaceVariant;
    final lines = <String>[
      if (game != null) savedGamePlayers(l10n, game),
      if (game != null) '${savedGameDate(context, game.savedAt)} · ${l10n.savesMoveCount(game.moves.length)}',
      if (!entry.resumable) l10n.savesCannotResume,
    ];
    return Card(
      key: Key('saved-$id'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => resumeSavedGame(context, entry),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.container,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: accent.color, width: 2),
                ),
                child: ExcludeSemantics(child: CustomPaint(painter: visualsOf(id).illustration(palette))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    for (final (i, line) in lines.indexed)
                      Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: !entry.resumable && i == lines.length - 1 ? theme.colorScheme.error : muted),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: Key('saved-$id-delete'),
                tooltip: l10n.savesDelete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => confirmDeleteSave(context, id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The game's title in the app language (its id for a game this build does
/// not know).
String savedGameTitle(AppLocalizations l10n, String id) =>
    localizedGameTitle(l10n, id, fallback: specById(id)?.title ?? id);

/// "Anna · Ben": every seat's name, the default name where none was typed.
String savedGamePlayers(AppLocalizations l10n, SavedGame game) => [
      for (var s = 0; s < game.config.players; s++)
        (s < game.names.length ? game.names[s] : null) ?? defaultSeatName(l10n, s),
    ].join(' · ');

/// The save's date and time in the app language.
String savedGameDate(BuildContext context, DateTime at) {
  final m = MaterialLocalizations.of(context);
  final local = at.toLocal();
  return '${m.formatMediumDate(local)}, ${m.formatTimeOfDay(TimeOfDay.fromDateTime(local),
      alwaysUse24HourFormat: MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false)}';
}

/// Asks "Spiel löschen?" and deletes the save of [gameId] on yes.
Future<void> confirmDeleteSave(BuildContext context, String gameId) async {
  final l10n = AppLocalizations.of(context);
  final store = SavedGamesScope.read(context);
  if (store == null) return;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('saves-delete-dialog'),
      title: Text(l10n.savesDeleteTitle),
      content: Text(l10n.savesDeleteBody(savedGameTitle(l10n, gameId))),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.shellCancel)),
        FilledButton(
          key: const Key('saves-delete-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.savesDelete),
        ),
      ],
    ),
  );
  if (yes == true) await store.remove(gameId);
}

/// Resumes [entry]: rebuilds the game by replaying its moves into a fresh
/// engine ([HotSeatTransport] with `log`), puts the saved names back into
/// the hot-seat name stores and replaces the current screen with the
/// game's ([GameSession] with `resumed`). A save that is outdated or does
/// not replay shows "Kann nicht fortgesetzt werden" and offers to delete it;
/// nothing throws.
Future<void> resumeSavedGame(BuildContext context, SaveEntry entry) async {
  final game = entry.game;
  if (game == null || !entry.resumable) return _cannotResume(context, entry.gameId);
  final config = game.config;
  if (config.gameId == 'wordtiles' && config.dictionary) {
    if (!await loadWordListWithProgress(context, config.tiles ?? TileSet.german.id) || !context.mounted) return;
  }
  HotSeatTransport? transport;
  try {
    if (configProblem(config) == null) {
      transport = HotSeatTransport(config,
          log: game.moves, resumeClock: game.clock, resumeClockBefore: game.clockBefore);
      if (transport.game.isOver) {
        transport.dispose();
        transport = null;
      }
    }
  } catch (_) {
    transport?.dispose();
    transport = null;
  }
  if (!context.mounted) {
    transport?.dispose();
    return;
  }
  if (transport == null) return _cannotResume(context, entry.gameId);
  final names = game.names;
  String? nameOf(int s) => s < names.length ? names[s] : null;
  await PlayerNameScope.maybeOf(context)?.hotSeat.setNames(nameOf(0), nameOf(1));
  if (config.players > 2) {
    final extra = ExtraSeatNames.shared();
    await extra.set(third: nameOf(2), fourth: config.players > 3 ? nameOf(3) : extra.nameOf(3));
  }
  if (!context.mounted) {
    transport.dispose();
    return;
  }
  final resumed = transport;
  await Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
    builder: (_) => GameSession(config: config, resumed: resumed),
  ));
}

Future<void> _cannotResume(BuildContext context, String gameId) async {
  final l10n = AppLocalizations.of(context);
  final delete = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('saves-cannot-resume'),
      title: Text(l10n.savesCannotResume),
      content: Text(l10n.savesCannotResumeBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.shellCancel)),
        FilledButton(
          key: const Key('saves-cannot-resume-delete'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.savesDelete),
        ),
      ],
    ),
  );
  if (delete == true && context.mounted) await SavedGamesScope.read(context)?.remove(gameId);
}

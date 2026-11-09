import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player, specById;

import '../profile/player_name_controller.dart';
import '../profile/undo_settings.dart';
import 'shell/confirm_move.dart';
import 'shell/game_screen.dart' show PlayerToken;
import 'shell/player_labels.dart';

export '../profile/player_name_controller.dart';
export 'shell/player_labels.dart' show defaultPlayerName;

/// Limits typing to [maxPlayerNameLength] characters (the stored name is
/// cleaned by [sanitizePlayerName] anyway).
final List<TextInputFormatter> playerNameInputFormatters = [
  LengthLimitingTextInputFormatter(maxPlayerNameLength),
];

/// Asks for the player name ("Wie heißt du?", KLD-056), prefilled with the
/// saved name or [suggestion] (default: the controller's suggestion), and
/// saves it. [firstRun]: only "OK", no way around it (the first visit of
/// "Raum starten" / "Raum beitreten"); otherwise there is a "Cancel" too (menu button).
/// Completes with true if a name was saved.
Future<bool> showPlayerNameDialog(
  BuildContext context,
  PlayerNameController controller, {
  String? suggestion,
  bool firstRun = false,
}) async {
  final initial = controller.value ?? sanitizePlayerName(suggestion ?? controller.suggested);
  final name = await showDialog<String>(
    context: context,
    barrierDismissible: !firstRun,
    builder: (_) => _PlayerNameDialog(initial: initial, cancellable: !firstRun),
  );
  if (name == null) return false;
  return controller.setName(name);
}

/// Shows the first-run name dialog if no name was chosen yet. Completes once
/// a name is set (immediately if there already is one).
Future<void> ensurePlayerName(BuildContext context, PlayerNameController controller, {String? suggestion}) async {
  if (controller.hasName) return;
  // One dialog per controller, even if two screens ask at once.
  final pending = _asking[controller];
  if (pending != null) {
    await pending;
    return;
  }
  final asking = showPlayerNameDialog(context, controller, suggestion: suggestion, firstRun: true);
  _asking[controller] = asking;
  try {
    await asking;
  } finally {
    _asking[controller] = null;
  }
}

final Expando<Future<bool>> _asking = Expando('player name dialog');

class _PlayerNameDialog extends StatefulWidget {
  const _PlayerNameDialog({required this.initial, required this.cancellable});

  final String initial;
  final bool cancellable;

  @override
  State<_PlayerNameDialog> createState() => _PlayerNameDialogState();
}

class _PlayerNameDialogState extends State<_PlayerNameDialog> {
  late final TextEditingController _text = TextEditingController(text: widget.initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: widget.initial.length);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _valid => sanitizePlayerName(_text.text).isNotEmpty;

  void _ok() {
    if (_valid) Navigator.of(context).pop(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    return PopScope(
      canPop: widget.cancellable,
      child: AlertDialog(
        key: const Key('player-name-dialog'),
        title: Text(l10n.playerNameTitle),
        content: TextField(
          key: const Key('player-name-field'),
          controller: _text,
          autofocus: true,
          inputFormatters: playerNameInputFormatters,
          decoration: InputDecoration(
            labelText: l10n.playerNameLabel,
            helperText: l10n.pairingDeviceNameHelper,
            helperMaxLines: 2,
          ),
          textInputAction: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _ok(),
        ),
        actions: [
          if (widget.cancellable)
            TextButton(
              key: const Key('player-name-cancel'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(material.cancelButtonLabel),
            ),
          FilledButton(
            key: const Key('player-name-ok'),
            onPressed: _valid ? _ok : null,
            child: Text(material.okButtonLabel),
          ),
        ],
      ),
    );
  }
}

/// App-bar button (person icon) that edits the player name. Hidden when the
/// app provides no [PlayerNameScope].
class PlayerNameButton extends StatelessWidget {
  const PlayerNameButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = PlayerNameScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();
    return IconButton(
      key: const Key('player-name-button'),
      icon: const Icon(Icons.person_outline),
      tooltip: AppLocalizations.of(context).playerNameLabel,
      // Prefilled with the default name of the room starter (KLD-103).
      onPressed: () => showPlayerNameDialog(context, scope.controller,
          suggestion: defaultPlayerName(AppLocalizations.of(context), Player.a)),
    );
  }
}

/// Hot-seat player names (KLD-056, KLD-103): two fields prefilled with the
/// names in use, i.e. the last typed ones or the regional default names
/// ("Anna" / "Ben"). Saved to the app's [HotSeatNamesController]; a field
/// left empty, or holding the default name, stores no name, so the default
/// follows the app language. [gameId] shows the player tokens (colour and
/// symbol) next to the fields and names the chess sides.
///
/// For a game that offers "Zug bestätigen" (KLD-122, [confirmMoveGames]) each
/// name has its own switch underneath (hot-seat default: off), saved to
/// [ConfirmMoveScope.of] with the names.
///
/// [start]: the dialog that opens a game on this device ("Wer spielt?",
/// "Spielen"); completes with false when it was cancelled (no game then).
/// Otherwise the in-game "Spielernamen" dialog (OK / Cancel). Without a
/// [PlayerNameScope] there is nothing to edit: completes with true at once.
Future<bool> showHotSeatNamesDialog(BuildContext context, {String? gameId, bool start = false}) async {
  final scope = PlayerNameScope.maybeOf(context);
  if (scope == null) return true;
  final l10n = AppLocalizations.of(context);
  final names = scope.hotSeat.value;
  final confirm = gameId != null && confirmMoveGames.contains(gameId) ? ConfirmMoveScope.of(context) : null;
  final result = await showDialog<_HotSeatChoice>(
    context: context,
    builder: (_) => _HotSeatNamesDialog(
      a: names.x ?? defaultPlayerName(l10n, Player.a),
      b: names.o ?? defaultPlayerName(l10n, Player.b),
      confirm: confirm == null ? null : (confirm.hotSeat(Player.a), confirm.hotSeat(Player.b)),
      undo: gameId == null ? null : UndoSettings.shared().allowed(gameId),
      gameId: gameId,
      start: start,
    ),
  );
  if (result == null) return false;
  if (gameId != null && result.undo != null) await UndoSettings.shared().setAllowed(gameId, result.undo!);
  if (confirm != null && result.confirm != null) {
    await confirm.setHotSeat(Player.a, result.confirm!.$1);
    await confirm.setHotSeat(Player.b, result.confirm!.$2);
  }
  // The default name is not stored: it follows the app language.
  String? typed(String raw, Player p) {
    final s = sanitizePlayerName(raw);
    return s == defaultPlayerName(l10n, p) ? null : s;
  }

  await scope.hotSeat.setNames(typed(result.a, Player.a), typed(result.b, Player.b));
  return true;
}

/// What "Wer spielt?" returns: both names, for a game with "Zug
/// bestätigen" both players' choice, and "Zug zurücknehmen erlauben".
typedef _HotSeatChoice = ({String a, String b, (bool, bool)? confirm, bool? undo});

class _HotSeatNamesDialog extends StatefulWidget {
  const _HotSeatNamesDialog(
      {required this.a, required this.b, this.confirm, this.undo, this.gameId, this.start = false});

  final String a;
  final String b;

  /// "Zug bestätigen" for player A and B; null = the game does not offer it.
  final (bool, bool)? confirm;

  /// "Zug zurücknehmen erlauben" for the game (both players); null = no
  /// game (no switch).
  final bool? undo;
  final String? gameId;
  final bool start;

  @override
  State<_HotSeatNamesDialog> createState() => _HotSeatNamesDialogState();
}

class _HotSeatNamesDialogState extends State<_HotSeatNamesDialog> {
  late final TextEditingController _a = TextEditingController(text: widget.a);
  late final TextEditingController _b = TextEditingController(text: widget.b);
  late bool _confirmA = widget.confirm?.$1 ?? false;
  late bool _confirmB = widget.confirm?.$2 ?? false;
  late bool _undo = widget.undo ?? UndoSettings.defaultAllowed;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _ok() => Navigator.of(context)
      .pop((
        a: _a.text,
        b: _b.text,
        confirm: widget.confirm == null ? null : (_confirmA, _confirmB),
        undo: widget.undo == null ? null : _undo,
      ));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final gameId = widget.gameId;
    Widget field(Player p, TextEditingController c, TextInputAction action) {
      final mark = PlayerLabels.markOf(p);
      return TextField(
        key: Key('hot-seat-name-$mark'),
        controller: c,
        inputFormatters: playerNameInputFormatters,
        decoration: InputDecoration(
          // Numbered in turn order: player A (1) makes the first move in
          // every hot-seat game, including the setup phases and chess
          // (White; only a network chess host may choose Black, KLD-059
          // step 4a).
          labelText: l10n.hotSeatNameLabel(p == Player.a ? 1 : 2),
          helperText: p == Player.a ? l10n.hotSeatStartsHint : null,
          hintText: defaultPlayerName(l10n, p),
          // The player's colour and symbol, as on the board (KLD-103).
          prefixIcon: gameId == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: PlayerToken(gameId: gameId, player: p, size: 24),
                ),
        ),
        textInputAction: action,
        onSubmitted: action == TextInputAction.done ? (_) => _ok() : null,
      );
    }

    // "Zug bestätigen" for one player (KLD-122), under the name field.
    Widget confirm(Player p, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
          key: Key('hot-seat-confirm-${PlayerLabels.markOf(p)}'),
          dense: true,
          contentPadding: const EdgeInsetsDirectional.only(start: 12),
          value: value,
          onChanged: onChanged,
          title: Text(l10n.confirmMoveSetting),
        );

    return AlertDialog(
      key: Key(widget.start ? 'hot-seat-start-dialog' : 'hot-seat-names-dialog'),
      title: Text(widget.start ? l10n.hotSeatStartTitle : l10n.hotSeatNamesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(Player.a, _a, TextInputAction.next),
          if (widget.confirm != null) confirm(Player.a, _confirmA, (v) => setState(() => _confirmA = v)),
          const SizedBox(height: 8),
          field(Player.b, _b, TextInputAction.done),
          if (widget.confirm != null) confirm(Player.b, _confirmB, (v) => setState(() => _confirmB = v)),
          const SizedBox(height: 12),
          Text(l10n.hotSeatNamesHelper, style: Theme.of(context).textTheme.bodySmall),
          // KLD-122: what the switches do, once.
          if (widget.confirm != null) ...[
            const SizedBox(height: 4),
            Text(l10n.confirmMoveHelper,
                key: const Key('hot-seat-confirm-helper'), style: Theme.of(context).textTheme.bodySmall),
          ],
          // KLD-117 follow-up: "Zug zurücknehmen erlauben", for both
          // players of this game.
          if (widget.undo != null) ...[
            const SizedBox(height: 4),
            SwitchListTile(
              key: const Key('hot-seat-undo'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.undo),
              value: _undo,
              onChanged: (v) => setState(() => _undo = v),
              title: Text(l10n.undoAllowedSetting),
            ),
          ],
          // KLD-105: hidden-information games are played by passing the
          // device (the handover cover keeps the secrets); said once here
          // instead of on the menu tiles.
          if (widget.start && gameId != null && specById(gameId)?.hiddenInformation == true) ...[
            const SizedBox(height: 12),
            Row(
              key: const Key('hot-seat-pass-device-hint'),
              children: [
                Icon(Icons.visibility_off_outlined, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.hotSeatPassDeviceHint, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ],
        ],
      ),
      scrollable: true,
      actions: [
        TextButton(
          key: const Key('hot-seat-names-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(
          key: const Key('hot-seat-names-ok'),
          onPressed: _ok,
          child: Text(widget.start ? l10n.hotSeatStartPlay : material.okButtonLabel),
        ),
      ],
    );
  }
}

/// The editable "Dein Name" field of the pairing screens (KLD-056), bound to
/// the app's [PlayerNameController]: every valid edit is saved, a change from
/// elsewhere (the first-run dialog) shows up in the field. On first use with
/// no saved name it shows the "Wie heißt du?" dialog once; [playerNameReady]
/// completes after that.
///
/// The controller is [explicitNameController], else the app's
/// [PlayerNameScope], else an in-memory one already set to
/// [playerNameSuggestion] (screens pumped alone in tests: no dialog).
mixin PlayerNameField<T extends StatefulWidget> on State<T> {
  /// A controller passed to the screen (tests), or null.
  PlayerNameController? get explicitNameController;

  /// Default name for this screen (device name, or "Browser").
  String playerNameSuggestion();

  late final PlayerNameController nameController;
  late final TextEditingController nameText;
  final Completer<void> _ready = Completer<void>();
  bool _nameInit = false;
  PlayerNameController? _ownController;

  /// Completes once a name is chosen (right away if there already was one).
  Future<void> get playerNameReady => _ready.future;

  /// The name to send: the field's cleaned text, else the controller's name.
  String get playerName {
    final s = sanitizePlayerName(nameText.text);
    return s.isEmpty ? nameController.name : s;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nameInit) return;
    _nameInit = true;
    nameController = explicitNameController ??
        PlayerNameScope.maybeOf(context)?.controller ??
        (_ownController = PlayerNameController.memory(name: playerNameSuggestion(), suggestion: playerNameSuggestion));
    nameText = TextEditingController(text: nameController.value ?? sanitizePlayerName(playerNameSuggestion()));
    nameController.addListener(_onNameChanged);
    if (nameController.hasName) {
      _ready.complete();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) await ensurePlayerName(context, nameController, suggestion: playerNameSuggestion());
        if (!_ready.isCompleted) _ready.complete();
      });
    }
  }

  void _onNameChanged() {
    final v = nameController.value;
    if (v != null && sanitizePlayerName(nameText.text) != v) nameText.text = v;
  }

  void _onFieldChanged(String text) {
    if (sanitizePlayerName(text).isNotEmpty) nameController.setName(text);
  }

  @override
  void dispose() {
    if (_nameInit) {
      nameController.removeListener(_onNameChanged);
      nameText.dispose();
      _ownController?.dispose();
    }
    super.dispose();
  }

  /// The "Dein Name" text field.
  Widget playerNameField({required Key key, bool enabled = true, TextInputAction? textInputAction}) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      key: key,
      controller: nameText,
      enabled: enabled,
      inputFormatters: playerNameInputFormatters,
      decoration: InputDecoration(
        labelText: l10n.playerNameLabel,
        helperText: l10n.pairingDeviceNameHelper,
        border: const OutlineInputBorder(),
      ),
      textInputAction: textInputAction ?? TextInputAction.done,
      onChanged: _onFieldChanged,
    );
  }
}

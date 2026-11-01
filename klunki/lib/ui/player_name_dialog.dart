import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player;

import '../profile/player_name_controller.dart';
import 'shell/player_labels.dart';

export '../profile/player_name_controller.dart';

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
      onPressed: () => showPlayerNameDialog(context, scope.controller),
    );
  }
}

/// Hot-seat: optional names for X and O (KLD-056), prefilled with the last
/// pair (X: the player name if there is no last X name). Saved to the app's
/// [HotSeatNamesController]; empty fields mean "mark only".
Future<void> showHotSeatNamesDialog(BuildContext context) async {
  final scope = PlayerNameScope.maybeOf(context);
  if (scope == null) return;
  final names = scope.hotSeat.value;
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (_) => _HotSeatNamesDialog(x: names.x ?? scope.controller.value ?? '', o: names.o ?? ''),
  );
  if (result == null) return;
  await scope.hotSeat.setNames(result.$1, result.$2);
}

class _HotSeatNamesDialog extends StatefulWidget {
  const _HotSeatNamesDialog({required this.x, required this.o});

  final String x;
  final String o;

  @override
  State<_HotSeatNamesDialog> createState() => _HotSeatNamesDialogState();
}

class _HotSeatNamesDialogState extends State<_HotSeatNamesDialog> {
  late final TextEditingController _x = TextEditingController(text: widget.x);
  late final TextEditingController _o = TextEditingController(text: widget.o);

  @override
  void dispose() {
    _x.dispose();
    _o.dispose();
    super.dispose();
  }

  void _ok() => Navigator.of(context).pop((_x.text, _o.text));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    Widget field(String mark, TextEditingController c, TextInputAction action) => TextField(
          key: Key('hot-seat-name-$mark'),
          controller: c,
          inputFormatters: playerNameInputFormatters,
          decoration: InputDecoration(labelText: l10n.hotSeatNameLabel(mark)),
          textInputAction: action,
          onSubmitted: action == TextInputAction.done ? (_) => _ok() : null,
        );
    return AlertDialog(
      key: const Key('hot-seat-names-dialog'),
      title: Text(l10n.hotSeatNamesTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(PlayerLabels.markOf(Player.a), _x, TextInputAction.next),
          const SizedBox(height: 8),
          field(PlayerLabels.markOf(Player.b), _o, TextInputAction.done),
          const SizedBox(height: 12),
          Text(l10n.hotSeatNamesHelper, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      scrollable: true,
      actions: [
        TextButton(
          key: const Key('hot-seat-names-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        FilledButton(key: const Key('hot-seat-names-ok'), onPressed: _ok, child: Text(material.okButtonLabel)),
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

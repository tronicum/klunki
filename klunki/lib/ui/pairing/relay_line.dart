import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/guest_web.dart' show parseRelayUrl;

import '../../net/room_link.dart';
import '../../profile/relay_settings.dart';
import '../ltr.dart';

/// "Relay: 192.168.1.5:8000 · ändern" (or "Kein Relay eingerichtet – Adresse
/// eingeben"): the one place the relay of [settings] is shown and changed,
/// the same on "Spiel hosten" and "Mit Raumcode beitreten". [defaultRelay]
/// is used while nothing is chosen (the PWA's own server).
class RelayLine extends StatelessWidget {
  final RelaySettings settings;
  final Uri? defaultRelay;
  final bool enabled;

  const RelayLine({super.key, required this.settings, this.defaultRelay, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<Uri?>(
      valueListenable: settings,
      builder: (context, _, _) {
        final relay = settings.relayFor(defaultRelay);
        return Row(
          key: const Key('relay-line'),
          children: [
            Icon(Icons.dns_outlined, size: 20, color: relay == null ? theme.colorScheme.error : null),
            const SizedBox(width: 8),
            Expanded(
              child: relay == null
                  ? Text(l10n.relayNotSet,
                      key: const Key('relay-line-unset'), style: TextStyle(color: theme.colorScheme.error))
                  : Text(l10n.relayInfo(bidiLtr(context, relayAddressLabel(relay))),
                      key: const Key('relay-line-address')),
            ),
            TextButton(
              key: const Key('relay-change'),
              onPressed: enabled ? () => editRelay(context, settings, defaultRelay: defaultRelay) : null,
              child: Text(l10n.relayChange),
            ),
          ],
        );
      },
    );
  }
}

/// Heading of the relay group, "Über Relay spielen (Raumcode)", with the
/// [RelayLine] below it: what "Spiel hosten" and "Mit Raumcode beitreten"
/// share.
class RelayGroupHeader extends StatelessWidget {
  final RelaySettings settings;
  final Uri? defaultRelay;
  final bool enabled;

  const RelayGroupHeader({super.key, required this.settings, this.defaultRelay, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppLocalizations.of(context).relayGroupTitle,
            key: const Key('relay-group-title'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        RelayLine(settings: settings, defaultRelay: defaultRelay, enabled: enabled),
      ],
    );
  }
}

/// The relay to use, asking for one when none is set: [settings]' choice,
/// else [defaultRelay], else the relay dialog. Null if the player cancels.
Future<Uri?> relayOrAsk(BuildContext context, RelaySettings settings, {Uri? defaultRelay}) async =>
    settings.relayFor(defaultRelay) ?? await editRelay(context, settings, defaultRelay: defaultRelay);

/// The "Relay-Adresse" dialog: an address field, "Übernehmen", and (with a
/// [defaultRelay]) "Standard: …" to go back to it. Saves into [settings] and
/// returns the relay now in use (null: cancelled).
Future<Uri?> editRelay(BuildContext context, RelaySettings settings, {Uri? defaultRelay}) =>
    showDialog<Uri>(
      context: context,
      builder: (_) => _RelayDialog(settings: settings, defaultRelay: defaultRelay),
    );

class _RelayDialog extends StatefulWidget {
  final RelaySettings settings;
  final Uri? defaultRelay;

  const _RelayDialog({required this.settings, this.defaultRelay});

  @override
  State<_RelayDialog> createState() => _RelayDialogState();
}

class _RelayDialogState extends State<_RelayDialog> {
  late final TextEditingController _text = TextEditingController(
    text: switch (widget.settings.relayFor(widget.defaultRelay)) {
      final r? => relayAddressLabel(r),
      null => '',
    },
  );
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    final relay = parseRelayUrl(_text.text.trim());
    if (relay == null) {
      setState(() => _error = AppLocalizations.of(context).relayAddressInvalid);
      return;
    }
    if (relay == widget.defaultRelay) {
      widget.settings.reset();
    } else {
      widget.settings.set(relay);
    }
    Navigator.of(context).pop(relay);
  }

  void _useDefault() {
    widget.settings.reset();
    Navigator.of(context).pop(widget.defaultRelay);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fallback = widget.defaultRelay;
    return AlertDialog(
      title: Text(l10n.relayAddressLabel),
      content: TextField(
        key: const Key('relay-dialog-address'),
        controller: _text,
        autofocus: true,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: '192.168.1.20:4749',
          helperText: l10n.relayAddressHelper,
          helperMaxLines: 3,
          errorText: _error,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        if (fallback != null)
          TextButton(
            key: const Key('relay-dialog-default'),
            onPressed: _useDefault,
            child: Text(l10n.relayUseDefault(bidiLtr(context, relayAddressLabel(fallback)))),
          ),
        TextButton(
          key: const Key('relay-dialog-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.pairingCancel),
        ),
        FilledButton(key: const Key('relay-dialog-save'), onPressed: _save, child: Text(l10n.relaySave)),
      ],
    );
  }
}

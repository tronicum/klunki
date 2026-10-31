import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final line = Row(
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
        if (relay == null || !isLoopbackHost(relay.host)) return line;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            line,
            LoopbackHint(host: relay.host, short: true, key: const Key('relay-line-loopback')),
          ],
        );
      },
    );
  }
}

/// KLD-083: the warning that other devices can't reach [host] (localhost,
/// 127.x, ::1): [short] = one line ("only on this device", under the relay
/// line and natively), otherwise the full hint with "open the page via this
/// computer's Wi-Fi address (e.g. http://192.168.x.x:8081)". Only a warning:
/// hosting on localhost stays allowed (two tabs on one machine).
class LoopbackHint extends StatelessWidget {
  final String host;
  final bool short;

  const LoopbackHint({super.key, required this.host, this.short = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final h = bidiLtr(context, host);
    final text = short
        ? l10n.relayLoopbackShort(h)
        : l10n.relayLoopbackHint(
            h, bidiLtr(context, loopbackHintExample), bidiLtr(context, loopbackHintMdnsExample));
    final color = theme.colorScheme.error;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    key: const Key('loopback-text'), style: theme.textTheme.bodySmall?.copyWith(color: color)),
              ),
            ],
          ),
          const LoopbackAddressHelp(),
        ],
      ),
    );
  }
}

/// "Wie finde ich die Adresse?" (KLD-083), collapsed: where macOS, Windows
/// and Linux show the computer's Wi-Fi address and `.local` name, with the
/// terminal commands (LTR, copyable).
class LoopbackAddressHelp extends StatelessWidget {
  const LoopbackAddressHelp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final small = theme.textTheme.bodySmall;
    Widget os(String name) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(name, style: theme.textTheme.labelLarge),
        );
    Widget line(String s) => Padding(padding: const EdgeInsets.only(top: 2), child: Text(s, style: small));
    return ExpansionTile(
      key: const Key('loopback-how'),
      dense: true,
      tilePadding: EdgeInsetsDirectional.zero,
      childrenPadding: const EdgeInsetsDirectional.only(start: 26, bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(l10n.loopbackHowTitle, style: theme.textTheme.bodyMedium),
      children: [
        os('macOS'),
        line(l10n.loopbackHowMacSettings),
        const _Command('ipconfig getifaddr en0'),
        line(l10n.loopbackHowMacMdns),
        os('Windows'),
        line(l10n.loopbackHowWindowsSettings),
        const _Command('ipconfig'),
        line(l10n.loopbackHowWindowsMdns),
        os('Linux'),
        line(l10n.loopbackHowLinuxTerminal),
        const _Command('hostname -I'),
        const _Command('ip -4 addr show'),
        line(l10n.loopbackHowLinuxSettings),
        const SizedBox(height: 8),
        Text(l10n.loopbackHowRelay(bidiLtr(context, 'klunki relay')),
            key: const Key('loopback-how-relay'), style: small),
      ],
    );
  }
}

/// A terminal command: monospace, left-to-right in every locale, selectable,
/// with a copy button.
class _Command extends StatelessWidget {
  final String command;

  const _Command(this.command);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The bundled font (no monospace font ships), in a tinted box.
    return Row(
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                command,
                key: Key('loopback-cmd-$command'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                textAlign: rtl ? TextAlign.right : TextAlign.left,
              ),
            ),
          ),
        ),
        IconButton(
          key: Key('loopback-copy-$command'),
          icon: const Icon(Icons.copy, size: 18),
          tooltip: l10n.loopbackHowCopy,
          visualDensity: VisualDensity.compact,
          onPressed: () async {
            final messenger = ScaffoldMessenger.maybeOf(context);
            final copied = l10n.loopbackHowCopied;
            await Clipboard.setData(ClipboardData(text: command));
            messenger?.showSnackBar(SnackBar(content: Text(copied)));
          },
        ),
      ],
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

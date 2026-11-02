import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/guest_web.dart' show parseRelayUrl;

import '../../net/room_link.dart';
import '../../net/server_kind.dart';
import '../../profile/relay_settings.dart';
import '../help_screen.dart';
import '../ltr.dart';

/// "Server im WLAN (…)" / "Server im Internet" (KLD-113).
String serverKindText(AppLocalizations l10n, ServerKind kind) => switch (kind) {
      ServerKind.lan => l10n.serverKindLan,
      ServerKind.internet => l10n.serverKindInternet,
    };

/// "Server: 192.168.1.5:8000 · ändern" with the kind of server under it
/// ("Server im WLAN …", KLD-113; or "Kein Server eingerichtet – Adresse
/// eingeben"): the one place the relay of [settings] is shown and changed,
/// the same on "Raum starten" and "Raum beitreten" (under "Erweitert"). [defaultRelay]
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.relayInfo(bidiLtr(context, relayAddressLabel(relay))),
                            key: const Key('relay-line-address')),
                        // KLD-113: the kind, from the address alone.
                        Text(serverKindText(l10n, serverKindOf(relay)),
                            key: const Key('relay-line-kind'),
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
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
        const CopyableCommand('ipconfig getifaddr en0'),
        line(l10n.loopbackHowMacMdns),
        os('Windows'),
        line(l10n.loopbackHowWindowsSettings),
        const CopyableCommand('ipconfig'),
        line(l10n.loopbackHowWindowsMdns),
        os('Linux'),
        line(l10n.loopbackHowLinuxTerminal),
        const CopyableCommand('hostname -I'),
        const CopyableCommand('ip -4 addr show'),
        line(l10n.loopbackHowLinuxSettings),
        const SizedBox(height: 8),
        Text(l10n.loopbackHowRelay(bidiLtr(context, 'klunki relay')),
            key: const Key('loopback-how-relay'), style: small),
      ],
    );
  }
}

/// A terminal command (also on the help screen, KLD-113): monospace, left-to-right in every locale, selectable,
/// with a copy button.
class CopyableCommand extends StatelessWidget {
  final String command;

  const CopyableCommand(this.command, {super.key});

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

/// "Erweitert" (KLD-098): the collapsed section with the technical details
/// of a room screen (relay address, IP addresses, direct connection), which
/// are needed once, when a relay is set up. [id] keys the tile and its title
/// (`<id>-toggle`, to tap it in tests). The children stay built while
/// collapsed ([ExpansionTile.maintainState]), so their fields keep their text.
class RoomAdvanced extends StatelessWidget {
  final String id;
  final List<Widget> children;
  final bool initiallyExpanded;

  const RoomAdvanced({super.key, required this.id, required this.children, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      key: Key(id),
      maintainState: true,
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsetsDirectional.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      shape: const Border(),
      collapsedShape: const Border(),
      leading: Icon(Icons.tune, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        AppLocalizations.of(context).roomAdvanced,
        key: Key('$id-toggle'),
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      children: children,
    );
  }
}

/// The relay to use, asking for one when none is set: [settings]' choice,
/// else [defaultRelay], else the relay dialog. Null if the player cancels.
Future<Uri?> relayOrAsk(BuildContext context, RelaySettings settings, {Uri? defaultRelay}) async =>
    settings.relayFor(defaultRelay) ?? await editRelay(context, settings, defaultRelay: defaultRelay);


/// The "Server" dialog (KLD-113): one address field; under it, in plain
/// words, what kind of server the address names ([serverKindOf]); a saved
/// club code of that server (KLD-112) to see, change or remove, shown only
/// when one is saved (a server that needs one asks for it, see
/// [ClubCodePrompt]); "Wie geht das?" opens the help screen; "Übernehmen",
/// and (with a [defaultRelay]) "Standard: …" to go back to it. Saves into
/// [settings] and returns the relay now in use (null: cancelled).
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
  late final Uri? _initial = widget.settings.relayFor(widget.defaultRelay);
  late final TextEditingController _text = TextEditingController(
    text: switch (_initial) {
      final r? => relayAddressLabel(r),
      null => '',
    },
  )..addListener(_typed);

  /// The server the saved club code belongs to (null: no code saved for the
  /// server in use when the dialog opened).
  late final Uri? _clubRelay = widget.settings.clubCodeFor(_initial) == null ? null : _initial;
  late final TextEditingController _club = TextEditingController(text: widget.settings.clubCodeFor(_clubRelay) ?? '');
  bool _clubRemoved = false;
  String? _error;

  /// The address as typed, parsed (null: not an address yet).
  late Uri? _typedRelay = parseRelayUrl(_text.text.trim());

  void _typed() {
    final r = parseRelayUrl(_text.text.trim());
    if (r != _typedRelay) setState(() => _typedRelay = r);
  }

  /// The saved club code is shown while the address is its server's.
  bool get _showClub => _clubRelay != null && !_clubRemoved && _typedRelay == _clubRelay;

  @override
  void dispose() {
    _text.dispose();
    _club.dispose();
    super.dispose();
  }

  /// Applies the club code field to [relay] if it is the code's server.
  void _applyClub(Uri relay) {
    if (_clubRelay == null || relay != _clubRelay) return;
    widget.settings.setClubCode(relay, _clubRemoved ? null : _club.text);
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
    _applyClub(relay);
    Navigator.of(context).pop(relay);
  }

  void _useDefault() {
    widget.settings.reset();
    if (widget.defaultRelay case final d?) _applyClub(d);
    Navigator.of(context).pop(widget.defaultRelay);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final fallback = widget.defaultRelay;
    final typed = _typedRelay;
    final kind = typed == null ? null : serverKindOf(typed);
    return AlertDialog(
      title: Text(l10n.relayAddressLabel),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
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
            if (kind != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(kind == ServerKind.lan ? Icons.wifi : Icons.public,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(serverKindText(l10n, kind),
                        key: const Key('relay-dialog-kind'), style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
            if (_showClub) ...[
              const SizedBox(height: 16),
              // KLD-112/113: only when a code is saved for this server; never
              // part of room links or QR codes.
              TextField(
                key: const Key('relay-dialog-club'),
                controller: _club,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.relayClubCodeLabel,
                  helperText: l10n.relayClubCodeHelper,
                  helperMaxLines: 3,
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: IconButton(
                    key: const Key('relay-dialog-club-remove'),
                    tooltip: l10n.serverClubCodeRemove,
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _clubRemoved = true),
                  ),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _save(),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ServerHelpLink(key: const Key('relay-dialog-help')),
            ),
          ],
        ),
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

/// "Wie geht das?" (KLD-113): opens the help screen.
class ServerHelpLink extends StatelessWidget {
  const ServerHelpLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
        icon: const Icon(Icons.help_outline, size: 18),
        label: Text(AppLocalizations.of(context).serverHelpLink),
        onPressed: () => openHelpScreen(context),
      );
}

/// The club code, asked for only when a server needs one (KLD-113): shown
/// under the refusal "Dieser Server braucht einen Clubcode …" (or "… kennt
/// den Clubcode nicht …") with the field right there and "Mit Clubcode
/// versuchen". The code is saved for [relay] in [settings] (KLD-112: sent
/// only to that server, never in room links or QR codes), then [onRetry]
/// starts or joins again. Keys: `<id>`, `<id>-field`, `<id>-retry`.
class ClubCodePrompt extends StatefulWidget {
  final String id;
  final RelaySettings settings;
  final Uri relay;
  final VoidCallback onRetry;
  final bool enabled;

  const ClubCodePrompt({
    super.key,
    required this.id,
    required this.settings,
    required this.relay,
    required this.onRetry,
    this.enabled = true,
  });

  @override
  State<ClubCodePrompt> createState() => _ClubCodePromptState();
}

class _ClubCodePromptState extends State<ClubCodePrompt> {
  late final TextEditingController _code = TextEditingController(text: widget.settings.clubCodeFor(widget.relay) ?? '');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _retry() async {
    if (_code.text.trim().isEmpty) return;
    await widget.settings.setClubCode(widget.relay, _code.text);
    if (mounted) widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: Key(widget.id),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: Key('${widget.id}-field'),
            controller: _code,
            enabled: widget.enabled,
            autofocus: true,
            textDirection: TextDirection.ltr,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.relayClubCodeLabel,
              helperText: l10n.relayClubCodeHelper,
              helperMaxLines: 3,
              prefixIcon: const Icon(Icons.key_outlined),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _retry(),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              const ServerHelpLink(),
              FilledButton.icon(
                key: Key('${widget.id}-retry'),
                onPressed: widget.enabled ? _retry : null,
                icon: const Icon(Icons.key_outlined),
                label: Text(l10n.serverClubCodeRetry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/guest_web.dart' show normalizeRoomCode;

import '../../net/room_link.dart';
import '../../profile/relay_settings.dart';
import '../../transport/network_transport.dart';
import '../ltr.dart';
import 'relay_errors.dart';
import 'relay_line.dart';

/// Joins room [code] on the relay at [relay] (`ws://host:port/relay`).
typedef RelayJoinTransportFactory = Future<NetworkTransport> Function(Uri relay, String code, {required String name});

/// The real thing: `NetworkTransport.joinRelay`.
Future<NetworkTransport> platformRelayJoin(Uri relay, String code, {required String name}) =>
    NetworkTransport.joinRelay(relay, code, name: name);

/// "Mit Raumcode beitreten" (KLD-057b): a room-code field, a join button,
/// progress with cancel and friendly relay errors. The relay is the shared
/// [settings] (shown and changed by the [RelayLine] above it; in the browser
/// [defaultRelay], the page's own server, until another one is chosen; with
/// none at all, joining asks for one). Used by the web join screen and the
/// app's join tab. Calls [onConnected] with the joined transport.
class RoomCodeJoin extends StatefulWidget {
  final RelayJoinTransportFactory joinTransport;
  final Duration joinTimeout;

  /// The relay used while [settings] has none: the page's own server in the
  /// browser, null natively.
  final Uri? defaultRelay;

  /// The shared relay setting (also used by "Spiel hosten").
  final RelaySettings settings;

  /// Prefills the code (`?room=`).
  final String? initialCode;

  /// Joins [initialCode] right away, after [ready] completes (the first-run
  /// name dialog).
  final bool autoConnect;
  final Future<void>? ready;

  /// The player name to send.
  final String Function() playerName;
  final void Function(NetworkTransport transport) onConnected;

  const RoomCodeJoin({
    super.key,
    required this.joinTransport,
    required this.playerName,
    required this.onConnected,
    this.joinTimeout = const Duration(seconds: 12),
    required this.settings,
    this.defaultRelay,
    this.initialCode,
    this.autoConnect = false,
    this.ready,
  });

  @override
  State<RoomCodeJoin> createState() => RoomCodeJoinState();
}

class RoomCodeJoinState extends State<RoomCodeJoin> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode ?? '');
  String? _codeError;

  /// The grouped code being joined (null: idle).
  String? _joining;
  String? _error;
  bool _showStartHint = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect && (widget.initialCode ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await widget.ready;
        if (mounted) _join();
      });
    }
  }

  @override
  void dispose() {
    _attempt++; // a join still in flight is closed when it completes
    _code.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    final code = normalizeRoomCode(_code.text);
    setState(() => _codeError = code == null ? l10n.relayCodeInvalid : null);
    if (code == null) return;
    final relay = await relayOrAsk(context, widget.settings, defaultRelay: widget.defaultRelay);
    if (relay == null || !mounted) return;
    _connect(code, relay);
  }

  Future<void> _connect(String code, Uri relay) async {
    if (_joining != null) return;
    final attempt = ++_attempt;
    setState(() {
      _joining = formatRoomCode(code);
      _error = null;
      _showStartHint = false;
    });
    NetworkTransport? transport;
    Object? failure;
    final pending = widget.joinTransport(relay, code, name: widget.playerName());
    try {
      transport = await pending.timeout(widget.joinTimeout);
    } on TimeoutException catch (e) {
      failure = e;
      pending.then((t) => t.close(), onError: (Object _) {}); // a late success must not leak
    } catch (e) {
      failure = e;
    }
    if (attempt != _attempt || !mounted) {
      transport?.close();
      return;
    }
    if (transport == null) {
      final l10n = AppLocalizations.of(context);
      final friendly = relayErrorText(context, failure!, code: code, relay: relay);
      setState(() {
        _joining = null;
        _error =
            friendly ??
            l10n.pairingJoinFailed(
              bidiLtr(context, formatRoomCode(code)),
              failure is TimeoutException ? l10n.pairingTimeout : '$failure',
            );
        _showStartHint = classifyRelayError(failure!) == RelayFailure.unreachable;
      });
      return;
    }
    _attempt++;
    setState(() => _joining = null);
    widget.onConnected(transport);
  }

  /// Joins room [code] on [relay] as if typed (a scanned QR code,
  /// KLD-052): fills the code, makes [relay] the shared relay setting (so it
  /// stays for hosting and the next code), and connects.
  void joinScanned(String code, Uri relay) {
    if (_joining != null) return;
    _code.text = formatRoomCode(code);
    if (relay == widget.defaultRelay) {
      widget.settings.reset();
    } else {
      widget.settings.set(relay);
    }
    setState(() => _codeError = null);
    _connect(code, relay);
  }

  void _cancel() {
    _attempt++;
    setState(() => _joining = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final busy = _joining != null;
    return Column(
      key: const Key('room-join'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.relayJoinTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.relayJoinIntro, key: const Key('room-join-intro'), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        TextField(
          key: const Key('room-code'),
          controller: _code,
          enabled: !busy,
          textDirection: TextDirection.ltr,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 \-]')),
            LengthLimitingTextInputFormatter(9),
            // Codes are shown in capitals; a hardware keyboard ignores
            // textCapitalization.
            TextInputFormatter.withFunction((_, v) => v.copyWith(text: v.text.toUpperCase())),
          ],
          style: theme.textTheme.titleLarge?.copyWith(
            letterSpacing: 2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            labelText: l10n.relayRoomCode,
            hintText: 'K7Q 2M',
            helperText: l10n.relayCodeHelper,
            helperMaxLines: 2,
            errorText: _codeError,
            errorMaxLines: 3,
            border: const OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => _join(),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('room-join-button'),
          onPressed: busy ? null : _join,
          icon: const Icon(Icons.meeting_room_outlined),
          label: Text(l10n.relayJoin),
        ),
        if (busy) ...[
          const SizedBox(height: 16),
          Row(
            key: const Key('room-progress'),
            children: [
              const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(child: Text(l10n.relayJoining(bidiLtr(context, _joining!)))),
              TextButton(onPressed: _cancel, child: Text(l10n.pairingCancel)),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(
            _error!,
            key: const Key('room-error'),
            style: TextStyle(color: theme.colorScheme.error),
          ),
          if (_showStartHint) RelayStartHint(key: const Key('room-start-hint')),
        ],
      ],
    );
  }
}

/// "Browser gegen Browser braucht ein Relay …" plus the start command
/// (left-to-right, selectable).
class RelayStartHint extends StatelessWidget {
  const RelayStartHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppLocalizations.of(context).relayStartHint),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest,
            child: SelectableText(
              relayStartCommand,
              key: const Key('relay-start-command'),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

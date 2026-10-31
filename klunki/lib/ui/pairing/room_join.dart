import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_net/guest_web.dart' show normalizeRoomCode, parseRelayUrl;

import '../../net/room_link.dart';
import '../../transport/network_transport.dart';
import '../ltr.dart';
import 'relay_errors.dart';

/// Joins room [code] on the relay at [relay] (`ws://host:port/relay`).
typedef RelayJoinTransportFactory = Future<NetworkTransport> Function(Uri relay, String code, {required String name});

/// The real thing: `NetworkTransport.joinRelay`.
Future<NetworkTransport> platformRelayJoin(Uri relay, String code, {required String name}) =>
    NetworkTransport.joinRelay(relay, code, name: name);

/// "Mit Raumcode beitreten" (KLD-057b): a room-code field, the relay address
/// (in the browser the page's own server, behind "Erweitert"; natively a
/// visible field, since an app has no page origin), a join button, progress
/// with cancel and friendly relay errors. Used by the web join screen and
/// the app's join tab. Calls [onConnected] with the joined transport.
class RoomCodeJoin extends StatefulWidget {
  final RelayJoinTransportFactory joinTransport;
  final Duration joinTimeout;

  /// The relay to use when the address field is left as it is: the page's
  /// own server in the browser, null natively (then the field is required).
  final Uri? defaultRelay;

  /// Prefills the code (`?room=`).
  final String? initialCode;

  /// Prefills the relay address (`?room=…&relay=…`).
  final Uri? initialRelay;

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
    this.defaultRelay,
    this.initialCode,
    this.initialRelay,
    this.autoConnect = false,
    this.ready,
  });

  @override
  State<RoomCodeJoin> createState() => _RoomCodeJoinState();
}

class _RoomCodeJoinState extends State<RoomCodeJoin> {
  late final TextEditingController _code = TextEditingController(text: widget.initialCode ?? '');
  late final TextEditingController _relay = TextEditingController(
    text: switch (widget.initialRelay ?? widget.defaultRelay) {
      final r? => relayAddressLabel(r),
      null => '',
    },
  );
  String? _codeError;
  String? _relayError;

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
    _relay.dispose();
    super.dispose();
  }

  /// The relay address the field stands for; null if invalid.
  Uri? _relayUri() {
    final text = _relay.text.trim();
    final fallback = widget.defaultRelay;
    if (fallback != null && (text.isEmpty || text == relayAddressLabel(fallback))) return fallback;
    return parseRelayUrl(text);
  }

  void _join() {
    final l10n = AppLocalizations.of(context);
    final code = normalizeRoomCode(_code.text);
    final relay = _relayUri();
    setState(() {
      _codeError = code == null ? l10n.relayCodeInvalid : null;
      _relayError = relay == null ? l10n.relayAddressInvalid : null;
    });
    if (code == null || relay == null) return;
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

  void _cancel() {
    _attempt++;
    setState(() => _joining = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final busy = _joining != null;
    final relayField = TextField(
      key: const Key('room-relay'),
      controller: _relay,
      enabled: !busy,
      keyboardType: TextInputType.url,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: l10n.relayAddressLabel,
        hintText: '192.168.1.20:4749',
        helperText: l10n.relayAddressHelper,
        helperMaxLines: 3,
        errorText: _relayError,
        errorMaxLines: 3,
        border: const OutlineInputBorder(),
      ),
      onSubmitted: (_) => _join(),
    );
    return Column(
      key: const Key('room-join'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.relayJoinTitle, style: theme.textTheme.titleMedium),
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
        if (widget.defaultRelay == null)
          relayField
        else
          ExpansionTile(
            key: const Key('room-advanced'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            initiallyExpanded: widget.initialRelay != null && widget.initialRelay != widget.defaultRelay,
            title: Text(l10n.relayAddressAdvanced, style: theme.textTheme.bodyMedium),
            children: [const SizedBox(height: 4), relayField],
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

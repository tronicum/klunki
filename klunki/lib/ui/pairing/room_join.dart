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

/// The real thing: `NetworkTransport.joinRelay`, with the club code saved
/// for [relay] (KLD-112; the app's shared relay setting; a relay from a link
/// gets none unless it is the saved one).
Future<NetworkTransport> platformRelayJoin(Uri relay, String code, {required String name}) =>
    NetworkTransport.joinRelay(relay, code, name: name, clubCode: RelaySettings.shared().clubCodeFor(relay));

/// The room-code join (KLD-057b; KLD-098: "Raumcode eintippen" on "Raum
/// beitreten"): a room-code field, a join button,
/// progress with cancel and friendly relay errors. The relay is the shared
/// [settings] (shown and changed by the [RelayLine] above it; in the browser
/// [defaultRelay], the page's own server, until another one is chosen; with
/// none at all, joining asks for one). Used by the web join screen and the
/// app's join tab. Calls [onConnected] with the joined transport.
///
/// A relay named by a link ([linkRelay], `?room=…&relay=…`) or a scanned
/// room QR code ([RoomCodeJoinState.joinScanned]) is used for that join only
/// (KLD-075): it is shown as "Relay aus Link: …" with "Als Standard
/// speichern", and the saved setting changes only when the player taps that.
/// In the browser a link to a relay other than the page's own server
/// ([defaultRelay]) gets a warning and does not join on its own.
class RoomCodeJoin extends StatefulWidget {
  final RelayJoinTransportFactory joinTransport;
  final Duration joinTimeout;

  /// The relay used while [settings] has none: the page's own server in the
  /// browser, null natively.
  final Uri? defaultRelay;

  /// The shared relay setting (also used by "Raum starten").
  final RelaySettings settings;

  /// Prefills the code (`?room=`).
  final String? initialCode;

  /// The relay of a `?room=` link (KLD-075): used for joining from this
  /// screen without changing [settings].
  final Uri? linkRelay;

  /// Joins [initialCode] right away, after [ready] completes (the first-run
  /// name dialog).
  final bool autoConnect;
  final Future<void>? ready;

  /// The player name to send.
  final String Function() playerName;
  final void Function(NetworkTransport transport) onConnected;

  /// The browser page (null natively): an `https:` page cannot reach a
  /// `ws://` relay (KLD-096), so such a join fails right away with a clear
  /// message.
  final Uri? pageUrl;

  const RoomCodeJoin({
    super.key,
    required this.joinTransport,
    required this.playerName,
    required this.onConnected,
    this.joinTimeout = const Duration(seconds: 12),
    required this.settings,
    this.defaultRelay,
    this.initialCode,
    this.linkRelay,
    this.autoConnect = false,
    this.ready,
    this.pageUrl,
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

  /// The relay of a link or scanned QR code, used instead of [settings]
  /// until the player saves it as the default or drops it (KLD-075).
  late Uri? _linkRelay = widget.linkRelay;

  /// The link's relay is not the page's own server (browser only): it could
  /// be a phishing or abuse relay, so the player is warned.
  bool get _foreignLink {
    final link = _linkRelay, page = widget.defaultRelay;
    return link != null && page != null && link != page;
  }

  /// The relay a join uses now: the link's, else the setting (or ask).
  Future<Uri?> _relay() async =>
      _linkRelay ?? await relayOrAsk(context, widget.settings, defaultRelay: widget.defaultRelay);

  @override
  void initState() {
    super.initState();
    // A link to a foreign relay waits for the player to read the warning.
    if (widget.autoConnect && !_foreignLink && (widget.initialCode ?? '').trim().isNotEmpty) {
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
    final relay = await _relay();
    if (relay == null || !mounted) return;
    _connect(code, relay);
  }

  Future<void> _connect(String code, Uri relay) async {
    if (_joining != null) return;
    if (browserBlocksWebSocket(pageUrl: widget.pageUrl, target: relay)) {
      setState(() {
        _error = AppLocalizations.of(context).webJoinHttpsWarning;
        _showStartHint = false;
      });
      return;
    }
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
      final friendly =
          versionMismatchText(context, failure!) ?? relayErrorText(context, failure, code: code, relay: relay);
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
  /// KLD-052): fills the code and connects through [relay] for this join
  /// only (KLD-075: the saved setting stays unless the player taps "Als
  /// Standard speichern").
  void joinScanned(String code, Uri relay) {
    if (_joining != null) return;
    _code.text = formatRoomCode(code);
    setState(() {
      _codeError = null;
      _linkRelay = relay;
    });
    _connect(code, relay);
  }

  /// "Als Standard speichern": the link's relay becomes the setting.
  void _saveLinkRelay() {
    final link = _linkRelay;
    if (link == null) return;
    if (link == widget.defaultRelay) {
      widget.settings.reset();
    } else {
      widget.settings.set(link);
    }
    setState(() => _linkRelay = null);
  }

  /// "Gespeichertes Relay verwenden": forget the link's relay.
  void _dropLinkRelay() => setState(() => _linkRelay = null);

  /// "Relay aus Link: …" with its two buttons (and the foreign-relay warning
  /// in the browser); nothing when the link names the relay in use anyway.
  Widget _linkRelayNotice(BuildContext context, bool busy) {
    return ValueListenableBuilder<Uri?>(
      valueListenable: widget.settings,
      builder: (context, _, _) {
        final link = _linkRelay;
        if (link == null || link == widget.settings.relayFor(widget.defaultRelay)) return const SizedBox.shrink();
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context);
        return Padding(
          key: const Key('room-link-relay'),
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.link, size: 20, color: _foreignLink ? theme.colorScheme.error : null),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.relayFromLink(bidiLtr(context, relayAddressLabel(link))),
                      key: const Key('room-link-relay-address'),
                    ),
                  ),
                ],
              ),
              if (_foreignLink)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.relayLinkForeign,
                    key: const Key('room-link-relay-foreign'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  TextButton(
                    key: const Key('room-link-relay-drop'),
                    onPressed: busy ? null : _dropLinkRelay,
                    child: Text(l10n.relayLinkUseSaved),
                  ),
                  TextButton(
                    key: const Key('room-link-relay-save'),
                    onPressed: busy ? null : _saveLinkRelay,
                    child: Text(l10n.relayLinkSaveDefault),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
        Text(l10n.roomTypeCode, key: const Key('room-join-title'), style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _linkRelayNotice(context, busy),
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
            helperText: l10n.roomCodeHelper,
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
          label: Text(l10n.roomJoin),
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

/// "Räume mit Raumcode brauchen ein Relay …" plus the start command
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

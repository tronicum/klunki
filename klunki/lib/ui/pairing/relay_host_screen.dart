import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../net/join_qr.dart';
import '../../net/room_link.dart';
import '../../profile/quartett_deck_settings.dart';
import '../../profile/relay_settings.dart';
import '../../transport/network_transport.dart';
import '../game_titles.dart';
import '../games/quartett_deck_picker.dart' show QuartettDeckChooser;
import '../ltr.dart';
import '../player_name_dialog.dart';
import '../shell/game_screen.dart' show newGameSeed;
import '../shell/screen_registry.dart' show networkGameSpecs;
import 'network_game_session.dart';
import 'refused_guest_notice.dart';
import 'relay_errors.dart';
import 'relay_line.dart';
import 'room_join.dart';

/// Hosts [config] through the relay at [relay] and completes once the relay
/// assigned a room code.
typedef RelayHostTransportFactory = Future<NetworkTransport> Function(
  GameConfig config,
  Uri relay, {
  required String name,
});

/// The real thing: `NetworkTransport.hostRelay`.
Future<NetworkTransport> platformRelayHost(GameConfig config, Uri relay, {required String name}) =>
    NetworkTransport.hostRelay(config, relay, name: name);

/// "Spiel hosten" through the relay (KLD-057b), the browser's way to host:
/// pick a game, open a room on the relay (the shared [relaySettings], shown
/// as "Relay: … · ändern"; [defaultRelay] = the page's own server until
/// another one is chosen), then wait with the room code (large,
/// grouped `K7Q 2M`), a QR code and the `?room=` link. When the guest
/// arrives the route is replaced by the same [NetworkGameSession] as in the
/// apps. A page not served by a relay gets the "how to start one" hint.
class RelayHostScreen extends StatefulWidget {
  final RelayHostTransportFactory hostTransport;

  /// The relay used while [relaySettings] has none (the page's own server);
  /// null natively.
  final Uri? defaultRelay;

  /// The shared relay setting (the same one as the room-code join); null:
  /// a private in-memory one.
  final RelaySettings? relaySettings;

  /// The remembered Quartett deck (KLD-069); null: a private in-memory one.
  final QuartettDeckSettings? deckSettings;

  /// The page URL, for the join link (`<page>/?room=CODE`).
  final Uri? pageUrl;

  /// Seed of the hosted game.
  final int Function() seed;

  /// Suggestion for the player name when none is saved.
  final String Function() deviceName;

  /// Overrides the app's player name controller (tests).
  final PlayerNameController? nameController;

  const RelayHostScreen({
    super.key,
    this.hostTransport = platformRelayHost,
    this.defaultRelay,
    this.relaySettings,
    this.deckSettings,
    this.pageUrl,
    this.seed = newGameSeed,
    this.deviceName = _browser,
    this.nameController,
  });

  static String _browser() => 'Browser';

  @override
  State<RelayHostScreen> createState() => _RelayHostScreenState();
}

class _RelayHostScreenState extends State<RelayHostScreen> with PlayerNameField {
  String _gameId = networkGameSpecs.first.id;
  late final QuartettDeckSettings _deckSettings = widget.deckSettings ?? QuartettDeckSettings.memory();
  late String _deck = _deckSettings.value;

  /// The deck to host with (KLD-069): only for Quartett.
  String? get _hostDeck => specById(_gameId)?.usesDeck == true ? _deck : null;
  late final RelaySettings _settings = widget.relaySettings ?? RelaySettings.memory();
  bool _starting = false;
  String? _error;
  bool _showStartHint = false;

  NetworkTransport? _transport;
  Uri? _relayUsed;
  bool _handedOver = false;

  @override
  PlayerNameController? get explicitNameController => widget.nameController;

  @override
  String playerNameSuggestion() => widget.deviceName();

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  void _teardown() {
    final t = _transport;
    _transport = null;
    t?.changes.removeListener(_onChange);
    if (t != null && !_handedOver) t.close();
  }

  Future<void> _start() async {
    final l10n = AppLocalizations.of(context);
    final relay = await relayOrAsk(context, _settings, defaultRelay: widget.defaultRelay);
    if (relay == null || !mounted) return;
    setState(() {
      _starting = true;
      _error = null;
      _showStartHint = false;
    });
    final config = GameConfig(_gameId, seed: widget.seed(), deck: _hostDeck);
    NetworkTransport transport;
    try {
      transport = await widget.hostTransport(config, relay, name: playerName);
    } catch (e) {
      if (mounted) {
        final failure = classifyRelayError(e);
        setState(() {
          _starting = false;
          _error = relayErrorText(context, e, relay: relay) ?? l10n.pairingHostStartFailed('$e');
          _showStartHint = failure == RelayFailure.unreachable;
        });
      }
      return;
    }
    if (!mounted) {
      transport.close();
      return;
    }
    setState(() {
      _transport = transport;
      _relayUsed = relay;
      _starting = false;
    });
    transport.changes.addListener(_onChange);
    _onChange(); // the guest may already be there
  }

  void _onChange() {
    final t = _transport;
    if (t == null || _handedOver || !mounted) return;
    final lost = t.roomLost;
    if (lost != null) {
      final text = relayErrorText(context, lost, relay: _relayUsed);
      _teardown();
      setState(() => _error = text ?? lost);
      return;
    }
    if (t.connection.value != NetConnectionState.connected) return;
    _handedOver = true;
    _teardown();
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => NetworkGameSession(transport: t)));
  }

  void _cancel() {
    _teardown();
    setState(() {});
  }

  Future<void> _copyLink(String link) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final copied = AppLocalizations.of(context).pairingLinkCopied;
    await Clipboard.setData(ClipboardData(text: link));
    messenger?.showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = _transport;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairingHostGame)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              key: const Key('relay-host'),
              padding: const EdgeInsets.all(16),
              children: [if (t == null) ..._setup(context) else ..._waiting(context, t)],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _setup(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return [
      playerNameField(key: const Key('relay-host-name'), enabled: !_starting),
      const SizedBox(height: 16),
      Text(l10n.pairingChooseGame, style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      RadioGroup<String>(
        groupValue: _gameId,
        onChanged: (v) {
          if (v != null && !_starting) setState(() => _gameId = v);
        },
        child: Column(
          children: [
            for (final spec in networkGameSpecs)
              RadioListTile<String>(
                key: Key('relay-game-${spec.id}'),
                value: spec.id,
                title: Text(localizedGameTitle(l10n, spec.id, fallback: spec.title)),
              ),
          ],
        ),
      ),
      if (_hostDeck != null) ...[
        const SizedBox(height: 8),
        Text(l10n.quartettDeckLabel, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        QuartettDeckChooser(
          key: const Key('relay-deck'),
          keyPrefix: 'relay-deck-',
          selected: _deck,
          enabled: !_starting,
          onChanged: (d) {
            setState(() => _deck = d);
            _deckSettings.set(d);
          },
        ),
      ],
      const SizedBox(height: 8),
      RelayLine(settings: _settings, defaultRelay: widget.defaultRelay, enabled: !_starting),
      const SizedBox(height: 8),
      FilledButton.icon(
        key: const Key('relay-host-start'),
        onPressed: _starting ? null : _start,
        icon: _starting
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.wifi_tethering),
        label: Text(l10n.pairingHostGame),
      ),
      const SizedBox(height: 8),
      Text(l10n.relayHostIntro, style: theme.textTheme.bodySmall),
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(
          _error!,
          key: const Key('relay-host-error'),
          style: TextStyle(color: theme.colorScheme.error),
        ),
        if (_showStartHint) const RelayStartHint(key: Key('relay-host-start-hint')),
      ],
    ];
  }

  static bool _isWebPage(Uri? page) => page != null && (page.scheme == 'http' || page.scheme == 'https');

  List<Widget> _waiting(BuildContext context, NetworkTransport t) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final code = t.roomCode ?? '';
    final relay = t.relayUrl ?? _relayUsed!;
    final link = roomJoinLink(code: code, relay: relay, pageUrl: widget.pageUrl).toString();
    final loopback = loopbackHostOf(relay: relay, pageUrl: widget.pageUrl);
    final title = localizedGameTitle(l10n, _gameId, fallback: specById(_gameId)?.title ?? _gameId);
    return [
      Column(
        key: const Key('relay-host-waiting'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pairingHosting(bidiName(context, t.localName), title),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(l10n.relayRoomCode, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Center(
            child: Text(
              formatRoomCode(code),
              key: const Key('relay-room-code'),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: theme.colorScheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: KlunkiQrCode(key: const Key('relay-qr'), data: link, size: 180, semanticLabel: link),
          ),
          const SizedBox(height: 8),
          ListTile(
            dense: true,
            leading: const Icon(Icons.link),
            title: SelectableText(
              link,
              key: const Key('relay-link'),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
            ),
            trailing: IconButton(
              key: const Key('relay-link-copy'),
              icon: const Icon(Icons.copy),
              tooltip: l10n.pairingCopyLink,
              onPressed: () => _copyLink(link),
            ),
          ),
          if (loopback != null)
            LoopbackHint(
              key: const Key('relay-host-loopback'),
              host: loopback,
              // Natively there is no page to reopen: just the short warning.
              short: !_isWebPage(widget.pageUrl),
            ),
          Text(l10n.relayWaitingHint, key: const Key('relay-host-hint'), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            l10n.relayInfo(bidiLtr(context, relayAddressLabel(relay))),
            key: const Key('relay-host-relay'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Flexible(child: Text(l10n.pairingWaitingForGuest, key: const Key('relay-host-status'))),
            ],
          ),
          RefusedGuestNotice(transport: t),
          const SizedBox(height: 16),
          OutlinedButton(key: const Key('relay-host-cancel'), onPressed: _cancel, child: Text(l10n.pairingCancel)),
        ],
      ),
    ];
  }
}

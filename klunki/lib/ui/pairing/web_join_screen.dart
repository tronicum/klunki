import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' show Player;
import 'package:klunki_net/guest_web.dart' show relayUriForPage;

import '../../net/join_payload.dart';
import '../../net/room_link.dart';
import '../../net/web_join_target.dart';
import '../../profile/quartett_deck_settings.dart';
import '../../profile/relay_settings.dart';
import '../../transport/network_transport.dart';
import '../game_titles.dart';
import '../ltr.dart';
import '../player_name_dialog.dart';
import '../shell/game_screen.dart' show newGameSeed;
import 'network_game_session.dart';
import 'relay_host_screen.dart';
import 'relay_errors.dart';
import 'relay_line.dart';
import 'room_join.dart';

/// Joins the host's WebSocket endpoint [url] (`ws://host:port`).
typedef WebJoinTransportFactory = Future<NetworkTransport> Function(Uri url, {required String name});

/// Default player name suggestion of a browser guest (what the host shows
/// until the player picks a name).
const String webDefaultDeviceName = 'Browser';

/// Everything the web join screen talks to, injectable for tests.
class WebJoinDeps {
  final WebJoinTransportFactory joinTransport;

  /// Room-code join through the relay (KLD-057b).
  final RelayJoinTransportFactory relayJoin;

  /// "Raum starten" through the relay (KLD-057b, see [webRoomStartScreen]).
  final RelayHostTransportFactory relayHost;

  /// Seed of a game in a relay room.
  final int Function() seed;

  /// Suggestion for the player name when none is saved; null: the regional
  /// default name ("Ben" when joining, "Anna" when starting a room, KLD-103).
  final String Function()? deviceName;

  /// Upper bound for a join attempt (also covers a WebSocket that never
  /// opens, e.g. a host on another network).
  final Duration joinTimeout;

  /// The relay setting shared by "Raum starten" and the room-code join.
  final RelaySettings Function() relaySettings;

  const WebJoinDeps({
    required this.joinTransport,
    this.relayJoin = platformRelayJoin,
    this.relayHost = platformRelayHost,
    this.seed = newGameSeed,
    this.deviceName,
    this.joinTimeout = const Duration(seconds: 12),
    this.relaySettings = RelaySettings.memory,
  });

  /// The real thing: `NetworkTransport.joinWebSocket`.
  factory WebJoinDeps.platform() =>
      WebJoinDeps(
        joinTransport: (url, {required name}) => NetworkTransport.joinWebSocket(url, name: name),
        relaySettings: RelaySettings.shared,
      );
}

/// "Raum starten" in the browser (KLD-057b, KLD-098): the relay room screen
/// with this page's relay ([pageUrl]'s own server) and [deps]' factories.
/// [gameId] (KLD-105, a game tile's "Mit anderen"): this game, no choice.
Widget webRoomStartScreen({Uri? pageUrl, WebJoinDeps? deps, PlayerNameController? nameController, String? gameId}) {
  final d = deps ?? WebJoinDeps.platform();
  return RelayHostScreen(
    hostTransport: d.relayHost,
    defaultRelay: pageUrl == null ? null : relayUriForPage(pageUrl),
    relaySettings: d.relaySettings(),
    deckSettings: QuartettDeckSettings.shared(),
    pageUrl: pageUrl,
    seed: d.seed,
    deviceName: d.deviceName,
    nameController: nameController,
    initialGameId: gameId,
    fixedGame: gameId != null,
  );
}

/// "Raum beitreten" in the browser (KLD-055, KLD-057b, KLD-098): the room
/// code field first (a page has no camera scanner and cannot browse mDNS);
/// under "Erweitert" the relay address and the direct connection to a device
/// a room runs on (its address or `klunki://` link, see [WebJoinTarget] for
/// the accepted forms). Also reached directly through `?join=<link>` in the
/// page URL ([initialInput] + [autoConnect], "Erweitert" then starts open)
/// and `?room=CODE` ([initialRoom]). Once connected the route is replaced by
/// the same [NetworkGameSession] the apps use.
///
/// The player name ("Dein Name", KLD-056) is the app's
/// [PlayerNameController] ([nameController] or the [PlayerNameScope]); the
/// first visit without a saved name asks for it once, before an automatic
/// `?join=` connect.
class WebJoinScreen extends StatefulWidget {
  final WebJoinDeps deps;

  /// Prefills the address field (e.g. the `?join=` parameter).
  final String? initialInput;

  /// Connects to [initialInput] right away.
  final bool autoConnect;

  /// A `?room=` link (KLD-057b): prefills the room code (and relay) and joins
  /// right away if the code is valid.
  final RoomLink? initialRoom;

  /// The page URL; an `https:` page gets a warning (browsers block `ws://`
  /// from https pages).
  final Uri? pageUrl;

  /// Overrides the app's player name controller (tests).
  final PlayerNameController? nameController;

  WebJoinScreen({
    super.key,
    WebJoinDeps? deps,
    this.initialInput,
    this.autoConnect = false,
    this.initialRoom,
    this.pageUrl,
    this.nameController,
  }) : deps = deps ?? WebJoinDeps.platform();

  @override
  State<WebJoinScreen> createState() => _WebJoinScreenState();
}

class _WebJoinScreenState extends State<WebJoinScreen> with PlayerNameField {
  late final TextEditingController _address = TextEditingController(text: widget.initialInput ?? '');
  late final RelaySettings _relaySettings = widget.deps.relaySettings();
  String? _addressError;

  /// The host being connected to (null: idle).
  String? _connecting;
  String? _error;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoConnect && (widget.initialInput ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await playerNameReady; // the first-run name dialog comes first
        if (mounted) _connectTyped();
      });
    }
  }

  @override
  PlayerNameController? get explicitNameController => widget.nameController;

  @override
  String playerNameSuggestion() =>
      widget.deps.deviceName?.call() ?? defaultPlayerName(AppLocalizations.of(context), Player.b);

  @override
  void dispose() {
    _attempt++; // a join still in flight is closed when it completes
    _address.dispose();
    super.dispose();
  }

  String get _deviceName => playerName;

  void _connectTyped() {
    final target = WebJoinTarget.tryParse(_address.text);
    if (target == null) {
      setState(() => _addressError = AppLocalizations.of(context).webJoinInvalidAddress);
      return;
    }
    setState(() => _addressError = null);
    _connect(target);
  }

  Future<void> _connect(WebJoinTarget target) async {
    if (_connecting != null) return;
    final l10n = AppLocalizations.of(context);
    final attempt = ++_attempt;
    final label = target.label;
    if (browserBlocksWebSocket(pageUrl: widget.pageUrl, target: target.uri)) {
      // KLD-096: the browser would refuse ws:// from this https page.
      setState(() => _error = l10n.webJoinHttpsWarning);
      return;
    }
    setState(() {
      _connecting = label;
      _error = null;
    });
    NetworkTransport? transport;
    Object? failure;
    final pending = widget.deps.joinTransport(target.uri, name: _deviceName);
    try {
      transport = await pending.timeout(widget.deps.joinTimeout);
    } on TimeoutException {
      failure = l10n.pairingTimeout;
      // A late success must not leak a session.
      pending.then((t) => t.close(), onError: (Object _) {});
    } catch (e) {
      failure = e;
    }
    if (attempt != _attempt || !mounted) {
      transport?.close();
      return;
    }
    if (transport == null) {
      setState(() {
        _connecting = null;
        // KLD-085: another build: say which device to update, no network hints.
        _error = (failure == null ? null : versionMismatchText(context, failure)) ??
            (failure != null && isSeatTaken(failure)
                ? l10n.pairingSeatTaken
                : '${l10n.pairingJoinFailed(bidiLtr(context, label), '$failure')}\n${l10n.webJoinHints}');
      });
      return;
    }
    _openGame(transport);
  }

  void _openGame(NetworkTransport transport) {
    _attempt++;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => NetworkGameSession(transport: transport)));
  }

  /// The relay of this page: its own server (null natively / in tests
  /// without a page URL).
  Uri? get _pageRelay => switch (widget.pageUrl) {
    final p? => relayUriForPage(p),
    null => null,
  };

  void _cancelConnect() {
    _attempt++;
    setState(() => _connecting = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final busy = _connecting != null;
    final https = widget.pageUrl?.scheme == 'https';
    final target = WebJoinTarget.tryParse(_address.text);
    final game = target?.gameId;
    final directFirst = (widget.initialInput ?? '').trim().isNotEmpty;
    // The room code through the relay (KLD-057b): what everybody uses.
    final room = RoomCodeJoin(
        joinTransport: widget.deps.relayJoin,
        joinTimeout: widget.deps.joinTimeout,
        defaultRelay: _pageRelay,
        settings: _relaySettings,
        initialCode: widget.initialRoom?.code ?? widget.initialRoom?.raw,
        // A `?room=` link names its relay (`&relay=`, else this page): used
        // for this join only, never saved silently (KLD-075).
        linkRelay: switch (widget.initialRoom) {
          null => null,
          final room => room.relay ?? _pageRelay,
        },
        autoConnect: widget.initialRoom?.code != null,
        ready: playerNameReady,
        playerName: () => _deviceName,
        onConnected: _openGame,
        pageUrl: widget.pageUrl,
      );
    // KLD-098: the technical part ("Erweitert"): the relay and a device a
    // room runs on directly.
    final direct = <Widget>[
      Text(l10n.joinDirectTitle, key: const Key('web-join-direct-title'), style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(l10n.joinDirectHelper, key: const Key('web-join-direct-helper'), style: theme.textTheme.bodySmall),
      const SizedBox(height: 16),
      TextField(
        key: const Key('web-join-address'),
        controller: _address,
        enabled: !busy,
        keyboardType: TextInputType.url,
        textDirection: TextDirection.ltr,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: l10n.webJoinAddressLabel,
          hintText: '192.168.1.20',
          helperText: l10n.webJoinAddressHelper(klunkiDefaultWebSocketPort),
          helperMaxLines: 3,
          errorText: _addressError,
          errorMaxLines: 3,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _connectTyped(),
      ),
      if (target != null) ...[
        const SizedBox(height: 4),
        Text(
          [
            if (target.name != null) bidiName(context, target.name!),
            if (game != null) localizedGameTitle(l10n, game, fallback: game),
            bidiLtr(context, target.uri.toString()),
          ].join(' · '),
          key: const Key('web-join-target'),
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 8),
      FilledButton(
        key: const Key('web-join-connect'),
        onPressed: busy ? null : _connectTyped,
        child: Text(l10n.pairingConnect),
      ),
      if (busy) ...[
        const SizedBox(height: 16),
        Row(
          key: const Key('web-join-progress'),
          children: [
            const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.pairingConnecting(bidiLtr(context, _connecting!)))),
            TextButton(onPressed: _cancelConnect, child: Text(l10n.pairingCancel)),
          ],
        ),
      ],
      if (_error != null) ...[
        const SizedBox(height: 16),
        Text(
          _error!,
          key: const Key('web-join-error'),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ],
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.roomJoin)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            // Not a lazy ListView: the room-code join keeps its state (and
            // its `?room=` auto-join runs once) while scrolled out of view.
            child: SingleChildScrollView(
              key: const Key('web-join'),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (https) ...[
                    Text(
                      l10n.webJoinHttpsWarning,
                      key: const Key('web-join-https'),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                  ],
                  playerNameField(
                    key: const Key('web-join-name'),
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  room,
                  const SizedBox(height: 16),
                  // `?join=` opens "Erweitert" right away (the direct join's
                  // progress and error are in there).
                  RoomAdvanced(
                    id: 'web-join-advanced',
                    initiallyExpanded: directFirst,
                    children: [
                      RelayLine(settings: _relaySettings, defaultRelay: _pageRelay, enabled: !busy),
                      const Divider(height: 32),
                      ...direct,
                    ],
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

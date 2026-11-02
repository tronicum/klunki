import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../app/test_mode.dart';
import '../../net/discovery.dart';
import '../../net/discovery_factory.dart';
import '../../net/join_payload.dart';
import '../../net/join_qr.dart';
import '../../net/local_ip.dart';
import '../../net/scanned_join_code.dart';
import '../../profile/quartett_deck_settings.dart';
import '../../profile/relay_settings.dart';
import '../../profile/room_settings.dart';
import '../../transport/network_transport.dart';
import '../game_titles.dart';
import '../ltr.dart';
import '../player_name_dialog.dart';
import '../shell/game_screen.dart' show newGameSeed;
import '../shell/screen_registry.dart' show networkGameSpecs;
import '../games/chess/chess_color_picker.dart';
import '../games/chess/chess_pieces.dart' show chessYouPlay;
import '../games/quartett_deck_picker.dart' show QuartettDeckChooser;
import '../games/wordtiles/wordtiles_options.dart';
import 'network_game_session.dart';
import 'qr_scan_screen.dart';
import 'qr_scanner_mobile.dart';
import 'relay_host_screen.dart';
import 'refused_guest_notice.dart';
import 'relay_errors.dart';
import 'relay_line.dart';
import 'room_game_choice.dart';
import 'room_join.dart';
import 'web_join_screen.dart';

/// Starts a host session for [config] on TCP [port] and WebSocket [wsPort]
/// (browser guests, KLD-055); 0 = any free port.
typedef HostTransportFactory = Future<NetworkTransport> Function(GameConfig config,
    {required String name, required int port, required int wsPort});

/// Joins the host at [host]:[port].
typedef JoinTransportFactory = Future<NetworkTransport> Function(String host, int port, {required String name});

/// Everything the pairing screen talks to, injectable for tests
/// (`FakeDiscovery`, loopback transports, fixed addresses).
class PairingDeps {
  /// Creates the discovery service (null: no mDNS, manual entry only). The
  /// screen owns and disposes it.
  final DiscoveryService? Function() discovery;
  final HostTransportFactory hostTransport;
  final JoinTransportFactory joinTransport;

  /// Joins a relay room by code (KLD-057b).
  final RelayJoinTransportFactory relayJoin;

  /// Opens a relay room ("Raum über ein Relay öffnen", KLD-098).
  final RelayHostTransportFactory relayHost;

  /// Whether "Raum starten" opens rooms through the relay (KLD-098).
  final RoomSettings Function() roomSettings;

  /// This device's LAN IPv4 addresses, best first.
  final Future<List<String>> Function() localAddresses;

  /// Suggestion for the player name ("Wie heißt du?") when none is saved;
  /// null (the app): the regional default name, "Anna" when starting a room,
  /// "Ben" when joining one (KLD-103).
  final String Function()? deviceName;

  /// Seed for a hosted game.
  final int Function() seed;

  /// Port tried first; if it is busy the host falls back to port 0.
  final int preferredPort;

  /// WebSocket port (browser guests) tried first; falls back to 0 likewise.
  final int preferredWsPort;

  /// Upper bound for a join attempt (the transport has its own handshake
  /// timeout; this also covers a hanging connect).
  final Duration joinTimeout;

  /// The camera for "QR-Code scannen" in the join tab (KLD-052); null hides
  /// the button.
  final QrScannerFactory? qrScanner;

  /// The relay setting of the room-code join and of relay rooms (one relay
  /// for everything).
  final RelaySettings Function() relaySettings;

  /// The remembered Quartett deck (KLD-069), preselected when a Quartett
  /// room is started.
  final QuartettDeckSettings Function() quartettDecks;

  const PairingDeps({
    required this.discovery,
    required this.hostTransport,
    required this.joinTransport,
    this.relayJoin = platformRelayJoin,
    this.relayHost = platformRelayHost,
    this.roomSettings = RoomSettings.memory,
    required this.localAddresses,
    this.deviceName,
    this.seed = newGameSeed,
    this.preferredPort = klunkiDefaultPort,
    this.preferredWsPort = klunkiDefaultWebSocketPort,
    this.joinTimeout = const Duration(seconds: 12),
    this.qrScanner,
    this.relaySettings = RelaySettings.memory,
    this.quartettDecks = QuartettDeckSettings.memory,
  });

  /// The real thing: platform discovery, TCP on all interfaces.
  factory PairingDeps.platform() => PairingDeps(
        discovery: createDiscovery,
        hostTransport: (config, {required name, required port, required wsPort}) =>
            NetworkTransport.host(config, name: name, port: port, wsPort: wsPort),
        joinTransport: (host, port, {required name}) => NetworkTransport.join(host, port, name: name),
        localAddresses: localIPv4Addresses,
        // E2E test mode (--dart-define KLUNKI_E2E_*): fixed port and seed.
        seed: E2eMode.enabled ? () => E2eMode.seed : newGameSeed,
        preferredPort: E2eMode.enabled ? E2eMode.port : klunkiDefaultPort,
        qrScanner: MobileQrScanner.new,
        relaySettings: RelaySettings.shared,
        roomSettings: RoomSettings.shared,
        quartettDecks: QuartettDeckSettings.shared,
      );
}

/// Which side of "Mit anderen Geräten spielen" (KLD-098) a [PairingScreen]
/// shows: "Raum starten" or "Raum beitreten".
enum RoomMode { start, join }

/// The app's room screens (KLD-034, KLD-098): one mental model, "a room with
/// a code".
///
/// - [RoomMode.start] ("Raum starten"): name, game (and deck), start. By
///   default the room runs directly on this device (TCP + mDNS: devices on
///   the same Wi-Fi find it, the QR code joins it, no server needed). Under
///   "Erweitert" the player can switch to rooms through the relay (room code,
///   browsers can join; remembered in [RoomSettings]); then the route is
///   replaced by the [RelayHostScreen], which opens the room right away.
/// - [RoomMode.join] ("Raum beitreten"): the camera scanner first (opened
///   right away when the device has one, [scanFirst]), the room code field,
///   the rooms found nearby, and under "Erweitert" the relay address and a
///   typed IP address.
///
/// Once both sides are connected the route is replaced by a
/// [NetworkGameSession], so leaving the game goes straight back to the menu.
///
/// The player name ("Dein Name", KLD-056) is the app's [PlayerNameController]
/// ([nameController] or the [PlayerNameScope]); the first visit without a
/// saved name asks for it once.
class PairingScreen extends StatefulWidget {
  final PairingDeps deps;
  final RoomMode mode;

  /// "Raum beitreten" opens the scanner right away when there is a camera.
  final bool scanFirst;

  /// Overrides the app's player name controller (tests).
  final PlayerNameController? nameController;

  /// "Raum starten" for this game only (KLD-105: a game tile's "Mit
  /// anderen" link): shown instead of the game choice. Null: choose a game.
  final String? gameId;

  PairingScreen({
    super.key,
    PairingDeps? deps,
    this.mode = RoomMode.start,
    this.scanFirst = true,
    this.nameController,
    this.gameId,
  }) : deps = deps ?? PairingDeps.platform();

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with PlayerNameField {
  late final DiscoveryService? _discovery = widget.deps.discovery();

  @override
  PlayerNameController? get explicitNameController => widget.nameController;

  @override
  String playerNameSuggestion() =>
      widget.deps.deviceName?.call() ??
      defaultPlayerName(AppLocalizations.of(context), widget.mode == RoomMode.start ? Player.a : Player.b);

  @override
  void dispose() {
    _discovery?.dispose();
    super.dispose();
  }

  String get _deviceName => playerName;

  /// Replaces the pairing route by the game.
  void _openGame(NetworkTransport transport) {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => NetworkGameSession(transport: transport),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final start = widget.mode == RoomMode.start;
    // A page can neither listen nor browse mDNS (KLD-055): the web screens.
    if (kIsWeb) {
      return start
          ? webRoomStartScreen(pageUrl: Uri.base, nameController: widget.nameController, gameId: widget.gameId)
          : WebJoinScreen(pageUrl: Uri.base, nameController: widget.nameController);
    }
    return Scaffold(
      appBar: AppBar(title: Text(start ? l10n.roomStart : l10n.roomJoin)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                playerNameField(key: const Key('pair-name')),
                const SizedBox(height: 16),
                if (start)
                  _HostPanel(
                    key: const Key('pair-host-panel'),
                    deps: widget.deps,
                    discovery: _discovery,
                    deviceName: () => _deviceName,
                    nameController: widget.nameController,
                    gameId: widget.gameId,
                    onConnected: _openGame,
                  )
                else
                  _JoinPanel(
                    key: const Key('pair-join-panel'),
                    deps: widget.deps,
                    discovery: _discovery,
                    deviceName: () => _deviceName,
                    scanFirst: widget.scanFirst,
                    ready: playerNameReady,
                    onConnected: _openGame,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Raum starten (on this device, or handed over to the relay room screen)

class _HostPanel extends StatefulWidget {
  final PairingDeps deps;
  final DiscoveryService? discovery;
  final String Function() deviceName;
  final PlayerNameController? nameController;
  final String? gameId;
  final void Function(NetworkTransport) onConnected;

  const _HostPanel({
    super.key,
    required this.deps,
    required this.discovery,
    required this.deviceName,
    required this.nameController,
    required this.gameId,
    required this.onConnected,
  });

  @override
  State<_HostPanel> createState() => _HostPanelState();
}

class _HostPanelState extends State<_HostPanel> {
  late String _gameId = widget.gameId ?? networkGameSpecs.first.id;
  late final QuartettDeckSettings _deckSettings = widget.deps.quartettDecks();
  late String _deck = _deckSettings.value;
  late final RoomSettings _roomSettings = widget.deps.roomSettings();
  late final RelaySettings _relaySettings = widget.deps.relaySettings();

  /// The deck of the room (KLD-069): only for Quartett.
  String? get _hostDeck => specById(_gameId)?.usesDeck == true ? _deck : null;

  /// Wortgewandt's tile language and word list (KLD-094 step 6), chosen by
  /// the host; null until first shown (the default follows the app language).
  WordTilesOptions? _words;
  WordTilesOptions get _wordOptions => _words ??= defaultWordTilesOptions(Localizations.localeOf(context));

  /// The host's colour in chess (KLD-059 step 4a); random by default.
  ChessColorChoice _chessColor = defaultChessColorChoice;
  bool _starting = false;
  String? _error;

  NetworkTransport? _transport;
  bool _handedOver = false;
  String _name = '';
  List<String> _addresses = const [];
  int _qrIndex = 0;
  bool _advertised = false;
  String? _advertiseError;

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }

  /// Cancel / leave: stop advertising and close the session unless the game
  /// screen took it over.
  void _teardown() {
    final t = _transport;
    _transport = null;
    t?.connection.removeListener(_onConnection);
    if (_advertised) {
      _advertised = false;
      widget.discovery?.stopAdvertising();
    }
    if (t != null && !_handedOver) t.close();
  }

  /// "Raum starten": on this device, or (KLD-098, "Erweitert") through the
  /// relay: the relay room screen takes over with the chosen game and opens
  /// the room right away (its cancel stays there, with the game preselected).
  Future<void> _start() async {
    if (_roomSettings.value) {
      final deps = widget.deps;
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => RelayHostScreen(
          hostTransport: deps.relayHost,
          relaySettings: _relaySettings,
          deckSettings: _deckSettings,
          seed: deps.seed,
          deviceName: deps.deviceName,
          nameController: widget.nameController,
          initialGameId: _gameId,
          initialWordTiles: _gameId == 'wordtiles' ? _wordOptions : null,
          initialChessColor: _chessColor,
          fixedGame: widget.gameId != null,
          autoStart: true,
        ),
      ));
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    final deps = widget.deps;
    final words = _gameId == 'wordtiles' ? _wordOptions : null;
    // A game with "Wörterbuch prüfen" needs its list before the host creates it.
    if (words != null && words.dictionary && !await loadWordListWithProgress(context, words.tiles)) {
      if (mounted) setState(() => _starting = false);
      return;
    }
    if (!mounted) return;
    final seed = deps.seed();
    // Chess: "Zufällig" is decided here, from the seed; the config carries
    // the result to the guest (KLD-059 step 4a).
    final config = GameConfig(_gameId,
        seed: seed,
        deck: _hostDeck,
        tiles: words?.tiles,
        dictionary: words?.dictionary ?? false,
        chessWhite: _gameId == 'chess' ? _chessColor.whitePlayer(seed) : Player.a);
    final name = widget.deviceName();
    NetworkTransport transport;
    try {
      transport = await _bind(deps, config, name);
    } catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = AppLocalizations.of(context).roomStartFailed('$e');
        });
      }
      return;
    }
    if (!mounted) {
      transport.close();
      return;
    }
    final addresses = await deps.localAddresses();
    if (!mounted) {
      transport.close();
      return;
    }
    setState(() {
      _transport = transport;
      _name = name;
      _addresses = addresses;
      _qrIndex = 0;
      _starting = false;
    });
    transport.connection.addListener(_onConnection);

    final discovery = widget.discovery;
    if (discovery != null) {
      try {
        _advertised = true;
        await discovery.advertise(KlunkiHostInfo(
          name: name,
          host: '',
          port: transport.port!,
          protocol: klunkiProtocolVersion,
          gameId: _gameId,
          wsPort: transport.wsPort,
        ));
      } catch (e) {
        _advertised = false;
        if (mounted) setState(() => _advertiseError = AppLocalizations.of(context).pairingNotAdvertised);
      }
    } else if (mounted) {
      setState(() => _advertiseError = AppLocalizations.of(context).pairingNoDiscoveryHost);
    }
    _onConnection(); // the guest may already be there
  }

  /// Binds the preferred TCP and WebSocket ports; a busy one falls back to
  /// any free port (e.g. a second Klunki on this machine), keeping the other
  /// preferred port if it is free. Rethrows the last failure.
  static Future<NetworkTransport> _bind(PairingDeps deps, GameConfig config, String name) async {
    final p = deps.preferredPort, w = deps.preferredWsPort;
    final attempts = <(int, int)>{(p, w), (p, 0), (0, w), (0, 0)}.toList();
    for (var i = 0;; i++) {
      final (port, wsPort) = attempts[i];
      try {
        return await deps.hostTransport(config, name: name, port: port, wsPort: wsPort);
      } catch (_) {
        if (i == attempts.length - 1) rethrow;
      }
    }
  }

  void _onConnection() {
    final t = _transport;
    if (t == null || _handedOver || !mounted) return;
    if (t.connection.value != NetConnectionState.connected) return;
    _handedOver = true;
    _teardown();
    widget.onConnected(t);
  }

  void _cancel() {
    _teardown();
    setState(() {
      _addresses = const [];
      _advertiseError = null;
    });
  }

  Future<void> _copyLink(String link) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final copied = AppLocalizations.of(context).pairingLinkCopied;
    await Clipboard.setData(ClipboardData(text: link));
    messenger?.showSnackBar(SnackBar(content: Text(copied)));
  }

  @override
  Widget build(BuildContext context) {
    final t = _transport;
    return t == null ? _setup(context) : _waiting(context, t);
  }

  Widget _setup(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoomGameChoice(
          gameId: _gameId,
          fixed: widget.gameId != null,
          enabled: !_starting,
          keyPrefix: 'pair-game-',
          onChanged: (id) => setState(() => _gameId = id),
        ),
        if (_hostDeck != null) ...[
          const SizedBox(height: 8),
          Text(l10n.quartettDeckLabel, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          QuartettDeckChooser(
            key: const Key('pair-deck'),
            keyPrefix: 'pair-deck-',
            selected: _deck,
            enabled: !_starting,
            onChanged: (d) {
              setState(() => _deck = d);
              _deckSettings.set(d);
            },
          ),
        ],
        if (_gameId == 'wordtiles') ...[
          const SizedBox(height: 12),
          WordTilesOptionsPicker(
            key: const Key('pair-wordtiles'),
            keyPrefix: 'pair-wordtiles-',
            value: _wordOptions,
            enabled: !_starting,
            onChanged: (o) => setState(() => _words = o),
          ),
        ],
        if (_gameId == 'chess') ...[
          const SizedBox(height: 12),
          ChessColorPicker(
            key: const Key('pair-chess-color'),
            keyPrefix: 'pair-chess-color-',
            value: _chessColor,
            enabled: !_starting,
            onChanged: (c) => setState(() => _chessColor = c),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: const Key('pair-host-start'),
          onPressed: _starting ? null : _start,
          icon: _starting
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.meeting_room_outlined),
          label: Text(l10n.roomStart),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, key: const Key('pair-host-error'), style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 8),
        // KLD-098: where the room runs. Default: this device (nothing to set
        // up); the relay (room code, browsers) is chosen once and remembered.
        RoomAdvanced(
          id: 'pair-start-advanced',
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _roomSettings,
              builder: (context, viaRelay, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    key: const Key('pair-via-relay'),
                    contentPadding: EdgeInsetsDirectional.zero,
                    value: viaRelay,
                    onChanged: _starting ? null : _roomSettings.set,
                    title: Text(l10n.roomViaRelay),
                    subtitle: Text(l10n.roomViaRelayHelper),
                  ),
                  if (viaRelay) RelayLine(settings: _relaySettings, enabled: !_starting),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _waiting(BuildContext context, NetworkTransport t) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final port = t.port!;
    final title = localizedGameTitle(l10n, _gameId, fallback: specById(_gameId)?.title ?? _gameId);
    final qrHost = _addresses.isEmpty ? null : _addresses[_qrIndex.clamp(0, _addresses.length - 1)];
    final wsPort = t.wsPort;
    final payload =
        qrHost == null ? null : JoinPayload(host: qrHost, port: port, name: _name, gameId: _gameId, wsPort: wsPort);
    return Column(
      key: const Key('pair-host-waiting'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.roomOfPlayer(bidiName(context, _name), title),
            key: const Key('pair-hosting'), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        if (_gameId == 'wordtiles')
          Text(wordTilesOptionsSummary(l10n, t.config),
              key: const Key('pair-hosting-options'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        if (_gameId == 'chess')
          Text(chessYouPlay(l10n, chessColorIn(t.config, t.me)),
              key: const Key('pair-hosting-options'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 12),
        if (payload != null)
          Center(
            child: JoinQrCode(
              key: const Key('pair-qr'),
              payload: payload,
              size: 200,
            ),
          )
        else
          Text(
            l10n.pairingNoAddress(port),
            key: const Key('pair-no-address'),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12),
        Text(l10n.roomDirectWaitingHint, key: const Key('pair-host-hint'), textAlign: TextAlign.center),
        if (_advertiseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_advertiseError!, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            // Flexible: long translations wrap instead of overflowing (I18N-06).
            Flexible(child: Text(l10n.pairingWaitingForGuest, key: const Key('pair-host-status'))),
          ],
        ),
        RefusedGuestNotice(transport: t),
        const SizedBox(height: 16),
        OutlinedButton(key: const Key('pair-host-cancel'), onPressed: _cancel, child: Text(l10n.pairingCancel)),
        const SizedBox(height: 8),
        // KLD-098: addresses to type and the browser link are technical.
        RoomAdvanced(id: 'pair-waiting-advanced', children: _addressDetails(context, port, payload, qrHost, wsPort)),
      ],
    );
  }

  List<Widget> _addressDetails(BuildContext context, int port, JoinPayload? payload, String? qrHost, int? wsPort) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return [
        if (_addresses.isNotEmpty) Text(l10n.pairingAddresses, style: theme.textTheme.labelLarge),
        for (var i = 0; i < _addresses.length; i++)
          ListTile(
            key: Key('pair-address-$i'),
            dense: true,
            leading: Icon(i == _qrIndex ? Icons.qr_code : Icons.lan_outlined),
            title: LtrText('${_addresses[i]}:$port', key: Key('pair-address-text-$i')),
            subtitle: i == 0 ? Text(l10n.pairingProbablyWifi) : null,
            onTap: () => setState(() => _qrIndex = i),
          ),
        // Browser guests (KLD-055): the PWA cannot scan or browse, so show
        // the WebSocket address and the link to paste.
        if (payload != null && wsPort != null) ...[
          const SizedBox(height: 8),
          Text(l10n.pairingBrowserJoin, style: theme.textTheme.labelLarge),
          ListTile(
            key: const Key('pair-browser'),
            dense: true,
            leading: const Icon(Icons.public),
            title: LtrText('$qrHost:$wsPort', key: const Key('pair-browser-address')),
            subtitle: SelectableText(
              payload.format(),
              key: const Key('pair-link'),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall,
            ),
            trailing: IconButton(
              key: const Key('pair-link-copy'),
              icon: const Icon(Icons.copy),
              tooltip: l10n.pairingCopyLink,
              onPressed: () => _copyLink(payload.format()),
            ),
          ),
        ],
    ];
  }
}

// ---------------------------------------------------------------------------
// Join

class _JoinPanel extends StatefulWidget {
  final PairingDeps deps;
  final DiscoveryService? discovery;
  final String Function() deviceName;
  final bool scanFirst;

  /// Completes once the player has a name (the first-run dialog comes
  /// before the scanner).
  final Future<void> ready;
  final void Function(NetworkTransport) onConnected;

  const _JoinPanel({
    super.key,
    required this.deps,
    required this.discovery,
    required this.deviceName,
    required this.scanFirst,
    required this.ready,
    required this.onConnected,
  });

  @override
  State<_JoinPanel> createState() => _JoinPanelState();
}

class _JoinPanelState extends State<_JoinPanel> {
  final TextEditingController _manual = TextEditingController();
  final GlobalKey<RoomCodeJoinState> _roomJoin = GlobalKey();
  late final RelaySettings _relaySettings = widget.deps.relaySettings();
  StreamSubscription<List<KlunkiHostInfo>>? _browse;
  List<KlunkiHostInfo> _hosts = const [];
  String? _browseError;
  String? _manualError;

  /// The host being connected to (null: idle).
  String? _connecting;
  String? _error;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    final d = widget.discovery;
    if (d != null) {
      _browse = d.browse().listen(
        (hosts) {
          if (mounted) setState(() => _hosts = hosts);
        },
        onError: (Object e) {
          if (mounted) setState(() => _browseError = AppLocalizations.of(context).pairingBrowseFailed);
        },
      );
    }
    // KLD-098: "Raum beitreten" leads straight to the camera; closing it (or
    // "Code eintippen") leaves the code field and the rooms nearby.
    final scanner = widget.deps.qrScanner;
    if (scanner != null && widget.scanFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await widget.ready;
        if (mounted && _connecting == null) _scan(scanner);
      });
    }
  }

  @override
  void dispose() {
    _attempt++; // a join still in flight is closed when it completes
    _browse?.cancel();
    widget.discovery?.stopBrowsing();
    _manual.dispose();
    super.dispose();
  }

  void _connectManual() {
    final payload = JoinPayload.tryParse(_manual.text);
    if (payload == null) {
      setState(() => _manualError = AppLocalizations.of(context).pairingInvalidAddress);
      return;
    }
    setState(() => _manualError = null);
    _connect(payload.host, payload.port, payload.name ?? payload.address);
  }

  Future<void> _connect(String host, int port, String label) async {
    if (_connecting != null) return;
    final l10n = AppLocalizations.of(context);
    final attempt = ++_attempt;
    setState(() {
      _connecting = label;
      _error = null;
    });
    NetworkTransport? transport;
    Object? failure;
    final pending = widget.deps.joinTransport(host, port, name: widget.deviceName());
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
        // The hints go with every failed join.
        // KLD-085: another build: say which device to update, no network hints.
        _error = (failure == null ? null : versionMismatchText(context, failure)) ??
            (failure != null && isSeatTaken(failure)
                ? l10n.pairingSeatTaken
                : '${l10n.pairingJoinFailed(label, '$failure')}\n${l10n.pairingJoinHints}');
      });
      return;
    }
    _attempt++;
    _browse?.cancel();
    _browse = null;
    widget.onConnected(transport);
  }

  /// "QR-Code scannen" (KLD-052): a scanned code joins right away, the same
  /// way as typing it.
  Future<void> _scan(QrScannerFactory scanner) async {
    final join = await scanJoinCode(context, scanner);
    if (!mounted || join == null || _connecting != null) return;
    switch (join) {
      case ScannedDirectJoin(:final payload):
        _manual.text = payload.address;
        setState(() => _manualError = null);
        _connect(payload.host, payload.port, payload.name ?? payload.address);
      case ScannedRoomJoin(:final code, :final relay):
        _roomJoin.currentState?.joinScanned(code, relay);
    }
  }

  void _cancelConnect() {
    _attempt++;
    setState(() => _connecting = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final busy = _connecting != null;
    final scanner = widget.deps.qrScanner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. The camera (KLD-052): reads both kinds of room QR code (a room
        //    on a device and a relay room). Opened right away (KLD-098).
        if (scanner != null) ...[
          FilledButton.icon(
            key: const Key('pair-scan'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: busy ? null : () => _scan(scanner),
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l10n.qrScanButton),
          ),
          const SizedBox(height: 16),
        ],
        // 2. The room code (a relay room, KLD-057b).
        RoomCodeJoin(
          key: _roomJoin,
          joinTransport: widget.deps.relayJoin,
          joinTimeout: widget.deps.joinTimeout,
          settings: _relaySettings,
          playerName: widget.deviceName,
          onConnected: (t) {
            _attempt++;
            _browse?.cancel();
            _browse = null;
            widget.onConnected(t);
          },
        ),
        // 3. Rooms running on a device in the same Wi-Fi (mDNS).
        const Divider(height: 32),
        Text(l10n.roomNearby, key: const Key('pair-nearby-title'), style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        if (widget.discovery == null)
          Text(l10n.pairingNoDiscoveryJoin)
        else if (_browseError != null)
          Text(_browseError!)
        else if (_hosts.isEmpty)
          ListTile(
            key: const Key('pair-browse-empty'),
            leading: const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            title: Text(l10n.pairingSearching),
          ),
        for (final h in _hosts) _hostTile(l10n, h, busy),
        if (busy) ...[
          const SizedBox(height: 16),
          Row(
            key: const Key('pair-join-progress'),
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
          Text(_error!, key: const Key('pair-join-error'), style: TextStyle(color: theme.colorScheme.error)),
        ],
        const SizedBox(height: 16),
        // 4. KLD-098: the technical part: the relay address (an app has no
        //    page origin: the last used relay, else "enter one") and a
        //    device's IP address.
        RoomAdvanced(
          id: 'pair-join-advanced',
          children: [
            RelayLine(settings: _relaySettings, enabled: !busy),
            const Divider(height: 32),
            Text(l10n.joinDirectTitle, key: const Key('pair-direct-title'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(l10n.joinDirectHelper, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            TextField(
              key: const Key('pair-manual'),
              controller: _manual,
              enabled: !busy,
              keyboardType: TextInputType.url,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.pairingManualLabel,
                hintText: '192.168.1.20:4747',
                errorText: _manualError,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _connectManual(),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('pair-manual-connect'),
              onPressed: busy ? null : _connectManual,
              child: Text(l10n.pairingConnect),
            ),
          ],
        ),
      ],
    );
  }

  Widget _hostTile(AppLocalizations l10n, KlunkiHostInfo h, bool busy) {
    final compatible = h.protocol == klunkiProtocolVersion;
    final id = h.gameId;
    final game = id == null ? null : localizedGameTitle(l10n, id, fallback: specById(id)?.title ?? id);
    return Card(
      key: Key('pair-host-${h.host}:${h.port}'),
      child: ListTile(
        leading: const Icon(Icons.meeting_room_outlined),
        // "Raum von Anna: 4 Gewinnt" (KLD-056: the player name of whoever
        // started it); the address only for telling two rooms apart.
        title: Text(game == null ? bidiName(context, h.name) : l10n.roomOfPlayer(bidiName(context, h.name), game)),
        subtitle: Text([
          bidiLtr(context, '${h.host}:${h.port}'),
          if (!compatible) l10n.pairingOtherVersion,
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        enabled: compatible && !busy,
        onTap: () => _connect(h.host, h.port, h.name),
      ),
    );
  }
}

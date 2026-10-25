import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../net/discovery.dart';
import '../../net/discovery_factory.dart';
import '../../net/join_payload.dart';
import '../../net/join_qr.dart';
import '../../net/local_ip.dart';
import '../../transport/network_transport.dart';
import '../shell/game_screen.dart' show newGameSeed;
import 'device_name.dart';
import 'network_game_session.dart';

/// Starts a host session for [config] on [port] (0 = any free port).
typedef HostTransportFactory = Future<NetworkTransport> Function(GameConfig config,
    {required String name, required int port});

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

  /// This device's LAN IPv4 addresses, best first.
  final Future<List<String>> Function() localAddresses;

  /// Default for the editable device name.
  final String Function() deviceName;

  /// Seed for a hosted game.
  final int Function() seed;

  /// Port tried first; if it is busy the host falls back to port 0.
  final int preferredPort;

  /// Upper bound for a join attempt (the transport has its own handshake
  /// timeout; this also covers a hanging connect).
  final Duration joinTimeout;

  const PairingDeps({
    required this.discovery,
    required this.hostTransport,
    required this.joinTransport,
    required this.localAddresses,
    required this.deviceName,
    this.seed = newGameSeed,
    this.preferredPort = klunkiDefaultPort,
    this.joinTimeout = const Duration(seconds: 12),
  });

  /// The real thing: platform discovery, TCP on all interfaces.
  factory PairingDeps.platform() => PairingDeps(
        discovery: createDiscovery,
        hostTransport: (config, {required name, required port}) =>
            NetworkTransport.host(config, name: name, port: port),
        joinTransport: (host, port, {required name}) => NetworkTransport.join(host, port, name: name),
        localAddresses: localIPv4Addresses,
        deviceName: defaultDeviceName,
      );
}

enum _Mode { host, join }

/// "Über WLAN spielen": host a game (name, IP:port, QR, waiting for the
/// guest) or join one (discovered hosts + manual entry). Once both sides are
/// connected the route is replaced by a [NetworkGameSession], so leaving the
/// game goes straight back to the menu.
class PairingScreen extends StatefulWidget {
  final PairingDeps deps;

  PairingScreen({super.key, PairingDeps? deps}) : deps = deps ?? PairingDeps.platform();

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  late final DiscoveryService? _discovery = widget.deps.discovery();
  late final TextEditingController _name = TextEditingController(text: widget.deps.deviceName());
  _Mode _mode = _Mode.host;

  @override
  void dispose() {
    _name.dispose();
    _discovery?.dispose();
    super.dispose();
  }

  String get _deviceName {
    final n = _name.text.trim();
    return n.isEmpty ? widget.deps.deviceName() : n;
  }

  /// Replaces the pairing route by the game.
  void _openGame(NetworkTransport transport) {
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => NetworkGameSession(transport: transport),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Über WLAN spielen')),
        body: const Center(child: Text('Netzwerkspiel ist im Browser nicht verfügbar')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Über WLAN spielen')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  key: const Key('pair-name'),
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Gerätename',
                    helperText: 'So sieht dich dein Mitspieler',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 16),
                SegmentedButton<_Mode>(
                  segments: const [
                    ButtonSegment(value: _Mode.host, label: Text('Hosten'), icon: Icon(Icons.wifi_tethering)),
                    ButtonSegment(value: _Mode.join, label: Text('Beitreten'), icon: Icon(Icons.login)),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 16),
                if (_mode == _Mode.host)
                  _HostPanel(
                    key: const Key('pair-host-panel'),
                    deps: widget.deps,
                    discovery: _discovery,
                    deviceName: () => _deviceName,
                    onConnected: _openGame,
                  )
                else
                  _JoinPanel(
                    key: const Key('pair-join-panel'),
                    deps: widget.deps,
                    discovery: _discovery,
                    deviceName: () => _deviceName,
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
// Host

class _HostPanel extends StatefulWidget {
  final PairingDeps deps;
  final DiscoveryService? discovery;
  final String Function() deviceName;
  final void Function(NetworkTransport) onConnected;

  const _HostPanel({
    super.key,
    required this.deps,
    required this.discovery,
    required this.deviceName,
    required this.onConnected,
  });

  @override
  State<_HostPanel> createState() => _HostPanelState();
}

class _HostPanelState extends State<_HostPanel> {
  String _gameId = gameSpecs.first.id;
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

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _error = null;
    });
    final deps = widget.deps;
    final config = GameConfig(_gameId, seed: deps.seed());
    final name = widget.deviceName();
    NetworkTransport transport;
    try {
      try {
        transport = await deps.hostTransport(config, name: name, port: deps.preferredPort);
      } catch (_) {
        if (deps.preferredPort == 0) rethrow;
        // Port busy (e.g. a second Klunki on this machine): any free port.
        transport = await deps.hostTransport(config, name: name, port: 0);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = 'Spiel konnte nicht gestartet werden: $e';
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
        ));
      } catch (e) {
        _advertised = false;
        if (mounted) setState(() => _advertiseError = 'Nicht automatisch sichtbar – Mitspieler gibt die Adresse ein.');
      }
    } else if (mounted) {
      setState(() => _advertiseError = 'Keine automatische Suche auf diesem Gerät – Mitspieler gibt die Adresse ein.');
    }
    _onConnection(); // the guest may already be there
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

  @override
  Widget build(BuildContext context) {
    final t = _transport;
    return t == null ? _setup(context) : _waiting(context, t);
  }

  Widget _setup(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Spiel wählen', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _gameId,
          onChanged: (v) {
            if (v != null && !_starting) setState(() => _gameId = v);
          },
          child: Column(
            children: [
              for (final spec in gameSpecs)
                RadioListTile<String>(
                  key: Key('pair-game-${spec.id}'),
                  value: spec.id,
                  title: Text(spec.title),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('pair-host-start'),
          onPressed: _starting ? null : _start,
          icon: _starting
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.wifi_tethering),
          label: const Text('Spiel hosten'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, key: const Key('pair-host-error'), style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }

  Widget _waiting(BuildContext context, NetworkTransport t) {
    final theme = Theme.of(context);
    final port = t.port!;
    final title = specById(_gameId)?.title ?? _gameId;
    final qrHost = _addresses.isEmpty ? null : _addresses[_qrIndex.clamp(0, _addresses.length - 1)];
    return Column(
      key: const Key('pair-host-waiting'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('$_name hostet $title', style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        if (qrHost != null)
          Center(
            child: JoinQrCode(
              key: const Key('pair-qr'),
              payload: JoinPayload(host: qrHost, port: port, name: _name, gameId: _gameId),
              size: 180,
            ),
          )
        else
          Text(
            'Keine WLAN-Adresse gefunden. Ist das Gerät mit dem WLAN verbunden? Port: $port',
            key: const Key('pair-no-address'),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12),
        if (_addresses.isNotEmpty) Text('Adressen (zum Eintippen):', style: theme.textTheme.labelLarge),
        for (var i = 0; i < _addresses.length; i++)
          ListTile(
            key: Key('pair-address-$i'),
            dense: true,
            leading: Icon(i == _qrIndex ? Icons.qr_code : Icons.lan_outlined),
            title: Text('${_addresses[i]}:$port'),
            subtitle: i == 0 ? const Text('wahrscheinlich WLAN') : null,
            onTap: () => setState(() => _qrIndex = i),
          ),
        if (_advertiseError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(_advertiseError!, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Warte auf Mitspieler…', key: Key('pair-host-status')),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(key: const Key('pair-host-cancel'), onPressed: _cancel, child: const Text('Abbrechen')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Join

/// Hints shown with every failed join.
const String joinHints = 'Tipps: Sind beide Geräte im selben WLAN? Gäste-WLANs blockieren oft Verbindungen '
    'zwischen Geräten. iOS: Ist „Lokales Netzwerk“ für Klunki erlaubt (Einstellungen › Datenschutz)?';

class _JoinPanel extends StatefulWidget {
  final PairingDeps deps;
  final DiscoveryService? discovery;
  final String Function() deviceName;
  final void Function(NetworkTransport) onConnected;

  const _JoinPanel({
    super.key,
    required this.deps,
    required this.discovery,
    required this.deviceName,
    required this.onConnected,
  });

  @override
  State<_JoinPanel> createState() => _JoinPanelState();
}

class _JoinPanelState extends State<_JoinPanel> {
  final TextEditingController _manual = TextEditingController();
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
          if (mounted) setState(() => _browseError = 'Suche im Netzwerk nicht möglich. Adresse unten eingeben.');
        },
      );
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
      setState(() => _manualError = 'Ungültige Adresse. Beispiel: 192.168.1.20 oder 192.168.1.20:4747');
      return;
    }
    setState(() => _manualError = null);
    _connect(payload.host, payload.port, payload.name ?? payload.address);
  }

  Future<void> _connect(String host, int port, String label) async {
    if (_connecting != null) return;
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
      failure = 'Zeitüberschreitung';
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
        _error = 'Verbindung zu $label fehlgeschlagen ($failure).\n$joinHints';
      });
      return;
    }
    _attempt++;
    _browse?.cancel();
    _browse = null;
    widget.onConnected(transport);
  }

  void _cancelConnect() {
    _attempt++;
    setState(() => _connecting = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _connecting != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Spiele im Netzwerk', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (widget.discovery == null)
          const Text('Automatische Suche ist auf diesem Gerät nicht verfügbar. Adresse unten eingeben.')
        else if (_browseError != null)
          Text(_browseError!)
        else if (_hosts.isEmpty)
          const ListTile(
            key: Key('pair-browse-empty'),
            leading: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            title: Text('Suche nach Spielen…'),
          ),
        for (final h in _hosts) _hostTile(h, busy),
        const SizedBox(height: 16),
        Text('Oder Adresse eingeben', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          key: const Key('pair-manual'),
          controller: _manual,
          enabled: !busy,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'IP, IP:Port oder klunki://-Link',
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
          child: const Text('Verbinden'),
        ),
        if (busy) ...[
          const SizedBox(height: 16),
          Row(
            key: const Key('pair-join-progress'),
            children: [
              const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 12),
              Expanded(child: Text('Verbinde mit $_connecting…')),
              TextButton(onPressed: _cancelConnect, child: const Text('Abbrechen')),
            ],
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Text(_error!, key: const Key('pair-join-error'), style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }

  Widget _hostTile(KlunkiHostInfo h, bool busy) {
    final compatible = h.protocol == klunkiProtocolVersion;
    final game = h.gameId == null ? null : (specById(h.gameId!)?.title ?? h.gameId);
    return Card(
      key: Key('pair-host-${h.host}:${h.port}'),
      child: ListTile(
        leading: const Icon(Icons.devices),
        title: Text(h.name),
        subtitle: Text([
          ?game,
          '${h.host}:${h.port}',
          if (!compatible) 'andere Klunki-Version',
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        enabled: compatible && !busy,
        onTap: () => _connect(h.host, h.port, h.name),
      ),
    );
  }
}

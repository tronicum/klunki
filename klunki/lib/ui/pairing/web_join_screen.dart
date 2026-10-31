import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';

import '../../net/join_payload.dart';
import '../../net/web_join_target.dart';
import '../../transport/network_transport.dart';
import '../game_titles.dart';
import '../ltr.dart';
import '../player_name_dialog.dart';
import 'network_game_session.dart';

/// Joins the host's WebSocket endpoint [url] (`ws://host:port`).
typedef WebJoinTransportFactory = Future<NetworkTransport> Function(Uri url, {required String name});

/// Default player name suggestion of a browser guest (what the host shows
/// until the player picks a name).
const String webDefaultDeviceName = 'Browser';

/// Everything the web join screen talks to, injectable for tests.
class WebJoinDeps {
  final WebJoinTransportFactory joinTransport;

  /// Suggestion for the player name when none is saved ("Browser").
  final String Function() deviceName;

  /// Upper bound for a join attempt (also covers a WebSocket that never
  /// opens, e.g. a host on another network).
  final Duration joinTimeout;

  const WebJoinDeps({
    required this.joinTransport,
    this.deviceName = _browser,
    this.joinTimeout = const Duration(seconds: 12),
  });

  static String _browser() => webDefaultDeviceName;

  /// The real thing: `NetworkTransport.joinWebSocket`.
  factory WebJoinDeps.platform() => WebJoinDeps(
        joinTransport: (url, {required name}) => NetworkTransport.joinWebSocket(url, name: name),
      );
}

/// "Über WLAN spielen" in the browser (KLD-055): join-only. A web page can
/// neither listen for guests nor browse mDNS, so there is no host tab and no
/// list of discovered games; the player types the host's address or pastes
/// its `klunki://` link (see [WebJoinTarget] for the accepted forms). Also
/// reached directly through `?join=<link>` in the page URL ([initialInput] +
/// [autoConnect]). Once connected the route is replaced by the same
/// [NetworkGameSession] the apps use.
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

  /// The page URL; an `https:` page gets a warning (browsers block `ws://`
  /// from https pages).
  final Uri? pageUrl;

  /// Overrides the app's player name controller (tests).
  final PlayerNameController? nameController;

  WebJoinScreen(
      {super.key, WebJoinDeps? deps, this.initialInput, this.autoConnect = false, this.pageUrl, this.nameController})
      : deps = deps ?? WebJoinDeps.platform();

  @override
  State<WebJoinScreen> createState() => _WebJoinScreenState();
}

class _WebJoinScreenState extends State<WebJoinScreen> with PlayerNameField {
  late final TextEditingController _address = TextEditingController(text: widget.initialInput ?? '');
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
  String playerNameSuggestion() => widget.deps.deviceName();

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
        _error = '${l10n.pairingJoinFailed(bidiLtr(context, label), '$failure')}\n${l10n.webJoinHints}';
      });
      return;
    }
    _attempt++;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => NetworkGameSession(transport: transport!),
    ));
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
    final https = widget.pageUrl?.scheme == 'https';
    final target = WebJoinTarget.tryParse(_address.text);
    final game = target?.gameId;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pairingTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              key: const Key('web-join'),
              padding: const EdgeInsets.all(16),
              children: [
                Text(l10n.webJoinIntro, key: const Key('web-join-intro')),
                if (https) ...[
                  const SizedBox(height: 12),
                  Text(l10n.webJoinHttpsWarning,
                      key: const Key('web-join-https'), style: TextStyle(color: theme.colorScheme.error)),
                ],
                const SizedBox(height: 16),
                playerNameField(
                    key: const Key('web-join-name'), enabled: !busy, textInputAction: TextInputAction.next),
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
                  Text(_error!, key: const Key('web-join-error'), style: TextStyle(color: theme.colorScheme.error)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

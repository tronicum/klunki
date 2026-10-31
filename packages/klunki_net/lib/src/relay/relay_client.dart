import 'dart:async';

import '../channel/channel.dart';
import '../channel/listener.dart';
import '../channel/platform.dart' as platform;
import '../events.dart';
import 'relay_protocol.dart';

/// Web-safe relay clients: they only use the platform's WebSocket
/// ([platform.connectWebSocket]), so they work in the browser and on the VM.

/// The host's side of a relay room, as a [HostListener]: every guest that
/// joins the room (`relay.peer`) is handed out as a new [MessageChannel],
/// exactly like a guest accepted on a TCP or WebSocket port, so `KlunkiHost`
/// runs its unchanged session logic on top.
///
/// The relay connection itself errors the [channels] stream with a
/// [NetException] (then closes it) when the room is gone.
class RelayHostListener implements HostListener {
  /// The relay endpoint (`ws://host:port/relay`).
  final Uri relayUrl;

  /// The room code the guest types.
  final String code;

  final MessageChannel _relay;
  final _channels = StreamController<MessageChannel>();
  late final StreamSubscription<String> _sub;
  _RelayPeerChannel? _current;
  bool _closed = false;

  RelayHostListener._(this.relayUrl, this.code, this._relay);

  /// Connects to [relayUrl], creates a room and completes with its code.
  /// Throws [NetException] if the relay cannot be reached or refuses.
  static Future<RelayHostListener> connect(Uri relayUrl, {Duration timeout = const Duration(seconds: 10)}) async {
    final relay = await platform.connectWebSocket(relayCreateUri(relayUrl), timeout);
    final first = Completer<RelayHostListener>();
    RelayHostListener? listener;
    late final StreamSubscription<String> sub;
    void fail(String why) {
      if (first.isCompleted) return;
      first.completeError(NetException(why));
      sub.cancel();
      relay.close();
    }

    sub = relay.messages.listen((line) {
      final l = listener;
      if (l != null) return l._onLine(line);
      final control = parseRelayControl(line);
      final code = control?['code'];
      if (control?['t'] == relayRoom && code is String) {
        listener = RelayHostListener._(relayUrl, code, relay).._sub = sub;
        first.complete(listener);
      } else if (control?['t'] == relayError) {
        fail('relay: ${control!['message'] ?? 'refused'}');
      } else {
        fail('not a Klunki relay (unexpected first message)');
      }
    }, onError: (Object e) {
      final l = listener;
      l != null ? l._onRelayGone('relay connection failed: $e') : fail('relay connection failed: $e');
    }, onDone: () {
      final l = listener;
      l != null ? l._onRelayGone('relay connection lost') : fail('relay closed the connection');
    });
    final timer = Timer(timeout, () => fail('no room from the relay within ${timeout.inMilliseconds} ms'));
    return first.future.whenComplete(timer.cancel);
  }

  /// Relay rooms have no ports; always 0.
  @override
  int get port => 0;

  /// Relay rooms have no ports; always null.
  @override
  int? get wsPort => null;

  @override
  Stream<MessageChannel> get channels => _channels.stream;

  /// Leaves the room: the relay closes it and drops the guest.
  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _current?._end();
    _current = null;
    await _sub.cancel();
    await _relay.close();
    if (!_channels.isClosed) await _channels.close();
  }

  void _onLine(String line) {
    final control = parseRelayControl(line);
    if (control == null) {
      _current?._incoming.add(line);
      return;
    }
    switch (control['t']) {
      case relayPeer:
        _current?._end(); // cannot happen: the relay reports `left` first
        final peer = _current = _RelayPeerChannel(this);
        if (!_channels.isClosed) _channels.add(peer);
      case relayLeft:
        _current?._end();
        _current = null;
      case relayClosed:
        _onRelayGone('relay: ${control['reason'] ?? 'room closed'}');
      case relayError:
        _onRelayGone('relay: ${control['message'] ?? 'error'}');
      default:
        break; // unknown control messages are ignored (forward compatible)
    }
  }

  void _onRelayGone(String reason) {
    if (_closed) return;
    _closed = true;
    _current?._end();
    _current = null;
    _sub.cancel();
    _relay.close();
    if (!_channels.isClosed) {
      _channels.addError(NetException(reason));
      _channels.close();
    }
  }
}

/// One guest connection inside a relay room.
class _RelayPeerChannel implements MessageChannel {
  final RelayHostListener _listener;
  final _incoming = StreamController<String>();

  _RelayPeerChannel(this._listener);

  bool get _active => identical(_listener._current, this) && !_listener._closed;

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  String get kind => 'relay';

  @override
  void send(String message) {
    if (!_active) throw StateError('relay guest is gone');
    _listener._relay.send(message);
  }

  /// Asks the relay to drop this guest (after the lines sent so far).
  @override
  Future<void> close() async {
    if (_active) {
      _listener._current = null;
      try {
        _listener._relay.send(relayControl(relayKick));
      } catch (_) {}
    }
    _end();
  }

  void _end() {
    if (!_incoming.isClosed) _incoming.close();
  }
}

/// A guest's connection through a relay room: game lines pass unchanged;
/// relay control lines become a [NetException] on [messages] (`relay.error`:
/// unknown or full room, `relay.closed`: the host is gone), so the session
/// reports a readable reason.
class RelayGuestChannel implements MessageChannel {
  final MessageChannel _inner;
  @override
  late final Stream<String> messages;

  RelayGuestChannel(this._inner) {
    messages = _inner.messages.transform(StreamTransformer.fromHandlers(handleData: (line, sink) {
      final control = parseRelayControl(line);
      if (control == null) return sink.add(line);
      switch (control['t']) {
        case relayError:
          sink.addError(NetException('relay: ${control['message'] ?? 'refused'}'));
        case relayClosed:
          sink.addError(NetException('relay: ${control['reason'] ?? 'room closed'}'));
        default:
          break; // unknown control messages are ignored
      }
    }));
  }

  /// Opens a guest connection to room [code] on [relayUrl].
  static Future<RelayGuestChannel> connect(Uri relayUrl, String code, Duration timeout) async =>
      RelayGuestChannel(await platform.connectWebSocket(relayJoinUri(relayUrl, code), timeout));

  @override
  String get kind => 'relay';

  @override
  void send(String message) => _inner.send(message);

  @override
  Future<void> close() => _inner.close();
}

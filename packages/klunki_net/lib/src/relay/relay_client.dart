import 'dart:async';

import '../awake_clock.dart';
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
/// KLD-120: when the relay connection drops (a locked phone, lost Wi-Fi),
/// the listener comes back to its room with the room's host key
/// (`?resume=CODE&key=KEY`) for up to [reattachFor], retrying with a short
/// backoff; [status] reports [RoomReconnecting] and [RoomReconnected]. A
/// relay without host keys (older), or one that no longer has the room,
/// ends it as before: the [channels] stream errors with a [NetException]
/// (then closes).
class RelayHostListener implements HostListener {
  /// The relay endpoint (`ws://host:port/relay`).
  final Uri relayUrl;

  /// The room code the guest types.
  final String code;

  /// How long the listener keeps trying to come back after its relay
  /// connection dropped (KLD-120).
  final Duration reattachFor;

  final Duration _timeout;
  final String? _clubCode;
  String? _key; // the room's host key from `relay.room` (KLD-120); null: an older relay
  _RelayLink _link;
  final _channels = StreamController<MessageChannel>();
  final _status = StreamController<NetEvent>.broadcast(sync: true);
  _RelayPeerChannel? _current;
  bool _closed = false;
  bool _reattaching = false;
  Completer<void>? _wake; // completes to skip the current backoff wait

  RelayHostListener._(this.relayUrl, this._link, this._timeout, this._clubCode, this.reattachFor)
      : code = _link.code!,
        _key = _link.key {
    _link.attach(_onLine, _onRelayGone);
  }

  /// Connects to [relayUrl], creates a room and completes with its code.
  /// Throws [NetException] if the relay cannot be reached or refuses.
  /// [clubCode]: the club code of a gated relay (KLD-112).
  static Future<RelayHostListener> connect(Uri relayUrl,
      {Duration timeout = const Duration(seconds: 10),
      String? clubCode,
      Duration reattachFor = const Duration(minutes: 5)}) async {
    final link = await _RelayLink.open(relayCreateUri(relayUrl, clubCode: clubCode), timeout);
    return RelayHostListener._(relayUrl, link, timeout, clubCode, reattachFor);
  }

  /// Relay rooms have no ports; always 0.
  @override
  int get port => 0;

  /// Relay rooms have no ports; always null.
  @override
  int? get wsPort => null;

  @override
  Stream<MessageChannel> get channels => _channels.stream;

  /// [RoomReconnecting] and [RoomReconnected] (KLD-120), synchronously.
  Stream<NetEvent> get status => _status.stream;

  /// Whether the relay gave this room a host key, so the host can come back
  /// after its connection dropped (KLD-120).
  bool get canReattach => _key != null;

  /// Whether the listener is trying to come back to its room right now.
  bool get reattaching => _reattaching;

  /// Leaves the room: the relay closes it and drops the guest.
  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _wake?.complete();
    _current?._end();
    _current = null;
    await _link.sub.cancel();
    await _link.channel.close();
    if (!_channels.isClosed) await _channels.close();
    await _status.close();
  }

  /// KLD-120: comes back to the room on a fresh connection now, e.g. after
  /// the app was suspended long enough for the relay to give up on the old
  /// one (which may still look open here). A guest connected through the
  /// old connection is dropped by the relay and rejoins. Without a host key
  /// (an older relay) this does nothing. While already trying, it skips the
  /// current wait.
  void reattach() {
    if (_closed || _key == null) return;
    if (_reattaching) {
      _wake?.complete();
      return;
    }
    _comeBack('reconnecting after a pause', keepOld: true);
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
        _fail('relay: ${control['reason'] ?? 'room closed'}');
      case relayError:
        _fail('relay: ${relayRefusalText(control, 'error')}');
      default:
        break; // unknown control messages are ignored (forward compatible)
    }
  }

  /// The relay connection ended without a word from the relay (network
  /// loss, the relay's ping went unanswered while the app was suspended).
  void _onRelayGone(String reason) {
    if (_closed) return;
    if (_key == null) return _fail(reason);
    _comeBack(reason, keepOld: false);
  }

  /// Retries `?resume=CODE&key=KEY` until it works, the relay refuses for
  /// good (the room is gone), or [reattachFor] has passed.
  Future<void> _comeBack(String reason, {required bool keepOld}) async {
    _reattaching = true;
    _current?._end();
    _current = null;
    final old = _link;
    unawaited(old.sub.cancel());
    // The old connection is closed only once the new one is in (or as
    // "away"): a clean close would tell the relay that the host left.
    if (!keepOld) unawaited(old.abandon());
    if (!_status.isClosed) _status.add(RoomReconnecting(reason));
    final clock = Stopwatch()..start();
    var delay = Duration.zero;
    var last = reason;
    while (!_closed) {
      if (delay > Duration.zero) {
        final wake = _wake = Completer<void>();
        await Future.any([wake.future, Future<void>.delayed(delay)]);
        _wake = null;
        if (_closed) return;
      }
      try {
        final link = await _RelayLink.open(relayResumeUri(relayUrl, code, _key!, clubCode: _clubCode), _timeout);
        if (_closed) {
          unawaited(link.abandon());
          return;
        }
        _link = link;
        _key = link.key ?? _key;
        _reattaching = false;
        unawaited(old.abandon());
        link.attach(_onLine, _onRelayGone);
        if (!_status.isClosed) _status.add(const RoomReconnected());
        return;
      } on NetException catch (e) {
        last = e.message;
        // The relay answered and refused (`relay: no room with code …`):
        // the room is gone. Anything else (no network yet) is retried.
        if (e.message.startsWith('relay:') || e.message.startsWith('not a Klunki relay')) break;
      }
      if (clock.elapsed >= reattachFor) break;
      delay = _nextDelay(delay);
    }
    _reattaching = false;
    unawaited(old.abandon());
    _fail(last.startsWith('relay') ? last : 'relay connection lost ($last)');
  }

  static Duration _nextDelay(Duration d) {
    final next = d == Duration.zero ? const Duration(milliseconds: 500) : d * 2;
    return next > const Duration(seconds: 5) ? const Duration(seconds: 5) : next;
  }

  /// The room is lost: the session cannot continue in it.
  void _fail(String reason) {
    if (_closed) return;
    _closed = true;
    _wake?.complete();
    _current?._end();
    _current = null;
    _link.sub.cancel();
    _link.channel.close();
    if (!_channels.isClosed) {
      _channels.addError(NetException(reason));
      _channels.close();
    }
    _status.close();
  }
}

/// One WebSocket to the relay as a host, from `relay.room` on: lines and
/// the end of the connection go to the handlers given to [attach]
/// (buffered until then, so nothing that arrives with `relay.room` is lost).
class _RelayLink {
  final MessageChannel channel;
  // ignore: cancel_subscriptions (cancelled by the listener that owns the link)
  late final StreamSubscription<String> sub;
  String? code;
  String? key;
  void Function(String line)? _onLine;
  void Function(String reason)? _onGone;
  final List<String> _early = [];
  String? _goneEarly;

  _RelayLink(this.channel);

  /// Connects to [uri] (`?create` or `?resume=…`) and completes once the
  /// relay sent `relay.room`. Throws [NetException] if the relay cannot be
  /// reached or refuses (`relay: …`).
  static Future<_RelayLink> open(Uri uri, Duration timeout) async {
    final link = _RelayLink(await platform.connectWebSocket(uri, timeout));
    final first = Completer<_RelayLink>();
    void fail(String why) {
      if (first.isCompleted) return;
      first.completeError(NetException(why));
      link.sub.cancel();
      // Not a clean close: a resume the relay accepted after all must not
      // read as the host leaving (KLD-120).
      link.abandon();
    }

    link.sub = link.channel.messages.listen((line) {
      if (first.isCompleted) return link._line(line);
      final control = parseRelayControl(line);
      final code = control?['code'];
      if (control?['t'] == relayRoom && code is String) {
        final key = control!['key'];
        link
          ..code = code
          ..key = key is String && key.isNotEmpty ? key : null;
        first.complete(link);
      } else if (control?['t'] == relayError) {
        fail('relay: ${relayRefusalText(control!, 'refused')}');
      } else {
        fail('not a Klunki relay (unexpected first message)');
      }
    }, onError: (Object e) {
      first.isCompleted ? link._gone('relay connection failed: $e') : fail('relay connection failed: $e');
    }, onDone: () {
      first.isCompleted ? link._gone('relay connection lost') : fail('relay closed the connection');
    });
    final timer = awakeTimer(timeout, () => fail('no room from the relay within ${timeout.inMilliseconds} ms'));
    return first.future.whenComplete(timer.cancel);
  }

  void attach(void Function(String line) onLine, void Function(String reason) onGone) {
    _onLine = onLine;
    _onGone = onGone;
    for (final line in _early) {
      onLine(line);
    }
    _early.clear();
    final gone = _goneEarly;
    if (gone != null) onGone(gone);
  }

  void _line(String line) {
    final f = _onLine;
    f == null ? _early.add(line) : f(line);
  }

  void _gone(String reason) {
    final f = _onGone;
    f == null ? _goneEarly ??= reason : f(reason);
  }

  /// Closes without leaving the room ([closeCodeAway]).
  Future<void> abandon() {
    final c = channel;
    return c is AbandonableChannel ? c.abandon() : c.close();
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
    _listener._link.channel.send(message);
  }

  /// Asks the relay to drop this guest (after the lines sent so far).
  @override
  Future<void> close() async {
    if (_active) {
      _listener._current = null;
      try {
        _listener._link.channel.send(relayControl(relayKick));
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
          sink.addError(NetException('relay: ${relayRefusalText(control, 'refused')}'));
        case relayClosed:
          sink.addError(NetException('relay: ${control['reason'] ?? 'room closed'}'));
        default:
          break; // unknown control messages are ignored
      }
    }));
  }

  /// Opens a guest connection to room [code] on [relayUrl] ([clubCode]: the
  /// club code of a gated relay, KLD-112).
  static Future<RelayGuestChannel> connect(Uri relayUrl, String code, Duration timeout, {String? clubCode}) async =>
      RelayGuestChannel(
          await platform.connectWebSocket(relayJoinUri(relayUrl, code, clubCode: clubCode), timeout));

  @override
  String get kind => 'relay';

  @override
  void send(String message) => _inner.send(message);

  @override
  Future<void> close() => _inner.close();
}

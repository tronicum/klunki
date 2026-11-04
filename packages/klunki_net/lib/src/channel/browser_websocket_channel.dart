import 'dart:async';
import 'dart:js_interop';

import '../awake_clock.dart';
import 'channel.dart';

/// The browser's `WebSocket`, bound directly through `dart:js_interop` (no
/// `package:web` dependency; only the members Klunki needs).
@JS('WebSocket')
extension type _JsWebSocket._(JSObject _) implements JSObject {
  external factory _JsWebSocket(String url);

  /// 0 connecting, 1 open, 2 closing, 3 closed.
  external int get readyState;
  external void send(String data);
  external void close([int code, String reason]);
  external set onopen(JSFunction? handler);
  external set onmessage(JSFunction? handler);
  external set onclose(JSFunction? handler);
  external set onerror(JSFunction? handler);
}

extension type _MessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}

extension type _CloseEvent._(JSObject _) implements JSObject {
  external int get code;
  external String get reason;
}

/// One message per text frame over the browser's `WebSocket` (the PWA guest).
class BrowserWebSocketChannel implements AbandonableChannel {
  final _JsWebSocket _ws;
  final _incoming = StreamController<String>();

  BrowserWebSocketChannel._(this._ws) {
    _ws.onmessage = ((_MessageEvent e) {
      final data = e.data;
      if (data.isA<JSString>()) {
        _incoming.add((data as JSString).toDart);
      } else {
        _incoming.addError(const MalformedInput('binary frame'));
      }
    }).toJS;
    _ws.onclose = ((_CloseEvent _) {
      if (!_incoming.isClosed) _incoming.close();
    }).toJS;
    _ws.onerror = null;
  }

  /// Opens [url] (`ws://host:port`) and completes once the socket is open.
  /// Throws a [StateError] with a short reason if it cannot connect (the
  /// browser does not say why: wrong address, nothing listening, blocked).
  static Future<BrowserWebSocketChannel> connect(Uri url, {required Duration timeout}) {
    final _JsWebSocket ws;
    try {
      ws = _JsWebSocket(url.toString());
    } catch (e) {
      return Future.error(StateError('bad WebSocket address $url: $e'));
    }
    final opened = Completer<BrowserWebSocketChannel>();
    void fail(String why) {
      if (opened.isCompleted) return;
      ws
        ..onopen = null
        ..onclose = null
        ..onerror = null;
      try {
        ws.close();
      } catch (_) {}
      opened.completeError(StateError(why));
    }

    ws.onopen = ((JSAny? _) {
      if (opened.isCompleted) return;
      ws
        ..onopen = null
        ..onerror = null;
      opened.complete(BrowserWebSocketChannel._(ws));
    }).toJS;
    ws.onerror = ((JSAny? _) => fail('cannot open $url')).toJS;
    ws.onclose = ((_CloseEvent e) => fail('cannot open $url (closed, code ${e.code})')).toJS;
    final timer = awakeTimer(timeout, () => fail('timed out opening $url'));
    return opened.future.whenComplete(timer.cancel);
  }

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  String get kind => 'ws';

  @override
  void send(String message) {
    if (_ws.readyState != 1) throw StateError('WebSocket is not open');
    _ws.send(message);
  }

  /// The browser sends buffered frames before the close frame.
  @override
  Future<void> close() => _close(1000);

  @override
  Future<void> abandon() => _close(closeCodeAway);

  Future<void> _close(int code) async {
    try {
      _ws.close(code);
    } catch (_) {}
    if (!_incoming.isClosed) unawaited(_incoming.close());
  }
}

import 'dart:async';
import 'dart:io';

import '../events.dart';
import 'channel.dart';
import 'io_websocket_channel.dart';
import 'listener.dart';
import 'socket_channel.dart';

/// `dart:io` implementation (VM, Android, iOS, macOS): TCP and WebSocket
/// guests, TCP + WebSocket listeners for the host.

Future<MessageChannel> connectTcp(Object host, int port, Duration timeout) async {
  try {
    return SocketChannel(await Socket.connect(host, port, timeout: timeout));
  } on SocketException catch (e) {
    throw NetException('cannot connect: ${e.message}');
  }
}

Future<MessageChannel> connectWebSocket(Uri url, Duration timeout) async {
  try {
    return IoWebSocketChannel(await WebSocket.connect(url.toString()).timeout(timeout));
  } on TimeoutException {
    throw NetException('cannot connect: no answer from $url within ${timeout.inMilliseconds} ms');
  } on SocketException catch (e) {
    throw NetException('cannot connect: ${e.message}');
  } on WebSocketException catch (e) {
    throw NetException('cannot connect: ${e.message}');
  } on HttpException catch (e) {
    throw NetException('cannot connect: ${e.message}');
  }
}

Future<HostListener> bindHostListener({Object? address, required int port, int? wsPort}) async {
  final bindTo = address ?? InternetAddress.anyIPv4;
  final tcp = await ServerSocket.bind(bindTo, port);
  HttpServer? http;
  if (wsPort != null) {
    try {
      http = await HttpServer.bind(bindTo, wsPort);
    } catch (_) {
      await tcp.close();
      rethrow;
    }
  }
  return _IoHostListener(tcp, http);
}

class _IoHostListener implements HostListener {
  final ServerSocket _tcp;
  final HttpServer? _http;
  final _channels = StreamController<MessageChannel>();

  _IoHostListener(this._tcp, this._http) {
    _tcp.listen((socket) => _channels.add(SocketChannel(socket)));
    _http?.listen(_onRequest);
  }

  @override
  int get port => _tcp.port;

  @override
  int? get wsPort => _http?.port;

  @override
  Stream<MessageChannel> get channels => _channels.stream;

  Future<void> _onRequest(HttpRequest request) async {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.upgradeRequired
        ..headers.set(HttpHeaders.upgradeHeader, 'websocket')
        ..headers.contentType = ContentType.text
        ..write('Klunki game host: connect with a WebSocket (ws://), one JSON message per text frame.\n');
      await request.response.close().catchError((_) {});
      return;
    }
    try {
      final ws = await WebSocketTransformer.upgrade(request);
      if (_channels.isClosed) {
        await ws.close(WebSocketStatus.goingAway);
        return;
      }
      _channels.add(IoWebSocketChannel(ws));
    } catch (_) {
      // a broken upgrade request: dart:io already answered it
    }
  }

  @override
  Future<void> close() async {
    await _tcp.close();
    await _http?.close(force: true); // upgraded WebSockets are detached and stay open
    unawaited(_channels.close());
  }
}

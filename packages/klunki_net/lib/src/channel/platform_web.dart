import '../events.dart';
import 'browser_websocket_channel.dart';
import 'channel.dart';
import 'listener.dart';

/// Browser implementation: WebSocket guests only. A web page can neither open
/// raw TCP sockets nor listen, so hosting and `ws`-less joins are refused.

Future<MessageChannel> connectTcp(Object host, int port, Duration timeout) => Future.error(const NetException(
    'a browser cannot open TCP connections; join the host over WebSocket (ws://host:port)'));

Future<MessageChannel> connectWebSocket(Uri url, Duration timeout) async {
  try {
    return await BrowserWebSocketChannel.connect(url, timeout: timeout);
  } on StateError catch (e) {
    throw NetException('cannot connect: ${e.message}');
  }
}

Future<HostListener> bindHostListener({Object? address, required int port, int? wsPort}) =>
    Future.error(UnsupportedError('a browser cannot host a Klunki game'));

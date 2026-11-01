// KLD-055: what the browser join screen makes of the typed address.
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/net/web_join_target.dart';

Uri _ws(String host, int port) => Uri(scheme: 'ws', host: host, port: port);

void main() {
  group('WebJoinTarget.tryParse', () {
    test('IP alone: default WebSocket port 4748', () {
      expect(WebJoinTarget.tryParse(' 192.168.1.20 ')!.uri, _ws('192.168.1.20', klunkiDefaultWebSocketPort));
      expect(klunkiDefaultWebSocketPort, 4748);
    });

    test('IP:port: the port is the WebSocket port', () {
      final t = WebJoinTarget.tryParse('192.168.1.20:5000')!;
      expect(t.uri, _ws('192.168.1.20', 5000));
      expect(t.address, '192.168.1.20:5000');
      expect(t.label, '192.168.1.20:5000');
    });

    test('host names work like IPs', () {
      expect(WebJoinTarget.tryParse('my-computer.local')!.uri, _ws('my-computer.local', 4748));
    });

    test('klunki:// link uses w=, with name and game', () {
      const p = JoinPayload(host: '10.0.0.7', port: 4747, name: 'Stefans iPhone', gameId: 'muehle', wsPort: 4749);
      final t = WebJoinTarget.tryParse(p.format())!;
      expect(t.uri, _ws('10.0.0.7', 4749));
      expect(t.name, 'Stefans iPhone');
      expect(t.gameId, 'muehle');
      expect(t.label, 'Stefans iPhone');
    });

    test('klunki:// link without w=: 4748 (not the TCP port)', () {
      expect(WebJoinTarget.tryParse('klunki://join?h=10.0.0.7&p=4747&v=3')!.uri, _ws('10.0.0.7', 4748));
    });

    test('klunki:// link with another protocol version is refused', () {
      expect(WebJoinTarget.tryParse('klunki://join?h=10.0.0.7&v=1&w=4748'), isNull);
    });

    test('ws:// URL as is (path dropped); without port: 4748', () {
      expect(WebJoinTarget.tryParse('ws://192.168.1.20:4800/')!.uri, _ws('192.168.1.20', 4800));
      expect(WebJoinTarget.tryParse('WS://192.168.1.20')!.uri, _ws('192.168.1.20', 4748));
    });

    test('a pasted PWA link with ?join= unwraps it', () {
      final link = Uri.encodeQueryComponent('klunki://join?h=10.0.0.7&p=4747&w=4750&n=iPad');
      final t = WebJoinTarget.tryParse('http://192.168.1.5:8000/?join=$link&lang=de')!;
      expect(t.uri, _ws('10.0.0.7', 4750));
      expect(t.name, 'iPad');
    });

    test('rejects nonsense, wss://, other schemes and bad ports', () {
      for (final bad in [
        '',
        '   ',
        'not an address',
        '999.1.1.1',
        '192.168.1.20:0',
        '192.168.1.20:70000',
        '192.168.1.20:abc',
        'wss://192.168.1.20:4748',
        'tcp://192.168.1.20',
        'http://192.168.1.5:8000/',
        'klunki://join?p=4747',
        'klunki://join?h=10.0.0.7&w=0',
      ]) {
        expect(WebJoinTarget.tryParse(bad), isNull, reason: bad);
      }
    });
  });

  test('joinParameter reads ?join= from the page URL (decoded)', () {
    final link = 'klunki://join?h=10.0.0.7&p=4747&w=4748';
    final url = Uri.parse('http://localhost:8000/?join=${Uri.encodeQueryComponent(link)}&lang=de');
    expect(WebJoinTarget.joinParameter(url), link);
    expect(WebJoinTarget.joinParameter(Uri.parse('http://localhost:8000/?join=')), isNull);
    expect(WebJoinTarget.joinParameter(Uri.parse('http://localhost:8000/')), isNull);
    expect(WebJoinTarget.joinParameter(null), isNull);
  });
}

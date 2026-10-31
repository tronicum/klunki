// KLD-052: what a scanned QR code means for the join tab.
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/net/scanned_join_code.dart';

void main() {
  group('native host (klunki://)', () {
    test('the payload the host QR encodes round-trips, incl. w=', () {
      const p = JoinPayload(host: '192.168.1.20', port: 4747, name: 'Anna', gameId: 'muehle', wsPort: 4749);
      expect(parseScannedJoinCode(p.format()), const ScannedDirectJoin(p));
    });

    test('defaults and surrounding whitespace', () {
      expect(parseScannedJoinCode('  klunki://join?h=10.0.0.7\n'),
          const ScannedDirectJoin(JoinPayload(host: '10.0.0.7')));
      expect(parseScannedJoinCode('KLUNKI://join?h=pc.local&p=5000'),
          const ScannedDirectJoin(JoinPayload(host: 'pc.local', port: 5000)));
    });

    test('bad host, port, ws port or action', () {
      for (final s in [
        'klunki://join?h=999.1.1.1',
        'klunki://join?p=4747',
        'klunki://join?h=10.0.0.7&p=70000',
        'klunki://join?h=10.0.0.7&w=abc',
        'klunki://host?h=10.0.0.7',
      ]) {
        expect(parseScannedJoinCode(s), isNull, reason: s);
      }
    });

    test('a PWA link with ?join=<klunki:// link>', () {
      const p = JoinPayload(host: '192.168.1.20', wsPort: 4748);
      final link = Uri.parse('http://192.168.1.5:8000/').replace(queryParameters: {'join': p.format()});
      expect(parseScannedJoinCode('$link'), const ScannedDirectJoin(p));
      // ?join=IP:port is a WebSocket port for browsers, not the app's TCP port.
      expect(parseScannedJoinCode('http://192.168.1.5:8000/?join=192.168.1.20:4748'), isNull);
    });
  });

  group('browser host (room link)', () {
    test('roomJoinLink in the browser: relay = the page itself', () {
      final relay = Uri.parse('ws://192.168.1.5:8000/relay');
      final link = roomJoinLink(code: 'K7Q2M', relay: relay, pageUrl: Uri.parse('http://192.168.1.5:8000/'));
      expect(link.queryParameters.containsKey('relay'), isFalse);
      expect(parseScannedJoinCode('$link'), ScannedRoomJoin('K7Q2M', relay));
    });

    test('&relay= wins over the page', () {
      final relay = Uri.parse('ws://10.0.0.9:4749/relay');
      final link = roomJoinLink(code: 'K7Q2M', relay: relay, pageUrl: Uri.parse('http://192.168.1.5:8000/'));
      expect(link.queryParameters['relay'], '10.0.0.9:4749');
      expect(parseScannedJoinCode('$link'), ScannedRoomJoin('K7Q2M', relay));
    });

    test('https gives wss; no port keeps none; code normalised', () {
      expect(parseScannedJoinCode('https://klunki.example/?room=k7q-2m'),
          ScannedRoomJoin('K7Q2M', Uri.parse('wss://klunki.example/relay')));
    });

    test('roomJoinLink without a page (relay origin)', () {
      final relay = Uri.parse('ws://192.168.1.5:4749/relay');
      expect(parseScannedJoinCode('${roomJoinLink(code: 'ABCDE', relay: relay)}'), ScannedRoomJoin('ABCDE', relay));
    });

    test('bad code or relay', () {
      for (final s in [
        'http://192.168.1.5:8000/?room=K7Q', // too short
        'http://192.168.1.5:8000/?room=K7Q0M', // 0 is not in the alphabet
        'http://192.168.1.5:8000/?room=K7Q2M&relay=ftp://x',
        'http://999.1.1.1:8000/?room=K7Q2M', // bad page host
      ]) {
        expect(parseScannedJoinCode(s), isNull, reason: s);
      }
    });
  });

  test('not a Klunki code', () {
    for (final s in [
      '',
      '   ',
      'hello',
      '192.168.1.20:4747', // plain text: no host shows this as a QR
      'https://example.com/',
      'https://example.com/?foo=bar',
      'ws://192.168.1.20:4748',
      'mailto:a@b.c',
      'WIFI:S:home;T:WPA;P:secret;;',
      'http://[::1',
    ]) {
      expect(parseScannedJoinCode(s), isNull, reason: s);
    }
  });
}

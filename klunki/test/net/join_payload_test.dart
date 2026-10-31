import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki_net/klunki_net.dart' as net;

void main() {
  test('mirrored protocol version and ports match klunki_net', () {
    expect(klunkiProtocolVersion, net.protocolVersion);
    expect(klunkiDefaultPort, net.defaultTcpPort);
    expect(klunkiDefaultWebSocketPort, net.defaultWebSocketPort);
  });

  group('WebSocket port w= (KLD-054)', () {
    test('is formatted and parsed', () {
      const p = JoinPayload(host: '192.168.1.20', name: 'iPad', gameId: 'muehle', wsPort: 4748);
      expect(p.format(), 'klunki://join?h=192.168.1.20&p=4747&v=1&n=iPad&g=muehle&w=4748');
      expect(JoinPayload.tryParse(p.format()), p);
      expect(p.webSocketUri.toString(), 'ws://192.168.1.20:4748');
      expect(JoinPayload.fromHostInfo(p.toHostInfo()), p);
    });

    test('is optional (old payloads still parse, no WebSocket URI)', () {
      final p = JoinPayload.tryParse('klunki://join?h=10.1.2.3&p=4747&v=1')!;
      expect(p.wsPort, isNull);
      expect(p.webSocketUri, isNull);
      expect(JoinPayload.tryParse('klunki://join?h=10.1.2.3&w=')!.wsPort, isNull);
    });

    test('a bad w makes the payload invalid', () {
      for (final w in ['0', '65536', 'x', '-1']) {
        expect(JoinPayload.tryParse('klunki://join?h=10.1.2.3&w=$w'), isNull, reason: w);
      }
    });
  });

  group('format', () {
    test('canonical URI with all fields', () {
      const p = JoinPayload(host: '192.168.1.20', port: 47474, name: 'Stefans iPhone', gameId: 'muehle');
      expect(p.format(), 'klunki://join?h=192.168.1.20&p=47474&v=1&n=Stefans+iPhone&g=muehle');
      expect(p.address, '192.168.1.20:47474');
    });

    test('omits empty optional fields', () {
      expect(const JoinPayload(host: '10.0.0.5', name: '', gameId: '').format(), 'klunki://join?h=10.0.0.5&p=4747&v=1');
    });
  });

  group('round trip', () {
    for (final p in const [
      JoinPayload(host: '192.168.1.20', port: 47474, name: 'Stefans iPhone', gameId: 'muehle'),
      JoinPayload(host: '10.0.0.5'),
      JoinPayload(host: 'stefans-mac.local', port: 1, protocol: 7, name: 'Ä & ö = ü?#'),
      JoinPayload(host: '172.20.10.1', port: 65535, gameId: 'connect4'),
    ]) {
      test(p.format(), () => expect(JoinPayload.tryParse(p.format()), p));
    }

    test('via KlunkiHostInfo', () {
      const info = KlunkiHostInfo(name: 'iPad', host: '192.168.0.7', port: 5000, protocol: 1, gameId: 'schiffe');
      final p = JoinPayload.fromHostInfo(info);
      expect(JoinPayload.tryParse(p.format())!.toHostInfo(), info);
    });

    test('nameless payload gets host:port as display name', () {
      expect(const JoinPayload(host: '10.0.0.5').toHostInfo().name, '10.0.0.5:4747');
    });
  });

  group('tryParse accepts', () {
    test('host:port', () => expect(JoinPayload.tryParse('192.168.1.20:47474'), const JoinPayload(host: '192.168.1.20', port: 47474)));
    test('plain IP with default port', () {
      expect(JoinPayload.tryParse(' 192.168.1.20 '), const JoinPayload(host: '192.168.1.20', port: klunkiDefaultPort));
      expect(klunkiDefaultPort, 4747);
    });
    test('host name', () => expect(JoinPayload.tryParse('ipad.local:4747')?.host, 'ipad.local'));
    test('URI without p/v uses defaults', () {
      expect(JoinPayload.tryParse('klunki://join?h=10.1.2.3'), const JoinPayload(host: '10.1.2.3'));
    });
    test('URI with percent-encoded name', () {
      expect(JoinPayload.tryParse('klunki://join?h=10.1.2.3&n=Stefans%20iPhone')?.name, 'Stefans iPhone');
    });
  });

  group('tryParse rejects', () {
    for (final bad in [
      '',
      '   ',
      'hello world',
      '999.1.1.1',
      '1.2.3',
      '1.2.3.4.5',
      '192.168.1.20:',
      '192.168.1.20:0',
      '192.168.1.20:65536',
      '192.168.1.20:12ab',
      '192.168.1.20:-1',
      ':4747',
      '-bad-.local',
      'http://192.168.1.20:4747',
      'klunki://join',
      'klunki://join?p=4747',
      'klunki://join?h=bad%20host',
      'klunki://join?h=1.2.3.4&p=99999',
      'klunki://join?h=1.2.3.4&v=one',
      'klunki://play?h=1.2.3.4',
      'klunki://join?h=[::1]',
      '::1',
    ]) {
      test('"$bad"', () => expect(JoinPayload.tryParse(bad), isNull));
    }
  });
}

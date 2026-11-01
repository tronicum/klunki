// KLD-057b: room codes, `?room=` links and the relay error classification.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/ui/pairing/relay_errors.dart';
import 'package:klunki_net/klunki_net.dart';

void main() {
  test('KLD-096: an https page cannot open ws:// (except loopback); http pages and natively it can', () {
    final https = Uri.parse('https://user.github.io/klunki/');
    bool blocks(Uri? page, String target) => browserBlocksWebSocket(pageUrl: page, target: Uri.parse(target));
    expect(blocks(https, 'ws://192.168.1.20:8081/relay'), isTrue);
    expect(blocks(https, 'ws://pc.local:4748'), isTrue);
    expect(blocks(https, 'wss://relay.example/relay'), isFalse);
    expect(blocks(https, 'ws://localhost:8081/relay'), isFalse);
    expect(blocks(https, 'ws://127.0.0.1:8081/relay'), isFalse);
    expect(blocks(Uri.parse('http://192.168.1.20:8081/'), 'ws://192.168.1.20:8081/relay'), isFalse);
    expect(blocks(null, 'ws://192.168.1.20:8081/relay'), isFalse);
  });

  group('KLD-083: loopback hosts', () {
    test('localhost, 127.x, ::1 and *.localhost are loopback', () {
      for (final h in ['localhost', 'LOCALHOST', '127.0.0.1', '127.1.2.3', '::1', '[::1]', '0:0:0:0:0:0:0:1',
          '::ffff:127.0.0.1', 'foo.localhost', 'localhost.']) {
        expect(isLoopbackHost(h), isTrue, reason: h);
      }
    });
    test('LAN IPs, .local names and hostnames are not', () {
      for (final h in ['192.168.1.20', '10.0.0.9', 'fd00::5', 'fe80::1', 'pc.local', 'klunki.example',
          'localhost.example', 'mylocalhost', '128.0.0.1', '']) {
        expect(isLoopbackHost(h), isFalse, reason: h);
      }
    });
    test('loopbackHostOf: the page host in the browser, else the relay host', () {
      final lan = Uri.parse('ws://192.168.1.5:8081/relay');
      final local = Uri.parse('ws://localhost:8081/relay');
      expect(loopbackHostOf(relay: local, pageUrl: Uri.parse('http://localhost:8081/')), 'localhost');
      expect(loopbackHostOf(relay: lan, pageUrl: Uri.parse('http://127.0.0.1:8081/')), '127.0.0.1');
      expect(loopbackHostOf(relay: Uri.parse('ws://[::1]:8081/relay'), pageUrl: Uri.parse('http://[::1]:8081/')),
          '::1');
      expect(loopbackHostOf(relay: local, pageUrl: Uri.parse('http://192.168.1.5:8081/')), 'localhost');
      expect(loopbackHostOf(relay: lan, pageUrl: Uri.parse('http://192.168.1.5:8081/')), isNull);
      expect(loopbackHostOf(relay: Uri.parse('ws://pc.local:8081/relay'), pageUrl: Uri.parse('http://pc.local:8081/')),
          isNull);
      expect(loopbackHostOf(relay: local), 'localhost'); // native
      expect(loopbackHostOf(relay: lan), isNull);
    });
    test('IPv6 relay labels keep their brackets', () {
      expect(relayAddressLabel(Uri.parse('ws://[::1]:8081/relay')), '[::1]:8081');
      expect(relayAddressLabel(Uri.parse('ws://pc.local:8081/relay')), 'pc.local:8081');
    });
  });

  group('formatRoomCode', () {
    test('groups 3 + 2 and normalises', () {
      expect(formatRoomCode('K7Q2M'), 'K7Q 2M');
      expect(formatRoomCode('k7q-2m'), 'K7Q 2M');
    });
    test('leaves invalid input unchanged', () {
      expect(formatRoomCode('K7Q0M'), 'K7Q0M');
      expect(formatRoomCode(''), '');
    });
  });

  group('RoomLink.fromPage', () {
    test('no or empty room parameter', () {
      expect(RoomLink.fromPage(null), isNull);
      expect(RoomLink.fromPage(Uri.parse('http://h:8000/')), isNull);
      expect(RoomLink.fromPage(Uri.parse('http://h:8000/?room=')), isNull);
      expect(RoomLink.fromPage(Uri.parse('http://h:8000/?join=x')), isNull);
    });
    test('valid code, case and dashes do not matter', () {
      final l = RoomLink.fromPage(Uri.parse('http://h:8000/?room=k7q-2m&lang=de'))!;
      expect(l.code, 'K7Q2M');
      expect(l.relay, isNull);
      expect(l.raw, 'k7q-2m');
    });
    test('invalid code keeps the raw text', () {
      final l = RoomLink.fromPage(Uri.parse('http://h:8000/?room=OOPS1'))!;
      expect(l.code, isNull);
      expect(l.raw, 'OOPS1');
    });
    test('explicit relay', () {
      final l = RoomLink.fromPage(Uri.parse('http://h:8000/?room=K7Q2M&relay=10.0.0.9:4749'))!;
      expect(l.relay, Uri.parse('ws://10.0.0.9:4749/relay'));
      expect(RoomLink.fromPage(Uri.parse('http://h/?room=K7Q2M&relay=ftp://x'))!.relay, isNull);
    });
  });

  group('roomJoinLink', () {
    final pageRelay = Uri.parse('ws://192.168.1.5:8000/relay');
    test('page served by the relay: just ?room=', () {
      final link = roomJoinLink(code: 'K7Q2M', relay: pageRelay, pageUrl: Uri.parse('http://192.168.1.5:8000/#/'));
      expect(link.toString(), 'http://192.168.1.5:8000/?room=K7Q2M');
      expect(RoomLink.fromPage(link)!.code, 'K7Q2M');
    });
    test('other relay: &relay= so the guest page uses it too', () {
      final link = roomJoinLink(
          code: 'K7Q2M', relay: Uri.parse('ws://10.0.0.9:4749/relay'), pageUrl: Uri.parse('http://192.168.1.5:8080/'));
      expect(link.toString(), 'http://192.168.1.5:8080/?room=K7Q2M&relay=10.0.0.9%3A4749');
      expect(RoomLink.fromPage(link)!.relay, Uri.parse('ws://10.0.0.9:4749/relay'));
    });
    test('no page (app): the relay origin over http', () {
      expect(roomJoinLink(code: 'K7Q2M', relay: Uri.parse('ws://10.0.0.9:4749/relay')).toString(),
          'http://10.0.0.9:4749/?room=K7Q2M');
      expect(roomJoinLink(code: 'K7Q2M', relay: Uri.parse('wss://r.example/relay')).toString(),
          'https://r.example/?room=K7Q2M');
    });
  });

  test('relayAddressLabel', () {
    expect(relayAddressLabel(Uri.parse('ws://10.0.0.9:4749/relay')), '10.0.0.9:4749');
    expect(relayAddressLabel(Uri.parse('wss://r.example/relay')), 'wss://r.example/relay');
  });

  group('classifyRelayError', () {
    final cases = <Object, RelayFailure?>{
      const NetException('relay: no room with code K7Q2M'): RelayFailure.unknownCode,
      const NetException('relay: room K7Q2M is full'): RelayFailure.roomFull,
      const NetException('peer error: session full'): RelayFailure.seatTaken, // KLD-071
      'relay: host left': RelayFailure.hostLeft,
      'relay: room expired (idle)': RelayFailure.expired,
      const NetException('cannot connect: cannot open ws://h:8080/relay?create'): RelayFailure.unreachable,
      const NetException('relay closed the connection'): RelayFailure.unreachable,
      const NetException('not a Klunki relay (unexpected first message)'): RelayFailure.unreachable,
      TimeoutException('x'): RelayFailure.unreachable,
      'relay: relay shutting down': RelayFailure.lost,
      'relay connection lost': RelayFailure.lost,
      'handshake timed out': null,
      'peer left: bye': null,
    };
    for (final MapEntry(key: error, value: failure) in cases.entries) {
      test('$error → $failure', () => expect(classifyRelayError(error), failure));
    }
    test('closed rooms', () {
      expect(relayRoomClosed(RelayFailure.hostLeft), isTrue);
      expect(relayRoomClosed(RelayFailure.expired), isTrue);
      expect(relayRoomClosed(RelayFailure.unknownCode), isFalse);
      expect(relayRoomClosed(null), isFalse);
    });
  });
}

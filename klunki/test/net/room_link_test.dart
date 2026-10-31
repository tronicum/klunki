// KLD-057b: room codes, `?room=` links and the relay error classification.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/ui/pairing/relay_errors.dart';
import 'package:klunki_net/klunki_net.dart';

void main() {
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

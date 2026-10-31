import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/fake_discovery.dart';

const host = KlunkiHostInfo(name: 'Stefans iPhone', host: '', port: 4747, protocol: 1, gameId: 'muehle');

void main() {
  test('a guest sees a host appear, update and disappear', () async {
    final network = FakeNetwork();
    final hostSide = FakeDiscovery(network: network, address: '192.168.1.20');
    final guestSide = FakeDiscovery(network: network);
    final seen = <List<KlunkiHostInfo>>[];
    final sub = guestSide.browse().listen(seen.add);
    await pumpEventQueue();

    await hostSide.advertise(host);
    await hostSide.advertise(host.copyWith(gameId: 'connect4'));
    await hostSide.stopAdvertising();
    await pumpEventQueue();

    expect(seen, [
      <KlunkiHostInfo>[],
      [host.copyWith(host: '192.168.1.20')],
      [host.copyWith(host: '192.168.1.20', gameId: 'connect4')],
      <KlunkiHostInfo>[],
    ]);
    expect(hostSide.advertiseCalls, hasLength(2));
    await sub.cancel();
  });

  test('own advertisement is not listed', () async {
    final d = FakeDiscovery();
    await d.advertise(host);
    expect(await d.browse().first, isEmpty);
    expect(d.advertised?.name, 'Stefans iPhone');
  });

  test('late listeners get the current list first', () async {
    final network = FakeNetwork();
    await FakeDiscovery(network: network, address: '10.0.0.2').advertise(host);
    final guest = FakeDiscovery(network: network);
    guest.browse(); // started earlier, e.g. by another widget
    expect(await guest.browse().first, [host.copyWith(host: '10.0.0.2')]);
  });

  test('addHost / removeHost emit add and remove, sorted by name', () async {
    final d = FakeDiscovery();
    final seen = <List<String>>[];
    final sub = d.browse().listen((l) => seen.add([for (final h in l) h.name]));
    await pumpEventQueue();
    d.addHost(host.copyWith(name: 'b', host: '10.0.0.2'));
    d.addHost(host.copyWith(name: 'A', host: '10.0.0.3'), id: 'a');
    d.addHost(host.copyWith(name: 'A', host: '10.0.0.3'), id: 'a'); // unchanged: no emit
    d.removeHost('10.0.0.2:4747');
    d.removeHost('missing'); // no emit
    await pumpEventQueue();
    expect(seen, [
      <String>[],
      ['b'],
      ['A', 'b'],
      ['A'],
    ]);
    await sub.cancel();
  });

  test('stopBrowsing empties the list and stops updates; browse restarts', () async {
    final network = FakeNetwork();
    final hostSide = FakeDiscovery(network: network, address: '10.0.0.9');
    final guest = FakeDiscovery(network: network);
    await hostSide.advertise(host);
    final seen = <int>[];
    final sub = guest.browse().listen((l) => seen.add(l.length));
    await pumpEventQueue();
    await guest.stopBrowsing();
    expect(guest.isBrowsing, isFalse);
    await hostSide.advertise(host.copyWith(port: 5000)); // not seen while stopped
    await pumpEventQueue();
    expect(seen, [1, 0]);
    expect((await guest.browse().first).single.port, 5000);
    await sub.cancel();
  });

  test('dispose withdraws the advertisement and closes the stream', () async {
    final network = FakeNetwork();
    final hostSide = FakeDiscovery(network: network);
    final guest = FakeDiscovery(network: network);
    await hostSide.advertise(host);
    final guestLists = <int>[];
    final guestSub = guest.browse().listen((l) => guestLists.add(l.length));
    final done = Completer<void>();
    hostSide.browse().listen(null, onDone: done.complete);
    await hostSide.dispose();
    await done.future;
    await pumpEventQueue();
    expect(guestLists, [1, 0]);
    await guestSub.cancel();
  });

  group('TXT record', () {
    test('round trip', () {
      final txt = klunkiTxtRecord(host);
      expect(txt, {'v': '1', 'name': 'Stefans iPhone', 'game': 'muehle'});
      expect(hostInfoFromTxt(serviceName: 'Stefans iPhone #1234', host: '10.0.0.2', port: 4747, txt: txt),
          host.copyWith(host: '10.0.0.2'));
    });

    test('the WebSocket port travels as "ws" (KLD-054)', () {
      const host = KlunkiHostInfo(name: 'iPad', host: '', port: 4747, protocol: 1, wsPort: 4748);
      final txt = klunkiTxtRecord(host);
      expect(txt, {'v': '1', 'name': 'iPad', 'ws': '4748'});
      expect(hostInfoFromTxt(serviceName: 'iPad #1', host: '10.0.0.2', port: 4747, txt: txt),
          host.copyWith(host: '10.0.0.2'));
      expect(hostInfoFromTxt(serviceName: 's', host: 'h', port: 1, txt: {'ws': 'nope'}).wsPort, isNull);
    });

    test('missing fields fall back', () {
      final info = hostInfoFromTxt(serviceName: 'svc', host: '10.0.0.2', port: 1, txt: {'v': 'x', 'game': ''});
      expect(info, const KlunkiHostInfo(name: 'svc', host: '10.0.0.2', port: 1, protocol: 0));
    });
  });
}

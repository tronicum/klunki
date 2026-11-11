// KLD-126: the chess clock over the network. The host keeps the
// authoritative clock: it starts when the guest joins, travels in every
// `accepted` and `welcome`, stands still while the guest is away, and the
// host plays `timeout` when a flag falls. The guest's moves carry its own
// think time; the host charges it within `clockLagCreditMs` of its own
// measure. The pause is two ordinary moves (request, agree).
@Timeout(Duration(seconds: 60))
library;

import 'package:klunki_engine/klunki_engine.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:test/test.dart';

import 'support.dart';

const _five = GameConfig('chess', chessClock: ChessTimeControl(5 * 60000));
const _inc = GameConfig('chess', chessClock: ChessTimeControl(5 * 60000, 2000));

Map<String, dynamic> _mv(String from, String to) => {'action': 'move', 'from': from, 'to': to};

/// A host and a guest whose clocks read [hostNow] / [guestNow] (ms).
Future<(KlunkiHost, KlunkiGuest)> _pair(GameConfig config, int Function() hostNow, int Function() guestNow) async {
  final host = await startHost(config);
  host.debugClockNow = hostNow;
  final guest = await joinHost(host.port);
  guest.debugClockNow = guestNow;
  await until(() => host.guestConnected);
  return (host, guest);
}

void main() {
  test('chess with a clock: rules version 4, the time control is config', () {
    expect(fingerprintOf(_five)!.rules, 4);
    expect(fingerprintOf(_five), fingerprintOf(const GameConfig('chess')), reason: 'one game, the clock is config');
  });

  test('no clock without a time control: no "clock" field, no think time', () async {
    final host = await startHost(const GameConfig('chess'));
    final peer = await RawPeer.connect(host.port);
    peer.send('hello', guestHello('Raw'));
    final welcome = await peer.next('welcome');
    expect(welcome.containsKey('clock'), isFalse);
    expect(host.clock, isNull);
    host.submitLocal(_mv('e2', 'e4'));
    expect((await peer.next('accepted')).containsKey('clock'), isFalse);
    peer.destroy();
    await host.close();
  });

  test('the clock starts when the guest joins and travels with welcome and accepted', () async {
    var h = 0, g = 0;
    final host = await startHost(_inc);
    host.debugClockNow = () => h;
    h = 5000; // waiting for the guest costs nothing
    expect(host.clock!.running, isNull);
    final peer = await RawPeer.connect(host.port);
    peer.send('hello', guestHello('Raw'));
    final welcome = await peer.next('welcome');
    expect(welcome['clock'], {'a': 300000, 'b': 300000, 'run': 'a', 'paused': false, 'spent': 0});
    h += 3000;
    expect(host.submitLocal(_mv('e2', 'e4')), isNull);
    final accepted = await peer.next('accepted');
    expect(accepted['clock'], {'a': 299000, 'b': 300000, 'run': 'b', 'paused': false, 'spent': 0}); // -3 s +2 s
    peer.destroy();
    await host.close();
    // The guest's copy follows the host's.
    final host2 = await startHost(_five);
    host2.debugClockNow = () => h;
    final guest = await joinHost(host2.port);
    final copy = guest.clock!.snapshot(guest.clockNow()); // the guest's own stopwatch
    expect(copy.a, closeTo(300000, 1000));
    expect((copy.b, copy.running, copy.paused), (300000, Player.a, false));
    guest.debugClockNow = () => g;
    host2.submitLocal(_mv('e2', 'e4'));
    await until(() => guest.moves.length == 1);
    expect(guest.clock!.snapshot(g), host2.clock!.snapshot(h));
    h += 1000;
    g += 1000;
    expect(guest.clock!.remainingOf(Player.b, g), 299000);
    await guest.close();
    await host2.close();
  });

  test('delay compensation: the guest\'s own think time within the lag credit; a cheat gains at most the credit',
      () async {
    var h = 0, g = 0;
    final (host, guest) = await _pair(_five, () => h, () => g);
    host.submitLocal(_mv('e2', 'e4'));
    await until(() => guest.moves.length == 1);
    // The guest thinks 2 s; the host measures 2.6 s (the network both ways).
    g += 2000;
    h += 2600;
    expect(await guest.submit(_mv('e7', 'e5')), isNull);
    expect(host.clock!.remainingOf(Player.b, h), 298000, reason: 'charged the guest\'s 2 s');
    expect(guest.clock!.remainingOf(Player.b, g), 298000);
    host.submitLocal(_mv('g1', 'f3'));
    await until(() => guest.moves.length == 3);
    // A cheating guest claims 0 ms after 10 s: charged 10 s - 1 s credit.
    h += 10000;
    g += 10000;
    guest.debugThink = 0;
    expect(await guest.submit(_mv('b8', 'c6')), isNull);
    expect(host.clock!.remainingOf(Player.b, h), 298000 - 9000);
    // Claiming more than the host measured costs only what the host measured.
    host.submitLocal(_mv('f1', 'c4'));
    await until(() => guest.moves.length == 5);
    h += 1000;
    guest.debugThink = 60000;
    expect(await guest.submit(_mv('g8', 'f6')), isNull);
    expect(host.clock!.remainingOf(Player.b, h), 289000 - 1000);
    await guest.close();
    await host.close();
  });

  test('a guest cannot call time; the host flags itself and the guest on its clock', () async {
    final host = await startHost(const GameConfig('chess', chessClock: ChessTimeControl(1000)));
    host.clockLagCreditMs = 300;
    final guest = await joinHost(host.port);
    await until(() => host.guestConnected);
    expect(await guest.submit(ChessGame.timeoutMove(Player.b)), 'only the host calls time');
    expect(await guest.submit(ChessGame.timeoutMove(Player.a)), isNotNull);
    // Nobody moves: the host (White) runs out of its second.
    await until(() => host.game.isOver, limit: const Duration(seconds: 10));
    expect(host.moves.last, ChessGame.timeoutMove(Player.a));
    expect(host.game.result.code, GameEndReason.chessTimeout);
    expect(host.game.result.winner, Player.b);
    await until(() => guest.game.isOver);
    expect(guest.game.result.code, GameEndReason.chessTimeout);
    expect(guest.clock!.running, isNull);
    expect(host.clock!.remainingOf(Player.a, host.clockNow()), lessThanOrEqualTo(0));
    await guest.close();
    await host.close();

    // The guest flags after its time plus the lag credit.
    final host2 = await startHost(const GameConfig('chess', chessClock: ChessTimeControl(1000)));
    host2.clockLagCreditMs = 300;
    final guest2 = await joinHost(host2.port);
    await until(() => host2.guestConnected);
    expect(host2.submitLocal(_mv('e2', 'e4')), isNull);
    final sw = Stopwatch()..start();
    await until(() => host2.game.isOver, limit: const Duration(seconds: 10));
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(1000 + 300 - 50));
    expect(host2.game.result.winner, Player.a);
    // A move that arrives after the flag fell ends the game on time too.
    expect(await guest2.submit(_mv('e7', 'e5')), isNotNull);
    await guest2.close();
    await host2.close();
  });

  test('a late move after the flag: the host refuses it and plays timeout', () async {
    var h = 0, g = 0;
    final (host, guest) = await _pair(const GameConfig('chess', chessClock: ChessTimeControl(5000)), () => h, () => g);
    host.submitLocal(_mv('e2', 'e4'));
    await until(() => guest.moves.length == 1);
    h += 7000; // the guest's 5 s and the 1 s credit are gone on the host
    g += 7000;
    expect(await guest.submit(_mv('e7', 'e5')), isNotNull);
    await until(() => guest.game.isOver);
    expect(host.moves.last, ChessGame.timeoutMove(Player.b));
    expect(guest.game.result.code, GameEndReason.chessTimeout);
    await guest.close();
    await host.close();
  });

  test('reconnect: the clocks stand still while the guest is away and the welcome brings them back', () async {
    var h = 0, g = 0;
    final host = await startHost(_five);
    host.debugClockNow = () => h;
    final proxy = await Proxy.start(host.port);
    final guest = await KlunkiGuest.connect(loopback, proxy.port, name: 'Guest');
    guest.debugClockNow = () => g;
    await until(() => host.guestConnected);
    host.submitLocal(_mv('e2', 'e4'));
    await until(() => guest.moves.length == 1);
    h += 4000;
    g += 4000;
    proxy.cut();
    await until(() => !host.guestConnected && !guest.connected);
    final away = host.clock!.snapshot(h);
    expect(away.paused, isTrue, reason: 'held');
    expect(away.b, 296000);
    expect(guest.clock!.ticking, isFalse, reason: 'the guest\'s copy stops too');
    h += 60000; // a minute away costs nothing
    g += 60000;
    await guest.reconnect();
    await until(() => host.guestConnected);
    final back = host.clock!.snapshot(h);
    expect(back, const ChessClockSnapshot(a: 300000, b: 296000, running: Player.b, spent: 4000));
    expect(guest.clock!.snapshot(g), back);
    // The think time still counts from the start of the turn.
    h += 1000;
    g += 1000;
    expect(await guest.submit(_mv('e7', 'e5')), isNull);
    expect(host.clock!.remainingOf(Player.b, h), 295000);
    await guest.close();
    await host.close();
    await proxy.close();
  });

  test('pause by agreement: requested by the guest, agreed by the host; both clocks stop until resumed', () async {
    var h = 0, g = 0;
    final (host, guest) = await _pair(_five, () => h, () => g);
    h += 2000;
    g += 2000;
    expect(await guest.submit(ChessGame.clockMove(ChessGame.clockPause, Player.b)), isNull);
    expect(host.clock!.ticking, isTrue, reason: 'a request does not stop the clock');
    expect(host.submitLocal(ChessGame.clockMove(ChessGame.clockAgree, Player.a)), isNull);
    await until(() => guest.moves.length == 2);
    expect(host.clock!.snapshot(h).paused, isTrue);
    expect(guest.clock!.snapshot(g).paused, isTrue);
    h += 600000;
    g += 600000;
    expect(host.submitLocal(_mv('e2', 'e4')), 'illegal move', reason: 'paused');
    expect(host.clock!.remainingOf(Player.a, h), 298000);
    // Going on needs the other one too.
    expect(host.submitLocal(ChessGame.clockMove(ChessGame.clockResume, Player.a)), isNull);
    await until(() => guest.moves.length == 3);
    expect(await guest.submit(ChessGame.clockMove(ChessGame.clockAgree, Player.b)), isNull);
    expect(host.clock!.ticking, isTrue);
    h += 1000;
    expect(host.submitLocal(_mv('e2', 'e4')), isNull);
    expect(host.clock!.remainingOf(Player.a, h), 297000);
    await guest.close();
    await host.close();
  });
}

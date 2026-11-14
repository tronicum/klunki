import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/saves/autosave.dart';
import 'package:klunki/saves/save_store.dart';
import 'package:klunki/saves/saved_game.dart';
import 'package:klunki/transport/game_transport.dart';
import 'package:klunki/transport/hot_seat_transport.dart';
import 'package:klunki_engine/klunki_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays [n] moves picked from the game's legal moves (seeded, so the test
/// is the same every run).
void playRandom(HotSeatTransport t, int n, {int seed = 1}) {
  final rng = Random(seed);
  for (var i = 0; i < n && !t.game.isOver; i++) {
    final legal = ((t.game as dynamic).legalMoves as List).cast<Map<String, dynamic>>();
    // No resigns: the game should go on.
    final moves = [for (final m in legal) if (m['action'] != 'resign') m];
    if (moves.isEmpty) break;
    expect(t.submitSync(moves[rng.nextInt(moves.length)]).isAccepted, isTrue);
  }
}

/// Saves [t] through a store, reloads it from the same preferences (an app
/// restart) and rebuilds the game from the save.
Future<HotSeatTransport> roundTrip(HotSeatTransport t, {List<String?> names = const [], int Function()? now}) async {
  final prefs = await SharedPreferences.getInstance();
  final store = await SaveStore.load(prefs: prefs);
  await store.save(SavedGame.now(t.config, [for (final m in t.moves) m.move],
      names: names, clock: t.clock?.snapshot(t.clockNow()), clockBefore: t.clockHistory));
  final reloaded = await SaveStore.load(prefs: prefs);
  final entry = reloaded.entryFor(t.config.gameId)!;
  expect(entry.resumable, isTrue);
  final save = entry.game!;
  expect(save.config, t.config);
  expect(save.names, names);
  return HotSeatTransport(save.config,
      log: save.moves, resumeClock: save.clock, resumeClockBefore: save.clockBefore, clockNow: now);
}

String _encode(Object? o) => jsonEncode(o, toEncodable: (x) => x.toString());

void expectSameGame(HotSeatTransport a, HotSeatTransport b) {
  expect(b.moves.length, a.moves.length);
  expect(_encode(b.game.history), _encode(a.game.history));
  expect(b.game.isOver, a.game.isOver);
  expect(_encode((b.game as dynamic).legalMoves), _encode((a.game as dynamic).legalMoves));
}

/// A transport that is not hot-seat (like a network table of KLD-088): the
/// moves come through a hot-seat engine, but the autosave must not see a
/// [HotSeatTransport].
class _TableTransport implements GameTransport {
  _TableTransport(GameConfig config) : inner = HotSeatTransport(config);

  final HotSeatTransport inner;

  @override
  bool get fullInformation => false;
  @override
  GameConfig get config => inner.config;
  @override
  Set<Player> get localPlayers => {Player.a};
  @override
  Game get game => inner.game;
  @override
  List<AcceptedMove> get moves => inner.moves;
  @override
  Stream<AcceptedMove> get accepted => inner.accepted;
  @override
  Future<SubmitResult> submit(Map<String, dynamic> move) async => inner.submitSync(move);
  @override
  void dispose() => inner.dispose();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('round trip through the store', () {
    for (final (config, n) in [
      (const GameConfig('chess', seed: 3), 12),
      (const GameConfig('quartett-trumpf', seed: 42, deck: 'cars'), 6),
      (const GameConfig('maumau', seed: 7), 10),
      (const GameConfig('wordtiles', seed: 9), 4),
      (const GameConfig('wordtiles', seed: 9, players: 3, jokerSwap: true), 5),
      (const GameConfig('property', seed: 5, players: 3), 25),
    ]) {
      test('$config after $n moves', () async {
        final t = HotSeatTransport(config);
        playRandom(t, n, seed: config.seed);
        expect(t.moves, isNotEmpty);
        final names = [for (var s = 0; s < config.players; s++) s == 1 ? null : 'Spieler$s'];
        final back = await roundTrip(t, names: names);
        expectSameGame(t, back);
        // The rebuilt game plays on like the original.
        final legal = ((t.game as dynamic).legalMoves as List).cast<Map<String, dynamic>>();
        if (legal.isNotEmpty) {
          expect(t.submitSync(legal.first).event?.payload, back.submitSync(legal.first).event?.payload);
          expectSameGame(t, back);
        }
      });
    }
  });

  test('chess clock: resumes paused with the saved times, undo keeps working', () async {
    var ms = 0;
    int now() => ms;
    const config = GameConfig('chess', seed: 1, chessClock: ChessTimeControl(300000, 2000));
    final t = HotSeatTransport(config, clockNow: now);
    ms += 4000;
    t.submitSync({'action': 'move', 'from': 'e2', 'to': 'e4'});
    ms += 7000;
    t.submitSync({'action': 'move', 'from': 'e7', 'to': 'e5'});
    ms += 1500; // White thinks 1.5 s, then the app closes
    final before = t.clock!.snapshot(now());
    final back = await roundTrip(t, now: now);
    final clock = back.clock!;
    expect(back.clockPaused, isTrue, reason: 'resumes behind the pause cover');
    expect(clock.remainingOf(Player.a, now()), before.a);
    expect(clock.remainingOf(Player.b, now()), before.b);
    ms += 60000; // the players sit down again: no time runs
    expect(clock.remainingOf(Player.a, now()), before.a);
    back.setClockPaused(false);
    ms += 1000;
    expect(back.clock!.remainingOf(Player.a, now()), before.a - 1000);
    expect(back.clockHistory, hasLength(2));
    // Undo goes back to the clock before Black's move (saved with the game).
    expect(back.undo(), isTrue);
    expect(back.clock!.remainingOf(Player.a, now()), 300000 - 4000 + 2000);
    expect(back.clock!.remainingOf(Player.b, now()), 300000 - 7000);
  });

  test('a save of another rules version or with damaged data is not resumable', () async {
    final save = SavedGame.now(const GameConfig('connect4'), [
      {'col': 3}
    ]);
    final json = save.toJson()..['rulesVersion'] = 99;
    SharedPreferences.setMockInitialValues({
      '${SaveStore.prefsPrefix}connect4': jsonEncode(json),
      '${SaveStore.prefsPrefix}muehle': '{not json',
      '${SaveStore.prefsPrefix}chess': jsonEncode({...save.toJson(), 'format': 2}),
      'otherKey': 'x',
    });
    final store = await SaveStore.load();
    expect(store.length, 3);
    expect(store.entries.every((e) => !e.resumable), isTrue);
    expect(store.entryFor('connect4')!.game!.isOutdated, isTrue);
    expect(store.entryFor('muehle')!.game, isNull);
    await store.remove('muehle');
    expect((await SaveStore.load()).entryFor('muehle'), isNull);
  });

  test('a log that does not replay throws on resume (caught by the menu)', () {
    expect(
        () => HotSeatTransport(const GameConfig('connect4'), log: [
              {'col': 3},
              {'col': 9},
            ]),
        throwsStateError);
  });

  test('one slot per game: a newer save replaces the older, list newest first', () async {
    final store = await SaveStore.load();
    await store.save(SavedGame.now(const GameConfig('connect4', seed: 1), [
      {'col': 1}
    ], savedAt: DateTime(2026, 11, 1)));
    await store.save(SavedGame.now(const GameConfig('muehle'), [
      {'action': 'place', 'to': 0}
    ], savedAt: DateTime(2026, 11, 2)));
    await store.save(SavedGame.now(const GameConfig('connect4', seed: 2), [
      {'col': 2}
    ], savedAt: DateTime(2026, 11, 3)));
    final reloaded = await SaveStore.load();
    expect(reloaded.entries.map((e) => e.gameId), ['connect4', 'muehle']);
    expect(reloaded.entryFor('connect4')!.game!.config.seed, 2);
  });

  testWidgets('a network game (a Wortgewandt table of 3) is never saved', (tester) async {
    final store = SaveStore.memory();
    final transport = _TableTransport(const GameConfig('wordtiles', seed: 9, players: 3));
    final controller = GameController(transport);
    final autosave = GameAutosave(controller: controller, store: store, names: (n) => List.filled(n, null));
    playRandom(transport.inner, 4, seed: 9);
    await tester.pump();
    autosave.saveNow();
    autosave.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(transport.moves, isNotEmpty);
    autosave.dispose();
    expect(store.isEmpty, isTrue);
    controller.dispose();
  });
}

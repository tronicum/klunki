// Wortgewandt over the network (KLD-094 step 6): host (Anna) and guest (Ben)
// as two NetworkGameSessions side by side, real NetworkTransports on
// 127.0.0.1. Each device shows only its own rack and the game's options;
// "Trotzdem zulassen" asks the other device ("Ben entscheidet…"), which
// accepts or declines in a dialog.
@Timeout(Duration(seconds: 90))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/games/wordtiles/wordtiles_board.dart';
import 'package:klunki/ui/pairing/network_game_session.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../l10n/l10n_test_utils.dart';
import '../../support/test_run.dart';

const _hostKey = Key('device-host');
const _guestKey = Key('device-guest');
const _ping = Duration(milliseconds: 100);
const _timeout = Duration(seconds: 30);

Finder _on(Key device, Finder f) => find.descendant(of: find.byKey(device), matching: f);

GameController _controller(WidgetTester tester, Key device) =>
    tester.widget<GameScreen>(_on(device, find.byType(GameScreen))).controller;

WordTilesGame _game(WidgetTester tester, Key device) => _controller(tester, device).game as WordTilesGame;

/// The text of [k] (a Text, or the one Text inside it).
String _text(WidgetTester tester, Key device, Key k) {
  final f = _on(device, find.byKey(k));
  final w = tester.widget(f);
  return w is Text ? w.data! : tester.widget<Text>(find.descendant(of: f, matching: find.byType(Text))).data!;
}

SortedWordListValidator _list(List<String> words) =>
    SortedWordListValidator.fromUtf8(Uint8List.fromList(utf8.encode('${(words.toList()..sort()).join('\n')}\n')));

/// Pumps (fake time) and waits a little real time until [condition] holds.
Future<void> _until(WidgetTester tester, bool Function() condition, String what) async {
  final alive = testRunGuard(tester);
  for (var round = 0;; round++) {
    alive();
    await tester.pump();
    if (condition()) {
      await tester.pump();
      await tester.pump();
      return;
    }
    if (round > 2000) fail('condition not met: $what');
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
  }
}

Future<void> _tap(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pump();
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _start(WidgetTester tester, GameConfig config) async {
  tester.view.physicalSize = const Size(2000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (host, guest) = (await tester.runAsync(() async {
    final h = await NetworkTransport.host(config,
        name: 'Anna', address: InternetAddress.loopbackIPv4, wsPort: null, pingInterval: _ping, timeout: _timeout);
    final g = await NetworkTransport.join(InternetAddress.loopbackIPv4, h.port!,
        name: 'Ben', pingInterval: _ping, timeout: _timeout);
    return (h, g);
  }))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    guest.dispose();
    host.dispose();
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump();
    }
  });
  Widget device(Key key, NetworkTransport t) => Expanded(
        child: KeyedSubtree(key: key, child: localizedApp(NetworkGameSession(transport: t))),
      );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Row(children: [device(_hostKey, host), device(_guestKey, guest)]),
  ));
  await _until(tester, () => _on(_guestKey, find.byType(WordTilesBoard)).evaluate().isNotEmpty, 'guest board');
  await _until(tester, () => _on(_hostKey, find.byType(WordTilesBoard)).evaluate().isNotEmpty, 'host board');
  await _settle(tester);
}

/// Two rack tiles (no blanks) of [seat] on the centre row of an empty board,
/// as (rack index, row, column).
List<(int, int, int)> _opening(WordTilesGame game, int seat) {
  final rack = game.rackOf(seat);
  for (var i = 0; i < rack.length; i++) {
    for (var j = 0; j < rack.length; j++) {
      if (i == j || rack[i] == TileSet.blank || rack[j] == TileSet.blank) continue;
      final move = WordTilesGame.placeMove([PlacedTile(7, 7, rack[i]), PlacedTile(7, 8, rack[j])]);
      if (game.checkPlacement(move, checkWords: false).ok) return [(i, 7, 7), (j, 7, 8)];
    }
  }
  fail('no opening for seat $seat');
}

String _word(WordTilesGame game, int seat, List<(int, int, int)> tiles) =>
    tiles.map((t) => game.rackOf(seat)[t.$1]).join();

Future<void> _lay(WidgetTester tester, Key device, List<(int, int, int)> tiles) async {
  for (final (i, r, c) in tiles) {
    await _tap(tester, _on(device, find.byKey(Key('wordtiles-rack-$i'))));
    await _tap(tester, _on(device, find.byKey(Key('wordtiles-sq-$r-$c'))));
  }
}

/// The host lays [tiles], gets "nicht im Wörterbuch" and asks the guest.
Future<void> _hostAsks(WidgetTester tester, List<(int, int, int)> tiles) async {
  final hc = _controller(tester, _hostKey);
  final n = hc.moves.length;
  await _lay(tester, _hostKey, tiles);
  await _tap(tester, _on(_hostKey, find.byKey(const Key('wordtiles-play'))));
  await _settle(tester);
  expect(_on(_hostKey, find.byKey(const Key('wordtiles-unknown'))), findsOneWidget);
  expect(_on(_hostKey, find.text('Du kannst die Steine zurücknehmen oder Ben fragen, ob es trotzdem zählt.')),
      findsOneWidget);
  expect(hc.moves.length, n, reason: 'the word list is checked locally, no round trip');
  await _tap(tester, _on(_hostKey, find.byKey(const Key('wordtiles-unknown-allow'))));
  await _until(tester, () => _on(_guestKey, find.byKey(const Key('wordtiles-allow-dialog'))).evaluate().isNotEmpty,
      'the request reaches the guest');
  await _settle(tester);
}

void main() {
  late SortedWordListValidator words;
  setUp(() {
    words = _list(['ZZZZZZZZ']);
    WordLists.register('de', words);
  });
  tearDown(WordLists.clear);

  testWidgets('each device sees its own rack and the options; the guest accepts the host\'s request',
      (tester) async {
    await _start(tester, const GameConfig('wordtiles', seed: 4, tiles: 'de', dictionary: true));
    final hg = _game(tester, _hostKey), gg = _game(tester, _guestKey);

    // Own rack only: the guest's view holds no tiles of the host's rack.
    expect(gg.rackOf(1), hg.rackOf(1));
    expect(gg.rackOf(0), isEmpty);
    expect(gg.rackSizeOf(0), 7);
    for (final d in [_hostKey, _guestKey]) {
      for (var i = 0; i < 7; i++) {
        expect(_on(d, find.byKey(Key('wordtiles-rack-$i'))), findsOneWidget, reason: '$d rack $i');
      }
      // The options the host chose, in the header and above the board.
      expect(_on(d, find.byKey(const Key('wordtiles-net-options'))), findsOneWidget, reason: '$d');
      expect(_text(tester, d, const Key('wordtiles-net-options-line')), 'Deutsch · Wörterbuch prüfen');
      expect(_on(d, find.byKey(const Key('shell-undo'))), findsNothing);
    }
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Warte auf Anna…');

    final tiles = _opening(hg, 0);
    final word = _word(hg, 0, tiles);
    await _hostAsks(tester, tiles);

    // Both sides see the request; the host waits.
    expect(_text(tester, _guestKey, const Key('wordtiles-allow-body')), 'Anna möchte „$word“ zulassen – einverstanden?');
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Ben entscheidet…');
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Du entscheidest');
    expect(_text(tester, _hostKey, const Key('wordtiles-allow-line')), startsWith('Anna möchte „$word“ zulassen ('));
    for (final (r, c) in [(7, 7), (7, 8)]) {
      expect(_on(_hostKey, find.byKey(Key('wordtiles-requested-$r-$c'))), findsOneWidget);
      expect(_on(_guestKey, find.byKey(Key('wordtiles-requested-$r-$c'))), findsOneWidget);
    }
    expect(_on(_hostKey, find.byKey(Key('wordtiles-rack-${tiles.first.$1}'))), findsNothing,
        reason: 'the asked tiles lie on the board');

    await _tap(tester, _on(_guestKey, find.byKey(const Key('wordtiles-allow-accept'))));
    final hc = _controller(tester, _hostKey);
    await _until(tester, () => _controller(tester, _guestKey).moves.length == 2 && hc.moves.length == 2,
        'the answer on both devices');
    await _settle(tester);
    expect(_on(_guestKey, find.byKey(const Key('wordtiles-allow-dialog'))), findsNothing);
    expect([for (final m in hc.moves) m.move['action']], [WordTilesGame.requestAllow, WordTilesGame.acceptAllow]);
    expect(hg.turns.single.allowed, [word]);
    expect(hg.scoreOf(0), greaterThan(0));
    expect(_game(tester, _guestKey).scoreOf(0), hg.scoreOf(0));
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Warte auf Ben…');
    expect(_on(_guestKey, find.byKey(const Key('wordtiles-sq-7-7'))), findsOneWidget);
    expect(_game(tester, _guestKey).rackOf(0), isEmpty, reason: 'still no tiles of the host after the turn');
  });

  testWidgets('declined: the tiles go back, the host plays on and cannot ask again for the same word',
      (tester) async {
    await _start(tester, const GameConfig('wordtiles', seed: 4, tiles: 'de', dictionary: true));
    final hg = _game(tester, _hostKey);
    final hc = _controller(tester, _hostKey);
    final tiles = _opening(hg, 0);
    final word = _word(hg, 0, tiles);
    await _hostAsks(tester, tiles);

    await _tap(tester, _on(_guestKey, find.byKey(const Key('wordtiles-allow-decline'))));
    await _until(tester, () => hc.moves.length == 2 && _controller(tester, _guestKey).moves.length == 2,
        'the decline on both devices');
    await _settle(tester);
    expect(hc.moves.last.move['action'], WordTilesGame.declineAllow);
    expect(hg.boardEmpty, isTrue);
    expect(hg.scoreOf(0), 0);
    expect(_text(tester, _hostKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_text(tester, _hostKey, const Key('wordtiles-allow-declined')), 'Ben lehnt „$word“ ab.');
    for (var i = 0; i < 7; i++) {
      expect(_on(_hostKey, find.byKey(Key('wordtiles-rack-$i'))), findsOneWidget, reason: 'rack $i back');
    }

    // The same word again: only "Zurücknehmen".
    await _lay(tester, _hostKey, tiles);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('wordtiles-play'))));
    await _settle(tester);
    expect(_on(_hostKey, find.text('Ben hat das schon abgelehnt. Nimm die Steine zurück.')), findsOneWidget);
    expect(_on(_hostKey, find.byKey(const Key('wordtiles-unknown-allow'))), findsNothing);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('wordtiles-unknown-withdraw'))));
    await _settle(tester);
    expect(hc.moves.length, 2);

    // Still the host's turn: "Passen" hands it to the guest.
    await _tap(tester, _on(_hostKey, find.byKey(const Key('wordtiles-pass'))));
    await _settle(tester);
    await _tap(tester, _on(_hostKey, find.byKey(const Key('wordtiles-pass-confirm'))));
    await _until(tester, () => _controller(tester, _guestKey).moves.length == 3, 'the pass reaches the guest');
    expect(hc.moves.last.move['action'], 'pass');
    expect(_text(tester, _guestKey, const Key('shell-status')), 'Du bist am Zug');
    expect(_on(_hostKey, find.byKey(const Key('wordtiles-allow-declined'))), findsNothing);
  });
}

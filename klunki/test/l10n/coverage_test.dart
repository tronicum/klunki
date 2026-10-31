// I18N-06: what the user actually sees, per locale. Walks every screen (menu,
// language picker, all six games incl. handover cover, restart dialog,
// history sheet and result dialog, pairing host and join, the player name
// dialogs and the network status lines of KLD-056) at two phone sizes
// and fails on
//  * visible text (Text/RichText, tooltips) that is the English string while
//    the locale is not en (untranslated leftovers, also in engine strings),
//  * raw ARB keys or unresolved `{placeholders}` / ICU syntax on screen,
//  * layout exceptions (RenderFlex overflow etc.) at 390×844 and 360×640.
//
// Locales whose ARB still has a non-empty `@@x-untranslated` list are skipped
// for the English check (TODO(I18N-03)); the check turns strict by itself as
// soon as the list is gone.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/discovery.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki/ui/shell/legal_move_board.dart';
import 'package:klunki/ui/shell/game_screen.dart';
import 'package:klunki/ui/shell/screen_registry.dart';
import 'package:klunki/game/game_controller.dart';
import 'package:klunki_engine/klunki_engine.dart' show GameConfig, Player;
import 'package:klunki_net/klunki_net.dart' show NetException, relayUriForPage;
import 'package:klunki_net/relay_server.dart';

import '../ui/pairing/pairing_test_utils.dart';
import '../ui/shell/shell_test_utils.dart';
import 'l10n_test_utils.dart';

const gameIds = ['connect4', 'muehle', 'quartett-trumpf', 'quartett-sets', 'schiffe', 'gostrategy'];
const sizes = [Size(390, 844), Size(360, 640)];

/// Text that may be identical to English in every locale: the brand, player
/// symbols, units, and the debug console command.
const allowEnglish = {
  'Klunki', 'X', 'O', 'km/h', 'kg', 's', 'PS', 'ccm', 'undo',
  // Quartett decks (KLD-069): brand-like set names and words spelled the same.
  'ICE', 'TGV', 'Shinkansen', 'Trains', 'Europe', 'China',
};

/// The deck each Quartett game is walked with (KLD-069: the picker first).
const walkDecks = {'quartett-trumpf': 'trains', 'quartett-sets': 'rockets'};

/// Coordinates (A1–J10), numbers, scores like `3 : 2`, card codes like `B3`.
final allowPattern = RegExp(r'^[\s\dA-J.,:;/–\-+×%()#]*$');

Map<String, dynamic> readArb(String languageCode) =>
    jsonDecode(File('lib/l10n/app_$languageCode.arb').readAsStringSync()) as Map<String, dynamic>;

/// Keys listed under `@@x-untranslated` (still English placeholders).
List<String> untranslatedKeys(Map<String, dynamic> arb) {
  final raw = arb['@@x-untranslated'];
  if (raw is! String) return const [];
  final list = raw.contains(':') ? raw.substring(raw.indexOf(':') + 1) : raw;
  return [for (final k in list.split(',')) if (k.trim().isNotEmpty) k.trim()];
}

/// An ARB message turned into a full-match regex: `{x}` matches anything,
/// `{n, plural, =1{…} other{…}}` matches any branch. [letters] counts the
/// literal letters, so placeholder-only messages (`{cell} {state}`) can be
/// ignored.
class ArbTemplate {
  ArbTemplate(this.key, this.value) {
    final buf = StringBuffer('^');
    _pos = 0;
    _convert(buf, topLevel: true);
    buf.write(r'$');
    regex = RegExp(buf.toString(), dotAll: true);
  }

  final String key;
  final String value;
  late final RegExp regex;
  int letters = 0;
  int _pos = 0;

  static final _letter = RegExp(r'\p{L}', unicode: true);

  void _convert(StringBuffer out, {required bool topLevel}) {
    while (_pos < value.length) {
      final c = value[_pos];
      if (c == '}' && !topLevel) return; // end of a plural branch
      if (c == '{') {
        _pos++;
        final start = _pos;
        while (_pos < value.length && value[_pos] != '}' && value[_pos] != ',') {
          _pos++;
        }
        if (_pos < value.length && value[_pos] == '}') {
          _pos++;
          out.write('.+?');
          continue;
        }
        // `{name, plural|select, sel{…} sel{…}}`
        _pos++; // ','
        while (_pos < value.length && value[_pos] != ',') {
          _pos++;
        }
        _pos++; // second ','
        final branches = <String>[];
        while (_pos < value.length) {
          while (_pos < value.length && value[_pos] == ' ') {
            _pos++;
          }
          if (_pos >= value.length || value[_pos] == '}') break;
          while (_pos < value.length && value[_pos] != '{') {
            _pos++; // selector (=1, other, …)
          }
          _pos++; // '{'
          final b = StringBuffer();
          _convert(b, topLevel: false);
          _pos++; // '}'
          branches.add(b.toString());
        }
        _pos++; // closing '}'
        out.write('(?:${branches.join('|')})');
        assert(start > 0);
        continue;
      }
      if (_letter.hasMatch(c)) letters++;
      out.write(RegExp.escape(c));
      _pos++;
    }
  }

  bool matches(String text) => regex.hasMatch(text);
}

List<ArbTemplate> templatesOf(Map<String, dynamic> arb) => [
      for (final e in arb.entries)
        if (!e.key.startsWith('@') && e.value is String) ArbTemplate(e.key, e.value as String),
    ];

/// Collects what the user can read on the current screen.
List<String> visibleTexts(WidgetTester tester) {
  final out = <String>{};
  for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
    final s = w.text.toPlainText(includeSemanticsLabels: false).replaceAll('￼', '').trim();
    // Icons are RichText with a private-use glyph.
    if (s.isEmpty || s.runes.every((r) => r >= 0xE000 && r <= 0xF8FF)) continue;
    out.add(s);
  }
  for (final t in tester.widgetList<Tooltip>(find.byType(Tooltip))) {
    final m = t.message?.trim();
    if (m != null && m.isNotEmpty) out.add(m);
  }
  return out.toList();
}

/// Bidi isolate/mark characters the RTL code wraps around LTR runs.
String stripBidi(String s) => s.replaceAll(RegExp('[\u2066-\u2069\u200E\u200F\u061C]'), '');

class Audit {
  Audit(this.locale, this.size) {
    final code = locale.languageCode;
    english = templatesOf(readArb('en')).where((t) => t.letters >= 2).toList();
    final arb = readArb(code);
    final all = templatesOf(arb);
    keys = {for (final t in all) t.key};
    // Placeholder-only messages ("{cell} {state}") would match anything.
    own = all.where((t) => t.letters >= 2).toList();
    strictEnglish = code != 'en' && untranslatedKeys(arb).isEmpty;
  }

  final Locale locale;
  final Size size;
  late final List<ArbTemplate> english;
  late final List<ArbTemplate> own;
  late final Set<String> keys;
  late final bool strictEnglish;

  final Set<String> seen = {};
  final List<String> englishLeftovers = [];
  final List<String> rawKeys = [];
  final List<String> layoutErrors = [];

  static final _icu = RegExp(r'\{\w+(,\s*(plural|select)\s*,.*)?\}', dotAll: true);
  static final _keyLike = RegExp(r'\b(menu|shell|connect4|muehle|quartett|schiffe|go|debug|pairing|engine|language|relay|webJoin)[A-Z]\w*');

  /// Records the current screen; [where] names it in failure messages.
  void check(WidgetTester tester, String where) {
    final error = tester.takeException();
    if (error != null) layoutErrors.add('$where: ${error.toString().split('\n').first}');
    for (final raw in visibleTexts(tester)) {
      if (!seen.add(raw)) continue;
      final text = stripBidi(raw);
      if (keys.contains(text) || _icu.hasMatch(text) || _keyLike.hasMatch(text)) {
        rawKeys.add('$where: "$text"');
      }
      if (locale.languageCode == 'en') continue;
      if (allowEnglish.contains(text) || allowPattern.hasMatch(text)) continue;
      final en = english.where((t) => t.matches(text)).toList();
      if (en.isEmpty) continue;
      // Same as the locale's own string (e.g. fr "Menu", "Horizontal"): fine.
      if (own.any((t) => t.matches(text))) continue;
      englishLeftovers.add('$where: "$text" (en ${en.first.key})');
    }
  }

  void expectClean() {
    expect(layoutErrors, isEmpty, reason: 'layout errors in $locale at ${size.width}×${size.height}');
    expect(rawKeys, isEmpty, reason: 'raw ARB keys / placeholders in $locale');
    if (strictEnglish) {
      expect(englishLeftovers, isEmpty, reason: 'English text in $locale');
    } else if (englishLeftovers.isNotEmpty && locale.languageCode != 'en') {
      // TODO(I18N-03): becomes a failure once @@x-untranslated is empty.
      // ignore: avoid_print
      print('I18N-03 pending, ${englishLeftovers.length} English text(s) in $locale (not failing yet)');
    }
  }
}

Future<void> setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Plays a game opened from the menu to the end, auditing every position,
/// the handover cover, the restart dialog and the history sheet on the way.
Future<void> walkGame(WidgetTester tester, Audit audit, String id) async {
  // The menu grid (KLD-062) can put a tile below the fold on small screens.
  await tester.ensureVisible(find.byKey(Key('menu-$id')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(Key('menu-$id')));
  await tester.pumpAndSettle();
  if (walkDecks[id] case final deck?) {
    // Quartett asks for the deck first (KLD-069).
    audit.check(tester, '$id deck picker');
    await tester.tap(find.byKey(Key('quartett-deck-$deck')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('quartett-deck-play')));
    await tester.pumpAndSettle();
  }
  audit.check(tester, '$id start');
  if (id == 'connect4') {
    // Hot-seat player names (KLD-056): dialog, then names in the status line.
    await tester.tap(find.byKey(const Key('shell-names')));
    await tester.pumpAndSettle();
    audit.check(tester, '$id names dialog');
    await tester.enterText(find.byKey(const Key('hot-seat-name-X')), 'Anna');
    await tester.enterText(find.byKey(const Key('hot-seat-name-O')), 'Ben');
    await tester.tap(find.byKey(const Key('hot-seat-names-ok')));
    await tester.pumpAndSettle();
    audit.check(tester, '$id with names');
  }

  var sawHistory = false;
  for (var step = 0; step < 2000; step++) {
    if (find.byKey(resultDialog).evaluate().isNotEmpty) break;
    if (find.byKey(handoverContinue).evaluate().isNotEmpty) {
      audit.check(tester, '$id handover');
      await tester.tap(find.byKey(handoverContinue));
      await tester.pump();
      continue;
    }
    if (!sawHistory && step == 6) {
      sawHistory = true;
      // Restart confirmation, then cancel.
      if (find.byKey(const Key('shell-restart')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('shell-restart')));
        await tester.pumpAndSettle();
        audit.check(tester, '$id restart dialog');
        if (find.byType(AlertDialog).evaluate().isNotEmpty) {
          await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextButton)).first);
          await tester.pumpAndSettle();
        }
      }
      await tester.tap(find.byKey(const Key('shell-history')));
      await tester.pumpAndSettle();
      audit.check(tester, '$id history');
      await tester.tapAt(const Offset(8, 8)); // barrier: close the sheet
      await tester.pumpAndSettle();
    }
    final c = tester.widget<GameScreen>(find.byType(GameScreen)).controller;
    final moves = legalMovesOf(c.game);
    if (moves.isEmpty) break;
    await c.submit(moves.first);
    await tester.pump();
    await tester.pump();
    // Every position early on, then a sample (Schiffe has ~200 shots); a
    // layout error in between is still pending and fails the test.
    if (step < 30 || step % 10 == 0) audit.check(tester, '$id step $step');
  }
  await tester.pumpAndSettle();
  expect(find.byKey(resultDialog), findsOneWidget, reason: '$id did not reach the result dialog');
  audit.check(tester, '$id result');
  // "Menu" leaves the game.
  await tester.tap(find.descendant(of: find.byKey(resultDialog), matching: find.byType(TextButton)));
  await tester.pumpAndSettle();
  audit.check(tester, '$id back in menu');
}

void main() {
  for (final language in appLanguages) {
    final locale = language.locale;
    final tag = locale.toLanguageTag();
    final arb = readArb(locale.languageCode);
    final pending = untranslatedKeys(arb);

    group('$tag${pending.isEmpty ? '' : ' (TODO(I18N-03): ${pending.length} keys untranslated, English check lenient)'}', () {
      for (final size in sizes) {
        final at = '${size.width.toInt()}×${size.height.toInt()}';

        testWidgets('menu, language picker and all games at $at', (tester) async {
          await setSize(tester, size);
          final audit = Audit(locale, size);
          await tester.pumpWidget(klunkiApp(locale: locale));
          await tester.pumpAndSettle();
          audit.check(tester, 'menu');

          await tester.tap(find.byKey(const Key('language-button')));
          await tester.pump();
          audit.check(tester, 'language picker');
          await tester.tapAt(const Offset(4, 4)); // barrier: close the picker
          await tester.pumpAndSettle();

          // Player name dialog from the menu (KLD-056).
          await tester.tap(find.byKey(const Key('player-name-button')));
          await tester.pumpAndSettle();
          audit.check(tester, 'player name dialog');
          await tester.tap(find.byKey(const Key('player-name-cancel')));
          await tester.pumpAndSettle();

          for (final id in gameIds) {
            await walkGame(tester, audit, id);
          }
          audit.expectClean();
        });

        testWidgets('network status lines and result at $at (KLD-056)', (tester) async {
          await setSize(tester, size);
          final audit = Audit(locale, size);
          for (final local in Player.values) {
            final c = GameController.hotSeat(const GameConfig('connect4', seed: 1));
            addTearDown(c.dispose);
            await tester.pumpWidget(localizedApp(
              PlayerLabelsScope(
                labels: PlayerLabels(local: local, names: const {Player.a: 'Anna', Player.b: 'Ben'}),
                child: buildGameScreen(c),
              ),
              locale: locale,
            ));
            await tester.pump();
            for (var step = 0; step < 60 && !c.game.isOver; step++) {
              audit.check(tester, 'network game $local step $step');
              await c.submit(legalMovesOf(c.game).first);
              await tester.pump();
              await tester.pump();
            }
            await tester.pumpAndSettle();
            audit.check(tester, 'network game $local result');
            await tester.tap(find.byKey(const Key('shell-history')), warnIfMissed: false);
            await tester.pumpAndSettle();
            audit.check(tester, 'network game $local history');
          }
          audit.expectClean();
        });

        testWidgets('pairing host and join at $at', (tester) async {
          await setSize(tester, size);
          final audit = Audit(locale, size);
          final created = CreatedTransports();
          final discovery = FakeDiscovery();
          await tester.pumpWidget(localizedApp(
            PairingScreen(deps: testDeps(discovery: discovery, created: created, name: 'Pixel')),
            locale: locale,
          ));
          await tester.pump();
          audit.check(tester, 'pairing');

          await tester.ensureVisible(find.byKey(const Key('pair-host-start')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('pair-host-start')));
          await pumpUntil(tester, () => find.byKey(const Key('pair-host-waiting')).evaluate().isNotEmpty,
              what: 'host waiting view', limit: const Duration(seconds: 30));
          audit.check(tester, 'pairing host waiting');
          await tester.ensureVisible(find.byKey(const Key('pair-host-cancel')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('pair-host-cancel')));
          await tester.pump();
          await tester.pump();
          audit.check(tester, 'pairing host cancelled');

          await tester.tap(find.byIcon(Icons.login));
          await tester.pump();
          audit.check(tester, 'pairing join (searching)');
          discovery.addHost(const KlunkiHostInfo(
              name: 'iPad', host: '192.168.0.20', port: 4747, protocol: klunkiProtocolVersion, gameId: 'connect4'));
          await tester.pump();
          audit.check(tester, 'pairing join (host found)');
          await tester.enterText(find.byKey(const Key('pair-manual')), 'not an address');
          await tester.ensureVisible(find.byKey(const Key('pair-manual-connect')));
          await tester.pump();
          await tester.tap(find.byKey(const Key('pair-manual-connect')));
          await tester.pump();
          audit.check(tester, 'pairing join (invalid address)');

          await unmountAndSettleSockets(tester, created);
          audit.expectClean();
        });

        testWidgets('browser join screen at $at (KLD-055)', (tester) async {
          await setSize(tester, size);
          final audit = Audit(locale, size);
          await tester.pumpWidget(localizedApp(
            WebJoinScreen(
              deps: WebJoinDeps(joinTransport: (url, {required name}) => Future.error(StateError('refused'))),
              pageUrl: Uri.parse('https://example.org/'), // shows the https warning too
            ),
            locale: locale,
          ));
          await tester.pump();
          audit.check(tester, 'web join');
          // Submit from the keyboard: the connect button may be outside the
          // lazily built list on small screens.
          await tester.enterText(find.byKey(const Key('web-join-address')), 'not an address');
          await tester.testTextInput.receiveAction(TextInputAction.go);
          await tester.pump();
          audit.check(tester, 'web join (invalid address)');
          await tester.enterText(
              find.byKey(const Key('web-join-address')), 'klunki://join?h=192.168.0.20&p=4747&n=iPad&g=connect4&w=4748');
          await tester.testTextInput.receiveAction(TextInputAction.go);
          await tester.pump();
          await tester.pump();
          await tester.dragUntilVisible(
              find.byKey(const Key('web-join-error')), find.byKey(const Key('web-join')), const Offset(0, -200));
          await tester.pump();
          audit.check(tester, 'web join (failed)');
          audit.expectClean();
        });

        testWidgets('relay host and room join at $at (KLD-057b)', (tester) async {
          await setSize(tester, size);
          final audit = Audit(locale, size);
          final server = (await tester.runAsync(() => Zone.root.run(
              () => RelayServer.start(port: 0, address: InternetAddress.loopbackIPv4, pingInterval: null))))!;
          final created = CreatedTransports();
          final page = Uri.parse('http://127.0.0.1:${server.port}/');
          // Unreachable relay first: the start hint.
          await tester.pumpWidget(localizedApp(
            RelayHostScreen(
              hostTransport: (config, relay, {required name}) =>
                  Future.error(const NetException('cannot connect: refused')),
              defaultRelay: relayUriForPage(page),
              pageUrl: page,
            ),
            locale: locale,
          ));
          await tester.pump();
          audit.check(tester, 'relay host setup');
          // Lazy ListView: with six games the button may not be built yet.
          await tester.scrollUntilVisible(find.byKey(const Key('relay-host-start')), 200,
              scrollable: find.byType(Scrollable).first);
          await tester.pump();
          await tester.tap(find.byKey(const Key('relay-host-start')));
          await tester.pump();
          await tester.pump();
          audit.check(tester, 'relay host (no relay)');

          await tester.pumpWidget(localizedApp(
            RelayHostScreen(
              key: const Key('second'),
              hostTransport: (config, relay, {required name}) => relayHost(created, config, relay, name: name),
              defaultRelay: relayUriForPage(page),
              pageUrl: page,
            ),
            locale: locale,
          ));
          await tester.pump();
          // Lazy ListView: with six games the button may not be built yet.
          await tester.scrollUntilVisible(find.byKey(const Key('relay-host-start')), 200,
              scrollable: find.byType(Scrollable).first);
          await tester.pump();
          await tester.tap(find.byKey(const Key('relay-host-start')));
          await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty,
              what: 'relay waiting view', limit: const Duration(seconds: 30));
          audit.check(tester, 'relay host waiting');

          // The room-code join with each friendly error.
          var error = const NetException('relay: no room with code K7Q2M');
          await tester.pumpWidget(localizedApp(
            WebJoinScreen(
              deps: WebJoinDeps(
                joinTransport: (url, {required name}) => Future.error(StateError('refused')),
                relayJoin: (relay, code, {required name}) => Future.error(error),
              ),
              pageUrl: page,
            ),
            locale: locale,
          ));
          await tester.pump();
          audit.check(tester, 'room join');
          for (final e in const [
            NetException('relay: no room with code K7Q2M'),
            NetException('relay: room K7Q2M is full'),
            NetException('relay: room expired (idle)'),
            NetException('cannot connect: refused'),
          ]) {
            error = e;
            await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
            await tester.testTextInput.receiveAction(TextInputAction.go);
            await tester.pump();
            await tester.pump();
            await tester.dragUntilVisible(
                find.byKey(const Key('room-error')), find.byKey(const Key('web-join')), const Offset(0, -200));
            await tester.pump();
            audit.check(tester, 'room join ($e)');
          }
          await tester.enterText(find.byKey(const Key('room-code')), 'OOPS0');
          await tester.testTextInput.receiveAction(TextInputAction.go);
          await tester.pump();
          audit.check(tester, 'room join (invalid code)');

          await unmountAndSettleSockets(tester, created);
          await tester.runAsync(server.close);
          audit.expectClean();
        });
      }
    });
  }

  group('ArbTemplate', () {
    test('placeholders and plurals', () {
      final t = ArbTemplate('k', 'Pot: {count, plural, =1{1 card} other{{count} cards}}');
      expect(t.matches('Pot: 1 card'), isTrue);
      expect(t.matches('Pot: 12 cards'), isTrue);
      expect(t.matches('Pott: 12 Karten'), isFalse);
      expect(ArbTemplate('k', "{player}'s turn").matches("X's turn"), isTrue);
      expect(ArbTemplate('k', '{cell} {state}').letters, 0);
    });

    test('untranslatedKeys reads the @@x-untranslated list', () {
      expect(untranslatedKeys({'@@x-untranslated': 'English placeholder text (I18N-02): a, b'}), ['a', 'b']);
      expect(untranslatedKeys({}), isEmpty);
    });

    test('the audit flags English text and raw keys', () {
      final audit = Audit(const Locale('fr'), sizes.first);
      expect(audit.english.any((t) => t.matches('Choose a game')), isTrue);
      expect(audit.own.any((t) => t.matches('Choose a game')), isFalse);
      expect(Audit._keyLike.hasMatch('menuChooseGame'), isTrue);
      expect(Audit._icu.hasMatch('Pot: {count}'), isTrue);
      expect(Audit._icu.hasMatch('Pot: 3'), isFalse);
    });
  });
}

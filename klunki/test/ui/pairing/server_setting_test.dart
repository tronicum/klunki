// KLD-113: one "Server" setting. The kind of server comes from the address
// ("Server im WLAN …" / "Server im Internet"), the club code is asked for
// only when a server refuses without it (inline field + retry), a saved code
// can be seen, changed and removed in the server dialog, and the help screen
// ("So spielt ihr zusammen") is reachable from the dialog and "Über Klunki".
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/server_kind.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/about_screen.dart';
import 'package:klunki/ui/help_screen.dart';
import 'package:klunki/ui/pairing/relay_host_screen.dart';
import 'package:klunki/ui/pairing/relay_line.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' show GameConfig;
import 'package:klunki_net/klunki_net.dart';
import 'package:klunki_net/relay_server.dart';

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

final _page = Uri.parse('http://192.168.1.5:8000/');
final _lan = Uri.parse('ws://192.168.1.5:8000/relay');
final _internet = Uri.parse('wss://spiele.example/relay');

Future<NetworkTransport> _noJoin(Uri url, {required String name}) => Future.error(StateError('unused'));

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

void _bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

String _text(WidgetTester tester, String key) => tester.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  group('serverKindOf', () {
    test('home addresses are "im WLAN"', () {
      for (final a in [
        'ws://192.168.1.5:8000/relay',
        'ws://10.0.0.9:4749/relay',
        'ws://172.20.1.2:4749/relay',
        'ws://169.254.3.4:4749/relay',
        'ws://127.0.0.1:4749/relay',
        'ws://localhost:4749/relay',
        'ws://spielerechner:4749/relay',
        'ws://pc.local:4749/relay',
        'ws://[fe80::1]:4749/relay',
        'ws://[fd12:3456::1]:4749/relay',
        'wss://192.168.1.5/relay',
      ]) {
        expect(serverKindOf(Uri.parse(a)), ServerKind.lan, reason: a);
      }
    });

    test('everything else is "im Internet"', () {
      for (final a in [
        'wss://spiele.example/relay',
        'ws://spiele.example:4749/relay',
        'wss://8.8.8.8/relay',
        'ws://172.32.0.1:4749/relay',
        'wss://[2001:db8::1]/relay',
      ]) {
        expect(serverKindOf(Uri.parse(a)), ServerKind.internet, reason: a);
      }
    });
  });

  testWidgets('the server line and the dialog say the kind; it follows the typed address', (tester) async {
    _bigView(tester);
    final settings = RelaySettings.memory(_lan);
    await tester.pumpWidget(localizedApp(Scaffold(body: RelayLine(settings: settings))));
    expect(_text(tester, 'relay-line-address'), 'Server: 192.168.1.5:8000');
    expect(_text(tester, 'relay-line-kind'), 'Server im WLAN (ein Rechner, auf dem „klunki relay“ läuft)');

    await tester.tap(find.byKey(const Key('relay-change')));
    await tester.pumpAndSettle();
    expect(find.text('Server'), findsOneWidget); // the dialog title
    expect(_text(tester, 'relay-dialog-kind'), startsWith('Server im WLAN'));
    expect(find.byKey(const Key('relay-dialog-club')), findsNothing, reason: 'no club code saved: no field');
    await tester.enterText(find.byKey(const Key('relay-dialog-address')), 'wss://spiele.example');
    await tester.pump();
    expect(_text(tester, 'relay-dialog-kind'), 'Server im Internet');
    await tester.enterText(find.byKey(const Key('relay-dialog-address')), '');
    await tester.pump();
    expect(find.byKey(const Key('relay-dialog-kind')), findsNothing);
    await tester.enterText(find.byKey(const Key('relay-dialog-address')), 'wss://spiele.example');
    await tester.tap(find.byKey(const Key('relay-dialog-save')));
    await tester.pumpAndSettle();
    expect(settings.value, _internet);
    expect(_text(tester, 'relay-line-kind'), 'Server im Internet');
  });

  testWidgets('a saved club code: shown in the dialog only for its server, can be changed and removed',
      (tester) async {
    _bigView(tester);
    final settings = RelaySettings.memory(_internet);
    await settings.setClubCode(_internet, 'K7QX-M2PA');
    await tester.pumpWidget(localizedApp(Scaffold(body: RelayLine(settings: settings))));

    Future<void> open() async {
      await tester.tap(find.byKey(const Key('relay-change')));
      await tester.pumpAndSettle();
    }

    TextField club() => tester.widget<TextField>(find.byKey(const Key('relay-dialog-club')));

    // Seen and changed.
    await open();
    expect(club().controller!.text, 'K7QXM2PA');
    expect(find.text('Clubcode'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('relay-dialog-club')), 'mnpq-rstu');
    await tester.tap(find.byKey(const Key('relay-dialog-save')));
    await tester.pumpAndSettle();
    expect(settings.clubCodeFor(_internet), 'MNPQRSTU');

    // Another address: the code is not shown (it belongs to the other server).
    await open();
    await tester.enterText(find.byKey(const Key('relay-dialog-address')), '192.168.1.20:4749');
    await tester.pump();
    expect(find.byKey(const Key('relay-dialog-club')), findsNothing);
    await tester.enterText(find.byKey(const Key('relay-dialog-address')), 'wss://spiele.example');
    await tester.pump();
    expect(find.byKey(const Key('relay-dialog-club')), findsOneWidget);

    // Removed: gone after "Übernehmen", and the field no longer appears.
    await tester.tap(find.byKey(const Key('relay-dialog-club-remove')));
    await tester.pump();
    expect(find.byKey(const Key('relay-dialog-club')), findsNothing);
    await tester.tap(find.byKey(const Key('relay-dialog-save')));
    await tester.pumpAndSettle();
    expect(settings.clubCodeFor(_internet), isNull);
    await open();
    expect(find.byKey(const Key('relay-dialog-club')), findsNothing);
  });

  testWidgets('removing in the dialog and then cancelling keeps the code', (tester) async {
    _bigView(tester);
    final settings = RelaySettings.memory(_internet);
    await settings.setClubCode(_internet, 'K7QXM2PA');
    await tester.pumpWidget(localizedApp(Scaffold(body: RelayLine(settings: settings))));
    await tester.tap(find.byKey(const Key('relay-change')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('relay-dialog-club-remove')));
    await tester.tap(find.byKey(const Key('relay-dialog-cancel')));
    await tester.pumpAndSettle();
    expect(settings.clubCodeFor(_internet), 'K7QXM2PA');
  });

  testWidgets('join: the server asks for a club code → field right there → retry sends it', (tester) async {
    _bigView(tester);
    final settings = RelaySettings.memory(_internet);
    final sent = <String?>[];
    await tester.pumpWidget(localizedApp(WebJoinScreen(
        pageUrl: _page,
        deps: WebJoinDeps(
            joinTransport: _noJoin,
            relayJoin: (relay, code, {required name}) {
              final club = settings.clubCodeFor(relay);
              sent.add(club);
              return Future.error(NetException(switch (club) {
                null => 'relay: $relayClubMissingText',
                'K7QXM2PA' => 'relay: no room with code $code',
                _ => 'relay: $relayClubWrongText',
              }));
            },
            relaySettings: () => settings))));
    await tester.pump();
    expect(find.byKey(const Key('room-club')), findsNothing, reason: 'not shown by default');

    await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
    await _tapVisible(tester, find.byKey(const Key('room-join-button')));
    await tester.pump();
    await tester.pump();
    expect(_text(tester, 'room-error'), 'Dieser Server braucht einen Clubcode. Frag die Person, die den Server betreibt.');
    expect(find.byKey(const Key('room-club-field')), findsOneWidget);
    expect(find.textContaining('kommt nie in Raum-Links oder QR-Codes'), findsOneWidget);
    // "Wie geht das?" right there, too.
    final help = find.descendant(of: find.byKey(const Key('room-club')), matching: find.byType(ServerHelpLink));
    expect(help, findsOneWidget);
    await _tapVisible(tester, help);
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // A wrong code: told so, the field stays with what was typed.
    await tester.enterText(find.byKey(const Key('room-club-field')), 'AAAA-BBBB');
    await _tapVisible(tester, find.byKey(const Key('room-club-retry')));
    await tester.pump();
    await tester.pump();
    expect(_text(tester, 'room-error'), 'Dieser Server kennt den Clubcode nicht. Frag die Person, die den Server betreibt.');
    expect(tester.widget<TextField>(find.byKey(const Key('room-club-field'))).controller!.text, 'AAAA-BBBB');

    // The right one: accepted by the server, the join goes on (here: no such room).
    await tester.enterText(find.byKey(const Key('room-club-field')), 'k7qx m2pa');
    await _tapVisible(tester, find.byKey(const Key('room-club-retry')));
    await tester.pump();
    await tester.pump();
    expect(sent, [null, 'AAAABBBB', 'K7QXM2PA']);
    expect(settings.clubCodeFor(_internet), 'K7QXM2PA', reason: 'saved for that server');
    expect(find.byKey(const Key('room-club')), findsNothing);
    expect(_text(tester, 'room-error'), startsWith('Kein Raum mit dem Code'));
  });

  testWidgets('start a room on a gated server: prompt, retry with the code, the room opens', (tester) async {
    _bigView(tester);
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('klunki_club_app_')))!;
    addTearDown(() => tester.runAsync(() => dir.delete(recursive: true)));
    final file = File('${dir.path}/codes.txt');
    await tester.runAsync(() => file.writeAsString('K7QX-M2PA  # Familie\n'));
    final server = (await tester.runAsync(() => Zone.root.run(() async => RelayServer.start(
        port: 0,
        address: InternetAddress.loopbackIPv4,
        pingInterval: null,
        clubCodes: await ClubCodes.load(file.path)))))!;
    addTearDown(() => tester.runAsync(server.close));
    final relay = Uri.parse('ws://127.0.0.1:${server.port}/relay');
    final settings = RelaySettings.memory(relay);
    final created = CreatedTransports();
    final codes = <String?>[];
    Future<NetworkTransport> host(GameConfig config, Uri relay, {required String name}) async {
      final club = settings.clubCodeFor(relay);
      codes.add(club);
      // Created in the root zone (real sockets); an error is thrown back in the caller's zone.
      final (NetworkTransport?, Object?) r = await Zone.root.run(() async {
        try {
          return (
            await NetworkTransport.hostRelay(config, relay,
                name: name, pingInterval: pingInterval, timeout: netTimeout, clubCode: club),
            null
          );
        } catch (e) {
          return (null, e);
        }
      });
      if (r.$2 case final e?) throw e;
      created.hosts.add(r.$1!);
      return r.$1!;
    }

    await tester.pumpWidget(localizedApp(RelayHostScreen(
      hostTransport: host,
      relaySettings: settings,
      seed: () => 7,
      deviceName: () => 'Ada',
    )));
    await tester.pump();
    await tester.tap(find.byKey(const Key('relay-host-start')));
    await pumpUntil(tester, () => find.byKey(const Key('relay-host-club')).evaluate().isNotEmpty,
        what: 'club code prompt');
    expect(_text(tester, 'relay-host-error'), startsWith('Dieser Server braucht einen Clubcode.'));

    await tester.enterText(find.byKey(const Key('relay-host-club-field')), 'k7qx-m2pa');
    await _tapVisible(tester, find.byKey(const Key('relay-host-club-retry')));
    await pumpUntil(tester, () => find.byKey(const Key('relay-host-waiting')).evaluate().isNotEmpty,
        what: 'waiting screen');
    expect(codes, [null, 'K7QXM2PA']);
    expect(settings.clubCodeFor(relay), 'K7QXM2PA');
    // The room link never carries the club code.
    final link = tester.widget<SelectableText>(find.byKey(const Key('relay-link'))).data!;
    expect(link, isNot(contains('K7QX')));
    expect(link, isNot(contains('club')));

    await unmountAndSettleSockets(tester, created);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('help: from the server dialog ("Wie geht das?")', (tester) async {
    _bigView(tester);
    final settings = RelaySettings.memory(_lan);
    await tester.pumpWidget(localizedApp(Scaffold(body: RelayLine(settings: settings))));
    await tester.tap(find.byKey(const Key('relay-change')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('relay-dialog-help')));
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.text('So spielt ihr zusammen'), findsOneWidget);
    for (final id in helpSectionIds) {
      await tester.dragUntilVisible(
          find.byKey(Key('help-$id-title')), find.byKey(const Key('help-text')), const Offset(0, -200));
    }
    expect(find.text('Was ist ein Clubcode?'), findsOneWidget);
    await tester.tap(find.byType(BackButton)); // pageBack() looks for the English "Back" tooltip
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('relay-dialog-address')), findsOneWidget, reason: 'back in the dialog');
  });

  testWidgets('help: from "Über Klunki"', (tester) async {
    _bigView(tester);
    await tester.pumpWidget(localizedApp(const AboutScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('about-help')));
    await tester.pumpAndSettle();
    expect(find.byType(HelpScreen), findsOneWidget);
    expect(find.byKey(const Key('help-Rooms-title')), findsOneWidget);
    expect(find.textContaining('Hat einer von euch die App?'), findsOneWidget);
  });

  testWidgets('help: every section in every locale, the start command after "Eigener Server"', (tester) async {
    _bigView(tester);
    for (final locale in ['de', 'en', 'fr', 'es', 'zh', 'ar', 'fa']) {
      await tester.pumpWidget(localizedApp(const HelpScreen(), locale: Locale(locale)));
      await tester.pump();
      for (final id in helpSectionIds) {
        await tester.dragUntilVisible(
            find.byKey(Key('help-$id-body')), find.byKey(const Key('help-text')), const Offset(0, -200));
        expect(_text(tester, 'help-$id-title'), isNotEmpty);
      }
      expect(find.byKey(const Key('help-command'), skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

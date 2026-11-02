// KLD-112: the optional "Clubcode" of a gated relay (`klunki relay --codes`):
// entered in the relay dialog, saved for that relay only, sent when hosting
// or joining there, and a refusal becomes a clear sentence.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/relay_errors.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki_net/klunki_net.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n_test_utils.dart';
import 'pairing_test_utils.dart';

final _page = Uri.parse('http://192.168.1.5:8000/');
final _pageRelay = Uri.parse('ws://192.168.1.5:8000/relay');
final _club = Uri.parse('ws://spiele.example:4749/relay');

Future<NetworkTransport> _noJoin(Uri url, {required String name}) => Future.error(StateError('unused'));

Future<void> _tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
}

void main() {
  test('RelaySettings: the club code belongs to one relay and is saved', () async {
    SharedPreferences.setMockInitialValues({});
    final s = RelaySettings.memory(_club);
    expect(s.clubCodeFor(_club), isNull);
    await s.setClubCode(_club, ' k7qx-m2pa ');
    expect(s.clubCodeFor(_club), 'K7QXM2PA');
    expect(s.clubCodeFor(_pageRelay), isNull, reason: 'never sent to another relay (e.g. one from a link)');
    expect(s.clubCodeFor(null), isNull);
    await s.setClubCode(_club, 'odd code!');
    expect(s.clubCodeFor(_club), 'odd code!', reason: 'kept as typed: the relay then says it does not know it');
    await s.setClubCode(_club, '  ');
    expect(s.clubCodeFor(_club), isNull);
  });

  test('club refusals are recognised', () {
    expect(classifyRelayError(const NetException('relay: club code required')), RelayFailure.clubMissing);
    expect(classifyRelayError(const NetException('relay: club code not accepted')), RelayFailure.clubWrong);
    expect(classifyRelayError(const NetException('relay: no room with code K7Q2M')), RelayFailure.unknownCode);
  });

  testWidgets('a saved club code is in the server dialog (KLD-113: only then); a room link has no club code',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = RelaySettings.memory();
    final joins = <Uri>[];
    await tester.pumpWidget(localizedApp(WebJoinScreen(
        pageUrl: _page,
        deps: WebJoinDeps(
            joinTransport: _noJoin,
            relayJoin: (relay, code, {required name}) {
              joins.add(relay);
              return Future.error(const NetException('relay: club code not accepted'));
            },
            relaySettings: () => settings))));
    await tester.pump();
    await openAdvanced(tester, 'web-join-advanced');
    await _tapVisible(tester, find.byKey(const Key('relay-change')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('relay-dialog-club')), findsNothing, reason: 'KLD-113: asked for only when needed');
    await tester.enterText(find.byKey(const Key('relay-dialog-address')), 'spiele.example:4749');
    await tester.tap(find.byKey(const Key('relay-dialog-save')));
    await tester.pumpAndSettle();
    expect(settings.value, _club);
    await settings.setClubCode(_club, 'k7qx-m2pa'); // as the club code prompt does
    expect(settings.clubCodeFor(_club), 'K7QXM2PA');

    // Reopened: prefilled.
    await _tapVisible(tester, find.byKey(const Key('relay-change')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('relay-dialog-club'))).controller!.text, 'K7QXM2PA');
    await tester.tap(find.byKey(const Key('relay-dialog-cancel')));
    await tester.pumpAndSettle();

    // A refusal is a plain sentence.
    await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
    await _tapVisible(tester, find.byKey(const Key('room-join-button')));
    await tester.pump();
    await tester.pump();
    expect(joins.single, _club);
    expect(tester.widget<Text>(find.byKey(const Key('room-error'))).data,
        'Dieser Server kennt den Clubcode nicht. Frag die Person, die den Server betreibt.');

    // Room links and QR codes carry the room and the relay, never the club code.
    final link = roomJoinLink(code: 'K7Q2M', relay: _club, pageUrl: _page).toString();
    expect(link, isNot(contains('K7QX')));
    expect(link, isNot(contains('club=')));
  });

  testWidgets('a missing club code: the sentence, and the field right there (KLD-113)', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(localizedApp(WebJoinScreen(
        pageUrl: _page,
        deps: WebJoinDeps(
            joinTransport: _noJoin,
            relayJoin: (relay, code, {required name}) => Future.error(const NetException('relay: club code required'))))));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('room-code')), 'K7Q2M');
    await _tapVisible(tester, find.byKey(const Key('room-join-button')));
    await tester.pump();
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('room-error'))).data,
        'Dieser Server braucht einen Clubcode. Frag die Person, die den Server betreibt.');
    expect(find.byKey(const Key('room-club-field')), findsOneWidget);
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(l10n.relayErrorClubWrong, isNotEmpty);
  });
}

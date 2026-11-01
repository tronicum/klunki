// KLD-052: "QR-Code scannen" in the join tab, with a fake camera (codes and
// camera state are injected, no plugin involved).
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/fake_discovery.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/profile/relay_settings.dart';
import 'package:klunki/transport/network_transport.dart';
import 'package:klunki/ui/pairing/pairing_screen.dart';
import 'package:klunki/ui/pairing/qr_scan_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart';
import 'package:klunki_net/guest_web.dart' show NetException;

import '../../l10n/l10n_test_utils.dart';

class FakeQrScanner implements QrScanner {
  final StreamController<String> _codes = StreamController.broadcast();
  final ValueNotifier<QrCameraState> _state;
  bool disposed = false;
  int torchToggles = 0;

  FakeQrScanner([QrCameraState initial = const QrCameraState(status: QrCameraStatus.running)])
      : _state = ValueNotifier(initial);

  void emit(String code) => _codes.add(code);
  set camera(QrCameraState s) => _state.value = s;

  @override
  Stream<String> get codes => _codes.stream;

  @override
  ValueListenable<QrCameraState> get state => _state;

  @override
  Widget buildPreview(BuildContext context) => const ColoredBox(key: Key('fake-preview'), color: Colors.black);

  @override
  Future<void> toggleTorch() async {
    torchToggles++;
    final s = _state.value;
    _state.value = QrCameraState(status: s.status, torchAvailable: s.torchAvailable, torchOn: !s.torchOn);
  }

  @override
  void dispose() {
    disposed = true;
    _codes.close();
  }
}

class _Calls {
  final List<(String, int, String)> direct = [];
  final List<(Uri, String, String)> relay = [];
  final List<FakeQrScanner> scanners = [];
  QrCameraState initial = const QrCameraState(status: QrCameraStatus.running);
  final RelaySettings settings = RelaySettings.memory();
  Object? relayError; // fail relay joins with this (null: stay connecting)
  FakeQrScanner get scanner => scanners.last;
}

PairingDeps _deps(_Calls calls, {bool scan = true}) => PairingDeps(
      discovery: () => FakeDiscovery(),
      hostTransport: (config, {required name, required port, required wsPort}) => Future.error('unused'),
      joinTransport: (host, port, {required name}) {
        calls.direct.add((host, port, name));
        return Completer<NetworkTransport>().future; // stays connecting
      },
      relayJoin: (relay, code, {required name}) {
        calls.relay.add((relay, code, name));
        final error = calls.relayError;
        return error != null ? Future.error(error) : Completer<NetworkTransport>().future;
      },
      localAddresses: () async => const [],
      deviceName: () => 'Pixel',
      relaySettings: () => calls.settings,
      qrScanner: scan
          ? () {
              final s = FakeQrScanner(calls.initial);
              calls.scanners.add(s);
              return s;
            }
          : null,
    );

/// "Raum beitreten" without opening the camera on its own ([scanFirst]
/// false), so the tests open it with the button.
Future<void> _openJoinTab(WidgetTester tester, PairingDeps deps, {bool scanFirst = false}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(localizedApp(PairingScreen(deps: deps, mode: RoomMode.join, scanFirst: scanFirst)));
  await tester.pump();
}

/// The join tab's "searching" spinner never settles: pump through the
/// route transitions instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Unmounts and runs out the join timeout of a join that never completes.
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 13));
}

Future<void> _openScanner(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('pair-scan')));
  await _settle(tester);
  expect(find.byKey(const Key('qr-scan-screen')), findsOneWidget);
}

void main() {
  // KLD-098: "Raum beitreten" leads straight to the camera; closing it
  // leaves the code field.
  testWidgets('"Raum beitreten" opens the scanner right away; closing it shows the code field', (tester) async {
    final calls = _Calls();
    await _openJoinTab(tester, _deps(calls), scanFirst: true);
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('qr-scan-cancel')));
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(find.byKey(const Key('room-code')), findsOneWidget);
    expect(calls.scanners, hasLength(1));
  });

  testWidgets('without a camera "Raum beitreten" shows the code field right away', (tester) async {
    await _openJoinTab(tester, _deps(_Calls(), scan: false), scanFirst: true);
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(find.byKey(const Key('room-code')), findsOneWidget);
  });

  testWidgets('the join screen has a "QR-Code scannen" button with a camera icon', (tester) async {
    await _openJoinTab(tester, _deps(_Calls()));
    final button = find.byKey(const Key('pair-scan'));
    expect(button, findsOneWidget);
    expect(find.descendant(of: button, matching: find.text('QR-Code scannen')), findsOneWidget);
    expect(find.descendant(of: button, matching: find.byIcon(Icons.qr_code_scanner)), findsOneWidget);
  });

  testWidgets('no scanner (e.g. tests, other platforms): no button', (tester) async {
    await _openJoinTab(tester, _deps(_Calls(), scan: false));
    expect(find.byKey(const Key('pair-scan')), findsNothing);
  });

  testWidgets('the browser join screen has no scan button', (tester) async {
    await tester.pumpWidget(localizedApp(WebJoinScreen(
        pageUrl: Uri.parse('http://192.168.1.5:8000/'),
        deps: WebJoinDeps(joinTransport: (url, {required name}) => Future.error('unused')))));
    await tester.pump();
    expect(find.byKey(const Key('pair-scan')), findsNothing);
    expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
  });

  testWidgets('scanner screen: viewfinder over the preview, hint, cancel joins nothing', (tester) async {
    final calls = _Calls();
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    expect(find.byKey(const Key('fake-preview')), findsOneWidget);
    expect(find.text('Richte die Kamera auf den QR-Code des anderen Geräts.'), findsOneWidget);
    expect(find.byKey(const Key('qr-scan-torch')), findsNothing); // no torch reported

    await tester.tap(find.byKey(const Key('qr-scan-cancel')));
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(calls.scanner.disposed, isTrue);
    expect(calls.direct, isEmpty);
    expect(calls.relay, isEmpty);
  });

  testWidgets('a native host code joins right away, like typing it', (tester) async {
    final calls = _Calls();
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    const p = JoinPayload(host: '192.168.1.20', port: 4747, name: 'Anna', gameId: 'muehle', wsPort: 4748);
    calls.scanner.emit(p.format());
    await _settle(tester);

    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(calls.scanner.disposed, isTrue);
    expect(calls.direct, [('192.168.1.20', 4747, 'Pixel')]);
    expect(find.byKey(const Key('pair-join-progress')), findsOneWidget);
    expect(find.textContaining('Anna'), findsWidgets);
    expect(tester.widget<TextField>(find.byKey(const Key('pair-manual'), skipOffstage: false)).controller!.text,
        '192.168.1.20:4747');
    await _drain(tester);
  });

  testWidgets('a code that is not Klunki shows a hint and keeps scanning', (tester) async {
    final calls = _Calls();
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    calls.scanner.emit('https://example.com/');
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsOneWidget);
    expect(find.byKey(const Key('qr-scan-not-klunki')), findsOneWidget);
    expect(find.textContaining('Kein Klunki-Code'), findsOneWidget);

    calls.scanner.emit('klunki://join?h=10.0.0.7&p=5000');
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(calls.direct, [('10.0.0.7', 5000, 'Pixel')]);
    await _drain(tester);
  });

  testWidgets('a room link joins the room through its relay without saving it (KLD-075)', (tester) async {
    final calls = _Calls();
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    calls.scanner.emit('http://192.168.1.5:8000/?room=K7Q2M');
    await _settle(tester);

    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(calls.relay, [(Uri.parse('ws://192.168.1.5:8000/relay'), 'K7Q2M', 'Pixel')]);
    expect(calls.direct, isEmpty);
    expect(find.byKey(const Key('room-progress')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('room-code'))).controller!.text, 'K7Q 2M');
    expect(calls.settings.value, isNull);
    expect(find.text('Relay aus Link: 192.168.1.5:8000'), findsOneWidget);
    expect(find.byKey(const Key('relay-line-unset'), skipOffstage: false), findsOneWidget); // under "Erweitert"
    // An app has no page origin: no foreign-relay warning.
    expect(find.byKey(const Key('room-link-relay-foreign')), findsNothing);
    await _drain(tester);
  });

  testWidgets('a scanned &relay= is used once; "Als Standard speichern" keeps it (KLD-075)', (tester) async {
    final saved = Uri.parse('ws://192.168.1.20:4749/relay');
    final calls = _Calls()
      ..relayError = const NetException('relay: no room with code ABCDE')
      ..settings.value = saved;
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    calls.scanner.emit('http://192.168.1.5:8000/?room=ABCDE&relay=10.0.0.9%3A4749');
    await _settle(tester);
    expect(calls.relay, [(Uri.parse('ws://10.0.0.9:4749/relay'), 'ABCDE', 'Pixel')]);
    expect(calls.settings.value, saved);
    expect(find.text('Relay: 192.168.1.20:4749', skipOffstage: false), findsOneWidget);
    expect(find.text('Relay aus Link: 10.0.0.9:4749'), findsOneWidget);
    expect(find.byKey(const Key('room-error')), findsOneWidget);

    // A retry by hand still goes to the link's relay.
    await tester.ensureVisible(find.byKey(const Key('room-join-button')));
    await tester.tap(find.byKey(const Key('room-join-button')));
    await _settle(tester);
    expect(calls.relay.last.$1, Uri.parse('ws://10.0.0.9:4749/relay'));
    expect(calls.settings.value, saved);

    await tester.ensureVisible(find.byKey(const Key('room-link-relay-save')));
    await tester.tap(find.byKey(const Key('room-link-relay-save')));
    await _settle(tester);
    expect(calls.settings.value, Uri.parse('ws://10.0.0.9:4749/relay'));
    expect(find.text('Relay: 10.0.0.9:4749', skipOffstage: false), findsOneWidget);
    expect(find.byKey(const Key('room-link-relay')), findsNothing);
    await _drain(tester);
  });

  testWidgets('torch toggle when the camera has one', (tester) async {
    final calls = _Calls()..initial = const QrCameraState(status: QrCameraStatus.running, torchAvailable: true);
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    expect(find.byTooltip('Licht einschalten'), findsOneWidget);
    await tester.tap(find.byKey(const Key('qr-scan-torch')));
    await tester.pump();
    expect(calls.scanner.torchToggles, 1);
    expect(find.byTooltip('Licht ausschalten'), findsOneWidget);
  });

  testWidgets('permission denied: message, settings hint, back to typing the code', (tester) async {
    final calls = _Calls()..initial = const QrCameraState(status: QrCameraStatus.starting);
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    calls.scanner.camera = const QrCameraState(status: QrCameraStatus.permissionDenied);
    await tester.pump();

    expect(find.byKey(const Key('qr-scan-denied')), findsOneWidget);
    expect(find.text('Klunki darf die Kamera nicht benutzen.'), findsOneWidget);
    expect(find.textContaining('Einstellungen'), findsOneWidget);
    expect(find.byKey(const Key('fake-preview')), findsNothing);

    await tester.tap(find.byKey(const Key('qr-scan-type-instead')));
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
    expect(find.byKey(const Key('room-code')), findsOneWidget);
    expect(calls.direct, isEmpty);
  });

  testWidgets('no camera: message and back to typing the code', (tester) async {
    final calls = _Calls()..initial = const QrCameraState(status: QrCameraStatus.unavailable);
    await _openJoinTab(tester, _deps(calls));
    await _openScanner(tester);
    expect(find.byKey(const Key('qr-scan-unavailable')), findsOneWidget);
    expect(find.text('Die Kamera ist nicht verfügbar.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('qr-scan-type-instead')));
    await _settle(tester);
    expect(find.byKey(const Key('qr-scan-screen')), findsNothing);
  });
}

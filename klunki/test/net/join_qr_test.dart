import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/net/join_payload.dart';
import 'package:klunki/net/join_qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('shows the payload as QR plus host:port', (tester) async {
    const payload = JoinPayload(host: '192.168.1.20', port: 4747, name: 'Stefans iPhone', gameId: 'muehle');
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: JoinQrCode(payload: payload)))));

    final widget = tester.widget<JoinQrCode>(find.byType(JoinQrCode));
    expect(JoinPayload.tryParse(widget.data), payload);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('QR-Code nicht verfügbar'), findsNothing);
    expect(find.text('192.168.1.20:4747'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('QR-Code.*192.168.1.20:4747')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('address line can be hidden', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: JoinQrCode(payload: JoinPayload(host: '10.0.0.2'), showAddress: false),
    ));
    expect(find.text('10.0.0.2:4747'), findsNothing);
  });
}

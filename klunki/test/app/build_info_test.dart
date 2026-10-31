import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki_engine/klunki_engine.dart' show catalogFingerprint;
import 'package:klunki_net/klunki_net.dart' show protocolVersion;

import '../l10n/l10n_test_utils.dart';
import 'package:klunki/ui/menu_screen.dart';

/// KLD-085: the visible version and the build label of the handshake.
void main() {
  test('appVersion mirrors pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    expect(appVersion, line.substring('version:'.length).trim());
  });

  test('the build label starts with the version (the other side compares it); no build id in tests', () {
    expect(appBuildId, isEmpty);
    expect(appBuildLabel, appVersion);
    expect(appBuildCompat().build, appVersion);
    expect(appVersionLine, '$appVersion · P$protocolVersion · ${catalogFingerprint()}');
  });

  testWidgets('the menu shows the version line', (tester) async {
    await tester.pumpWidget(localizedApp(const MenuScreen()));
    await tester.pumpAndSettle();
    final version = find.byKey(const Key('menu-version'));
    await tester.scrollUntilVisible(version, 200);
    expect(tester.widget<Text>(version).data, contains('Version $appVersion · P$protocolVersion'));
  });
}

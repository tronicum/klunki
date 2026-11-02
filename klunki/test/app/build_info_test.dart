import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/build_info.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki_engine/klunki_engine.dart' show catalogFingerprint;
import 'package:klunki_net/klunki_net.dart' show protocolVersion, versionDisplay;

import '../l10n/l10n_test_utils.dart';

/// KLD-085, KLD-116: the visible version and the build label of the handshake.
void main() {
  test('appVersion mirrors pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final line = pubspec.firstWhere((l) => l.startsWith('version:'));
    expect(appVersion, line.substring('version:'.length).trim());
  });

  test('the version is MAJOR.MINOR.PATCH+BUILD (KLD-116)', () {
    expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')));
    expect(appVersionName, appVersion.split('+').first);
  });

  test('without KLUNKI_BUILD (tests, local builds): "1.0.0 (dev)", the pubspec build number', () {
    expect(appBuildId, isEmpty);
    expect(appBuildNumber, appVersion.split('+').last);
    expect(appBuildLabel, appVersion);
    expect(appBuildCompat().build, appVersion);
    expect(appVersionLine, '$appVersionName (dev)');
    expect(appBuildDetails, (build: appBuildNumber, protocol: '$protocolVersion', games: catalogFingerprint()));
  });

  test('with KLUNKI_BUILD and KLUNKI_BUILD_NUMBER (CI): label and line', () {
    final label = buildLabel('1.0.0',
        buildNumber: '2026110201', commit: 'b8752a9d0c1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a');
    expect(label, '1.0.0+2026110201 b8752a9');
    expect(versionDisplay(label), '1.0.0 (b8752a9)');
    // CI passes only the commit: still the pubspec's build number.
    expect(buildLabel('1.1.0', buildNumber: '1', commit: 'c3d4e5f'), '1.1.0+1 c3d4e5f');
    expect(versionDisplay(buildLabel('1.1.0', buildNumber: '1', commit: 'c3d4e5f')), '1.1.0 (c3d4e5f)');
    expect(buildLabel('1.0.0'), '1.0.0');
    expect(versionDisplay(buildLabel('1.0.0')), '1.0.0 (dev)');
  });

  testWidgets('the menu shows the simple version line', (tester) async {
    await tester.pumpWidget(localizedApp(const MenuScreen()));
    await tester.pumpAndSettle();
    final version = find.byKey(const Key('menu-version'));
    await tester.scrollUntilVisible(version, 200);
    expect(tester.widget<Text>(version).data, 'Version $appVersionName (dev)');
  });
}

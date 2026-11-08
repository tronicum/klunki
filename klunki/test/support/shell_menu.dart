import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taps the "⋮" menu entry [key] of a game's app bar (`shell-names`,
/// `shell-restart`): opens the menu (`shell-menu`) first unless it is open.
/// [within] narrows the menu button down (e.g. one of two devices).
Future<void> tapShellMenuItem(WidgetTester tester, String key, {Finder Function(Finder)? within}) async {
  Finder f(Finder x) => within == null ? x : within(x);
  if (find.byKey(Key(key)).evaluate().isEmpty) {
    await tester.tap(f(find.byKey(const Key('shell-menu'))));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(Key(key)).last);
  await tester.pumpAndSettle();
}

/// Whether the "⋮" menu of the app bar offers [key]: opens and closes it.
Future<bool> shellMenuHas(WidgetTester tester, String key) async {
  final menu = find.byKey(const Key('shell-menu'));
  if (menu.evaluate().isEmpty) return false;
  await tester.tap(menu);
  await tester.pumpAndSettle();
  final has = find.byKey(Key(key)).evaluate().isNotEmpty;
  await tester.tapAt(const Offset(4, 4));
  await tester.pumpAndSettle();
  return has;
}

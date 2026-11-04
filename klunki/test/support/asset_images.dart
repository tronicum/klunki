import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Decodes every image on screen (asset images such as the app icon in the
/// menu's app bar, KLD-097) outside the fake clock, so a screenshot shows
/// them instead of an empty box. The screenshot helpers call it before
/// capturing.
Future<void> precacheShownImages(WidgetTester tester) async {
  final images = find.byType(Image).evaluate().toList();
  if (images.isEmpty) return;
  await tester.runAsync(() async {
    for (final e in images) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump();
}

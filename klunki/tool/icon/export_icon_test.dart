// KLD-097 step 2: exports one icon concept in every size the app needs.
//
//   cd klunki
//   KLUNKI_ICON_EXPORT=/tmp/klunki-icon KLUNKI_ICON_ID=c5-zoom-b-fill \
//     flutter test tool/icon/export_icon_test.dart
//
// Opt-in like render_icons_test.dart (skipped unless both variables are set).
// Writes a tree that mirrors the app's paths, so after review it can be
// copied over `klunki/` as is (`cp -R /tmp/klunki-icon/{ios,android,web,assets} .`):
//
// - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-*.png: every file
//   the existing Contents.json names, RGB without alpha (incl. the 1024
//   marketing icon). Contents.json itself is unchanged and not written.
// - android/app/src/main/res/mipmap-*dpi/ic_launcher.png (48 dp, legacy),
//   ic_launcher_foreground.png (108 dp, transparent, motif centred on its
//   smallest enclosing circle and shrunk into the 66 dp safe circle), ic_launcher_background.png (108 dp, the table), and
//   mipmap-anydpi-v26/ic_launcher.xml (adaptive icon, API 26+).
// - web/icons/Icon-{192,512}.png, Icon-maskable-{192,512}.png (table full
//   size, motif shrunk into the 80 % maskable safe circle), web/favicon.png (32 px).
// - store/play-store-512.png (Google Play listing icon; kept in docs/store/).
// - assets/icon/app_icon.png (384 px, shown on the About screen).
// - check/android-adaptive.png: foreground on background with a circle and a
//   squircle mask and the 66 dp safe circle, for review.
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'icon_concepts.dart';
import 'icon_png.dart';

final String? _out = Platform.environment['KLUNKI_ICON_EXPORT'];
final String? _id = Platform.environment['KLUNKI_ICON_ID'];

/// iOS AppIcon set: (point size, scale) as listed in Contents.json.
const _ios = [
  (20.0, 1), (20.0, 2), (20.0, 3), //
  (29.0, 1), (29.0, 2), (29.0, 3),
  (40.0, 1), (40.0, 2), (40.0, 3),
  (60.0, 2), (60.0, 3),
  (76.0, 1), (76.0, 2),
  (83.5, 2),
  (1024.0, 1),
];

/// Android densities: folder suffix → scale factor (mdpi = 1).
const _android = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0};

/// Adaptive icon geometry: 108 dp layers, safe circle 66 dp in diameter.
const _safeRadius = adaptiveSafeRadius;

/// Concepts that crop their motif at the icon's edge, and the uncropped
/// source art to fit into the Android and maskable safe circles instead.
const _motifSource = {'c5-zoom-b-fill': 'c5-zoom-b'};

const _adaptiveXml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
''';

void main() {
  testWidgets('export icon $_id', skip: _out == null || _id == null, (tester) async {
    await tester.runAsync(() async {
      await loadIconFonts();
      final entry = iconConcepts[_id];
      if (entry == null) fail('Unknown KLUNKI_ICON_ID "$_id"; known: ${iconConcepts.keys.join(', ')}');
      final paint = entry.$2;
      final out = _out!;

      Future<void> full(int px, String path) async {
        iconLayer = IconLayer.full;
        await writePng(await renderImage(px, px, (c) => paint(c, px.toDouble())), '$out/$path');
      }

      // iOS.
      for (final (pt, scale) in _ios) {
        final name = pt == pt.roundToDouble() ? pt.toInt().toString() : pt.toString();
        await full(
          (pt * scale).round(),
          'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-${name}x$name@${scale}x.png',
        );
      }

      // Android: fit the foreground motif into the safe circle, centred on
      // its smallest enclosing circle. A concept that crops its motif at the
      // edge (c5-zoom-b-fill) uses its uncropped source art here.
      final motif = iconConcepts[_motifSource[_id] ?? _id]!.$2;
      final fit = await motifSafeFit(motif, _safeRadius);
      // ignore: avoid_print
      print('Android foreground scale for $_id: ${fit.scale.toStringAsFixed(3)}');
      void fitted(Canvas c, double px, ({Offset centre, double scale}) f) {
        iconLayer = IconLayer.foreground;
        c.save();
        c.translate(px / 2, px / 2);
        c.scale(f.scale);
        c.translate(-f.centre.dx * px, -f.centre.dy * px);
        motif(c, px);
        c.restore();
        iconLayer = IconLayer.full;
      }

      void foreground(Canvas c, double px) => fitted(c, px, fit);

      void background(Canvas c, double px) {
        iconLayer = IconLayer.background;
        paint(c, px);
        iconLayer = IconLayer.full;
      }

      const res = 'android/app/src/main/res';
      for (final MapEntry(key: dpi, value: k) in _android.entries) {
        await full((48 * k).round(), '$res/mipmap-$dpi/ic_launcher.png');
        final layer = (108 * k).round();
        await writePng(
          await renderImage(layer, layer, (c) => foreground(c, layer.toDouble())),
          '$out/$res/mipmap-$dpi/ic_launcher_foreground.png',
          alpha: true,
        );
        await writePng(
          await renderImage(layer, layer, (c) => background(c, layer.toDouble())),
          '$out/$res/mipmap-$dpi/ic_launcher_background.png',
        );
      }
      File('$out/$res/mipmap-anydpi-v26/ic_launcher.xml')
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(_adaptiveXml);

      // Web, Play Store. Maskable icons: the table fills the square, the
      // motif is shrunk (if needed) until every visible pixel sits inside the
      // 80 % safe circle the browser may crop to.
      final maskFit = await motifSafeFit(motif, maskableSafeRadius);
      // ignore: avoid_print
      print('Maskable web icon scale for $_id: ${maskFit.scale.toStringAsFixed(3)}');
      void maskable(Canvas c, double px) {
        background(c, px);
        fitted(c, px, maskFit);
      }

      for (final s in [192, 512]) {
        await full(s, 'web/icons/Icon-$s.png');
        await writePng(
          await renderImage(s, s, (c) => maskable(c, s.toDouble())),
          '$out/web/icons/Icon-maskable-$s.png',
        );
      }
      await full(32, 'web/favicon.png');
      await full(512, 'store/play-store-512.png');
      // In-app copy for the About screen (up to ~128 logical px at 3x).
      await full(384, 'assets/icon/app_icon.png');

      // Review sheet: adaptive layers under a circle and a squircle mask.
      const px = 432.0;
      final sheet = await renderImage(3 * 432 + 4 * 32, 432 + 64, (c) {
        c.drawRect(const Rect.fromLTWH(0, 0, 3 * 432 + 4 * 32, 432 + 64), Paint()..color = const Color(0xFFDDDDDD));
        for (var i = 0; i < 3; i++) {
          final r = Rect.fromLTWH(32 + i * (px + 32), 32, px, px);
          c.save();
          // The launcher shows the central 72 of 108 dp.
          final visible = r.deflate(px * 18 / 108);
          if (i == 1) c.clipPath(Path()..addOval(visible));
          if (i == 2) c.clipRRect(RRect.fromRectAndRadius(visible, Radius.circular(visible.width * 0.3)));
          c.translate(r.left, r.top);
          background(c, px);
          foreground(c, px);
          c.restore();
          c.drawCircle(
            r.center,
            px * _safeRadius,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = const Color(0xFF00E5FF),
          );
        }
      });
      await writePng(sheet, '$out/check/android-adaptive.png');
    });
  });
}

// Renders the app icon concepts (KLD-097) to opaque PNGs.
//
//   cd klunki
//   KLUNKI_ICON_OUT=/tmp/icon-concepts flutter test tool/icon/render_icons_test.dart
//
// Lives outside `test/`, so the normal `flutter test` run never picks it up;
// without KLUNKI_ICON_OUT it is skipped as well. Writes per concept
// `concept-<id>-1024.png` (RGB, no alpha channel) and `concept-<id>-preview.png`
// (sizes 180/120/60/40 unmasked, iOS rounded square and Android circle on a
// light and a dark home screen). Also writes `c5-k-compare.png` and
// `c5-k1-compare.png`: variant groups side by side at 256, 180 and 60 px
// (iOS mask on the small rows).
//
// `c5-zoom-compare.png` (plus `c5-zoom-row-<id>.png` per icon) compares the
// app icon c5-final-d4 with its zoomed variants: 1024 px, 180/120/60/30 px
// plain and in the iOS mask on a light and a dark home screen, the Android
// 66 % / 80 % safe circles and the adaptive icon as the export would build
// it, and a home-screen row between placeholder icons; `c5-zoom-small.png`
// puts all of them side by side at 120/60/30 px. Run only this one
// with `--plain-name c5-zoom`.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'icon_concepts.dart';
import 'icon_png.dart';

final String? _out = Platform.environment['KLUNKI_ICON_OUT'];

void main() {
  setUpAll(() async {
    if (_out != null) await loadIconFonts();
  });
  final ids = iconConcepts.keys;
  final compare = {
    // The first wordmark round: c5-k1 … c5-k6.
    'c5-k-compare': [
      for (final id in ids)
        if (RegExp(r'^c5-k\d$').hasMatch(id)) id,
    ],
    // The leather patch (k1) styles and the card variants.
    // card-b with patch steps from k1 to k1b, and the letter tile placements.
    'c5-cb-compare': [
      for (final id in ids)
        if (id.startsWith('c5-cb')) id,
    ],
    // The base c5-cb-tile-1 and the die variants.
    'c5-final-compare': [
      'c5-cb-tile-1',
      for (final id in ids)
        if (id.startsWith('c5-final-d')) id,
    ],
    'c5-k1-compare': [
      for (final id in ids)
        if (id.startsWith('c5-k1')) id,
    ],
  };
  testWidgets('c5-zoom-compare sheet', skip: _out == null, (tester) async {
    await tester.runAsync(() async {
      final zoomIds = [
        'c5-final-d4',
        for (final id in ids)
          if (id.startsWith('c5-zoom-')) id,
      ];
      final rows = <ui.Image>[];
      for (final id in zoomIds) {
        final paint = iconConcepts[id]!.$2;
        final extent = await motifExtent(paint);
        final fit = await foregroundSafeScale(paint);
        // ignore: avoid_print
        print(
          '$id: motif ${(extent.box.width * 100).round()} % × ${(extent.box.height * 100).round()} % '
          'of the side, Android foreground scale ${fit.toStringAsFixed(2)}',
        );
        final row = await renderImage(
          _zoomW.toInt(),
          _zoomRowH.toInt(),
          (c) => _zoomRow(c, id, paint, extent.box, fit),
        );
        await writePng(row, '$_out/c5-zoom-row-$id.png');
        rows.add(row);
      }
      final sheet = await renderImage(_zoomW.toInt(), (_zoomRowH * rows.length).toInt(), (c) {
        for (var i = 0; i < rows.length; i++) {
          c.drawImage(rows[i], Offset(0, i * _zoomRowH), Paint());
        }
      });
      await writePng(sheet, '$_out/c5-zoom-compare.png');
      // Small sizes at a glance: every icon at 120, 60 and 30 px in the iOS
      // mask, on a light and a dark home screen.
      const colW = 200.0;
      final small = await renderImage((colW * zoomIds.length).toInt(), 2 * 300, (c) {
        for (final (b, bg) in [const Color(0xFFF2F2F7), const Color(0xFF1C1C1E)].indexed) {
          c.drawRect(Rect.fromLTWH(0, b * 300.0, colW * zoomIds.length, 300), Paint()..color = bg);
          for (final (i, id) in zoomIds.indexed) {
            final fg = b == 0 ? const Color(0xFF1C1C1E) : const Color(0xFFFFFFFF);
            _text(c, id, Offset(i * colW + colW / 2, b * 300.0 + 10), 18, fg, center: true);
            var y = b * 300.0 + 44;
            for (final s in [120.0, 60.0, 30.0]) {
              final r = Rect.fromLTWH(i * colW + (colW - s) / 2, y, s, s);
              _paintAt(c, iconConcepts[id]!.$2, r, clip: _squircle(r));
              y += s + 12;
            }
          }
        }
      });
      await writePng(small, '$_out/c5-zoom-small.png');
    });
  });
  for (final MapEntry(key: name, value: ids) in compare.entries) {
    testWidgets('$name sheet', skip: _out == null, (tester) async {
      await tester.runAsync(() async {
        final icons = [for (final id in ids) await renderImage(1024, 1024, (c) => iconConcepts[id]!.$2(c, 1024))];
        await writePng(await _compareSheet(ids, icons), '$_out/$name.png');
      });
    });
  }
  for (final MapEntry(key: id, value: (title, paint)) in iconConcepts.entries) {
    testWidgets('icon concept $id ($title)', skip: _out == null, (tester) async {
      await tester.runAsync(() async {
        final icon = await renderImage(1024, 1024, (c) => paint(c, 1024));
        await writePng(icon, '$_out/concept-$id-1024.png');
        final preview = await renderImage(_sheetW, _sheetH, (c) => _sheet(c, icon));
        await writePng(preview, '$_out/concept-$id-preview.png');
      });
    });
  }
}

/// [icons] side by side at 256 px (no mask), 180 and 60 px (iOS mask).
Future<ui.Image> _compareSheet(List<String> ids, List<ui.Image> icons) {
  const gap = 32.0, label = 44.0;
  const rows = [256.0, 180.0, 60.0];
  final w = gap + ids.length * (256 + gap);
  final h = gap + rows.fold(0.0, (a, s) => a + s + gap) + label;
  return renderImage(w.toInt(), h.toInt(), (c) {
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFF2F2F7));
    var y = gap;
    for (var i = 0; i < ids.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: ids[i],
          style: const TextStyle(fontFamily: iconFontFamily, fontSize: 26, color: Color(0xFF1C1C1E)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(gap + i * (256 + gap) + (256 - tp.width) / 2, y));
    }
    y += label;
    for (final s in rows) {
      for (var i = 0; i < ids.length; i++) {
        final r = Rect.fromLTWH(gap + i * (256 + gap) + (256 - s) / 2, y, s, s);
        _drawIcon(c, icons[i], r, s == 256 ? null : _squircle(r));
      }
      y += s + gap;
    }
  });
}

// ------------------------------------------------------------ preview --

const _sizes = [180.0, 120.0, 60.0, 40.0];
const _pad = 40.0;
const _rowH = 180.0 + 2 * _pad;
const _sheetW = 1240;
const _sheetH = 3 * 260; // unmasked on neutral, light home, dark home

void _sheet(Canvas c, ui.Image icon) {
  final bands = [const Color(0xFFDDDDDD), const Color(0xFFF2F2F7), const Color(0xFF1C1C1E)];
  for (var b = 0; b < 3; b++) {
    final top = b * _rowH;
    c.drawRect(Rect.fromLTWH(0, top, _sheetW.toDouble(), _rowH), Paint()..color = bands[b]);
    var x = _pad;
    if (b == 0) {
      // Unmasked squares (what the 1024 master looks like when scaled).
      for (final s in _sizes) {
        _drawIcon(c, icon, Rect.fromLTWH(x, top + (_rowH - s) / 2, s, s), null);
        x += s + _pad;
      }
      // Safe-zone guide: the central 66 % circle (Android adaptive icons)
      // and the 80 % circle (PWA maskable icons).
      x += _pad;
      final r = Rect.fromLTWH(x, top + _pad, 180, 180);
      _drawIcon(c, icon, r, null);
      final guide = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      c.drawCircle(r.center, 90 * 0.66, guide..color = const Color(0xFF00E5FF));
      c.drawCircle(r.center, 90 * 0.8, guide..color = const Color(0xCCFFFFFF));
      continue;
    }
    for (final s in _sizes) {
      final r = Rect.fromLTWH(x, top + (_rowH - s) / 2, s, s);
      _drawIcon(c, icon, r, _squircle(r));
      x += s + _pad;
    }
    x += _pad;
    for (final s in _sizes) {
      final r = Rect.fromLTWH(x, top + (_rowH - s) / 2, s, s);
      _drawIcon(c, icon, r, Path()..addOval(r));
      x += s + _pad;
    }
  }
}

void _drawIcon(Canvas c, ui.Image icon, Rect r, Path? clip) {
  c.save();
  if (clip != null) c.clipPath(clip);
  c.drawImageRect(
    icon,
    const Rect.fromLTWH(0, 0, 1024, 1024),
    r,
    Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true,
  );
  c.restore();
}

/// iOS-like continuous rounded square (corner radius ≈ 22.4 %).
Path _squircle(Rect r) {
  // A superellipse with n = 5 is close to Apple's mask.
  const n = 5.0;
  final path = Path();
  final a = r.width / 2, b = r.height / 2;
  for (var i = 0; i <= 360; i++) {
    final t = i * math.pi / 180;
    final ct = math.cos(t), st = math.sin(t);
    final x = a * math.pow(ct.abs(), 2 / n) * ct.sign;
    final y = b * math.pow(st.abs(), 2 / n) * st.sign;
    final p = r.center + Offset(x, y);
    i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

// ------------------------------------------------------- zoom sheet --

const _zg = 32.0; // gap
const _zLabel = 64.0;
const _zSizes = [180.0, 120.0, 60.0, 30.0];
const _zPanelW = _zg + 180 + 120 + 60 + 30 + 4 * 24.0;
const _zPanelH = 2 * 180 + 3 * 24.0;
const _zAndroidW = 2 * 210 + 3 * 24.0;
const _zHomeW = 4 * 76 + 5 * 22.0;
const _zoomW = _zg + 1024 + _zg + _zPanelW + _zg + _zAndroidW + _zg + _zHomeW + _zg;
const _zoomRowH = _zLabel + 1024 + 2 * _zg;

/// Paints [paint] (vector, straight at the target size) into [r].
void _paintAt(Canvas c, IconConcept paint, Rect r, {Path? clip}) {
  c.save();
  if (clip != null) c.clipPath(clip);
  c.translate(r.left, r.top);
  paint(c, r.width);
  c.restore();
}

void _text(Canvas c, String s, Offset at, double size, Color color, {bool bold = false, bool center = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: iconFontFamily,
        fontSize: size,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center ? at - Offset(tp.width / 2, 0) : at);
}

/// One row of the zoom sheet: [id] at every size and in every mask.
void _zoomRow(Canvas c, String id, IconConcept paint, Rect box, double fit) {
  const ink = Color(0xFF1C1C1E);
  c.drawRect(const Rect.fromLTWH(0, 0, _zoomW, _zoomRowH), Paint()..color = const Color(0xFFDDDDDD));
  _text(c, id, const Offset(_zg, 14), 34, ink, bold: true);
  _text(
    c,
    '${iconConcepts[id]!.$1}  ·  motif ${(box.width * 100).round()} % × ${(box.height * 100).round()} % '
    'of the side  ·  Android foreground scale ${fit.toStringAsFixed(2)}',
    const Offset(_zg + 330, 22),
    24,
    ink,
  );
  final top = _zLabel + _zg;
  var x = _zg;
  // 1024, unmasked.
  _paintAt(c, paint, Rect.fromLTWH(x, top, 1024, 1024));
  x += 1024 + _zg;

  // Light and dark home screen: plain squares above, iOS mask below.
  for (final (i, bg) in [const Color(0xFFF2F2F7), const Color(0xFF1C1C1E)].indexed) {
    final py = top + i * (_zPanelH + 40);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, py, _zPanelW, _zPanelH), const Radius.circular(18)),
      Paint()..color = bg,
    );
    for (var row = 0; row < 2; row++) {
      var sx = x + 24;
      for (final s in _zSizes) {
        final r = Rect.fromLTWH(sx, py + 24 + row * (180 + 24) + (180 - s) / 2, s, s);
        _paintAt(c, paint, r, clip: row == 1 ? _squircle(r) : null);
        sx += s + 24;
      }
    }
  }
  _text(c, '180 · 120 · 60 · 30 px, plain / iOS mask', Offset(x, top + 2 * _zPanelH + 40 + 12), 22, ink);
  x += _zPanelW + _zg;

  // Android: the full icon with the safe circles, then the adaptive icon as
  // the export builds it (foreground shrunk into the 66 dp circle).
  final big = Rect.fromLTWH(x, top, _zAndroidW, _zAndroidW);
  _paintAt(c, paint, big);
  final guide = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  c.drawCircle(big.center, big.width / 2 * 0.66, guide..color = const Color(0xFF00E5FF));
  c.drawCircle(big.center, big.width / 2 * 0.8, guide..color = const Color(0xCCFFFFFF));
  _text(c, 'cyan 66 % (Android), white 80 % (PWA)', Offset(x, big.bottom + 8), 22, ink);
  _text(c, 'Android adaptive (export), circle / squircle', Offset(x, big.bottom + 52), 22, ink);
  for (final (i, s) in [210.0, 60.0].indexed) {
    for (var m = 0; m < 2; m++) {
      final visible = Rect.fromLTWH(x + m * (210 + 24) + (210 - s) / 2, big.bottom + 92 + i * (210 + 24), s, s);
      final layer = visible.inflate(s * 18 / 72);
      c.save();
      c.clipPath(
        m == 0
            ? (Path()..addOval(visible))
            : (Path()..addRRect(RRect.fromRectAndRadius(visible, Radius.circular(s * 0.3)))),
      );
      c.translate(layer.left, layer.top);
      final px = layer.width;
      iconLayer = IconLayer.background;
      paint(c, px);
      iconLayer = IconLayer.foreground;
      c.translate(px / 2, px / 2);
      c.scale(fit);
      c.translate(-px / 2, -px / 2);
      paint(c, px);
      iconLayer = IconLayer.full;
      c.restore();
    }
  }
  x += _zAndroidW + _zg;

  // Fake home-screen rows at 60 px between placeholder apps.
  const placeholders = [(Color(0xFF34C759), 'Uhr'), (Color(0xFF5E9CF0), 'Wetter'), (Color(0xFFAF7AC5), 'Notizen')];
  for (final (i, dark) in [false, true].indexed) {
    final r = Rect.fromLTWH(x, top + i * 260, _zHomeW, 230);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(18)),
      Paint()
        ..shader = ui.Gradient.linear(
          r.topLeft,
          r.bottomRight,
          dark
              ? [const Color(0xFF1B2233), const Color(0xFF3A2440)]
              : [const Color(0xFFB9D7F2), const Color(0xFFF5D6C6)],
        ),
    );
    final label = dark ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1E);
    for (var k = 0; k < 4; k++) {
      final cx = r.left + 22 + k * (76 + 22) + 38;
      final ir = Rect.fromCenter(center: Offset(cx, r.top + 90), width: 60, height: 60);
      if (k == 2) {
        _paintAt(c, paint, ir, clip: _squircle(ir));
        _text(c, 'Klunki', Offset(cx, ir.bottom + 8), 13, label, center: true);
      } else {
        final (color, name) = placeholders[k == 3 ? 2 : k];
        c.save();
        c.clipPath(_squircle(ir));
        c.drawRect(
          ir,
          Paint()
            ..shader = ui.Gradient.linear(ir.topCenter, ir.bottomCenter, [
              Color.lerp(color, const Color(0xFFFFFFFF), 0.25)!,
              color,
            ]),
        );
        c.drawCircle(ir.center, 15, Paint()..color = const Color(0xE6FFFFFF));
        c.restore();
        _text(c, name, Offset(cx, ir.bottom + 8), 13, label, center: true);
      }
    }
  }
  _text(c, 'home screen, 60 px', Offset(x, top + 2 * 260), 22, ink);
  // The in-app header size.
  final hy = top + 2 * 260 + 60;
  _text(c, 'menu header, 30 px', Offset(x, hy), 22, ink);
  for (final (i, bg) in [const Color(0xFFFBF4E8), const Color(0xFF1F1A16)].indexed) {
    final r = Rect.fromLTWH(x + i * 200, hy + 40, 180, 60);
    c.drawRect(r, Paint()..color = bg);
    final ir = Rect.fromLTWH(r.left + 15, r.top + 15, 30, 30);
    _paintAt(c, paint, ir, clip: Path()..addRRect(RRect.fromRectAndRadius(ir, const Radius.circular(7))));
    _text(c, 'Klunki', Offset(r.left + 54, r.top + 18), 20, i == 0 ? ink : const Color(0xFFFFFFFF), bold: true);
  }
}

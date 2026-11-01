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

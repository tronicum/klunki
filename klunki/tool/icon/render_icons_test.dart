// Renders the app icon concepts (KLD-097) to opaque PNGs.
//
//   cd klunki
//   KLUNKI_ICON_OUT=/tmp/icon-concepts flutter test tool/icon/render_icons_test.dart
//
// Lives outside `test/`, so the normal `flutter test` run never picks it up;
// without KLUNKI_ICON_OUT it is skipped as well. Writes per concept
// `concept-<id>-1024.png` (RGB, no alpha channel) and `concept-<id>-preview.png`
// (sizes 180/120/60/40 unmasked, iOS rounded square and Android circle on a
// light and a dark home screen). Also writes `c5-k-compare.png`: the c5-k
// variants side by side at 256, 180 and 60 px (iOS mask on the small rows).
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';

import 'icon_concepts.dart';

final String? _out = Platform.environment['KLUNKI_ICON_OUT'];

Future<void> _loadFont() async {
  final loader = FontLoader(iconFontFamily);
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    if (_out != null) await _loadFont();
  });
  testWidgets('c5-k compare sheet', skip: _out == null, (tester) async {
    await tester.runAsync(() async {
      final ids = [
        for (final id in iconConcepts.keys)
          if (id.startsWith('c5-k')) id,
      ];
      final icons = [for (final id in ids) await _render(1024, 1024, (c) => iconConcepts[id]!.$2(c, 1024))];
      const gap = 32.0, label = 44.0;
      const rows = [256.0, 180.0, 60.0];
      final w = gap + ids.length * (256 + gap);
      final h = gap + rows.fold(0.0, (a, s) => a + s + gap) + label;
      final sheet = await _render(w.toInt(), h.toInt(), (c) {
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
      await _writePng(sheet, '$_out/c5-k-compare.png');
    });
  });
  for (final MapEntry(key: id, value: (title, paint)) in iconConcepts.entries) {
    testWidgets('icon concept $id ($title)', skip: _out == null, (tester) async {
      await tester.runAsync(() async {
        final icon = await _render(1024, 1024, (c) => paint(c, 1024));
        await _writePng(icon, '$_out/concept-$id-1024.png');
        final preview = await _render(_sheetW, _sheetH, (c) => _sheet(c, icon));
        await _writePng(preview, '$_out/concept-$id-preview.png');
      });
    });
  }
}

Future<ui.Image> _render(int w, int h, void Function(Canvas c) body) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  body(c);
  return rec.endRecording().toImage(w, h);
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

// --------------------------------------------------------- PNG (RGB) --

/// Writes [img] as an 8-bit RGB PNG (colour type 2, no alpha channel).
Future<void> _writePng(ui.Image img, String path) async {
  final data = (await img.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
  final w = img.width, h = img.height;
  final raw = BytesBuilder(copy: false);
  final row = Uint8List(1 + w * 3);
  for (var y = 0; y < h; y++) {
    row[0] = 0; // filter: none
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      // Composite on black would be the same for opaque pixels; the canvas is
      // opaque, so the alpha byte is simply dropped.
      row[1 + x * 3] = data[i];
      row[2 + x * 3] = data[i + 1];
      row[3 + x * 3] = data[i + 2];
    }
    raw.add(Uint8List.fromList(row));
  }
  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // colour type RGB
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final out = BytesBuilder()
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    ..add(_chunk('IHDR', ihdr.buffer.asUint8List()))
    ..add(_chunk('IDAT', Uint8List.fromList(ZLibCodec(level: 9).encode(raw.takeBytes()))))
    ..add(_chunk('IEND', Uint8List(0)));
  final f = File(path)..parent.createSync(recursive: true);
  f.writeAsBytesSync(out.takeBytes());
}

Uint8List _chunk(String type, Uint8List data) {
  final b = BytesBuilder();
  final len = ByteData(4)..setUint32(0, data.length);
  final typeBytes = type.codeUnits;
  b
    ..add(len.buffer.asUint8List())
    ..add(typeBytes)
    ..add(data);
  final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
  b.add(crc.buffer.asUint8List());
  return b.takeBytes();
}

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

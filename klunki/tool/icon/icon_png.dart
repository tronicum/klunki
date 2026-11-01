// Shared helpers for the icon tools (KLD-097): font loading, rendering a
// painter to an image, and a small PNG encoder (Flutter's own PNG export is
// always RGBA; the App Store icon must not have an alpha channel).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show FontLoader;

import 'icon_concepts.dart';

/// Loads Roboto (used by the "Klunki" letterings) from the app's assets.
/// Run from the `klunki/` directory.
Future<void> loadIconFonts() async {
  final loader = FontLoader(iconFontFamily);
  for (final w in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/Roboto/Roboto-$w.ttf').readAsBytesSync())));
  }
  await loader.load();
}

/// Records [body] on a [w] × [h] canvas and returns the image.
Future<ui.Image> renderImage(int w, int h, void Function(Canvas c) body) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  body(c);
  return rec.endRecording().toImage(w, h);
}

// ---------------------------------------------------------------- PNG --

/// Writes [img] as an 8-bit PNG: RGB without an alpha channel (colour type 2;
/// for opaque icons, e.g. the App Store marketing icon) or, with [alpha],
/// straight (non-premultiplied) RGBA (colour type 6).
Future<void> writePng(ui.Image img, String path, {bool alpha = false}) async {
  final data = (await img.toByteData(format: alpha ? ui.ImageByteFormat.rawStraightRgba : ui.ImageByteFormat.rawRgba))!
      .buffer
      .asUint8List();
  final w = img.width, h = img.height, ch = alpha ? 4 : 3;
  final raw = BytesBuilder(copy: false);
  final row = Uint8List(1 + w * ch);
  for (var y = 0; y < h; y++) {
    row[0] = 0; // filter: none
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      // Opaque canvases: the alpha byte is simply dropped.
      for (var k = 0; k < ch; k++) {
        row[1 + x * ch + k] = data[i + k];
      }
    }
    raw.add(Uint8List.fromList(row));
  }
  final ihdr = ByteData(13)
    ..setUint32(0, w)
    ..setUint32(4, h)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, alpha ? 6 : 2) // colour type RGBA / RGB
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

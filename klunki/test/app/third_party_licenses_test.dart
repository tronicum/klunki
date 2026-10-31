import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klunki/app/third_party_licenses.dart';

void main() {
  test('zxing-cpp and libzint licences are registered once (KLD-080)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerNativeLicenses(web: false);
    registerNativeLicenses(web: false);
    final entries = await LicenseRegistry.licenses.toList();
    String textOf(String package) {
      final mine = entries.where((e) => e.packages.contains(package)).toList();
      expect(mine, hasLength(1), reason: package);
      return mine.single.paragraphs.map((p) => p.text).join('\n');
    }

    expect(textOf('zxing-cpp'), contains('Apache License'));
    expect(textOf('libzint'), contains('Robin Stuart'));
  });
}

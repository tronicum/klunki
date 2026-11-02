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

  test('the Wortgewandt word list licences are on the licence page (KLD-094 step 7)', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerWordListLicenses();
    registerWordListLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    String textOf(String package) {
      final mine = entries.where((e) => e.packages.contains(package)).toList();
      expect(mine, hasLength(1), reason: package);
      return mine.single.paragraphs.map((p) => p.text).join('\n');
    }

    expect(textOf('Wortgewandt word list (de): enz/german-wordlist'), contains('CC0 1.0 Universal'));
    expect(textOf('Wortgewandt word list (en): English Speller Database (SCOWL)'), contains('Kevin Atkinson'));
  });
}

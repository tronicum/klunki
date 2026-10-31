import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licences of native code that a package compiles into the app but whose
/// licence file the package does not ship (KLD-080). Flutter's license page
/// lists each package's own LICENSE automatically; flutter_zxing's is MIT and
/// does not cover the C/C++ sources it bundles:
/// - zxing-cpp (Apache-2.0; its section 4 asks for a copy of the licence),
/// - libzint, zxing-cpp's barcode writer backend (BSD-3-Clause).
const Map<String, String> nativeLicenseAssets = {
  'zxing-cpp': 'assets/licenses/zxing-cpp/LICENSE',
  'libzint': 'assets/licenses/libzint/LICENSE',
};

bool _registered = false;

/// Adds [nativeLicenseAssets] to the app's license page on Android and iOS
/// (the web build contains no flutter_zxing code). Idempotent.
void registerNativeLicenses({bool web = kIsWeb}) {
  if (web || _registered) return;
  _registered = true;
  LicenseRegistry.addLicense(() async* {
    for (final e in nativeLicenseAssets.entries) {
      final text = await rootBundle.loadString(e.value);
      yield LicenseEntryWithLineBreaks([e.key], text);
    }
  });
}

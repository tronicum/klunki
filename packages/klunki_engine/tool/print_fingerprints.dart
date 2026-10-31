import 'package:klunki_engine/klunki_engine.dart';

/// Prints every game's compatibility fingerprint (KLD-085), e.g. to update
/// the golden values in `test/compat_test.dart` after a deliberate change:
/// `dart run tool/print_fingerprints.dart`.
void main() {
  final all = allFingerprints();
  for (final k in all.keys) {
    print("'$k': ${all[k]!.toJson()},");
  }
  print('catalog ${catalogFingerprint()}');
}

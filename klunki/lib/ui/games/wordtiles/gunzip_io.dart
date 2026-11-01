import 'dart:io';
import 'dart:typed_data';

/// Native (iOS, Android, desktop, tests): the Dart VM's zlib.
Future<Uint8List> gunzipBytes(Uint8List gz) async => Uint8List.fromList(gzip.decode(gz));

/// Whether [gunzipBytes] may run in a background isolate ([compute]).
const bool gunzipInIsolate = true;

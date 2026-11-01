import 'dart:js_interop';
import 'dart:typed_data';

/// Web: the browser's own `DecompressionStream('gzip')` (every current
/// browser has it), through `dart:js_interop` from the SDK: no package and
/// no gzip code in the PWA bundle. Pipeline:
/// `new Response(new Blob([gz]).stream().pipeThrough(new DecompressionStream('gzip'))).arrayBuffer()`.
Future<Uint8List> gunzipBytes(Uint8List gz) async {
  final stream = _Blob([gz.toJS].toJS).stream().pipeThrough(_DecompressionStream('gzip'));
  final buffer = await _Response(stream).arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

/// The web has no isolates for [compute]; it runs on the main thread.
const bool gunzipInIsolate = false;

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts);
  external _ReadableStream stream();
}

extension type _ReadableStream._(JSObject _) implements JSObject {
  external _ReadableStream pipeThrough(JSObject transform);
}

@JS('DecompressionStream')
extension type _DecompressionStream._(JSObject _) implements JSObject {
  external factory _DecompressionStream(String format);
}

@JS('Response')
extension type _Response._(JSObject _) implements JSObject {
  external factory _Response(JSObject body);
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

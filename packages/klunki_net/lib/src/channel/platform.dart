/// The platform's transports, picked at compile time: `dart:io` (TCP +
/// WebSocket, can host) or the browser (WebSocket guest only). Importing this
/// file never pulls `dart:io` into a web build.
library;

export 'platform_stub.dart'
    if (dart.library.io) 'platform_io.dart'
    if (dart.library.js_interop) 'platform_web.dart';

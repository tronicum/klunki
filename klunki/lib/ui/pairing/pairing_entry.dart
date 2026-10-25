/// Web-safe entry point to the Wi-Fi pairing screen (KLD-034).
///
/// The pairing screen needs sockets (`klunki_net` imports `dart:io`), so the
/// menu reaches it only through this conditional import: on web
/// [pairingScreenBuilder] is null and the menu hides "Über WLAN spielen".
library;

import 'package:flutter/widgets.dart';

import 'pairing_entry_stub.dart' if (dart.library.io) 'pairing_entry_io.dart' as impl;

/// Builds the pairing screen; null where there are no sockets (web).
WidgetBuilder? get pairingScreenBuilder => impl.pairingScreenBuilder;

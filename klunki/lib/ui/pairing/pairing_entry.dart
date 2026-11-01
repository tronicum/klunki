/// Web-safe entry points to "Mit anderen Geräten spielen" (KLD-034, KLD-055,
/// KLD-098): "Raum starten" and "Raum beitreten".
///
/// Native builds get the [PairingScreen]s (rooms on this device over TCP +
/// mDNS, or through the relay; scanner, room code, rooms nearby). The web
/// build gets the relay room screen and the browser join screen. The
/// conditional import keeps `bonsoir` and the other native-only pairing code
/// out of the web build.
library;

import 'package:flutter/widgets.dart';

import 'pairing_entry_stub.dart' if (dart.library.io) 'pairing_entry_io.dart' as impl;
import 'web_join_screen.dart';

/// Builds "Raum starten" for this platform (null: no network play).
WidgetBuilder? get roomStartScreenBuilder => impl.roomStartScreenBuilder;

/// Builds "Raum beitreten" for this platform (null: no network play).
WidgetBuilder? get roomJoinScreenBuilder => impl.roomJoinScreenBuilder;

/// The join screen for a `?join=<link>` page URL parameter (KLD-055): opens
/// the browser join flow and connects right away. Works natively too (the
/// join goes over WebSocket either way); the app only calls it on the web.
Widget webJoinScreenFor(String link, {Uri? pageUrl, WebJoinDeps? deps}) =>
    WebJoinScreen(initialInput: link, autoConnect: true, pageUrl: pageUrl, deps: deps);

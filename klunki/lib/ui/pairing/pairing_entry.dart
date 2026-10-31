/// Web-safe entry point to "Über WLAN spielen" (KLD-034, KLD-055).
///
/// Native builds get the full pairing screen (host + join over TCP, mDNS).
/// The web build gets the join-only [WebJoinScreen] (WebSocket to a native
/// host). The conditional import keeps `bonsoir` and the other native-only
/// pairing code out of the web build.
library;

import 'package:flutter/widgets.dart';

import 'pairing_entry_stub.dart' if (dart.library.io) 'pairing_entry_io.dart' as impl;
import 'web_join_screen.dart';

/// Builds the pairing screen for this platform (null: no network play).
WidgetBuilder? get pairingScreenBuilder => impl.pairingScreenBuilder;

/// The join screen for a `?join=<link>` page URL parameter (KLD-055): opens
/// the browser join flow and connects right away. Works natively too (the
/// join goes over WebSocket either way); the app only calls it on the web.
Widget webJoinScreenFor(String link, {Uri? pageUrl, WebJoinDeps? deps}) =>
    WebJoinScreen(initialInput: link, autoConnect: true, pageUrl: pageUrl, deps: deps);

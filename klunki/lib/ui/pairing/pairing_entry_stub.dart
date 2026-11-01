import 'package:flutter/widgets.dart';

import 'web_join_screen.dart';

/// Web: "Raum starten" through the relay of this page (KLD-057b); a page
/// cannot listen for guests itself.
WidgetBuilder? get roomStartScreenBuilder => (_) => webRoomStartScreen(pageUrl: Uri.base);

/// Web: "Raum beitreten" by room code (no camera scanner, no mDNS; KLD-055).
WidgetBuilder? get roomJoinScreenBuilder => (_) => WebJoinScreen(pageUrl: Uri.base);

/// Web: "Raum starten" through the relay for one game (KLD-105, a tile's
/// "Mit anderen").
Widget Function(String gameId)? get roomStartForGameBuilder =>
    (gameId) => webRoomStartScreen(pageUrl: Uri.base, gameId: gameId);

import 'package:flutter/widgets.dart';

import 'pairing_screen.dart';

/// Native: "Raum starten" (room on this device, or through the relay).
WidgetBuilder? get roomStartScreenBuilder => (_) => PairingScreen(mode: RoomMode.start);

/// Native: "Raum beitreten" (scanner, room code, rooms nearby).
WidgetBuilder? get roomJoinScreenBuilder => (_) => PairingScreen(mode: RoomMode.join);

/// Native: "Raum starten" for one game (KLD-105, a tile's "Mit anderen").
Widget Function(String gameId)? get roomStartForGameBuilder =>
    (gameId) => PairingScreen(mode: RoomMode.start, gameId: gameId);

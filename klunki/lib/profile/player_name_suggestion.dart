/// Default player name suggestion (KLD-056), web-safe: the device name
/// natively (`device_name.dart` needs `dart:io`), "Browser" on the web.
library;

import 'player_name_suggestion_stub.dart' if (dart.library.io) 'player_name_suggestion_io.dart' as impl;

/// The suggestion for the "Wie heißt du?" field.
String defaultPlayerNameSuggestion() => impl.defaultPlayerNameSuggestion();

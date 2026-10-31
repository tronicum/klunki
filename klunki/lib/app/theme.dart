import 'package:flutter/material.dart';

import 'fonts.dart';

/// Application colour + typography. Text uses the bundled fonts in every
/// locale (Roboto on the web + script fallbacks, see `fonts.dart`).
class KlunkiTheme {
  static const Color _seed = Color(0xFF4F46E5);

  static ThemeData get light => withAppFonts(
      ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: _seed)));

  static ThemeData get dark => withAppFonts(
        ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
              seedColor: _seed, brightness: Brightness.dark),
        ),
      );
}

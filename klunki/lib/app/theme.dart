import 'package:flutter/material.dart';

/// Application colour + typography.
class KlunkiTheme {
  static const Color _seed = Color(0xFF4F46E5);

  static ThemeData get light =>
      ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: _seed));

  static ThemeData get dark =>
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: _seed, brightness: Brightness.dark),
      );
}

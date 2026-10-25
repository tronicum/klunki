import 'package:flutter/material.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'theme.dart';

/// The Klunki root widget. Pure UI + routing; all game logic lives in
/// `klunki_engine` and all play delivery lives in `klunki/lib/transport`.
class KlunkiApp extends StatelessWidget {
  const KlunkiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klunki',
      debugShowCheckedModeBanner: false,
      theme: KlunkiTheme.light,
      darkTheme: KlunkiTheme.dark,
      home: const MenuScreen(),
    );
  }
}

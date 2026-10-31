import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/room_link.dart';
import 'package:klunki/net/web_join_target.dart';
import 'package:klunki/profile/player_name_controller.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart' show WebJoinDeps;

import 'theme.dart';

/// The Klunki root widget. Pure UI + routing; all game logic lives in
/// `klunki_engine` and all play delivery lives in `klunki/lib/transport`.
///
/// [localeController] holds the language choice (loaded in `main()`); when
/// omitted, an in-memory controller following the system language is used.
///
/// [pageUrl] is the page URL on the web (default [Uri.base] there, nothing
/// natively): `?join=<klunki:// link>` opens the browser join flow at start
/// (KLD-055), `?room=CODE[&relay=host:port]` joins a relay room (KLD-057b).
class KlunkiApp extends StatefulWidget {
  const KlunkiApp({
    super.key,
    this.localeController,
    this.playerNameController,
    this.hotSeatNames,
    this.pageUrl,
    this.webJoinDeps,
  });

  final LocaleController? localeController;

  /// The player name for network games (KLD-056; loaded in `main()`). When
  /// omitted, an in-memory controller with no name yet is used (the first
  /// visit of "Über WLAN spielen" asks for one).
  final PlayerNameController? playerNameController;

  /// Last-used hot-seat names (KLD-056); in-memory and empty when omitted.
  final HotSeatNamesController? hotSeatNames;
  final Uri? pageUrl;

  /// Test hook for the `?join=` flow (default: the real WebSocket join).
  @visibleForTesting
  final WebJoinDeps? webJoinDeps;

  @override
  State<KlunkiApp> createState() => _KlunkiAppState();
}

class _KlunkiAppState extends State<KlunkiApp> {
  late final LocaleController _controller = widget.localeController ?? LocaleController.memory();
  late final PlayerNameController _playerName = widget.playerNameController ?? PlayerNameController.memory();
  late final HotSeatNamesController _hotSeat = widget.hotSeatNames ?? HotSeatNamesController.memory();
  late final Uri? _pageUrl = widget.pageUrl ?? (kIsWeb ? Uri.base : null);
  late final String? _joinLink = WebJoinTarget.joinParameter(_pageUrl);
  late final RoomLink? _room = RoomLink.fromPage(_pageUrl);

  @override
  Widget build(BuildContext context) {
    return PlayerNameScope(
      controller: _playerName,
      hotSeat: _hotSeat,
      child: LocaleScope(
        controller: _controller,
        child: ValueListenableBuilder<Locale?>(
          valueListenable: _controller,
          builder: (context, locale, _) => MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            theme: KlunkiTheme.light,
            darkTheme: KlunkiTheme.dark,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MenuScreen(
                initialJoinLink: _joinLink, initialRoom: _room, pageUrl: _pageUrl, webJoinDeps: widget.webJoinDeps),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/net/web_join_target.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'package:klunki/ui/pairing/web_join_screen.dart' show WebJoinDeps;
import 'fonts.dart';
import 'theme.dart';

/// The Klunki root widget. Pure UI + routing; all game logic lives in
/// `klunki_engine` and all play delivery lives in `klunki/lib/transport`.
///
/// [localeController] holds the language choice (loaded in `main()`); when
/// omitted, an in-memory controller following the system language is used.
///
/// [pageUrl] is the page URL on the web (default [Uri.base] there, nothing
/// natively): `?join=<klunki:// link>` opens the browser join flow at start
/// (KLD-055).
class KlunkiApp extends StatefulWidget {
  const KlunkiApp({super.key, this.localeController, this.pageUrl, this.webJoinDeps});

  final LocaleController? localeController;
  final Uri? pageUrl;

  /// Test hook for the `?join=` flow (default: the real WebSocket join).
  @visibleForTesting
  final WebJoinDeps? webJoinDeps;

  @override
  State<KlunkiApp> createState() => _KlunkiAppState();
}

class _KlunkiAppState extends State<KlunkiApp> {
  late final LocaleController _controller =
      widget.localeController ?? LocaleController.memory();
  late final Uri? _pageUrl = widget.pageUrl ?? (kIsWeb ? Uri.base : null);
  late final String? _joinLink = WebJoinTarget.joinParameter(_pageUrl);

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
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
          // Arabic-script locales get the bundled Noto Sans Arabic as text
          // fallback (offline web, I18N-04b).
          builder: (context, child) {
            final theme = Theme.of(context);
            final localized =
                themeForLocale(theme, Localizations.localeOf(context));
            return identical(localized, theme)
                ? child!
                : Theme(data: localized, child: child!);
          },
          home: MenuScreen(initialJoinLink: _joinLink, pageUrl: _pageUrl, webJoinDeps: widget.webJoinDeps),
        ),
      ),
    );
  }
}

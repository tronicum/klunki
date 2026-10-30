import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';
import 'package:klunki/ui/menu_screen.dart';
import 'fonts.dart';
import 'theme.dart';

/// The Klunki root widget. Pure UI + routing; all game logic lives in
/// `klunki_engine` and all play delivery lives in `klunki/lib/transport`.
///
/// [localeController] holds the language choice (loaded in `main()`); when
/// omitted, an in-memory controller following the system language is used.
class KlunkiApp extends StatefulWidget {
  const KlunkiApp({super.key, this.localeController});

  final LocaleController? localeController;

  @override
  State<KlunkiApp> createState() => _KlunkiAppState();
}

class _KlunkiAppState extends State<KlunkiApp> {
  late final LocaleController _controller =
      widget.localeController ?? LocaleController.memory();

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
          home: const MenuScreen(),
        ),
      ),
    );
  }
}

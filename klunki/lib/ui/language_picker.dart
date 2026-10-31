import 'package:flutter/material.dart';
import 'package:klunki/app/fonts.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/l10n/locale_controller.dart';

/// App-bar button that opens the [LanguagePicker].
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('language-button'),
      icon: const Icon(Icons.language),
      tooltip: AppLocalizations.of(context).menuLanguage,
      onPressed: () => showLanguagePicker(context),
    );
  }
}

/// Shows the picker and applies the choice to the app's [LocaleController].
Future<void> showLanguagePicker(BuildContext context) async {
  final controller = LocaleScope.of(context);
  await showDialog<void>(
    context: context,
    builder: (_) => LanguagePicker(controller: controller),
  );
}

/// Dialog listing "System" plus every language as its endonym; the current
/// choice is checked. Tapping an entry applies it and closes the dialog.
class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, required this.controller});

  final LocaleController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = controller.value;
    Widget entry(String key, String label, Locale? locale) {
      final selected = current == locale;
      return ListTile(
        key: Key('language-$key'),
        // Endonyms include Arabic and Chinese script in every app language
        // (the theme carries the same fallback; explicit for robustness).
        title: Text(label,
            style: const TextStyle(fontFamilyFallback: appFontFallback)),
        trailing: selected ? const Icon(Icons.check) : null,
        selected: selected,
        onTap: () {
          controller.setLocale(locale);
          Navigator.of(context).pop();
        },
      );
    }

    return SimpleDialog(
      title: Text(l10n.languagePickerTitle),
      children: [
        entry('system', l10n.languageSystem, null),
        for (final lang in appLanguages)
          entry(lang.locale.toLanguageTag(), lang.endonym, lang.locale),
      ],
    );
  }
}

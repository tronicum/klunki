import 'package:klunki/l10n/app_localizations.dart';

/// Localized title of the game [id] (a `GameSpec.id`). Ids without a
/// translation fall back to [fallback], normally the engine's German
/// `GameSpec.title`.
String localizedGameTitle(AppLocalizations l10n, String id, {required String fallback}) => switch (id) {
  'connect4' => l10n.menuGameConnect4,
  'muehle' => l10n.menuGameMuehle,
  'quartett-trumpf' => l10n.menuGameQuartettTrumpf,
  'quartett-sets' => l10n.menuGameQuartettSets,
  'schiffe' => l10n.menuGameSchiffe,
  _ => fallback,
};

# I18N-05: localize the strings that come from the engine

- **ID:** `I18N-05` (also covers backlog `KLD-028`)
- **Title:** Machine-readable result reasons in the engine; app maps reason codes, Quartett sets/stats and ship names to `AppLocalizations`
- **Status:** DONE
- **Depends on:** I18N-01, I18N-02 (+02b)
- **Touched paths:**
  - `packages/klunki_engine/lib/{game,connect4,muehle,quartett,schiffe}.dart`
  - `packages/klunki_engine/test/{connect4,muehle,quartett,schiffe}_test.dart`, new `test/result_code_test.dart`
  - `klunki/lib/l10n/*.arb` + generated `app_localizations*.dart`
  - new `klunki/lib/ui/engine_l10n.dart`
  - `klunki/lib/ui/shell/game_screen.dart` (result dialog), `klunki/lib/ui/games/quartett_card.dart`,
    `quartett_trumpf_screen.dart`, `quartett_sets_screen.dart`, `schiffe/schiffe_board.dart`, `schiffe/schiffe_describe.dart` (text only)
  - tests: new `klunki/test/l10n/engine_l10n_test.dart`; `test/ui/shell/{game_screen_test,shell_test_utils}.dart`,
    `test/ui/games/quartett_{sets,trumpf}_screen_test.dart`, `test/e2e/muehle_screens_e2e_test.dart`

## Goal
The result dialog, the Quartett cards and screens and the Schiffe screen show engine-sourced words in the app language
("Vier in einer Reihe" / "Four in a row", "Leistung" / "Power", "U-Boot" / "Submarine"). The engine keeps its English
`reason` text for the CLI, the debug console and the network log.

## Engine
- New `enum GameEndReason` in `game.dart` with a stable string `code` (`<game>.<reason>`) and `fromCode()`.
- `GameResult` gained `code` (`GameEndReason?`, null while running) and `params` (`Map<String, int>`, default `{}`).
  `reason` (English) is unchanged. `GameResult` is not serialized; move/event JSON and the protocol are untouched.

| enum value | code | params | English `reason` |
|---|---|---|---|
| `connect4FourInARow` | `connect4.fourInARow` | | four in a row |
| `connect4BoardFull` | `connect4.boardFull` | | board full |
| `muehleFewerThanThree` | `muehle.fewerThanThree` | | opponent has fewer than 3 pieces |
| `muehleBlocked` | `muehle.blocked` | | opponent has no legal move |
| `muehleNoRemovalLimit` | `muehle.noRemovalLimit` | `moves` | 50 moves without a removal |
| `quartettBothStacksEmpty` | `quartett.bothStacksEmpty` | | both stacks empty |
| `quartettAllCards` | `quartett.allCards` | | opponent has no cards left |
| `quartettTrickLimitEqual` | `quartett.trickLimitEqual` | `a`, `b` | trick limit reached with equal stacks (a:b) |
| `quartettTrickLimitMoreCards` | `quartett.trickLimitMoreCards` | `a`, `b` | trick limit reached, more cards (a:b) |
| `quartettAllQuartetsEqual` | `quartett.allQuartetsEqual` | `a`, `b` | all quartets laid down, a:b |
| `quartettMostQuartets` | `quartett.mostQuartets` | `a`, `b` | more quartets (a:b) |
| `schiffeAllSunk` | `schiffe.allSunk` | | all ships sunk |

## App
- `lib/ui/engine_l10n.dart`: `localizedEndReason(l10n, code, params)` (exhaustive switch, so a new enum value fails
  to compile until mapped), `localizedResultReason(l10n, result)`, `localizedSetName`, `localizedStatLabel`,
  `localizedStatUnit`, `localizedShipName`. Unknown ids fall back to the engine text.
- Used in the result dialog (text keyed `result-reason`), the Quartett card (set name, stat labels, units), the Trumpf
  reveal line and `describeMove`, the Sets screen (badges, groups, "Quartett! … abgelegt", `describeMove`), the Schiffe
  setup/hint lines and `describeSchiffeMove`. `quartettSetName(l10n, set)` and
  `formatQuartettValue(stat, value, {locale, unit})` take the localized parts.
- Car names stay content. Units: de PS / km/h / cm³ / kg / s, en hp / km/h / cc / kg / s.
- 35 new ARB keys (`engineReason*` 12, `engineSet*` 8, `engineStat*` 5, `engineUnit*` 5, `engineShip*` 5), de with
  descriptions and typed placeholders, real English, fr/es/zh/ar/fa with the English text and listed in `@@x-untranslated`.
  Template now has 200 keys.

## Acceptance criteria
- [x] Engine: every finished game has a known code (`test/result_code_test.dart` auto-plays every game for 25 seeds,
      plus random Quartett-sets games with params); specific reasons asserted in the per-game tests.
- [x] App: result dialog in de and en shows the localized reason (`game_screen_test.dart`), a Quartett card in en shows
      English stat labels/units/set name, every `GameEndReason` value maps to a non-empty text in every locale
      (`test/l10n/engine_l10n_test.dart`).
- [x] `dart test` green in `klunki_engine` (124) and `klunki_net` (34, protocol unchanged); `flutter gen-l10n`,
      `flutter analyze`, `flutter test` (185) green; `dart run bin/klunki.dart demo muehle` unchanged.

## Notes
- KLD-028's proposed `germanReason(String)` regex mapping is superseded by the reason codes.
- The shell status line ("X hat gewonnen") has no reason in it, so it needed no change. No layout/directionality
  changes (I18N-04 runs in parallel).

# KLD-110: Quartett polish: thousands separators, Trumpf layout on large phones and tablets

- **ID:** `KLD-110`
- **Title:** Quartett: group large stat values per locale; Trumpf layout on phones and iPads
- **Milestone:** M4 (polish)
- **Status:** DONE (awaiting maintainer review of the screenshots)
- **Depends on:** KLD-082 (number formats), KLD-092 (hyphenated stat labels), KLD-100 (choose view)
- **Touched paths:**
  - `klunki/lib/ui/games/quartett_card.dart` (`formatQuartettValue`)
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`
  - `packages/klunki_engine/lib/{quartett,quartett_decks}.dart` (`QuartettStat.grouped` removed),
    `packages/klunki_engine/test/compat_test.dart`
  - `klunki/test/ui/games/{quartett_media_test,quartett_trumpf_screen_test}.dart`
  - `klunki/test/screenshots/quartett_polish_shots_test.dart` (new)

## Goal
Large stat values read like numbers in the player's language ("15.400 kN", not "15400 kN"), and the Quartett
(Trumpf) table uses the space of a large phone and a tablet sensibly. Presentation only: no rules, deck data,
protocol or fingerprint change.

## What changed
1. **Thousands separators** (`formatQuartettValue`): every stat value except a year is grouped with
   `NumberFormat.decimalPattern(<app locale>)` (`intl`, already a dependency): de "15.400 kN", en/zh "15,400 kN",
   fr "15 400 kN" (narrow no-break space U+202F, bundled in Noto Sans Math), es groups from five digits on
   ("1640 kg", "15.400 kN": CLDR `minimumGroupingDigits` 2, which `intl` ignores, done by hand), ar and fa
   "15,400 kN" (Western digits, I18N-04). Decimals keep the stat's rules ("6,1 s", "12.500,5 km" in de).
   Before, only the `built` count was grouped (flag `QuartettStat.grouped`); the flag is gone, grouping is the
   default. The engine's `formatNumber` stays locale-neutral and ungrouped (CLI, debug text).
   Values from 1000 on per deck: cars PS, cm³, kg; trains kW, built; rockets thrust (kN), launch mass (t);
   planes km/h, range (km), built.
2. **Trumpf layout** (screenshots before/after at 390×844, 430×932, iPad mini 744×1133 and 1133×744):
   - Phone: "Vorige Runde" was alone on a second line under the two count chips. Now it sits on the line of
     "Deine Karte (Anna)" (table) or under "Weiter" (round result, shrinks instead of clipping in fr); the
     counts keep one line. Wide layouts keep it in the counts row.
   - Phone: the opponent's stack (a 120 px card back) was below the fold at 430×932. Now a small back with
     "Stapel von Ben / 16 Karten" beside it: card and stack fit a large phone without scrolling.
   - Tablet landscape: the round result spread both cards over the whole width (labels and values far apart).
     The result is now at most 760 px wide, centred, like the table; the table may be 760 instead of 640 px
     (a little larger card on an iPad).
   - Sets screen reviewed at the same sizes: no change needed (720 px max, 2 or 4 slots per row). Small
     leftover: "Anna:" and "noch kein Quartett" are not on one baseline.

## Acceptance criteria
- [x] Values from 1000 on are grouped per locale in every deck; decimals stay correct; years stay bare.
- [x] Unit tests per locale (de, en, es, fr, zh, ar, fa) incl. decimals; glyph coverage test still green.
- [x] Hyphenated labels (KLD-092) still fit (`kld092` screenshots).
- [x] Trumpf phone/tablet fixes with before/after screenshots; widget tests for the phone and landscape layouts.
- [x] Fingerprint unchanged (grouping is presentation; `compat_test.dart` goldens pass unchanged).

## Screenshots
`KLUNKI_SHOTS=<dir> flutter test test/screenshots/quartett_polish_shots_test.dart` (from `klunki/`):
`kld110-numbers-<deck>-<locale>-phone`, `kld110-trumpf-{table,result,round2}-<size>-<locale>`,
`kld110-sets-<size>-<locale>`; sizes `phone` 390×844, `phonel` 430×932, `ipad` 744×1133, `ipadland` 1133×744.

## Open (maintainer)
- Look at the screenshots; Spanish four-digit values stay ungrouped on purpose (CLDR/RAE).
- Pre-existing, not changed: in ar the unit stands left of the number in an RTL row ("kN 15,400"); the
  "Vorige Runde" dialog cards on a phone break long labels in three lines.

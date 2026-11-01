# KLD-092 — Quartett (Trumpf): "Runde" and "Stechen", hot-seat status, long stat labels

- **ID:** `KLD-092`
- **Title:** Round/tie-break wording instead of "Stich", hot-seat status line under a result, stat labels that never break mid-word
- **Status:** DONE
- **Depends on:** KLD-091 (next-picker cue, `GameShell.setStatusOverride`)
- **Touched paths:**
  - `klunki/lib/l10n/**` (texts of 8 existing keys in all 7 locales, soft hyphens in stat labels of de/en/fr/es, generated files)
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart` (hot-seat status override, doc comments)
  - `klunki/lib/ui/games/hyphenated_label.dart` (new), `klunki/lib/ui/games/quartett_card.dart`, `klunki/lib/ui/engine_l10n.dart` (`localizedStatLabelHyphenated`, `softHyphen`)
  - `klunki/lib/ui/shell/game_screen.dart` (doc comments only)
  - `klunki/assets/fonts/NotoSansSC/**` (subset for the new zh texts)
  - `packages/klunki_engine/lib/quartett.dart` (English result reason), `packages/klunki_engine/lib/debug/quartett_text.dart` (CLI narration), `packages/klunki_engine/test/quartett_test.dart`
  - `klunki/test/**` (Trumpf widget tests, live UI adapter, hyphenation test, label finders), `klunki/tool/browser_live/**`

## Why

The user's son pointed out that Quartett has no "Stich" (trick): one
comparison is a **Runde** (round), and a tie leads to a **Stechen**
(tie-break) where the next card decides. Two more things from the same
session: in hot-seat the status pill said "X ist am Zug" while the result
below it said "O wählt als Nächstes" (the pick is only applied on "Weiter"),
and "Höchstgeschwindigkeit" broke as "Höchstgesch / windigkeit" on the narrow
result cards at phone width.

## What changed

1. **Wording** (approved by the user). Internal identifiers (`trick*` keys,
   `trickWinner`, `tricks`, widget keys `qt-last-trick*`) are unchanged: no
   protocol or fingerprint change (compat goldens pass).

   | Key | de old → new | en new |
   |---|---|---|
   | `quartettTrumpfWinsTrick` | "O gewinnt den Stich" → "O gewinnt die Runde" | "O wins the round" |
   | `quartettTrumpfTie` (headline) | "Gleichstand – Karten in den Topf" → "Gleichstand – Stechen!" | "Tie – tie-break!" |
   | `quartettTrumpfPotAgain` (cue under it) | "Im Topf: 2 Karten – X wählt noch einmal" → "Karten in den Topf (jetzt 2), X wählt noch einmal" | "Cards go to the pot (now 2), X picks again" |
   | `quartettTrumpfLastTrick` | "Letzter Stich" → "Vorige Runde" (not "Letzte Runde" = the final round) | "Previous round" |
   | `quartettTrumpfTricksBehind` | "noch 2 Stiche / 1 Stich" → "noch 2 Runden / 1 Runde" | "2 more rounds / 1 more round" |
   | `quartettTrumpfHandoverReason` | "O hat den Stich gewonnen" → "O hat die Runde gewonnen" | "O won the round" |
   | `engineReasonQuartettTrickLimitEqual` | "Stichlimit erreicht, …" → "Rundenlimit erreicht, gleich viele Karten (a:b)" | "Round limit reached, equal stacks (a:b)" |
   | `engineReasonQuartettTrickLimitMoreCards` | "Stichlimit erreicht, …" → "Rundenlimit erreicht, mehr Karten (a:b)" | "Round limit reached, more cards (a:b)" |

   The tie now reads as two lines that say nothing twice: headline
   "Gleichstand – Stechen!", cue "Karten in den Topf (jetzt 2), X wählt noch
   einmal" (the pot count stays).
   Other locales, same split: fr "manche" / "départage" ("Manche
   précédente"), es "ronda" / "desempate" ("Ronda anterior"), zh "轮" /
   "加赛" ("上一轮", was "上一墩"), ar "الجولة" / "جولة فاصلة" ("الجولة
   السابقة", was "the last round"), fa "دور" / "دور تعیین‌کننده" ("دور
   قبلی"). Quartett (Sets) never said "Stich": unchanged.
   Engine: the English reason ("round limit reached …") and the CLI
   narration ("→ O wins the round", "tie, tie-break! Both cards go to the
   pot", "(round n)").
2. **Hot-seat status line.** While a previewed result is on screen (the pick
   is applied only on "Weiter"), the board sets the shell's status override
   (`GameShell.setStatusOverride`, KLD-091) to the cue's words: "O wählt als
   Nächstes" when the other player won, "X wählt noch einmal" after a win of
   the picker or a tie (with the player's name if set, "Anna (X) …"), in the
   next picker's colour, no badge. "Weiter" clears it and the live status
   ("O ist am Zug" / cover) takes over. A result of a move that is already
   applied keeps the live status (it agrees). Network unchanged.
3. **Stat labels never break mid-word.** Flutter cuts a word wider than its
   line anywhere and draws no hyphen at U+00AD. The card's stat label is now
   a `HyphenatedLabel`, which lays the label out itself, in this order:
   full size breaking only between words → full size also at the label's
   soft hyphens with a visible "-" → the same at 90 % and 80 % → at 80 % with
   more lines, shrinking further only for a piece that still does not fit.
   The soft hyphens live in the ARB (`­`, de: "Höchst·geschwindig·keit",
   "Anfahr·zug·kraft", "Start·schub", "Erfolgs·quote", "Reich·weite", …; a
   few long en/fr/es words too). `localizedStatLabel` strips them (history,
   reveal text, semantics, tests); `localizedStatLabelHyphenated` keeps them
   for the card. The semantics label is the plain text. CJK labels wrap as
   before (they may break between any characters).
   At 390 px the full card shows every label on one line; on the narrow
   result cards "Höchst- / geschwindigkeit" at 80 % (planes: "Höchst- /
   geschwindig- / keit"); every other label of every deck and locale fits
   at full size, at most wrapped at a space.

## Tests

- `quartett_trumpf_screen_test.dart`: new texts; win/loss/tie check the
  status line under the result ("X wählt noch einmal" / "O wählt als
  Nächstes", never "X ist am Zug"); tie checks "Gleichstand – Stechen!".
- `quartett_trumpf_network_test.dart`: new texts ("noch 2 Runden", "Vorige Runde").
- `hyphenated_label_test.dart` (new): the layout rules with the test font,
  and every stat label of every deck in all 7 locales with the real bundled
  fonts on a full card (366 px) and a narrow result card (179 px): every
  rendered line fits its box (so Flutter never cuts a word), the lines put
  back together give the plain label, at most 3 lines; semantics is plain.
- Live UI (`test/e2e/live_ui`): the adapter's `checkShown` now also checks
  the hot-seat status line under every result (cue words, no badge); the
  hot-seat games assert the check ran for every round.
- Browser (`tool/browser_live`): new texts; the status is the topmost
  matching node (it can read like the cue in hot-seat), the cue the one
  below "X wählt PS"; hot-seat reveals report a problem when the status does
  not read like the cue.
- Label finders in `quartett_decks_test`, `engine_l10n_test`,
  `quartett_media_test` accept the plain label as the semantics label (a
  label laid out over two lines).

## Screenshots

`KLUNKI_SHOTS=<dir> flutter test test/screenshots --plain-name kld092`:
`kld092-hotseat-result-status`, `kld092-hotseat-stechen`,
`kld092-vorige-runde-overlay`, `kld092-card-kmh-{cars,planes}`,
`kld092-reveal-kmh-{cars,planes}` (phone light).

## Results

- `flutter analyze`: no issues. `flutter test` (all of `klunki/`, incl. `translations_test.dart`, glyph coverage, compat): 694 passed, 97 skipped (screenshots etc.).
- `flutter test test/e2e/live_ui` (in the full run): hot-seat games check the status line under every round.
- `packages/klunki_engine`: `dart test` 355 passed (compat goldens unchanged).
- `flutter gen-l10n`; `python3 -I tool/update_web_fonts.py subset`: Noto Sans SC re-subset for 加赛/现有/轮 (619 code points).
- Browser (`tool/browser_live/run.sh --build --port 8813`, headless Firefox): PASS. Hot-seat 64 rounds, 25 covers, 0 problems (every result's status read like the cue, e.g. "O wählt noch einmal" after a Stechen); network 130 rounds, the status line followed a queued reveal 56 times, 0 problems. (A first run, before the status was limited to nodes above the reveal, also passed: 64 + 200 rounds.)

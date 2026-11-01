# KLD-091 — Quartett (Trumpf): say who picks next

- **ID:** `KLD-091`
- **Title:** Next-picker cue on every trick result, hot-seat cover only when the device changes hands (with the reason), network status line follows the trick on screen
- **Status:** DONE
- **Depends on:** KLD-089 (live UI turn check, its proposals 1 and 2), KLD-086 (network flow)
- **Touched paths:**
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`
  - `klunki/lib/ui/shell/game_screen.dart` (`GameShell.setStatusOverride`, `ShellStatus`, badge)
  - `klunki/lib/l10n/**` (6 new keys in all 7 locales, generated files)
  - `klunki/test/ui/games/quartett_trumpf_screen_test.dart`, `klunki/test/ui/games/quartett_trumpf_network_test.dart`
  - `klunki/test/e2e/live_ui/**` (driver hooks, Quartett adapter)
  - `klunki/test/screenshots/screenshots_test.dart` (`kld091` shots)
  - `klunki/tool/browser_live/quartett_trumpf.mjs`, `klunki/tool/browser_live/live.mjs`
  - `docs/tasks/KLD-029-quartett-reveal-handover.md` (closed), `docs/tasks/BOARD.md`

## Why

KLD-089 showed the turn order is right (the trick winner picks next, the same
player again after a tie), but the user found the flow confusing ("X wählt
Reichweite, O gewinnt Stich", "it feels like it skips players"). The screen
never said who picks next, and on a network device the status line already
showed the live state ("Du bist am Zug") while older queued tricks were still
being shown. Player names instead of X/O are a separate, later step.

## What changed

1. **Cue on every trick result** (`qt-next-picker`, hot-seat and network, also
   in "Letzter Stich"):
   - the other player won: "O gewinnt den Stich" / **"O wählt als Nächstes"**
   - the picker won: "X gewinnt den Stich" / **"X wählt noch einmal"**
   - tie: "Gleichstand – Karten in den Topf" / **"Im Topf: 2 Karten – X wählt
     noch einmal"** (the existing tie text, now always shown as the cue)
   - the button reads **"Weiter – O wählt"** (`qt-continue`).
   The picked line got its own key, `qt-reveal-picked`.
2. **Hot-seat cover.** Already only shown when the turn passes (the
   controller's rule, unchanged); it now says why: "Gib das Gerät an O
   weiter" + **"O hat den Stich gewonnen"** (`qt-handover-reason`, via the
   shell's `handoverDetail`). No cover when the same player picks again;
   **KLD-029** (a cover even then) is closed, its card explains why.
3. **Network status line.** While the reveal on screen has newer tricks
   queued behind it, the shell's status line follows the reveal:
   **"Anna (X) wählt als Nächstes"** (or **"Du wählst als Nächstes (O)"**)
   plus a badge **"noch 2 Stiche"** / "noch 1 Stich"
   (`shell-status-badge`). When the queue is empty it goes back to the live
   status. New shell API `GameShell.setStatusOverride(ShellStatus?)` (text,
   player for the pill colour and mood, optional badge); the board pushes it
   on every `setState`, so it changes in the same frame as the reveal.
   The badge is pinned to the pill's top end corner and takes no layout
   space: the first version put it next to the pill, where it wrapped onto
   its own line at phone width and pushed the reveal (and its "Weiter"
   button) down whenever a trick arrived. The browser run caught this as
   mis-taps (a tap aimed at "Weiter" landed beside it after the jump).
4. Unchanged: "Letzter Stich", the 5 s grace, `holdResult` (KLD-089).
   Hot-seat status line unchanged (the reveal there is a preview, the live
   status is already right).
5. The "Weiter – X wählt" button takes at most half the result row and
   wraps there; the longer fr/fa labels overflowed by 16–28 px at 390 px
   width (caught by `translations_test.dart`).

New ARB keys (de, en, es, fr, ar, fa, zh): `quartettTrumpfNextPicker`,
`quartettTrumpfPicksAgain`, `quartettTrumpfContinuePicker`,
`quartettTrumpfYouPickNext`, `quartettTrumpfTricksBehind` (plural),
`quartettTrumpfHandoverReason`. ar/fa checked in an RTL screenshot; the zh
glyphs were already in the font subset (`update_web_fonts.py subset`: no
change).

## Tests

- `quartett_trumpf_screen_test.dart`, group "who picks next (KLD-091)": win
  (cue, button, no cover), loss (cue, button, cover names O and the reason),
  tie (pot cue, no cover), and 40 tricks in a row: a cover exactly when the
  next picker differs, each naming the right player.
- `quartett_trumpf_network_test.dart`, group "status line follows the shown
  result (KLD-091)": the waiting device with two tricks queued shows "Anna (X)
  wählt als Nächstes" + "noch 2 Stiche", then "noch 1 Stich", then the live
  status without badge; a batch arrival shows "Du wählst als Nächstes (O)";
  the next picker's own reveal keeps the live status.
- Live UI (`test/e2e/live_ui`): the adapter now also checks, on every
  observation, the cue and "Weiter" text against the trick's next picker, and
  (new driver hook `checkShown`) the status line and badge against the number
  of tricks the device knows beyond the one shown; hot-seat: every cover
  names the winner of the last trick, and covers appear exactly at the moves
  where the picker changes (`checkCovers`). The slow-guest test asserts the
  queued-status check actually ran.
- Browser (`tool/browser_live`): the adapter reads "Weiter – X wählt", the
  cue, the cover reason and the badge; `live.mjs` reports a problem when the
  cue/button name the wrong player, a cover appears although the same player
  goes on (or is missing on a switch), or the status/badge do not match the
  "… hat gewählt" queue notice.

## Screenshots

`KLUNKI_SHOTS=<dir> flutter test test/screenshots --plain-name kld091`:
`kld091-hotseat-result-next`, `kld091-hotseat-tie`, `kld091-hotseat-cover`,
`kld091-network-badge` (phone light, plus `-ar` variants).

## Results

- `flutter analyze`: no issues. `flutter test` (all of `klunki/`): 651 passed, 88 skipped (screenshots etc.).
- `flutter test test/e2e/live_ui`: 11 passed (8 hot-seat games, 3 network games); the slow-guest game ran the queued-status check.
- Browser (`tool/browser_live/run.sh --port 8791`, headless Firefox): PASS. Hot-seat 200 tricks, 98 covers, 0 problems; network 196 tricks, the status line followed a queued reveal 140 times, 0 problems.

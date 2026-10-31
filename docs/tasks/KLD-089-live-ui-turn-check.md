# KLD-089 — Live UI tests: Quartett (Trumpf) turn order, played to the end

- **ID:** `KLD-089`
- **Title:** Quartett (Trumpf) "skips players"? Complete games through the real UI (widget tests and real browsers), turn-order check, fix for the final tricks hidden by the result dialog
- **Status:** DONE
- **Depends on:** KLD-086 (Trumpf network flow), KLD-057b (relay e2e tooling)
- **Touched paths:**
  - `packages/klunki_engine/test/quartett_trumpf_turns_test.dart` (new)
  - `klunki/test/e2e/live_ui/**` (new: driver, Quartett adapter, tests)
  - `klunki/test/ui/games/quartett_trumpf_network_test.dart` (regression tests)
  - `klunki/lib/ui/shell/game_screen.dart` (`GameShell.holdResult`)
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart` (holds the result)
  - `klunki/tool/browser_live/**` (new: Firefox/BiDi driver, adapter, `run.sh`, README)

## Report

The user played Quartett (Trumpf) in the PWA: "it does not change players
every time … 'X wählt Reichweite, O gewinnt Stich' … sometimes it changes
players correctly but in between I have the feeling it skips some."

Rule: the trick winner picks next; after a tie the same player picks again.
So the same player picking several times in a row is correct.

## What was tested

1. **Engine** (`quartett_trumpf_turns_test.dart`): 300 complete games per deck
   (all four), random and "strongest stat" picks; after every trick the
   picker is the previous winner (same player after a tie), the history names
   the picker, a replay of the log gives the same pickers and result.
2. **Widget level, like a user** (`klunki/test/e2e/live_ui/`): a generic
   driver plays complete games by taps; a per-game adapter reads the screen
   and maps a move to taps. After every pump each device is observed and
   every trick result that appears on its *uncovered* screen is logged once.
   - Hot-seat: real `QuartettTrumpfScreen` via the registry; stat → "Weiter"
     → handover cover. Checks: the table shows the player-to-move's top card
     with "Deine Karte (X)", the cover names the player to move, each device
     log equals the engine history.
   - Network: host and guest `NetworkGameSession`s side by side, real
     `NetworkTransport`s over 127.0.0.1 through the seeded Wi-Fi latency
     proxy, random device order, dawdling (tricks queue up behind a grace),
     the fake clock jumping 1–6 s (graces run out), "Letzter Stich" peeks.
     Checks: both devices showed every trick once, in engine order (picker,
     stat, winner, both cards); the host applied exactly the tapped picks by
     the tapping player; the table card and status name the right players.
   - Default (CI): every deck in hot-seat (2 seeds), 3 network games;
     `KLUNKI_LIVE_UI_FULL=1`: 24 hot-seat + 10 network games (~7 min).
3. **Real browser** (`klunki/tool/browser_live/`): headless Firefox over
   WebDriver BiDi (already used by `pwa_relay_e2e.mjs`; nothing installed),
   semantics tree on, taps as pointer events. Hot-seat in one browser,
   network host + guest by room code through `klunki relay`; every trick
   each browser shows is logged (`tricks.log`), same checks.

## Result

**The turn order is correct.** In every engine, widget and browser game the
picker was always the previous trick's winner (or the same player after a
tie), every hot-seat cover named the right player, the table always showed
the right player's card, and the host never applied a pick from the wrong
player. Mid-game, no trick was ever skipped, duplicated or reordered, even
with up to 10 tricks queued behind a grace period.

**One real bug, at the end of a network game:** the result dialog came up
the moment the last trick was played. On the device that was still working
through queued tricks (the waiting player), the remaining tricks, including
the final one, then only played out *under* the modal dialog: dimmed,
covered, no "Weiter". The winner of the final trick also had its own last
reveal covered at once. So the last tricks of a game were effectively never
shown. (Found by the browser run: the guest's screenshot showed trick 197
with "X hat gewählt: Hubraum" queued behind the "Ada (X) gewinnt!" dialog.)

Root cause: the shell (`GameScreen`) showed the result dialog on the first
frame after `game.isOver`, regardless of what the board still had to show.
Fix: `GameShell.holdResult(bool)`; the Quartett board holds the result on a
network device while the game is over and a reveal is on screen or tricks
are queued. The dialog follows when the last reveal is left ("Weiter", or
the waiting player's grace runs out). Hot-seat is unchanged (the final
trick is previewed before it is submitted). Regression tests: the "game end
(KLD-089)" group in `quartett_trumpf_network_test.dart` (3 of them fail
without the fix) and the live network tests (which only count tricks seen
on an uncovered screen).

## Why it can *feel* skipped (no change made, proposals)

1. **Winner streaks without a cue.** Hot-seat: when the picker wins, no
   cover appears and the next card of the same player shows at once; five
   or ten picks in a row by X are normal. The reveal says "X gewinnt den
   Stich", but nothing says "X wählt noch einmal" (only ties have "… wählt
   noch einmal"). Proposal: a line under the headline, "X wählt als
   Nächstes" / "X wählt noch einmal", and on the "Weiter" button "Weiter –
   X wählt" (also KLD-029: a handover cover even when the same player goes
   on, so the opponent who watched the reveal hands back deliberately).
2. **Status line ahead of the reveal (network).** While a waiting device
   still shows older queued tricks, the status line already shows the live
   state. Logged example (guest, two tricks behind):
   `guest O sees #41 X thrustKn → X wins … [status: "Du bist am Zug (O)", 2 newer trick(s) already played]`
   The screen says X won while the status says it is O's turn; tapping
   "Weiter" quickly makes the queued tricks flash by. Proposal: while a
   queued reveal is shown, the status line follows the reveal ("Stich 41 –
   X wählt als Nächstes") or a small badge "noch 2 Stiche" next to "Weiter".
3. **The reveal disappears on its own** for the waiting player after 5 s;
   if several tricks were picked meanwhile they come one after another,
   5 s each. The "X hat gewählt: …" notice helps but is easy to overlook.

## Trick log excerpt (browser, network, after the fix)

```
 337.3 host X    sees  #196 O Gewicht → O wins (X:A4 O:C1)   [Warte auf Bea (O)…, Weiter in 5 s]
 337.3 guest O   sees  #196 O Gewicht → O wins (X:A4 O:C1)   [Du bist am Zug (O)]
 337.6 guest O   taps Hubraum on B3
 337.9 guest O   sees  #197 O Hubraum → O wins (X:C2 O:B3)   [Du bist am Zug (O)]
 338.2 guest O   taps Gewicht on A1
 338.5 host X    sees  #197 O Hubraum → O wins (X:C2 O:B3)   [Du bist am Zug (X), Weiter in 5 s, queued: O hat gewählt: Gewicht]
 338.5 guest O   sees  #198 O Gewicht → X wins (X:C3 O:A1)   [Warte auf Ada (X)…, Weiter in 5 s]
 339.1 host X    sees  #198 O Gewicht → X wins (X:C3 O:A1)   [Du bist am Zug (X)]
 339.3 host X    taps Leistung on H1
 339.6 host X    sees  #199 X Leistung → O wins (X:H1 O:G3)   [Weiter in 5 s]
 339.7 guest O   sees  #199 X Leistung → O wins (X:H1 O:G3)
```

## How to run

```sh
cd packages/klunki_engine && dart test test/quartett_trumpf_turns_test.dart
cd klunki && flutter test test/e2e/live_ui                       # KLUNKI_LIVE_UI_VERBOSE=1 for logs
cd klunki && flutter test test/ui/games/quartett_trumpf_network_test.dart
klunki/tool/browser_live/run.sh --build                          # real Firefox, see its README
```

## Follow-up

KLD-090: adapters for the other games (Connect Four, Mühle, Quartett Sets,
Schiffe, GoStrategy) on the same driver, hot-seat and network, widget and
browser.

# KLD-086 — Quartett (Trumpf): local "Weiter", grace countdown, "Letzter Stich"

- **ID:** `KLD-086`
- **Title:** Quartett (Trumpf) over the network: "Weiter" never blocks the other device; grace countdown for the waiting player; "Letzter Stich" overlay
- **Status:** DONE
- **Depends on:** KLD-024 (Trumpf screen), KLD-064 (secrecy), KLD-069 (decks)
- **Touched paths:**
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`
  - `klunki/lib/l10n/**` (4 keys in the `quartettTrumpf*` block: `HintWaiting`, `LastTrick`, `GraceSeconds`, `QueuedPick`), `klunki/assets/fonts/NotoSansSC/**`
  - `klunki/test/ui/games/quartett_trumpf_network_test.dart` (new)

## Problem (before)

After a trick both players had to press "Weiter" before play went on.
"Weiter" was never a network message, but on the **network host** the
screen previewed the host's own pick on a replayed engine copy (as in
hot-seat) and submitted it only on "Weiter". So the guest saw nothing until
the host had looked at the result and tapped. The guest's picks went out at
once (no preview on a redacted view), but every incoming trick replaced the
reveal on screen at once, so a trick could jump away unseen.

## Behaviour (now)

- **Hot-seat** is unchanged: tap a stat → preview → one tap on "Weiter"
  submits → handover cover if the turn passed. No grace, no countdown.
- **Network** (one local player, host or guest):
  - A pick is submitted on the tap; the host applies it at once. Every
    accepted pick (own or the opponent's) is revealed from its event.
  - "Weiter" is local only: no message, the game never waits for it.
  - **Next picker** (winner, or the same player after a tie): the reveal
    stays until "Weiter", then the new top card.
  - **Waiting player**: the reveal stays at least `quartettRevealGrace`
    (5 s) with a countdown ring + "Weiter in N s"; "Weiter" skips it.
    A trick the opponent picks meanwhile is announced ("X hat gewählt: PS")
    and queued; it is shown when the countdown ends or on a tap, with its own
    countdown. Several queued tricks are shown in order. After the grace with
    nothing new: the own new top card plus the hint "X wählt …".
- **"Letzter Stich"** (chip next to the stack counts, every mode, both
  players, disabled before the first trick): a dialog with the last trick the
  player has seen — summary, stat with both values, both cards, stack sizes
  right after it (and the pot). Closes on tap outside, close button, Back.
  Purely local: while open, nothing new is revealed and a countdown pauses;
  tricks arriving meanwhile are queued and shown after closing. The board
  keeps `quartettTrickHistoryLength` (= 1) tricks; a longer list would allow
  a history view later.

Quartett Sets and the other games do not share this code path and are
unchanged.

## Definition of done
`flutter analyze` and `flutter test` (in `klunki/`) are green; BOARD.md row.

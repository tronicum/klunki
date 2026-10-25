# KLD-024 — Quartett Trumpf screen

- **ID:** `KLD-024`
- **Title:** Auto-Quartett (Supertrumpf) screen: top card with stats, tap a stat, trick reveal, pot, handover
- **Milestone:** P2
- **Status:** DONE
- **Depends on:** KLD-021 (shell)
- **Touched paths:**
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`
  - `klunki/lib/ui/games/quartett_card.dart` (new, shared with KLD-025)
  - `klunki/test/ui/games/quartett_trumpf_screen_test.dart`
  - `docs/tasks/KLD-024-quartett-trumpf-screen.md`

## Goal
Replace the placeholder with a real Auto-Quartett board that is playable in
hot-seat without ever showing the opponent's card except in the trick reveal
both players watch.

## Design
- **Table:** the active player's top card face-up (stat rows tappable, keys
  `qt-stat-<id>`), the opponent's stack face-down with a count, chips with both
  stack sizes and the pot (only if > 0). Hint: "Wähle eine Eigenschaft deiner Karte".
- **Reveal (`qt-reveal`):** tapping a stat does *not* submit yet. The trick is
  computed on a replayed copy of the engine (`replay(config, moves)` +
  `applyMove(pick)`), so the reveal is exactly what the engine will do. Both
  cards side by side (picker left), the chosen stat highlighted green / red /
  grey, text "X gewinnt den Stich" / "Gleichstand – Karten in den Topf".
- **"Weiter" (`qt-continue`)** submits the pick. If the turn passed, the
  controller sets `needsHandover` and the shell's `HandoverCover` hides the
  board. Submitting first and revealing afterwards would not work: the cover
  appears right after the move is accepted and would hide the reveal.
- Moves that arrive from somewhere else (later: network) are revealed from
  their event payload; "Weiter" then only closes the reveal.
- Undo or restart while a reveal is open closes it.
- History: `describeMove` → "wählt Leistung" (no card names, no player; the shell prefixes "X: ").
- Stat taps are disabled when `!controller.canAct`.
- The temporary `Key('legal-move-0')` alias was removed in the integration commit; the
  shell tests now drive games through the controller.

## `quartett_card.dart` API (for KLD-025)
- `QuartettCard({required Card card, onStatTap, enabled = true, statKeyPrefix, highlightStat, outcome, dense = false})`
- `QuartettCard.back({count, label, dense = false})`: face-down
- `QuartettOutcome { win, lose, tie }`, `quartettOutcomeColor(o)`
- `quartettSetColor(set)`, `quartettSetName(set)`, `formatQuartettValue(stat, value)`

## Acceptance criteria
- [x] Top card stats shown (label, value + unit, higher/lower-wins arrow)
- [x] Picking a stat shows the reveal with the engine's winner; it stays until "Weiter"
- [x] Tie path (seed found via the engine) → pot chip, same player again
- [x] Handover cover after the turn passes; next cards stay hidden
- [x] Opponent card not shown before picking
- [x] Full game by repeated picks ends in the result dialog
- [x] No overflow at phone width (360 px)
- [x] `flutter analyze` clean

## Open point (resolved in the integration commit: the test now uses `quartett-sets`)
`test/ui/shell/game_screen_test.dart` → "history falls back to the move map"
uses `quartett-trumpf` because that placeholder had no `describeMove`. That is
no longer true now that this card is done, and the test is outside this card's
paths. Fix: point the test at a game whose screen still has no `describeMove`
(currently `muehle` or `quartett-sets`, with
`find.textContaining('X: {')`), or remove it.

# KLD-029 — Quartett: handover after the trick reveal even when the same player continues

- **ID:** `KLD-029`
- **Title:** In hot-seat Quartett Trumpf, cover the screen after every trick reveal, not only when the turn passes
- **Milestone:** P2 polish (backlog)
- **Status:** TODO
- **Depends on:** KLD-024 (Quartett Trumpf screen) merged
- **Touched paths:**
  - `klunki/lib/game/game_controller.dart` (handover rule)
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart` (only if the reveal → cover sequencing needs it)
  - `klunki/test/game/**`, `klunki/test/ui/games/quartett_trumpf*`
  - `docs/tasks/KLD-029-quartett-reveal-handover.md`

## Goal
In Trumpf both top cards are revealed after a pick, and both players look at the screen. Today
(`GameController._onAccepted`) a handover is only requested when `game.currentPlayer != m.player`. When the picker wins the
trick (or ties), they continue, no cover appears, and the opponent — who is still looking — sees the picker's next top card.
After this card, every Trumpf trick ends with: reveal → "Weiter" → `HandoverCover` for the player on turn, so the next top card is
only shown after the right person confirmed "Ich bin X – weiter".

## Repo context
- `klunki/lib/game/game_controller.dart`: `_onAccepted` sets `_needsHandover` when `_sharedDeviceSecrets && !game.isOver && game.currentPlayer != m.player`;
  `_sharedDeviceSecrets` = `spec.hiddenInformation && transport.localPlayers.length > 1` (hot-seat only; network games never cover).
- `klunki/lib/ui/shell/handover_cover.dart` shows "Gib das Gerät an <mark> weiter" for `game.currentPlayer`.
- Read KLD-024's screen first: how the reveal is shown and when it calls `acknowledgeHandover`.
- Quartett Sets: a hit lets the asker continue, but nothing secret is revealed to the opponent (only the moved card, which both learn
  anyway), so keep the current rule for Sets. Schiffe: unchanged.

## Acceptance criteria
- [ ] For `quartett-trumpf` in hot-seat, every accepted pick sets `needsHandover` (also when the same player continues). Cover text
      names the player on turn. Other games unchanged.
- [ ] The reveal stays readable before the cover (the screen shows the reveal, then the cover after "Weiter", as in KLD-024).
- [ ] Controller unit test: Trumpf pick won by the picker → `needsHandover == true`; Sets hit → `false`; network-style transport
      (`localPlayers.length == 1`) → `false`.
- [ ] Widget test: a trick won by X → reveal → "Weiter" → cover "Gib das Gerät an X weiter" → no top card visible until acknowledged.
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Constraints
- Keep the rule in one place (the controller), keyed off the game id or a small per-spec flag; no engine changes.

## Definition of done
Green analyze + tests; card status DONE; BOARD row ✅.

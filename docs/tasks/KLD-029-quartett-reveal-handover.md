# KLD-029 — Quartett: handover after the trick reveal even when the same player continues

- **ID:** `KLD-029`
- **Title:** In hot-seat Quartett Trumpf, cover the screen after every trick reveal, not only when the turn passes
- **Milestone:** P2 polish (backlog)
- **Status:** CLOSED (won't do; decided the opposite in KLD-091)
- **Depends on:** KLD-024 (Quartett Trumpf screen) merged
- **Touched paths:**
  - `klunki/lib/game/game_controller.dart` (handover rule)
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart` (only if the reveal → cover sequencing needs it)
  - `klunki/test/game/**`, `klunki/test/ui/games/quartett_trumpf*`
  - `docs/tasks/KLD-029-quartett-reveal-handover.md`

## Decision (2026-10-31, KLD-091)

Closed without building it. KLD-091 decides the opposite: **no cover when the
same player picks again** (the picker won the trick, or a tie). Why:

- In hot-seat both players watch the reveal anyway; the next card that shows
  after "Weiter" is the picker's own, and the picker is the one holding the
  device. An extra "Gib das Gerät an X weiter" / "Ich bin X – weiter" when
  nothing has to be passed felt like a turn change that did not happen; the
  user's report (KLD-089: "it feels like it skips players") came from exactly
  this kind of mismatch between what the screen says and who acts.
- Instead every trick result now says who picks next ("X wählt noch einmal",
  "O wählt als Nächstes", "Weiter – X wählt"), and the cover only appears
  when the device really changes hands, naming the player and why
  ("Gib das Gerät an O weiter" / "O hat den Stich gewonnen").
- The secrecy concern below (the opponent glimpses the picker's next top
  card) is accepted for now: it is the opponent's own choice to keep looking
  after "Weiter – X wählt". If it turns out to matter, a short "X wählt …"
  privacy pause can be a new card; it should not reuse the handover cover.

The original plan follows for reference.

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

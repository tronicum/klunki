# KLD-071: Shell guards: leave confirmation, no undo in hidden games, start cover, tap guard

- **ID:** `KLD-071`
- **Title:** Shell guards: leave confirmation, no undo in hidden games, start cover, tap guard
- **Priority:** high
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-065 merged (same file)
- **Touched paths:** `klunki/lib/ui/shell/{game_screen,handover_cover}.dart`, `klunki/lib/game/game_controller.dart`, `klunki/lib/ui/pairing/network_game_session.dart`, `klunki/lib/l10n/**`, tests

## Goal
Closes UX-REVIEW 2.5, 3.1, 3.2 and 3.3 (REVIEW U1): one back gesture must not end a running game (over the network, for both players), and hot-seat secrets must not leak.

## Acceptance criteria
- [ ] A `PopScope` asks for confirmation while a game runs ("Spiel verlassen? Das Spiel endet für beide." over the network).
- [ ] There is no undo in hidden-information hot-seat games (`spec.hiddenInformation`).
- [ ] A cover appears before the first move of a hidden-information hot-seat game.
- [ ] The handover button ignores taps for about 600 ms after the cover appears.
- [ ] Widget tests cover all four. The strings are in all 7 ARBs, and the zh subset is regenerated.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.

# KLD-067: Whose turn it is, through colour

- **ID:** `KLD-067`
- **Title:** Make the turn state obvious through colour, not only the name
- **Priority:** medium
- **Status:** DONE
- **Depends on:** KLD-062 (palette, player tokens), KLD-056 (player labels)
- **Touched paths:**
  - `klunki/lib/ui/shell/game_screen.dart` (status pill, turn edge, hot-seat legend, `PlayerToken`)
  - `klunki/lib/ui/pairing/network_game_session.dart` (connection bar)
  - `klunki/lib/ui/game_visuals.dart` (`playerColor`), `klunki/lib/app/theme.dart` (`secondPlayer`, `inkOn`, `contrastRatio`)
  - `klunki/lib/l10n/*.arb` (2 keys after `pairingStatus`)
  - tests: `test/ui/shell/turn_colour_test.dart` (new), `test/app/theme_test.dart`, `test/screenshots/screenshots_test.dart`,
    `test/ui/pairing/{pairing_flow,relay,web_join_screen}_test.dart`, `test/ui/pairing/pairing_test_utils.dart`

## Goal
User feedback after playing iOS vs browser over the relay: "add a color to whose turn it is, not only the player's
name". Especially over the network it must be obvious at a glance whether it is **my turn** or I am **waiting**.

## What was done

### Player colours
- `playerColor(palette, gameId, player)` in `game_visuals.dart` is the single source: the piece colour where the game
  has one (`GameVisuals.token`: 4 Gewinnt red/yellow, Mühle light/dark stone), otherwise the game accent for X and
  the new `KlunkiPalette.secondPlayer` for O (slate `#4A5560` light, `#B4C0CC` dark).
- **Hook for new games (GoStrategy):** set `token:` in the game's `gameVisuals` entry (e.g. black/white stones); pill,
  edge, legend, tokens and the network bar follow automatically.
- `PlayerToken` now uses `playerColor` (O in X/O games is a slate disc instead of a card-coloured one), mark text in
  `inkOn(fill)`.
- `inkOn(color)` (theme.dart) picks black or white, whichever contrasts more: ≥ 4.58:1 for any colour.

### Shell (hot-seat and network)
- **Status pill** (`shell-turn`) by `TurnMood`:
  - `active` (hot-seat, or "Du bist am Zug" on a network device): filled with the player's colour, bold text in
    `inkOn`, soft glow; edge in the colour where it has 3:1 to the page, else the theme outline.
  - `waiting` (network, other device to move): card-coloured with a 10 % tint, 2 px outline in the opponent's colour
    (faded), an hourglass (`shell-waiting`), muted text.
  - `won` / `draw`: trophy + winner token / handshake, as before.
- **Turn edge** (`shell-turn-edge`): a 6 px band under the app bar in the colour of the player to move (35 % while
  waiting, winner's colour at the end, none for a draw); colours that would vanish on the page (light stone on paper,
  dark stone on the dark table) fall back to the theme outline. It sits outside the handover cover (the turn is no
  secret).
- **Network pulse + haptic:** when the turn comes back to this device, the pill scales 1 → 1.07 → 1 once (500 ms) and
  `HapticFeedback.lightImpact()` fires (built in, no package). Nothing on the first frame.
- **Hot-seat legend** (`shell-players`): both players at the end of the status row, token + name (token only when
  unnamed); the one to move at full opacity with an underline in its colour, the other at 60 %. Decorative
  (`ExcludeSemantics`), the status line says it already.
- Colour changes animate (250–300 ms); with reduced motion (`MediaQuery.disableAnimations`) there is no transition
  and no pulse (the haptic tap stays, it is not motion).
- Colour is never the only signal: status text and the token with its mark stay; the status line is still a
  `liveRegion`, so screen readers announce turn changes.

### Connection bar
- Instead of the one sentence: `[X token] Du (Anna) · [O token] Gegner: Ben` (`net-you-token`, `net-you`,
  `net-peer-token`, `net-peer`). Screen readers still get the full "Du (Anna, X) · Gegner: Ben (O)" as the
  semantics label of `net-status` (tests find it with `netStatus(...)` in `pairing_test_utils.dart`).

### Strings (all 7 ARB files, one block right after `pairingStatus`)
`netBarYou` ("Du ({name})"), `netBarOpponent` ("Gegner: {peer}"). en by hand; fr/es/zh/ar/fa machine translations
(files flagged `@@x-review`). The zh texts reuse characters of `pairingStatus`, so no font subset rebuild.

## Verification
- `flutter analyze`: no issues. `flutter test`: 474 passed, 38 skipped (screenshot captures).
- `test/ui/shell/turn_colour_test.dart`: colour per player (pill, edge, text ink), hot-seat legend, fallback colours,
  network "my turn" vs "waiting", pulse + haptic on the turn coming back, reduced motion, live region.
- `test/app/theme_test.dart`: per preset and brightness, every game's two player colours differ and carry their
  pill text at ≥ 4.5:1; `secondPlayer` ≥ 3:1 on the card; `inkOn` ≥ 4.5:1 over a colour sweep.
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots` now also renders a loopback network game from
  both sides (`network-myturn-*`, `network-waiting-*`).

## Follow-ups
- Mühle side panels still use the theme primary for the active border; could use `playerColor`.
- The connection bar could mark whose turn it is as well (needs the controller, not just the transport).

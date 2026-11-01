# KLD-106: no X / O marks in the UI

- **ID:** `KLD-106`
- **Title:** Remove the remaining X / O marks from the app: names in sentences, "1" / "2" or the game piece on tokens
- **Milestone:** M3 (polish)
- **Status:** DONE
- **Depends on:** KLD-103 (player names, "Spieler 1 / 2"), KLD-067 (tokens, connection bar)
- **Touched paths:**
  - `klunki/lib/l10n/app_*.arb` (+ generated `app_localizations*.dart`)
  - `klunki/lib/ui/shell/player_labels.dart`, `klunki/lib/ui/shell/game_screen.dart`
  - `klunki/lib/ui/game_visuals.dart`
  - `klunki/lib/ui/pairing/network_game_session.dart`
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`, `quartett_card.dart`, `gostrategy/gostrategy_board.dart`
  - tests (`test/ui/**`, `test/e2e/live_ui/**`, `test/screenshots/screenshots_test.dart`, `integration_test/network_test.dart`)

## Goal

Players are "Spieler 1 / Spieler 2" with names (KLD-103). The last X / O marks go (maintainer decision):
sentences name the players, tokens show the player number or the game's own piece.

## What changed

| Where | Before | After |
|---|---|---|
| Network status, own turn | "Du bist am Zug (X)" | "Du bist am Zug" |
| Network status, other turn / hot-seat | (already) "Warte auf Ben…" / "Anna ist am Zug" | unchanged |
| Connection bar (visible) | token + "Du (Anna)" · token + "Gegner: Ben" | token + "Du: Anna" · token + "Gegner: Ben" |
| Connection bar (screen reader) | "Du (Anna, X) · Gegner: Ben (O)" | "Du: Anna · Gegner: Ben" |
| GoStrategy panel | "Deine Armee (Anna)" | "Deine Armee" |
| Quartett (Trumpf) network, queued rounds | "Du wählst als Nächstes (O)" | "Du wählst als Nächstes" |
| Same name for both players | "Anna (X)" / "Anna (O)" | "Anna (1)" / "Anna (2)", also in the players legend |
| Token (legend, turn pill, name fields, result, bar, score bars) | disc with "X" / "O" | see below |
| Quartett (Trumpf) opponent card back | "O" | "2" (the owner's number) |

Card counts in Quartett were already name-based ("Anna: 16 Karten", KLD-103).

### Token per game

| Game | Token | Why |
|---|---|---|
| 4 Gewinnt | the board's disc, red (1) / yellow with the embossed inner ring (2), no letter | it is a game piece; the ring tells them apart without colour (UX-REVIEW 2.10) |
| Mühle | the board's stone, light (1) / dark (2), no letter | game piece; light vs dark is a lightness difference, not hue |
| Schach | the side's king (unchanged) | game piece |
| Quartett (Trumpf, Sets), Schiffe, GoStrategy, Wortgewandt | disc in the player colour with "1" / "2" | no piece of the player's own; the number matches "Spieler 1 / 2" and makes the disc readable without colour |

GoStrategy's pieces are square tiles with ranks; the round "1" / "2" token stays distinct from them.

### Same-name label: "Anna (1)"

"Anna (1)" / "Anna (2)" rather than "Spieler 1" / "Spieler 2": the players typed the names, so they stay;
the number is the one from the "Wer spielt?" fields ("Spieler 1 / 2") and on the token; and it is the same
`playerLabel` pattern as chess ("Anna (Weiß)"), so no new string. In games with pieces (4 Gewinnt, Mühle)
the token has no number, so the players legend also shows "Anna (1)" / "Anna (2)" when the names are equal.

## Kept on purpose

- Internal X / O: `PlayerLabels.markOf` / `playerMark` for widget keys (`shell-player-X`, `hot-seat-name-X`,
  …), the `HotSeatNames` prefs keys (`hotSeatNameX` / `hotSeatNameO`), engine/CLI/debug output and logs.
- `klunki_net` still falls back to "X" / "O" for a player who sent an empty name (`playerNameOr`, the guest's
  host-name fallback). The app always sends a name (the typed one or the default), so the fallback does not
  show in practice; changing it would change what a host sends, so it is out of scope (presentation only).
- No protocol, rules or fingerprint change.

## Acceptance criteria

- [x] No user-visible "(X)" / "(O)" / "X:" / "O:" in ARB values (7 locales; ar without gendered verbs for `{player}`).
- [x] Tokens: "1" / "2" or the game piece, distinguishable without colour.
- [x] Tests updated (widget, network, live-UI adapters, screenshots); new token test in `turn_colour_test.dart`.
- [x] Screenshots (group `kld106`, plus the existing per-game and `kld103` shots).
- [x] `dart test` (engine, net), `flutter analyze`, `flutter test -j 2` green.

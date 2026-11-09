# KLD-122: "Zug bestätigen" (confirm a move before it counts)

- **ID:** `KLD-122`
- **Title:** "Zug bestätigen": a chosen chess move waits for "✓ Ziehen", "✗ Anders ziehen" chooses again
- **Milestone:** M4 (UX polish)
- **Status:** DONE
- **Depends on:** KLD-059 (chess board), KLD-103 ("Wer spielt?"), KLD-117 ("Zug zurücknehmen")
- **Touched paths:**
  - `klunki/lib/profile/confirm_move_settings.dart` (new), `klunki/lib/ui/shell/confirm_move.dart` (new)
  - `klunki/lib/ui/games/chess/chess_board.dart`, `klunki/lib/ui/shell/game_screen.dart`,
    `klunki/lib/ui/player_name_dialog.dart`, `klunki/lib/ui/pairing/{pairing_screen,relay_host_screen}.dart`
  - `klunki/lib/l10n/app_*.arb` (+ generated)
  - `klunki/test/ui/games/chess_confirm_move_test.dart` (new), `klunki/test/ui/games/chess_network_test.dart`,
    `klunki/test/e2e/live_ui/chess_{adapter,live_test}.dart`, `klunki/test/screenshots/confirm_move_shots_test.dart` (new)

## Goal

The maintainer (2026-11-08): a chess move counts the instant a piece is dropped or tapped; over the network a
misplaced piece cannot be taken back. A per-player setting **"Zug bestätigen"**: the chosen move is only shown
(piece on its target, old square still marked) with **"✓ Ziehen"** and **"✗ Anders ziehen"** under the board; only
"Ziehen" sends it. A UI preference: no engine change, no rules version bump, no protocol change, no touch-move
rule.

## Design as built

- **Setting** (`ConfirmMoveSettings`, `shared_preferences`, keys `confirmMoveNetwork`, `confirmMoveHotSeatA/B`):
  - network games: this device's choice, **default on**; switch "Zug bestätigen" on "Raum starten" (LAN and
    relay host screens, under the colour choice, for games in `confirmMoveGames`) and a toggle in the game's
    app bar (`shell-confirm-move`, ✓ circle filled = on, a snack bar says "Zug bestätigen ist an/aus.");
    a joining device uses the toggle in the game.
  - hot-seat: per seat, **default on** (since 2026-11-09, the maintainer: a slip of the finger is caught before
    the other player sees it; before that it was off because "Zug zurücknehmen" exists); one switch under each name in
    "Wer spielt?" (`hot-seat-confirm-X/O`) and in the in-game "Spielernamen" dialog, so Anna can have it on and
    Ben off. Only a player's explicit choice is stored.
  - One setting for every game that offers it (not per game). `ConfirmMoveScope` (an `InheritedNotifier`)
    can put other settings below it (tests: one per simulated device); without one the app's instance is used.
- **Board** (chess): with the setting on for the mover (`confirmMoveFor`), tap, drag and promotion (piece
  picked first) keep the move as pending: the board shows `controller.previewCopy()` with the move applied
  (piece on its target with the selection ring, a faint copy on the square it left, a captured piece small and
  faint in the corner of its square, check shown if the move gives check); the hint line says "Passt der Zug?
  Tippe auf „Ziehen“ oder „Anders ziehen“."; `ConfirmMoveBar` sits above the move list. The board takes no other
  move meanwhile. "Ziehen" submits (back to pending if it was not delivered); "Anders ziehen" restores (named
  "Zurück" until 2026-11-09; renamed so it no longer sounds like the undo button "Zug zurücknehmen"; en "Other
  move", fr "Autre coup", es "Otra jugada", ar "حركة أخرى", fa "حرکت دیگر", zh 重选 unchanged). A draw offer,
  resign, undo, restart or reconnect (any change of the log or transport) drops the pending move.
- **Reuse**: another board joins by keeping its move pending the same way, showing `ConfirmMoveBar` and being
  listed in `confirmMoveGames` (then "Wer spielt?", "Raum starten" and the app bar show the setting).

## Acceptance criteria

- [x] Hot-seat: per-player choice in "Wer spielt?" (default on since 2026-11-09, was off), Anna on / Ben off
      played through the UI; the choice changes in "Spielernamen"; saved and restored (`chess_confirm_move_test.dart`).
- [x] Network: on by default per device; the guest's unconfirmed move does not reach the host, "Anders ziehen"
      restores the board, drag and tap, the host turns it on in the game (`chess_network_test.dart`); every
      network move in the existing tests and in the live-UI games goes through "Ziehen", some after "Anders ziehen".
- [x] Promotion: the piece first, then the pending queen/knight on the board, "Anders ziehen" keeps the pawn.
- [x] Draw offer, resign and undo drop the pending move.
- [x] 7 locales; no new Chinese characters (all already in `app_zh.arb`).
- [x] Screenshots (`--plain-name kld122`): pending move de light/dark and ar, "Wer spielt?", "Raum starten",
      network device with the toggle.

## Open

- Other games (Mühle, 4 Gewinnt, Wortgewandt) are not wired yet.
- Hot-seat has no app-bar toggle; the switches sit in "Spielernamen" (people icon), which does not say so.

# KLD-117: Take back a move next to the board

- **ID:** `KLD-117`
- **Title:** Take back a move next to the board ("Zug zurück" in the game area)
- **Milestone:** M4 (UX polish)
- **Status:** DONE
- **Depends on:** KLD-059 (chess controls), KLD-094 (Wortgewandt control row), KLD-065 (resign)
- **Touched paths:**
  - `klunki/lib/ui/shell/game_screen.dart`, `klunki/lib/ui/shell/handover_cover.dart`
  - `klunki/lib/ui/games/chess_screen.dart`, `klunki/lib/ui/games/chess/chess_board.dart`
  - `klunki/lib/ui/games/wordtiles_screen.dart`, `klunki/lib/ui/games/wordtiles/wordtiles_board.dart`
  - `klunki/lib/l10n/app_*.arb` (+ generated)
  - `klunki/test/ui/shell/undo_move_button_test.dart`, `klunki/test/screenshots/undo_shots_test.dart`, tests using `shell-undo`

## Goal

The maintainer found the "take back move" arrow odd in the app bar, next to the whole-game controls (new game,
resign, history). It moves into the game area, the same for every game: a labelled button **"Zug zurück"**
(↶ + text) next to the board, hot-seat only as before.

## Acceptance criteria

- [x] One widget, `UndoMoveButton` (`game_screen.dart`): `TextButton.icon` with `Icons.undo` (mirrored in RTL
      through `matchTextDirection`) and the label `shellTakeBack` (new ARB key, 7 locales; `shellUndo` stays as
      its tooltip). Key `shell-undo` on the button. Shown only for `HotSeatTransport`; disabled while
      `!controller.canUndo`. Same semantics as before (`controller.undo`: the last accepted move, in
      Wortgewandt the last played turn).
- [x] Placement: chess in the control row under the board next to ⇅ and the turn toggle; Wortgewandt right
      under its control row (↓ / shuffle / zoom / Tauschen / Passen / Legen is full on a phone, one row on
      every width since step 8b), at the end of the "Bänkchen" line; on a small phone (bench button in the
      score row) on a line of its own, which costs the board about 32 px there in hot-seat only (open for
      maintainer feedback); every other game (4 Gewinnt, Mühle, Quartett Trumpf/Sets, Schiffe,
      GoStrategy) in a small row under the board that the shell provides (`shell-actions`, end-aligned).
      A board that shows the button itself says so with `GameScreen(boardPlacesUndo: true)`.
- [x] App bar keeps: names (hot-seat), new game, resign, history.
- [x] Handover cover: the board's button sits inside the covered area (offstage, not hit-testable). Before,
      the app-bar arrow worked while the cover was up, so the player who just moved could take the move back
      before passing the device; to keep that, the cover shows the same button under "Ich bin … – weiter".
      Undo from the cover shows nothing secret: the controller covers the board again for the player whose
      turn it is after the take-back.
- [x] `UndoMoveButton(visualDensity: …)`: the word game passes the bench line's density so that line keeps
      its height.
- [x] Chess control row fits narrow boards: the buttons shrink to fit (FittedBox), the check badge takes
      what is left.
- [x] Tests: per game that the button is in the game area and not in the app bar, disabled/enabled, takes
      back; cover behaviour for the hidden-information games; RTL; network games show no button (existing
      chess / Wortgewandt / pairing tests). Live-UI tests pass.
- [x] Screenshots: `KLUNKI_SHOTS=/tmp/kld117 flutter test test/screenshots --plain-name kld117`
      (chess de/ar, 4 Gewinnt de/ar + start, Wortgewandt de on 390×844 and 375×667, Schiffe de + cover, phone 390×844).

## Constraints

- No rules or protocol change (UI only): no rules version, fingerprint or `protocolVersion` bump.
- No font subset change: the zh label (悔棋) uses glyphs that were already in the subset.

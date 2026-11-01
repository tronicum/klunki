# KLD-099 — Confirm resign and leave ("Wirklich aufgeben?" / "Spiel verlassen?")

- **ID:** `KLD-099`
- **Title:** Resigning or leaving a running game asks first; the dialog closes itself when the game ends underneath it
- **Status:** DONE
- **Depends on:** KLD-065 (resign in the shell)
- **Touched paths:**
  - `klunki/lib/ui/shell/game_screen.dart` (`PopScope`, `_confirm`, `_closeConfirm`, `_leave`, `_underway`)
  - `klunki/lib/l10n/**` (`shellResignBody` reworded; new `shellLeaveTitle`, `shellLeaveBody`, `shellLeave`)
  - `klunki/test/ui/shell/confirm_quit_test.dart` (new), `klunki/test/ui/shell/resign_test.dart`,
    `klunki/test/ui/games/gostrategy_network_test.dart`, `klunki/test/ui/pairing/{pairing_flow,web_join_screen}_test.dart`,
    `klunki/test/screenshots/screenshots_test.dart` (`kld099` shots, `_themed(webFonts:)`)
  - `docs/tasks/BOARD.md`

## Report

User feedback: in a device-vs-device game a mis-tap or a back swipe ends the
game for both players. Quitting should ask first.

## What it does

All in the shared shell (`GameScreen`), so every game gets it: 4 Gewinnt,
Mühle, Quartett (Trumpf/Sets), Schiffe, GoStrategy, Schach.
`network_game_session.dart` is unchanged: the shell's `PopScope` registers on
the session's route.

| | Network | Hot-seat |
|---|---|---|
| "Aufgeben" (flag) | "Wirklich aufgeben?" / "Das Spiel endet für beide – {Gegner} gewinnt." / "Abbrechen" · **"Aufgeben"** (error colour) | unchanged (KLD-065): the dialog asks who gives up, which already is the confirmation |
| Back button, Android back, predictive back | "Spiel verlassen?" / "Die Verbindung wird getrennt, das Spiel endet für beide." / "Abbrechen" · "Verlassen" — always while the game runs, also before the first move | same title and buttons, body "Das laufende Spiel wird abgebrochen." (the restart dialog's text), only once the game is **under way**: each side has moved, or 4 moves (resigns not counted) |
| iOS back swipe | held back while the dialog would be needed (`PopScope(canPop: false)` disables the Cupertino gesture); the back button shows the dialog | same rule |
| Game over | no dialog: back and "Menü" leave directly | same |

- A confirm dialog is opened through `_confirm`, which remembers its route. When
  the game ends while it is open (opponent resigns, last move arrives), the
  shell closes it (`_closeConfirm`, answer null = cancel) before the result
  dialog comes up. A leave dialog closed this way keeps the player in the game
  with the result in front.
- A resign confirmed in a dialog that raced with the end of the game is not
  sent (`controller.game.isOver` checked after the dialog).
- A second system back while the leave dialog is open closes the dialog, not
  the game.

## Locales

All 7 ARB locales. ar/fa keep the opponent's label (bidi-isolated name plus
mark) at the end of the clause, before the full stop, without a dash next to
the placeholder; checked in the screenshots (`kld099-*-ar/fa-*`). No new
Chinese characters (the font subset is unchanged).

## Tests

- `confirm_quit_test.dart`: network resign → cancel (game continues, opponent
  and own moves go through) / confirm (resign sent, result); destructive
  button colour; back button → leave dialog, cancel stays, confirm leaves;
  before the first move; system back (twice: second closes the dialog); iOS
  `popGestureEnabled` false mid-game, true after; opponent resigns while the
  resign dialog / leave dialog is open; hot-seat untouched board and one move
  (no dialog), each side moved (dialog, cancel, system back, confirm), after
  the game (no dialog), and every app game: untouched leaves, after 4 moves asks.
- Updated: the new resign wording in `resign_test.dart` and
  `gostrategy_network_test.dart`; `pairing_flow_test.dart` and
  `web_join_screen_test.dart` confirm the leave dialog when leaving mid-game.
- Live UI harness (`test/e2e/live_ui/`, `tool/browser_live/`) never resigns
  or leaves mid-game: unchanged.

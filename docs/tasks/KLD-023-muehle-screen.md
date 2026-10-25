# KLD-023 — Mühle screen

- **ID:** `KLD-023`
- **Title:** Mühle screen: board painter, tap to place/move/remove, mill highlight, phase hints
- **Milestone:** P2 — Hot-seat on one device
- **Status:** IN_PROGRESS (an agent is working on it, 2026-10-25)
- **Depends on:** KLD-021 (shell + placeholder `MuehleScreen`), which builds on KLD-020 (`GameController`)
- **Touched paths:**
  - `klunki/lib/ui/games/muehle_screen.dart`
  - `klunki/test/ui/games/muehle*`
  - `docs/tasks/KLD-023-muehle-screen.md` (status only)

## Goal
Two people on one device can play Mühle to the end. The screen supports placing, moving, flying and the
removal step after a mill. Mills and selectable points are highlighted, and a hint line explains what to do next.

## Repo context
- Flutter app `klunki/`; engine `package:klunki_engine/klunki_engine.dart` (pure Dart; add `hide Card` if you import the whole library,
  since the engine's Quartett `Card` clashes with Material's). UI strings in German.
- **Read first:** `klunki/lib/ui/shell/**` (KLD-021) and `klunki/lib/game/**` + `klunki/lib/transport/**` (KLD-020).
  Expected contract, which may differ slightly (adapt): `GameController` (ChangeNotifier) with `game`, `spec`, `canAct`,
  `Future<GameEvent?> submit(Map move)` (null = rejected), `lastEvent`, `moves`, `newGame()`.
  `GameScreen(controller:, board:)` provides the status line, result dialog, history and new game. Keep
  `const MuehleScreen({super.key, required this.controller})`.
- Engine API (`packages/klunki_engine/lib/muehle.dart`), with `final g = controller.game as MuehleGame`:
  - `g.board`: `List<Player?>` of 24 points; `MuehleGame.adjacency[p]` (neighbors); `MuehleGame.mills` (16 triples)
  - `g.phaseOf(player)`: `MuehlePhase.placing | moving | flying` (**per player**)
  - `g.pendingRemoval`: true after a new mill. The **same** player must now remove an opponent piece
  - `g.legalMoves`: `List<Map>` for the current player: `{'action':'place','to':p}`,
    `{'action':'move','from':a,'to':b}`, or only `{'action':'remove','at':p}` while `pendingRemoval`
  - `g.piecesInHand(p)`, `g.piecesOnBoard(p)`, `g.movesSinceRemoval`, `MuehleGame.drawMoveLimit` (50)
  - event payloads: `{'mill': true}` (mill formed, removal pending), `{'removed': at}`
  - `g.result.reason`: `'opponent has fewer than 3 pieces'`, `'opponent has no legal move'`, or a draw
- Point layout (index → grid x,y on a 7×7 lattice):
  ```
  0(0,0)  1(3,0)  2(6,0)   3(1,1)  4(3,1)  5(5,1)   6(2,2)  7(3,2)  8(4,2)
  9(0,3) 10(1,3) 11(2,3)  12(4,3) 13(5,3) 14(6,3)
  15(2,4) 16(3,4) 17(4,4)  18(1,5) 19(3,5) 20(5,5)  21(0,6) 22(3,6) 23(6,6)
  ```
  Lines: draw the three squares plus the four midpoint connectors (1-4-7, 9-10-11, 12-13-14, 16-19-22), or derive them from `adjacency`.

## Actual API after KLD-020/021 (verified against main @ `c10573c`; overrides the expected contract above)
- `GameScreen(controller:, boardBuilder: (context, controller) => …, describeMove:, title:)`; there is no `board:` parameter.
  Set the hint line with `GameScreen.of(context).setHint('…')` (safe from `build`; `null` hides it).
- `controller.submit(move)` returns `Future<SubmitResult>` (`isAccepted`, `event`, `reason`), not `GameEvent?`.
  `controller.moves` is `List<AcceptedMove>` (`index`, `player`, `move`, `event`). Restart is `controller.restart(seed:)`; there is no `newGame()`.
  Also: `canAct`, `canUndo`, `undo()`, `needsHandover`, `acknowledgeHandover()`, `config`, `transport`.
- Status line text is "X ist am Zug"; result dialog buttons are "Nochmal" / "Menü"; handover button is "Ich bin O – weiter".
  `HandoverCover` keeps the board mounted but `Offstage` (use `skipOffstage: false` only if you need to find offstage widgets).
- Routing: `klunki/lib/ui/shell/screen_registry.dart` (`gameScreens`, `buildGameScreen(controller)`, `openGame(context, id, seed:)`); there is no `screenFor`.
- Stable keys: `shell-status`, `shell-hint`, `shell-undo`, `shell-restart`, `shell-history`, `history-sheet`, `result-dialog`,
  `handover-cover`, `handover-continue`, `menu-<gameId>`. Full list: `docs/tasks/KLD-021-ui-shell.md`.
- Transport interface (`klunki/lib/transport/game_transport.dart`): `config`, `Set<Player> localPlayers`, `game`, `moves`,
  `Stream<AcceptedMove> accepted`, `Future<SubmitResult> submit(move)`, `dispose()`; `RejectReason {notYourTurn, illegal, gameOver, disconnected}`.

## Acceptance criteria
- [ ] A `CustomPainter` draws the board (3 squares + connectors) and the pieces for X (`Player.a`) and O (`Player.b`). It scales to the available square.
- [ ] Tap handling (all moves go through `controller.submit`; ignore taps when `!canAct` or the game is over):
  - **placing:** tap an empty point → `place`;
  - **moving/flying:** tap your own piece to select it (highlighted). The legal targets from `legalMoves` are marked;
    tap a target → `move`; tap another own piece to switch selection; tap elsewhere to clear it;
  - **pendingRemoval:** the removable opponent pieces (from `legalMoves`) are marked; tap one → `remove`.
- [ ] Mill highlight: every mill currently fully owned by one player is drawn emphasized. The mill just formed is extra visible until the removal.
- [ ] Hint line above or below the board, e.g. "X: Stein setzen (noch 7)", "X: Stein ziehen", "X: Springen erlaubt",
      "Mühle! X entfernt einen Stein von O". It also shows pieces in hand and on board for both players.
- [ ] Widget test `klunki/test/ui/games/muehle_screen_test.dart`: taps through a scripted game to the end. Use the
      console's demo script as a source: `packages/klunki_engine/lib/debug/muehle_text.dart` `demoScript`, 33 moves,
      O wins. Map `"4"` → tap point 4, `"4-7"` → tap 4 then 7, `"x13"` → tap 13. Assert the result dialog "O gewinnt".
      Plus a focused test: after a mill the hint mentions "Mühle", and a tap on a protected piece does nothing.
- [ ] Give each point a hit target `Key('muehle-point-$i')` (e.g. an invisible `Positioned` button) so tests can tap points reliably.
- [ ] `flutter analyze` and `flutter test` are green.

## Constraints
- Board rules: engine stays pure Dart and unchanged. Never install toolchains, download SDK components, accept
  licenses, sign up for accounts or publish anything without the user's OK. No new pub.dev dependencies.
- Only touch the paths above; report shell/controller gaps instead of editing them. No handover (no hidden information).
- Don't commit unless asked.

## Hints / context
- Text reference: `cd packages/klunki_engine && dart run bin/klunki.dart demo muehle`, and interactive
  `dart run bin/klunki.dart muehle` with `moves` to list the legal moves.
- Hit-testing: a point is "tapped" if the tap is within ~0.4 lattice cells of its position.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test test/ui/games/
flutter test
```
All green; manual game to the end on Chrome or the simulator; card status set to DONE.

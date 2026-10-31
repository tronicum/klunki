# KLD-065: "Aufgeben" (resign) in every game

- **ID:** `KLD-065`
- **Title:** Resign in every game (engine, network, CLI, app)
- **Status:** ✅ done
- **Depends on:** KLD-056 (player names), KLD-062 (theme)
- **Touched paths:**
  - `packages/klunki_engine/lib/game.dart` (the resign itself), one rename per game in
    `connect4.dart`, `muehle.dart`, `quartett.dart`, `schiffe.dart`, `gostrategy.dart`
  - `packages/klunki_engine/lib/debug/{text_game,debug_console}.dart`
  - `packages/klunki_net/lib/src/{host,guest}.dart`, `packages/klunki_net/lib/src/cli/cli.dart`, `PROTOCOL.md`
  - `klunki/lib/game/game_controller.dart`, `klunki/lib/transport/*.dart`, `klunki/lib/ui/shell/game_screen.dart`,
    `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/ui/games/connect4/connect4_board.dart`, `klunki/lib/l10n/**`,
    `klunki/assets/fonts/NotoSansSC/**`

## Decisions

**Once in the engine base.** `Game` (in `game.dart`) is now a template: games implement `applyPlayMove` and
`playResult`; `Game.applyMove`, `Game.result` and `Game.isOver` add the resignation on top. New games (chess,
…) get resign for free and cannot forget it (the abstract members force the split). The per-game diff is a
rename (`applyMove` → `applyPlayMove`, `result` → `playResult`), `implements Game` → `extends Game`, and the
dropped `isOver` overrides.

**A normal move in the log.** `{'action': 'resign', 'player': 'a' | 'b'}` (`Game.resignMove(p)`). It goes through
the same move log as everything else, so it replicates over the network, rebuilds on reconnect (`welcome`
snapshot), replays (`replay(config, moves)`) and hot-seat undo takes it back (replay minus one). It is not in
`Game.history` (the game's own play log); `Game.resignedBy` says who resigned. The transport / session move list is
the full history.

**Any time, either player.** A resign is accepted whenever the game is running: on turn, off turn, during setup
phases (Schiffe placement, GoStrategy setup), during a Mühle pending removal. That is why the move names its
player: `Game.playerOf(move)` is the resigner for a resign, otherwise `currentPlayer`. Every place that used to
attribute a move to `currentPlayer` uses `playerOf` now (host validation, host/guest replay, guest `accepted`
check, both app transports, CLI, debug console). A finished game rejects everything, a second resign too.

**Result.** Winner = the other player, `GameEndReason.commonResigned` (code `common.resigned`, params
`{'player': 0 | 1}` = `Player.index` of the resigner), English reason `X resigned` / `O resigned`. The event
payload is `{'resigned': Player}`.

**Hot-seat: ask who resigns.** Both players sit at one device and either may give up at any moment, so the
dialog asks: "Wirklich aufgeben?" / "Wer gibt auf? …" with one button per player ("Anna (X) gibt auf",
"O gibt auf") plus "Abbrechen". Guessing "the player to move" would be wrong half the time (the loser often
resigns right after the opponent's strong move, i.e. off turn) and is undefined in setup phases. The flag sits in
the app bar, outside the handover cover, so it works while the cover is up; a resign drops the cover.

**Network: the local player.** One local player per device: "Wirklich aufgeben?" / "Die Partie endet sofort,
Ada (X) gewinnt." with "Aufgeben" / "Abbrechen". The opponent's result dialog says "Du gewinnst!" with
"Bea (O) hat aufgegeben"; the resigner's says "Ada (X) gewinnt!" with "Du hast aufgegeben".

**UI place.** A flag icon (`Icons.flag_outlined`, key `shell-resign`, tooltip "Aufgeben") in the shared
`GameScreen` app bar, shown only while the game runs and the device has a local player. It lives in the shell,
so every game screen, including the coming GoStrategy screen (KLD-058b), gets it. The dialog uses the game's
accent colour for the flag icon (KLD-062). The history sheet shows a resign as "X: Aufgeben" (the board
describers only know their own moves).

## Protocol impact

None on the wire: no new message type, version stays 1. The host's turn check now uses `Game.playerOf(move)`, so
a guest may send its own resign off turn; a resign naming the other player is `"not your turn"`. An older client
(before KLD-065) would reject a resign as an illegal move (and a guest would see a divergence); both sides must
run this version. See `packages/klunki_net/PROTOCOL.md`, "Resign (KLD-065)".

## CLI

`klunki host|join`: type `resign` any time (also on the opponent's turn); both terminals print the result
("O resigns. You win!" / "You resign. X wins.", then "X wins (O resigned)"). Debug console: `resign` (player to
move) or `resign x` / `resign o`; `history` lists it as `resign X`, `undo` takes it back.

## l10n

Keys (one block at the end of each ARB): `shellResign`, `shellResignTitle`, `shellResignBody`, `shellResignWho`,
`shellResignPlayer`, `engineReasonCommonResigned`, `engineReasonCommonYouResigned`. de is the template; en, fr,
es, zh-Hans, ar, fa are machine translations (files marked `@@x-review`). The Noto Sans SC subset was rebuilt
(`python3 -I tool/update_web_fonts.py subset`) for the new Chinese characters.

## Tests

- engine `test/resign_test.dart`: every game, A and B at the start (on/off turn), later off turn, malformed
  resigns, replay, setup phases (Schiffe, GoStrategy), Mühle pending removal, finished game, debug console.
- net `test/resign_test.dart`: guest resigns off turn and host resigns during the Schiffe setup, each over TCP,
  WebSocket and the relay; no resigning for the other player; a resumed log with an off-turn resign. CLI:
  `test/cli_test.dart` (guest resigns in the Schiffe setup, host resigns in 4 Gewinnt).
- app `test/ui/shell/resign_test.dart`: the hot-seat dialog in every app game, cancel, names, the handover cover,
  undo of a resign, and a network game (two real `NetworkTransport`s) where the opponent sees "Bea (O) hat
  aufgegeben"; `test/l10n/engine_l10n_test.dart` for the reason text.

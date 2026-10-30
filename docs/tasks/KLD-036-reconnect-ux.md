# KLD-036 — Disconnect / reconnect UX

- **ID:** `KLD-036`
- **Title:** "Gegner hat das Spiel verlassen" / "Verbindung verloren – verbinde neu…", resume from snapshot
- **Milestone:** P3/P4 — network play
- **Status:** TODO
- **Depends on:** KLD-034 (pairing screen; and via it 030, 032, 033)
- **Touched paths:**
  - `klunki/lib/ui/pairing/reconnect*`
  - `klunki/lib/transport/network_transport.dart`
  - `klunki/test/ui/pairing/reconnect*` (tests)
  - `docs/tasks/KLD-036-reconnect-ux.md` (status only)

## Goal
When the Wi-Fi drops or one device locks or backgrounds the app mid-game, the game doesn't die. Both sides see what's
happening, the guest reconnects automatically to the same host, and the game resumes exactly where it was (replay
from seed + accepted moves). If the opponent leaves on purpose (`bye`), both sides get a clear end state.

## Repo context — read first
- `packages/klunki_net/lib/**` (KLD-030): `snapshot {moves}` message, rejoin handling on the host, `ping`, `bye`, the
  replay idea (`replay(config, moves)` in `package:klunki_engine/klunki_engine.dart`: rebuild a game from `GameConfig` + move list, `null` if the logs disagree).
- `klunki/lib/transport/network_transport.dart` (KLD-032): connection state (`connected`/`disconnected`/`closed`), host/guest wrappers.
- `klunki/lib/ui/pairing/**` (KLD-034): how sessions are created (host address/port is known there).
- `klunki/lib/game/**` (KLD-020) `GameController`: how it holds `game` and whether it can be re-seeded from a replayed game or move list.
- Names may differ: adapt, and report gaps in files you don't own.

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
- [ ] Heartbeat: if no message or `ping` arrives within ~6 s (tune it, document it), the state becomes `disconnected` (reuse 030's ping if it has one).
- [ ] **Guest** on `disconnected`: retries connecting to the last host `IP:port` with backoff (1, 2, 4, … s, max ~60 s total), sends its rejoin/hello,
      receives `snapshot`, rebuilds its game via `replay(config, moves)`, and continues. If the replay returns `null` → error state "Spielstand
      passt nicht zusammen" with "Zum Menü".
- [ ] **Host** on guest loss: keeps the authoritative game and the listening socket open, and accepts the same guest again (030's rejoin rule), sending the snapshot.
- [ ] `lib/ui/pairing/reconnect_overlay.dart` (name starting with `reconnect`): a modal overlay over the game screen showing
      "Verbindung verloren – verbinde neu… (n)" with "Abbrechen" (→ menu, sends `bye` if possible). It blocks input while shown.
      On `bye` from the opponent: a dialog "Gegner hat das Spiel verlassen" → "Zum Menü".
- [ ] Moves submitted while disconnected aren't lost silently: reject them with a visible message, or queue exactly one until resume.
      Document which.
- [ ] App lifecycle: on `AppLifecycleState.resumed`, the guest checks the socket and reconnects if needed. On `paused` nothing is torn down actively
      (iOS will kill the socket anyway; KLD-040 tests that on devices).
- [ ] Tests in `klunki/test/ui/pairing/reconnect_test.dart`. The board lists no test path for this card. This file mirrors the
      `reconnect*` pattern and doesn't collide with anything running in parallel (KLD-034 is done by then). Mention it in your report.
      Cover:
      loopback host + guest, play 3 Four in a Row moves, kill the guest socket, the guest reconnects and continues to a win, both sides agree;
      `bye` shows the dialog; a replay mismatch shows the error.
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Constraints
- Board rules: never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the user's OK.
  No new packages (`connectivity_plus` etc. need the user's OK first; not needed for this).
- Only touch the paths above. If `klunki_net` lacks a rejoin path, report it as a blocker with the exact message flow you need. Don't fake it in the app.
- Don't commit unless asked.

## Hints / context
- PoC limitation (accepted in the roadmap): the guest gets seed + moves, so Quartett hands are recomputable. The UI must still never show them.
- Host IP can change after a Wi-Fi drop (DHCP). Retrying the old IP is enough for the PoC. Optionally fall back to re-browsing mDNS by service name.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test
```
Green; 🧑 manual check on two devices: toggle Wi-Fi off/on on the guest mid-game, and the game resumes. Card status set to DONE.

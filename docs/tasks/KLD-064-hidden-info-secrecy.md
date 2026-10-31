# KLD-064: Real secrecy for hidden-information games over the network

- **ID:** `KLD-064`
- **Title:** The guest never holds the host's secrets (Schiffe fleet, GoStrategy setup, Quartett deal); the
  host's honesty is checked at the end
- **Milestone:** network
- **Status:** DONE
- **Depends on:** KLD-030 (klunki_net), KLD-057 (relay), KLD-058a (GoStrategy engine)
- **Touched paths:**
  - `packages/klunki_engine/lib/secrecy.dart` (new: `Redaction`, `jsonSafe`, `canonicalJson`, event/result JSON)
  - `packages/klunki_engine/lib/{schiffe,quartett,gostrategy}_view.dart` (new `part` files: `SchiffeView`,
    `QuartettView`, `GoStrategyView`, the three `Redaction`s), `schiffe.dart`, `quartett.dart`, `gostrategy.dart`
    (`viewJson`), `registry.dart` (`GameSpec.redaction`), `klunki_engine.dart`
  - `packages/klunki_net/lib/src/secrecy/` (new: `sha256.dart`, `secrecy.dart` = commitments, view hashes,
    `verifyRedactedGame`), `host.dart`, `guest.dart`, `events.dart` (v2, `MoveAccepted.event`, `GameVerified`,
    `VerificationFailed`, `Verification`), `cli/cli.dart`, `PROTOCOL.md`
  - `klunki/lib/transport/{game_transport,hot_seat_transport,network_transport}.dart`,
    `klunki/lib/game/game_controller.dart` (`previewCopy`), `klunki/lib/net/join_payload.dart` (v2)
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`, `quartett_sets_screen.dart`,
    `schiffe/schiffe_board.dart` (mechanical: no local preview on a redacted guest; render the local player)
  - `klunki/lib/ui/pairing/network_game_session.dart` (banner), `klunki/lib/l10n/*.arb` (+ generated)
  - tests: `packages/klunki_engine/test/secrecy_test.dart`, `packages/klunki_net/test/secrecy_test.dart` (new),
    net/ws/names/cli tests (v2), `klunki/test/ui/pairing/pairing_flow_test.dart`, join payload tests

## Problem
Up to protocol 1 every move, including the setups, and the seed of the deal were replicated to both devices,
and both ran the full engine. The UI rendered only `viewFor(me)`, but the device held the opponent's Schiffe
fleet, GoStrategy setup and the Quartett deal; a modified client could read them. (Two screens even showed
them: the network Schiffe board and the Trumpf table rendered the *player to move*, i.e. the opponent while
waiting.)

## Design

**Host-authoritative redaction.** The host runs the full engine and is the referee. Each hidden-information
game has a `Redaction` (engine, pure Dart) that says what a player may know:
- `view(game, viewer)`: everything the viewer may know, as JSON (`SchiffeGame.viewJson`, …);
- `fromView(json)`: a read-only game object for that view, a subclass of the engine class
  (`SchiffeView extends SchiffeGame`, …), so `controller.game as SchiffeGame`, the text adapters and the
  CLI keep working unchanged. Views fill the inherited private state with only the viewer's data (the
  opponent's unknown cards/pieces become placeholders that every public getter hides) and refuse
  `applyMove`;
- `redactMove` / `redactPayload`: a move and its event as the viewer may see them.

**Guest state.** For every accepted move the guest receives the redacted move, the redacted event and its new
view. It runs no engine; `KlunkiGuest.game` is the latest view object, `KlunkiGuest.entries` the redacted log
with events. The app's `NetworkTransport` takes the events from the net layer (the shadow replay engine is
gone), so the screens see the same `AcceptedMove`s as before, just redacted for the opponent's secrets.
Why views instead of a guest-side engine fed with redacted events: the opponent's moves depend on hidden
state (where a shot lands, which card is drawn, whether a player is blocked), so a partial engine would have
to re-implement every rule with unknowns; a view per move is simple, generic and exactly as small as what
the player may know.

**Own secrets.** The guest's setup goes to the host only. The host's acknowledgement echoes the guest's own
move (the guest checks it is unchanged) and carries nothing of the host's data; the host's later setup is
redacted. The guest's own view contains its own fleet/hand, which is not a leak.

**Commitments.** Every secret of the host gets a salted SHA-256 commitment, sent before it matters: the
Quartett seed in `welcome` (`seedCommit`, the config then has no seed), each secret host move (Schiffe
placement, GoStrategy setup) with its `accepted` (`commit`). At game end the host sends `reveal` (seed + salt,
each committed move + salt). The guest checks the commitments, replays the full game from the revealed seed
and moves, and compares every step (player, redacted move, redacted event, view hash) with what it was told.
Mismatch → `VerificationFailed`, banner "Spielverlauf konnte nicht bestätigt werden".

**State checks.** There was no state-hash check before; the closest was the log-prefix check on reconnect.
For redacted games it compares the redacted steps (incl. commitments), and the snapshot carries one hash of
the guest's *view* per step (`viewHash`) instead of whole views, so a reconnect stays small and the end check
still covers every position the guest was shown.

**Protocol.** Version bumped to 2 (`v` and `protocol` in `hello`); a v1 peer gets the existing clear
`error "unsupported protocol version 1 (expected 2)"`. The app's join payload/mDNS `v` is 2, so old hosts
show as incompatible. Connect4 and Mühle keep the plain messages. Details: `PROTOCOL.md`, "Hidden information".

**Hashing.** `package:crypto` is only a transitive dev dependency (via `test`), not a dependency of
`klunki_net`, so a small pure-Dart SHA-256 (`lib/src/secrecy/sha256.dart`, FIPS vectors in the tests,
checked identical on the VM and compiled to JavaScript) is used instead of adding one.

**App glue (minimal, no visual redesign).**
- `GameTransport.fullInformation`, `GameController.previewCopy()`: the Quartett screens previewed a pick/ask
  by replaying the log locally, which needs the deal. On a redacted guest they submit directly and show the
  outcome from the accepted event (same reveal/feedback widgets).
- The Trumpf table and the Schiffe board render the local player on a network device (the player to move in
  hot-seat), instead of the player to move — before, the opponent's card/fleet was shown while waiting.
- `NetworkTransport.verification` / `verificationFailed`; the connection bar shows the banner.

## Threat model (short)
- The host is trusted for secrecy: as referee it sees the guest's setup and hand.
- The guest is protected against outcome manipulation: changed setups, another deal, misreported shots,
  fights or tricks are detected at the end (not during the game). No reveal (host quits) = unverified.
- The host picks the Quartett seed alone (it can choose a deal, not change it). The relay and the `ws://`
  link see the guest's own moves in clear text.

## Tests
- Engine (`secrecy_test.dart`): views round-trip and agree with the engine for the viewer in full random games
  of all four games; redaction tables; the opponent's placements/setup/hand are absent from the view JSON.
- Net (`secrecy_test.dart`): every message the host sends is tapped; Schiffe (no unhit host square, no `dir`),
  GoStrategy (no rank of an unrevealed host piece, no `pieces`), Quartett both modes (no seed, every card id
  in a message is the guest's own top/hand, a trick card, the asked card or its own draw); guest as X: its setup
  acks carry nothing of the host, the reveal holds only the host's move; cheating hosts are caught (fleet
  swapped mid-game via `debugReplaceMove`, misreported hit via `debugRewriteOutgoing`, other Quartett seed in
  the reveal); verified after a reconnect; SHA-256 vectors.
- `net_test.dart` full random games: all games complete; hidden ones end `Verification.verified`.
- CLI: a full Quartett game between two terminals ends with "Verified: …".
- App: `pairing_flow_test.dart` Schiffe over loopback — the guest's board renders from its `SchiffeView`
  (own fleet, nothing of the host's, miss/hit from the events); the Quartett handover test adapted.

## Open
- Fair Quartett shuffle (mix in guest entropy before the deal).
- Verification only at the end; a host that leaves early is never checked.
- KLD-058b: the GoStrategy screen should use `viewFor(local player)` like the Schiffe board now does.

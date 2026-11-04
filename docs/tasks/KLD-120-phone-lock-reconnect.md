# KLD-120: A locked phone keeps the network game

- **ID:** `KLD-120`
- **Title:** Locking the phone during a device-to-device game no longer drops it for good
- **Milestone:** M3 (network play)
- **Status:** DONE (device test by the maintainer open)
- **Depends on:** KLD-057 (relay), KLD-071 (rejoin token), KLD-109 (awake clock), KLD-114 (Worker relay)
- **Touched paths:**
  - `packages/klunki_net/lib/src/{host,events}.dart`, `lib/src/relay/{relay_server,relay_client,relay_protocol}.dart`,
    `lib/src/channel/{channel,io_websocket_channel,browser_websocket_channel,platform_io}.dart`, `lib/src/cli/cli.dart`
  - `packages/klunki_net/PROTOCOL.md`, `test/{suspend_test,suspend_peer,relay_resume_test}.dart`, `test/relay_vectors*`
  - `deploy/cloudflare/{src,test}/**`, `deploy/cloudflare/README.md`
  - `klunki/lib/transport/network_transport.dart`, `klunki/lib/ui/pairing/{network_game_session,relay_errors}.dart`,
    `klunki/lib/app/screen_awake.dart`, `klunki/lib/l10n/**`
  - `klunki/ios/Runner/AppDelegate.swift`, `klunki/android/app/src/main/kotlin/de/klunki/klunki/MainActivity.kt`
  - `klunki/test/transport/network_resume_test.dart`, `klunki/test/ui/pairing/network_resume_test.dart`, `klunki/test/e2e/e2e_support.dart`

## Goal

Maintainer report: "if the phone locks the connection is dropped instantly, can we hold it longer?" Locking the
phone for a while (up to a few minutes) and unlocking it continues the game without anyone tapping anything, on
both sides, whether the host or the guest locked, over the LAN and through the relay.

## Findings: what happened before (reproduced)

Reproduced with one side in its own process frozen by SIGSTOP (like a suspended app: it reads nothing, answers no
ping, its timers stand still), keepalive 100 ms / timeout 800 ms, relay ping 1 s, locked 5 s. The harness is now a
test: `packages/klunki_net/test/suspend_test.dart` (+ `suspend_peer.dart`).

| who locks | how | what happened |
|---|---|---|
| guest | LAN | The host noticed after its timeout (10 s in the app; `PeerDisconnected`, timed out) and kept the seat (token). Host banner: "Verbindung zu Ben unterbrochen. Warte, bis er wieder beitritt…". On unlock the guest read the host's close at once ("Broken pipe" / connection closed): banner "Verbindung … unterbrochen" plus "Neu verbinden". **Only a tap** brought it back; rejoin with the token worked, the missed moves arrived. |
| guest | relay | Same: the host (or the relay's own ping, whichever first) dropped the guest (`relay.left` / kick), the **room stayed open** (idle expiry 10 min). After unlock: button, tap, rejoin worked. |
| host | LAN | The guest noticed after 10 s and showed the button. A tap while the host was locked failed: the kernel still accepted the TCP connection but nobody answered `hello` (handshake timeout). After unlock the host process handled the stale connections and kept waiting; the guest's next **tap** got back in. Not visible with SIGSTOP but likely on iOS: a suspended app's listening socket may be taken by the system, then nobody could join at all until the host restarted the room (nothing re-bound it). |
| host | relay | **The game was lost.** The relay pings every 20 s; an unanswered ping closed the host's WebSocket and the relay closed the room at once (`relay.closed "host left"`). The guest got "no room with code …" / "Der Raum wurde geschlossen", the host on unlock "relay connection lost" → "Starte einen neuen Raum". |

Also: nothing in the app listened to `AppLifecycleState`; the keepalive already ignored the suspended side's own
stall (KLD-109), so the problem was never the suspended side timing out, but the awake side (and the relay)
dropping it, plus nobody reconnecting by themselves. Raising the timeout alone would not have helped.

## What changed

**Guest reconnects by itself** (`NetworkTransport`, default on; `autoReconnect: false` for scripts that
reconnect by hand). On every disconnect except a `bye` from the host or a relay that closed the room, and when
the app comes back to the foreground (`appResumed`; also when it was away longer than the timeout while the
connection still looks fine), it retries `KlunkiGuest.reconnect` (token rejoin) with backoff 0.5 s, 1 s, 2 s,
then every 3 s, for up to 5 minutes (`reconnectFor`). Meanwhile the banner says "Verbindung wird
wiederhergestellt …" with a spinner and no button. It stops early (and shows why) on a version mismatch,
`session full`, a divergence, or a room that is gone. After giving up the banner shows "Neu verbinden" as before;
coming back to the app starts a new round.

**LAN host listens again** (`KlunkiHost.resume`): on app resume the TCP/WebSocket listener is closed and bound
again on the same ports (retried for ~10 s if a port is still busy). Open connections are not touched (tested
for a TCP and a WebSocket guest). A listener that errors or ends by itself is re-bound too (no longer an unhandled
error).

**Relay keeps the room for an away host** (Dart relay and Cloudflare Worker, shared vectors):
- `relay.room` now carries `key` (random 16 bytes, hex): the room's host key.
- A host connection that ends without a clean close (no close frame, error, unanswered ping, code 1001, or
  the new 4000 "dropped, not leaving") makes the host *away* for `hostGrace` (5 min; Worker
  `HOST_GRACE_SECONDS`; 0 = old behaviour): the guest is dropped (it reconnects), joins get
  `relay.error {error: "host-away"}`. A clean close (1000 / none) still closes the room at once.
- `?resume=CODE&key=KEY` brings the host back (`relay.room` again); wrong key = "no room"; a resume replaces a
  host connection that still looks open and drops the guest.
- `RelayHostListener` comes back on its own when its relay connection drops (`RoomReconnecting` /
  `RoomReconnected` events, backoff up to 5 s, for 5 min); `KlunkiHost.resume(away:)` forces it after a pause of
  at least the timeout. It closes old connections with 4000, never with a "leaving" close. The host banner shows
  "Verbindung wird wiederhergestellt …" meanwhile.

**Screen stays on during a running game** (`ScreenAwake`, platform channel `klunki/screen`, no package): iOS
`UIApplication.shared.isIdleTimerDisabled` (registered in `AppDelegate.swift` through the implicit engine's
plugin registry; no Xcode project change), Android `FLAG_KEEP_SCREEN_ON` (`MainActivity.kt`), web/desktop no-op.
On while `NetworkGameSession` shows a game that is not over, off when the game ends or the screen closes. The
user can still lock the phone by hand; that case is what the reconnect handles.

**Wording:** `pairingReconnecting` (de) is now "Verbindung wird wiederhergestellt …"; new `relayErrorHostAway`
("Das Gerät, das Raum {code} gestartet hat, ist gerade nicht erreichbar. Versuch es gleich noch einmal.") in all
7 locales (zh reworded to glyphs in the font subset).

## Protocol impact

- **Game protocol: unchanged, `protocolVersion` stays 3.** Old and new builds play together; rejoin uses the
  existing token.
- **Relay protocol: additive and backwards compatible.** New: `key` in `relay.room`, `?resume=CODE&key=KEY`,
  `relay.error` `error: "host-away"`, close code 4000. An old host on a new relay: ignores `key`, leaves with a
  clean close (room closes as before); only its dropped connection now leaves the room waiting 5 min. A new host
  on an old relay gets no `key` and loses the room as before. An old guest that meets "host-away" sees a generic
  relay error and can tap again. `PROTOCOL.md` "Reconnect" / "A locked phone" and "Relay" updated; two new shared
  vector scenarios.
- The deployed relay (if any) must be updated to get the host grace period; the Docker image builds from this
  code, the Worker port is updated too.

## Acceptance criteria

- [x] Findings per case (host/guest locks × LAN/relay) written down (above), reproduced with a SIGSTOP test.
- [x] Guest auto-reconnects on resume and on disconnect, with backoff and "Verbindung wird wiederhergestellt …";
      the manual button stays as fallback.
- [x] The host keeps the seat; a LAN host re-binds on resume; a relay host re-attaches; the relay keeps the room
      for 5 minutes for an away host (backwards compatible, no protocol bump).
- [x] Screen stays on during a running network game, without a new package and without Xcode project edits.
- [x] All 7 locales; l10n tests green.
- [x] Tests: `packages/klunki_net/test/suspend_test.dart` (SIGSTOP, all four cases), `relay_resume_test.dart`
      (grace, resume, wrong key, expiry, replace, LAN re-bind, old relay), vectors (Dart + Worker),
      Worker `relay.test.js`; app `test/transport/network_resume_test.dart`, `test/ui/pairing/network_resume_test.dart`.
- [ ] 🧑 Device test (below).

## Device test for the maintainer

Use two phones, a game such as 4 Gewinnt, and for each case lock one phone for ~1 min, then ~4 min, then unlock:
1. **LAN, guest locks**: the host shows "Verbindung zu … unterbrochen. Warte …"; after unlocking the guest
   shows "Verbindung wird wiederhergestellt …" briefly and plays on, no tap.
2. **LAN, host locks**: the guest shows "Verbindung wird wiederhergestellt …" the whole time (spinner, no
   button) and is back within a few seconds of the host unlocking.
3. **Relay, guest locks** and 4. **Relay, host locks**: same as 1 / 2; the room code stays the same. Needs a relay
   built from this branch (`klunki relay`, Docker or Worker); with an older relay case 4 still loses the room.
5. **Screen**: during a game the screen should no longer dim/lock by itself (iPhone, Android); after the game
   (result shown) or leaving it, auto-lock works again.
6. Longer than 5 minutes locked: the guest ends with "Neu verbinden" (tap works if the host is still there);
   through the relay the room is gone after 5 minutes of the host being away.
Also check the PWA in a mobile browser (tab in the background, then back), where iOS Safari may behave
differently from the app.

## Notes / follow-ups

- iOS may still kill a suspended app after a long time (memory); then the host's room is gone and a new room is
  needed (the guest ends with the button / "Raum geschlossen").
- A background task (`beginBackgroundTask`) could keep the connection for ~30 s after locking; not needed now.
- The relay CLI has no flag for `hostGrace` (default 5 min); add `--host-grace` if an operator needs it.

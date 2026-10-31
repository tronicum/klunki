# KLD-057: Browser hosts a game (relay with room codes)

- **ID:** `KLD-057a` (network package + CLI, DONE), `KLD-057b` (UI, open)
- **Title:** Browser vs browser: a relay pairs a host and a guest by room code; the host stays authoritative
- **Milestone:** P3/P4 (PWA multiplayer)
- **Status:** 057a DONE · 057b TODO
- **Depends on:** KLD-054 (WebSocket in `klunki_net`), KLD-055 (web join screen), KLD-056 (player names)
- **Touched paths (057a):**
  - `packages/klunki_net/lib/src/relay/relay_protocol.dart` (new, web-safe: codes, URLs, control messages)
  - `packages/klunki_net/lib/src/relay/relay_client.dart` (new, web-safe: `RelayHostListener`, `RelayGuestChannel`)
  - `packages/klunki_net/lib/src/relay/relay_server.dart` + `lib/relay_server.dart` (new, `dart:io`: `RelayServer`)
  - `packages/klunki_net/lib/src/host.dart` (`startRelay`, `roomCode`, `relayUrl`), `lib/src/guest.dart`
    (`connectRelay`, `roomCode`, `relayUrl`), `lib/src/connection.dart` (a `NetException` on the channel
    becomes the close reason), `lib/klunki_net.dart`, `lib/guest_web.dart` (exports)
  - `packages/klunki_net/lib/src/cli/cli.dart`, `bin/klunki.dart` (`relay`, `host --relay`, `join --relay --room`)
  - `packages/klunki_net/test/relay_test.dart` (new), `test/cli_test.dart`, `test/web_compile_test.dart`
  - `packages/klunki_net/PROTOCOL.md` ("Relay"), `docs/DEMO.md`, `docs/tasks/BOARD.md`

## Goal
A web page cannot listen for connections. For browser vs browser, browser A presses "Spiel hosten",
connects out to a relay and gets a short room code; browser B enters the code and joins. The host keeps
running the existing host logic (authoritative engine, move validation, token rejoin, names). The relay only
forwards protocol lines between the host and one guest. One LAN computer runs
`klunki relay --port 8080 --web klunki/build/web`, and the PWA served from there uses the same origin
(`ws://<location.host>/relay`).

## Design
- **One server, two jobs** (`RelayServer`, plain `dart:io` `HttpServer` + `WebSocketTransformer`, no new
  dependencies): WebSocket endpoint `/relay` (`?create` for the host, `?join=CODE` for the guest), and with
  `--web DIR` static files on every other path (MIME map incl. `.wasm`, `.mjs`, `.json`, `.webmanifest`,
  fonts; `/` and directories → `index.html`; `.`/`..` segments, encoded separators and symlinks leading
  outside the root → 404; GET/HEAD only; `no-cache` for html, service worker, manifest).
- **Control messages** carry `t` (never `type`) with a `relay.` prefix: `relay.room {code}`, `relay.peer`,
  `relay.left {reason}`, `relay.closed {reason}`, `relay.error {message}` and host → relay `relay.kick`.
  Everything else is forwarded unchanged. A guest sending a relay control line is refused, so it cannot
  impersonate the relay. Full table in `PROTOCOL.md`, "Relay".
- **Lifecycle (my choice, documented):** the guest leaving does *not* close the room: the host gets
  `relay.left`, and a guest can rejoin with the same code (the host session then does the usual token
  rejoin, so `KlunkiGuest.reconnect()` works through the relay). The host leaving closes the room: the
  guest gets `relay.closed "host left"` and is disconnected. Idle rooms (no forwarded frame for 10 min)
  expire with `relay.closed`.
- **Limits:** 5-character codes from `23456789ABCDEFGHJKMNPQRSTUVWXYZ` (no 0/O/1/I/L, case-insensitive input,
  dashes/spaces ignored); one guest per room ("room … is full"); 256 Ki characters per frame; 500 rooms;
  text frames only; WebSocket pings every 20 s to notice vanished peers.
- **No parallel host implementation.** `KlunkiHost` already took its guests from a `HostListener` (a stream
  of `MessageChannel`s). `RelayHostListener` is a second `HostListener`: it holds the one WebSocket to the
  relay and turns every `relay.peer` into a fresh virtual `MessageChannel` (ended by `relay.left`; closing
  it sends `relay.kick`). The session code (`Connection`, handshake, moves, keepalive, rejoin) is untouched.
  `RelayGuestChannel` wraps the guest's WebSocket and turns `relay.error`/`relay.closed` into a
  `NetException` with a readable reason.
- **Web-safe:** the client side only uses the platform WebSocket (`dart:io` on the VM, the browser's
  `WebSocket` on the web); `relay_server.dart` is a separate `dart:io` library that the web entry points do
  not reach (checked by `web_compile_test`, which also compiles a relay host + relay guest program with dart2js).

## API for the UI (KLD-057b)
All in `package:klunki_net/klunki_net.dart` (the guest side also in `guest_web.dart`), web-safe:

```dart
// Where is the relay? In the PWA served by `klunki relay --web`: the page's own origin.
final Uri? relay = relayUriForPage(Uri.base);          // http://h:p/… → ws://h:p/relay (https → wss)
final Uri? typed = parseRelayUrl('192.168.1.20:8080');  // ws://…, wss://…, http(s)://…, host:port → …/relay

// Host ("Spiel hosten"): completes once the relay assigned a room code.
final host = await KlunkiHost.startRelay(GameConfig('connect4', seed: s), relay!,
    name: playerName, hostPlayer: Player.a, pingInterval: …, timeout: …);  // NetException on failure
host.roomCode;   // 'K7Q2M': show it
host.relayUrl;   // the relay endpoint
host.events;     // PeerConnected(name) when the guest's hello arrives = "the peer is here";
                 // PeerDisconnected / PeerConnected(reconnect: true) as usual;
                 // NetError('relay: …') when the room is lost (relay restart, idle expiry)
host.submitLocal(move); host.close();   // everything else exactly as a direct host

// Guest (room-code join): the same KlunkiGuest as for direct WebSocket.
final code = normalizeRoomCode(input);   // null = invalid ('k7q-2m' → 'K7Q2M')
final guest = await KlunkiGuest.connectRelay(relay!, code!, name: playerName);
// NetException('relay: no room with code K7Q2M' / 'relay: room K7Q2M is full' / …)
guest.transport == 'relay'; guest.roomCode; guest.relayUrl; guest.hostName; guest.reconnect();
```

Constants: `relayPath` (`/relay`), `defaultRelayPort` (4749), `roomCodeLength` (5), `roomCodeAlphabet`.
Server (`package:klunki_net/relay_server.dart`, `dart:io` only): `RelayServer.start(port:, address:,
webRoot:, idleTimeout:, maxLineLength:, maxRooms:, pingInterval:)`, `.port`, `.roomCount`, `.close()`,
`mimeTypeFor(name)`.

## CLI
```bash
dart run klunki_net:klunki relay [--port N] [--web DIR]          # default port 4749; Ctrl+C stops
dart run klunki_net:klunki host <game> --relay ws://<relay>[:port] [--seed S] [--name NAME]   # prints "Room code: K7Q2M"
dart run klunki_net:klunki join --relay ws://<relay>[:port] --room CODE [--name NAME]
```
`--relay` accepts `ws://`, `wss://`, `http(s)://` or `host:port`; the path defaults to `/relay`.
`host --relay` cannot be combined with `--port`/`--ws-port`. A relay host whose room is lost ends with exit 1.

## Acceptance criteria (057a)
- [x] Relay server: `/relay?create` → `relay.room {code}`; `?join=CODE` → host gets `relay.peer`; lines
      forwarded unchanged both ways; disconnect propagation (`relay.left` / `relay.closed`); codes from an
      unambiguous alphabet, case-insensitive; one guest per room; idle expiry; max line size, max rooms
- [x] Static serving with `--web` (MIME incl. `.wasm`/`.js`/`.json`/`.webmanifest`, index fallback, no traversal)
- [x] CLI `relay`, `host --relay`, `join --relay --room`; `--help` text and `docs/DEMO.md`
- [x] Web-safe client API reusing the existing host/guest session code; names unchanged
- [x] Tests: relay unit tests (create/join/forward, wrong code, full room, guest/host disconnect, kick,
      expiry with a short timeout, line limit, binary/forged control lines, max rooms, shutdown, 426),
      client tests (names, moves, errors, rejoin with token, `reconnect()`, relay loss), end to end Mühle
      demo script with host and guest both through the relay (same final state, names, every move once),
      static serving (MIME, fallback, HEAD/405, traversal incl. encoded and symlink), CLI through a relay,
      `web_compile_test` compiles a relay host + guest for the web
- [x] `PROTOCOL.md` "Relay" section, `BOARD.md`

## KLD-057b: what the UI needs (open)
- **Host:** a "Spiel hosten" entry in the web pairing flow (and optionally in the apps): pick a game, call
  `KlunkiHost.startRelay(config, relayUriForPage(Uri.base)!, name: profile name)`, show `roomCode` large
  (plus a copyable `?room=` link), wait for `PeerConnected`, then start the same `NetworkGameSession`.
  `NetworkTransport` needs a `hostRelay(...)` factory next to `host`/`joinWebSocket` (the host session API is
  the same, so the transport code should only need the factory). Show `NetError('relay: …')` as "room lost".
- **Join:** a room-code field in `WebJoinScreen` (5 characters, uppercase, `normalizeRoomCode`), relay from
  the page origin; `NetworkTransport.joinRelay(relayUrl, code, name:)` → `KlunkiGuest.connectRelay`.
  Map `relay: no room with code` / `is full` to German hints. Optionally `?room=CODE` at startup.
- **Relay address:** default = page origin (`relayUriForPage`); when the PWA is served elsewhere (e.g.
  python http.server), the user needs a field for the relay address (`parseRelayUrl`). Native apps have no
  page origin: they would need a typed relay address, or keep hosting directly (they can listen).
- Strings in all 7 ARB files; widget tests with a real `RelayServer` on loopback.

## Constraints / notes
- No new dependencies (plain `dart:io` server). No changes to the app in 057a.
- No authentication or TLS: whoever knows the code can take a free guest slot; meant for the LAN. Internet
  hosting (wss, per-IP rate limits, abuse review) stays KLD-051 and needs 🧑 decisions.
- A guest whose connection silently died holds the slot until the host session's keepalive timeout (10 s)
  kicks it or the relay's WebSocket ping (20 s) notices; then it can rejoin.

## Definition of done
`cd packages/klunki_net && dart analyze && dart test`; `cd packages/klunki_engine && dart analyze && dart test`.

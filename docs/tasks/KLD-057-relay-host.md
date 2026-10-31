# KLD-057: Browser hosts a game (relay with room codes)

- **ID:** `KLD-057a` (network package + CLI, DONE), `KLD-057b` (UI, DONE)
- **Title:** Browser vs browser: a relay pairs a host and a guest by room code; the host stays authoritative
- **Milestone:** P3/P4 (PWA multiplayer)
- **Status:** 057a DONE · 057b DONE
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

## KLD-057b: the UI (DONE)
**Touched paths:** `klunki/lib/transport/network_transport.dart` (`hostRelay`, `joinRelay`, `roomCode`,
`relayUrl`, `roomLost`, `changes`), `klunki/lib/net/room_link.dart` (new: `formatRoomCode`, `RoomLink`
(`?room=` / `&relay=`), `roomJoinLink`, `relayAddressLabel`, `relayStartCommand`), `klunki/lib/net/join_qr.dart`
(`KlunkiQrCode` for any string), `klunki/lib/ui/pairing/relay_host_screen.dart` (new),
`room_join.dart` (new, `RoomCodeJoin` + `RelayStartHint`), `relay_errors.dart` (new),
`web_join_screen.dart`, `pairing_screen.dart` (join tab), `network_game_session.dart` (relay banners),
`klunki/lib/app/klunki_app.dart`, `klunki/lib/ui/menu_screen.dart` (`?room=`), 7 ARB files (+ generated),
`klunki/assets/fonts/NotoSansSC/**` (subset rerun), `klunki/tool/pwa_relay_e2e.{sh,mjs}` (new), tests, `docs/DEMO.md`.

What the user sees:
- **PWA → Über WLAN spielen:** name field, then **Spiel hosten** ("Ein zweiter Browser im selben WLAN tritt mit
  dem Raumcode bei."), then **Mit Raumcode beitreten** (code field in capitals, "Erweitert: Relay-Adresse"
  prefilled with the page's own `host:port`, **Raum beitreten**), then the existing direct join to a native host
  ("Oder mit einem Host-Gerät verbinden"). With `?join=` the direct section comes first.
- **Spiel hosten:** name, game choice (same list as the app's host tab), "Erweitert: Relay-Adresse",
  **Spiel hosten** → waiting screen: "Ada hostet 4 Gewinnt", **Raumcode** large and grouped (`K7Q 2M`), QR code of
  the join link, the link `<page>/?room=K7Q2M` (selectable, copy button; `&relay=host:port` when another relay was
  chosen), a hint, "Relay: host:port", spinner "Warte auf Mitspieler…", Abbrechen. When the guest's hello
  arrives the route is replaced by the usual `NetworkGameSession` (connection bar with both names).
- **`?room=CODE[&relay=…]`** at startup opens the join screen over the menu with the code filled in and joins
  right away (after the first-run name dialog), like `?join=`. An invalid code is only prefilled.
- **Not served by a relay** (plain `python3 -m http.server`): "Kein Relay erreichbar unter host:port." plus
  "Browser gegen Browser braucht ein Relay …" and the command `dart run klunki_net:klunki relay --web klunki/build/web`.
- **Errors** (`relay_errors.dart`, from the `klunki_net` messages): unknown code, room full, host left, room expired,
  relay not reachable (also a join timeout), relay connection lost. Anything else falls back to the usual
  "Verbindung zu … fehlgeschlagen (…)".
- **In the game:** a relay guest whose host left (bye, or `relay: host left`) gets "Der Host hat den Raum verlassen.
  Das Spiel ist beendet." without the pointless "Neu verbinden"; a guest that lost its own connection keeps
  "Neu verbinden" (token rejoin through the room). A relay host whose room is lost (`NetError('relay: …')`, e.g.
  relay restart or idle expiry) gets "… Starte ein neues Spiel." instead of "Warte, bis er wieder beitritt".
- **Apps (native):** the join tab gets the same **Mit Raumcode beitreten** block with a visible, required relay
  address field (an app has no page origin). Hosting through the relay from the apps was skipped (they can listen
  directly); the LAN host flow is unchanged.

l10n: 22 new keys (`relay*`, `webJoinDirectTitle`) in all 7 ARB files; fr/es/zh/ar/fa are machine translations
under the existing `@@x-review` marker. Room codes, addresses and URLs are LTR (`bidiLtr`, `textDirection: ltr`).
The Noto Sans SC subset was rebuilt (`tool/update_web_fonts.py subset`) for the new zh characters.

Tests:
- `test/net/room_link_test.dart`: code grouping, `?room=`/`&relay=` parsing, join links, error classification.
- `test/ui/pairing/relay_test.dart`: room-code validation and normalisation (`k7q-2m` → `K7Q2M`, page relay),
  each relay error's text and the start hint, the advanced relay field, the native join tab, `?room=` at startup
  (name dialog first, `&relay=`, invalid code), the host waiting screen against a real `RelayServer` on loopback
  (grouped code, link = QR data, guest arrives → game), no relay → start hint, relay stops while waiting →
  "Die Verbindung zum Relay ist abgebrochen.", and an **in-process end to end** game: two web join screens, A hosts via
  the relay, B types the code, Four in a Row to the result on both, then A leaves and B sees "Der Host hat den Raum
  verlassen" without "Neu verbinden".
- `test/l10n/coverage_test.dart` ("relay host and room join", every locale, two sizes), `rtl_test.dart` (ar).
- **Real browsers:** `klunki/tool/pwa_relay_e2e.sh [--build] [--port N] [--out DIR]` starts the relay with
  `--web build/web` and a plain python server, then drives two headless Firefox instances over WebDriver BiDi
  (Flutter's accessibility tree is switched on, widgets are found by their semantics labels and tapped with real
  pointer events; no app test hooks). Run 1: the plain server shows the "no relay" hint, A hosts, B types the code,
  7 moves, both show the result. Run 2: B opens A's `?room=` link instead. PASS/FAIL + screenshots.

## Constraints / notes
- No new dependencies (plain `dart:io` server). No changes to the app in 057a.
- No authentication or TLS: whoever knows the code can take a free guest slot; meant for the LAN. Internet
  hosting (wss, per-IP rate limits, abuse review) stays KLD-051 and needs 🧑 decisions.
- A guest whose connection silently died holds the slot until the host session's keepalive timeout (10 s)
  kicks it or the relay's WebSocket ping (20 s) notices; then it can rejoin.

## Definition of done
`cd packages/klunki_net && dart analyze && dart test`; `cd packages/klunki_engine && dart analyze && dart test`;
`cd klunki && flutter analyze && flutter test`; `klunki/tool/pwa_relay_e2e.sh --build` (057b).

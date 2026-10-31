# KLD-054: WebSocket support in `klunki_net` (PWA joins a native host)

- **ID:** `KLD-054`
- **Title:** The host accepts WebSocket guests next to TCP; a web-safe guest for the browser PWA
- **Milestone:** P3/P4 (PWA multiplayer)
- **Status:** DONE
- **Depends on:** KLD-030, KLD-031, KLD-032, KLD-033
- **Touched paths:**
  - `packages/klunki_net/**` (library, CLI, tests, `PROTOCOL.md`)
  - `klunki/lib/net/discovery.dart`, `klunki/lib/net/join_payload.dart` (`w=` / TXT `ws`, data only)
  - `klunki/lib/transport/network_transport.dart` (`wsPort`, `joinWebSocket`)
  - `klunki/test/net/join_payload_test.dart`, `klunki/test/net/fake_discovery_test.dart`, `klunki/test/transport/network_transport_test.dart`

## Goal
User decision: the browser PWA gets multiplayer by **joining a native host**
(iOS/Android app or `klunki host` CLI) **over WebSocket on the LAN** (`ws://`,
since the PWA is served over plain http). No relay, no internet server;
browser ↔ browser is out of scope (a page cannot listen).

## Design
- **Channel abstraction.** `src/channel/channel.dart` defines `MessageChannel`
  (incoming text messages, `send`, `close`). `Connection` (envelope checks,
  keepalive, `bye`/`error`, timeout) runs on any channel, so host authority,
  tokens, replay and reconnect exist once. Implementations:
  - `SocketChannel`: TCP, NDJSON (one message per line), as before.
  - `IoWebSocketChannel`: `dart:io` `WebSocket`, one message per text frame
    (host side, VM guests, the CLI).
  - `BrowserWebSocketChannel`: the browser `WebSocket` through
    `dart:js_interop` extension types; **no new pub dependency** (not even
    `package:web`).
- **Platform split.** `src/channel/platform.dart` conditionally exports
  `platform_io.dart` (TCP + WebSocket, can host) or `platform_web.dart`
  (WebSocket guest only; TCP connect and hosting fail with a clear error).
  `host.dart`, `guest.dart` and `connection.dart` no longer import `dart:io`,
  so both `package:klunki_net/klunki_net.dart` and the guest-only
  `package:klunki_net/guest_web.dart` compile for the web.
- **Second port, not sniffing.** The host listens on TCP `port` (default
  4747) and on a separate WebSocket port `wsPort` (default 4748 in the CLI;
  `KlunkiHost.start` defaults to `0` = ephemeral, `null` = TCP only).
  Rationale (also in `PROTOCOL.md`): sniffing `GET ` on one port needs bytes
  "un-read" from a single-subscription `dart:io` `Socket` before handing it
  to `HttpServer`/`WebSocket.fromUpgradedSocket`: a hand-written `Socket`
  wrapper or HTTP parser. The second port uses `HttpServer.bind` +
  `WebSocketTransformer.upgrade` as documented and leaves the TCP path
  untouched. If either port is taken, `start` throws and nothing stays bound.
  Non-upgrade HTTP requests get `426 Upgrade Required`.
- **Advertising.** Join payload: optional `w=` (`JoinPayload.wsPort`,
  `JoinPayload.webSocketUri`). mDNS TXT: optional key `ws`
  (`KlunkiTxt.wsPort`, `KlunkiHostInfo.wsPort`). Old clients ignore both.
- **CLI.** `klunki host <game>` also listens on `--ws-port` (default 4748;
  `--port 0` alone makes both ephemeral) and prints the `ws://` URLs.
  `klunki join ws://ip[:port]` joins as a WebSocket guest.

## Web-guest API (for the app / pairing UI agent)
```dart
import 'package:klunki_net/guest_web.dart'; // or klunki_net.dart: both are web-safe

final guest = await KlunkiGuest.connectWebSocket(
  webSocketUri('192.168.1.20', defaultWebSocketPort), // ws://192.168.1.20:4748
  name: 'Bea', token: savedToken /* optional, to rejoin */,
);
```
In the app: `NetworkTransport.joinWebSocket(payload.webSocketUri!, name: …)`
returns the same `NetworkTransport` as `join`. On the host,
`NetworkTransport.host(…)` now also opens a WebSocket port (`wsPort: 0` by
default); advertise `transport.wsPort` as `JoinPayload(wsPort: …)` and
`KlunkiHostInfo(wsPort: …)`.

Left for the follow-up web pairing UI task (not done here, no UI changes):
- wire `transport.wsPort` into the pairing screen's QR payload and
  advertisement (prefer 4748, fall back to 0 like the TCP port);
- a web join screen (manual `ip:port` / `ws://` entry or pasted payload);
  on web `pairing_entry.dart` still routes to the stub;
- the copies of the default ports and protocol version in `join_payload.dart`
  could now come from `klunki_net` directly, since it no longer pulls in
  `dart:io`.

## Acceptance criteria
- [x] One protocol implementation over TCP (NDJSON) and WebSocket (frame per message)
- [x] Host accepts TCP and WebSocket guests at the same time (second port, documented why)
- [x] Web-safe guest entrypoint without `dart:io`; no new dependencies; no Flutter in `klunki_net`
- [x] CLI: `host` accepts WebSocket guests, `join ws://ip:port`
- [x] Tests (`test/ws_test.dart`): Mühle TCP host vs WebSocket guest to the end; reconnect over
      WebSocket (token rejoin + `reconnect()` replay); full session for mixed TCP/WebSocket guests
      (both directions) and switching transport with the token; protocol version mismatch over
      WebSocket (both directions); binary/malformed frames; ping timeout; 426; taken port
- [x] `test/web_compile_test.dart`: the web import graph of `guest_web.dart` and `klunki_net.dart`
      (conditional imports resolved for the web) reaches neither `dart:io` nor Flutter, and
      `dart compile js` builds a WebSocket guest program. dart2js alone would not prove the
      first point: it accepts `dart:io` imports and only fails at run time
- [x] Existing TCP tests and the KLD-037a e2e pass unchanged
- [x] `PROTOCOL.md`: WebSocket framing, ports, `w=` and TXT `ws`
- [x] `dart analyze` + `dart test` (klunki_net), `flutter analyze` + `flutter test` (klunki) green

## Definition of done
`cd packages/klunki_net && dart analyze && dart test`; `cd klunki && flutter analyze && flutter test`.

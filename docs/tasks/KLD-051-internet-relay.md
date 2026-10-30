# KLD-051 — Internet lobby / relay (design + local prototype)

- **ID:** `KLD-051`
- **Title:** Lobby/relay service: game code → session, relays `klunki_net` messages over WebSocket, so players on different networks (and the PWA) can play
- **Milestone:** Backlog (after the PoC). **Needs a hosting decision and a privacy/abuse review by the user (🧑) before anything is deployed.**
- **Status:** TODO
- **Depends on:** KLD-030 (protocol), KLD-032 (transport), KLD-050 (code format); 🧑 hosting provider + budget, privacy review
- **Touched paths** (proposed; the board lists none for backlog items, so confirm with the caller):
  - `packages/klunki_relay/**` (new pure-Dart package: server + client lib)
  - `docs/tasks/KLD-051-internet-relay.md` (status only)
  - Phase 2 only, in a separate card: `klunki/lib/transport/relay_transport.dart`, `klunki/lib/ui/pairing/**`, `klunki/pubspec.yaml`

## Goal
**Phase 1 (this card, no deployment):** a written design and a pure-Dart relay server that runs locally (`dart run`). Two clients
(CLI or tests) meet via a game code and play through it, with messages relayed unchanged. **Phase 2 (separate card, after 🧑 decisions):**
an app `RelayTransport`, the PWA joining over WebSocket, and deployment.

## Repo context
- `packages/klunki_net` (KLD-030): NDJSON messages `hello {protocol, game, mode, seed}`, `move`, `accepted`, `rejected`, `snapshot {moves}`, `ping`, `bye`;
  host-authoritative. The relay should **not** run game logic. It forwards lines between the host and the guest of one session; the host stays authoritative.
- Browsers can't open TCP sockets but can open WebSockets, which is why the web build is hot-seat only today (`docs/ROADMAP.md`).
- Code format from KLD-050: `KLNK-` + 4 digits. On the internet that's too guessable: the design must use a longer code or rate limits.

## Acceptance criteria (phase 1)
- [ ] A design section at the top of `packages/klunki_relay/README.md`: message flow (create session → code; join with code; relay; expiry), code length
      and entropy, expiry (e.g. 10 min idle), rate limits per IP, max message size, what's logged (target: nothing but counters), TLS (`wss://`)
      termination, and a hosting options table (cost and ops effort). It ends with an explicit **"Decisions needed from the user"** list (🧑).
- [ ] `packages/klunki_relay/bin/server.dart`: a `dart:io` `HttpServer` with WebSocket upgrade on `localhost` and a configurable port. `create` returns a code;
      `join <code>` pairs; after pairing, every text frame is forwarded to the peer; it closes on `bye`/disconnect; it expires idle sessions.
- [ ] `packages/klunki_relay/lib/relay_client.dart`: a minimal client usable from tests and later from the app.
- [ ] Tests: two clients play a Four in a Row game through a local relay using real `klunki_net` messages. A wrong code is rejected. Expiry and
      size-limit behaviour are covered.
- [ ] `cd packages/klunki_relay && dart analyze && dart test` green.

## Constraints
- **Board rule:** never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the user's
  explicit OK. **No hosting sign-up, no deployment, no domain, no public endpoint** in this card. Phase 1 runs on `localhost` only.
- Pure Dart (no Flutter) in `klunki_relay`. New pub.dev dependencies (e.g. `shelf`, `shelf_web_socket`) only after the user confirmed the list.
  `dart:io` alone is enough.
- Privacy: store no player names or IPs beyond the process lifetime, and no analytics. Don't commit unless asked.

## Hints / context
- The relay is "dumb pipes per code": host socket ↔ guest socket. Reconnect (KLD-036) works the same way, through the same code within the expiry window.
- The PWA (KLD-010) would need a `WebSocketChannel`-style transport. That's phase 2.

## Definition of done
```bash
cd packages/klunki_relay
dart analyze
dart test
dart run bin/server.dart --port 8080   # local only
```
Green; design doc with the 🧑 decision list delivered; card status set to DONE (phase 1).

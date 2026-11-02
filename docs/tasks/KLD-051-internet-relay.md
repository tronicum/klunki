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

## Later: self-hosted club server with access codes (maintainer idea, 2026-11-02)
Not scheduled yet; collected here so the internet relay is designed for it.
- **Package the existing relay** (`klunki relay`, KLD-057a) as something anyone can run for their circle of friends:
  - a small Docker image (`dart compile exe`, minimal base image), with TLS through a reverse proxy (e.g. Caddy) for `wss://`;
  - possibly later an edge-function variant (would need a port of the relay protocol; assess first).
- **Server access codes ("Clubcodes"), beta:** the server keeps a list of codes, several per server, e.g. one per family or friend. A browser or app needs a valid code once (it is saved in the relay settings next to the server address); after that, rooms work with the normal room codes.
  - Codes can be **revoked** one by one (edit the list or an admin CLI command, no restart), so a server shared with a friend club can't be misused by strangers.
  - The code travels in the WebSocket handshake. It is only checked by the relay and never reaches the host or the game; there are no accounts, and nothing is stored beyond the process lifetime except the code list.
  - Wrong or revoked code: a clear message in the app ("Dieser Server kennt den Code nicht"), no room list leak.
- With such a server set in the relay settings, the GitHub Pages beta can play over the network (KLD-108 checks for a usable `wss://` relay).
- Open: how codes are created and shared (QR?), per-code limits on rooms, a protocol version bump for the handshake field.
- **Cloudflare variant (assessed 2026-11-02):** a Worker with **Durable Objects** (one object per room holds the host and guest WebSockets). The Workers Free plan includes Durable Objects (since 2025-04): 100,000 requests a day, where incoming WebSocket messages count 1:20 and outgoing ones are free, plus 13,000 GB-s a day of duration (about 29 h of open rooms a day at 128 MB). Idle objects hibernate after about 10 s and cost nothing then. That is plenty for a friend club.
  - Our keepalive pings must be answered without waking the object (WebSocket auto-response), otherwise rooms never hibernate.
  - The relay protocol has to be ported to TypeScript/JS (a few hundred lines) and tested against the Dart relay's protocol tests. Club codes go in a Worker secret or KV.
  - Each user deploys to their own Cloudflare account (button or `wrangler deploy`); we host nothing.
- **Prepared in KLD-114** (not deployed): `deploy/docker/` (image + Caddy) and `deploy/cloudflare/` (Worker + Durable Objects, club codes as a secret). The auto-response idea above does not fit: `ping`/`pong` are end-to-end game messages; see `deploy/cloudflare/README.md`, "Keepalive, hibernation and why there is no auto-response".

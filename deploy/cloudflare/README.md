# Klunki relay as a Cloudflare Worker (deploy it yourself)

> **Status: prepared, work in progress (KLD-114). Not deployed.** The code is a complete port of the relay and is
> tested here with Node against a hand-written fake of the Workers runtime, but it has never run on Cloudflare.
> The project hosts nothing: each club deploys it to **its own** Cloudflare account. Before the project
> recommends this anywhere, the first real deployment needs the maintainer's OK.

The relay lets two browsers (or apps on different networks) play each other: one player starts a room, the other
types its 5-character room code; the relay forwards their messages and runs no game logic. This is the same
protocol as `klunki relay` (`packages/klunki_net/PROTOCOL.md`, "Relay" and "Club codes"), ported to plain
JavaScript: ES modules, no build step, no dependencies.

```
browser/app ──wss──► Worker (src/relay.js)  path, upgrade, Origin, club code: refused here, before any room
                        │ create: draws a room code     join: normalises the code
                        ▼
                     Durable Object "RelayRoom" named by the room code (src/room.js)
                     holds the host's and the guest's WebSocket, forwards text frames unchanged
```

| file | what it is |
|---|---|
| `src/index.js` | Worker entry: the request handler and the `RelayRoom` class |
| `src/relay.js` | request checks, club codes, create/join, refusals as `relay.error` |
| `src/room.js` | `RelayRoom`, one per room, on the WebSocket Hibernation API |
| `src/protocol.js` | room/club code alphabet and normalisation, control messages, constant-time club code check |
| `wrangler.toml` | template: Durable Object binding, SQLite class migration (Free plan), logs off |
| `test/` | `node --test`: the shared protocol vectors plus Worker-specific tests, on a fake runtime (`test/fakes.js`) |
| `tool/new-club-code.js` | prints a new club code line |

## Deploy it yourself

You need a Cloudflare account (the Free plan is enough) and Node.js 22 or newer. `npx wrangler` downloads
Cloudflare's command-line tool the first time.

1. **Log in** (opens the browser): `npx wrangler login`
2. **Deploy**, in this directory (`deploy/cloudflare/`):
   ```bash
   npx wrangler deploy
   # … https://klunki-relay.<your-subdomain>.workers.dev
   ```
   The relay address for the app is `wss://klunki-relay.<your-subdomain>.workers.dev` (the app adds `/relay`).
   Until step 3 it is an **open** relay: anyone who finds the address can use it.
3. **Club codes** (strongly recommended): one per family or friend, in a file that stays on your computer:
   ```bash
   node tool/new-club-code.js "Familie Müller" >> codes.txt
   node tool/new-club-code.js "Ben" >> codes.txt
   npx wrangler secret put CLUB_CODES < codes.txt
   ```
   Same format as `klunki relay --codes FILE`: one code per line, `# label` optional, `#` lines are comments
   (`klunki relay-code new` makes the same codes). The labels are only for you; the Worker never logs anything.
   An existing but empty secret admits nobody.
4. **Check it** (needs the Dart SDK; opens a room, joins it, sends a line each way, and checks that a missing and a
   wrong code are refused):
   ```bash
   cd ../docker/relay && dart pub get --offline
   dart run tool/check_relay.dart wss://klunki-relay.<your-subdomain>.workers.dev/relay K7QX-M2PA
   ```
5. **In the app:** "Raum starten" › "Erweitert" › "ändern": relay address from step 2, Clubcode from step 3. Give
   each person their code separately; room links and QR codes never contain it.

Optional settings in `wrangler.toml` under `[vars]`: `ALLOWED_ORIGINS` (comma-separated web origins whose pages
may use the relay, e.g. `https://example.github.io`; apps send no Origin and always pass; browsers from other
pages get `403`), `IDLE_TIMEOUT_SECONDS` (default 600), `MAX_LINE_LENGTH` (default 262144),
`HOST_GRACE_SECONDS` (default 300: how long a room waits for a host whose connection dropped, e.g. a locked
phone; 0 closes the room at once; KLD-120).

## Revoke a code

Delete its line from your `codes.txt` and upload the file again:
```bash
npx wrangler secret put CLUB_CODES < codes.txt
```
The code is refused from the next connection on. Changing a secret deploys a new version of the Worker, and
Cloudflare then restarts the room objects: **expect open rooms to be disconnected** (players start a new room).
The same happens on every `wrangler deploy`. To remove everything: `npx wrangler delete`.

## Free plan: is it enough?

From the assessment in `docs/tasks/KLD-051-internet-relay.md` (Workers Free plan, Durable Objects included since
2025-04; check Cloudflare's current pricing page before relying on it):

- **100,000 requests a day.** Each new WebSocket is one request, incoming WebSocket messages count 1:20, outgoing
  ones are free. A running game sends about 2 keepalive messages per second through the relay (each side pings
  every 2 s, the other side answers), so one hour of play costs roughly 7,200 messages = 360 requests:
  about **270 hours of play a day**.
- **13,000 GB-s of duration a day**, about **29 hours of open rooms a day** at 128 MB. This is the real limit:
  a room in a running game never sleeps (see below), so one game hour costs one room hour.
- A room whose host waits for a guest **hibernates** after about 10 seconds and costs nothing until something
  happens. Rooms close after 10 minutes without a message.

For a friend club that is plenty. When a limit is reached, Cloudflare refuses further requests until the next day.

## Keepalive, hibernation and why there is no auto-response

The relay uses the WebSocket Hibernation API (`ctx.acceptWebSocket` with the handlers `webSocketMessage`,
`webSocketClose`, `webSocketError`, plus an alarm for idle expiry). Because an object can be evicted from memory
at any time, `RelayRoom` keeps no state in memory at all: host and guest are socket tags, and the room code, the
last activity and the "already gone" flag live in each socket's attachment. The tests evict every object after
every step to prove it.

The KLD-051 note hoped to answer our keepalive pings with `setWebSocketAutoResponse` so that rooms could sleep
during a game. That does **not** fit the protocol: `ping` / `pong` are **game messages between host and guest**
(`{"type":"ping","v":3}`, PROTOCOL.md "Keepalive"), forwarded by the relay, and they are how each side notices
that the *other player* is gone (timeout 10 s). An auto-response at the relay would answer for the other player:
a vanished guest would look alive to the host forever. It would also swallow the ping, so the other side would
time out. A waiting room already sleeps (no game messages flow before a guest joins; WebSocket-level ping frames
are answered by Cloudflare without waking the object).

What would have to change to let running games sleep: a relay-level keepalive, e.g. the client sends
`{"t":"relay.ping"}` and the relay auto-responds `{"t":"relay.pong"}` (a fixed request/response pair, as the API
requires), the game sessions on both sides stop sending their own pings through the relay and instead learn about
a lost peer from `relay.left` / `relay.closed`. That changes the clients (`klunki_net` host/guest), the Dart relay
(today a guest's `relay.*` line is refused) and PROTOCOL.md; with about 360 requests per game hour it is not
worth it for a friend club, so it is not done.

## Differences from `klunki relay` (Dart)

| | Dart relay / Docker image | this Worker |
|---|---|---|
| club codes | file, re-read on every connection | secret `CLUB_CODES`; changing it restarts the Worker (open rooms are disconnected) |
| wrong-code limit (10 per address per 10 min) | per relay process; behind a proxy shared by everyone | per Cloudflare isolate (best effort: an address can hit several isolates); uses the real client address (`CF-Connecting-IP`) |
| at most 500 rooms | yes | no global count (each room is its own object); the plan's request and duration limits are the brake |
| Origin allow-list | no | optional `ALLOWED_ORIGINS` |
| relay stops / restarts | `relay.closed "relay shutting down"` | connections just drop (deploys, secret changes, Cloudflare maintenance) |
| serving the PWA (`--web`) | yes | no (host the PWA elsewhere, e.g. GitHub Pages) |
| frame limit | 256 Ki UTF-16 code units | the same (Cloudflare's own WebSocket message limit is larger) |

Everything else (room codes, create/join, forwarding byte for byte, `relay.kick`, rejoin after `relay.left`,
one guest per room, idle expiry, refusal texts and close codes, club code checked before any room is looked at,
constant-time comparison) behaves the same; the shared vectors check it.

## Privacy

- **Nothing stored:** rooms live in the objects' memory and WebSocket attachments; the only storage entry is the
  idle alarm, deleted when the room closes.
- **Nothing logged by the Worker:** no `console` calls. `wrangler.toml` turns Workers Logs off, because Cloudflare
  would store request URLs, and the club code is in the URL (`?create&club=…`). `npx wrangler tail` (live logs,
  only for you as the account owner) shows URLs too.
- **Cloudflare is the operator:** TLS ends at Cloudflare, which processes IP addresses and could technically read
  the forwarded game messages; Cloudflare's own terms and privacy policy apply to your account. Klunki itself
  receives nothing.

## Tests

```bash
cd deploy/cloudflare && node --test test/
```
Node 22 or newer, nothing to install. `test/vectors.test.js` runs the protocol vectors in
`packages/klunki_net/test/relay_vectors.json`, the same file the Dart relay is tested against
(`relay_vectors_test.dart`, real sockets), so both relays must answer every scenario the same way; each scenario
runs twice, the second time with every room object evicted after every step (hibernation).
`test/relay.test.js` covers what only the Worker has: HTTP answers, Origin allow-list, club codes from the secret
(a refused client never reaches a room object), wrong-code limit, revocation, code collisions, idle alarm,
connection errors. `test/fakes.js` is a small fake of `WebSocketPair`, `Response` with status 101, and Durable
Objects with hibernation; it is not Cloudflare's runtime, which is why a first real deployment is still needed.

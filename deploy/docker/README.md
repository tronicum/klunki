# Klunki relay in Docker (for a friend club)

> **Status: prepared, work in progress (KLD-114).** The files are complete, but the project has not built or
> run this image yet: the first real build needs the maintainer's OK. What was checked without Docker is listed
> in `docs/tasks/KLD-114-relay-packages.md`.

The relay lets two browsers (or apps on different networks) play each other: one player starts a room, the other
types its 5-character room code. The relay forwards their messages and runs no game logic. With **club codes**
only people who know one of your codes can use it, so you can put it on the internet for family and friends.
Protocol details: `packages/klunki_net/PROTOCOL.md`, "Relay" and "Club codes".

What is in here:

| file | what it is |
|---|---|
| `Dockerfile` | two stages: the official Dart image (`dart:3.13.7`) compiles the relay with `dart compile exe`; the runtime image is `scratch` plus the few libraries the binary needs (from the Dart image's `/runtime/`), running as user 65532, no shell |
| `Dockerfile.dockerignore` | keeps everything but the two Dart packages and `relay/` out of the build (the build context is the repo root) |
| `relay/` | the image's entry point: the normal `klunki` CLI plus a `healthcheck` sub-command; `tool/check_relay.dart` checks a running relay from outside |
| `compose.yaml`, `Caddyfile` | the relay behind [Caddy](https://caddyserver.com), which gets a TLS certificate by itself, so players use `wss://` |

## Step by step

You need: a small Linux server or VM with Docker (with the compose plugin), a DNS name pointing at it
(e.g. `relay.example.org`), ports 80 and 443 open. All commands run in `deploy/docker/` of a checkout of this
repository, except where noted.

1. **Your name in the Caddyfile.** Replace `relay.example.org` with your DNS name.
2. **Build the image** (downloads the Dart image the first time):
   ```bash
   docker compose build
   ```
3. **Create club codes**, one per family or friend, with a label so you know whose it is:
   ```bash
   mkdir -p data
   docker compose run --rm --no-deps -T relay relay-code new --label "Familie Müller" >> data/codes.txt
   docker compose run --rm --no-deps -T relay relay-code new --label "Ben" >> data/codes.txt
   cat data/codes.txt
   # K7QX-M2PA  # Familie Müller
   # MNPQ-RSTU  # Ben
   ```
   (With the Dart SDK instead: `dart run packages/klunki_net/bin/klunki.dart relay-code new --label "Ben"` from
   the repo root.) The file is plain text: one code per line, `# label` optional, `#` lines are comments.
   The relay runs as user 65532 and must be able to read it: `chmod 644 data/codes.txt`, or, to keep other users
   on the server out, `sudo chown 65532 data/codes.txt && chmod 400 data/codes.txt`.
4. **Start:**
   ```bash
   docker compose up -d
   docker compose logs relay
   # Club codes loaded from /data/codes.txt: 2 (Familie Müller, Ben)
   # Klunki relay listening on port 4749: …
   # Host grace: a room waits 300 s for a host whose connection dropped (KLD-120).
   ```
   The addresses it prints are the container's own; players use your DNS name. No "Host grace" line: the image
   is older than this line (2026-11-04); built before KLD-120 it closes a room as soon as the phone that started
   it is locked for a few seconds. Rebuild it.
   After `git pull`, `docker compose up -d --build` builds a new image from this checkout (the build context is
   the repo root) and restarts the relay; running games end then. `--host-grace SECONDS` in the `command` of
   `compose.yaml` changes the 5 minutes (0 = off).

   To see what happens to a game (e.g. a phone that is locked), add `--log-rooms` to the `command` for a while:
   then the log has one line per room event (room code and WebSocket close code, no names, no addresses). Remove
   it again afterwards: the privacy page promises a relay that writes no logs.
   ```
   12:00:01 Room K7QX2: opened
   12:00:09 Room K7QX2: guest joined
   12:01:30 Room K7QX2: host away (close code 1001), the room waits 300 s for it   # a phone locked
   12:02:10 Room K7QX2: host back after 40 s
   12:02:11 Room K7QX2: guest joined
   12:10:00 Room K7QX2: host left (close code 1000)                                 # "Spiel verlassen"
   12:10:00 Room K7QX2: closed: host left
   ```
5. **Check it from anywhere** with the Dart SDK (opens a room, joins it, sends one line each way):
   ```bash
   cd deploy/docker/relay && dart pub get --offline
   dart run tool/check_relay.dart wss://relay.example.org/relay K7QX-M2PA
   ```
   It also checks that a missing and a wrong code are refused (two wrong attempts; see "Rate limit" below).
6. **Give each person their code** (separately from room codes: room links and QR codes never contain it). In the
   app: "Raum starten" › "Erweitert" › "ändern": relay `wss://relay.example.org`, Clubcode `K7QX-M2PA`. The app
   saves the code for this relay only.

## Revoke a code

Delete its line from `data/codes.txt` (or put `#` in front of it). That's all: the relay reads the file again on
every new connection, so the code is refused from the next connection on, without a restart. A game that is
already running may finish; a reconnect after the revocation is refused. Adding a line works the same way.

Mount the **directory** `./data`, as `compose.yaml` does, not the file alone: editors save by writing a new file
and renaming it, and a single-file bind mount would keep showing the old file to the container.

If the file is missing or unreadable, the relay refuses everyone until it is back (it does not start at all if
the file is missing at startup).

## Update

```bash
git pull
docker compose up -d --build
```
Running games are disconnected by the restart (the app says the connection to the relay broke off; players start a new room). Update when
nobody plays. The protocol version is checked when two players connect, so an old app against a new relay (or the
other way round) is told to update instead of misbehaving.

## Without compose

```bash
# from the repository root
docker build -f deploy/docker/Dockerfile -t klunki-relay .
docker run -d --name klunki-relay --restart unless-stopped \
  -p 127.0.0.1:4749:4749 -v "$PWD/deploy/docker/data:/data:ro" klunki-relay
```
Put any TLS reverse proxy in front (it must pass WebSocket upgrades on `/relay`). Plain `ws://` without TLS works
only for apps and for a PWA served over plain `http` (e.g. on your own network); a browser on an `https` page
(like the GitHub Pages beta) needs `wss://`.

Other commands of the same image: `docker run --rm klunki-relay relay-code new`,
`docker run --rm klunki-relay healthcheck 4749` (the image's HEALTHCHECK), and for an **open** relay without
codes (only on a private network) `docker run … klunki-relay relay --port 4749`.

**Serving the PWA too** (optional): build it (`cd klunki && flutter build web --release`, see `docs/BUILDING.md`
§6), mount `klunki/build/web` at `/web`, add `--web /web` to the command and let Caddy proxy every path (both are
commented in `compose.yaml` and `Caddyfile`). Then `https://relay.example.org/` is the game and its own relay.

## Privacy

- The relay **stores nothing**: no database, no files written (the container runs read-only), rooms live in memory
  and are gone after 10 minutes without a message, when the host leaves, or on restart.
- It **logs no codes and no addresses**: the log shows the labels from `codes.txt` (or a 6-character hash for a
  code without a label) when the file is loaded or changes, and nothing per connection (unless you add
  `--log-rooms` for a diagnosis: then room codes, times and close codes, still no names or addresses).
  `compose.yaml` keeps the container log small (1 MB, rotated).
- The club code travels in the WebSocket URL (`?create&club=…`). The provided Caddyfile has **no access log**, so
  Caddy does not store it either. If you turn on an access log, remove the `club` parameter from it (an example
  is in the Caddyfile).
- Game messages pass through the relay unchanged; over `wss://` nobody between the players and your server can
  read them, but the relay (you) technically could. It never looks at them.
- No accounts, no names, no analytics. Codes are compared in constant time.

## Limits and known gaps

- **Rate limit behind a proxy:** after 10 wrong codes from one address within 10 minutes that address is refused
  for the rest of the window. Behind Caddy every player has Caddy's address, so the limit is **shared**: someone
  guessing codes can lock everyone out for up to 10 minutes. (A follow-up could let the relay trust
  `X-Forwarded-For` from its own proxy.) Codes have about 40 bits, so guessing is hopeless either way.
- Up to 500 open rooms, frames up to 256 Ki characters, one guest per room (as `klunki relay`).
- Image digests are not pinned yet (`dart:3.13.7`, `caddy:2.10.2`): pin them with `@sha256:…` after the first
  pull if you want reproducible builds.
- The image has not been built by the project yet (see the status note at the top).

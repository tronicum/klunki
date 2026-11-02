# KLD-114: Relay packages: Docker image and Cloudflare Worker (prepared, not deployed)

- **ID:** `KLD-114`
- **Title:** Ready-to-use packages of the relay for a friend club: a Docker image (with Caddy for `wss://`) and a
  Cloudflare Worker port (Durable Objects, hibernation), both with club codes (KLD-112)
- **Milestone:** Backlog (the in-app server option is "in Vorbereitung")
- **Status:** PREPARED / WIP: files complete and tested locally; **the first real image build and the first
  Cloudflare deployment need the maintainer's OK** (nothing was built with Docker, nothing deployed, nothing
  downloaded)
- **Depends on:** KLD-051 (design notes "Later: self-hosted club server", Cloudflare assessment), KLD-057a (relay),
  KLD-112 (club codes)
- **Touched paths:**
  - `deploy/docker/**` (new: `Dockerfile`, `Dockerfile.dockerignore`, `compose.yaml`, `Caddyfile`, `README.md`,
    `relay/` = entry point package with `healthcheck`, `relay/tool/check_relay.dart`)
  - `deploy/cloudflare/**` (new: `src/{index,relay,room,protocol}.js`, `wrangler.toml`, `package.json`,
    `README.md`, `test/*.js`, `tool/new-club-code.js`)
  - `packages/klunki_net/test/relay_vectors.json`, `packages/klunki_net/test/relay_vectors_test.dart` (new: shared
    protocol vectors), `packages/klunki_net/PROTOCOL.md` (a note in "Relay")
  - `docs/tasks/KLD-051-internet-relay.md` (pointer), `docs/BUILDING.md` (§6.3 pointer), `docs/tasks/BOARD.md`,
    `AGENTS.md` (repo layout line)

## Goal
Someone who wants a relay for family and friends finds two ready-made ways, each with a step-by-step README:
1. **Docker:** `docker compose up -d` on a small server: the AOT-compiled `klunki relay --codes /data/codes.txt`
   in a minimal image, Caddy in front for automatic TLS (`wss://`).
2. **Cloudflare:** `npx wrangler deploy` to their own account (Free plan): a JavaScript port of the relay
   protocol, one Durable Object per room, club codes from a Worker secret.

No relay code in `packages/klunki_net` changed; the protocol is unchanged (`protocolVersion` 3, no fingerprint
change).

## Decisions
- **Docker entry point** is a tiny package `deploy/docker/relay/` (path dependency on `klunki_net`, no
  dev_dependencies) whose `main` is the normal CLI plus `healthcheck [PORT]` (GET `/relay` must answer 426),
  because the `scratch` runtime has no shell or curl. `dart pub get --offline` resolves it with an empty pub
  cache, so the image build downloads nothing but the base images.
- **Runtime image:** `scratch` + the Dart image's `/runtime/` (Dart's documented way for AOT binaries), user
  65532, `EXPOSE 4749`, `HEALTHCHECK`, codes **required by default** (`CMD relay --port 4749 --codes
  /data/codes.txt`); an open relay is an explicit command override. No web assets in the image; `--web /web`
  with a mounted build is optional.
- **Mount the directory** `./data:/data:ro`, not the file: a single-file bind mount keeps the old inode when an
  editor saves by renaming, so a deleted line would not revoke.
- **Caddy:** `handle /relay*` → `reverse_proxy relay:4749`, no access log (the club code is in the query); an
  example log filter that deletes `club` is commented in.
- **Worker structure:** the Worker refuses (path 404, no upgrade 426, Origin 403, club codes `relay.error`)
  **before** any Durable Object is touched (a test counts the object fetches), then sends create/join to the
  object named by the room code with internal headers and a fixed internal URL (the club code never reaches the
  object). A create whose drawn code is in use (409) draws again, up to 8 times.
- **Hibernation:** `RelayRoom` keeps no state in memory: roles are socket tags, the room code / last activity /
  "gone" flag are socket attachments, idle expiry is a storage alarm (rescheduled from the host's last activity,
  so there is no storage write per message). The tests evict every object after every step.
- **No `setWebSocketAutoResponse`:** the keepalive (`ping`/`pong`) is a game message between host and guest and
  detects a lost *player*; a relay answering it would hide a vanished peer and swallow the ping. Waiting rooms
  sleep anyway; running games stay awake (one game hour = one room hour of the 29 h/day Free plan duration). What
  a relay-level keepalive would need (client, Dart relay and PROTOCOL.md changes) is in
  `deploy/cloudflare/README.md`; not worth it now.
- **Club codes in the Worker:** secret `CLUB_CODES`, same format as the codes file; unset = open, set but empty =
  nobody. SHA-256 digests compared over every entry without early exit (as in Dart). Wrong-code limit 10 per
  address per 10 min per isolate (best effort), keyed by `CF-Connecting-IP`.
- **Shared vectors:** `packages/klunki_net/test/relay_vectors.json` (normalisation, control-line parsing, codes
  file, and 11 scenarios: create/join/forward/rejoin/kick, room full, unknown/invalid codes, bad request, host
  leaves, guest control lines, host control lines, frame cap guest/host, binary frames, open relay ignores
  `club`, gated relay incl. "same answer whether a room exists"). The Dart relay runs them over real sockets
  (`relay_vectors_test.dart`), the Worker on the fake runtime (`test/vectors.test.js`). Dart is the reference.
- **CI:** unchanged. CI has no Node setup step, and adding one would download Node; the Dart vectors test runs in
  the existing `klunki_net` job. The Node tests are documented (`node --test test/` in `deploy/cloudflare`).

## Acceptance criteria
- [x] `deploy/docker/Dockerfile`: multi-stage, `dart:3.13.7` build stage with `dart compile exe`, `scratch` +
      `/runtime/` runtime, non-root, `EXPOSE`, `HEALTHCHECK`, `/data/codes.txt` volume, optional `--web`.
- [x] `compose.yaml` with Caddy (automatic TLS), `Caddyfile`, `Dockerfile.dockerignore`, `README.md` (codes with
      `relay-code new`, start, check, revoke by deleting a line, update, privacy).
- [x] `deploy/cloudflare`: Worker + `RelayRoom` Durable Object on the Hibernation API; room codes, create/join,
      forwarding, kick, rejoin, idle expiry, frame cap, binary refusal, Origin allow-list, `CLUB_CODES` secret
      (constant time), same `relay.error` texts/codes and close codes, refusal before room lookup.
- [x] `wrangler.toml` template (binding, `new_sqlite_classes` migration, logs off), `README.md` (deploy it
      yourself, Free plan limits, secret, revoke, keepalive/auto-response analysis, differences, privacy).
- [x] `node --test` with a hand-written fake runtime, incl. the shared vectors (with and without hibernation).
- [x] Dart side of the vectors green; existing `klunki_net` tests green.
- [ ] 🧑 First real `docker compose build` / run, and a first `wrangler deploy` to a test account, with
      `tool/check_relay.dart` against both (needs the maintainer's OK: downloads images / wrangler, account).

## What was verified (2026-11-02, without Docker and without Cloudflare)
- The image's build commands, outside Docker: the context the `.dockerignore` lets through (the two packages
  without `test/`, `deploy/docker/relay`) copied to a temp dir, `dart pub get --offline` with an **empty pub
  cache**, `dart compile exe bin/relay.dart -o /out/klunki`: OK (macOS arm64 binary, ~7.9 MB). This found a bug:
  `dart compile exe` does not create the output directory, so the `RUN` line now creates `/out` first.
- Smoke test of that binary: `relay --port 47611 --codes codes.txt` (codes from `relay-code new`), then
  `healthcheck 47611` → 0 (and → 1 with nothing listening), `tool/check_relay.dart ws://127.0.0.1:47611/relay
  CODE`: missing code → `club-missing`, wrong code → `club-wrong` (create and join), room opened, joined, lines
  forwarded both ways unchanged, `relay.left` → OK. Then the line deleted from the file → the same code refused
  (`club-wrong`) without restart. The log showed labels / hashes only, never the code. SIGTERM → "Relay
  stopped." (`docker stop` sends SIGTERM).
- `cd deploy/docker/relay && dart analyze --fatal-infos`: no issues.
- `cd deploy/cloudflare && node --test test/` (Node 26.12.1): 42 tests green; a deliberately broken
  `room.js` (wrong close reason, kicked guest not marked) made the vector tests fail, so they bite.
- `packages/klunki_net`: `dart analyze --fatal-infos`, `dart test` green, incl. the new `relay_vectors_test.dart`.

## What was NOT verified
- No `docker build` (no Docker on the machine, and pulling images needs the OK): that `/runtime/` of `dart:3.13.7`
  is enough for this binary in `scratch`, `COPY --chown` of `/data`, `read_only: true`, the HEALTHCHECK in
  practice, Caddy 2.10.2 with this Caddyfile (incl. the commented log filter syntax), IPv6 inside the container
  (the relay falls back to IPv4).
- No Cloudflare run: the real runtime's behaviour around `Response` 101 with a pre-closed refusal socket, close
  handshakes in `webSocketClose`, `getWebSockets` after close, alarms, secrets restarting objects, actual Free
  plan accounting. The fake is deliberately pessimistic (async delivery, close echoes reported twice, eviction
  after every step) but it is not workerd.

## Open questions (🧑)
- OK for a first real Docker build and a test deployment on a Cloudflare account (which one)?
- Behind Caddy the wrong-code limit is shared by every player (all have Caddy's address): a stranger could lock
  the club out for 10 minutes. Follow-up: `klunki relay --trust-proxy` reading `X-Forwarded-For` from the proxy?
- Should the app's relay dialog link to these READMEs once the server option leaves "in Vorbereitung"?
- Publish a prebuilt image (e.g. GHCR from CI) later? Not done: publishing needs the OK.

## Definition of done
```bash
(cd packages/klunki_net && dart pub get --offline && dart analyze --fatal-infos && dart test)
(cd deploy/docker/relay && dart pub get --offline && dart analyze --fatal-infos)
(cd deploy/cloudflare && node --test test/)
```

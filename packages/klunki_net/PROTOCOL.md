# Klunki network protocol, version 1

Two devices, one connection (TCP or WebSocket). The **host** owns the
authoritative engine and move log; the **guest** runs the same engine (from
`GameConfig` via `createGame`) but applies only moves the host has accepted,
in log order.

## Transports and framing
The messages and rules below are identical on both transports; only the
framing differs. The host accepts both at the same time, on two ports.

| transport | default port | framing | who uses it |
|---|---|---|---|
| TCP | 4747 (`defaultTcpPort`) | UTF-8 text, **one JSON object per line**, terminated by `\n`; empty lines are ignored | apps (iOS/Android), the `klunki` CLI |
| WebSocket (`ws://host:port`, RFC 6455) | 4748 (`defaultWebSocketPort`) | **one JSON object per text frame**; a binary frame is a protocol error (`error "malformed input (binary frame)"`) | the browser PWA, `klunki join ws://…` |

- Every message has `type` (string) and `v` (int, protocol version = `1`).
- Anything else (invalid UTF-8, not JSON, not an object, no `type`, `v != 1`,
  an unknown or unexpected `type`, wrongly typed fields) is a protocol error:
  the receiver sends `error` and closes the connection.
- The WebSocket port speaks plain HTTP/1.1 only for the upgrade: any request
  without `Upgrade: websocket` gets `426 Upgrade Required`. Any path is
  accepted; no subprotocol is negotiated. WebSocket-level ping/close frames
  are left to the WebSocket stack; keepalive and `bye` are the protocol's own
  messages, as on TCP.
- Plain `ws://` (no TLS) on the local network: the PWA is served over plain
  http on the LAN, and browsers allow `ws://` from an `http://` page.

**Why a second port and not sniffing on one port.** Sniffing the first bytes
(`GET ` = HTTP upgrade) would mean consuming bytes from a `dart:io` `Socket`
and then handing the socket to `HttpServer` / `WebSocket.fromUpgradedSocket`.
`dart:io` cannot "un-read" bytes, and a `Socket` stream can be listened to
only once, so that needs a hand-written `Socket` wrapper that replays the
sniffed prefix, or a hand-rolled HTTP upgrade parser. A second port uses
`HttpServer.bind` + `WebSocketTransformer.upgrade` exactly as documented,
keeps the TCP path byte-for-byte unchanged for existing apps, and costs one
extra number that the join payload and mDNS record carry anyway (`w=`, `ws`).

**Advertising the WebSocket port** (app side, `klunki/lib/net/`):
- join payload / QR: optional `w` parameter,
  `klunki://join?h=192.168.1.20&p=4747&v=1&n=iPad&g=muehle&w=4748`;
- mDNS TXT record of `_klunki._tcp`: optional key `ws` (`"4748"`).

Both are optional and ignored by older clients, so the payload stays backward
compatible; a host without WebSocket support simply omits them.

## Messages

| type | direction | fields | meaning |
|---|---|---|---|
| `hello` | guest → host | `role: "guest"`, `name` (player name), `protocol: 1`, `token?` | first message on a connection; `token` only when rejoining |
| `hello` | host → guest | `role: "host"`, `name` (player name), `protocol: 1` | reply to the guest's `hello` |
| `welcome` | host → guest | `config` (`{game, seed}` = `GameConfig.toJson()`), `you` (`"a"`/`"b"`), `moves` (array of move objects), `token`, `host` (host's player name) | snapshot: guest's player + full accepted log |
| `move` | guest → host | `index` (int), `move` (object) | `index` = the position the move would take in the log |
| `accepted` | host → guest | `index`, `player` (`"a"`/`"b"`), `move` | a move entered the log (guest's or host's) |
| `rejected` | host → guest | `index`, `reason` | the guest's move was refused; nothing changed |
| `ping` / `pong` | both | – | keepalive; `ping` is answered with `pong` |
| `bye` | both | `reason` | polite end of the connection |
| `error` | both | `message` | protocol error; the sender closes the connection |

Example session (Four in a Row, host = A):

```
G→H {"type":"hello","v":1,"role":"guest","name":"Bea","protocol":1}
H→G {"type":"hello","v":1,"role":"host","name":"Host","protocol":1}
H→G {"type":"welcome","v":1,"config":{"game":"connect4","seed":0},"you":"b","moves":[],"token":"9f…","host":"Host"}
H→G {"type":"accepted","v":1,"index":0,"player":"a","move":{"col":3}}
G→H {"type":"move","v":1,"index":1,"move":{"col":4}}
H→G {"type":"accepted","v":1,"index":1,"player":"b","move":{"col":4}}
G→H {"type":"move","v":1,"index":2,"move":{"col":5}}
H→G {"type":"rejected","v":1,"index":2,"reason":"not your turn"}
```

## Player names (KLD-056)

Both sides already learn each other's name in protocol v1, no new field was
needed: the guest sends its name as `name` in its `hello`; the host sends its
own as `name` in its `hello` and again as `host` in `welcome`. The apps use
the user's player name (handle) here, not a device name. Names are display
text only; nothing but the rejoin rule below compares them.

Names are untrusted input. Both sides clean what they send and what they
receive with the same rules (`sanitizePlayerName` in this package, also used
by the app when the user types a name):

- any script; whitespace of any kind becomes one space, trimmed at both ends;
- control characters (C0, DEL, C1), bidi controls (U+061C, U+200E/F,
  U+202A–U+202E, U+2066–U+2069), U+FEFF, lone surrogates and U+FFFE/U+FFFF
  are dropped (ZWJ/ZWNJ stay);
- at most 20 code points.

A name that is missing, not a string or empty after cleaning is replaced by
the player's mark: `"X"` for A, `"O"` for B (host: for the guest's name;
guest: for the host's name, once `welcome` told it its own player). The
reconnecting guest sends the same name again, so names survive a reconnect.
The mDNS TXT key `n` and the join payload's `n=` carry the host's (cleaned)
player name too.

## Rules

**Handshake.** The guest sends `hello`; the host answers `hello` + `welcome`.
The host chooses the players (default host = A, guest = B). The first guest to
join gets a random `token`. Later connections are let in only with that token
or the same (cleaned) `name`; they replace a stale connection of the same guest. Anyone
else gets `error "session full"`.

**Moves.** For `move {index, move}` the host checks, in order:

1. `index < log length`: if the log already holds this exact move by the guest
   at `index` (a resend), the host repeats `accepted` for it; otherwise
   `rejected "stale index …"`.
2. `index > log length`: `rejected "index ahead …"`.
3. game over → `"game is over"`; not the guest's turn → `"not your turn"`;
   engine refuses (or the move is malformed for the game) → `"illegal move"`.
4. Otherwise the host applies the move, appends it and sends `accepted`.

Host moves go through steps 3–4 locally and are sent as `accepted`. Moves are
normalised through JSON on the host, so both logs hold identical maps.

**Guest.** Applies `accepted` only when `index == local log length` (it ignores
lower indices = duplicates; a higher index is a gap → `error`). If an accepted
move does not apply locally, the states diverged → `error` and close; the guest
can reconnect to resync.

**Keepalive.** Each side sends `ping` every `pingInterval` (default 2 s). Every
received line counts as a sign of life; after `timeout` (default 10 s) of
silence the connection is closed and reported as timed out. A connection must
also send `hello` within `timeout`.

**Reconnect.** The guest connects again and sends `hello` with its `token`. It
receives a fresh `welcome`, checks that its own log is a prefix of `moves`
(the host only ever appends), rebuilds the game with
`replay(config, moves)` and continues. A non-prefix log or a snapshot that
does not replay (`replay` returns null) is a divergence → `error`.

## Relay (KLD-057a): browser vs browser

A web page cannot listen for connections, so two browsers meet through a
**relay** (`klunki relay`, `package:klunki_net/relay_server.dart`). The relay
pairs one host and one guest by a short **room code** and forwards their
messages **unchanged**. It runs no game logic: the host stays authoritative
and runs the same session code as on a direct connection, and everything in
"Messages" and "Rules" above applies end to end.

```
host (browser A)                relay                     guest (browser B)
  │ WS /relay?create  ───────────►│
  │◄── {"t":"relay.room","code":"K7Q2M"}
  │                               │◄────────── WS /relay?join=k7q2m
  │◄── {"t":"relay.peer"}         │
  │◄─────────── hello ────────────┼─────────── hello (guest → host)
  │──── hello, welcome, … ────────┼──────────►  (forwarded byte for byte)
```

**Endpoint.** One WebSocket path, `/relay`, on the relay's port (default
4749, `defaultRelayPort`; `klunki relay --port N`). One message per text
frame, as on the WebSocket transport. A plain HTTP request to `/relay` gets
`426 Upgrade Required`. With `--web DIR` the same server serves the built PWA
on every other path, so a PWA served by the relay finds it at
`ws://<location.host>/relay` (`relayUriForPage(Uri.base)`).

| query | who | effect |
|---|---|---|
| `?create` | host | opens a room; the relay answers `relay.room` |
| `?join=CODE` | guest | joins room `CODE` (case-insensitive; spaces and dashes ignored) |

**Control messages.** Relay control messages are JSON objects with a `t` key
(never `type`) whose value starts with `relay.`; game messages always have
`type`, so the two cannot be confused. They are only exchanged between the
relay and a client, never forwarded.

| `t` | direction | fields | meaning |
|---|---|---|---|
| `relay.room` | relay → host | `code` | the room exists; show `code` to the user |
| `relay.peer` | relay → host | – | a guest joined; its game messages follow |
| `relay.left` | relay → host | `reason` | the guest's connection ended; the room stays open, a guest may join again with the same code (reconnect with the token, as usual) |
| `relay.closed` | relay → host, guest | `reason` | the room is gone (`host left`, `room expired (idle)`, `host broke the relay rules`, `relay shutting down`); the relay closes the connection right after |
| `relay.error` | relay → anyone | `message` | refused or rule broken: `no room with code …`, `room … is full`, `too many rooms, try again later`, `bad request: …`, `line too long (max N characters)`, `binary frames are not relayed`, `relay control messages are not allowed from a guest`; the relay closes that connection right after |
| `relay.kick` | host → relay | – | drop the current guest (the host session closed it, e.g. after `error "session full"`); lines sent before it are delivered first; no `relay.left` follows |

**Rules.**
- **Codes:** 5 characters from `23456789ABCDEFGHJKMNPQRSTUVWXYZ` (no 0/O, 1/I/L;
  31^5 ≈ 28.6 million codes), random (`Random.secure`), unique among open rooms.
- **One guest per room.** A second guest gets `relay.error "room CODE is full"`.
  A guest whose connection silently died keeps its slot until the host session
  notices (keepalive timeout, 10 s) and kicks it, or the relay's WebSocket ping
  (every 20 s) detects it; then the guest can rejoin.
- **Guest leaves** (close, network loss, rule broken): the host gets
  `relay.left`, its session reports `PeerDisconnected`, the room stays open.
- **Host leaves:** the room is closed; the guest gets `relay.closed "host left"`
  and is disconnected. A polite host sends `bye` first, which is forwarded.
- **Idle expiry:** a room in which no frame was forwarded for 10 minutes
  (`idleTimeout`) is closed with `relay.closed "room expired (idle)"`. A
  running game never idles: keepalive `ping`s pass every 2 s.
- **Limits:** frames up to 256 Ki characters (`maxLineLength`); at most 500
  open rooms (`maxRooms`); text frames only. A guest breaking a rule loses
  its own connection; a host breaking one closes the room.
- The relay keeps no logs, names or addresses beyond the open connections.

**Clients** (web-safe, in `package:klunki_net/klunki_net.dart`):
- `KlunkiHost.startRelay(config, relayUrl, name: …)` connects with `?create`,
  completes with `host.roomCode` set, and treats every `relay.peer` as a new
  guest connection for the unchanged host session; closing that connection
  sends `relay.kick`. A lost room surfaces as `NetError("relay: …")`.
- `KlunkiGuest.connectRelay(relayUrl, code, name: …)` connects with
  `?join=CODE`; `relay.error` / `relay.closed` end the connection with the
  reason (`NetException("relay: no room with code …")`). `reconnect()` rejoins
  the same room.

## Known limitations (accepted for the PoC)
- **Hidden information is not hidden on the wire.** `welcome` carries the seed
  and the whole move log, so a modified client could reconstruct the
  opponent's Quartett hand or Schiffe fleet. The UI never shows it; per-player
  views are post-PoC.
- No encryption (`ws://`, not `wss://`); the token only prevents accidental
  takeovers. Local Wi-Fi only. The WebSocket port does not check `Origin`, so
  any web page the guest's browser opens could connect to a host it can
  reach on the LAN; acceptable for the PoC (one guest, local network).
- One guest per host, over either transport: a second guest gets
  `error "session full"` whether it comes over TCP or WebSocket. A joined
  guest may rejoin over the other transport with its token.
- Browser ↔ browser play needs a relay (see "Relay"): a web page cannot
  listen for connections. The relay sees all messages in clear text (`ws://`)
  and does not authenticate anyone: whoever knows the room code can take the
  guest slot while it is free. Meant for a relay on the local network.

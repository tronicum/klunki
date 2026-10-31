# Klunki network protocol, version 2

Two devices, one connection (TCP or WebSocket). The **host** owns the
authoritative engine and move log. For games without hidden information
(Four in a Row, Mühle) the **guest** runs the same engine (from `GameConfig`
via `createGame`) but applies only moves the host has accepted, in log order.
For hidden-information games (Quartett, Schiffe versenken, GoStrategy) the
host is the referee and the guest only ever receives what its player may
know; see "Hidden information" below.

Version 2 (KLD-064) added the hidden-information messages. Version 1 peers
are refused (see "Version mismatch").

## Transports and framing
The messages and rules below are identical on both transports; only the
framing differs. The host accepts both at the same time, on two ports.

| transport | default port | framing | who uses it |
|---|---|---|---|
| TCP | 4747 (`defaultTcpPort`) | UTF-8 text, **one JSON object per line**, terminated by `\n`; empty lines are ignored | apps (iOS/Android), the `klunki` CLI |
| WebSocket (`ws://host:port`, RFC 6455) | 4748 (`defaultWebSocketPort`) | **one JSON object per text frame**; a binary frame is a protocol error (`error "malformed input (binary frame)"`) | the browser PWA, `klunki join ws://…` |

- Every message has `type` (string) and `v` (int, protocol version = `2`).
- Anything else (invalid UTF-8, not JSON, not an object, no `type`, `v != 2`,
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
  `klunki://join?h=192.168.1.20&p=4747&v=2&n=iPad&g=muehle&w=4748`;
- mDNS TXT record of `_klunki._tcp`: optional key `ws` (`"4748"`).

Both are optional and ignored by older clients, so the payload stays backward
compatible; a host without WebSocket support simply omits them.

## Messages

| type | direction | fields | meaning |
|---|---|---|---|
| `hello` | guest → host | `role: "guest"`, `name` (player name), `protocol: 2`, `token?` | first message on a connection; `token` only when rejoining |
| `hello` | host → guest | `role: "host"`, `name` (player name), `protocol: 2` | reply to the guest's `hello` |
| `welcome` | host → guest | `config` (`{game, seed}` = `GameConfig.toJson()`), `you` (`"a"`/`"b"`), `moves` (array of move objects), `token`, `host` (host's player name) | snapshot: guest's player + full accepted log (games without hidden information) |
| `welcome` (redacted) | host → guest | `config` (`{game, seed}`; `{game}` only when the seed is secret), `you`, `token`, `host`, `redacted: true`, `seedCommit?`, `start`, `log` (array of steps), `view` | snapshot of a hidden-information game, see "Hidden information" |
| `move` | guest → host | `index` (int), `move` (object) | `index` = the position the move would take in the log |
| `accepted` | host → guest | `index`, `player` (`"a"`/`"b"`), `move` | a move entered the log (guest's or host's) |
| `accepted` (redacted) | host → guest | `index`, `player`, `move` (redacted), `event` (redacted), `view`, `commit?` | the same for a hidden-information game |
| `reveal` | host → guest | `seed?`, `seedSalt?`, `secrets` (array of `{index, move, salt}`) | hidden-information game over: the host's secrets, for the guest's check |
| `rejected` | host → guest | `index`, `reason` | the guest's move was refused; nothing changed |
| `ping` / `pong` | both | – | keepalive; `ping` is answered with `pong` |
| `bye` | both | `reason` | polite end of the connection |
| `error` | both | `message` | protocol error; the sender closes the connection |

Example session (Four in a Row, host = A):

```
G→H {"type":"hello","v":2,"role":"guest","name":"Bea","protocol":2}
H→G {"type":"hello","v":2,"role":"host","name":"Host","protocol":2}
H→G {"type":"welcome","v":2,"config":{"game":"connect4","seed":0},"you":"b","moves":[],"token":"9f…","host":"Host"}
H→G {"type":"accepted","v":2,"index":0,"player":"a","move":{"col":3}}
G→H {"type":"move","v":2,"index":1,"move":{"col":4}}
H→G {"type":"accepted","v":2,"index":1,"player":"b","move":{"col":4}}
G→H {"type":"move","v":2,"index":2,"move":{"col":5}}
H→G {"type":"rejected","v":2,"index":2,"reason":"not your turn"}
```

## Player names (KLD-056)

Both sides already learned each other's name in protocol v1, no new field was
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

**Version mismatch.** A peer speaking another version gets
`error "unsupported protocol version 1 (expected 2)"` for an envelope `v` of 1,
or `error "unsupported protocol 1"` for a `hello` with `protocol: 1`, and the
connection closes; `KlunkiGuest.connect…` throws a `NetException` with that
text. The apps compare the join payload's `v` and the mDNS `v` with their own
version first, so an old host shows up as incompatible before anyone connects.

## Hidden information (KLD-064)

Games with `GameSpec.redaction` (`quartett-trumpf`, `quartett-sets`,
`schiffe`, `gostrategy`). Connect4 and Mühle have nothing to hide and keep
the plain messages above.

**Roles.** The host runs the full engine and is the referee: it sees both
players' secrets (it has to, to judge shots and fights). The guest never
receives the host's secrets. Its own secret input (its setup) goes to the
host only; the host's answers to it carry nothing of the host's own data.

**What the guest gets per move** (`accepted`, redacted):
- `move`: the move as the guest may see it (`Redaction.redactMove`). The
  guest's own moves and public moves are unchanged; the host's secret moves
  are cut down to what is public:

  | game | host's move | guest sees |
  |---|---|---|
  | Schiffe | `{action: place, ship, row, col, dir}` | `{action: place, ship}` |
  | Schiffe | `{action: autoplace, seed}` | `{action: autoplace}` |
  | GoStrategy | `{action: setup, pieces}` / `{action: autosetup, seed}` | `{action: setup}` |
  | Quartett | `pick` / `ask` | unchanged (public) |

- `event`: `{winner?, draw?, payload}`, the engine's event as the guest may
  see it (`Redaction.redactPayload`). Shot results, fights (both ranks) and
  Trumpf tricks (both cards) are public. In Quartett (Sets) the card the
  host draws is replaced by `drew: true`.
- `view`: the guest's complete view of the game after the move, JSON
  (`SchiffeGame.viewJson` / `QuartettGame.viewJson` / `GoStrategyGame.viewJson`):

  | game | the view holds | it never holds |
  |---|---|---|
  | Schiffe | own fleet, shots at the guest, shot results on the host's ocean, the host's ship counts | any host ship square that was not hit |
  | GoStrategy | own pieces, owner of every piece, kinds of revealed pieces, `moved` flags, counters, remaining pieces per kind (public) | the kind of an unrevealed host piece |
  | Quartett (Trumpf) | own top card, stack sizes, pot, tricks | the host's cards, the order of any stack, the seed |
  | Quartett (Sets) | own hand, hand sizes, stock size, laid-down quartets | the host's hand, the stock, the seed |

  The guest turns it into a read-only game object (`Redaction.fromView`:
  `SchiffeView`, `QuartettView`, `GoStrategyView`, subclasses of the engine
  classes), so screens and text adapters render it unchanged. It cannot
  apply moves; the next `accepted` brings the next view.
- `commit`: only on a host move that hides something (the redacted `move`
  differs from the real one): the commitment to the real move (below).

**Snapshot** (`welcome`, redacted): `start` (hash of the guest's view before
the first move), `log` (one step per move: `{player, move, event, viewHash,
commit?}`), `view` (the current view; its hash must equal the last step's
`viewHash`, or `start` for an empty log), `seedCommit` for a secret seed.
On reconnect the guest checks that its steps are a prefix of `log`, as in
the plain protocol. `viewHash` is the first 128 bits of
SHA-256(`"klunki-view-v2\n"` + canonical JSON of the view), as hex. It
replaces a full state comparison: the guest cannot see the host's state, so
the redacted view is what both sides agree on, and it is checked at the end.

**Commitments.** For each secret of its own the host draws a fresh 16-byte
salt (`Random.secure`) and sends

    commit = hex SHA-256("klunki-commit-v2\n" + label + "\n" + salt + "\n" + canonicalJson(value))

- the seed, when it decides a hidden deal (Quartett): label `seed`, sent as
  `seedCommit` in `welcome`, before the first move; `config` then carries
  no seed;
- each secret host move (Schiffe placements, GoStrategy setup): label
  `move:<index>`, sent as `commit` with that move's `accepted`, i.e. before
  the guest's first shot or move against it.

Canonical JSON = map keys sorted at every level, no spaces. The salt makes
the commitment unguessable (there are only a few hundred placements per
ship); the hash makes it binding.

**Reveal and check.** When the game is over the host sends `reveal`:
`seed` + `seedSalt` (secret seed only) and `secrets`, one `{index, move, salt}`
per committed move (only the host's moves, never the guest's). It is also
sent right after the `welcome` of a guest that (re)joins a finished game.
The guest (`verifyRedactedGame`):
1. checks every commitment against the revealed value and salt, and that
   exactly the committed moves are revealed;
2. builds the full move list (revealed host moves, everything else as
   received) and replays it on a fresh engine from the (revealed) seed;
3. for every step compares the player, the redacted move, the redacted
   event and the hash of its view with what the host reported, and the
   start view with `start`;
4. requires the replayed game to be over.

Success emits `GameVerified`; any mismatch emits `VerificationFailed(reason)`
and the app shows "Spielverlauf konnte nicht bestätigt werden". During the
game the guest also checks what it can at once: each view must be its own
(`viewer`), parse, and the echo of its own move must be the move it sent.

**Threat model.**
- The host is trusted for secrecy: as the referee it sees the guest's setup
  and hand. A modified host app can show them to its player; nothing in the
  protocol prevents that.
- The guest is protected against outcome manipulation: a host that changes
  its fleet or setup after committing, deals from another seed, or
  misreports a hit, a fight or a trick is caught by the check at the end
  (not during the game). A host that never sends `reveal` (it quits or
  disconnects before the end) leaves the game unverified; the guest cannot
  tell that apart from a network loss.
- The host chooses the Quartett seed alone, so it could pick a deal it
  likes before the game starts (it cannot change it afterwards). A fair
  shuffle needs the guest's entropy too (open).
- A modified guest learns nothing beyond its view: the host's secrets are
  not on its device or on the wire before the reveal. The relay (and anyone
  on the unencrypted `ws://` link) sees the redacted host → guest messages,
  but the guest's own moves (its setup) in clear text.

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
- Hidden information is redacted since protocol 2 (see "Hidden
  information"), but the host, as referee, sees the guest's secrets, and the
  guest's check happens only at the end of the game.
- A redacted snapshot grows by about 120 bytes per move (plus the current
  view); very long GoStrategy games through a relay could approach the
  relay's 256 Ki frame limit after roughly 2000 moves.
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

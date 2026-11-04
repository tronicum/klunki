# Klunki network protocol, version 3

Two devices, one connection (TCP or WebSocket). The **host** owns the
authoritative engine and move log. For games without hidden information
(Four in a Row, Mühle, chess) the **guest** runs the same engine (from `GameConfig`
via `createGame`) but applies only moves the host has accepted, in log order.
For hidden-information games (Quartett, Schiffe versenken, GoStrategy) the
host is the referee and the guest only ever receives what its player may
know; see "Hidden information" below.

Version 2 (KLD-064) added the hidden-information messages. Version 3
(KLD-085) adds build fingerprints to both `hello`s, so two builds that
disagree about a game (protocol, rules, Quartett deck data) refuse each
other with a clear error instead of playing a diverging game. Version 1 and
2 peers are refused (see "Build compatibility").

## Transports and framing
The messages and rules below are identical on both transports; only the
framing differs. The host accepts both at the same time, on two ports.

| transport | default port | framing | who uses it |
|---|---|---|---|
| TCP | 4747 (`defaultTcpPort`) | UTF-8 text, **one JSON object per line**, terminated by `\n`; empty lines are ignored | apps (iOS/Android), the `klunki` CLI |
| WebSocket (`ws://host:port`, RFC 6455) | 4748 (`defaultWebSocketPort`) | **one JSON object per text frame**; a binary frame is a protocol error (`error "malformed input (binary frame)"`) | the browser PWA, `klunki join ws://…` |

- Every message has `type` (string) and `v` (int, protocol version = `3`).
- Anything else (invalid UTF-8, not JSON, not an object, no `type`, `v != 3`,
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
  `klunki://join?h=192.168.1.20&p=4747&v=3&n=iPad&g=muehle&w=4748`;
- mDNS TXT record of `_klunki._tcp`: optional key `ws` (`"4748"`).

Both are optional and ignored by older clients, so the payload stays backward
compatible; a host without WebSocket support simply omits them.

## Messages

| type | direction | fields | meaning |
|---|---|---|---|
| `hello` | guest → host | `role: "guest"`, `name` (player name), `protocol: 3`, `token?`, `build`, `games` | first message on a connection; `token` only when rejoining; `build` and `games`: see "Build compatibility" |
| `hello` | host → guest | `role: "host"`, `name` (player name), `protocol: 3`, `build`, `game`, `fingerprint` | reply to the guest's `hello`; `game` / `fingerprint`: the hosted game's key and fingerprint |
| `welcome` | host → guest | `config` (`{game, seed, deck?, tiles?, dict?, joker?, white?}` = `GameConfig.toJson()`; `deck` = Quartett deck id, KLD-069, absent = cars; `tiles` (`de`/`en`) and `dict: true` = Wortgewandt tile set and word list, KLD-094; `joker: true` = Wortgewandt house rule "Joker tauschen", KLD-094 step 9; `white: "b"` = in chess B plays White, KLD-059 step 4a, absent = A), `you` (`"a"`/`"b"`), `moves` (array of move objects), `token`, `host` (host's player name) | snapshot: guest's player + full accepted log (games without hidden information) |
| `welcome` (redacted) | host → guest | `config` (`{game, seed, deck?, tiles?, dict?}`; `{game, deck?, tiles?, dict?}` = `GameConfig.publicJson()` when the seed is secret: the options are public), `you`, `token`, `host`, `redacted: true`, `seedCommit?`, `start`, `log` (array of steps), `view` | snapshot of a hidden-information game, see "Hidden information" |
| `move` | guest → host | `index` (int), `move` (object) | `index` = the position the move would take in the log |
| `accepted` | host → guest | `index`, `player` (`"a"`/`"b"`), `move` | a move entered the log (guest's or host's) |
| `accepted` (redacted) | host → guest | `index`, `player`, `move` (redacted), `event` (redacted), `view`, `commit?` | the same for a hidden-information game |
| `reveal` | host → guest | `seed?`, `seedSalt?`, `secrets` (array of `{index, move, salt}`) | hidden-information game over: the host's secrets, for the guest's check |
| `rejected` | host → guest | `index`, `reason` | the guest's move was refused; nothing changed |
| `ping` / `pong` | both | – | keepalive; `ping` is answered with `pong` |
| `bye` | both | `reason` | polite end of the connection |
| `error` | both | `message`, `code?`, `protocol?`, `build?`, `name?`, `game?`, `fingerprint?` | protocol error; the sender closes the connection. `code` and the rest only for a refused handshake, see "Build compatibility" |

Example session (Four in a Row, host = A):

```
G→H {"type":"hello","v":3,"role":"guest","name":"Bea","protocol":3,"build":"1.0.0+1","games":{"connect4":{"rules":1,"rev":1,"content":"282f…"},…}}
H→G {"type":"hello","v":3,"role":"host","name":"Host","protocol":3,"build":"1.0.0+2026110201 abc1234","game":"connect4","fingerprint":{"rules":1,"rev":1,"content":"282f…"}}
H→G {"type":"welcome","v":3,"config":{"game":"connect4","seed":0},"you":"b","moves":[],"token":"9f…","host":"Host"}
H→G {"type":"accepted","v":3,"index":0,"player":"a","move":{"col":3}}
G→H {"type":"move","v":3,"index":1,"move":{"col":4}}
H→G {"type":"accepted","v":3,"index":1,"player":"b","move":{"col":4}}
G→H {"type":"move","v":3,"index":2,"move":{"col":5}}
H→G {"type":"rejected","v":3,"index":2,"reason":"not your turn"}
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
join gets a random `token`. Later connections are let in **only with that
token** (compared in constant time; KLD-071), whatever their `name`: names and
the default mark are public, so they never reclaim the seat. A connection with
the token replaces a stale connection of the same guest. Anyone else gets
`error "session full"` and the connected guest is not disturbed. A connection
that sends no `hello` within the host's handshake timeout is closed.

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

**Resign (KLD-065).** `{"action":"resign","player":"a"|"b"}` is an ordinary
move in every game: no new message type and no version bump of its own (it
shipped together with protocol 2). It is
the one move that may come from the player who is *not* to move (and during
setup phases), so "the guest's turn" in step 3 means `Game.playerOf(move)`:
the player the resign names, the player to move for anything else. A guest
can only resign for itself (`"player":"a"` from the guest → `"not your
turn"`). The engine ends the game at once ("game is over" for anything after
it); both sides attribute the `accepted` entry to the resigner, also when
replaying a `welcome` snapshot. In a hidden-information game (below) the
resign is public: its move and event (`{"resigned":"a"|"b"}`) are never
redacted, the guest's `view` carries `"resigned":"a"|"b"`, and the host sends
`reveal` right after it like after any last move, also during a setup phase
(moves never made have no commitment). The guest's end-of-game replay
attributes each step with `playerOf` as well.

**Chess (KLD-059 step 3).** Plain messages, no redaction. The host is A
and the guest B as in every game; who plays which colour is config (step
4a, below). A move is
`{"action":"move","from":"e2","to":"e4"}`; a pawn reaching the last rank
must carry `"promotion":"q"|"r"|"b"|"n"` (the host refuses it without one,
or with one on any other move: `"illegal move"`). All draws by rule
(stalemate, insufficient material, 75 moves, threefold repetition) are
automatic, so nobody claims anything. There are no clocks (a follow-up).

**Chess colours (KLD-059 step 4a).** The host chooses its colour when it
starts the room: White, Black or random. The seats do not change (host = A,
`you: "b"` for the guest); the config says who plays White: `"white": "b"`
in `config` (written only then; absent = A plays White, as before) makes B
White. White moves first, so with `white: "b"` the guest makes the first
move and the host's first own move is refused with `"not your turn"`. The
host resolves "random" before it creates the game (the apps and the CLI:
from the config's seed, even = the host plays White), so the config always
holds the result and both sides build the same game from it; a rejoining
guest gets the same config again. **No commitment:** the host could pick
its colour and call it random, and the guest cannot check that. That is
fine here: the colour is public as soon as the game starts, nothing is
hidden afterwards, and the host could simply have chosen the colour
openly. Resign and the draw offer moves name players (`"a"`/`"b"`), not
colours, so they are unchanged. No protocol bump: the new key is
config, and chess rules version 3 (KLD-085 fingerprint) makes a build
that ignores `white` (rules 2, which would play a diverging game) refuse
with `incompatible-rules`.

**Chess draw offer.** Three ordinary moves that, like a resign, name their
player (`playerOf` = the named player; the guest only for itself, else
`"not your turn"`); the answer comes from the player who is not to move:

| move | allowed when | effect |
|---|---|---|
| `{"action":"offerDraw","player":p}` | `p` is to move, no offer is open and `p` has not offered in this position (a board move must come between two offers of one player) | the offer is open; the turn does not change, and `p` cannot make a board move until it is answered |
| `{"action":"acceptDraw","player":q}` | `q`'s opponent has an open offer | the game ends drawn, reason `chess.drawAgreed` |
| `{"action":"declineDraw","player":q}` | `q`'s opponent has an open offer | the offer is gone, play goes on |

Anything else is `"illegal move"`. Because the offerer waits, the answer
is the only move that can follow an offer (besides a resign): no board move
can cross an answer in flight and make it a stale index. The offer lives in the move log only, so a rejoining guest's
`welcome` replay restores it. No new message type and no protocol version
bump: the moves arrived with chess rules version 2 (KLD-085 fingerprint),
so a build with chess rules 1 is refused with `incompatible-rules` instead
of meeting a move it does not know.

**Guest.** Applies `accepted` only when `index == local log length` (it ignores
lower indices = duplicates; a higher index is a gap → `error`). If an accepted
move does not apply locally, the states diverged → `error` and close; the guest
can reconnect to resync.

**Keepalive.** Each side sends `ping` every `pingInterval` (default 2 s). Every
received line counts as a sign of life; after `timeout` (default 10 s) of
silence the connection is closed and reported as timed out. Only silence while
the side could read counts (KLD-109): when its keepalive timer fires late (the
process was stalled: a long frame, no CPU, a sleeping machine, an app resumed
from the background), the time it was late does not count towards `timeout`:
the other side's messages were waiting unread meanwhile. Nothing changes on
the wire. A connection must also send `hello` within
`timeout`.

**Reconnect.** The guest connects again and sends `hello` with its `token`. It
receives a fresh `welcome`, checks that its own log is a prefix of `moves`
(the host only ever appends), rebuilds the game with
`replay(config, moves)` and continues. A non-prefix log or a snapshot that
does not replay (`replay` returns null) is a divergence → `error`.

**Version mismatch.** See "Build compatibility" below. The apps also compare
the join payload's `v` and the mDNS `v` with their own version first, so an
old host shows up as incompatible before anyone connects.

## Build compatibility (KLD-085)

Two devices may run different builds: an iPhone on a new build and a
browser with a cached older PWA. With Quartett the decks can then differ
(other cards or stats), and a game would silently diverge. So the
handshake compares what both builds know about the game, and refuses a
mismatch with a specific `code`.

**Fingerprint** (`package:klunki_engine`'s `compat.dart`), per game and
deck, keyed by `compatKey`: the game id, plus `/deck` for a game with a
deck (`quartett-trumpf/rockets`; no deck = the default `cars`). The seed
does not matter.

| field | what | changes when |
|---|---|---|
| `rules` | `GameSpec.rulesVersion` | bumped by hand on a breaking rule change (a move one build accepts and the other refuses, another deal from the same seed, a changed move or view format) |
| `rev` | `QuartettDeck.revision` (1 for games without a deck) | bumped by hand when deck data changes |
| `content` | first 128 bits of SHA-256(`"klunki-content-v1\n"` + JSON of the game id and, for Quartett, the deck's id, stat ids in order with `higherWins`, and every card's id, set, name and values), hex | automatically, whenever that data changes (so a forgotten bump is still caught) |

Values are written as text (whole numbers without a decimal point) so the
VM and the browser hash the same bytes. Presentation is not part of it:
stat labels, units, number formats, set and deck names, and the app's card
photos, Wikipedia links and image credits. A build that only adds photos
stays compatible. `dart run tool/print_fingerprints.dart` (in the engine)
prints the current values; `test/compat_test.dart` keeps golden values.

**`build`** is the app's version label, `VERSION+BUILD COMMIT`
(KLD-116): `1.0.0+2026110201 b8752a9` is version `1.0.0` from
`pubspec.yaml`, build number `2026110201` (`YYYYMMDDNN`, set by CI; `1` in
local builds) and the commit from `--dart-define=KLUNKI_BUILD=…` (left out
when the build has none). Builds before KLD-116 sent `1.0.0+1 abc1234`, the
same shape. The CLI sends an empty label. It decides nothing; it only tells
which side is older when the fingerprints do not (same `rules` and `rev`,
other `content`), and the apps show it to people as `1.0.0 (b8752a9)`
(`versionDisplay`; `1.0.0 (dev)` without a commit): in the menu footer, on
the About screen (with the build number, the protocol and a short code over
all fingerprints in small print, `catalogFingerprint`) and in the mismatch
message, for both devices ("Anna hat 1.0.0 (b8752a9), Ben hat 1.1.0
(c3d4e5f)."). The app version itself never decides compatibility.

**The checks.**
1. *Envelope.* A message whose `v` is not `3` closes the connection. The
   answer is `error {code: "incompatible-protocol", protocol: 3, build,
   message}` sent **in the peer's own envelope version** (`v` = the peer's
   `v`): a protocol 2 build reads it as a normal `error` and shows its
   English `message` ("incompatible versions: the other device runs a newer
   Klunki (protocol 3, this one 2) – please update this app (browser: reload
   the page)"). An `error` that arrives in another envelope version (an old
   host refusing our `v`: `"unsupported protocol version 3 (expected 2)"`)
   is read, not answered, and reported as a protocol mismatch.
2. *Host, on the guest's `hello`*, before the seat check (an incompatible
   guest never gets `session full`): `protocol` must be 3 and `games` must be
   an object, else `incompatible-protocol`. **Missing fields are a mismatch,
   never "compatible"**: builds before KLD-085 send none. Then the guest's
   entry for the hosted game's key is compared with the host's own:
   missing → `incompatible-content`; other `rules` → `incompatible-rules`;
   other `rev` or `content` → `incompatible-content`.
   The host answers `error {code, message, protocol, build, name, game,
   fingerprint}` (its own key and fingerprint, so the guest can work out
   which side is older; `name` is the host's player name, KLD-116), closes, emits `IncompatiblePeer` and keeps waiting
   for another guest.
3. *Guest, on `welcome`*: the host's `hello` must have carried `game` and
   `fingerprint`, `game` must equal the key of the `config` in `welcome`
   (the deck the host actually deals), and the fingerprint must equal the
   guest's own for that key (an unknown game or deck is `incompatible-content`).
   Otherwise the guest sends `error {code, …, name}` and fails the join. This
   protects against an old or wrong host; with two current builds check 2
   already caught any difference.

**Codes** (`Incompatibility`): `incompatible-protocol`, `incompatible-rules`,
`incompatible-content`. A failed join throws `NetException` with `mismatch`
(`VersionMismatch {kind, peer, peerBuild, detail}`); `peer` is `older`,
`newer` or `unknown` from the receiver's point of view, decided by the
protocol number, then `rules`, then `rev`, then the `build` label (first
`major.minor.patch+build` numbers). `VersionMismatch` also carries both
sides' build labels and, where known, both player names (`myBuild`,
`myName`, `peerBuild`, `peerName`; KLD-116): the guest knows the host's name
from its `hello` or from the refusing `error`'s `name`, the host the
guest's from its `hello`. `name` in `error` is informational and optional:
older builds ignore it and send none (then the app says "das andere
Gerät"), so it needs no protocol version. The app maps it to "Die Spielversionen
passen nicht zusammen: Das andere Gerät hat eine ältere Version. Bitte dort
die App aktualisieren (Browser: neu laden)." (or "Dieses Gerät …" / "bitte
beide Apps aktualisieren"); the host's waiting screen says that a device was
turned away.

**Why a version bump (3) and not optional fields.** Optional fields would
let a protocol 2 build join a new host, and a new guest join an old host,
exactly the silent mismatch this is about. With `v = 3` every protocol 2
build fails the envelope check on both sides, in both directions:

| new side | old side (protocol 2) | what happens |
|---|---|---|
| host | guest | the old guest's `hello` (v 2) is refused with an `error` in v 2; the old app shows "Verbindung … fehlgeschlagen: peer error: incompatible versions: … please update this app (browser: reload the page)"; the new host shows that a device with an older version was turned away |
| guest | host | the old host answers the v 3 `hello` with its own `error "unsupported protocol version 3 (expected 2)"` (v 2); the new guest reports a protocol mismatch, the other device older |
| either | either, through the relay | the same: the relay forwards unchanged |

Future changes to a game's rules or data need no new protocol version: bump
`rulesVersion` / `revision` (the content hash changes by itself).

## Hidden information (KLD-064)

Games with `GameSpec.redaction` (`quartett-trumpf`, `quartett-sets`,
`schiffe`, `gostrategy`, `wordtiles`). Connect4, Mühle and chess have nothing to hide and
keep the plain messages above.

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
  | Quartett (Trumpf, KLD-100) | `choose` (card) | `{"action": "choose"}` (the card shows in the round's payload) |

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
  | Quartett (Trumpf) | own top card (with 2–3 cards: own whole stack and own choice, KLD-100), stack sizes, pot, tricks, an announced stat | the host's cards and choice, the order of any stack, the seed |
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

### Wortgewandt (`wordtiles`, KLD-094 step 6)

- **Config.** The host chooses the tile set (`tiles`: `de`/`en`) and the
  word list (`dict: true`, "Wörterbuch prüfen"); both travel in the
  `welcome` `config` (`publicJson`, the seed is secret and committed as
  `seedCommit`). The guest builds the same `GameConfig` from them.
- **"Joker tauschen" (KLD-094 step 9, rules 4).** The host may turn on the
  house rule: `joker: true` in the `welcome` `config` (written only when on).
  Then a `place` (and a `requestAllow`) may carry `swaps: [{row, col,
  tile}, …]`: before the tiles are laid, the real letter `tile` from the
  mover's rack replaces the blank on that square and the blank joins the
  rack. Always together with tiles; refused without the option. Public like
  the rest of a placement (the board change shows it anyway); the view says
  `jokerSwap: true`, its turn log `swaps: n`, an open `allowRequest` its
  `swaps`.
- **Fingerprint.** Rules version 4 (3 before "Joker tauschen"). The content hash covers the tile sets,
  the board layout and `WordLists.revisions`: per language the list's source
  and the SHA-256 of the bundled `words.txt.gz`. Builds with different lists
  (or rules 2) refuse each other (`incompatible-content` / `-rules`). The
  guest does not need the list loaded to join; the app loads it right after
  (the host checks every placement anyway).
- **Secrecy.** The view holds the guest's own rack, the rack sizes, the bag
  size (a number), the board, scores and the public turn log; never the
  host's rack, the bag order or the seed. A host `exchange` reaches the
  guest as `{action: exchange, count}` with a `commit`; placements, passes
  and challenges are public. At the end `reveal` brings the seed and the
  exchanged tiles; the guest replays the game (`verifyRedactedGame` with the
  config's `tiles`, `dict` and `joker`).
- **"Trotzdem zulassen" (dictionary mode).** The word check runs locally at
  "Legen" (no round trip); "Zurücknehmen" is local too. Letting a word the
  list lacks count needs the other player:

  | move | by | effect |
  |---|---|---|
  | `{action: requestAllow, player, tiles, allow}` | the player on turn | opens the request: the tiles lie on the board (public), nobody else may move; at most one open request |
  | `{action: acceptAllow, player}` | the other player | the placement counts with `allowed` = `allow`; the turn passes |
  | `{action: declineAllow, player}` | the other player | the tiles go back; still the placer's turn; the same words cannot be asked again this turn |

  `player` names the mover (like the chess draw offer), so the answer is
  accepted from the player who is not on turn. A `place` with `allow` is
  refused (rules 3): the host only lets a word stand that the other player
  agreed to. An open request is part of the view (`allowRequest`), so a
  guest that rejoins sees it again (and its answer dialog). One leak is
  inherent: a declined request shows those tiles of the placer's rack.
- **Without the word list** the challenge flow ("Anzweifeln" /
  "Akzeptieren") runs over the network unchanged: the next player answers
  on their own device.
- The CLI (`klunki host wordtiles`) has no flags for `tiles` / `dict` yet.
- **3–4 players (KLD-088 step 1): not on the wire yet.** `GameConfig` has a
  `players` key (written only when not 2; absent = 2), but a session is host
  + one guest: `KlunkiHost.start` / `startRelay` refuse a config with
  `players` other than 2 (`ArgumentError`), and a guest refuses such a
  `welcome` (an older guest would ignore the key and build a 2-player game).
  The n-player protocol (lobby with seats, per-seat redaction and
  commitments) is planned in `docs/tasks/KLD-088-more-players.md`; it will
  bump `protocolVersion`.

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
- **Keepalive is end to end:** `ping` / `pong` are game messages between host and
  guest, and a relay must forward them like any other line. A relay that
  answered them itself (e.g. a Cloudflare WebSocket auto-response) would hide
  a lost player from the other side (KLD-114).
- **Implementations:** this Dart relay (the reference) and a Cloudflare Worker
  port (`deploy/cloudflare`, KLD-114, prepared). Both are tested against the
  same vectors, `test/relay_vectors.json` (`relay_vectors_test.dart` here).
  The Worker's wrong-code limit counts per client address as Cloudflare
  reports it (`CF-Connecting-IP`), per isolate.

### Club codes (KLD-112): a gated relay

A relay started with `klunki relay --codes FILE` admits only clients that
send a current **club code** (server access code; for a self-hosted relay
used by a circle of friends). Without `--codes` nothing changes: the relay is
open and ignores a club code.

| query | effect |
|---|---|
| `?create&club=K7QX-M2PA` | open a room on a gated relay |
| `?join=CODE&club=K7QX-M2PA` | join room `CODE` on a gated relay |

- **Where the code travels:** the `club` query parameter of the WebSocket
  URL. Browsers cannot set custom headers on a WebSocket, so a header alone
  would not work for the PWA, and a first message would make an old relay
  refuse a joining guest ("relay control messages are not allowed from a
  guest") and would leave a gated relay waiting for clients that never send
  it. Trade-off: URLs, query included, can end up in reverse-proxy access
  logs (nginx, a tunnel's request log). For a self-hosted relay those are the
  operator's own logs; strip or disable query logging there. (A future option
  without that trade-off: `Sec-WebSocket-Protocol`, which browsers can set.)
  The code goes only to the relay: it is never forwarded, never part of a
  game message, and the host and guest sessions never see it. Room links and
  QR codes (`?room=…&relay=…`) never contain it, since room codes get shared
  widely; the app sends a saved club code only to the relay it was entered
  for.
- **Checked first:** before `create`/`join` is looked at, so a refused client
  learns nothing about rooms (the answer is the same for an open room, an
  unknown room and no room at all).
- **Refusal:** `relay.error` with a machine-readable `error` field, then
  close (`policyViolation`):

  | `error` | `message` | when |
  |---|---|---|
  | `club-missing` | `club code required` | no `club` parameter (or empty) |
  | `club-wrong` | `club code not accepted` | unknown or revoked code |
  | `club-wrong` | `too many wrong club codes, try again later` | 10 wrong codes from one address within 10 minutes (`ClubStrikes`); then even a valid code is refused until the window has passed |

  The clients turn these into `NetException("relay: club code required")` /
  `NetException("relay: club code not accepted")` whatever the `message`
  says (`relayClubMissingText` / `relayClubWrongText`). Other `relay.error`s
  have no `error` field (unchanged).
- **Codes file:** one code per line, optional `# label` (`K7QX-M2PA  # Familie
  Müller`); blank lines and `#` lines are skipped. Codes are normalised like
  room codes (case, spaces and dashes ignored) and must be 4–64 letters or
  digits after that. `klunki relay-code new [--label X]` prints a random line
  (two groups of four from the room-code alphabet, 31^8 ≈ 8.5 · 10^11). Codes
  are compared in constant time (SHA-256 digests, every entry compared) and
  never logged: the console shows labels or a 6-digit hash prefix.
- **Revocation:** the file is read again on every gated connection attempt
  (it is tiny; no file watcher or signal, the same on macOS and Linux and
  robust against editors that save by renaming). A deleted line refuses that
  code for **new connections** right away; rooms already open keep running
  until their game ends (the relay does not remember which code opened a
  room), but a reconnect after the revocation is refused. A file that cannot
  be read refuses everyone (fail closed) until it is readable again.
- **Rate limit:** per remote address as the relay sees it. Behind a reverse
  proxy every client has the proxy's address, so the limit is shared; with
  ~40-bit codes it is a brake, not the protection.
- **`protocolVersion` stays 3:** the game protocol
  does not change, and the relay handshake only gains an optional query
  parameter. Old clients against an open relay work as before; old clients
  against a gated relay are refused (`relay.error`, which they show as a
  lost relay); new clients with a club code against an old relay work (the
  parameter is ignored). The build fingerprint is not affected.

**Clients** (web-safe, in `package:klunki_net/klunki_net.dart`):
- `KlunkiHost.startRelay(config, relayUrl, name: …)` connects with `?create`,
  completes with `host.roomCode` set, and treats every `relay.peer` as a new
  guest connection for the unchanged host session; closing that connection
  sends `relay.kick`. A lost room surfaces as `NetError("relay: …")`.
- `KlunkiGuest.connectRelay(relayUrl, code, name: …)` connects with
  `?join=CODE`; `relay.error` / `relay.closed` end the connection with the
  reason (`NetException("relay: no room with code …")`). `reconnect()` rejoins
  the same room.
- Both take an optional `clubCode:` for a gated relay (see "Club codes"); the
  guest sends it again on `reconnect()`.

## Known limitations (accepted for the PoC)
- Hidden information is redacted since protocol 2 (see "Hidden
  information"), but the host, as referee, sees the guest's secrets, and the
  guest's check happens only at the end of the game.
- A redacted snapshot grows by about 120 bytes per move (plus the current
  view); very long GoStrategy games through a relay could approach the
  relay's 256 Ki frame limit after roughly 2000 moves.
- No encryption (`ws://`, not `wss://`). The token (16 random bytes from
  `Random.secure`) is the only proof of the guest seat (KLD-071): a guest that
  loses it (e.g. a new app instance or terminal) cannot rejoin and gets
  `session full` ("Platz belegt" in the app). Whoever can read the traffic
  (same Wi-Fi without encryption, the relay operator) can read the token too. Local Wi-Fi only. The WebSocket port does not check `Origin`, so
  any web page the guest's browser opens could connect to a host it can
  reach on the LAN; acceptable for the PoC (one guest, local network).
- One guest per host, over either transport: a second guest gets
  `error "session full"` whether it comes over TCP or WebSocket. A joined
  guest may rejoin over the other transport with its token.
- Browser ↔ browser play needs a relay (see "Relay"): a web page cannot
  listen for connections. The relay sees all messages in clear text (`ws://`)
  and does not authenticate anyone, but the host does: whoever knows the room
  code can occupy the free guest slot only until the host refuses its `hello`
  without the token (`session full`, then `relay.kick`), so it can neither
  take a disconnected guest's seat nor see that guest's view. Meant for a relay
  on the local network.
- A `?room=…&relay=…` link or a scanned room QR code names a relay; the apps
  use it for that join only and save it as the default only when the player
  confirms ("Als Standard speichern", KLD-075). The PWA warns about a relay
  other than the page's own server and does not join it without a tap.

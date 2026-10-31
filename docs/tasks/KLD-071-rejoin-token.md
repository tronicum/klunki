# KLD-071: Rejoin only with the session token

- **ID:** `KLD-071`
- **Title:** A guest seat is reclaimed only with the session token (review 2026-10, S1 🔴)
- **Status:** ✅ done
- **Depends on:** –
- **Touched paths:**
  - `packages/klunki_net/lib/src/host.dart`, `packages/klunki_net/lib/src/cli/cli.dart`, `packages/klunki_net/PROTOCOL.md`
  - `packages/klunki_net/test/{net,ws,relay,cli}_test.dart`
  - `klunki/lib/ui/pairing/{relay_errors,pairing_screen,web_join_screen}.dart`, `klunki/lib/l10n/**` (`pairingSeatTaken`)
  - `klunki/test/ui/pairing/{pairing_screen,relay}_test.dart`, `klunki/test/net/room_link_test.dart`

## Problem

`KlunkiHost._onHello` let a later connection in when it had the token **or the same name**
(`token != _token && name != _guestName`), and then closed the real guest's connection. Names are public
(shown on screen, sent in clear text, mDNS) and default to the mark "O". So anyone on the Wi-Fi, or anyone
with a relay room code, could take the guest seat; in a hidden-information game the intruder then got the
guest's own view (fleet, hand). Repro: `klunki join <ip> --name Ben` while Ben is connected.

## Decisions

**Token only.** Once a guest has joined, `hello` must carry the session token (compared in constant time) or
the host answers `error "session full"`, whatever the name. The first join is unchanged (no token needed; the
host hands one out in `welcome`).

**Every client already resends its token.** `KlunkiGuest` keeps the token from `welcome` and sends it on every
`_open()`, so `reconnect()` works over TCP, WebSocket and the relay. The app's `NetworkTransport.reconnect`
("Neu verbinden") and the CLI's "Reconnect? [Y/n]" go through `KlunkiGuest.reconnect()`; the browser uses the
same `KlunkiGuest`. Nothing in the app or CLI relied on the name fallback.

**No token persistence.** A network game does not survive an app restart today (the session and the
`NetworkGameSession` screen are in memory only), so a persisted token would have nothing to resume. A fresh
join to a host whose seat is taken shows a clear message instead: "Platz belegt: In diesem Spiel spielt schon
jemand. Nur wer zuerst beigetreten ist, kann wieder einsteigen." (`pairingSeatTaken`, `isSeatTaken` /
`RelayFailure.seatTaken` in `relay_errors.dart`, used by the room join, the native direct join and the PWA's
direct join). The CLI prints "The seat is taken: only the player who joined first can rejoin this game." If
network games are ever resumed after a restart, persist the token together with that game.

**Relay.** The relay runs no game logic and cannot check tokens, so the host does. While the guest is
connected the relay itself refuses (`relay: room … is full`). While the guest is away, a newcomer with the
code reaches the host, which refuses it without the token (`session full`) and kicks it from the room
(`relay.kick`), so the slot is free again for the real guest. To keep a silent connection from holding the
relay slot, the host now also drops any connection that sends no `hello` within its handshake timeout.

## Acceptance criteria

- [x] An intruder with the guest's name, the default mark "O" or an empty name is refused; the real guest stays
      connected and plays on (`net_test.dart`, group "KLD-071").
- [x] While the guest is away: same name, default mark, wrong or longer token are refused; the right token gets
      back in, also in a hidden-information game (`net_test.dart`).
- [x] Token rejoin works over TCP, WebSocket and the relay; intruders are refused on each (`net_test`,
      `ws_test`, `relay_test`).
- [x] CLI repro `klunki join <ip> --name Ben` (and `--name O`) while Ben is connected fails with exit code 1
      (`cli_test.dart`).
- [x] A connection without `hello` is dropped after the timeout.
- [x] App: "Platz belegt" for `session full` (`pairing_screen_test`, `relay_test`, `room_link_test`).
- [x] PROTOCOL.md: handshake rule and security notes.

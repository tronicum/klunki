# KLD-112: Relay access codes (Clubcodes)

- **ID:** `KLD-112`
- **Title:** Relay access codes (Clubcodes): a self-hosted relay only for a circle of friends
- **Milestone:** Backlog (trial; the maintainer is not sure about the idea yet, so it is off by default and easy to revert)
- **Status:** DONE (awaiting maintainer review of the screenshots and the idea)
- **Depends on:** KLD-057a/b (relay and its clients), KLD-075 (relay from links), KLD-098 ("Erweitert")
- **Touched paths:**
  - `packages/klunki_net/lib/src/relay/club_codes.dart` (new: codes file, constant-time check, strikes)
  - `packages/klunki_net/lib/src/relay/{relay_protocol,relay_server,relay_client}.dart`
  - `packages/klunki_net/lib/src/{host,guest}.dart` (`clubCode:` on `startRelay` / `connectRelay`)
  - `packages/klunki_net/lib/src/cli/cli.dart` (`relay --codes`, `relay-code new`, `--club`)
  - `packages/klunki_net/lib/{klunki_net,guest_web,relay_server}.dart` (exports)
  - `packages/klunki_net/test/relay_club_test.dart` (new), `packages/klunki_net/PROTOCOL.md`
  - `klunki/lib/profile/relay_settings.dart`, `klunki/lib/ui/pairing/{relay_line,relay_errors,relay_host_screen,room_join}.dart`,
    `klunki/lib/transport/network_transport.dart`
  - `klunki/lib/l10n/**` (4 keys)
  - `klunki/test/ui/pairing/relay_club_test.dart`, `klunki/test/screenshots/relay_club_shots_test.dart` (new)
  - `docs/BUILDING.md` (§6.3 "Club codes"), `docs/tasks/BOARD.md`

## Goal
Someone runs `klunki relay` for family and friends and does not want strangers to use it. With
`klunki relay --codes codes.txt` the relay admits only connections that carry a club code from that file;
players enter it once as "Clubcode" next to the relay address. Without `--codes` nothing changes.

## Decisions
- **Wire:** `club=CODE` query parameter on the relay WebSocket (`?create&club=…`, `?join=…&club=…`).
  Browsers cannot set WebSocket headers; a first message would break joins on old relays and make a gated relay
  wait for old clients. Trade-off (query in proxy logs) and the `Sec-WebSocket-Protocol` alternative are in
  PROTOCOL.md "Club codes".
- **Refusal:** `relay.error {error: "club-missing" | "club-wrong", message}`, checked before create/join, so the
  answer is the same whether a room exists or not. Missing and wrong are distinct (that leaks nothing); wrong,
  revoked and rate-limited are the same `club-wrong`.
- **Revocation:** the file is read again on every gated connection attempt (no watcher, no SIGHUP: simplest and
  robust on macOS and Linux). A deleted line refuses new connections at once; rooms already open may finish
  their game; a reconnect after revocation is refused. Unreadable file: everyone refused (fail closed).
- **Secrets:** codes compared in constant time (SHA-256 digests, every entry); logs show labels or a 6-hex hash.
- **Rate limit:** 10 wrong codes per remote address per 10 minutes, then refused like a wrong code (behind a
  proxy the limit is shared; documented).
- **`protocolVersion` stays 3**, no fingerprint change: old clients still work against an open relay; old
  clients against a gated relay are refused; new clients with a code against an old relay work.
- **App:** the code lives in `RelaySettings` together with the relay it was entered for and is sent only to that
  relay (`clubCodeFor`), never to a relay from a link. Room links and QR codes never contain it. The production
  factories (`platformRelayHost` / `platformRelayJoin`) read it from `RelaySettings.shared()`, so the screen
  factory typedefs (and their many test fakes) stay unchanged. Web (PWA) uses the same code path.

## Acceptance criteria
- [x] `klunki relay` without `--codes`: unchanged (all existing relay tests green; a club code is ignored).
- [x] `--codes FILE`: valid code plays a game; missing → `club-missing`; wrong / revoked → `club-wrong`; same
      reply for existing and unknown rooms; deleting a line revokes without restart; running game finishes.
- [x] Constant-time compare; codes never logged (test checks the log); per-address strikes.
- [x] `klunki relay-code new [--label X]` prints a line to append; `host/join --relay … --club CODE`.
- [x] App: "Clubcode" field in the relay dialog (under "Erweitert" › "ändern"), saved with the relay, sent when
      hosting/joining there; refusals become "Dieser Server kennt den Clubcode nicht. Frag die Person, die den
      Server betreibt." / "Dieser Server braucht einen Clubcode. …" in all 7 locales (zh says 通行码 "pass code":
      the bundled font subset lacks 俱乐部 / 会员; no subset regeneration).
- [x] Room links / QR codes do not include the club code (test).
- [x] PROTOCOL.md "Club codes", BUILDING.md §6.3 "Club codes", this card, BOARD row.
- [x] Screenshots `--plain-name kld112` (dialog, wrong code, missing code; de + ar; phone).

## How to revert
Self-contained on purpose. To remove the feature:
1. Delete `packages/klunki_net/lib/src/relay/club_codes.dart`, `packages/klunki_net/test/relay_club_test.dart`,
   `klunki/test/ui/pairing/relay_club_test.dart`, `klunki/test/screenshots/relay_club_shots_test.dart`.
2. `git revert` the KLD-112 commit, or revert these files to their state before it:
   `packages/klunki_net/lib/src/relay/{relay_protocol,relay_server,relay_client}.dart`,
   `packages/klunki_net/lib/src/{host,guest}.dart`, `packages/klunki_net/lib/src/cli/cli.dart`,
   `packages/klunki_net/lib/{klunki_net,guest_web,relay_server}.dart`, `packages/klunki_net/PROTOCOL.md`,
   `klunki/lib/profile/relay_settings.dart`, `klunki/lib/ui/pairing/{relay_line,relay_errors,relay_host_screen,room_join}.dart`,
   `klunki/lib/transport/network_transport.dart`, `docs/BUILDING.md`.
3. Remove the 4 ARB keys `relayClubCodeLabel`, `relayClubCodeHelper`, `relayErrorClubMissing`,
   `relayErrorClubWrong` from `klunki/lib/l10n/app_*.arb` and run `flutter gen-l10n`.
No protocol version, rules version or fingerprint changed, so a revert needs no compat bump. Saved settings keys
`relayClubCode` / `relayClubCodeRelay` are simply ignored afterwards.

## Later (not here)
Internet packaging (Docker image, Cloudflare tunnel, `wss://`, abuse review) stays in KLD-051.

## Definition of done
```bash
(cd packages/klunki_engine && dart pub get --offline && dart analyze --fatal-infos && dart test)
(cd packages/klunki_net && dart pub get --offline && dart analyze --fatal-infos && dart test)
(cd klunki && flutter pub get --offline && flutter gen-l10n && flutter analyze && caffeinate -i flutter test -j 2)
KLUNKI_SHOTS=/tmp/kld112 flutter test test/screenshots --plain-name kld112   # from klunki/
```

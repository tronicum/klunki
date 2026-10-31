# KLD-085: Build compatibility check in the handshake

- **ID:** `KLD-085`
- **Title:** Two builds that do not fit together refuse each other at join time, with a clear "please update" message
- **Milestone:** P3/P4 (network play)
- **Status:** DONE
- **Depends on:** KLD-064 (protocol 2), KLD-069 (decks), KLD-082 (rocket deck stats)
- **Touched paths:**
  - `packages/klunki_engine/lib/{compat,sha256,registry,quartett_decks,klunki_engine}.dart`, `packages/klunki_engine/tool/print_fingerprints.dart`, `packages/klunki_engine/test/compat_test.dart`
  - `packages/klunki_net/lib/src/{compat,connection,events,host,guest}.dart`, `packages/klunki_net/lib/src/secrecy/sha256.dart` (now a re-export), `packages/klunki_net/lib/src/cli/cli.dart`, `packages/klunki_net/lib/{klunki_net,guest_web}.dart`, `packages/klunki_net/PROTOCOL.md`, `packages/klunki_net/test/**`
  - `klunki/lib/app/build_info.dart`, `klunki/lib/transport/network_transport.dart`, `klunki/lib/net/join_payload.dart`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/pairing/{relay_errors,refused_guest_notice,pairing_screen,relay_host_screen,web_join_screen,room_join,network_game_session}.dart`, `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/**`, `klunki/test/**`
  - `.github/workflows/build.yml` (`--dart-define=KLUNKI_BUILD`), `docs/BUILDING.md`, `docs/tasks/KLD-069-quartett-decks.md`

## Goal

A real case: an iPhone on a new build joined a browser with a cached older
PWA. The old build's rocket deck still had the year stats ("in Betrieb
seit", first flight) and no photos; the new one has flights, number built
and success rate. The game started anyway and diverged. Now the join fails
on both sides with "Die Spielversionen passen nicht zusammen …", naming the
device that has to update when that can be told.

## Design

- **Engine** (`compat.dart`): `GameFingerprint {rules, rev, content}` per
  `compatKey` (`connect4`, `quartett-trumpf/rockets`, …).
  `rules` = `GameSpec.rulesVersion` (all 1), `rev` = `QuartettDeck.revision`
  (trains, rockets, planes 2 since KLD-082; cars 1), `content` = SHA-256 of
  the gameplay data (deck id, stat ids in order + `higherWins`, card ids,
  sets, names, values as platform-independent text). Labels, units, formats,
  set/deck names and the app's photos/links/credits are not hashed. The
  pure-Dart SHA-256 moved from `klunki_net` to the engine.
  `catalogFingerprint()` = 8 hex characters over everything, for the eye.
- **Protocol 3** (see PROTOCOL.md, "Build compatibility"): guest `hello`
  carries `build` + `games` (all its fingerprints); host `hello` carries
  `build` + `game` + `fingerprint`. The host checks before the seat; the
  guest checks the host's fingerprint against the `config` in `welcome`.
  Missing fields = incompatible. Error codes `incompatible-protocol`,
  `incompatible-rules`, `incompatible-content`. Envelope-version errors are
  sent in the peer's own `v`, so a protocol 2 build can read and show them.
  Version bump instead of optional fields: optional fields would let old
  and new builds keep joining each other.
- **Which side is older**: protocol number, then `rules`, then `rev`, then
  the `build` label (`major.minor.patch+build`); otherwise "both".
- **App**: `NetException.mismatch` → localized text (all 7 locales):
  `versionMismatchUpdateOther` / `versionMismatchUpdateThis` /
  `versionMismatchBoth`; host waiting screens show
  `versionMismatchGuestRefused` (`NetworkTransport.refusedGuest`). The menu
  footer shows `Version 1.0.0+1 · <commit> · P3 · <catalog code>`
  (`build_info.dart`; commit from `--dart-define=KLUNKI_BUILD`, CI passes
  `github.sha`).

## Acceptance criteria
- [x] Golden fingerprint per game and deck; a stat value, `higherWins`, stat order/id or card name change changes the hash; labels, units, formats, names, revision and whole-number doubles do not.
- [x] Matching handshake passes; protocol, rules and content mismatches are rejected with the right code over TCP, WebSocket and the relay; the host keeps waiting.
- [x] A protocol 2 guest (no fingerprint) is refused by a new host, over TCP and the relay, with an error it can read; a protocol 2 host (its own error, or a v2 hello + welcome) is detected by a new guest; a v3 hello without fingerprint is refused on both sides.
- [x] The app shows the mismatch message (join over TCP, room join) and the host's "turned away" notice; the menu shows the version line.

## How to change a game or deck later
Change rules → bump `rulesVersion` in `gameSpecs`. Change deck data → bump
the deck's `revision:`. Either way update the golden values in
`packages/klunki_engine/test/compat_test.dart`
(`dart run tool/print_fingerprints.dart`). Photo-only updates need nothing.

## Known limits
- An old (protocol 2) **host** that a new guest tries to join shows nothing
  on the host: its old code drops the connection before the handshake. The
  new guest shows the message.
- An old **guest** shows the new host's English error inside its generic
  "Verbindung … fehlgeschlagen" text (it has no localized text for it).
- An old join link or QR code with `v=2` in the new PWA's address field is
  treated as an invalid address (the existing protocol check of
  `WebJoinTarget`); a scanned one in the native app connects and gets the
  mismatch message.
- `appVersion` mirrors `pubspec.yaml` (a test keeps them equal); nobody bumps
  it yet, so "which side is older" mostly comes from `rules`/`rev`.

# KLD-050 — Lobby / game code over local Wi-Fi (code in the mDNS TXT record)

- **ID:** `KLD-050`
- **Title:** The host gets a short game code (e.g. `KLNK-4821`); the guest types it in and joins the matching host on the same Wi-Fi, with no IP or list needed
- **Milestone:** Backlog (after the PoC networking works)
- **Status:** TODO
- **Depends on:** KLD-033 (discovery, TXT records), KLD-034 (pairing screen)
- **Touched paths** (proposed; the board lists none for backlog items. Confirm with the caller that nothing else touches them in the same wave):
  - `klunki/lib/net/**`
  - `klunki/lib/ui/pairing/**` (except `reconnect*`)
  - `klunki/test/net/**`, `klunki/test/ui/pairing/**`
  - `docs/tasks/KLD-050-lobby-code-local.md` (status only)

## Goal
Joining is "type 4 digits". The host's pairing screen shows a code. The guest enters it in a code field, the app browses
`_klunki._tcp`, picks the service whose TXT record carries that code, and connects. This needs no server (step 1 of the
lobby idea in `docs/ROADMAP.md`; step 2 is the internet relay, KLD-051).

## Repo context — read first
- `klunki/lib/net/**` (KLD-033): `DiscoveryService.advertise/browse`, `KlunkiHostInfo`, TXT keys (`v`, `game`, `name`), `join_payload`.
- `klunki/lib/ui/pairing/**` (KLD-034): host and join flows.
- `packages/klunki_net` (KLD-030): `hello` carries `{protocol, game, mode, seed}`.

## Acceptance criteria
- [ ] Code format `KLNK-` + 4 digits (shown as such; the input accepts `4821`, `klnk4821`, `KLNK-4821`). Generated with `Random.secure()`. If a browse
      already shows the same code on the network, regenerate.
- [ ] The host advertises TXT key `code=4821` in addition to the existing keys, and the QR payload includes `&c=4821`.
- [ ] Guest: a code field on the join tab → browse for up to 5 s → exactly one match → connect. No match → "Kein Spiel mit Code 4821 gefunden
      (gleiches WLAN?)". Several matches (shouldn't happen) → show them as a list.
- [ ] The host verifies the code in the guest's `hello`/join message if `klunki_net` supports an extra field. If it doesn't, report it (the PoC
      can accept any guest; the code only filters discovery).
- [ ] Tests: code normalisation/parsing (pure Dart); fake discovery with 3 hosts → the right one is picked; no-match message.
- [ ] `cd klunki && flutter analyze && flutter test` green.

## Constraints
- Board rules: never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the user's OK.
  No new packages. It's a local network only, so no server.
- A 4-digit code isn't a security boundary on a shared Wi-Fi. Don't claim it is in UI text. Don't commit unless asked.

## Hints / context
- TXT records are small: keep values short (and well under 255 bytes per entry).
- On iOS, browsing still needs the local-network permission (KLD-040); the code flow inherits the same hint on failure.

## Definition of done
```bash
cd klunki
flutter analyze
flutter test
```
Green; 🧑 manual check on two devices: join by code. Card status set to DONE.

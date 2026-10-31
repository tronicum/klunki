# KLD-074: Background/resume: auto-reconnect, relay grace period, host listener check

- **ID:** `KLD-074`
- **Title:** Background/resume: auto-reconnect, relay grace period, host listener check
- **Priority:** medium
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-069
- **Touched paths:** `klunki/lib/transport/network_transport.dart`, `klunki/lib/ui/pairing/network_game_session.dart`, `packages/klunki_net/lib/src/{guest,host,connection}.dart`, `packages/klunki_net/lib/src/relay/**`

## Goal
Switching apps or locking the phone for a minute doesn't end a game (REVIEW C2; overlaps with KLD-036 and KLD-040).

## Acceptance criteria
- [ ] An `AppLifecycleListener` makes the guest reconnect on its own when the app resumes (with back-off; the banner shows progress).
- [ ] An optional `pause` hint lets the peer show "Ben ist kurz weg".
- [ ] The relay keeps a room for N minutes after the host's socket ends, and the host re-attaches with a room secret.
- [ ] After resume, the native host checks its listener and rebinds it if needed.
- [ ] 🧑 device check: an iPhone Safari host copies the room code, switches to Messages for 30 s, returns, and the game continues.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.

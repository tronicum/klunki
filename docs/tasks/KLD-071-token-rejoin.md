# KLD-071: Rejoin only with the session token (no takeover by name)

- **ID:** `KLD-071`
- **Title:** Rejoin only with the session token (no takeover by name)
- **Priority:** high
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** –
- **Touched paths:** `packages/klunki_net/lib/src/host.dart`, `packages/klunki_net/PROTOCOL.md`, `klunki/lib/transport/network_transport.dart`, `klunki/lib/ui/pairing/**`, tests

## Goal
Only the token from `welcome` can take the guest seat back. Today a newcomer with the same name (or the default mark "O") replaces the real guest (`host.dart:220`); see REVIEW-2026-10 S1.

## Acceptance criteria
- [ ] A `hello` without the right token after the first join gets `error "session full"` (TCP, ws, relay).
- [ ] The guest saves its token per host and session (`shared_preferences`), so it can still rejoin after an app restart.
- [ ] If the token is lost, the host sees "Ben möchte wieder beitreten – zulassen?" (accept/deny). There is never an automatic takeover.
- [ ] Test: a third client with the guest's name is refused, and the real guest stays connected.
- [ ] PROTOCOL.md, "Player names" and "Known limitations", is updated.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.

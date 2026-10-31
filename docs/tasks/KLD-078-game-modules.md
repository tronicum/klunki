# KLD-078: Game modules, typed net errors, i18n and code cleanup

- **ID:** `KLD-078`
- **Title:** Game modules, typed net errors, i18n and code cleanup
- **Priority:** medium
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** KLD-058b merged
- **Touched paths:** `klunki/lib/ui/{game_titles,game_visuals,game_illustrations,engine_l10n}.dart`, `klunki/lib/ui/shell/screen_registry.dart`, `klunki/lib/app/theme.dart`, `klunki/lib/ui/pairing/**`, `packages/klunki_net/lib/src/events.dart`, `klunki/lib/l10n/**`

## Goal
Adding a game (chess next) means one `GameModule` and one engine class, and errors are typed instead of matched by English text (REVIEW A2–A5, I2–I4).

## Acceptance criteria
- [ ] A `GameModule` per game (id, screen, title, visuals, accents, illustration, move describer), with a test that every `appGameSpecs` id has a complete one. The engine titles leave `GameSpec`.
- [ ] `NetErrorCode` on `NetException`, `NetError` and `MoveRejected`. `relay_errors.dart` and `mapReason` switch on the codes, and no raw `$e` reaches UI texts.
- [ ] Pairing: shared host and join controllers instead of three copies. The native join screen shows LAN and QR first, with the relay under "Erweitert".
- [ ] Remove `webJoinIntro`, `relayAddressAdvanced` and `webJoinDirectTitle`; plurals for `schiffeRemaining` and the others; localize `join_qr.dart:71`.
- [ ] Rename "4 Gewinnt" to a generic title (e.g. "Vier in einer Reihe").

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.

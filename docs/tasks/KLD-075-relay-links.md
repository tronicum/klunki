# KLD-075: Links and QR codes: no silent relay switch, confirm before auto-connect

- **ID:** `KLD-075`
- **Title:** Links and QR codes: no silent relay switch, confirm before auto-connect
- **Priority:** medium
- **Status:** TODO (stub from `docs/REVIEW-2026-10.md`)
- **Depends on:** –
- **Touched paths:** `klunki/lib/ui/pairing/{web_join_screen,room_join,relay_line}.dart`, `klunki/lib/profile/relay_settings.dart`, tests

## Goal
A shared link can no longer send all later games through another relay (REVIEW S3).

## Acceptance criteria
- [ ] The relay from a link or QR code is used for that join only. Saving it asks "Diesen Relay merken?".
- [ ] The join confirmation shows the relay host. Auto-connect happens only after the name dialog and with the target visible.
- [ ] Tests check that `?room=…&relay=…` doesn't change `RelaySettings` without consent.

## Definition of done
`dart test` (both packages), `flutter analyze` and `flutter test` are green, the card status is DONE, and BOARD.md is updated.

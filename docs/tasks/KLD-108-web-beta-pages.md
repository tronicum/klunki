# KLD-108: Web beta on GitHub Pages

- **ID:** `KLD-108`
- **Title:** Pages build is a marked web beta; network play greyed out where it can't work
- **Milestone:** M6
- **Status:** DONE
- **Depends on:** KLD-096 (Pages, `browserBlocksWebSocket`), KLD-098 (room buttons), KLD-102 (About), KLD-105 (tile links)
- **Touched paths:**
  - `klunki/lib/app/web_channel.dart` (new), `klunki/lib/net/room_link.dart`
  - `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/about_screen.dart`, `klunki/lib/ui/pairing/network_unavailable.dart` (new)
  - `klunki/lib/l10n/**` (6 keys), `klunki/test/l10n/translations_test.dart`
  - `klunki/test/ui/web_beta_test.dart`, `klunki/test/screenshots/web_beta_shots_test.dart`
  - `.github/workflows/build.yml`, `docs/BUILDING.md`, `AGENTS.md`, `site/support/index.html`

## Goal
The PWA on GitHub Pages (`https://tronicum.github.io/klunki/`) can't play over the network: https pages can't
open `ws://` relays and there is no `wss://` relay yet. It should say it is a beta and not offer network play
that fails, while the relay-served http build on the LAN keeps working.

## Acceptance criteria
- [x] Build-time define `KLUNKI_WEB_CHANNEL=pages-beta`, set only in the `pages-build` job. With it: a "Beta"
  badge next to "Klunki" in the menu app bar and the About line "Web-Beta – Spiele mit mehreren Geräten gibt
  es in der App."
- [x] General detection `browserCannotPlayOnline(pageUrl, chosenRelay)`: https page and no relay in the relay
  settings that the browser may open (reuses `browserBlocksWebSocket`; the page's own `wss://` origin doesn't
  count). Not tied to the flag; false natively and on http pages.
- [x] Then the "Mit anderen" links and the "Raum starten" / "Raum beitreten" cards are greyed out but visible;
  a tap opens a sheet: "Im Browser noch nicht verfügbar – mit der App könnt ihr auf mehreren Geräten spielen."
  + "App-Beta in Vorbereitung." Choosing a `wss://` relay enables them again (live).
- [x] Optional app links as defines `KLUNKI_IOS_BETA_URL` / `KLUNKI_ANDROID_URL` (Pages job: from repository
  variables of the same names), empty by default: no buttons, only the teaser. Only https links count.
  No release or upload.
- [x] Texts in all 7 locales (zh only with characters already in the font subset), RTL checked.
- [x] Tests: badge + About line with the flag (none without), disabled under https-without-wss and enabled
  natively / on http / with a wss relay, the sheet, empty links mean no buttons.
- [x] Screenshots (web 1280×800, phone 390×844): `KLUNKI_SHOTS=… flutter test test/screenshots/web_beta_shots_test.dart`.

## Notes
- A self-hosted https page with a wss relay on the same origin also starts greyed out (its relay isn't
  "configured"); a saved `wss://` relay or a `?room=CODE&relay=wss://…` link (opens the join screen directly)
  works there.

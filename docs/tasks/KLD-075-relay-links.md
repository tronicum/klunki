# KLD-075: Links and QR codes no longer silently replace the saved relay

- **ID:** `KLD-075`
- **Title:** A link's relay is used for that join only (review 2026-10, S3 🟠)
- **Status:** ✅ done
- **Depends on:** KLD-052 (relay line, scan), KLD-057b (`?room=` links)
- **Touched paths:**
  - `klunki/lib/ui/pairing/room_join.dart`, `klunki/lib/ui/pairing/web_join_screen.dart`
  - `klunki/lib/l10n/**` (4 `relay*Link*` keys + `pairingSeatTaken`, one block before `webJoinDirectTitle`),
    `klunki/assets/fonts/NotoSansSC/**` (re-subset)
  - `klunki/test/ui/pairing/{qr_scan,relay}_test.dart`

## Problem

Opening `?room=CODE&relay=evil:9000` (`web_join_screen.dart`) or scanning a room QR code
(`RoomCodeJoinState.joinScanned`) wrote the link's relay into the shared, persisted `RelaySettings`. One shared
link routed every later "Spiel hosten" and room join through an attacker-chosen relay, which sees everything in
clear text.

## Decisions

**For this join only.** `RoomCodeJoin` keeps the link's relay in its own state (`linkRelay` for a `?room=` link,
`joinScanned` for a scanned code) and joins through it; `RelaySettings` stays as it was. A link without
`&relay=` names the page's own server. A retry from the same screen still uses the link's relay.

**Visible.** When the link's relay differs from the relay in use, the join shows "Relay aus Link: host:port"
(`room-link-relay`) with two buttons:
- "Als Standard speichern" (`room-link-relay-save`): the only way the link's relay becomes the saved setting.
- "Gespeichertes Relay verwenden" (`room-link-relay-drop`): forget the link's relay.

**Foreign relay in the PWA.** A link to a relay other than the page's origin gets a warning in the error colour
(`room-link-relay-foreign`: "Achtung: Dieser Link führt zu einem fremden Relay …") and does **not** join on its
own: the player reads the warning and taps "Beitreten". Links to the page's own relay still join right away
(after the first-run name dialog), and a scanned QR code in the app still joins at once (an app has no page
origin, so there is no foreign warning there).

The relay line, the "ändern" dialog and hosting are unchanged (KLD-052).

## Acceptance criteria

- [x] `?room=…&relay=other`: no auto-join, warning, setting unchanged; join uses the link relay; only "Als
      Standard speichern" saves it (`relay_test.dart`, group "?room= at startup").
- [x] "Gespeichertes Relay verwenden" drops the link relay.
- [x] `?room=` to the page itself with a different saved relay: joins the page relay once, saved relay stays.
- [x] Scanned room QR: joins through its relay, setting unchanged, "Relay aus Link" shown; retry uses it again;
      "Als Standard speichern" saves it (`qr_scan_test.dart`).
- [x] Strings in all 7 ARB files (one block; non-German machine-translated, files carry `@@x-review`), zh glyphs
      re-subset, glyph tests green.

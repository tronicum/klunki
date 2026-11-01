# KLD-098 — Room flow: "Raum starten" / "Raum beitreten"

- **ID:** `KLD-098`
- **Title:** One mental model for device-vs-device play, "a room with a code": no "hosten", no hidden "beitreten", technical details under "Erweitert"
- **Milestone:** P3/P4 polish (UX feedback from the user and their kids)
- **Status:** DONE
- **Depends on:** KLD-034 (pairing screen), KLD-052 (QR scanning), KLD-055 (web join), KLD-057b (relay rooms), KLD-075 (relay links), KLD-083 (localhost hint), KLD-085 (version check)
- **Touched paths:**
  - `klunki/lib/ui/menu_screen.dart` (two equal room buttons instead of the "Über WLAN spielen" card)
  - `klunki/lib/ui/pairing/{pairing_entry,pairing_entry_io,pairing_entry_stub,pairing_screen,relay_host_screen,web_join_screen,room_join,relay_line,relay_errors,network_game_session}.dart`
  - `klunki/lib/profile/room_settings.dart` (new: rooms through the relay yes/no, remembered)
  - `klunki/lib/l10n/*` (7 ARB files + generated), `klunki/assets/fonts/NotoSansSC/*` (re-subset)
  - comments in `klunki/lib/{app,profile}/*`, `klunki/lib/ui/player_name_dialog.dart`
  - tests: `klunki/test/ui/pairing/*`, `klunki/test/ui/player_names_test.dart`, `klunki/test/l10n/{coverage,rtl}_test.dart`, `klunki/test/screenshots/room_flow_shots_test.dart` (new), `klunki/integration_test/{app,network}_test.dart`
  - `klunki/tool/browser_live/{browser.mjs,README.md}`, `docs/DEMO.md`, `docs/tasks/BOARD.md`

## Problem
"Spiel hosten" is English jargon kids do not understand, and "beitreten" was a segment of the pairing screen
(app) or buried below the host button (PWA). Relay address, IP addresses and the direct connection were all on
the first screen, although they are needed once, when a relay is set up.

## Design (approved by the user)
- Menu: heading **"Mit anderen Geräten spielen"** with two equal-sized buttons:
  **"Raum starten"** ("Andere kommen mit dem Raumcode dazu") and **"Raum beitreten"** ("Code scannen oder
  eintippen"). English "Play with other devices" / "Start a room" / "Join a room"; fr/es/zh/ar/fa use the same
  "room" word as the existing "Raumcode" (salle, sala, 房间, غرفة, اتاق).
- **"Raum starten"**: name, game (chess stays out: `networkGameSpecs`), Quartett deck picker, "Raum starten".
  Waiting: "Raum von Anna: Mühle", the QR code (and on a relay room the large room code and the link), "Andere
  tippen auf „Raum beitreten“ …".
- **"Raum beitreten"**: in the app the camera scanner opens right away (if the device has a scanner; closing it or
  "Code eintippen" goes back), then "Raumcode eintippen" + "Raum beitreten", then "Räume in der Nähe" (mDNS). The
  PWA has no scanner: the code field comes first.
- **"Erweitert"** (collapsed `ExpansionTile`, `RoomAdvanced` in `relay_line.dart`): relay line, IP addresses,
  browser link, the direct address field, the switch "Raum über ein Relay öffnen". `?join=` links open it
  right away (their progress and error are in it).

## One room, two transports (decision)
A **room** is either a direct room (TCP + WebSocket on the device, mDNS, `klunki://` QR) or a relay room
(room code, `?room=` link/QR). The technical paths are unchanged; only the entry and wording are shared:
- **App default: the room runs on this device.** It needs no server, works offline on any Wi-Fi, other apps find
  it under "Räume in der Nähe" or scan its QR code, browsers can still join it via the link under "Erweitert".
- **"Erweitert" → "Raum über ein Relay öffnen"** switches the app to relay rooms (room code, browsers on the
  relay join by code). The choice is remembered (`RoomSettings`, prefs key `roomViaRelay`) so it is needed once.
  Starting then replaces the route by the `RelayHostScreen` with the chosen game, which opens the room at once
  (`autoStart`); cancel there stays on that screen with the game preselected.
- **PWA: always a relay room** (a page cannot listen); the relay is the page's own server unless changed under
  "Erweitert".
- Joining handles both everywhere: a scanned code of either kind, the room code (relay), a room nearby
  (direct), an address under "Erweitert" (direct).
- Why not "relay if one is configured": the app saves a relay as soon as it joins a browser room once, so that
  rule would silently move later rooms onto a server that may not be running.

## Wording changes beyond the buttons
- No "Host" in user texts: "Raum von {name}: {game}" (was "{name} hostet {game}"), "Der Raum wurde geschlossen: Wer
  ihn gestartet hat, ist gegangen." (was "Der Host hat den Raum verlassen"), "… und ist der Raum noch offen?",
  "Ist das andere Gerät noch im Spiel?", QR scanner hints, browser join hints, the port helper, "Starte einen
  neuen Raum." The version-mismatch texts (KLD-085) had no "Host" in any locale and are unchanged.
- KLD-096 (https/wss hint, not on main yet): `webJoinHttpsWarning` keeps its key and place (top of
  "Raum beitreten" in the browser), so KLD-096's rewording applies as is. Its code hunks in
  `relay_host_screen.dart`, `room_join.dart` and `web_join_screen.dart` will need a manual merge (the
  `RoomCodeJoin(pageUrl: …)` argument and the https line at the top of the relay room setup).

## ARB keys
Renamed: `pairingHostGame`→`roomStart`, `relayJoin`→`roomJoin`, `pairingHosting`→`roomOfPlayer`,
`pairingHostStartFailed`→`roomStartFailed`, `relayHostIntro`→`roomStartIntro`, `pairingGamesOnNetwork`→`roomNearby`,
`relayCodeHelper`→`roomCodeHelper`, `relayErrorHostLeft`→`relayErrorRoomClosed`.
New: `roomStartSubtitle`, `roomJoinSubtitle`, `roomAdvanced`, `roomDirectWaitingHint`, `roomViaRelay`,
`roomViaRelayHelper`, `roomTypeCode`.
Removed: `menuPlayOverWifi`, `menuNetworkSubtitle`, `pairingTitle`, `pairingModeHost`, `pairingModeJoin`,
`relayGroupTitle`, `relayJoinTitle`, `relayJoinIntro`, `pairingOrEnterAddress`, and the already unused
`webJoinIntro`, `webJoinDirectTitle`, `relayAddressAdvanced`.

## Not done / notes
- Games have no network option of their own (a menu tile starts hot-seat), so the menu is the only entry.
- The QR widget's caption still shows `IP:port` under the code of a direct room (part of `JoinQrCode`).
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots/room_flow_shots_test.dart`.

## Acceptance criteria
- [x] Menu: heading + two equal buttons; no "hosten"/"Host"/"multiplayer" in any locale's room texts.
- [x] App join opens the scanner first (with a camera), code field below; PWA join starts at the code field.
- [x] Relay/IP/direct details under "Erweitert"; the relay choice is remembered.
- [x] Chess still not offered for rooms; Quartett deck picker on both start screens.
- [x] `flutter analyze`, full `flutter test`, browser live run green.

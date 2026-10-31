# Task board

Small, self-contained tasks so several agents (or people) can work in parallel.
Each task has its own card `KLD-XXX-*.md` (format: `_TEMPLATE.md`) that can be
executed from that file alone. **Touched paths** are disjoint inside a wave, so
tasks of the same wave can run at the same time without merge conflicts.

Rules for every task:
- Engine code stays pure Dart (`packages/klunki_engine`, `packages/klunki_net`): no Flutter imports.
- **Never install toolchains, download SDK components, accept licenses, sign up for
  accounts or publish anything without the user's explicit OK.** If a task needs that, stop and report what's needed.
  (Adding pub.dev packages to a pubspec is fine *after* the card says so and the user has confirmed the dependency list.)
- Done = card's acceptance criteria met, `dart test` / `flutter test` / `flutter analyze` green, card status set to DONE.

Legend: 🧑 = needs the user (confirmation, device, account, GUI step).

## Platform hello world (side quest: de-risk the final demos)

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-010 ✅ | **PWA:** Klunki branding in `manifest.json`/`index.html`, custom offline service worker (Flutter's generated one unregisters itself), local serve + offline check | – | `klunki/web/**`, `docs/tasks/KLD-010*` | – |
| KLD-011 | **Android:** debug build + run on the one Android phone; app label "Klunki"; `INTERNET` permission in the main manifest. **BLOCKED** on 🧑 cmdline-tools + licenses + phone USB debugging | Android Studio install (approved) + 🧑 cmdline-tools, licenses, USB debugging | `klunki/android/**` | 🧑 |
| KLD-012a ✅ | **iOS Simulator:** unchanged app builds and runs on iPhone 18 Pro + iPad Pro simulators | – | `docs/tasks/KLD-012a*` | – |
| KLD-012 | **iOS (priority):** simulator part done (KLD-012a); iPhone + iPad on device + signing team **BLOCKED** on 🧑 Apple ID + Developer Mode | 🧑 Apple ID in Xcode, Developer Mode | `klunki/ios/**` | 🧑 |

## P2 — Hot-seat on one device

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-020 ✅ | Typed `GameTransport` (matches `docs/ARCHITECTURE.md`) + `HotSeatTransport` that applies moves through the engine + `GameController` (ChangeNotifier) + game registry (id → factory, title) | – | `klunki/lib/transport/**`, `klunki/lib/game/**`, `klunki/test/game/**` | – |
| KLD-021 ✅ | Shared UI shell: `GameScreen` frame (status line, result dialog, move history sheet, new game), `HandoverCover` ("pass the phone to O"), menu → game routing with one placeholder screen per game | 020 | `klunki/lib/ui/shell/**`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/games/*_screen.dart` (placeholders), `klunki/test/ui/shell/**`, `klunki/test/widget_test.dart` | – |
| KLD-022 ✅ | Four in a Row screen (tap a column, drop animation, winning line highlight) | 021 | `klunki/lib/ui/games/connect4_screen.dart`, `klunki/test/ui/games/connect4*` | – |
| KLD-023 ✅ | Mühle screen (board painter, tap to place/move/remove, mill highlight, phase hints) | 021 | `klunki/lib/ui/games/muehle_screen.dart`, `klunki/test/ui/games/muehle*` | – |
| KLD-024 ✅ | Quartett Trumpf screen (top card with stats, tap a stat, trick reveal, pot) + handover | 021 | `klunki/lib/ui/games/quartett_trumpf_screen.dart`, `klunki/lib/ui/games/quartett_card.dart`, `klunki/test/ui/games/quartett_trumpf*` | – |
| KLD-025 ✅ | Quartett Sets screen (hand grouped by set, ask for a card, quartets laid down) + handover | 021, 024 (`quartett_card.dart`) | `klunki/lib/ui/games/quartett_sets_screen.dart`, `klunki/test/ui/games/quartett_sets*` | – |
| KLD-026 ✅ | Schiffe versenken screen (fleet placement with rotate + random, own grid + target grid, tap to fire) + handover | 021 | `klunki/lib/ui/games/schiffe_screen.dart`, `klunki/test/ui/games/schiffe*` | – |

## P3 — iPhone ↔ iPad over Wi-Fi

Milestone: iPhone ↔ iPad verified on simulators (KLD-038c); real devices pending (KLD-012, 040).

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-030 ✅ | `packages/klunki_net` (pure Dart): NDJSON protocol (`hello`, `welcome` {config, moves, token}, `move`, `accepted`, `rejected`, `ping`/`pong`, `bye`; no separate `snapshot`), host-authoritative TCP session, replay from seed + move list, loopback tests | – | `packages/klunki_net/**` | – |
| KLD-031 ✅ | Terminal networking: `klunki host <game>` / `klunki join <ip>` — two terminals play each other through the `DebugConsole` (networked Quartett needs a seed hook, see card) | 030 | `packages/klunki_net/bin/**`, `packages/klunki_net/test/cli*` | – |
| KLD-032 ✅ | `NetworkTransport` in the app on top of `klunki_net` (same interface as `HotSeatTransport`) | 020, 030 | `klunki/lib/transport/network_transport.dart`, `klunki/test/transport/network*`, `klunki/pubspec.yaml` (only the `klunki_net` path dependency; KLD-033 adds bonsoir/QR there later — sequential, no conflict) | – |
| KLD-033 ✅ | Discovery service: advertise/browse `_klunki._tcp` via mDNS (`bonsoir`), manual IP:port fallback, QR payload; the host only **shows** the QR (scanning = backlog KLD-052) | 030, 🧑 OK for the `bonsoir` + QR packages | `klunki/lib/net/**`, `klunki/pubspec.yaml`, `klunki/test/net/**` | 🧑 |
| KLD-034 ✅ | Pairing screen: host (shows name, IP, QR) / join (list + manual entry), then start the chosen game over `NetworkTransport` | 021, 032, 033 | `klunki/lib/ui/pairing/**`, `klunki/test/ui/pairing/**`, `klunki/lib/ui/menu_screen.dart` | – |
| KLD-035 (partial: manifest permissions + app label done; release build and device test pending) | Android networking for Android ↔ iOS: multicast lock + Wi-Fi/nearby permissions for discovery, release-build networking check | 011, 033 | `klunki/android/**` | 🧑 |
| KLD-036 | Disconnect / reconnect UX ("opponent left", resume from snapshot). The basic leave/disconnect banner plus "Neu verbinden" already exist (KLD-034, `network_game_session.dart`) | 034 | `klunki/lib/ui/pairing/reconnect*`, `klunki/lib/transport/network_transport.dart`, `klunki/test/ui/pairing/reconnect*` | – |
| KLD-054 ✅ | WebSocket transport in `packages/klunki_net` (io + browser channels, host listens on TCP and WS, web-compile test); app: `JoinPayload.wsPort`, `NetworkTransport.joinWebSocket`, `ws` mDNS TXT key (see `docs/tasks/KLD-054-websocket.md`) | 030, 032, 033 | `packages/klunki_net/**`, `klunki/lib/net/**`, `klunki/lib/transport/network_transport.dart`, `klunki/test/net/**`, `klunki/test/transport/**` | – |
| KLD-055 ✅ | Browser join screen (PWA joins a host over WebSocket: paste a link or `?join=`, web pairing UI; see `docs/tasks/KLD-055-web-join.md`) | 054 | `klunki/lib/ui/pairing/**`, `klunki/lib/net/web_join_target.dart` | – |
| KLD-056 ✅ | Player name/handle for multiplayer (persisted, first-run "Wie heißt du?" dialog, shown in status, connection bar, discovery, result) plus optional hot-seat names; see `docs/tasks/KLD-056-player-name.md` | 055 | `klunki/lib/profile/**`, `klunki/lib/ui/player_name_dialog.dart`, `klunki/lib/ui/shell/player_labels.dart`, `packages/klunki_net/lib/src/names.dart` | – |
| KLD-057a ✅ | Relay with room codes for browser vs browser, network part: `klunki relay [--port N] [--web DIR]` (WebSocket `/relay` + static PWA serving), `KlunkiHost.startRelay` / `KlunkiGuest.connectRelay` (web-safe), CLI `host --relay` / `join --relay --room`; see `docs/tasks/KLD-057-relay-host.md` | 054, 056 | `packages/klunki_net/**`, `docs/DEMO.md` | – |
| KLD-057b ✅ | UI for browser vs browser: "Spiel hosten" in the PWA (game choice → room code `K7Q 2M` large + QR + `?room=` link, relay = page origin, "Erweitert" for another relay), room-code join in the web join screen and the app's join tab (relay address field), `?room=CODE[&relay=…]` at startup, friendly relay errors in 7 languages, `NetworkTransport.hostRelay`/`joinRelay`; real two-browser e2e `klunki/tool/pwa_relay_e2e.sh`; see `docs/tasks/KLD-057-relay-host.md` | 057a, 055 | `klunki/lib/ui/pairing/**`, `klunki/lib/net/**`, `klunki/lib/transport/network_transport.dart`, `klunki/lib/app/klunki_app.dart`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/**`, `klunki/tool/pwa_relay_e2e.*`, `klunki/test/**`, `docs/DEMO.md` | – |
| KLD-065 ✅ | "Aufgeben" (resign) in every game: once in the engine base (`Game.applyMove` handles `{'action':'resign','player':'a'\|'b'}`, any time, also off turn and in setup phases, `GameEndReason.commonResigned` with `player`), an ordinary logged move (network, replay, hot-seat undo), host accepts it off turn (`Game.playerOf`), CLI/debug console `resign`, flag action in the shared game shell with confirmation (hot-seat: "Wer gibt auf?"), "X hat aufgegeben" in the result; see `docs/tasks/KLD-065-resign.md` | 056, 062 | `packages/klunki_engine/lib/game.dart` (+ one rename per game), `packages/klunki_net/lib/src/{host,guest}.dart`, `packages/klunki_net/lib/src/cli/cli.dart`, `packages/klunki_net/PROTOCOL.md`, `klunki/lib/ui/shell/game_screen.dart`, `klunki/lib/game/game_controller.dart`, `klunki/lib/transport/**`, `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/**` | – |
| KLD-052 ✅ | Scan a host's QR code in the app's join tab (originally `mobile_scanner` 7.4.2, since KLD-080 `flutter_zxing`; camera permission on iOS/Android; native host `klunki://` and browser room links; hidden on the web), plus the join screens regrouped: "Über Relay spielen (Raumcode)" with one shared relay setting (relay line "Relay: … · ändern", no expanders), "QR-Code scannen", "Direkt mit einem Gerät verbinden"; see `docs/tasks/KLD-052-qr-scanning.md` | 033, 057b, 🧑 OK for the package | `klunki/pubspec.*`, `klunki/lib/net/scanned_join_code.dart`, `klunki/lib/profile/relay_settings.dart`, `klunki/lib/ui/pairing/**`, `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/**`, `klunki/ios/Runner/Info.plist`, `klunki/android/app/src/main/AndroidManifest.xml`, `klunki/test/**`, `docs/DEMO.md` | 🧑 device check |
| KLD-080 ✅ | QR scanner on open-source zxing-cpp: `mobile_scanner` (ML Kit on Android, Apple Vision on iOS) replaced by `flutter_zxing` 3.1.0 (FFI, Apache-2.0 zxing-cpp; SwiftPM on iOS, CMake/NDK on Android) behind the unchanged `QrScanner` abstraction; zxing-cpp/libzint licences on the license page; Android manifest trimmed (no RECORD_AUDIO, camera optional). **Android scanner unverified until CI/device.** See `docs/tasks/KLD-080-zxing-scanner.md` | 052, 🧑 OK for the package | `klunki/pubspec.*`, `klunki/lib/ui/pairing/qr_scanner_mobile.dart`, `klunki/lib/app/third_party_licenses.dart`, `klunki/lib/main.dart`, `klunki/assets/licenses/**`, `klunki/android/app/src/main/AndroidManifest.xml`, `klunki/test/app/third_party_licenses_test.dart` | 🧑 device check (Android) |
| KLD-083 ✅ | Localhost notice: hosting from a page/relay on `localhost`/127.x/`::1`/`*.localhost` warns under the QR/link and on the relay line (link and QR unreachable for other devices; hosting stays allowed), with a collapsible "Wie finde ich die Adresse?" per OS; `klunki relay` prints "Open on other devices" (LAN IPs + `.local` name) and binds dual-stack (IPv6 + IPv4). Next step (not built): `/relay/info` so link/QR use a reachable address automatically. See `docs/tasks/KLD-083-localhost-hint.md` | 052, 057b | `klunki/lib/net/room_link.dart`, `klunki/lib/ui/pairing/{relay_line,relay_host_screen}.dart`, `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/**`, `packages/klunki_net/lib/src/{relay/relay_server,cli/cli,cli/open_urls}.dart`, `klunki/test/**`, `packages/klunki_net/test/{cli,relay}_test.dart`, `docs/{BUILDING,DEMO}.md` | – |

## P4 — Android ↔ iOS (end of PoC)

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-040 (partial: Info.plist keys done; permission prompt and backgrounding device test pending) | iOS local network: `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_klunki._tcp`), permission prompt flow, backgrounding → reconnect | 012, 033 | `klunki/ios/**` | 🧑 |
| KLD-041 | Demo runbook `docs/DEMO.md`: exact steps for the final demos (text, hot-seat, Android↔Android, Android↔iOS, PWA), device checklist, Wi-Fi pitfalls | – (update as tasks land) | `docs/DEMO.md` | – |

## E2E tests

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-037a ✅ | Protocol-level Mühle e2e: "iOS" host vs "Android" guest over TCP (pure Dart), incl. reconnect and swapped roles | 030 | `packages/klunki_net/test/e2e_*` | – |
| KLD-037b ✅ | App-level e2e: two `GameController`s over `NetworkTransport` on loopback play Mühle to the end (`flutter test`) | 032 | `klunki/test/e2e/**` | – |
| KLD-038a | Simulator e2e: iOS Simulator app hosts, Android emulator app joins via `10.0.2.2`; both play the Mühle demo script automatically (`integration_test` + `--dart-define` test mode with a fixed port) and compare final states; `tool/e2e_android_vs_ios.sh` prints PASS/FAIL. Existing AVD: `Medium_Phone_API_37.0`. Script `tool/e2e_android_vs_ios.sh` and test mode are prepared (KLD-038c); blocked on 🧑 Android cmdline-tools + licenses | 032, 037b, 🧑 Android cmdline-tools + licenses | `klunki/integration_test/**`, `tool/e2e_*`, `klunki/pubspec.yaml` (`integration_test` SDK dev dep only), small test-mode hook (path decided in the card) | 🧑 |
| KLD-038b | The same on real devices: iPhone/iPad ↔ Android phone over Wi-Fi | 038a, 011, 012, 040, 035 | `tool/e2e_*` (device variant) | 🧑 |
| KLD-038c ✅ | Mobile integration tests on iOS simulators: `integration_test/app_test.dart` (menu, all five games hot-seat, language picker, plugins) PASS on iPhone 18 Pro and iPad Pro 11-inch; `tool/e2e_ios_sims.sh` iPhone hosts ↔ iPad joins Mühle PASS via address and via mDNS (`--mdns`); test mode `lib/app/test_mode.dart` (see card) | 037b | `klunki/integration_test/**`, `tool/e2e_*` | – |

## i18n

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| I18N-01 ✅ | gen-l10n setup (`l10n.yaml`, ARB files for de/en/fr/es/zh/ar/fa), persisted `LocaleController` (`shared_preferences`, system default), language picker in the menu AppBar | – | `klunki/l10n.yaml`, `klunki/lib/l10n/**`, `klunki/lib/ui/language_picker.dart`, `klunki/lib/app/klunki_app.dart`, `klunki/lib/main.dart`, `klunki/pubspec.yaml`, `klunki/test/l10n/**` | – |
| I18N-02 ✅ | Extract all UI strings into ARB; `de` is the template, `en` complete (incl. pairing strings) | 01 | `klunki/lib/l10n/*.arb`, `klunki/lib/ui/**` | – |
| I18N-03 ✅ (machine translation, native review pending) | fr/es/zh-Hans/ar/fa machine translations, flagged for native review | 02 | `klunki/lib/l10n/*.arb` | 🧑 native review |
| I18N-04 ✅ RTL + Arabic font offline; Chinese font offline still open | RTL polish for ar/fa (game boards stay LTR) + CJK/Arabic fonts bundled for the offline PWA | 02 | `klunki/lib/ui/**`, `klunki/pubspec.yaml` (fonts), `klunki/web/**` | – |
| I18N-05 ✅ | Localize engine result reasons + Quartett set names, card names, stat labels/units + Schiffe ship names (covers KLD-028; leftovers from I18N-02) | 02 | `packages/klunki_engine/**` (reason codes), `klunki/lib/ui/**`, `klunki/lib/l10n/*.arb` | – |
| I18N-06 ✅ | PWA language check: ARB key coverage + glyph coverage tests, `?lang=` URL hook in `LocaleController`, headless check script `klunki/tool/pwa_i18n_check.sh`, pairing-screen overflow fix | 03, 04 | `klunki/test/l10n/**`, `klunki/lib/l10n/locale_controller.dart`, `klunki/tool/pwa_i18n_check.*`, `klunki/lib/ui/pairing/pairing_screen.dart`, `docs/DEMO.md` | – |
| I18N-07 ✅ | Chinese font offline for the PWA: bundled Noto Sans SC subset (Regular + Bold, OFL) covering the UI strings plus 简体中文, in the font fallback chain; strict glyph tests; `tool/update_web_fonts.py` regenerates the subset (see `docs/tasks/I18N-07-08-offline-fonts.md`) | 03, 04 | `klunki/assets/fonts/**`, `klunki/pubspec.yaml` (fonts), `klunki/lib/app/fonts.dart`, `klunki/web/**`, `klunki/tool/update_web_fonts.py` | – |
| I18N-08 ✅ | Bundled Roboto (Regular/Medium/Bold, OFL) plus a Noto Sans Math subset for arrows, dashes and ellipsis, so the offline PWA shows Latin text and the 'X' inside ar/fa text on a first visit without internet | 04 | `klunki/assets/fonts/**`, `klunki/pubspec.yaml` (fonts), `klunki/lib/app/fonts.dart`, `klunki/web/**` | – |

## New games

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-058a ✅ | **GoStrategy** (hidden-rank capture-the-flag, id `gostrategy`): engine (setup phase, per-player views, fights, two-square rule, move limit), `GoStrategyText` for the CLI/demo, registered for `klunki host gostrategy`; see `docs/tasks/KLD-058-gostrategy.md` | – | `packages/klunki_engine/**`, `packages/klunki_net/lib/src/cli/cli.dart`, `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/l10n/**`, `klunki/lib/ui/shell/screen_registry.dart` | – |
| KLD-064 ✅ | Real secrecy for hidden-information games over the network: host-authoritative redaction (guest holds only its own view: `SchiffeView` / `QuartettView` / `GoStrategyView`), salted SHA-256 commitments to the host's setup / Quartett seed, `reveal` at the end + full replay check on the guest ("Spielverlauf konnte nicht bestätigt werden"), protocol v2; see `docs/tasks/KLD-064-hidden-info-secrecy.md` | 057, 058a | `packages/klunki_engine/lib/{secrecy,*_view}.dart`, `packages/klunki_net/**`, `klunki/lib/transport/**`, `klunki/lib/game/game_controller.dart`, `klunki/lib/ui/games/{quartett_*,schiffe/schiffe_board}.dart`, `klunki/lib/ui/pairing/network_game_session.dart`, `klunki/lib/l10n/**`, `klunki/lib/net/join_payload.dart` | – |
| KLD-058b ✅ | GoStrategy screen: setup editor (shuffle, swap by tapping, Fertig, piece counts + legend), board from `viewFor(me)` turned so the own army is at the bottom, tap piece → `targetsFrom`, fight reveal (static with reduced motion, outcome also on the hot-seat cover), armies panel + move-limit hint, olive accent + menu illustration, piece names in 7 locales; `appReady: true` | 058a, 021 | `klunki/lib/ui/games/gostrategy*`, `klunki/lib/ui/shell/{screen_registry,game_screen,handover_cover}.dart`, `klunki/lib/ui/{game_titles,game_visuals,game_illustrations}.dart`, `klunki/lib/app/theme.dart`, `klunki/lib/l10n/**`, `klunki/assets/fonts/NotoSansSC/**`, `packages/klunki_engine/lib/registry.dart`, `klunki/test/**` | 🧑 manual check on a device |
| KLD-069 ✅ | Quartett decks: `QuartettDeck` model + registry (cars, trains, rockets, planes; 32 cards = 8 sets × 4, 5–6 stats each, validation + tie rates), `GameConfig.deck` (public with a secret seed, old configs = cars), `QuartettView` names the deck, CLI/debug `--deck`; app: deck picker before hot-seat Quartett and in the host setups (remembered via shared_preferences), drawn pictograms per deck, deck name in the game title, view-only card gallery ("Karten ansehen": decks → sets → full card pager, Top 5 per stat); see `docs/tasks/KLD-069-quartett-decks.md` | 064, 062 | `packages/klunki_engine/lib/{quartett,quartett_decks,quartett_view,registry}.dart`, `packages/klunki_engine/lib/debug/**`, `packages/klunki_engine/bin/klunki.dart`, `packages/klunki_net/lib/src/{host,guest,secrecy/secrecy,cli/cli}.dart`, `klunki/lib/ui/games/quartett_*`, `klunki/lib/ui/{engine_l10n,menu_screen}.dart`, `klunki/lib/ui/shell/screen_registry.dart`, `klunki/lib/ui/pairing/{pairing_screen,relay_host_screen,web_join_screen}.dart`, `klunki/lib/profile/quartett_deck_settings.dart`, `klunki/lib/l10n/**` (one `quartett*` block at the end), `klunki/assets/fonts/NotoSansSC/**` | – |
| KLD-081 ✅ | GoStrategy setup on the real board (step 1 of the user feedback): the editor is the 10×10 play board (same widget/orientation, turned for O, lakes, neutral rows, enemy rows dimmed and empty), tap-swap plus drag & drop with refused targets shown, draft keyed by engine squares (`setupFromSquares`, wire format unchanged), coordinates a–j / 1–10 in setup and play, selection ring drawn above the piece; no mapping bug (presentation only); rules checked, attacks confirmed with regression tests. Steps 2 (figurative pieces) and 3 (attack marker, preview → confirm turn flow) parked; see `docs/tasks/KLD-081-gostrategy-setup-on-board.md` | 058b, 064 | `packages/klunki_engine/lib/gostrategy.dart`, `klunki/lib/ui/games/gostrategy/gostrategy_board.dart`, `klunki/lib/l10n/**`, `klunki/test/**` | 🧑 browser check |

## Long-term games

| ID | Task | Notes |
|---|---|---|
| KLD-059 | **Schach** (chess, id `chess`): standard rules incl. castling, en passant, promotion, check/mate/stalemate, draw rules; see `docs/tasks/KLD-059-chess.md` | 2 players, fits the current protocol |
| KLD-060 | **Immobilien-Spiel** (property-trading dice game, working title, id `property`): dice, buying/rent/houses, cards, bankruptcy; see `docs/tasks/KLD-060-property-game.md` | large; 2–n players needs protocol/lobby work |
| KLD-061 | **Hotelspiel** (hotel-building dice game, working title, id `hotel`): hotel lots on a track, buildings + extras, permit die, overnight fees, bankruptcy; see `docs/tasks/KLD-061-hotel-game.md` | shares a possible "board-economy" core with 060; 2–4 players needs protocol/lobby work |
| KLD-079 | **Pause and resume games**: hot-seat auto-save after each move and on app background, plus a "Fortsetzen" list in the menu. Network resume: the host hosts the saved log again with the same token (relay: a resumable room secret); the KLD-064 salts and secrets are saved; versioned saves (`rulesVersion`), with `shared_preferences`, files or IndexedDB. See `docs/tasks/KLD-079-pause-resume.md` | after 071, 072 (stable PRNG), 074; important for 059–061 |

## Look & feel

| ID | Task | Priority | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|---|
| KLD-062 ✅ | Visual baseline: warm "Spieltisch" theme (light + dark, `KlunkiPalette` theme extension with per-game accents and board materials, preset structure), menu as a tile grid with drawn illustrations + one-liners, accent app bars, turn pill with player tokens, wood/sea/blue boards, card styling, reduced-motion handling. UX-REVIEW done: 1.1 (one-liners, no rules sheet yet), 1.2 (eye-off badge), 2.1 (player token in status + result), 2.10 (ring on O pieces), 5.2 partly (live regions = quick win 9, reduced motion), quick win 11 partly (Debug-Konsole demoted). See `docs/tasks/KLD-062-visual-design.md` | medium | – | `klunki/lib/app/theme.dart`, `klunki/lib/ui/**`, `klunki/lib/l10n/**` (9 `menu*` keys after `menuGameSchiffe`), `klunki/test/app/theme_test.dart`, `klunki/test/screenshots/**` | – |
| KLD-063 | Selectable themes: more `KlunkiPreset`s (e.g. "Klassisch", "Nacht", "Pastell", high contrast) + picker in settings, persisted via `shared_preferences` (like the language) | low/medium | 062 | `klunki/lib/app/theme.dart`, `klunki/lib/app/klunki_app.dart`, new settings UI | – |
| KLD-067 ✅ | Turn colour: status pill filled with the colour of the player to move (black/white text by contrast), coloured turn edge under the app bar, network "my turn" (filled, glow, one pulse + light haptic) vs "waiting" (muted, hourglass, faded opponent colour), hot-seat legend with both players' tokens + names, connection bar with a token per player; per-game hook `playerColor` / `GameVisuals.token` (GoStrategy); reduced motion respected. See `docs/tasks/KLD-067-turn-colour.md` | medium | 062 | `klunki/lib/ui/shell/game_screen.dart`, `klunki/lib/ui/pairing/network_game_session.dart`, `klunki/lib/ui/game_visuals.dart`, `klunki/lib/app/theme.dart`, `klunki/lib/l10n/**` (2 `netBar*` keys after `pairingStatus`) | – |
| KLD-066 | Start/welcome screen "Klunki – deine Spielesammlung für die Hosentasche" (wordmark, tagline, playful intro animation, reduced motion), later also native launch screen and PWA splash; see `docs/tasks/KLD-066-start-screen.md` | medium-low | 062 | `klunki/lib/ui/start_screen.dart`, `klunki/lib/l10n/**`, later `klunki/web/**`, launch assets | 🧑 for native launch assets |
| KLD-068 ✅ | Better Schiffe placement: local editable layout, "Zufällig" sets the whole fleet, then select (tap), move (drag or tap a cell), rotate (tap again or "Drehen" ↻ with orientation), remove to the harbour, "Zurücksetzen"; live green/red footprint, red flash + shake + hint on invalid moves; "Fertig" submits the usual `place` moves (protocol and KLD-064 redaction unchanged); network guest can arrange early. See `docs/tasks/KLD-068-schiffe-placement.md` | medium | 026, 062, 064 | `klunki/lib/ui/games/schiffe/**`, `packages/klunki_engine/lib/schiffe.dart` (layout helpers), `klunki/lib/l10n/**` (15 `schiffe*` keys after `schiffeMoveFire`) | – |

## Review 2026-10

From `docs/REVIEW-2026-10.md`, in order of value per effort (the "Top 10" there). Open unless marked ✅. Renumbered on merge (the review's 069–072 collided with KLD-069 Quartett decks and KLD-070 CI; its CI card is a note on the KLD-070 row under Infrastructure); its resign × secrecy card is ✅ done in the KLD-065 merge `a6bc0ab`.

| ID | Task | Priority | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|---|
| KLD-071 ✅ | Rejoin only with the session token (review S1): no name fallback, constant-time compare, hello deadline; clear "Platz belegt" in the app and CLI. See `docs/tasks/KLD-071-rejoin-token.md` | 🔴 | – | `packages/klunki_net/lib/src/{host,cli/cli}.dart`, `PROTOCOL.md`, `klunki/lib/ui/pairing/{relay_errors,pairing_screen,web_join_screen}.dart`, `klunki/lib/l10n/**` | – |
| KLD-073 | Shell guards: leave confirmation (`PopScope`), no undo in hidden-information hot-seat games, a start cover, a tap guard on the cover | high | 065 merged | `klunki/lib/ui/shell/**`, `klunki/lib/game/game_controller.dart`, `klunki/lib/ui/pairing/network_game_session.dart` | – |
| KLD-072 | Unguessable hidden setups: 128-bit secure seeds or explicit layouts, and an engine-owned PRNG (also stable replays) | high | 065 merged | `packages/klunki_engine/lib/**`, `klunki/lib/ui/shell/game_screen.dart`, `klunki/lib/ui/games/schiffe/**`, CLI | – |
| KLD-075 ✅ | Links and QR codes no longer silently replace the saved relay (review S3): "Relay aus Link: …" for that join only, "Als Standard speichern", foreign-relay warning in the PWA. See `docs/tasks/KLD-075-relay-links.md` | 🟠 | – | `klunki/lib/ui/pairing/{room_join,web_join_screen}.dart`, `klunki/lib/l10n/**` | – |
| KLD-074 | App background/resume: guest auto-reconnect, relay room grace period, host listener check | medium | 071 | `klunki/lib/transport/**`, `packages/klunki_net/lib/src/**` | 🧑 device check |
| KLD-076 | Release basics: icons, launch screens, signing, About/licences, Info.plist l10n, encryption key, PWA update prompt | medium | 053, 012, 066 | `klunki/ios/Runner/**` (never pbxproj/xcscheme/Main.storyboard), `klunki/android/**`, `klunki/web/**` | 🧑 licence, keys, team |
| KLD-077 | Accessibility pass: Four in a Row and mill semantics, announcements, keyboard on the web, contrast, battleship target size | medium | 068, 058b | `klunki/lib/ui/**`, `klunki/lib/app/theme.dart` | – |
| KLD-078 | Game modules (one registration point per game), typed `NetErrorCode`, pairing controller deduplication, i18n cleanup (unused keys, plurals, generic title instead of "4 Gewinnt") | medium | 058b merged | `klunki/lib/ui/**`, `packages/klunki_net/lib/src/events.dart`, `klunki/lib/l10n/**` | – |

## Infrastructure

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-070 ✅ | GitHub Actions: `ci.yml` (engine/net `dart analyze --fatal-infos` + `dart test`, app gen-l10n check + `flutter analyze` + `flutter test`; push main + PRs) and `build.yml` (PWA build + finalize + no-CDN-URL check → artifact `klunki-pwa`; Android release APK, debug-signed unless `KEYSTORE_*` secrets → `klunki-android-apk`; iOS `--no-codesign` compile check on manual runs only; Pages deploy disabled). Flutter 3.47.8 pinned, actions SHA-pinned. Release signing from `key.properties` / env with debug fallback. Moderate lints (`strict-casts`, `cancel_subscriptions`, `unawaited_futures` in the packages). Flaky loopback widget tests fixed (2 s keepalive vs long synchronous pumps → 10 s in widget tests). `docs/BUILDING.md`. **Android CI build unverified until first run on GitHub.** See `docs/tasks/KLD-070-ci.md`. Review 2026-10 note (its CI card, T1/T4/C8), still open: `flutter build web` + `pwa_finalize.py` in CI is done; open are a font-subset currency check, an unused-ARB-key check, and the stricter lint set (`strict-inference`, `strict-raw-types`, `close_sinks`, `avoid_dynamic_calls`, `only_throw_errors`; about 190 findings on a trial run) | – | `.github/workflows/**`, `klunki/android/app/build.gradle.kts`, `klunki/tool/check_pwa_external_urls.py`, `**/analysis_options.yaml`, `klunki/test/{ui/pairing/pairing_test_utils,e2e/e2e_support,e2e/muehle_screens_e2e_test,ui/shell/resign_test}.dart`, `docs/BUILDING.md`, `README.md` | 🧑 push; optional signing secrets |

## Backlog

| ID | Task | Notes |
|---|---|---|
| KLD-050 | Lobby / game code over local Wi-Fi (code in mDNS TXT record) | after 033 |
| KLD-051 | Internet lobby/relay (code → session, WebSocket relay; makes PWA networkable). The LAN relay exists since KLD-057a (`klunki relay`); what remains is internet hosting (TLS/`wss`, rate limits per IP, abuse review). REVIEW-2026-10 S4 adds: per-IP caps on rooms, sockets and joins, 6–7 character codes, an absolute room lifetime, an `Origin` allow-list and a frame cap; fix KLD-069 first | hosting + privacy review 🧑 |
| KLD-027 | Rename the engine's `Card` to `QuartettCard` (clashes with Flutter's `Card`; today every Flutter file needs `hide Card`) | after the screen wave (022–026), touches many files |
| ~~KLD-028~~ | German result reasons in the UI (engine reasons are English, e.g. "four in a row") | superseded by I18N-05 ✅ |
| KLD-029 | Quartett handover after the trick reveal even when the same player continues (the opponent watched the reveal) | after 024 |
| KLD-053 | Android release signing (keystore) instead of the debug keys. Gradle part done in KLD-070 (`key.properties` / `KLUNKI_KEYSTORE_*`, debug fallback); remaining: 🧑 creates the keystore, optional CI secrets | 🧑 chooses passwords, keeps the keystore |
| KLD-082 | **Quartett media**: Wikipedia links (de/en) and free-licence Wikimedia Commons photos on the cards, credit dialog "ⓘ" and "Bildnachweise", `url_launcher`; reusable `klunki/tool/fetch_card_media.py`. **Rockets ✅** (32/32 photos, 1.09 MB); also the stat format fix ("1999,0") and the year stats replaced (Gebaut / Erfolgsquote). Cars, trains, planes: KLD-084 ✅. See `docs/tasks/KLD-082-quartett-media.md` | photos need a look per deck |
| KLD-084 ✅ | **Quartett photos for the other decks** (KLD-082 pipeline): Wikipedia links and free Commons photos, credits, "Bildnachweise". **Planes ✅** (32/32, 0.95 MB) · **trains ✅** (32/32, 1.0 MB) · **cars ✅** (32/32, 1.03 MB); all 128 cards have a photo. One commit per deck. See `docs/tasks/KLD-084-deck-photos.md` | every JPEG looked at; no app code change |
| KLD-069b | More Quartett decks (follow-up to KLD-069): ships, animals, dinosaurs, planets; each = one `QuartettDeck.build` + ARB set names + a pictogram (see "How to add a deck" in `docs/tasks/KLD-069-quartett-decks.md`) | data needs a source check like the KLD-069 decks |

## Waves (what can run in parallel)

1. **Now:** KLD-010, KLD-020, KLD-030, KLD-041 (+ audits for 011/012)
2. After 020: KLD-021 · after 030: KLD-031 · after 020+030: KLD-032
3. After 021: KLD-022, 023, 024, 026 in parallel (025 after 024)
4. After 🧑 steps: KLD-012 → 033 → 040 → 034 (iPhone ↔ iPad first), then KLD-011 → 035 (Android ↔ iOS), then 036
5. E2E: KLD-037a now (pure Dart); 037b after 032; 038a after 037b + 🧑 Android cmdline-tools; 038b after 038a + all device tasks

Legend: ✅ done · 🚧 in progress (an agent is on it).

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

## Backlog

| ID | Task | Notes |
|---|---|---|
| KLD-050 | Lobby / game code over local Wi-Fi (code in mDNS TXT record) | after 033 |
| KLD-051 | Internet lobby/relay (code → session, WebSocket relay; makes PWA networkable) | hosting + privacy review 🧑 |
| KLD-027 | Rename the engine's `Card` to `QuartettCard` (clashes with Flutter's `Card`; today every Flutter file needs `hide Card`) | after the screen wave (022–026), touches many files |
| ~~KLD-028~~ | German result reasons in the UI (engine reasons are English, e.g. "four in a row") | superseded by I18N-05 ✅ |
| KLD-029 | Quartett handover after the trick reveal even when the same player continues (the opponent watched the reveal) | after 024 |
| KLD-052 | QR *scanning* to join (camera plugin + camera permissions on Android and iOS) | after 033/034; 🧑 OK for plugin + permissions |
| KLD-053 | Android release signing (keystore) instead of the debug keys | 🧑 chooses passwords, keeps the keystore |

## Waves (what can run in parallel)

1. **Now:** KLD-010, KLD-020, KLD-030, KLD-041 (+ audits for 011/012)
2. After 020: KLD-021 · after 030: KLD-031 · after 020+030: KLD-032
3. After 021: KLD-022, 023, 024, 026 in parallel (025 after 024)
4. After 🧑 steps: KLD-012 → 033 → 040 → 034 (iPhone ↔ iPad first), then KLD-011 → 035 (Android ↔ iOS), then 036
5. E2E: KLD-037a now (pure Dart); 037b after 032; 038a after 037b + 🧑 Android cmdline-tools; 038b after 038a + all device tasks

Legend: ✅ done · 🚧 in progress (an agent is on it).

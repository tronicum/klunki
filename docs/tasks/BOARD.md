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
| KLD-011 | **Android:** debug build + run on the one Android phone (no emulator); app label "Klunki"; `INTERNET` permission in the main manifest | Android Studio install (approved) + 🧑 setup wizard, licenses, USB debugging | `klunki/android/**` | 🧑 |
| KLD-012 | **iOS (priority):** build + run on simulator (KLD-012a), then iPhone + iPad; signing team | 🧑 `xcode-select --switch`, Apple ID, Developer Mode | `klunki/ios/**` | 🧑 |

## P2 — Hot-seat on one device

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-020 ✅ | Typed `GameTransport` (matches `docs/ARCHITECTURE.md`) + `HotSeatTransport` that applies moves through the engine + `GameController` (ChangeNotifier) + game registry (id → factory, title) | – | `klunki/lib/transport/**`, `klunki/lib/game/**`, `klunki/test/game/**` | – |
| KLD-021 ✅ | Shared UI shell: `GameScreen` frame (status line, result dialog, move history sheet, new game), `HandoverCover` ("pass the phone to O"), menu → game routing with one placeholder screen per game | 020 | `klunki/lib/ui/shell/**`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/ui/games/*_screen.dart` (placeholders), `klunki/test/ui/shell/**` | – |
| KLD-022 | Connect Four screen (tap a column, drop animation, winning line highlight) | 021 | `klunki/lib/ui/games/connect4_screen.dart`, `klunki/test/ui/games/connect4*` | – |
| KLD-023 | Mühle screen (board painter, tap to place/move/remove, mill highlight, phase hints) | 021 | `klunki/lib/ui/games/muehle_screen.dart`, `klunki/test/ui/games/muehle*` | – |
| KLD-024 | Quartett Trumpf screen (top card with stats, tap a stat, trick reveal, pot) + handover | 021 | `klunki/lib/ui/games/quartett_trumpf_screen.dart`, `klunki/lib/ui/games/quartett_card.dart`, `klunki/test/ui/games/quartett_trumpf*` | – |
| KLD-025 | Quartett Sets screen (hand grouped by set, ask for a card, quartets laid down) + handover | 021, 024 (`quartett_card.dart`) | `klunki/lib/ui/games/quartett_sets_screen.dart`, `klunki/test/ui/games/quartett_sets*` | – |
| KLD-026 | Schiffe versenken screen (fleet placement with rotate + random, own grid + target grid, tap to fire) + handover | 021 | `klunki/lib/ui/games/schiffe_screen.dart`, `klunki/test/ui/games/schiffe*` | – |

## P3 — iPhone ↔ iPad over Wi-Fi

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-030 ✅ | `packages/klunki_net` (pure Dart): NDJSON protocol (`hello`, `move`, `accepted`, `rejected`, `snapshot`, `ping`, `bye`), host-authoritative TCP session, replay from seed + move list, loopback tests | – | `packages/klunki_net/**` | – |
| KLD-031 | Terminal networking: `klunki host <game>` / `klunki join <ip>` — two terminals play each other through the `DebugConsole` | 030 | `packages/klunki_net/bin/**`, `packages/klunki_net/test/cli*` | – |
| KLD-032 | `NetworkTransport` in the app on top of `klunki_net` (same interface as `HotSeatTransport`) | 020, 030 | `klunki/lib/transport/network_transport.dart`, `klunki/test/transport/network*` | – |
| KLD-033 | Discovery service: advertise/browse `_klunki._tcp` via mDNS (`bonsoir`), manual IP:port fallback, QR payload | 030, 🧑 OK for the `bonsoir` + QR packages | `klunki/lib/net/**`, `klunki/pubspec.yaml`, `klunki/test/net/**` | 🧑 |
| KLD-034 | Pairing screen: host (shows name, IP, QR) / join (list + manual entry), then start the chosen game over `NetworkTransport` | 021, 032, 033 | `klunki/lib/ui/pairing/**`, `klunki/test/ui/pairing/**` | – |
| KLD-035 | Android networking for Android ↔ iOS: multicast lock + Wi-Fi/nearby permissions for discovery, release-build networking check | 011, 033 | `klunki/android/**` | 🧑 |
| KLD-036 | Disconnect / reconnect UX ("opponent left", resume from snapshot) | 034 | `klunki/lib/ui/pairing/reconnect*`, `klunki/lib/transport/network_transport.dart` | – |

## P4 — Android ↔ iOS (end of PoC)

| ID | Task | Depends on | Touched paths | 🧑 |
|---|---|---|---|---|
| KLD-040 | iOS local network: `NSLocalNetworkUsageDescription`, `NSBonjourServices` (`_klunki._tcp`), permission prompt flow, backgrounding → reconnect | 012, 033 | `klunki/ios/**` | 🧑 |
| KLD-041 | Demo runbook `docs/DEMO.md`: exact steps for the final demos (text, hot-seat, Android↔Android, Android↔iOS, PWA), device checklist, Wi-Fi pitfalls | – (update as tasks land) | `docs/DEMO.md` | – |

## Backlog

| ID | Task | Notes |
|---|---|---|
| KLD-050 | Lobby / game code over local Wi-Fi (code in mDNS TXT record) | after 033 |
| KLD-051 | Internet lobby/relay (code → session, WebSocket relay; makes PWA networkable) | hosting + privacy review 🧑 |

## Waves (what can run in parallel)

1. **Now:** KLD-010, KLD-020, KLD-030, KLD-041 (+ audits for 011/012)
2. After 020: KLD-021 · after 030: KLD-031 · after 020+030: KLD-032
3. After 021: KLD-022, 023, 024, 026 in parallel (025 after 024)
4. After 🧑 steps: KLD-012 → 040 (iPhone ↔ iPad) first, then KLD-011 → 035 (Android ↔ iOS); 033 → 034 → 036

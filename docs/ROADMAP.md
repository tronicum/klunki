# Klunki — Roadmap / Milestones

Each milestone is a shippable, demoable step. M0 is being built now.

## M0 — Scaffold & engine (in progress)
- [x] Monorepo scaffold: `packages/klunki_engine`, `klunki/` app, `docs/`.
- [ ] Pure-Dart engine for **Connect Four** with unit tests.
- [ ] Pure-Dart engine for **Mühle** with unit tests.
- [ ] Pure-Dart engine for **Quartett** with unit tests.
- [ ] `dart test` green for all engine packages.
- [ ] Flutter app shell: routes + stub game screens.
- **Exit criterion:** `dart test` passes; app boots to a game menu on web.

## M1 — Hot-seat single-device PoC
- [ ] Connect Four playable on one device, hand-to-hand.
- [ ] Mühle playable on one device.
- [ ] Simple AI opponent toggle for single-device practice.
- [ ] Win / draw / move-history UI.
- **Exit criterion:** full game loop works without a second device.

## M2 — Quartett
- [ ] Card set definition (deck + superlative rules).
- [ ] Quartett gameplay: ask / answer / steal-the-set turns.
- [ ] UI: deal, turn, answer prompt.

## M3 — Network (Android ↔ Android, same Wi-Fi)
- [ ] `NetworkTransport`: one host, one peer, over TCP/UDP on local IP.
- [ ] Host/peer role selection + connection screen.
- [ ] Move validation on both ends (single source of truth stays the engine).
- [ ] Latency / disconnect handling (reconnect, last-state).
- **Exit criterion:** two real Android phones play Connect Four.

## M4 — iOS parity + Polish
- [ ] Verify iOS toolchain; hot-seat works on iOS.
- [ ] Theming, onboarding, game selection screen, settings.

## M5 — PWA build
- [ ] `flutter build web` → PWA manifest, service worker (offline play).
- [ ] Connect Four, Mühle, Quartett work offline in a browser.

## M6 — Bluetooth transport (optional / stretch)
- [ ] `BluetoothTransport` using a stable BLE profile.
- [ ] Pairing + connection screen.

---

### Dependency order
M0 → M1 → M2 → M3 → M4 → M5 → M6. M2 can partly run parallel to M1.

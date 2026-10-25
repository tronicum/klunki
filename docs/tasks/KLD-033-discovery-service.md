# KLD-033 — Discovery service (mDNS `_klunki._tcp`, manual IP, QR payload)

- **ID:** `KLD-033`
- **Title:** Advertise/browse `_klunki._tcp` via mDNS (`bonsoir`), manual IP:port fallback, QR payload
- **Milestone:** P3 — two devices on the same Wi-Fi (first real devices: iPhone ↔ iPad)
- **Status:** TODO
- **Depends on:** KLD-030 (`packages/klunki_net`); 🧑 **the user's OK for the new packages** (`bonsoir` + a QR package)
- **Touched paths:**
  - `klunki/lib/net/**`
  - `klunki/pubspec.yaml`
  - `klunki/test/net/**`
  - `docs/tasks/KLD-033-discovery-service.md` (status only)

## Goal
The app can announce "I'm hosting Klunki on port N" on the local Wi-Fi and list such hosts on another device. Where mDNS
doesn't work, the host shows `IP:port` and a QR code that encodes the same data. All of this sits behind a small interface
that the pairing screen (KLD-034) uses and tests can fake.

## Repo context
- Flutter app `klunki/` (Flutter 3.47.8). `klunki/pubspec.yaml` currently depends on `flutter`, `cupertino_icons`, and
  `klunki_engine: {path: ../packages/klunki_engine}`.
- `packages/klunki_net` (KLD-030, pure Dart) owns the TCP session and its default port and protocol version. **Read it.**
- Platform setup lives elsewhere: Android permissions and multicast lock → KLD-035 (`klunki/android/**`); iOS `NSBonjourServices`
  / `NSLocalNetworkUsageDescription` → KLD-040 (`klunki/ios/**`). Without them, real-device discovery will fail. That's expected
  until those land. Unit tests don't need them.

## 🧑 Step 0: confirm dependencies (stop here first)
Before editing `pubspec.yaml`, report this list to the user and wait for an explicit OK:
- `bonsoir` (mDNS/DNS-SD advertise + discover; Android/iOS/macOS). Check pub.dev for the current stable version, platform support
  and the README's Android/iOS setup notes, and quote the README's required permissions in your report (KLD-035/040 need them).
- `qr_flutter` (render a QR code; pure Flutter, no permissions).
- `klunki_net: {path: ../packages/klunki_net}` (local, no download).
- **Not** in this card (board decision): QR *scanning*. This card only **shows** the QR. Scanning is backlog **KLD-052** (camera plugin + camera permissions on Android and iOS, needs the user's OK).
`flutter pub get` downloads packages: run it only after the OK.

## Acceptance criteria
- [ ] `lib/net/discovery.dart`: platform-neutral types:
  - `KlunkiHostInfo {String name, String host, int port, int protocol, String? gameId}` with equality;
  - `abstract class DiscoveryService { Future<void> advertise(KlunkiHostInfo me); Future<void> stopAdvertising();
    Stream<List<KlunkiHostInfo>> browse(); Future<void> stopBrowsing(); }`;
  - constant `klunkiServiceType = '_klunki._tcp'`.
- [ ] `lib/net/bonsoir_discovery.dart`: the `bonsoir` implementation. TXT record keys: `v` (protocol version), `game` (optional),
      `name`. It resolves services to host + port and handles services appearing and disappearing.
- [ ] `lib/net/fake_discovery.dart` (or in tests): an in-memory implementation for widget tests (KLD-034 uses it).
- [ ] `lib/net/join_payload.dart` (pure Dart, no Flutter imports): encode/decode the manual and QR payload, e.g.
      `klunki://join?h=192.168.1.20&p=47474&v=1&n=Stefans%20iPhone`. `tryParse` also accepts plain `192.168.1.20:47474` and `192.168.1.20`
      (default port from `klunki_net`). Invalid input → `null`.
- [ ] `lib/net/local_ip.dart`: lists candidate LAN IPv4 addresses (`NetworkInterface.list()`), preferring `en0`/`wlan0`, skipping loopback and link-local.
- [ ] Web build keeps compiling: nothing under `lib/net/` that uses `dart:io` or `bonsoir` is imported from web code paths.
      Provide `DiscoveryService? createDiscovery()` that returns `null` on web (`kIsWeb`) via a conditional import.
- [ ] Tests in `klunki/test/net/`: `join_payload` round trips and rejects garbage; the fake discovery emits add and remove; `local_ip`
      filtering on a stubbed interface list. (No real mDNS in `flutter test`: platform channels aren't available there.)
- [ ] `cd klunki && flutter analyze && flutter test` are green; `flutter build web` still compiles (no web-incompatible imports reachable).

## Constraints
- **Board rule:** never install toolchains, download SDK components, accept licenses, sign up for accounts or publish anything without the
  user's explicit OK. Adding pub.dev packages only after the user confirmed the list in Step 0.
- Only touch the paths above. No Android/iOS manifest or plist edits (KLD-035/040). Don't commit unless asked.

## Hints / context
- mDNS needs, on Android: `CHANGE_WIFI_MULTICAST_STATE` + a multicast lock (bonsoir may acquire it itself; check its README).
  On iOS 14+: `NSBonjourServices` containing `_klunki._tcp` and `NSLocalNetworkUsageDescription`, or browsing silently returns nothing.
- Service names must be unique on the network. Use the device or host name plus a short random suffix.
- On-device check (only once 035/040 landed): host on one device, browse on another, and the entry appears within ~3 s.

## Definition of done
```bash
cd klunki
flutter pub get        # only after the 🧑 OK
flutter analyze
flutter test test/net/
flutter test
flutter build web      # still compiles
```
All green; card status set to DONE.

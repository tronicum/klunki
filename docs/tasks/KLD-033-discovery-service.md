# KLD-033 — Discovery service (mDNS `_klunki._tcp`, manual IP, QR payload)

- **ID:** `KLD-033`
- **Title:** Advertise/browse `_klunki._tcp` via mDNS (`bonsoir`), manual IP:port fallback, QR payload
- **Milestone:** P3 — two devices on the same Wi-Fi (first real devices: iPhone ↔ iPad)
- **Status:** DONE
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
- [x] `lib/net/discovery.dart`: platform-neutral types:
  - `KlunkiHostInfo {String name, String host, int port, int protocol, String? gameId}` with equality;
  - `abstract class DiscoveryService { Future<void> advertise(KlunkiHostInfo me); Future<void> stopAdvertising();
    Stream<List<KlunkiHostInfo>> browse(); Future<void> stopBrowsing(); }`;
  - constant `klunkiServiceType = '_klunki._tcp'`.
- [x] `lib/net/bonsoir_discovery.dart`: the `bonsoir` implementation. TXT record keys: `v` (protocol version), `game` (optional),
      `name`. It resolves services to host + port and handles services appearing and disappearing.
- [x] `lib/net/fake_discovery.dart` (or in tests): an in-memory implementation for widget tests (KLD-034 uses it).
- [x] `lib/net/join_payload.dart` (pure Dart, no Flutter imports): encode/decode the manual and QR payload, e.g.
      `klunki://join?h=192.168.1.20&p=47474&v=1&n=Stefans%20iPhone`. `tryParse` also accepts plain `192.168.1.20:47474` and `192.168.1.20`
      (default port from `klunki_net`). Invalid input → `null`.
- [x] `lib/net/local_ip.dart`: lists candidate LAN IPv4 addresses (`NetworkInterface.list()`), preferring `en0`/`wlan0`, skipping loopback and link-local.
- [x] Web build keeps compiling: nothing under `lib/net/` that uses `dart:io` or `bonsoir` is imported from web code paths.
      Provide `DiscoveryService? createDiscovery()` that returns `null` on web (`kIsWeb`) via a conditional import.
- [x] Tests in `klunki/test/net/`: `join_payload` round trips and rejects garbage; the fake discovery emits add and remove; `local_ip`
      filtering on a stubbed interface list. (No real mDNS in `flutter test`: platform channels aren't available there.)
- [x] `cd klunki && flutter analyze && flutter test` are green; `flutter build web` still compiles (no web-incompatible imports reachable).

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

## Result

**Packages** (the user approved them; every resolved version is at least two weeks old on 2026-10-25):
- `bonsoir: 7.1.5` (2026-08-11), pinned exactly. 7.1.6 and its federated packages came out on 2026-10-25, which is too fresh.
  The lock holds the matching federated set: `bonsoir_darwin 7.1.1`, `bonsoir_android 7.1.3`, `bonsoir_platform_interface 7.0.0`,
  `bonsoir_windows 7.3.0`, `bonsoir_linux 7.1.0` (taken with `flutter pub downgrade bonsoir_*` because caret ranges picked the
  same-day releases). A later `flutter pub upgrade` would move those four. Transitive: `dbus`, `ffi`, `xml`, `petitparser`,
  `plugin_platform_interface`.
- `qr_flutter: ^4.1.0` (4.1.0, plus `qr 3.0.2`). Pure Flutter, no permissions.
- **iOS SPM:** `bonsoir_darwin` ships `darwin/bonsoir_darwin/Package.swift` (iOS 13+; the app targets 15.0). It shows up in
  `FlutterGeneratedPluginSwiftPackage` and `flutter build ios --simulator --debug` links it. No CocoaPods and no Podfile.

**Platform setup still needed** (not done here):
- iOS (KLD-040), `Info.plist`: `NSLocalNetworkUsageDescription` (string) and `NSBonjourServices` (array) = [`_klunki._tcp`].
- Android (KLD-035): bonsoir's own manifest declares `INTERNET` and `CHANGE_WIFI_MULTICAST_STATE`, and they merge in automatically.
  bonsoir also takes a `WifiManager.MulticastLock` itself (reference-counted). Optionally declare both in the app manifest too.

**API** (`klunki/lib/net/`):
- `discovery.dart` (pure Dart, web-safe): `klunkiServiceType = '_klunki._tcp'`, `KlunkiTxt` keys `v`/`game`/`name`,
  `KlunkiHostInfo {name, host, port, protocol, gameId?}` (== / hashCode / copyWith), and `abstract class DiscoveryService`
  { `advertise(KlunkiHostInfo me)`, `stopAdvertising()`, `browse()` → `Stream<List<KlunkiHostInfo>>` (each listener first gets
  the current list; this device's own ad is hidden), `stopBrowsing()` (emits `[]`), `dispose()` }. Also `HostListBroadcaster`,
  `klunkiTxtRecord`, `hostInfoFromTxt`. A missing or bad `v` gives protocol 0.
- `bonsoir_discovery.dart`: `BonsoirDiscoveryService`. The service name is `"<name> #xxxx"` (a random hex suffix, kept to
  63 bytes), and the clean name travels in TXT `name`. Found → resolve. Resolved/Updated → put (IPv4 address preferred).
  Lost → remove.
- `fake_discovery.dart`: `FakeNetwork` + `FakeDiscovery({network, address})`. Instances on one network see each other.
  Tests can call `addHost`/`removeHost`, and `advertised`/`advertiseCalls`/`isBrowsing` are there for assertions.
- `discovery_factory.dart`: `DiscoveryService? createDiscovery()`, a conditional import. It returns bonsoir on
  Android/iOS/macOS and `null` on web and other platforms.
- `local_ip.dart`: `localIPv4Addresses()` (conditional `dart:io`; `[]` on web) and the pure
  `rankLocalIPv4(List<LocalInterface>)`. It drops loopback, link-local, unspecified addresses and duplicates, then ranks
  `en0`/`wlan0` → private ranges → the rest.
- `join_payload.dart` (pure Dart): `JoinPayload {host, port=4747, protocol=1, name?, gameId?}`, `format()` →
  `klunki://join?h=192.168.1.20&p=4747&v=1&n=Stefans+iPhone&g=muehle`, `tryParse` (URI, `ip:port`, `ip`, host names; IPv6 not
  supported), `fromHostInfo`/`toHostInfo`. `klunkiDefaultPort = 4747` and `klunkiProtocolVersion = 1` are copies of `klunki_net`'s
  values (importing `klunki_net` would pull `dart:io` into web). A test checks the protocol copy.
- `join_qr.dart`: `JoinQrCode(payload, size, showAddress)`, a black-on-white QR plus a selectable `host:port`.

**Note for KLD-034:** `NetworkTransport.host` defaults to port 0, which is ephemeral. A plain IP with no port means 4747, so to make
"type just the IP" work, host on 4747 and fall back to 0 only if that port is busy. Show the real port in the QR and in the address line.

**Verification:** `flutter analyze`: no issues. `flutter test`: +144, all passed (57 in `test/net/`). `flutter build web`
passes, and so does a web build of a probe entrypoint that imports every `lib/net/` file. `flutter build ios --simulator --debug`
passes, with bonsoir linked through SPM.

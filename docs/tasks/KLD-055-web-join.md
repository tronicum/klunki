# KLD-055: PWA joins a native host over WebSocket (web pairing UI)

- **ID:** `KLD-055`
- **Title:** The browser PWA gets "Über WLAN spielen" (join-only over `ws://`); native hosts open and advertise the WebSocket port
- **Milestone:** P3/P4 (PWA multiplayer)
- **Status:** DONE
- **Depends on:** KLD-034 (pairing screen), KLD-054 (WebSocket in `klunki_net`)
- **Touched paths:**
  - `klunki/lib/ui/pairing/pairing_screen.dart` (WebSocket port, `w=` in QR/TXT, browser address + copyable link)
  - `klunki/lib/ui/pairing/web_join_screen.dart` (new), `klunki/lib/net/web_join_target.dart` (new)
  - `klunki/lib/ui/pairing/pairing_entry*.dart`, `klunki/lib/ui/menu_screen.dart`, `klunki/lib/app/klunki_app.dart` (`?join=`)
  - `klunki/lib/l10n/*.arb` (+ generated `app_localizations*.dart`)
  - `klunki/test/ui/pairing/**`, `klunki/test/net/web_join_target_test.dart`, `klunki/test/l10n/coverage_test.dart`
  - `docs/DEMO.md` (section "Browser spielt gegen iPhone/Terminal")

## Goal
User decision: the browser PWA joins a native host (iOS/Android app or `klunki host` CLI) over `ws://`
on the LAN; the PWA is served over http, so no wss. No browser host, no browser ↔ browser.
The PWA's multiplayer should be as close to the iOS app as the browser allows.

## Design
- **Native host.** `PairingDeps` gains `preferredWsPort` (default `klunkiDefaultWebSocketPort` = 4748);
  `HostTransportFactory` takes `wsPort`. Binding tries `(4747, 4748)`, then `(4747, 0)`, `(0, 4748)`,
  `(0, 0)`: a busy port falls back to a free one and the other keeps its default. The QR payload and the
  mDNS record carry the WebSocket port (`w=`, TXT `ws`). The waiting view adds "Im Browser beitreten":
  `IP:wsPort` plus the `klunki://` link as selectable text with a copy button (a browser cannot scan the
  QR code, and the device does not know the PWA's URL).
- **Web join screen** (`WebJoinScreen`, web-safe: no `dart:io`, no `bonsoir`). On web,
  `pairing_entry_stub.dart` returns it, so the menu shows "Über WLAN spielen" there too. Join-only: no host
  tab, no discovery list. Fields: device name (default "Browser"), address. The address accepts
  (`WebJoinTarget.tryParse`): `IP` → `ws://IP:4748`; `IP:port` (port = WebSocket port, said in the helper
  text); `klunki://join?…` (uses `w`, else 4748; shows host name and game before connecting);
  `ws://ip[:port]`; a pasted PWA URL with `?join=`. `wss://` and other schemes are refused. Join goes
  through `NetworkTransport.joinWebSocket`, with a 12 s overall timeout; failures and timeouts show the
  reason plus browser hints (same Wi-Fi, http not https, host version with browser support). An https page
  gets an up-front warning. Success replaces the route with the same `NetworkGameSession` the apps use
  (connection bar, leave banner, "Neu verbinden").
- **`?join=` at startup.** `KlunkiApp(pageUrl:)` (default `Uri.base` on web) reads `join`; `MenuScreen`
  pushes `WebJoinScreen(initialInput: link, autoConnect: true)` after the first frame, so "back" lands in
  the menu. `KlunkiApp.webJoinDeps` / `MenuScreen.webJoinDeps` are test hooks.
- **Strings.** New keys `pairingBrowserJoin`, `pairingCopyLink`, `pairingLinkCopied`, `webJoin*` in all
  7 ARB files (fr/es/zh/ar/fa machine-translated like the rest, flagged by the files' review marker).
  `pairingWebUnavailable` is gone (no longer reachable).

## Acceptance criteria
- [x] Native host opens a WebSocket port (4748, fallback 0) and puts `w=` into the QR payload and TXT `ws`
- [x] Host shows the browser address and a copyable `klunki://` link
- [x] Web: "Über WLAN spielen" opens a join-only screen; manual field accepts IP, IP:port (WS port), `klunki://` (with/without `w`), `ws://`
- [x] `?join=<urlencoded link>` opens the join flow and connects
- [x] Device name (default "Browser"), errors and timeouts with German hints (Wi-Fi, http not https, host version)
- [x] After joining: `NetworkGameSession` with connection bar, leave banner, "Neu verbinden"
- [x] All new strings in de/en/fr/es/zh/ar/fa; strings, translations, coverage (incl. the new screen at 390×844 and 360×640) tests green
- [x] Tests: parser (`test/net/web_join_target_test.dart`), web join screen widget tests for every input form,
      invalid input, failure + timeout hints, https warning, `?join=` startup, host QR/TXT `w=`, WS port fallback,
      and a loopback game: native `PairingScreen` host (TCP + WS) vs the web join screen through `joinWebSocket`,
      Four in a Row moves in both directions, leaving shows the host banner
- [x] Real browser: release web build + `klunki host connect4 --port 4747 --ws-port 4748` CLI + headless
      Firefox Nightly (WebDriver BiDi, same approach as `tool/pwa_i18n_check.mjs`) at
      `http://localhost:8099/?join=<klunki://join?h=127.0.0.1&p=4747&n=Terminal&g=connect4&w=4748>&lang=de`:
      the CLI printed "Browser joined", the CLI's move in column 3 showed in the browser, a click on column 4
      in the browser reached the CLI ("O drops into column 4"); the connection bar read
      "Du bist O · Gegner: Terminal (X)"
- [x] `docs/DEMO.md`: "Browser spielt gegen iPhone/Terminal"

## Constraints / notes
- No new dependencies. No changes to `klunki/ios/**`, `klunki/integration_test/**`, fonts.
- A web page cannot host or browse mDNS; browser ↔ browser stays out of scope.
- The service worker does not register on `http://<lan-ip>` (no secure context): browser multiplayer works
  while the PWA server is reachable; offline install stays a `localhost`/https thing.
- No `Origin` check on the host's WebSocket port (see `packages/klunki_net/PROTOCOL.md`, known limitations).
- In widget tests, `dart:io`'s `WebSocket.close()` arms a 5 s timer in the closing zone; the loopback test
  pumps past it.

## Definition of done
`cd klunki && flutter analyze && flutter test`; `cd packages/klunki_net && dart test`.

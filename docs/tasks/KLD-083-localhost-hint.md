# KLD-083: Localhost notice when hosting through the relay

- **ID:** `KLD-083`
- **Title:** Warn when the room link/QR would carry `localhost`; print and explain the reachable addresses
- **Status:** ✅ done
- **Depends on:** KLD-052 (relay line, `RelaySettings`), KLD-057a/b (relay, "Spiel hosten", room links)
- **Touched paths:**
  - `klunki/lib/net/room_link.dart` (`isLoopbackHost`, `loopbackHostOf`, IPv6 brackets in `relayAddressLabel`)
  - `klunki/lib/ui/pairing/relay_line.dart` (`LoopbackHint`, `LoopbackAddressHelp`), `relay_host_screen.dart`
  - `klunki/lib/l10n/**` (12 keys, one block at the end: `relayLoopback*`, `loopbackHow*`),
    `klunki/assets/fonts/NotoSansSC/**` (re-subset)
  - `packages/klunki_net/lib/src/relay/relay_server.dart` (dual-stack bind),
    `packages/klunki_net/lib/src/cli/{cli,open_urls}.dart` ("Open on other devices")
  - tests: `klunki/test/ui/pairing/loopback_hint_test.dart`, `klunki/test/net/room_link_test.dart`,
    `klunki/test/screenshots/screenshots_test.dart` (`kld083`), `packages/klunki_net/test/{cli,relay}_test.dart`
  - docs: `docs/BUILDING.md` §6.2, `docs/DEMO.md` (relay demo)

## Problem

The PWA uses its own origin as the relay. Opened as `http://localhost:8081/` (or `127.0.0.1`, `[::1]`), hosting
works on that machine, but the room link and QR code contain `localhost`, which other devices can't reach. A
browser can't find out its own LAN IP, so the app can't fix the link by itself.

## Decisions

**Only a warning.** Hosting on localhost stays allowed (two tabs on one machine is legitimate).

**Loopback** = `localhost`, `*.localhost`, `127.x.x.x`, `::1` (also bracketed, `0:…:1`, `::ffff:127.x`)
(`isLoopbackHost`). A LAN IP, a `.local` name or any other hostname is not.

**Where:**
- "Spiel hosten" waiting screen, right under the QR code and link (`relay-host-loopback`): the full notice in the
  browser, "Hinweis: Andere Geräte können „localhost“ nicht erreichen. Öffne die Seite über die WLAN-Adresse
  dieses Rechners (z. B. http://192.168.x.x:8081) oder seinen .local-Namen (z. B. http://my-computer.local:8081),
  damit Link und QR-Code auf anderen Geräten funktionieren." Checked against the link's host (the page) and the
  relay (`loopbackHostOf`). Natively (no page to reopen) the short form.
- Relay line in the join/host group (`relay-line-loopback`): the short form, "„localhost“ ist nur auf diesem
  Gerät erreichbar – andere Geräte brauchen die WLAN-Adresse oder den .local-Namen des Rechners." Also for a
  localhost relay typed in by hand in the app.
- Both carry a collapsed "Wie finde ich die Adresse?" (`loopback-how`): macOS, Windows, Linux (settings path,
  terminal command with a copy button, `.local` name) and the tip that the `klunki relay` console prints the
  addresses. Commands, hosts and URLs stay LTR (`bidiLtr`, LTR `Directionality`); commands are not translated.

**Examples stay generic** (`http://192.168.x.x:8081`, `http://my-computer.local:8081`).

**Relay CLI prints the reachable addresses** at startup (when bound to all interfaces):
```
Open on other devices:
  http://192.168.178.105:8081/            (Wi-Fi/LAN, en0)
  http://Stefans-MacBook-Pro.local:8081/  (Bonjour/mDNS name)
  (.local names work on Apple devices and most recent Windows, Android and Linux with Avahi; if not, use the IP address.)
```
LAN IPv4 addresses from `NetworkInterface.list()` without loopback, link-local `169.254.x.x` and recognisable
virtual interfaces (docker, br-, veth, virbr, vmnet, vboxnet, utun/tun/tap, awdl/llw, bridge, …). The mDNS name
on macOS from `scutil --get LocalHostName` (`Platform.localHostname` there is often the router's DNS name, e.g.
`Mac.fritz.box`), elsewhere `<first label of Platform.localHostname>.local`. Without `--web` the block shows the
`ws://…/relay` addresses.

**Dual-stack relay.** `RelayServer.start` without an address now binds `::` with `v6Only: false` (IPv4 `0.0.0.0`
as fallback where IPv6 is missing), because a `.local` name often resolves to an IPv6 address first. Verified on
macOS: `GET /` → 200 and a WebSocket upgrade → 101 on `<LocalHostName>.local` (IPv4 and IPv6), the LAN IPv4, the
IPv6 ULA, `127.0.0.1` and `[::1]`. `parseRelayUrl`/`relayUriForPage` already handled `.local` and bracketed
IPv6; `relayAddressLabel` now keeps the brackets (`[::1]:8081`).

## Tests

- `room_link_test`: loopback for localhost, 127.x, ::1 (also expanded / mapped), `foo.localhost`; not for LAN IPs,
  `.local`, hostnames, `localhost.example`; `loopbackHostOf` for page vs relay vs native; IPv6 labels.
- `loopback_hint_test`: relay line warns for localhost/127.0.0.1/::1/foo.localhost pages, not for LAN/`.local`/
  hostname pages; native localhost relay set and cleared; the help opens with all commands, copy works; RTL keeps
  host and commands LTR; waiting screen with a real relay: full notice under the link (localhost page), short
  notice natively (127.0.0.1), none for a LAN page.
- `klunki_net`: CLI address filtering, mDNS name, aligned block; dual-stack relay (host via `::1`, guest via
  `127.0.0.1`, HTTP on both); `.local` and `[::1]` relay URLs.
- Screenshot: `KLUNKI_SHOTS=<dir> flutter test test/screenshots --plain-name kld083` →
  `kld083-localhost-waiting-phone-light.png`, `kld083-localhost-help-phone-light.png`.

## Next step (not built)

The relay could report its LAN addresses and mDNS name to the page (e.g. `GET /relay/info` →
`{"addresses": ["192.168.178.105"], "mdns": "Stefans-MacBook-Pro.local", "port": 8081}`). A page opened as
localhost would then build the room link and QR code from a reachable address automatically (with a picker when
there are several), and the notice would only be needed when the relay knows no LAN address.

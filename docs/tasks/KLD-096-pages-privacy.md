# KLD-096: GitHub Pages (PWA + privacy, support, Impressum) and a pre-publication audit

- **ID:** `KLD-096`
- **Title:** Publish the PWA and the App Store pages on GitHub Pages; audit the history before the repo goes public
- **Milestone:** release basics (App Store / TestFlight external testing)
- **Status:** DONE (🧑: set `PAGES_ENABLED`, legal review of the pages)
- **Depends on:** KLD-070 (CI), KLD-010 (offline service worker), KLD-057b (relay in the browser)
- **Touched paths:**
  - `site/{privacy,support,impressum}/index.html`, `site/site.json`, `site/build_site.py`
  - `.github/workflows/build.yml` (jobs `pages-build`, `pages`)
  - `klunki/web/klunki_sw.js`, `klunki/web/pwa_finalize.py`
  - `klunki/lib/net/room_link.dart`, `klunki/lib/ui/pairing/{web_join_screen,relay_host_screen,room_join}.dart`
  - `klunki/lib/l10n/**` (`webJoinHttpsWarning` reworded in all 7 locales), `klunki/assets/fonts/NotoSansSC/**`
  - `klunki/test/net/room_link_test.dart`, `klunki/test/ui/pairing/{web_join_screen_test,relay_test}.dart`
  - `docs/BUILDING.md` (§7.1), `docs/tasks/BOARD.md`

> **Not legal advice.** The privacy policy, the Impressum and the support page were written from what the code
> does (checked below), not by a lawyer. Have them reviewed before relying on them.

## Goal

The App Store needs a privacy policy URL and a support URL, and a German site needs an Impressum. All three are
static pages on GitHub Pages next to the PWA. The repo went public, so its whole history was checked first.

## App Store link targets

Pages project site pattern: `https://<owner>.github.io/<repo>/`, so for `tronicum/klunki`:

| App Store Connect field | URL |
|---|---|
| Privacy Policy URL | `https://tronicum.github.io/klunki/privacy/` |
| Support URL | `https://tronicum.github.io/klunki/support/` |
| Marketing URL (optional) | `https://tronicum.github.io/klunki/` (the PWA) |
| (Impressum, linked from all pages) | `https://tronicum.github.io/klunki/impressum/` |

The base path comes from `github.event.repository.name` in the workflow, so a renamed repo still builds right
(the URLs above then change).

## Enabling the deployment

1. Settings › Pages › Source: **GitHub Actions** (done by 🧑).
2. Settings › Secrets and variables › Actions › **Variables** › `PAGES_ENABLED` = `true`.

After that every push to `main` deploys. Without the variable (or with any other value) both Pages jobs are
skipped. Details: `docs/BUILDING.md` §7.1.

## Contact address (one place)

The pages contain `{{CONTACT_EMAIL}}`; `site/build_site.py` fills it from **`site/site.json`**
(`"CONTACT_EMAIL": "contact@tronicum.com"`) when the Pages job copies the pages into the build. To switch to
a dedicated App Store alias later, change only `site/site.json`. The script fails on any placeholder it has no
value for.

## Provider (Impressum, privacy controller)

The provider is the private person; the company is only the postal address (c/o):

```
Stefan Sels
c/o tronicum networx GmbH
Markgrafendamm 4
10245 Berlin
E-Mail: contact@tronicum.com
```

So there are no GmbH fields (managing director, register court/HRB, VAT ID). The Impressum names § 5 DDG and
§ 18 Abs. 2 MStV (same person and address). Consistent with the Apple developer account being personal.

## What the privacy policy says, and where it was checked

| Statement | Checked in |
|---|---|
| No account, analytics, ads, tracking or data-collecting SDKs | `klunki/pubspec.yaml`: `shared_preferences`, `bonsoir`, `qr_flutter`, `flutter_zxing` (on-device zxing-cpp), `camera`, `url_launcher`, `intl`; the packages have no third-party deps. No HTTP client in `klunki/lib` |
| Stored locally only: player name, hot-seat names, language, relay address, Quartett deck | the only `SharedPreferences` writes: `locale`, `playerName`, `hotSeatNameX/O`, `relayAddress`, `quartettDeck` |
| The name may be pre-filled from the device name | `lib/ui/pairing/device_name.dart` (`Platform.localHostname`) |
| Hosting announces name + game on the LAN | `lib/net/discovery.dart` `klunkiTxtRecord` (Bonjour TXT: protocol, name, game, ws port) |
| Messages: names, game, moves, session token, build version | KLD-071 (rejoin token), KLD-085 (build fingerprint) |
| Relay forwards, stores nothing, logs nothing | `packages/klunki_net/lib/src/relay/relay_server.dart` has no print/log; the CLI (`cli.dart` `_runRelay`) prints only its startup lines. Rooms live in memory, closed when the host leaves or after the 10-minute idle timeout |
| Camera only for QR scanning, not stored or sent | `lib/ui/pairing/qr_scanner_mobile.dart` (camera stream to zxing); the web build has no scanner |
| Card photos bundled, nothing loaded at runtime; links open only on tap | `assets/quartett/*/`, `quartett_media.dart` (`launchUrl` on tap), `tool/check_pwa_external_urls.py` (no hotlinks) |
| PWA loads nothing from CDNs | `check_pwa_external_urls.py`, fonts bundled (KLD-093, I18N-07/08) |

## Sub-path and the service worker

The sources already used relative URLs (`<base href>`, manifest `start_url`/`scope`/`id` `./`, worker
registered as `klunki_sw.js` with scope `./`), so the same build steps work at `/` (relay) and `/klunki/`
(Pages). Verified in headless Firefox against a local `/klunki/` server: scope `…/klunki/`, manifest start URL
and scope `…/klunki/`.

One real bug for Pages: the worker answers **every navigation** in its scope with the app shell, so
`/klunki/privacy/` would have shown the app to anyone who had opened the PWA. Now `STATIC_PAGES`
(`privacy`, `support`, `impressum`) are passed through to the network and never cached, and `pwa_finalize.py`
does not precache them. Verified: with the worker controlling the page, all three pages (and `privacy` without a
slash) load as themselves, and `/klunki/?lang=en` still gets the app.

## https and `ws://`

Pages serves https. Browsers block `ws://` from https pages (mixed content), except to loopback hosts. Before:
the join screen showed a warning that ended with "Öffne Klunki über http://" (no help on Pages); the host screen
showed nothing; a `ws://` relay or host failed with a generic "Kein Relay erreichbar" / "Verbindung
fehlgeschlagen" (Firefox and Chrome throw a `SecurityError` when the `WebSocket` is created).

Now (`browserBlocksWebSocket` in `room_link.dart`):

- `webJoinHttpsWarning` reads "Im Browser über https kann Klunki nur sichere Relays (wss://) erreichen – nutze
  die App oder die lokale http-Version." (7 locales), shown on the browser join screen **and** the browser host
  screen when the page is https;
- direct join, room-code join and "Spiel hosten" do not try a blocked `ws://` connection; they show that same
  sentence as the error (no "start a relay" hint). `ws://localhost` still works.

On Pages the page's own relay default is `wss://tronicum.github.io/relay`, which does not exist; it fails as
"Kein Relay erreichbar unter …" with the start hint. Acceptable for now.

## Pre-publication audit (2026-11-01)

Scope: all 116 commits reachable from any local ref (`git log -p --all`, `git rev-list --objects --all`), which
includes `origin/main`. `gitleaks`/`trufflehog` are not installed; pattern scans by hand.

| Finding | Where | Severity | Recommendation |
|---|---|---|---|
| No tokens, keys, passwords, private keys, `GH_TOKEN` values, `.p12`/`.mobileprovision`/`.jks`/`key.properties` | – | – | fine |
| Apple team ID `DZLNSB46V4` | not in any commit | – | fine (stays in the uncommitted pbxproj) |
| Device UDIDs | none (only `<udid>` placeholders) | – | fine |
| Nothing under `.claude/` committed; no `.swp` | – | – | fine |
| Commit author: only `Alfred GErd N. Tic <ai@noreply.email.local>` (116/116) | all commits | none | fine |
| `packages/klunki_engine/.dart_tool/` committed: `package_config.json` with 50× `/Users/stefan/.pub-cache/…`, a 31 MB `test.dart-3.13.7.snapshot`, a 4.6 MB kernel file | `fc1cd58` (added), `1eef627` (removed) | low (user name in paths; repo bloat, pack is 12.7 MB) | optional history rewrite (`git filter-repo --path packages/klunki_engine/.dart_tool --invert-paths`); not needed for privacy |
| LAN IP `192.168.178.105`, host names `Stefans-MacBook(-Pro).local`, `stefans-mac.local` | docs, KLD-083 card, tests (`05e57c5`, `aebbaba`, `a3880d4`, `73e11ae`, `72c52d5`, …) | low | current tree scrubbed in "Docs: neutral example addresses and device placeholders"; history: fine to leave |
| `Stefans iPhone` / `Stefans-iPhone.local` as test fixtures | `klunki/test/ui/pairing/*`, `device_name.dart` doc (`4ed95cb`, `575723a`) | low (first name only) | fine; could be genericized |
| Device names `troniPhone`, `troniPad` | `docs/DEV-DIARY.md` (`13ce4f1`) | low | fine (milestones keep them) |
| Family: "the developer's son", "the developer's younger son"; no names | `docs/DEV-DIARY.md`, `KLD-092` card | none | fine |
| `tronicum/klunki` in the Wikimedia User-Agent | `klunki/tool/fetch_card_media.py`, KLD-082 card | none | fine (public repo name) |
| `rstuart114@gmail.com` | a vendored licence/copyright header (zxing/zint) | none | fine |
| Large blobs besides `.dart_tool`: none over 300 KB | – | – | fine |

Nothing must be fixed before the repo is public.

## Follow-ups (not built)

- **`wss://` relay hosting** (KLD-051): with a TLS relay on the internet the Pages PWA could play browser vs
  browser. Needs hosting, rate limits and a privacy review (the relay would then process IP addresses of
  strangers; the policy's "we run no relay" would change).
- Optional history rewrite for the `.dart_tool` blobs (see the audit).
- A link to the privacy page from inside the app (About/licences), if App Review asks for it.

## Verification

- `flutter analyze`, `flutter test` (all), `dart test` in `packages/klunki_net` (cli, relay).
- `flutter build web --release --base-href /klunki/` → `pwa_finalize.py` → `site/build_site.py` →
  `check_pwa_external_urls.py`: passed; `<base href="/klunki/">`; no placeholder left.
- Root build (`flutter build web --release`) → finalize → URL check: passed; `<base href="/">`.
- Headless Firefox on a local `/klunki/` server: worker scope and manifest, the three pages under a controlling
  worker, the app deep link.

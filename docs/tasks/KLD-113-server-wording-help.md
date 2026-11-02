# KLD-113: Server wording, club code on demand, in-app help

- **ID:** `KLD-113`
- **Title:** Server wording, club code on demand, in-app help
- **Milestone:** Backlog (maintainer feedback on KLD-112)
- **Status:** DONE (awaiting maintainer review of the wording and the screenshots)
- **Depends on:** KLD-112 (club codes), KLD-098 ("Erweitert"), KLD-108 (https needs wss), KLD-102 ("Über Klunki")
- **Touched paths:**
  - `klunki/lib/net/server_kind.dart` (new: the kind of server from its address)
  - `klunki/lib/ui/help_screen.dart` (new: "So spielt ihr zusammen")
  - `klunki/lib/ui/pairing/relay_line.dart` (server line with its kind, server dialog, `ClubCodePrompt`, `ServerHelpLink`;
    `_Command` is now the public `CopyableCommand`)
  - `klunki/lib/ui/pairing/{room_join,relay_host_screen}.dart` (the club code prompt after a refusal)
  - `klunki/lib/ui/about_screen.dart` (entry "So spielt ihr zusammen")
  - `klunki/lib/l10n/**` (17 values reworded, 20 new keys)
  - tests: `klunki/test/ui/pairing/server_setting_test.dart` (new), `relay_club_test.dart`, wording in
    `relay_test.dart`, `qr_scan_test.dart`, `loopback_hint_test.dart`, `web_join_screen_test.dart`
  - `klunki/test/screenshots/server_help_shots_test.dart` (new)

## Goal
"Relay" is jargon. The UI says **Server**, there is one server setting, the app tells from the address what
kind of server it is, the club code appears only when a server asks for it, and a short offline help explains
how to play together.

## Decisions
- **Wording only, no churn:** ARB keys, class names, the CLI (`klunki relay`) and the docs keep "relay"; every
  user-visible value says Server (en Server, fr serveur, es servidor, zh 服务器, ar خادم, fa سرور).
- **Kind from the address** (`serverKindOf`): the host decides, not the scheme. Private/link-local IPv4 and IPv6,
  loopback, `.local`/`.lan`/`.home.arpa`/`.fritz.box` names and names without a dot are "Server im WLAN (ein
  Rechner, auf dem „klunki relay" läuft)"; everything else is "Server im Internet". Shown under the address on the
  server line and live under the field in the dialog.
- **Club code on demand:** the dialog shows no club code field unless a code is saved for the server being edited;
  then it can be changed or removed (bin icon, applied with "Übernehmen", "Abbrechen" keeps it). A
  `club-missing` / `club-wrong` refusal on "Raum starten" or "Raum beitreten" shows the refusal sentence and, right
  under it, a "Clubcode" field and "Mit Clubcode versuchen"; the code is saved for that server (KLD-112's
  `setClubCode`, still one code for one server) and the start or join runs again. A code typed there for a server
  from a link is saved for that server (the player typed it for it); a saved code is still never sent to another
  server. `relayErrorClubMissing` no longer points to "Erweitert".
- **KLD-108:** `webJoinHttpsWarning` now says "nur sichere Server (wss://)"; behaviour unchanged.
- **Help screen** (offline, ARB strings, 7 locales): reached from "Über Klunki" and from "Wie geht das?" in the
  server dialog and in the club code prompt.
- **No protocol, rules or fingerprint change.**

## Help texts (also for the website FAQ)
All help texts are ARB keys starting with `help`, plain text; paragraphs are separated by a blank line (`\n\n`),
list lines by `\n` and start with `• `. The order is fixed in one place, `helpSectionIds` in
`klunki/lib/ui/help_screen.dart`:

1. `helpTitle` (page title; also the "Über Klunki" entry)
2. `helpSectionRoomsTitle` / `helpSectionRoomsBody` – Mit anderen spielen
3. `helpSectionWifiTitle` / `helpSectionWifiBody` – Im selben WLAN (the app is the server)
4. `helpSectionServerTitle` / `helpSectionServerBody` – Wann braucht ihr einen Server?
5. `helpSectionOwnServerTitle` / `helpSectionOwnServerBody` – Eigener Server im WLAN; the app shows the start
   command (`relayStartCommand`) after this section (`helpCommandSection`); a site script may do the same
6. `helpSectionComingTitle` / `helpSectionComingBody` – Bald einfacher (in Vorbereitung): Cloudflare, download,
   Docker; no links yet
7. `helpSectionClubTitle` / `helpSectionClubBody` – Was ist ein Clubcode?
8. `helpSectionDataTitle` / `helpSectionDataBody` – Was passiert mit meinen Daten?

Other new keys: `serverKindLan`, `serverKindInternet`, `serverHelpLink`, `serverClubCodeRemove`,
`serverClubCodeRetry`. Chinese is worded with the glyphs of the bundled font subset (no subset regeneration).

## Acceptance criteria
- [x] No "Relay" (or relais / relé / 中继 / مُرحِّل / رله) in user-visible strings; "Server" instead.
- [x] Server line and dialog say "Server im WLAN …" / "Server im Internet" from the address (unit + widget tests).
- [x] No club code field by default; refusal → inline field → retry; with a real gated relay the room opens after
      the retry (widget test); the code is saved for that server and not in the room link.
- [x] A saved code is shown only for its server and can be changed and removed (widget tests).
- [x] Help screen reachable from "Über Klunki", the server dialog and the club code prompt; all sections render in
      all 7 locales (widget tests); l10n tests green.
- [x] Screenshots `--plain-name kld113` (server line, dialog WLAN, dialog Internet with saved code, club code prompt,
      help in 3 parts; de + ar; phone).

## Definition of done
```bash
(cd klunki && flutter pub get --offline && flutter gen-l10n && flutter analyze && caffeinate -i flutter test -j 2)
KLUNKI_SHOTS=/tmp/kld113 flutter test test/screenshots --plain-name kld113   # from klunki/
```

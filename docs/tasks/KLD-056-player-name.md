# KLD-056: Player name (handle) for multiplayer, optional hot-seat names

- **ID:** `KLD-056`
- **Title:** Players pick a name; network games (and, optionally, hot-seat games) show names instead of only X/O
- **Milestone:** P3/P4 (multiplayer UX)
- **Status:** DONE
- **Depends on:** KLD-034 (pairing screen), KLD-054 (WebSocket), KLD-055 (browser join screen)
- **Touched paths:**
  - `packages/klunki_net/lib/src/names.dart` (new), `lib/src/host.dart`, `lib/src/guest.dart`, `lib/klunki_net.dart`,
    `PROTOCOL.md`, `test/names_test.dart` (new)
  - `klunki/lib/profile/**` (new: `PlayerNameController`, `HotSeatNamesController`, `PlayerNameScope`, web-safe
    suggestion)
  - `klunki/lib/ui/player_name_dialog.dart` (new), `klunki/lib/ui/shell/player_labels.dart` (new),
    `klunki/lib/ui/ltr.dart`
  - `klunki/lib/ui/shell/game_screen.dart`, `handover_cover.dart`, `screen_registry.dart`
  - `klunki/lib/ui/pairing/pairing_screen.dart`, `web_join_screen.dart`, `network_game_session.dart`,
    `klunki/lib/transport/network_transport.dart` (`localName`)
  - `klunki/lib/ui/menu_screen.dart`, `klunki/lib/app/klunki_app.dart`, `klunki/lib/main.dart`
  - `klunki/lib/l10n/*.arb` (+ generated), `klunki/assets/fonts/NotoSansSC/**` (subset rerun)
  - `klunki/test/profile/**`, `klunki/test/ui/player_names_test.dart` (new), `klunki/test/ui/pairing/**`,
    `klunki/test/l10n/coverage_test.dart`

## Goal
User request: "for the multiplayer setup it should be possible to get a name/handle", later extended with
"optional names on hot seats too". A player picks a name once; both devices of a network game show each
other's name ("Anna ist am Zug"). Hot-seat players can name X and O, optionally.

## Design

**Storage.** `PlayerNameController` (`ValueNotifier<String?>`, null = not chosen yet), persisted in
shared_preferences under `playerName`, loaded in `main()` next to the `LocaleController` and injected into
`KlunkiApp` (tests pass `PlayerNameController.memory(...)`). The default suggestion is the device name
(`device_name.dart`) natively and "Browser" on the web (`player_name_suggestion*.dart`, conditional import,
since `device_name.dart` needs `dart:io`). `HotSeatNamesController` keeps the last-used hot-seat pair under
`hotSeatNameX` / `hotSeatNameO`. Both are provided by `PlayerNameScope` above the `MaterialApp`.

**Name rules** (one function, `sanitizePlayerName` in `klunki_net`, used by storage, the text fields, the
host and the guest): any script; all whitespace kinds collapse to one space, trimmed; control characters
(C0, DEL, C1), bidi controls (ALM, LRM, RLM, LRE…RLO, LRI…PDI), BOM, lone surrogates and U+FFFE/FFFF are
dropped (ZWJ/ZWNJ stay for Persian and emoji); at most 20 code points. Empty after cleaning = invalid (the
dialogs refuse it; on the wire it becomes the mark "X"/"O").

**UX flow.**
1. First "Über WLAN spielen" (native pairing screen or browser join screen, also via `?join=`) with no
   saved name: a dialog "Wie heißt du?" with the field prefilled with the suggestion, OK only. A `?join=`
   auto-connect waits for it. The dialog never comes again once a name is saved.
2. The pairing screens' former "Gerätename" field is now "Dein Name", bound to the controller (every valid
   edit is saved; an emptied field keeps the old name).
3. Menu AppBar: a person button next to the language button opens the same dialog (with Cancel) to change
   the name at any time.
4. Hosting: "Anna hostet 4 Gewinnt"; the mDNS TXT `n` and the QR/`klunki://` `n=` carry the player name.
   The discovery list shows "Anna hostet 4 Gewinnt" with the address below.
5. In a network game: status line "Du bist am Zug (X)" / "Warte auf Ben (O)…" / "Du hast gewonnen" /
   "Ben (O) hat gewonnen"; connection bar "Du (Anna, X) · Gegner: Ben (O)"; result dialog "Du gewinnst!" /
   "Ben (O) gewinnt!"; leave banner "Ben hat das Spiel verlassen" / "Verbindung zu Ben unterbrochen"; history
   "Ben (O): …". The mark stays next to every name (it maps to colours and pieces).
6. Hot-seat: starting a game is still one tap. With no names the game looks as before (X/O). An app-bar
   action "Spielernamen" (people icon, hot-seat only) opens a dialog with two optional fields "Spieler X" /
   "Spieler O", prefilled with the last pair (X: the player name if there is no last X name). The names show
   in the status line ("Anna (X) ist am Zug"), the handover cover ("Gib das Gerät an Ben (O) weiter"), the
   result dialog and the history; "Nochmal" and the next game keep them; an empty field means the mark only.

**Display abstraction.** `PlayerLabels` (`lib/ui/shell/player_labels.dart`): optional names per player plus
the local player (network only). `GameScreen` and `HandoverCover` ask the nearest `PlayerLabelsScope` and
default to `PlayerLabels.marks` (the pre-KLD-056 X/O look). `NetworkGameSession` provides network labels
(rebuilt on connection changes, so the peer name from a reconnect shows up); the hot-seat `GameSession`
provides the hot-seat names. The game boards' own hint texts (Mühle, Schiffe, Quartett) still use marks.

**Protocol (no new fields).** v1 already carries both names: the guest's `hello.name`, the host's
`hello.name` and `welcome.host`. KLD-056 only adds cleaning: the host cleans the incoming guest name (non
strings count as missing) and falls back to the guest's mark; the guest cleans the host name and falls back
to the host's mark once `welcome` told it its own player; both clean their own name before sending
(`KlunkiHost.name` falls back to its mark). The rejoin-by-name rule compares cleaned names. The guest sends
the same name again on reconnect, so names stay. Documented in `PROTOCOL.md` ("Player names").

**Bidi.** Names are embedded with `bidiName` (`ltr.dart`): a first-strong isolate (U+2068 … U+2069) when the
UI is RTL or the name contains RTL letters, unchanged otherwise (Latin names in LTR locales stay
byte-identical). So "علی" in the German UI and "Anna" in the Arabic UI keep their own direction.

**Translations.** New keys `playerNameTitle`, `playerNameLabel`, `playerLabel` ("{name} ({mark})",
full-width parentheses in zh), `hotSeatNamesTitle`, `hotSeatNameLabel`, `hotSeatNamesHelper`,
`shellYourTurn`, `shellWaitingFor`, `shellYouHaveWon`, `shellYouWin`; changed `pairingStatus`,
`pairingPeerLeft`, `pairingPeerLost` (now with `{peer}`); removed `pairingDeviceName`. All 7 ARB files;
fr/es/zh/ar/fa are machine translations under the existing `@@x-review` marker (native review pending, like
I18N-03). OK/Cancel come from `MaterialLocalizations`. The Noto Sans SC subset was rebuilt
(`tool/update_web_fonts.py subset`) for the new zh characters.

## Acceptance criteria
- [x] Name persisted under `playerName`, loaded in `main()`, injectable; hot-seat pair persisted.
- [x] Cleaning: control chars, bidi overrides, whitespace, 20-char limit, empty input (app and `klunki_net`).
- [x] First-run dialog appears once (native pairing and browser `?join=`); menu edit; "Dein Name" field.
- [x] Both sides learn each other's name over TCP and WebSocket; the host sanitises and falls back to X/O;
      names survive a reconnect; documented in `PROTOCOL.md`.
- [x] Names in status line, connection bar, host waiting screen, discovery list, QR/TXT, result dialog,
      leave banner, history; mark always visible.
- [x] Hot-seat names optional: status, handover cover, result, history; "Nochmal" keeps them; empty = X/O.
- [x] RTL name in the de UI and LTR name in the ar UI are isolated.
- [x] All strings in 7 ARB files; coverage (incl. the new dialogs and network status lines), strings and
      glyph tests strict across all locales.
- [x] `flutter analyze`, `flutter test`, `dart test` (klunki_net) green.

## Known limitations
- Player names are user input: characters outside the bundled fonts (e.g. a Chinese name that uses
  characters not in the Noto Sans SC subset, Hebrew, Devanagari, emoji) are fetched from the online font
  fallback in the PWA, or show as tofu offline. Accepted; the UI strings themselves stay fully offline.
- The limit counts code points, not grapheme clusters: a long emoji sequence may be cut mid-cluster.
- Names are display only; the token is still the rejoin key (a guest with the same cleaned name may also
  rejoin, as before).
- Game-specific hint texts inside the boards still say X/O.

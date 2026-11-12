# App Store submission

Draft texts, screenshots and checklist for the iOS App Store (App Store Connect). German is the primary
language, English the second localization. Game names stay generic: no brand names of other publishers
(see the game names in `klunki/lib/l10n/app_*.arb`).

## Contents

1. [Screenshots](#screenshots)
2. [Store texts (German)](#store-texts-german)
3. [Store texts (English)](#store-texts-english)
4. [Category, age rating, contact](#category-age-rating-contact)
5. [App Privacy](#app-privacy)
6. [Version and build number](#version-and-build-number)
7. [Open points before submitting](#open-points-before-submitting)

## Screenshots

### Required sizes

Source: Apple, "Screenshot specifications",
<https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications> (checked 2026-11-01).

- Format: `.png`, `.jpg` or `.jpeg`, **no alpha channel or transparency**. 1 to 10 screenshots per display size
  and language.
- If the UI is the same across sizes, the highest required resolution of a family is enough. App Store Connect
  scales it down for the smaller devices.

| Folder | Display (Apple's name) | Portrait size | Status |
|---|---|---|---|
| `iphone-6.9` | iPhone with Dynamic Island, large display (6.9", e.g. 16/17 Pro Max) | 1320 × 2868 | Optional. Without it, the Face ID large set is scaled. |
| `iphone-6.3` | iPhone with Dynamic Island, medium display (6.3", e.g. 16/17 Pro) | 1206 × 2622 | The page lists "at least one screenshot" for this size as the iPhone requirement. |
| `ipad-13` | iPad 13" | 2064 × 2752 | Required, since the app runs on iPad. |

Apple also accepts 1290 × 2796 and 1260 × 2736 for the large iPhone, 1179 × 2556 for the medium one,
2048 × 2732 for the 13" iPad and 1284 × 2778 or 1242 × 2688 for the older 6.5" iPhones (only needed if no
large Dynamic Island set is provided). We upload the three sets above.

### Generating them

The set is the `appstore` group of `klunki/test/screenshots/screenshots_test.dart`. It renders the real app
with the bundled fonts at logical size × device pixel ratio (440 × 956 @3x, 402 × 874 @3x, 1032 × 1376 @2x),
in light mode, in German and English. It writes RGB PNGs without alpha and checks the pixel size. Without
`KLUNKI_APPSTORE` the group is skipped, so a normal `flutter test` writes nothing.

```bash
cd klunki
# The commit in the menu's version line ("Version 1.1.0 (abc1234)" instead of "(dev)"):
KLUNKI_APPSTORE=../build/store-shots/appstore flutter test test/screenshots --plain-name appstore \
  --dart-define=KLUNKI_BUILD=$(git rev-parse --short HEAD)
# One device or language only:
KLUNKI_APPSTORE=/tmp/appstore flutter test test/screenshots --plain-name "appstore ipad-13/de"
# Check the result:
sips -g pixelWidth -g pixelHeight -g hasAlpha /tmp/appstore/*/*/*.png
```

Output: `<dir>/{iphone-6.9,iphone-6.3,ipad-13}/{de,en}/NN-scene.png`, 60 files, about 20 MB, plus a contact
sheet per language (`<dir>/overview-de.png`, `overview-en.png`: a row per device, not for upload). `build/` is
gitignored, so `build/store-shots/` in the repo root is a good permanent place.

Players use the default names of the language (Anna, Ben, Cleo, Dani in German; Dan instead of Dani in
English); the tours and the "Neu hier?" line count as seen; no handover cover is on screen.

| # | Scene | Setup |
|---|---|---|
| 01 | Menu | Release look ("Klunki Spielesammlung", no debug console link), all games, "Karten" on the Quartett tiles; on the iPhones the first rows, on the iPad all twelve tiles |
| 02 | Baulöwe / Housing Corp | Berlin (German street names in every language), 4 players, seed 11 with bot moves to round 16: Dani has landed on Ben's Schlesische Straße with a Späti-Palast, its deed card in the centre with the rent paid, "Zug beenden" |
| 03 | Quartett (Trumpf), rockets deck | Seed 7, three picks played: a round result with photos and the card counts |
| 04 | Wortgewandt / Wordsmith | 3 players, tiles in the store language: HAUS, STERN, BIRNE (de) or GAME, EARTH, LIGHT (en), the last word accepted; Anna's rack and the score row of three |
| 05 | Mau-Mau | The first seed where three plain cards (no 7, 8, jack) leave Ben with 4 cards, 2 of them fitting: own hand, discard pile, Anna's card backs |
| 06 | Mäxchen / Mia | 4 players, scripted rolls: three lives lost, Dani says 64 to Anna ("Glauben" / "Anzweifeln") |
| 07 | Ausgewürfelt / Rolled Out | 4 players, six rounds (Anna has the upper bonus), Anna's first roll of round 7 |
| 08 | Schach / Chess | 10-minute clock running (KLD-126, 7:14 and 6:43 left), Italian opening, both sides castled, the f3 knight selected with its targets |
| 09 | Schiffe versenken / Sink the Fleet | Seed 7, 60 shots played: hits, misses, own fleet |
| 10 | "Raum starten" / "Start a room" | Waiting for a guest: QR code, the made-up address `192.168.1.20:4747`, player name "Anna" |

No real addresses or device names are used. Apple allows up to 10 screenshots per device size, so all ten go up
in this order.

Dropped in the November 2026 refresh (to make room for the new games): the Quartett card gallery, GoStrategy and
Mühle. Their scenes are still in the history of `screenshots_test.dart` if they are wanted back.

Known look: on the iPad (and the Play phone/tablet sets) the Baulöwe action row under "Zug beenden" ("Meine
Straßen", "Tauschen") is cut at the bottom edge: the board takes all the width and the action panel scrolls
there. That is the app's own layout (`property_board.dart`, portrait: board side = height − 250), not a capture
error.

## Store texts (German)

**Name** (≤ 30): `Klunki`

Alternative with a keyword, if "Klunki" alone is taken or too bare: `Klunki Spielesammlung` (21), the title
the app itself shows.

**Untertitel** (≤ 30): `Brett-, Karten- & Würfelspiele` (30), chosen by the maintainer.

Alternatives (not used):

- `Spiele für 2–4, auch offline` (28)
- `Spielesammlung für die Familie` (30)

**Werbetext** (≤ 170, can be changed without a new review):

> Zwölf Spiele in einer App: 4 Gewinnt, Schach, Mau-Mau, Mäxchen, Baulöwe, Quartett und mehr. Zu zweit bis zu
> viert an einem Gerät, zu zweit auch über WLAN. Ohne Werbung.

(168 characters)

**Beschreibung** (≤ 4000):

> Klunki ist eine Spielesammlung für die ganze Familie: zwölf Klassiker zum Mitnehmen, für zwei bis vier
> Spieler, ohne Werbung, ohne Konto und ohne In-App-Käufe.
>
> DIE SPIELE
> • 4 Gewinnt: vier in einer Reihe, waagerecht, senkrecht oder schräg
> • Mühle: bilde Dreierreihen und schlage gegnerische Steine
> • Quartett (Trumpf): vergleicht Werte, der bessere Wert gewinnt beide Karten
> • Quartett (Sets): erfrage Karten und sammle vollständige Vierer-Sets
> • Schiffe versenken: versteckt eure Flotten und schießt abwechselnd
> • GoStrategy: verdeckte Armeen auf einem 10×10-Feld, finde und erobere die gegnerische Fahne
> • Schach: der Klassiker, mit markierten Zügen, Zugliste und auf Wunsch mit Schachuhr
> • Wortgewandt: legt Wörter aus Buchstabensteinen, auf Deutsch oder Englisch, mit eingebautem Wörterbuch (2–4
> Spieler)
> • Mau-Mau: legt passende Karten ab, wer zuerst keine mehr hat, gewinnt
> • Mäxchen: würfeln, flunkern, durchschauen – wer glaubt dir, wer zweifelt? (2–4 Spieler)
> • Ausgewürfelt: fünf Würfel, bis zu drei Würfe, dann ein Feld im Spielzettel füllen (2–4 Spieler)
> • Baulöwe: würfle übers Spielfeld, kaufe Straßen, baue Häuser und kassiere Miete, in Berlin oder in der
> Fantasiestadt (2–4 Spieler)
>
> Zu jedem Spiel gibt es die Regeln direkt in der App. Bei Mäxchen und Ausgewürfelt kannst du auch durch
> Schütteln würfeln.
>
> QUARTETT MIT ECHTEN FOTOS
> Vier Kartendecks mit je 32 Karten: Autos, Flugzeuge, Raketen und Züge, mit Fotos, Kennzahlen und Link zum
> Wikipedia-Artikel. Über „Karten“ auf der Quartett-Kachel siehst du dir alle Karten auch ohne Spiel an.
>
> GEMEINSAM AN EINEM GERÄT
> Ihr spielt abwechselnd: zu zweit, bei Wortgewandt, Mäxchen, Ausgewürfelt und Baulöwe auch zu dritt oder zu
> viert. Bei geheimen Karten, Buchstaben, Würfeln oder Flotten verdeckt Klunki den Bildschirm, bis das Gerät
> weitergereicht ist.
>
> ÜBER WLAN SPIELEN
> Zu zweit auf zwei Geräten: Ein Gerät tippt auf „Raum starten“, das andere auf „Raum beitreten“ und scannt den
> QR-Code oder tippt den Raumcode ein. iPhone, iPad und Android spielen miteinander. Kein Konto, kein Server von
> uns: die Geräte verbinden sich direkt im selben WLAN. Über WLAN gehen alle Spiele außer Ausgewürfelt und
> Baulöwe; zu dritt oder zu viert spielt ihr an einem Gerät.
>
> OHNE INTERNET
> Alle Spiele laufen offline. Klunki sammelt keine Daten, zeigt keine Werbung und verkauft nichts.
>
> Sprachen: Deutsch, Englisch, Französisch, Spanisch, Arabisch, Persisch, Chinesisch.

(2419 characters)

**Schlüsselwörter** (≤ 100, comma-separated, no spaces after the commas; the name and the category need not be
repeated, so "brettspiel" is left to the category Board):

`kartenspiel,würfelspiel,mau mau,mäxchen,schach,mühle,4 gewinnt,quartett,schiffe versenken,familie`
(97 characters, 100 bytes in UTF-8, so it fits even if App Store Connect counted bytes)

## Store texts (English)

**Name**: `Klunki`. Alternative: `Klunki Game Collection` (22).

**Subtitle** (≤ 30): `Board, card & dice games` (24). Alternative: `Games for 2–4, also offline` (27).

**Promotional text** (≤ 170):

> Twelve games in one app: Four in a Row, Chess, Mau-Mau, Mia, Housing Corp, Quartett and more. Two to four
> players on one device, two over Wi-Fi. No ads, no account.

(164 characters)

**Description** (≤ 4000):

> Klunki is a game collection for the whole family: twelve classics to take along, for two to four players,
> without ads, accounts or in-app purchases.
>
> THE GAMES
> • Four in a Row: four in a line, across, down or diagonal
> • Mill: form rows of three and capture your opponent's pieces
> • Quartett (Trumps): compare values, the better value wins both cards
> • Quartett (Sets): ask for cards and collect complete sets of four
> • Sink the Fleet: hide your fleets and take turns firing
> • GoStrategy: hidden armies on a 10×10 board, find and capture the enemy flag
> • Chess: the classic, with highlighted moves, a move list and an optional chess clock
> • Wordsmith: lay words from letter tiles, in German or English, with a built-in dictionary (2–4 players)
> • Mau-Mau: play a matching card, the first to run out of cards wins
> • Mia: roll, bluff and call the bluff – who believes you, who doubts? (2–4 players)
> • Rolled Out: five dice, up to three rolls, then fill one box on the score sheet (2–4 players)
> • Housing Corp: roll around the board, buy streets, build houses and collect rent, in Berlin or in Fantasy
> Town (2–4 players; street names in German for now)
>
> Every game has its rules right in the app. In Mia and Rolled Out you can also shake the phone to roll.
>
> QUARTETT WITH REAL PHOTOS
> Four decks of 32 cards each: cars, planes, rockets and trains, with photos, stats and a link to the Wikipedia
> article. Tap "Cards" on the Quartett tile to browse every card, no game needed.
>
> TOGETHER ON ONE DEVICE
> Take turns: two players, and in Wordsmith, Mia, Rolled Out and Housing Corp also three or four. In games with
> secret cards, letters, dice or fleets, Klunki covers the screen until the device has been passed on.
>
> PLAY OVER WI-FI
> Two players on two devices: one taps "Start a room", the other "Join a room" and scans the QR code or types
> the room code. iPhone, iPad and Android play together. No account, no server of ours: the devices connect
> directly on the same Wi-Fi. Every game except Rolled Out and Housing Corp works over Wi-Fi; with three or four
> players, play on one device.
>
> NO INTERNET NEEDED
> All games work offline. Klunki collects no data, shows no ads and sells nothing.
>
> Languages: German, English, French, Spanish, Arabic, Persian, Chinese.

(2247 characters)

**Keywords** (≤ 100):

`board game,card game,dice game,mau mau,mia,chess,mill,four in a row,quartett,sink the fleet,family`
(98 characters)

## Category, age rating, contact

- **Primary category:** Games. **Subcategories:** Board, Family. (Alternatively Card as a secondary
  subcategory.)
- **Age rating:** expected **4+**. Questionnaire answers:
  - Violence (cartoon, fantasy, realistic), horror, sexual content, nudity, profanity, drugs, alcohol, tobacco,
    mature themes, medical information, gambling: **None**. GoStrategy and Schiffe versenken are abstract
    strategy games with tokens and grid markers, no depicted violence. Quartett is a comparison card game with
    no stakes, so not simulated gambling. The dice games (Mäxchen, Ausgewürfelt, Baulöwe) and Mau-Mau have no
    betting and no stakes; Baulöwe's money is play money that exists only within one game, nothing can be bought
    or won. Mäxchen is played for "lives", no drinking theme.
  - Contests: **No**.
  - Unrestricted web access: **No**. The Wikipedia and image credit links open in the system browser, not
    in an in-app browser.
  - User-generated content: **No**. The only free text is the player name, shown to the players at the same
    table or to the one other player of a network game, not published or stored anywhere else. No chat.
  - Messaging or chat, social features: **No**.
  - Advertising: **No**. In-app purchases: **None**.
  - Parental controls, age assurance: not applicable.
- **Copyright:** `2026 <name as in the developer account>`.
- **Support URL:** <https://tronicum.github.io/klunki/support/>
- **Privacy policy URL:** <https://tronicum.github.io/klunki/privacy/>. In the app (guideline 5.1.1): menu (bottom) →
  "Über Klunki" → Datenschutz and Impressum (texts stored in the app, readable offline and without the web pages,
  each with a link to its page; exported by `site/export_legal_text.py`), Support (opens the web page) (KLD-102).
- **Marketing URL** (optional): <https://tronicum.github.io/klunki/> (the landing page since KLD-115; the PWA is at `play/`)
- **Contact email** (App Review contact and **TestFlight beta feedback email**): `contact@tronicum.com`. It can be
  switched to a dedicated alias later.
- **App Review notes** (suggestion; the labels in quotes are the German UI, the English UI in brackets): "No
  login or account is needed, and there is nothing to buy. All 12 games work offline on one device: tap a game
  tile; Wortgewandt, Mäxchen, Ausgewürfelt and Baulöwe ask for 2 to 4 players. Network play is for 2 players
  and needs two devices (iPhone, iPad or Android) on the same Wi-Fi: on the first, tap 'Raum starten' (Start a
  room) under 'Mit anderen Geräten spielen' (Play with other devices), choose a game and start the room; on
  the second, tap 'Raum beitreten' (Join a room) and scan the QR code, type the room code, or pick the room
  under 'Räume in der Nähe' (Rooms nearby). A game tile's 'Mit anderen' (With others) link starts a room for
  that game directly. Ausgewürfelt and Baulöwe are one-device games. The camera is used only to scan the QR
  code; local network access is used only to find and connect to the other device. There is no server of
  ours."

## App Privacy

Answer: **Data Not Collected.**

Checked against the code (`klunki/pubspec.yaml`, `klunki/lib`):

- No analytics, crash reporting, advertising or tracking SDKs. Dependencies are Flutter, the own engine and
  network packages, `shared_preferences`, `bonsoir` (mDNS), `qr_flutter`, `flutter_zxing` with `camera`
  (QR scanning) and `url_launcher`.
- Stored only on the device (`shared_preferences`): language, player name, chosen Quartett deck, an optional
  relay address. Nothing is sent to the developer.
- Network play goes directly between the players' devices in the local network (TCP/WebSocket, mDNS). The
  native app has no default server. A relay is only used if the player enters one. The player name and moves
  go to the other player only, in real time.
- Camera: only to scan a join QR code, frames are processed on the device and not stored.
- Links (Wikipedia, image credits) open in the system browser. Klunki adds no tracking parameters.
- No tracking in Apple's sense (no linking with third-party data), so no App Tracking Transparency prompt.

If any of this changes (e.g. crash reporting or a hosted relay that logs), the answers must be revisited.

## Version and build number

`CFBundleShortVersionString` = the version from `klunki/pubspec.yaml` (`1.1.0` for the first external
TestFlight build; `1.0.0` was an internal-only upload; numbering rule in `docs/RELEASING.md`), `CFBundleVersion` = the build number `YYYYMMDDNN` from `tool/build_number.sh` (KLD-116),
both through `Info.plist`'s `$(FLUTTER_BUILD_NAME)` / `$(FLUTTER_BUILD_NUMBER)`; no Xcode project change. CI
has no signed iOS build: build the upload on the Mac from the tagged commit with
`flutter build ipa --release --build-number=$(../tool/build_number.sh) --dart-define=KLUNKI_BUILD=$(git rev-parse HEAD) --dart-define=KLUNKI_BUILD_NUMBER=$(../tool/build_number.sh)`
and upload it with Transporter or Xcode Organizer. Steps: [`RELEASING.md`](RELEASING.md).

## Open points before submitting

Done since the first draft: the **app icon** (KLD-097, `c5-zoom-b-fill`, in the iOS AppIcon set; the 1024 px store
master is `docs/store/app-icon-1024.png`), **export compliance** (`ITSAppUsesNonExemptEncryption` is `false` in
`klunki/ios/Runner/Info.plist`, so App Store Connect does not ask per build) and the **web pages** for the support,
privacy policy and Impressum URLs above (GitHub Pages, KLD-096/115).

- **App icon on devices:** the look on real home screens (light and dark) is still to be checked (KLD-097).
- **Screenshots:** the `appstore` set (scenes above) shows none of Mau-Mau, Mäxchen, Ausgewürfelt and Baulöwe,
  and the table above still describes scene 07 (`07-play-together`) as "Über WLAN spielen" (to check against the
  current room screen). Apple allows 10 per size: one of the new
  games (e.g. Baulöwe or Ausgewürfelt with 3–4 players) would show that Klunki is not only for two.
- **Card and street names:** the Quartett decks show real vehicle names (e.g. rocket and train models), and
  Baulöwe's Berlin board real street names. They are factual names, not game names, but App Review may ask. The
  photo credits (CC licences) are in the app under "Bildnachweise".
- Screenshots of a dark mode or the other languages are optional and can be added with more locales in the
  `appstore` group.

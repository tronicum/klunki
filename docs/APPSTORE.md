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
6. [Open points before submitting](#open-points-before-submitting)

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
KLUNKI_APPSTORE=/tmp/appstore flutter test test/screenshots --plain-name appstore
# One device or language only:
KLUNKI_APPSTORE=/tmp/appstore flutter test test/screenshots --plain-name "appstore ipad-13/de"
# Check the result:
sips -g pixelWidth -g pixelHeight -g hasAlpha /tmp/appstore/*/*/*.png
```

Output: `<dir>/{iphone-6.9,iphone-6.3,ipad-13}/{de,en}/NN-scene.png`, about 28 MB for all 54 files.

| # | Scene | Setup |
|---|---|---|
| 01 | Menu with all games | Menu as in a release build (no debug console link) |
| 02 | Quartett (Trumpf), rockets deck | Seed 7, three picks played: a round result with photos and the card counts |
| 03 | Quartett card gallery | Rockets deck with photos |
| 04 | Schiffe versenken | Seed 7, 60 shots played: hits, misses, own fleet |
| 05 | GoStrategy | Both armies set up (seeds 14/15), 30 quiet moves |
| 06 | Chess | Italian opening, both sides castled, the f3 knight selected with its targets |
| 07 | "Über WLAN spielen", host | Waiting for a guest: QR code, `192.168.1.20:4747`, player name "Anna" |
| 08 | Mühle | Seed 7, 13 moves (placing phase) |
| 09 | Wortgewandt / Wordsmith | Tiles in the store language: HAUS, STERN, BIRNE (de) or GAME, EARTH, LIGHT (en), the last word accepted; the next player's rack |

No real addresses or device names are used. Apple allows up to 10 screenshots per device size.

Upload order: 01, 02, 09, 04, 05, 06, 08, 03, 07 works well too (games first, then gallery and network play).

## Store texts (German)

**Name** (≤ 30): `Klunki`

Alternative with a keyword, if "Klunki" alone is taken or too bare: `Klunki – Spiele zu zweit` (24).

**Untertitel** (≤ 30):

- Proposal: `Brett- und Kartenspiele zu zweit` is 32 characters, too long. Use one of these:
  - `Spiele zu zweit, auch offline` (29)
  - `Brettspiele für zwei` (20)
  - `Deine Spielesammlung` (20)
- The suggested "Deine Spielesammlung für unterwegs" has 34 characters and does not fit.

**Werbetext** (≤ 170, can be changed without a new review):

> Acht Spiele in einer App: 4 Gewinnt, Mühle, Schach, Wortgewandt, Schiffe versenken, Quartett und mehr. Zu
> zweit an einem Gerät oder über WLAN. Ohne Werbung, ohne Konto.

(168 characters)

**Beschreibung**:

> Klunki ist eine Spielesammlung für zwei: Klassiker zum Mitnehmen, ohne Werbung, ohne Konto und ohne
> In-App-Käufe.
>
> DIE SPIELE
> • 4 Gewinnt: vier in einer Reihe, waagerecht, senkrecht oder schräg
> • Mühle: bilde Dreierreihen und schlage gegnerische Steine
> • Schach: der Klassiker, mit markierten Zügen und Zugliste
> • Schiffe versenken: versteckt eure Flotten und schießt abwechselnd
> • GoStrategy: verdeckte Armeen auf einem 10×10-Feld, finde und erobere die gegnerische Fahne
> • Wortgewandt: legt Wörter aus Buchstabensteinen, auf Deutsch oder Englisch, mit eingebautem Wörterbuch
> • Quartett (Trumpf): vergleicht Werte, der bessere Wert gewinnt beide Karten
> • Quartett (Sets): erfrage Karten und sammle vollständige Vierer-Sets
>
> QUARTETT MIT ECHTEN FOTOS
> Vier Kartendecks mit je 32 Karten: Autos, Flugzeuge, Raketen und Züge, mit Fotos, Kennzahlen und Link zum
> Wikipedia-Artikel. Alle Karten kannst du auch ohne Spiel in der Galerie ansehen.
>
> ZU ZWEIT AN EINEM GERÄT
> Ihr spielt abwechselnd. Bei Spielen mit geheimen Karten, Buchstaben oder Flotten verdeckt Klunki den Bildschirm, bis das
> Gerät weitergereicht ist.
>
> ÜBER WLAN SPIELEN
> Ein Gerät hostet, das andere tritt per QR-Code oder Adresse bei, iPhone, iPad, Android oder ein Browser im
> selben WLAN. Kein Server, kein Konto: die Geräte verbinden sich direkt.
>
> OHNE INTERNET
> Alle Spiele laufen offline. Klunki sammelt keine Daten, zeigt keine Werbung und verkauft nichts.
>
> Sprachen: Deutsch, Englisch, Französisch, Spanisch, Arabisch, Persisch, Chinesisch.

**Schlüsselwörter** (≤ 100, comma-separated, no spaces after the commas; the name and the category need not be
repeated):

`brettspiel,zu zweit,offline,mühle,schach,4 gewinnt,quartett,schiffe versenken,wortspiel,familie`
(95 characters)

## Store texts (English)

**Name**: `Klunki`

**Subtitle** (≤ 30): `Board & card games for two` (26). Alternative: `Classic games for two` (21).

**Promotional text** (≤ 170):

> Eight games in one app: Four in a Row, Mill, Chess, Wordsmith, Sink the Fleet, Quartett and more. Two players
> on one device or over Wi-Fi. No ads, no account.

(158 characters)

**Description**:

> Klunki is a collection of games for two: classics to take along, without ads, accounts or in-app purchases.
>
> THE GAMES
> • Four in a Row: four in a line, across, down or diagonal
> • Mill: form rows of three and capture your opponent's pieces
> • Chess: the classic, with highlighted moves and a move list
> • Sink the Fleet: hide your fleets and take turns firing
> • GoStrategy: hidden armies on a 10×10 board, find and capture the enemy flag
> • Wordsmith: lay words from letter tiles, in German or English, with a built-in dictionary
> • Quartett (Trumps): compare values, the better value wins both cards
> • Quartett (Sets): ask for cards and collect complete sets of four
>
> QUARTETT WITH REAL PHOTOS
> Four decks of 32 cards each: cars, planes, rockets and trains, with photos, stats and a link to the
> Wikipedia article. Browse every card in the gallery, no game needed.
>
> TWO PLAYERS, ONE DEVICE
> Take turns. In games with secret cards, letters or fleets, Klunki covers the screen until the device has been passed on.
>
> PLAY OVER WI-FI
> One device hosts, the other joins by QR code or address: iPhone, iPad, Android or a browser on the same Wi-Fi.
> No server, no account: the devices connect directly.
>
> NO INTERNET NEEDED
> All games work offline. Klunki collects no data, shows no ads and sells nothing.
>
> Languages: German, English, French, Spanish, Arabic, Persian, Chinese.

**Keywords** (≤ 100):

`board game,two player,offline,mill,chess,four in a row,quartett,sink the fleet,word game,family`
(95 characters)

## Category, age rating, contact

- **Primary category:** Games. **Subcategories:** Board, Family. (Alternatively Card as a secondary
  subcategory.)
- **Age rating:** expected **4+**. Questionnaire answers:
  - Violence (cartoon, fantasy, realistic), horror, sexual content, nudity, profanity, drugs, alcohol, tobacco,
    mature themes, medical information, gambling: **None**. GoStrategy and Schiffe versenken are abstract
    strategy games with tokens and grid markers, no depicted violence. Quartett is a comparison card game with
    no stakes, so not simulated gambling.
  - Contests: **No**.
  - Unrestricted web access: **No**. The Wikipedia and image credit links open in the system browser, not
    in an in-app browser.
  - User-generated content: **No**. The only free text is the player name, shown to the one other player of a
    local game, not published or stored anywhere else. No chat.
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
- **App Review notes** (suggestion): "All games work offline on one device. Network play needs two devices on
  the same Wi-Fi: one taps 'Über WLAN spielen' → 'Hosten', the other scans the QR code or types the address
  under 'Beitreten'. No login."

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

## Open points before submitting

- **App icon: still the default Flutter icon** (`klunki/ios/Runner/Assets.xcassets/AppIcon.appiconset`). Apple
  may reject it under guideline 4.0 or 2.3 (placeholder content), and it looks unfinished on the store page. It
  must be replaced before submitting. Options:
  1. The user provides a design (a 1024 × 1024 PNG, no alpha, no rounded corners). The iOS sizes can be
     generated from it.
  2. After the user's OK: a simple generated icon from the in-app logo (`KlunkiLogo`, the three overlapping
     circles in the menu header), drawn on the Klunki background colour, rendered by a test like the
     screenshots and written as the 1024 px master.
  3. A designer or an icon tool with the same constraints.

  In all cases check the Android launcher icon and the PWA icons (`klunki/web/icons`) as well, for one look.
- **Export compliance:** the app uses no encryption of its own (plain TCP/WebSocket in the local network, HTTPS
  only through the system). Answer "No" to non-exempt encryption, or set `ITSAppUsesNonExemptEncryption` to
  `NO` in `Info.plist` (not changed here).
- **Card names:** the Quartett decks show real vehicle names (e.g. rocket and train models). They are factual
  names, not game names, but App Review may ask. The photo credits (CC licences) are in the app under
  "Bildnachweise".
- Screenshots of a dark mode or the other languages are optional and can be added with more locales in the
  `appstore` group.

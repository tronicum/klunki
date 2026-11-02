# Google Play submission

Build setup, store texts, graphics, policy answers and a checklist for the Google Play Store (Play Console).
German is the primary language, English the second listing. Game names stay generic: no brand names of other
publishers (see the game names in `klunki/lib/l10n/app_*.arb`). The iOS counterpart is [APPSTORE.md](APPSTORE.md);
texts and privacy answers are kept in line with it.

The developer (not an agent) creates the Play Console account, accepts the agreements and uploads everything.
Rules marked **(check in the console)** are from memory as of 2026-11 and may have changed: the console's own
help text wins.

## Contents

1. [Developer account](#developer-account)
2. [Build: app id, versions, SDK levels, permissions](#build)
3. [Upload key and Play App Signing](#upload-key-and-play-app-signing)
4. [Step by step in the Play Console](#step-by-step-in-the-play-console)
5. [Store texts (German)](#store-texts-german)
6. [Store texts (English)](#store-texts-english)
7. [Graphics](#graphics)
8. [App content: data safety, content rating, target audience](#app-content)
9. [Checklist](#checklist)

## Developer account

One-time registration fee of 25 USD. Two account types:

| | **Organization** (e.g. a GmbH) | **Personal** |
|---|---|---|
| Identity | **D-U-N-S number** of the company (free from Dun & Bradstreet, can take days to weeks to get or correct); the company name and address must match the D-U-N-S record | ID check of the person |
| Before production | No testing requirement; production can be used right away | Accounts created after 13 Nov 2023 must run a **closed test with at least 12 testers who stay opted in for at least 14 days in a row**, then apply for production access (a short questionnaire about the test). The number was 20 until Dec 2024. **(check in the console)** |
| Public on the store page | Developer name, email, website, address; phone (check in the console) | Developer name and email; address and phone only if the account declares itself a **trader** (EU Digital Services Act) |
| Other | Organization contact plus a developer contact; possibly website verification **(check in the console)** | Proof of access to a real Android device (Play Console app) **(check in the console)** |

**EU trader status (DSA):** every account must declare whether it acts as a trader. A GmbH publishing an app is a
trader, so its address, phone and email are shown on the store page. A private person publishing a free app
without commercial intent usually is not. Decide before submitting; the contact data shown must match the
Impressum (`site/impressum/`; the app shows a stored copy under "Über Klunki" → Impressum, KLD-102).

**Recommendation:** an organization account if Klunki is published under the company; it avoids the 12-tester /
14-day wait. Under a personal account, plan the closed test early (the internal track does not count).

## Build

### Application id

`applicationId = "de.klunki.klunki"` (and `namespace` the same) in `klunki/android/app/build.gradle.kts`. It is a
stable reverse domain, not `com.example`. It **cannot change after the first upload**: Play identifies the app by
it forever.

It **matches the iOS bundle id** (`PRODUCT_BUNDLE_IDENTIFIER = de.klunki.klunki` in `Runner.xcodeproj`), so
both stores use one id. Keep it. Play does not check that the publisher owns `klunki.de`; the id only has to be unique on Play.

### Version

`versionCode = flutter.versionCode` and `versionName = flutter.versionName`, both from `version:` in
`klunki/pubspec.yaml` (`1.0.0+1` today: name `1.0.0`, code `1`). Every upload to Play needs a **higher versionCode**
than any bundle uploaded before, on any track. Bump the `+N` part in `pubspec.yaml`, or pass
`--build-number N` (and `--build-name x.y.z`) to `flutter build appbundle`. A rejected or deleted bundle still
uses up its code.

### SDK levels

| Setting | Value | Source |
|---|---|---|
| `compileSdk` | 36 | `flutter.compileSdkVersion` (Flutter 3.47.8, `FlutterExtension.kt`) |
| `targetSdk` | 36 (Android 16) | `flutter.targetSdkVersion` |
| `minSdk` | 24 (Android 7.0) | `flutter.minSdkVersion` |
| NDK | 28.2.13676358 (r28c) | `flutter.ndkVersion` |

Play's target API rule: new apps and updates must target the API level of the Android release from about a year
earlier. Since 31 Aug 2025 that is API 35; the next step to API 36 is expected around 31 Aug 2026 **(check in the
console)**. targetSdk 36 meets both. minSdk 24 has no Play requirement.

**16 KB memory pages:** since 1 Nov 2025, new apps and updates targeting Android 15+ must support 16 KB page sizes
**(check in the console)**. Native code in Klunki: the Flutter engine (16 KB ready since Flutter 3.32) and zxing-cpp
from `flutter_zxing`, compiled with NDK r28, which aligns to 16 KB by default. The Play Console shows a warning on
the bundle's page if a library is not aligned; look there after the first upload.

### Building the bundle

```bash
cd klunki
flutter build appbundle --release --dart-define=KLUNKI_BUILD=$(git rev-parse --short HEAD)
# -> build/app/outputs/bundle/release/app-release.aab
```

Signed with the upload key when `klunki/android/key.properties` exists (next section), otherwise with the debug
key and a Gradle warning. Play Console **rejects debug-signed bundles**, so a bundle without the key only checks
the build. CI (`build.yml`, job `android`) builds the same bundle as the artifact `klunki-android-aab`: debug-signed
unless the `KEYSTORE_*` repository secrets are set (see [BUILDING.md](BUILDING.md) §7).

The local build needs these SDK parts (Android Studio › SDK Manager): **Android SDK Platform 36**, Build-Tools,
and **NDK 28.2.13676358** (SDK Tools › NDK (Side by side), "Show package details"). Gradle installs missing ones
by itself once the licences are accepted.

Optional, smaller crash reports in the console: `--obfuscate --split-debug-info=build/symbols` and upload the
native debug symbols. Not needed for the first release.

### Permissions

Declared in `klunki/android/app/src/main/AndroidManifest.xml`, merged with the plugins' manifests (checked in
the pub cache: `bonsoir_android`, `camera_android_camerax`, `url_launcher_android`, `image_picker_android`,
`flutter_zxing`, `shared_preferences_android`):

| Permission | Why | Runtime prompt |
|---|---|---|
| `INTERNET` | TCP/WebSocket sockets for network play (hosting, joining, a relay); also needed for sockets in the local network | no |
| `ACCESS_NETWORK_STATE` | read connectivity for the host screen | no |
| `ACCESS_WIFI_STATE` | read the Wi-Fi IP address shown as "IP:Port" on the host screen | no |
| `CHANGE_WIFI_MULTICAST_STATE` | multicast lock for mDNS (Bonjour) discovery: "Räume in der Nähe" and announcing a hosted game | no |
| `CAMERA` | scan the host's QR code to join (flutter_zxing on CameraX); only while the scanner is open | yes |

Removed on purpose (`tools:node="remove"`): `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE`, which the camera plugin
declares for video recording. Features: `android.hardware.camera` and `android.hardware.camera.any` are **not
required**, so devices without a camera can install the app (joining by code or address still works).

Not requested: location, `NEARBY_WIFI_DEVICES`, notifications, storage, contacts, the advertising id
(`com.google.android.gms.permission.AD_ID`). No foreground service. The `url_launcher` plugin adds a non-exported
`WebViewActivity` that Klunki does not use (links open in the browser); `image_picker_android` adds a non-exported
`FileProvider` without permissions. To see the final list after a build:
`build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml` (path varies
with the AGP version), or the bundle explorer in the Play Console.

## Upload key and Play App Signing

Play App Signing is mandatory for new apps. Two keys:

- **App signing key:** signs what users install. **Google generates and keeps it** (choose "Google-generated key"
  when asked). You never hold it, so it cannot get lost on your side.
- **Upload key:** yours. It signs the `.aab` you upload; Play checks it and re-signs with the app signing key. The
  first upload registers it. If it is lost or leaked, the account owner can ask Play support to **reset the upload
  key** (a new certificate, a few days of waiting); the app itself is not lost. Still, back it up.

### Create the upload key (you, once)

```bash
mkdir -p ~/keys
keytool -genkeypair -v \
  -keystore ~/keys/klunki-upload.jks -storetype PKCS12 \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000
```

- RSA 4096 (2048 is the minimum), 10000 days ≈ 27 years (Play wants a certificate valid past 22 Oct 2033; 25+ years
  is the usual advice).
- keytool asks for a password and the certificate fields (name, organisation, country `DE`). With PKCS12 the key
  password is the store password: use the same value for both in `key.properties`.
- Keep the file **outside the repo**. Back up the `.jks` and the password in a password manager (both, together)
  and on a second medium. Never mail or commit it.

### Use it in the build

Create `klunki/android/key.properties` (ignored by git through `klunki/android/.gitignore`, which also ignores
`*.jks` and `*.keystore`):

```properties
storeFile=/Users/<you>/keys/klunki-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

`klunki/android/app/build.gradle.kts` reads it (or the `KLUNKI_KEYSTORE_FILE`, `KLUNKI_KEYSTORE_PASSWORD`,
`KLUNKI_KEY_ALIAS`, `KLUNKI_KEY_PASSWORD` environment variables in CI) and signs release builds with it. If any value
is missing, it falls back to the debug key, so CI and other machines keep building. Check the signer:

```bash
cd klunki
flutter build appbundle --release
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab   # your name, not "Android Debug"
git status --ignored android/key.properties                                   # listed as ignored
```

For CI signing, add the four `KEYSTORE_*` secrets (see [BUILDING.md](BUILDING.md) §7). Optional; uploads can be made
from the local build.

## Step by step in the Play Console

1. **Create app:** Home › Create app. App name `Klunki` (can be changed later), default language **German (de-DE)**,
   type **Game**, **Free** (a free app can never become paid), confirm the declarations (Developer Program
   Policies, US export laws).
2. **Dashboard › "Set up your app":** fill in the App content forms (section [App content](#app-content)) and the
   store listing (texts and [graphics](#graphics)). Store settings: category **Games › Board** (alternatives: Card,
   Casual), tags (e.g. Board, Two-player, Offline; pick from the list), contact email `contact@tronicum.com`,
   website `https://tronicum.github.io/klunki/`.
3. **Internal testing** (Testing › Internal testing), the fastest track, up to 100 testers, available within
   minutes:
   - Testers tab › create an email list (Google account emails of the testers).
   - Create release › Play App Signing: accept **Google-generated key** › upload `app-release.aab` (signed with the
     upload key) › release name (e.g. `1.0.0 (1)`) and release notes (de/en, "Erster Test") › Save › Review ›
     Start rollout.
   - Copy the **opt-in link** from the Testers tab and send it. Each tester opens it on the phone with the listed
     Google account, accepts, then installs from the Play Store link.
4. **Closed testing** (Testing › Closed testing › create a track, or use the default "Alpha"): testers via email
   lists or a Google Group, select countries, upload or promote the internal release. Closed releases go through
   review (hours to a few days). **Personal accounts: this is the track for the 12 testers / 14 days.** Testers
   must stay opted in for the whole 14 days; they should also use the app and can leave feedback.
5. **Open testing** (optional): anyone can join from the store page. Needs the complete store listing and review.
6. **Production:** personal accounts first click "Apply for production" on the dashboard after the closed test.
   Then Production › Create release (promote the tested release) › countries › staged rollout (e.g. 20 %, then
   100 %). The first review of a new app can take several days.

Version codes are shared across all tracks: promoting a release reuses its bundle; a new build needs a new code.

## Store texts (German)

**App-Name** (≤ 30): `Klunki – Spiele zu zweit` (24). Plain `Klunki` also works; the name must not contain
claims like "Nr. 1", prices or emoji.

**Kurzbeschreibung** (≤ 80):

> 4 Gewinnt, Mühle, Schach, Quartett und mehr – zu zweit, offline, ohne Werbung.

(78 characters)

**Vollständige Beschreibung** (≤ 4000):

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
> Ein Gerät startet einen Raum, das andere tritt per QR-Code oder Adresse bei: Android, iPhone, iPad oder ein
> Browser im selben WLAN. Kein Konto, kein Server von uns: die Geräte verbinden sich direkt.
>
> OHNE INTERNET
> Alle Spiele laufen offline. Klunki sammelt keine Daten für uns, zeigt keine Werbung und verkauft nichts.
>
> Sprachen: Deutsch, Englisch, Französisch, Spanisch, Arabisch, Persisch, Chinesisch.

(about 1,400 characters; Play has no separate keyword field, the description is indexed for search, so the game
names in it matter. Avoid keyword lists and repetition: the metadata policy forbids them.)

**Versionshinweise** for the first release (≤ 500): `Erste Version von Klunki.`

## Store texts (English)

**App name** (≤ 30): `Klunki – Games for Two` (22).

**Short description** (≤ 80):

> Four in a Row, Mill, Chess, Quartett and more for two. Offline, no ads.

(71 characters)

**Full description** (≤ 4000):

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
> One device opens a room, the other joins by QR code or address: Android, iPhone, iPad or a browser on the same
> Wi-Fi. No account, no server of ours: the devices connect directly.
>
> NO INTERNET NEEDED
> All games work offline. Klunki collects no data for us, shows no ads and sells nothing.
>
> Languages: German, English, French, Spanish, Arabic, Persian, Chinese.

**Release notes** (≤ 500): `First release of Klunki.`

The other app languages (fr, es, ar, fa, zh) can get translated listings later (Store presence › Store listings ›
Manage translations); without them, Play shows the English listing.

## Graphics

Sources: Play Console help "Add preview assets to showcase your app" **(check in the console)**.

| Asset | Rules | Status |
|---|---|---|
| **App icon** | 512 × 512, 32-bit PNG (alpha allowed), ≤ 1 MB. Full square, **no own rounded corners or drop shadow**: Play applies the mask (rounded square) and the shadow itself | **TODO:** still the default Flutter icon. Comes from KLD-097 (the "pocket" concept, variant pending); render the 512 px master from the same source as iOS, together with the Android launcher icons (`mipmap-*`, adaptive `mipmap-anydpi-v26`) |
| **Feature graphic** | 1024 × 500, JPEG or 24-bit PNG (no alpha), required. Shown at the top of the listing and in promotions; keep text and key art away from the edges, it may be cropped or overlaid | **TODO:** after the icon is final (icon art + "Klunki" + a few game pieces on the Spieltisch background). Can be rendered by a test like the screenshots |
| **Phone screenshots** | 2–8, JPEG or 24-bit PNG (no alpha), each side 320–3840 px, the long side at most twice the short side. For promotion (recommendations, "suggested" lists) at least 4 screenshots, at least 1080 px, 9:16 portrait or 16:9 landscape | Generated: `phone`, 1080 × 1920 (9:16) |
| **7" tablet screenshots** | up to 8, same format rules, each side 320–3840 px | Generated: `tablet-7`, 1200 × 1920 |
| **10" tablet screenshots** | up to 8, each side 1080–7680 px | Generated: `tablet-10`, 1600 × 2560 |
| Chromebook, Android XR, TV, Wear | not applicable | – |

Upload tablet screenshots: Play uses them for the large-screen listing and its tablet quality checks; without
them, the app shows phone screenshots on tablets.

The App Store sets (iPhone 1320 × 2868, 1206 × 2622) are 19.5:9, longer than 2:1, so they **do not pass Play's
ratio rule**. Hence a separate set.

### Generating the screenshots

The `playstore` group of `klunki/test/screenshots/screenshots_test.dart` renders the same nine scenes as the App
Store set (see [APPSTORE.md](APPSTORE.md#generating-them): menu, Quartett round, card gallery, Schiffe versenken,
GoStrategy, Chess, room hosting with QR code, Mühle, Wortgewandt) in light mode, German and English, as RGB PNGs without alpha,
and checks the pixel size. Without `KLUNKI_PLAYSTORE` the group is skipped.

```bash
cd klunki
KLUNKI_PLAYSTORE=/tmp/playstore flutter test test/screenshots --plain-name playstore
# One device or language only:
KLUNKI_PLAYSTORE=/tmp/playstore flutter test test/screenshots --plain-name "playstore phone/de"
# Check:
sips -g pixelWidth -g pixelHeight -g hasAlpha /tmp/playstore/*/*/*.png
```

Output: `<dir>/{phone,tablet-7,tablet-10}/{de,en}/NN-scene.png`, 54 files, about 22 MB. Play takes at most 8
screenshots per device type: leave one out (e.g. 03, the card gallery). The phone set is rendered at
411 × 731 dp × 2.625 (a typical Android phone width); the tablets at 600 × 960 and 800 × 1280 dp × 2.

## App content

Policy › App content in the Play Console. All forms must be complete before the first review.

### Privacy policy

`https://tronicum.github.io/klunki/privacy/` (KLD-096; needs Pages enabled, see [BUILDING.md](BUILDING.md) §7.1).
It must be reachable, not a PDF, and name the app and the developer as on the store page. Required for every app
(and for every app requesting `CAMERA`).

### App access

"All functionality is available without special access": no login, no account. Optional note for the reviewer:
"All games work offline on one device. Network play needs two devices on the same Wi-Fi: one taps 'Über WLAN
spielen' › 'Raum starten', the other scans the QR code or enters the address under 'Raum beitreten'."

### Ads

"No, my app does not contain ads."

### Advertising ID

"No" (the app does not use the advertising id; no `AD_ID` permission).

### Data safety

What the code does (checked: `klunki/pubspec.yaml`, `klunki/lib`, `packages/klunki_net/lib`; same findings as
APPSTORE.md "App Privacy"):

- **No analytics, crash reporting, ads or tracking SDKs.** Dependencies: Flutter, the own engine and network
  packages, `shared_preferences`, `bonsoir` (mDNS), `qr_flutter`, `flutter_zxing` + `camera`, `url_launcher`.
- **Stored on the device only** (`shared_preferences`): language (`locale`), player name (`playerName`), chosen
  Quartett deck (`quartettDeck`), relay address (`relayAddress`), "rooms through the relay" choice
  (`roomViaRelay`). Nothing is sent to the developer.
- **No developer server.** The card photos are bundled; the app makes no HTTP requests of its own. Wikipedia and
  licence links open in the browser only when tapped.
- **Network play:** the player name, the chosen game, moves and a random session token go **to the other player's
  device**, directly over TCP/WebSocket in the local network, or through a relay that the players run themselves
  (`klunki relay`; the native app has no default relay). Hosting announces the player name and the game on the local
  network via mDNS. The traffic is **not encrypted** (plain TCP/`ws://`; `wss://` only with a TLS relay).
- **Camera:** frames are decoded on the device for the QR code and neither stored nor sent.

**Recommended answer:** "Does your app collect or share any of the required user data types?" › **No**. Reasoning:
the developer receives nothing; data goes only to the other player's device at the user's request, in real time,
and is not kept by any service of ours. This matches the App Store answer "Data Not Collected" and the privacy
policy.

**Open decision (check in the console):** Play defines "collection" as data transmitted off the device by the
app, which some read to include the player name sent to the other device. The conservative alternative is to
declare **Personal info › Name**: collected, not shared (a transfer the user starts is not "sharing"), optional
(default names exist), processed ephemerally (the host holds it in memory for one game), purpose **App
functionality**; then "encrypted in transit" must be answered **No**, which shows on the store page. Whichever is
chosen, the privacy policy must say the same.

Other answers if asked: no account creation, so no account deletion URL; the app is not independently security
reviewed (optional badge, skip).

### Content rating (IARC questionnaire)

Category: **Game**. Expected result: **USK 0 / PEGI 3 / ESRB Everyone / IARC 3+**.

- Violence, blood, fear, sexual content, nudity, language, drugs, alcohol, tobacco, crude humour: **No**. GoStrategy
  and Schiffe versenken are abstract strategy games with tokens and grid markers; no depicted violence.
- Gambling or simulated gambling, real or virtual currency: **No**. Quartett compares values with no stakes.
- Users interacting or exchanging content (chat, voice, images): **No**. The only free text is the player name, shown
  to the one other player of a game; no chat, no public profiles. **(check the exact question wording; if it asks
  about any exchange between users, consider "Yes" with "Users Interact".)**
- Sharing the user's location with other users: **No**.
- Digital purchases: **No**. Unrestricted internet access or web browser: **No** (links open in the system browser).
- Is the app a web browser or search engine: **No**.

### Target audience and content

Choose the age groups the app is **designed for**. This decides whether Google's **Families policy** applies.

- **13+ only (13–15, 16–17, 18+):** no Families requirements. The form then asks whether the store listing could
  unintentionally appeal to children; colourful family board games may draw a "yes" from Google's review, which
  can lead to follow-up questions. Answer honestly.
- **Any group under 13 selected (also "mixed audience"):** the **Families policy** applies, in particular: the app
  and its listing must suit children, a privacy policy that covers children, compliance with COPPA and GDPR for
  children's data, no ads unless through Families-certified ad SDKs (Klunki has none), no precise location, no
  transmission of device identifiers, no unmoderated sharing of personal information. Points to check for Klunki in
  that case: **the player name** (a child may enter a real name) is sent to the other device and **announced on the
  local network via mDNS**, unencrypted; the relay option lets a child join rooms on a relay run by someone else.
  Both are probably acceptable for local play among people in the same Wi-Fi, but they need a conscious decision
  and possibly a hint in the app (e.g. "use a nickname"). Families apps also go through a stricter review.

**Recommendation:** decide this together with the App Store age rating (4+). The lighter path is target ages 13+;
the honest path for a family game collection may be "all ages", with the points above addressed. **Open decision
for the developer; flagged clearly here because it is hard to undo after launch** (changing the audience later
triggers a new review).

### Other declarations

News app: No. COVID-19 contact tracing/status: No. Government app: No. Financial features: none. Health: none.
Data deletion: not applicable (no accounts).

## Checklist

**Before the first upload**

- [ ] Play Console account created (organization with D-U-N-S, or personal), fee paid, identity verified.
- [ ] EU trader status declared; public contact data matches the Impressum.
- [ ] Decision: `applicationId` stays `de.klunki.klunki` (same as the iOS bundle id; cannot change after the first upload).
- [ ] Upload key created (`keytool`, above), backed up with its password, `klunki/android/key.properties` filled in,
      `git status` shows no secret.
- [ ] Final app icon in the Android launcher (`mipmap-*`, adaptive icon) and as 512 × 512 Play icon (KLD-097).
- [ ] `version:` in `pubspec.yaml` bumped if a bundle with this code was uploaded before.
- [ ] `flutter build appbundle --release --dart-define=KLUNKI_BUILD=<sha>` built; `keytool -printcert -jarfile …aab`
      shows the upload certificate.
- [ ] Release APK tested on a real Android phone: hot-seat, hosting and joining in the Wi-Fi (mDNS "Räume in der
      Nähe"), QR scan with the camera prompt, a device without camera if available.

**In the Play Console**

- [ ] App created (German default, Game, Free).
- [ ] Play App Signing: Google-generated key accepted.
- [ ] Internal testing: email list, release uploaded, opt-in link sent, installed by at least one tester.
- [ ] Store listing de + en: name, short and full description, icon, feature graphic, phone screenshots (≥ 4),
      7" and 10" tablet screenshots.
- [ ] Category Games › Board, tags, contact email, website.
- [ ] App content: privacy policy URL live, app access, ads (No), advertising id (No), data safety (decision
      above), content rating, target audience (decision above), news / government / financial / health.
- [ ] Personal account only: closed test with ≥ 12 opted-in testers for ≥ 14 days, then "Apply for production".
- [ ] Production release with release notes, countries, staged rollout.

**Later**

- [ ] Feature graphic rendered after the icon is final.
- [ ] Translated listings for fr, es, ar, fa, zh.
- [ ] Optional CI signing secrets, so `klunki-android-aab` from CI is uploadable.
- [ ] Revisit data safety and the privacy policy if crash reporting, a hosted relay or anything that sends data is
      added.

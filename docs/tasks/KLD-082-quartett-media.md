# KLD-082 — Quartett media: Wikipedia links and Commons photos (step 1: rockets)

- **ID:** `KLD-082`
- **Title:** Wikipedia links and free-licence Wikimedia Commons photos on the Quartett cards, rockets deck first; plus the stat format fix and new stats
- **Milestone:** M3 (content)
- **Status:** DONE for the rockets deck · cars, trains, planes done in KLD-084 (`docs/tasks/KLD-084-deck-photos.md`)
- **Depends on:** KLD-069 (decks, gallery), KLD-070 (PWA external-URL check)
- **Touched paths:**
  - `klunki/tool/fetch_card_media.py`, `klunki/tool/card_media/rockets.json`, `klunki/tool/check_pwa_external_urls.py`, `klunki/tool/update_web_fonts.py`
  - `klunki/assets/quartett/rockets/**` (32 JPEGs + `credits.json`), `klunki/pubspec.{yaml,lock}` (`url_launcher` 6.3.3, asset folder)
  - `klunki/lib/ui/games/{quartett_media,quartett_media_data,quartett_card,quartett_gallery}.dart`, `klunki/lib/ui/engine_l10n.dart`, `klunki/lib/l10n/**`
  - `packages/klunki_engine/lib/{quartett,quartett_decks}.dart`, `packages/klunki_engine/lib/debug/quartett_text.dart`, `packages/klunki_engine/test/quartett_decks_test.dart`
  - `klunki/test/ui/games/quartett_media_test.dart`, `klunki/test/screenshots/screenshots_test.dart`, small updates in `klunki/test/{l10n/rtl_test,l10n/translations_test,ui/games/quartett_decks_test}.dart`

## Goal

Every Quartett card can show a real photo (bundled, free licence, credited)
and link to its Wikipedia article. Pilot: the 32 rocket cards, with a
reusable, reproducible pipeline for the other decks.

## What was built

### Pipeline (`klunki/tool/fetch_card_media.py`, stdlib only)
- `python3 -I klunki/tool/fetch_card_media.py rockets` reads
  `klunki/tool/card_media/rockets.json` (card id → en/de article title, the
  chosen Commons file = the checked-in manual override, optional author
  override and note) and writes the assets, `credits.json` and the generated
  Dart data `lib/ui/games/quartett_media_data.dart`. Idempotent (rewrites only
  what changed; `--offline` rebuilds from the cache), `--candidates` lists
  the free images of the articles for choosing overrides.
- Wikipedia: the API resolves redirects to the canonical title; the de title
  comes from the en article's interlanguage link unless given; every URL is
  fetched and must answer HTTP 200.
- Commons: `prop=imageinfo&iiprop=url|extmetadata` gives `LicenseShortName`,
  `LicenseUrl`, `Artist`, `Credit`, `ImageDescription`. A file that is not on
  Commons (local fair-use upload) is skipped. Licence allow-list: public
  domain (incl. PD-USGov), CC0, CC BY and CC BY-SA (any version, ports, IGO),
  Free Art License, OGL, Licence Ouverte (Etalab), GODL-India, Commons'
  generic "Attribution". Rejected: NC, ND, fair use, "permission",
  GFDL-only, anything unclear. Public-domain files without a licence URL get
  the Public Domain Mark URL.
- Requests send `KlunkiBuild/0.1 (https://github.com/tronicum/klunki; asset collection)`,
  are throttled (1 s) and cached outside the repo (`$KLUNKI_MEDIA_CACHE`,
  default `$TMPDIR/klunki_card_media`); originals stay there.
- Images: `sips` (macOS built-in; it reads WebP but cannot write it, and
  `cwebp` is not installed) → JPEG, 480 px long side, quality 80 stepping
  down until ≤ 40 KB.
- Author: HTML stripped; a doubled "Unknown author" is collapsed and named
  after the source host; per-card overrides where Commons' field is
  unhelpful (A2, A3, E2, E3, G1, G3, G4).

### App
- **Card** (`QuartettCard`): a photo band (132 dp, dense 72 dp) between the
  header and the stats: the whole photo (contain) over a blurred cover copy,
  so tall rockets are not cropped. Decorative for screen readers. Stat rows
  unchanged (a long value now scales down instead of overflowing). No photo
  → the drawn pictogram only, as before. In game, in the gallery grid and on
  the full card.
- **Full card** (`showLinks: true`, gallery pager): "ⓘ" on the photo opens
  "Bildnachweis": "Foto: <Autor>, <Lizenz>", "Für die App verkleinert." (+
  for share-alike: "Die verkleinerte Fassung steht unter derselben Lizenz."),
  buttons Lizenz / Quelle / Schließen. Below the stats "Auf Wikipedia lesen"
  opens the article in the UI language, else English, else German.
- **Bildnachweise** (`QuartettImageCreditsScreen`): app-bar button in the
  deck list and in a deck with photos; every photo with thumbnail and credit
  line, tap = the credit dialog. (The app has no licences page of its own.)
- Links open through `url_launcher` (6.3.3, flutter.dev, BSD-3; external app,
  web: new tab). `quartettLinkOpener` is replaceable in tests; a failure
  shows "Der Link konnte nicht geöffnet werden." No `canLaunchUrl`, so no
  `LSApplicationQueriesSchemes` / Android `<queries>` needed.
- **Offline / CSP:** photos are bundled assets, precached by the PWA worker
  (`pwa_finalize.py` precaches all of `assets/`; release build: 65 files, the
  photos add 1.1 MB to a 43 MB build dir). Nothing is loaded from Wikimedia
  at runtime. `check_pwa_external_urls.py` now fails on any
  `upload.wikimedia.org` (hotlink) and allows wikipedia.org /
  wikimedia.org / creativecommons.org URLs only as link text in
  `main.dart.js`, `assets/NOTICES` and the bundled `credits.json`; it also
  checks the photos are precached.
- **Fonts:** credit authors are drawn in every locale, so
  `update_web_fonts.py subset` also reads the credits (H4's author is "海人");
  a test checks every credit and every formatted stat value against the
  bundled fonts.
- **l10n:** 15 keys in one KLD-082 block (3 stat keys + 12 photo/link keys),
  de template, others machine-translated under `@@x-review`.

### Stat format fix and new stats (same change)
- **Bug:** "1999,0": `formatQuartettValue` printed one decimal whenever
  `value is double`, which on the web is true for every number. Now each
  `QuartettStat` declares its format: `decimals` (max digits; validation
  rejects more), `fixedDecimals` (0–100 s: "7,0 s"), `isYear` (bare digits, no
  unit, no grouping; kept generic, no deck uses it now), `grouped` (thousands
  separator per locale) and `isPercent` (unit `%`, locale percent format).
  Western digits in every locale (fa/ar fall back to English formatting).
- **Years replaced** (user decision, "older/newer" is a poor trump):
  trains `inService` and planes `firstFlight` → `built` "Gebaut" (Stk., ↑,
  grouped: "16.000 Stk." / "16,000 units"); rockets `firstFlight` →
  `successPct` "Erfolgsquote" (%, ↑, one decimal: "92,3 %" / "92.3%").
  Values approximate, unverified (see the deck comments and the KLD-069
  card). Stat ids are not in `GameConfig`; the guest replays with the same
  engine, so network verify is unaffected (klunki_net tests green).

## Rockets: images and licences

32 of 32 cards have a photo. Licences: Public domain 17 (NASA, NRO, USAF,
USSF, own-work release), CC BY-SA 4.0 6, CC BY 4.0 4 (China News Service,
Russian MoD/mil.ru), GODL-India 2 (ISRO), CC0 1 (SpaceX), CC BY 2.0 1,
CC BY-SA 3.0 IGO 1 (ESA). Total added: 32 JPEGs 1 061 574 B (largest
40 575 B) + `credits.json` 28 458 B = **1 090 032 B**.

Not photos of a flying rocket, for lack of a free one on Commons:
C3 Vega C (scale model; the free Licence-Ouverte launch photo shows the
rocket tiny, ESA's files are infographics), E4 Energija (test article in the
Baikonur hall; launch pictures are drawings), F4 Langer Marsch 2C (3D
rendering).

| Card | Name | Commons file | Author | Licence | SA | Wikipedia |
|---|---|---|---|---|---|---|
| A1 | Saturn V | [Apollo 11 Launch - GPN-2000-000630.jpg](https://commons.wikimedia.org/wiki/File:Apollo_11_Launch_-_GPN-2000-000630.jpg) | NASA | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Saturn_(Rakete)) · [en](https://en.wikipedia.org/wiki/Saturn_V) |
| A2 | Saturn IB | [Saturn IB (AS-201) launch.jpg](https://commons.wikimedia.org/wiki/File:Saturn_IB_(AS-201)_launch.jpg) | NASA | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Saturn_(Rakete)) · [en](https://en.wikipedia.org/wiki/Saturn_IB) |
| A3 | SLS Block 1 | [Artemis II launch (SLS MAF 20260401 ArtemisIILaunch 02) crop.jpg](https://commons.wikimedia.org/wiki/File:Artemis_II_launch_(SLS_MAF_20260401_ArtemisIILaunch_02)_crop.jpg) | NASA | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Space_Launch_System) · [en](https://en.wikipedia.org/wiki/Space_Launch_System) |
| A4 | N1 | [N1 1M1 mockup on the launch pad at the Baikonur Cosmodrome in late 1967.jpg](https://commons.wikimedia.org/wiki/File:N1_1M1_mockup_on_the_launch_pad_at_the_Baikonur_Cosmodrome_in_late_1967.jpg) | National Reconnaissance Office | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/N1_(Rakete)) · [en](https://en.wikipedia.org/wiki/N1_(rocket)) |
| B1 | Falcon 9 | [SpaceX Demo-2 Launch (NHQ202005300044) (cropped).jpg](https://commons.wikimedia.org/wiki/File:SpaceX_Demo-2_Launch_(NHQ202005300044)_(cropped).jpg) | Joel Kowsky | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Falcon_9) · [en](https://en.wikipedia.org/wiki/Falcon_9) |
| B2 | Falcon Heavy | [Falcon Heavy Demo Mission (39337245145).jpg](https://commons.wikimedia.org/wiki/File:Falcon_Heavy_Demo_Mission_(39337245145).jpg) | SpaceX | [CC0](https://creativecommons.org/publicdomain/zero/1.0/deed.en) | – | [de](https://de.wikipedia.org/wiki/Falcon_Heavy) · [en](https://en.wikipedia.org/wiki/Falcon_Heavy) |
| B3 | Starship | [SpaceX Starship ignition during IFT-5.jpg](https://commons.wikimedia.org/wiki/File:SpaceX_Starship_ignition_during_IFT-5.jpg) | Steve Jurvetson | [CC BY 2.0](https://creativecommons.org/licenses/by/2.0) | – | [de](https://de.wikipedia.org/wiki/Starship) · [en](https://en.wikipedia.org/wiki/SpaceX_Starship) |
| B4 | New Glenn | [New Glenn - BlueBird 7 Launch (9628277) (cropped).jpg](https://commons.wikimedia.org/wiki/File:New_Glenn_-_BlueBird_7_Launch_(9628277)_(cropped).jpg) | U.S. Space Force photo by Gwendolyn Kurzen | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/New_Glenn) · [en](https://en.wikipedia.org/wiki/New_Glenn) |
| C1 | Ariane 5 | [Ariane 5 with James Webb Space Telescope Prelaunch (51773093465).jpg](https://commons.wikimedia.org/wiki/File:Ariane_5_with_James_Webb_Space_Telescope_Prelaunch_(51773093465).jpg) | Chris Gunn | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Ariane_5) · [en](https://en.wikipedia.org/wiki/Ariane_5) |
| C2 | Ariane 6 (A64) | [Ariane 6 on pad.jpg](https://commons.wikimedia.org/wiki/File:Ariane_6_on_pad.jpg) | ESA | [CC BY-SA 3.0 igo](https://creativecommons.org/licenses/by-sa/3.0/igo/deed.en) | yes | [de](https://de.wikipedia.org/wiki/Ariane_6) · [en](https://en.wikipedia.org/wiki/Ariane_6) |
| C3 | Vega C | [Maquette Vega C DSC 0020.JPG](https://commons.wikimedia.org/wiki/File:Maquette_Vega_C_DSC_0020.JPG) | Pline | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Vega_(Rakete)) · [en](https://en.wikipedia.org/wiki/Vega_C) |
| C4 | Ariane 4 | [Ariane42P rocket.png](https://commons.wikimedia.org/wiki/File:Ariane42P_rocket.png) | NASA | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Ariane_4) · [en](https://en.wikipedia.org/wiki/Ariane_4) |
| D1 | Atlas V | [Atlas V 551 launch with Juno.jpg](https://commons.wikimedia.org/wiki/File:Atlas_V_551_launch_with_Juno.jpg) | NASA/Tony Gray and Don Kight | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Atlas_V) · [en](https://en.wikipedia.org/wiki/Atlas_V) |
| D2 | Delta IV Heavy | [Delta IV Heavy on pad with Orion EFT-1 (KSC-2014-4686).jpg](https://commons.wikimedia.org/wiki/File:Delta_IV_Heavy_on_pad_with_Orion_EFT-1_(KSC-2014-4686).jpg) | Kim Shiflett | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Delta_IV) · [en](https://en.wikipedia.org/wiki/Delta_IV_Heavy) |
| D3 | Space Shuttle | [STS120LaunchHiRes-edit1.jpg](https://commons.wikimedia.org/wiki/File:STS120LaunchHiRes-edit1.jpg) | NASA; edited by jjron (tilt corrected) | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Space_Shuttle) · [en](https://en.wikipedia.org/wiki/Space_Shuttle) |
| D4 | Titan IV B | [Titan4B on Launch Complex 40.jpg](https://commons.wikimedia.org/wiki/File:Titan4B_on_Launch_Complex_40.jpg) | NASA | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Titan_(Tr%C3%A4gerrakete)) · [en](https://en.wikipedia.org/wiki/Titan_IV) |
| E1 | Sojus-U | [Soyuz TM-31 launch.jpg](https://commons.wikimedia.org/wiki/File:Soyuz_TM-31_launch.jpg) | NASA | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Sojus_(Rakete)) · [en](https://en.wikipedia.org/wiki/Soyuz-U) |
| E2 | Proton-M | [Night start of Proton-M rocket with Blagovest satellite 17.08.2017.jpg](https://commons.wikimedia.org/wiki/File:Night_start_of_Proton-M_rocket_with_Blagovest_satellite_17.08.2017.jpg) | Ministry of Defence of the Russian Federation (mil.ru) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) | – | [de](https://de.wikipedia.org/wiki/Proton_(Rakete)) · [en](https://en.wikipedia.org/wiki/Proton-M) |
| E3 | Angara A5 | [Launch of the Angara-A5 from the Plesetsk cosmodrome (2025-06-19) 05.jpg](https://commons.wikimedia.org/wiki/File:Launch_of_the_Angara-A5_from_the_Plesetsk_cosmodrome_(2025-06-19)_05.jpg) | Ministry of Defence of the Russian Federation (mil.ru) | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) | – | [de](https://de.wikipedia.org/wiki/Angara_(Rakete)) · [en](https://en.wikipedia.org/wiki/Angara_A5) |
| E4 | Energija | [Космодром Байконур, ракета Энергия в ангаре.jpg](https://commons.wikimedia.org/wiki/File:%D0%9A%D0%BE%D1%81%D0%BC%D0%BE%D0%B4%D1%80%D0%BE%D0%BC_%D0%91%D0%B0%D0%B9%D0%BA%D0%BE%D0%BD%D1%83%D1%80,_%D1%80%D0%B0%D0%BA%D0%B5%D1%82%D0%B0_%D0%AD%D0%BD%D0%B5%D1%80%D0%B3%D0%B8%D1%8F_%D0%B2_%D0%B0%D0%BD%D0%B3%D0%B0%D1%80%D0%B5.jpg) | Nikolai Bulykin | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Energia) · [en](https://en.wikipedia.org/wiki/Energia) |
| F1 | Langer Marsch 5 | [Launching Tianhe Core Module.jpg](https://commons.wikimedia.org/wiki/File:Launching_Tianhe_Core_Module.jpg) | China News Service | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) | – | [de](https://de.wikipedia.org/wiki/Langer_Marsch_5) · [en](https://en.wikipedia.org/wiki/Long_March_5) |
| F2 | Langer Marsch 2F | [LM2F-Y13.png](https://commons.wikimedia.org/wiki/File:LM2F-Y13.png) | China News Service | [CC BY 4.0](https://creativecommons.org/licenses/by/4.0) | – | [de](https://de.wikipedia.org/wiki/Langer_Marsch_2) · [en](https://en.wikipedia.org/wiki/Long_March_2F) |
| F3 | Langer Marsch 3B | [The Launch of Long March 3B Rocket.jpg](https://commons.wikimedia.org/wiki/File:The_Launch_of_Long_March_3B_Rocket.jpg) | AAxanderr | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Langer_Marsch_3) · [en](https://en.wikipedia.org/wiki/Long_March_3B) |
| F4 | Langer Marsch 2C | [CZ-2C rendering (cropped).jpg](https://commons.wikimedia.org/wiki/File:CZ-2C_rendering_(cropped).jpg) | Shujianyang | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Langer_Marsch_2) · [en](https://en.wikipedia.org/wiki/Long_March_2C) |
| G1 | H3 | [H3 rocket launch.jpg](https://commons.wikimedia.org/wiki/File:H3_rocket_launch.jpg) | U.S. Air Force (AF991) | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/H3_(Rakete)) · [en](https://en.wikipedia.org/wiki/H3_(rocket)) |
| G2 | H-IIB | [H-ⅡBロケット8号機.jpg](https://commons.wikimedia.org/wiki/File:H-%E2%85%A1B%E3%83%AD%E3%82%B1%E3%83%83%E3%83%888%E5%8F%B7%E6%A9%9F.jpg) | Shinntarou | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/H-II) · [en](https://en.wikipedia.org/wiki/H-IIB) |
| G3 | PSLV | [PSLVC62.webp](https://commons.wikimedia.org/wiki/File:PSLVC62.webp) | ISRO (Indian Space Research Organisation) | [GODL-India](https://data.gov.in/sites/default/files/Gazette_Notification_OGDL.pdf) | – | [de](https://de.wikipedia.org/wiki/Polar_Satellite_Launch_Vehicle) · [en](https://en.wikipedia.org/wiki/Polar_Satellite_Launch_Vehicle) |
| G4 | LVM3 | [LVM3 M6 with BlueBird-6 during Liftoff (3).webp](https://commons.wikimedia.org/wiki/File:LVM3_M6_with_BlueBird-6_during_Liftoff_(3).webp) | ISRO (Indian Space Research Organisation) | [GODL-India](https://data.gov.in/sites/default/files/Gazette_Notification_OGDL.pdf) | – | [de](https://de.wikipedia.org/wiki/Launch_Vehicle_Mark_3) · [en](https://en.wikipedia.org/wiki/LVM3) |
| H1 | Electron | [Rocket Lab PREFIRE and Ice Launch (KSC-20240605-PH-RKL01 0005).jpg](https://commons.wikimedia.org/wiki/File:Rocket_Lab_PREFIRE_and_Ice_Launch_(KSC-20240605-PH-RKL01_0005).jpg) | NASA Kennedy Space Center / Rocket Lab | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Electron_(Rakete)) · [en](https://en.wikipedia.org/wiki/Rocket_Lab_Electron) |
| H2 | Pegasus XL | [Launch of Pegasus F43 from Stargazer (KSC-20161215-PH LAL02 0005).jpg](https://commons.wikimedia.org/wiki/File:Launch_of_Pegasus_F43_from_Stargazer_(KSC-20161215-PH_LAL02_0005).jpg) | NASA/Lori Losey | [Public domain](https://creativecommons.org/publicdomain/mark/1.0/) | – | [de](https://de.wikipedia.org/wiki/Pegasus_(Rakete)) · [en](https://en.wikipedia.org/wiki/Northrop_Grumman_Pegasus) |
| H3 | Firefly Alpha | [Firefly Alpha 1st Flight.jpg](https://commons.wikimedia.org/wiki/File:Firefly_Alpha_1st_Flight.jpg) | JacobRendon | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Firefly_Aerospace) · [en](https://en.wikipedia.org/wiki/Firefly_Alpha) |
| H4 | Epsilon | [Epsilon rocket F2.jpg](https://commons.wikimedia.org/wiki/File:Epsilon_rocket_F2.jpg) | 海人 | [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0) | yes | [de](https://de.wikipedia.org/wiki/Epsilon_(Rakete)) · [en](https://en.wikipedia.org/wiki/Epsilon_(rocket)) |

### Licence notes
- **CC BY-SA in an AGPL app:** fine with attribution. The photos are
  separate bundled works (not code); each resized copy is an adaptation and
  stays under its CC BY-SA licence (said in the credit dialog, `"modified"`
  in `credits.json`). CC BY-SA 4.0 is one-way compatible with GPLv3, but
  that is not needed here: the photos are not combined into the program.
- **Attribution in the app:** every credit names author, licence (with link)
  and source (Commons file page) in the "ⓘ" dialog and on "Bildnachweise".
  Store listings or a printed deck would need the same credits.
- **GODL-India** (G3, G4): India's open government licence (attribution,
  commercial use and adaptation allowed), accepted under "equal open
  licences"; Commons marks it free.
- **Public domain** is US-federal or own-work release; the Public Domain Mark
  URL is used as the "licence" link. Some NASA/USSF photos show company
  logos on the rockets (trademarks, not copyright; no endorsement implied).
- **Russian MoD (mil.ru) CC BY 4.0** (E2, E3): the site's CC BY 4.0
  release as recorded on Commons; author named after the source.
- The Epsilon author "海人" is a Commons user name, kept as given.

## Stats changed in this card

Approximate, unverified, rounded figures from general knowledge (as the rest
of the KLD-069 data); see the comment above each deck in
`packages/klunki_engine/lib/quartett_decks.dart`.

**Trains, "Gebaut" (Stk., ↑):** ICE 1 60 · ICE T 71 · ICE 3 67 · ICE 4 137 ·
Shinkansen 0 250 · 300 69 · N700S 66 · E5 59 · TGV Sud-Est 109 · TGV
Atlantique 105 · TGV Duplex 89 · TGV V150 1 · Eurostar e320 17 · AVE S-103 26 ·
Frecciarossa 1000 50 · Talgo 350 46 · Fuxing CR400AF 450 · KTX-Sancheon 24 ·
Shanghai Transrapid 3 · Avelia Liberty 28 · BR 103 149 · BR 101 145 · Re 460
119 · Taurus ES64U4 100 · Flying Scotsman (A3 class) 79 · Mallard (A4) 35 ·
18 201 1 · Big Boy 25 · Krokodil 51 · SD70ACe 1500 · AC6000CW 317 · Class 66 480.

**Planes, "Gebaut" (Stk., ↑):** A380 251 · 747-8I 48 · 777-300ER 840 ·
A350-900 600 · A320neo (family) 4000 · 737 MAX (all) 1900 · A220-300 300 ·
E195-E2 50 · Concorde 20 · Tu-144 16 · SR-71 32 · X-15 3 · DC-3 (incl. C-47)
16000 · Ju 52/3m 4800 · Super Constellation 579 · Dash 8-400 640 · An-225 1 ·
An-124 55 · Dreamlifter 4 · Beluga XL 6 · Cessna 172 45000 · Learjet 75 250 ·
G650 500 · PC-12 2000 · Wright Flyer (I–III) 3 · Blériot XI 800 · Spirit of
St. Louis 1 · Junkers F 13 322 · Solar Impulse (1 and 2) 2 · H-4 Hercules 1 ·
Stratolaunch Roc 1 · Rutan Voyager 1. (Per card variant, not the whole
family: 737 MAX 8 shows all MAX, not all 737s.)

**Rockets, "Erfolgsquote" (%, ↑, fully successful launches):** Saturn V
92.3 (Apollo 6 partial) · Saturn IB 100 · SLS 100 (1 flight) · N1 0 (4) ·
Falcon 9 97.5 · Falcon Heavy 72.7 · Starship 45.5 · New Glenn 50 (2) ·
Ariane 5 95.7 · Ariane 6 80 (5) · Vega C 75 (4) · Ariane 4 97.4 · Atlas V 99 ·
Delta IV Heavy 93.8 · Space Shuttle 98.5 · Titan IV 89.7 · Sojus-U 97.2 ·
Proton-M 90.4 · Angara A5 87.5 · Energija 50 (2, Polyus failed) · LM-5 92.9 ·
LM-2F 100 · LM-3B 95 · LM-2C 98.6 · H3 83.3 (6) · H-IIB 100 · PSLV 93.3 ·
LVM3 100 (7) · Electron 94.3 · Pegasus XL 93.3 · Firefly Alpha 33.3 (6) ·
Epsilon 83.3 (6). Partial failures count as failures; in the reusable set a
booster lost on a planned landing counts as a partial failure (Falcon 9,
Falcon Heavy center cores, New Glenn NG-1): with pure mission success six
rockets would sit at 100 % and the stat would tie in 3.0 % of pairs.

## Tie rates (Trumpf, share of 496 pairs; must be < 3 %)

| Deck | New stat | Ties |
|---|---|---|
| trains | built | 0.2 % (1: TGV V150 / 18 201) |
| rockets | successPct | 2.6 % (100: A2/A3/F2/G2/G4, 50: B4/E4, 83.3: G1/H4, 93.3: G3/H2) |
| planes | built | 2.2 % (1: An-225 / Spirit / H-4 / Roc / Voyager, 3: X-15 / Wright) |

All other stats unchanged (KLD-069 table).

## Tests
- `klunki/test/ui/games/quartett_media_test.dart`: every rocket card has
  complete, allowed credits (or none); assets exist, are JPEGs ≤ 40 KB, no
  stray files, folder registered; Wikipedia links are https
  `de|en.wikipedia.org/wiki/…`, every card has one; language fallback; the
  generated Dart matches `credits.json`; credit texts and every formatted
  stat value are in the bundled fonts; photo above the stats, no
  photo/link in a trick, pictogram-only fallback, missing asset harmless;
  gallery grid photos; "ⓘ" dialog with licence/source links (mock
  launcher), share-alike note; "Auf Wikipedia lesen" in de/en/fr; failed
  launch → snack bar; Bildnachweise screen; number format (years, grouped
  counts, percent, decimals) in all locales and on every card of every deck
  in de/en/fa.
- Engine: `formatNumber` per stat from doubles (the web runtime), year
  rules, validation of decimals and years.
- Screenshots (`KLUNKI_SHOTS=… flutter test test/screenshots --plain-name kld082`):
  `kld082-deck-rockets-*`, `kld082-card-rockets-{A1,B3,G3}-*`,
  `kld082-credit-dialog-*`, `kld082-image-credits-*`, phone light/dark.

## Next: cars, trains, planes (done: KLD-084)
1. Copy `klunki/tool/card_media/rockets.json` to `<deck>.json` with en titles.
2. `python3 -I klunki/tool/fetch_card_media.py <deck> --candidates`, pick
   photos (lead images are often logos or fair use), set `file`, rerun
   without `--candidates`, look at the JPEGs.
3. Add `- assets/quartett/<deck>/` to `pubspec.yaml`; run
   `python3 -I tool/update_web_fonts.py subset` (credit authors).
4. Extend the data tests in `quartett_media_test.dart` to the deck.
Cars will be the hardest: many car photos on Commons are fine, but recent
models often only have press photos (not free).

# Changelog

What changed in each Klunki release, in plain words. Newest first. Versions are `MAJOR.MINOR.PATCH`
(new games or features raise MINOR, fixes raise PATCH; see `docs/RELEASING.md`). Each release has a
short German summary ("Kurz") for the store notes and the testers.

## [Unreleased]

## [1.0.0] – first external test (TestFlight, Play internal testing, web beta)

Kurz: Acht Spiele für zwei – auf einem Gerät, mit zwei Geräten im selben WLAN oder im Browser über einen
Raumcode. Deutsch und sechs weitere Sprachen.

### Games
- **4 Gewinnt** (Four in a Row) and **Mühle** (Nine Men's Morris).
- **Quartett** in two variants, **Trumpf** and **Sets**, with four decks (cars, trains, rockets,
  planes), card photos and Wikipedia links with image credits; house rule "with 3 or fewer cards you
  choose" in Trumpf.
- **Schiffe versenken** (sink the fleet) with a fleet of six ships and an easy setup (random fleet,
  move, turn).
- **GoStrategy** (hidden ranks, capture the flag) with the setup on the real board.
- **Schach** (chess, full rules, automatic draws); the room starter picks white, black or random.
- **Wortgewandt** (word tile game) with German and English word lists.

### Playing together
- **One device** (hot-seat): a cover hides the hand, rack or fleet when the device is handed over.
- **With others**: "Raum starten" / "Raum beitreten" from the menu or right from a game's tile;
  join by room code, QR code or link; devices on the same Wi-Fi find each other.
- **Browser vs browser** through a small relay that also serves the web app; relays can ask for a club
  code (Clubcode), off by default.
- Hidden information stays hidden over the network: the starting device is the referee and the other
  device only sees what it may see; secrets are checked at the end.
- Rejoin after a lost connection (only with the session's own token).
- Builds that do not fit together refuse to play and say which device has to update.

### App
- Player names (Anna and Ben by default, your own names possible), no X / O anywhere.
- Confirmation before quitting a running game; resign in every game.
- Warm "Spieltisch" look in light and dark, a new app icon.
- **7 languages**: German, English, French, Spanish, Chinese, Arabic and Persian (right to left).
- "Über Klunki" with privacy policy and Impressum (readable offline), support, source code, licences.
- Version line "Version 1.0.0 (b8752a9)": version and commit; build number, protocol and game data in
  small print on the About screen.

### Web
- Offline-capable web app (PWA), nothing loaded from a CDN.
- Web beta on GitHub Pages: plays on one device; network play there needs a secure (wss://) relay.

[Unreleased]: https://github.com/tronicum/klunki/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/tronicum/klunki/releases/tag/v1.0.0

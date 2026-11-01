# Klunki – Developer Diary

A short log of milestones: "firsts" on real devices and in real play. Implementation details live in `docs/tasks/` and the git history.

## 2026-10-25 – Day 1: from scaffold to five games
- Project scaffold: pure-Dart engine, Flutter shell, task board for parallel work.
- All five game engines (4 Gewinnt, Mühle, Quartett, Schiffe versenken) with a narrated text demo.
- Own network protocol `klunki_net` (NDJSON over TCP, host/guest, rejoin).
- First game screens for every game; app-level end-to-end test: two controllers play Mühle over the network.
- Installable offline PWA; first run on the iOS simulators (iPhone and iPad).

## 2026-10-31 – Browser, relay, real phones
- 7 languages including RTL (Arabic, Persian), bundled fonts so the PWA works offline.
- Browser joins a native host via WebSocket; then a **relay with room codes**: browser vs browser.
- **First install on a real iPhone** (troniPhone, release build).
- **First cross-platform game: iPhone vs browser** over the relay.
- GoStrategy (hidden-rank capture-the-flag) added; setup moved onto the real board after playtesting.
- Real secrecy for hidden-information games (host-side redaction, SHA-256 commitments, end-of-game verification).
- QR code scanning to join (open-source zxing).
- Quartett decks with themes (cars, trains, rockets, planes) and a card gallery.
- **CI on GitHub** (tests, PWA and Android APK builds); **first green CI run** after fixing three flaky network tests at the root (lost "bye" on close).
- Quartett cards get Wikipedia links and openly licensed Commons photos, for all 128 cards.
- Build compatibility check (protocol 3): old and new builds refuse to play together instead of silently diverging.
- Chess: engine with full FIDE rules (all perft counts match).

## 2026-11-01 – Android and iPad
- **First install on an Android phone** (Redmi Note 13 5G), APK from GitHub CI over the local Wi-Fi, no developer mode needed.
- **First install on an iPad** (troniPad).
- **First Android vs iOS Quartett game**, joined by **scanning the QR code**; it worked on the first try.
- Quartett Trumpf turn order verified by a real-browser end-to-end test (headless Firefox, 200-round games); fixed a game-end bug found by it.
- Chess board in the app (hot-seat).
- Playtest feedback: in Quartett the comparison is a "Runde" and a tie leads to a "Stechen", not a "Stich" (credit: the developer's son).
- Playtest feedback: "hosten" is English jargon that kids don't understand, and "beitreten" is too hidden (credit: the developer's younger son).
- Font fix: on iOS the bundled fallback fonts had replaced the system font (bold-looking umlauts); fallbacks now web-only.

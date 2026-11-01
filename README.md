# Klunki

Cross-platform casual game app (**iOS, Android, PWA**) for classic two-player games, played on one device
(hot-seat), over the local Wi-Fi, or browser vs browser through a small relay:

- **4 Gewinnt** (Four in a Row)
- **Mühle** (Nine Men's Morris)
- **Quartett** (superlative card game) in two variants: **Trumpf** and **Sets**
- **Schiffe versenken** (sink-the-fleet guessing game)
- **GoStrategy** (hidden-rank capture-the-flag; engine and terminal only so far)

Built with **Flutter**: one codebase compiles to Android, iOS and the web (PWA). No Node.js.

**Docs:** [Building it yourself](docs/BUILDING.md) (toolchains, Android, iOS/Xcode, PWA, CI) ·
[Demo runbook](docs/DEMO.md) · [Network protocol](packages/klunki_net/PROTOCOL.md) ·
[Architecture](docs/ARCHITECTURE.md) · [Task board](docs/tasks/BOARD.md)

## Layout

```
klunki/
├── packages/
│   └── klunki_engine/   # pure-Dart game logic, NO Flutter dep. Fully unit-tested.
│       └── lib/
│           ├── game.dart          # shared types (Player, Move, GameResult, ...)
│           ├── connect4.dart      # 4 Gewinnt engine
│           ├── muehle.dart        # Mühle engine
│           └── quartett.dart      # Quartett engine
│       └── test/                # dart test for the engine (runs without Android SDK)
│   └── klunki_net/      # pure-Dart networking: TCP/WebSocket host + guest, relay, CLI (PROTOCOL.md)
├── klunki/                    # the Flutter app (UI + transport layer on top of engine)
│   └── lib/
│       ├── main.dart
│       ├── app/               # routing, theme
│       ├── ui/                # game screens (board, cards)
│       └── transport/         # hot-seat vs network abstraction (same engine)
├── .github/workflows/         # CI: analyze + test (ci.yml), PWA/APK builds (build.yml)
└── docs/
    ├── BUILDING.md            # build it yourself: toolchains, Android, iOS, PWA, CI
    ├── ARCHITECTURE.md        # how the pieces fit
    ├── ROADMAP.md             # milestones
    └── tasks/                 # agent-ready task cards (pick one up, run it)
```

## Quick start

```bash
# engine tests (no Android SDK required — pure Dart)
cd packages/klunki_engine
dart pub get
dart test

# text debug frontend (same console as the in-app "Debug-Konsole")
dart run bin/klunki.dart                    # interactive
dart run bin/klunki.dart connect4 3 3 4 4   # scripted: play moves, print boards

# run the app (needs the Android SDK / Xcode / Chrome — see flutter doctor)
cd klunki
flutter pub get
flutter run

# app-level e2e: two app stacks play Mühle over loopback TCP (from klunki/)
flutter test test/e2e

# PWA build (from klunki/): fills the offline service worker's build hash
# and precache list — serve build/web/ afterwards
flutter build web --release && python3 build/web/pwa_finalize.py
```

See [`docs/BUILDING.md`](docs/BUILDING.md) for the full build guide, `docs/ROADMAP.md` for milestones and
`docs/tasks/` for agent-executable cards.

## License

Klunki is licensed under the **GNU Affero General Public License v3.0**
(AGPL-3.0-only). See [`LICENSE`](LICENSE).

Bundled third-party data keeps its own licence (all listed on the app's licence page): fonts (SIL OFL 1.1),
Quartett card photos (see `klunki/assets/quartett/*/credits.json`), and the word lists of the word tile game
(`klunki/assets/wordlists/*/SOURCE.txt`):

- German: [enz/german-wordlist](https://github.com/enz/german-wordlist), CC0-1.0.
- English: the English Speller Database (ESDB, formerly SCOWL) by Kevin Atkinson,
  [en-wl/wordlist](https://github.com/en-wl/wordlist), "Copyright 2000-2026 by Kevin Atkinson", MIT-like licence
  (full notice in `klunki/assets/wordlists/en/LICENSE`); derived mainly from 12dicts and ENABLE2K (public domain,
  Alan Beale).

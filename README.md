# Klunki

Cross-platform casual game app (**iOS, Android, PWA**) for classic brain-teaser
games:

- **4 Gewinnt** (Connect Four)
- **Mühle** (Nine Men's Morris)
- **Quartett** (collect-the-four / superlative card game)
- **Schiffe versenken** (Battleship)

Built with **Flutter** — one codebase compiles to Android, iOS and the web
(PWA). No Node.js.

## Play modes (roadmap)

1. **Hot-seat** (1 device, hand the phone to the opponent) — first PoC.
2. **Local network** (2 phones on the same Wi-Fi, over IP) — second PoC.
3. **Bluetooth** — later.

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
├── klunki/                    # the Flutter app (UI + transport layer on top of engine)
│   └── lib/
│       ├── main.dart
│       ├── app/               # routing, theme
│       ├── ui/                # game screens (board, cards)
│       └── transport/         # hot-seat vs network abstraction (same engine)
└── docs/
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

# PWA build (from klunki/): fills the offline service worker's build hash
# and precache list — serve build/web/ afterwards
flutter build web --release && python3 build/web/pwa_finalize.py
```

See `docs/ROADMAP.md` for milestones and `docs/tasks/` for agent-executable cards.

## License

Klunki is licensed under the **GNU Affero General Public License v3.0**
(AGPL-3.0-only). See [`LICENSE`](LICENSE).

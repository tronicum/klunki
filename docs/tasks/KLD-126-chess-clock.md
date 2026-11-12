# KLD-126: Chess clock

- **ID:** `KLD-126`
- **Title:** Chess clock: time controls, pause, flag fall; hot-seat and network
- **Milestone:** M3
- **Status:** DONE
- **Depends on:** KLD-059 (chess over the network), KLD-122 ("Zug bestätigen"), KLD-120 (reconnect)
- **Touched paths:**
  - `packages/klunki_engine/lib/{chess_clock,chess,game,registry}.dart`, `test/{chess_clock,compat,chess}_test.dart`
  - `packages/klunki_net/lib/src/{host,guest}.dart`, `PROTOCOL.md`, `test/chess_clock_net_test.dart`
  - `klunki/lib/transport/{game_clock,hot_seat_transport,network_transport}.dart`
  - `klunki/lib/profile/chess_clock_settings.dart`, `klunki/lib/ui/games/chess/{chess_clock_view,chess_board}.dart`
  - `klunki/lib/ui/{player_name_dialog,engine_l10n}.dart`, `klunki/lib/ui/pairing/{pairing_screen,relay_host_screen}.dart`
  - `klunki/lib/ui/shell/screen_registry.dart`, `klunki/lib/ui/rules/games/chess_rules.dart`, `klunki/lib/l10n/**`
  - Chinese web font subset (now 2 parts: `NotoSansSC`, `NotoSansSC2`)

## Goal
Chess can be played with a clock: "Ohne Uhr" (default), 5 Min, 10 Min, 15 Min + 10 s, 30 Min, chosen in
"Wer spielt?" (hot-seat) and on "Raum starten" (network, LAN and relay) and remembered per device. Whoever
runs out of time loses, except against a bare king (then it is a draw).

## Acceptance criteria
- [x] Engine: `ChessTimeControl` (config key `clock`, written only with a clock, e.g. `"900+10"`),
      `ChessClock` (pure, time passed in), moves `timeout`, `clockPause` / `clockResume` / `clockAgree` /
      `clockRefuse` in the move log; result `chess.timeout` (opponent wins) or `chess.timeoutDraw` (the opponent
      has only the king); no board or draw move while paused; the time-out is an undo barrier. Rules version 4,
      compat golden updated.
- [x] Two clock faces next to the captured pieces (above and below the board); the running one highlighted;
      under 10 s red with tenths; screen readers hear name and time.
- [x] With "Zug bestätigen" the clock switches only on "✓ Ziehen".
- [x] Pause: hot-seat at once (pause cover, also when the app goes to the background; "Weiter" goes on);
      network: asked, the other device agrees or refuses (both pausing and going on).
- [x] Network: the host's clock decides. The guest sends its thinking time (`think`) and the host charges it,
      but never less than its own measured time minus a 1 s lag credit. `accepted` / `welcome` carry a
      `clock` snapshot; a reconnect keeps the clock state; while the guest is away both clocks stand still.
      Only the host calls time (`timeout` from a guest is refused). Documented in `PROTOCOL.md`; no
      `protocolVersion` bump (gated by chess rules version 4 in the fingerprint).
- [x] Hot-seat undo puts the clock back to before the undone move; a move after the flag fell (timer not
      run yet) ends on time instead.
- [x] Result text "Zeit abgelaufen bei {player}", history lines, rules page section; 7 locales; zh subset rebuilt.
- [x] Tests: engine (`chess_clock_test.dart`), net (`chess_clock_net_test.dart`), widget
      (`test/ui/games/chess_clock_test.dart`, `chess_clock_network_test.dart`), live UI (hot-seat and network
      games with a short clock that runs out, `chess_live_test.dart`).
- [x] Screenshots `kld126` (de phone and iPad): `test/screenshots/chess_clock_shots_test.dart`.

## Decisions (confirmed by the maintainer 2026-11-12)
- Lag credit 1 s per move over the network.
- Clocks stand still while the guest is disconnected (the guest could think while away).
- Draw on time only against a bare king (other dead positions already end the game as a draw).
- The time-out cannot be undone.
- Also confirmed: the app going to the background pauses the hot-seat clock (pause cover); the clock choice is
  remembered per device.

## Hints / context
`KLUNKI_SHOTS=/tmp/kld126 flutter test test/screenshots --plain-name kld126`.

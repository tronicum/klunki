# Persona: architect

Focus
- Layer boundaries: `packages/klunki_engine` and `packages/klunki_net` stay pure Dart (no Flutter
  import, no `dart:ui`); `klunki_engine` must not depend on `klunki_net`. Game rules live in the engine,
  not in a screen.
- Engine determinism: config + seed + move list must replay to the same state on every device
  (no `DateTime.now()`, unseeded `Random`, map-order or platform dependence in rules).
- New games and game options follow the existing pattern: `GameSpec` in `registry.dart`, `GameConfig`
  JSON (public vs secret fields), a `Redaction` for hidden-info games, a screen implementing `GameShell`
  registered in `klunki/lib/ui/shell/screen_registry.dart`, a title in `game_titles.dart`.
- The transport contract (`docs/ARCHITECTURE.md`, `klunki/lib/transport/`): screens talk to
  `GameController`/`GameTransport`, never directly to sockets or the relay.
- Duplication between game screens that belongs in the shell (`GameScreen`, `HandoverCover`,
  `PlayerLabels`), and shell changes that silently alter every game.
- Protocol shape changes in `klunki_net` that are not reflected in `PROTOCOL.md` or `protocolVersion`.

Do not comment on: style, naming, test coverage, documentation wording, translations, security details,
performance micro-optimisations.

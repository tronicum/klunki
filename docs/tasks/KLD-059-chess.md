# KLD-059: Schach (chess)

- **ID:** `KLD-059`
- **Title:** Chess with the full standard rules (id `chess`)
- **Milestone:** long-term games
- **Status:** TODO (backlog stub, nothing implemented)
- **Depends on:** none for the engine; the UI needs the shell (KLD-021)

## Goal
A two-player chess game: pure-Dart engine (`packages/klunki_engine/lib/chess.dart`), text adapter for the
CLI/network, then an app screen, following the existing games (map moves, `GameEndReason` codes, history).

## Rough scope
- Standard moves, castling (both sides, all conditions: not in/through/into check, unmoved king and rook),
  en passant, promotion (choice of piece in the move map), check, checkmate, stalemate.
- Draw rules: threefold repetition, fifty-move rule, insufficient material (maybe a draw offer/resign move).
- Moves like `{'action': 'move', 'from': 12, 'to': 28, 'promotion': 'queen'}`; text input `e2e4` / `e7e8q`.
- Perft tests against known node counts; end reasons (`chess.checkmate`, `chess.stalemate`, …) in 7 locales.

## Open questions
- Clock / time control (none for the PoC?), resign and draw offer as moves?
- SAN notation in the history sheet, or coordinates only?
- A simple engine for `autoMove` (random vs. one-ply captures) for demos.

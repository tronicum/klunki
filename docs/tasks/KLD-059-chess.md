# KLD-059: Schach (chess)

- **ID:** `KLD-059`
- **Title:** Chess with the full standard rules (id `chess`)
- **Milestone:** long-term games
- **Status:** step 1 DONE (engine, text adapter, tests), step 2 DONE (hot-seat board UI), step 3 DONE (network
  play, draw offer), step 4a DONE (colour choice for network chess); step 4 open, see "Step plan"
- **Depends on:** none for the engine; the UI needs the shell (KLD-021)
- **Touched paths (step 1):**
  - `packages/klunki_engine/lib/chess.dart` (new), `lib/debug/chess_text.dart` (new), `test/chess_test.dart` (new)
  - `packages/klunki_engine/lib/game.dart` (5 `chess.*` `GameEndReason`s), `lib/registry.dart` (`GameSpec` with
    `appReady: false`), `lib/klunki_engine.dart`, `lib/debug.dart`, `lib/debug/debug_console.dart`
  - `packages/klunki_engine/test/{compat,game_contract,result_code}_test.dart` (golden fingerprint, contract entry,
    code prefix)
  - `packages/klunki_net/test/cli_test.dart` (`chess` was the example of an unknown game)
  - `klunki/lib/ui/engine_l10n.dart` (the exhaustive switch needs the new codes; English until step 2)

## Goal
A two-player chess game: pure-Dart engine, text adapter for the CLI/network, then an app screen, following the
existing games (map moves, `GameEndReason` codes, history).

## Step plan
1. **Engine (done).** Full FIDE rules, FEN, SAN, perft-tested; `ChessText` for the debug console and CLI.
2. **Hot-seat board UI (done ✅).** See "Board UI (step 2)" below.
3. **Network play (done ✅).** See "Network play (step 3)" below.
4a. **Colour choice for network chess (done ✅).** See "Colours (step 4a)" below.
4. **Later:** clocks / time control, pause and resume (KLD-079: `fen` + move log), a simple computer opponent,
   take-back requests over the network.

## Design (step 1)
- **Players:** White = `Player.a` (moves first, like every Klunki game), Black = `Player.b`. Since step 4a
  `ChessGame(white: Player.b)` lets B play White (network host on Black); hot-seat stays A = White. A game from a FEN can
  start with Black to move.
- **Squares:** algebraic names `a1`…`h8` in moves (readable in logs, the network protocol and tests; the console
  needs no conversion). `board` and the internal state use index `rank * 8 + file` (`a1` = 0, `h8` = 63);
  `ChessGame.squareIndex` / `squareName` convert.
- **Moves:** `{'action': 'move', 'from': 'e2', 'to': 'e4'}`; a promotion must carry `'promotion': 'q'|'r'|'b'|'n'`
  (lower case), other moves must not. Castling is the king's two-square move (`e1g1`), en passant the pawn's move
  to the empty target square. Resign is the common `{'action': 'resign', 'player': 'a'|'b'}`.
- **Draw rules, all automatic** (no claim moves, so hot-seat and network need nothing extra):
  - stalemate;
  - insufficient material: no pawns, rooks or queens, and at most one minor piece, or only bishops all on one
    square colour (K–K, K+B–K, K+N–K, K+B–K+B same colour); K+N+N–K and K+B–K+N play on;
  - **75-move rule** (FIDE 9.6.2): 150 half-moves without capture or pawn move; a mate on that move still counts.
    There is no claimable 50-move draw;
  - **threefold repetition, automatic** (FIDE: threefold is a claim, fivefold automatic): same pieces, side to
    move, castling rights, and an en passant square only if an en passant capture is actually legal. Counting
    starts with the game (a FEN game knows no earlier positions).
- **End codes:** `chess.checkmate`, `chess.stalemate`, `chess.insufficientMaterial`, `chess.seventyFiveMoves`
  (params `moves`: 75), `chess.threefoldRepetition` (params `times`: 3), plus `common.resigned`.
- **FEN:** `fen` exports, `ChessGame.fromFen` imports (`FormatException` for malformed or impossible positions:
  king count, pawns on rank 1/8, an en passant square without the pawn that just moved, the side not to move in
  check). Castling rights without king/rook at home are dropped; the clock fields may be left out. The en passant
  field is written after every double step (original FEN standard).
- **Registration:** `GameSpec('chess', 'Schach', appReady: false)` and `DebugConsole.games['chess']` (the registry
  test keeps both lists equal). The app menu does not show it; `rulesVersion` 1, golden fingerprint added.

## API (for step 2)
- `ChessGame()`, `ChessGame.fromFen(fen)`, `startFen`, `startPosition`, `fen`
- `board` (64 × `ChessPiece?` with `color` and `type`, `fen` letter), `pieceAt('e4')`
- `currentPlayer`, `isInCheck`, `legalMoves`, `legalMovesFrom('e2')` (move maps), `sanOf(move)`
- `result` / `playResult`, `isOver`, `history` (move maps plus `'san'`), `sanHistory`, `halfmoveClock`,
  `fullmoveNumber`, `perft(depth)`
- `GameEvent.payload`: `from`, `to`, `piece`, `san`, `capture` (piece letter or null), `captureSquare` (differs
  from `to` for en passant), `enPassant`, `castle` (`'kingside'`/`'queenside'`/null), `promotion`, `check`, `mate`.

## Text adapter
`ChessText` (from the repo root: `dart run packages/klunki_engine/bin/klunki.dart chess`; inside
`packages/klunki_engine`, `dart run klunki_engine:klunki chess` works too): board with White in upper case at the bottom; input in long
algebraic (`e2e4`, `e2-e4`, `e7e8q`) or SAN (`Nf3`, `exd5`, `O-O`/`0-0`, `e8=Q`, check marks optional);
players are called White/Black. `autoMove`: a mate in one, else the most valuable capture or a queen promotion,
else a random move. `demo chess` replays a famous short game from 1858 (queenside castling, back-rank mate).

## Tests
`test/chess_test.dart` (68 tests): perft from the start position (depth 1–5, up to 4,865,609), Kiwipete (1–4, up to
4,085,603), positions 3 (1–5), 4 (1–4) and 5 (1–3) of the standard perft suite; piece moves, castling conditions,
en passant (incl. the rank pin), promotion, check, Fool's and Scholar's mate, stalemate, each draw rule, FEN
round-trip and rejects, illegal moves without state change, SAN disambiguation, the text adapter and demo.
The whole file runs in under a second (`dart test`), so no tag is needed.

## Board UI (step 2)
- **Files:** `klunki/lib/ui/games/chess_screen.dart`, `chess/chess_board.dart`, `chess/chess_pieces.dart`;
  `ChessPalette` in `app/theme.dart` (board, pieces, highlights, turn colours, light and dark), menu entry in
  `game_visuals.dart` / `game_illustrations.dart` / `game_titles.dart`, `GameSpec` now `appReady: true`.
- **Pieces:** drawn in code (`ChessPiecePainter`, own Staunton-like paths in a 100 × 100 box, filled and
  outlined, light inner lines on the black pieces), no font glyphs and no image assets. The bundled fonts
  (Roboto, Noto Sans Arabic, the Noto Sans SC / Math subsets) do not cover U+2654–265F, so glyphs would make the
  PWA fetch a fallback font (not allowed) and render as emoji on some platforms. No external piece set needed.
- **Play:** tap an own piece (selection ring), its targets get a dot (quiet move) or a ring (capture, en passant
  included); tap a target to move, anything else to deselect, or drag the piece. Castling is the king's
  two-square step. A pawn reaching the last rank opens the promotion picker (Q/R/B/N in the mover's colour);
  cancel leaves the pawn. Last move tinted, the king in check red plus a "Schach!" badge.
- **Orientation:** hot-seat turns the board to the side to move (like GoStrategy); the auto-turn toggle keeps it
  fixed with White at the bottom, the flip button turns it by 180° on top (state of the screen, not saved). A
  network device would show its own side at the bottom.
- **Shell:** `PlayerLabels.markNames`: chess shows "Weiß" / "Schwarz" instead of X / O in the status pill, the
  result and resign dialogs and the history ("Anna (Weiß)" with names); the player token is the side's king.
  Open information, so no handover cover. The history sheet lists SAN.
- **Move list / captured:** SAN in English letters (`Nf3`, `O-O`), one wrapped list scrolled to the latest move;
  captured pieces per side with the material lead ("+3"). Figurine notation would be possible with the painted
  pieces (open question below).
- **Tests:** `klunki/test/ui/games/chess_screen_test.dart` (selection and targets, capture, castling, en passant,
  promotion choose and cancel, check highlight, Fool's mate, stalemate, resign, flip / auto-turn, drag-and-drop,
  undo, Scholar's mate by taps at phone and tablet size with the board compared to the engine after every move);
  chess added to the menu, resign, l10n coverage / RTL / translation tests; screenshot `chess-<size>-<theme>` in
  `test/screenshots`.

## Network play (step 3)
- **Colours:** in step 3 the host always played White (A), the guest Black (B); step 4a adds the choice (below). Open information, so the plain protocol: no redaction, the guest replays the log.
- **App:** `chess` left `hotSeatOnlyGames`, so the menu tile shows "Mit anderen" (KLD-105), the room flow takes
  it preselected and the room game choice lists it (`networkGameSpecs`). The web beta greys out network play by
  channel, not by game (KLD-108): nothing chess-specific.
- **Board on a network device:** its own side at the bottom (the guest sees the board turned, files h…a and
  ranks 1…8 turned with it), no auto-turn toggle, the flip button stays; no undo and no restart (shell rule for
  network games). Status: "Du bist am Zug" / "Warte auf Anna (Weiß)…" (names, KLD-106); tokens are the kings.
- **Promotion** travels in the move map (`promotion: q|r|b|n`); the host refuses a last-rank pawn move without
  it (or a piece letter on any other move) like any illegal move.
- **Draw offer** (engine moves, rules version 2): `{'action': 'offerDraw'|'acceptDraw'|'declineDraw',
  'player': 'a'|'b'}`. Like a resign they name their player (`ChessGame.playerOf`; the answer comes from the
  player not to move); the host checks them like every move. Only the player to move offers, at most once per
  position (a board move must come between), one open offer at a time; the offer does not pass the turn and
  the offerer cannot move until it is answered. That keeps the network simple: the answer is the only move
  that can follow an offer, so no board move crosses it in flight (a first version let either side offer at
  any time and the offerer move on; the live-UI test caught an answer rejected as a stale index behind the
  offerer's move). Accepting ends the game drawn
  (`chess.drawAgreed`, "Remis vereinbart"). Not in `history` / `sanHistory`, only in the transport log, so
  hot-seat undo and a rejoining guest's replay work unchanged. Chosen over a shell-level message because the
  protocol has no side channel: a move needs no new message type, no protocol bump, and the fingerprint
  (`rulesVersion` 2) refuses a build that does not know the moves.
- **Draw offer UI:** on the own turn the handshake button next to the flip button (`chess-offer-draw`) →
  "Remis anbieten?" ("Ben
  (Schwarz) kann annehmen oder ablehnen …", Abbrechen / Anbieten). The other device gets "Remis-Angebot"
  ("Anna (Weiß) bietet ein Remis an …", Ablehnen / Annehmen); the dialog closes by itself when the offer goes
  away (resign, undo). The offerer's hint line: "Remis angeboten – Ben (Schwarz) entscheidet.", after a decline
  "Ben (Schwarz) lehnt das Remis ab." The history sheet: "Remis angeboten / abgelehnt / angenommen". The pieces wait
  while the own offer is open; an answer that does not get through is asked again. Hot-seat uses the same
  flow: the player to move offers, the dialog asks the other one at once.
- **Text adapter / CLI:** `draw`, `accept`, `decline`; narrated ("Anna (White) offers a draw.").
- **Tests:** engine `chess_test.dart` (draw offer group); net `packages/klunki_net/test/chess_net_test.dart`
  (Fool's mate, both promotions incl. an en passant capture, the 10-move stalemate, draw offer declined and
  accepted, resign with an open offer, over TCP, WebSocket and the relay; rejoin restores an open offer; a
  chess rules 1 guest is refused); app `test/ui/games/chess_network_test.dart` (turned board for Black,
  names, no undo, Fool's mate by taps, draw offer between devices, promotion picker, resign closes the offer
  dialog), hot-seat draw offer tests in `chess_screen_test.dart`, live UI `test/e2e/live_ui/chess_live_test.dart`
  with `chess_adapter.dart` (whole games by taps on two devices through the Wi-Fi proxy, plus hot-seat).
- **Follow-ups:** clocks (step 4); ~~choosing colours~~ (step 4a); a take-back request over the network.

## Colours (step 4a)
- **Choice:** on "Raum starten" (app and relay room screen) chess shows "Deine Farbe" with **Weiß / Schwarz /
  Zufällig** (segmented, kings as icons) and "Weiß beginnt. Bei „Zufällig“ wird ausgelost." Default **Zufällig**:
  fair for two kids, nobody always gets the first move; one constant (`defaultChessColorChoice`) to switch to
  Weiß. Not remembered between rooms (no setting yet). Hot-seat is unchanged: Spieler 1 = Weiß.
- **Engine / protocol:** seats stay as they are (host = A). `GameConfig.chessWhite` (JSON `white: "b"`, only when
  B is White) says who plays White; `ChessGame(white:)`, `whitePlayer`, `colorOf(player)`, `seatOf(color)`,
  `sideToMove`. Pieces carry a `ChessColor` (white/black) instead of a `Player`, so a piece's colour and its
  owner can no longer be mixed up. `currentPlayer`, results, resign and the draw offer stay player-based. The
  host resolves Zufällig before creating the game (`ChessColorChoice.whitePlayer(seed)`: even seed = host
  White) and the config carries the result; no commitment (the colour is public anyway, see PROTOCOL.md).
  Rules version 3 (a rules-2 build would ignore `white` and diverge, so it is refused). CLI:
  `host chess --color white|black|random`.
- **App:** the board's bottom is the own colour (host on Black: turned); "Du spielst Weiß." / "Du spielst
  Schwarz." in the host's waiting room and as the hint line on both devices until the first board move (the
  guest has no waiting room: it joins straight into the game). Tokens follow the colours (`PlayerLabels.tokens`,
  `tokenSidesOf(config)`: the host on Black shows the black king, in the connection bar too); "Weiß"/"Schwarz"
  in the status texts follow `colorOf`; texts stay name-based ("Warte auf Ben (Weiß)…"). 5 new strings in 7
  locales (no new zh glyphs).
- **Tests:** engine `chess_test.dart` group "colours per player" (6 tests: B as White, mate/resign/draw offer by
  player, config JSON, random from the seed, text adapter); net `chess_net_test.dart` (host Black: fool's mate
  by the host and the draw offer both ways over TCP, WebSocket and relay; welcome carries `white`, rejoin keeps
  it; rules 2 refused) and `cli_test.dart` (`--color black`); app `chess_network_test.dart` (host Black:
  boards and coordinates by own colour, "Du spielst …", king tokens, guest opens, host mates; draw offer by the
  guest as White), `pairing_screen_test.dart` (the choice → `chessWhite`, waiting room line, relay hand-over),
  live UI `chess_live_test.dart` one network game with the host on Black. Screenshots:
  `KLUNKI_SHOTS=… flutter test test/screenshots/chess_net_shots_test.dart --plain-name "kld059 colours"`.

## Open questions
- Figurine notation (painted pieces) instead of SAN letters, or localized
  letters (German K D T L S)? Persist the auto-turn / flip choice (no per-game settings yet)?

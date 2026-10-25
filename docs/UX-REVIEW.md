# Klunki: UX review of the user flow

Scope: flow, interaction, feedback, clarity, onboarding, error states, accessibility and consistency. Colours, themes and
branding are out of scope; they come later.
Based on: `klunki/lib/ui/**`, `klunki/lib/game/game_controller.dart`, `klunki/lib/transport/network_transport.dart`,
`klunki/lib/net/**`, the widget tests in `klunki/test/ui/**`, `docs/DEMO.md`, `docs/ROADMAP.md`, `docs/tasks/BOARD.md`,
and the cards KLD-034, KLD-036, KLD-050 and KLD-052. I also checked one simulator screenshot (iPhone, Quartett (Trumpf), X to move).
This is a review only. No code was changed.

Severity: **high** means it breaks fairness or flow, or loses a game. **medium** means it confuses players or slows them down. **low** is polish.
Effort: **S** is ≤ ½ day, **M** is 1–2 days, **L** is more than 2 days.

---

## Executive summary: top 5

1. **Hidden-info integrity in hot-seat has leaks** (high). The app bar stays live above the `HandoverCover`, so
   undo and restart work while the device is being passed. Undo during a Trumpf reveal or after a Schiffe miss lets a player
   take a move back after seeing hidden information. There's no cover at game start, so X's hand or fleet is visible to whoever holds
   the device. And the big "Ich bin O – weiter" button reacts at once, so the passing player can accidentally hit it with a quick double tap.
   *Fix:* no undo in hidden-info games (or an undo only before the handover), a start cover, and a ~600 ms tap guard on the cover button.
2. **Feedback gets lost at the handover** (high). When a move passes the turn, `GameController._onAccepted` raises the cover
   *immediately*. In Schiffe the shooter never sees their own "Wasser". After the last ship (or "Zufällig") the player never
   sees their finished fleet. The next player gets no summary of what the opponent just did (which stat was played and who won the trick,
   which card was asked for). *Fix:* the same pattern Trumpf and Sets already use (show the result, then "Weiter"), plus a one-line
   "Was ist passiert" on the cover.
3. **Network play needs a session model, not just a pairing screen** (high). `GameScreen` always shows "Neues Spiel" and the
   result dialog's "Nochmal". Both call `controller.restart()`, whose default factory is `HotSeatTransport.new`, so a network game would
   silently turn into a local game. `NetworkTransport` itself says restart is unsupported. Before KLD-034 ships we need decisions on
   rematch (both confirm), who picks the next game, a connection indicator, and waiting states.
4. **Rules and identity are invisible** (medium–high). The menu shows bare titles ("Quartett (Trumpf)", "Quartett (Sets)") with no
   description and no rules, anywhere in the app. House rules ("Treffer! Nochmal", 8 cards plus a draw pile, flying with 3 stones)
   are never explained. Players are only "X" and "O", while 4 Gewinnt shows red and yellow and Mühle shows light and dark stones, and nothing on screen
   maps one to the other.
5. **A game is easy to lose** (medium–high). Back (button, swipe or browser back) leaves a running game with no confirmation. Nothing is
   persisted, so an app kill or a PWA reload loses the game. The result dialog can't be dismissed and covers the final board
   (the 4 Gewinnt winning line and the Schiffe end state). The loser never sees the winner's fleet.

---

## Journey 1: app start, menu, choosing a game

### 1.1 No descriptions, no rules
- **Problem:** `menu_screen.dart` shows `ListTile(title: spec.title)`, with a subtitle only for hidden-info games. There's no description,
  no player count, no length, and no rules screen anywhere (there's no "Regeln" in the `GameScreen` app bar either). First-time players can't tell
  "Quartett (Trumpf)" from "Quartett (Sets)".
- **Why it matters:** two of the five games share a name and differ only by a jargon suffix. Couch players decide in seconds.
- **Recommendation:** a 1-line description per game, plus a "Regeln" (?) action in the game's app bar that opens a bottom sheet with
  5–8 bullet points, including the house rules. Suggested copy:
  - 4 Gewinnt: "Vier in einer Reihe – waagerecht, senkrecht oder schräg."
  - Mühle: "Bilde Dreierreihen und schlage gegnerische Steine."
  - Quartett (Trumpf) → **"Quartett: Stechen"**: "Vergleicht Werte – der bessere Wert gewinnt beide Karten."
  - Quartett (Sets) → **"Quartett: Sammeln"**: "Erfrage Karten und sammle vollständige Vierer-Sets."
  - Schiffe versenken: "Versteckt eure Flotten und schießt abwechselnd. Treffer = nochmal."
- **Severity:** high · **Effort:** M (descriptions S, rules sheets M)

### 1.2 The "Gerät weitergeben" subtitle is ambiguous
- **Problem:** hidden-info games show the subtitle "Gerät weitergeben". It reads like an instruction, not like a property of the game.
- **Recommendation:** use an icon (eye-off) plus "Geheime Karten – ihr reicht das Gerät weiter" (Quartett) or "Geheime Flotte – …" (Schiffe).
- **Severity:** low · **Effort:** S

### 1.3 No first-run explanation of X/O and the handover
- **Problem:** nothing tells a new pair that the app calls them X and O, or that the screen will hide itself between turns.
- **Recommendation:** on the first start of any game, a one-time sheet: "Ihr spielt zu zweit an einem Gerät. Spieler 1 ist **X**, Spieler 2 ist **O**.
  Bei geheimen Spielen verdeckt Klunki den Bildschirm – reicht dann das Gerät weiter." Optional (L): player names ("Wer spielt?")
  that replace X/O in every text.
- **Severity:** medium · **Effort:** S (sheet), L (names)

### 1.4 Debug-Konsole placement
- **Problem:** in every non-release build (debug and **profile**, so demo builds too) an `OutlinedButton` "Debug-Konsole" sits directly
  under the game list. Inside the console the texts are English and technical ("Type \"help\" for commands.", tooltip "undo",
  "Neu: connect4").
- **Why it matters:** during the demo it looks unfinished and is one mis-tap away from the game list.
- **Recommendation:** move it into an app-bar overflow menu ("⋮ → Entwickler → Debug-Konsole") or behind a long-press on the "Klunki"
  title. Keep it out of release builds as now. Keeping the console English is fine (it's a developer tool), but use display titles in "Neu: 4 Gewinnt".
- **Severity:** low · **Effort:** S

### 1.5 Entry point for network play (planned)
- **Problem:** KLD-034 adds "Über WLAN spielen" to the menu. On the PWA, the planned flow pushes a screen that only says
  "Netzwerkspiel ist im Browser nicht verfügbar".
- **Recommendation:** structure the menu as *mode first*: two segmented options at the top, "An einem Gerät" / "Über WLAN", then the game list.
  On web, hide the WLAN option or show it disabled with the subtitle "Im Browser nicht verfügbar – nutze die App", so users don't hit a dead end.
- **Severity:** medium · **Effort:** S

---

## Journey 2: hot-seat play (all games)

### Shell (`ui/shell/game_screen.dart`)

#### 2.1 Turn identity is text only and doesn't match the board
- **Problem:** the status line is "X ist am Zug" everywhere. In 4 Gewinnt, X is red and O is yellow (`Connect4Colors.piece`), and nothing on screen
  says so. In Mühle the panels show a stone swatch plus the mark (good), but the status line doesn't.
- **Recommendation:** a shared `PlayerChip` (token or swatch plus mark) in the status line: "● Rot (X) ist am Zug",
  "○ Weiß (X) ist am Zug". Use the same chip in the result dialog and the history.
- **Severity:** medium · **Effort:** S

#### 2.2 Three feedback places with no single rule
- **Problem:** the status line says whose turn it is, the hint line says what to do, and every game invents its own "what just happened" element:
  the Schiffe banner `sv-extra-shot`, the Sets `qs-feedback` panel, the Trumpf `qt-reveal` header, the 1.4 s mill flash in Mühle, and nothing in 4 Gewinnt.
- **Recommendation:** a shell-level **event line or banner** ("Mühle! X darf einen Stein entfernen", "Treffer!", "O gewinnt den Stich") with a
  common position and style, persistent until the next move and announced to screen readers. Games keep their rich reveals inside the board.
- **Severity:** medium · **Effort:** M

#### 2.3 No waiting state when it's not my turn
- **Problem:** when `!canAct` the hint is just `null` in 4 Gewinnt, Mühle and Quartett. Only Schiffe says "Warte auf O …". In hot-seat that's rare,
  but on the network it's the normal case.
- **Recommendation:** the shell sets a default hint when `!canAct && !isOver`: "O ist am Zug – warte auf den Zug …". Games can override it.
- **Severity:** medium (high for network) · **Effort:** S

#### 2.4 Silent no-ops on invalid taps
- **Problem:** a full column in 4 Gewinnt (`_tap`: "full column: no-op"), a tap on an occupied point or a non-movable stone in Mühle,
  an invalid ship anchor in Schiffe (`onPointerUp` ignores it), and `SubmitResult` rejections are ignored by every caller.
- **Recommendation:** a light haptic (`HapticFeedback.selectionClick`) plus a short hint for ~2 s: "Diese Spalte ist voll.",
  "Dieser Stein kann nicht ziehen.", "Hier passt das Schiff nicht – Schiffe dürfen sich nicht berühren."
- **Severity:** medium · **Effort:** S

#### 2.5 Back leaves a running game with no confirmation, and nothing is saved
- **Problem:** there's no `PopScope` in `lib/` (I grepped it). The AppBar back button, the iOS swipe, Android back and the browser back all pop the
  `GameSession`, which disposes the controller. The restart button *does* confirm ("Neues Spiel?"), so leaving is less protected than restarting.
  There's no persistence of seed and moves.
- **Recommendation:** `PopScope` with the dialog "Spiel verlassen? – Der Spielstand geht verloren." [Weiterspielen] [Verlassen]
  (only when moves exist and the game isn't over). Later (M): save `GameConfig` and the move list on every move (`shared_preferences`, or
  `localStorage` on web) and offer "Letztes Spiel fortsetzen" in the menu. `replay()` already exists.
- **Severity:** high · **Effort:** S (confirm), M (resume)

#### 2.6 The result dialog hides the final board
- **Problem:** `_showResult` uses `barrierDismissible: false` with only "Menü" and "Nochmal". Players can't look at the winning four, the
  final mill, or the opponent's fleet.
- **Recommendation:** add a third action, "Ansehen", which closes the dialog and leaves the board visible (read-only). The status line then shows
  "X hat gewonnen" plus an inline "Nochmal" button. In Schiffe, "Ansehen" shows *both* fleets uncovered.
- **Severity:** medium · **Effort:** S

#### 2.7 Rematch: same starter, no score
- **Problem:** "Nochmal" calls `restart(seed: newGameSeed())`. Every engine starts with X (`Player.a`), so the same person always begins, and
  there's no running score.
- **Recommendation:** alternate the starting player on "Nochmal" (via config or a swap of the mark display), and show a session score
  in the dialog: "X 2 : 1 O". Copy: "Nochmal – diesmal beginnt O".
- **Severity:** medium · **Effort:** M (needs an engine/config contract for the starting player)

#### 2.8 App-bar actions: reach and confusability
- **Problem:** undo, restart (`Icons.refresh`) and history (`Icons.history`) sit side by side in the top right. In the screenshot, refresh and
  history look almost identical. They're the hardest spot to reach one-handed, and the primary in-game buttons ("Weiter" in Trumpf and Sets)
  also sit at the top of the board.
- **Recommendation:** keep undo in the bar, and move "Neues Spiel", "Züge" and "Regeln" into an overflow menu (⋮). Pin the primary per-turn button
  ("Weiter") to a bottom action area inside `SafeArea`.
- **Severity:** medium · **Effort:** S–M

#### 2.9 Inconsistent win wording
- **Problem:** the dialog says "X gewinnt!", the status line says "X hat gewonnen", the Trumpf reveal says "X gewinnt den Stich", and the Trumpf side label is "X – gewinnt".
- **Recommendation:** dialog headline "X gewinnt!" (keep it). The status line after the end is "Spiel vorbei – X hat gewonnen". Trumpf side labels
  become "X: Stich" / "O: kein Stich" / "Gleichstand", so the words don't compete with the game result.
- **Severity:** low · **Effort:** S

### 4 Gewinnt (`connect4/connect4_board.dart`)

#### 2.10 Color-only player identity, weak semantics
- **Problem:** pieces differ only by red and yellow. The column semantics are just `'Spalte ${c + 1}'`, with no fill level or content. The hint
  "Tippe auf eine Spalte" repeats on every turn.
- **Recommendation:** an optional subtle mark inside the pieces (X/O, or ring vs. solid) for color-blind players. Semantics: "Spalte 4, 3 von 6 belegt,
  oben Rot". Show the hint only for the first 2 moves.
- **Severity:** medium · **Effort:** S
- (Keep: hover/press column highlight, the drop animation, white ring plus fading on the winning line, which isn't color-only.)

### Mühle (`muehle/muehle_board.dart`, `muehle_screen.dart`)

#### 2.11 The point numbers mean nothing to players
- **Problem:** the history says "setzt auf 5", "zieht 15→16", and semantics say "Punkt 5, leer". Points 0–23 are internal indices and
  aren't shown on the board.
- **Recommendation:** use the usual board coordinates (a1–g7) in history and semantics, with optional small edge labels on the board (like the Schiffe A–J / 1–10 grid).
- **Severity:** medium · **Effort:** S–M

#### 2.12 Phase changes aren't announced
- **Problem:** the switch from Setzen to Ziehen to Springen shows only in the small panel label `muehle-phase-X`. The mill flash pulses 3× in 1.4 s and is the only
  mill signal besides the hint.
- **Recommendation:** an event line (see 2.2) on change: "Alle Steine gesetzt – jetzt wird gezogen.", "X hat nur noch 3 Steine und darf springen."
  Respect `MediaQuery.disableAnimations` for the flash (show a static highlight instead).
- **Severity:** low · **Effort:** S

#### 2.13 Hint copy is too long
- **Problem:** "Wähle ein Ziel (oder tippe den Stein erneut zum Abwählen)".
- **Recommendation:** "Wähle ein Ziel – erneut tippen hebt die Auswahl auf." Movable stones get a ring that isn't just color (a dashed ring or a small dot),
  because the current green ring is color-only.
- **Severity:** low · **Effort:** S

---

## Journey 3: hidden-information games (Quartett ×2, Schiffe)

### 3.1 Undo and restart stay live during the cover and the reveal (exploit)
- **Problem:** the app bar is outside `HandoverCover`, and `shell-undo` is shown for every `HotSeatTransport`. Cases:
  - Schiffe: X fires, misses, the cover appears, and X taps undo. The miss is gone and X shoots again elsewhere.
  - Trumpf: while the reveal (`qt-reveal`) shows O's card, the picker can tap undo. The reveal is dropped and the previous trick is undone,
    with the picker now knowing O's next card.
  - Sets: on a miss the drawn card is shown before submit. Undo drops the pending ask and lets the player re-ask.
  - The cover itself: whoever holds the device can undo the opponent's last move before passing it.
- **Why it matters:** fairness is the whole point of the handover cover.
- **Recommendation:** hide undo for `spec.hiddenInformation` games. Alternatively, allow "Zug zurück" only for the *own* last move and only *before*
  the handover was acknowledged and no hidden info was revealed. Disable undo, restart and back while a reveal or the cover is shown
  (expose `GameShell.setBusy(true)` to boards).
- **Severity:** high · **Effort:** S

### 3.2 No cover at game start
- **Problem:** `needsHandover` is only set after a move, so a new or restarted Quartett or Schiffe game shows X's hand or setup grid at once to whoever holds
  the device, typically right after "Nochmal" while both players are looking.
- **Recommendation:** start hidden-info games covered: "X beginnt. Gib das Gerät an X." [Ich bin X – los geht's]. The same applies after "Nochmal".
- **Severity:** high · **Effort:** S

### 3.3 The cover button can be hit by the passing player
- **Problem:** the cover appears in the same frame as the move. "Ich bin O – weiter" is a 240×72 button in the centre, right where
  the Schiffe target grid or the Sets slots were. A double tap or a quick second tap reveals O's screen to X.
- **Recommendation:** ignore taps for ~600 ms after the cover appears (fade the button in), or use press-and-hold ("Halten zum Aufdecken").
  Wording stays: "Gib das Gerät an O weiter" / "Ich bin O – weiter" is clear and friendly.
- **Severity:** high · **Effort:** S

### 3.4 Schiffe: the shooter never sees their miss
- **Problem:** `_onAccepted` sets `needsHandover` as soon as `currentPlayer` changes. A miss passes the turn, so the cover appears before the "Wasser" dot
  is drawn. X learns the result only from the history or next turn.
- **Recommendation:** do it like Sets: compute the shot on a replay copy, show "Wasser bei E5." plus the dot for the shooter, then [Weiter – Gerät an O].
  Hits keep the instant "Treffer! Nochmal" flow.
- **Severity:** high · **Effort:** M

### 3.5 Schiffe setup: the fleet is never reviewed
- **Problem:** the fleet is 6 ships on a 10×10 grid (`SchiffeGame.defaultFleet` = 5, 4, 3, 3, 2, 2; ships may not touch; a hit earns another shot), so setup is 12 placements per game for the pair,
  and "Zufällig" will be the common path. Placing the 6th ship, or "Zufällig" (which places *all* remaining ships), passes the turn and raises the cover at once. The "Flotte komplett"
  title (`sv-next-ship`) is effectively never seen. "Zufällig" can't be re-rolled.
- **Recommendation:** after the last ship, a review state: "Flotte komplett" with [Neu würfeln] [Zurücksetzen] [Fertig – Gerät an O].
  Rename the button to **"Zufällig aufstellen"**.
- **Severity:** high · **Effort:** M (needs the move to be pending until "Fertig", or a setup-confirm move in the engine)

### 3.6 The next player doesn't learn what happened
- **Problem:** after the cover, O sees only "O ist am Zug". In Trumpf, O never sees the trick that just decided the cards. In Sets, the ask
  ("X fragt nach B3") is public in the real game and key for memory, but O isn't shown it (the history has it, buried). Schiffe does it well
  with `sv-incoming` ("O schoss zuletzt auf E5: Wasser").
- **Recommendation:** a public one-liner on the cover, under the headline:
  - Trumpf: "X spielte Leistung – X gewinnt den Stich." (a *public* fact: both cards are revealed at the table anyway)
  - Sets: "X fragte nach B3 – du hattest sie nicht." / "X bekam B3 von dir."
  - Schiffe: "X schoss auf E5: Wasser."
  Never include private info (the drawn card, the hand contents).
- **Severity:** medium · **Effort:** S

### 3.7 Trumpf: rules of comparison only in a tooltip, one-tap commit
- **Problem:** ↑/↓ per stat explain "höher gewinnt / niedriger gewinnt" only in a `Tooltip` (long press, so nobody finds it). A tap on a stat row
  commits at once (the reveal shows the opponent card, so it can't be revised). The rows are 44 px and close together.
- **Recommendation:** a legend under the card: "↑ höher gewinnt · ↓ niedriger gewinnt". Optionally a two-step select: tap highlights
  the row (set color, `highlightStat`), a bottom button reads "Mit Leistung stechen". The hint during the reveal: "Tippe auf „Weiter“."
- **Severity:** medium · **Effort:** S (legend), M (two-step)

### 3.8 Sets: discoverability and terms
- **Problem:** tapping your own card opens the full card, which isn't discoverable. `'$have/4 – fehlt: ${4 - have}'` is redundant. "Stapel" means the *draw
  pile* here but the *opponent's stack* in Trumpf ("Stapel von O"). The mode name "Sets" is English.
- **Recommendation:** "3/4" alone. Trumpf uses "Karten von O", Sets uses "Nachziehstapel". The mode is named "Sammeln" (see 1.1). A small "Antippen für Details" hint the first time.
- **Severity:** low · **Effort:** S
- (Keep: the missing slots with "fragen" / "fehlt" text (not color-only), the drawn card shown only to the asker, "Fehlanzeige", the board rendering
  nothing at all while covered, and the history never naming the drawn card.)

### 3.9 Schiffe battle: small targets, mixed terms
- **Problem:** on a phone in portrait the 10×10 target grid gets `flex: 3`, about 32–35 pt per cell, below the 44 pt guideline. A wrong tap is
  final. The terms vary: section "Gegner", hint "Gegner-Meer", semantics "Fehlschuss" vs. history "Wasser", and the standalone label "versenkt".
  The rotate button shows the *state* ("Horizontal") instead of the action. The hint "Treffer! Nochmal – …" assumes the house rule is known.
- **Recommendation:** in battle, collapse "Dein Meer" to a mini-map (tap to enlarge) so the target grid can use the full width (~38–40 pt). An optional
  aim-then-fire: first tap marks a cell, second tap or "Feuer!" shoots. Terms: "Meer von O" / "Dein Meer", "Wasser", "Treffer", "versenkt". The rotate
  button becomes "Drehen (waagerecht)" / "Drehen (senkrecht)". The rule goes into the rules sheet: "Wer trifft, darf nochmal schießen."
  Placement preview valid/invalid is green/red only: add an outline style or an ✕ for invalid.
- **Severity:** medium · **Effort:** M

---

## Journey 4: network play (planned, KLD-034 / 036 / 050 / 052)

### 4.1 Shell actions assume hot-seat
- **Problem:** `GameScreen` always shows `shell-restart`, and the result dialog always offers "Nochmal". Both call `controller.restart()`. The
  default `_transportFactory` is `HotSeatTransport.new`, so a network game would silently become a local game on one device. `NetworkTransport`'s doc says
  restart isn't supported.
- **Recommendation:** for non-hot-seat games, hide "Neues Spiel" and replace "Nochmal" with **"Revanche anbieten"**. The other side gets
  "X möchte eine Revanche" [Annehmen] [Ablehnen]. The host creates a new seed and starts. Until that exists, show just "Menü".
- **Severity:** high · **Effort:** S (hide), M–L (rematch protocol in `klunki_net`)

### 4.2 Who picks the game, and what happens after a game
- **Problem:** KLD-034 has the host choose the game *before* advertising. To play something else, both have to go back and re-pair.
- **Recommendation:** pair once and get a **lobby**: both devices show "Verbunden mit Stefans iPad". The host picks the game (the guest sees "Stefan wählt ein Spiel …"),
  and after a game both return to the lobby. That also gives rematch a home. KLD-034 can still ship host-picks-first, but the
  join list should always show the game title (TXT `game`) so the guest knows what they're joining: "Stefans iPhone – Mühle".
- **Severity:** medium · **Effort:** L

### 4.3 Host waiting screen
- **Problem:** the plan is to show "every candidate IP with port" plus the QR. Several IPs (cellular, VPN, link-local) confuse people. The default port 4747 adds noise.
- **Recommendation:** show one primary address (the Wi-Fi interface), with the others behind "Andere Adressen". Hide `:4747` when it's the default.
  Copy: "Warte auf Mitspieler … · Auf dem anderen Gerät: Über WLAN spielen → Beitreten". Use a spinner, not a static text, and keep [Abbrechen] at the bottom.
- **Severity:** medium · **Effort:** S

### 4.4 The QR is shown but can't be used yet
- **Problem:** `JoinQrCode` encodes `klunki://join?...`. Scanning comes only with KLD-052, and no `klunki://` deep link is registered, so the system
  camera app does nothing useful with it. Users will try.
- **Recommendation:** until KLD-052, either hide the QR or label it "QR-Scan folgt bald – gib die Adresse ein". Alternatively register the URL scheme
  so the system camera opens Klunki (one config change per platform, needs the user's OK).
- **Severity:** medium · **Effort:** S

### 4.5 Join list: empty, failure and permission states
- **Problem:** the card defines the list, manual entry and a 10 s timeout with hints. It doesn't cover the empty state while browsing, stale entries, or the
  common iOS case where local-network permission was denied (browse then just returns nothing).
- **Recommendation:**
  - Empty, 0–5 s: spinner plus "Suche nach Spielen im WLAN …".
  - Empty after 5 s: "Kein Spiel gefunden. Ist das andere Gerät im selben WLAN und zeigt „Warte auf Mitspieler“?" Then auto-focus the manual field.
  - iOS: "Klunki braucht Zugriff auf das lokale Netzwerk – Einstellungen › Klunki › Lokales Netzwerk." with a button that opens Settings.
  - Manual-entry error: "Das sieht nicht nach einer Adresse aus. Beispiel: 192.168.1.20".
  - Protocol mismatch: "Die Klunki-Versionen passen nicht zusammen – bitte beide Apps aktualisieren."
- **Severity:** medium · **Effort:** S–M

### 4.6 Identity and connection status in game
- **Problem:** the planned "Du bist X/O" in the status line is good, but there's no persistent connection indicator, and the status line still reads "O ist am Zug"
  from the guest's point of view.
- **Recommendation:** status from each device's own perspective: "Du bist am Zug (X)" / "Stefan (O) ist am Zug …". A small connection dot in the app bar
  (green when connected, amber while reconnecting) that opens "Verbunden mit Stefans iPad · 192.168.1.20".
- **Severity:** medium · **Effort:** S

### 4.7 Disconnect and leave (KLD-036)
- **Problem:** the card specifies a guest-side overlay "Verbindung verloren – verbinde neu… (n)" and a dialog for `bye`. It doesn't specify what the
  **host** sees while the guest is gone (`peerMissing`), how intentional leaving is confirmed, or what happens when the host backgrounds (iOS kills the host socket,
  and the game is gone).
- **Recommendation:**
  - Host overlay: "O ist nicht mehr verbunden – warte auf Wiederverbindung …" [Spiel beenden].
  - Leaving: "Spiel verlassen? O wird benachrichtigt." [Bleiben] [Verlassen].
  - Received `bye`: "O hat das Spiel verlassen." [Zum Menü] [Neues Spiel hosten].
  - The guest overlay shows the attempt counter only after 3 s (short blips shouldn't flash an overlay).
  - Tip on the pairing screen: "Lasst Klunki auf beiden Geräten geöffnet." A keep-screen-awake option needs a package, so it needs the user's OK.
  - Replay mismatch, "Spielstand passt nicht zusammen": add the next step: "Startet ein neues Spiel."
- **Severity:** medium · **Effort:** M

### 4.8 Moves while disconnected
- **Problem:** the card leaves it open whether moves are rejected or queued, and today rejections (`RejectReason.disconnected`) are ignored by all boards.
- **Recommendation:** block input with the overlay (already planned) and never queue. If a submit is rejected anyway, show
  "Zug nicht gesendet – keine Verbindung." The Trumpf and Sets "Weiter" (pending moves) must keep the reveal until the submit is accepted.
- **Severity:** medium · **Effort:** S

---

## Journey 5: cross-cutting

### 5.1 Terms and copy (German)
| Now | Where | Proposal |
|---|---|---|
| "Gerät weitergeben" | menu subtitle | "Geheime Karten/Flotte – Gerät wird weitergereicht" |
| "Quartett (Trumpf)" / "Quartett (Sets)" | registry titles | "Quartett: Stechen" / "Quartett: Sammeln" |
| "Horizontal" / "Vertikal" | `sv-rotate` | "Drehen (waagerecht/senkrecht)" |
| "Zufällig" | `sv-random` | "Zufällig aufstellen" |
| "Gegner" / "Gegner-Meer" | Schiffe sections and hint | "Meer von O" everywhere |
| "Fehlschuss" (semantics) vs "Wasser" | `_lookLabel` | "Wasser" |
| "Stapel von O" vs "Stapel" (draw pile) | Trumpf vs Sets | "Karten von O" / "Nachziehstapel" |
| "X hat gewonnen" vs "X gewinnt!" | status vs dialog | see 2.9 |
| "Wähle ein Ziel (oder tippe den Stein erneut zum Abwählen)" | Mühle hint | "Wähle ein Ziel – erneut tippen hebt die Auswahl auf." |
| "Aufstellung: tippe aufs Meer (oder ziehe und lass los), um das Schiff zu setzen. Schiffe dürfen sich nicht berühren." | Schiffe hint (2 lines) | "Tippe oder ziehe, um das Schiff zu setzen. Schiffe dürfen sich nicht berühren." |
| "Type \"help\" for commands." | Debug-Konsole | fine for a dev tool, or "Tippe „help“ für Befehle." |

The tone ("du", short imperatives, "Fehlanzeige", "Ich bin O – weiter") is good and consistent. Keep it.

### 5.2 Accessibility
- **Problem:** status and hint aren't live regions, so screen-reader users miss turn changes and results. Several color-only signals: 4 Gewinnt pieces,
  Mühle movable ring, Schiffe preview valid/invalid. No reduced-motion handling (the 4 Gewinnt drop, the Mühle mill flash at about 2 Hz). Schiffe target
  cells are under 44 pt (3.9). Only 4 `Semantics`/`MediaQuery` uses in `lib/ui`.
- **Recommendation:** `Semantics(liveRegion: true)` on `shell-status` and `shell-hint`, or `SemanticsService.announce` for event lines. Check
  `MediaQuery.disableAnimationsOf(context)` to skip the drop and the flash. Add shape cues as listed above. Add semantic values with state ("E5, Treffer").
  Test with large text: the Muehle panels (`TextOverflow.ellipsis`) and the Trumpf reveal side by side at 1.3× need a check.
- **Severity:** medium · **Effort:** M

### 5.3 One-handed and tablet
- Phone: the primary actions ("Weiter", "Zufällig", "Drehen") belong in a bottom area. The top app bar is for rare actions (2.8).
- Tablet in hot-seat usually lies flat between two players: an optional "Ansicht für O drehen" (rotate 180° on O's turn) for 4 Gewinnt and Mühle is a nice
  couch feature (low, M). The layouts already adapt (Schiffe ≥ 600, Trumpf/Sets ≥ 520, Mühle wide panels), which is good.

### 5.4 PWA specifics
- Browser back and reload lose the game (2.5). Persistence matters most here.
- Network: hide the entry point (1.5).
- Keyboard: the 4 Gewinnt columns could take keys 1–7, which is cheap and nice on desktop Chrome (low, S).

### 5.5 Feedback channels
- No haptics or sound anywhere. A `HapticFeedback.lightImpact` on a move and a `mediumImpact` on mill, hit, quartet or win adds a lot of feel for zero visual work (low, S).

---

## Quick wins (≤ 1 hour each)

1. Hide `shell-undo` for `spec.hiddenInformation` games (3.1).
2. A ~600 ms tap guard on `handover-continue` (3.3).
3. Hide "Neues Spiel" and "Nochmal" when the transport isn't `HotSeatTransport` (4.1), before KLD-034 merges.
4. `PopScope` leave confirmation for running games (2.5).
5. "Ansehen" button in the result dialog (2.6).
6. A default waiting hint in the shell: "O ist am Zug – warte …" (2.3).
7. Trumpf legend "↑ höher gewinnt · ↓ niedriger gewinnt" plus the reveal hint "Tippe auf „Weiter“." (3.7).
8. Copy fixes from table 5.1 (rotate, Zufällig aufstellen, Wasser, Meer von O, hint lengths).
9. `liveRegion` on status and hint (5.2).
10. Haptics on moves and big events (5.5); haptic plus a hint on invalid taps (2.4).
11. Move the Debug-Konsole into an overflow menu (1.4).
12. A start cover for hidden-info games (3.2), if the controller just sets `_needsHandover = true` on create/restart.

---

## Already good: keep these

- `HandoverCover` keeps the board mounted but `Offstage` + `ExcludeSemantics` + `TickerMode`. Sets renders *no cards at all* while covered.
- The cover wording: "Gib das Gerät an O weiter" / "Ich bin O – weiter". It's clear, friendly, with a big target.
- Trumpf and Sets compute the reveal on a **replay copy** and submit only on "Weiter", which is exactly the right pattern (reuse it for Schiffe).
- Move histories never leak hidden info ("wählt Leistung", "fragt nach B3: Fehlanzeige", "platziert ein Schiff").
- Restart asks for confirmation only when a game is in progress.
- 4 Gewinnt: press/hover column highlight, last-move dot, winning ring plus fade of the others.
- Mühle: phase-aware hints, removable stones marked with ✕ (not color-only), target dots, player panels with hand/board/captured counts, a wide layout.
- Schiffe: drag-to-preview placement, the A–J/1–10 grid, the "O schoss zuletzt auf E5: Wasser" incoming line, the remaining-ships counter.
- Sets: four-slot set groups with "fragen"/"fehlt" text, the drawn card only for the asker, the public score chip.
- German number formatting (`2,7 s`) and singular/plural ("1 Karte").
- The join payload accepts `IP`, `IP:port` or `klunki://…`. The QR is always dark-on-white, with a semantics label and a selectable address.
- KLD-034's timeout error with concrete hints (same Wi-Fi, guest network, iOS permission).
- Stable widget keys and widget tests that assert the real copy, which makes UX changes safe to refactor.

---

## Proposed task cards (suggestions)

- **UX-01: Lock down hidden-info hot-seat.** No undo in hidden-info games, undo/restart/back disabled during reveal or cover, a 600 ms cover tap guard.
- **UX-02: Start cover.** Hidden-info games (and "Nochmal") begin with "X beginnt – Ich bin X".
- **UX-03: Schiffe miss reveal.** Show "Wasser bei E5" to the shooter before the handover (replay-copy pattern, like Trumpf and Sets).
- **UX-04: Schiffe fleet review.** After the last ship or "Zufällig aufstellen": [Neu würfeln] [Zurücksetzen] [Fertig].
- **UX-05: Handover summary line.** A public "was ist passiert" sentence on the cover for Trumpf, Sets and Schiffe.
- **UX-06: Network-safe shell.** Hide restart/Nochmal for network transports, add a default waiting hint, status from your own point of view ("Du bist am Zug").
- **UX-07: Rematch and lobby over WLAN.** "Revanche anbieten" with accept/decline, back to the lobby after a game, host picks the game. Needs a `klunki_net` message.
- **UX-08: Pairing states.** Browse empty states, iOS permission hint plus a Settings button, one primary IP, a QR label until KLD-052, version mismatch copy.
- **UX-09: Host-side disconnect UX.** "O ist nicht mehr verbunden" overlay, leave confirmation, "Neues Spiel hosten" after `bye` (extends KLD-036).
- **UX-10: Menu descriptions plus a rules sheet.** One-liners, new Quartett mode names, a "Regeln" sheet per game including the house rules.
- **UX-11: PlayerChip.** A shared token plus mark ("● Rot (X)") in status, dialog and history; optional player names later.
- **UX-12: Leave guard plus resume.** `PopScope` confirmation now; persist config and moves and offer "Letztes Spiel fortsetzen".
- **UX-13: Result dialog "Ansehen"** plus both Schiffe fleets uncovered at the end, a session score, and alternating starter on "Nochmal".
- **UX-14: Shell event line.** One standard place and style for "what just happened", announced to screen readers.
- **UX-15: Invalid-tap feedback plus haptics.** Short hints ("Diese Spalte ist voll.") and light or medium haptics.
- **UX-16: Accessibility pass.** Live regions, reduced motion, non-color cues (4 Gewinnt pieces, Mühle movable, Schiffe preview), large-text check.
- **UX-17: Mühle coordinates.** a1–g7 in history and semantics, optional edge labels.
- **UX-18: Schiffe battle ergonomics.** Mini-map own grid on phones, optional aim-then-fire, unified terms.
- **UX-19: Bottom action area.** Move the per-turn primary buttons ("Weiter", setup buttons) to a thumb-reachable bottom bar, and put rare actions in the overflow.
- **UX-20: Debug-Konsole out of the menu list** (overflow or long-press), with display titles in its game menu.

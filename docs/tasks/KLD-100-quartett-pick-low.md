# KLD-100 — Quartett (Trumpf): with 3 or fewer cards you choose

- **ID:** `KLD-100`
- **Title:** House rule "with 3 or fewer cards you choose which card to play" (Trumpf), on by default
- **Status:** DONE
- **Depends on:** KLD-086 (network reveal flow), KLD-089 (live UI harness), KLD-091/092 (cue, cover reason, wording)
- **Touched paths:**
  - `packages/klunki_engine/lib/{quartett,quartett_view,registry}.dart`, `packages/klunki_engine/lib/debug/quartett_text.dart`
  - `packages/klunki_engine/test/{quartett_pick_low_test,secrecy_test,compat_test}.dart`
  - `packages/klunki_net/lib/src/{guest.dart,secrecy/secrecy.dart}`, `packages/klunki_net/test/{secrecy_test,compat_test}.dart`
  - `klunki/lib/ui/games/quartett_trumpf_screen.dart`, `klunki/lib/l10n/**` (4 new keys, all 7 locales)
  - `klunki/test/ui/games/{quartett_pick_low_test,quartett_trumpf_screen_test,quartett_trumpf_network_test}.dart`
  - `klunki/test/e2e/live_ui/**`, `klunki/test/screenshots/screenshots_test.dart`

## Why

Playtest feedback from the user's son: at the end of a game, with only a few
cards left, playing blindly from the top is no fun. House rule: a player with
3 or fewer cards sees them and chooses which one to play.

## Rules (agreed with the user)

- Applies to any player whose stack (pot excluded) holds 2 or 3 cards
  (`QuartettGame.pickLowLimit` = 3). A single last card has nothing to choose
  from and plays like a top card (no extra tap, no extra hot-seat handover).
  With more than 3 cards again: top card again.
- One round: the picker, if low, first chooses a card (`{'action': 'choose',
  'card': id}`, the turn stays), then announces the stat (`pick`). If the
  defender is low, the pick only announces the stat (`announcedStat`;
  `currentPlayer` is the defender, `picker` stays the picker) and the
  defender chooses its card knowing the stat (`choose`). Then the comparison
  as before.
- Tie-break (Stechen) and pot unchanged; the chosen card leaves the stack
  exactly like the top card would, the rest keeps its order.
- Toggle `GameConfig.pickLowCards`, **on by default**; JSON key `pickLow`,
  written only when off (`publicJson` too, so host and guest agree). A bare
  `QuartettGame(...)` keeps the classic rules (`pickLowCards: false`).
- **Rules version:** `quartett-trumpf` `rulesVersion` 1 → 2 (KLD-085
  fingerprint), so old builds refuse to play new ones. Sets unchanged.

## Hidden information

- View (`viewJson`): a low viewer gets its whole stack (`hand`) and its own
  choice (`chosen`); `announced` (stat) is public; `current` is the player to
  act. The opponent's hand and choice never appear.
- `QuartettRedaction.redactMove`: the opponent sees `{'action': 'choose'}`
  without the card; a host's choice is therefore committed and revealed at
  the end (existing KLD-064 mechanism). The card only becomes visible in the
  trick payload (the reveal). `verifyRedactedGame` takes `pickLowCards`.
- Trick payload: `picker` (when the defender's choice completed the round)
  and `chosen` (who chose); the picker's own `choose` returns `{'chose': true}`,
  an announcing pick `{'stat', 'announced': true}`.

## UI

- Choose view (`qt-choose`, cards `qt-choose-<id>`, hint `qt-choose-hint`):
  the 2–3 own cards face-up side by side (two per row below 3×190 px), tap to
  choose. Picker: "Du hast nur noch 3 Karten – wähle eine aus." Defender:
  "Anna (X) spielt Höchstgeschwindigkeit. Wähle deine Karte.", the stat
  highlighted on every card.
- Hot-seat: the picker's choice is submitted at once; a pick with a low
  defender is submitted at once (nothing to preview) and the handover cover
  names the stat; the defender's choice is previewed like a pick (reveal,
  "Weiter"). A tie completed by the defender's choice gives a cover "X wählt
  noch einmal".
- Network: the waiting picker sees "Ben (O) wählt eine Karte …"; the round
  is revealed from the event on both devices. History: "wählt eine Karte".
- New keys: `quartettTrumpfChooseOwn`, `quartettTrumpfChooseDefend`,
  `quartettTrumpfMoveChoose`, `quartettTrumpfHintDefending`.

## Tests

- Engine `quartett_pick_low_test.dart`: rule off unchanged, config/JSON,
  rules version, picker chooses, defender chooses after the stat, both low
  with a tie, back above 3, single last card, illegal choices, random full
  games, replay, resign mid-choice, redaction (no leak, views round-trip),
  text game (render/parse/narrate/autoMove).
- Net: full Trumpf game over the network with choices, the host's choices
  redacted and committed, guest view checked after every move.
- App: `quartett_pick_low_test.dart` (hot-seat picker/defender with cover,
  phone width, rule off, network device as defender/picker); live UI adapter
  taps choices (counters asserted), driver counts rounds instead of moves and
  compares the guest's log redacted.
- Screenshots: `KLUNKI_SHOTS=<dir> flutter test test/screenshots --name kld100`.

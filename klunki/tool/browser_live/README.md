# Live UI tests in a real browser (KLD-089)

Plays complete games of the PWA the way a user does: real headless Firefox,
real taps, the real relay. For now Quartett (Trumpf); adapters for the other
games are KLD-090.

- **Hot-seat**: one browser. Menu → Quartett (Trumpf) → deck → Spielen, then
  pick stats, "Weiter", acknowledge the handover cover, to the result dialog.
- **Network**: two browsers. A taps "Raum starten" and opens a Quartett
  (Trumpf) room through the relay, B taps "Raum beitreten" and types the
  room code. Both play to the end; the waiting browser sometimes
  taps "Weiter" and sometimes lets the 5 s grace run out, so tricks queue up.

Every trick each browser shows is logged (`tricks.log`). The run fails if:

- a picker is not the previous trick's winner (or the same player after a tie),
- a reveal is not the stat and card that was just tapped,
- the table shows the wrong player's card, or the hot-seat cover names the
  wrong player,
- (KLD-091) the cue ("O wählt als Nächstes" / "X wählt noch einmal") or the
  button ("Weiter – O wählt") names the wrong player, a hot-seat cover
  appears although the same player goes on (or is missing on a switch) or
  gives the wrong reason, or on a network device the status line and the
  "noch n Runden" badge do not follow a reveal with tricks queued behind it,
- (KLD-092) the hot-seat status line under a result does not read like the
  cue ("O wählt als Nächstes" / "X wählt noch einmal"),
- the two network browsers did not show the same tricks in the same order
  (a skipped, duplicated or reordered trick),
- no result dialog at the end.

## Run

Needs Node >= 22, Firefox (any of the usual install paths, or
`KLUNKI_FIREFOX=/path/to/firefox`, or `--browser PATH`), Flutter/Dart for the
build and the relay. Nothing is installed: Firefox is driven over WebDriver
BiDi, which is built in.

```sh
klunki/tool/browser_live/run.sh --build                      # build web, hot-seat + network
klunki/tool/browser_live/run.sh --mode network --deck Raketen --seed 7
klunki/tool/browser_live/run.sh --port 8776 --out /tmp/bl    # other port / output dir
```

`run.sh` starts `dart run klunki_net:klunki relay --port 8775 --web build/web`
and stops it at the end. To drive a relay you already run:

```sh
node klunki/tool/browser_live/live.mjs --url http://127.0.0.1:8775/ --mode both
```

Options of `live.mjs`: `--mode hotseat|network|both`, `--deck Autos|Züge|Raketen|Flugzeuge`,
`--seed N` (the random stat choices), `--width/--height` (default 412×1400:
a phone width, tall enough that nothing needs scrolling), `--max-steps`,
`--verbose`, `--out DIR`.

Output in `--out` (default `./browser-live`): `tricks.log` (every tap and
every trick each browser showed, with its status line, grace countdown and
queued notice), `report.json`, screenshots at the start and the end.

## How it reads the screen

Flutter web draws on a canvas. The driver turns on Flutter's accessibility
tree (the hidden "Enable accessibility" placeholder, what a screen reader
does) and reads the semantics labels from the DOM (`flt-semantics`): "X wählt
Leistung", "X gewinnt die Runde", the card ids ("B3") under "X – gewinnt" /
"O – verliert", "Deine Karte (X)", the stat buttons, "Ich bin O – weiter".
Taps are real pointer events at a node's centre. The app has no test hooks
for this; the labels are the German UI texts (the driver sets the locale).

## Files

- `browser.mjs`: generic Firefox/BiDi driver (start, load PWA, semantics
  nodes, tap, type, start a room, join by code).
- `live.mjs`: generic game loop (hot-seat and network), logs, checks, report.
- `quartett_trumpf.mjs`: the Quartett (Trumpf) adapter (read the screen,
  choose a stat, the turn rule).

The Flutter-side twin with the same split (driver + per-game adapter) is
`klunki/test/e2e/live_ui/` (`flutter test test/e2e/live_ui`).

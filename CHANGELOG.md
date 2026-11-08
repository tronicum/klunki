# Changelog

What changed in each Klunki release, in plain words. Newest first. Versions are `MAJOR.MINOR.PATCH`
(new games or game variants raise PATCH; design tweaks and small fixes only get a new build number;
MINOR/MAJOR for bigger milestones; see `docs/RELEASING.md`). Each release has a
short German summary ("Kurz") for the store notes and the testers.

## [Unreleased]

### Games
- **New game: Ausgewürfelt** (KLD-119), the five-dice score-sheet game for **2 to 4 players on one device**, the
  first Klunki game for more than two: roll five dice up to three times (tap dice to keep them, or shake the
  phone), then write the result into one box of your column: ones to sixes (35 bonus from 63), three and four
  of a kind, full house, small and large straight, five of a kind, chance. The sheet shows what every free box
  would score; a mis-tap can be taken back until the next player rolls. After 13 rounds the ranking shows who
  won. House rule "Extra-Fünfer" (off by default): 100 extra for another five of a kind, which then counts as a
  joker. "Wer spielt?" now asks how many play (2, 3 or 4) for this game. "Wer fängt an?" before the game: the
  first player, your own order (arrows next to the names), or chance; the game says who starts.
- **Ausgewürfelt: Anfängermodus** (KLD-119), on by default: after the last roll the box that fits best glows on
  the sheet and a tip says why in one line ("Tipp: Fünfer – 15 Punkte helfen dir beim Bonus (63)."), also when
  another box would give more now but is worth more later, or which box to strike; while rolls are left, "Tipp"
  shows which dice to keep. Any box can still be chosen. "Anfängermodus beenden" in the tip or the switch in the
  start options turns it off. Filled boxes now look used (a solid chip with a check, the name faded), empty ones
  like open slots, and the sheet says how many boxes are still free; the rules page says early that every box is
  filled only once. The first game on a device starts with a short tour (5 steps; again via "⋮" → "Kurz
  erklärt").
- **GoStrategy** (KLD-058): every piece now shows a drawn rank insignia instead of the big number: crossed
  batons (Marschall), peaked cap (General), three, two or one star (Oberst, Major, Hauptmann), a bar (Leutnant),
  chevrons (Feldwebel), pickaxe (Mineur), binoculars (Aufklärer), hat and mask (Spion); bomb and flag as before.
  White with a thin dark edge, centred on the tile; the rank number sits in a small badge in the top left
  corner, the "seen" eye in one top right.
- **GoStrategy** (KLD-058): the board zooms like Wortgewandt's: two fingers zoom and move it (also while
  setting up), the magnifier button zooms in on the selected piece and back out, the mouse wheel zooms in the
  browser. Tapping and moving work at any zoom, the coordinates follow, each player keeps their own view.
- **Mau-Mau** (new, KLD-118): the classic card game for two on one device. Lay a card of the same suit or
  rank, or draw; whoever is out of cards first wins. 7 = the other player draws 2 (another 7 passes on 2 more),
  8 = the other player misses a turn, jack = wish a suit, ace = lay another card (ace after ace too), and
  "Mau!" before the second-to-last card (forget it and draw a penalty card). Before the game you choose the
  house rules (each of these can be switched off; "Bube auf Bube" can be switched on). Own card faces, the
  cards stay hidden between turns.
  Clearer buttons: what to do now is a strong filled button, the alternative outlined, "Mau!" stands out only
  when it is due, the draw pile glows and can be tapped. Stacked 7s show on the pile ("2 + 2 + 2 = 6 Karten
  ziehen"), and drawn cards arrive highlighted in the hand. A short "So geht's" tour the first time; its
  last step shows where all the rules are ("Regeln").
- **Mau-Mau: new house rule "Legen, wenn möglich"** (on by default): you may only draw when no card in your hand
  fits; the draw button is gone and the pile does not glow while one does, and the hint says "Du hast eine
  passende Karte – leg sie." After a 7 you may still take the cards instead of answering with a 7, and a drawn
  card that fits may still be kept. Can be switched off in the start options.
- **New game: Mäxchen** (KLD-121, en "Mia"), the dice bluffing game, on one device: roll two dice
  secretly under a cup, announce a value (fibbing allowed), the next player believes it and must top it, or
  doubts it and the cup is lifted. Mäxchen (2 and 1) beats everything. 3 or 5 lives, house rule "Mäxchen
  doppelt" (on by default: doubting a real Mäxchen or being caught with a fake one costs 2 lives). "Zug
  zurück" never takes back a doubt or a given-up life (the dice were shown).
- **Mäxchen**: the buttons are always on screen, also on small phones and with large text: the controls sit
  pinned under the table (beside it in landscape), the values to announce are a compact grid, and before a
  value is chosen the button says "Wähle eine Zahl". New: **"Schütteln zum Würfeln"**: shake the phone like a
  dice cup to roll (iOS, Android, and the browser on phones; in Safari on iPhone after allowing motion access
  on the first "Würfeln" tap). The button stays; the phone gives a short knock when the dice land. On by
  default, switch in Mäxchen's start options.
- **Wortgewandt**: new house rule "Joker tauschen" (swap the blank), chosen at game start (also for a room),
  off by default: whoever holds the letter a laid blank stands for may put it there, take the blank and then lay
  tiles in the same turn. Builds without it cannot play Wortgewandt with builds that have it (rules version 4).
- **Wortgewandt**: a tile laid this turn drags right away, with a finger or the mouse (no more resting on it
  first); on a zoomed board a drag that starts elsewhere still scrolls.
- **Schach**: "Zug bestätigen" (KLD-122): a chosen move is only shown until "✓ Ziehen"; "✗ Zurück" chooses
  again. On by default for games with others (switch on "Raum starten", toggle in the game), off by default
  on one device, where each player chooses in "Wer spielt?".

- **Rules for every game** (KLD-123): a "Spielregeln" page per game, the same parts everywhere (Ziel, So läuft
  ein Zug, Regeln, and "Regelvarianten": the rule variants that are on in this game, left out when none is on;
  the start options say "Regelvariante" instead of "Hausregel" too), with small pictures: the chess
  pieces and how they move, a GoStrategy table of all pieces (rank, how many, who beats whom), the Mau-Mau
  special cards, the Mäxchen value order with dice. Open it with "Regeln" (book icon) at the top right of every
  game, or from the "Regeln" link on each game in the menu. New players see "Neu hier? So geht's" under the
  status line in their first games. Wortgewandt's "So geht's" is part of its rules page now, and Ausgewürfelt's
  page shows every box of the sheet with an example throw.
- **Tidier title bar in every game**: "Spielernamen" and "Neues Spiel" moved into a "⋮" menu (with icon and
  word), so the game's name fits next to "Aufgeben", the move list and "Regeln" on a phone.
- **Mäxchen in the browser on an iPhone**: before Safari asks for motion access, a short card says what it is
  for ("Würfeln durch Schütteln?"); "Nein, nur tippen" turns shaking off. The privacy page now says what the
  motion sensor is used for (only shaking to roll, on the device, nothing stored or sent).

### Playing together
- **A locked phone no longer ends a game with others** (KLD-120). After unlocking, the game goes on by
  itself: the joined device reconnects ("Verbindung wird wiederhergestellt …"), the device that started the
  room opens it again (also through the relay server, which now keeps the room for 5 minutes while that
  device is away). "Neu verbinden" stays as a fallback. During a running game the screen no longer turns off
  by itself (iPhone, Android).
- **Back in the game faster after unlocking** (KLD-120 follow-up): the app no longer waits for the old
  connection to time out, it reconnects at once after any pause of 2 s or more, and retries every second
  while the other device is still coming back. A tap on "reconnect" while the app is already reconnecting
  joins that attempt instead of racing it (over the relay the second one was told the room is full).
- Relay operators: `klunki relay --host-grace SECONDS` and `--log-rooms` (one line per room event, off by
  default); the relay start shows "Host grace: …", which tells a current relay from one built before KLD-120.

### App
- The app icon fills its square on the home screen: a larger pocket and a bolder "Klunki" on the patch.

## [1.1.0] – first external test (TestFlight, Play internal testing, web beta)

1.0.0 was an internal TestFlight test build only (not released).

Kurz: Acht Spiele für zwei – auf einem Gerät, mit zwei Geräten im selben WLAN oder im Browser über einen
Raumcode. Deutsch und sechs weitere Sprachen.

### Games
- **4 Gewinnt** (Four in a Row) and **Mühle** (Nine Men's Morris).
- **Quartett** in two variants, **Trumpf** and **Sets**, with four decks (cars, trains, rockets,
  planes), card photos and Wikipedia links with image credits; house rule "with 3 or fewer cards you
  choose" in Trumpf.
- **Schiffe versenken** (sink the fleet) with a fleet of six ships and an easy setup (random fleet,
  move, turn).
- **GoStrategy** (hidden ranks, capture the flag) with the setup on the real board.
- **Schach** (chess, full rules, automatic draws); the room starter picks white, black or random.
- **Wortgewandt** (word tile game) with German and English word lists and the "Bänkchen" practice rows.

### Playing together
- **One device** (hot-seat): a cover hides the hand, rack or fleet when the device is handed over.
- **With others**: "Raum starten" / "Raum beitreten" from the menu or right from a game's tile;
  join by room code, QR code or link; devices on the same Wi-Fi find each other.
- **Browser vs browser** through a small relay that also serves the web app; relays can ask for a club
  code (Clubcode), off by default.
- Hidden information stays hidden over the network: the starting device is the referee and the other
  device only sees what it may see; secrets are checked at the end.
- Rejoin after a lost connection (only with the session's own token).
- Builds that do not fit together refuse to play and say which device has to update.
- Plain "Server" wording; a club code is asked for only when a server needs one; in-app help "So spielt ihr
  zusammen" (rooms, Wi-Fi, servers, club codes, data).

### App
- Player names (Anna and Ben by default, your own names possible), no X / O anywhere.
- Confirmation before quitting a running game; resign in every game.
- Warm "Spieltisch" look in light and dark, a new app icon.
- **7 languages**: German, English, French, Spanish, Chinese, Arabic and Persian (right to left).
- "Über Klunki" with privacy policy and Impressum (readable offline), support, source code, licences.
- Version line "Version 1.1.0 (b8752a9)": version and commit; build number, protocol and game data in
  small print on the About screen.

### Web
- Offline-capable web app (PWA), nothing loaded from a CDN.
- Web beta on GitHub Pages: plays on one device; network play there needs a secure (wss://) relay.
- A landing page on GitHub Pages (games, FAQ, beta sign-up); the web app moved to `play/`.

[Unreleased]: https://github.com/tronicum/klunki/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/tronicum/klunki/releases/tag/v1.1.0

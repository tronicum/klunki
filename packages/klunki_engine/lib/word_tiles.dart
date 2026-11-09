import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'game.dart';
import 'seats.dart';
import 'secrecy.dart';

part 'word_tiles_view.dart';

/// A crossword-style word tile game (KLD-094, id `wordtiles`, title
/// "Wortgewandt"): players draw letter tiles from a bag and lay words on a
/// 15 × 15 board with premium squares. See `docs/tasks/KLD-094-word-tiles.md`.
///
/// The engine is written for 2–4 seats ([playerCount]); seats are `0…n-1`
/// in turn order. The shared [Game] interface (and with it the 2-player
/// network) knows two players only, so seat 0 is [Player.a] and seat 1
/// [Player.b]; with 3–4 seats the game is played through [SeatGame]
/// ([currentSeat], [seatResult], [seatViewJson], seat-named moves; KLD-088
/// step 1). Two seats behave exactly as before (same moves, views, results).
///
/// Moves (all maps, like every Klunki game):
/// * `{'action': 'place', 'tiles': [{'row': 7, 'col': 7, 'tile': 'H'},
///   {'row': 7, 'col': 8, 'tile': '?', 'letter': 'E'}, …]}`: lay tiles from
///   the rack; a blank (`'?'`) names the letter it stands for, a letter tile
///   carries no `letter`.
///   With the house rule "Joker tauschen" ([jokerSwap], KLD-094 step 9,
///   rules version 4) the move may also carry `'swaps': [{'row': 7, 'col':
///   9, 'tile': 'E'}, …]`: before laying, the player puts the real letter
///   `tile` from the rack on a square that holds a blank standing for that
///   letter and takes the blank onto the rack (where it may be laid again
///   in the same placement). One or more swaps, always together with a
///   placement (no swap alone, none with an exchange or a pass); the
///   swapped square scores like any letter already on the board.
/// * `{'action': 'exchange', 'tiles': ['Q', '?']}`: swap rack tiles with the
///   bag (only while the bag holds at least [rackSize] tiles).
/// * `{'action': 'pass'}`.
/// * "Trotzdem zulassen" in [WordCheck.dictionary] (KLD-094 step 6, rules
///   version 3): a placement whose words the list does not know needs the
///   other player's agreement, as three moves that name their player like
///   a resign ([playerOf]):
///   - `{'action': 'requestAllow', 'player': p, 'tiles': […], 'allow':
///     ['XYZ', …]}`: `p`, the player to move, asks to let the placement
///     stand; `allow` names exactly the formed words the list lacks. The
///     turn does not change and `p` can make no other move (but resign)
///     until it is answered. At most one request is open, and a request
///     declined this turn cannot be repeated with the same words.
///   - `{'action': 'acceptAllow', 'player': q}`: the other player agrees;
///     the placement counts as if laid now, with the words in its log entry
///     ([WordTilesTurn.allowed]).
///   - `{'action': 'declineAllow', 'player': q}`: the other player declines;
///     the tiles stay on `p`'s rack and it is still `p`'s turn.
///   A `place` move carrying `allow` itself is refused (since rules 3): the
///   log shows that both players agreed, which a network host checks.
///   With 3–4 seats the three moves name a seat instead (`'seat': n`, see
///   [requestAllowMoveFor]); the answer comes from the next seat still in.
/// * `{'action': 'challenge'}` / `{'action': 'accept'}`: challenge mode only,
///   see [WordCheck.challenge].
/// * resign: the common `{'action': 'resign', 'player': 'a'|'b'}` with two
///   seats (ends the game). With 3–4 seats `{'action': 'resign', 'seat': n}`
///   ([SeatGame], KLD-088): seat `n` leaves, any time; its rack goes back
///   into the bag, the turn order skips it, it ranks behind everyone still
///   in; the game goes on until one seat is left (that seat wins,
///   [GameEndReason.commonResigned]) or ends normally.
///
/// An illegal move returns null and changes nothing.
enum WordCheck {
  /// No check when a word is laid ("Anzweifeln", as at a real table). The
  /// next player may answer the last placement with `challenge` before
  /// making their own move (anything else accepts it). Without a
  /// [WordTilesGame.validator] the challenger's call is final: the placement
  /// is withdrawn (tiles back to the rack, drawn tiles back into the bag, no
  /// score) and the challenger plays on. With a validator the words are
  /// checked: an invalid word is withdrawn the same way, a valid one stands
  /// and the challenger loses the turn.
  challenge,

  /// Every word a placement forms must pass [WordTilesGame.validator]; a
  /// placement with an unknown word is refused like any illegal move,
  /// unless the move names that word in `allow` (the players agreed to let
  /// it stand, KLD-094 step 4). No challenges: the check at "Legen"
  /// replaces them.
  dictionary,
}

/// The kinds of premium squares.
enum Premium {
  none(1, 1, '.'),
  doubleLetter(2, 1, ':'),
  tripleLetter(3, 1, '^'),
  doubleWord(1, 2, '+'),
  tripleWord(1, 3, '*');

  final int letterFactor;
  final int wordFactor;

  /// One character for the text board.
  final String symbol;
  const Premium(this.letterFactor, this.wordFactor, this.symbol);
}

/// Decides whether a word may be played. Words come upper case, as on the
/// board (`HÄUSER`, blanks resolved to their letter).
abstract class WordValidator {
  const WordValidator();
  bool isWord(String word);
}

/// Accepts every word: the challenge mode without a dictionary, where the
/// players judge.
class AcceptAllValidator extends WordValidator {
  const AcceptAllValidator();
  @override
  bool isWord(String word) => true;
}

/// An in-memory word list (tests, small lists). Words are normalized with
/// [TileSet.normalize] of [tileSet] (upper case, `ß` → `SS`).
class WordListValidator extends WordValidator {
  final Set<String> _words;
  WordListValidator(Iterable<String> words, [TileSet tileSet = TileSet.german])
      : _words = {for (final w in words) tileSet.normalize(w)};
  @override
  bool isWord(String word) => _words.contains(word);
  int get length => _words.length;
}

/// A large word list kept as one block of UTF-8 bytes (KLD-094 step 4: the
/// bundled lists, 190 k – 590 k words): one normalized word per line, sorted
/// by byte (= code point) order, as `klunki/tool/build_word_lists.py` writes
/// it. Lookup is a binary search over the line starts (~20 compares), so the
/// memory is the text plus 4 bytes per word, no string per word.
class SortedWordListValidator extends WordValidator {
  final Uint8List _bytes;
  final Int32List _starts;

  SortedWordListValidator._(this._bytes, this._starts);

  /// Indexes [bytes] (UTF-8, a line feed after every word, sorted). Throws
  /// [FormatException] if the lines are not strictly ascending.
  factory SortedWordListValidator.fromUtf8(Uint8List bytes) {
    var n = 0;
    for (final b in bytes) {
      if (b == 0x0a) n++;
    }
    final open = bytes.isNotEmpty && bytes.last != 0x0a;
    if (open) n++;
    final starts = Int32List(n + 1);
    var line = 0;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0x0a) starts[++line] = i + 1;
    }
    if (open) starts[n] = bytes.length + 1;
    final v = SortedWordListValidator._(bytes, starts);
    for (var k = 1; k < n; k++) {
      if (v._compareLines(k - 1, k) >= 0) throw FormatException('word list not sorted at line ${k + 1}');
    }
    return v;
  }

  /// Number of words.
  int get length => _starts.length - 1;

  int _end(int k) => _starts[k + 1] - 1;

  int _compareLines(int a, int b) {
    var i = _starts[a], j = _starts[b];
    final ea = _end(a), eb = _end(b);
    while (i < ea && j < eb) {
      final d = _bytes[i++] - _bytes[j++];
      if (d != 0) return d;
    }
    return (ea - i) - (eb - j);
  }

  int _compareTo(int k, List<int> w) {
    var i = _starts[k];
    final e = _end(k);
    var j = 0;
    while (i < e && j < w.length) {
      final d = _bytes[i++] - w[j++];
      if (d != 0) return d;
    }
    return (e - i) - (w.length - j);
  }

  @override
  bool isWord(String word) {
    if (word.isEmpty) return false;
    final w = utf8.encode(word);
    var lo = 0, hi = length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final c = _compareTo(mid, w);
      if (c == 0) return true;
      if (c < 0) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return false;
  }
}

/// The word lists the app has loaded, per tile set id (KLD-094 step 4). A
/// [GameConfig] with `dictionary` on creates its game with the list
/// registered for its tile set; the app loads and registers it before it
/// starts such a game (the engine never reads files).
class WordLists {
  WordLists._();
  static final Map<String, WordValidator> _lists = {};

  /// Which list a build ships per tile set: the source and its commit plus
  /// the SHA-256 of the bundled `words.txt.gz` (as in its `SOURCE.txt`;
  /// KLD-094 step 6, an app test checks that it matches the asset). Part of
  /// the compat fingerprint ([WordTilesGame.gameplayData]), so two builds
  /// with different lists refuse to play a word tile game together instead
  /// of judging words differently. Change it together with the asset.
  static const Map<String, String> revisions = {
    'de': 'enz/german-wordlist@1071d87 sha256:fa8ab81c96e5eb075fb3f3fe1e639a7f81196c8d9e4458abae8d2eb4c070c0b8',
    'en': 'en-wl/wordlist ESDB@1e5b7d3 size 80 sha256:0927f44c2dedac2e82bbade2a262b0e4d245c59ad4c021762bec30d9a8e7091d',
  };

  static void register(String tileSetId, WordValidator list) => _lists[tileSetId] = list;
  static WordValidator? of(String tileSetId) => _lists[tileSetId];
  static bool has(String tileSetId) => _lists.containsKey(tileSetId);

  /// Tests only.
  static void clear() => _lists.clear();
}

/// The letters of one language: how many tiles of each and what they score.
///
/// Our own derivation (KLD-094), not copied from any commercial game: counts
/// follow published letter frequencies, points the rarity of the letter.
/// The derivation (in `test/word_tiles_test.dart`, which recomputes and pins
/// both sets):
/// * **Counts:** 98 letter tiles + 2 blanks = 100. Every letter gets one
///   tile; the other tiles go one at a time to the letter with the highest
///   `f^0.9 / (n + 1)` (`f` = frequency, `n` = tiles so far; a highest-
///   averages method, so a more frequent letter never gets fewer tiles). The
///   exponent 0.9 damps the most frequent letters slightly.
/// * **Points:** `r = log2(fRef / f)` with `fRef` = mean frequency of the six
///   most frequent letters (0 if `f > fRef`), scaled by `k` so the rarest
///   letter reaches the top band: `k = 7 / log2(fRef / fMin)`; band index
///   `floor(r · k)` into 1, 2, 3, 4, 5, 6, 8, 10.
///
/// Sources of the frequencies: German, Karl-Heinz Best, "Buchstaben-
/// häufigkeiten im Deutschen und Englischen" (2005), as tabled on
/// de.wikipedia.org/wiki/Buchstabenhäufigkeit (with Ä Ö Ü; ß folded into S
/// twice, since ß is written SS); English, the "Dictionaries" column of
/// en.wikipedia.org/wiki/Letter_frequency. Both should be recalibrated
/// against the approved word list (step 4).
class TileSet {
  /// Stable id (`de`, `en`), part of the game's view.
  final String id;

  /// Tiles per letter.
  final Map<String, int> counts;

  /// Points per letter (a blank scores 0).
  final Map<String, int> points;

  /// Number of blanks.
  final int blanks;

  const TileSet(this.id, this.counts, this.points, {this.blanks = 2});

  /// The tile that stands for a blank.
  static const String blank = '?';

  /// German: A–Z plus Ä Ö Ü as tiles of their own; no ß tile (ß is written
  /// SS, as in upper-case German and in word games).
  static const TileSet german = TileSet('de', {
    'E': 15, 'N': 9, 'S': 7, 'I': 7, 'R': 6, 'A': 6, 'T': 6, 'D': 5, 'H': 4, 'U': 4, //
    'L': 3, 'C': 3, 'G': 3, 'M': 2, 'O': 2, 'B': 2, 'W': 2, 'F': 1, 'K': 1, 'Z': 1, //
    'P': 1, 'V': 1, 'Ü': 1, 'Ä': 1, 'Ö': 1, 'J': 1, 'Y': 1, 'X': 1, 'Q': 1,
  }, {
    'E': 1, 'N': 1, 'S': 1, 'I': 1, 'R': 1, 'A': 1, 'T': 1, 'D': 1, 'H': 1, 'U': 1, //
    'L': 2, 'C': 2, 'G': 2, 'M': 2, 'O': 2, 'B': 2, 'W': 2, 'F': 2, 'K': 3, 'Z': 3, //
    'P': 3, 'V': 3, 'Ü': 4, 'Ä': 4, 'Ö': 4, 'J': 5, 'Y': 8, 'X': 8, 'Q': 10,
  });

  /// English: A–Z.
  static const TileSet english = TileSet('en', {
    'E': 10, 'S': 8, 'I': 8, 'A': 8, 'R': 7, 'N': 7, 'T': 6, 'O': 6, 'L': 5, 'C': 4, //
    'D': 4, 'U': 3, 'G': 3, 'P': 3, 'M': 3, 'H': 2, 'B': 2, 'Y': 1, 'F': 1, 'V': 1, //
    'K': 1, 'W': 1, 'Z': 1, 'X': 1, 'J': 1, 'Q': 1,
  }, {
    'E': 1, 'S': 1, 'I': 1, 'A': 1, 'R': 1, 'N': 1, 'T': 1, 'O': 1, 'L': 1, 'C': 2, //
    'D': 2, 'U': 2, 'G': 2, 'P': 3, 'M': 3, 'H': 3, 'B': 3, 'Y': 4, 'F': 4, 'V': 4, //
    'K': 4, 'W': 5, 'Z': 6, 'X': 8, 'J': 8, 'Q': 10,
  });

  static const List<TileSet> all = [german, english];

  static TileSet? byId(Object? id) => all.where((t) => t.id == id).firstOrNull;

  /// The letters, in a fixed order (alphabetical, umlauts last).
  List<String> get letters => counts.keys.toList()..sort();

  int get size => counts.values.fold(blanks, (a, b) => a + b);

  /// Points of [tile] (0 for a blank or an unknown tile).
  int pointsOf(String tile) => points[tile] ?? 0;

  /// [word] as it would lie on the board: upper case, `ß` → `SS`.
  String normalize(String word) => word.replaceAll('ß', 'SS').replaceAll('ẞ', 'SS').toUpperCase();

  /// Whether every letter of [word] (normalized) has a tile.
  bool canSpell(String word) => normalize(word).split('').every(counts.containsKey);

  /// The whole bag, unshuffled, in [letters] order, blanks last.
  List<String> bag() => [
        for (final l in letters) ...List.filled(counts[l]!, l),
        ...List.filled(blanks, blank),
      ];
}

/// A tile on the board.
class BoardTile {
  /// The letter it shows (a blank shows the letter it was given).
  final String letter;
  final bool blank;
  const BoardTile(this.letter, {this.blank = false});

  @override
  bool operator ==(Object other) => other is BoardTile && other.letter == letter && other.blank == blank;
  @override
  int get hashCode => Object.hash(letter, blank);
  @override
  String toString() => blank ? letter.toLowerCase() : letter;
}

/// A "Joker tauschen" swap (KLD-094 step 9): the real letter [tile] from
/// the rack goes onto the square [row], [col], which holds a blank standing
/// for [tile]; the blank goes onto the rack.
class JokerSwap {
  final int row;
  final int col;
  final String tile;
  const JokerSwap(this.row, this.col, this.tile);

  Map<String, dynamic> toJson() => {'row': row, 'col': col, 'tile': tile};

  @override
  bool operator ==(Object other) => other is JokerSwap && other.row == row && other.col == col && other.tile == tile;
  @override
  int get hashCode => Object.hash(row, col, tile);
}

/// One tile of a placement: square, rack tile, and for a blank its letter.
class PlacedTile {
  final int row;
  final int col;

  /// The rack tile: a letter or [TileSet.blank].
  final String tile;

  /// The letter shown: [tile], or the chosen letter of a blank.
  final String letter;
  const PlacedTile(this.row, this.col, this.tile, [String? letter]) : letter = letter ?? tile;

  bool get isBlank => tile == TileSet.blank;

  Map<String, dynamic> toJson() => {'row': row, 'col': col, 'tile': tile, if (isBlank) 'letter': letter};
}

/// A word a placement forms, with its score.
class FormedWord {
  final String word;
  final int score;

  /// Start square and direction.
  final int row;
  final int col;
  final bool across;
  const FormedWord(this.word, this.score, this.row, this.col, this.across);

  Map<String, dynamic> toJson() => {'word': word, 'score': score, 'row': row, 'col': col, 'across': across};

  @override
  String toString() => '$word ($score)';
}

/// Why a placement is not allowed ([WordTilesGame.checkPlacement]).
enum PlacementError {
  /// The move map is malformed (missing or bad fields, a blank without a
  /// letter, a letter tile with one).
  malformed,
  /// No tiles.
  empty,
  /// A square outside the board.
  offBoard,
  /// A square that already holds a tile, or the same square twice.
  occupied,
  /// A tile the player does not hold (or more of them than held).
  notOnRack,
  /// The tiles are not in one row or one column.
  notInLine,
  /// The tiles leave an empty square between them.
  gap,
  /// The first word does not cover the centre square.
  firstNotOnCentre,
  /// The first word has only one letter.
  firstTooShort,
  /// The tiles touch no tile on the board.
  notConnected,
  /// A formed word fails the validator (dictionary mode).
  unknownWord,
  /// It is not the time for a placement (the game ended, or only
  /// `challenge` / `accept` are allowed).
  notNow,
}

/// The outcome of [WordTilesGame.checkPlacement]: an [error], or the formed
/// [words] (main word first) and the [score] (bonus included).
class PlacementCheck {
  final PlacementError? error;
  final List<FormedWord> words;
  final int score;
  final bool bingo;
  final List<PlacedTile> tiles;

  /// The "Joker tauschen" swaps made before the tiles are laid.
  final List<JokerSwap> swaps;
  const PlacementCheck.error(PlacementError this.error)
      : words = const [],
        score = 0,
        bingo = false,
        tiles = const [],
        swaps = const [];
  const PlacementCheck(this.tiles, this.words, this.score, this.bingo, {this.swaps = const []}) : error = null;
  bool get ok => error == null;
}

/// One entry of the public turn log ([WordTilesGame.turns]): who did what,
/// without hidden data (an exchange shows only how many tiles).
class WordTilesTurn {
  final int seat;

  /// `place`, `exchange`, `pass`, `challenge`, `accept`; `resign` (3–4
  /// seats: the seat left the game).
  final String action;
  final List<String> words;
  final int score;

  /// Tiles placed or exchanged.
  final int count;

  /// For a placement: withdrawn after a challenge. For a challenge: it
  /// succeeded.
  final bool withdrawn;

  /// For a placement in [WordCheck.dictionary]: the words the list does not
  /// know that the players let stand ("Trotzdem zulassen").
  final List<String> allowed;

  /// For a placement: how many blanks the player took with "Joker tauschen"
  /// before laying (KLD-094 step 9).
  final int swaps;
  const WordTilesTurn(this.seat, this.action,
      {this.words = const [],
      this.score = 0,
      this.count = 0,
      this.withdrawn = false,
      this.allowed = const [],
      this.swaps = 0});

  WordTilesTurn copyWith({bool? withdrawn}) => WordTilesTurn(seat, action,
      words: words,
      score: score,
      count: count,
      withdrawn: withdrawn ?? this.withdrawn,
      allowed: allowed,
      swaps: swaps);

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'action': action,
        if (words.isNotEmpty) 'words': words,
        if (score != 0) 'score': score,
        if (count != 0) 'count': count,
        if (withdrawn) 'withdrawn': true,
        if (allowed.isNotEmpty) 'allowed': allowed,
        if (swaps != 0) 'swaps': swaps,
      };

  static WordTilesTurn fromJson(Object? j) {
    if (j is! Map) throw const BadViewException('bad turn');
    return WordTilesTurn(j['seat'] as int, j['action'] as String,
        words: [for (final w in (j['words'] as List? ?? const [])) w as String],
        score: j['score'] as int? ?? 0,
        count: j['count'] as int? ?? 0,
        withdrawn: j['withdrawn'] == true,
        allowed: [for (final w in (j['allowed'] as List? ?? const [])) w as String],
        swaps: j['swaps'] as int? ?? 0);
  }
}

/// The last placement while it can still be challenged.
class _OpenPlacement {
  final int seat;
  final List<PlacedTile> tiles;
  final List<String> words;
  final int score;
  final List<String> rackBefore;
  final int drawn;
  final int scorelessBefore;
  final int turnIndex;
  final List<JokerSwap> swaps;
  const _OpenPlacement(this.seat, this.tiles, this.words, this.score, this.rackBefore, this.drawn,
      this.scorelessBefore, this.turnIndex,
      [this.swaps = const []]);
}

/// The open "Trotzdem zulassen" request (KLD-094 step 6).
class _AllowRequest {
  final int seat;
  final List<PlacedTile> tiles;
  final List<String> allow;
  final List<String> words;
  final int score;
  final List<JokerSwap> swaps;
  const _AllowRequest(this.seat, this.tiles, this.allow, this.words, this.score, [this.swaps = const []]);
}

/// The rules engine. See the library docs above for moves; the design and
/// its decisions are in the KLD-094 card.
class WordTilesGame extends Game implements SeatGame {
  static const int size = 15;
  static const int centre = 7;
  static const int rackSize = 7;

  /// Bonus for laying all [rackSize] tiles in one move.
  static const int bingoBonus = 50;

  /// Our own premium layout (KLD-094), given as one octant
  /// (`row <= col <= 7`) and mirrored on both axes and the diagonal:
  /// 8 triple word, 17 double word (centre included), 12 triple letter,
  /// 24 double letter squares.
  static const Map<(int, int), Premium> _octant = {
    (0, 3): Premium.tripleWord,
    (2, 4): Premium.doubleWord,
    (5, 5): Premium.doubleWord,
    (1, 7): Premium.doubleWord,
    (7, 7): Premium.doubleWord,
    (1, 1): Premium.tripleLetter,
    (3, 5): Premium.tripleLetter,
    (0, 0): Premium.doubleLetter,
    (0, 6): Premium.doubleLetter,
    (3, 6): Premium.doubleLetter,
    (4, 4): Premium.doubleLetter,
  };

  static final List<Premium> _premiums = List.generate(size * size, (i) {
    var r = i ~/ size, c = i % size;
    if (r > centre) r = size - 1 - r;
    if (c > centre) c = size - 1 - c;
    if (r > c) (r, c) = (c, r);
    return _octant[(r, c)] ?? Premium.none;
  });

  /// The rules data two builds must agree on (KLD-085 fingerprint): every
  /// tile set (letters, counts, points, blanks) and the premium layout.
  static List<Object> gameplayData() => [
        for (final t in TileSet.all) [t.id, [for (final l in t.letters) [l, t.counts[l], t.points[l]]], t.blanks],
        [for (final p in _premiums) p.index].join(),
        rackSize,
        bingoBonus,
        [for (final e in WordLists.revisions.entries) '${e.key}=${e.value}'],
      ];

  /// The premium of the square at [row], [col].
  static Premium premiumAt(int row, int col) => _premiums[row * size + col];

  final int seed;
  final TileSet tileSet;
  @override
  final int playerCount;
  final WordCheck check;

  /// The house rule "Joker tauschen" (KLD-094 step 9, off by default): a
  /// `place` move may carry `swaps` (see the library docs).
  final bool jokerSwap;

  /// "Restpunkte abziehen" (KLD-094 step 10, on by default, the usual rule):
  /// at the end every player loses the points of the tiles left on the
  /// rack and whoever went out gains their sum (on the scoreless end
  /// everyone just loses theirs). Off: no deduction and no bonus, the
  /// scores of the laid words decide ([rackPenalties] stay 0).
  final bool rackPenalty;

  /// The word check: required in [WordCheck.dictionary]; optional in
  /// [WordCheck.challenge] (null: the challenger decides).
  final WordValidator? validator;

  /// Consecutive scoreless turns (passes, exchanges, withdrawn or zero-score
  /// placements, failed challenges) that end the game; by default
  /// [defaultScorelessLimit].
  final int scorelessLimit;

  /// The default [scorelessLimit] for [players] seats: 6 (the usual rule)
  /// for 2 and 3 seats, 2 × [players] beyond, so every player has passed
  /// (or exchanged) twice in a row before a game ends that way.
  static int defaultScorelessLimit(int players) => max(6, 2 * players);

  final List<BoardTile?> _board = List.filled(size * size, null);

  /// The bag; tiles are drawn from the end.
  final List<String> _bag = [];
  final List<List<String>> _racks;
  final List<int> _scores;
  final List<int> _penalties;
  final Random _rng;
  int _seat = 0;
  int _scoreless = 0;
  _OpenPlacement? _open;
  _AllowRequest? _request;

  /// The `allow` word sets declined in this turn (sorted), so the same
  /// request cannot be repeated until the turn changes.
  final List<List<String>> _declined = [];
  /// Seats that resigned (3–4 seats only), in the order they left.
  final List<int> _outOrder = [];
  bool _endPending = false;
  bool _over = false;
  GameEndReason? _endCode;
  int? _outSeat;
  final List<Map<String, dynamic>> _history = [];
  final List<WordTilesTurn> _turns = [];

  WordTilesGame(
      {this.seed = 0,
      this.tileSet = TileSet.german,
      this.playerCount = 2,
      this.check = WordCheck.challenge,
      this.validator,
      this.jokerSwap = false,
      this.rackPenalty = true,
      int? scorelessLimit})
      : scorelessLimit = scorelessLimit ?? defaultScorelessLimit(playerCount),
        _racks = List.generate(playerCount, (_) => <String>[]),
        _scores = List.filled(playerCount, 0),
        _penalties = List.filled(playerCount, 0),
        _rng = Random(seed) {
    if (playerCount < 2 || playerCount > 4) throw ArgumentError.value(playerCount, 'playerCount', '2–4 seats');
    if (check == WordCheck.dictionary && validator == null) {
      throw ArgumentError('dictionary mode needs a validator');
    }
    _bag.addAll(tileSet.bag());
    for (var i = _bag.length - 1; i > 0; i--) {
      final j = _rng.nextInt(i + 1);
      final t = _bag[i];
      _bag[i] = _bag[j];
      _bag[j] = t;
    }
    for (var s = 0; s < playerCount; s++) {
      _draw(s, rackSize);
    }
  }

  /// The empty shell of a view ([WordTilesView]): no bag, no racks dealt.
  WordTilesGame._view(this.tileSet, this.playerCount, this.check, this.validator, this.scorelessLimit,
      {this.jokerSwap = false, this.rackPenalty = true})
      : seed = 0,
        _racks = List.generate(playerCount, (_) => <String>[]),
        _scores = List.filled(playerCount, 0),
        _penalties = List.filled(playerCount, 0),
        _rng = Random(0);

  /// Test and debug hook: replaces the racks (per seat), the bag (drawn
  /// from the end) and/or puts [board] tiles down, before the first move.
  /// Tile counts are not checked against [tileSet].
  void debugSetup({List<List<String>>? racks, List<String>? bag, Map<(int, int), BoardTile>? board}) {
    if (_history.isNotEmpty) throw StateError('debugSetup only before the first move');
    if (racks != null) {
      for (var s = 0; s < playerCount; s++) {
        _racks[s]
          ..clear()
          ..addAll(racks[s]);
      }
    }
    if (bag != null) {
      _bag
        ..clear()
        ..addAll(bag);
    }
    board?.forEach((sq, t) => _board[sq.$1 * size + sq.$2] = t);
  }

  // --- seats and players ---

  /// The seat to move.
  int get currentSeat => _seat;

  /// The seat expected to move now: the answerer of an open "Trotzdem
  /// zulassen" request, else [currentSeat] (who may also challenge); null
  /// once over.
  @override
  int? get actorSeat => isOver ? null : allowRequestAnswerer ?? _seat;

  @override
  bool isSeatOut(int seat) => _outOrder.contains(seat);

  /// The seats that resigned, in the order they left (3–4 seats).
  List<int> get outSeats => List.unmodifiable(_outOrder);

  /// The seats still in, in seat order.
  List<int> get activeSeats => [for (var s = 0; s < playerCount; s++) if (!isSeatOut(s)) s];

  @override
  int seatOfMove(Map<String, dynamic> move) {
    if (move['action'] == 'resign') {
      final s = playerCount == 2 ? Game.resignerOf(move)?.index : move['seat'];
      if (s is int) return s;
    }
    return _allowSeatOf(move) ?? _seat;
  }

  /// [Player] of a seat: seat 0 = A, 1 = B (null beyond, until KLD-088).
  static Player? playerOfSeat(int seat) => seat < Player.values.length ? Player.values[seat] : null;

  /// Seat of [p].
  static int seatOf(Player p) => p.index;

  @override
  Player get currentPlayer =>
      playerOfSeat(_seat) ?? (throw StateError('seat $_seat has no Player (more than 2 seats, KLD-088)'));

  /// The next seat still in after [seat].
  int _next(int seat) {
    var s = seat;
    do {
      s = (s + 1) % playerCount;
    } while (_outOrder.contains(s) && s != seat);
    return s;
  }

  // --- state getters ---

  /// The tile at [row], [col], or null.
  BoardTile? tileAt(int row, int col) => _board[row * size + col];

  /// The board, row by row (`row * size + col`).
  List<BoardTile?> get board => List.unmodifiable(_board);

  bool get boardEmpty => _board.every((t) => t == null);

  /// [seat]'s rack, in draw order.
  List<String> rackOf(int seat) => List.unmodifiable(_racks[seat]);

  int rackSizeOf(int seat) => _racks[seat].length;

  int get bagCount => _bag.length;

  /// [seat]'s score (end-of-game rack adjustments included once over).
  int scoreOf(int seat) => _scores[seat];

  List<int> get scores => List.unmodifiable(_scores);

  /// End-of-game rack adjustments per seat (negative: tiles left on the
  /// rack; positive: the player who went out gets the others' tiles); all
  /// zero while running.
  List<int> get rackPenalties => List.unmodifiable(_penalties);

  /// Consecutive scoreless turns so far.
  int get scorelessTurns => _scoreless;

  /// Whether `challenge` / `accept` are allowed now (challenge mode, right
  /// after another seat's placement).
  bool get canChallenge => _open != null && !_over && resignedBy == null;

  /// The placement that can be challenged: its seat, tiles, words, score.
  ({int seat, List<PlacedTile> tiles, List<String> words, int score})? get challengeable {
    final o = _open;
    if (o == null || !canChallenge) return null;
    return (seat: o.seat, tiles: o.tiles, words: o.words, score: o.score);
  }

  /// True while the game waits for the answer to a placement that would
  /// end it (the placer went out): only `challenge` or `accept`.
  bool get endPending => _endPending && !_over;

  /// Whether exchanging is allowed (bag holds at least [rackSize] tiles).
  bool get canExchange => _bag.length >= rackSize;

  /// Public turn log.
  List<WordTilesTurn> get turns => List.unmodifiable(_turns);

  @override
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);

  /// Seats with the top score once the game is over (more than one: a tie);
  /// seats that resigned do not count (the last seat left wins alone).
  List<int> get winnerSeats {
    if (!_over) return const [];
    final active = activeSeats;
    if (_endCode == GameEndReason.commonResigned) return active;
    final best = active.map((s) => _scores[s]).reduce(max);
    return [for (final s in active) if (_scores[s] == best) s];
  }

  /// The outcome per seat: places by final score (ties share a place),
  /// seats that resigned behind (the last to leave best among them). With
  /// two seats a common resign gives the resigner place 2.
  @override
  SeatResult get seatResult {
    final resigner = resignedBy;
    if (resigner != null) {
      return SeatResult(
          isOver: true,
          places: [for (var s = 0; s < playerCount; s++) s == resigner.index ? 2 : 1],
          code: GameEndReason.commonResigned.code,
          params: {'seat': resigner.index},
          reason: '${_markOf(resigner.index)} resigned');
    }
    if (!_over) return const SeatResult();
    final r = playResult;
    return SeatResult(
        isOver: true,
        places: _endCode == GameEndReason.commonResigned
            ? SeatResult.placesFor(List.filled(playerCount, 0), out: _outOrder)
            : SeatResult.placesFor(_scores, out: _outOrder),
        code: _endCode!.code,
        params: {
          for (var s = 0; s < playerCount; s++) 'score$s': _scores[s],
          if (_endCode == GameEndReason.wordtilesScoreless) 'turns': scorelessLimit,
          if (_endCode == GameEndReason.commonResigned) 'seat': _outOrder.last,
        },
        reason: r.reason);
  }

  /// The engine's English name for [seat] (CLI, logs).
  static String _markOf(int seat) => switch (seat) {
        0 => playerNameOf(Player.a),
        1 => playerNameOf(Player.b),
        _ => 'P${seat + 1}',
      };

  @override
  bool get isOver => resignedBy != null || _over;

  /// The two-player outcome. With 3–4 seats a winner in seat 2+ cannot be
  /// named as a [Player]: then (and on a shared first place) [GameResult.draw]
  /// is true only to say that the game is over; use [seatResult].
  @override
  GameResult get playResult {
    if (!_over) return const GameResult();
    final w = winnerSeats;
    final winner = w.length == 1 ? playerOfSeat(w.single) : null;
    final draw = winner == null;
    final params = <String, int>{
      for (var s = 0; s < playerCount && s < 2; s++) Player.values[s].name: _scores[s],
      if (_endCode == GameEndReason.wordtilesScoreless) 'turns': scorelessLimit,
      if (_endCode == GameEndReason.commonResigned) 'player': _outOrder.last,
    };
    final scoreText = [for (var s = 0; s < playerCount; s++) '${_markOf(s)} ${_scores[s]}'].join(', ');
    final why = switch (_endCode) {
      GameEndReason.wordtilesPlayedOut => '${_markOf(_outSeat!)} played out',
      GameEndReason.commonResigned => 'the others resigned',
      _ => '$scorelessLimit scoreless turns',
    };
    return GameResult(winner: winner, draw: draw, reason: '$why; $scoreText', code: _endCode, params: params);
  }

  // --- placement check ---

  /// Parses [move]'s `tiles` into [PlacedTile]s; null if malformed.
  List<PlacedTile>? _parseTiles(Object? raw) {
    if (raw is! List) return null;
    final out = <PlacedTile>[];
    for (final t in raw) {
      if (t is! Map) return null;
      final row = t['row'], col = t['col'], tile = t['tile'], letter = t['letter'];
      if (row is! int || col is! int || tile is! String) return null;
      if (tile == TileSet.blank) {
        if (letter is! String || !tileSet.counts.containsKey(letter)) return null;
        out.add(PlacedTile(row, col, tile, letter));
      } else {
        if (letter != null || !tileSet.counts.containsKey(tile)) return null;
        out.add(PlacedTile(row, col, tile));
      }
    }
    return out;
  }

  /// Parses a move's `swaps` (KLD-094 step 9): a non-empty list of
  /// `{row, col, tile}` with a letter tile; null if malformed.
  List<JokerSwap>? _parseSwaps(Object? raw) {
    if (raw is! List || raw.isEmpty) return null;
    final out = <JokerSwap>[];
    for (final s in raw) {
      if (s is! Map || s.length != 3) return null;
      final row = s['row'], col = s['col'], tile = s['tile'];
      if (row is! int || col is! int || tile is! String || !tileSet.counts.containsKey(tile)) return null;
      out.add(JokerSwap(row, col, tile));
    }
    return out;
  }

  /// Whether a player could take the blank on [row], [col] by laying [tile]
  /// there ("Joker tauschen", [jokerSwap]): the rule is on and the square
  /// holds a blank standing for [tile]. Does not look at any rack.
  bool canSwapJokerAt(int row, int col, String tile) {
    if (!jokerSwap || row < 0 || row >= size || col < 0 || col >= size) return false;
    final b = _board[row * size + col];
    return b != null && b.blank && b.letter == tile;
  }

  /// Checks a `place` [move] for the seat to move, without changing
  /// anything: the error, or the words and the score it would make. The UI
  /// uses it for a live score preview and to explain a refused placement.
  ///
  /// [checkWords] false skips the word list: the preview must not tell the
  /// player whether a word is in the list before "Legen" (that would be an
  /// indirect dictionary); [unknownWords] answers it at "Legen".
  PlacementCheck checkPlacement(Map<String, dynamic> move, {bool checkWords = true}) {
    if (isOver || _endPending || _request != null) return const PlacementCheck.error(PlacementError.notNow);
    final tiles = _parseTiles(move['tiles']);
    if (tiles == null) return const PlacementCheck.error(PlacementError.malformed);
    if (tiles.isEmpty) return const PlacementCheck.error(PlacementError.empty);
    // "Joker tauschen" (KLD-094 step 9): the swaps happen first; the blanks
    // they free join the rack, the real letters stand on their squares.
    var swaps = const <JokerSwap>[];
    final rack = List<String>.of(_racks[_seat]);
    final swapped = <int, String>{};
    if (move.containsKey('swaps')) {
      final s = jokerSwap ? _parseSwaps(move['swaps']) : null;
      if (s == null) return const PlacementCheck.error(PlacementError.malformed);
      for (final x in s) {
        if (!canSwapJokerAt(x.row, x.col, x.tile) || swapped.containsKey(x.row * size + x.col)) {
          return const PlacementCheck.error(PlacementError.malformed);
        }
        if (!rack.remove(x.tile)) return const PlacementCheck.error(PlacementError.notOnRack);
        swapped[x.row * size + x.col] = x.tile;
      }
      rack.addAll(List.filled(s.length, TileSet.blank));
      swaps = s;
    }
    final squares = <int>{};
    for (final t in tiles) {
      if (t.row < 0 || t.row >= size || t.col < 0 || t.col >= size) {
        return const PlacementCheck.error(PlacementError.offBoard);
      }
      if (_board[t.row * size + t.col] != null || !squares.add(t.row * size + t.col)) {
        return const PlacementCheck.error(PlacementError.occupied);
      }
    }
    for (final t in tiles) {
      if (!rack.remove(t.tile)) return const PlacementCheck.error(PlacementError.notOnRack);
    }
    final sameRow = tiles.every((t) => t.row == tiles.first.row);
    final sameCol = tiles.every((t) => t.col == tiles.first.col);
    if (!sameRow && !sameCol) return const PlacementCheck.error(PlacementError.notInLine);
    // Direction of the main word; a single tile goes across if it has a
    // neighbour across, else down.
    var across = sameRow && tiles.length > 1;
    if (tiles.length == 1) {
      final t = tiles.single;
      across = _filled(t.row, t.col - 1) || _filled(t.row, t.col + 1);
    }
    final placed = {for (final t in tiles) t.row * size + t.col: t};
    BoardTile? at(int r, int c) {
      if (r < 0 || r >= size || c < 0 || c >= size) return null;
      final p = placed[r * size + c];
      if (p != null) return BoardTile(p.letter, blank: p.isBlank);
      final s = swapped[r * size + c];
      return s != null ? BoardTile(s) : _board[r * size + c];
    }

    // No gaps between the first and the last new tile.
    final along = [for (final t in tiles) across ? t.col : t.row]..sort();
    final line = across ? tiles.first.row : tiles.first.col;
    for (var i = along.first; i <= along.last; i++) {
      if ((across ? at(line, i) : at(i, line)) == null) return const PlacementCheck.error(PlacementError.gap);
    }
    if (boardEmpty) {
      if (!placed.containsKey(centre * size + centre)) {
        return const PlacementCheck.error(PlacementError.firstNotOnCentre);
      }
      if (tiles.length < 2) return const PlacementCheck.error(PlacementError.firstTooShort);
    } else {
      final touches = tiles.any((t) =>
          _filled(t.row - 1, t.col) || _filled(t.row + 1, t.col) || _filled(t.row, t.col - 1) || _filled(t.row, t.col + 1));
      if (!touches) return const PlacementCheck.error(PlacementError.notConnected);
    }
    // Words: the main word, then a cross word through every new tile.
    final words = <FormedWord>[];
    FormedWord? wordThrough(int r, int c, bool acr) {
      final dr = acr ? 0 : 1, dc = acr ? 1 : 0;
      var sr = r, sc = c;
      while (at(sr - dr, sc - dc) != null) {
        sr -= dr;
        sc -= dc;
      }
      final letters = StringBuffer();
      var sum = 0, factor = 1, n = 0;
      for (var rr = sr, cc = sc; at(rr, cc) != null; rr += dr, cc += dc) {
        final tile = at(rr, cc)!;
        letters.write(tile.letter);
        var v = tile.blank ? 0 : tileSet.pointsOf(tile.letter);
        if (placed.containsKey(rr * size + cc)) {
          final p = premiumAt(rr, cc);
          v *= p.letterFactor;
          factor *= p.wordFactor;
        }
        sum += v;
        n++;
      }
      if (n < 2) return null;
      return FormedWord(letters.toString(), sum * factor, sr, sc, acr);
    }

    final main = wordThrough(tiles.first.row, tiles.first.col, across);
    if (main != null) words.add(main);
    for (final t in tiles) {
      final cross = wordThrough(t.row, t.col, !across);
      if (cross != null) words.add(cross);
    }
    if (words.isEmpty) return const PlacementCheck.error(PlacementError.firstTooShort);
    if (checkWords && check == WordCheck.dictionary) {
      final allow = _allowOf(move);
      if (allow == null) return const PlacementCheck.error(PlacementError.malformed);
      final unknown = {for (final w in words) if (!validator!.isWord(w.word)) w.word};
      // Every unknown word must be allowed, and only unknown words may be.
      if (!allow.every(unknown.contains)) return const PlacementCheck.error(PlacementError.malformed);
      if (!unknown.every(allow.contains)) return const PlacementCheck.error(PlacementError.unknownWord);
    } else if (move.containsKey('allow') && check != WordCheck.dictionary) {
      return const PlacementCheck.error(PlacementError.malformed);
    }
    final bingo = tiles.length == rackSize;
    final score = words.fold(0, (a, w) => a + w.score) + (bingo ? bingoBonus : 0);
    return PlacementCheck(tiles, words, score, bingo, swaps: swaps);
  }

  /// The `allow` list of a placement (empty when absent); null if malformed
  /// (not a non-empty list of distinct strings).
  Set<String>? _allowOf(Map<String, dynamic> move) {
    if (!move.containsKey('allow')) return const {};
    final raw = move['allow'];
    if (raw is! List || raw.isEmpty || raw.any((w) => w is! String)) return null;
    final set = raw.cast<String>().toSet();
    return set.length == raw.length ? set : null;
  }

  /// The words of the placement [move] that the word list does not know
  /// (dictionary mode; empty otherwise, or when the placement does not fit),
  /// in board order without repeats. The UI asks this at "Legen" and lets
  /// the players take the tiles back or allow the words (`allow`).
  List<String> unknownWords(Map<String, dynamic> move) {
    final v = validator;
    if (check != WordCheck.dictionary || v == null) return const [];
    final c = checkPlacement(
        {'action': 'place', 'tiles': move['tiles'], if (move.containsKey('swaps')) 'swaps': move['swaps']},
        checkWords: false);
    if (!c.ok) return const [];
    final out = <String>[];
    for (final w in c.words) {
      if (!v.isWord(w.word) && !out.contains(w.word)) out.add(w.word);
    }
    return out;
  }

  bool _filled(int r, int c) => r >= 0 && r < size && c >= 0 && c < size && _board[r * size + c] != null;

  // --- moves ---

  /// With 3–4 seats a resign names a seat and lets the game go on (see the
  /// library docs); with two seats it is the common resign of [Game].
  @override
  GameEvent? applyMove(Map<String, dynamic> move) {
    if (playerCount == 2 || move['action'] != 'resign') return super.applyMove(move);
    return _resignSeat(move);
  }

  /// The resign move for [seat] in a game with 3–4 seats.
  static Map<String, dynamic> resignSeatMove(int seat) => {'action': 'resign', 'seat': seat};

  GameEvent? _resignSeat(Map<String, dynamic> move) {
    final seat = move['seat'];
    if (isOver || move.length != 2 || seat is! int || seat < 0 || seat >= playerCount || isSeatOut(seat)) return null;
    _outOrder.add(seat);
    // The rack goes back into the bag at random places (as an exchange).
    for (final t in _racks[seat]) {
      _bag.insert(_rng.nextInt(_bag.length + 1), t);
    }
    _racks[seat].clear();
    final r = _request;
    if (r != null && r.seat == seat) _request = null;
    final o = _open;
    if (o != null && (o.seat == seat || _seat == seat)) {
      // The placement stands: its placer left, or the seat that could
      // challenge it did.
      _open = null;
      if (_endPending) {
        _endPending = false;
        if (o.seat != seat) _finishOut(o.seat);
      }
    }
    if (_seat == seat) {
      _declined.clear();
      _seat = _next(seat);
    }
    _turns.add(WordTilesTurn(seat, 'resign'));
    _history.add(Map.unmodifiable(move));
    if (!_over && activeSeats.length == 1) {
      _endCode = GameEndReason.commonResigned;
      _over = true;
      _open = null;
      _request = null;
    }
    return _event({'action': 'resign', 'seat': seat});
  }

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) {
    final action = move['action'];
    // An open request waits for its answer (a resign is handled by Game).
    if (_request != null && action != acceptAllow && action != declineAllow) return null;
    final GameEvent? e = switch (action) {
      requestAllow => _requestAllow(move),
      acceptAllow => _acceptAllow(move),
      declineAllow => _declineAllow(move),
      'place' => _place(move),
      'exchange' => _exchange(move),
      'pass' => _pass(move),
      'challenge' => _challenge(move),
      'accept' => _accept(move),
      _ => null,
    };
    if (e != null) _history.add(Map.unmodifiable(move));
    return e;
  }

  GameEvent? _place(Map<String, dynamic> move) {
    // `allow` only through requestAllow / acceptAllow (rules 3).
    if (move.length != (move.containsKey('swaps') ? 3 : 2) || move.containsKey('allow')) return null;
    final c = checkPlacement(move);
    if (!c.ok) return null;
    return _lay(c, const []);
  }

  /// Puts the checked placement [c] on the board for the player to move;
  /// [allowed]: the words let stand by agreement.
  GameEvent _lay(PlacementCheck c, List<String> allowed) {
    _declined.clear();
    final seat = _seat;
    final rackBefore = List<String>.of(_racks[seat]);
    final scorelessBefore = _scoreless;
    for (final s in c.swaps) {
      _board[s.row * size + s.col] = BoardTile(s.tile);
      _racks[seat]
        ..remove(s.tile)
        ..add(TileSet.blank);
    }
    for (final t in c.tiles) {
      _board[t.row * size + t.col] = BoardTile(t.letter, blank: t.isBlank);
      _racks[seat].remove(t.tile);
    }
    _scores[seat] += c.score;
    final drawn = _draw(seat, rackSize - _racks[seat].length);
    _scoreless = c.score == 0 ? _scoreless + 1 : 0;
    final words = [for (final w in c.words) w.word];
    _turns.add(WordTilesTurn(seat, 'place',
        words: words, score: c.score, count: c.tiles.length, allowed: allowed, swaps: c.swaps.length));
    _open = check == WordCheck.challenge
        ? _OpenPlacement(
            seat, c.tiles, words, c.score, rackBefore, drawn, scorelessBefore, _turns.length - 1, c.swaps)
        : null;
    _seat = _next(seat);
    final out = _racks[seat].isEmpty && _bag.isEmpty;
    if (out) {
      if (_open != null) {
        _endPending = true; // the next seat may still challenge
      } else {
        _finishOut(seat);
      }
    } else {
      _checkScoreless();
    }
    return _event({
      'action': 'place',
      'seat': seat,
      'words': [for (final w in c.words) w.toJson()],
      'score': c.score,
      'bingo': c.bingo,
      'drew': drawn,
      if (allowed.isNotEmpty) 'allowed': allowed,
      if (c.swaps.isNotEmpty) 'swaps': [for (final s in c.swaps) s.toJson()],
    });
  }

  GameEvent? _exchange(Map<String, dynamic> move) {
    final raw = move['tiles'];
    if (move.length != 2 || raw is! List || raw.isEmpty || raw.length > rackSize || !canExchange || _endPending) {
      return null;
    }
    final rack = List<String>.of(_racks[_seat]);
    for (final t in raw) {
      if (t is! String || !rack.remove(t)) return null;
    }
    _closeChallenge();
    _declined.clear();
    final seat = _seat;
    _racks[seat]
      ..clear()
      ..addAll(rack);
    _draw(seat, raw.length);
    // The returned tiles go into the bag at random places.
    for (final t in raw.cast<String>()) {
      _bag.insert(_rng.nextInt(_bag.length + 1), t);
    }
    _turns.add(WordTilesTurn(seat, 'exchange', count: raw.length));
    _scoreless++;
    _seat = _next(seat);
    _checkScoreless();
    return _event({'action': 'exchange', 'seat': seat, 'count': raw.length});
  }

  GameEvent? _pass(Map<String, dynamic> move) {
    if (move.length != 1 || _endPending) return null;
    _closeChallenge();
    _declined.clear();
    final seat = _seat;
    _turns.add(WordTilesTurn(seat, 'pass'));
    _scoreless++;
    _seat = _next(seat);
    _checkScoreless();
    return _event({'action': 'pass', 'seat': seat});
  }

  GameEvent? _accept(Map<String, dynamic> move) {
    if (move.length != 1 || !canChallenge) return null;
    final o = _open!;
    _turns.add(WordTilesTurn(_seat, 'accept'));
    _closeChallenge();
    if (_endPending) {
      _endPending = false;
      _finishOut(o.seat);
    }
    return _event({'action': 'accept', 'seat': _seat});
  }

  GameEvent? _challenge(Map<String, dynamic> move) {
    if (move.length != 1 || !canChallenge) return null;
    final o = _open!;
    final challenger = _seat;
    final v = validator;
    final invalid = v == null ? o.words : [for (final w in o.words) if (!v.isWord(w)) w];
    final success = invalid.isNotEmpty;
    _turns.add(WordTilesTurn(challenger, 'challenge', words: invalid, withdrawn: success));
    _open = null;
    if (success) {
      // Withdraw: tiles off the board, the drawn tiles back on top of the
      // bag (same order), rack and score as before.
      for (final t in o.tiles) {
        _board[t.row * size + t.col] = null;
      }
      // Swapped blanks go back onto their squares (the rack is restored).
      for (final s in o.swaps) {
        _board[s.row * size + s.col] = BoardTile(s.tile, blank: true);
      }
      final rack = _racks[o.seat];
      final drawn = rack.sublist(rack.length - o.drawn);
      _bag.addAll(drawn.reversed);
      rack
        ..clear()
        ..addAll(o.rackBefore);
      _scores[o.seat] -= o.score;
      _turns[o.turnIndex] = _turns[o.turnIndex].copyWith(withdrawn: true);
      _scoreless = o.scorelessBefore + 1;
      _endPending = false;
    } else {
      // The words stand; the challenger loses the turn.
      _scoreless++;
      _seat = _next(challenger);
      if (_endPending) {
        _endPending = false;
        _finishOut(o.seat);
      }
    }
    if (!_over) _checkScoreless();
    return _event({
      'action': 'challenge',
      'seat': challenger,
      'placer': o.seat,
      'withdrawn': success,
      'words': invalid,
      'score': o.score,
    });
  }

  // --- "Trotzdem zulassen" over two devices (KLD-094 step 6) ---

  /// The request / answer moves (see the library docs).
  static const String requestAllow = 'requestAllow', acceptAllow = 'acceptAllow', declineAllow = 'declineAllow';

  /// [player] asks to let the placement [tiles] stand although the list
  /// lacks the words [allow].
  static Map<String, dynamic> requestAllowMove(Player player, List<PlacedTile> tiles, List<String> allow,
          {List<JokerSwap> swaps = const []}) =>
      {
        'action': requestAllow,
        'player': player.name,
        'tiles': [for (final t in tiles) t.toJson()],
        'allow': allow,
        if (swaps.isNotEmpty) 'swaps': [for (final s in swaps) s.toJson()],
      };

  /// [player] agrees to the other player's open request.
  static Map<String, dynamic> acceptAllowMove(Player player) => {'action': acceptAllow, 'player': player.name};

  /// [player] declines the other player's open request.
  static Map<String, dynamic> declineAllowMove(Player player) => {'action': declineAllow, 'player': player.name};

  /// The player a request / answer move names, else null.
  static Player? allowPlayerOf(Map<String, dynamic> move) {
    final a = move['action'];
    if (a != requestAllow && a != acceptAllow && a != declineAllow) return null;
    return playerOrNull(move['player']);
  }

  /// The seat a request / answer move names (`player` with two seats,
  /// `seat` with 3–4), else null.
  int? _allowSeatOf(Map<String, dynamic> move) {
    final a = move['action'];
    if (a != requestAllow && a != acceptAllow && a != declineAllow) return null;
    if (playerCount == 2) return allowPlayerOf(move)?.index;
    final s = move['seat'];
    return s is int && s >= 0 && s < playerCount ? s : null;
  }

  /// [requestAllowMove] for [seat] in this game: names the player with two
  /// seats, the seat with 3–4.
  Map<String, dynamic> requestAllowMoveFor(int seat, List<PlacedTile> tiles, List<String> allow,
          {List<JokerSwap> swaps = const []}) =>
      playerCount == 2
          ? requestAllowMove(Player.values[seat], tiles, allow, swaps: swaps)
          : {
              'action': requestAllow,
              'seat': seat,
              'tiles': [for (final t in tiles) t.toJson()],
              'allow': allow,
              if (swaps.isNotEmpty) 'swaps': [for (final s in swaps) s.toJson()],
            };

  /// [acceptAllowMove] for [seat] in this game (see [requestAllowMoveFor]).
  Map<String, dynamic> acceptAllowMoveFor(int seat) =>
      playerCount == 2 ? acceptAllowMove(Player.values[seat]) : {'action': acceptAllow, 'seat': seat};

  /// [declineAllowMove] for [seat] in this game (see [requestAllowMoveFor]).
  Map<String, dynamic> declineAllowMoveFor(int seat) =>
      playerCount == 2 ? declineAllowMove(Player.values[seat]) : {'action': declineAllow, 'seat': seat};

  /// The request moves name their player (an answer comes from the player
  /// not to move); everything else as [Game.playerOf].
  @override
  Player playerOf(Map<String, dynamic> move) => allowPlayerOf(move) ?? super.playerOf(move);

  /// The open request: the placer's seat, the tiles, the words to allow, all
  /// formed words, the score it would make and its "Joker tauschen" swaps;
  /// null if none is open.
  ({int seat, List<PlacedTile> tiles, List<String> allow, List<String> words, int score, List<JokerSwap> swaps})?
      get allowRequest {
    final r = _request;
    if (r == null || isOver) return null;
    return (seat: r.seat, tiles: r.tiles, allow: r.allow, words: r.words, score: r.score, swaps: r.swaps);
  }

  /// The seat that answers an open request: the next one.
  int? get allowRequestAnswerer {
    final r = _request;
    return r == null || isOver ? null : _next(r.seat);
  }

  /// Whether the player to move may ask to allow [words] now: dictionary
  /// mode, no open request, and not declined already in this turn.
  bool canRequestAllow(List<String> words) {
    if (isOver || check != WordCheck.dictionary || _request != null || words.isEmpty) return false;
    final key = [...words]..sort();
    return !_declined.any((d) => _sameWords(d, key));
  }

  static bool _sameWords(List<String> a, List<String> b) =>
      a.length == b.length && Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);

  GameEvent? _requestAllow(Map<String, dynamic> move) {
    final p = _allowSeatOf(move);
    final hasSwaps = move.containsKey('swaps');
    if (move.length != (hasSwaps ? 5 : 4) || p == null || p != _seat || check != WordCheck.dictionary) return null;
    final raw = move['allow'];
    if (raw is! List || raw.any((w) => w is! String)) return null;
    final allow = raw.cast<String>().toList();
    if (!canRequestAllow(allow)) return null;
    final c = checkPlacement(
        {'action': 'place', 'tiles': move['tiles'], 'allow': allow, if (hasSwaps) 'swaps': move['swaps']});
    if (!c.ok) return null;
    _request = _AllowRequest(_seat, c.tiles, allow, [for (final w in c.words) w.word], c.score, c.swaps);
    return _event({
      'action': requestAllow,
      'seat': _seat,
      'words': [for (final w in c.words) w.toJson()],
      'allow': allow,
      'score': c.score,
    });
  }

  GameEvent? _acceptAllow(Map<String, dynamic> move) {
    final p = _allowSeatOf(move);
    final r = _request;
    if (move.length != 2 || p == null || r == null || p != _next(r.seat)) return null;
    _request = null;
    final c = checkPlacement(placeMove(r.tiles, allow: r.allow, swaps: r.swaps));
    if (!c.ok) {
      _request = r; // cannot happen: nothing changed since the request
      return null;
    }
    final e = _lay(c, r.allow);
    return GameEvent(
        winner: e.winner, draw: e.draw, payload: {...e.payload as Map<String, dynamic>, 'agreed': p});
  }

  GameEvent? _declineAllow(Map<String, dynamic> move) {
    final p = _allowSeatOf(move);
    final r = _request;
    if (move.length != 2 || p == null || r == null || p != _next(r.seat)) return null;
    _request = null;
    _declined.add([...r.allow]..sort());
    return _event({'action': declineAllow, 'seat': p, 'placer': r.seat, 'allow': r.allow});
  }

  GameEvent _event(Map<String, dynamic> payload) {
    if (!_over) return GameEvent(payload: payload);
    final r = playResult;
    return GameEvent(winner: r.winner, draw: r.draw, payload: payload);
  }

  void _closeChallenge() => _open = null;

  /// Draws up to [n] tiles for [seat]; returns how many.
  int _draw(int seat, int n) {
    var k = 0;
    while (k < n && _bag.isNotEmpty) {
      _racks[seat].add(_bag.removeLast());
      k++;
    }
    return k;
  }

  int _rackValue(int seat) => _racks[seat].fold(0, (a, t) => a + tileSet.pointsOf(t));

  void _finishOut(int seat) {
    var total = 0;
    for (var s = 0; s < playerCount && rackPenalty; s++) {
      if (s == seat) continue;
      final v = _rackValue(s);
      _penalties[s] = -v;
      _scores[s] -= v;
      total += v;
    }
    _penalties[seat] = total;
    _scores[seat] += total;
    _outSeat = seat;
    _endCode = GameEndReason.wordtilesPlayedOut;
    _over = true;
    _open = null;
  }

  void _checkScoreless() {
    if (_over || _scoreless < scorelessLimit) return;
    for (var s = 0; s < playerCount && rackPenalty; s++) {
      final v = _rackValue(s);
      _penalties[s] = -v;
      _scores[s] -= v;
    }
    _endCode = GameEndReason.wordtilesScoreless;
    _over = true;
    _open = null;
  }

  // --- moves for players and tests ---

  /// A move map for [tiles].
  /// [swaps]: "Joker tauschen" before laying (only with [jokerSwap]).
  static Map<String, dynamic> placeMove(List<PlacedTile> tiles,
          {List<String> allow = const [], List<JokerSwap> swaps = const []}) =>
      {
        'action': 'place',
        'tiles': [for (final t in tiles) t.toJson()],
        if (allow.isNotEmpty) 'allow': allow,
        if (swaps.isNotEmpty) 'swaps': [for (final s in swaps) s.toJson()],
      };

  /// A sample of legal moves for the seat to move, in a fixed order (not
  /// every placement: that set is huge): `challenge` / `accept` when open;
  /// the opening two-tile placements through the centre, or every legal
  /// one-tile placement next to the board; exchanging the whole rack;
  /// `pass`. Enough for random play, demos and the shared contract tests.
  List<Map<String, dynamic>> get legalMoves {
    if (isOver) return const [];
    final r = _request;
    if (r != null) {
      final to = _next(r.seat);
      return [acceptAllowMoveFor(to), declineAllowMoveFor(to)];
    }
    final out = <Map<String, dynamic>>[];
    if (canChallenge) {
      out
        ..add({'action': 'challenge'})
        ..add({'action': 'accept'});
    }
    if (_endPending) return out;
    final rack = _racks[_seat];
    final distinct = rack.toSet().toList()..sort();
    String letterFor(String t) => t == TileSet.blank ? _commonest : t;
    PlacedTile tile(int r, int c, String t) => PlacedTile(r, c, t, t == TileSet.blank ? letterFor(t) : null);
    void tryAdd(List<PlacedTile> tiles) {
      final m = placeMove(tiles);
      if (checkPlacement(m).ok) out.add(m);
    }

    if (boardEmpty) {
      for (final across in [true, false]) {
        for (final start in [centre - 1, centre]) {
          for (final x in distinct) {
            for (final y in distinct) {
              if (x == y && rack.where((t) => t == x).length < 2) continue;
              final r1 = across ? centre : start, c1 = across ? start : centre;
              tryAdd([tile(r1, c1, x), tile(across ? r1 : r1 + 1, across ? c1 + 1 : c1, y)]);
            }
          }
        }
      }
    } else {
      for (var i = 0; i < size * size; i++) {
        final r = i ~/ size, c = i % size;
        if (_board[i] != null) continue;
        if (!(_filled(r - 1, c) || _filled(r + 1, c) || _filled(r, c - 1) || _filled(r, c + 1))) continue;
        for (final t in distinct) {
          tryAdd([tile(r, c, t)]);
        }
      }
    }
    if (canExchange && rack.isNotEmpty) out.add({'action': 'exchange', 'tiles': List.of(rack)});
    out.add({'action': 'pass'});
    return out;
  }

  /// The most frequent letter of [tileSet] (what a blank stands for in
  /// [legalMoves]).
  String get _commonest =>
      tileSet.counts.entries.reduce((a, b) => b.value > a.value || (b.value == a.value && b.key.compareTo(a.key) < 0) ? b : a).key;

  // --- views (KLD-064) ---

  /// What [viewer] may know, as JSON: the board, scores, rack sizes, bag
  /// size, the turn log and the viewer's own rack. Never another rack, the
  /// bag order or the seed.
  Map<String, dynamic> viewJson(Player viewer) => seatViewJson(seatOf(viewer));

  /// [viewJson] for any seat (KLD-088): what [v] may know. With two seats
  /// exactly the [viewJson] of its [Player]; with 3–4 seats it also holds
  /// `viewerSeat` (and `viewer` only for seats 0 and 1) and `out`, the seats
  /// that resigned.
  Map<String, dynamic> seatViewJson(int v) {
    if (v < 0 || v >= playerCount) throw RangeError.range(v, 0, playerCount - 1, 'seat');
    final o = _open;
    return {
      if (v < 2) 'viewer': Player.values[v].name,
      if (playerCount > 2) 'viewerSeat': v,
      'tileSet': tileSet.id,
      'players': playerCount,
      'check': check.name,
      'scorelessLimit': scorelessLimit,
      if (jokerSwap) 'jokerSwap': true,
      if (!rackPenalty) 'rackPenalty': false,
      'board': [
        for (var r = 0; r < size; r++) [for (var c = 0; c < size; c++) _board[r * size + c]?.toString() ?? '.'].join(),
      ],
      'rack': List.of(_racks[v]),
      'racks': [for (final r in _racks) r.length],
      'bag': _bag.length,
      'scores': List.of(_scores),
      'penalties': List.of(_penalties),
      'seat': _seat,
      'scoreless': _scoreless,
      if (o != null)
        'open': {
          'seat': o.seat,
          'tiles': [for (final t in o.tiles) t.toJson()],
          'words': o.words,
          'score': o.score,
        },
      if (_endPending) 'endPending': true,
      if (_request case final r?)
        'allowRequest': {
          'seat': r.seat,
          'tiles': [for (final t in r.tiles) t.toJson()],
          'allow': r.allow,
          'words': r.words,
          'score': r.score,
          if (r.swaps.isNotEmpty) 'swaps': [for (final s in r.swaps) s.toJson()],
        },
      if (_declined.isNotEmpty) 'declined': [for (final d in _declined) d],
      'turns': [for (final t in _turns) t.toJson()],
      if (_over) 'end': {'code': _endCode!.code, if (_outSeat != null) 'out': _outSeat},
      if (resignedBy != null) 'resigned': resignedBy!.name,
      if (_outOrder.isNotEmpty) 'out': List.of(_outOrder),
    };
  }
}

/// Redaction for the word tile game: the seed (and with it the bag order)
/// stays secret, racks are in the views only for their owner, and the
/// tiles of another player's exchange are hidden (`{'action': 'exchange',
/// 'count': n}`). Placements are public.
class WordTilesRedaction extends Redaction {
  const WordTilesRedaction();

  @override
  bool get secretSeed => true;

  @override
  Map<String, dynamic> view(Game game, Player viewer) => (game as WordTilesGame).viewJson(viewer);

  @override
  Game fromView(Map<String, dynamic> view) => WordTilesView.fromJson(view);

  @override
  Map<String, dynamic> redactMove(Map<String, dynamic> move, Player mover, Player viewer) {
    final tiles = move['tiles'];
    if (mover == viewer || move['action'] != 'exchange' || tiles is! List) return super.redactMove(move, mover, viewer);
    return {'action': 'exchange', 'count': tiles.length};
  }
}

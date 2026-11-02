import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../ltr.dart';
import '../../shell/game_screen.dart';
import '../../../profile/seen_tips.dart';
import 'wordtiles_bench_coach.dart';
import 'wordtiles_help.dart';
import 'wordtiles_options.dart' show wordTilesOptionsSummary, wordTilesTileNames;
import 'wordtiles_tiles.dart';

/// The interactive word tile board (KLD-094 step 2): the 15 × 15 board with
/// our premium layout, the rack of the player to move, the score bar and the
/// actions.
///
/// * **Laying tiles:** drag a rack tile onto a free square, or tap a rack
///   tile and then a square. A blank asks for its letter first
///   ([BlankLetterDialog]). A tile laid this turn goes back to the rack with
///   a tap (or a long-press drag to another square or back to the rack).
///   The line under the board previews the words and the score
///   ([WordTilesGame.checkPlacement]) or says why the tiles do not fit;
///   "Legen" plays them (a refused placement shows the reason in red).
/// * **Recall / shuffle / zoom:** take all tiles of this turn back, shuffle
///   the rack, zoom the board. On a phone (squares smaller than
///   [autoZoomBelow]) the board zooms in on the first tile laid and back
///   out after the move; pinch-zoom and panning work any time.
/// * **Swap and pass:** "Tauschen" turns the rack into a picker (needs at
///   least [WordTilesGame.rackSize] tiles in the bag); "Passen" passes after
///   a light confirmation that counts the scoreless turns (KLD-094 step 5).
/// * **Challenge mode** (no word list): after another player's placement the
///   player to move sees it ringed on the board plus "Anzweifeln" /
///   "Annehmen" (a placement, swap or pass accepts it too). The challenger's
///   call is final (the confirmation says so).
/// * **Word list** ("Wörterbuch prüfen", KLD-094 step 4,
///   [WordCheck.dictionary]): nothing tells whether a word is in the list
///   before "Legen" (no hint, no ✓/✗: that would be an indirect dictionary).
///   At "Legen" every formed word is looked up; unknown ones open a notice
///   (`wordtiles-unknown`) with "Zurücknehmen" (tiles back to the rack, the
///   turn goes on) and "Trotzdem zulassen" (the other player agrees: a
///   `requestAllow` move, answered by `acceptAllow` / `declineAllow`; in
///   hot-seat both go in at once, over the network (KLD-094 step 6) the
///   other device shows `wordtiles-allow-dialog` while the placer waits).
///   The history says "zugelassen: …". No challenges then.
/// * **Bänkchen** (the bench, KLD-094 step 4): [benchRows] private practice
///   rows of [benchSlots] slots below the actions (KLD-094 step 8). Open from
///   the start where it fits without making the board smaller (large phones,
///   landscape with room; [benchOpenFits]), closed otherwise ("Bänkchen ▸");
///   the player's own open / close choice holds for the rest of the game.
///   The first time it is visible on a player's turn (hot-seat: after the
///   handover cover), a short explanation ([showBenchCoach], once per
///   device). Drag rack tiles in, move them between slots, drag them
///   back to the rack or straight onto the board (or tap a tile, then a
///   slot). Each row shows the base score of its words (letter points; the
///   premium squares count only on the board) and nothing else. The tiles are
///   still rack tiles: the engine's rack is unchanged, the bench is an
///   arrangement kept per player across turns and the handover cover (which
///   hides it like the rack). Open, a bench tile leaves a gap in the rack;
///   closed, its tiles are back in the rack (nothing is ever out of sight).
///   On a small phone ([benchOverlayMargin], [benchMinBoardShare]) the
///   collapsed bench is a button in the score row and the open bench lies
///   over the lower part of the board (`wordtiles-bench-overlay`), so the
///   board keeps its size.
/// * **Layout** (KLD-094 step 8b): portrait stacks the score row, the board
///   (as wide as the screen), the rack and actions and the open bench with
///   small fixed gaps; the space left over is at the very bottom, and the
///   board only shrinks when the rest does not fit (`wordtiles-board-area`).
///   Landscape (from 480 px wide): board left, a scrolling panel right.
/// * **Score bar** (KLD-094 step 5): token and score per player (the names
///   are in the shell's legend; the semantics label keeps them), the bag,
///   and "So geht's" ([showWordTilesHelp]).
/// * Hot-seat: the shell's handover cover hides the rack between turns
///   (`GameSpec.hiddenInformation`); the board resets its pending tiles when
///   the turn changes.
///
/// The board itself is always left-to-right ([LtrBoard]): the letters are
/// Latin and the columns are the engine's.
///
/// Keys for tests: `wordtiles-sq-<row>-<col>`, `wordtiles-rack`,
/// `wordtiles-rack-<rack index>`, `wordtiles-play`, `wordtiles-recall`,
/// `wordtiles-shuffle`, `wordtiles-zoom`, `wordtiles-exchange`,
/// `wordtiles-exchange-confirm`, `wordtiles-exchange-cancel`, `wordtiles-pass`,
/// `wordtiles-challenge`, `wordtiles-accept`, `wordtiles-challenge-confirm`,
/// `wordtiles-preview`, `wordtiles-error`, `wordtiles-last-turn`,
/// `wordtiles-open`, `wordtiles-score-<seat>`, `wordtiles-penalty-<seat>`,
/// `wordtiles-bag`, `wordtiles-viewer`; the blank picker's
/// `wordtiles-blank-<letter>`; the bench's `wordtiles-bench`,
/// `wordtiles-bench-toggle`, `wordtiles-bench-clear`,
/// `wordtiles-bench-<row>-<slot>`, `wordtiles-bench-score-<row>` (a tile on
/// the bench keeps its `wordtiles-rack-<rack index>`, its place in the rack
/// `wordtiles-rack-gap-<rack index>`); the coach `wordtiles-coach`; the unknown-word
/// notice's `wordtiles-unknown`, `wordtiles-unknown-withdraw`,
/// `wordtiles-unknown-allow`; step 5: `wordtiles-help`,
/// `wordtiles-bench-overlay`, `wordtiles-pass-dialog`,
/// `wordtiles-pass-confirm`, `wordtiles-pass-cancel`.
class WordTilesBoard extends StatefulWidget {
  final GameController controller;

  const WordTilesBoard({super.key, required this.controller});

  /// Below this square size (logical pixels, unzoomed) the board zooms in
  /// on the first tile laid.
  static const double autoZoomBelow = 30;

  /// Practice rows of the bench and slots per row.
  static const int benchRows = 2;
  static const int benchSlots = 9;

  /// The largest rack tile (logical pixels). Bench tiles grow up to this
  /// size where there is room (tablets, the landscape panel, browsers); on
  /// a phone they stay smaller so both rows fit without scrolling (KLD-094
  /// step 8e).
  static const double tileMax = 54;

  /// The bench may use up to this width (the rack keeps 420).
  static const double benchMaxWidth = 600;

  /// The height around the board on a phone with the bench open: score
  /// row, last-turn line, preview line, rack, actions, the open bench and
  /// their gaps (about 320–340 px with the app fonts).
  /// On a narrow screen whose board area is less high than this plus
  /// [benchMinBoardShare] of its width, the open bench lies over the board
  /// (bottom sheet style); otherwise it goes below the actions and the
  /// board gets a little smaller where needed (KLD-094 step 8b).
  static const double benchOverlayMargin = 325;

  /// How far the board may shrink (share of its full width) for the open
  /// bench below the actions before the bench becomes the overlay.
  static const double benchMinBoardShare = 0.85;

  /// Only phones (narrower than this) get the bench overlay; a tablet in
  /// portrait shrinks its board a little instead (KLD-094 step 8b).
  static const double benchOverlayMaxWidth = 600;

  /// The height of the landscape panel (score row, info, rack, actions and
  /// the open bench) without scrolling.
  static const double benchOpenPanelHeight = 380;

  /// The bench starts open when it fits without making the board smaller
  /// (KLD-094 step 8c): on a phone in portrait the board area must be at
  /// least its width plus [benchOverlayMargin] high (430 × 932, 412 × 915,
  /// 402 × 874; not 390 × 844 or small phones, whose board would shrink), in
  /// landscape the panel must show it without scrolling
  /// ([benchOpenPanelHeight]). A tablet in portrait
  /// ([benchOverlayMaxWidth] and wider) always starts open: its board gets
  /// about 10 % smaller, and the empty slots invite to use the bench
  /// (maintainer). [box] is the board widget's constraints.
  static bool benchOpenFits(BoxConstraints box, {required bool wide}) => wide
      ? box.maxHeight >= benchOpenPanelHeight
      : box.maxWidth >= benchOverlayMaxWidth || box.maxHeight >= box.maxWidth + benchOverlayMargin;

  @override
  State<WordTilesBoard> createState() => _WordTilesBoardState();
}

/// A rack tile laid on the board this turn.
class _Pending {
  final int rackIndex;
  final String tile;
  final String letter;
  const _Pending(this.rackIndex, this.tile, this.letter);
}

/// What is dragged: a rack tile, a pending tile from [square], or a bench
/// tile from [slot].
class _Drag {
  final int rackIndex;
  final int? square;
  final (int, int)? slot;
  const _Drag(this.rackIndex, [this.square, this.slot]);
}

const int _n = WordTilesGame.size;

class _WordTilesBoardState extends State<WordTilesBoard> with SingleTickerProviderStateMixin {
  final Map<int, _Pending> _pending = {};
  int? _selected;
  List<int> _order = [];
  bool _exchanging = false;
  final Set<int> _swap = {};

  /// "Legen" was tapped on a placement that does not fit: the reason shows
  /// in the error colour until the tiles change.
  bool _tried = false;

  /// A one-off notice in the preview line (e.g. why swapping is not possible).
  String? _notice;

  late GameTransport _transport;
  int _seen = 0;
  bool _busy = false;

  /// The bench of the seat on screen: a rack index per slot.
  List<List<int?>> _bench = _emptyBench();

  /// Every seat's bench as letters (tiles), kept across turns, the cover
  /// and undo; matched to the rack again at each turn ([_loadBench]).
  final Map<int, List<List<String?>>> _benchSaved = {};

  /// Bench open or collapsed by the player's choice (kept for the rest of
  /// the game, not per device); null = by screen size
  /// ([WordTilesBoard.benchOpenFits]).
  bool? _benchOpen;

  /// The bench as last laid out (open or overlay) and a coach check waiting
  /// for the end of the next frame ([_maybeBenchCoach]).
  bool _benchVisible = false;
  bool _coachPending = false;

  static List<List<int?>> _emptyBench() =>
      List.generate(WordTilesBoard.benchRows, (_) => List<int?>.filled(WordTilesBoard.benchSlots, null));

  final TransformationController _zoom = TransformationController();
  late final AnimationController _zoomAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 260))..addListener(_onZoomTick);
  Matrix4Tween? _zoomTween;
  double _boardSize = 0;

  GameController get controller => widget.controller;
  WordTilesGame get game => controller.game as WordTilesGame;

  /// The seat whose rack this device shows: the local player on a network
  /// device, the player to move in hot-seat.
  int get _seat {
    final local = controller.transport.localPlayers;
    return local.length == 1 ? WordTilesGame.seatOf(local.single) : game.currentSeat;
  }

  /// One player per device (KLD-094 step 6), not hot-seat.
  bool get _network => controller.transport.localPlayers.length == 1;

  List<String> get _rack => game.rackOf(_seat);

  /// While a "Trotzdem zulassen" request is open nobody lays tiles: the
  /// placer waits for the answer.
  bool get _myTurn => controller.canAct && game.currentSeat == _seat && !_busy && game.allowRequest == null;

  /// The open "accept the word?" dialog and the log index of the request it
  /// answers (KLD-094 step 6, like the chess draw offer).
  ModalRoute<Object?>? _allowRoute;
  int? _allowShownFor;

  /// Tiles may be laid (not while only challenge / accept are allowed).
  bool get _canLay => _myTurn && !game.endPending && !_exchanging;

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    _seen = controller.moves.length;
    _resetTurn();
    controller.addListener(_onChange);
    _syncAllow(); // e.g. a guest that rejoins while a request is open
  }

  @override
  void didUpdateWidget(WordTilesBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _transport = controller.transport;
      _seen = controller.moves.length;
      _benchSaved.clear();
      _benchOpen = null;
      _resetTurn();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    _zoomAnim.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {
      if (!identical(_transport, controller.transport) || controller.moves.length != _seen) {
        if (!identical(_transport, controller.transport)) {
          // A new game: empty benches, open or closed by screen size again.
          _benchSaved.clear();
          _benchOpen = null;
        }
        _transport = controller.transport;
        _seen = controller.moves.length;
        _resetTurn();
      }
    });
    _syncAllow();
  }

  // ------------------------------------------------- "Trotzdem zulassen"

  /// The local player who answers the open request, or null (none open, or
  /// the other device answers it).
  Player? get _allowTo {
    final seat = game.allowRequestAnswerer;
    final to = seat == null ? null : WordTilesGame.playerOfSeat(seat);
    return to != null && controller.transport.localPlayers.contains(to) ? to : null;
  }

  int get _lastRequestIndex => controller.moves.lastIndexWhere((m) => m.move['action'] == WordTilesGame.requestAllow);

  /// Shows the answer dialog for a new open request to a local player and
  /// closes it when the request is gone (answered, a resign).
  void _syncAllow() {
    final to = _allowTo;
    if (to == null || _hotSeatAgreeing) {
      _allowShownFor = null;
      final r = _allowRoute;
      _allowRoute = null;
      _closeRoute(r);
      return;
    }
    final index = _lastRequestIndex;
    if (_allowShownFor == index) return;
    _allowShownFor = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _allowTo == to && _allowShownFor == index && !_hotSeatAgreeing) _answerAllow(to);
    });
  }

  /// Hot-seat "Trotzdem zulassen": both players agreed at the device, the
  /// request and its acceptance go in one go (no answer dialog in between).
  bool _hotSeatAgreeing = false;

  static void _closeRoute(ModalRoute<Object?>? r) {
    final nav = r?.navigator;
    if (r == null || nav == null || !r.isActive) return;
    if (r.isCurrent) {
      nav.pop();
    } else {
      nav.removeRoute(r);
    }
  }

  String _nameOfSeat(int seat) {
    final p = WordTilesGame.playerOfSeat(seat);
    return p == null ? '${seat + 1}' : playerName(context, p);
  }

  /// "Anna möchte „BAU“ zulassen – einverstanden?" with "Annehmen" /
  /// "Ablehnen".
  Future<void> _answerAllow(Player to) async {
    final request = game.allowRequest;
    if (request == null) return;
    final l10n = AppLocalizations.of(context);
    final who = _nameOfSeat(request.seat);
    final accept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        _allowRoute = ModalRoute.of(ctx);
        return PopScope(
          canPop: false,
          child: AlertDialog(
            key: const Key('wordtiles-allow-dialog'),
            title: Text(l10n.wordtilesAllowTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.wordtilesAllowBody(who, wordList(ctx, request.allow)),
                    key: const Key('wordtiles-allow-body'), style: Theme.of(ctx).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text(l10n.wordtilesPreview(wordList(ctx, request.words), request.score),
                    style: Theme.of(ctx).textTheme.bodyMedium),
              ],
            ),
            actions: [
              TextButton(
                key: const Key('wordtiles-allow-decline'),
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.wordtilesAllowDecline),
              ),
              FilledButton(
                key: const Key('wordtiles-allow-accept'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.wordtilesAllowAccept),
              ),
            ],
          ),
        );
      },
    );
    _allowRoute = null;
    if (accept == null || !mounted || game.allowRequestAnswerer != WordTilesGame.seatOf(to)) return;
    final r = await controller.submit(
        accept ? WordTilesGame.acceptAllowMove(to) : WordTilesGame.declineAllowMove(to));
    // Not delivered (e.g. the connection dropped): ask again while the
    // request is still open.
    if (!r.isAccepted && mounted && game.allowRequestAnswerer == WordTilesGame.seatOf(to)) {
      _allowShownFor = null;
      _syncAllow();
    }
  }

  /// The rack indices of the tiles of the own open request (they lie on the
  /// board while the other player decides).
  Set<int> get _requestedRackTiles {
    final r = game.allowRequest;
    if (r == null || r.seat != _seat) return const {};
    final rack = _rack;
    final bench = _onBench;
    // Tiles off the bench first (the laid ones left it).
    final order = [for (var i = 0; i < rack.length; i++) if (!bench.contains(i)) i, ...bench];
    final used = <int>{};
    for (final t in r.tiles) {
      for (final i in order) {
        if (rack[i] == t.tile && used.add(i)) break;
      }
    }
    return used;
  }

  void _resetTurn() {
    _pending.clear();
    _selected = null;
    _exchanging = false;
    _swap.clear();
    _tried = false;
    _notice = null;
    _busy = false;
    _order = List.generate(_rack.length, (i) => i);
    _loadBench();
    _zoomAnim.stop();
    _zoom.value = Matrix4.identity();
  }

  // ------------------------------------------------------------ bench

  /// Puts the saved bench of the seat on screen back onto its current rack:
  /// each saved tile takes a rack tile with the same letter that is still
  /// free; tiles that left the rack (laid, swapped) drop out.
  void _loadBench() {
    final rack = _rack;
    final used = <int>{};
    final saved = _benchSaved[_seat];
    _bench = _emptyBench();
    if (saved == null) return;
    for (var r = 0; r < _bench.length && r < saved.length; r++) {
      for (var s = 0; s < _bench[r].length && s < saved[r].length; s++) {
        final t = saved[r][s];
        if (t == null) continue;
        for (var i = 0; i < rack.length; i++) {
          if (rack[i] == t && used.add(i)) {
            _bench[r][s] = i;
            break;
          }
        }
      }
    }
    _saveBench();
  }

  void _saveBench() {
    final rack = _rack;
    _benchSaved[_seat] = [
      for (final row in _bench) [for (final i in row) i == null || i >= rack.length ? null : rack[i]],
    ];
  }

  Set<int> get _onBench => {for (final row in _bench) for (final i in row) ?i};

  (int, int)? _slotOf(int rackIndex) {
    for (var r = 0; r < _bench.length; r++) {
      final s = _bench[r].indexOf(rackIndex);
      if (s >= 0) return (r, s);
    }
    return null;
  }

  void _removeFromBench(int rackIndex) {
    final at = _slotOf(rackIndex);
    if (at != null) _bench[at.$1][at.$2] = null;
  }

  /// The bench may change: the player on screen is on turn (hot-seat: the
  /// player behind the cover), not while picking tiles to swap.
  bool get _benchActive => _myTurn && !_exchanging;

  /// Puts [rackIndex] (from the rack, the board or another slot) into
  /// [slot]; a tile already there moves to where the new one came from (a
  /// slot), else back to the rack.
  void _toBench(int rackIndex, (int, int) slot, {int? fromSquare}) {
    if (!_benchActive) return;
    setState(() {
      if (fromSquare != null) _pending.remove(fromSquare);
      final from = _slotOf(rackIndex);
      final occupant = _bench[slot.$1][slot.$2];
      _removeFromBench(rackIndex);
      _bench[slot.$1][slot.$2] = rackIndex;
      if (occupant != null && occupant != rackIndex && from != null) _bench[from.$1][from.$2] = occupant;
      _selected = null;
      _tried = false;
      _notice = null;
      _saveBench();
    });
  }

  void _benchToRack(int rackIndex) {
    setState(() {
      _removeFromBench(rackIndex);
      _saveBench();
    });
  }

  void _clearBench() {
    setState(() {
      _bench = _emptyBench();
      _selected = null;
      _saveBench();
    });
  }

  void _tapSlot((int, int) slot) {
    final occupant = _bench[slot.$1][slot.$2];
    if (occupant != null) {
      _tapRack(occupant);
      return;
    }
    final sel = _selected;
    if (sel != null && !_exchanging) _toBench(sel, slot);
  }

  /// The words of a bench row (runs of 2+ tiles) and their base score:
  /// letter points only (a blank shows "?" and scores 0).
  ({List<String> words, int score}) _benchWords(int row) {
    final rack = _rack;
    final words = <String>[];
    var score = 0;
    final run = <String>[];
    void flush() {
      if (run.length >= 2) {
        words.add(run.map((t) => t == TileSet.blank ? '?' : t).join());
        score += run.fold(0, (a, t) => a + game.tileSet.pointsOf(t));
      }
      run.clear();
    }

    for (final i in _bench[row]) {
      if (i == null || i >= rack.length) {
        flush();
      } else {
        run.add(rack[i]);
      }
    }
    flush();
    return (words: words, score: score);
  }

  // ------------------------------------------------------------ placing

  List<PlacedTile> get _placed => [
        for (final e in _pending.entries) PlacedTile(e.key ~/ _n, e.key % _n, e.value.tile, e.value.tile == TileSet.blank ? e.value.letter : null),
      ];

  bool _free(int sq) => game.tileAt(sq ~/ _n, sq % _n) == null;

  /// Lays rack tile [rackIndex] on [sq] (asking a blank's letter first).
  Future<void> _lay(int sq, int rackIndex, {String? letter}) async {
    if (!_canLay || !_free(sq)) return;
    final tile = _rack[rackIndex];
    var shown = letter ?? tile;
    if (tile == TileSet.blank && letter == null) {
      final seen = _seen;
      final picked = await showDialog<String>(
        context: context,
        builder: (_) => BlankLetterDialog(tileSet: game.tileSet),
      );
      if (!mounted || seen != _seen) return;
      if (picked == null) {
        setState(() => _selected = null);
        return;
      }
      shown = picked;
    }
    final first = _pending.isEmpty;
    setState(() {
      _pending.removeWhere((_, p) => p.rackIndex == rackIndex);
      _pending[sq] = _Pending(rackIndex, tile, shown);
      _removeFromBench(rackIndex);
      _saveBench();
      _selected = null;
      _tried = false;
      _notice = null;
    });
    if (first) _autoZoom(sq);
  }

  void _takeBack(int sq) {
    setState(() {
      _pending.remove(sq);
      _tried = false;
      _notice = null;
    });
  }

  void _recallAll() {
    setState(() {
      _pending.clear();
      _selected = null;
      _tried = false;
      _notice = null;
    });
    _zoomOut();
  }

  void _shuffle() {
    setState(() => _order.shuffle(Random()));
  }

  void _tapSquare(int sq) {
    if (!_canLay) return;
    if (_pending.containsKey(sq)) {
      final sel = _selected;
      if (sel != null) {
        // Swap: the selected tile takes the square.
        _takeBack(sq);
        _lay(sq, sel);
      } else {
        _takeBack(sq);
      }
      return;
    }
    final sel = _selected;
    if (sel != null && _free(sq)) _lay(sq, sel);
  }

  void _tapRack(int rackIndex) {
    if (!_myTurn || game.endPending) return;
    setState(() {
      if (_exchanging) {
        if (!_swap.remove(rackIndex)) _swap.add(rackIndex);
      } else {
        _selected = _selected == rackIndex ? null : rackIndex;
      }
      _notice = null;
    });
  }

  /// A dragged tile lands on [sq]. A tile laid this turn moves with its
  /// letter (a blank keeps the one chosen); onto another such tile the two
  /// swap places (KLD-094 step 8d). A rack or bench tile is laid.
  void _drop(_Drag d, int sq) {
    final from = d.square;
    if (from != null) {
      final p = _pending[from];
      if (p == null || from == sq || !_canLay) return;
      setState(() {
        final there = _pending.remove(sq);
        _pending.remove(from);
        _pending[sq] = p;
        if (there != null) _pending[from] = there;
        _tried = false;
        _notice = null;
      });
    } else {
      _lay(sq, d.rackIndex);
    }
  }

  // ------------------------------------------------------------ moves

  Future<void> _submit(Map<String, dynamic> move) async {
    setState(() => _busy = true);
    final r = await controller.submit(move);
    if (!mounted) return;
    if (!r.isAccepted) setState(() => _busy = false);
  }

  Future<void> _play() async {
    if (_pending.isEmpty || !_canLay) return;
    final placed = _placed;
    final move = WordTilesGame.placeMove(placed);
    if (!game.checkPlacement(move, checkWords: false).ok) {
      setState(() => _tried = true);
      return;
    }
    // KLD-094 step 4: the word list is asked only now, at "Legen".
    final unknown = game.unknownWords(move);
    if (unknown.isEmpty) {
      _submit(move);
      return;
    }
    final seen = _seen;
    final canAsk = game.canRequestAllow(unknown);
    final allow = await _askUnknown(unknown, canAsk: canAsk);
    if (!mounted || seen != _seen) return;
    if (!allow || !canAsk) {
      _recallAll();
      return;
    }
    // KLD-094 step 6: "Trotzdem zulassen" asks the other player. Over the
    // network their device shows the request; in hot-seat both players
    // agreed right here, so the answer follows at once.
    final me = WordTilesGame.playerOfSeat(_seat)!;
    final other = WordTilesGame.playerOfSeat(game.currentSeat == 0 ? 1 : 0)!;
    setState(() => _busy = true);
    _hotSeatAgreeing = !_network;
    try {
      final r = await controller.submit(WordTilesGame.requestAllowMove(me, placed, unknown));
      if (r.isAccepted && !_network && mounted) await controller.submit(WordTilesGame.acceptAllowMove(other));
      if (!r.isAccepted && mounted) setState(() => _busy = false);
    } finally {
      _hotSeatAgreeing = false;
    }
  }

  /// "„XYZ“ steht nicht im Wörterbuch." – "Zurücknehmen" (false) or
  /// "Trotzdem zulassen" (true). Hot-seat: one joint decision, both players
  /// are at the device. Network (KLD-094 step 6): it asks the other player.
  /// [canAsk] false (the other player already declined these words this
  /// turn): only "Zurücknehmen".
  Future<bool> _askUnknown(List<String> words, {bool canAsk = true}) async {
    final l10n = AppLocalizations.of(context);
    final otherSeat = _seat == 0 ? 1 : 0;
    final allow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('wordtiles-unknown'),
        title: Text(l10n.wordtilesUnknownTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.wordtilesUnknownBody(wordList(ctx, words), words.length),
                style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text(!canAsk
                ? l10n.wordtilesUnknownDeclinedBefore(_nameOfSeat(otherSeat))
                : _network
                    ? l10n.wordtilesUnknownAskNet(_nameOfSeat(otherSeat))
                    : l10n.wordtilesUnknownAsk),
          ],
        ),
        actions: [
          if (canAsk)
            TextButton(
              key: const Key('wordtiles-unknown-allow'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.wordtilesUnknownAllow),
            ),
          FilledButton(
            key: const Key('wordtiles-unknown-withdraw'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.wordtilesUnknownWithdraw),
          ),
        ],
      ),
    );
    return allow == true;
  }

  /// "Passen" with a light confirmation (KLD-094 step 5): it ends the turn
  /// and counts towards the scoreless turns that end the game.
  Future<void> _pass() async {
    if (!_canLay) return;
    final l10n = AppLocalizations.of(context);
    final g = game;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('wordtiles-pass-dialog'),
        title: Text(l10n.wordtilesPassTitle),
        content: Text(l10n.wordtilesPassBody(g.scorelessTurns + 1, g.scorelessLimit)),
        actions: [
          TextButton(
            key: const Key('wordtiles-pass-cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.shellCancel),
          ),
          FilledButton(
            key: const Key('wordtiles-pass-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.wordtilesPass),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || !_canLay) return;
    _submit(const {'action': 'pass'});
  }

  void _startExchange() {
    if (!_canLay) return;
    if (!game.canExchange) {
      setState(() => _notice = AppLocalizations.of(context).wordtilesExchangeNotNow(WordTilesGame.rackSize));
      return;
    }
    setState(() {
      _pending.clear();
      _selected = null;
      _exchanging = true;
      _swap.clear();
      _notice = null;
    });
  }

  void _confirmExchange() {
    if (_swap.isEmpty || !_myTurn) return;
    final rack = _rack;
    _submit({
      'action': 'exchange',
      'tiles': [for (final i in _swap) rack[i]],
    });
  }

  Future<void> _challenge() async {
    if (!_myTurn || !game.canChallenge) return;
    final l10n = AppLocalizations.of(context);
    final labels = PlayerLabelsScope.of(context);
    final open = game.challengeable!;
    final placer = WordTilesGame.playerOfSeat(open.seat);
    final who = placer == null ? '${open.seat + 1}' : labels.label(context, l10n, placer);
    final seen = _seen;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('wordtiles-challenge-dialog'),
        title: Text(l10n.wordtilesChallengeTitle),
        content: Text(game.validator == null ? l10n.wordtilesChallengeBodyFree(who) : l10n.wordtilesChallengeBodyDict),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(l10n.shellCancel)),
          FilledButton(
            key: const Key('wordtiles-challenge-confirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.wordtilesChallenge),
          ),
        ],
      ),
    );
    if (ok != true || !mounted || seen != _seen) return;
    _submit(const {'action': 'challenge'});
  }

  void _accept() {
    if (!_myTurn || !game.canChallenge) return;
    _submit(const {'action': 'accept'});
  }

  // ------------------------------------------------------------ zoom

  bool get _zoomed => _zoom.value.getMaxScaleOnAxis() > 1.01;

  void _onZoomTick() {
    final t = _zoomTween;
    if (t != null) _zoom.value = t.evaluate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOut));
  }

  void _animateTo(Matrix4 target) {
    if (reduceMotion(context)) {
      _zoom.value = target;
      setState(() {});
      return;
    }
    _zoomTween = Matrix4Tween(begin: _zoom.value.clone(), end: target);
    _zoomAnim.forward(from: 0).whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  /// Zooms to [scale] with board point [focus] (unzoomed board pixels) as
  /// near the centre as the board edges allow.
  void _zoomTo(Offset focus, double scale) {
    final s = _boardSize;
    if (s <= 0) return;
    final dx = (s / 2 - focus.dx * scale).clamp(s - s * scale, 0.0);
    final dy = (s / 2 - focus.dy * scale).clamp(s - s * scale, 0.0);
    _animateTo(Matrix4.translationValues(dx, dy, 0)..multiply(Matrix4.diagonal3Values(scale, scale, 1)));
  }

  double get _cell => _boardSize / _n;

  Offset _centreOf(Iterable<int> squares) {
    var x = 0.0, y = 0.0, k = 0;
    for (final sq in squares) {
      x += (sq % _n + 0.5) * _cell;
      y += (sq ~/ _n + 0.5) * _cell;
      k++;
    }
    return k == 0 ? Offset(_boardSize / 2, _boardSize / 2) : Offset(x / k, y / k);
  }

  /// A comfortable zoom: squares of about 40 px.
  double get _zoomScale => (40 / max(_cell, 1)).clamp(1.6, 3.0);

  void _autoZoom(int sq) {
    if (_cell >= WordTilesBoard.autoZoomBelow || _zoomed) return;
    _zoomTo(_centreOf([sq]), _zoomScale);
  }

  void _zoomOut() {
    if (_zoomed) _animateTo(Matrix4.identity());
  }

  void _toggleZoom() {
    if (_zoomed) {
      _zoomOut();
      return;
    }
    final focus = _pending.isNotEmpty ? _pending.keys : _lastPlacement();
    _zoomTo(_centreOf(focus), max(_zoomScale, 2));
  }

  /// Squares of the last placement still on the board.
  Set<int> _lastPlacement() {
    for (final m in controller.moves.reversed) {
      final a = m.move['action'];
      if (a == 'challenge' && m.event.payload is Map && (m.event.payload as Map)['withdrawn'] == true) return const {};
      if (a != 'place') continue;
      final tiles = m.move['tiles'];
      if (tiles is! List) return const {};
      final out = <int>{};
      for (final t in tiles) {
        if (t is Map && t['row'] is int && t['col'] is int) out.add((t['row'] as int) * _n + (t['col'] as int));
      }
      return out.where((sq) => !_free(sq)).toSet();
    }
    return const {};
  }

  // ------------------------------------------------------------ build

  void _updateHint(AppLocalizations l10n) {
    final shell = GameScreen.of(context);
    String? hint;
    if (_myTurn) {
      if (game.canChallenge) {
        hint = l10n.wordtilesHintAnswer;
      } else if (_exchanging) {
        hint = l10n.wordtilesHintExchange;
      } else if (_selected != null) {
        hint = l10n.wordtilesHintSelected;
      } else if (_pending.isEmpty) {
        hint = game.boardEmpty ? l10n.wordtilesHintFirst : l10n.wordtilesHintPlace;
      }
    }
    shell.setHint(hint);
    // KLD-094 step 6, network: while a request is open the placer's device
    // says who decides ("Ben entscheidet …"), the other one that it decides.
    ShellStatus? status;
    final request = game.allowRequest;
    final answerer = game.allowRequestAnswerer;
    if (_network && request != null && answerer != null) {
      final to = WordTilesGame.playerOfSeat(answerer)!;
      status = answerer == _seat
          ? ShellStatus(text: l10n.wordtilesAllowYouDecide, player: to)
          : ShellStatus(text: l10n.wordtilesAllowDeciding(_nameOfSeat(answerer)), player: to);
    }
    shell.setStatusOverride(status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _updateHint(l10n);
    return LayoutBuilder(builder: (context, box) {
      // Landscape: board left, panel right. From 480 px wide, so a small
      // phone in landscape (568 × 320) gets it too instead of a board
      // squeezed to nothing above the controls (KLD-094 step 8b).
      final wide = box.maxWidth >= 480 && box.maxWidth > box.maxHeight * 1.15;
      // A small phone (e.g. 375 × 667): the open bench lies over the lower
      // part of the board instead of taking its height (KLD-094 step 5). A
      // tablet in portrait has the room: its board gets a little smaller
      // instead (KLD-094 step 8b).
      final compact = !wide &&
          box.maxWidth < WordTilesBoard.benchOverlayMaxWidth &&
          box.maxHeight < box.maxWidth * WordTilesBoard.benchMinBoardShare + WordTilesBoard.benchOverlayMargin;
      // KLD-094 step 8c: open from the start where it fits without making
      // the board smaller, closed otherwise (the rack and the actions right
      // under the board); the player's choice wins.
      final benchOpen = _benchOpen ?? WordTilesBoard.benchOpenFits(box, wide: wide);
      _benchVisible = benchOpen;
      if (benchOpen) _maybeBenchCoach();
      final benchOverlay = compact && benchOpen;
      final board = _boardView(context);
      // Compact: the collapsed bench is a button in the score row (no row of
      // its own); open, the whole bench is the overlay.
      // The same height open or closed, so the board keeps its size (two
      // players fit one line; more players would need a second line here).
      final scores = SizedBox(
        height: compact ? kMinInteractiveDimension : null,
        child: _scoreBar(context, l10n,
            extra: compact && !benchOpen ? _benchView(context, l10n, box.maxWidth, false) : null),
      );
      final info = _infoLine(context, l10n);
      // KLD-094 step 8: the bench below the actions (rack and actions right
      // under the board, the bench is the optional extra).
      // KLD-117: "Zug zurück" (hot-seat) right under the actions, at the end
      // of the bench line (the actions row is full on a phone; as dense as
      // the bench line). On a small phone, where the bench button is in the
      // score row, just the ↶ icon in the actions row, so the board keeps
      // its size. Nothing in network play.
      const undo = UndoMoveButton(visualDensity: VisualDensity(horizontal: -4, vertical: -4));
      final Widget bench = compact
          ? const SizedBox.shrink()
          : LayoutBuilder(
              builder: (context, benchBox) =>
                  _benchView(context, l10n, min(benchBox.maxWidth, WordTilesBoard.benchMaxWidth), benchOpen, trailing: undo),
            );
      final controls = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _previewLine(context, l10n),
          const SizedBox(height: 4),
          LayoutBuilder(
              builder: (context, rackBox) => _rackView(context, min(rackBox.maxWidth, 420.0), benchShown: benchOpen)),
          const SizedBox(height: 6),
          _actions(context, l10n, undoIcon: compact),
          const SizedBox(height: 6),
          bench,
        ],
      );
      if (wide) {
        final side = min(box.maxHeight, box.maxWidth * 0.6);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.all(8), child: SizedBox.square(dimension: side - 16, child: board)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    scores,
                    const SizedBox(height: 8),
                    info,
                    const SizedBox(height: 16),
                    controls,
                  ],
                ),
              ),
            ),
          ],
        );
      }
      // KLD-094 step 8b: the board right under the score row, the rack and
      // the actions right under the board, the (open) bench right under
      // them; what is left over goes to the very bottom. The board is as
      // wide as the screen and only gets smaller when the rest does not fit
      // below it (a Flexible, not centred in an Expanded: no empty bands
      // above and below the board).
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: scores),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 4), child: info),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Stack(
                key: const Key('wordtiles-board-area'),
                alignment: Alignment.topCenter,
                children: [
                  AspectRatio(aspectRatio: 1, child: board),
                  // Small phone: the open bench lies over the lower part of
                  // the board (KLD-094 step 5), which keeps its size.
                  if (benchOverlay)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        key: const Key('wordtiles-bench-overlay'),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, -2))],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
                          child: LayoutBuilder(
                            builder: (context, b) => _benchView(context, l10n, min(b.maxWidth, WordTilesBoard.benchMaxWidth), true),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(8, 0, 8, 8), child: controls),
        ],
      );
    });
  }

  /// [extra]: the collapsed bench button on a small phone.
  Widget _scoreBar(BuildContext context, AppLocalizations l10n, {Widget? extra}) {
    final theme = Theme.of(context);
    final labels = PlayerLabelsScope.of(context);
    final g = game;
    final penalties = g.rackPenalties;
    // KLD-094 step 5: token and score only; the names are in the shell's
    // legend right above (the semantics label and a tooltip keep them).
    Widget seat(int s) {
      final p = WordTilesGame.playerOfSeat(s);
      final label = p == null ? '${s + 1}' : labels.label(context, l10n, p);
      final on = !g.isOver && g.currentSeat == s;
      final pen = penalties[s];
      return Semantics(
        label:l10n.wordtilesScore(label, g.scoreOf(s)),
        excludeSemantics: true,
        child: Container(
          key: Key('wordtiles-score-$s'),
          padding: const EdgeInsetsDirectional.fromSTEB(4, 2, 10, 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: on ? theme.colorScheme.secondaryContainer : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p != null)
                PlayerToken(gameId: controller.spec.id, player: p, size: 22)
              else
                Text('${s + 1}', style: theme.textTheme.labelLarge),
              const SizedBox(width: 6),
              Text('${g.scoreOf(s)}',
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              if (pen != 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Text(
                    pen > 0 ? '(+$pen)' : '(−${-pen})',
                    key: Key('wordtiles-penalty-$s'),
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Scores (scaled down when space is short), then the bench
    // button on a small phone, the bag and "So geht's" (KLD-094 step 5).
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          // Scaled down rather than wrapped when space is short (end scores
          // with penalties on a small phone; more players later).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var s = 0; s < g.playerCount; s++) ...[if (s > 0) const SizedBox(width: 6), seat(s)],
              ],
            ),
          ),
        ),
        if (extra != null) Flexible(child: extra),
        Row(mainAxisSize: MainAxisSize.min, children: [
        // KLD-094 step 6: the host's options in the header of a network
        // game ("EN" plus a book for "Wörterbuch prüfen"; the full text as
        // tooltip and for screen readers).
        if (_network) _optionsChip(context, l10n),
        const SizedBox(width: 4),
        Tooltip(
          message: l10n.wordtilesBag(g.bagCount),
          child: Semantics(
            label: l10n.wordtilesBag(g.bagCount),
            excludeSemantics: true,
            child: Row(
              key: const Key('wordtiles-bag'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Text('${g.bagCount}', textDirection: TextDirection.ltr, style: theme.textTheme.labelLarge),
              ],
            ),
          ),
        ),
        IconButton(
          key: const Key('wordtiles-help'),
          tooltip: l10n.wordtilesHelp,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          iconSize: 22,
          icon: const Icon(Icons.help_outline),
          onPressed: () => showWordTilesHelp(context, game),
        ),
        ]),
      ],
    );
  }

  Widget _optionsChip(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final config = controller.config;
    final summary = wordTilesOptionsSummary(l10n, config);
    final tiles = config.tiles ?? TileSet.german.id;
    final muted = theme.colorScheme.onSurfaceVariant;
    return Tooltip(
      message: summary,
      child: Semantics(
        label: summary,
        excludeSemantics: true,
        child: Container(
          key: const Key('wordtiles-net-options'),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(wordTilesTileNames.containsKey(tiles) ? tiles.toUpperCase() : tiles,
                  textDirection: TextDirection.ltr, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
              if (config.dictionary) ...[
                const SizedBox(width: 3),
                Icon(Icons.menu_book_outlined, size: 16, color: muted),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The challenge banner while the player to move may answer the last
  /// placement, otherwise the last turn as one line.
  Widget _infoLine(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final labels = PlayerLabelsScope.of(context);
    final g = game;
    final open = g.challengeable;
    if (open != null && _myTurn) {
      final placer = WordTilesGame.playerOfSeat(open.seat);
      final who = placer == null ? '${open.seat + 1}' : labels.label(context, l10n, placer);
      final c = WordTilesColors.of(context);
      return Container(
        key: const Key('wordtiles-open'),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.open, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.wordtilesOpenPlacement(who, wordList(context, open.words), open.score),
                style: theme.textTheme.bodyLarge),
            if (g.endPending)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(l10n.wordtilesEndPending(who), style: theme.textTheme.bodySmall),
              ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const Key('wordtiles-challenge'),
                  icon: const Icon(Icons.help_outline),
                  onPressed: _challenge,
                  label: Text(l10n.wordtilesChallenge),
                ),
                FilledButton.tonalIcon(
                  key: const Key('wordtiles-accept'),
                  icon: const Icon(Icons.check),
                  onPressed: _accept,
                  label: Text(l10n.wordtilesAccept),
                ),
              ],
            ),
          ],
        ),
      );
    }
    // KLD-094 step 6: an open "Trotzdem zulassen" request, on both devices.
    final request = g.allowRequest;
    if (request != null) {
      final c = WordTilesColors.of(context);
      return Container(
        key: const Key('wordtiles-allow-line'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.open, width: 1.5),
        ),
        child: Text(
          l10n.wordtilesAllowLine(_nameOfSeat(request.seat), wordList(context, request.allow), request.score),
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    final moves = controller.moves;
    if (moves.isNotEmpty && moves.last.move['action'] == WordTilesGame.declineAllow) {
      final p = moves.last.event.payload;
      final words = p is Map && p['allow'] is List ? (p['allow'] as List).whereType<String>().toList() : <String>[];
      return Text(
        l10n.wordtilesAllowDeclined(playerName(context, moves.last.player), wordList(context, words)),
        key: const Key('wordtiles-allow-declined'),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final turns = g.turns;
    if (turns.isEmpty) {
      // A network game starts with the host's options (KLD-094 step 6).
      if (!_network) return const SizedBox(height: 20);
      return Text(
        wordTilesOptionsSummary(l10n, controller.config),
        key: const Key('wordtiles-net-options-line'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final t = turns.last;
    final p = WordTilesGame.playerOfSeat(t.seat);
    final who = p == null ? '${t.seat + 1}' : labels.label(context, l10n, p);
    return Text(
      l10n.shellHistoryEntry(who, describeWordTilesTurn(context, l10n, t)),
      key: const Key('wordtiles-last-turn'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  Widget _previewLine(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    String? text;
    var error = false;
    final notice = _notice;
    if (notice != null) {
      text = notice;
      error = true;
    } else if (_pending.isNotEmpty) {
      // Never the word list here (see the class docs): only "Legen" asks it.
      final check = game.checkPlacement(WordTilesGame.placeMove(_placed), checkWords: false);
      if (check.ok) {
        final words = wordList(context, [for (final w in check.words) w.word]);
        text = check.bingo
            ? l10n.wordtilesPreviewBingo(words, check.score, WordTilesGame.bingoBonus)
            : l10n.wordtilesPreview(words, check.score);
      } else {
        text = placementErrorText(l10n, check.error!);
        error = _tried;
      }
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 22),
      child: text == null
          ? const SizedBox()
          : Text(
              text,
              key: Key(error ? 'wordtiles-error' : 'wordtiles-preview'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: error ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                fontWeight: error || (_pending.isNotEmpty && !_tried) ? FontWeight.w600 : null,
              ),
            ),
    );
  }

  Widget _boardView(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest.shortestSide;
      _boardSize = size;
      return Center(
        child: SizedBox.square(
          dimension: size,
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _zoom,
              minScale: 1,
              maxScale: 4,
              onInteractionEnd: (_) => setState(() {}),
              child: LtrBoard(child: _grid(context, size)),
            ),
          ),
        ),
      );
    });
  }

  Widget _grid(BuildContext context, double size) {
    final c = WordTilesColors.of(context);
    final l10n = AppLocalizations.of(context);
    final cell = size / _n;
    final open = {for (final t in game.challengeable?.tiles ?? const <PlacedTile>[]) t.row * _n + t.col};
    final last = open.isEmpty ? _lastPlacement() : const <int>{};
    // The tiles of an open "Trotzdem zulassen" request lie on the board,
    // ringed, while the other player decides (KLD-094 step 6).
    final requested = {for (final t in game.allowRequest?.tiles ?? const <PlacedTile>[]) t.row * _n + t.col: t};
    return Container(
      key: const Key('wordtiles-board'),
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.line, border: Border.all(color: c.edge, width: 1)),
      child: Column(
        children: [
          for (var r = 0; r < _n; r++)
            Row(
              children: [
                for (var col = 0; col < _n; col++)
                  _square(context, l10n, c, r, col, cell - (2 / _n), open, last, requested),
              ],
            ),
        ],
      ),
    );
  }

  Widget _square(BuildContext context, AppLocalizations l10n, WordTilesColors c, int r, int col, double cell,
      Set<int> open, Set<int> last, Map<int, PlacedTile> requested) {
    final sq = r * _n + col;
    final key = Key('wordtiles-sq-$r-$col');
    final tile = game.tileAt(r, col);
    final inset = max(0.5, cell * 0.03);
    final asked = requested[sq];
    if (tile == null && asked != null) {
      return SizedBox.square(
        key: key,
        dimension: cell,
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: LetterTile(
            key: Key('wordtiles-requested-$r-$col'),
            letter: asked.letter,
            points: asked.isBlank ? 0 : game.tileSet.pointsOf(asked.tile),
            blank: asked.isBlank,
            size: cell - 2 * inset,
            face: c.pending,
            ring: c.open,
          ),
        ),
      );
    }
    if (tile != null) {
      final ring = open.contains(sq) ? c.open : null;
      return SizedBox.square(
        key: key,
        dimension: cell,
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: LetterTile(
            letter: tile.letter,
            points: tile.blank ? 0 : game.tileSet.pointsOf(tile.letter),
            blank: tile.blank,
            size: cell - 2 * inset,
            face: last.contains(sq) ? c.lastMove : null,
            ring: ring,
          ),
        ),
      );
    }
    final pending = _pending[sq];
    if (pending != null) {
      final face = LetterTile(
        letter: pending.letter,
        points: game.tileSet.pointsOf(pending.tile),
        blank: pending.tile == TileSet.blank,
        size: cell - 2 * inset,
        face: c.pending,
        ring: _tried ? Theme.of(context).colorScheme.error : c.select,
      );
      return SizedBox.square(
        key: key,
        dimension: cell,
        child: DragTarget<_Drag>(
          onWillAcceptWithDetails: (d) => _canLay,
          onAcceptWithDetails: (d) {
            if (d.data.square == sq) return;
            // A rack or bench tile replaces this one (back to the rack); a
            // tile from another square swaps with it ([_drop]).
            if (d.data.square == null) _takeBack(sq);
            _drop(d.data, sq);
          },
          builder: (context, _, _) => GestureDetector(
            onTap: () => _tapSquare(sq),
            child: LongPressDraggable<_Drag>(
              data: _Drag(pending.rackIndex, sq),
              maxSimultaneousDrags: _canLay ? 1 : 0,
              // At least finger size, as big as the tile on screen when
              // zoomed in further.
              feedback: _feedback(context, pending.letter, pending.tile,
                  max(52.0, (cell - 2 * inset) * _zoom.value.getMaxScaleOnAxis())),
              childWhenDragging: const SizedBox(),
              child: Padding(padding: EdgeInsets.all(inset), child: face),
            ),
          ),
        ),
      );
    }
    final premium = WordTilesGame.premiumAt(r, col);
    final centre = r == WordTilesGame.centre && col == WordTilesGame.centre;
    final bg = c.premium(premium);
    final ink = inkOn(bg);
    return SizedBox.square(
      key: key,
      dimension: cell,
      child: DragTarget<_Drag>(
        onWillAcceptWithDetails: (d) => _canLay,
        onAcceptWithDetails: (d) => _drop(d.data, sq),
        builder: (context, candidates, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _tapSquare(sq),
          child: Container(
            margin: EdgeInsets.all(inset * 0.5),
            decoration: BoxDecoration(
              color: candidates.isNotEmpty ? Color.alphaBlend(c.select.withValues(alpha: 0.35), bg) : bg,
              borderRadius: BorderRadius.circular(cell * 0.08),
            ),
            alignment: Alignment.center,
            child: centre
                ? Icon(Icons.star, size: cell * 0.6, color: ink.withValues(alpha: 0.8))
                : premium == Premium.none
                    ? null
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: EdgeInsets.all(cell * 0.06),
                          child: Text(
                            premiumLabel(l10n, premium),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: max(6, cell * 0.3),
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _feedback(BuildContext context, String letter, String tile, double size) => Material(
        type: MaterialType.transparency,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: LetterTile(
            letter: letter,
            points: game.tileSet.pointsOf(tile),
            blank: tile == TileSet.blank,
            size: size,
            lifted: true,
          ),
        ),
      );

  /// The rack tile size for a controls column [width] wide (the rack uses
  /// at most 420 px of it); the bench tiles grow up to it (step 8e).
  double _rackTileSize(double width) {
    const gap = 6.0;
    // Padding (6 + 6) and border (1 + 1) of the rack, plus a little air.
    return min(WordTilesBoard.tileMax,
        (min(width, 420.0) - 18 - gap * (WordTilesGame.rackSize - 1)) / WordTilesGame.rackSize);
  }

  /// [benchShown]: the bench is open; its tiles leave a gap in the rack
  /// (`wordtiles-rack-gap-<rack index>`, a tap brings the tile back). A
  /// closed bench hides nothing: its tiles are in the rack (KLD-094 step 8:
  /// tiles on a closed bench looked lost, the rack short of 7).
  Widget _rackView(BuildContext context, double width, {required bool benchShown}) {
    final c = WordTilesColors.of(context);
    final rack = _rack;
    if (_order.length != rack.length) _order = List.generate(rack.length, (i) => i);
    final laid = {for (final p in _pending.values) p.rackIndex, ..._requestedRackTiles};
    final bench = benchShown ? _onBench : const <int>{};
    final shown = [for (final i in _order) if (!laid.contains(i)) i];
    const gap = 6.0;
    final size = _rackTileSize(width);
    final active = _myTurn && !game.endPending;
    return DragTarget<_Drag>(
      onWillAcceptWithDetails: (d) => d.data.square != null || d.data.slot != null,
      onAcceptWithDetails: (d) {
        final sq = d.data.square;
        if (sq != null) {
          _takeBack(sq);
        } else {
          _benchToRack(d.data.rackIndex);
        }
      },
      builder: (context, candidates, _) => Container(
        key: const Key('wordtiles-rack'),
        height: size + 16,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: candidates.isNotEmpty ? c.select.withValues(alpha: 0.15) : c.board.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.tileEdge.withValues(alpha: 0.5)),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (k, i) in shown.indexed) ...[
                if (k > 0) const SizedBox(width: gap),
                if (bench.contains(i)) _rackGap(c, i, size) else _rackTile(context, c, rack, i, size, active),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The place of a rack tile that lies on the open bench.
  Widget _rackGap(WordTilesColors c, int i, double size) => GestureDetector(
        key: Key('wordtiles-rack-gap-$i'),
        onTap: _benchActive ? () => _benchToRack(i) : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.14),
            border: Border.all(color: c.tileEdge.withValues(alpha: 0.35)),
            color: c.tile.withValues(alpha: 0.18),
          ),
        ),
      );

  Widget _rackTile(BuildContext context, WordTilesColors c, List<String> rack, int i, double size, bool active,
      {(int, int)? slot}) {
    final tile = rack[i];
    final blank = tile == TileSet.blank;
    final selected = _exchanging ? _swap.contains(i) : _selected == i;
    final face = LetterTile(
      letter: blank ? '' : tile,
      points: game.tileSet.pointsOf(tile),
      blank: blank,
      size: size,
      ring: selected ? c.select : null,
      lifted: selected,
    );
    final lifted = AnimatedSlide(
      offset: selected ? const Offset(0, -0.12) : Offset.zero,
      duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 120),
      child: face,
    );
    return GestureDetector(
      key: Key('wordtiles-rack-$i'),
      onTap: active ? () => _tapRack(i) : null,
      child: Draggable<_Drag>(
        data: _Drag(i, null, slot),
        maxSimultaneousDrags: active && !_exchanging ? 1 : 0,
        feedback: _feedback(context, blank ? '' : tile, tile, size * 1.1),
        childWhenDragging: Opacity(opacity: 0.3, child: face),
        onDragStarted: () => setState(() => _selected = null),
        child: lifted,
      ),
    );
  }

  /// The bench: a header to open / collapse it and, when open, the practice
  /// rows with their base scores.
  /// On a small phone the open bench is an overlay over the board and the
  /// collapsed one a button in the score row (`build`).
  ///
  /// [trailing] (the take-back button, KLD-117) sits at the end of the header.
  Widget _benchView(BuildContext context, AppLocalizations l10n, double width, bool open, {Widget? trailing}) {
    final hasTiles = _onBench.isNotEmpty;
    const compact = VisualDensity(horizontal: -4, vertical: -4);
    final header = Row(
      mainAxisSize: open || trailing != null ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Flexible(
          child: Semantics(
            expanded: open,
            child: TextButton.icon(
              key: const Key('wordtiles-bench-toggle'),
              style: TextButton.styleFrom(visualDensity: compact, padding: const EdgeInsets.symmetric(horizontal: 6)),
              icon: Icon(open ? Icons.expand_more : Icons.chevron_right, size: 20),
              label: Text(l10n.wordtilesBench, maxLines: 1, overflow: TextOverflow.ellipsis),
              onPressed: () => setState(() => _benchOpen = !open),
            ),
          ),
        ),
        if (open || trailing != null) const Spacer(),
        if (open && hasTiles)
          IconButton(
            key: const Key('wordtiles-bench-clear'),
            tooltip: l10n.wordtilesBenchClear,
            visualDensity: compact,
            iconSize: 20,
            icon: const Icon(Icons.vertical_align_bottom),
            onPressed: _benchActive ? _clearBench : null,
          ),
        ?trailing,
      ],
    );
    if (!open) return KeyedSubtree(key: const Key('wordtiles-bench'), child: header);
    return Column(
      key: const Key('wordtiles-bench'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [header, _benchRows(context, l10n, width)],
    );
  }

  /// The bench is visible: the first time on a player's own turn, a short
  /// explanation (once per device; KLD-094 step 8). In hot-seat only once
  /// the handover cover is gone, and not under another dialog or sheet. It
  /// shows sample tiles only, never a rack.
  ///
  /// Checked after two frames: the first frame of the screen can lay the
  /// board out taller than it stays (the shell's header settles a frame
  /// later), and only a bench that is really on screen counts.
  void _maybeBenchCoach() {
    if (_coachPending || SeenTips.shared.has(SeenTips.wordtilesBench)) return;
    _coachPending = true;
    bool shown() =>
        mounted &&
        _benchVisible &&
        _benchActive &&
        !controller.needsHandover &&
        !controller.game.isOver &&
        ModalRoute.of(context)?.isCurrent != false;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!shown()) {
        _coachPending = false;
        return;
      }
      binding.addPostFrameCallback((_) {
        _coachPending = false;
        if (shown() && SeenTips.shared.markFirst(SeenTips.wordtilesBench)) showBenchCoach(context, game.tileSet);
      });
      binding.scheduleFrame();
    });
  }

  /// The practice rows of the bench with their base scores.
  Widget _benchRows(BuildContext context, AppLocalizations l10n, double width) {
    final theme = Theme.of(context);
    final c = WordTilesColors.of(context);
    final rack = _rack;
    final hasTiles = _onBench.isNotEmpty;
    // KLD-094 step 8e: where there is room (wider than a phone) the tiles
    // grow up to the rack tile size, with tighter spacing; on a phone they
    // stay smaller so both rows fit as before.
    final roomy = width > 440;
    final gap = roomy ? 3.0 : 4.0;
    final scoreWidth = roomy ? 30.0 : 34.0;
    final slack = roomy ? 0.0 : 12.0; // the row is gap narrower than width anyway
    const slots = WordTilesBoard.benchSlots;
    final size = min(_rackTileSize(width), (width - slack - scoreWidth - gap * slots) / slots);
    final active = _benchActive;
    Widget slotView(int r, int s) {
      final i = _bench[r][s];
      return DragTarget<_Drag>(
        key: Key('wordtiles-bench-$r-$s'),
        onWillAcceptWithDetails: (d) => active && !(d.data.slot == (r, s)),
        onAcceptWithDetails: (d) => _toBench(d.data.rackIndex, (r, s), fromSquare: d.data.square),
        builder: (context, candidates, _) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: active ? () => _tapSlot((r, s)) : null,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: candidates.isNotEmpty ? c.select.withValues(alpha: 0.3) : c.board.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(size * 0.14),
              border: Border.all(color: c.tileEdge.withValues(alpha: 0.35)),
            ),
            child: i == null || i >= rack.length
                ? null
                : _rackTile(context, c, rack, i, size, _myTurn && !game.endPending || _exchanging, slot: (r, s)),
          ),
        ),
      );
    }

    Widget row(int r) {
      final w = _benchWords(r);
      return Padding(
        padding: EdgeInsets.only(top: gap),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var s = 0; s < slots; s++) ...[if (s > 0) SizedBox(width: gap), slotView(r, s)],
            SizedBox(
              width: scoreWidth,
              child: w.words.isEmpty
                  ? null
                  : Semantics(
                      label: l10n.wordtilesPreview(w.words.join(', '), w.score),
                      excludeSemantics: true,
                      child: Text(
                        '${w.score}',
                        key: Key('wordtiles-bench-score-$r'),
                        textAlign: TextAlign.end,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(mainAxisSize: MainAxisSize.min, children: [for (var r = 0; r < _bench.length; r++) row(r)]),
          if (!hasTiles)
            IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(right: scoreWidth),
                child: Text(
                  l10n.wordtilesBenchHint,
                  textAlign: TextAlign.center,
                  textDirection: Directionality.of(context),
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// [undoIcon]: the icon-only "Zug zurück" at the start of the row (small
  /// phone, KLD-117).
  Widget _actions(BuildContext context, AppLocalizations l10n, {bool undoIcon = false}) {
    if (_exchanging) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          TextButton(
            key: const Key('wordtiles-exchange-cancel'),
            onPressed: () => setState(() {
              _exchanging = false;
              _swap.clear();
            }),
            child: Text(l10n.shellCancel),
          ),
          FilledButton.icon(
            key: const Key('wordtiles-exchange-confirm'),
            icon: const Icon(Icons.swap_horiz),
            onPressed: _swap.isNotEmpty && _myTurn ? _confirmExchange : null,
            label: Text(l10n.wordtilesExchangeConfirm(_swap.length)),
          ),
        ],
      );
    }
    final lay = _canLay;
    // One row on every width (phones included): compact icons, then the
    // three buttons sharing the rest; long translations shrink to fit.
    const compact = VisualDensity(horizontal: -2, vertical: -2);
    final pad = const EdgeInsets.symmetric(horizontal: 8);
    Widget fit(String text) => FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Row(
          children: [
            if (undoIcon) const UndoMoveButton(visualDensity: compact, iconOnly: true),
            IconButton(
              key: const Key('wordtiles-recall'),
              tooltip: l10n.wordtilesRecall,
              visualDensity: compact,
              icon: const Icon(Icons.vertical_align_bottom),
              onPressed: _pending.isNotEmpty ? _recallAll : null,
            ),
            IconButton(
              key: const Key('wordtiles-shuffle'),
              tooltip: l10n.wordtilesShuffle,
              visualDensity: compact,
              icon: const Icon(Icons.shuffle),
              onPressed: _rack.length > 1 ? _shuffle : null,
            ),
            IconButton(
              key: const Key('wordtiles-zoom'),
              tooltip: _zoomed ? l10n.wordtilesZoomOut : l10n.wordtilesZoomIn,
              visualDensity: compact,
              icon: Icon(_zoomed ? Icons.zoom_out_map : Icons.zoom_in),
              onPressed: _toggleZoom,
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 3,
              child: OutlinedButton(
                key: const Key('wordtiles-exchange'),
                style: OutlinedButton.styleFrom(padding: pad),
                onPressed: lay ? _startExchange : null,
                child: fit(l10n.wordtilesExchange),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: OutlinedButton(
                key: const Key('wordtiles-pass'),
                style: OutlinedButton.styleFrom(padding: pad),
                onPressed: lay ? _pass : null,
                child: fit(l10n.wordtilesPass),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              flex: 4,
              child: FilledButton(
                key: const Key('wordtiles-play'),
                style: FilledButton.styleFrom(padding: pad),
                onPressed: lay && _pending.isNotEmpty ? _play : null,
                child: fit(l10n.wordtilesPlay),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Words as one string ("HAUS, AUS"), kept left-to-right in RTL locales.
String wordList(BuildContext context, List<String> words) => bidiLtr(context, words.join(', '));

/// Why a placement does not fit, for the line under the board.
String placementErrorText(AppLocalizations l10n, PlacementError e) => switch (e) {
      PlacementError.notInLine => l10n.wordtilesErrorLine,
      PlacementError.gap => l10n.wordtilesErrorGap,
      PlacementError.firstNotOnCentre => l10n.wordtilesHintFirst,
      PlacementError.firstTooShort => l10n.wordtilesErrorShort,
      PlacementError.notConnected => l10n.wordtilesErrorConnect,
      PlacementError.unknownWord => l10n.wordtilesErrorUnknownWord,
      PlacementError.notNow => l10n.wordtilesErrorAnswerFirst,
      PlacementError.malformed ||
      PlacementError.empty ||
      PlacementError.offBoard ||
      PlacementError.occupied ||
      PlacementError.notOnRack =>
        l10n.wordtilesErrorOther,
    };

/// One turn of the public log, without the player ("HAUS, AUS für 14
/// Punkte", "2 Steine getauscht", …).
String describeWordTilesTurn(BuildContext context, AppLocalizations l10n, WordTilesTurn t) => switch (t.action) {
      'place' => t.allowed.isEmpty
          ? l10n.wordtilesMovePlace(wordList(context, t.words), t.score)
          : l10n.wordtilesMovePlaceAllowed(wordList(context, t.words), t.score, wordList(context, t.allowed)),
      'exchange' => l10n.wordtilesMoveExchange(t.count),
      'pass' => l10n.wordtilesMovePass,
      'challenge' => t.withdrawn ? l10n.wordtilesMoveChallengeWithdrawn(wordList(context, t.words)) : l10n.wordtilesMoveChallengeFailed,
      'accept' => l10n.wordtilesMoveAccept,
      _ => t.action,
    };

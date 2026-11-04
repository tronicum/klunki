part of 'word_tiles.dart';

/// A word tile game as one player sees it (KLD-064): built from
/// [WordTilesGame.viewJson] on the remote side of a network game. It has
/// the board, the scores, the turn log and the viewer's own rack; the other
/// racks and the bag are counts only ([hiddenTile] inside), [seed] is 0.
/// Read-only: [applyMove] returns null (the host applies moves and sends
/// the next view).
class WordTilesView extends WordTilesGame {
  /// Stands for a tile the viewer may not see (other racks, the bag).
  static const String hiddenTile = '#';

  /// The seat whose view this is (KLD-088).
  final int viewerSeat;

  /// The player whose view this is; throws for seat 2+ (use [viewerSeat]).
  Player get viewer =>
      WordTilesGame.playerOfSeat(viewerSeat) ?? (throw StateError('seat $viewerSeat has no Player (KLD-088)'));

  WordTilesView._(this.viewerSeat, TileSet tileSet, int players, WordCheck check, WordValidator? validator, int limit,
      {bool jokerSwap = false})
      : super._view(tileSet, players, check, validator, limit, jokerSwap: jokerSwap);

  /// Rebuilds the view from [WordTilesGame.viewJson]; throws
  /// [BadViewException] if [j] is malformed. [validator] is the word check
  /// for a dictionary game (the word list is not part of the view).
  factory WordTilesView.fromJson(Map<String, dynamic> j, {WordValidator? validator}) {
    try {
      final viewerSeat = j['viewerSeat'] as int? ?? WordTilesGame.seatOf(playerIn(j['viewer']));
      final tileSet = TileSet.byId(j['tileSet']) ?? (throw BadViewException('unknown tile set ${j['tileSet']}'));
      final players = j['players'] as int;
      if (players < 2 || players > 4) throw BadViewException('bad player count $players');
      final check = WordCheck.values.byName(j['check'] as String);
      if (viewerSeat < 0 || viewerSeat >= players) throw BadViewException('bad viewer seat $viewerSeat');
      final v = WordTilesView._(viewerSeat, tileSet, players, check,
          validator ?? (check == WordCheck.dictionary ? const AcceptAllValidator() : null), j['scorelessLimit'] as int,
          jokerSwap: j['jokerSwap'] == true)
        .._lazyList = validator == null;
      final rows = (j['board'] as List).cast<String>();
      if (rows.length != WordTilesGame.size) throw const BadViewException('bad board');
      for (var r = 0; r < WordTilesGame.size; r++) {
        final cells = rows[r].split('');
        if (cells.length != WordTilesGame.size) throw const BadViewException('bad board row');
        for (var c = 0; c < WordTilesGame.size; c++) {
          final x = cells[c];
          if (x == '.') continue;
          final upper = x.toUpperCase();
          if (!tileSet.counts.containsKey(upper)) throw BadViewException('bad tile $x');
          v._board[r * WordTilesGame.size + c] = BoardTile(upper, blank: x != upper);
        }
      }
      final racks = (j['racks'] as List).cast<int>();
      final scores = (j['scores'] as List).cast<int>();
      final penalties = (j['penalties'] as List).cast<int>();
      if (racks.length != players || scores.length != players || penalties.length != players) {
        throw const BadViewException('bad seat lists');
      }
      final rack = (j['rack'] as List).cast<String>();
      final me = viewerSeat;
      if (me >= players || rack.length != racks[me]) throw const BadViewException('rack size mismatch');
      for (final t in rack) {
        if (t != TileSet.blank && !tileSet.counts.containsKey(t)) throw BadViewException('bad tile $t');
      }
      for (var s = 0; s < players; s++) {
        v._racks[s].addAll(s == me ? rack : List.filled(racks[s], hiddenTile));
        v._scores[s] = scores[s];
        v._penalties[s] = penalties[s];
      }
      v._bag.addAll(List.filled(j['bag'] as int, hiddenTile));
      final seat = j['seat'] as int;
      if (seat < 0 || seat >= players) throw BadViewException('bad seat $seat');
      v._seat = seat;
      v._scoreless = j['scoreless'] as int;
      v._turns.addAll([for (final t in j['turns'] as List) WordTilesTurn.fromJson(t)]);
      final open = j['open'];
      if (open != null) {
        final o = open as Map<String, dynamic>;
        final tiles = v._parseTiles(o['tiles']) ?? (throw const BadViewException('bad open tiles'));
        v._open = _OpenPlacement(o['seat'] as int, tiles, (o['words'] as List).cast<String>(), o['score'] as int,
            const [], 0, 0, v._turns.length - 1);
      }
      v._endPending = j['endPending'] == true;
      final request = j['allowRequest'];
      if (request != null) {
        final r = request as Map<String, dynamic>;
        final tiles = v._parseTiles(r['tiles']) ?? (throw const BadViewException('bad request tiles'));
        final seat = r['seat'] as int;
        if (seat < 0 || seat >= players || tiles.isEmpty) throw const BadViewException('bad request');
        final swaps = r.containsKey('swaps')
            ? v._parseSwaps(r['swaps']) ?? (throw const BadViewException('bad request swaps'))
            : const <JokerSwap>[];
        v._request = _AllowRequest(seat, tiles, (r['allow'] as List).cast<String>(),
            (r['words'] as List).cast<String>(), r['score'] as int, swaps);
      }
      for (final d in j['declined'] as List? ?? const []) {
        v._declined.add((d as List).cast<String>().toList());
      }
      final end = j['end'];
      if (end != null) {
        final e = end as Map<String, dynamic>;
        final code = GameEndReason.fromCode(e['code'] as String);
        if (code != GameEndReason.wordtilesPlayedOut &&
            code != GameEndReason.wordtilesScoreless &&
            (code != GameEndReason.commonResigned || players == 2)) {
          throw BadViewException('bad end ${e['code']}');
        }
        v
          .._over = true
          .._endCode = code
          .._outSeat = e['out'] as int?;
      }
      for (final s in j['out'] as List? ?? const []) {
        if (s is! int || s < 0 || s >= players || players == 2 || v._outOrder.contains(s)) {
          throw BadViewException('bad out seat $s');
        }
        v._outOrder.add(s);
      }
      final resigned = j['resigned'];
      if (resigned != null) v._restoreResign(resigned);
      return v;
    } on BadViewException {
      rethrow;
    } catch (e) {
      throw BadViewException('malformed word tiles view: $e');
    }
  }

  @override
  int get seed => 0;

  /// The viewer's own rack; empty for every other seat (only its size,
  /// [rackSizeOf], is known).
  @override
  List<String> rackOf(int seat) => seat == viewerSeat ? super.rackOf(seat) : const [];

  /// The viewer's legal moves on its turn (or the answers to the other
  /// player's open request); empty otherwise.
  @override
  List<Map<String, dynamic>> get legalMoves {
    final me = viewerSeat;
    final answerer = allowRequestAnswerer;
    if (answerer != null) return answerer == me ? super.legalMoves : const [];
    return _seat == me ? super.legalMoves : const [];
  }

  /// The word check of a dictionary game: the list given to [fromJson], else
  /// the one registered in [WordLists] for the tile set (the app loads it
  /// after joining, KLD-094 step 6), else nothing is refused locally (the
  /// host checks every placement anyway).
  @override
  WordValidator? get validator {
    final own = super.validator;
    if (check != WordCheck.dictionary || own is! AcceptAllValidator || !_lazyList) return own;
    return WordLists.of(tileSet.id) ?? own;
  }

  /// No list was given to [fromJson]: look it up in [WordLists].
  bool _lazyList = false;

  /// Read-only: the host applies every move, a resign included.
  @override
  GameEvent? applyMove(Map<String, dynamic> move) => null;

  @override
  GameEvent? applyPlayMove(Map<String, dynamic> move) => null;

  void _restoreResign(Object? name) => super.applyMove(Game.resignMove(playerIn(name)));

  @override
  Map<String, dynamic> seatViewJson(int v) {
    if (v != viewerSeat) throw ArgumentError.value(v, 'viewer', 'not the view of this seat');
    return super.seatViewJson(v);
  }

  @override
  String toString() => 'WordTilesView(seat $viewerSeat, ${tileSet.id})';
}

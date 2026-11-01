import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../ltr.dart';
import '../../shell/game_screen.dart';
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
///   least [WordTilesGame.rackSize] tiles in the bag); "Passen" passes.
/// * **Challenge mode:** after another player's placement the player to move
///   sees it ringed on the board plus "Anzweifeln" / "Annehmen" (a
///   placement, swap or pass accepts it too). Without a word list the
///   challenger's call is final (the confirmation says so).
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
/// `wordtiles-blank-<letter>`.
class WordTilesBoard extends StatefulWidget {
  final GameController controller;

  const WordTilesBoard({super.key, required this.controller});

  /// Below this square size (logical pixels, unzoomed) the board zooms in
  /// on the first tile laid.
  static const double autoZoomBelow = 30;

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

/// What is dragged: a rack tile, or a pending tile from [square].
class _Drag {
  final int rackIndex;
  final int? square;
  const _Drag(this.rackIndex, [this.square]);
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

  List<String> get _rack => game.rackOf(_seat);

  bool get _myTurn => controller.canAct && game.currentSeat == _seat && !_busy;

  /// Tiles may be laid (not while only challenge / accept are allowed).
  bool get _canLay => _myTurn && !game.endPending && !_exchanging;

  @override
  void initState() {
    super.initState();
    _transport = controller.transport;
    _seen = controller.moves.length;
    _resetTurn();
    controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(WordTilesBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _transport = controller.transport;
      _seen = controller.moves.length;
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
        _transport = controller.transport;
        _seen = controller.moves.length;
        _resetTurn();
      }
    });
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
    _zoomAnim.stop();
    _zoom.value = Matrix4.identity();
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

  void _drop(_Drag d, int sq) {
    final from = d.square;
    if (from != null) {
      final p = _pending[from];
      if (p == null) return;
      setState(() {
        _pending.remove(from);
        _pending[sq] = p;
        _tried = false;
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

  void _play() {
    if (_pending.isEmpty || !_canLay) return;
    final move = WordTilesGame.placeMove(_placed);
    if (!game.checkPlacement(move).ok) {
      setState(() => _tried = true);
      return;
    }
    _submit(move);
  }

  void _pass() {
    if (!_canLay) return;
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
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _updateHint(l10n);
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 640 && box.maxWidth > box.maxHeight * 1.15;
      final board = _boardView(context);
      final scores = _scoreBar(context, l10n);
      final info = _infoLine(context, l10n);
      final controls = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _previewLine(context, l10n),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, rackBox) => _rackView(context, min(rackBox.maxWidth, 420.0))),
          const SizedBox(height: 6),
          _actions(context, l10n),
          const SizedBox(height: 6),
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
                  children: [scores, const SizedBox(height: 8), info, const SizedBox(height: 16), controls],
                ),
              ),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: scores),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 4), child: info),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AspectRatio(aspectRatio: 1, child: board),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: controls),
        ],
      );
    });
  }

  Widget _scoreBar(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final labels = PlayerLabelsScope.of(context);
    final g = game;
    final penalties = g.rackPenalties;
    Widget seat(int s) {
      final p = WordTilesGame.playerOfSeat(s);
      final name = p == null ? '${s + 1}' : labels.name(l10n, p);
      final label = p == null ? name : labels.label(context, l10n, p);
      final on = !g.isOver && g.currentSeat == s;
      final pen = penalties[s];
      return Semantics(
        label: l10n.wordtilesScore(label, g.scoreOf(s)),
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
              if (p != null) PlayerToken(gameId: controller.spec.id, player: p, size: 20),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 90),
                child: Text(
                  bidiName(context, name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: on ? FontWeight.w700 : null),
                ),
              ),
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

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(spacing: 6, children: [for (var s = 0; s < g.playerCount; s++) seat(s)]),
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
      ],
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
    final turns = g.turns;
    if (turns.isEmpty) return const SizedBox(height: 20);
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
      final check = game.checkPlacement(WordTilesGame.placeMove(_placed));
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
                for (var col = 0; col < _n; col++) _square(context, l10n, c, r, col, cell - (2 / _n), open, last),
              ],
            ),
        ],
      ),
    );
  }

  Widget _square(BuildContext context, AppLocalizations l10n, WordTilesColors c, int r, int col, double cell,
      Set<int> open, Set<int> last) {
    final sq = r * _n + col;
    final key = Key('wordtiles-sq-$r-$col');
    final tile = game.tileAt(r, col);
    final inset = max(0.5, cell * 0.03);
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
            _takeBack(sq);
            _drop(d.data, sq);
          },
          builder: (context, _, _) => GestureDetector(
            onTap: () => _tapSquare(sq),
            child: LongPressDraggable<_Drag>(
              data: _Drag(pending.rackIndex, sq),
              maxSimultaneousDrags: _canLay ? 1 : 0,
              feedback: _feedback(context, pending.letter, pending.tile, 52),
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

  Widget _rackView(BuildContext context, double width) {
    final c = WordTilesColors.of(context);
    final rack = _rack;
    if (_order.length != rack.length) _order = List.generate(rack.length, (i) => i);
    final laid = {for (final p in _pending.values) p.rackIndex};
    final shown = [for (final i in _order) if (!laid.contains(i)) i];
    const gap = 6.0;
    // Padding (6 + 6) and border (1 + 1) of the rack, plus a little air.
    final size = min(54.0, (width - 18 - gap * (WordTilesGame.rackSize - 1)) / WordTilesGame.rackSize);
    final active = _myTurn && !game.endPending;
    return DragTarget<_Drag>(
      onWillAcceptWithDetails: (d) => d.data.square != null,
      onAcceptWithDetails: (d) => _takeBack(d.data.square!),
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
                _rackTile(context, c, rack, i, size, active),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _rackTile(BuildContext context, WordTilesColors c, List<String> rack, int i, double size, bool active) {
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
        data: _Drag(i),
        maxSimultaneousDrags: active && !_exchanging ? 1 : 0,
        feedback: _feedback(context, blank ? '' : tile, tile, size * 1.1),
        childWhenDragging: Opacity(opacity: 0.3, child: face),
        onDragStarted: () => setState(() => _selected = null),
        child: lifted,
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
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
      'place' => l10n.wordtilesMovePlace(wordList(context, t.words), t.score),
      'exchange' => l10n.wordtilesMoveExchange(t.count),
      'pass' => l10n.wordtilesMovePass,
      'challenge' => t.withdrawn ? l10n.wordtilesMoveChallengeWithdrawn(wordList(context, t.words)) : l10n.wordtilesMoveChallengeFailed,
      'accept' => l10n.wordtilesMoveAccept,
      _ => t.action,
    };

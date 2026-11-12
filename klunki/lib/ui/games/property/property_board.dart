import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../profile/seen_tips.dart';
import '../../shell/coach_marks.dart';
import '../../shell/game_screen.dart';
import '../../shell/seat_game_screen.dart';
import '../maexchen/maexchen_dice.dart' show DieFace;
import '../../board_zoom.dart';
import 'property_names.dart';
import 'property_roll_show.dart';
import 'property_screen.dart';
import 'property_trade.dart';

/// The Baulöwe board (KLD-060): the players with their money, the 40
/// squares around the centre (dice, the square in focus, the pot) and below
/// it the actions of the seat that must move now ([PropertyGame.actor]):
/// roll, buy or auction, bid or drop out, pay a debt, end the turn, "Meine
/// Straßen" (build, sell, mortgage) and "Zug zurücknehmen". A tap on a
/// square shows its details (price, rents, owner). The last move's events
/// are told in a line of their own above the players (two lines' height
/// kept from the start, so the board never moves; not the shell's hint,
/// whose height changes with the text).
///
/// A roll is shown, not just applied ([PropertyRollShow]): the dice tumble,
/// the token walks square by square, the target square is outlined, and
/// only then the square's card, the question or the rent appear; the
/// buttons wait meanwhile. A tap on the board or the dice skips to the end;
/// with "reduce motion" the result shows at once. The engine has the move
/// at once (undo, tests and replays do not wait).
///
/// One device for everyone (hot-seat): no secrets, so no handover cover.
/// The first game on a device starts with a short tour ([showCoachMarks],
/// [SeenTips.propertyIntro]); "Kurz erklärt" in the "⋮" menu shows it again.
///
/// Keys: `property-story`, `property-board`, `property-players`, `property-player-<seat>`,
/// `property-square-<i>`, `property-controls`, `property-roll`,
/// `property-pay-bail`, `property-use-card`, `property-buy`,
/// `property-decline`, `property-bid-<0..2>`, `property-pass`,
/// `property-end`, `property-bankrupt`, `property-trade` (the trade sheet;
/// it and the answer are in `property_trade.dart`), `property-manage`, `property-manage-sheet`,
/// `property-manage-<action>-<square>`, `property-square-sheet`; while a roll
/// is shown `property-dice-rolling`, `property-rolling` (the waiting
/// button), `property-focus-waiting` (the hidden card),
/// `property-walking-<seat>` (the walking token).
class PropertyBoard extends StatefulWidget {
  final GameController controller;
  final PropertyTourRequest? tour;
  const PropertyBoard({super.key, required this.controller, this.tour});

  @override
  State<PropertyBoard> createState() => _PropertyBoardState();
}

/// "Kurz erklärt" (the "⋮" menu) asks the board for the tour again.
class PropertyTourRequest extends ChangeNotifier {
  void request() => notifyListeners();
}

/// The colour of colour group [group] (0–7, cheap to expensive): the
/// classic order brown, light blue, pink, orange, red, yellow, green, dark
/// blue. Shown with the group's name in the details, never alone.
Color propertyGroupColor(int group) => const [
      Color(0xFF8B5A2B),
      Color(0xFF6EC1E4),
      Color(0xFFD63C8E),
      Color(0xFFF08A24),
      Color(0xFFD62828),
      Color(0xFFF2C200),
      Color(0xFF1F9D55),
      Color(0xFF1E4FA8),
    ][group.clamp(0, 7)];

class _PropertyBoardState extends State<PropertyBoard> with TickerProviderStateMixin {
  final _rollKey = GlobalKey(debugLabel: 'property-roll');
  final _boardKey = GlobalKey(debugLabel: 'property-board');
  final _playersKey = GlobalKey(debugLabel: 'property-players');
  final _manageKey = GlobalKey(debugLabel: 'property-manage');
  final _tradeKey = GlobalKey(debugLabel: 'property-trade');
  bool _coachPending = false;
  bool _coachOpen = false;
  /// What happened in the turn so far (else in the turn before).
  String? _story;

  /// Pinch zoom: zoomed in, the squares show the full street names.
  late final BoardZoom _zoom = BoardZoom(vsync: this);

  /// The roll being shown, null when the board shows the game as it is.
  PropertyRollShow? _show;
  late final AnimationController _anim = AnimationController(vsync: this)
    ..addListener(() {
      if (mounted && _show != null) setState(() {});
    })
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) _skip();
    });

  /// The moves and positions the board last showed (to know where a walk
  /// starts).
  int _seenMoves = 0;
  List<int> _shownPos = const [];
  List<int> _shownCash = const [];

  /// The money before the roll being shown (the chips change when the
  /// token has arrived, not before it passes Start).
  List<int> _cashBefore = const [];

  GameController get controller => widget.controller;
  PropertyGame get game => controller.game as PropertyGame;

  @override
  void initState() {
    super.initState();
    controller.addListener(_changed);
    widget.tour?.addListener(_replayTour);
    _seenMoves = controller.moves.length;
    _shownPos = _positions();
    _shownCash = [for (final st in game.seats) st.cash];
  }

  List<int> _positions() => [for (final st in game.seats) st.pos];

  @override
  void didUpdateWidget(PropertyBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
    if (old.tour != widget.tour) {
      old.tour?.removeListener(_replayTour);
      widget.tour?.addListener(_replayTour);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_changed);
    widget.tour?.removeListener(_replayTour);
    _anim.dispose();
    _zoom.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    final moves = controller.moves;
    PropertyRollShow? show;
    // One new move (not an undo or a new game): a roll is shown.
    if (moves.length == _seenMoves + 1 && !reduceMotion(context)) {
      final m = moves.last;
      final e = m.event;
      if (e is PropertyEvent && m.seat < _shownPos.length) {
        show = PropertyRollShow.of(seat: m.seat, from: _shownPos[m.seat], events: e.events, theme: game.theme);
      }
    }
    _seenMoves = moves.length;
    _shownPos = _positions();
    _cashBefore = _shownCash;
    _shownCash = [for (final st in game.seats) st.cash];
    setState(() => _show = show);
    if (show != null) {
      _anim.duration = show.duration;
      _anim.forward(from: 0);
    } else {
      _anim.stop();
    }
  }

  /// Ends the roll being shown: the board shows the game as it is.
  void _skip() {
    if (!mounted || _show == null) return;
    _anim.stop();
    setState(() => _show = null);
  }

  String _name(int seat) {
    final l10n = AppLocalizations.of(context);
    return SeatLabelsScope.of(context).label(context, l10n, seat, count: game.playerCount);
  }

  String _money(int amount) => AppLocalizations.of(context).propertyMoney(amount);

  void _submit(Map<String, dynamic> move) => controller.submit(move);

  // ------------------------------------------------------------- hint

  /// The events of the turn so far (else of the turn before), the last
  /// three sentences; null before the first move.
  String? _storyNow() {
    final l10n = AppLocalizations.of(context);
    final moves = controller.moves;
    List<String> linesFrom(int end) {
      final lines = <String>[];
      var i = end;
      while (i >= 0 && moves[i].move['action'] != 'endTurn') {
        i--;
      }
      for (var k = i + 1; k <= end; k++) {
        final e = moves[k].event;
        if (e is PropertyEvent) lines.addAll(propertyNarration(l10n, game, e.events, moves[k].seat, _name));
      }
      return lines;
    }

    var lines = moves.isEmpty ? <String>[] : linesFrom(moves.length - 1);
    if (lines.isEmpty && moves.isNotEmpty) {
      // The turn just changed: what happened in the last one.
      var end = moves.length - 1;
      while (end >= 0 && moves[end].move['action'] == 'endTurn') {
        end--;
      }
      if (end >= 0) lines = linesFrom(end);
    }
    return lines.isEmpty ? null : lines.skip(math.max(0, lines.length - 3)).join(' · ');
  }

  /// [_story] in a box of two lines' height, also when empty (an invisible
  /// two-line text sets the height, with the text scale).
  Widget _storyBox() {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Stack(
        children: [
          ExcludeSemantics(child: Opacity(opacity: 0, child: Text('\n', maxLines: 2, style: style))),
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              child: Text(_story ?? '',
                  key: const Key('property-story'), maxLines: 2, overflow: TextOverflow.ellipsis, style: style),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- tour

  void _maybeCoach() {
    if (_coachPending || _coachOpen || SeenTips.shared.has(SeenTips.propertyIntro)) return;
    bool ready() =>
        mounted && controller.moves.isEmpty && game.phase == PropertyPhase.roll && ModalRoute.of(context)?.isCurrent != false;
    if (!ready()) return;
    _coachPending = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      if (!ready()) {
        _coachPending = false;
        return;
      }
      binding.addPostFrameCallback((_) {
        _coachPending = false;
        if (ready() && SeenTips.shared.markFirst(SeenTips.propertyIntro)) _showCoach();
      });
      binding.scheduleFrame();
    });
  }

  void _replayTour() {
    if (!mounted || _coachOpen) return;
    _showCoach();
  }

  /// The tour: "Würfeln", the board, the money, "Meine Straßen" and where
  /// the rules are.
  Future<void> _showCoach() async {
    final l10n = AppLocalizations.of(context);
    final rules = GameScreen.of(context).rulesButtonKey;
    _coachOpen = true;
    try {
      await showCoachMarks(
        context,
        keyPrefix: 'property-coach',
        accent: KlunkiPalette.of(context).accent('property'),
        steps: [
          if (_rollKey.currentContext != null)
            CoachStep(target: _rollKey, icon: Icons.casino_outlined, text: l10n.propertyCoachRoll),
          CoachStep(target: _boardKey, icon: Icons.home_work_outlined, text: l10n.propertyCoachBoard),
          CoachStep(target: _playersKey, icon: Icons.savings_outlined, text: l10n.propertyCoachPlayers),
          CoachStep(target: _manageKey, icon: Icons.construction, text: l10n.propertyCoachManage),
          if (_tradeKey.currentContext != null)
            CoachStep(target: _tradeKey, icon: Icons.swap_horiz, text: l10n.propertyCoachTrade),
          if (rules.currentContext != null)
            CoachStep(target: rules, icon: Icons.menu_book_outlined, text: l10n.rulesCoachHere),
        ],
      );
    } finally {
      _coachOpen = false;
    }
  }

  // ------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    // The story tells the roll once it has been shown; before the first
    // move, who starts (the shell's line for it is off: it would go away
    // and move the board).
    if (_show == null) {
      final l10n = AppLocalizations.of(context);
      final first = game.actor;
      _story = controller.moves.isEmpty && first != null && !game.isOver
          ? (controller.config.randomStart ? l10n.seatStartsRandom(_name(first)) : l10n.seatStarts(_name(first)))
          : _storyNow();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeCoach();
    });
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth > box.maxHeight * 1.15;
      if (wide) {
        final side = math.min(box.maxHeight - 8, box.maxWidth * 0.58);
        return Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(dimension: side, child: _board(side)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_storyBox(), _players(), const SizedBox(height: 8), _panel()],
                  ),
                ),
              ),
            ],
          ),
        );
      }
      // Portrait: the story, the players, the board as big as fits with
      // room for the actions, the actions (scrolling when a phase needs
      // more room, e.g. "Kaufen" and "Nicht kaufen"). The story and the
      // players are measured; the room kept for the actions is that of the
      // panel with a main button and the row "Meine Straßen" / "Tauschen" /
      // "Zug zurücknehmen" ([_panelReserve]), the same in every phase, so
      // the board keeps its size. Where that row would take the board room,
      // "Zug zurücknehmen" is just its "↶" (when the label needs a line of
      // its own: a phone with 4 players).
      final width = box.maxWidth - _panelPadding.horizontal;
      final labelled = _panelReserve(width);
      return CustomMultiChildLayout(
        delegate: _PortraitLayout(
            reserve: labelled,
            compactReserve: _panelReserve(width, compactRow: true),
            mainOnlyReserve: _panelReserve(width, row: false)),
        children: [
          LayoutId(id: _Slot.story, child: _storyBox()),
          LayoutId(
              id: _Slot.players, child: Padding(padding: const EdgeInsets.fromLTRB(8, 2, 8, 4), child: _players())),
          LayoutId(id: _Slot.board, child: LayoutBuilder(builder: (context, b) => _board(b.maxWidth))),
          LayoutId(
            id: _Slot.panel,
            child: LayoutBuilder(
              builder: (context, b) => SingleChildScrollView(
                  padding: _panelPadding, child: _panel(compactRow: b.maxHeight < labelled - 0.5)),
            ),
          ),
        ],
      );
    });
  }

  /// Around the action panel under the board (portrait).
  static const _panelPadding = EdgeInsets.fromLTRB(8, 6, 8, 8);

  /// The action panel's padding and border (inside [_panelPadding]).
  static const _panelInset = 10.0 + 1;

  /// The width of the "↶" button alone (a compact [IconButton]).
  static const _undoIconWidth = 40.0;

  /// Whether "Zug zurücknehmen" needs a line of its own in the row at
  /// [width] (inside the panel; a phone): then a compact row
  /// ([_panel]'s `compactRow`) shows only its "↶".
  bool _undoIconOnly(double width, {required bool trade}) {
    final l10n = AppLocalizations.of(context);
    final labels = [l10n.propertyManage, if (trade) l10n.propertyTrade, l10n.shellTakeBack];
    return labels.fold(0.0, (sum, t) => sum + UndoMoveButton.textButtonWidth(context, t)) > width;
  }

  /// The lines the row "Meine Straßen" / "Tauschen" / "Zug zurücknehmen"
  /// takes at [width] (inside the panel; a [Wrap]: a line breaks where the
  /// next button does not fit), with [compact] as in [_panel].
  int _rowRuns(double width, {required bool compact}) {
    final l10n = AppLocalizations.of(context);
    final widths = [
      UndoMoveButton.textButtonWidth(context, l10n.propertyManage),
      UndoMoveButton.textButtonWidth(context, l10n.propertyTrade),
      compact && _undoIconOnly(width, trade: true) ? _undoIconWidth : UndoMoveButton.textButtonWidth(context, l10n.shellTakeBack),
    ];
    var runs = 1;
    var used = 0.0;
    for (final w in widths) {
      if (used > 0 && used + w > width) {
        runs++;
        used = 0;
      }
      used += w;
    }
    return runs;
  }

  /// The height of the action panel with a main button ("Würfeln", "Zug
  /// beenden") and, with [row], the row "Meine Straßen" / "Tauschen" /
  /// "Zug zurücknehmen" as it wraps at [width] (the panel's outer width), at
  /// the current text size, with [compactRow] as in [_panel];
  /// [_panelPadding] included.
  double _panelReserve(double width, {bool row = true, bool compactRow = false}) {
    // A button: 48 high (the tap target), or its label line with padding.
    final button = math.max(48.0, MediaQuery.textScalerOf(context).scale(20) + 16);
    final frame = _panelPadding.vertical + 2 * _panelInset;
    if (!row) return frame + button;
    return frame + button + 6 + _rowRuns(width - 2 * _panelInset, compact: compactRow) * button;
  }

  // ------------------------------------------------------------- players

  Widget _players() {
    final n = game.playerCount;
    return LayoutBuilder(
      key: _playersKey,
      builder: (context, box) {
        final perRow = n <= 2 ? 2 : 2;
        final w = (box.maxWidth - 6 * (perRow - 1)) / perRow;
        return Wrap(
          key: const Key('property-players'),
          spacing: 6,
          runSpacing: 6,
          children: [for (var s = 0; s < n; s++) SizedBox(width: w, child: _playerChip(s))],
        );
      },
    );
  }

  Widget _playerChip(int seat) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final st = game.seats[seat];
    final actor = game.actor == seat;
    final color = seatColor(context, seat);
    return Semantics(
      container: true,
      child: AnimatedContainer(
        key: Key('property-player-$seat'),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 200),
        padding: const EdgeInsetsDirectional.fromSTEB(6, 4, 8, 4),
        decoration: BoxDecoration(
          color: st.out ? theme.colorScheme.surfaceContainerHighest : palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: actor ? visibleOn(context, color, minRatio: 3) : theme.colorScheme.outlineVariant, width: actor ? 2.5 : 1),
        ),
        child: Row(
          children: [
            SeatToken(seat: seat, size: 24, out: st.out),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_name(seat),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: actor ? FontWeight.w800 : FontWeight.w600)),
                  Text(
                    st.out
                        ? l10n.propertyOut
                        : '${_money(_show != null && seat < _cashBefore.length ? _cashBefore[seat] : st.cash)} · '
                            '${l10n.propertyStreets(game.ownedBy(seat).length)}',
                    key: Key('property-cash-$seat'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (st.inPause) Icon(Icons.pause_circle_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
            if (st.freeCards.isNotEmpty) Icon(Icons.confirmation_number_outlined, size: 18, color: palette.trophy),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- board

  /// Row and column (0–10) of [square] on the 11 × 11 grid: Start in the
  /// bottom right corner, then clockwise (left along the bottom, up the
  /// left side, right along the top, down the right side).
  static (int, int) cellOf(int square) {
    if (square <= 10) return (10, 10 - square);
    if (square < 20) return (20 - square, 0);
    if (square <= 30) return (0, square - 20);
    return (square - 30, 10);
  }

  Widget _board(double side) {
    _zoom.layout(side);
    // Pinch to zoom; zoomed in, the squares show the full names.
    return ValueListenableBuilder<Matrix4>(
      valueListenable: _zoom,
      builder: (context, _, _) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: InteractiveViewer(
          transformationController: _zoom,
          minScale: 1,
          maxScale: 4,
          child: _boardAt(side, _zoom.scale),
        ),
      ),
    );
  }

  Widget _boardAt(double side, double scale) {
    final cell = side / 11;
    // Names in zoom steps of a quarter (one size per step, not per frame).
    final steps = (scale * 4).round() / 4;
    final fullNames = cell * steps >= propertyFullNameCell;
    final band = cell * 0.24;
    final nameBox = Size(cell - 2 * cell * _SquareCell.nameAcross, cell - band - 2 * cell * _SquareCell.nameDepth);
    final names = {
      for (final sq in game.theme.squares)
        if (sq.kind == PropertyKind.street) sq.index: fullNames ? propertyBreakable(sq.name) : sq.shortName,
    };
    // Full names in up to three lines (a long word may be split), short
    // forms in two.
    final nameLines = fullNames ? 3 : 2;
    // Measured and drawn in the same style.
    final nameBase = DefaultTextStyle.of(context).style;
    final nameSize = propertyBoardNameSize(names.values, nameBox,
        min: propertyMinNameSize / steps,
        max: (fullNames ? propertyMaxNameSize : 9) / steps,
        base: nameBase,
        lines: nameLines,
        hyphens: fullNames);
    final show = _show;
    final now = show?.at(_anim.value);
    final positions = _positions();
    if (show != null) positions[show.seat] = now!.square;
    // While a roll is shown the target square is outlined.
    final focus = show?.target ?? game.auction?.square ?? game.seats[game.actor ?? game.currentSeat].pos;
    return Directionality(
      // The board is a picture: the same in every language.
      textDirection: TextDirection.ltr,
      child: Container(
        key: _boardKey,
        // The borders are drawn on top (foreground): a border as decoration
        // would pad the squares, and the names are measured for the full
        // square.
        decoration: BoxDecoration(color: const Color(0xFFD9EAD3), borderRadius: BorderRadius.circular(6)),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF2E4B2A), width: 1.5),
        ),
        child: Stack(
          key: const Key('property-board'),
          children: [
            for (var i = 0; i < 40; i++)
              Positioned(
                left: cellOf(i).$2 * cell,
                top: cellOf(i).$1 * cell,
                width: cell,
                height: cell,
                child: _SquareCell(
                  game: game,
                  square: i,
                  size: cell,
                  focus: i == focus,
                  positions: positions,
                  walking: show?.seat,
                  hop: now?.hop ?? 0,
                  name: names[i],
                  nameSize: nameSize,
                  nameBox: nameBox,
                  nameBase: nameBase,
                  nameLines: nameLines,
                  onTap: show != null ? _skip : () => showPropertySquareSheet(context, game, i),
                ),
              ),
            Positioned(
              left: cell,
              top: cell,
              width: cell * 9,
              height: cell * 9,
              child: GestureDetector(
                behavior: show != null ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
                onTap: show != null ? _skip : null,
                child: _BoardCentre(
                  game: game,
                  cell: cell,
                  focus: focus,
                  dice: show?.dice ?? game.dice,
                  rolling: now?.rolling == true ? _anim.value * show!.totalMs / PropertyRollShow.diceMs : null,
                  showFocus: show == null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- actions

  /// The actions; with [compactRow] "Zug zurücknehmen" is just its "↶"
  /// where its label would need a line of its own (portrait, when the room
  /// under the board is short).
  Widget _panel({bool compactRow = false}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    final a = _show == null ? game.actor : null;
    final children = <Widget>[];
    void line(String text, {Key? key, bool strong = false}) => children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text,
              key: key,
              style: strong
                  ? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)
                  : theme.textTheme.bodyMedium),
        ));
    Widget big(Key key, String label, VoidCallback? onPressed, {IconData? icon, GlobalKey? anchor}) {
      final button = FilledButton.icon(
        key: key,
        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.check),
        label: Text(label),
      );
      return anchor == null ? button : KeyedSubtree(key: anchor, child: button);
    }

    Widget other(Key key, String label, VoidCallback? onPressed, {IconData? icon}) => OutlinedButton.icon(
          key: key,
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.close),
          label: Text(label),
        );

    if (_show != null) {
      // The roll is being shown: the buttons wait for the token.
      children.add(big(const Key('property-rolling'), l10n.propertyRoll, null, icon: Icons.casino_outlined));
    }
    if (a != null) {
      final seat = game.seats[a];
      switch (game.phase) {
        case PropertyPhase.roll:
          if (seat.inPause) {
            // The theme's phrase ("steht im Stau auf der A100") in its
            // language (German), else the quoted square name.
            line(switch (game.theme.pauseAt) {
              final at? when l10n.localeName == 'de' => l10n.propertyInPausePhrase(_name(a), at),
              _ => l10n.propertyInPause(_name(a), game.theme.squares[PropertyGame.pauseSquare].name),
            });
          }
          children.add(big(const Key('property-roll'), l10n.propertyRoll, () => _submit({'action': 'roll'}),
              icon: Icons.casino_outlined, anchor: _rollKey));
          if (seat.inPause) {
            children.add(const SizedBox(height: 6));
            children.add(Wrap(spacing: 8, runSpacing: 6, children: [
              other(const Key('property-pay-bail'), l10n.propertyPayBail(_money(PropertyGame.bail)),
                  seat.cash >= PropertyGame.bail ? () => _submit({'action': 'payBail'}) : null,
                  icon: Icons.payments_outlined),
              if (seat.freeCards.isNotEmpty)
                other(const Key('property-use-card'), l10n.propertyUseCard, () => _submit({'action': 'useCard'}),
                    icon: Icons.confirmation_number_outlined),
            ]));
          }
        case PropertyPhase.buy:
          final sq = game.theme.squares[seat.pos];
          line(l10n.propertyFreeToBuy(sq.name), strong: true);
          final can = seat.cash >= sq.price;
          children.add(big(const Key('property-buy'), l10n.propertyBuy(_money(sq.price)),
              can ? () => _submit({'action': 'buy'}) : null,
              icon: Icons.shopping_cart_outlined));
          if (!can) line(l10n.propertyTooPoor);
          children.add(const SizedBox(height: 6));
          children.add(other(const Key('property-decline'), l10n.propertyDecline, () => _submit({'action': 'decline'}),
              icon: Icons.gavel));
        case PropertyPhase.auction:
          final au = game.auction!;
          line(l10n.propertyAuctionTitle(game.theme.squares[au.square].name), strong: true, key: const Key('property-auction'));
          line(au.highSeat == null ? l10n.propertyAuctionNone : l10n.propertyAuctionHigh(_money(au.high), _name(au.highSeat!)));
          line(l10n.propertyAuctionTurn(_name(a)));
          final bids = [
            for (final m in game.legalMoves)
              if (m['action'] == 'bid') m['amount'] as int
          ];
          children.add(Wrap(spacing: 8, runSpacing: 6, children: [
            for (final (i, b) in bids.indexed)
              FilledButton.tonal(
                key: Key('property-bid-$i'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: () => _submit({'action': 'bid', 'amount': b}),
                child: Text(l10n.propertyBid(_money(b))),
              ),
            other(const Key('property-pass'), l10n.propertyPass, () => _submit({'action': 'pass'}), icon: Icons.back_hand_outlined),
          ]));
        case PropertyPhase.trade:
          // The partner answers over the board ([PropertyTradeGate]).
          final t = game.trade!;
          line(l10n.propertyTradeOfferFor(_name(t.from), _name(t.to)), strong: true);
        case PropertyPhase.debt:
          final d = game.debts.first;
          line(l10n.propertyDebt(_name(d.debtor), _money(d.amount), _money(game.seats[d.debtor].cash)),
              strong: true, key: const Key('property-debt'));
          if (game.canDeclareBankruptcy) {
            children.add(FilledButton.icon(
              key: const Key('property-bankrupt'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError),
              onPressed: () => _submit({'action': 'bankrupt'}),
              icon: const Icon(Icons.money_off),
              label: Text(l10n.propertyBankrupt),
            ));
          }
        case PropertyPhase.end:
          children.add(big(const Key('property-end'), l10n.propertyEndTurn, () => _submit({'action': 'endTurn'}),
              icon: Icons.skip_next_rounded));
        case PropertyPhase.over:
          break;
      }
    }
    final canManage = a != null && game.phase != PropertyPhase.auction && game.phase != PropertyPhase.trade;
    return Container(
      key: const Key('property-controls'),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          const SizedBox(height: 6),
          // A Wrap: on a narrow side panel the buttons stack. In a compact
          // row, where the labelled "Zug zurücknehmen" would need a line of
          // its own, just its "↶" (the label is its tooltip).
          LayoutBuilder(builder: (context, box) {
            final trade = a != null && propertyCanTrade(game);
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                KeyedSubtree(
                  key: _manageKey,
                  child: TextButton.icon(
                    key: const Key('property-manage'),
                    onPressed: canManage ? () => showPropertyManageSheet(context, controller, a) : null,
                    icon: const Icon(Icons.holiday_village_outlined),
                    label: Text(l10n.propertyManage),
                  ),
                ),
                if (trade)
                  KeyedSubtree(
                    key: _tradeKey,
                    child: TextButton.icon(
                      key: const Key('property-trade'),
                      onPressed: () => showPropertyTradeSheet(context, controller),
                      icon: const Icon(Icons.swap_horiz),
                      label: Text(l10n.propertyTrade),
                    ),
                  ),
                // Not while a trade offer waits for its answer (the partner
                // may look at the board; the offer is taken back on the
                // handover cover).
                if (game.phase != PropertyPhase.trade)
                  UndoMoveButton(iconOnly: compactRow && _undoIconOnly(box.maxWidth, trade: trade)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

enum _Slot { story, players, board, panel }

/// Portrait ([_PropertyBoardState.build]): the story and the players at
/// their height, then the board as big as the width allows with [reserve]
/// left for the action panel below; the panel takes the rest. Where that
/// would make the board smaller than the width, [compactReserve] (the row
/// with just "↶") is kept instead; where the board would be smaller than
/// [minSide] (an iPhone SE), only [mainOnlyReserve] (the main button) and
/// the row scrolls.
class _PortraitLayout extends MultiChildLayoutDelegate {
  final double reserve;
  final double compactReserve;
  final double mainOnlyReserve;
  _PortraitLayout({required this.reserve, required this.compactReserve, required this.mainOnlyReserve});

  /// The smallest board kept with the whole action panel on screen: below
  /// it the short street names would get smaller than they are made for.
  static const minSide = 240.0;

  @override
  void performLayout(Size size) {
    final w = size.width;
    final story = layoutChild(_Slot.story, BoxConstraints.tightFor(width: w));
    positionChild(_Slot.story, Offset.zero);
    final players = layoutChild(_Slot.players, BoxConstraints.tightFor(width: w));
    positionChild(_Slot.players, Offset(0, story.height));
    final top = story.height + players.height;
    final avail = size.height - top;
    var side = avail - reserve;
    if (side < w - 8) side = avail - compactReserve;
    if (side < minSide) side = math.max(side, math.min(avail - mainOnlyReserve, minSide));
    side = math.max(0.0, math.min(math.min(w - 8, avail), side));
    layoutChild(_Slot.board, BoxConstraints.tight(Size.square(side)));
    positionChild(_Slot.board, Offset((w - side) / 2, top));
    final panelTop = top + side;
    layoutChild(_Slot.panel, BoxConstraints.tightFor(width: w, height: math.max(0.0, size.height - panelTop)));
    positionChild(_Slot.panel, Offset(0, panelTop));
  }

  @override
  bool shouldRelayout(_PortraitLayout old) =>
      old.reserve != reserve || old.compactReserve != compactReserve || old.mainOnlyReserve != mainOnlyReserve;
}

/// One square of the ring: the group's colour band on the side facing the
/// centre, a symbol for the special squares, the owner's colour and
/// buildings, a lock when mortgaged, and the players' tokens.
class _SquareCell extends StatelessWidget {
  final PropertyGame game;
  final int square;
  final double size;
  final bool focus;

  /// Where every seat's token is shown (during a walk not where it stands).
  final List<int> positions;

  /// The seat whose token walks, and its hop (0–1).
  final int? walking;
  final double hop;

  /// The street name (with soft hyphens) written on the square, null for
  /// other squares; the board's one name size and the name's area.
  final String? name;
  final double nameSize;
  final Size nameBox;
  final TextStyle? nameBase;
  final int nameLines;
  final VoidCallback onTap;
  const _SquareCell(
      {required this.game,
      required this.square,
      required this.size,
      required this.focus,
      required this.positions,
      required this.walking,
      required this.hop,
      this.name,
      this.nameSize = 8,
      this.nameBox = Size.zero,
      this.nameBase,
      this.nameLines = 2,
      required this.onTap});

  IconData? get _icon => switch (game.theme.squares[square].kind) {
        PropertyKind.start => Icons.flag_rounded,
        PropertyKind.surprise => Icons.help_outline_rounded,
        PropertyKind.neighbourhood => Icons.mail_outline_rounded,
        PropertyKind.tax => Icons.receipt_long_outlined,
        PropertyKind.station => Icons.train_outlined,
        PropertyKind.utility => square == 12 ? Icons.water_drop_outlined : Icons.cell_tower,
        PropertyKind.pause => Icons.pause_circle_outline,
        PropertyKind.free => Icons.weekend_outlined,
        PropertyKind.goToPause => Icons.block,
        PropertyKind.street => null,
      };

  /// The name's margin (a share of the square) along the side and towards
  /// the edges: little along the side, so long names fit; the borders are
  /// drawn on top.
  static const nameAcross = 0.02, nameDepth = 0.05;

  /// Quarter turns of the name on the side at [row]: every name reads
  /// from the bottom of the screen (the top row upright, both sides from
  /// bottom to top).
  static int _turns(int row) => row == 10 || row == 0 ? 0 : 3;

  /// Where the name sits in its (turned) area: at the square's outer edge,
  /// away from the tokens next to the colour band.
  static Alignment _nameAt(int row, int col) => switch ((row, col)) {
        (10, _) => Alignment.bottomCenter,
        (0, _) => Alignment.topCenter,
        (_, 0) => Alignment.topCenter, // turned: the text's top faces left
        _ => Alignment.bottomCenter,
      };

  Widget _token(int s, double size) => s == walking
      ? Transform.translate(
          key: Key('property-walking-$s'),
          offset: Offset(0, -hop * this.size * 0.22),
          child: SeatToken(seat: s, size: size),
        )
      : SeatToken(seat: s, size: size);

  @override
  Widget build(BuildContext context) {
    final sq = game.theme.squares[square];
    final owner = game.ownerOf(square);
    final houses = game.housesOn(square);
    final mortgaged = game.isMortgaged(square);
    final (row, col) = _PropertyBoardState.cellOf(square);
    final band = size * 0.24;
    // The side that faces the centre.
    final Alignment inner = row == 10
        ? Alignment.topCenter
        : row == 0
            ? Alignment.bottomCenter
            : col == 0
                ? Alignment.centerRight
                : Alignment.centerLeft;
    final horizontal = inner == Alignment.topCenter || inner == Alignment.bottomCenter;
    final ownerColor = owner == null ? null : seatColor(context, owner);
    const ink = Color(0xFF26301F);
    final here = [for (var s = 0; s < game.playerCount; s++) if (!game.seats[s].out && positions[s] == square) s];
    return Semantics(
      button: true,
      label: sq.name,
      child: GestureDetector(
        key: Key('property-square-$square'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          color: ownerColor == null ? const Color(0xFFFFFBF0) : Color.alphaBlend(ownerColor.withValues(alpha: 0.28), Colors.white),
          foregroundDecoration: BoxDecoration(
            border: Border.all(
                color: focus ? Colors.black : (ownerColor ?? const Color(0xFF7A8A70)), width: focus ? 2 : (owner == null ? 0.5 : 1.5)),
          ),
          child: Stack(
            children: [
              if (sq.group >= 0)
                Align(
                  alignment: inner,
                  child: Container(
                    width: horizontal ? double.infinity : band,
                    height: horizontal ? band : double.infinity,
                    color: propertyGroupColor(sq.group),
                    alignment: Alignment.center,
                    child: houses == 0
                        ? null
                        : houses == 5
                            ? Icon(Icons.apartment, size: band * 0.95, color: Colors.white)
                            : Flex(
                                direction: horizontal ? Axis.horizontal : Axis.vertical,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (var h = 0; h < houses; h++)
                                    Container(
                                      width: band * 0.42,
                                      height: band * 0.42,
                                      margin: EdgeInsets.all(band * 0.04),
                                      decoration: BoxDecoration(
                                          color: Colors.white, border: Border.all(color: Colors.black54, width: 0.5)),
                                    ),
                                ],
                              ),
                  ),
                ),
              if (_icon case final icon?)
                Center(child: Icon(icon, size: size * 0.5, color: ink.withValues(alpha: 0.75))),
              if (name case final name?)
                Align(
                  // The part of the square outside the colour band.
                  alignment: Alignment(-inner.x, -inner.y),
                  child: SizedBox(
                    width: horizontal ? size : size - band,
                    height: horizontal ? size - band : size,
                    child: Padding(
                      padding: horizontal
                          ? EdgeInsets.symmetric(horizontal: size * nameAcross, vertical: size * nameDepth)
                          : EdgeInsets.symmetric(horizontal: size * nameDepth, vertical: size * nameAcross),
                      child: RotatedBox(
                        quarterTurns: _turns(row),
                        child: Center(
                          child: SizedBox.fromSize(
                            size: nameBox,
                            child: PropertyFieldName(
                                key: Key('property-name-$square'),
                                text: name,
                                size: nameSize,
                                box: nameBox,
                                base: nameBase,
                                alignment: _nameAt(row, col),
                                lines: nameLines,
                                color: ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (mortgaged)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x88FFFFFF),
                    child: Center(child: Icon(Icons.lock_outline, size: size * 0.4, color: ink)),
                  ),
                ),
              if (here.isNotEmpty && name != null)
                Align(
                  // Next to the colour band, on the inner part of the square:
                  // the name at the outer edge stays readable.
                  alignment: Alignment(inner.x * 0.42, inner.y * 0.42),
                  child: Flex(
                    direction: horizontal ? Axis.horizontal : Axis.vertical,
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final s in here) _token(s, here.length == 1 ? size * 0.36 : size * 0.24)],
                  ),
                )
              else if (here.isNotEmpty)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 0,
                    runSpacing: 0,
                    children: [for (final s in here) _token(s, here.length == 1 ? size * 0.5 : size * 0.42)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The middle of the board: the board's name, the dice, the square in
/// focus (where the player to move stands, or the one auctioned) and the
/// pot.
class _BoardCentre extends StatelessWidget {
  final PropertyGame game;
  final double cell;
  final int focus;

  /// The dice shown.
  final List<int>? dice;

  /// While the dice tumble: how far (0–1); null when they lie still.
  final double? rolling;

  /// False while a roll is shown: the card of the square waits.
  final bool showFocus;
  const _BoardCentre(
      {required this.game,
      required this.cell,
      required this.focus,
      required this.dice,
      required this.rolling,
      required this.showFocus});

  /// A changing face of die [i] while it tumbles (like Ausgewürfelt's).
  int _tumbleFace(int i, double t) => 1 + ((i * 7 + (t * 14).floor() * 5) % 6);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const ink = Color(0xFF26301F);
    final dice = this.dice;
    final t = rolling;
    final usesPot = game.freeSquare == PropertyFreeSquare.pot || game.freeSquare == PropertyFreeSquare.potWithSeed;
    return Padding(
      padding: EdgeInsets.all(cell * 0.35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            PropertyNames.themeTitle(l10n, game.theme).toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
                color: ink.withValues(alpha: 0.55), letterSpacing: 3, fontWeight: FontWeight.w800),
          ),
          if (dice != null)
            Row(
              key: Key(t == null ? 'property-dice' : 'property-dice-rolling'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final i in const [0, 1]) ...[
                  if (i == 1) SizedBox(width: cell * 0.4),
                  // Tumbling: changing faces, turning less and less, a small
                  // bounce; then the result.
                  Transform.translate(
                    offset: Offset(0, t == null ? 0 : -(math.sin(t * math.pi * 3).abs()) * cell * 0.35 * (1 - t)),
                    child: DieFace(
                      value: t == null ? dice[i] : _tumbleFace(i, t),
                      size: cell * 1.25,
                      angle: t == null
                          ? (i == 0 ? -0.12 : 0.1)
                          : math.sin((t + i) * math.pi * 4) * 0.9 * (1 - t) + (i == 0 ? -0.12 : 0.1),
                    ),
                  ),
                ],
              ],
            )
          else
            SizedBox(height: cell * 1.25),
          // The square in focus as a compact deed card (price, rents with the
          // group's buildings, building cost, mortgage; the rent that applies
          // now highlighted). It takes the room left and shrinks if it must;
          // a tap opens the full card.
          Flexible(
            child: Opacity(
              opacity: showFocus ? 1 : 0,
              child: GestureDetector(
                key: Key(showFocus ? 'property-focus' : 'property-focus-waiting'),
                behavior: HitTestBehavior.opaque,
                onTap: showFocus ? () => showPropertySquareSheet(context, game, focus) : null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: math.min(PropertyDeedCard.maxWidth, cell * 7.6),
                    child: PropertyDeedCard(game: game, square: focus, compact: true, keyPrefix: 'property-focus-deed'),
                  ),
                ),
              ),
            ),
          ),
          if (usesPot)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings_outlined, size: 18, color: ink),
                const SizedBox(width: 4),
                Text(l10n.propertyMoney(game.pot),
                    key: const Key('property-pot'), style: theme.textTheme.labelLarge?.copyWith(color: ink)),
              ],
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- sheets

/// The details of [square] as a deed card ([PropertyDeedCard]), with the
/// owner below it; special squares say what they do.
Future<void> showPropertySquareSheet(BuildContext context, PropertyGame game, int square) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final theme = Theme.of(ctx);
      final sq = game.theme.squares[square];
      final owner = game.ownerOf(square);
      return SafeArea(
        child: SingleChildScrollView(
          key: const Key('property-square-sheet'),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Center(
            child: ConstrainedBox(
              // A deed card, not a page: compact and centred.
              constraints: const BoxConstraints(maxWidth: PropertyDeedCard.maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PropertyDeedCard(game: game, square: square),
                  if (sq.isOwnable) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      if (owner != null) ...[SeatToken(seat: owner, size: 22), const SizedBox(width: 8)],
                      Expanded(
                        child: Text(
                          owner == null
                              ? l10n.propertyOwnerNone
                              : l10n.propertyOwnerLine(
                                  SeatLabelsScope.of(context).label(context, l10n, owner, count: game.playerCount)),
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (game.isMortgaged(square)) Text(l10n.propertyMortgaged, style: theme.textTheme.labelLarge),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// One square as a deed card, like the cards of a real board game: a header
/// in the group's colour (or the square's symbol), the price, and the rent
/// table: for a street the plain rent, with the whole colour group, with 1–4
/// small buildings and with the big one (the group's own building names),
/// the building cost and the mortgage value; for a station the rent by the
/// number of stations owned; for a utility the dice factors. Special squares
/// say what they do. Fixed light colours (a printed card, also in dark mode).
/// The rent that applies now (owned, not mortgaged) is highlighted.
///
/// [compact]: the card in the board centre (after a landing, at an auction,
/// with the buy question): the same content, smaller and tighter, the
/// amounts without the currency, building cost and mortgage in one line.
///
/// Keys ([keyPrefix], default `property-deed`): `<prefix>`, `<prefix>-rent-<0..5>`,
/// `<prefix>-rent-group`, `<prefix>-house-cost`, `<prefix>-mortgage`,
/// `<prefix>-stations-<n>`, `<prefix>-utility-<1|2>`, `<prefix>-owner`
/// (compact, owned), `<prefix>-now` (inside the highlighted row).
class PropertyDeedCard extends StatelessWidget {
  final PropertyGame game;
  final int square;
  final bool compact;
  final String keyPrefix;
  const PropertyDeedCard(
      {super.key, required this.game, required this.square, this.compact = false, this.keyPrefix = 'property-deed'});

  /// The card's widest size (a deed card, not a page).
  static const double maxWidth = 300;

  static const _paper = Color(0xFFFFFBF0);
  static const _ink = Color(0xFF26301F);

  /// The rent row that applies now (`rent-0`, `rent-group`, `rent-<h>`,
  /// `stations-<n>`, `utility-<n>`), null if unowned or mortgaged.
  String? _now() {
    final owner = game.ownerOf(square);
    if (owner == null || game.isMortgaged(square)) return null;
    final sq = game.theme.squares[square];
    int owned(PropertyKind kind) =>
        [for (var i = 0; i < 40; i++) if (game.ownerOf(i) == owner && game.theme.squares[i].kind == kind) i].length;
    switch (sq.kind) {
      case PropertyKind.street:
        final h = game.housesOn(square);
        if (h > 0) return 'rent-$h';
        return game.theme.groups[sq.group].every((i) => game.ownerOf(i) == owner) ? 'rent-group' : 'rent-0';
      case PropertyKind.station:
        return 'stations-${owned(PropertyKind.station)}';
      case PropertyKind.utility:
        return 'utility-${owned(PropertyKind.utility)}';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final t = game.theme;
    final sq = t.squares[square];
    final now = _now();
    final owner = game.ownerOf(square);
    String money(int a) => l10n.propertyMoney(a);
    // In the compact card's two-column table the amounts stand without the
    // currency (the price line above names it), like on a printed card.
    String amount(int a) => compact ? '$a' : money(a);
    final base = compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium;
    final body = base?.copyWith(color: _ink, height: compact ? 1.15 : null);
    final small = (compact ? theme.textTheme.labelSmall : theme.textTheme.bodySmall)?.copyWith(color: _ink);
    final strong = body?.copyWith(fontWeight: FontWeight.w700);
    Key k(String id) => Key('$keyPrefix-$id');
    Widget row(String id, String left, String right) {
      final hot = id == now;
      return Container(
        key: k(id),
        padding: EdgeInsets.symmetric(vertical: compact ? 0.5 : 1.5, horizontal: hot ? 3 : 0),
        decoration: hot
            ? BoxDecoration(color: seatColor(context, owner!).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(3))
            : null,
        child: Row(children: [
          if (hot) SizedBox(key: k('now'), width: 0),
          Expanded(child: Text(left, maxLines: 1, overflow: TextOverflow.ellipsis, style: hot ? strong : body)),
          SizedBox(width: compact ? 4 : 8),
          Text(right, style: strong),
        ]),
      );
    }

    Widget centred(String text, {TextStyle? style, Key? key}) => Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 1 : 2),
        child: Text(text, key: key, textAlign: TextAlign.center, style: style ?? body));
    final divider = Divider(height: compact ? 6 : 12, thickness: 1, color: const Color(0x5526301F));
    // Two columns only where the labels are short (stations); a street's
    // rows ("Mit ganzer Farbgruppe", "3 × Trödelstände") need the width.
    List<Widget> table(List<Widget> rows, {bool columns = false}) {
      if (!compact || !columns || rows.length < 3) return rows;
      final half = (rows.length + 1) ~/ 2;
      return [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows.sublist(0, half))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows.sublist(half))),
        ]),
      ];
    }

    // The header: colour band with the group's name, or a symbol.
    final Color band = sq.group >= 0 ? propertyGroupColor(sq.group) : const Color(0xFFE6E0CC);
    final onBand = band.computeLuminance() > 0.45 ? Colors.black : Colors.white;
    final IconData? icon = switch (sq.kind) {
      PropertyKind.station => Icons.train_outlined,
      PropertyKind.utility => square == 12 ? Icons.water_drop_outlined : Icons.cell_tower,
      PropertyKind.tax => Icons.receipt_long_outlined,
      PropertyKind.surprise => Icons.help_outline_rounded,
      PropertyKind.neighbourhood => Icons.mail_outline_rounded,
      PropertyKind.start => Icons.flag_rounded,
      PropertyKind.pause => Icons.pause_circle_outline,
      PropertyKind.free => Icons.weekend_outlined,
      PropertyKind.goToPause => Icons.block,
      PropertyKind.street => null,
    };
    final name = Text(sq.name,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
            ?.copyWith(color: sq.group >= 0 ? onBand : _ink, fontWeight: FontWeight.w800));
    final header = Container(
      color: band,
      padding: compact ? const EdgeInsets.fromLTRB(6, 3, 6, 3) : const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        children: [
          if (sq.group >= 0)
            Text(t.colourGroups[sq.group].name.toUpperCase(),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: onBand, letterSpacing: 1.2, fontSize: compact ? 9 : null)),
          if (icon != null && !compact) Icon(icon, size: 30, color: _ink),
          if (icon != null && compact)
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: _ink),
              const SizedBox(width: 4),
              Flexible(child: name),
            ])
          else
            name,
        ],
      ),
    );

    // The price; on the compact card for an owned property who owns it and
    // the rent now instead.
    Widget priceLine() {
      if (!compact || owner == null) return centred(l10n.propertyPrice(money(sq.price)), style: strong);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SeatToken(seat: owner, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
                game.isMortgaged(square)
                    ? l10n.propertyMortgaged
                    : l10n.propertyRent(money(game.rentFor(square, diceTotal: 7))),
                key: k('owner'),
                style: strong),
          ),
        ]),
      );
    }

    Widget costs({bool houses = true}) => compact
        ? centred(
            [
              if (houses) l10n.propertyHouseCost(money(sq.houseCost)),
              '${l10n.propertyDeedMortgageValue}: ${money(sq.mortgageValue)}',
            ].join(' · '),
            style: small,
            key: k('mortgage'))
        : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (houses) centred(l10n.propertyHouseCost(money(sq.houseCost)), style: small, key: k('house-cost')),
            row('mortgage', l10n.propertyDeedMortgageValue, money(sq.mortgageValue)),
          ]);

    final rows = <Widget>[];
    switch (sq.kind) {
      case PropertyKind.street:
        final g = t.colourGroups[sq.group];
        rows
          ..add(priceLine())
          ..add(divider)
          ..addAll(table([
            row('rent-0', l10n.propertyDeedRent, amount(sq.rents[0])),
            row('rent-group', l10n.propertyDeedRentGroup, amount(sq.rents[0] * 2)),
            for (var h = 1; h <= 5; h++)
              row('rent-$h', h == 5 ? '1 × ${g.big}' : '$h × ${h == 1 ? g.small : g.smallPlural}', amount(sq.rents[h])),
          ]))
          ..add(divider)
          ..add(costs());
      case PropertyKind.station:
        rows
          ..add(priceLine())
          ..add(divider)
          ..add(centred(l10n.propertyStationRents, style: small))
          ..addAll(table([
            for (var n = 1; n <= sq.rents.length; n++)
              row('stations-$n', l10n.propertyDeedStations(n), amount(sq.rents[n - 1])),
          ], columns: true))
          ..add(divider)
          ..add(costs(houses: false));
      case PropertyKind.utility:
        rows
          ..add(priceLine())
          ..add(divider)
          ..addAll([
            for (var n = 1; n <= sq.rents.length && n <= 2; n++)
              row('utility-$n', n == 1 ? l10n.propertyDeedUtilityOne : l10n.propertyDeedUtilityBoth,
                  l10n.propertyDeedDiceTimes(sq.rents[n - 1])),
          ])
          ..add(divider)
          ..add(costs(houses: false));
      case PropertyKind.tax:
        rows.add(centred(l10n.propertyTax(money(sq.amount))));
      case PropertyKind.surprise:
        rows.add(centred(l10n.propertyCardSquare(t.deckTitles[PropertyDeck.surprise] ?? '')));
      case PropertyKind.neighbourhood:
        rows.add(centred(l10n.propertyCardSquare(t.deckTitles[PropertyDeck.neighbourhood] ?? '')));
      case PropertyKind.start:
        rows.add(centred(l10n.propertyStartSquare(money(PropertyGame.startSalary))));
      case PropertyKind.pause:
        rows.add(centred(l10n.propertyPauseSquare));
      case PropertyKind.goToPause:
        rows.add(centred(l10n.propertyGoToPauseSquare));
      case PropertyKind.free:
        rows.add(centred(switch (game.freeSquare) {
          PropertyFreeSquare.none => l10n.propertyFreeNone,
          PropertyFreeSquare.pot => l10n.propertyFreeExplain,
          PropertyFreeSquare.potWithSeed => l10n.propertyFreeExplain,
          PropertyFreeSquare.fixedBonus => l10n.propertyFreeBonusExplain(sq.name, money(game.freeSquareAmount)),
        }));
    }
    return Container(
      key: Key(keyPrefix),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _ink, width: compact ? 1 : 1.5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      padding: EdgeInsets.all(compact ? 3 : 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(3), child: header),
          Padding(
              padding: compact ? const EdgeInsets.fromLTRB(5, 3, 5, 1) : const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows)),
        ],
      ),
    );
  }
}

/// "Meine Straßen" of [seat] (the player who must move): every property
/// with its buildings and what may be done now (build, sell, mortgage,
/// lift the mortgage). The sheet stays open and follows the game.
Future<void> showPropertyManageSheet(BuildContext context, GameController controller, int seat) {
  final labels = SeatLabelsScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SeatLabelsScope(
      labels: labels,
      child: ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) {
          final game = controller.game as PropertyGame;
          final l10n = AppLocalizations.of(ctx);
          final theme = Theme.of(ctx);
          final t = game.theme;
          String money(int a) => l10n.propertyMoney(a);
          final owned = game.ownedBy(seat)
            ..sort((x, y) {
              final gx = t.squares[x].group < 0 ? 99 : t.squares[x].group, gy = t.squares[y].group < 0 ? 99 : t.squares[y].group;
              return gx != gy ? gx - gy : x - y;
            });
          void go(String action, int square) => controller.submit({'action': action, 'square': square});
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.75),
              child: ListView(
                key: const Key('property-manage-sheet'),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Row(children: [
                    SeatToken(seat: seat, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l10n.propertyManageOf(labels.label(ctx, l10n, seat, count: game.playerCount)),
                          style: theme.textTheme.titleLarge),
                    ),
                    Text(money(game.seats[seat].cash), style: theme.textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 8),
                  if (owned.isEmpty) Text(l10n.propertyManageEmpty, style: theme.textTheme.bodyLarge),
                  for (final i in owned)
                    Container(
                      key: Key('property-manage-row-$i'),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Container(
                              width: 14,
                              height: 14,
                              margin: const EdgeInsetsDirectional.only(end: 8),
                              decoration: BoxDecoration(
                                  color: t.squares[i].group < 0 ? theme.colorScheme.outline : propertyGroupColor(t.squares[i].group),
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            Expanded(child: Text(t.squares[i].name, style: theme.textTheme.titleSmall)),
                            if (game.housesOn(i) > 0)
                              Text('${game.housesOn(i) == 5 ? 1 : game.housesOn(i)} × ${PropertyNames.building(t, i, game.housesOn(i))}',
                                  style: theme.textTheme.bodySmall),
                            if (game.isMortgaged(i)) Text(l10n.propertyMortgaged, style: theme.textTheme.labelMedium),
                            // The street's deed card (rents, building cost).
                            IconButton(
                              key: Key('property-manage-deed-$i'),
                              tooltip: t.squares[i].name,
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => showPropertySquareSheet(context, game, i),
                            ),
                          ]),
                          Wrap(spacing: 6, runSpacing: 4, children: [
                            if (game.canBuild(seat, i))
                              FilledButton.tonal(
                                key: Key('property-manage-build-$i'),
                                onPressed: () => go('build', i),
                                child: Text(l10n.propertyBuild(money(t.squares[i].houseCost))),
                              ),
                            if (game.canSell(seat, i))
                              OutlinedButton(
                                key: Key('property-manage-sell-$i'),
                                onPressed: () => go('sell', i),
                                child: Text(l10n.propertySell(money(t.squares[i].houseCost ~/ 2))),
                              ),
                            if (game.canMortgage(seat, i))
                              OutlinedButton(
                                key: Key('property-manage-mortgage-$i'),
                                onPressed: () => go('mortgage', i),
                                child: Text(l10n.propertyMortgage(money(t.squares[i].mortgageValue))),
                              ),
                            if (game.canUnmortgage(seat, i))
                              OutlinedButton(
                                key: Key('property-manage-unmortgage-$i'),
                                onPressed: () => go('unmortgage', i),
                                child: Text(l10n.propertyUnmortgage(money(t.squares[i].unmortgageCost))),
                              ),
                          ]),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

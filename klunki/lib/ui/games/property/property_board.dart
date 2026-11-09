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
import 'property_roll_show.dart';
import 'property_screen.dart';

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
/// `property-end`, `property-bankrupt`, `property-trade-accept`,
/// `property-trade-decline`, `property-manage`, `property-manage-sheet`,
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

class _PropertyBoardState extends State<PropertyBoard> with SingleTickerProviderStateMixin {
  final _rollKey = GlobalKey(debugLabel: 'property-roll');
  final _boardKey = GlobalKey(debugLabel: 'property-board');
  final _playersKey = GlobalKey(debugLabel: 'property-players');
  final _manageKey = GlobalKey(debugLabel: 'property-manage');
  bool _coachPending = false;
  bool _coachOpen = false;
  /// What happened in the turn so far (else in the turn before).
  String? _story;

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
      // Portrait: the players, the board as big as fits with room for the
      // actions, the actions (scrolling when they need more room).
      final side = math.min(box.maxWidth - 8, math.max(220.0, box.maxHeight - 250));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _storyBox(),
          Padding(padding: const EdgeInsets.fromLTRB(8, 2, 8, 4), child: _players()),
          Center(child: SizedBox.square(dimension: side, child: _board(side))),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: _panel(),
            ),
          ),
        ],
      );
    });
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
    final cell = side / 11;
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
        decoration: BoxDecoration(
          color: const Color(0xFFD9EAD3),
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

  Widget _panel() {
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
          if (seat.inPause) line(l10n.propertyInPause(_name(a), game.theme.squares[PropertyGame.pauseSquare].name));
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
          children.add(Wrap(spacing: 8, runSpacing: 6, children: [
            big(const Key('property-trade-accept'), MaterialLocalizations.of(context).okButtonLabel,
                () => _submit({'action': 'tradeAccept'})),
            other(const Key('property-trade-decline'), l10n.shellCancel, () => _submit({'action': 'tradeDecline'})),
          ]));
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
          // A Wrap: on a narrow side panel the two buttons stack.
          Wrap(
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
              const UndoMoveButton(),
            ],
          ),
        ],
      ),
    );
  }
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
  final VoidCallback onTap;
  const _SquareCell(
      {required this.game,
      required this.square,
      required this.size,
      required this.focus,
      required this.positions,
      required this.walking,
      required this.hop,
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
          decoration: BoxDecoration(
            color: ownerColor == null ? const Color(0xFFFFFBF0) : Color.alphaBlend(ownerColor.withValues(alpha: 0.28), Colors.white),
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
              if (mortgaged)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0x88FFFFFF),
                    child: Center(child: Icon(Icons.lock_outline, size: size * 0.4, color: ink)),
                  ),
                ),
              if (here.isNotEmpty)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 0,
                    runSpacing: 0,
                    children: [
                      for (final s in here)
                        s == walking
                            ? Transform.translate(
                                key: Key('property-walking-$s'),
                                offset: Offset(0, -hop * size * 0.22),
                                child: SeatToken(seat: s, size: here.length == 1 ? size * 0.5 : size * 0.42),
                              )
                            : SeatToken(seat: s, size: here.length == 1 ? size * 0.5 : size * 0.42),
                    ],
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
    final sq = game.theme.squares[focus];
    final owner = game.ownerOf(focus);
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
          // The square in focus, as a small card.
          Opacity(
            opacity: showFocus ? 1 : 0,
            child: Container(
              key: Key(showFocus ? 'property-focus' : 'property-focus-waiting'),
              constraints: BoxConstraints(maxWidth: cell * 6.5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF0),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF7A8A70)),
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sq.group >= 0) Container(height: cell * 0.35, color: propertyGroupColor(sq.group)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Column(
                      children: [
                        Text(sq.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w800)),
                        if (sq.isOwnable)
                          Text(
                            owner == null ? l10n.propertyPrice(l10n.propertyMoney(sq.price)) : '',
                            style: theme.textTheme.bodySmall?.copyWith(color: ink),
                          ),
                        if (owner != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SeatToken(seat: owner, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  game.isMortgaged(focus)
                                      ? l10n.propertyMortgaged
                                      : l10n.propertyRent(l10n.propertyMoney(game.rentFor(focus, diceTotal: 7))),
                                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
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

/// The details of [square]: name, group, price, rents, building cost and
/// owner (streets, stations, utilities), or what the special square does.
Future<void> showPropertySquareSheet(BuildContext context, PropertyGame game, int square) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);
      final theme = Theme.of(ctx);
      final t = game.theme;
      final sq = t.squares[square];
      final owner = game.ownerOf(square);
      String money(int a) => l10n.propertyMoney(a);
      final rows = <Widget>[];
      Widget row(String left, String right, {bool strong = false}) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Expanded(child: Text(left, style: strong ? theme.textTheme.titleSmall : theme.textTheme.bodyMedium)),
              Text(right, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          );
      switch (sq.kind) {
        case PropertyKind.street:
          final g = t.colourGroups[sq.group];
          rows.add(Text(g.name, style: theme.textTheme.labelLarge));
          rows.add(row(l10n.propertyPrice(money(sq.price)), ''));
          rows.add(row(l10n.propertyRent(money(sq.rents[0])), ''));
          rows.add(Text(l10n.propertyRentGroup, style: theme.textTheme.bodySmall));
          for (var h = 1; h <= 5; h++) {
            rows.add(row('${h == 5 ? 1 : h} × ${h == 5 ? g.big : (h == 1 ? g.small : g.smallPlural)}', money(sq.rents[h])));
          }
          rows.add(Text(l10n.propertyHouseCost(money(sq.houseCost)), style: theme.textTheme.bodySmall));
        case PropertyKind.station:
          rows.add(row(l10n.propertyPrice(money(sq.price)), ''));
          rows.add(Text(l10n.propertyStationRents, style: theme.textTheme.bodyMedium));
          for (var k = 1; k <= 4; k++) {
            rows.add(row('$k ×', money(25 * (1 << (k - 1)))));
          }
        case PropertyKind.utility:
          rows.add(row(l10n.propertyPrice(money(sq.price)), ''));
          rows.add(Text(l10n.propertyUtilityRent, style: theme.textTheme.bodyMedium));
        case PropertyKind.tax:
          rows.add(Text(l10n.propertyTax(money(sq.amount)), style: theme.textTheme.bodyLarge));
        case PropertyKind.surprise:
          rows.add(Text(l10n.propertyCardSquare(t.deckTitles[PropertyDeck.surprise] ?? ''), style: theme.textTheme.bodyLarge));
        case PropertyKind.neighbourhood:
          rows.add(
              Text(l10n.propertyCardSquare(t.deckTitles[PropertyDeck.neighbourhood] ?? ''), style: theme.textTheme.bodyLarge));
        case PropertyKind.start:
          rows.add(Text(l10n.propertyStartSquare(money(PropertyGame.startSalary)), style: theme.textTheme.bodyLarge));
        case PropertyKind.pause:
          rows.add(Text(l10n.propertyPauseSquare, style: theme.textTheme.bodyLarge));
        case PropertyKind.goToPause:
          rows.add(Text(l10n.propertyGoToPauseSquare, style: theme.textTheme.bodyLarge));
        case PropertyKind.free:
          rows.add(Text(switch (game.freeSquare) {
            PropertyFreeSquare.none => l10n.propertyFreeNone,
            PropertyFreeSquare.pot => l10n.propertyFreeExplain,
            PropertyFreeSquare.potWithSeed => l10n.propertyFreeExplain,
            PropertyFreeSquare.fixedBonus => l10n.propertyFreeBonusExplain(sq.name, money(game.freeSquareAmount)),
          }, style: theme.textTheme.bodyLarge));
      }
      if (sq.isOwnable) {
        rows.add(const Divider());
        rows.add(Row(children: [
          if (owner != null) ...[SeatToken(seat: owner, size: 22), const SizedBox(width: 8)],
          Expanded(
            child: Text(
              owner == null
                  ? l10n.propertyOwnerNone
                  : l10n.propertyOwnerLine(SeatLabelsScope.of(context).label(context, l10n, owner, count: game.playerCount)),
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (game.isMortgaged(square)) Text(l10n.propertyMortgaged, style: theme.textTheme.labelLarge),
        ]));
      }
      return SafeArea(
        child: SingleChildScrollView(
          key: const Key('property-square-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                if (sq.group >= 0)
                  Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsetsDirectional.only(end: 8),
                      decoration: BoxDecoration(color: propertyGroupColor(sq.group), borderRadius: BorderRadius.circular(4))),
                Expanded(child: Text(sq.name, style: theme.textTheme.titleLarge)),
              ]),
              const SizedBox(height: 8),
              ...rows,
            ],
          ),
        ),
      );
    },
  );
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

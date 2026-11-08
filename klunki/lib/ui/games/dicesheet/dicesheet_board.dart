import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../shell/game_screen.dart';
import '../../shell/seat_game_screen.dart';
import '../maexchen/maexchen_dice.dart' show DieFace;
import '../shake_to_roll.dart';
import 'dicesheet_screen.dart' show diceBoxName;

/// The Ausgewürfelt board (KLD-119): the score sheet with a column per
/// player on top, the five dice and "Würfeln" pinned below it (beside it on
/// a wide, low screen), so the dice and the button never scroll away.
///
/// * "Würfeln (noch 2)": up to three rolls a turn; shaking the phone rolls
///   too ([ShakeToRoll], the shared setting).
/// * After a roll, tapping a die keeps it (lifted, framed in the player's
///   colour, a lock and "behalten" under it); a second tap lets it go.
/// * The sheet shows in the column of the player to move what every empty
///   box would score with these dice; a tap writes it (a 0 strikes the box).
///   A mis-tap: "Zug zurück" takes the entry back until the next player
///   rolls (a roll itself is final, `GameSpec.undoBarrier`).
/// * The upper section shows the way to the bonus ("41/63", then "+35"),
///   the header the names and the round, the footer the totals.
class DiceSheetBoard extends StatefulWidget {
  final GameController controller;
  const DiceSheetBoard({super.key, required this.controller});

  @override
  State<DiceSheetBoard> createState() => _DiceSheetBoardState();
}

class _DiceSheetBoardState extends State<DiceSheetBoard> with SingleTickerProviderStateMixin {
  late final AnimationController _rollAnim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  final Set<int> _keep = {};

  /// The positions that tumble in the running roll animation.
  Set<int> _tumbling = const {};
  late int _seen = widget.controller.moves.length;

  GameController get controller => widget.controller;
  DiceSheetGame get game => controller.game as DiceSheetGame;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
    _restoreKeep();
  }

  @override
  void didUpdateWidget(DiceSheetBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _seen = controller.moves.length;
      _keep.clear();
      _restoreKeep();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    _rollAnim.dispose();
    super.dispose();
  }

  /// After an undo back to a roll: the dice that roll kept stay kept.
  void _restoreKeep() {
    final moves = controller.moves;
    if (game.rollsUsed == 0 || moves.isEmpty || moves.last.move['action'] != 'roll') return;
    _keep.addAll((moves.last.move['keep'] as List? ?? const []).cast<int>());
  }

  void _onChange() {
    if (!mounted) return;
    final moves = controller.moves;
    final grew = moves.length > _seen;
    final changed = moves.length != _seen;
    _seen = moves.length;
    setState(() {
      if (game.rollsUsed == 0 || game.isOver) {
        _keep.clear();
      } else if (changed && !grew) {
        _keep.clear();
        _restoreKeep();
      }
    });
    if (grew && moves.last.move['action'] == 'roll') {
      final kept = (moves.last.move['keep'] as List? ?? const []).cast<int>().toSet();
      _tumbling = {for (var i = 0; i < DiceSheetGame.diceCount; i++) if (!kept.contains(i)) i};
      if (reduceMotion(context)) {
        _tumbling = const {};
        HapticFeedback.mediumImpact();
      } else {
        _rollAnim.forward(from: 0).then((_) {
          if (!mounted) return;
          setState(() => _tumbling = const {});
          HapticFeedback.mediumImpact();
        });
      }
    }
  }

  bool get _myTurn => controller.canAct && !game.isOver;

  bool get _canRoll => _myTurn && game.canRoll;

  /// Keeping is possible between rolls (after the first, before the last).
  bool get _canKeep => _myTurn && game.rollsUsed > 0 && game.rollsLeft > 0;

  void _roll({bool shaken = false}) {
    if (!_canRoll) return;
    if (!shaken) ShakeToRoll.askPermissionFromTap();
    controller.submit(DiceSheetGame.rollMove(game.rollsUsed == 0 ? const [] : _keep));
  }

  void _toggle(int i) {
    if (!_canKeep) return;
    HapticFeedback.selectionClick();
    setState(() => _keep.contains(i) ? _keep.remove(i) : _keep.add(i));
  }

  void _score(DiceBox box) {
    if (!_myTurn || !game.canScore) return;
    controller.submit(DiceSheetGame.scoreMove(box));
  }

  String _name(int seat) =>
      SeatLabelsScope.of(context).label(context, AppLocalizations.of(context), seat, count: game.playerCount);

  /// The hint line: what just happened and what to do now.
  String? _hint(AppLocalizations l10n) {
    if (game.isOver) return null;
    if (game.rollsUsed == 0) {
      final last = controller.moves.isEmpty ? null : controller.moves.last;
      final p = last?.event.payload;
      final before = last != null && last.move['action'] == 'score' && p is Map
          ? '${l10n.dicesheetLastScore(_name(last.seat), diceBoxName(l10n, DiceBox.byId(p['scored'])!), p['points'] as int)} '
          : '';
      return '$before${l10n.dicesheetHintRoll}';
    }
    if (game.isJoker) return l10n.dicesheetHintJoker;
    return game.rollsLeft > 0 ? l10n.dicesheetHintKeep : l10n.dicesheetHintPick;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    GameScreen.of(context).setHint(_hint(l10n));
    return ShakeToRoll(
      enabled: _canRoll,
      onShake: () => _roll(shaken: true),
      builder: (context, shakeReady) => LayoutBuilder(builder: (context, box) => _layout(context, l10n, box, shakeReady)),
    );
  }

  Widget _layout(BuildContext context, AppLocalizations l10n, BoxConstraints box, bool shakeReady) {
    final wide = box.maxWidth >= 600 && box.maxWidth > box.maxHeight * 1.15;
    final sheet = _ScoreSheet(
      game: game,
      name: _name,
      active: _myTurn && game.canScore,
      onScore: _score,
      lastScored: _lastScored,
    );
    final controls = game.isOver ? null : _controls(context, l10n, shakeReady, narrow: box.maxWidth < 420);
    if (wide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 8), child: sheet),
              ),
              if (controls != null)
                SizedBox(
                  width: min(400.0, box.maxWidth * 0.42),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 12, 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Flexible(child: SingleChildScrollView(child: controls))],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(8, 2, 8, 0), child: sheet)),
            if (controls != null) Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 6), child: controls),
          ],
        ),
      ),
    );
  }

  /// The box filled last (to show it for a moment), while the next player
  /// has not rolled yet.
  (int, DiceBox)? get _lastScored {
    final moves = controller.moves;
    if (moves.isEmpty || game.rollsUsed > 0) return null;
    final m = moves.last;
    if (m.move['action'] != 'score') return null;
    final b = DiceBox.byId(m.move['box']);
    return b == null ? null : (m.seat, b);
  }

  Widget _controls(BuildContext context, AppLocalizations l10n, bool shakeReady, {required bool narrow}) {
    final theme = Theme.of(context);
    final seat = game.currentSeat;
    final color = seatColor(context, seat);
    final dice = game.dice;
    return Column(
      key: const Key('dicesheet-controls'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, box) {
          // Each die adds 12 for its frame; at least 4 between them.
          final size = min(64.0, (box.maxWidth - 5 * 12 - 4 * 4) / 5);
          return Directionality(
            // Dice positions read left to right in every language.
            textDirection: TextDirection.ltr,
            child: AnimatedBuilder(
              animation: _rollAnim,
              builder: (context, _) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < DiceSheetGame.diceCount; i++)
                    _DieButton(
                      key: Key('dicesheet-die-$i'),
                      value: dice.isEmpty ? null : (_tumbling.contains(i) ? _tumbleFace(i) : dice[i]),
                      angle: _tumbling.contains(i) ? sin((_rollAnim.value + i) * pi * 4) * 0.35 * (1 - _rollAnim.value) : 0,
                      kept: _keep.contains(i) && game.rollsLeft > 0,
                      color: color,
                      size: size,
                      onTap: _canKeep ? () => _toggle(i) : null,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: shakeReady && _canRoll
                  ? Row(
                      key: const Key('dicesheet-shake-hint'),
                      children: [
                        Icon(Icons.vibration, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(l10n.maexchenShakeHint,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const UndoMoveButton(),
          ],
        ),
        const SizedBox(height: 2),
        FilledButton(
          key: const Key('dicesheet-roll'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          onPressed: _canRoll ? _roll : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_canRoll ? Icons.casino_outlined : Icons.touch_app_outlined),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  _canRoll ? l10n.dicesheetRollButton(game.rollsLeft) : l10n.dicesheetPickBox,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_canRoll) ...[
                const SizedBox(width: 10),
                _RollPips(left: game.rollsLeft, color: theme.colorScheme.onPrimary),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// A changing face while die [i] tumbles.
  int _tumbleFace(int i) => 1 + ((i * 7 + (_rollAnim.value * 14).floor() * 5) % 6);
}

/// Three small pips on the roll button: the rolls left this turn.
class _RollPips extends StatelessWidget {
  final int left;
  final Color color;
  const _RollPips({required this.left, required this.color});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < DiceSheetGame.maxRolls; i++)
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < left ? color : Colors.transparent,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
          ],
        ),
      );
}

/// One die: the face (an empty slot before the first roll), lifted and
/// framed in [color] with a lock and "behalten" when [kept].
class _DieButton extends StatelessWidget {
  final int? value;
  final double angle;
  final bool kept;
  final Color color;
  final double size;
  final VoidCallback? onTap;
  const _DieButton(
      {super.key,
      required this.value,
      required this.angle,
      required this.kept,
      required this.color,
      required this.size,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final v = value;
    final duration = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 160);
    final face = v == null
        ? Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.18),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
            ),
          )
        : DieFace(value: v, size: size, angle: angle);
    return Semantics(
      button: onTap != null,
      selected: kept,
      label: v == null ? null : (kept ? l10n.dicesheetDieKept(v) : l10n.dicesheetDie(v)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                duration: duration,
                offset: Offset(0, kept ? -0.06 : 0),
                child: AnimatedContainer(
                  duration: duration,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.22),
                    border: Border.all(color: kept ? color : Colors.transparent, width: 3),
                    color: kept ? color.withValues(alpha: 0.18) : Colors.transparent,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      face,
                      if (kept)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            child: Icon(Icons.lock, size: 13, color: inkOn(color)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 18,
                width: size + 6,
                child: kept
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l10n.dicesheetKept,
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: visibleOn(context, color), fontWeight: FontWeight.w700),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The score sheet: a header with the players (pinned), the 13 boxes with
/// the bonus row (scrolls), the totals (pinned).
class _ScoreSheet extends StatelessWidget {
  final DiceSheetGame game;
  final String Function(int seat) name;

  /// The player to move may fill a box now.
  final bool active;
  final void Function(DiceBox box) onScore;
  final (int, DiceBox)? lastScored;

  const _ScoreSheet(
      {required this.game, required this.name, required this.active, required this.onScore, required this.lastScored});

  int get n => game.playerCount;

  Map<int, TableColumnWidth> get _widths => {0: FlexColumnWidth(n == 2 ? 1.8 : (n == 3 ? 1.5 : 1.3))};

  int? get _current => game.isOver ? null : game.currentSeat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = KlunkiPalette.of(context);
    return Container(
      key: const Key('dicesheet-sheet'),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _table(context, [_header(context)]),
          Divider(height: 1, thickness: 1.5, color: theme.colorScheme.outline),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('dicesheet-sheet-scroll'),
              child: _table(context, [
                for (final b in DiceBox.upperBoxes) _boxRow(context, b),
                _bonusRow(context),
                for (final b in DiceBox.lowerBoxes) _boxRow(context, b),
                if (game.extraFives) _extraRow(context),
              ]),
            ),
          ),
          Divider(height: 1, thickness: 1.5, color: theme.colorScheme.outline),
          _table(context, [_totalRow(context)]),
        ],
      ),
    );
  }

  Widget _table(BuildContext context, List<TableRow> rows) => Table(
        columnWidths: _widths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows,
      );

  /// The column of [seat]: tinted for the player to move, faded for a seat
  /// that left.
  BoxDecoration? _column(BuildContext context, int seat) =>
      seat == _current ? BoxDecoration(color: seatColor(context, seat).withValues(alpha: 0.12)) : null;

  Widget _cell(BuildContext context, int seat, Widget child, {Key? key, double minHeight = 40}) => Opacity(
        key: key,
        opacity: game.isSeatOut(seat) ? 0.4 : 1,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          alignment: Alignment.center,
          decoration: _column(context, seat),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: child,
        ),
      );

  TableRow _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TableRow(children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
        child: Text(
          l10n.dicesheetRound(game.round, DiceSheetGame.rounds),
          key: const Key('dicesheet-round'),
          maxLines: 2,
          style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
      for (var s = 0; s < n; s++)
        _cell(
          context,
          s,
          key: Key('dicesheet-head-$s'),
          minHeight: 52,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SeatToken(seat: s, size: 22, out: game.isSeatOut(s)),
              const SizedBox(height: 2),
              Text(
                name(s),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: s == _current ? FontWeight.w800 : FontWeight.w500),
              ),
              if (s == _current)
                Container(
                    height: 3, margin: const EdgeInsets.only(top: 2), width: 28, color: visibleOn(context, seatColor(context, s))),
            ],
          ),
        ),
    ]);
  }

  Widget _label(BuildContext context, String text, {Widget? leading, String? sub}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 4, top: 2, bottom: 2),
      child: Row(
        children: [
          if (leading != null) ...[leading, const SizedBox(width: 6)],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FitLabel(text, style: theme.textTheme.bodyMedium),
                if (sub != null)
                  Text(sub,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _boxRow(BuildContext context, DiceBox box) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final last = lastScored;
    return TableRow(
      key: ValueKey('row-${box.id}'),
      children: [
        _label(context, diceBoxName(l10n, box),
            leading: box.upper ? DieFace(value: box.face, size: 18) : null),
        for (var s = 0; s < n; s++)
          _cell(
            context,
            s,
            key: Key('dicesheet-cell-$s-${box.id}'),
            () {
              final entry = game.entryOf(s, box);
              if (entry != null) {
                final fresh = last != null && last.$1 == s && last.$2 == box;
                return Container(
                  key: fresh ? const Key('dicesheet-fresh') : null,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: fresh
                      ? BoxDecoration(
                          color: seatColor(context, s).withValues(alpha: 0.28), borderRadius: BorderRadius.circular(8))
                      : null,
                  child: Text('$entry',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: entry == 0 ? theme.colorScheme.onSurfaceVariant : null,
                          decoration: entry == 0 ? TextDecoration.lineThrough : null)),
                );
              }
              final points = s == _current && active ? game.scoreIfFilled(box) : null;
              if (points == null) return const SizedBox.shrink();
              return _Suggestion(
                key: Key('dicesheet-score-${box.id}'),
                points: points,
                color: seatColor(context, s),
                label: l10n.dicesheetScoreAction(diceBoxName(l10n, box), points),
                onTap: () => onScore(box),
              );
            }(),
          ),
      ],
    );
  }

  TableRow _bonusRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TableRow(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
      children: [
        _label(context, l10n.dicesheetBonus, sub: l10n.dicesheetBonusRule('\u2066+${DiceSheetGame.upperBonus}\u2069', DiceSheetGame.upperBonusAt)),
        for (var s = 0; s < n; s++)
          _cell(
            context,
            s,
            key: Key('dicesheet-bonus-$s'),
            game.upperBonusOf(s) > 0
                ? Text('+${DiceSheetGame.upperBonus}',
                    textDirection: TextDirection.ltr,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: visibleOn(context, const Color(0xFF2E8B57))))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${game.upperSumOf(s)}/${DiceSheetGame.upperBonusAt}',
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: min(1, game.upperSumOf(s) / DiceSheetGame.upperBonusAt),
                            minHeight: 4,
                            color: seatColor(context, s),
                            backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }

  TableRow _extraRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TableRow(children: [
      _label(context, l10n.dicesheetExtraFives),
      for (var s = 0; s < n; s++)
        _cell(
          context,
          s,
          key: Key('dicesheet-extra-$s'),
          Text(game.extraBonusOf(s) > 0 ? '+${game.extraBonusOf(s)}' : '',
              textDirection: TextDirection.ltr,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
    ]);
  }

  TableRow _totalRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return TableRow(children: [
      _label(context, l10n.dicesheetTotal),
      for (var s = 0; s < n; s++)
        _cell(
          context,
          s,
          key: Key('dicesheet-total-$s'),
          minHeight: 42,
          Text('${game.totalOf(s)}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ),
    ]);
  }
}

/// What an empty box would score now: a framed number in the player's
/// colour; a tap writes it. A 0 (striking the box) is quieter.
class _Suggestion extends StatelessWidget {
  final int points;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _Suggestion({super.key, required this.points, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zero = points == 0;
    final edge = zero ? theme.colorScheme.outline : visibleOn(context, color, minRatio: 2);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: zero ? Colors.transparent : color.withValues(alpha: 0.16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: edge, width: zero ? 1.2 : 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 34),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '$points',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: zero ? FontWeight.w400 : FontWeight.w800,
                    color: zero ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A box name in the narrow first column: on one line when it fits, else
/// wrapped between words, and a word that is still too long is scaled down
/// rather than broken in the middle ("Zweie-r").
class _FitLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const _FitLabel(this.text, {this.style});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final scaler = MediaQuery.textScalerOf(context);
        final dir = Directionality.of(context);
        final merged = DefaultTextStyle.of(context).style.merge(style);
        double widest(String t) {
          final p = TextPainter(text: TextSpan(text: t, style: merged), textDirection: dir, textScaler: scaler)
            ..layout();
          final w = p.width;
          p.dispose();
          return w;
        }

        final words = text.split(' ');
        final longest = words.map(widest).fold<double>(0, (a, b) => a > b ? a : b);
        if (longest <= box.maxWidth) return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(words.join('\n'), style: style),
        );
      });
}

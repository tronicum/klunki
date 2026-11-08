import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../profile/beginner_settings.dart';
import '../../../profile/seen_tips.dart';
import '../../shell/coach_marks.dart';
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
///   the header the names, the round and the boxes still free, the footer
///   the totals. A filled box looks used (a solid chip with a check), an
///   empty one like an open slot.
/// * Anfängermodus ([BeginnerSettings], on by default): after the last roll
///   (or with a big box already made) the box [DiceSheetAdvisor] recommends
///   glows in the sheet and a tip bubble above the dice says why, with
///   "Anfängermodus beenden"; while rolls are left a "Tipp" button shows
///   which dice to keep. Advice only: any box can be tapped as before.
/// * The first game on a device starts with a short tour ([showCoachMarks],
///   [SeenTips.dicesheetIntro]); "Kurz erklärt" in the "⋮" menu ([tour])
///   shows it again.
class DiceSheetBoard extends StatefulWidget {
  final GameController controller;

  /// Asks for the tour again ("Kurz erklärt").
  final DiceSheetTourRequest? tour;
  const DiceSheetBoard({super.key, required this.controller, this.tour});

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

  // Targets of the tour and of the tip.
  final _rollKey = GlobalKey(debugLabel: 'dicesheet-roll');
  final _diceKey = GlobalKey(debugLabel: 'dicesheet-dice');
  final _sheetKey = GlobalKey(debugLabel: 'dicesheet-sheet');
  final _boxKey = GlobalKey(debugLabel: 'dicesheet-box');
  final _tipCellKey = GlobalKey(debugLabel: 'dicesheet-tip-cell');

  /// The "Tipp" button was tapped this roll (keep advice while rolls are left).
  bool _tipOpen = false;

  /// On a short screen the tip shows its first line only until tapped.
  bool _tipExpanded = false;
  bool _coachPending = false;
  bool _coachOpen = false;

  /// The move count the recommended box was last scrolled into view for.
  int? _revealedFor;

  GameController get controller => widget.controller;
  DiceSheetGame get game => controller.game as DiceSheetGame;
  BeginnerSettings get _beginner => BeginnerSettings.shared();

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
    _beginner.addListener(_onSettings);
    widget.tour?.addListener(_replayTour);
    _restoreKeep();
  }

  void _onSettings() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(DiceSheetBoard old) {
    super.didUpdateWidget(old);
    if (old.tour != widget.tour) {
      old.tour?.removeListener(_replayTour);
      widget.tour?.addListener(_replayTour);
    }
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
    _beginner.removeListener(_onSettings);
    widget.tour?.removeListener(_replayTour);
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
      if (changed) _tipOpen = _tipExpanded = false;
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
    if (shaken) {
      controller.submit(DiceSheetGame.rollMove(game.rollsUsed == 0 ? const [] : _keep));
      return;
    }
    // KLD-123: the shake consent card first, once, on the web on iOS.
    ShakeToRoll.rollFromTap(context, () {
      if (mounted && _canRoll) controller.submit(DiceSheetGame.rollMove(game.rollsUsed == 0 ? const [] : _keep));
    });
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

  // ------------------------------------------------------------- tour

  /// Before the first roll of a game, once per device: the tour. Never
  /// over a dialog; checked after two frames, once the layout has settled.
  void _maybeCoach() {
    if (_coachPending || _coachOpen || SeenTips.shared.has(SeenTips.dicesheetIntro)) return;
    bool ready() =>
        mounted &&
        _canRoll &&
        game.rollsUsed == 0 &&
        controller.moves.isEmpty &&
        ModalRoute.of(context)?.isCurrent != false;
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
        if (ready() && SeenTips.shared.markFirst(SeenTips.dicesheetIntro)) _showCoach();
      });
      binding.scheduleFrame();
    });
  }

  void _replayTour() {
    if (!mounted || _coachOpen) return;
    _showCoach();
  }

  /// The tour: "Würfeln", the dice, the sheet, a box (each only once), and
  /// where the rules are.
  Future<void> _showCoach() async {
    final l10n = AppLocalizations.of(context);
    final rules = GameScreen.of(context).rulesButtonKey;
    _coachOpen = true;
    try {
      await showCoachMarks(
        context,
        keyPrefix: 'dicesheet-coach',
        accent: KlunkiPalette.of(context).accent('dicesheet'),
        steps: [
          CoachStep(target: _rollKey, icon: Icons.casino_outlined, text: l10n.dicesheetCoachRoll(DiceSheetGame.maxRolls)),
          CoachStep(target: _diceKey, icon: Icons.touch_app_outlined, text: l10n.dicesheetCoachKeep),
          CoachStep(target: _sheetKey, icon: Icons.edit_note, text: l10n.dicesheetCoachSheet),
          CoachStep(
              target: _boxKey, icon: Icons.check_box_outlined, text: l10n.dicesheetCoachOnce(DiceSheetGame.rounds)),
          if (rules.currentContext != null)
            CoachStep(target: rules, icon: Icons.menu_book_outlined, text: l10n.rulesCoachHere),
        ],
      );
    } finally {
      _coachOpen = false;
    }
  }

  // ------------------------------------------------------------- tips

  /// The advice for the player to move (Anfängermodus on, dice on the table
  /// and not tumbling), else null.
  DiceSheetAdvice? get _advice =>
      _beginner.enabled && _myTurn && game.canScore && _tumbling.isEmpty ? DiceSheetAdvisor.forGame(game) : null;

  /// The box tip shows by itself after the last roll, with a big box
  /// already made, or with a joker's forced choice.
  bool _boxTip(DiceSheetAdvice a) => game.rollsLeft == 0 || a.stop || game.isJoker;

  void _revealTip() {
    final ctx = _tipCellKey.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(ctx,
          alignment: 0.5, duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 250));
    }
  }

  void _endBeginner(AppLocalizations l10n) {
    _beginner.setEnabled(false);
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.dicesheetBeginnerEnded)));
  }

  /// The lines of the tip bubble.
  _TipText _tipText(AppLocalizations l10n, DiceSheetAdvice a, bool boxTip) {
    if (!boxTip) {
      final keep = a.keep ?? const [];
      return keep.isEmpty
          ? _TipText(l10n.dicesheetTipRerollAll)
          : _TipText(l10n.dicesheetTipKeep, keep: [for (final i in keep) game.dice[i]]);
    }
    final box = diceBoxName(l10n, a.box);
    final main = switch (a.reason) {
      DiceTipReason.bonus => l10n.dicesheetTipBonus(box, a.points, DiceSheetGame.upperBonusAt),
      DiceTipReason.allDice => l10n.dicesheetTipAllDice(box, a.points),
      DiceTipReason.fixed => l10n.dicesheetTipFixed(box, a.points),
      DiceTipReason.points => l10n.dicesheetTipPoints(box, a.points),
      DiceTipReason.leastLoss => l10n.dicesheetTipLeastLoss(box, a.points),
      DiceTipReason.strike => l10n.dicesheetTipStrike(box),
    };
    final richer = a.richer;
    final firstTurn = game.roundOf(game.currentSeat) == 1;
    return _TipText(main, extra: [
      if (a.stop && game.rollsLeft > 0) l10n.dicesheetTipStop,
      if (richer == DiceBox.chance)
        l10n.dicesheetTipSaveChance
      else if (richer != null)
        l10n.dicesheetTipRicher(diceBoxName(l10n, richer), a.richerPoints!),
      if (firstTurn || a.box == DiceBox.chance || a.reason == DiceTipReason.strike) l10n.dicesheetTipOnce,
    ]);
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
    _maybeCoach();
    return ShakeToRoll(
      enabled: _canRoll,
      onShake: () => _roll(shaken: true),
      builder: (context, shakeReady) => LayoutBuilder(builder: (context, box) => _layout(context, l10n, box, shakeReady)),
    );
  }

  Widget _layout(BuildContext context, AppLocalizations l10n, BoxConstraints box, bool shakeReady) {
    final wide = box.maxWidth >= 600 && box.maxWidth > box.maxHeight * 1.15;
    final advice = _advice;
    final boxTip = advice != null && _boxTip(advice);
    if (boxTip && _revealedFor != controller.moves.length) {
      _revealedFor = controller.moves.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealTip();
      });
    }
    final sheet = _ScoreSheet(
      key: _sheetKey,
      game: game,
      name: _name,
      active: _myTurn && game.canScore,
      onScore: _score,
      lastScored: _lastScored,
      tipBox: boxTip ? advice.box : null,
      tipCellKey: _tipCellKey,
      boxKey: _boxKey,
    );
    final bubble = advice != null && (boxTip || _tipOpen)
        ? _TipBubble(
            key: const Key('dicesheet-tip'),
            text: _tipText(l10n, advice, boxTip),
            pointsUp: !wide,
            // A short phone (an iPhone SE): the first line, the rest on a tap.
            compact: !wide && box.maxHeight < 560 && !_tipExpanded,
            onTap: () {
              if (!wide && box.maxHeight < 560) setState(() => _tipExpanded = !_tipExpanded);
              if (boxTip) _revealTip();
            },
            onEnd: () => _endBeginner(l10n),
          )
        : null;
    final controls = game.isOver
        ? null
        : _controls(context, l10n, shakeReady, narrow: box.maxWidth < 420, tipButton: advice != null && !boxTip);
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
                      children: [
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [controls, if (bubble != null) ...[const SizedBox(height: 8), bubble]],
                            ),
                          ),
                        ),
                      ],
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
            // At most a quarter of the height (it scrolls inside then): the
            // names and totals of the sheet stay on screen on a small phone.
            if (bubble != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: max(88.0, box.maxHeight * 0.25)),
                  child: SingleChildScrollView(key: const Key('dicesheet-tip-scroll'), child: bubble),
                ),
              ),
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

  Widget _controls(BuildContext context, AppLocalizations l10n, bool shakeReady,
      {required bool narrow, required bool tipButton}) {
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
            key: _diceKey,
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
            if (tipButton) ...[
              _TipButton(
                key: const Key('dicesheet-tip-button'),
                label: l10n.dicesheetTipLabel,
                tooltip: l10n.dicesheetTipShow,
                open: _tipOpen,
                onPressed: () => setState(() => _tipOpen = !_tipOpen),
              ),
              const SizedBox(width: 4),
            ],
            const UndoMoveButton(),
          ],
        ),
        const SizedBox(height: 2),
        KeyedSubtree(
          key: _rollKey,
          child: FilledButton(
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

  /// The box the Anfängermodus recommends (glows), its cell's key (to
  /// scroll it into view), and the key of a box for the tour.
  final DiceBox? tipBox;
  final GlobalKey? tipCellKey;
  final GlobalKey? boxKey;

  const _ScoreSheet(
      {super.key,
      required this.game,
      required this.name,
      required this.active,
      required this.onScore,
      required this.lastScored,
      this.tipBox,
      this.tipCellKey,
      this.boxKey});

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dicesheetRound(game.round, DiceSheetGame.rounds),
              key: const Key('dicesheet-round'),
              maxLines: 2,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            // The empty boxes left on the sheet of the player to move: each
            // box is filled only once.
            if (_current case final s?)
              Text(
                l10n.dicesheetFreeBoxes(DiceSheetGame.rounds - game.roundOf(s) + 1),
                key: const Key('dicesheet-free'),
                maxLines: 2,
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
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

  Widget _label(BuildContext context, String text, {Widget? leading, String? sub, bool used = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8, end: 4, top: 2, bottom: 2),
      // A box the player to move has filled already: its name fades.
      child: Opacity(
        opacity: used ? 0.5 : 1,
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
      ),
    );
  }

  TableRow _boxRow(BuildContext context, DiceBox box) {
    final l10n = AppLocalizations.of(context);
    final last = lastScored;
    final current = _current;
    return TableRow(
      key: ValueKey('row-${box.id}'),
      children: [
        _label(context, diceBoxName(l10n, box),
            leading: box.upper ? DieFace(value: box.face, size: 18) : null,
            used: current != null && game.isFilled(current, box)),
        for (var s = 0; s < n; s++)
          _cell(
            context,
            s,
            key: Key('dicesheet-cell-$s-${box.id}'),
            KeyedSubtree(
              key: s == current && box == DiceBox.ones ? boxKey : null,
              child: () {
                final entry = game.entryOf(s, box);
                if (entry != null) {
                  return _UsedBox(
                    entry: entry,
                    fresh: last != null && last.$1 == s && last.$2 == box,
                    color: seatColor(context, s),
                  );
                }
                final points = s == current && active ? game.scoreIfFilled(box) : null;
                // An empty box: an open slot.
                if (points == null) return const _OpenBox();
                final tip = box == tipBox;
                return KeyedSubtree(
                  key: tip ? tipCellKey : null,
                  child: _Suggestion(
                    key: Key('dicesheet-score-${box.id}'),
                    points: points,
                    color: seatColor(context, s),
                    tip: tip,
                    label: l10n.dicesheetScoreAction(diceBoxName(l10n, box), points),
                    onTap: () => onScore(box),
                  ),
                );
              }(),
            ),
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

  /// The Anfängermodus recommends this box: a glowing ring and a bulb.
  final bool tip;
  const _Suggestion(
      {super.key, required this.points, required this.color, required this.label, required this.onTap, this.tip = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final zero = points == 0;
    final glow = tipInk(context);
    final edge = tip ? glow : (zero ? theme.colorScheme.outline : visibleOn(context, color, minRatio: 2));
    final button = Material(
      color: zero ? Colors.transparent : color.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: edge, width: tip ? 3 : (zero ? 1.2 : 2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 34),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tip) ...[Icon(Icons.lightbulb, size: 15, color: glow), const SizedBox(width: 2)],
                  Text(
                    '$points',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: zero && !tip ? FontWeight.w400 : FontWeight.w800,
                      color: zero && !tip ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      label: tip ? '${l10n.dicesheetTipLabel}: $label' : label,
      excludeSemantics: true,
      child: tip
          ? DecoratedBox(
              key: const Key('dicesheet-tip-ring'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: tipColor.withValues(alpha: 0.75), blurRadius: 10, spreadRadius: 1.5)],
              ),
              child: button,
            )
          : button,
    );
  }
}

/// The colour of the Anfängermodus: the ring of the recommended box, the
/// bulb, the edge of the tip bubble.
const Color tipColor = Color(0xFFF2A900);

/// [tipColor] for lines and icons: a deeper amber on a light ground.
Color tipInk(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark ? tipColor : const Color(0xFFB37A00);

/// A filled box: a solid chip with the number and a small check, so it
/// reads as done (each box is filled only once); a struck box (0) crossed
/// out. The box filled last glows in the player's colour for a moment.
class _UsedBox extends StatelessWidget {
  final int entry;
  final bool fresh;
  final Color color;
  const _UsedBox({required this.entry, required this.fresh, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final struck = entry == 0;
    return Container(
      key: fresh ? const Key('dicesheet-fresh') : null,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
      padding: const EdgeInsetsDirectional.fromSTEB(6, 2, 4, 2),
      decoration: BoxDecoration(
        color: fresh ? color.withValues(alpha: 0.28) : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$entry',
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: struck ? scheme.onSurfaceVariant : null,
                  decoration: struck ? TextDecoration.lineThrough : null)),
          const SizedBox(width: 2),
          ExcludeSemantics(child: Icon(Icons.check, size: 13, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// An empty box: a faint open slot.
class _OpenBox extends StatelessWidget {
  const _OpenBox();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.8)),
        ),
      );
}

/// "Kurz erklärt" (the "⋮" menu) asks the board for the tour again.
class DiceSheetTourRequest extends ChangeNotifier {
  void request() => notifyListeners();
}

/// What the tip bubble says: the [main] line, [extra] lines, and with
/// [keep] small dice to keep.
class _TipText {
  final String main;
  final List<String> extra;
  final List<int> keep;
  const _TipText(this.main, {this.extra = const [], this.keep = const []});
}

/// The Anfängermodus bubble between the sheet and the dice (beside the dice
/// on a wide screen): a bulb, the tip, maybe more lines and dice to keep,
/// and "Anfängermodus beenden". With [pointsUp] a small notch points up
/// to the sheet. A tap on the text scrolls the recommended box into view.
class _TipBubble extends StatelessWidget {
  final _TipText text;
  final bool pointsUp;

  /// Only the first line (and dice); a tap shows the rest.
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback onEnd;
  const _TipBubble(
      {super.key,
      required this.text,
      required this.pointsUp,
      this.compact = false,
      required this.onTap,
      required this.onEnd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final edge = tipInk(context);
    final fill = Color.alphaBlend(tipColor.withValues(alpha: 0.12), scheme.surface);
    final more = compact && text.extra.isNotEmpty;
    final body = Material(
      color: fill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: edge, width: 2)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 6, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(Icons.lightbulb, size: 20, color: edge),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(text.main,
                            key: const Key('dicesheet-tip-text'),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                        if (text.keep.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: ExcludeSemantics(
                              child: Directionality(
                                key: const Key('dicesheet-tip-keep'),
                                textDirection: TextDirection.ltr,
                                child: Wrap(spacing: 4, children: [for (final d in text.keep) DieFace(value: d, size: 22)]),
                              ),
                            ),
                          ),
                        for (final line in compact ? const <String>[] : text.extra)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(line, style: theme.textTheme.bodySmall),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (more)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 24),
                      child: Icon(Icons.expand_more, key: const Key('dicesheet-tip-more'), color: edge),
                    ),
                  const Spacer(),
                  TextButton(
                    key: const Key('dicesheet-beginner-end'),
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: theme.textTheme.labelMedium?.copyWith(decoration: TextDecoration.underline),
                    ),
                    onPressed: onEnd,
                    child: Text(l10n.dicesheetBeginnerEnd),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!pointsUp) return body;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: CustomPaint(size: const Size(18, 8), painter: _NotchPainter(fill: fill, edge: edge))),
        Transform.translate(offset: const Offset(0, -1), child: body),
      ],
    );
  }
}

/// The notch of the tip bubble, pointing up.
class _NotchPainter extends CustomPainter {
  final Color fill;
  final Color edge;
  _NotchPainter({required this.fill, required this.edge});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(path..close(), Paint()..color = fill);
    canvas.drawPath(
        Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height),
        Paint()
          ..color = edge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_NotchPainter old) => old.fill != fill || old.edge != edge;
}

/// "Tipp" while rolls are left: shows (or hides) which dice to keep.
class _TipButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final bool open;
  final VoidCallback onPressed;
  const _TipButton(
      {super.key, required this.label, required this.tooltip, required this.open, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final edge = tipInk(context);
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: open ? tipColor.withValues(alpha: 0.2) : null,
          side: BorderSide(color: edge, width: 1.5),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: onPressed,
        icon: Icon(open ? Icons.lightbulb : Icons.lightbulb_outline, size: 18, color: edge),
        label: Text(label),
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../shell/game_screen.dart';
import '../../shell/seat_labels.dart';
import '../shake_to_roll.dart';
import 'maexchen_dice.dart';
import 'maexchen_options.dart' show maexchenOptionsSummary;
import 'maexchen_screen.dart' show maexchenValueLabel;

/// The Mäxchen board (KLD-121): every player with their hearts (or, with
/// "Unbegrenzte Leben", the lives lost so far), the
/// announcement of the round, the table with the cup, and what the player
/// to move can do:
///
/// * roll: "Würfeln" shakes the cup;
/// * announce: "Nachschauen" lifts the cup (only the roller holds the
///   device then), the values that beat the announcement as chips plus a
///   big "Mäxchen!", then "54 ansagen" (the chosen value);
/// * respond: "Glauben" / "Anzweifeln", after a Mäxchen "Leben abgeben" /
///   "Anzweifeln".
///
/// After a doubt the cup lifts by itself and the round's verdict shows
/// until the next roll. The dice of the current roll are drawn only while
/// the roller peeks; nobody else ever sees them on this screen.
class MaexchenBoard extends StatefulWidget {
  final GameController controller;
  const MaexchenBoard({super.key, required this.controller});

  @override
  State<MaexchenBoard> createState() => _MaexchenBoardState();
}

class _MaexchenBoardState extends State<MaexchenBoard> with TickerProviderStateMixin {
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  late final AnimationController _lift =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  bool _peek = false;
  int? _choice;
  late int _seen = widget.controller.moves.length;

  /// The last move was a doubt: the verdict appears with a short drum roll.
  bool _freshReveal = false;

  GameController get controller => widget.controller;
  MaexchenGame get game => controller.game as MaexchenGame;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onChange);
    _lift.value = _liftTarget;
  }

  @override
  void didUpdateWidget(MaexchenBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _reset();
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onChange);
    _shake.dispose();
    _lift.dispose();
    super.dispose();
  }

  void _onChange() {
    if (!mounted) return;
    final moves = controller.moves;
    if (moves.length == _seen) {
      setState(() {});
      return;
    }
    final grew = moves.length > _seen;
    _seen = moves.length;
    final action = moves.isEmpty ? null : moves.last.move['action'];
    setState(() {
      _peek = false;
      _choice = null;
      _freshReveal = grew && action == 'doubt';
    });
    // The cup wobbles; when the dice land the phone gives a short knock.
    if (grew && action == 'roll') _shake.forward(from: 0).then((_) => HapticFeedback.mediumImpact());
    if (_freshReveal) {
      // The cup stays down for a moment, then lifts: a short reveal (the
      // pause is the first part of the curve, see [_liftShown]).
      _lift.value = 0;
      _lift.animateTo(_liftTarget, duration: const Duration(milliseconds: 900));
    } else {
      _lift.animateTo(_liftTarget);
    }
  }

  void _reset() {
    _seen = controller.moves.length;
    _peek = false;
    _choice = null;
    _freshReveal = false;
    _lift.value = _liftTarget;
  }

  /// The round ended with a doubt and nobody rolled since: the dice lie open.
  bool get _revealed => game.phase == MaexchenPhase.roll && game.roller == null && game.lastRound?.dice != null;

  /// The player to move rolled and may look under the cup.
  bool get _canPeek => controller.canAct && game.phase == MaexchenPhase.announce && game.dice != null;

  double get _liftTarget => _revealed || (_peek && _canPeek) ? 1 : 0;

  /// The dice drawn on the table, high die first: the revealed ones, or the
  /// roller's own while peeking. Null otherwise (never someone else's).
  List<int>? get _visibleDice {
    final d = _revealed ? game.lastRound!.dice : (_peek && _canPeek ? game.dice : null);
    if (d == null) return null;
    return d[0] >= d[1] ? d : [d[1], d[0]];
  }

  /// How far the cup is lifted on screen.
  double get _liftShown {
    final t = _lift.value;
    return _freshReveal ? const Interval(0.4, 1, curve: Curves.easeOut).transform(t) : Curves.easeOut.transform(t);
  }

  void _togglePeek() {
    setState(() => _peek = !_peek);
    _lift.animateTo(_liftTarget);
  }

  void _submit(Map<String, dynamic> move) => controller.submit(move);

  String _hint(AppLocalizations l10n) {
    if (game.isOver || !controller.canAct) return '';
    final announced = game.announced;
    String label(int v) => maexchenValueLabel(l10n, v);
    return switch (game.phase) {
      MaexchenPhase.roll => announced != null ? l10n.maexchenHintBelieved(label(announced)) : l10n.maexchenHintRoll,
      MaexchenPhase.announce =>
        announced == null ? l10n.maexchenHintAnnounceFirst : l10n.maexchenHintAnnounceHigher(label(announced)),
      MaexchenPhase.respond => announced == MaexchenGame.maexchen
          ? l10n.maexchenHintRespondMaexchen(maexchenSeatName(context, game, game.announcerSeat!))
          : l10n.maexchenHintRespond(maexchenSeatName(context, game, game.announcerSeat!), label(announced!)),
    };
  }

  /// A roll is allowed now, by the button or by shaking the phone.
  bool get _canRoll =>
      controller.canAct && !game.isOver && game.phase == MaexchenPhase.roll && !controller.needsHandover;

  /// Rolls: a tap on "Würfeln" ([shaken] false, which also asks the web on
  /// iOS for motion access, once after the consent card, KLD-123) or a
  /// shake.
  void _roll({bool shaken = false}) {
    if (!_canRoll) return;
    if (shaken) {
      _submit(MaexchenGame.rollMove);
      return;
    }
    ShakeToRoll.rollFromTap(context, () {
      if (mounted && _canRoll) _submit(MaexchenGame.rollMove);
    });
  }

  /// Phones narrower than this get the compact controls ("Zug zurücknehmen" as an
  /// icon next to "Nachschauen").
  static const double _narrow = 420;

  /// Below this height (a phone in landscape) the value grid is denser.
  static const double _low = 320;

  /// What the table part keeps at least before the controls below scroll
  /// inside (small phones, large text): while announcing enough for the
  /// lifted cup and the dice (the value order help scrolls away first).
  static double _minTop(bool announcing) => announcing ? 240 : 170;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hint = _hint(l10n);
    GameScreen.of(context).setHint(hint.isEmpty ? null : hint);
    return ShakeToRoll(
      enabled: _canRoll,
      onShake: () => _roll(shaken: true),
      builder: (context, shakeReady) => LayoutBuilder(
        builder: (context, box) => _layout(context, l10n, box, shakeReady),
      ),
    );
  }

  /// The table on top, the controls pinned below it, so the action button is
  /// always on screen (KLD-121 follow-up: on a phone the "ansagen" button
  /// was below the fold). Landscape on a wide screen: the controls beside
  /// the table. On a tablet the column keeps a phone-like width.
  Widget _layout(BuildContext context, AppLocalizations l10n, BoxConstraints box, bool shakeReady) {
    final actions = controller.canAct && !game.isOver
        ? _actions(context, l10n, shakeReady, narrow: box.maxWidth < _narrow, dense: box.maxHeight < _low)
        : null;
    final announcing = actions != null && game.phase == MaexchenPhase.announce;
    final table = _tableSection(context, minTable: announcing ? 96 : 130);
    final wide = box.maxWidth >= 560 && box.maxWidth > box.maxHeight * 1.2;
    if (wide) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: table),
              if (actions != null)
                SizedBox(
                  width: min(460.0, box.maxWidth * 0.46),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0, 4, 12, 8),
                    child: Column(
                      key: const Key('maexchen-controls'),
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Flexible(child: actions)],
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
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: table),
            if (actions != null)
              ConstrainedBox(
                key: const Key('maexchen-controls'),
                constraints: BoxConstraints(maxHeight: max(0.0, box.maxHeight - _minTop(announcing))),
                child: Padding(padding: const EdgeInsets.fromLTRB(12, 6, 12, 8), child: actions),
              ),
          ],
        ),
      ),
    );
  }

  /// Lives, announcement (or how the round ended) and the table with the
  /// cup, which takes the room that is left (at least [minTable]); scrolls
  /// only when even that does not fit.
  Widget _tableSection(BuildContext context, {required double minTable}) {
    final last = game.lastRound;
    final roundOver = game.phase == MaexchenPhase.roll && game.roller == null && game.announced == null && last != null;
    return CustomScrollView(
      key: const Key('maexchen-board'),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LivesRow(game: game),
                // Over the network: the host's options, until the first move.
                if (controller.transport.localPlayers.length == 1 && controller.moves.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      maexchenOptionsSummary(AppLocalizations.of(context), controller.config),
                      key: const Key('maexchen-net-options'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 6),
                if (roundOver)
                  MaexchenRoundSummary(
                      key: ValueKey('summary-${last.round}'), game: game, end: last, animate: _freshReveal)
                else
                  _AnnouncementBanner(game: game),
                const SizedBox(height: 6),
                Expanded(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: minTable),
                    child: GestureDetector(
                      key: const Key('maexchen-table'),
                      onTap: _canPeek ? _togglePeek : null,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_shake, _lift]),
                        builder: (context, _) => CupTable(
                          dice: _visibleDice,
                          lift: _liftShown,
                          shake: _shake.isAnimating ? _shake.value : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// A small row above the big buttons: [leading] (the shake hint, the peek
  /// button) and "Zug zurücknehmen" at the end.
  Widget _toolRow({Widget? leading, bool undoIcon = false}) => Row(
        children: [
          Expanded(child: Align(alignment: AlignmentDirectional.centerStart, child: leading)),
          const SizedBox(width: 8),
          UndoMoveButton(iconOnly: undoIcon),
        ],
      );

  Widget _actions(BuildContext context, AppLocalizations l10n, bool shakeReady,
      {required bool narrow, required bool dense}) {
    final theme = Theme.of(context);
    final big = FilledButton.styleFrom(
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      textStyle: theme.textTheme.titleMedium,
    );
    switch (game.phase) {
      case MaexchenPhase.roll:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolRow(
              leading: shakeReady
                  ? Row(
                      key: const Key('maexchen-shake-hint'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.vibration, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(l10n.maexchenShakeHint,
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              key: const Key('maexchen-roll'),
              style: big,
              onPressed: _canRoll ? _roll : null,
              icon: const Icon(Icons.casino_outlined),
              label: Text(l10n.maexchenRoll),
            ),
          ],
        );
      case MaexchenPhase.announce:
        return _picker(context, l10n, narrow: narrow, dense: dense);
      case MaexchenPhase.respond:
        final maexchen = game.announced == MaexchenGame.maexchen;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _toolRow(),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: maexchen
                      ? FilledButton.tonalIcon(
                          key: const Key('maexchen-giveup'),
                          style: big,
                          onPressed: () => _submit(MaexchenGame.giveUpMove),
                          icon: const Icon(Icons.heart_broken_outlined),
                          label: Text(l10n.maexchenGiveUp, textAlign: TextAlign.center),
                        )
                      : FilledButton.icon(
                          key: const Key('maexchen-believe'),
                          style: big,
                          onPressed: () => _submit(MaexchenGame.believeMove),
                          icon: const Icon(Icons.thumb_up_alt_outlined),
                          label: Text(l10n.maexchenBelieve, textAlign: TextAlign.center),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('maexchen-doubt'),
                    style: big.copyWith(
                      backgroundColor: WidgetStatePropertyAll(theme.colorScheme.error),
                      foregroundColor: WidgetStatePropertyAll(theme.colorScheme.onError),
                    ),
                    onPressed: () => _submit(MaexchenGame.doubtMove),
                    icon: const Icon(Icons.search),
                    label: Text(l10n.maexchenDoubt, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  /// The announcement controls: "Nachschauen", the values that beat the
  /// announcement as a compact grid (8 per row, low to high, then a wide
  /// "Mäxchen!"), the order as help text, and "`<Wert>` ansagen" (before a
  /// value is chosen it is off and says "Wähle eine Zahl"). The grid and the
  /// help scroll inside when the screen is very small; the buttons never do.
  Widget _picker(BuildContext context, AppLocalizations l10n, {required bool narrow, required bool dense}) {
    final theme = Theme.of(context);
    final choice = _choice;
    return Column(
      key: const Key('maexchen-picker'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolRow(
          undoIcon: narrow,
          leading: FilledButton.tonalIcon(
            key: const Key('maexchen-peek'),
            style: FilledButton.styleFrom(
                visualDensity: dense ? const VisualDensity(horizontal: -2, vertical: -3) : VisualDensity.compact),
            onPressed: _togglePeek,
            icon: Icon(_peek ? Icons.visibility_off_outlined : Icons.visibility_outlined),
            label: Text(_peek ? l10n.maexchenCover : l10n.maexchenPeek, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: SingleChildScrollView(
            key: const Key('maexchen-values'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "Was sagst du an?" for screen readers (the hint and the
                // button say it on screen).
                Semantics(
                  container: true,
                  label: l10n.maexchenPickTitle,
                  child: _valueGrid(context, l10n, dense: dense),
                ),
                const SizedBox(height: 4),
                Text(l10n.maexchenOrder, key: const Key('maexchen-order'), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('maexchen-announce'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: theme.textTheme.titleMedium,
          ),
          onPressed: choice == null ? null : () => _submit(MaexchenGame.announceMove(choice)),
          icon: Icon(choice == null ? Icons.touch_app_outlined : Icons.campaign_outlined),
          label: Text(
            choice == null ? l10n.maexchenPickFirst : l10n.maexchenAnnounce(maexchenValueLabel(l10n, choice)),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// The values above the announcement, [_columns] per row; "Mäxchen!" is
  /// the last cell, as wide as the rest of its row (a row of its own when
  /// fewer than 3 cells are left).
  Widget _valueGrid(BuildContext context, AppLocalizations l10n, {required bool dense}) {
    final values = MaexchenGame.valuesAbove(game.announced);
    final plain = values.where((v) => v != MaexchenGame.maexchen).toList();
    final rows = <List<int>>[for (var i = 0; i < plain.length; i += _columns) plain.sublist(i, min(i + _columns, plain.length))];
    final lastFree = rows.isEmpty ? 0 : _columns - rows.last.length;
    final ownRow = lastFree < 3;
    Widget cell(int v) => _ValueCell(
          minHeight: dense ? 34 : 40,
          key: Key('maexchen-value-$v'),
          selected: _choice == v,
          onTap: () => setState(() => _choice = v),
          semanticsLabel: maexchenValueLabel(l10n, v),
          child: v == MaexchenGame.maexchen
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ValueDice(value: MaexchenGame.maexchen, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.maexchenMaexchenCall),
                  ],
                )
              : Text('$v'),
        );
    // Cells of a row share its height (one may wrap with large text).
    Widget row(List<Widget> cells) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cells)),
        );
    Widget slot(Widget child, {int flex = 1}) =>
        Expanded(flex: flex, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: child));
    return Directionality(
      // Values read low to high, left to right, in every language.
      textDirection: TextDirection.ltr,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++)
            row([
              for (final v in rows[i]) slot(cell(v)),
              if (i == rows.length - 1 && !ownRow)
                slot(cell(MaexchenGame.maexchen), flex: lastFree)
              else if (rows[i].length < _columns)
                Spacer(flex: _columns - rows[i].length),
            ]),
          if (ownRow) row([slot(cell(MaexchenGame.maexchen))]),
        ],
      ),
    );
  }

  static const int _columns = 8;
}

/// One value in the announcement grid: a rounded button, filled with the
/// game's colour when chosen.
class _ValueCell extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String semanticsLabel;
  final Widget child;
  final double minHeight;
  const _ValueCell(
      {super.key,
      required this.selected,
      required this.onTap,
      required this.semanticsLabel,
      required this.child,
      this.minHeight = 40});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maexchen');
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: selected ? accent.color : theme.colorScheme.outlineVariant),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? accent.color : theme.colorScheme.surfaceContainerLow,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: selected ? accent.onColor : theme.colorScheme.onSurface,
                    ),
                    child: child,
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

/// [seat]'s name in a sentence: the seat labels with 3–4 players (KLD-121
/// step 2), the player labels with 2 (as over the network).
String maexchenSeatName(BuildContext context, MaexchenGame game, int seat) {
  final p = MaexchenGame.playerOfSeat(seat);
  if (game.playerCount > 2 || p == null) {
    return SeatLabelsScope.of(context).label(context, AppLocalizations.of(context), seat, count: game.playerCount);
  }
  return playerName(context, p);
}

/// [seat]'s token: the seat token (colour and number) with 3–4 players, the
/// game's player token with 2; greyed for a seat that is out.
class MaexchenSeatToken extends StatelessWidget {
  final MaexchenGame game;
  final int seat;
  final double size;
  const MaexchenSeatToken({super.key, required this.game, required this.seat, this.size = 22});

  @override
  Widget build(BuildContext context) {
    final p = MaexchenGame.playerOfSeat(seat);
    if (game.playerCount > 2 || p == null) return SeatToken(seat: seat, size: size, out: game.isSeatOut(seat));
    return PlayerToken(gameId: 'maexchen', player: p, size: size);
  }
}

/// Key suffix of [seat]: `a`, `b` (as the players), `c`, `d`.
String _seatKey(int seat) => 'abcd'[seat];

/// Every player: token, name and hearts; with "Unbegrenzte Leben" a broken
/// heart and the lives lost so far instead (the tally). The player to move
/// is outlined, a player who is out is greyed. With 3–4 players the cells
/// are narrower: the name next to a smaller token, the hearts on one line
/// below, shrunk to fit (a phone of 320 points, 5 lives). No LayoutBuilder:
/// the table section measures this row's height.
class _LivesRow extends StatelessWidget {
  final MaexchenGame game;
  const _LivesRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final n = game.playerCount;
    final gap = n > 2 ? 4.0 : 8.0;
    return Row(
      children: [
        for (var s = 0; s < n; s++) ...[
          if (s > 0) SizedBox(width: gap),
          Expanded(child: _SeatLives(game: game, seat: s)),
        ],
      ],
    );
  }
}

class _SeatLives extends StatelessWidget {
  final MaexchenGame game;
  final int seat;
  const _SeatLives({required this.game, required this.seat});

  static const Color _red = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maexchen');
    final compact = game.playerCount > 2;
    final name = maexchenSeatName(context, game, seat);
    final lives = game.livesOfSeat(seat);
    final out = game.isSeatOut(seat);
    final toMove = !game.isOver && game.actorSeat == seat;
    final k = _seatKey(seat);
    final tokenSize = compact ? 18.0 : 22.0;

    final Widget marks;
    if (game.unlimitedLives) {
      final lost = game.lostOf(seat);
      marks = Row(
        key: Key('maexchen-tally-$k'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.heart_broken, size: 18, color: lost > 0 ? _red : theme.colorScheme.outline),
          const SizedBox(width: 3),
          Text('$lost',
              key: Key('maexchen-lost-$k'),
              textDirection: TextDirection.ltr,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        ],
      );
    } else {
      final hearts = [
        for (var i = 0; i < game.startLives; i++)
          Icon(
            i < lives ? Icons.favorite : Icons.favorite_border,
            key: Key('maexchen-heart-$k-$i'),
            size: 18,
            color: i < lives ? _red : theme.colorScheme.outline,
          ),
      ];
      marks = compact
          // One line, shrunk to the cell (5 hearts in a quarter of a phone).
          ? FittedBox(
              key: Key('maexchen-hearts-$k'),
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(mainAxisSize: MainAxisSize.min, children: hearts),
            )
          : Wrap(key: Key('maexchen-hearts-$k'), children: hearts);
    }
    final nameText = Text(name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (compact ? theme.textTheme.labelLarge : theme.textTheme.titleSmall)
            ?.copyWith(fontWeight: toMove && compact ? FontWeight.w700 : null));
    final token = MaexchenSeatToken(game: game, seat: seat, size: tokenSize);
    return Semantics(
      label: game.unlimitedLives ? l10n.maexchenLostOf(name, game.lostOf(seat)) : l10n.maexchenLivesOf(name, lives),
      excludeSemantics: true,
      child: Opacity(
        opacity: out ? 0.5 : 1,
        child: AnimatedContainer(
          key: Key('maexchen-lives-$k'),
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: toMove ? accent.onSurface(theme.brightness) : theme.colorScheme.outlineVariant,
              width: toMove ? 2.5 : 1,
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(children: [token, const SizedBox(width: 4), Expanded(child: nameText)]),
                    const SizedBox(height: 2),
                    marks,
                  ],
                )
              : Row(
                  children: [
                    token,
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [nameText, marks],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// The round's announcement: who said what, with the value as dice; or
/// "Neue Runde" before the first one.
class _AnnouncementBanner extends StatelessWidget {
  final MaexchenGame game;
  const _AnnouncementBanner({required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a = game.announced;
    return Container(
      key: const Key('maexchen-announced'),
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: KlunkiPalette.of(context).accent('maexchen').container,
        borderRadius: BorderRadius.circular(14),
      ),
      child: a == null
          ? Row(
              children: [
                const Icon(Icons.casino_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.maexchenNewRound, style: theme.textTheme.titleMedium)),
                Text(l10n.maexchenRoundLabel(game.round), style: theme.textTheme.labelMedium),
              ],
            )
          : Row(
              children: [
                ValueDice(value: a, size: 34),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.maexchenAnnouncedLabel, style: theme.textTheme.labelMedium),
                      Text(
                          l10n.maexchenAnnounced(
                              maexchenSeatName(context, game, game.announcerSeat!), maexchenValueLabel(l10n, a)),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// How a round ended: the dice from under the cup, what was announced and
/// who loses lives ("Geflunkert! Anna verliert ein Leben."). With [animate]
/// the dice pop in after a short pause and the verdict follows: the reveal.
class MaexchenRoundSummary extends StatelessWidget {
  /// The game, for the players' names.
  final MaexchenGame game;
  final MaexchenRoundEnd end;
  final bool animate;
  const MaexchenRoundSummary({super.key, required this.game, required this.end, this.animate = false});

  String verdict(BuildContext context, AppLocalizations l10n) {
    final loser = maexchenSeatName(context, game, end.loser);
    if (end.gaveUp) return l10n.maexchenVerdictGaveUp(loser);
    if (end.bluff) return end.lost >= 2 ? l10n.maexchenVerdictBluffTwo(loser) : l10n.maexchenVerdictBluff(loser);
    return end.lost >= 2 ? l10n.maexchenVerdictTrueTwo(loser) : l10n.maexchenVerdictTrue(loser);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dice = end.dice;
    final value = end.value;
    final good = !end.gaveUp && !end.bluff;
    final colour = end.gaveUp
        ? theme.colorScheme.surfaceContainerHigh
        : good
            ? const Color(0xFF2E7D32).withValues(alpha: 0.16)
            : theme.colorScheme.errorContainer;
    Widget body(double t) {
      final pop = Curves.elasticOut.transform((t * 1.6).clamp(0.0, 1.0));
      final textIn = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
      return Row(
        children: [
          if (dice != null && value != null)
            Transform.scale(scale: 0.3 + 0.7 * pop, child: ValueDice(value: value, size: 34))
          else
            const Icon(Icons.heart_broken_outlined, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.maexchenAnnounced(
                      maexchenSeatName(context, game, end.announcer), maexchenValueLabel(l10n, end.announced)),
                  style: theme.textTheme.labelLarge,
                ),
                if (value != null) Text(l10n.maexchenUnderCup(maexchenValueLabel(l10n, value)), style: theme.textTheme.labelLarge),
                Opacity(
                  opacity: textIn,
                  child: Text(verdict(context, l10n),
                      key: const Key('maexchen-verdict'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      key: const Key('maexchen-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(14)),
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              builder: (context, t, _) => body(t),
            )
          : body(1),
    );
  }
}

/// Public information on the handover cover: the announcement the next
/// player answers, or how the round just ended. Never the dice under a
/// closed cup.
class MaexchenHandoverDetail extends StatelessWidget {
  final GameController controller;
  const MaexchenHandoverDetail({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final game = controller.game as MaexchenGame;
    final moves = controller.moves;
    final action = moves.isEmpty ? null : moves.last.move['action'];
    if ((action == 'doubt' || action == 'giveUp') && game.lastRound != null) {
      return MaexchenRoundSummary(
          key: const Key('maexchen-handover-summary'), game: game, end: game.lastRound!, animate: true);
    }
    final a = game.announced;
    if (a == null) return const SizedBox.shrink();
    return Column(
      key: const Key('maexchen-handover-announced'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueDice(value: a, size: 40),
        const SizedBox(height: 8),
        Text(l10n.maexchenAnnounced(maexchenSeatName(context, game, game.announcerSeat!), maexchenValueLabel(l10n, a)),
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

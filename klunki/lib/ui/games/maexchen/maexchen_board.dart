import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../shell/game_screen.dart';
import 'maexchen_dice.dart';
import 'maexchen_screen.dart' show maexchenValueLabel;

/// The Mäxchen board (KLD-121): both players with their hearts, the
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
    if (grew && action == 'roll') _shake.forward(from: 0);
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
          ? l10n.maexchenHintRespondMaexchen(playerName(context, game.announcer!))
          : l10n.maexchenHintRespond(playerName(context, game.announcer!), label(announced!)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hint = _hint(l10n);
    GameScreen.of(context).setHint(hint.isEmpty ? null : hint);
    final last = game.lastRound;
    final roundOver = game.phase == MaexchenPhase.roll && game.roller == null && game.announced == null && last != null;
    return CustomScrollView(
      key: const Key('maexchen-board'),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LivesRow(game: game),
                const SizedBox(height: 8),
                if (roundOver)
                  MaexchenRoundSummary(key: ValueKey('summary-${last.round}'), end: last, animate: _freshReveal)
                else
                  _AnnouncementBanner(game: game),
                const SizedBox(height: 8),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 150),
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
                const SizedBox(height: 8),
                if (controller.canAct) _actions(context, l10n),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final big = FilledButton.styleFrom(minimumSize: const Size(0, 56), textStyle: theme.textTheme.titleMedium);
    switch (game.phase) {
      case MaexchenPhase.roll:
        return FilledButton.icon(
          key: const Key('maexchen-roll'),
          style: big,
          onPressed: () => _submit(MaexchenGame.rollMove),
          icon: const Icon(Icons.casino_outlined),
          label: Text(l10n.maexchenRoll),
        );
      case MaexchenPhase.announce:
        return _picker(context, l10n);
      case MaexchenPhase.respond:
        final maexchen = game.announced == MaexchenGame.maexchen;
        return Row(
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
                      label: Text(l10n.maexchenBelieve),
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
                label: Text(l10n.maexchenDoubt),
              ),
            ),
          ],
        );
    }
  }

  Widget _picker(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maexchen');
    final values = MaexchenGame.valuesAbove(game.announced);
    final plain = values.where((v) => v != MaexchenGame.maexchen).toList();
    final choice = _choice;
    return Column(
      key: const Key('maexchen-picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(l10n.maexchenPickTitle, style: theme.textTheme.titleMedium)),
            OutlinedButton.icon(
              key: const Key('maexchen-peek'),
              onPressed: _togglePeek,
              icon: Icon(_peek ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              label: Text(_peek ? l10n.maexchenCover : l10n.maexchenPeek),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Directionality(
          // Values read low to high, left to right, in every language.
          textDirection: TextDirection.ltr,
          child: Wrap(
            spacing: 5,
            runSpacing: 2,
            children: [
              for (final v in plain)
                ChoiceChip(
                  key: Key('maexchen-value-$v'),
                  label: SizedBox(
                    width: 26,
                    child: Text('$v',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: choice == v ? accent.onColor : null)),
                  ),
                  labelPadding: EdgeInsets.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  selected: choice == v,
                  selectedColor: accent.color,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  onSelected: (_) => setState(() => _choice = v),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: ChoiceChip(
            key: const Key('maexchen-value-21'),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ValueDice(value: MaexchenGame.maexchen, size: 20),
                const SizedBox(width: 10),
                Text(l10n.maexchenMaexchenCall,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: choice == MaexchenGame.maexchen ? accent.onColor : null)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            selectedColor: accent.color,
            selected: choice == MaexchenGame.maexchen,
            showCheckmark: false,
            onSelected: (_) => setState(() => _choice = MaexchenGame.maexchen),
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.maexchenOrder, key: const Key('maexchen-order'), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('maexchen-announce'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52), textStyle: theme.textTheme.titleMedium),
          onPressed: choice == null ? null : () => _submit(MaexchenGame.announceMove(choice)),
          icon: const Icon(Icons.campaign_outlined),
          label: Text(choice == null ? l10n.maexchenPickTitle : l10n.maexchenAnnounce(maexchenValueLabel(l10n, choice))),
        ),
      ],
    );
  }
}

/// Both players: token, name and hearts; the player to move is outlined.
class _LivesRow extends StatelessWidget {
  final MaexchenGame game;
  const _LivesRow({required this.game});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maexchen');
    return Row(
      children: [
        for (final p in Player.values) ...[
          if (p != Player.a) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: l10n.maexchenLivesOf(playerName(context, p), game.livesOf(p)),
              excludeSemantics: true,
              child: AnimatedContainer(
                key: Key('maexchen-lives-${p.name}'),
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: !game.isOver && game.currentPlayer == p
                        ? accent.onSurface(theme.brightness)
                        : theme.colorScheme.outlineVariant,
                    width: !game.isOver && game.currentPlayer == p ? 2.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    PlayerToken(gameId: 'maexchen', player: p, size: 22),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(playerName(context, p),
                              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                          Wrap(
                            children: [
                              for (var i = 0; i < game.startLives; i++)
                                Icon(
                                  i < game.livesOf(p) ? Icons.favorite : Icons.favorite_border,
                                  key: Key('maexchen-heart-${p.name}-$i'),
                                  size: 18,
                                  color: i < game.livesOf(p) ? const Color(0xFFD32F2F) : theme.colorScheme.outline,
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
          ),
        ],
      ],
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
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      Text(l10n.maexchenAnnounced(playerName(context, game.announcer!), maexchenValueLabel(l10n, a)),
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
  final MaexchenRoundEnd end;
  final bool animate;
  const MaexchenRoundSummary({super.key, required this.end, this.animate = false});

  String verdict(BuildContext context, AppLocalizations l10n) {
    final loser = playerName(context, Player.values[end.loser]);
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
                  l10n.maexchenAnnounced(playerName(context, Player.values[end.announcer]),
                      maexchenValueLabel(l10n, end.announced)),
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
      return MaexchenRoundSummary(key: const Key('maexchen-handover-summary'), end: game.lastRound!, animate: true);
    }
    final a = game.announced;
    if (a == null) return const SizedBox.shrink();
    return Column(
      key: const Key('maexchen-handover-announced'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueDice(value: a, size: 40),
        const SizedBox(height: 8),
        Text(l10n.maexchenAnnounced(playerName(context, game.announcer!), maexchenValueLabel(l10n, a)),
            textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki/ui/engine_l10n.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/klunki_engine.dart' as qe show Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../shell/game_screen.dart';
import 'quartett_card.dart';

/// Quartett (Trumpf) / Auto-Quartett screen.
///
/// Contract (keep it): the public class name `QuartettTrumpfScreen` and the
/// constructor `const QuartettTrumpfScreen({super.key, required this.controller})`.
/// The screen is built by `ui/shell/screen_registry.dart` and renders a
/// [GameScreen].
///
/// Flow of one trick (hot-seat):
/// 1. The player to move sees only their own top card (stats tappable) and
///    the opponent's face-down stack.
/// 2. Tapping a stat shows the trick reveal (both cards, chosen stat
///    highlighted, winner text). The move is *not* submitted yet: the reveal
///    is computed on a replayed copy of the engine, so the shell's handover
///    cover (which appears as soon as a move passes the turn) cannot hide it.
/// 3. "Weiter" submits the pick. If the turn passed, the shell's
///    [HandoverCover] appears; otherwise the same player picks again.
///
/// Moves that arrive from elsewhere (network) are revealed from their event
/// payload; "Weiter" then only dismisses the reveal.
///
/// Keys: `qt-stat-<statId>` (stat rows of the active card), `qt-reveal`,
/// `qt-continue`.
class QuartettTrumpfScreen extends StatelessWidget {
  final GameController controller;

  const QuartettTrumpfScreen({super.key, required this.controller});

  /// History text for a pick: "wählt Leistung" (the shell prefixes the
  /// player). No card names, so the history never leaks a card.
  static String describeMove(AppLocalizations l10n, AcceptedMove m) {
    return l10n.quartettTrumpfMovePick(localizedStatLabel(l10n, '${m.move['stat']}'));
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeMove,
      boardBuilder: (context, controller) => _QuartettTrumpfBoard(controller: controller),
    );
  }
}

/// One trick as shown in the reveal.
class _Trick {
  final Player picker;
  final QuartettStat stat;
  final qe.Card a, b;
  final num va, vb;
  final Player? winner;

  /// Pot size after the trick.
  final int pot;

  /// The pick still to submit on "Weiter" (null: already applied, e.g. a
  /// remote move).
  final Map<String, dynamic>? pending;

  const _Trick({
    required this.picker,
    required this.stat,
    required this.a,
    required this.b,
    required this.va,
    required this.vb,
    required this.winner,
    required this.pot,
    required this.pending,
  });

  static _Trick? fromPayload(Player picker, Object? payload, Map<String, dynamic>? pending) {
    if (payload is! Map) return null;
    final stat = QuartettGame.statById('${payload['stat']}');
    final cards = payload['cards'], values = payload['values'];
    if (stat == null || cards is! Map || values is! Map) return null;
    final a = QuartettGame.cardById('${cards['a']}'), b = QuartettGame.cardById('${cards['b']}');
    if (a == null || b == null) return null;
    final w = payload['trickWinner'];
    return _Trick(
      picker: picker,
      stat: stat,
      a: a,
      b: b,
      va: values['a'] as num,
      vb: values['b'] as num,
      winner: w == 'a' ? Player.a : (w == 'b' ? Player.b : null),
      pot: (payload['pot'] as num?)?.toInt() ?? 0,
      pending: pending,
    );
  }
}

class _QuartettTrumpfBoard extends StatefulWidget {
  final GameController controller;
  const _QuartettTrumpfBoard({required this.controller});

  @override
  State<_QuartettTrumpfBoard> createState() => _QuartettTrumpfBoardState();
}

class _QuartettTrumpfBoardState extends State<_QuartettTrumpfBoard> {
  _Trick? _reveal;
  late Object _transport;
  late int _seenMoves;
  bool _submitting = false;

  /// Our pick went out without a preview (network guest, KLD-064): reveal
  /// it from the accepted event.
  bool _revealOwn = false;

  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _sync();
    c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_QuartettTrumpfBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _reveal = null;
      _sync();
    }
  }

  @override
  void dispose() {
    c.removeListener(_onChange);
    super.dispose();
  }

  void _sync() {
    _transport = c.transport;
    _seenMoves = c.moves.length;
  }

  void _onChange() {
    if (!mounted) return;
    final moves = c.moves;
    _Trick? next = _reveal;
    if (!identical(_transport, c.transport) || moves.length < _seenMoves) {
      // Restart or undo: drop any reveal.
      next = null;
      _submitting = false;
    } else if (moves.length > _seenMoves) {
      if (_submitting && !_revealOwn) {
        _submitting = false; // our own pick, already revealed
      } else {
        // A move we did not make here (network), or our own pick on a
        // device that cannot preview it: reveal it from its event.
        _submitting = false;
        _revealOwn = false;
        final m = moves.last;
        next = _Trick.fromPayload(m.player, m.event.payload, null);
      }
    }
    _sync();
    if (!identical(next, _reveal)) setState(() => _reveal = next);
  }

  QuartettGame? get _game {
    final g = c.game;
    return g is QuartettGame ? g : null;
  }

  /// Computes the trick for [stat] on a replayed copy of the engine; the real
  /// game is only changed on "Weiter".
  void _pick(QuartettStat stat) {
    if (!c.canAct || _reveal != null || _submitting) return;
    final move = <String, dynamic>{'action': 'pick', 'stat': stat.id};
    final copy = c.previewCopy();
    if (copy == null) {
      // Network guest: the opponent's card is not on this device. Submit;
      // the accepted event reveals the trick.
      _submitting = true;
      _revealOwn = true;
      c.submit(move).then((r) {
        if (!r.isAccepted) _submitting = _revealOwn = false;
      });
      return;
    }
    final event = copy.applyMove(move);
    final trick = event == null ? null : _Trick.fromPayload(c.game.currentPlayer, event.payload, move);
    if (trick != null) setState(() => _reveal = trick);
  }

  void _continue() {
    final trick = _reveal;
    if (trick == null) return;
    setState(() => _reveal = null);
    final move = trick.pending;
    if (move == null) return;
    _submitting = true;
    c.submit(move).then((r) {
      if (!r.isAccepted) _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final l10n = AppLocalizations.of(context);
    if (game == null) return Center(child: Text(l10n.quartettNoGame));
    final shell = GameScreen.of(context);
    final reveal = _reveal;
    final choosing = reveal == null && c.canAct && game.topCard(game.currentPlayer) != null;
    shell.setHint(choosing ? l10n.quartettTrumpfHintPick : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _counts(context, game, reveal),
          const SizedBox(height: 8),
          if (reveal != null)
            _revealView(context, reveal)
          else if (!game.isOver)
            _tableView(context, game),
        ],
      ),
    );
  }

  /// Stack counts of both players plus the pot. During a reveal the counts
  /// are those before the trick (the pick is not applied yet).
  Widget _counts(BuildContext context, QuartettGame game, _Trick? reveal) {
    Widget chip(String key, IconData icon, String text) => Chip(
          key: Key(key),
          avatar: Icon(icon, size: 18),
          label: Text(text),
          visualDensity: VisualDensity.compact,
        );
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        chip('qt-count-a', Icons.person, l10n.quartettPlayerCards(playerMark(Player.a), game.stackSize(Player.a))),
        chip('qt-count-b', Icons.person_outline, l10n.quartettPlayerCards(playerMark(Player.b), game.stackSize(Player.b))),
        if (game.potSize > 0) chip('qt-pot', Icons.savings_outlined, l10n.quartettTrumpfPot(game.potSize)),
      ],
    );
  }

  /// Whose card this device shows: the single local player, or (hot-seat)
  /// the player to move.
  Player _viewer(QuartettGame g) {
    final local = c.transport.localPlayers;
    return local.length == 1 ? local.first : g.currentPlayer;
  }

  /// Own top card face-up (stats tappable), opponent's stack face-down.
  Widget _tableView(BuildContext context, QuartettGame game) {
    final me = _viewer(game);
    final opp = me == Player.a ? Player.b : Player.a;
    final top = game.topCard(me);
    if (top == null) return const SizedBox.shrink();
    final own = QuartettCard(
      key: const Key('qt-own-card'),
      card: top,
      statKeyPrefix: 'qt-stat-',
      onStatTap: _pick,
      enabled: c.canAct,
    );
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    Widget caption(String s) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(s, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
        );
    final oppStack = SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          caption(l10n.quartettTrumpfOpponentStack(playerMark(opp))),
          QuartettCard.back(
            key: const Key('qt-opponent-stack'),
            label: playerMark(opp),
            count: game.stackSize(opp),
            dense: true,
          ),
        ],
      ),
    );
    final ownColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [caption(l10n.quartettTrumpfYourCard(playerMark(me))), own],
    );
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= 520) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: ownColumn), const SizedBox(width: 16), oppStack],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [ownColumn, const SizedBox(height: 12), Center(child: oppStack)],
      );
    });
  }

  Widget _revealView(BuildContext context, _Trick t) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final w = t.winner;
    final headline = w == null ? l10n.quartettTrumpfTie : l10n.quartettTrumpfWinsTrick(playerMark(w));
    final color = w == null ? quartettOutcomeColor(QuartettOutcome.tie) : quartettOutcomeColor(QuartettOutcome.win);
    QuartettOutcome outcomeOf(Player p) =>
        w == null ? QuartettOutcome.tie : (w == p ? QuartettOutcome.win : QuartettOutcome.lose);

    Widget side(Player p, qe.Card card) {
      final o = outcomeOf(p);
      final word = switch (o) {
        QuartettOutcome.win => l10n.quartettTrumpfOutcomeWin,
        QuartettOutcome.lose => l10n.quartettTrumpfOutcomeLose,
        QuartettOutcome.tie => l10n.quartettTrumpfOutcomeTie,
      };
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.quartettTrumpfSideOutcome(playerMark(p), word),
              key: Key('qt-reveal-${p.name}-outcome'),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(color: quartettOutcomeColor(o), fontWeight: FontWeight.bold),
            ),
          ),
          QuartettCard(
            key: Key('qt-reveal-${p.name}'),
            card: card,
            highlightStat: t.stat.id,
            outcome: o,
            dense: true,
          ),
        ],
      );
    }

    // The picker's card on the left.
    final first = t.picker;
    final second = first == Player.a ? Player.b : Player.a;
    qe.Card cardOf(Player p) => p == Player.a ? t.a : t.b;

    return Column(
      key: const Key('qt-reveal'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.quartettTrumpfPicked(playerMark(t.picker), localizedStatLabel(l10n, t.stat.id)), style: theme.textTheme.bodyMedium),
                    Text(
                      headline,
                      key: const Key('qt-reveal-text'),
                      style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    if (w == null && t.pot > 0)
                      Text(l10n.quartettTrumpfPotAgain(t.pot, playerMark(t.picker)),
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                key: const Key('qt-continue'),
                onPressed: _continue,
                child: Text(l10n.quartettContinue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: side(first, cardOf(first))),
            const SizedBox(width: 8),
            Expanded(child: side(second, cardOf(second))),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;
import 'package:klunki_engine/klunki_engine.dart' as qe show Card;

import '../../game/game_controller.dart';
import '../../transport/game_transport.dart';
import '../../app/theme.dart';
import '../shell/game_screen.dart';
import 'quartett_card.dart';

/// Quartett (Sets) screen: classic Quartett, ask the opponent for cards and
/// collect complete sets.
///
/// Contract (keep it): the public class name `QuartettSetsScreen` and the
/// constructor `const QuartettSetsScreen({super.key, required this.controller})`.
/// The screen is built by `ui/shell/screen_registry.dart` and renders a
/// [GameScreen].
///
/// Flow of one ask (hot-seat):
/// 1. The player to move sees only their own hand, grouped by set. Every set
///    shows its four slots: own cards face-up, missing cards as "ask" slots.
/// 2. Tapping a missing slot asks for that card. The outcome is computed on a
///    replayed copy of the engine first:
///    * hit (or the move ends the game): submitted at once; "Treffer! O gibt
///      dir B3" and the same player asks again;
///    * miss: *not* submitted yet. "Fehlanzeige – du ziehst eine Karte" shows
///      the drawn card to the asker only; "Weiter" submits the ask, the turn
///      passes and the shell's [HandoverCover] appears.
/// 3. Laid-down quartets are announced ("Quartett! Klassiker abgelegt").
///
/// Public information is always visible: the opponent's hand count, the stock
/// count, both players' quartets and the score. While the handover cover is
/// up the board renders no cards at all (not even offstage).
///
/// Keys: `qs-hand-<id>` (own card), `qs-ask-<id>` (missing slot, tap to ask),
/// `qs-set-<letter>` (set group), `qs-feedback`, `qs-feedback-text`,
/// `qs-drawn-card`, `qs-continue`, `qs-opponent-count`, `qs-stock`,
/// `qs-score`, `qs-quartets-a`, `qs-quartets-b`.
class QuartettSetsScreen extends StatelessWidget {
  final GameController controller;

  const QuartettSetsScreen({super.key, required this.controller});

  /// History text for an ask: "fragt nach B3: Treffer" (the shell prefixes the
  /// player). Never names a drawn card.
  static String describeMove(AppLocalizations l10n, AcceptedMove m) {
    final p = m.event.payload;
    final card = m.move['card'];
    final hit = p is Map && p['hit'] == true;
    final quartet = p is Map ? p['quartet'] : null;
    final result = hit ? l10n.quartettSetsHit : l10n.quartettSetsMiss;
    return quartet is String
        ? l10n.quartettSetsMoveAskQuartet('$card', result, quartettSetName(l10n, quartet))
        : l10n.quartettSetsMoveAsk('$card', result);
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeMove,
      boardBuilder: (context, controller) => _QuartettSetsBoard(controller: controller),
    );
  }
}

/// Outcome of one ask as shown in the feedback panel.
class _Feedback {
  final Player asker;
  final String card;
  final bool hit;
  final String? quartet;

  /// Drawn card; only set when the viewer is the asker.
  final qe.Card? drew;

  /// The ask still to submit on "Weiter" (miss, not yet applied).
  final Map<String, dynamic>? pending;

  /// The move was made on this device by the asker (vs. arrived from elsewhere).
  final bool own;

  const _Feedback({
    required this.asker,
    required this.card,
    required this.hit,
    required this.quartet,
    required this.drew,
    required this.pending,
    required this.own,
  });

  static _Feedback? fromPayload(Player asker, Object? payload,
      {required bool own, Map<String, dynamic>? pending}) {
    if (payload is! Map) return null;
    final card = payload['card'];
    if (card is! String) return null;
    final quartet = payload['quartet'];
    final drew = payload['drew'];
    return _Feedback(
      asker: asker,
      card: card,
      hit: payload['hit'] == true,
      quartet: quartet is String ? quartet : null,
      drew: own && drew is String ? QuartettGame.cardById(drew) : null,
      pending: pending,
      own: own,
    );
  }
}

class _QuartettSetsBoard extends StatefulWidget {
  final GameController controller;
  const _QuartettSetsBoard({required this.controller});

  @override
  State<_QuartettSetsBoard> createState() => _QuartettSetsBoardState();
}

class _QuartettSetsBoardState extends State<_QuartettSetsBoard> {
  _Feedback? _feedback;
  late Object _transport;
  late int _seenMoves;
  bool _submitting = false;

  /// Our ask went out without a preview (network guest, KLD-064): show its
  /// feedback from the accepted event.
  bool _ownFeedback = false;

  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _sync();
    c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_QuartettSetsBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _feedback = null;
      _submitting = false;
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
    var next = _feedback;
    if (!identical(_transport, c.transport) || moves.length < _seenMoves) {
      next = null; // restart or undo
      _submitting = false;
    } else if (moves.length > _seenMoves) {
      if (_submitting && !_ownFeedback) {
        _submitting = false; // our own ask, feedback already set
      } else {
        // A move not made through this board (network): announce it
        // publicly; our own ask without a preview: as our own.
        final own = _ownFeedback;
        _submitting = false;
        _ownFeedback = false;
        final m = moves.last;
        next = _Feedback.fromPayload(m.player, m.event.payload, own: own);
      }
    }
    _sync();
    if (!identical(next, _feedback)) setState(() => _feedback = next);
  }

  QuartettGame? get _game {
    final g = c.game;
    return g is QuartettGame ? g : null;
  }

  /// Whose hand this device shows: the single local player, or (hot-seat) the
  /// player to move.
  Player _viewer(QuartettGame g) {
    final local = c.transport.localPlayers;
    return local.length == 1 ? local.first : g.currentPlayer;
  }

  bool get _canAsk => c.canAct && !c.needsHandover && _feedback?.pending == null && !_submitting;

  void _ask(String cardId) {
    if (!_canAsk) return;
    final game = _game;
    if (game == null) return;
    final move = <String, dynamic>{'action': 'ask', 'card': cardId};
    final copy = c.previewCopy();
    if (copy == null) {
      // Network guest: the opponent's hand is not on this device. Submit;
      // the accepted event gives the feedback.
      setState(() => _feedback = null);
      _ownFeedback = true;
      _submit(move);
      return;
    }
    final event = copy.applyMove(move);
    if (event == null) return;
    final asker = game.currentPlayer;
    final passes = !copy.isOver && copy.currentPlayer != asker;
    if (passes) {
      // Miss: show the outcome (and the drawn card) before the handover.
      setState(() => _feedback = _Feedback.fromPayload(asker, event.payload, own: true, pending: move));
      return;
    }
    setState(() => _feedback = _Feedback.fromPayload(asker, event.payload, own: true));
    _submit(move);
  }

  void _submit(Map<String, dynamic> move) {
    _submitting = true;
    c.submit(move).then((r) {
      if (!r.isAccepted && mounted) setState(() => _submitting = _ownFeedback = false);
    });
  }

  void _continue() {
    final f = _feedback;
    if (f == null) return;
    setState(() => _feedback = null);
    final move = f.pending;
    if (move != null) _submit(move);
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final l10n = AppLocalizations.of(context);
    if (game == null) return Center(child: Text(l10n.quartettNoGame));
    final shell = GameScreen.of(context);
    if (c.needsHandover) {
      // Covered: keep the tree free of any card.
      shell.setHint(null);
      return const SizedBox.shrink();
    }
    final f = _feedback;
    final viewer = _viewer(game);
    final hint = game.isOver
        ? null
        : f?.pending != null
            ? l10n.quartettSetsHintContinue(playerMark(_other(viewer)))
            : _canAsk
                ? l10n.quartettSetsHintAsk
                : null;
    shell.setHint(hint);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _publicInfo(context, game, viewer),
              if (f != null) ...[const SizedBox(height: 8), _feedbackView(context, f, viewer)],
              if (!game.isOver) ...[const SizedBox(height: 12), _hand(context, game, viewer)],
            ],
          ),
        ),
      ),
    );
  }

  static Player _other(Player p) => p == Player.a ? Player.b : Player.a;

  /// Opponent's hand count, stock, score and both players' quartets.
  Widget _publicInfo(BuildContext context, QuartettGame game, Player viewer) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final opp = _other(viewer);
    final qa = game.quartetsOf(Player.a), qb = game.quartetsOf(Player.b);
    Widget chip(String key, IconData icon, String text) => Chip(
          key: Key(key),
          avatar: Icon(icon, size: 18),
          label: Text(text),
          visualDensity: VisualDensity.compact,
        );
    Widget quartets(Player p, List<String> sets) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            key: Key('qs-quartets-${p.name}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${playerMark(p)}:', style: theme.textTheme.labelLarge),
                ),
              ),
              Expanded(
                child: sets.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(l10n.quartettSetsNoQuartet, style: theme.textTheme.bodySmall),
                      )
                    : Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [for (final s in sets) _quartetBadge(context, s)],
                      ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            chip('qs-opponent-count', Icons.back_hand_outlined, l10n.quartettPlayerCards(playerMark(opp), game.handOf(opp).length)),
            chip('qs-stock', Icons.layers_outlined, l10n.quartettSetsStock(game.stockSize)),
            chip('qs-score', Icons.emoji_events_outlined, l10n.quartettSetsScore(qa.length, qb.length)),
          ],
        ),
        quartets(Player.a, qa),
        quartets(Player.b, qb),
      ],
    );
  }

  Widget _quartetBadge(BuildContext context, String set) {
    final color = quartettSetColor(set, KlunkiPalette.of(context).quartett);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        '$set ${quartettSetName(AppLocalizations.of(context), set)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _feedbackView(BuildContext context, _Feedback f, Player viewer) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final opp = playerMark(_other(f.asker));
    final String headline;
    if (!f.own) {
      headline = l10n.quartettSetsOtherAsked(playerMark(f.asker), f.card, f.hit ? l10n.quartettSetsHit : l10n.quartettSetsMiss);
    } else if (f.hit) {
      headline = l10n.quartettSetsHitGives(opp, f.card);
    } else if (f.drew != null) {
      headline = l10n.quartettSetsMissDraw;
    } else {
      headline = l10n.quartettSetsMissEmpty;
    }
    final color = quartettOutcomeColor(f.hit ? QuartettOutcome.win : QuartettOutcome.lose, KlunkiPalette.of(context).quartett);
    final q = f.quartet;
    final sub = <String>[
      if (f.own && f.hit && !c.game.isOver) l10n.quartettSetsAskAgain,
      if (f.own && !f.hit) l10n.quartettSetsNotHeld(opp, f.card),
    ];
    return Container(
      key: const Key('qs-feedback'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      key: const Key('qs-feedback-text'),
                      style: theme.textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                    ),
                    for (final s in sub) Text(s, style: theme.textTheme.bodyMedium),
                    if (q != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.quartettSetsQuartetLaid(quartettSetName(l10n, q)),
                          key: const Key('qs-quartet-text'),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: KlunkiPalette.of(context).quartett.setText(q), fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              if (f.pending != null || !f.own) ...[
                const SizedBox(width: 12),
                FilledButton(
                  key: const Key('qs-continue'),
                  onPressed: _continue,
                  child: Text(l10n.quartettContinue),
                ),
              ],
            ],
          ),
          if (f.drew != null) ...[
            const SizedBox(height: 12),
            Text(l10n.quartettSetsDrawn, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: QuartettCard(key: const Key('qs-drawn-card'), card: f.drew!, dense: true),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// [viewer]'s hand grouped by set, each set with its four slots.
  Widget _hand(BuildContext context, QuartettGame game, Player viewer) {
    final theme = Theme.of(context);
    final hand = game.handOf(viewer);
    final l10n = AppLocalizations.of(context);
    final held = {for (final card in hand) card.id};
    final sets = [for (final s in QuartettGame.setNames.keys) if (hand.any((card) => card.set == s)) s];
    final askable = _canAsk && viewer == game.currentPlayer
        ? {for (final m in game.legalMoves) m['card'] as String}
        : const <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.quartettSetsYourCards(playerMark(viewer), hand.length), style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        for (final s in sets) _setGroup(context, s, held, askable),
      ],
    );
  }

  Widget _setGroup(BuildContext context, String set, Set<String> held, Set<String> askable) {
    final theme = Theme.of(context);
    final color = KlunkiPalette.of(context).quartett.setText(set);
    final slots = [for (final card in QuartettGame.deck) if (card.set == set) card];
    final have = slots.where((card) => held.contains(card.id)).length;
    return Padding(
      key: Key('qs-set-$set'),
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(width: 4, height: 20, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$set ${quartettSetName(AppLocalizations.of(context), set)}',
                  style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ),
              Text(AppLocalizations.of(context).quartettSetsProgress(have, 4 - have), style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(builder: (context, box) {
            const gap = 6.0;
            final perRow = box.maxWidth >= 520 ? 4 : 2;
            final w = (box.maxWidth - gap * (perRow - 1)) / perRow;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final card in slots)
                  SizedBox(
                    width: w,
                    child: held.contains(card.id)
                        ? _OwnCard(card: card)
                        : _MissingSlot(
                            card: card,
                            onAsk: askable.contains(card.id) ? () => _ask(card.id) : null,
                          ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

/// Compact face-up hand card (id badge + car name in the set colour). Tap
/// shows the full [QuartettCard]. Local wrapper: [QuartettCard] has no compact
/// hand mode.
class _OwnCard extends StatelessWidget {
  final qe.Card card;
  const _OwnCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = quartettSetColor(card.set, KlunkiPalette.of(context).quartett);
    return Material(
      key: Key('qs-hand-${card.id}'),
      color: color,
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: QuartettCard(card: card),
              ),
            ),
          ),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                child: Text(card.id,
                    style: theme.textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  card.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card of a held set that the player lacks; tap to ask for it.
class _MissingSlot extends StatelessWidget {
  final qe.Card card;
  final VoidCallback? onAsk;
  const _MissingSlot({required this.card, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = KlunkiPalette.of(context).quartett.setText(card.set);
    final enabled = onAsk != null;
    return Material(
      key: Key('qs-ask-${card.id}'),
      color: color.withValues(alpha: enabled ? 0.08 : 0.04),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withValues(alpha: enabled ? 0.8 : 0.35), width: 1.5),
      ),
      child: InkWell(
        onTap: onAsk,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Text(card.id,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color.withValues(alpha: enabled ? 1 : 0.5), fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  enabled ? AppLocalizations.of(context).quartettSetsAskSlot : AppLocalizations.of(context).quartettSetsMissingSlot,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              if (enabled) Icon(Icons.help_outline, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

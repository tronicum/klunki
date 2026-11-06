import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart';
import 'maumau_cards.dart';

/// Mau-Mau screen (KLD-118 step 2, hot-seat).
///
/// Contract (keep it): the public class name `MauMauScreen` and the
/// constructor `const MauMauScreen({super.key, required this.controller})`.
///
/// From top to bottom: the other player's hand (backs and a count), what
/// happened last (public, e.g. "Anna hat Herz 7 gelegt. Ben muss 2 Karten
/// ziehen."), the table (draw pile with its count, the top card with the
/// wished suit or the cards to draw), the buttons ("Karte ziehen",
/// "Behalten", "Passen", "Mau!") and the own hand, sorted, the cards that
/// may be laid lifted and framed, the others greyed.
///
/// Tapping a card lays it; a jack first asks for the suit
/// ([showMauMauSuitPicker]). Drawing is previewed on a copy of the engine:
/// a drawn card that fits stays in the hand to lay or keep; cards that end
/// the turn (no fit, or the cards of a 7) are shown to the drawer first,
/// "Weiter" submits the draw and the shell's handover cover follows. While
/// the cover is up the board renders no card.
///
/// Keys: `maumau-opponent`, `maumau-last`, `maumau-stock`, `maumau-top`,
/// `maumau-wish`, `maumau-penalty`, `maumau-draw`, `maumau-keep`,
/// `maumau-pass`, `maumau-mau`, `maumau-hand-<id>`, `maumau-feedback`,
/// `maumau-continue`; the suit picker: `maumau-suit-picker`,
/// `maumau-suit-<c|s|h|d>`.
class MauMauScreen extends StatelessWidget {
  final GameController controller;
  const MauMauScreen({super.key, required this.controller});

  /// History text for a move (the shell prefixes the player). Never names a
  /// drawn card.
  static String describeMove(AppLocalizations l10n, AcceptedMove m) {
    final p = m.event.payload is Map ? m.event.payload as Map : const {};
    switch (m.move['action']) {
      case 'play':
        final card = MauMauCard.byId('${m.move['card']}');
        if (card == null) return '${m.move}';
        final name = maumauCardName(l10n, card);
        final wish = MauMauSuit.byCode('${m.move['suit']}');
        return wish == null ? l10n.maumauMovePlay(name) : l10n.maumauMovePlayWish(name, maumauSuitName(l10n, wish));
      case 'draw':
        return l10n.maumauMoveDraw(p['count'] as int? ?? 1);
      case 'pass':
        return p['kept'] == true ? l10n.maumauMoveKeep : l10n.maumauMovePass;
    }
    return '${m.move}';
  }

  @override
  Widget build(BuildContext context) {
    return GameScreen(
      controller: controller,
      describeMove: describeMove,
      handoverDetail: (context) => _HandoverDetail(controller: controller),
      boardBuilder: (context, controller) => _MauMauBoard(controller: controller),
    );
  }
}

MauMauGame? _gameOf(GameController c) {
  final g = c.game;
  return g is MauMauGame ? g : null;
}

Player _other(Player p) => p == Player.a ? Player.b : Player.a;

/// The last play move of the log (resigns skipped), or null.
AcceptedMove? _lastMove(GameController c) {
  for (final m in c.moves.reversed) {
    if (Game.resignerOf(m.move) == null) return m;
  }
  return null;
}

/// What [m] did, in plain words, public information only ("Anna hat Herz 7
/// gelegt. Ben muss 2 Karten ziehen.").
String _describeLast(BuildContext context, AcceptedMove m) {
  final l10n = AppLocalizations.of(context);
  final who = playerName(context, m.player);
  final next = playerName(context, _other(m.player));
  final p = m.event.payload is Map ? m.event.payload as Map : const {};
  final parts = <String>[];
  switch (m.move['action']) {
    case 'play':
      final card = MauMauCard.byId('${p['card']}');
      final name = card == null ? '' : maumauCardName(l10n, card);
      final wish = MauMauSuit.byCode('${p['wish']}');
      parts.add(
        wish == null
            ? l10n.maumauLastPlayed(who, name)
            : l10n.maumauLastPlayedWish(who, name, maumauSuitName(l10n, wish)),
      );
      if (p['mau'] == true) parts.add(l10n.maumauExtraMau(who));
      if (p['forgotMau'] == true) parts.add(l10n.maumauExtraForgotMau(who));
      if (m.event.winner != null) break;
      if (p['penalty'] case final int n) parts.add(l10n.maumauExtraPenalty(next, n));
      if (p['again'] == true) parts.add(l10n.maumauExtraAgain(next));
    case 'draw':
      final n = p['count'] as int? ?? 1;
      parts.add(p['penalty'] != null ? l10n.maumauLastDrewPenalty(who, n) : l10n.maumauLastDrew(who, n));
    case 'pass':
      parts.add(p['kept'] == true ? l10n.maumauLastKept(who) : l10n.maumauLastPassed(who));
  }
  if (p['reshuffled'] == true) parts.add(l10n.maumauExtraReshuffled);
  return parts.join(' ');
}

/// Asks which suit a jack wishes; null when dismissed.
Future<MauMauSuit?> showMauMauSuitPicker(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<MauMauSuit>(
    context: context,
    builder: (ctx) => AlertDialog(
      key: const Key('maumau-suit-picker'),
      title: Text(l10n.maumauPickSuitTitle, textAlign: TextAlign.center),
      content: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final s in MauMauSuit.values)
            Material(
              key: Key('maumau-suit-${s.code}'),
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: maumauSuitColor(s).withValues(alpha: 0.5), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(ctx).pop(s),
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MauMauSuitIcon(suit: s, size: 52),
                      const SizedBox(height: 6),
                      Text(
                        maumauSuitName(l10n, s),
                        style: TextStyle(color: maumauSuitColor(s), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.shellCancel))],
    ),
  );
}

/// Public info on the handover cover: the top card and what happened last.
class _HandoverDetail extends StatelessWidget {
  final GameController controller;
  const _HandoverDetail({required this.controller});

  @override
  Widget build(BuildContext context) {
    final g = _gameOf(controller);
    final last = _lastMove(controller);
    if (g == null || last == null) return const SizedBox.shrink();
    return Column(
      key: const Key('maumau-cover-detail'),
      mainAxisSize: MainAxisSize.min,
      children: [
        MauMauCardFace(card: g.topCard, width: 64),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            _describeLast(context, last),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

/// Cards drawn in a preview that ends the turn: shown to the drawer until
/// "Weiter" submits [move].
class _Drawn {
  final List<MauMauCard> cards;
  final bool penalty;
  final Map<String, dynamic> move;
  const _Drawn(this.cards, this.penalty, this.move);
}

class _MauMauBoard extends StatefulWidget {
  final GameController controller;
  const _MauMauBoard({required this.controller});

  @override
  State<_MauMauBoard> createState() => _MauMauBoardState();
}

class _MauMauBoardState extends State<_MauMauBoard> {
  _Drawn? _drawn;
  bool _submitting = false;

  /// "Mau!" pressed for the next card.
  bool _mau = false;
  late Object _transport;
  late int _seen;

  GameController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _sync();
    c.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_MauMauBoard old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
      _reset();
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
    _seen = c.moves.length;
  }

  void _reset() {
    _drawn = null;
    _submitting = false;
    _mau = false;
  }

  void _onChange() {
    if (!mounted) return;
    if (!identical(_transport, c.transport) || c.moves.length != _seen) {
      // A move, an undo or a new game: start the turn fresh.
      setState(() {
        if (!identical(_transport, c.transport) || c.moves.length < _seen) _drawn = null;
        _submitting = false;
        _mau = false;
      });
    }
    _sync();
  }

  /// Whose hand this device shows: the single local player, or (hot-seat)
  /// the player to move.
  Player _viewer(MauMauGame g) {
    final local = c.transport.localPlayers;
    return local.length == 1 ? local.first : g.currentPlayer;
  }

  bool get _canAct => c.canAct && !c.needsHandover && _drawn == null && !_submitting;

  void _submit(Map<String, dynamic> move) {
    _submitting = true;
    c.submit(move).then((r) {
      if (!r.isAccepted && mounted) setState(() => _submitting = false);
    });
  }

  Future<void> _play(MauMauGame g, MauMauCard card) async {
    if (!_canAct || !g.canPlay(card)) return;
    final move = <String, dynamic>{'action': 'play', 'card': card.id};
    if (card.rank == MauMauRank.jack) {
      final suit = await showMauMauSuitPicker(context);
      if (suit == null || !mounted || !_canAct) return;
      move['suit'] = suit.code;
    }
    if (_mau && g.mauDue) move['mau'] = true;
    setState(() => _submit(move));
  }

  void _draw(MauMauGame g) {
    if (!_canAct || !g.canDraw) return;
    const move = {'action': 'draw'};
    final copy = c.previewCopy();
    if (copy == null) {
      setState(() => _submit(move));
      return;
    }
    final me = g.currentPlayer;
    final e = copy.applyMove(move);
    if (e == null) return;
    final p = e.payload as Map;
    if (!copy.isOver && copy.currentPlayer != me) {
      // The turn ends: show the drawn cards to the drawer first.
      final cards = [for (final id in p['drew'] as List) MauMauCard.byId('$id')!];
      setState(() => _drawn = _Drawn(cards, p['penalty'] != null, move));
      return;
    }
    setState(() => _submit(move));
  }

  void _pass() {
    if (!_canAct) return;
    setState(() => _submit(const {'action': 'pass'}));
  }

  void _continue() {
    final d = _drawn;
    if (d == null || _submitting) return;
    setState(() {
      _drawn = null;
      _submit(d.move);
    });
  }

  String? _hint(AppLocalizations l10n, MauMauGame g, Player viewer) {
    if (g.isOver || _drawn != null || !_canAct || g.currentPlayer != viewer) return null;
    if (g.penalty > 0) {
      return g.playableCards.isNotEmpty ? l10n.maumauHintPenaltyStack(g.penalty) : l10n.maumauHintPenalty(g.penalty);
    }
    if (g.hasDrawn) return l10n.maumauHintDrawn;
    if (g.canPass) return l10n.maumauHintPass;
    if (g.mauDue && !_mau && g.playableCards.isNotEmpty) return l10n.maumauHintMau;
    if (g.wish case final w?) return l10n.maumauHintWish(maumauSuitName(l10n, w));
    return l10n.maumauHintPlay;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final g = _gameOf(c);
    if (g == null) return const SizedBox.shrink();
    final shell = GameScreen.of(context);
    if (c.needsHandover) {
      // Covered: keep the tree free of any card.
      shell.setHint(null);
      return const SizedBox.shrink();
    }
    final viewer = _viewer(g);
    shell.setHint(_hint(l10n, g, viewer));
    final last = _lastMove(c);
    return LayoutBuilder(
      builder: (context, box) {
        final width = math.min(box.maxWidth, 720.0);
        final tableCard = (width * 0.22).clamp(72.0, 112.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _opponent(context, g, _other(viewer)),
                  const SizedBox(height: 8),
                  if (last != null) _lastAction(context, last),
                  const SizedBox(height: 12),
                  _table(context, g, tableCard),
                  const SizedBox(height: 12),
                  if (_drawn case final d?)
                    _drawnView(context, d)
                  else if (!g.isOver) ...[
                    _actions(context, g),
                    const SizedBox(height: 8),
                    _hand(context, g, viewer),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _opponent(BuildContext context, MauMauGame g, Player opp) {
    final l10n = AppLocalizations.of(context);
    final n = g.handCount(opp);
    const w = 30.0;
    final shown = math.min(n, 12);
    return Row(
      key: const Key('maumau-opponent'),
      children: [
        SizedBox(
          width: w + (shown > 1 ? (shown - 1) * 10.0 : 0),
          height: w / maumauCardAspect,
          child: Stack(
            children: [
              for (var i = 0; i < shown; i++)
                Positioned(
                  left: i * 10.0,
                  child: const MauMauCardBack(width: w),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.maumauOpponentCards(playerName(context, opp), n),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ],
    );
  }

  Widget _lastAction(BuildContext context, AcceptedMove last) {
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maumau');
    return Container(
      key: const Key('maumau-last'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.container.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(_describeLast(context, last), style: theme.textTheme.bodyMedium),
    );
  }

  /// Draw pile (tap to draw) and the discard pile with the wish or the 7s.
  Widget _table(BuildContext context, MauMauGame g, double cardWidth) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canDraw = _canAct && g.canDraw;
    Widget badge(String key, Widget child, Color color) => Container(
      key: Key(key),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        child: child,
      ),
    );
    final stock = Semantics(
      button: true,
      label: l10n.maumauStockLabel(g.stockCount),
      child: GestureDetector(
        key: const Key('maumau-stock'),
        onTap: canDraw ? () => _draw(g) : null,
        child: Column(
          children: [
            g.stockCount > 0
                ? MauMauCardBack(width: cardWidth)
                : Container(
                    width: cardWidth,
                    height: cardWidth / maumauCardAspect,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardWidth * 0.1),
                      border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
                    ),
                  ),
            const SizedBox(height: 6),
            Text(l10n.maumauStock(g.stockCount), style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
    final wish = g.wish;
    final discard = Column(
      children: [
        SizedBox(
          width: cardWidth + 8,
          height: cardWidth / maumauCardAspect + 4,
          child: Stack(
            children: [
              if (g.discardCount > 1)
                Positioned(
                  left: 6,
                  top: 3,
                  child: Transform.rotate(
                    angle: 0.08,
                    child: Container(
                      width: cardWidth,
                      height: cardWidth / maumauCardAspect,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EEE6),
                        borderRadius: BorderRadius.circular(cardWidth * 0.1),
                        border: Border.all(color: const Color(0xFFBDB6A8)),
                      ),
                    ),
                  ),
                ),
              MauMauCardFace(key: const Key('maumau-top'), card: g.topCard, width: cardWidth),
            ],
          ),
        ),
        const SizedBox(height: 6),
        if (wish != null)
          badge(
            'maumau-wish',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(l10n.maumauWish(maumauSuitName(l10n, wish)), textAlign: TextAlign.center)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: MauMauSuitIcon(suit: wish, size: 16),
                ),
              ],
            ),
            KlunkiPalette.of(context).accent('maumau').color,
          )
        else if (g.penalty > 0)
          badge('maumau-penalty', Text(l10n.maumauDrawPenalty(g.penalty), textAlign: TextAlign.center), maumauRed)
        else
          Text(l10n.maumauDiscard, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
      ],
    );
    // Each pile gets half the width; long labels wrap under their card.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Align(alignment: AlignmentDirectional.topEnd, child: stock)),
        SizedBox(width: cardWidth * 0.4),
        Expanded(child: Align(alignment: AlignmentDirectional.topStart, child: discard)),
      ],
    );
  }

  Widget _actions(BuildContext context, MauMauGame g) {
    final l10n = AppLocalizations.of(context);
    final act = _canAct;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (g.canDraw)
          FilledButton.tonalIcon(
            key: const Key('maumau-draw'),
            onPressed: act ? () => _draw(g) : null,
            icon: const Icon(Icons.add_card),
            label: Text(g.penalty > 0 ? l10n.maumauDrawPenalty(g.penalty) : l10n.maumauDraw),
          ),
        if (g.hasDrawn)
          FilledButton.tonalIcon(
            key: const Key('maumau-keep'),
            onPressed: act ? _pass : null,
            icon: const Icon(Icons.back_hand_outlined),
            label: Text(l10n.maumauKeep),
          )
        else if (g.canPass)
          FilledButton.tonalIcon(
            key: const Key('maumau-pass'),
            onPressed: act ? _pass : null,
            icon: const Icon(Icons.skip_next),
            label: Text(l10n.maumauPass),
          ),
        if (g.mauDue && g.playableCards.isNotEmpty)
          FilterChip(
            key: const Key('maumau-mau'),
            label: Text(l10n.maumauMauButton),
            selected: _mau,
            onSelected: act ? (v) => setState(() => _mau = v) : null,
          ),
      ],
    );
  }

  /// The own hand in one or two overlapping rows; cards that may be laid
  /// lifted and framed, the others greyed.
  Widget _hand(BuildContext context, MauMauGame g, Player viewer) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hand = MauMauCard.sorted(g.handOf(viewer));
    final mine = g.currentPlayer == viewer;
    final accent = KlunkiPalette.of(context).accent('maumau').color;
    final drawn = g.drawnCard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.maumauYourCards(hand.length), style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, box) {
            final maxW = box.maxWidth;
            final cardW = (maxW / 4.6).clamp(64.0, 92.0);
            const lift = 14.0;
            // Up to two rows; the step shrinks so a row fits the width.
            final rows = hand.length * 34.0 + cardW > maxW * 1.0 && hand.length > 8 ? 2 : 1;
            final perRow = (hand.length / rows).ceil();
            final step = perRow <= 1 ? cardW : math.min(cardW + 6, (maxW - cardW) / (perRow - 1));
            Widget card(MauMauCard card) {
              final ok = mine && g.canPlay(card) && _canAct;
              return GestureDetector(
                key: Key('maumau-hand-${card.id}'),
                onTap: ok ? () => _play(g, card) : null,
                child: MauMauCardFace(
                  card: card,
                  width: cardW,
                  highlight: ok ? (card == drawn ? theme.colorScheme.primary : accent) : null,
                  dimmed: mine && !ok,
                ),
              );
            }

            final cardH = cardW / maumauCardAspect;
            return Column(
              children: [
                for (var r = 0; r < rows; r++)
                  Builder(
                    builder: (context) {
                      final row = hand.skip(r * perRow).take(perRow).toList();
                      final rowW = cardW + (row.length - 1) * step;
                      return SizedBox(
                        height: cardH + lift + 4,
                        width: maxW,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Stack(
                            children: [
                              for (final (i, c) in row.indexed)
                                Positioned(
                                  left: (maxW - rowW) / 2 + i * step,
                                  top: mine && g.canPlay(c) && _canAct ? 0 : lift,
                                  child: card(c),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _drawnView(BuildContext context, _Drawn d) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maumau');
    return Container(
      key: const Key('maumau-feedback'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.container.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.color),
      ),
      child: Column(
        children: [
          Text(
            d.penalty ? l10n.maumauDrewPenalty(d.cards.length) : l10n.maumauDrewNoFit,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [for (final card in d.cards) MauMauCardFace(card: card, width: 72)],
          ),
          const SizedBox(height: 12),
          FilledButton(key: const Key('maumau-continue'), onPressed: _continue, child: Text(l10n.maumauContinue)),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../profile/seen_tips.dart';
import '../../../transport/game_transport.dart';
import '../../shell/coach_marks.dart';
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
      if (p['penalty'] case final int n) {
        // A 7 on a 7: say that the cards add up (KLD-118).
        parts.add(
          n > MauMauGame.sevenPenalty ? l10n.maumauExtraPenaltyStacked(next, n) : l10n.maumauExtraPenalty(next, n),
        );
      }
      if (p['again'] == true) {
        parts.add(card?.rank == MauMauRank.ace ? l10n.maumauExtraAce(who) : l10n.maumauExtraAgain(next));
      }
    case 'draw':
      final n = p['count'] as int? ?? 1;
      parts.add(p['penalty'] != null ? l10n.maumauLastDrewPenalty(who, n) : l10n.maumauLastDrew(who, n));
    case 'pass':
      parts.add(p['kept'] == true ? l10n.maumauLastKept(who) : l10n.maumauLastPassed(who));
  }
  if (p['reshuffled'] == true) parts.add(l10n.maumauExtraReshuffled);
  return parts.join(' ');
}

/// The 7s of the open draw chain, oldest first (the last one is the top
/// card); empty while nobody has to draw.
List<MauMauCard> _sevenChain(GameController c, MauMauGame g) {
  if (g.penalty <= 0) return const [];
  final n = g.penalty ~/ MauMauGame.sevenPenalty;
  final out = <MauMauCard>[];
  for (final m in c.moves.reversed) {
    if (out.length >= n) break;
    if (Game.resignerOf(m.move) != null) continue;
    final card = m.move['action'] == 'play' ? MauMauCard.byId('${m.move['card']}') : null;
    if (card == null || card.rank != MauMauRank.seven) break;
    out.add(card);
  }
  return out.reversed.toList();
}

/// The discard pile: the top card on a hint of the cards below; while 7s
/// are stacked, the whole chain fanned out, each 7 with its "+2", so the
/// cards to draw visibly add up (KLD-118).
///
/// Keys: `maumau-discard`, `maumau-top` (the top card), `maumau-chain-<i>`
/// (the "+2" of the i-th 7, from 1).
class _DiscardPile extends StatelessWidget {
  final MauMauGame game;
  final List<MauMauCard> chain;
  final double width;
  const _DiscardPile({required this.game, required this.chain, required this.width});

  @override
  Widget build(BuildContext context) {
    final h = width / maumauCardAspect;
    final fan = chain.length >= 2 ? chain : const <MauMauCard>[];
    final step = width * 0.3;
    final chipFont = (width * 0.15).clamp(10.0, 15.0);
    Widget chip(int i) => Container(
      key: Key('maumau-chain-${i + 1}'),
      padding: EdgeInsets.symmetric(horizontal: chipFont * 0.3, vertical: 1),
      decoration: BoxDecoration(
        color: maumauRed,
        borderRadius: BorderRadius.circular(chipFont),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        '+${MauMauGame.sevenPenalty}',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: chipFont, height: 1.1),
      ),
    );
    final pile = SizedBox(
      key: const Key('maumau-discard'),
      width: width + 8 + (fan.isEmpty ? 0 : (fan.length - 1) * step),
      height: h + 4 + (fan.isEmpty ? 0 : chipFont),
      child: Directionality(
        // The fan grows to the right in every language, like the hand.
        textDirection: TextDirection.ltr,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (fan.isEmpty) ...[
              if (game.discardCount > 1)
                Positioned(
                  left: 6,
                  top: 3,
                  child: Transform.rotate(
                    angle: 0.08,
                    child: Container(
                      width: width,
                      height: h,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EEE6),
                        borderRadius: BorderRadius.circular(width * 0.1),
                        border: Border.all(color: const Color(0xFFBDB6A8)),
                      ),
                    ),
                  ),
                ),
              MauMauCardFace(key: const Key('maumau-top'), card: game.topCard, width: width),
            ] else ...[
              for (final (i, card) in fan.indexed)
                Positioned(
                  left: i * step,
                  top: chipFont,
                  child: Transform.rotate(
                    angle: (i - fan.length + 1) * 0.05,
                    child: MauMauCardFace(
                      key: i == fan.length - 1 ? const Key('maumau-top') : null,
                      card: i == fan.length - 1 ? game.topCard : card,
                      width: width,
                    ),
                  ),
                ),
              for (var i = 0; i < fan.length; i++) Positioned(left: i * step, top: 0, child: chip(i)),
            ],
          ],
        ),
      ),
    );
    return FittedBox(fit: BoxFit.scaleDown, child: pile);
  }
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
        _DiscardPile(game: g, chain: _sevenChain(controller, g), width: 64),
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

/// Cards drawn in a preview that ends the turn: shown to the drawer, framed
/// in the [hand] they arrive in, until "Weiter" submits [move].
class _Drawn {
  final List<MauMauCard> cards;
  final List<MauMauCard> hand;
  final bool penalty;
  final Map<String, dynamic> move;
  const _Drawn(this.cards, this.hand, this.penalty, this.move);
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

  /// Targets of the "how to play" tour.
  final _handKey = GlobalKey(debugLabel: 'maumau-hand');
  final _stockKey = GlobalKey(debugLabel: 'maumau-stock');
  bool _coachPending = false;
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
      final hand = (copy as MauMauGame).handOf(me);
      setState(() => _drawn = _Drawn(cards, hand, p['penalty'] != null, move));
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

  /// The first time a player sees their own hand on their turn: a short
  /// "how to play" tour (once per device, [SeenTips.maumauIntro]). Never over
  /// the handover cover or a dialog; it points at the viewer's own hand only.
  /// Checked after two frames, once the layout has settled.
  void _maybeCoach(MauMauGame g, Player viewer) {
    if (_coachPending || SeenTips.shared.has(SeenTips.maumauIntro)) return;
    bool ready() =>
        mounted &&
        !c.needsHandover &&
        _canAct &&
        !c.game.isOver &&
        c.game.currentPlayer == viewer &&
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
        if (ready() && SeenTips.shared.markFirst(SeenTips.maumauIntro)) _showCoach();
      });
      binding.scheduleFrame();
    });
  }

  /// The tour: lay a fitting card (the hand), else draw (the pile), who
  /// wins, and where the rules are (the shell's "Regeln" button, KLD-123).
  Future<void> _showCoach() {
    final l10n = AppLocalizations.of(context);
    final g = _gameOf(c);
    return showCoachMarks(
      context,
      keyPrefix: 'maumau-coach',
      accent: KlunkiPalette.of(context).accent('maumau'),
      steps: [
        CoachStep(target: _handKey, icon: Icons.touch_app_outlined, text: l10n.maumauCoachPlay),
        CoachStep(target: _stockKey, icon: Icons.add_card, text: l10n.maumauCoachDraw),
        CoachStep(
          icon: Icons.emoji_events_outlined,
          text: g != null && g.rules.mauCall ? l10n.maumauCoachWinMau : l10n.maumauCoachWin,
        ),
        // KLD-123: where all the rules are.
        CoachStep(target: GameScreen.of(context).rulesButtonKey, icon: Icons.menu_book_outlined, text: l10n.rulesCoachHere),
      ],
    );
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
    _maybeCoach(g, viewer);
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
                  if (_drawn case final d?) ...[
                    _drawnView(context, d),
                    const SizedBox(height: 8),
                    _hand(context, g, viewer, arrived: d),
                  ] else if (!g.isOver) ...[
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
    // Tapping the pile draws too; while that is possible it glows (more
    // when drawing is the only thing to do).
    final accent = KlunkiPalette.of(context).accent('maumau');
    final onlyDraw = canDraw && g.playableCards.isEmpty;
    final stock = Semantics(
      button: true,
      enabled: canDraw,
      label: l10n.maumauStockLabel(g.stockCount),
      child: GestureDetector(
        key: const Key('maumau-stock'),
        onTap: canDraw ? () => _draw(g) : null,
        child: Column(
          key: _stockKey,
          children: [
            g.stockCount > 0
                ? DecoratedBox(
                    key: Key(canDraw ? 'maumau-stock-active' : 'maumau-stock-idle'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardWidth * 0.1),
                      boxShadow: [
                        if (canDraw)
                          BoxShadow(
                            color: accent.onSurface(theme.brightness).withValues(alpha: onlyDraw ? 0.75 : 0.4),
                            blurRadius: onlyDraw ? 14 : 8,
                            spreadRadius: onlyDraw ? 3 : 1,
                          ),
                      ],
                    ),
                    child: MauMauCardBack(width: cardWidth),
                  )
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
    final chain = _sevenChain(c, g);
    final discard = Column(
      children: [
        _DiscardPile(game: g, chain: chain, width: cardWidth),
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
          badge(
            'maumau-penalty',
            Text(
              chain.length >= 2
                  ? l10n.maumauChainBadge(
                      List.filled(chain.length, '${MauMauGame.sevenPenalty}').join(' + '),
                      g.penalty,
                    )
                  : l10n.maumauDrawPenalty(g.penalty),
              textAlign: TextAlign.center,
            ),
            maumauRed,
          )
        else
          Text(l10n.maumauDiscard, style: theme.textTheme.labelLarge, textAlign: TextAlign.center),
      ],
    );
    // Each pile gets half the width; long labels wrap under their card.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Align(alignment: AlignmentDirectional.topEnd, child: stock),
        ),
        SizedBox(width: cardWidth * 0.4),
        Expanded(
          child: Align(alignment: AlignmentDirectional.topStart, child: discard),
        ),
      ],
    );
  }

  /// The buttons (KLD-118 follow-up): what to do now is filled in the game's
  /// colour ("Karte ziehen" when no card fits, "Passen" when nothing else is
  /// left, "Mau!" when it is due); the alternative to laying a card is
  /// outlined ("Karte ziehen" while a card fits, "Behalten" after drawing a
  /// fitting card). Actions that are not possible are not shown.
  Widget _actions(BuildContext context, MauMauGame g) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final accent = KlunkiPalette.of(context).accent('maumau');
    final onSurface = accent.onSurface(theme.brightness);
    final act = _canAct;
    final label = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    const size = Size(0, 52);
    const padding = EdgeInsets.symmetric(horizontal: 20);
    final filled = FilledButton.styleFrom(
      backgroundColor: accent.color,
      foregroundColor: accent.onColor,
      minimumSize: size,
      padding: padding,
      textStyle: label,
    );
    final outlined = OutlinedButton.styleFrom(
      foregroundColor: onSurface,
      side: BorderSide(color: onSurface, width: 2),
      minimumSize: size,
      padding: padding,
      textStyle: label,
    );
    Widget button(String key, IconData icon, String text, VoidCallback onPressed, {required bool main}) => main
        ? FilledButton.icon(
            key: Key(key),
            style: filled,
            onPressed: act ? onPressed : null,
            icon: Icon(icon),
            label: Text(text),
          )
        : OutlinedButton.icon(
            key: Key(key),
            style: outlined,
            onPressed: act ? onPressed : null,
            icon: Icon(icon),
            label: Text(text),
          );
    final canLay = g.playableCards.isNotEmpty;
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        if (g.mauDue && canLay) _mauButton(context, filled, outlined, act),
        if (g.canDraw)
          button(
            'maumau-draw',
            Icons.add_card,
            g.penalty > 0 ? l10n.maumauDrawPenalty(g.penalty) : l10n.maumauDraw,
            () => _draw(g),
            main: !canLay,
          ),
        if (g.hasDrawn)
          button('maumau-keep', Icons.back_hand_outlined, l10n.maumauKeep, _pass, main: false)
        else if (g.canPass)
          button('maumau-pass', Icons.skip_next, l10n.maumauPass, _pass, main: true),
      ],
    );
  }

  /// "Mau!" (house rule, only while it is due): filled before it is
  /// pressed, then outlined with a tick (tap again to take it back).
  Widget _mauButton(BuildContext context, ButtonStyle filled, ButtonStyle outlined, bool act) {
    final l10n = AppLocalizations.of(context);
    final accent = KlunkiPalette.of(context).accent('maumau');
    void toggle() => setState(() => _mau = !_mau);
    return Semantics(
      toggled: _mau,
      child: _mau
          ? OutlinedButton.icon(
              key: const Key('maumau-mau'),
              style: outlined.copyWith(
                backgroundColor: WidgetStatePropertyAll(accent.container.withValues(alpha: 0.7)),
              ),
              onPressed: act ? toggle : null,
              icon: const Icon(Icons.check_circle),
              label: Text(l10n.maumauMauButton),
            )
          : FilledButton.icon(
              key: const Key('maumau-mau'),
              style: filled,
              onPressed: act ? toggle : null,
              icon: const Icon(Icons.campaign),
              label: Text(l10n.maumauMauButton),
            ),
    );
  }

  /// The own hand in one or two overlapping rows; cards that may be laid
  /// lifted and framed, the others greyed. With [arrived] (cards just drawn
  /// that end the turn): the hand after the draw, the new cards lifted,
  /// framed and sliding in, nothing to tap.
  Widget _hand(BuildContext context, MauMauGame g, Player viewer, {_Drawn? arrived}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hand = MauMauCard.sorted(arrived?.hand ?? g.handOf(viewer));
    final fresh = {...?arrived?.cards};
    final mine = g.currentPlayer == viewer && arrived == null;
    final accent = KlunkiPalette.of(context).accent('maumau').color;
    final drawn = g.drawnCard;
    return Column(
      key: _handKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KLD-123: the rules ("?" before) are behind the shell's "Regeln".
        Text(l10n.maumauYourCards(hand.length), style: theme.textTheme.titleSmall),
        const SizedBox(height: 2),
        LayoutBuilder(
          builder: (context, box) {
            final maxW = box.maxWidth;
            final cardW = (maxW / 4.6).clamp(64.0, 92.0);
            const lift = 14.0;
            // Up to two rows; the step shrinks so a row fits the width.
            final rows = hand.length * 34.0 + cardW > maxW * 1.0 && hand.length > 8 ? 2 : 1;
            final perRow = (hand.length / rows).ceil();
            final step = perRow <= 1 ? cardW : math.min(cardW + 6, (maxW - cardW) / (perRow - 1));
            bool up(MauMauCard card) => fresh.contains(card) || (mine && g.canPlay(card) && _canAct);
            Widget card(MauMauCard card) {
              final ok = mine && g.canPlay(card) && _canAct;
              final face = GestureDetector(
                key: Key('maumau-hand-${card.id}'),
                onTap: ok ? () => _play(g, card) : null,
                child: MauMauCardFace(
                  card: card,
                  width: cardW,
                  highlight: fresh.contains(card)
                      ? accent
                      : ok
                      ? (card == drawn ? theme.colorScheme.primary : accent)
                      : null,
                  dimmed: mine && !ok,
                ),
              );
              if (!fresh.contains(card)) return face;
              // A new card slides in from the draw pile's side.
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Opacity(
                  opacity: t,
                  child: Transform.translate(offset: Offset(0, -60 * (1 - t)), child: child),
                ),
                child: face,
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
                                Positioned(left: (maxW - rowW) / 2 + i * step, top: up(c) ? 0 : lift, child: card(c)),
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

  /// What was drawn (the cards themselves show framed in the hand below)
  /// and "Weiter".
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
          FilledButton.icon(
            key: const Key('maumau-continue'),
            style: FilledButton.styleFrom(
              backgroundColor: accent.color,
              foregroundColor: accent.onColor,
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            onPressed: _continue,
            icon: const Icon(Icons.arrow_forward),
            label: Text(l10n.maumauContinue),
          ),
        ],
      ),
    );
  }
}

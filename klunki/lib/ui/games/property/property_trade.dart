import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../app/theme.dart';
import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart' show AcceptedMove;
import '../../shell/game_screen.dart' show UndoMoveButton;
import '../../shell/seat_game_screen.dart';
import 'property_board.dart' show propertyGroupColor;

/// Trades in Baulöwe (KLD-060 step 3b), hot-seat:
///
/// 1. The player whose turn it is taps "Tauschen" (before or after rolling,
///    at most [PropertyGame.maxTradeOffersPerTurn] offers a turn) and puts
///    an offer together in the trade sheet ([showPropertyTradeSheet]): the
///    partner, then "Du gibst" / "Du bekommst" with streets, money and free
///    cards. The engine checks it live ([PropertyGame.tradeProblem]); a
///    street whose colour group has buildings is shown, but cannot be
///    chosen ([PropertyGame.tradeSquareProblem]).
/// 2. The device goes to the partner ([PropertyTradeGate]: "Gib das Gerät an
///    Ben weiter"; the offering player can still take the offer back).
/// 3. The partner sees the whole offer ([PropertyTradeAnswer], full size
///    over the board) and taps "Annehmen" or "Ablehnen".
/// 4. The device goes back ([PropertyTradeGate]: "Ben nimmt den Tausch an"),
///    and the turn goes on. The answer is final: "Zug zurücknehmen" stops
///    there ([PropertyGame.isUndoBarrier]).
///
/// No secrets (everything in Baulöwe is public): the handover steps make
/// sure the right person decides, they hide nothing.
///
/// Keys: `property-trade-sheet`, `property-trade-partner-<seat>`,
/// `property-trade-<give|get>-<square>`, `property-trade-<give|get>-money`
/// (the amount) with `…-money-plus-<10|50|100>`, `…-money-minus-10`,
/// `…-money-reset`, `property-trade-<give|get>-cards` with `…-cards-plus`,
/// `…-cards-minus`, `property-trade-problem`, `property-trade-offer`;
/// `property-trade-answer-view` with `property-trade-answer`,
/// `property-trade-answer-<give|get>`, `property-trade-accept`, `property-trade-decline`;
/// `property-trade-cover`, `property-trade-handover`, `property-trade-back`.

/// Whether [game]'s current player may open the trade sheet now: their turn
/// (roll or end phase), offers left this turn, somebody to trade with.
bool propertyCanTrade(PropertyGame game) =>
    (game.phase == PropertyPhase.roll || game.phase == PropertyPhase.end) &&
    game.actor == game.currentSeat &&
    game.tradeOffersLeft > 0 &&
    game.activeSeats.length > 1;

/// The engine's reason why an offer cannot be made ([PropertyGame.tradeProblem],
/// [PropertyGame.tradeSquareProblem]) in words for the player.
String propertyTradeProblemText(AppLocalizations l10n, String problem) {
  if (problem == 'empty offer') return l10n.propertyTradeEmpty;
  if (problem == 'too many offers this turn') return l10n.propertyTradeTooMany(PropertyGame.maxTradeOffersPerTurn);
  if (problem == 'not enough money') return l10n.propertyTradeNoMoney;
  if (problem.startsWith('sell the houses')) return l10n.propertyTradeHouses;
  return l10n.propertyTradeNotNow;
}

/// One side of a trade in words: "Skalitzer Straße, 100 Taler, 1 Freikarte"
/// or "nichts" (history and story line).
String propertyTradeSideText(AppLocalizations l10n, PropertyTheme theme, Map<String, dynamic>? side) {
  final s = PropertyTradeSide.parse(side) ?? const PropertyTradeSide();
  final parts = [
    for (final i in s.squares) i >= 0 && i < theme.squares.length ? theme.squares[i].name : '?',
    if (s.money > 0) l10n.propertyMoney(s.money),
    if (s.cards > 0) l10n.propertyTradeCardCount(s.cards),
  ];
  return parts.isEmpty ? l10n.propertyTradeNothing : parts.join(', ');
}

/// [squares] by colour group (stations and utilities last), then by square.
List<int> _byGroup(PropertyTheme t, List<int> squares) => squares
  ..sort((x, y) {
    final gx = t.squares[x].group < 0 ? 99 : t.squares[x].group, gy = t.squares[y].group < 0 ? 99 : t.squares[y].group;
    return gx != gy ? gx - gy : x - y;
  });

// ------------------------------------------------------------- the sheet

/// The trade sheet of the current player: pick a partner and what goes
/// each way; "Angebot machen" sends the offer (and the board then asks for
/// the device to be handed over).
Future<void> showPropertyTradeSheet(BuildContext context, GameController controller) {
  final labels = SeatLabelsScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SeatLabelsScope(
      labels: labels,
      child: PropertyTradeSheet(controller: controller),
    ),
  );
}

class PropertyTradeSheet extends StatefulWidget {
  final GameController controller;
  const PropertyTradeSheet({super.key, required this.controller});

  @override
  State<PropertyTradeSheet> createState() => _PropertyTradeSheetState();
}

class _PropertyTradeSheetState extends State<PropertyTradeSheet> {
  int? _partner;
  final Set<int> _give = {}, _get = {};
  int _giveMoney = 0, _getMoney = 0, _giveCards = 0, _getCards = 0;

  PropertyGame get game => widget.controller.game as PropertyGame;
  int get me => game.currentSeat;
  List<int> get _others => [
    for (final s in game.activeSeats)
      if (s != me) s,
  ];

  @override
  void initState() {
    super.initState();
    final others = _others;
    // One possible partner: chosen already.
    if (others.length == 1) _partner = others.single;
  }

  PropertyTradeSide get _giveSide =>
      PropertyTradeSide(money: _giveMoney, squares: _byGroup(game.theme, _give.toList()), cards: _giveCards);
  PropertyTradeSide get _getSide =>
      PropertyTradeSide(money: _getMoney, squares: _byGroup(game.theme, _get.toList()), cards: _getCards);

  void _pickPartner(int seat) => setState(() {
    if (_partner == seat) return;
    _partner = seat;
    // The other side belonged to the old partner.
    _get.clear();
    _getMoney = 0;
    _getCards = 0;
  });

  Future<void> _offer() async {
    final to = _partner!;
    final move = {'action': 'tradeOffer', 'to': to, 'give': _giveSide.toJson(), 'get': _getSide.toJson()};
    Navigator.of(context).pop();
    await widget.controller.submit(move);
  }

  String _name(BuildContext context, int seat) =>
      SeatLabelsScope.of(context).label(context, AppLocalizations.of(context), seat, count: game.playerCount);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final partner = _partner;
    final problem = partner == null ? null : game.tradeProblem(partner, _giveSide, _getSide);
    final others = _others;
    final left = game.tradeOffersLeft;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          key: const Key('property-trade-sheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  Row(
                    children: [
                      SeatToken(seat: me, size: 26),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l10n.propertyTradeTitle, style: theme.textTheme.titleLarge)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 8),
                    child: Text(
                      l10n.propertyTradeOffersLeft(left),
                      key: const Key('property-trade-left'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(l10n.propertyTradeWith, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final s in others)
                        ChoiceChip(
                          key: Key('property-trade-partner-$s'),
                          avatar: SeatToken(seat: s, size: 20),
                          label: Text(_name(context, s)),
                          selected: partner == s,
                          showCheckmark: false,
                          onSelected: (_) => _pickPartner(s),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, box) {
                      final give = _side(context, me, give: true);
                      final get = partner == null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(l10n.propertyTradeWith, style: theme.textTheme.bodyMedium),
                            )
                          : _side(context, partner, give: false);
                      // Side by side from phone width on; very narrow: stacked.
                      if (box.maxWidth < 320) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [give, const SizedBox(height: 12), get],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: give),
                          const SizedBox(width: 10),
                          Expanded(child: get),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (problem != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                propertyTradeProblemText(l10n, problem),
                                key: const Key('property-trade-problem'),
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  FilledButton.icon(
                    key: const Key('property-trade-offer'),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                    onPressed: partner != null && problem == null ? _offer : null,
                    icon: const Icon(Icons.swap_horiz),
                    label: Text(l10n.propertyTradeOffer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One column: "Du gibst" (the current player's things) or "Du bekommst"
  /// (the partner's).
  Widget _side(BuildContext context, int seat, {required bool give}) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tag = give ? 'give' : 'get';
    final chosen = give ? _give : _get;
    final st = game.seats[seat];
    final squares = _byGroup(game.theme, game.ownedBy(seat));
    return Column(
      key: Key('property-trade-$tag'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (!give) ...[SeatToken(seat: seat, size: 18), const SizedBox(width: 6)],
            Expanded(
              child: Text(
                give ? l10n.propertyTradeGive : '${l10n.propertyTradeGet} · ${_name(context, seat)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Stepper(
          keyPrefix: 'property-trade-$tag-money',
          label: l10n.propertyTradeMoney,
          value: l10n.propertyMoney(give ? _giveMoney : _getMoney),
          amount: give ? _giveMoney : _getMoney,
          max: st.cash,
          steps: const [10, 50, 100],
          resetTooltip: l10n.propertyTradeMoneyReset,
          onChanged: (v) => setState(() => give ? _giveMoney = v : _getMoney = v),
        ),
        if (st.freeCards.isNotEmpty) ...[
          const SizedBox(height: 6),
          _Stepper(
            keyPrefix: 'property-trade-$tag-cards',
            label: l10n.propertyTradeFreeCards,
            value: '${give ? _giveCards : _getCards}',
            amount: give ? _giveCards : _getCards,
            max: st.freeCards.length,
            steps: const [1],
            onChanged: (v) => setState(() => give ? _giveCards = v : _getCards = v),
          ),
        ],
        const SizedBox(height: 8),
        if (squares.isEmpty) Text(l10n.propertyTradeNoStreets, style: theme.textTheme.bodySmall),
        for (final i in squares)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Builder(
              builder: (context) {
                final problem = game.tradeSquareProblem(seat, i);
                return PropertyDeedChip(
                  key: Key('property-trade-$tag-$i'),
                  game: game,
                  square: i,
                  selected: chosen.contains(i),
                  reason: problem == null ? null : propertyTradeProblemText(l10n, problem),
                  onTap: problem != null
                      ? null
                      : () => setState(() => chosen.contains(i) ? chosen.remove(i) : chosen.add(i)),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// An amount with "−" and quick "+" steps, bounded by 0 and [max].
class _Stepper extends StatelessWidget {
  final String keyPrefix;
  final String label;
  final String value;
  final int amount;
  final int max;
  final List<int> steps;
  final String? resetTooltip;
  final ValueChanged<int> onChanged;
  const _Stepper({
    required this.keyPrefix,
    required this.label,
    required this.value,
    required this.amount,
    required this.max,
    required this.steps,
    required this.onChanged,
    this.resetTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = steps.length > 1;
    Widget step(String text, Key key, VoidCallback? onPressed) => SizedBox(
      height: 36,
      child: FilledButton.tonal(
        key: key,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(44, 36),
          visualDensity: VisualDensity.compact,
        ),
        onPressed: onPressed,
        // Numbers read left to right in every language ("+50").
        child: Text(text, textDirection: TextDirection.ltr),
      ),
    );
    final small = steps.first;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 4, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  key: Key(keyPrefix),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: amount > 0 ? FontWeight.w800 : FontWeight.w400),
                ),
              ),
              if (money)
                IconButton(
                  key: Key('$keyPrefix-reset'),
                  tooltip: resetTooltip,
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  onPressed: amount > 0 ? () => onChanged(0) : null,
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              step(
                '−$small',
                Key(money ? '$keyPrefix-minus-$small' : '$keyPrefix-minus'),
                amount > 0 ? () => onChanged((amount - small).clamp(0, max)) : null,
              ),
              for (final s in steps)
                step(
                  '+$s',
                  Key(money ? '$keyPrefix-plus-$s' : '$keyPrefix-plus'),
                  amount < max ? () => onChanged((amount + s).clamp(0, max)) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A street (or station, utility) as a small deed chip: the group's colour,
/// the name, a lock when mortgaged; chosen with a check mark. A street that
/// cannot be traded is greyed out with the [reason] under it.
class PropertyDeedChip extends StatelessWidget {
  final PropertyGame game;
  final int square;
  final bool selected;
  final String? reason;
  final VoidCallback? onTap;
  const PropertyDeedChip({
    super.key,
    required this.game,
    required this.square,
    this.selected = false,
    this.reason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final palette = KlunkiPalette.of(context);
    final sq = game.theme.squares[square];
    final band = sq.group >= 0 ? propertyGroupColor(sq.group) : theme.colorScheme.outline;
    final disabled = reason != null;
    final interactive = onTap != null;
    final mortgaged = game.isMortgaged(square);
    final IconData? kind = switch (sq.kind) {
      PropertyKind.station => Icons.train_outlined,
      PropertyKind.utility => square == 12 ? Icons.water_drop_outlined : Icons.cell_tower,
      _ => null,
    };
    final chip = Material(
      color: selected ? theme.colorScheme.primaryContainer : palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 8, color: disabled ? band.withValues(alpha: 0.4) : band),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 6, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          if (kind != null) ...[Icon(kind, size: 14), const SizedBox(width: 4)],
                          Expanded(
                            child: Text(
                              sq.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: disabled ? theme.colorScheme.onSurfaceVariant : null,
                                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (mortgaged) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock_outline, size: 14, semanticLabel: l10n.propertyMortgaged),
                          ],
                          if (interactive) ...[
                            const SizedBox(width: 4),
                            Icon(
                              selected ? Icons.check_circle : Icons.circle_outlined,
                              size: 18,
                              color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
                            ),
                          ],
                        ],
                      ),
                      if (reason != null)
                        Text(
                          reason!,
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      button: interactive,
      selected: interactive ? selected : null,
      enabled: interactive || !disabled,
      child: chip,
    );
  }
}

// ------------------------------------------------------------- the answer

/// What the trade partner sees (over the board): the whole offer from
/// their side ("Du gibst" is what they give) and "Annehmen" / "Ablehnen".
class PropertyTradeAnswer extends StatelessWidget {
  final PropertyGame game;
  final String Function(int seat) name;
  final void Function(Map<String, dynamic> move) submit;
  const PropertyTradeAnswer({super.key, required this.game, required this.name, required this.submit});

  @override
  Widget build(BuildContext context) {
    final t = game.trade;
    if (t == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget column(String title, PropertyTradeSide side, String tag) => Column(
      key: Key('property-trade-answer-$tag'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        if (side.isEmpty) Text(l10n.propertyTradeNothing, style: theme.textTheme.bodyMedium),
        if (side.money > 0)
          Text(
            l10n.propertyMoney(side.money),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        if (side.cards > 0) Text(l10n.propertyTradeCardCount(side.cards), style: theme.textTheme.bodyMedium),
        for (final i in side.squares)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: PropertyDeedChip(game: game, square: i),
          ),
      ],
    );
    return Column(
      key: const Key('property-trade-answer'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            SeatToken(seat: t.from, size: 22),
            const Icon(Icons.swap_horiz, size: 20),
            SeatToken(seat: t.to, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.propertyTradeOfferFor(name(t.from), name(t.to)),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // The partner's side: they give what was asked for.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(l10n.propertyTradeGive, t.get, 'give')),
            const SizedBox(width: 10),
            Expanded(child: column(l10n.propertyTradeGet, t.give, 'get')),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            FilledButton.icon(
              key: const Key('property-trade-accept'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => submit({'action': 'tradeAccept'}),
              icon: const Icon(Icons.handshake_outlined),
              label: Text(l10n.propertyTradeAccept),
            ),
            OutlinedButton.icon(
              key: const Key('property-trade-decline'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => submit({'action': 'tradeDecline'}),
              icon: const Icon(Icons.close),
              label: Text(l10n.propertyTradeDecline),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- handover

/// Covers the board while the device changes hands for a trade: after an
/// offer, "Gib das Gerät an Ben weiter" until Ben taps "Ich bin Ben –
/// weiter" (the offering player may still take the offer back); after the
/// answer, what Ben decided and "Gib das Gerät an Anna weiter". The board
/// stays mounted underneath ([Offstage]).
class PropertyTradeGate extends StatefulWidget {
  final GameController controller;
  final Widget child;
  const PropertyTradeGate({super.key, required this.controller, required this.child});

  @override
  State<PropertyTradeGate> createState() => _PropertyTradeGateState();
}

class _PropertyTradeGateState extends State<PropertyTradeGate> {
  /// The move after which the cover was acknowledged (the offer, the answer).
  AcceptedMove? _seen;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final game = widget.controller.game;
        final moves = widget.controller.moves;
        final last = moves.isEmpty ? null : moves.last;
        Widget? cover;
        if (game is PropertyGame &&
            !game.isOver &&
            game.phase == PropertyPhase.trade &&
            game.trade != null &&
            identical(last, _seen)) {
          // The partner has the device: the whole offer, full size (on a
          // phone the action panel under the board would be too small).
          cover = _AnswerView(game: game, submit: widget.controller.submit);
        } else if (game is PropertyGame && !game.isOver && last != null && !identical(last, _seen)) {
          final action = last.move['action'];
          final t = game.trade;
          if (game.phase == PropertyPhase.trade && t != null && action == 'tradeOffer') {
            cover = _Cover(
              from: t.from,
              to: t.to,
              answer: null,
              seat: t.to,
              count: game.playerCount,
              onDone: () => setState(() => _seen = last),
            );
          } else if (action == 'tradeAccept' || action == 'tradeDecline') {
            // The offering player is the one whose turn it is; the partner answered.
            final from = game.currentSeat, to = last.seat;
            if (from != to) {
              cover = _Cover(
                from: from,
                to: to,
                answer: action == 'tradeAccept',
                seat: from,
                count: game.playerCount,
                onDone: () => setState(() => _seen = last),
              );
            }
          }
        }
        final covered = cover != null;
        return Stack(
          fit: StackFit.expand,
          children: [
            Offstage(
              offstage: covered,
              child: TickerMode(
                enabled: !covered,
                child: ExcludeSemantics(excluding: covered, child: widget.child),
              ),
            ),
            ?cover,
          ],
        );
      },
    );
  }
}

class _AnswerView extends StatelessWidget {
  final PropertyGame game;
  final void Function(Map<String, dynamic> move) submit;
  const _AnswerView({required this.game, required this.submit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = SeatLabelsScope.of(context);
    return Material(
      key: const Key('property-trade-answer-view'),
      color: theme.colorScheme.surfaceContainerLow,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: KlunkiPalette.of(context).card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: PropertyTradeAnswer(
                game: game,
                name: (s) => labels.label(context, l10n, s, count: game.playerCount),
                submit: submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final int from;
  final int to;

  /// Null: the offer was just made; else whether it was accepted.
  final bool? answer;

  /// Who takes the device now.
  final int seat;

  /// The number of seats (for their labels).
  final int count;
  final VoidCallback onDone;
  const _Cover({
    required this.from,
    required this.to,
    required this.answer,
    required this.seat,
    required this.count,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final labels = SeatLabelsScope.of(context);
    String name(int s) => labels.label(context, l10n, s, count: count);
    final a = answer;
    final title = a == null
        ? l10n.propertyTradeOfferFor(name(from), name(to))
        : (a ? l10n.propertyEvTraded(name(to)) : l10n.propertyEvTradeDeclined(name(to)));
    return Material(
      key: const Key('property-trade-cover'),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                a == null ? Icons.swap_horiz : (a ? Icons.handshake_outlined : Icons.do_not_disturb_alt),
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                key: const Key('property-trade-cover-title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              SeatToken(seat: seat, size: 40),
              const SizedBox(height: 12),
              Text(
                l10n.shellHandoverPass(name(seat)),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 28),
              FilledButton(
                key: Key(a == null ? 'property-trade-handover' : 'property-trade-back'),
                style: FilledButton.styleFrom(minimumSize: const Size(240, 64), textStyle: theme.textTheme.titleLarge),
                onPressed: onDone,
                child: Text(l10n.shellHandoverContinue(name(seat)), textAlign: TextAlign.center),
              ),
              // The offering player may still take the offer back before
              // passing the device; the answer itself is final.
              if (a == null) ...[const SizedBox(height: 16), const UndoMoveButton()],
            ],
          ),
        ),
      ),
    );
  }
}

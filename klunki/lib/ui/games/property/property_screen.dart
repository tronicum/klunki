import 'package:flutter/material.dart';
import 'package:klunki/l10n/app_localizations.dart';
import 'package:klunki_engine/klunki_engine.dart' hide Card;

import '../../../game/game_controller.dart';
import '../../../transport/game_transport.dart';
import '../../shell/game_screen.dart' show ShellMenuEntry;
import '../../shell/seat_game_screen.dart';
import 'property_board.dart';
import 'property_trade.dart';

/// Baulöwe (KLD-060): the property-trading dice game for 2–4 players on one
/// device, in the seat shell ([SeatGameScreen]). The board
/// (`property_board.dart`) has the players with their money, the 40
/// squares, the dice and the actions of the player who must move now (the
/// bidder in an auction, the debtor in a debt); the rules are the shell's
/// "Regeln" page (`rules/games/property_rules.dart`).
///
/// Street names, building names and card texts come from the board theme
/// (German data, like Quartett car names); everything else is localised.
///
/// Contract: `const PropertyScreen({super.key, required this.controller})`,
/// built by `ui/shell/screen_registry.dart`.
class PropertyScreen extends StatefulWidget {
  final GameController controller;
  const PropertyScreen({super.key, required this.controller});

  @override
  State<PropertyScreen> createState() => _PropertyScreenState();
}

class _PropertyScreenState extends State<PropertyScreen> {
  /// "Kurz erklärt" in the "⋮" menu: the board shows the tour again.
  final _tour = PropertyTourRequest();

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SeatNamesBuilder(
      // The names of the seats are needed by the history texts.
      child: Builder(
        builder: (context) => SeatGameScreen(
          controller: widget.controller,
          describeMove: (l10n, move) => describePropertyMove(l10n, widget.controller, move, propertySeatNamer(context, widget.controller.config.players)),
          // The narration names everybody ("Anna würfelt …", "Ben zahlt …").
          historyNamesMover: false,
          // The board tells who starts in its story line (fixed height).
          showStarter: false,
          resultScore: (l10n, result, seat) {
            final game = widget.controller.game;
            if (game is PropertyGame && game.isSeatOut(seat)) return l10n.propertyOut;
            final worth = result.params['worth$seat'];
            return worth == null ? null : l10n.propertyMoney(worth);
          },
          menuEntries: [
            ShellMenuEntry(
              key: const Key('property-tour'),
              icon: Icons.tour_outlined,
              label: l10n.propertyCoachReplay,
              onSelected: _tour.request,
            ),
          ],
          // Trades (step 3b): the device goes to the partner and back.
          boardBuilder: (context, controller) =>
              PropertyTradeGate(controller: controller, child: PropertyBoard(controller: controller, tour: _tour)),
        ),
      ),
    );
  }
}

/// The names of [count] seats as shown in sentences ([SeatLabelsScope]).
String Function(int seat) propertySeatNamer(BuildContext context, int count) {
  final labels = SeatLabelsScope.of(context);
  final l10n = AppLocalizations.of(context);
  return (seat) => labels.label(context, l10n, seat, count: count);
}

/// Small lookups shared by the board and the texts.
abstract final class PropertyNames {
  /// The localised name of a built-in board, else its own title.
  static String themeTitle(AppLocalizations l10n, PropertyTheme theme) => switch (theme.id) {
        'berlin' => l10n.propertyThemeBerlin,
        'fantasie' => l10n.propertyThemeFantasie,
        _ => theme.title,
      };

  /// The building name for [houses] (1–4 small, 5 the big one) on [square].
  static String building(PropertyTheme theme, int square, int houses) {
    final g = theme.colourGroups[theme.squares[square].group];
    return houses >= 5 ? g.big : g.small;
  }
}

/// History text of a move: what happened, in sentences.
String describePropertyMove(
    AppLocalizations l10n, GameController controller, AcceptedMove move, String Function(int seat) name) {
  final game = controller.game;
  final event = move.event;
  if (game is! PropertyGame || event is! PropertyEvent) return move.move['action']?.toString() ?? '';
  final lines = propertyNarration(l10n, game, event.events, move.seat, name);
  if (lines.isNotEmpty) return lines.join(' · ');
  // Nothing to tell (e.g. "Zug beenden"): the mover and the button.
  final action = move.move['action'];
  final label = switch (action) {
    'endTurn' => l10n.propertyEndTurn,
    'decline' => l10n.propertyDecline,
    'pass' => l10n.propertyPass,
    'roll' => l10n.propertyRoll,
    'useCard' => l10n.propertyUseCard,
    'bankrupt' => l10n.propertyBankrupt,
    _ => action?.toString() ?? '',
  };
  return l10n.shellHistoryEntry(name(move.seat), label);
}

/// The engine's [events] of one move by [mover] as short sentences (the
/// shell's hint line and the history). Turn changes and the game end are
/// left out (the status line and the result dialog say them).
List<String> propertyNarration(AppLocalizations l10n, PropertyGame game, List<Map<String, dynamic>> events, int mover,
    String Function(int seat) name) {
  final theme = game.theme;
  String square(Object? i) => i is int && i >= 0 && i < theme.squares.length ? theme.squares[i].name : '?';
  String money(Object? a) => l10n.propertyMoney(a is int ? a : 0);
  String who(Object? s) => name(s is int ? s : mover);
  final pot = game.freeSquare == PropertyFreeSquare.pot || game.freeSquare == PropertyFreeSquare.potWithSeed;
  final out = <String>[];
  for (var i = 0; i < events.length; i++) {
    final e = events[i];
    switch (e['type']) {
      case 'rolled':
        final dice = (e['dice'] as List).cast<int>();
        var text = l10n.propertyEvRolled(who(mover), dice[0], dice[1]);
        // "→ square" right after the roll it belongs to.
        if (i + 1 < events.length && events[i + 1]['type'] == 'moved') {
          text = '$text → ${square(events[++i]['to'])}';
        }
        out.add(text);
      case 'moved':
        out.add('→ ${square(e['to'])}');
      case 'salary':
        out.add(l10n.propertyEvSalary(who(e['seat']), money(e['amount'])));
      case 'card':
        out.add(l10n.propertyEvCard(theme.card(e['id'])?.text ?? '${e['id']}'));
      case 'collected':
        out.add(l10n.propertyEvCollected(who(e['seat']), money(e['amount'])));
      case 'pot':
        out.add(l10n.propertyEvPot(who(e['seat']), money(e['amount'])));
      case 'paid':
        final creditor = e['creditor'];
        if (creditor is int) {
          out.add(l10n.propertyEvPaid(who(e['debtor']), money(e['amount']), who(creditor)));
        } else if (pot && (e['reason'] == 'tax' || e['reason'] == 'card')) {
          out.add(l10n.propertyEvPaidPot(who(e['debtor']), money(e['amount'])));
        } else {
          out.add(l10n.propertyEvPaidBank(who(e['debtor']), money(e['amount'])));
        }
      case 'bought':
        out.add(l10n.propertyEvBought(who(e['seat']), square(e['square']), money(e['price'])));
      case 'auction':
        out.add(l10n.propertyAuctionTitle(square(e['square'])));
      case 'bid':
        out.add(l10n.propertyEvBid(who(e['seat']), money(e['amount'])));
      case 'passed':
        out.add(l10n.propertyEvPassed(who(e['seat'])));
      case 'unsold':
        out.add(l10n.propertyEvUnsold(square(e['square'])));
      case 'built':
        final s = e['square'] as int;
        out.add(l10n.propertyEvBuilt(who(e['seat']), PropertyNames.building(theme, s, e['houses'] as int), square(s)));
      case 'sold':
        out.add(l10n.propertyEvSold(who(e['seat']), square(e['square']), money(e['amount'])));
      case 'mortgaged':
        out.add(l10n.propertyEvMortgaged(who(e['seat']), square(e['square']), money(e['amount'])));
      case 'unmortgaged':
        out.add(l10n.propertyEvUnmortgaged(who(e['seat']), square(e['square']), money(e['amount'])));
      case 'toPause':
        out.add(l10n.propertyEvToPause(who(e['seat']), square(PropertyGame.pauseSquare)));
      case 'threeDoubles':
        out.add(l10n.propertyEvThreeDoubles);
      case 'leftPause':
        out.add(l10n.propertyEvLeftPause(who(mover)));
      case 'stayInPause':
        out.add(l10n.propertyEvStayInPause(who(mover), e['tries'] as int));
      case 'bankrupt':
        out.add(l10n.propertyEvBankrupt(who(e['seat'])));
      case 'resigned':
        out.add(l10n.propertyEvResigned(who(e['seat'])));
      case 'tradeOffered':
        out.add(l10n.propertyEvTradeOffered(who(e['from']), who(e['to']),
            propertyTradeSideText(l10n, theme, e['give'] as Map<String, dynamic>?),
            propertyTradeSideText(l10n, theme, e['get'] as Map<String, dynamic>?)));
      case 'traded':
        out.add(l10n.propertyEvTraded(who(e['to'])));
      case 'tradeDeclined':
        out.add(l10n.propertyEvTradeDeclined(who(e['to'])));
    }
  }
  return out;
}
